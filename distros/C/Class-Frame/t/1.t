#!/usr/bin/perl -w

use strict;

use Test;

BEGIN { plan tests => 16 };

##----------------------------------------------------------------------------
#
# Set up test packages
#
##----------------------------------------------------------------------------

#
# So be it, Jedi . . .
#
package Sith;

use strict;

use base qw( Class::Frame );
use Class::Frame;

DEFINE_FIELDS(
	name => 'Palpatine',
	occupation => 'Sith Lord',
	weapon => [ 'The Force', 'Lightsaber' ]
);

#
# At last we will have our revenge,
# at last we will reveal ourselves to Jedi . . .
#
package DarthMaul;

use strict;

use base qw( Class::Frame );
use Class::Frame;

DEFINE_FIELDS(
	name => 'Darth Maul',
	occupation => 'Sith Apprentice',
	weapon => [ 'Sith Lightsaber' ]
);

#
# I find your lack of faith disturbing (whoooopshhhhh)
#
package DarthVader;

use strict;

use base qw( Class::Frame );
use Class::Frame;

DEFINE_FIELDS(
	name => 'Darth Vader',
	occupation => 'Sith Lord',
	weapon => [ 'Lightsaber' ]
);

#
# I have become more powerfull than any Jedi!
#
package DarthTiranius;

use base qw(Sith);

sub new {
	my $pkg = shift;
    my @args = @_;

    my $self = $pkg->SUPER::new(@args);
    bless $self, $pkg;
}

##----------------------------------------------------------------------------
#
# Start testing
#
##----------------------------------------------------------------------------
package main;

my $emperor = Sith->new();
$emperor->set_name('Palpatine');
my $vader = DarthVader->new();
$vader->set_name('Darth Vader');
my $maul = DarthMaul->new();
$maul->set_name('Darth Maul');

# Check defaults
ok($emperor->get_name_default, 'Palpatine');
ok($emperor->get_occupation_default, 'Sith Lord');
ok($vader->get_name_default, 'Darth Vader');
ok($vader->get_occupation_default, 'Sith Lord');
ok($maul->get_name_default, 'Darth Maul');
ok($maul->get_occupation_default, 'Sith Apprentice');


ok($emperor->name, 'Palpatine');
ok($vader->name, 'Darth Vader');
ok($maul->name, 'Darth Maul');

my $count_dooku = new DarthTiranius(
	name => 'Count Dooku',
	occupation => 'Sith Apprentice'
);
ok($count_dooku->name, 'Count Dooku');
ok($count_dooku->get_name, 'Count Dooku');
$count_dooku->set_occupation('Sith Apprentice');
$count_dooku->set_weapon(['Lightnings','Lightsaber','Dark Side']);
ok(ref $count_dooku->weapon, 'ARRAY');
ok(scalar @{$count_dooku->weapon}, 3);
ok($count_dooku->weapon->[0], 'Lightnings');
ok($count_dooku->weapon->[1], 'Lightsaber');
ok($count_dooku->weapon->[2], 'Dark Side');



