package Apache::Emulator::Apache;

package Apache;
use strict;

sub new {
    my $class = shift;
    my %p = @_;
    return bless {
		  query           => $p{cgi} || CGI->new,
		  headers_out     => Apache::Table->new,
		  err_headers_out => Apache::Table->new,
		  pnotes          => {},
		 }, $class;
}

# CGI request are _always_ main, and there is never a previous or a next
# internal request.
sub main {}
sub prev {}
sub next {}
sub is_main {1}
sub is_initial_req {1}

# What to do with this?
# sub allowed {}

sub method {
    $_[0]->query->request_method;
}

# There mut be a mapping for this.
# sub method_number {}

# Can CGI.pm tell us this?
# sub bytes_sent {0}

# The request line sent by the client." Poached from Apache::Emulator.
sub the_request {
    my $self = shift;
    $self->{the_request} ||= join ' ', $self->method,
      ( $self->{query}->query_string
        ? $self->uri . '?' . $self->{query}->query_string
        : $self->uri ),
      $self->{query}->server_protocol;
}

# Is CGI ever a proxy request?
# sub proxy_req {}

sub header_only { $_[0]->method eq 'HEAD' }

sub protocol { $ENV{SERVER_PROTOCOL} || 'HTTP/1.0' }

sub hostname { $_[0]->{query}->server_name }

# Fake it by just giving the current time.
sub request_time { time }

sub uri {
    my $self = shift;

    $self->{uri} ||= $self->{query}->script_name . $self->path_info || '';
}

# Is this available in CGI?
# sub filename {}

# "The $r->location method will return the path of the
# <Location> section from which the current "Perl*Handler"
# is being called." This is irrelevant, I think.
# sub location {}

sub path_info { $_[0]->{query}->path_info }

sub args {
    my $self = shift;
    if (@_) {
        # Assign args here.
    }
    return $self->{query}->Vars unless wantarray;
    # Do more here to return key => arg values.
}

sub headers_in {
    my $self = shift;

    # Create the headers table if necessary. Decided how to build it based on
    # information here:
    # http://cgi-spec.golux.com/draft-coar-cgi-v11-03-clean.html#6.1
    #
    # Try to get as much info as possible from CGI.pm, which has
    # workarounds for things like the IIS PATH_INFO bug.
    #
    $self->{headers_in} ||= Apache::Table->new
      ( 'Authorization'       => $self->{query}->auth_type, # No credentials though.
        'Content-Length'      => $ENV{CONTENT_LENGTH},
        'Content-Type'        =>
        ( $self->{query}->can('content_type') ?
          $self->{query}->content_type :
          $ENV{CONTENT_TYPE}
        ),
        # Convert HTTP environment variables back into their header names.
        map {
            my $k = ucfirst lc;
            $k =~ s/_(.)/-\u$1/g;
            ( $k => $self->{query}->http($_) )
        } grep { s/^HTTP_// } keys %ENV
      );


    # Give 'em the hash list of the hash table.
    return wantarray ? %{$self->{headers_in}} : $self->{headers_in};
}

sub header_in {
    my ($self, $header) = (shift, shift);
    my $h = $self->headers_in;
    return @_ ? $h->set($header, shift) : $h->get($header);
}


#           The $r->content method will return the entity body
#           read from the client, but only if the request content
#           type is "application/x-www-form-urlencoded".  When
#           called in a scalar context, the entire string is
#           returned.  When called in a list context, a list of
#           parsed key => value pairs are returned.  *NOTE*: you
#           can only ask for this once, as the entire body is read
#           from the client.
# Not sure what to do with this one.
# sub content {}

# I think this may be irrelevant under CGI.
# sub read {}

# Use LWP?
sub get_remote_host {}
sub get_remote_logname {}

sub http_header {
    my $self = shift;
    my $h = $self->headers_out;
    my $e = $self->err_headers_out;
    my $method = exists $h->{Location} || exists $e->{Location} ?
      'redirect' : 'header';
    return $self->query->$method(tied(%$h)->cgi_headers,
                                 tied(%$e)->cgi_headers);
}

sub send_http_header {
    my $self = shift;

    print STDOUT $self->http_header;

    $self->{http_header_sent} = 1;
}

sub http_header_sent { shift->{http_header_sent} }

# How do we know this under CGI?
# sub get_basic_auth_pw {}
# sub note_basic_auth_failure {}

# I think that this just has to be empty.
sub handler {}

sub notes {
    my ($self, $key) = (shift, shift);
    $self->{notes} ||= Apache::Table->new;
    return wantarray ? %{$self->{notes}} : $self->{notes}
      unless defined $key;
    return $self->{notes}{$key} = "$_[0]" if @_;
    return $self->{notes}{$key};
}

sub pnotes {
    my ($self, $key) = (shift, shift);
    return wantarray ? %{$self->{pnotes}} : $self->{pnotes}
      unless defined $key;
    return $self->{pnotes}{$key} = $_[0] if @_;
    return $self->{pnotes}{$key};
}

sub subprocess_env {
    my ($self, $key) = (shift, shift);
    unless (defined $key) {
        $self->{subprocess_env} = Apache::Table->new(%ENV);
        return wantarray ? %{$self->{subprocess_env}} :
          $self->{subprocess_env};

    }
    $self->{subprocess_env} ||= Apache::Table->new(%ENV);
    return $self->{subprocess_env}{$key} = "$_[0]" if @_;
    return $self->{subprocess_env}{$key};
}

sub content_type {
    shift->header_out('Content-Type', @_);
}

sub content_encoding {
    shift->header_out('Content-Encoding', @_);
}

sub content_languages {
    my ($self, $langs) = @_;
    return unless $langs;
    my $h = shift->headers_out;
    for my $l (@$langs) {
        $h->add('Content-Language', $l);
    }
}

sub status {
    shift->header_out('Status', @_);
}

sub status_line {
    # What to do here? Should it be managed differently than status?
    my $self = shift;
    if (@_) {
        my $status = shift =~ /^(\d+)/;
        return $self->header_out('Status', $status);
    }
    return $self->header_out('Status');
}

sub headers_out {
    my $self = shift;
    return wantarray ? %{$self->{headers_out}} : $self->{headers_out};
}

sub header_out {
    my ($self, $header) = (shift, shift);
    my $h = $self->headers_out;
    return @_ ? $h->set($header, shift) : $h->get($header);
}

sub err_headers_out {
    my $self = shift;
    return wantarray ? %{$self->{err_headers_out}} : $self->{err_headers_out};
}

sub err_header_out {
    my ($self, $err_header) = (shift, shift);
    my $h = $self->err_headers_out;
    return @_ ? $h->set($err_header, shift) : $h->get($err_header);
}

sub no_cache {
    my $self = shift;
    $self->header_out(Pragma => 'no-cache');
    $self->header_out('Cache-Control' => 'no-cache');
}

sub print {
    print @_;
}

sub send_fd {
    my ($self, $fd) = @_;
    local $_;

    print STDOUT while defined ($_ = <$fd>);
}

# Should this perhaps throw an exception?
# sub internal_redirect {}
# sub internal_redirect_handler {}

# Do something with ErrorDocument?
# sub custom_response {}

# I think we'ev made this essentially the same thing.
BEGIN {
    local $^W;
    *send_cgi_header = \&send_http_header;
}

# Does CGI support logging?
# sub log_reason {}
# sub log_error {}
sub warn {
    shift;
    print STDERR @_, "\n";
}

sub params {
    my $self = shift;
    return HTML::Mason::Utils::cgi_request_args($self->query,
                                                $self->query->request_method);
}

1;

__END__

=head1 NAME

HTML::Mason::FakeApache - An Apache object emulator for use with Mason

=head1 SYNOPSIS

See L<HTML::Mason::CGIHandler|HTML::Mason::CGIHandler>.

=head1 DESCRIPTION

This class's API is documented in L<HTML::Mason::CGIHandler|HTML::Mason::CGIHandler>.

=cut
