package Beagle::Cmd::Command;

use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::GlobalCommand/;

has 'cache' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'use cache',
    traits        => ['Getopt'],
    trigger       => sub {
        my $self = shift;
        my $true = shift;
        if ($true) {
            enable_cache();
        }
        else {
            disable_cache();
        }
    },
);

has 'devel' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'use devel',
    traits        => ['Getopt'],
    trigger       => sub {
        my $self = shift;
        my $true = shift;
        if ($true) {
            enable_devel();
        }
        else {
            disable_devel();
        }
    },
);

has 'name' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'specify beagle name',
    cmd_aliases   => 'n',
    traits        => ['Getopt'],
    trigger       => sub {
        my $self = shift;
        my $name = shift;
        if ( defined $name && length $name ) {
            if ( $name eq 'global' ) {
                $Beagle::Util::ROOT = '';
            }
            else {
                my $all = roots();
                die "no such name: $name" unless $all->{$name};
                set_current_root( $all->{$name}{local} );
            }
        }
        else {
            $Beagle::Util::ROOT = '';
        }
    },
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Beagle::Cmd::Command - base class of commands that need a beagle root

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

