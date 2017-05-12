package App::CMAM;

use warnings;
use strict;

=head1 NAME

App::CMAM - Watch and commit differences

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    # the module is empty for now, use the cacm script like this:
    
    cacm --repo path_to_git_repo --watch directory_to_watch
    
    # it will commit at most once per 5 seconds
    # you can tweak the latency with --latency N


=head1 DESCRIPTION

The cmam script will watch over a specific directory and commit the
detected changes to a Git repository.


=head1 AUTHOR

Pedro Melo, C<< <melo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-cmam at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-CMAM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::CMAM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-CMAM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-CMAM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-CMAM>

=item * Search CPAN

L<http://search.cpan.org/dist/App-CMAM>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Melo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::CMAM
