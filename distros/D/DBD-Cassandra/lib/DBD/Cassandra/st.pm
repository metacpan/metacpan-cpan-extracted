package DBD::Cassandra::st;
use 5.010;
use strict;
use warnings;

# Documentation-driven cargocult
$DBD::Cassandra::st::imp_data_size = 0;

sub bind_param {
    my ($sth, $pNum, $val, $attr)= @_;
    my $params= ($sth->{cass_params} ||= []);
    $params->[$pNum-1] = $val;
    1;
}

sub execute {
    my ($sth, @bind_values)= @_;

    $sth->{cass_bind}= (@bind_values ? \@bind_values : $sth->{cass_params});
    &start_async;
    $sth->STORE('Active', 1);
    if (!$sth->{cass_async}) {
        return &x_finish_async;
    }

    return '0E0';
}

sub start_async {
    my ($sth)= @_;

    $sth->{cass_future}= $sth->{Database}{cass_client}->future_call_execute($sth->{Statement}, $sth->{cass_bind}, {
        consistency => $sth->{cass_consistency},
        page_size => $sth->{cass_page_size},
        page => $sth->{cass_next_page},
    });
}

sub x_finish_async {
    my ($sth)= @_;

    my $future= delete $sth->{cass_future};
    if (!$future) { return '0E0'; }

    my ($error, $result)= $future->();
    if ($error) {
        $sth->STORE('Active', 0);
        return $sth->set_err($DBI::stderr, $error);
    }

    my $rows= ($result && $result->rows) || [];
    my $names= ($result && $result->column_names) || [];
    my $page= ($result && $result->next_page);

    $sth->{rows}= $rows;
    $sth->{row_count}= 0+@$rows;

    if (!@$rows && !@$names) {
        # This is a weird Cassandra corner-case, triggered by doing 'list permissions' etc when there are none.
        # Our code is fine with it, but DBI wants to have at least one column. So let's give it one.
        @$names= ('no_column_names_returned_by_cassandra');
    }

    $sth->STORE('NUM_OF_FIELDS', 0+@$names);
    $sth->{NAME}= $names;
    $sth->{cass_next_page}= $page;

    return ((0+@$rows) || '0E0');
}

sub execute_for_fetch {
    die 'Not implemented'; #TODO
}

sub bind_param_array {
    die 'Not implemented'; #TODO
}

sub fetchrow_arrayref {
    my ($sth)= @_;
    if ($sth->{cass_future}) {
        return undef unless &x_finish_async;
    }

    my $row= shift @{$sth->{rows}};
    if (!$row && $sth->{cass_next_page}) {
        &start_async;
        if (!&x_finish_async) {
            return undef;
        }
        $row= shift @{$sth->{rows}};
    }
    if ($row) {
        if ($sth->FETCH('ChopBlanks')) {
            map { $_ =~ s/\s+$//; } @$row;
        }

        return $sth->_set_fbav($row);
    }

    $sth->STORE('Active', 0);
    return undef;
}

*fetch = \&fetchrow_arrayref;

sub rows {
    my $sth= shift;
    if ($sth->{cass_future}) {
        return undef unless &x_finish_async;
    }
    return $sth->{row_count};
}

sub FETCH {
    my ($sth, $attr)= @_;
    if ($attr =~ /\A(?:NAME|NUM_OF_FIELDS)\z/ && $sth->{cass_future}) {
        return undef unless &x_finish_async;
        return $sth->{$attr} if $attr eq 'NAME';
    }
    return $sth->SUPER::FETCH($attr);
}

1;
