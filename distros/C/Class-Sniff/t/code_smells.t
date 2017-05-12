#!/usr/bin/perl

use strict;
use warnings;

use Test::Most tests => 28;
use Class::Sniff;

{

    package Abstract;

    sub new {
        my ( $class, $arg_for ) = @_;
        #
        # Forcing this to be a long method to force a 'long method' report
        #
        #
        #
        #
        #
        #
        my $self = bless {} => $class;
        return $self;
    }

    sub foo { }
    sub bar { }
    sub baz { }

    package Child1;
    our @ISA = 'Abstract';
    use Carp 'croak';
    sub foo { 1 }

    package Child2;
    our @ISA = 'Abstract';
    sub foo { 1 }
    sub bar { }

    package Grandchild;
    our @ISA = qw<Child1 Child2>;
    sub foo  { }    # diamond inheritance
    sub bar  { }    # Not a problem because it's inherited through 1 path
    sub quux { }    # no inheritance
}

can_ok 'Class::Sniff', 'new';
my $sniff = Class::Sniff->new( { class => 'Grandchild', method_length => 10 } );
can_ok $sniff, 'report';
ok my $report = $sniff->report, '... and it should return a report of potential issues';

like $report, qr/Report for class: Grandchild/,
    'The report should have a title';

my $bar = qr/[^|]*\|[^|]*/;
my $bar_newline = qr/$bar \| \s* $bar/x;
like $report, qr/Overridden Methods/,
    'The report should identify overridden methods';
like $report, qr/bar $bar Grandchild $bar_newline Abstract $bar_newline Child2 /,
    '... identifying the method and the class(es) it is overridden in';

like $report, qr/Unreachable Methods/,
    'The report should identify unreachable methods';
like $report, qr/bar $bar Child2/,
    '... identifying the method and the class(es) it is unreachable in';

like $report, qr/Multiple Inheritance/,
    'The report should identify multiple inheritance';
like $report, qr/Grandchild $bar Child1 $bar_newline Child2 /x,
    '... identifying all parent classes';

like $report, qr/Exported Subroutines/,
    'The report should identify exported subroutines';
like $report,
  qr/Child1 $bar croak $bar Carp $bar_newline/x,
  '... and not miss any';

like $report, qr/Duplicate Methods/,
    'The report should identify duplicate methods';
like $report,
    qr/Grandchild::quux     $bar Abstract::bar
                 $bar_newline Abstract::baz
                 $bar_newline Abstract::foo
                 $bar_newline Child2::bar
                 $bar_newline Grandchild::bar
                 $bar_newline Grandchild::foo $bar \n
    \| \s* Child2::foo   $bar Child1::foo/x,
  '... and not miss any';
like $report, qr/Long Methods/,
    'The report should identify long methods';
like $report,
    qr/Abstract::new $bar \d+/x,
  '... and not miss any';

# Multiple search paths through a hierarchy are a smell because it implies MI
# and possibly unreachable methods.

can_ok $sniff, 'paths';
my $expected_paths = [
    [ 'Grandchild', 'Child1', 'Abstract' ],
    [ 'Grandchild', 'Child2', 'Abstract' ]
];
eq_or_diff [$sniff->paths], $expected_paths,
    '... and it should report inheritance paths';

{
    package One;
    our @ISA = qw/Two Three/;
    package Two;
    package Three;
    our @ISA = qw/Four Six/;
    package Four;
    our @ISA = 'Five';
    package Five;
    package Six;
}
#    5
#    |
#    4  6
#    | /
# 2  3
#  \ |
#    1
# 1 -> 2
# 1 -> 3 -> 4 -> 5
# 1 -> 3 -> 6
my $complex_sniff = Class::Sniff->new({class => 'One'});
$expected_paths = [
    [ 'One', 'Two' ],
    [ 'One', 'Three', 'Four', 'Five' ],
    [ 'One', 'Three', 'Six' ]
];
eq_or_diff [$complex_sniff->paths], $expected_paths,
    '... even for convoluted hierarchies';

# overridden methods aren't really a smell, but a programmer can compare the
# classes they're overridden in (listed in search order) against the paths to
# understand why something can't be reached.

can_ok $sniff, 'overridden';
my $expected_overridden = {
    'bar' => [ 'Grandchild', 'Abstract', 'Child2' ],
    'foo' => [ 'Grandchild', 'Child1',   'Abstract', 'Child2' ]
};
eq_or_diff $sniff->overridden, $expected_overridden,
  '... and it should return an HoA with overridden methods and the classes';

# 'unreachable' methods can be called directly, but this lists the classes
# overridden methods are listed in which won't allow them to be called.
# We don't account for AUTOLOAD.

can_ok $sniff, 'unreachable';
my $expected_unreachable = [
    'Child2::bar',
    'Child2::foo',
];

eq_or_diff [sort $sniff->unreachable], $expected_unreachable,
  '... and it should return an HoA with unreachable methods and the classes';

can_ok $sniff, 'multiple_inheritance';
eq_or_diff [$sniff->multiple_inheritance], ['Grandchild'],
    '... and it should return classes with more than one parent';
eq_or_diff [$complex_sniff->multiple_inheritance],
    [qw/One Three/],
    '... in the order their found in the hierarchy';

{
    package Platypus;
    our @ISA = qw<SpareParts Duck>;
    package Duck;
    our @ISA = 'SpareParts';
    sub quack {}
    package SpareParts;
    our @ISA = 'Animal';
    sub quack {}
    package Animal;
}

#         Animal
#           |
#      SpareParts
#       |    |   
#       |   Duck 
#       |    |   
#      Platypus

my $platypus = Class::Sniff->new({
    class     => 'Platypus',
    universal => 1,
});
eq_or_diff [$platypus->unreachable], ['Duck::quack'],
    'Unbalanced inheritance graphs are parsed properly';

# Circular inheritance really breaks things!
if ( $] < 5.010000 ) {
    eval <<'    END';
    package Un;
    our @ISA = 'Deux';
    package Deux;
    our @ISA = 'Trois';
    package Trois;
    our @ISA = 'Un';
    END
}

SKIP: {
    skip 'Circular inheritance is now fatal in 5.10 and up', 1
        if $] >= 5.010000;
    throws_ok { Class::Sniff->new({class => 'Un'}) }
        qr/^Circular path found/,
    'Circular paths should throw a fatal error';
}
