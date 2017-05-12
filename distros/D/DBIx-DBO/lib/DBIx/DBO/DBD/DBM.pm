use strict;
use warnings;

BEGIN {
    unless ($ENV{DBO_ALLOW_DBM}) {
        warn "Set \$ENV{DBO_ALLOW_DBM} to a true value to try DBM.\n";
        die "DBM is not yet supported!\n";
    }
}
use SQL::Statement;

package # hide from PAUSE
    DBIx::DBO::DBD::DBM;
use Carp 'croak';

sub _init_dbo {
    my $class = shift;
    my $me = $class->SUPER::_init_dbo(@_);
    # DBM does not support QuoteIdentifier correctly!
    $me->config(QuoteIdentifier => 0);
    return $me;
}

sub _get_table_schema {
    # Schema is not used
}

sub _get_column_info {
    my($class, $me, $schema, $table) = @_;
    my $q_table = $table;

    unless (exists $me->rdbh->{dbm_tables}{$q_table}) {
        $q_table = $class->_qi($me, $table); # Try with the quoted table name
        unless (exists $me->rdbh->{dbm_tables}{$q_table}) {
            croak 'Invalid table: '.$q_table;
        }
    }
    # The DBM internal table_name may be different.
    $q_table = $me->rdbh->{dbm_tables}{$q_table}{table_name};

    unless (exists $me->rdbh->{f_meta}{$q_table}
            and exists $me->rdbh->{f_meta}{$q_table}{col_names}
            and ref $me->rdbh->{f_meta}{$q_table}{col_names} eq 'ARRAY') {
        croak 'Invalid DBM table info, could be an incompatible version';
    }
    my $cols = $me->rdbh->{f_meta}{$q_table}{col_names};

    my $i;
    map { $_ => ++$i } @$cols;
}

sub _set_table_key_info {
}

1;
