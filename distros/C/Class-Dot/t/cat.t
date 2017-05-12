# $Id: cat.t 24 2007-10-29 17:15:19Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/branches/stable-1.5.0/t/cat.t $
# $Revision: 24 $
# $Date: 2007-10-29 18:15:19 +0100 (Mon, 29 Oct 2007) $
use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use English qw( -no_match_vars );
use lib 'lib';
use lib $Bin;
use lib 't';
use lib "$Bin/../lib";

our $THIS_TEST_HAS_TESTS = 61;

plan( tests => $THIS_TEST_HAS_TESTS );

use_ok('Cat');
use_ok('Class::Dot');

eval 'use Class::Dot qw( -new :std :weird )';
my $wanted_err_msg = quotemeta
      'Only one export class can be used. '.
      '(Used already: [:std] now: [:weird])'
;
like( $EVAL_ERROR, qr/$wanted_err_msg/, 'only one export class allowed');

my $properties_for_cat
    = Class::Dot->properties_for_class('Cat');

my %should_have = map { $_ => 1 } qw(
    gender memory fur action dna brain colour state family
);

is_deeply($properties_for_cat, \%should_have);

ok(ref $properties_for_cat eq 'HASH', 'properties_for_class(Cat)');
ok(scalar keys %{ $properties_for_cat }, 'properties_for_class(Cat)');


my $albert = new Cat({
    gender => 'male',
    memory => {
        name => 'Albert',
    },
    fur    => [
        qw( short thin shiny )
    ],
    action => 'hunting',
    nonexising_property => 'should_work',
});

for my $property (keys %{ $properties_for_cat }) {
    can_ok( $albert,        $property );
    can_ok( $albert, 'set_'.$property );
}

can_ok($albert, 'new');
can_ok($albert, 'BUILD');

ok(ref Class::Dot->properties_for_class($albert) eq 'HASH');
ok(scalar keys %{ Class::Dot->properties_for_class($albert) });

is( $albert->test_new, 'BUILD and -new works!', '->BUILD' );

is($albert->gender, 'male', 'cat->gender');
is_deeply($albert->memory, {name => 'Albert'}, 'cat->memory');
is_deeply($albert->fur,    [qw( short thin shiny )], 'cat->fur');
is( $albert->action, 'hunting', 'cat->action');

my $lucy = new Cat({gender => 'female'});
ok(ref Class::Dot->properties_for_class($lucy) eq 'HASH');
ok(scalar keys %{ Class::Dot->properties_for_class($lucy) });

for my $property (keys %{ $properties_for_cat }) {
    can_ok( $lucy,        $property );
    can_ok( $lucy, 'set_'.$property );
}
can_ok($lucy, 'new');
can_ok($lucy, 'BUILD');
is( $lucy->test_new, 'BUILD and -new works!', '->BUILD' );
is($lucy->gender, 'female', 'cat->gender');
$lucy->memory->{name} = 'Lucy';
$lucy->state->{instinct} = 'tired';
$lucy->set_fur([qw(fluffy long)]);
$lucy->set_action('sleeping');

is_deeply( $lucy->memory, { name     => 'Lucy'  }, 'cat->memory');
is_deeply( $lucy->state,  { instinct => 'tired' }, 'cat->state' );
 
push @{ $lucy->family   }, [$albert];
push @{ $albert->family }, [$lucy  ];

is_deeply( $lucy->family,   [[$albert]], 'cat->family');
is_deeply( $albert->family, [[$lucy  ]], 'cat->family');


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
