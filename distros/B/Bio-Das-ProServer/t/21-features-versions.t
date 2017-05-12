use strict;
use warnings;
use Test::More tests => 3;
my $sa = SA::FeaturesStub->new();

my $expected_response = qq(<SEGMENT id="seg-1" version="v1" start="100" stop="200">\n<FEATURE id="feat-1"><TYPE id="t" /><METHOD id="m" /><START>100</START><END>200</END></FEATURE>\n</SEGMENT>\n);
my $response = $sa->das_features({'features' => ['feat-1']});
is_deeply($response, $expected_response, "segment version in separate method");

$expected_response = qq(<SEGMENT id="seg-2" version="v2" start="200" stop="300">\n<FEATURE id="feat-2"><TYPE id="t" /><METHOD id="m" /><START>200</START><END>300</END></FEATURE>\n</SEGMENT>\n);
$response = $sa->das_features({'features' => ['feat-2']});
is_deeply($response, $expected_response, "segment version in feature hash");

$expected_response = qq(<SEGMENT id="seg-3" start="300" stop="400">\n<FEATURE id="feat-3"><TYPE id="t" /><METHOD id="m" /><START>300</START><END>400</END></FEATURE>\n</SEGMENT>\n);
$response = $sa->das_features({'features' => ['feat-3']});
is_deeply($response, $expected_response, "segment version not provided");

package SA::FeaturesStub;
use base qw(Bio::Das::ProServer::SourceAdaptor);

sub init {
  my $self = shift;
  $self->{'capabilities'}{'features'} = '1.1';
  $self->{'features'} = [
    {
     'segment'         => 'seg-1',
     # version specified in method
     'start'           => '100',
     'end'             => '200',
     'id'              => 'feat-1',
     'type'            => 't',
     'method'          => 'm',
    },
    {
     'segment'         => 'seg-2',
     'segment_version' => 'v2', # version here instead of separate method
     'start'           => '200',
     'end'             => '300',
     'id'              => 'feat-2',
     'type'            => 't',
     'method'          => 'm',
    },
    {
     'segment'         => 'seg-3',
     # no version at all
     'start'           => '300',
     'end'             => '400',
     'id'              => 'feat-3',
     'type'            => 't',
     'method'          => 'm',
    },
   ];
  $self->{'versions'} = {
    'seg-1' => 'v1',
   };
}

sub build_features {
  my ($self, $params) = @_;
  if ($params->{'feature_id'}) {
    my %all = map { $_->{'id'} => $_ } @{ $self->{'features'} };
    return ($all{$params->{'feature_id'}});
  } elsif ($params->{'group_id'}) {
    return ();
  } else {
    return ();
  }
}

sub segment_version {
  my ($self, $seg) = @_;
  return $self->{'versions'}->{$seg};
}

1;
__DATA__
seg-1  feat-1  grp-1  
