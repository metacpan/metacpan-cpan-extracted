package CSS::Croco::Statement::Media;

use utf8;
use strict;
use warnings;

our @ISA = qw(CSS::Croco::Statement);

1;

__END__

=head1 NAME

CSS::Croco::Statement::Media

=head1 DESCRIPTION

C<@media> statement.

=head1 SYNOPSYS

  @media print {
      body {
          background-color: black; # CSS of evil :-)
      }
  }

=head1 METHOD

=head2 media_list

Returns list of media types which can be handled by this selector

=head2 rules

Returns list of L<CSS::Croco::Statement::RuleSet> in this section.

=head1 BUGS

=head1 NOTES

=head1 AUTHOR

Andrey Kostenko (), <andrey@kostenko.name>

=head1 COMPANY

Rambler Internet Holding

=head1 CREATED

07.11.2009 02:40:03 MSK

=cut

use strict;
use warnings;



