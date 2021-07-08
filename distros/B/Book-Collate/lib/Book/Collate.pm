package Book::Collate;

use 5.006;
use strict;
use warnings;

=head1 NAME

Book::Collate - Tools to Collate and Report Text Documents

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = 'v0.0.1';


=head1 SYNOPSIS

Tools allow iteration through text files and generation of a single combined
file or a set of modified individual files. They can provide grade level and 
word count reports.

=cut 

#use lib 'lib/Book/Collate';
use Book::Collate::Section;
use Book::Collate::Book;
use Book::Collate::Report;
use Book::Collate::Writer::Report;
#use Text;


=head1 AUTHOR

Leam Hall, C<< <leamhall at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to i
C<bug-book::collate at rt.cpan.org>, or through the web interface at 
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Book::Collate>.  
I will be notified, and then you'll automatically be notified of progress 
on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Book::Collate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Book::Collate>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Book::Collate>

=item * Search CPAN

L<https://metacpan.org/release/Book::Collate>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Leam Hall.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Book::Collate
