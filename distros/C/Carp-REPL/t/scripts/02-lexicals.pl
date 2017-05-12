#!perl
use strict;
use warnings;

my $pi = 3.1415;
my $pi_ref = \$pi;

my @grades = qw/A B C D F/;
my $grades = [ @grades ];
my $grades2 = \@grades;

my %grade_of =
(
    Abe => 'A',
    Bo  => 'B',
    Cal => 'C',
    Doy => 'D',
    Fun => 'F',
);

my $grade_of = { %grade_of };
my $grade_of2 = \%grade_of;

my $closure = sub
{
    my $person = shift;
    return $grade_of{$person};
};

my $deep =
{
    eidolos =>
    [
        { role => 'Wiz', death => 'ascended' },
        { role => 'Tou', death => 'killed by a soldier' },
        { role => 'Sam', death => 'ascended' },
    ],

    marvin =>
    [
        { role => 'Arc', death => 'ascended' },
        { role => 'Bar', death => 'ascended' },
        { role => 'Cav', death => 'ascended' },
        { role => 'Ran', death => 'killed by a plains centaur' },
    ],
};

my $regex = qr/(bb|[^b]{2})/;

my $object = Point->new(x => 80, y => 24);

die 'You caitiff!';

package Point;

sub new
{
    my $class = shift;
    bless {@_}, $class;
}

sub x
{
    my ($self, $new) = @_;
    $self->{x} = $new if defined $new;
    return $self->{x};
}

sub y
{
    my ($self, $new) = @_;
    $self->{y} = $new if defined $new;
    return $self->{y};
}

