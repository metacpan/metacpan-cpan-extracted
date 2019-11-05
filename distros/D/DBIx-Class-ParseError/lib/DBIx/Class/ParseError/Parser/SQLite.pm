package DBIx::Class::ParseError::Parser::SQLite;

use strict;
use warnings;
use Moo;
use Regexp::Common;

with 'DBIx::Class::ParseError::Parser';

sub type_regex {
    return {
        data_type => qr{
                        attrs_for_bind\(\)\:
                        .+value\s+supplied\s+for\s+column\s+
                        \'(\w+)\'
        }ix,
        missing_table => qr{()no\s+such\s+table}i,
        missing_column => qr{no\s+such\s+column\s+\'(\w+)\'}i,
        not_null => qr{
                       NOT\s+NULL\s+constraint\s+failed\:\s+
                       ($RE{list}{-pat => '\w+'}{-sep => '.'})
        }ix,
        unique_key => qr{
                         UNIQUE\s+constraint\s+failed\:\s+
                         ($RE{list}{-pat => '\w+'}{-sep => '.'})
        }ix,
    };
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::ParseError::Parser::SQLite - Parser for SQLite

=head1 DESCRIPTION

This implements specific rules for parsing errors from SQLite DB.

=head1 AUTHOR

wreis - Wallace reis <wreis@cpan.org>

=head1 COPYRIGHT

Copyright (c) the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
