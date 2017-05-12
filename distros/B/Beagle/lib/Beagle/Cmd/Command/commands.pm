package Beagle::Cmd::Command::commands;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::GlobalCommand App::Cmd::Command::commands/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    App::Cmd::Command::commands::execute(@_);
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::commands - show beagle commands

=head1 SYNOPSIS

    $ beagle commands

check C<cmds> if you only want the command names.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

