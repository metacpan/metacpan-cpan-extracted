package Beagle::Cmd::Command::look;
use Beagle::Util;

use Any::Moose;
extends qw/Beagle::Cmd::Command/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $root = current_root('not die');
    if ($root) {

        my $shell = $ENV{SHELL};
        $shell ||= $ENV{COMSPEC} if is_windows();
        if ($shell) {
            chdir $root;
            system $shell;
        }
        else {
            puts "no SHELL available";
            exit;
        }
    }
    else {
        puts "no root specified";
        exit;
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::look - open the beagle root directory with SHELL

=head1 SYNOPSIS

    $ beagle look

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

