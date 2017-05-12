use strict;
use warnings;

package # hide from PAUSE
    DBIx::DBO::DBD::Oracle;
use Carp 'croak';

sub _build_limit {
    '';
}

sub _build_sql_select {
    my($class, $me) = @_;
    my $sql = $class->SUPER::_build_sql_select($me);
    return $sql unless defined (my $limoff = $me->{build_data}{LimitOffset});
    return 'SELECT * FROM ('.$sql.') WHERE ROWNUM <= '.$limoff->[0] unless $limoff->[1];
    # If we have an offset then we must add the "_DBO_ROWNUM_" column to the result set
    return 'SELECT * FROM (SELECT A.*, ROWNUM AS "_DBO_ROWNUM_" FROM ('.$sql.') A WHERE ROWNUM <= '.($limoff->[0] + $limoff->[1]).') WHERE "_DBO_ROWNUM_" > '.$limoff->[1];
}

sub _alias_preference {
    my($class, $me, $method) = @_;
    # Oracle doesn't allow the use of aliases in GROUP BY or HAVING
    return 0 if $method eq 'join_on' or $method eq 'group_by' or $method eq 'having';
    return 1;
}

# Query
sub _calc_found_rows {
    my($class, $me) = @_;
    local $me->{build_data}{LimitOffset};
    $me->{Found_Rows} = $me->count_rows;
}

1;
