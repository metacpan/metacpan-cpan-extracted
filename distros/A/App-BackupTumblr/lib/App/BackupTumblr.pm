package App::BackupTumblr;

use warnings;
use strict;
use 5.010;

=head1 NAME

App::BackupTumblr - Backup Tumblr

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

App::BackupTumblr backups your Tumblr articles.    

    BackupTumblr <URL>

<URL> is optional, default value is L<http://dalinaum-kr.tumblr.com>. BackupTumblr backups URL's articles into a current directory.

=head1 AUTHOR

Leonardo Kim, C<< <dalinaum at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-backuptumblr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-BackupTumblr>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::BackupTumblr


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-BackupTumblr>

=item * Search CPAN

L<http://search.cpan.org/dist/App-BackupTumblr/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Leonardo Kim.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of App::BackupTumblr
