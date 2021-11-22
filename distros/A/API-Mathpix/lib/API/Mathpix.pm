package API::Mathpix;

use Moose;
use JSON::PP;
use LWP::UserAgent;
use HTTP::Request;
use MIME::Base64;
use Algorithm::LeakyBucket;

use API::Mathpix::Response;

has 'app_id' => (
  is  => 'rw',
  isa => 'Str'
);

has 'app_key' => (
  is  => 'rw',
  isa => 'Str'
);

has '_ua' => (
  is  => 'rw',
  isa => 'LWP::UserAgent'
);

has '_bucket' => (
  is  => 'rw',
  isa => 'Algorithm::LeakyBucket'
);

=head1 NAME

API::Mathpix - Use the API of Mathpix

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    my $mathpix = API::Mathpix->new({
      app_id  => $ENV{MATHPIX_APP_ID},
      app_key => $ENV{MATHPIX_APP_KEY},
    });

    my $response = $mathpix->process({
      src     => 'https://mathpix.com/examples/limit.jpg',
    });

    print $response->text;


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

sub BUILD {
  my ($self) = @_;

  $self->_ua(
    LWP::UserAgent->new(
      timeout => 30,
    )
  );

  $self->_bucket(
    Algorithm::LeakyBucket->new(
      ticks   => 200,
      seconds => 60
    )
  );

}

=head2 process

=cut

sub process {
  my ($self, $opt) = @_;


  if (-f $opt->{src}) {

    my $contents = do {
      open my $fh, $opt->{src} or die '...';
      local $/;
      <$fh>;
    };

    $opt->{src} = "data:image/jpeg;base64,'".encode_base64($contents)."'";
  }

  my $url = 'https://api.mathpix.com/v3/text';

  my $headers = [
    'Content-Type'  => 'application/json',
    ':app_id'       => $self->app_id,
    ':app_key'      => $self->app_key,
  ];

  my $encoded_data = encode_json($opt);

  my $r = HTTP::Request->new('POST', $url, $headers, $encoded_data);

  my $response;

  if ($self->_bucket->tick) {
    $response = $self->_ua->request($r);
  }
  else {
    warn 'Rate limiting !';
  }

  if ($response->is_success) {
      my $data = decode_json($response->decoded_content);
      return API::Mathpix::Response->new($data);
  }
  else {
      warn $response->status_line;
  }


}

=head1 AUTHOR

Eriam Schaffter, C<< <eriam at mediavirtuel.com> >>

=head1 BUGS & SUPPORT

Please go directly to Github

    https://github.com/eriam/API-Mathpix

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Eriam Schaffter.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;
