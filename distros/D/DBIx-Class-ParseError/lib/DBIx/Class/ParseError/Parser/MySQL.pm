package DBIx::Class::ParseError::Parser::MySQL;

use strict;
use warnings;
use Moo;

with 'DBIx::Class::ParseError::Parser';

sub type_regex {
    return {
        data_type => qr{Incorrect.+value\:.+for\s+column\s+\'(\w+)\'}i,
        missing_table => qr{()Table\s+\'.+\'\s+doesn\'t\s+exist}i,
        missing_column => qr{no\s+such\s+column\s+\'(\w+)\'}i,
        not_null => qr{
                       Column\s+\'(\w+)\'\s+cannot\s+be\s+null
                       |Field\s+\'(\w+)\'\s+doesn\'t\s+have\s+a\s+default
        }ix,
        unique_key => qr{
                         Duplicate\s+entry\s+\'\w+\'\s+
                         for\s+key\s+\'(\w+[^PRIMARY])\'
        }ix,
        primary_key => qr{
                          Duplicate\s+entry\s+\'(\w+)\'\s+
                          for\s+key\s+\'(PRIMARY)\'
        }ix,
        foreign_key => qr{
                          foreign\s+key\s+constraint\s+fails\s+
                          .+CONSTRAINT\s+.+FOREIGN\s+KEY\s+\(\`(\w+)\`\)
        }ix,
    };
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::ParseError::Parser::MySQL - Parser for MySQL

=head1 DESCRIPTION

This implements specific rules for parsing errors from MySQL DB.

=head1 AUTHOR

wreis - Wallace reis <wreis@cpan.org>

=head1 COPYRIGHT

Copyright (c) the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
