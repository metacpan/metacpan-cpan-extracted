package Data::Microformat::hCard::name;
use base qw(Data::Microformat);

use strict;
use warnings;

our $VERSION = "0.04";

sub class_name { "n" }
sub plural_fields { qw() }
sub singular_fields { qw(honorific_prefix given_name additional_name family_name honorific_suffix) }

1;

__END__

=head1 NAME

Data::Microformat::hCard::name - A module to parse and create names within hCards

=head1 VERSION

This documentation refers to Data::Microformat::hCard::name version 0.03.

=head1 DESCRIPTION

This module exists to assist the Data::Microformat::hCard module with handling
names in hCards.

=head1 SUBROUTINES/METHODS

=head2 class_name

The hCard class name for a name; to wit, "n."

=head2 singular_fields

This is a method to list all the fields on a name that can hold exactly one value.

They are as follows:

=head3 given_name

The given, or "first," name.

=head3 additional_name

The additional, or "middle," name.

=head3 family_name

The family, or "last," name.

=head3 honorific_prefix

Any honorific prefix, such as "Dr."

=head3 honorific_suffix

Any honorific suffix, such as "Ph.D."

=head2 plural_fields

This is a method to list all the fields on a name that can hold multiple values.

There are none for a name.

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