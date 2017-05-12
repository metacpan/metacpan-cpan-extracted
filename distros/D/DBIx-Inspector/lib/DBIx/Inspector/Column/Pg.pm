package DBIx::Inspector::Column::Pg;
use strict;
use warnings;
use utf8;
use base qw/DBIx::Inspector::Column/;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;

    if ( exists $args{ PK_NAME } ) {
        # primary_key_info returns pg_column with mistaken value.
        # I have no idea in case of quotated column name intentionally.
        $args{COLUMN_NAME} =~ s{^"(.+)"$}{$1};
    }
    else {
        # pg_column contains the unquoted name.
        # DBD::Pg v1.xx does not support the attribue,
        # but don't you use such a old module, do you?
        $args{ COLUMN_NAME } = $args{ PG_COLUMN };
    }

    bless {%args}, $class;
}

1;

