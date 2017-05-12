
use strict;
use warnings;

use Test::More tests => 3;

# ABSTRACT: Expected failures

use CPAN::Changes::Group::Dependencies::Details;

sub is_fail($$) {
  my ( $reason, $sub ) = @_;
  local $@;
  my $failed = 1;
  eval {
    $sub->();
    undef $failed;
  };
  if ($failed) {
    @_ = ( "Got expected failure: " . $reason );
    goto &pass;
  }
  @_ = ( "Missed expected failure: " . $reason );
  goto &fail;
}

is_fail 'has_changes will fail without both prereqs' => sub {
  CPAN::Changes::Group::Dependencies::Details->new(
    'change_type' => "Added",
    'phase'       => 'runtime',
    'type'        => 'requires',
  )->has_changes;
};
is_fail 'has_changes will fail without old_prereqs' => sub {
  CPAN::Changes::Group::Dependencies::Details->new(
    'change_type' => "Added",
    'phase'       => 'runtime',
    'type'        => 'requires',
    'new_prereqs' => {},
  )->has_changes;
};
is_fail 'has_changes will fail without new_prereqs' => sub {
  CPAN::Changes::Group::Dependencies::Details->new(
    'change_type' => "Added",
    'phase'       => 'runtime',
    'type'        => 'requires',
    'old_prereqs' => {},
  )->has_changes;
};
