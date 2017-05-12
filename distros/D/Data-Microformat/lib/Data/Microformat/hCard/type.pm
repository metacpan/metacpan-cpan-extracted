package Data::Microformat::hCard::type;
use base qw(Data::Microformat);

use strict;
use warnings;

our $VERSION = "0.04";

sub class_name { "REPLACE_WITH_KIND" }
sub plural_fields { qw(type) }
sub singular_fields { qw(value kind) }

sub from_tree
{
	my $class = shift;
	my $tree = shift;
	
	$tree = $tree->look_down("class", qr/./);
	
	return unless $tree;
	
	my $object = Data::Microformat::hCard::type->new;
    $object->{_no_dupe_keys} = 1;
	$object->kind($class->_remove_newlines($class->_trim($tree->attr('class'))));
	my @bits = $tree->content_list;
	foreach my $bit (@bits)
	{
		if (ref($bit) eq "HTML::Element")
		{
			next unless $bit->attr('class');
			my @types = split(" ", $bit->attr('class'));
			foreach my $type (@types)
			{
				$type = $class->_trim($type);
				my @cons = $bit->content_list;
				my $data = $class->_trim($cons[0]);
				if ($bit->tag eq "abbr" && $bit->attr('title'))
				{
					$data = $class->_trim($bit->attr('title'));
				}
				elsif ($tree->attr('class') =~ m/(email|tel)/ && $bit->tag =~ m/(a|area)/ && $bit->attr('href'))
				{
					$data = $class->_trim($class->_url_decode($bit->attr('href')));
					$data =~ s/^(mailto|tel)\://;
					$data =~ s/\?$//;
				}
				
				if ($type eq $object->kind)
				{
					$object->value($data);
				}
				else
				{
					$object->$type($data);
				}
			}
		}
		elsif ($tree->attr('class') =~ m/(email|tel)/ && $tree->tag =~ m/(a|area)/ && $tree->attr('href'))
		{
			# This check deals with non-nested mailto links-- such as are created by the official hCard creator.
			my $data = $class->_trim($class->_url_decode($tree->attr('href')));
			$data =~ s/^(mailto|tel)\://;
			$data =~ s/\?$//;
			$object->value($data);
		}
		else
		{
			$bit = $class->_trim($bit);
			if (length $bit > 0 && !$object->value)
			{
				$object->value($bit);
			}
		}
	}
    $object->{_no_dupe_keys} = 0;
	return $object;
}

1;

__END__

=head1 NAME

Data::Microformat::hCard::type - A module to parse and create typed things within hCards

=head1 VERSION

This documentation refers to Data::Microformat::hCard::type version 0.03.

=head1 DESCRIPTION

This module exists to assist the Data::Microformat::hCard module with handling
typed things (emails and phone numbers) in hCards.

=head1 SUBROUTINES/METHODS

=head2 Data::Microformat::organization->from_tree($tree)

This method overrides but provides the same functionality as the
method of the same name in L<Data::Microformat>.

=head2 class_name

The hCard class name for a type; for types, it is not fully known, and thus this value should be ignored.

=head2 singular_fields

This is a method to list all the fields on a typed object that can hold exactly one value.

They are as follows:

=head3 value

The value of the object; for instance, in an email object, the email address.

=head3 kind

The kind of object this represents; either "email" or "tel."

=head2 plural_fields

This is a method to list all the fields on a typed object that can hold multiple values.

They are as follows:

=head3 type

The type of the object, such as "Home" or "Work."

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
