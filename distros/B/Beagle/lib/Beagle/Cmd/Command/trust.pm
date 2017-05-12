package Beagle::Cmd::Command::trust;
use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

has 'all' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'all the beagles',
    cmd_aliases   => 'a',
    traits        => ['Getopt'],
);

has 'names' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'names of beagles',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $all = roots();

    my @names;
    if ( $self->all ) {
        @names = sort keys %{ handles() };
    }
    elsif ( $self->names || @$args ) {
        my $names = $self->names ? to_array( $self->names ) : $args;
        for my $name (@$names) {
            die "invalid name: $name" unless $all->{$name};
            push @names, $name;
        }
    }
    else {
        @names = current_handle()->name;
    }

    return unless @names;

    for my $name ( @names ) {
        $all->{$name}{trust} ||= 1;
    }
    set_roots($all);
    puts 'trusted ', join( ', ', @names ), '.';
}

1;

__END__

=head1 NAME

Beagle::Cmd::Command::trust - trust beagles

=head1 SYNOPSIS

    $ beagle trust foo bar

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

