# $Id: db.pm 245 2006-07-25 14:20:59Z martin $
use strict;
use warnings;
use DBI;
use Log::Log4perl;
use Data::Dumper;

package DBIx::Log4perl::db;
@DBIx::Log4perl::db::ISA = qw(DBI::db DBIx::Log4perl);
use DBIx::Log4perl::Constants qw (:masks $LogMask);

# $_glogger is not relied upon - it is just a fallback
my $_glogger;

my $_counter;                   # to hold sub to count

BEGIN {
    my $x = sub {
        my $start = shift;
        return sub {$start++}};
    $_counter = &$x(0);         # used to count dbh connections
}


sub STORE{
    my $dbh = shift;
    my @args = @_;

    my $h = $dbh->{private_DBIx_Log4perl};
    # as we don't set private_DBIx_Log4perl until the connect method sometimes
    # $h will not be set
    $dbh->_dbix_l4p_debug($h, 2, "STORE($h->{dbh_no})", @args)
        if ($h && ($h->{logmask} & DBIX_L4P_LOG_INPUT));


    return $dbh->SUPER::STORE(@args);
}

sub get_info
{
    my ($dbh, @args) = @_;

    my $h = $dbh->{private_DBIx_Log4perl};
    my $value = $dbh->SUPER::get_info(@args);

    $dbh->_dbix_l4p_debug($h, 2, "get_info($h->{dbh_no})", @args, $value)
        if ($h->{logmask} & DBIX_L4P_LOG_INPUT);
    return $value;
}
sub prepare {
    my($dbh, @args) = @_;

    my $h = $dbh->{private_DBIx_Log4perl};
    my $ctr = $h->{new_stmt_no}(); # get a new unique stmt counter in this dbh
    if (($h->{logmask} & (DBIX_L4P_LOG_INPUT|DBIX_L4P_LOG_SQL)) &&
            (caller !~ /^DBIx::Log4perl/o) &&
                (caller !~ /^DBD::/o)) { # e.g. from selectall_arrayref
        $dbh->_dbix_l4p_debug($h, 2, "prepare($h->{dbh_no}.$ctr)", $args[0]);
    }

    my $sth = $dbh->SUPER::prepare(@args);
    if ($sth) {
        $sth->{private_DBIx_Log4perl} = $h;
        $sth->{private_DBIx_st_no} = $ctr;
    }

    return $sth;
}

sub prepare_cached {
    my($dbh, @args) = @_;

    my $h = $dbh->{private_DBIx_Log4perl};
    my $ctr = $h->{new_stmt_no}();
    if (($h->{logmask} & (DBIX_L4P_LOG_INPUT|DBIX_L4P_LOG_SQL)) &&
            (caller !~ /^DBIx::Log4perl/o) &&
                (caller !~ /^DBD::/o)) { # e.g. from selectall_arrayref
        $dbh->_dbix_l4p_debug($h, 2,
                              "prepare_cached($h->{dbh_no}.$ctr)", $args[0]);
    }

    my $sth = $dbh->SUPER::prepare_cached(@args);
    if ($sth) {
        $sth->{private_DBIx_Log4perl} = $h;
        $sth->{private_DBIx_st_no} = $ctr;
    }
    return $sth;
}

sub do {
    my ($dbh, @args) = @_;
    my $h = $dbh->{private_DBIx_Log4perl};

    $h->{Statement} = $args[0];
    $dbh->_dbix_l4p_debug($h, 2, "do($h->{dbh_no})", @args)
        if ($h->{logmask} & (DBIX_L4P_LOG_INPUT|DBIX_L4P_LOG_SQL));

    my $affected = $dbh->SUPER::do(@args);

    if (!defined($affected)) {
        $dbh->_dbix_l4p_error(2, 'do error for ', @args)
            if (($h->{logmask} & DBIX_L4P_LOG_ERRCAPTURE) &&
                    !($h->{logmask} & DBIX_L4P_LOG_INPUT)); # not already logged
    } elsif (defined($affected) && $affected eq '0E0' &&
                 ($h->{logmask} & DBIX_L4P_LOG_WARNINGS)) {
        $dbh->_dbix_l4p_warning(2, 'no effect from ', @args);
    } elsif (($affected ne '0E0') && ($h->{logmask} & DBIX_L4P_LOG_INPUT)) {
        $dbh->_dbix_l4p_debug($h, 2, "affected($h->{dbh_no})", $affected);
        $dbh->_dbix_l4p_debug($h, 2, "\t" . $dbh->SUPER::errstr)
            if (!defined($affected));
    }
    return $affected;
}

sub selectrow_array {
    my ($dbh, @args) = @_;

    my $h = $dbh->{private_DBIx_Log4perl};

    if ($h->{logmask} & (DBIX_L4P_LOG_INPUT|DBIX_L4P_LOG_SQL)) {
        if ((scalar(@args) > 0) && (ref $args[0])) {
            $dbh->_dbix_l4p_debug($h,
                2,
                "selectrow_array($h->{dbh_no}." .
                    $args[0]->{private_DBIx_st_no} . ")", @args);
        } else {
            $dbh->_dbix_l4p_debug($h, 2,
                                  "selectrow_array($h->{dbh_no})", @args);
        }
    }

    if (wantarray) {
	my @ret = $dbh->SUPER::selectrow_array(@args);
	$dbh->_dbix_l4p_debug($h, 2, "result($h->{dbh_no})", @ret)
	  if ($h->{logmask} & DBIX_L4P_LOG_OUTPUT);
	return @ret;

    } else {
	my $ret = $dbh->SUPER::selectrow_array(@args);
	$dbh->_dbix_l4p_debug($h, 2, "result($h->{dbh_no})", $ret)
	  if ($h->{logmask} & DBIX_L4P_LOG_OUTPUT);
	return $ret;
    }
}

sub selectrow_arrayref {
    my ($dbh, @args) = @_;

    my $h = $dbh->{private_DBIx_Log4perl};

    if ($h->{logmask} & (DBIX_L4P_LOG_INPUT|DBIX_L4P_LOG_SQL)) {
        if ((scalar(@args) > 0) && (ref $args[0])) {
            $dbh->_dbix_l4p_debug(
                $h, 2,
                "selectrow_arrayref($h->{dbh_no}." .
                    $args[0]->{private_DBIx_st_no} . ")", @args);
        } else {
            $dbh->_dbix_l4p_debug(
                $h, 2, "selectrow_arrayref($h->{dbh_no})", @args);
        }
    }

    my $ref = $dbh->SUPER::selectrow_arrayref(@args);
    $dbh->_dbix_l4p_debug($h, 2, "result($h->{dbh_no})", $ref)
      if ($h->{logmask} & DBIX_L4P_LOG_OUTPUT);
    return $ref;
}

sub selectrow_hashref {
    my ($dbh, @args) = @_;

    my $h = $dbh->{private_DBIx_Log4perl};

    if ($h->{logmask} & (DBIX_L4P_LOG_INPUT|DBIX_L4P_LOG_SQL)) {
        if ((scalar(@args) > 0) && (ref $args[0])){
            $dbh->_dbix_l4p_debug(
                $h, 2,
                "selectrow_hashref($h->{dbh_no}." .
                    $args[0]->{private_DBIx_st_no} . ")", @args)
        } else {
            $dbh->_dbix_l4p_debug($h, 2,
                                  "selectrow_hashref($h->{dbh_no})", @args);
        }
    }

    my $ref = $dbh->SUPER::selectrow_hashref(@args);
    # no need to show result - fetch will do this
    return $ref;

}

sub selectall_arrayref {
    my ($dbh, @args) = @_;

    my $h = $dbh->{private_DBIx_Log4perl};
    if ($h->{logmask} & (DBIX_L4P_LOG_INPUT|DBIX_L4P_LOG_SQL)) {
        if ((scalar(@args) > 0) && (ref $args[0])) {
            $dbh->_dbix_l4p_debug(
                $h, 2,
                "selectall_arrayref($h->{dbh_no}." .
                    $args[0]->{private_DBIx_st_no} . ")", @args);
        } else {
            $dbh->_dbix_l4p_debug(
                $h, 2, "selectall_arrayref($h->{dbh_no})", @args);
        }
    }

    my $ref = $dbh->SUPER::selectall_arrayref(@args);
    $dbh->_dbix_l4p_debug($h, 2, "result($h->{dbh_no})", $ref)
      if ($h->{logmask} & DBIX_L4P_LOG_OUTPUT);
    return $ref;
}

sub selectall_hashref {
    my ($dbh, @args) = @_;

    my $h = $dbh->{private_DBIx_Log4perl};
    if ($h->{logmask} & (DBIX_L4P_LOG_INPUT|DBIX_L4P_LOG_SQL)) {
        if ((scalar(@args) > 0) && (ref $args[0])) {
            $dbh->_dbix_l4p_debug(
                $h, 2,
                "selectall_hashref($h->{dbh_no}." .
                    $args[0]->{private_DBIx_st_no} . ")", @args);
        } else {
            $dbh->_dbix_l4p_debug($h, 2,
                                  "selectall_hashref($h->{dbh_no})", @args);
        }
    }

    my $ref = $dbh->SUPER::selectall_hashref(@args);
    # no need to show result - fetch will do this
    return $ref;

}

sub _make_counter {
    my $start = shift;
    return sub {$start++}
};

sub connected {

    my ($dbh, $dsn, $user, $pass, $attr) = @_;

    my %h = ();
    $h{dbh_no} = &$_counter();
    $h{new_stmt_no} = _make_counter(0); # get a new stmt count for this dbh

    if ($attr) {
      # check we have not got dbix_l4p_init without dbix_l4p_log or vice versa
	my ($a, $b) = (exists($attr->{dbix_l4p_init}),
		       exists($attr->{dbix_l4p_class}));
	croak ('dbix_l4p_init specified without dbix_l4p_class or vice versa')
	  if (($a xor $b));
	# if passed a Log4perl log handle use that
	if (exists($attr->{dbix_l4p_logger})) {
	    $h{logger} = $attr->{dbix_l4p_logger};
	} elsif ($a && $b) {
	    Log::Log4perl->init($attr->{dbix_l4p_init});
	    $h{logger} = Log::Log4perl->get_logger($attr->{dbix_l4p_class});
	    $h{init} = $attr->{dbix_l4p_init};
	    $h{class} = $attr->{dbix_l4p_class};
	} else {
	    $h{logger} = Log::Log4perl->get_logger('DBIx::Log4perl');
	}
	# save log mask
	$h{logmask} = $attr->{dbix_l4p_logmask}
	  if (exists($attr->{dbix_l4p_logmask}));
        # save error regexp
        $h{err_regexp} = $attr->{dbix_l4p_ignore_err_regexp}
            if (exists($attr->{dbix_l4p_ignore_err_regexp}));
	# remove our attrs from connection attrs
	#delete $attr->{dbix_l4p_init};
	#delete $attr->{dbix_l4p_class};
	#delete $attr->{dbix_l4p_logger};
	#delete $attr->{dbix_l4p_logmask};
        #delete $attr->{dbix_l4p_ignore_err_regexp};
    }
    # take global log mask if non defined
    $h{logmask} = $LogMask unless (exists($h{logmask}));

    $h{logger} = Log::Log4perl->get_logger('DBIx::Log4perl')
        unless (exists($h{logger}));
    $_glogger = $h{logger};

    # make sure you don't change the depth before calling get_logger:
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 4;

    $h{dbd_specific} = 0;
    $h{driver} = $dbh->{Driver}->{Name};

    $dbh->{private_DBIx_Log4perl} = \%h;

    if ($h{logmask} & DBIX_L4P_LOG_CONNECT) {
        local $Data::Dumper::Indent = 0;
	$h{logger}->debug(
            "connect($h{dbh_no}): " .
                (defined($dsn) ? $dsn : '') . ', ' .
                    (defined($user) ? $user : '') . ', ' .
            Data::Dumper->Dump([$attr], [qw(attr)]));
	no strict 'refs';
	my $v = "DBD::" . $dbh->{Driver}->{Name} . "::VERSION";
	$h{logger}->info("DBI: " . $DBI::VERSION,
			 ", DBIx::Log4perl: " . $DBIx::Log4perl::VERSION .
			   ", Driver: " . $h{driver} . "(" .
			     $$v . ")");
    }

    #
    # If capturing errors then save any error handler and set_err Handler
    # passed to us and replace with our own.
    #
    if ($h{logmask} & DBIX_L4P_LOG_ERRCAPTURE) {
	$h{HandleError} = $attr->{HandleError}
	    if (exists($attr->{HandleError}));
	$h{HandleSetErr} = $attr->{HandleSetErr}
	    if (exists($attr->{HandleSetErr}));
	$dbh->{HandleError} = \&_error_handler;
	$dbh->{HandleSetErr} = \&_set_err_handler;
    }
    return;

}
sub clone {
    my ($dbh, @args) = @_;

    my $h = $dbh->{private_DBIx_Log4perl};
    if ($h->{logmask} & DBIX_L4P_LOG_CONNECT) {
        $dbh->_dbix_l4p_debug($h, 2, "clone($h->{dbh_no})", @args);
    }

    return $dbh->SUPER::clone(@args);
}

sub disconnect {
    my $dbh = shift;

    if ($dbh) {
	my $h;
	eval {
	    # Avoid
	    # (in cleanup) Can't call method "FETCH" on an undefined value
	    $h = $dbh->{private_DBIx_Log4perl};
	};
	if (!$@ && $h && defined($h->{logger})) {
            if ($h->{logmask} & DBIX_L4P_LOG_CONNECT) {
                local $Log::Log4perl::caller_depth =
                    $Log::Log4perl::caller_depth + 2;
                $dbh->_dbix_l4p_debug($h, 2, "disconnect($h->{dbh_no})");
            }
	}
    }
    return $dbh->SUPER::disconnect;

}

sub begin_work {
    my $dbh = shift;
    my $h = $dbh->{private_DBIx_Log4perl};

    $dbh->_dbix_l4p_debug($h, 2, "start transaction($h->{dbh_no})")
        if ($h->{logmask} & DBIX_L4P_LOG_TXN);

    return $dbh->SUPER::begin_work;
}

sub rollback {
    my $dbh = shift;
    my $h = $dbh->{private_DBIx_Log4perl};

    $dbh->_dbix_l4p_debug($h, 2, "roll back($h->{dbh_no})")
        if ($h->{logmask} & DBIX_L4P_LOG_TXN);

    return $dbh->SUPER::rollback;
}

sub commit {
    my $dbh = shift;

    my $h = $dbh->{private_DBIx_Log4perl};
    $dbh->_dbix_l4p_debug($h, 2, "commit($h->{dbh_no})")
        if ($h->{logmask} & DBIX_L4P_LOG_TXN);

    return $dbh->SUPER::commit;
}

sub last_insert_id {
    my ($dbh, @args) = @_;
    my $h = $dbh->{private_DBIx_Log4perl};

    $dbh->_dbix_l4p_debug($h, 2,
	sub {Data::Dumper->Dump([\@args], ["last_insert_id($h->{dbh_no})"])})
      if ($h->{logmask} & DBIX_L4P_LOG_INPUT);

    my $ret = $dbh->SUPER::last_insert_id(@args);
    $dbh->_dbix_l4p_debug($h, 2, sub {"\t" . DBI::neat($ret)})
      if ($h->{logmask} & DBIX_L4P_LOG_INPUT);
    return $ret;
}


#
# Error handler to capture errors and log them
# Whatever, errors are passed on.
# if the user of DBIx::Log4perl passed in an error handler that is called
# before returning.
#
sub _error_handler {
    my ($msg, $handle, $method_ret) = @_;

    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;

    my $dbh = $handle;
    my $lh;
    my $h = $handle->{private_DBIx_Log4perl};
    my $out = '';

    $lh = $_glogger;
    $lh = $h->{logger} if ($h && exists($h->{logger}));
    return 0 if (!$lh);

    if ($h && exists($h->{err_regexp})) {
        if ($dbh->err =~ $h->{err_regexp}) {
            goto FINISH;
        }
    }
    # start with error message, state and err
    $out .=  '  ' . '=' x 60 . "\n  $msg\n";
    $out .= "err() = " . $handle->err . "\n";
    $out .= "state() = " . $handle->state . "\n";

    if ($DBI::lasth) {
	$out .= "  lasth type: $DBI::lasth->{Type}\n"
	    if ($DBI::lasth->{Type});
	$out .= "  lasth Statement ($DBI::lasth):\n    " .
	    "$DBI::lasth->{Statement}\n"
		if ($DBI::lasth->{Statement});
    }
    # get db handle if we have an st
    my $type = $handle->{Type};
    my $sql;
    if ($type eq 'st') {	# given statement handle
	$dbh = $handle->{Database};
	$sql = $handle->{Statement};
    } else {
	# given db handle
	# We've got other stmts under this db but we'll deal with those later
	$sql = 'Possible SQL: ';
	$sql .= "/$h->{Statement}/" if (exists($h->{Statement}));
	$sql .= "/$dbh->{Statement}/"
	  if ($dbh->{Statement} &&
		(exists($h->{Statement}) &&
		 ($dbh->{Statement} ne $h->{Statement})));
    }

    my $dbname = exists($dbh->{Name}) ? $dbh->{Name} : "";
    my $username = exists($dbh->{Username}) ? $dbh->{Username} : "";
    $out .= "  DB: $dbname, Username: $username\n";
    $out .= "  handle type: $type\n  SQL: " . DBI::neat($sql) . "\n";
    $out .= '  db Kids=' . $dbh->{Kids} .
	', ActiveKids=' . $dbh->{ActiveKids} . "\n";
    $out .= "  DB errstr: " . $handle->errstr . "\n"
	if ($handle->errstr && ($handle->errstr ne $msg));

    if (exists($h->{ParamValues}) && $h->{ParamValues}) {
	$out .= "  ParamValues captured in HandleSetErr:\n    ";
	foreach (sort keys %{$h->{ParamValues}}) {
	    $out .= "$_=" . DBI::neat($h->{ParamValues}->{$_}) . ",";
	}
	$out .= "\n";
    }
    if ($type eq 'st') {
	my $str = "";
	if ($handle->{ParamValues}) {
	    foreach (sort keys %{$handle->{ParamValues}}) {
		$str .= "$_=" . DBI::neat($handle->{ParamValues}->{$_}) . ",";
	    }
	}
	$out .= "  ParamValues: $str\n";
	$out .= "  " .
	  Data::Dumper->Dump([$handle->{ParamArrays}], ['ParamArrays'])
	      if ($handle->{ParamArrays});
    }
    my @substmts;
    # get list of statements under the db
    push @substmts, $_ for (grep { defined } @{$dbh->{ChildHandles}});
    $out .= "  " . scalar(@substmts) . " sub statements:\n";
    if (scalar(@substmts)) {
	foreach my $stmt (@substmts) {
	    $out .= "  stmt($stmt):\n";
	    $out .= '    SQL(' . $stmt->{Statement} . ")\n  "
		if ($stmt->{Statement} &&
		    (exists($h->{Statement}) &&
		     ($h->{Statement} ne $stmt->{Statement})));
	    if (exists($stmt->{ParamValues}) && $stmt->{ParamValues}) {
		$out .= '   Params(';
		foreach (sort keys %{$stmt->{ParamValues}}) {
		    $out .= "$_=" . DBI::neat($stmt->{ParamValues}->{$_}) . ",";
		}
		$out .= ")\n";
	    }
	}
    }

    if (exists($dbh->{Callbacks})) {
        $out .= "  Callbacks exist for " .
            join(",", keys(%{$dbh->{Callbacks}})) . "\n";
    }
    local $Carp::MaxArgLen = 256;
    $out .= "  " .Carp::longmess("DBI error trap");
    $out .= "  " . "=" x 60 . "\n";
    $lh->fatal($out);

  FINISH:
    if ($h && exists($h->{ErrorHandler})) {
      return $h->{ErrorHandler}($msg, $handle, $method_ret);
    } else {
      return 0;			# pass error on
    }
}

#
# set_err handler so we can capture ParamValues before a statement
# is destroyed.
# If the use of DBIx::Log4perl passed in an error handler that is
# called before returning.
#
sub _set_err_handler {
    my ($handle, $err, $errstr, $state, $method) = @_;

    # Capture ParamValues
    if ($handle) {
	my $h = $handle->{private_DBIx_Log4perl};
	$h->{ParamValues} = $handle->{ParamValues}
	    if (exists($handle->{ParamValues}));
	return $h->{HandleSetErr}(@_) if (exists($h->{HandleSetErr}));
    }
    return 0;
}


1;
