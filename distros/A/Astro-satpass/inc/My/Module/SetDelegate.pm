package My::Module::SetDelegate;

use strict;
use warnings;

use Astro::Coord::ECI::TLE;
our @ISA = qw{ Astro::Coord::ECI::TLE };

sub new {
    my ($class, @args) = @_;
    $class = ref $class if ref $class;
    my $self = $class->SUPER::new ();
    $self->set (model => 'null', @args);
    return $self;
}

*_nodelegate_nodelegate = \&nodelegate;
sub nodelegate {return $_[0]}

sub delegate {return $_[0]}

sub rebless {}	# No-op rebless() to defeat class changes.

1;

