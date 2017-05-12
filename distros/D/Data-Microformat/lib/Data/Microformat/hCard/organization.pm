package Data::Microformat::hCard::organization;
use base qw(Data::Microformat);

use strict;
use warnings;

our $VERSION = "0.04";

sub class_name { "org" }
sub plural_fields { qw() }
sub singular_fields { qw(organization_name organization_unit) }

sub from_tree
{
	my $class = shift;
	my $tree = shift;
	
	$tree = $tree->look_down("class", qr/(^|\s)org($|\s)/);
	
	return unless $tree;
	
	my $object = Data::Microformat::hCard::organization->new;
    $object->{_no_dupe_keys} = 1;
	my @bits = $tree->content_list;
	
	foreach my $bit (@bits)
	{
		if (ref($bit) eq "HTML::Element")
		{
			next unless $bit->attr('class');
			my @types = split(" ", $bit->attr('class'));
			foreach my $type (@types)
			{
				$type =~ s/\-/\_/;
				$type = $class->_trim($type);
				my @cons = $bit->content_list;
				my $data = $class->_trim($cons[0]);
				if ($bit->tag eq "abbr" && $bit->attr('title'))
				{
					$data = $class->_trim($bit->attr('title'));
				}
				$object->$type($data);
			}
		}
		else
		{
			$bit = $class->_trim($bit);
			if (length $bit > 0)
			{
				$object->organization_name($bit);
			}
		}
	}
	$object->{_no_dupe_keys} = 0;
	return $object;
}

1;

__END__

=head1 NAME

Data::Microformat::hCard::organization - A module to parse and create orgs within hCards

=head1 VERSION

This documentation refers to Data::Microformat::hCard::organization version 0.03.

=head1 DESCRIPTION

This module exists to assist the Data::Microformat::hCard module with handling
organizations in hCards.

=head1 SUBROUTINES/METHODS

=head2 Data::Microformat::organization->from_tree($tree)

This method overrides but provides the same functionality as the
method of the same name in L<Data::Microformat>.

=head2 class_name

The hCard class name for an organization; to wit, "org."

=head2 singular_fields

This is a method to list all the fields on an organization that can hold exactly one value.

They are as follows:

=head3 organization_name

The name of the organization.

=head3 organization_unit

The division within the organization.

=head2 plural_fields

This is a method to list all the fields on an organization that can hold multiple values.

There are none for organizations.

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
