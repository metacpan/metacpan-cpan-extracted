package Beagle::Cmd::Command::exists;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::Command/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $all = roots();
    die "beagle exists name" unless @$args == 1;
    my $name = shift @$args;
    puts $all->{$name} ? 'true' : 'false';
}

1;

__END__

=head1 NAME

Beagle::Cmd::Command::exists - show if the beagle exists

=head1 SYNOPSIS

    $ beagle exists foo

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

