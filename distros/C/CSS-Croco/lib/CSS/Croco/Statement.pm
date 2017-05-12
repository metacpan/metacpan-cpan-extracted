package CSS::Croco::Statement;

use utf8;
use strict;
use warnings;

1;

__END__

=head1 NAME

CSS::Croco::Statement - statement object.

=head1 DESCRIPTION

Abstract class representing one CSS statement.

Statement type can be one of:

=over 4

L<CSS::Croco::Statement::RuleSet> - statement with CSS selectors and declarations

L<CSS::Croco::Statement::Media>

=back

=head1 METHODS

=head2 to_string

Returns string representation of statement.


=head1 BUGS

=head1 NOTES

=head1 AUTHOR

Andrey Kostenko (), <andrey@kostenko.name>

=head1 COMPANY

Rambler Internet Holding

=head1 CREATED

07.11.2009 02:33:17 MSK

=cut

use strict;
use warnings;



