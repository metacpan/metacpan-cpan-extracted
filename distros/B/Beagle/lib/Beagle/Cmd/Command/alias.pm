package Beagle::Cmd::Command::alias;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has set => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'set',
    traits        => ['Getopt'],
);

has unset => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'unset',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/alias aliases/ }

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $system_alias = system_alias;
    my $user_alias   = user_alias;
    my $alias        = alias;

    if ( $self->set || $self->unset ) {

        my @set;
        my @unset;

        if ( $self->unset ) {
            for my $name ( @{ $self->unset } ) {
                delete $user_alias->{$name};
                push @unset, $name;
            }
        }

        if ( $self->set ) {
            for my $item ( @{ $self->set } ) {
                my ( $name, $value ) = split /=/, $item, 2;
                $user_alias->{$name} = $value;
                push @set, $name;
            }
        }

        set_user_alias($user_alias) if @set || @unset;

        if (@unset) {
            puts 'unset ', join( ', ', @unset ) . '.';
        }
        if (@set) {
            puts 'set ', join( ', ', @set ) . '.';
        }

        return;
    }

    if (@$args) {
        for my $key (@$args) {
            if ( exists $alias->{$key} ) {
                my $value = $alias->{$key};
                $value = '' unless defined $value;
                puts "$key: $value";
            }
            else {
                puts "$key: <not exist>";
            }
        }
    }
    else {

        my $width = max_length( keys %{$alias} );
        $width += 2;

        puts "System aliases:";
        for my $cmd ( sort keys %$system_alias ) {
            printf "%${width}s: %s" . newline, $cmd, $system_alias->{$cmd};
        }
        puts;

        if ( keys %$user_alias ) {
            puts "Personal aliases:";
            for my $cmd ( sort keys %$user_alias ) {
                printf "%${width}s: %s" . newline, $cmd, $user_alias->{$cmd};
            }
            puts;
        }
    }
}

1;

__END__

=head1 NAME

Beagle::Cmd::Command::alias - manage aliases

=head1 SYNOPSIS

    $ beagle alias                  # show current aliases
    $ beagle aliases                # ditto
    $ beagle alias today week       # show aliases today and week

    $ beagle alias --set 'homer=ls homer' --set 'bart=ls bart'
    $ beagle alias --unset homer --unset bart

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

