use strict;
use warnings;

use FindBin;
use Test::More;
use Test::Exception;

use lib "$FindBin::Bin/lib";

my $awesome_robot = 0;
my $first = 0;
my $last = 0;

BEGIN {
  package MyModule::Plugin::TestActions;

  use Class::C3::Componentised::ApplyHooks;

  BEFORE_APPLY { $awesome_robot++; $first = $awesome_robot };
  BEFORE_APPLY { $awesome_robot++; $first = $awesome_robot };
  AFTER_APPLY  { $awesome_robot++;  $last  = $awesome_robot };

  1;
}

BEGIN {
  package MyModule::Plugin::TestActionDie;

  use Class::C3::Componentised::ApplyHooks
    -before_apply => sub { die 'this component is not applicable (yuk yuk yuk)' };

  1;
}

BEGIN {
  package MyModule::Plugin::TestActionLoadFrew;

  use Class::C3::Componentised::ApplyHooks;

  BEFORE_APPLY { $_[0]->load_components('TestActionFrew') };

  1;
}

BEGIN {
  package MyModule::Plugin::TestActionFrew;
  sub frew { 1 }
  1;
}

use_ok('MyModule');
is( $first, 0, 'first starts at zero' );
is( $last, 0, 'last starts at zero' );

MyModule->load_components('TestActions');
is( $first, 2, 'first gets value of 1 (it runs first)' );
is( $last, 3, 'last gets value of 2 (it runs last)' );

dies_ok { MyModule->load_components('TestActionDie') } 'die from BEFORE_APPLY works';

dies_ok { MyModule->frew } 'fREW is not loaded';
MyModule->load_components('TestActionLoadFrew');
is( MyModule->frew, 1, 'fREW is loaded' );

done_testing;
