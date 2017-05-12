package App::FileSummoner;
BEGIN {
  $App::FileSummoner::VERSION = '0.005';
}

# ABSTRACT: Makes file creation easier!

use 5.006;
use strict;
use warnings;

use App::FileSummoner::CreateFile;

=head1 NAME

App::FileSummoner

=head1 METHODS

=head2 run

Main function - accepts @ARGV as parameter

=cut

sub run {
    my (@args) = @_;

    if (! @args) {
        print "Usage: create <file>\n";
        exit;
    }

    my $summoner = App::FileSummoner::CreateFile->new;

    my $action = 'summonFile';
    foreach my $arg (@args) {
        if ($arg eq '-') {
            $action = 'summonFileToStdout';
            next;
        }
        $summoner->$action($arg);
    }
}

=head1 AUTHOR

Marian Schubert, C<< <marian.schubert at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-skeleton at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Skeleton>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::FileSummoner


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Skeleton>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Skeleton>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Skeleton>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Skeleton/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Marian Schubert.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of App::FileSummoner
