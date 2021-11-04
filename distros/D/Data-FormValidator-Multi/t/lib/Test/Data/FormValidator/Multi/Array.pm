use warnings;
use strict;

package # Hide from PAUSE
  Test::Data::FormValidator::Multi::Array;

use base qw(Test::Data::FormValidator::Multi);
use Test::More;

sub array : Test(2) {
  my $self = shift;

  my $data = [
    $self->skeleton_data,
    $self->skeleton_data,
    $self->skeleton_data,
  ];

  # make the second element valid
  $data->[1]{dashboard} = 11;

  my $dfv = Data::FormValidator::Multi->new({
    profile     => $self->main_profile->profile,
    subprofiles => {
      timezones  => $self->timezones_profile->profile,
      meta       => $self->meta_profile->profile,
    }
  });

  isa_ok(
    my $results = $self->{results} = $dfv->check($data)
      =>
    'Data::FormValidator::Results' => '$results'
  );

  ok(! $results->success, 'data is invalid');
}


1;
