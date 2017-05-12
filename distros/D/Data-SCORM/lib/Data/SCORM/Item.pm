package Data::SCORM::Item;

use Any::Moose;
use Any::Moose qw/ ::Util::TypeConstraints /;
use Data::SCORM::Types;

=head1 NAME

Data::SCORM::Item 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

has 'identifier' => (
        is        => 'rw',
        isa       => 'Str',
        );
has 'identifierref' => (
        is        => 'rw',
        isa       => 'Str',
        );
has 'title' => (
        is        => 'rw',
        isa       => 'Str',
        );
has 'resource' => (
        is        => 'rw',
        isa       => 'Data::SCORM::Resource',
        );

has 'isvisible' => (
        is        => 'rw',
        isa       => 'Bool',
	coerce    => 1,
        );

=head1 SYNOPSIS

=cut

# __PACKAGE__->make_immutable;
no Any::Moose;

=head1 AUTHOR

osfameron, C<< <osfameron at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-scorm-manifest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SCORM-Item>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::SCORM::Item

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-SCORM-Item>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-SCORM-Item/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 OSFAMERON.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::SCORM::Item
