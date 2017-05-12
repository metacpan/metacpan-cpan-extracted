#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 33;

sub clean_inc {
    my @packages = qw(
      Circle
      Class::Trait
      Class::Trait::Base
      Class::Trait::Config
      Extra::TSpouse
      Polygamy
      TBomb
      TDisallowed
      TSpouse
      TestTraits
    );

    foreach my $package (@packages) {
        no strict 'refs';
        foreach my $glob ( keys %{"${package}::"} ) {
            undef *{"${package}::$glob"};
        }
    }
    my @includes = map { s{::}{/}g; "$_.pm" } @packages;
    delete @INC{@includes};

}

local $SIG{__WARN__} = sub {
    my $message = shift;
    return if $message =~ /Too late to run INIT block/;
    warn $message;
};

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => ( '../lib', 'test_lib' );
}

#
# Note that Class::Trait->initialize is only being called because the code is
# eval'ed and the INIT phase does not run.  This is also necessary when
# running under mod_perl
#

#
# TSpouse: fuse explode
# TBomb:   fuse explode
#

eval <<'END_PACKAGE';
package TestTraits;
use Class::Trait ( 'TSpouse', 'TBomb' );
Class::Trait->initialize;
END_PACKAGE

ok my $error = $@, 'Trying to load conflicting traits should fail';
like $error, qr/\QPackage TestTraits has conflicting methods (explode fuse)/,
  '... with an appropriate error message';

#
# TSpouse:  explode
# TBomb:    fuse explode
#

clean_inc();
eval <<'END_PACKAGE';
package TestTraits;
use Class::Trait ( 
    'TSpouse' => { exclude => ['fuse'] },
    'TBomb'
);
Class::Trait->initialize;
END_PACKAGE

ok $error = $@, 'Trying to load conflicting traits should fail';
like $error, qr/\QPackage TestTraits has conflicting methods (explode)/,
  '... with an appropriate error message';

#
# TSpouse:  explode
# TBomb:    fuse
#

clean_inc();
eval <<'END_PACKAGE';
package TestTraits;
use Class::Trait ( 
    'TSpouse' => { exclude => ['fuse']    },
    'TBomb'   => { exclude => ['explode'] },
);
Class::Trait->initialize;
END_PACKAGE

ok !$@, 'Trying to load properly configured traits should not fail';
can_ok 'TestTraits', 'fuse';
is TestTraits->fuse, 'Bomb fuse',
  '... and it should pull in the correct fuse() method';
can_ok 'TestTraits', 'explode';
is TestTraits->explode, 'Spouse explodes',
  '... and it should pull in the correct explode() method';

clean_inc();
eval <<'END_PACKAGE';
package TestTraits;
use Class::Trait ( 
    'TSpouse' => { exclude => 'explode' }
);
Class::Trait->initialize;
sub explode { 'TestTraits explode' }
END_PACKAGE

ok !$@, 'Trying to load properly configured traits should not fail';
can_ok 'TestTraits', 'fuse';
is TestTraits->fuse, 'Spouse fuse',
  '... and it should pull in the correct fuse() method';
can_ok 'TestTraits', 'explode';
is TestTraits->explode, 'TestTraits explode',
  '... and it should not pull in explicitly defined methods';

#
# Extra::TSpouse: fuse explode [ requires lawyer() ]
#           does: Original::TSpouse: fuse explode [ requires alimony() ]
#

clean_inc();
eval <<'END_PACKAGE';
package Polygamy;
use Class::Trait 'Extra::TSpouse';
Class::Trait->initialize;
sub alimony {}
END_PACKAGE

ok $@,   'Trying to load a trait which does not meet requirements should fail';
like $@, qr/\QRequirement (lawyer) for Extra::TSpouse not in Polygamy\E/,
  '... with an appropriate error message';

#
# Extra::TSpouse: fuse explode [ requires lawyer() ]
#           does: Original::TSpouse: fuse explode [ requires alimony() ]
#

clean_inc();
eval <<'END_PACKAGE';
package Polygamy;
use Class::Trait 'Extra::TSpouse';
Class::Trait->initialize;
sub lawyer {}
END_PACKAGE

ok $@,   'Trying to load a trait which does not meet requirements should fail';
like $@, qr/\QRequirement (alimony) for Extra::TSpouse not in Polygamy\E/,
  '... and @REQUIREMENTS should bubble up correctly';
clean_inc();

#
# Extra::TSpouse: fuse explode [requires lawyer()]
#           does: TSpouse: fuse explode
#

clean_inc();
eval <<'END_PACKAGE';
package Polygamy;
use Class::Trait 'Extra::TSpouse';
Class::Trait->initialize;
sub lawyer {}
sub alimony {}
END_PACKAGE

ok !$@,
'Trying to load a trait which overrides an included traits methods should succeed';

can_ok Polygamy => 'explode';
is Polygamy->explode, 'Extra spouse explodes',
  '... and we should have the correct method';

can_ok Polygamy => 'fuse';
is Polygamy->fuse, 'Spouse fuse',
  '... and we should get the composed trait method';

clean_inc();
eval <<'END_PACKAGE';
package TestTraits;
use Class::Trait ( 
    'TSpouse' => { exclude => ['fuse']    },
    'TBomb'   => { exclude => ['explode'] },
);
Class::Trait->rename_does('%%');
Class::Trait->initialize;
END_PACKAGE

ok $@,   'Trying to rename does() to an illegal method name should fail';
like $@, qr/\QIllegal name for trait relation method (%%)/,
  '... telling us that it\'s an illegal method name';

clean_inc();
eval <<'END_PACKAGE';
package TestTraits;
use Class::Trait 'Circle';
Class::Trait->initialize;
END_PACKAGE

ok $@, 'Trying to use a non-trait as a trait should fail';
like $@,
  qr/\QCircle is not a proper trait (inherits from Class::Trait::Base)\E/,
  '... telling us that it\'s not a trait';

clean_inc();
eval <<'END_PACKAGE';
package TestTraits;
use Class::Trait 'TDisallowed';
Class::Trait->initialize;
END_PACKAGE

ok $@, 'Trying to use a trait with a disallowed method should fail';
like $@,
  qr/\QTrait TDisallowed attempted to implement disallowed method DESTROY\E/,
  '... telling us what the disallowed method is';

clean_inc();
eval <<'END_PACKAGE';
package TestTraits;
use Class::Trait ( 
    'TSpouse' => { exclude => ['fuse', 'no_such_method' ]    },
    'TBomb'   => { exclude => ['explode'] },
);
Class::Trait->initialize;
END_PACKAGE

ok $@, 'Attempting to exclude a non-existent method should fail';
like $@,
qr/\QAttempt to exclude method (no_such_method) that is not in trait (TSpouse)\E/,
  '... telling us which non-existent method we tried to exclude';

clean_inc();
eval <<'END_PACKAGE';
package TestTraits;
use Class::Trait ( 
    'TSpouse' => { alias   => { no_such_method => 'fuse' } },
    'TBomb'   => { exclude => ['explode'] },
);
Class::Trait->initialize;
END_PACKAGE

ok $@, 'Attempting to alias a non-existent method should fail';
like $@,
qr/\QAttempt to alias method (no_such_method) that is not in trait (TSpouse)\E/,
  '... telling us which non-existent method we tried to alias';

