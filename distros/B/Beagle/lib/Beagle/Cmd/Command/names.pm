package Beagle::Cmd::Command::names;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::Command/;

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
    my $all = roots();
    my $seprator = $self->seprator;
    $seprator =~
      s{\\(.)}{$1 eq 'r' ? "\r" : $1 eq 'n' ? "\n" : $1 eq 't' ?  "\t" : $1 }g;
    puts join $seprator, sort keys %$all if keys %$all;
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::names - show names

=head1 SYNOPSIS

    $ beagle names

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

