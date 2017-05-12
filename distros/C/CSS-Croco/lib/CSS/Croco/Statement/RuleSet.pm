package CSS::Croco::Statement::RuleSet;
@ISA = qw(CSS::Croco::Statement);
use utf8;
use strict;
use warnings;

=head1 NAME

CSS::Croco::Statement::RuleSet - List of rule objects

=head1 DESCRIPTION

RuleSet is:

    selector, selector1 {
        property: value;
        ...
    }

=head1 METHODS

=head2 declarations

Returns list of declarations

=head2 parse_declaration

Args: C<$string>

Parses single declaration

=head2 selectors

Returns list of CSS Selectors

=head1 BUGS

=head1 NOTES

=head1 AUTHOR

Andrey Kostenko (), <andrey@kostenko.name>

=head1 COMPANY

Rambler Internet Holding

=head1 CREATED

02.11.2009 02:15:11 MSK

=cut

1;

