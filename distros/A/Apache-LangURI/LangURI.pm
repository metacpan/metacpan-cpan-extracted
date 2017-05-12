package Apache::LangURI;

use strict;
use warnings;
use Apache::Log ();
use Locale::Language qw(code2language);
use Locale::Country  qw(LOCALE_CODE_ALPHA_2 LOCALE_CODE_ALPHA_3 code2country);

our (@ISA, $VERSION, %PARAMS);

BEGIN {
  # if by some fluke we wanted to change the config directives
  use constant IGNORE_REGEX => 'IgnorePathRegex';
  use constant DEFAULT_LANG => 'DefaultLanguage';
  use constant FORCE_LANG   => 'ForceLanguage';
  use constant REDIR_PERM   => 'RedirectPermanent';

  require mod_perl;

  $VERSION = '0.19';

  %PARAMS = (
    IGNORE_REGEX,   [], 
    DEFAULT_LANG,   'en',
    FORCE_LANG,     1, 
    REDIR_PERM,     0,
  );

  if ($mod_perl::VERSION >= 1.99) {
    require Apache::RequestRec;
    require Apache::SubRequest;
    require Apache::RequestUtil;
    require APR::Table;
    require APR::URI;
    # this whines unless you "use" it. figure that one out.
    require Apache::Const;
    Apache::Const->import(-compile => qw(OK HTTP_OK DECLINED 
      HTTP_MOVED_PERMANENTLY REDIRECT SERVER_ERROR OR_ALL ITERATE TAKE1));
    @ISA = qw(Apache::RequestRec);

    *handler = \&_handler_2;
  }
  else {
    require Apache;
    require Apache::URI;
    require Apache::Constants;
    Apache::Constants->import(qw(OK DECLINED HTTP_MOVED_PERMANENTLY
      REDIRECT SERVER_ERROR));
    @ISA = qw(Apache);
    *Apache::OK = *Apache::HTTP_OK  = \&Apache::Constants::OK;
    *Apache::DECLINED               = \&Apache::Constants::DECLINED;
    *Apache::REDIRECT               = \&Apache::Constants::REDIRECT;
    *Apache::SERVER_ERROR           = \&Apache::Constants::SERVER_ERROR;
    *Apache::HTTP_MOVED_PERMANENTLY = 
      \&Apache::Constants::HTTP_MOVED_PERMANENTLY;
    
    # blech
    *Apache::OR_ALL = *Apache::TAKE1 = *Apache::ITERATE = sub { 1 };

    *handler = \&_handler_1;
  }
}

our @APACHE_MODULE_COMMANDS = (
  {
    name          => IGNORE_REGEX,
    func          => __PACKAGE__ . '::_ignore_regex',
    req_override  => Apache::OR_ALL,
    args_how      => Apache::ITERATE,
    errmsg        => IGNORE_REGEX . ' pattern [pattern ...]',
  },
  {
    name          => DEFAULT_LANG,
    func          => __PACKAGE__ . '::_default_lang',
    req_override  => Apache::OR_ALL,
    args_how      => Apache::TAKE1,
    errmsg        => DEFAULT_LANG . ' language',
  },
  {
    name          => FORCE_LANG,
    func          => __PACKAGE__ . '::_force_lang',
    req_override  => Apache::OR_ALL,
    args_how      => Apache::TAKE1,
    errmsg        => FORCE_LANG . ' yes|no',
  },
  {
    name          => REDIR_PERM,
    func          => __PACKAGE__ . '::_redir_perm',
    req_override  => Apache::OR_ALL,
    args_how      => Apache::TAKE1,
    errmsg        => REDIR_PERM . ' yes|no',
  },
);

our $A2 = LOCALE_CODE_ALPHA_2;
our $A3 = LOCALE_CODE_ALPHA_3;

sub _ignore_regex { 
  $PARAMS{&IGNORE_REGEX} ||= [];
  my $neg = $_[2] !~ s/^!// || 0;
  my $re = eval { qr{$_[2]} };
  die "Invalid regular expression $_[2]" if ($@);
  push @{$PARAMS{&IGNORE_REGEX}}, sub { $neg == scalar(shift =~ $re) };
}

sub _default_lang { $PARAMS{&DEFAULT_LANG}  =  $_[2]                         }
sub _force_lang   { $PARAMS{&FORCE_LANG}    = ($_[2] =~ /^(1|true|on|yes)$/) }
sub _redir_perm   { $PARAMS{&REDIR_PERM}    = ($_[2] =~ /^(1|true|on|yes)$/) }

sub _handler {
my $r = shift;
  if ($r->is_initial_req) {
    $r->verify_config;
    for my $ignore (@{$PARAMS{&IGNORE_REGEX}}) {
      if ($ignore->($r->uri)) {
        $r->log->debug
          (sprintf("Ignoring %s that matches ignore regex.", $r->uri));
        return Apache::DECLINED;
      }
    }
    $r->set_accept_language;
    return $r->perform_redirection;
  }
  return Apache::DECLINED;
}

sub _handler_1 ($$) {
  my $r = bless { r => $_[1] }, $_[0];
  return $r->_handler;
}

sub _handler_2 : method {
  my $r = bless { r => $_[1] }, $_[0];
  return $r->_handler;
}

sub verify_config {
  my $r = shift;
  $PARAMS{&DEFAULT_LANG} ||= $r->dir_config->get(DEFAULT_LANG);
  for my $bit (FORCE_LANG, REDIR_PERM) {
    my $cfg = $r->dir_config->get($bit) || '';
    $PARAMS{$bit} ||= scalar($cfg =~ /^(1|true|on|yes)$/i);
  }
  map { _ignore_regex(undef,undef,$_) } $r->dir_config->get(IGNORE_REGEX)
    unless @{$PARAMS{&IGNORE_REGEX}};
}

sub get_accept_language {
  my $r   = shift;

  my $hdr = $r->headers_in->get('Accept-Language');
  return Apache::DECLINED unless $hdr;

  # acquire hash of from the Accept-Language header
  my %accept;
  my $seen = 0;
  for (split(/\s*,\s*/, $hdr)) {
    my ($key, @vals) = split /\s*;\s*/;
    $key =~ tr/A-Z_/a-z-/;
    $accept{$key} ||= {};
    unless (@vals) {
      # decrement quality assessment just a bit to indicate order
      $accept{$key}{q} = 1 - ++$seen / 10000;
      #$r->log->debug("$key => '1.0'");
    }
    my $seenq = 0;
    for (@vals) {
      my ($k, $v) = split /\s*=\s*/;
      # some user agents use qs :P
      if ($k =~ /^qs?$/) {
        # no mucking about if the client sent us more than one q parameter.
        next if $seenq;
        $v = 1 - ++$seen / 10000 if (!defined $v or $v eq '' or $v > 1);
        $v = 0 if ($v < 0);
        $accept{$key}{q}  = $v;
        #$r->log->debug("$key => '$v'");
        $seenq = 1;
      }
      else {
        $accept{$key}{$k} = $v;
        #$r->log->debug("$key => '$v'");
      }
    }
  }
  $r->{accept_langs} = \%accept;
  return Apache::OK;
}

sub translate_uri_path {
  my $r = shift;

  $r->get_accept_language unless defined $r->{accept_langs};

  # walk the url path looking for language tags.
  # future note: check for actual on-disk entities corresponding to 
  # language tags via subrequests
  
  my @uri = split(/\/+/, $r->uri, -1);
  my ($major, $minor);
  my $i = 1; # segment 0 will be an empty string
  (@{$r}{qw(cnt pos)}) = (0, 1);
  while ($i < @uri) {
    if ($uri[$i] =~ /^([A-Za-z]{2})(?:[\-_]([A-Za-z]{2,3}))?$/
        and (code2language($1) and 
          (!$2 || code2country($2,  length($2) == 2 ? $A2 : $A3)))) {
      if (my $subr = $r->lookup_uri(join('/', @uri[0..$i]))) {
        if ($subr->status == Apache::HTTP_OK and -e $subr->filename) {
          $r->log->debug(sprintf('Existing path %s', $subr->filename));
          $i++;
          next;
        }
      }
      ($major, $minor) = (lc($1), lc($2));
      $r->{pos} = $i; # set the index of the farthest-right language tag
      $r->{cnt}++;    # increment the count of discovered tags in the path
      splice(@uri, $i, 1);
    }
    else {
      $i++;
    }
  }
  @{$r}{qw(major minor)} = ($major, $minor);
  $r->{uri_parts} = \@uri;
  return Apache::OK;
}

sub set_accept_language {
  my $r = shift;
  $r->get_accept_language;
  $r->translate_uri_path;

  # adjust Accept-Language header with new data
  my $lang;
  my $accept = $r->{accept_langs};
  $accept->{$PARAMS{&DEFAULT_LANG}} = { q => 0.0001 } 
    unless defined($accept->{$PARAMS{&DEFAULT_LANG}});
  my @order = sort { $accept->{$b}{q} <=> $accept->{$a}{q} } keys %$accept;
  if ($r->{major}) {
    $lang = ($r->{minor} ? "$r->{major}-$r->{minor}" : $r->{major});
  }
  else {
    $lang = (@order ? $order[0] : $PARAMS{&DEFAULT_LANG});
  }
  my $m = $r->{major} ||= substr($lang, 0, 2);
  my $hdr = "$lang;q=1.0";
  $hdr .= ", $m;q=0.8" if (defined $r->{minor} and $r->{minor} ne '');
  for my $k (@order) {
    if ($k =~ /^$m/i) {
      delete $accept->{$k};
    }
    else {
      # fucking rad.
      $hdr .= sprintf(', %s;q=%.4f%s', $k, $accept->{$k}{q} / 2 , join(';', '', 
      map { "$_=$accept->{$k}{$_}" } grep { $_ ne 'q' } keys %{$accept->{$k}}));
    }
  }

  # modify inbound header for following handlers
  $r->headers_in->set('Accept-Language', $hdr);
  $r->log->debug("Accept-Language: $hdr");
  $r->{lang} = $lang;
  return Apache::OK;
}

sub perform_redirection {
  my $r = shift;
  my @uri = @{$r->{uri_parts}};

  # prepare a subrequest that will discover if we are actually pointing
  # to anything
  my $uri  = '/' . join('/', @uri[1..$#uri]);
  $r->log->debug
    (sprintf("Original uri: '%s' Modified uri: '%s'", $r->uri, $uri));
  if ($PARAMS{&FORCE_LANG}) {
    $r->log->debug
      ("Attempting to enforce language-code path segment for $r->{lang}.");
    my $subr = $r->lookup_uri($uri || '/');
    if ($subr->status == Apache::HTTP_OK) {

      my $fn = $subr->filename;
      #my $cl = lc($subr->headers_out->get('Content-Language'));
      my $df = lc(substr($PARAMS{&DEFAULT_LANG}, 0, 2));
      my $uri_out;
      
      # if the selected language major can be found in the default language
      # redirect to a path with no rfc3066 segment if the path contains one
      # otherwise leave alone.
      
      if ($df eq $r->{major}) {
        $r->log->debug
          ("Default language '$df' is the same as major '$r->{major}'.");
        return Apache::DECLINED if ($r->{cnt} == 0); 
        if ($r->{cnt} == 1) {
          $r->log->debug(sprintf("Skipping on default language URI %s", $uri));
          $r->uri($uri);
          return Apache::DECLINED;
        }
        push @uri, '' if (-d $fn and (@uri == 1 or $uri[-1] ne ''));
        $uri_out = '/' . join('/', @uri[1..$#uri]) . 
          (defined($r->args) ? '?' . $r->args : '');
        $r->headers_out->set(Location => $uri_out);
        return $PARAMS{&REDIR_PERM} ? 
          Apache::HTTP_MOVED_PERMANENTLY : Apache::REDIRECT;
      }
      else {
        # if the subrequest's filename returns a directory on the filesystem,
        # append an empty space so that a trailing slash will be added when
        # the path is reassembled.
        $r->log->debug
          ("Default language '$df' is different from major '$r->{major}'.");
        
        if (-d $fn and (@uri == 1 or $uri[-1] ne '')) {
          push @uri, '';
          # even if we had a language segment, we have to redirect or else
          # mod_dir will eat us.
          $r->{cnt} = 0;
          $r->log->debug
            ("Modifying path to prevent counteraction with mod_dir");
        }

        # if the selected major cannot be found in the default language
        # append the rfc3066 segment to the path if it does not contain one.
      
        unless ($r->{cnt} == 1) {
          splice(@uri, ($r->{cnt} ? $r->{pos} : -1), 0, $r->{lang});
          $uri_out = join('/', @uri) . ($r->args ? '?' . $r->args : '');
          $r->log->debug("Redirecting request to '$uri_out'.");
          $r->headers_out->set(Location => $uri_out);
          return $PARAMS{&REDIR_PERM} ? 
            Apache::HTTP_MOVED_PERMANENTLY : Apache::REDIRECT;
        }
      }
    }
  }
  else {
    $r->log->debug(FORCE_LANG . " not set. not redirecting.");
  }
  $r->uri($uri);
  return Apache::DECLINED;
}

1;

__END__

=head1 NAME

Apache::LangURI - Rewrite Accept-Language headers from URI path and back

=head1 SYNOPSIS

  # httpd.conf
  
  PerlSetVar DefaultLanguage en

  # for redirecting the url based on the top language 
  # in the inbound header
  PerlSetVar ForceLanguage on

  PerlAddVar IgnorePathRegex ^/foo
  # and the opposite:
  PerlAddVar IgnorePathRegex !^/foo/bar

  PerlTransHandler Apache::LangURI

=head1 DESCRIPTION

Apache::LangURI will attempt to match the first segment of the path
of an http URL to an RFC3066 E<lt>majorE<gt>-E<lt>minorE<gt> language code.
It will also optionally prepend the "best" language code to the path, should
it not already be there. Language tags are normalized to a lower case major
with an upper case minor and a hyphen in between.

=head1 CONFIGURATION


=head3 DefaultLanguage

This defines the default language that will be added at a diminished quality
value after the language found in the URI path, should its major part not
match. This is to ensure that a suitable variant will always be returned when
content negotiation occurs. Defaults to 'en' if omitted.

=head3 ForceLanguage

Setting this variable to a positive (1|true|on|yes) value will cause the
server to redirect the user to a path beginning with the language code of 
the highest quality value found in the Accept-Language header. This occurs 
only when the URI path does not begin with an RFC3066 language code. This
directive can be omitted if this behavior is not desired.

=head3 IgnorePathRegex

Passing a regular expression (optionally prefixed by ! to denote negation)
will limit the effect of this handler to simulate <Location> blocks on a 
transhandler.

=head3 RedirectPermanent

if set to a positive (1|true|on|yes) value, the server will return 301 Moved 
rather than 302 Found on a successful redirection.

=head1 BUGS

Only currently does ISO639 language majors and ISO3166 country minors. No 
support for constructs like "no-sami" or "x-jawa".

RFC3066 includes rules for pairings of ISO639-1/2 and ISO3166 two-character
and three-character denominations. This module does not enforce those rules.

The DefaultLanguage variable will eventually be phased out to use
Apache::Module to derive the value from mod_mime as soon as this author
manages to get it to compile.

Forms that refer to absolute URL paths may no longer function due to the
redirection process, as the POST payload will be interrupted.

=head1 SEE ALSO

Locale::Language
Locale::Country

http://www.ietf.org/rfc3066.txt

ISO 639
ISO 3166

=head1 AUTHOR

Dorian Taylor, E<lt>dorian@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Dorian Taylor

=cut
