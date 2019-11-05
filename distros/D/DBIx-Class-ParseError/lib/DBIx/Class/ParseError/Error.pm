package DBIx::Class::ParseError::Error;

use strict;
use warnings;
use Moo;

use overload
    '""' => sub { shift->message },
    fallback => 1;

extends 'DBIx::Class::Exception';

has message => (is => 'ro', required => 1);

has [qw(type operation table source_name column_data columns)] => ( is => 'ro' );

1;

__END__

=pod

=head1 NAME

DBIx::Class::ParseError::Parser::Error - Structured error info

=head1 DESCRIPTION

Handy error object with info from parsed DB errors when using L<DBIx::Class>.

These objects stringify to the contained error message.

=head1 ATTRIBUTES

=head2 message

The raw error string.

=head2 type

Error case key:

=over

=item primary_key

=item foreign_key

=item unique_key

=item not_null

=item data_type

=item missing_column

=item missing_table

=back

=head2 operation

DB operation issued (C<INSERT> or C<UPDATE>).

=head2 table

Table name.

=head2 source_name

Source moniker name.

=head2 column_data

Hashref of column names and values.

=head2 columns

Column(s) involved in error.

=head1 METHODS

=head2 rethrow

This method provides some syntactic sugar in order to re-throw exceptions.

=head1 AUTHOR

wreis - Wallace reis <wreis@cpan.org>

=head1 COPYRIGHT

Copyright (c) the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
