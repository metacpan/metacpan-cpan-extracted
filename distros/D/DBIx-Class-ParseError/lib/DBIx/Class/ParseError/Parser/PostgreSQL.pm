package DBIx::Class::ParseError::Parser::PostgreSQL;

use Moo;
use Carp 'croak';

with 'DBIx::Class::ParseError::Parser';

sub type_regex {
    return {
        data_type => qr{
            ERROR:\s+column\s+"(\w+)"\s+is\s+of\s+type\s+.*?\s+but\s+expression\s+is\s+of\s+type\s+.*?
            |
            # unfortunately, PostgreSQL's error messages are sometimes a bit problematic
            # because they can tell us the bad data, not the bad column
            ERROR:\s+invalid\s+input\s+syntax\s+for\s+[^:]+:\s+"(.*?)"
        }ix,
        missing_table    => qr{ERROR:\s+relation "(\w+)" does not exist}i,
        missing_column   => qr{
            ERROR:\s+column\s+"(\w+)"\s+of\s+relation\s+"(\w+)"\s+does\s+not\s+exist
            |
            DBIx::Class::Row::(?:get|store)_column\(\):\s+No\s+such\s+column\s+'([^']+)'\s+on
        }ix,
        not_null         => qr{ERROR:\s+null\s+value\s+in\s+column\s+"(\w+)"\s+violates\s+not-null\s+constraint}i,

        # ERROR:  duplicate key value violates unique constraint "foo_name"
        unique_key       => qr{ERROR:\s+duplicate key value violates unique constraint "(\w+)"}i,

        # primary_key not supported because the error message from PostgreSQL is
        # the same as the error message for unique_key
        foreign_key      => qr{ERROR:\s+insert or update on table "\w+" violates foreign key constraint.*?DETAIL:\s+Key\s+\(([^)]+)\)}si,

        # custom functions for PostgreSQL
        custom_unknown_function => qr{ERROR:\s+function\s+(.*?)\s+does not exist}i,
        custom_syntax_error     => qr{ERROR:\s+syntax error at or near\s+([^\n]+)}i,
    };
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::ParseError::Parser::PostgreSQL - Parser for PostgreSQL

=head1 DESCRIPTION

This implements specific rules for parsing errors from PostgreSQL DB.

=head1 AUTHOR

wreis - Wallace reis <wreis@cpan.org>

=head1 COPYRIGHT

Copyright (c) the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
