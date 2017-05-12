package Data::Microformat::adr;
use base qw(Data::Microformat);

use strict;
use warnings;

our $VERSION = "0.04";

sub class_name { "adr" }
sub plural_fields { qw(type) }
sub singular_fields { qw(post_office_box street_address extended_address locality region postal_code country_name) }

1;

__END__

=head1 NAME

Data::Microformat::adr - A module to parse and create adrs

=head1 VERSION

This documentation refers to Data::Microformat::adr version 0.03.

=head1 SYNOPSIS

	use Data::Microformat::adr;

	my $adr = Data::Microformat::adr->parse($a_web_page);

	print "The street address we found in this adr was:\n";
	print $adr->street_address."\n";

	# To create a new adr:
	my $new_adr = Data::Microformat::adr->new;
	$new_adr->street_address("548 4th St.");
	$new_adr->locality("San Francisco");
	$new_adr->region("CA");
	$new_adr->postal_code("94107");
	$new_adr->country_name("USA");

	print "Here's the new adr I've just made:\n";
	print $new_adr->to_hcard."\n";

=head1 DESCRIPTION

An adr is the address microformat used primarily in hCards. It exists as its
own separate specification.

This module exists both to parse existing adrs from web pages, and to create
new adrs so that they can be put onto the Internet.

To use it to parse an existing adr (or adrs), simply give it the content
of the page containing them (there is no need to first eliminate extraneous
content, as the module will handle that itself):

	my $adr = Data::Microformat::adr->parse($content);

If you would like to get all the adrs on the webpage, simply ask using an
array:

	my @adrs = Data::Microformat::adr->parse($content);

To create a new adr, first create the new object:
	
	my $adr = Data::Microformat::adr->new;
	
Then use the helper methods to add any data you would like. When you're ready
to output the adr in the hCard HTML format, simply write

	my $output = $adr->to_hcard;

And $output will be filled with an hCard representation, using <div> tags
exclusively with the relevant class names.

=head1 SUBROUTINES/METHODS

=head2 class_name

The hCard class name for an address; to wit, "adr."

=head2 singular_fields

This is a method to list all the fields on an address that can hold exactly one value.

They are as follows:

=head3 post_office_box

The Post Office box, such as "P.O. Box 1234."

=head3 street_address

The street address, such as "1234 Main St."

=head3 extended_address

The second line of the address, such as "Suite 1."

=head3 locality

The city.

=head3 region

The region/state.

=head3 postal_code

The postal code.

=head3 country_name

The name of the country, such as "U.S.A."

=head2 plural_fields

This is a method to list all the fields on an address that can hold multiple values.

They are as follows:

=head3 type

The type of address, such as "Home" or "Work."

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-data-microformat at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Microformat>.  I will be
notified,and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 AUTHOR

Brendan O'Connor, C<< <perl at ussjoin.com> >>

=head1 COPYRIGHT

Copyright 2008, Six Apart Ltd. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.