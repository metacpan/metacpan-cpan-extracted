package Data::Microformat::geo;
use base qw(Data::Microformat);

use strict;
use warnings;

our $VERSION = "0.04";

sub class_name { "geo" }
sub plural_fields { }
sub singular_fields { qw(latitude longitude) }

1;

__END__

=head1 NAME

Data::Microformat::geo - A module to parse and create geos

=head1 VERSION

This documentation refers to Data::Microformat::geo version 0.03.

=head1 SYNOPSIS

	use Data::Microformat::geo;

	my $geo = Data::Microformat::geo->parse($a_web_page);

	print "The latitude we found in this geo was:\n";
	print $adr->latitude."\n";
	
	print "The longitude we found in this geo was:\n";
	print $adr->longitude."\n";

	# To create a new geo:
	my $new_geo = Data::Microformat::geo->new;
	$new_adr->latitude("37.779598");
	$new_adr->longitude("-122.398453");

	print "Here's the new adr I've just made:\n";
	print $new_adr->to_hcard."\n";

=head1 DESCRIPTION

A geo is the geolocation microformat used primarily in hCards. It exists as its
own separate specification.

This module exists both to parse existing geos from web pages, and to create
new geos so that they can be put onto the Internet.

To use it to parse an existing geo (or geos), simply give it the content
of the page containing them (there is no need to first eliminate extraneous
content, as the module will handle that itself):

	my $geo = Data::Microformat::geo->parse($content);

If you would like to get all the geos on the webpage, simply ask using an
array:

	my @geos = Data::Microformat::geo->parse($content);

To create a new geo, first create the new object:
	
	my $geo = Data::Microformat::geo->new;
	
Then use the helper methods to add any data you would like. When you're ready
to output the geo in the hCard HTML format, simply write

	my $output = $geo->to_hcard;

And $output will be filled with an hCard representation, using <div> tags
exclusively with the relevant class names.

=head1 SUBROUTINES/METHODS

=head2 class_name

The hCard class name for a geolocation; to wit, "geo."

=head2 singular_fields

This is a method to list all the fields on a geo that can hold exactly one value.

They are as follows:

=head3 latitude

The latitude of the encoded location.

=head3 longitude

The longitude of the encoded location.

=head2 plural_fields

This is a method to list all the fields on an address that can hold multiple values.

There are none for a geo.

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

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.