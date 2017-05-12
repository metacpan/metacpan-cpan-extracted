package Beagle::Cmd::Command::version;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::GlobalCommand/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    require Beagle;
    puts "beagle version $Beagle::VERSION";
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::version - show beagle version

=head1 SYNOPSIS

    $ beagle version

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

