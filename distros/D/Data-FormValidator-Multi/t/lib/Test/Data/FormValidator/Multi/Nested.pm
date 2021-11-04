use warnings;
use strict;

package # Hide from PAUSE
  Test::Data::FormValidator::Multi::Nested;

use base qw(Test::Data::FormValidator::Multi);
use Test::More;
use Data::Dumper;

sub nested : Test(3) {
  my $self = shift;

  my $data = $self->skeleton_data;
  my $dfv  = $self->nested_validator;

  $data->{hash_in_hash}{foo}{bar} = $self->timezones(
    [ 999, 'America/New_York',    'Home',  '01/01', '23:59'],
    [ 111, 'America/Los_Angeles', 'L. A.', 'x01/01', '20:59'],
  );
  delete $data->{hash_in_hash}{foo}{foo};

  isa_ok(
    my $results = $self->{results} = $dfv->check($data)
      =>
    'Data::FormValidator::Results' => '$results'
  );

  ok(! $results->success, 'data is invalid');

  is_deeply( $results->to_json, {
    'dashboard' => 'ERROR: MUST BE POSITIVE',
    'hash_in_hash' => {
      'foo' => {
        'bar' => [
          undef,
          {
            'date' => 'ERROR: DATE FORMAT MUST BE MM/DD'
          }
        ],
        'foo' => 'ERROR: FIELD IS REQUIRED'
      }
    }
  }, 'got expected json');
}

sub nested_validator {
  my $self = shift;

  my $profile = $self->main_profile;
  $profile->add( 'hash_in_hash',
    required => 1,
  );

  my $dfv = $self->skeleton_validator;
  $dfv->{profiles}{profile} = $profile->profile;

  $dfv->{profiles}{subprofiles}{hash_in_hash} = {
    profile     => $self->meta_profile->profile,
    subprofiles => {
      foo => {
        profile     => $self->meta_profile->profile,
        subprofiles => {
          bar => $self->timezones_profile->profile,
        }
      }
    }
  };

  return $dfv;
}

1;
