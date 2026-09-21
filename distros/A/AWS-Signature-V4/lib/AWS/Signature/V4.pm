package AWS::Signature::V4;
{ our $VERSION = '0.001' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use Digest::SHA qw< sha256_hex >;
use POSIX qw< strftime >;
use Scalar::Util qw< openhandle >;

use AWS::Signature::V4::Error qw< fail shown >;
use AWS::Signature::V4::Checksum ();
use AWS::Signature::V4::Chunker ();
use AWS::Signature::V4::Credentials ();
use AWS::Signature::V4::X509 ();

use constant {

   # Headers that intermediaries commonly rewrite or that should never be
   # signed
   AUTH_PARAM => +{
      map { lc($_) => $_ } qw<
         X-Amz-Algorithm
         X-Amz-Credential
         X-Amz-Date
         X-Amz-Expires
         X-Amz-Security-Token
         X-Amz-Signature
         X-Amz-SignedHeaders
         X-Amz-X509
         X-Amz-X509-Chain
      >
   },

   # Headers that intermediaries commonly rewrite or that should never be
   # signed
   UNSIGNED => +{
      map { lc($_) => 1 } qw<
         Authorization
         Connection
         Expect
         Keep-Alive
         Proxy-Authenticate
         Proxy-Authorization
         Proxy-Connection
         TE
         Trailer
         Transfer-Encoding
         Upgrade
         User-Agent
         X-Amzn-Trace-Id
      >
   },

   # the arguments of some methods; anything else is an error
   ALLOWED_ARGS => +{
      encoded_length => +{
         map { $_ => 1 } qw<
            checksum
            signed
            trailers
         >
      },

      sign => +{
         map { $_ => 1 } qw<
            body
            body_fh
            checksum
            decoded_content_length
            headers
            method
            payload_hash
            signed_headers
            streaming
            time
            trailers
            unsigned_payload
            url
         >
      },

      presign => +{
         map { $_ => 1 } qw<
            body
            body_fh
            expires
            headers
            method
            payload_hash
            signed_headers
            time
            unsigned_payload
            url
         >
      },

      payload => [ qw< body body_fh payload_hash unsigned_payload > ],
      streaming => [ qw< decoded_content_length checksum trailers > ],
   },

   MAX_EPOCH => 253402300799,    # 9999-12-31T23:59:59Z
};

sub _copy ($value) { ref $value eq 'HASH' ? {$value->%*} : $value }

sub _hash_or_undef ($name, $value) {
   fail 400, qq{"$name" must be a hash reference}
      unless !defined $value || ref $value eq 'HASH';
}

# arguments of sign/presign as a hash: name => value pairs or a hash
# reference; undefined values are like missing ones, unknown names an error
sub _args ($what, @args) {
   @args = $args[0]->%* if @args == 1 && ref $args[0] eq 'HASH';
   fail 400, "$what takes name => value pairs or a hash reference" if @args % 2;
   my %args = @args;
   defined $args{$_} or delete $args{$_} for keys %args;

   # go looking for argument names that are outside the allowed ones
   my $allowed = ALLOWED_ARGS->{$what}
      or die "ALLOWED_ARGS does not support <$what>";
   if (my @l = grep { ! $allowed->{$_} } keys(%args)) {
      fail 400, "unsupported for $what: " . _shown_list(@l);
   }
   return %args;
}

sub _check_url ($url) {
   defined $url or fail 400, 'missing parameter "url"';
   fail 400, 'url must be a string' if ref $url;
   fail 400, 'url must be ASCII: percent-encode non-ASCII characters'
      if $url =~ m{[^\x00-\x7F]};
   fail 400, 'url must not contain control characters: percent-encode them'
      if $url =~ m{[\x00-\x1F\x7F]};
   return $url;
}

# an HTTP token (RFC 9110), like header names and methods
sub _is_token ($s) {
   defined $s && !ref $s && $s =~ m{\A[!#\$%&'*+.^_`|~0-9A-Za-z-]+\z};
}

sub _method ($method) {
   fail 400, 'invalid method ' . shown($method) . ': it must be an HTTP token'
      unless _is_token($method);
   return uc $method;
}

sub _is_count ($n) {
   defined $n && !ref $n && $n =~ m{\A (?: 0 | [1-9][0-9]* ) \z}mxs;
}

# headers as a hash or array of pairs, to a hash with lowercase names;
# undefined values are skipped, like missing headers
sub _headers_hash ($in) {
   my @pairs;
   if (ref $in eq 'HASH') {
      @pairs = map { $_ => $in->{$_} } sort keys $in->%*;    # repeatable order
   }
   elsif (ref $in eq 'ARRAY') {
      fail 400, '"headers" as an array reference must hold name => value pairs'
         if $in->@* % 2;
      @pairs = $in->@*;
   }
   elsif (defined $in) {
      fail 400, '"headers" must be a hash or array reference';
   }
   my %h;
   while (my ($k, $v) = splice @pairs, 0, 2) {
      _check_header_name($k);
      my @values = grep { defined } ref $v eq 'ARRAY' ? $v->@* : $v;
      _check_header_value($k, $_) for @values;
      next unless @values;
      $v = join ',', @values;
      $k = lc $k;
      $h{$k} = exists $h{$k} ? "$h{$k},$v" : $v;
   }
   return %h;
}

# so that it cannot change the canonical request
sub _check_header_name ($name) {
   fail 400, 'invalid header name ' . shown($name) unless _is_token($name);
}

# what is wrong with a value that gets signed, if anything: CR, LF and NUL
# would forge lines in the canonical request, and a character beyond a byte
# cannot go on the wire (in a query string _uri_encode would turn it into an
# invalid percent escape, silently mangling e.g. a session token)
sub _bad_value ($value) {
   return 'no CR, LF or NUL' if $value =~ m{[\r\n\0]};
   return 'a byte string, encode characters first' if $value =~ m{[^\x00-\xFF]};
   return undef;
}

# so that it cannot inject headers or lines in the canonical request
sub _check_header_value ($name, $value) {
   my $invalid = ref $value ? 'a string or an array reference of strings'
      : _bad_value($value) // return;
   fail 400, 'invalid value for header ' . shown($name) . ": $invalid";
}

# the same, for what presign signs into the query string instead of headers
sub _check_query_values (@pairs) {
   while (my ($name, $value) = splice @pairs, 0, 2) {
      my $invalid = ref $value ? 'a string' : _bad_value($value // '') // next;
      fail 400, 'invalid value for query parameter ' . shown($name) . ": $invalid";
   }
}

# all the headers to send, including those that the module adds itself
sub _check_header_values ($h) {
   _check_header_value($_, $h->{$_}) for sort keys $h->%*;
}

# sorted, lowercase names of the headers to sign. Always included: host, all
# the x-amz-* headers (AWS wants them signed) and the names in @also
sub _signed_headers ($h, $names, @also) {
   fail 400, '"signed_headers" must be an array reference' unless ref $names eq 'ARRAY';
   my %signed = map { $_ => 1 } 'host', @also, grep { m{\Ax-amz-} } keys $h->%*;
   for my $name ($names->@*) {
      _check_header_name($name);
      $signed{lc $name} = 1;
   }
   for my $name (sort keys %signed) {
      fail 400, 'cannot sign missing header ' . shown($name) unless exists $h->{$name};
   }
   return sort keys %signed;
}

sub _is_sha256 ($hash) { $hash =~ m{\A[0-9a-f]{64}\z}mxs }

# a hex SHA-256 (lowercased), UNSIGNED-PAYLOAD or a STREAMING-* marker
sub _check_payload_hash ($what, $value) {
   if (!ref $value) {
      return lc $value if $value =~ m{\A[0-9A-Fa-f]{64}\z};
      return $value if $value =~ m{\A(?:UNSIGNED-PAYLOAD|STREAMING-[A-Z0-9-]+)\z};
   }
   fail 400, "$what must be a SHA-256 in hex, UNSIGNED-PAYLOAD or a STREAMING-* marker";
}

# the payload hash in the x-amz-content-sha256 header provided by the
# caller, if any; it is put back later, when needed
sub _given_payload_hash ($h) {
   my $given = delete $h->{'x-amz-content-sha256'} // return undef;
   return _check_payload_hash('the x-amz-content-sha256 header', $given);
}

# payload hash from the arguments, undef if they say nothing about it
sub _payload_hash ($args) {
   return _check_payload_hash('"payload_hash"', $args->{payload_hash})
      if defined $args->{payload_hash};
   return 'UNSIGNED-PAYLOAD' if $args->{unsigned_payload};
   return _body_hash($args);
}

# the payload hash from the arguments and the one in the header must agree;
# the default applies if there is neither
sub _agree ($from_args, $given, $default) {
   return $from_args // $default unless defined $given;
   fail 400, 'the x-amz-content-sha256 header does not match the payload'
      if defined $from_args && $from_args ne $given;
   return $given;
}

# hex SHA-256 of the "body" or "body_fh" argument, undef if none is given
sub _body_hash ($args) {
   my $fh = $args->{body_fh};
   fail 400, 'give either "body" or "body_fh", not both'
      if defined $fh && defined $args->{body};
   return _fh_hash($fh) if defined $fh;
   return undef unless defined $args->{body};

   # the hash must match what goes on the wire, so no characters allowed;
   # a copy is made only for internally-UTF-8 strings, never modify input
   my $ref = _body_ref($args);
   return sha256_hex($$ref // '') unless utf8::is_utf8($$ref);
   my $copy = $$ref;
   utf8::downgrade($copy, 1)
      or fail 400, 'body must be a byte string: encode characters first';
   return sha256_hex($copy);
}

# the handle is hashed from where it is to its end, then put back there
sub _fh_hash ($fh) {
   openhandle($fh) or fail 400, '"body_fh" must be an open filehandle';
   fail 400, '"body_fh" must be a binary handle: binmode it'
      if grep { m{\A(?:encoding|utf8|crlf)} } PerlIO::get_layers($fh);
   my $pos = tell $fh;
   fail 400, '"body_fh" must be seekable (a file, not a pipe or a socket)'
      unless $pos >= 0 && seek $fh, $pos, 0;
   my $sha = Digest::SHA->new(256);
   eval { $sha->addfile($fh); 1 } or fail 400, qq{"body_fh" cannot be read: $!};
   seek $fh, $pos, 0 or fail 400, qq{"body_fh" cannot be put back where it was: $!};
   return $sha->hexdigest;
}

# names of the trailers: built-in checksum first, then the declared ones
sub _trailer_names ($args) {
   my @names;
   if (defined(my $algo = $args->{checksum})) {
      fail 400, 'unknown checksum ' . shown($algo) . ' (supported: '
         . join(', ', AWS::Signature::V4::Checksum->supported_algorithms) . ')'
         unless AWS::Signature::V4::Checksum->is_supported_algorithm($algo);
      push @names, "x-amz-checksum-$algo";
   }
   my $trailers = $args->{trailers} // [];
   fail 400, '"trailers" must be an array reference' unless ref $trailers eq 'ARRAY';
   for my $name (map { lc($_ // '') } $trailers->@*) {
      _check_trailer_name($name);
      fail 400, "trailer '$name' declared twice" if grep { $_ eq $name } @names;
      push @names, $name;
   }
   return @names;
}

sub _check_trailer_name ($name) {
   fail 400, 'invalid trailer name ' . shown($name) unless $name =~ m{\A[a-z0-9][a-z0-9-]*\z};
}

sub _canonical_query ($query) {
   return '' unless defined $query && length $query;
   my @pairs = map {
      my ($k, $v) = split /=/, $_, 2;
      [_uri_encode(_uri_decode($k)), _uri_encode(_uri_decode($v // ''))];
   } grep { length } split /&/, $query;
   return join '&', map { "$_->[0]=$_->[1]" }
      sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @pairs;
}

sub _uri_encode ($s) {
   $s =~ s{([^A-Za-z0-9\-_.~])}{sprintf '%%%02X', ord $1}gmse;
   return $s;
}

sub _uri_decode ($s) {
   $s =~ s{%([0-9A-Fa-f]{2})}{chr hex $1}gse;
   return $s;
}

# body is either a plain scalar or a reference to one; only in the latter
# case the caller's data is not copied at all
sub _body_ref ($args) {
   my $body = $args->{body};
   return \$args->{body} unless ref $body;
   fail 400, 'body must be a scalar or a reference to a scalar'
      unless ref($body) eq 'SCALAR';
   return $body;
}

# AWS trims and collapses spaces, so ASCII whitespace only (/a): with
# unicode_strings, \s would also take the bytes 0xA0 and 0x85 of UTF-8 text
sub _trim ($v) {
   $v =~ s{\A\s+|\s+\z}{}gmxa;  # remove leading/trailing whitespaces
   $v =~ s{\s+}{ }gas;          # normalize internal whitespaces
   return $v;
}

# (host, path, query) of a url; the host is lowercased and the port is
# removed if it is the default one, as user agents do before sending it
sub _split_url ($url) {
   # every part is optional, so this always matches
   my ($scheme, $auth, $path, $query) =
      $url =~ m{\A (?: ([A-Za-z][A-Za-z0-9+.-]*) :// ([^/?\#]*) )?
                   ([^?\#]*) (?: \? ([^\#]*) )? }x;
   fail 400, 'url path must start with "/": give an absolute url, or a path with a Host header'
      if length $path && $path !~ m{\A/};
   fail 400, 'url query must not contain "+": write %20 for a space, %2B for a plus sign'
      if defined $query && $query =~ m{\+};
   return (undef, $path, $query) unless defined $auth && length $auth;

   fail 400, 'url must not have user information (user@host)' if $auth =~ m{@};
   my ($host, $port) = $auth =~ m{\A
         (\[[0-9A-Fa-f:.]+\] | [A-Za-z0-9._~-]+)  # host
         (?: : ([0-9]*) )?   # optional port
      \z}x or fail 400, 'invalid url: ' . shown($auth);
   $host = lc $host;
   if (length($port // '')) {
      $port += 0;
      fail 400, "invalid port: $port" if $port < 1 || $port > 65535;
      my $lcscheme = lc($scheme);
      my $default = $lcscheme eq 'https' ? 443
         : $lcscheme eq 'http'           ? 80
         :                                 0;
      $host .= ':' . $port if $port != $default;
   }
   return ($host, $path, $query);
}

sub _shown_list (@list) {
   return join ', ',
      map { join '', q{"}, shown($_), q{"} }
      sort { $a cmp $b } @list;
}


use namespace::clean;    # imported or plain functions must not become methods


has service => (is => 'ro');
has region  => (is => 'ro');

# credentials: {access_key_id, secret_access_key, session_token?}
has credentials => (is => 'ro', coerce => \&_copy, isa => sub { _hash_or_undef(credentials => @_) });

# Certificate-based variant, as used by IAM Roles Anywhere.
#   certificate / certificate_file: PEM or DER text, or path of a file with it
#   chain / chain_files: optional arrayref of PEM/DER intermediate certificates,
#                or of paths of files with them; a PEM item can be a bundle.
#                chain can also be a plain string: a PEM-encoded bundle, and
#                chain_files a plain string: the path of one file
#   key_type:    'RSA' or 'ECDSA'
#   signer:      sub ($bytes_to_sign) -> signature (DER for ECDSA, PKCS#1 v1.5
#                for RSA), computed with SHA-256; or, alternatively,
#   private_key_file / private_key: PEM or DER key (path or content), signed
#                with CryptX; private_key_password if it is encrypted
has x509 => (is => 'ro', coerce => \&_copy, isa => sub { _hash_or_undef(x509 => @_) });

# S3 is the odd one out: this is the only place that knows how to tell. S3
# Object Lambda, S3 on Outposts and S3 Express sign with names of their own,
# under the same rules.
has _is_s3 => (is => 'lazy', init_arg => undef);
sub _build__is_s3 ($self) { $self->service =~ m{\As3(?:-object-lambda|-outposts|express)?\z} }

has double_encode  => (is => 'ro', lazy => 1, default => sub ($self) { !$self->_is_s3 });
has normalize_path => (is => 'ro', lazy => 1, default => sub ($self) { !$self->_is_s3 });
has payload_header => (is => 'ro', lazy => 1, default => sub ($self) { $self->_is_s3 });

# FIXME review this decision: "undef" in Perl has a history of meaning
# "false" but here we're saying that it means "do the default".
# an undefined option is like a missing one: the default applies
around BUILDARGS => sub ($orig, $class, @args) {
   my $args = $class->$orig(@args);
   defined $args->{$_} or delete $args->{$_}
      for qw< double_encode normalize_path payload_header >;
   return $args;
};

# The variant in use, credentials or x509, which knows how to sign and what
# goes with the request: see AWS::Signature::V4::Credentials and ::X509
has _auth => (is => 'lazy', init_arg => undef);

sub BUILD ($self, $args) {
   for my $name (qw< service region >) {
      my $value = $self->$name;
      defined($value) || fail 400, qq{missing parameter "$name"};
      fail 400, qq{invalid "$name" } . shown($value)
         . ': only letters, digits, ".", "_" and "-" are allowed'
         unless $value =~ m{\A[-A-Za-z0-9._]+\z};
   }

   # make sure the caller provides us *exactly* one of credentials/X509
   my $x509_params = $self->x509;
   my $credentials_params = $self->credentials;
   fail 400, 'provide either "credentials" or "x509", not both'
      if $credentials_params && $x509_params;
   fail 400, 'provide (exactly) one of "credentials" or "x509"'
      unless $credentials_params || $x509_params;

   $self->_auth;    # force building and fail fast

   # after using the parameters, we get rid of sensitive data in the input
   # hash for X509
   delete($x509_params->{$_}) for qw< private_key private_key_password >;

   return;
}

sub _build__auth ($self) {
   return $self->credentials
      ? AWS::Signature::V4::Credentials->new($self->credentials->%*)
      : AWS::Signature::V4::X509->new($self->x509->%*);
}

sub algorithm ($self) { $self->_auth->algorithm }

# sign(method => ..., url => ..., headers => ..., body => ..., time => ...)
# Returns a hashref:
#   headers:        all headers to set on the request (name => value)
#                   including Authorization, X-Amz-Date, Host if missing...
#   authorization:  value of the Authorization header
#   signature, canonical_request, string_to_sign, signed_headers, scope
sub sign ($self, @args) {
   my %args = _args(sign => @args);

   # some arguments apply to the "payload" variant and some to the
   # "streaming" variant only, we need some more input validation.
   # $not_allowed below collects the name of the parameter that are not
   # allowed for the variant that is requested.
   my $streaming = $args{streaming};
   my $not_allowed = ALLOWED_ARGS->{$streaming ? 'payload' : 'streaming'};
   my @misplaced = grep { exists $args{$_} } $not_allowed->@*;
   fail 400, qq{"$misplaced[0]" }
         . ($streaming ? 'does not apply to streaming' : 'needs streaming')
      if @misplaced;

   my $method = _method($args{method} // fail 400, 'missing parameter "method"');
   my ($h, $path, $query, $amzdate, $scope) = $self->_request(\%args);
   $h->{'x-amz-date'} = $amzdate;
   my $given = _given_payload_hash($h);

   my ($unsigned_chunks, @trailer_names);
   my $payload_hash;
   if ($streaming) {
      fail 400, 'streaming must be false, 1, "signed", or "unsigned"'
         unless $streaming =~ m{\A(?:1|signed|unsigned)\z};
      $unsigned_chunks = $streaming eq 'unsigned';
      @trailer_names = _trailer_names(\%args);
      fail 400, 'unsigned streaming needs "checksum" or "trailers"'
         if $unsigned_chunks && !@trailer_names;
      fail 400, 'signed streaming needs the credentials variant, not x509'
         if !$unsigned_chunks && !$self->_auth->can_sign_chunks;
      my $len = $args{decoded_content_length}
         // fail 400, 'streaming needs "decoded_content_length"';
      fail 400, 'decoded_content_length must be a non-negative integer'
         unless $len =~ m{\A[0-9]+\z};
      $payload_hash =
           $unsigned_chunks ? 'STREAMING-UNSIGNED-PAYLOAD-TRAILER'
         : @trailer_names   ? 'STREAMING-AWS4-HMAC-SHA256-PAYLOAD-TRAILER'
         :                    'STREAMING-AWS4-HMAC-SHA256-PAYLOAD';
      $h->{'x-amz-decoded-content-length'} = $len;
      $h->{'x-amz-trailer'} = join ',', @trailer_names if @trailer_names;

      # whatever the caller has, e.g. gzip, then aws-chunked: RFC 9110 wants
      # the encodings in the order they were applied, and this one is the
      # outermost, applied to the already-gzipped data (as botocore does)
      my @encodings = grep { length && lc($_) ne 'aws-chunked' }
         map { _trim($_) } split m{,}, $h->{'content-encoding'} // '';
      $h->{'content-encoding'} = join ',', @encodings, 'aws-chunked';
   }
   else {
      $payload_hash = _payload_hash(\%args);
   }
   $payload_hash = _agree($payload_hash, $given, sha256_hex(''));
   $h->{'x-amz-content-sha256'} = $payload_hash
      if $self->payload_header || $streaming || defined $given || !_is_sha256($payload_hash);

   my %extra = $self->_auth->extra_fields;
   $h->{lc $_} = $extra{$_} for keys %extra;
   _check_header_values($h);    # before they end up in the canonical request

   my @signed = _signed_headers($h, $args{signed_headers}
      // [grep { ! UNSIGNED->{$_} } keys $h->%*], $streaming ? 'content-encoding' : ());
   my $r = $self->_signed($method, $path, _canonical_query($query), $h,
      \@signed, $payload_hash, $amzdate, $scope);

   my $credential = $self->_auth->credential_id . "/$scope";
   $r->{authorization} = $self->algorithm . " Credential=$credential, "
      . "SignedHeaders=$r->{signed_headers}, Signature=$r->{signature}";
   _check_header_value(authorization => $r->{authorization});
   $r->{headers} = {$h->%*, authorization => $r->{authorization}};

   $r->{chunker} = AWS::Signature::V4::Chunker->new(
      ($unsigned_chunks ? () : (key => $self->_auth->signing_key($scope))),
      signed => !$unsigned_chunks, amzdate => $amzdate,
      scope => $scope, previous => $r->{signature},
      expected => $args{decoded_content_length},
      checksum => $args{checksum}, trailer_names => \@trailer_names,
   ) if $streaming;
   return $r;
}

# presign(method => 'GET', url => ..., expires => 3600, time => ...)
# Returns a hashref:
#   url:            the URL, with the signature in its query string
#   headers:        headers that the client must send with it (Host, ...)
#   signature, canonical_request, string_to_sign, signed_headers, scope
sub presign ($self, @args) {
   my %args = _args(presign => @args);
   my $method = _method($args{method} // 'GET');
   my ($h, $path, $query, $amzdate, $scope) = $self->_request(\%args);

   my $expires = $args{expires} // 3600;
   fail 400, 'expires must be an integer between 1 and 604800 seconds'
      unless $expires =~ m{\A[0-9]+\z} && $expires >= 1 && $expires <= 604800;

   for my $pair (split m{&}, $query // '') {
      my ($name) = split m{=}, $pair, 2;
      my $known = AUTH_PARAM->{lc _uri_decode($name // '')} or next;
      fail 400, "url already carries $known: presign adds it";
   }

   # S3 takes UNSIGNED-PAYLOAD for granted in presigned URLs, the others the
   # hash of the body they get: anything else needs the header, signed
   my $given = _given_payload_hash($h);
   my $payload_hash = _agree(_payload_hash(\%args), $given,
      $self->payload_header ? 'UNSIGNED-PAYLOAD' : sha256_hex(''));
   my $taken_for_granted = $self->payload_header
      ? $payload_hash eq 'UNSIGNED-PAYLOAD' : _is_sha256($payload_hash);
   $h->{'x-amz-content-sha256'} = $payload_hash
      if defined $given || !$taken_for_granted;

   my @signed = _signed_headers($h, $args{signed_headers} // []);
   _check_header_values($h);

   my @params = (
      'X-Amz-Algorithm'     => $self->algorithm,
      'X-Amz-Credential'    => $self->_auth->credential_id . "/$scope",
      'X-Amz-Date'          => $amzdate,
      'X-Amz-Expires'       => $expires,
      'X-Amz-SignedHeaders' => join(';', @signed),
      $self->_auth->extra_fields,
   );
   _check_query_values(@params);

   my @query = grep { length } $query // '';
   while (my ($k, $v) = splice @params, 0, 2) {
      push @query, _uri_encode($k) . '=' . _uri_encode($v);
   }
   my $canonical_query = _canonical_query(join '&', @query);

   my $r = $self->_signed($method, $path, $canonical_query, $h,
      \@signed, $payload_hash, $amzdate, $scope);

   # whatever is not allowed in a URL path (e.g. a space) is percent-encoded
   my ($prefix) = $args{url} =~ m{\A([^?\#]*)};
   $prefix =~ s{([^A-Za-z0-9\-._~!\$&'()*+,;=:@/%\[\]])}{sprintf '%%%02X', ord $1}ge;
   $r->{url} = "$prefix?$canonical_query&X-Amz-Signature=$r->{signature}";
   $r->{headers} = $h;
   return $r;
}

# pieces of the request that sign and presign have in common: the headers
# (with host), the path and query from the url, the date and the scope
sub _request ($self, $args) {
   my ($host, $path, $query) = _split_url(_check_url($args->{url}));
   my %h = _headers_hash($args->{headers});
   $h{host} //= $host;
   length($h{host} // '')
      or fail 400, 'url has no host: give an absolute url or a Host header';

   my $epoch = $args->{time} // time;
   fail 400, 'time must be an epoch in seconds, e.g. from time()'
      unless !ref $epoch && $epoch =~ m{\A[0-9]+(?:\.[0-9]*)?\z} && $epoch <= MAX_EPOCH;
   my $amzdate = strftime('%Y%m%dT%H%M%SZ', gmtime int $epoch);
   my $scope   = join '/', substr($amzdate, 0, 8), $self->region, $self->service, 'aws4_request';
   return (\%h, $path, $query, $amzdate, $scope);
}

# canonical request, string to sign and signature, as returned to the caller
sub _signed ($self, $method, $path, $canonical_query, $h, $signed, $payload_hash, $amzdate, $scope) {
   my $signed_headers = join ';', $signed->@*;
   my $canonical_request = join "\n",
      $method,
      $self->_canonical_path($path),
      $canonical_query,
      join('', map { "$_:" . _trim($h->{$_}) . "\n" } $signed->@*),    # ends with blank line
      $signed_headers,
      $payload_hash;
   my $string_to_sign = join "\n",
      $self->algorithm, $amzdate, $scope, sha256_hex($canonical_request);
   return {
      signature         => $self->_auth->signature($scope, $string_to_sign),
      signed_headers    => $signed_headers,
      scope             => $scope,
      canonical_request => $canonical_request,
      string_to_sign    => $string_to_sign,
   };
}

# size of an aws-chunked body: every chunk but the last one is $chunk_size
#   signed => 1 (default) or 0, checksum => $algo, trailers => {name => length}
sub encoded_length ($class, $decoded, $chunk_size, @args) {
   fail 400, 'the decoded size must be a non-negative integer'
      unless _is_count($decoded);
   fail 400, 'the chunk size must be a positive integer'
      unless _is_count($chunk_size) && $chunk_size > 0;

   fail 400, 'encoded_length named options must be name => value pairs' if @args % 2;
   my %opts = _args(encoded_length => @args);

   my $signed = exists($opts{signed}) ? ($opts{signed} || 0) : 1;
   fail 400, 'signed must be false, 1, "signed", or "unsigned"'
      if ref $signed || $signed !~ m{\A(?:1|0|signed|unsigned|)\z}mxs;
   $signed = $signed eq '1' || $signed eq 'signed';

   my $trailer = 0;  # sum of length of each trailer line "name:value\r\n"
   my %seen; # catch duplicates
   if (defined(my $algo = $opts{checksum})) {
      my ($name) = _trailer_names({checksum => $algo});
      $seen{$name} = 1;
      $trailer += length($name) + 1 + AWS::Signature::V4::Checksum->encoded_size($algo) + 2;
   }
   my $declared = $opts{trailers} // {};
   fail 400, '"trailers" must be a hash reference from names to lengths'
      unless ref $declared eq 'HASH';
   for my $given (sort keys $declared->%*) {
      my $name = lc $given;
      _check_trailer_name($name);
      # sign() refuses the same repetition, so do not count a line twice
      fail 400, "trailer '$name' declared twice" if $seen{$name}++;
      fail 400, 'the length of trailer ' . shown($given) . ' must be a non-negative integer'
         unless _is_count($declared->{$given});
      $trailer += length($name) + 1 + $declared->{$given} + 2;
   }

   my $chunk = sub ($size) {    # everything around the data of a chunk
      length(sprintf '%x', $size) + ($signed ? 17 + 64 : 0) + 2 + 2;
   };
   my $total = 0;
   my $full = int($decoded / $chunk_size);
   $total += $full * ($chunk->($chunk_size) + $chunk_size);
   my $rest = $decoded - $full * $chunk_size;
   $total += $chunk->($rest) + $rest if $rest;

   # final chunk: "0[;chunk-signature=..]\r\n", trailers, [signature line,] "\r\n"
   $total += 1 + ($signed ? 17 + 64 : 0) + 2 + $trailer + 2;
   $total += length('x-amz-trailer-signature') + 1 + 64 + 2 if $signed && $trailer;
   return $total;
}

# the path is empty or starts with "/", see _split_url
sub _canonical_path ($self, $path) {
   $path = '/' unless length $path;
   my $trailing = $path =~ m{/\z} && $path ne '/';
   my @parts = split m{/}, $path, -1;
   shift @parts;    # leading empty item, before the first /
   pop @parts if @parts && $parts[-1] eq '';    # trailing, re-added below

   if ($self->normalize_path) {
      my @out;
      for my $p (@parts) {
         next if $p eq '' || $p eq '.';
         if ($p eq '..') { pop @out; next }
         # AWS might or might not take them as dot segments: refuse them
         fail 400, 'url path has a percent-encoded dot segment ' . shown($p)
            . ': write it as it is, or remove it'
            if _uri_decode($p) =~ m{\A\.\.?\z};
         push @out, $p;
      }
      @parts = @out;
   }

   # incoming path is percent-encoded already: decode then encode once,
   # and a second time for everything but S3
   @parts = map {
      my $e = _uri_encode(_uri_decode($_));
      $e = _uri_encode($e) if $self->double_encode;
      $e;
   } @parts;
   my $out = '/' . join '/', @parts;
   $out .= '/' if $trailing && @parts;
   return $out;
}

1;
