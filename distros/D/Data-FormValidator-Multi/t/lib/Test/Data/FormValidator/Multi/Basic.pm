use warnings;
use strict;

package # Hide from PAUSE
  Test::Data::FormValidator::Multi::Basic;

use base qw(Test::Data::FormValidator::Multi);
use Test::More;

sub basic : Test(3) {
  my $self = shift;

  my $data = $self->skeleton_data;
  my $dfv  = $self->skeleton_validator;

  delete $data->{timezones}[1]{name};

  isa_ok(
    my $results = $self->{results} = $dfv->check($data)
      =>
    'Data::FormValidator::Results' => '$results'
  );

  ok(! $results->success, 'data is invalid');

  is_deeply( $results->to_json, {
    'dashboard' => 'ERROR: MUST BE POSITIVE',
    'timezones' => [
      undef,
      {
        'name' => 'ERROR: FIELD IS REQUIRED'
      }
    ]
  } => 'got expected value');
}


1;
