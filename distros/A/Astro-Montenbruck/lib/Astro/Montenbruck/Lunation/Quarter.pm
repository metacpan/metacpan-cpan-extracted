package Astro::Montenbruck::Lunation::Quarter;

use strict;
use warnings;

use Exporter qw/import/;
use Readonly;

our $VERSION   = 0.01;


sub new {
    my $class = shift;
    my ($name, $coeff) = @_;
    bless {
        name  => $name,
        coeff => $coeff
    }, $class
}

sub find_closest {
    my $self = shift;
    my $query = @_;
    $qq->($self)
}

1;
__END__
