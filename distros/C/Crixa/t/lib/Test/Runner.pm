package Test::Runner;

use strict;
use warnings;
use namespace::autoclean;

use Module::Runtime qw( require_module );
use Test::Class::Moose::Config;
use Test::Class::Moose::Runner;

use Moose;
with 'MooseX::Getopt::Dashes';

has classes => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => '_build_classes',
);

has methods => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { [] },
);

sub _build_classes {
    my $self = shift;

    my @classes = @{ $self->extra_argv };

    for my $class (@classes) {

        # accept file names as well as module names
        $class =~ s{t/lib/}{};
        $class =~ s{/}{::}g;
        $class =~ s{\.pm\z}{};

        require_module($class);
    }

    unless (@classes) {
        require Test::Class::Moose::Load;
        Test::Class::Moose::Load->import('t/lib');
    }

    return \@classes;
}

sub run {
    my $self = shift;

    my $runner = Test::Class::Moose::Runner->new(
        test_configuration => Test::Class::Moose::Config->new(
            $self->_tcm_config_class_constructor_args()
        ),
    );

    $runner->runtests();

    return;
}

sub _tcm_config_class_constructor_args {
    my $self = shift;

    my $include = join '|',
        map { $_ =~ /^test_/ ? $_ : 'test_' . $_ } @{ $self->methods() };

    return (
        test_classes => $self->classes(),
        ( $include ? ( include => qr/^(?:$include)$/ ) : () ),
    );
}

__PACKAGE__->meta()->make_immutable();

1;
