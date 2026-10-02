package CPAN::Maker::Bootstrapper::Role::PAUSEUpload;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use Data::Dumper;
use English qw(-no_match_vars);
use English;
use File::Basename qw(basename);
use HTTP::Tiny;
use MIME::Base64 qw(encode_base64);
use Role::Tiny;

use Readonly;
Readonly::Scalar our $CRLF => sprintf '%c%c', 0x0d, 0x0a;
Readonly::Scalar our $PAUSE_URL => 'https://pause.perl.org/pause/authenquery?ACTION=add_uri';

########################################################################
sub cmd_publish_to_cpan {
########################################################################
  my ($self) = @_;

  my ( $file, $user, $pass ) = $self->get_args;
  $user //= $ENV{PAUSE_USER};
  $pass //= $ENV{PAUSE_PASSWORD};

  die "ERROR: distribution file is required\n"
    if !$file || !-f $file;

  die "ERROR: PAUSE username is required\n"
    if !$user;

  die "ERROR: PAUSE password is required\n"
    if !$pass;

  open my $fh, '<:raw', $file
    or die "ERROR: could not open $file\n$OS_ERROR";

  my $content = slurp($fh);
  close $fh;

  my $filename = basename($file);

  my @fields = (
    HIDDENNAME                        => uc $user,
    CAN_MULTIPART                     => 1,
    pause99_add_uri_upload            => $filename,
    pause99_add_uri_uri               => q{},
    SUBMIT_pause99_add_uri_httpupload => ' Upload this file from my disk ',
  );

  # boundary must not occur in the payload
  my $boundary;
  do { $boundary = sprintf 'pause%08x%08x', rand 2**32, rand 2**32 } while index( $content, $boundary ) >= 0;

  my $body = q{};

  while ( my ( $name, $value ) = splice @fields, 0, 2 ) {
    $body .= "--$boundary$CRLF" . qq{Content-Disposition: form-data; name="$name"$CRLF$CRLF} . "$value$CRLF";
  }

  $body
    .= "--$boundary$CRLF"
    . qq{Content-Disposition: form-data; name="pause99_add_uri_httpupload"; filename="$filename"$CRLF}
    . "Content-Type: application/gzip$CRLF$CRLF"
    . $content
    . $CRLF
    . "--$boundary--$CRLF";

  my $res = HTTP::Tiny->new( verify_SSL => $TRUE, timeout => 30 )->request(
    POST => $PAUSE_URL,
    { headers => {
        'Content-Type'  => "multipart/form-data; boundary=$boundary",
        'Authorization' => 'Basic ' . encode_base64( "$user:$pass", q{} ),
      },
      content => $body,
    }
  );

  die sprintf "ERROR: upload failed - %s %s\n", $res->{status}, $res->{reason}
    if !$res->{success};

  print {*STDERR} "Successfully uploaded $file for PAUSE_USER $user\n";

  return $SUCCESS;
}

1;
