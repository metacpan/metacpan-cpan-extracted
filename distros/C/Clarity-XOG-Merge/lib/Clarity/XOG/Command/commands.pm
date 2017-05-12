package Clarity::XOG::Command::commands;

use strict;
use warnings;

use Clarity::XOG -command;

sub abstract { "list the application's commands" }

sub description {
        "This is a Clarity XOG utility. Its primary usecase is
merging project files. See 'xogtool help merge' for more
details."
}

*execute = *App::Cmd::Command::commands::execute;
*sort_commands = *App::Cmd::Command::commands::sort_commands;

1;

__END__

=pod

=head1 NAME

Clarity::XOG::Command::commands - xogtool subcommand 'commands'

=head1 ABOUT

This is the class for C<xogtool commands>. It lists all available
subcommands.

See also L<xogtool|xogtool> for details.

=head1 AUTHOR

Steffen Schwigon, C<< <ss5 at renormalist.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-clarity-xog-merge
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Clarity-XOG-Merge>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Steffen Schwigon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
