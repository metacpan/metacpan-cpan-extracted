package Beagle::Cmd::Command::cmds;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has 'alias' => (
    isa           => 'Bool',
    is            => 'rw',
    traits        => ['Getopt'],
    documentation => 'show aliases instead',
);

has 'all' => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'a',
    traits        => ['Getopt'],
    documentation => 'show all the commands and aliases',
);

has 'seprator' => (
    isa           => 'Str',
    is            => 'rw',
    traits        => ['Getopt'],
    documentation => 'seprator',
    default       => ' ',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    # can't use ->app->command_names directly as it contains alias such as -h 
    my @cmds = map { ( $_->command_names )[0] } $self->app->command_plugins;
    my @aliases = Beagle::Util::aliases;

    my @out;
    if ( $self->all ) {
        @out = ( @cmds, @aliases );
    }
    else {
        @out = (
              $self->alias
            ? @aliases
            : @cmds
        );
    }
    my $seprator = $self->seprator;
    $seprator =~
      s{\\(.)}{$1 eq 'r' ? "\r" : $1 eq 'n' ? "\n" : $1 eq 't' ?  "\t" : $1 }g;
    Beagle::Util::puts( join $seprator, sort Beagle::Util::uniq @out );
}

1;

__END__

=head1 NAME

Beagle::Cmd::Command::cmds - show names of all the commands/aliases

=head1 SYNOPSIS

    $ beagle cmds
    $ beagle cmds --alias
    $ beagle cmds --all
    $ beagle cmds --sperator "\t"

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

