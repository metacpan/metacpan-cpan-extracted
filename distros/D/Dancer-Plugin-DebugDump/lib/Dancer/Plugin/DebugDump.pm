package Dancer::Plugin::DebugDump;

use warnings;
use strict;
use Dancer::Logger;
use Dancer::Plugin;
use Data::Dump;

our $VERSION = '0.03';

Dancer::Logger::warning(
    "Dancer::Plugin::DebugDump is deprecated and may go away in future.\n",
    "Dancer's built in debug() keyword automatically serialises for you.\n",
);

register debug_dump => sub {
    my $message;
    if (@_ == 1) {
        # Single thing to dump, easy:
        Dancer::Logger::debug( Data::Dump::dump(shift) );
    } elsif (@_ % 2 == 0) {
        # Looks like we got pairs of labels and dumpable things:
        while (@_) {
            my ($label, $ref) = splice @_, 0, 2;
            Dancer::Logger::debug( "$label: " . Data::Dump::dump($ref) );
        }
    } else {
        # Just feed each argument to dump() and log the result
        Dancer::Logger::debug(Data::Dump::dump($_)) for @_;
    }
};

register_plugin;

=head1 NAME

Dancer::Plugin::DebugDump - dump objects to debug log with Data::Dump [DEPRECATED]

=head1 DEPRECATION NOTICE

*NOTE* : this module is now deprecated; there's no need for it, as Dancer's own
L<debug keyword|Dancer/debug> automatically serialises any references passed to
it using L<Data::Dumper>, so you can just say e.g.:

    debug \%foo;

or

    debug "User details", \%foo;

This plugin may be removed from CPAN at some point in the future; I've decided
to leave it around with a deprecation notice for the time being so that it's
still available for anyone already using it.


=head1 DESCRIPTION

Provides a C<debug_dump> keyword, which takes an optional label and an object
or reference to dump, and calls Dancer's C<debug> keyword after dumping the
object / reference with L<Data::Dump>.

Allows quick and easy debugging by dumping stuff to your log/console.


=cut


=head1 SYNOPSIS

    use Dancer::Plugin::DebugDump;

    debug_dump("My nice object" => $object);
    debug_dump("My hash" => \%hash);
    debug_dump($anotherref);

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-debugdump at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-DebugDump>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::DebugDump


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-DebugDump>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-DebugDump>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-DebugDump>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-DebugDump/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer::Plugin::DebugDump
