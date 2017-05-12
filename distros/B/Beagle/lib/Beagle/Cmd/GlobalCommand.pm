package Beagle::Cmd::GlobalCommand;

use Any::Moose;
use Beagle::Util;
extends any_moose('X::App::Cmd::Command');

has 'verbose' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'verbose',
    cmd_aliases   => 'v',
    traits        => ['Getopt'],
);

has 'output' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'output file',
    traits        => ['Getopt'],
    cmd_aliases   => 'o',
    trigger       => sub {
        my $self = shift;
        my $file = shift;
        return unless $file && $file ne '-';
        open my $fh, '>', $file or die $!;
        select $fh;
    },
);

has 'page' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'page output',
    traits        => ['Getopt'],
    trigger       => sub {
        my $self = shift;
        my $true = shift;
        require IO::Page if $true;
    },
);

has plugins => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'plugins to use',
    traits        => ['Getopt'],
    cmd_aliases   => 'x',
    trigger       => sub {
        my $self = shift;
        my $value = shift;
        undef $Beagle::Util::SEARCHED_PLUGINS;
        $ENV{BEAGLE_PLUGINS} = encode( locale => $value );
        Beagle::Util::plugins();
    },
);

sub resolve_ids {
    my $self = shift;
    my $args = shift;

    my @newargs;

    for my $id (@$args) {
        if ( $id eq '-' ) {
            push @newargs, map { /^(\w{32})/ ? $1 : () } <STDIN>;
        }
        else {
            push @newargs, $id;
        }
    }

    return \@newargs;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Beagle::Cmd::Command - base class of command


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

