use strict;
use warnings;
use Test::More tests => 2;
my $sa = SA::FeaturesStub->new();

my $expected_response = qq(<SEGMENT id="seg-1" start="100" stop="400">\n<FEATURE id="grp-1"><TYPE id="t2" /><METHOD id="" /><PART id="feat-1" /><PART id="feat-2" /><PART id="feat-3" /></FEATURE><FEATURE id="feat-1"><TYPE id="t" /><METHOD id="m" /><START>100</START><END>200</END><PARENT id="grp-1" /></FEATURE><FEATURE id="feat-2"><TYPE id="t" /><METHOD id="m" /><START>200</START><END>300</END><PARENT id="grp-1" /></FEATURE><FEATURE id="feat-3"><TYPE id="t" /><METHOD id="m" /><START>300</START><END>400</END><PARENT id="grp-1" /></FEATURE>\n</SEGMENT>\n);
my $response = $sa->das_features({'segments' => ['seg-1:100,400']});
is_deeply($response, $expected_response, "convert groups to parents");

$expected_response = qq(<SEGMENT id="seg-1" start="1">\n<FEATURE id="grp-1"><TYPE id="t2" /><METHOD id="" /><PART id="feat-1" /><PART id="feat-2" /><PART id="feat-3" /></FEATURE><FEATURE id="feat-1"><TYPE id="t" /><METHOD id="m" /><START>100</START><END>200</END><PARENT id="grp-1" /></FEATURE><FEATURE id="feat-2"><TYPE id="t" /><METHOD id="m" /><START>200</START><END>300</END><PARENT id="grp-1" /></FEATURE><FEATURE id="feat-3"><TYPE id="t" /><METHOD id="m" /><START>300</START><END>400</END><PARENT id="grp-1" /></FEATURE>\n</SEGMENT>\n);
$response = $sa->das_features({'features' => ['grp-1']});
is_deeply($response, $expected_response, "query by group ID");

package SA::FeaturesStub;
use base qw(Bio::Das::ProServer::SourceAdaptor);

sub init {
  my $self = shift;
  $self->{'capabilities'}{'features'} = 1.0; # legacy implementation
  $self->{'features'} = [
    {
     'segment'         => 'seg-1',
     'start'           => '100',
     'end'             => '200',
     'id'              => 'feat-1',
     'type'            => 't',
     'method'          => 'm',
     'group'           => 'grp-1',
     'grouptype'       => 't2',
    },
    {
     'segment'         => 'seg-1',
     'start'           => '200',
     'end'             => '300',
     'id'              => 'feat-2',
     'type'            => 't',
     'method'          => 'm',
     'group'           => 'grp-1',
     'grouptype'       => 't2',
    },
    {
     'segment'         => 'seg-1',
     'start'           => '300',
     'end'             => '400',
     'id'              => 'feat-3',
     'type'            => 't',
     'method'          => 'm',
     'group'           => 'grp-1',
     'grouptype'       => 't2',
    },
   ];
}

sub build_features {
  my ($self, $params) = @_;
  my @f;
  if ($params->{'feature_id'}) {
    map { $_->{'id'} eq $params->{'feature_id'} && push @f, $_; } @{ $self->{'features'} };
  } elsif ($params->{'group_id'}) {
    map { $_->{'group'} eq $params->{'group_id'} && push @f, $_; } @{ $self->{'features'} };
  } else {
    map { $_->{'segment'} eq $params->{'segment'} && push @f, $_; } @{ $self->{'features'} };
  }
  return @f;
}

1;