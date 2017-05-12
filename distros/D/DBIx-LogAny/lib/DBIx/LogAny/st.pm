# $Id$
use strict;
use warnings;
use DBI;

package DBIx::LogAny::st;
@DBIx::LogAny::st::ISA = qw(DBI::st DBIx::LogAny);
use DBIx::LogAny::Constants qw (:masks $LogMask);

sub finish {
    my ($sth) = shift;

    my $h = _unseen_sth($sth);

    $sth->_dbix_la_debug($h, 2,
                          "finish($h->{dbh_no}.$sth->{private_DBIx_st_no})")
        if ($h->{logmask} & DBIX_LA_LOG_INPUT);
    return $sth->SUPER::finish;
}

#
# NOTE: execute can be called from the DBD. Now we support retrieving
# dbms_output from DBD::Oracle we need a flag to say we are in the
# 'dbms_output_get' or when we call dbms_output_get we will log a second
# execute and potentially recurse until we run out of stack.
# We use the "dbd_specific" flag since we may need it for other
# drivers in the future and that is the logging flag we implement dbms_output
# fetching under
#
sub execute {
    my $sth = shift;
    my $h = $sth->{private_DBIx_LogAny};

    if (($h->{logmask} & (DBIX_LA_LOG_INPUT|DBIX_LA_LOG_SQL)) &&
            (caller !~ /^DBD::/o) &&
                (!$h->{dbd_specific})) {
        my $params;
        #if (defined($sth->{ParamValues})) {
        #    $params = '{params => ';
        #    foreach (sort keys %{$sth->{ParamValues}}) {
        #        $params .= "$_=" . DBI::neat($h->{ParamValues}->{$_}) . ",";
        #    }
        #    $params .= '}';     # TO_DO not used yet
        #}
        if (scalar(@_)) {
            $sth->_dbix_la_debug(
                $h, 2,
                "execute($h->{dbh_no}.$sth->{private_DBIx_st_no}) (" .
                    ($sth->{Statement} ? $sth->{Statement} : '') . ')', @_);
        } else {
            my @param_info;
            push @param_info, $sth->{ParamValues}, $sth->{ParamTypes}
                if ($h->{logmask} & DBIX_LA_LOG_DELAYBINDPARAM);
            $sth->_dbix_la_debug(
                $h, 2,
                "execute($h->{dbh_no}.$sth->{private_DBIx_st_no})",
                @param_info);
        }
    }

    my $ret = $sth->SUPER::execute(@_);

    #
    # If DBDSPECIFIC is enabled and this is DBD::Oracle we will attempt to
    # to retrieve any dbms_output. However, 'dbms_output_get' actually
    # creates a new statement, prepares it, executes it, binds parameters
    # and then fetches the dbms_output. This will cause this execute method
    # to be called again and we could recurse forever. To prevent that
    # happening we set {dbd_specific} flag before calling dbms_output_get
    # and clear it afterwards.
    #
    # Also in DBI (at least up to 1.54) and most DBDs, the same memory is
    # used for a dbh errstr/err/state and each statement under it. As a
    # result, if you sth1->execute (it fails) then $sth2->execute which
    # succeeds, sth1->errstr/err are undeffed :-(
    # see http://www.nntp.perl.org/group/perl.dbi.users/2007/02/msg30971.html
    # To sort this out, we save the errstr/err/state on the first sth
    # and put them back after using the second sth (ensuring we temporarily
    # turn off any error handler to avoid set_err calling them again).
    #
    if (($h->{logger}->is_debug()) &&
        ($h->{logmask} & DBIX_LA_LOG_DBDSPECIFIC) &&
    	($h->{driver} eq 'Oracle') && (!$h->{dbd_specific})) {

        my ($errstr, $err, $state) = (
            $sth->errstr, $sth->err, $sth->state);
    	$h->{dbd_specific} = 1;
    	my $dbh = $sth->FETCH('Database');

        my @lines = $dbh->func('dbms_output_get');
    	$sth->_dbix_la_debug($h, 2, 'dbms', @lines) if (scalar(@lines) > 0);
    	$h->{dbd_specific} = 0;
        {
            local $sth->{HandleError} = undef;
            local $sth->{HandleSetErr} = undef;
            $sth->set_err($err, $errstr, $state);
        }
    }

    if (!$ret) {		# error
        if (($h->{logmask} & DBIX_LA_LOG_ERRCAPTURE) && # logging errors
                (caller !~ /^DBD::/o)) { # ! called from DBD e.g. execute_array
            if ((exists($h->{err_regexp}) && ($sth->err !~ $h->{err_regexp})) ||
                    (!exists($h->{err_regexp}))) {
                $sth->_dbix_la_error(
                    2, "\tfailed with " . DBI::neat($sth->errstr));
            }
        }
    } elsif (defined($ret) && (!$h->{dbd_specific})) {
        $sth->_dbix_la_debug(
            $h, 2, "affected($h->{dbh_no}.$sth->{private_DBIx_st_no})", $ret)
	    if ((!defined($sth->{NUM_OF_FIELDS})) && # not a result-set
		($h->{logmask} & DBIX_LA_LOG_INPUT)	&& # logging input
		(caller !~ /^DBD::/o));
    }
    return $ret;
}

sub execute_array {
    my ($sth, @args) = @_;
    my $h = $sth->{private_DBIx_LogAny};

    $sth->_dbix_la_debug($h, 2,
                          "execute_array($h->{dbh_no}.$sth->{private_DBIx_st_no})", @args)
        if ($h->{logmask} & DBIX_LA_LOG_INPUT);

    if (($#args >= 0) && ($args[0]) &&
            (ref($args[0]) eq 'HASH') &&
                (!exists($args[0]->{ArrayTupleStatus}))) {
        $args[0]->{ArrayTupleStatus} = \my @tuple_status;
    } elsif (!$args[0]) {
        $args[0] = {ArrayTupleStatus => \my @tuple_status};
    }
    my $array_tuple_status = $args[0]->{ArrayTupleStatus};

    #
    # NOTE: We have a problem here. The DBI pod stipulates that
    # execute_array returns undef (for error) or the number of tuples
    # executed. If we want to access the number of rows updated or
    # inserted then we need to add up the values in the ArrayTupleStatus.
    # Unfortunately, the drivers which implement execute_array themselves
    # (e.g. DBD::Oracle) don't do this properly (e.g. DBD::Oracle 1.18a).
    # As a result, until this is sorted out, our logging of execute_array
    # may be less than accurate.
    # NOTE: DBD::Oracle 1.19 is working now from my supplied patch
    #
    my ($executed, $affected) = $sth->SUPER::execute_array(@args);
    if (!$executed) {
        #print Data::Dumper->Dump([$sth->{ParamArrays}], ['ParamArrays']), "\n";
        if (!$h->{logmask} & DBIX_LA_LOG_ERRORS) {
            return $executed unless wantarray;
            return ($executed, $affected);
        }
        my $pa = $sth->{ParamArrays};
        $sth->_dbix_la_error(2, "execute_array error:");
        for my $n (0..@{$array_tuple_status}-1) {
            next if (!ref($array_tuple_status->[$n]));
            $sth->_dbix_la_error('Error', $array_tuple_status->[$n]);
            my @plist;
            foreach my $p (keys %{$pa}) {
                if (ref($pa->{$p})) {
                    push @plist, $pa->{$p}->[$n];
                } else {
                    push @plist, $pa->{$p};
                }
            }
            $sth->_dbix_la_error(
                2, "\t for " . join(',', map(DBI::neat($_), @plist)));
        }
    } elsif ($executed) {
        if ((defined($sth->{NUM_OF_FIELDS})) ||  # result-set
                !($h->{logmask} & DBIX_LA_LOG_INPUT)) { # logging input
            return $executed unless wantarray;
            return ($executed, $affected);
        }
        $sth->_dbix_la_debug($h, 2, "executed $executed, affected " .
                                  DBI::neat($affected));
    }
    $sth->_dbix_la_debug($h, 2, Data::Dumper->Dump(
        [$array_tuple_status], ['ArrayTupleStatus']))
        if ($h->{logmask} & DBIX_LA_LOG_INPUT);
    return $executed unless wantarray;
    return ($executed, $affected);
}

sub bind_param {
    my $sth = shift;

    my $h = $sth->{private_DBIx_LogAny};

    $sth->_dbix_la_debug(
        $h, 2, "bind_param($h->{dbh_no}.$sth->{private_DBIx_st_no})", @_)
        if (($h->{logmask} & DBIX_LA_LOG_INPUT) &&
                (($h->{logmask} & DBIX_LA_LOG_DELAYBINDPARAM) == 0));

    return $sth->SUPER::bind_param(@_);
}

sub bind_param_inout {
    my $sth = shift;
    my $h = $sth->{private_DBIx_LogAny};

    $sth->_dbix_la_debug(
        $h, 2,
        "bind_param_inout($h->{dbh_no}.$sth->{private_DBIx_st_no})", @_)
        if (($h->{logmask} & DBIX_LA_LOG_INPUT) && (caller !~ /^DBD::/o));
    return $sth->SUPER::bind_param_inout(@_);
}

sub bind_param_array {
    my($sth, @args) = @_;
    my $h = $sth->{private_DBIx_LogAny};

    $sth->_dbix_la_debug($h, 2,
        "bind_param_array($h->{dbh_no}.$sth->{private_DBIx_st_no})",
        @args) if ($h->{logmask} & DBIX_LA_LOG_INPUT);
    return $sth->SUPER::bind_param_array(@args);
}

sub fetch {			# alias for fetchrow_arrayref
    my($sth, @args) = @_;

    my $h = _unseen_sth($sth);

    my $res = $sth->SUPER::fetch(@args);
    $sth->_dbix_la_debug(
        $h, 2,
        Data::Dumper->Dump([$res], ["fetch($h->{dbh_no}.$sth->{private_DBIx_st_no})"]))
        if ($h->{logmask} & DBIX_LA_LOG_OUTPUT);
    return $res;
}

sub fetchrow_arrayref {			# alias for fetchrow_arrayref
    my($sth, @args) = @_;

    my $h =_unseen_sth($sth);

    my $res = $sth->SUPER::fetchrow_arrayref(@args);
    $sth->_dbix_la_debug(
        $h, 2,
        Data::Dumper->Dump([$res], ["fetchrow_arrayref($h->{dbh_no}.$sth->{private_DBIx_st_no})"]))
        if ($h->{logmask} & DBIX_LA_LOG_OUTPUT);
    return $res;
}

sub fetchrow_array {
    my ($sth, @args) = @_;

    my $h = _unseen_sth($sth);

    if (wantarray) {
        my @row = $sth->SUPER::fetchrow_array(@args);
        $sth->_dbix_la_debug(
            $h, 2,
            Data::Dumper->Dump(
                [\@row], ["fetchrow_array($h->{dbh_no}.$sth->{private_DBIx_st_no})"]))
            if ($h->{logmask} & DBIX_LA_LOG_OUTPUT);
        return @row;
    } else {
        my $row = $sth->SUPER::fetchrow_array(@args);
        $sth->_dbix_la_debug(
            $h, 2,
            Data::Dumper->Dump(
                [$row], ["fetchrow_array($h->{dbh_no}.$sth->{private_DBIx_st_no})"]))
            if ($h->{logmask} & DBIX_LA_LOG_OUTPUT);
        return $row;
    }
}

sub fetchrow_hashref {
    my($sth, @args) = @_;

    my $h = _unseen_sth($sth);

    my $res = $sth->SUPER::fetchrow_hashref(@args);
    $sth->_dbix_la_debug(
        $h, 2,
        Data::Dumper->Dump(
            [$res], ["fetchrow_hashref($h->{dbh_no}.$sth->{private_DBIx_st_no})"]))
        if ($h->{logmask} & DBIX_LA_LOG_OUTPUT);
    return $res;
}

#
# _unseen_sth is called when we might come across a statement handle which was
# not created via the prepare method e.g., a statement handle DBD::Oracle
# magicked into existence when a function or procedure returns a cursor.
# We need to save the private log handle and set the statement number.
#
sub _unseen_sth
{
    my $sth = shift;

    if (!exists($sth->{private_DBIx_LogAny})) {
        my $p = $sth->FETCH('Database')->{private_DBIx_LogAny};
        $sth->{private_DBIx_LogAny} = $p;
        $sth->{private_DBIx_st_no} = $p->{new_stmt_no}();
        return $p;
    } else {
        return $sth->{private_DBIx_LogAny};
    }
}

1;
