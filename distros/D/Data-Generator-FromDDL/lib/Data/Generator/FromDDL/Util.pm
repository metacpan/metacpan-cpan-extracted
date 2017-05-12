package Data::Generator::FromDDL::Util;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(
    normalize_parser_str
    need_quote_data_type
    get_numeric_type_byte
);

sub normalize_parser_str {
    my $parser = lc(shift);
    my %normalized_parsers = (
        mysql      => 'MySQL',
        sqlite     => 'SQLite',
        oracle     => 'Oracle',
        postgresql => 'PostgreSQL',
    );

    return $normalized_parsers{$parser} || undef;
}

sub need_quote_data_type {
    my $type = lc(shift);
    my %quote_data_types = map { $_ => 1 }
        qw(char varchar tinytext text mediumtext timestamp enum);

    return $quote_data_types{$type} || undef;
}

sub get_numeric_type_byte {
    my $type = lc(shift);
    my %numeric_type_bytes = (
        bigint    => 8,
        int       => 4,
        integer   => 4,
        mediumint => 3,
        smallint  => 2,
        tinyint   => 1,
        # UNIX timestamps are signed integer
        timestamp => 4,
    );

    return $numeric_type_bytes{$type} || 0; 
}

1;
