package Data::SCORM::Resource;

use Any::Moose;
use Any::Moose qw/ ::Util::TypeConstraints /;
use Data::SCORM::Types;

use Params::Coerce;

=head1 NAME

Data::SCORM::Resource 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

has 'identifier' => (
        is        => 'rw',
        isa       => 'Str',
        );
has 'scormtype' => (
        is        => 'rw',
        isa       => 'Str',
        );
has 'type' => (
        is        => 'rw',
        isa       => 'Str',
        );
has 'href' => ( # optional attribute
        is        => 'rw',
        isa       => 'Maybe[Str]',
        );

subtype 'Dependency' 
    => as 'Maybe[ArrayRef[HashRef]]';
coerce 'Dependency'
    => from 'HashRef'
        => via { [ $_ ] };

has 'dependency' => ( # optional attribute
        is        => 'rw',
        isa       => 'Dependency',
        coerce    => 1,
        );


subtype 'ListOfFiles'
	=> as 'ArrayRef[HashRef]';

coerce 'ListOfFiles'
	=> from 'HashRef'
		=> via { [$_] };

has 'file' => (
	metaclass => 'Collection::Array',
        is        => 'rw',
        isa       => 'ListOfFiles',
	default   => sub { +[] },
	coerce    => 1,
	provides => {
		elements => 'all_files',
		count    => 'count_files',
		get      => 'get_file',
		map      => 'map_files',
	  },
        );

=head1 SYNOPSIS

=cut

# __PACKAGE__->make_immutable;
no Any::Moose;

=head1 AUTHOR

osfameron, C<< <osfameron at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-scorm-manifest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SCORM-Resource>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::SCORM::Resource

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-SCORM-Resource>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-SCORM-Resource/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 OSFAMERON.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::SCORM::Resource
