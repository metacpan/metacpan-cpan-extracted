use strict;
use warnings;
package CPAN::Uploader;
# ABSTRACT: upload things to the CPAN
$CPAN::Uploader::VERSION = '0.103014';
#pod =head1 ORIGIN
#pod
#pod This code is mostly derived from C<cpan-upload-http> by Brad Fitzpatrick, which
#pod in turn was based on C<cpan-upload> by Neil Bowers.  I (I<rjbs>) didn't want to
#pod have to use a C<system> call to run either of those, so I refactored the code
#pod into this module.
#pod
#pod =cut

use Carp ();
use File::Basename ();
use File::Spec;
use HTTP::Request::Common qw(POST);
use HTTP::Status;
use LWP::UserAgent;
use File::HomeDir;

my $UPLOAD_URI = $ENV{CPAN_UPLOADER_UPLOAD_URI}
              || 'https://pause.perl.org/pause/authenquery?ACTION=add_uri';

#pod =method upload_file
#pod
#pod   CPAN::Uploader->upload_file($file, \%arg);
#pod
#pod   $uploader->upload_file($file);
#pod
#pod Valid arguments are:
#pod
#pod   user        - (required) your CPAN / PAUSE id
#pod   password    - (required) your CPAN / PAUSE password
#pod   subdir      - the directory (under your home directory) to upload to
#pod   http_proxy  - uri of the http proxy to use
#pod   upload_uri  - uri of the upload handler; usually the default (PAUSE) is right
#pod   debug       - if set to true, spew lots more debugging output
#pod   retries     - number of retries to perform on upload failure (5xx response)
#pod   retry_delay - number of seconds to wait between retries
#pod
#pod This method attempts to actually upload the named file to the CPAN.  It will
#pod raise an exception on error.
#pod
#pod =cut

sub upload_file {
  my ($self, $file, $arg) = @_;

  Carp::confess(q{don't supply %arg when calling upload_file on an object})
    if $arg and ref $self;

  Carp::confess(q{attempted to upload a non-file}) unless -f $file;

  # class call with no args is no good
  Carp::confess(q{need to supply %arg when calling upload_file from the class})
    if not (ref $self) and not $arg;

  $self = $self->new($arg) if $arg;

  if ($arg->{dry_run}) {
    require Data::Dumper;
    $self->log("By request, cowardly refusing to do anything at all.");
    $self->log(
      "The following arguments would have been used to upload: \n"
      . '$self: ' . Data::Dumper::Dumper($self)
      . '$file: ' . Data::Dumper::Dumper($file)
    );
  } else {
    my $tries = ($self->{retries} > 0) ? $self->{retries} + 1 : 1;

    TRY: for my $try (1 .. $tries) {
      last TRY if eval { $self->_upload($file); 1 };
      die $@ unless $@ !~ /request failed with error code 5/;
      if ($try <= $tries) {
        $self->log("Upload failed ($@), will make attempt #$try ...");
        sleep $self->{retry_delay} if $self->{retry_delay};
      }
    }
  }
}

sub _ua_string {
  my ($self) = @_;
  my $class   = ref $self || $self;
  my $version = defined $class->VERSION ? $class->VERSION : 'dev';

  return "$class/$version";
}

sub uri { shift->{upload_uri} || $UPLOAD_URI }
sub target { shift->{target} || 'PAUSE' }

sub _upload {
  my $self = shift;
  my $file = shift;

  $self->log("registering upload with " . $self->target . " web server");

  my $agent = LWP::UserAgent->new;
  $agent->agent( $self->_ua_string );

  $agent->env_proxy;
  $agent->proxy(http => $self->{http_proxy}) if $self->{http_proxy};

  my $uri = $self->{upload_uri} || $UPLOAD_URI;

  my $type = 'form-data';
  my %content = (
    HIDDENNAME                        => $self->{user},
    ($self->{subdir} ? (pause99_add_uri_subdirtext        => $self->{subdir}) : ()),
  );

  if ($file =~ m{^https?://}) {
    $type = 'application/x-www-form-urlencoded';
    %content = (
      %content,
      pause99_add_uri_httpupload        => '',
      pause99_add_uri_uri               => $file,
      SUBMIT_pause99_add_uri_uri        => " Upload this URL ",
    );
  } else {
    %content = (
      %content,
      CAN_MULTIPART                     => 1,
      pause99_add_uri_upload            => File::Basename::basename($file),
      pause99_add_uri_httpupload        => [ $file ],
      pause99_add_uri_uri               => '',
      SUBMIT_pause99_add_uri_httpupload => " Upload this file from my disk ",
    );
  }

  my $request = POST(
    $uri,
    Content_Type => $type,
    Content      => \%content,
  );

  $request->authorization_basic($self->{user}, $self->{password});

  my $DEBUG_METHOD = $ENV{CPAN_UPLOADER_DISPLAY_HTTP_BODY}
                   ? 'as_string'
                   : 'headers_as_string';

  $self->log_debug(
    "----- REQUEST BEGIN -----\n" .
    $request->$DEBUG_METHOD . "\n" .
    "----- REQUEST END -------\n"
  );

  # Make the request to the PAUSE web server
  $self->log("POSTing upload for $file to $uri");
  my $response = $agent->request($request);

  # So, how'd we do?
  if (not defined $response) {
    die "Request completely failed - we got undef back: $!";
  }

  if ($response->is_error) {
    if ($response->code == RC_NOT_FOUND) {
      die "PAUSE's CGI for handling messages seems to have moved!\n",
        "(HTTP response code of 404 from the ", $self->target, " web server)\n",
        "It used to be: ", $uri, "\n",
        "Please inform the maintainer of $self.\n";
    } else {
      die "request failed with error code ", $response->code,
        "\n  Message: ", $response->message, "\n";
    }
  } else {
    $self->log_debug($_) for (
      "Looks OK!",
      "----- RESPONSE BEGIN -----\n" .
      $response->$DEBUG_METHOD . "\n" .
      "----- RESPONSE END -------\n"
    );

    $self->log($self->target . " add message sent ok [" . $response->code . "]");
  }
}


#pod =method new
#pod
#pod   my $uploader = CPAN::Uploader->new(\%arg);
#pod
#pod This method returns a new uploader.  You probably don't need to worry about
#pod this method.
#pod
#pod Valid arguments are the same as those to C<upload_file>.
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;

  $arg->{$_} or Carp::croak("missing $_ argument") for qw(user password);
  bless $arg => $class;
}

#pod =method read_config_file
#pod
#pod   my $config = CPAN::Uploader->read_config_file( $filename );
#pod
#pod This reads the config file and returns a hashref of its contents that can be
#pod used as configuration for CPAN::Uploader.
#pod
#pod If no filename is given, it looks for F<.pause> in the user's home directory
#pod (from the env var C<HOME>, or the current directory if C<HOME> isn't set).
#pod
#pod See L<cpan-upload/CONFIGURATION> for the config format.
#pod
#pod =cut

sub read_config_file {
  my ($class, $filename) = @_;

  unless (defined $filename) {
    my $home  = File::HomeDir->my_home || '.';
    $filename = File::Spec->catfile($home, '.pause');

    return {} unless -e $filename and -r _;
  }

  my %conf;
  if ( eval { require Config::Identity } ) {
    %conf = Config::Identity->load($filename);
    $conf{user} = delete $conf{username} unless $conf{user};
  }
  else { # Process .pause manually
    open my $pauserc, '<', $filename
      or die "can't open $filename for reading: $!";

    while (<$pauserc>) {
      chomp;
      if (/BEGIN PGP MESSAGE/ ) {
        Carp::croak "$filename seems to be encrypted. "
          . "Maybe you need to install Config::Identity?"
      }

      next unless $_ and $_ !~ /^\s*#/;

      my ($k, $v) = /^\s*(\w+)\s+(.+)$/;
      Carp::croak "multiple enties for $k" if $conf{$k};
      $conf{$k} = $v;
    }
  }

  # minimum validation of arguments
  Carp::croak "Configured user has trailing whitespace"
    if defined $conf{user} && $conf{user} =~ /\s$/;
  Carp::croak "Configured user contains whitespace"
    if defined $conf{user} && $conf{user} =~ /\s/;

  return \%conf;
}

#pod =method log
#pod
#pod   $uploader->log($message);
#pod
#pod This method logs the given string.  The default behavior is to print it to the
#pod screen.  The message should not end in a newline, as one will be added as
#pod needed.
#pod
#pod =cut

sub log {
  shift;
  print "$_[0]\n"
}

#pod =method log_debug
#pod
#pod This method behaves like C<L</log>>, but only logs the message if the
#pod CPAN::Uploader is in debug mode.
#pod
#pod =cut

sub log_debug {
  my $self = shift;
  return unless $self->{debug};
  $self->log($_[0]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Uploader - upload things to the CPAN

=head1 VERSION

version 0.103014

=head1 METHODS

=head2 upload_file

  CPAN::Uploader->upload_file($file, \%arg);

  $uploader->upload_file($file);

Valid arguments are:

  user        - (required) your CPAN / PAUSE id
  password    - (required) your CPAN / PAUSE password
  subdir      - the directory (under your home directory) to upload to
  http_proxy  - uri of the http proxy to use
  upload_uri  - uri of the upload handler; usually the default (PAUSE) is right
  debug       - if set to true, spew lots more debugging output
  retries     - number of retries to perform on upload failure (5xx response)
  retry_delay - number of seconds to wait between retries

This method attempts to actually upload the named file to the CPAN.  It will
raise an exception on error.

=head2 new

  my $uploader = CPAN::Uploader->new(\%arg);

This method returns a new uploader.  You probably don't need to worry about
this method.

Valid arguments are the same as those to C<upload_file>.

=head2 read_config_file

  my $config = CPAN::Uploader->read_config_file( $filename );

This reads the config file and returns a hashref of its contents that can be
used as configuration for CPAN::Uploader.

If no filename is given, it looks for F<.pause> in the user's home directory
(from the env var C<HOME>, or the current directory if C<HOME> isn't set).

See L<cpan-upload/CONFIGURATION> for the config format.

=head2 log

  $uploader->log($message);

This method logs the given string.  The default behavior is to print it to the
screen.  The message should not end in a newline, as one will be added as
needed.

=head2 log_debug

This method behaves like C<L</log>>, but only logs the message if the
CPAN::Uploader is in debug mode.

=head1 ORIGIN

This code is mostly derived from C<cpan-upload-http> by Brad Fitzpatrick, which
in turn was based on C<cpan-upload> by Neil Bowers.  I (I<rjbs>) didn't want to
have to use a C<system> call to run either of those, so I refactored the code
into this module.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Barbie Christian Walde David Caldwell Golden fREW Schmidt Gabor Szabo Graham Knop Kent Fredric Mark Fowler Mike Doherty perlancar (@netbook-zenbook-ux305) Ricardo Signes Steven Haryanto (on Asus Zenbook) sungo Torsten Raudssus Vincent Pit

=over 4

=item *

Barbie <barbie@missbarbell.co.uk>

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

David Caldwell <david@porkrind.org>

=item *

David Golden <dagolden@cpan.org>

=item *

fREW Schmidt <frioux@gmail.com>

=item *

Gabor Szabo <szabgab@gmail.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

perlancar (@netbook-zenbook-ux305) <perlancar@gmail.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Steven Haryanto (on Asus Zenbook) <stevenharyanto@gmail.com>

=item *

sungo <sungo@sungo.us>

=item *

Torsten Raudssus <github@raudssus.de>

=item *

Vincent Pit <perl@profvince.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
