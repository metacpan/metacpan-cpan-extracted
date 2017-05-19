#line 1
package DBD::Mock;

sub import {
    shift;
    $DBI::connect_via = "DBD::Mock::Pool::connect" if (@_ && lc($_[0]) eq "pool");
}

# --------------------------------------------------------------------------- #
#   Copyright (c) 2004-2007 Stevan Little, Chris Winters
#   (spawned from original code Copyright (c) 1994 Tim Bunce)
# --------------------------------------------------------------------------- #
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
# --------------------------------------------------------------------------- #

use 5.008001;

use strict;
use warnings;

require DBI;

our $VERSION = '1.39';

our $drh    = undef;    # will hold driver handle
our $err    = 0;        # will hold any error codes
our $errstr = '';       # will hold any error messages

sub driver {
    return $drh if defined $drh;
    my ($class, $attributes) = @_;
    $attributes = {} unless (defined($attributes) && (ref($attributes) eq 'HASH'));
    $drh = DBI::_new_drh( "${class}::dr", {
        Name        => 'Mock',
        Version     => $DBD::Mock::VERSION,
        Attribution => 'DBD Mock driver by Chris Winters & Stevan Little (orig. from Tim Bunce)',
        Err         => \$DBD::Mock::err,
        Errstr      => \$DBD::Mock::errstr,
        # mock attributes
        mock_connect_fail => 0,
        # and pass in any extra attributes given
        %{$attributes}
    });
    return $drh;
}

sub CLONE { undef $drh }

# NOTE:
# this feature is still quite experimental. It is defaulted to
# be off, but it can be turned on by doing this:
#    $DBD::Mock::AttributeAliasing++;
# and then turned off by doing:
#    $DBD::Mock::AttributeAliasing = 0;
# we shall see how this feature works out.

our $AttributeAliasing = 0;

my %AttributeAliases = (
    mysql => {
        db => {
            # aliases can either be a string which is obvious
            mysql_insertid => 'mock_last_insert_id'
        },
        st => {
            # but they can also be a subroutine reference whose
            # first argument will be either the $dbh or the $sth
            # depending upon which context it is aliased in.
            mysql_insertid => sub { (shift)->{Database}->{'mock_last_insert_id'} }
        }
    },
);

sub _get_mock_attribute_aliases {
    my ($dbname) = @_;
    (exists $AttributeAliases{lc($dbname)})
        || die "Attribute aliases not available for '$dbname'";
    return $AttributeAliases{lc($dbname)};
}

sub _set_mock_attribute_aliases {
    my ($dbname, $dbh_or_sth, $key, $value) = @_;
    return $AttributeAliases{lc($dbname)}->{$dbh_or_sth}->{$key} = $value;
}

## Some useful constants

use constant NULL_RESULTSET => [[]];


########################################
# DRIVER

package
    DBD::Mock::dr;

use strict;
use warnings;

$DBD::Mock::dr::imp_data_size = 0;

sub connect {
    my ($drh, $dbname, $user, $auth, $attributes) = @_;
    if ($drh->{'mock_connect_fail'} == 1) {
        $drh->DBI::set_err(1, "Could not connect to mock database");
        return;
    }
    $attributes ||= {};

    if ($dbname && $DBD::Mock::AttributeAliasing) {
        # this is the DB we are mocking
        $attributes->{mock_attribute_aliases} = DBD::Mock::_get_mock_attribute_aliases($dbname);
        $attributes->{mock_database_name} = $dbname;
    }

    # holds statement parsing coderefs/objects
    $attributes->{mock_parser} = [];
    # holds all statements applied to handle until manually cleared
    $attributes->{mock_statement_history} = [];
    # ability to fake a failed DB connection
    $attributes->{mock_can_connect} = 1;
    # ability to make other things fail :)
    $attributes->{mock_can_prepare} = 1;
    $attributes->{mock_can_execute} = 1;
    $attributes->{mock_can_fetch}   = 1;

    my $dbh = DBI::_new_dbh($drh, {Name => $dbname})
        || return;

    return $dbh;
}

sub FETCH {
    my ($drh, $attr) = @_;
    if ($attr =~ /^mock_/) {
        if ($attr eq 'mock_connect_fail') {
            return $drh->{'mock_connect_fail'};
        }
        elsif ($attr eq 'mock_data_sources') {
            unless (defined $drh->{'mock_data_sources'}) {
                $drh->{'mock_data_sources'} = [ 'DBI:Mock:' ];
            }
            return $drh->{'mock_data_sources'};
        }
        else {
            return $drh->SUPER::FETCH($attr);
        }
    }
    else {
        return $drh->SUPER::FETCH($attr);
    }
}

sub STORE {
    my ($drh, $attr, $value) = @_;
    if ($attr =~ /^mock_/) {
        if ($attr eq 'mock_connect_fail') {
            return $drh->{'mock_connect_fail'} = $value ? 1 : 0;
        }
        elsif ($attr eq 'mock_data_sources') {
            if (ref($value) ne 'ARRAY') {
                $drh->DBI::set_err(1, "You must pass an array ref of data sources");
                return;
            }
            return $drh->{'mock_data_sources'} = $value;
        }
        elsif ($attr eq 'mock_add_data_sources') {
            return push @{$drh->{'mock_data_sources'}} => $value;
        }
    }
    else {
        return $drh->SUPER::STORE($attr, $value);
    }
}

sub data_sources {
    my $drh = shift;
    return map { (/^DBI\:Mock\:/i) ? $_ : "DBI:Mock:$_" } @{$drh->FETCH('mock_data_sources')};
}

# Necessary to support DBI < 1.34
# from CPAN RT bug #7057

sub disconnect_all {
    # no-op
}

sub DESTROY { undef }

########################################
# DATABASE

package
    DBD::Mock::db;

use strict;
use warnings;

$DBD::Mock::db::imp_data_size = 0;

sub ping {
     my ( $dbh ) = @_;
     return $dbh->{mock_can_connect};
}

sub last_insert_id {
     my ( $dbh ) = @_;
     return $dbh->{mock_last_insert_id};
}

sub get_info {
    my ( $dbh, $attr ) = @_;
    $dbh->{mock_get_info} ||= {};
    return $dbh->{mock_get_info}{ $attr };
}

sub prepare {
    my($dbh, $statement) = @_;

    unless ($dbh->{mock_can_connect}) {
        $dbh->DBI::set_err(1, "No connection present");
        return;
    }
    unless ($dbh->{mock_can_prepare}) {
        $dbh->DBI::set_err(1, "Cannot prepare");
        return;
    }
    $dbh->{mock_can_prepare}++ if $dbh->{mock_can_prepare} < 0;


    eval {
        foreach my $parser ( @{ $dbh->{mock_parser} } ) {
            if (ref($parser) eq 'CODE') {
                $parser->($statement);
            }
            else {
                $parser->parse($statement);
            }
        }
    };
    if ($@) {
        my $parser_error = $@;
        chomp $parser_error;
        $dbh->DBI::set_err(1, "Failed to parse statement. Error: ${parser_error}. Statement: ${statement}");
        return;
    }

    if (my $session = $dbh->FETCH('mock_session')) {
        eval {
            $session->verify_statement($dbh, $statement);
        };
        if ($@) {
            my $session_error = $@;
            chomp $session_error;
            $dbh->DBI::set_err(1, "Session Error: ${session_error}. Statement: ${statement}");
            return;
        }
    }

    my $sth = DBI::_new_sth($dbh, { Statement => $statement });

    $sth->trace_msg("Preparing statement '${statement}'\n", 1);

    my %track_params = (statement => $statement);

    # If we have available resultsets seed the tracker with one

    my $rs;
    if ( my $all_rs = $dbh->{mock_rs} ) {
        if ( my $by_name = $all_rs->{named}{$statement} ) {
            # We want to copy this, because it is meant to be reusable
            $rs = [ @{$by_name->{results}} ];
            if (exists $by_name->{failure}) {
                $track_params{failure} = [ @{$by_name->{failure}} ];
            }
        }
        else {
            $rs = shift @{$all_rs->{ordered}};
        }
    }

    if (ref($rs) eq 'ARRAY' && scalar(@{$rs}) > 0 ) {
        my $fields = shift @{$rs};
        $track_params{return_data} = $rs;
        $track_params{fields}      = $fields;
        $sth->STORE(NAME           => $fields);
        $sth->STORE(NUM_OF_FIELDS  => scalar @{$fields});
    }
    else {
        $sth->trace_msg("No return data set in DBH\n", 1);
    }

     # do not allow a statement handle to be created if there is no
     # connection present.

    unless ($dbh->FETCH('Active')) {
        $dbh->DBI::set_err(1, "No connection present");
        return;
    }

    # This history object will track everything done to the statement

    my $history = DBD::Mock::StatementTrack->new(%track_params);
    $sth->STORE(mock_my_history => $history);

    # ...now associate the history object with the database handle so
    # people can browse the entire history at once, even for
    # statements opened and closed in a black box

    my $all_history = $dbh->FETCH('mock_statement_history');
    push @{$all_history}, $history;

    return $sth;
}

*prepare_cached = \&prepare;

{
    my $begin_work_commit;
    sub begin_work {
        my $dbh = shift;
        if ($dbh->FETCH('AutoCommit')) {
            $dbh->STORE('AutoCommit', 0);
            $begin_work_commit = 1;
            my $sth = $dbh->prepare( 'BEGIN WORK' );
            my $rc = $sth->execute();
            $sth->finish();
            return $rc;
        }
        else {
            return $dbh->set_err(1, 'AutoCommit is off, you are already within a transaction');
        }
    }

    sub commit {
        my $dbh = shift;
        if ($dbh->FETCH('AutoCommit') && $dbh->FETCH('Warn')) {
            return $dbh->set_err(1, "commit ineffective with AutoCommit" );
        }

        my $sth = $dbh->prepare( 'COMMIT' );
        my $rc = $sth->execute();
        $sth->finish();

        if ($begin_work_commit) {
            $dbh->STORE('AutoCommit', 1);
            $begin_work_commit = 0;
        }

        return $rc;
    }

    sub rollback {
        my $dbh = shift;
        if ($dbh->FETCH('AutoCommit') && $dbh->FETCH('Warn')) {
            return $dbh->set_err(1, "rollback ineffective with AutoCommit" );
        }

        my $sth = $dbh->prepare( 'ROLLBACK' );
        my $rc = $sth->execute();
        $sth->finish();

        if ($begin_work_commit) {
            $dbh->STORE('AutoCommit', 1);
            $begin_work_commit = 0;
        }

        return $rc;
    }
}

# NOTE:
# this method should work in most cases, however it does
# not exactly follow the DBI spec in the case of error
# handling. I am not sure if that level of detail is
# really nessecary since it is a weird error conditon
# which causes it to fail anyway. However if you find you do need it,
# then please email me about it. I think it would be possible
# to mimic it by accessing the DBD::Mock::StatementTrack
# object directly.
sub selectcol_arrayref {
    my ($dbh, $query, $attrib, @bindvalues) = @_;
    # get all the columns ...
    my $a_ref = $dbh->selectall_arrayref($query, $attrib, @bindvalues);

    # if we get nothing back, or dont get an
    # ARRAY ref back, then we can assume
    # something went wrong, and so return undef.
    return undef unless defined $a_ref || ref($a_ref) ne 'ARRAY';

    my @cols = 0;
    if (ref $attrib->{Columns} eq 'ARRAY') {
        @cols = map { $_ - 1 } @{$attrib->{Columns}};
    }

    # if we do get something then we
    # grab all the columns out of it.
    return [ map { @$_[@cols] } @{$a_ref} ]
}

sub FETCH {
    my ( $dbh, $attrib, $value ) = @_;
    $dbh->trace_msg( "Fetching DB attrib '$attrib'\n" );

    if ($attrib eq 'Active') {
        return $dbh->{mock_can_connect};
    }
    elsif ($attrib eq 'mock_all_history') {
        return $dbh->{mock_statement_history};
    }
    elsif ($attrib eq 'mock_all_history_iterator') {
        return DBD::Mock::StatementTrack::Iterator->new($dbh->{mock_statement_history});
    }
    elsif ($attrib =~ /^mock/) {
        return $dbh->{$attrib};
    }
    elsif ($attrib =~ /^(private_|dbi_|dbd_|[A-Z])/ ) {
        $dbh->trace_msg("... fetching non-driver attribute ($attrib) that DBI handles\n");
        return $dbh->SUPER::FETCH($attrib);
    }
    else {
        if ($dbh->{mock_attribute_aliases}) {
            if (exists ${$dbh->{mock_attribute_aliases}->{db}}{$attrib}) {
                my $mock_attrib = $dbh->{mock_attribute_aliases}->{db}->{$attrib};
                if (ref($mock_attrib) eq 'CODE') {
                   return $mock_attrib->($dbh);
                }
                else {
                    return $dbh->FETCH($mock_attrib);
                }
            }
        }
        $dbh->trace_msg( "... fetching non-driver attribute ($attrib) that DBI doesn't handle\n");
        return $dbh->{$attrib};
    }
}

sub STORE {
    my ( $dbh, $attrib, $value ) = @_;
    $dbh->trace_msg( "Storing DB attribute '$attrib' with '" . (defined($value) ? $value : 'undef') . "'\n" );

    if ($attrib eq 'AutoCommit') {
        # These are magic DBI values that say we can handle AutoCommit
        # internally as well
        $value = ($value) ? -901 : -900;
    }

    if ( $attrib eq 'mock_clear_history' ) {
        if ( $value ) {
            $dbh->{mock_statement_history} = [];
        }
        return [];
    }
    elsif ( $attrib eq 'mock_add_parser' ) {
        my $parser_type = ref($value);
        my $is_valid_parser;

        if ($parser_type eq 'CODE') {
            $is_valid_parser++;
        }
        elsif ($parser_type && $parser_type !~ /^(ARRAY|HASH|SCALAR)$/) {
            $is_valid_parser = eval { $parser_type->can( 'parse' ) };
        }

        unless ($is_valid_parser) {
            my $error = "Parser must be a code reference or object with 'parse()' " .
                        "method (Given type: '$parser_type')";
            $dbh->DBI::set_err(1, $error);
            return;
        }
        push @{$dbh->{mock_parser}}, $value;
        return $value;
    }
    elsif ( $attrib eq 'mock_add_resultset' ) {
        $dbh->{mock_rs} ||= { named   => {},
                              ordered => [] };
        if ( ref $value eq 'ARRAY' ) {
            my @copied_values = @{$value};
            push @{$dbh->{mock_rs}{ordered}}, \@copied_values;
            return \@copied_values;
        }
        elsif ( ref $value eq 'HASH' ) {
            my $name = $value->{sql};
            unless ($name) {
                die "Indexing resultset by name requires passing in 'sql' ",
                    "as hashref key to 'mock_add_resultset'.\n";
            }
            my @copied_values = @{$value->{results}};
            $dbh->{mock_rs}{named}{$name} = {
                results => \@copied_values,
            };
            if ( exists $value->{failure} ) {
                $dbh->{mock_rs}{named}{$name}{failure} = [
                    @{$value->{failure}},
                ];
            }
            return \@copied_values;
        }
        else {
            die "Must provide an arrayref or hashref when adding ",
                "resultset via 'mock_add_resultset'.\n";
        }
    }
    elsif ($attrib eq 'mock_start_insert_id') {
        if ( ref $value eq 'ARRAY' ) {
            $dbh->{mock_last_insert_ids} = {} unless $dbh->{mock_last_insert_ids};
            $dbh->{mock_last_insert_ids}{$value->[0]} = $value->[1];
        }
        else {
            # we start at one minus the start id
            # so that the increment works
            $dbh->{mock_last_insert_id} = $value - 1;
        }

    }
    elsif ($attrib eq 'mock_session') {
        (ref($value) && UNIVERSAL::isa($value, 'DBD::Mock::Session'))
            || die "Only DBD::Mock::Session objects can be placed into the 'mock_session' slot\n"
                if defined $value;
        $dbh->{mock_session} = $value;
    }
    elsif ($attrib =~ /^mock_(add_)?data_sources/) {
        $dbh->{Driver}->STORE($attrib, $value);
    }
    elsif ($attrib =~ /^mock/) {
        return $dbh->{$attrib} = $value;
    }
    elsif ($attrib =~ /^(private_|dbi_|dbd_|[A-Z])/ ) {
        $dbh->trace_msg("... storing non-driver attribute ($attrib) with value ($value) that DBI handles\n");
        return $dbh->SUPER::STORE($attrib, $value);
    }
  else {
      $dbh->trace_msg("... storing non-driver attribute ($attrib) with value ($value) that DBI won't handle\n");
      return $dbh->{$attrib} = $value;
  }
}

sub DESTROY {
    my ($dbh) = @_;
    if ( my $session = $dbh->{mock_session} ) {
        if ( $session->has_states_left ) {
            die "DBH->finish called when session still has states left\n";
        }
    }
}

sub disconnect {
    my ($dbh) = @_;
    if ( my $session = $dbh->{mock_session} ) {
        if ( $session->has_states_left ) {
            die "DBH->finish called when session still has states left\n";
        }
    }
}

########################################
# STATEMENT

package
    DBD::Mock::st;

use strict;
use warnings;

$DBD::Mock::st::imp_data_size = 0;

sub bind_col {
    my ($sth, $param_num, $ref, $attr) = @_;

    my $tracker = $sth->FETCH( 'mock_my_history' );
    $tracker->bind_col( $param_num, $ref );
    return 1;
}

sub bind_param {
    my ($sth, $param_num, $val, $attr) = @_;
    my $tracker = $sth->FETCH( 'mock_my_history' );
    $tracker->bound_param( $param_num, $val );
    return 1;
}

sub bind_param_inout {
    my ($sth, $param_num, $val, $max_len) = @_;
    # check that $val is a scalar ref
    (UNIVERSAL::isa($val, 'SCALAR'))
        || $sth->{Database}->DBI::set_err(1, "need a scalar ref to bind_param_inout, not $val");
    # check for positive $max_len
    ($max_len > 0)
        || $sth->{Database}->DBI::set_err(1, "need to specify a maximum length to bind_param_inout");
    my $tracker = $sth->FETCH( 'mock_my_history' );
    $tracker->bound_param( $param_num, $val );
    return 1;
}

sub execute {
    my ($sth, @params) = @_;
    my $dbh = $sth->{Database};

    unless ($dbh->{mock_can_connect}) {
        $dbh->DBI::set_err(1, "No connection present");
        return 0;
    }
    unless ($dbh->{mock_can_execute}) {
        $dbh->DBI::set_err(1, "Cannot execute");
        return 0;
    }
    $dbh->{mock_can_execute}++ if $dbh->{mock_can_execute} < 0;

    my $tracker = $sth->FETCH( 'mock_my_history' );

    if ($tracker->has_failure()) {
        $dbh->DBI::set_err($tracker->get_failure());
        return 0;
    }

    if ( @params ) {
        $tracker->bind_params( @params );
    }

    if (my $session = $dbh->{mock_session}) {
        eval {
            $session->verify_bound_params($dbh, $tracker->bound_params());
            my $idx = $session->{state_index} - 1;
            my @results = @{$session->{states}->[$idx]->{results}};
            shift @results;
            $tracker->{return_data} = \@results;
        };
        if ($@) {
            my $session_error = $@;
            chomp $session_error;
            $dbh->DBI::set_err(1, "Session Error: ${session_error}");
            return;
        }
    }

    $tracker->mark_executed;
    my $fields = $tracker->fields;
    $sth->STORE( NUM_OF_PARAMS => $tracker->num_params );

    # handle INSERT statements and the mock_last_insert_ids
    # We should only increment these things after the last successful INSERT.
    # -RobK, 2007-10-12
#use Data::Dumper;warn Dumper $dbh->{mock_last_insert_ids};
    if ($dbh->{Statement} =~ /^\s*?insert\s+into\s+(\S+)/i) {
        if ( $dbh->{mock_last_insert_ids} && exists $dbh->{mock_last_insert_ids}{$1} ) {
            $dbh->{mock_last_insert_id} = $dbh->{mock_last_insert_ids}{$1}++;
        }
        else {
            $dbh->{mock_last_insert_id}++;
        }
    }
#warn "$dbh->{mock_last_insert_id}\n";

    # always return 0E0 for Selects
    if ($dbh->{Statement} =~ /^\s*?select/i) {
        return '0E0';
    }
    return ($sth->rows() || '0E0');
}

sub fetch {
    my ($sth) = @_;
    my $dbh = $sth->{Database};
    unless ($dbh->{mock_can_connect}) {
        $dbh->DBI::set_err(1, "No connection present");
        return;
    }
    unless ($dbh->{mock_can_fetch}) {
        $dbh->DBI::set_err(1, "Cannot fetch");
        return;
    }
    $dbh->{mock_can_fetch}++ if $dbh->{mock_can_fetch} < 0;

    my $tracker = $sth->FETCH( 'mock_my_history' );

    my $record = $tracker->next_record
        or return;

    if ( my @cols = $tracker->bind_cols() ) {
        for my $i ( grep { ref $cols[$_] } 0..$#cols ) {
            ${ $cols[$i] } = $record->[$i];
        }
    }

    return $record;
}

sub fetchrow_array {
    my ($sth) = @_;
    my $row = $sth->DBD::Mock::st::fetch();
    return unless ref($row) eq 'ARRAY';
    return @{$row};
}

sub fetchrow_arrayref {
    my ($sth) = @_;
    return $sth->DBD::Mock::st::fetch();
}

sub fetchrow_hashref {
    my ($sth, $name) = @_;
    my $dbh = $sth->{Database};
    # handle any errors since we are grabbing
    # from the tracker directly
    unless ($dbh->{mock_can_connect}) {
        $dbh->DBI::set_err(1, "No connection present");
        return;
    }
    unless ($dbh->{mock_can_fetch}) {
        $dbh->DBI::set_err(1, "Cannot fetch");
        return;
    }
    $dbh->{mock_can_fetch}++ if $dbh->{mock_can_fetch} < 0;

    # first handle the $name, it will default to NAME
    $name ||= 'NAME';
    # then fetch the names from the $sth (per DBI spec)
    my $fields = $sth->FETCH($name);

    # now check the tracker ...
    my $tracker = $sth->FETCH( 'mock_my_history' );
    # and collect the results
    if (my $record = $tracker->next_record()) {
        my @values = @{$record};
        return {
            map {
                $_ => shift(@values)
            } @{$fields}
        };
    }

    return undef;
}

#XXX Isn't this supposed to return an array of hashrefs? -RobK, 2007-10-15
sub fetchall_hashref {
    my ($sth, $keyfield) = @_;
    my $dbh = $sth->{Database};
    # handle any errors since we are grabbing
    # from the tracker directly
    unless ($dbh->{mock_can_connect}) {
        $dbh->DBI::set_err(1, "No connection present");
        return;
    }
    unless ($dbh->{mock_can_fetch}) {
        $dbh->DBI::set_err(1, "Cannot fetch");
        return;
    }
    $dbh->{mock_can_fetch}++ if $dbh->{mock_can_fetch} < 0;

    my $tracker = $sth->FETCH( 'mock_my_history' );
    my $rethash = {};

    # get the name set by
    my $name = $sth->{Database}->FETCH('FetchHashKeyName') || 'NAME';
    my $fields = $sth->FETCH($name);

    # check if $keyfield is not an integer
    if (!($keyfield =~ /^-?\d+$/)) {
        my $found = 0;
        # search for index of item that matches $keyfield
        foreach my $index (0 .. scalar(@{$fields})) {
            if ($fields->[$index] eq $keyfield) {
                $found++;
                # now make the keyfield the index
                $keyfield = $index;
                # and jump out of the loop :)
                last;
            }
        }
        unless ($found) {
            $dbh->DBI::set_err(1, "Could not find key field '$keyfield'");
            return;
        }
    }

    # now loop through all the records ...
    while (my $record = $tracker->next_record()) {
        # copy the values so as to preserve
        # the original record...
        my @values = @{$record};
        # populate the hash
        $rethash->{$record->[$keyfield]} = {
            map {
                $_ => shift(@values)
            } @{$fields}
        };
    }

    return $rethash;
}

sub finish {
    my ($sth) = @_;
    $sth->FETCH( 'mock_my_history' )->is_finished( 'yes' );
}

sub rows {
    my ($sth) = @_;
    $sth->FETCH('mock_num_rows');
}

sub FETCH {
    my ( $sth, $attrib ) = @_;
    $sth->trace_msg( "Fetching ST attribute '$attrib'\n" );
    my $tracker = $sth->{mock_my_history};
    $sth->trace_msg( "Retrieved tracker: " . ref( $tracker ) . "\n" );
    # NAME attributes
    if ( $attrib eq 'NAME' ) {
        return [ @{$tracker->fields} ];
    }
    elsif ( $attrib eq 'NAME_lc' ) {
        return [ map { lc($_) } @{$tracker->fields} ];
    }
    elsif ( $attrib eq 'NAME_uc' ) {
        return [ map { uc($_) } @{$tracker->fields} ];
    }
    # NAME_hash attributes
    elsif ( $attrib eq 'NAME_hash' ) {
        my $i = 0;
        return { map { $_ => $i++ } @{$tracker->fields} };
    }
    elsif ( $attrib eq 'NAME_hash_lc' ) {
        my $i = 0;
        return { map { lc($_) => $i++ } @{$tracker->fields} };
    }
    elsif ( $attrib eq 'NAME_hash_uc' ) {
        my $i = 0;
        return { map { uc($_) => $i++ } @{$tracker->fields} };
    }
    # others
    elsif ( $attrib eq 'NUM_OF_FIELDS' ) {
        return $tracker->num_fields;
    }
    elsif ( $attrib eq 'NUM_OF_PARAMS' ) {
        return $tracker->num_params;
    }
    elsif ( $attrib eq 'TYPE' ) {
        my $num_fields = $tracker->num_fields;
        return [ map { $DBI::SQL_VARCHAR } ( 0 .. $num_fields ) ];
    }
    elsif ( $attrib eq 'Active' ) {
        return $tracker->is_active;
    }
    elsif ( $attrib !~ /^mock/ ) {
        if ($sth->{Database}->{mock_attribute_aliases}) {
            if (exists ${$sth->{Database}->{mock_attribute_aliases}->{st}}{$attrib}) {
                my $mock_attrib = $sth->{Database}->{mock_attribute_aliases}->{st}->{$attrib};
                if (ref($mock_attrib) eq 'CODE') {
                   return $mock_attrib->($sth);
                }
                else {
                    return $sth->FETCH($mock_attrib);
                }
            }
        }
        return $sth->SUPER::FETCH( $attrib );
    }

    # now do our stuff...

    if ( $attrib eq 'mock_my_history' ) {
        return $tracker;
    }
    if ( $attrib eq 'mock_statement' ) {
        return $tracker->statement;
    }
    elsif ( $attrib eq 'mock_params' ) {
        return $tracker->bound_params;
    }
    elsif ( $attrib eq 'mock_records' ) {
        return $tracker->return_data;
    }
    elsif ( $attrib eq 'mock_num_records' || $attrib eq 'mock_num_rows' ) {
        return $tracker->num_rows;
    }
    elsif ( $attrib eq 'mock_current_record_num' ) {
        return $tracker->current_record_num;
    }
    elsif ( $attrib eq 'mock_fields' ) {
        return $tracker->fields;
    }
    elsif ( $attrib eq 'mock_is_executed' ) {
        return $tracker->is_executed;
    }
    elsif ( $attrib eq 'mock_is_finished' ) {
        return $tracker->is_finished;
    }
    elsif ( $attrib eq 'mock_is_depleted' ) {
        return $tracker->is_depleted;
    }
    else {
        die "I don't know how to retrieve statement attribute '$attrib'\n";
    }
}

sub STORE {
    my ($sth, $attrib, $value) = @_;
    $sth->trace_msg( "Storing ST attribute '$attrib'\n" );
    if ($attrib =~ /^mock/) {
        return $sth->{$attrib} = $value;
    }
    elsif ($attrib =~ /^NAME/) {
        # no-op...
        return;
    }
    else {
        $value ||= 0;
        return $sth->SUPER::STORE( $attrib, $value );
    }
}

sub DESTROY { undef }

##########################
# Database Pooling
# (Apache::DBI emulation)

package
    DBD::Mock::Pool;

use strict;
use warnings;

my $connection;

sub connect {
    return $connection if $connection;

    # according to the code before my tweaks, this could be a class
    # name, but it was never used - DR, 2008-11-08
    shift unless ref $_[0];

    my $drh = shift;
    return $connection = bless $drh->connect(@_), 'DBD::Mock::Pool::db';
}

package
    DBD::Mock::Pool::db;

use strict;
use warnings;

our @ISA = qw(DBI::db);

sub disconnect { 1 }

########################################
# TRACKER

package
    DBD::Mock::StatementTrack;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;
    # these params have default values
    # but can be overridden
    $params{return_data}  ||= [];
    $params{fields}       ||= [];
    $params{bound_params} ||= [];
    $params{statement}    ||= "";
    $params{failure}      ||= undef;
    # these params should never be overridden
    # and should always start out in a default
    # state to assure the sanity of this class
    $params{is_executed}        = 'no';
    $params{is_finished}        = 'no';
    $params{current_record_num} = 0;
    # NOTE:
    # changed from \%params here because that
    # would bind the hash sent in so that it
    # would reflect alterations in the object
    # this violates encapsulation
    my $self = bless { %params }, $class;
    return $self;
}

sub has_failure {
    my ($self) = @_;
    $self->{failure} ? 1 : 0;
}

sub get_failure {
    my ($self) = @_;
    @{$self->{failure}};
}

sub num_fields {
    my ($self) = @_;
    return scalar @{$self->{fields}};
}

sub num_rows {
    my ($self) = @_;
    return scalar @{$self->{return_data}};
}

sub num_params {
    my ($self) = @_;
    return scalar @{$self->{bound_params}};
}

sub bind_col {
    my ($self, $param_num, $ref) = @_;
    $self->{bind_cols}->[$param_num - 1] = $ref;
}

sub bound_param {
    my ($self, $param_num, $value) = @_;
    $self->{bound_params}->[$param_num - 1] = $value;
    return $self->bound_params;
}

sub bound_param_trailing {
    my ($self, @values) = @_;
    push @{$self->{bound_params}}, @values;
}

sub bind_cols {
    my $self = shift;
    return @{$self->{bind_cols} || []};
}

sub bind_params {
    my ($self, @values) = @_;
    @{$self->{bound_params}} = @values;
}

# Rely on the DBI's notion of Active: a statement is active if it's
# currently in a SELECT and has more records to fetch

sub is_active {
    my ($self) = @_;
    return 0 unless $self->statement =~ /^\s*select/ism;
    return 0 unless $self->is_executed eq 'yes';
    return 0 if     $self->is_depleted;
    return 1;
}

sub is_finished {
    my ($self, $value) = @_;
    if (defined $value && $value eq 'yes' ) {
        $self->{is_finished} = 'yes';
        $self->current_record_num(0);
        $self->{return_data} = [];
    }
    elsif (defined $value) {
        $self->{is_finished} = 'no';
    }
    return $self->{is_finished};
}

####################
# RETURN VALUES

sub mark_executed {
    my ($self) = @_;
    $self->is_executed('yes');
    $self->current_record_num(0);
}

sub next_record {
    my ($self) = @_;
    return if $self->is_depleted;
    my $rec_num = $self->current_record_num;
    my $rec = $self->return_data->[$rec_num];
    $self->current_record_num($rec_num + 1);
    return $rec;
}

sub is_depleted {
    my ($self) = @_;
    return ($self->current_record_num >= scalar @{$self->return_data});
}

# DEBUGGING AID

sub to_string {
    my ($self) = @_;
    return join "\n" => (
                  $self->{statement},
                  "Values: [" . join( '] [', @{ $self->{bound_params} } ) . "]",
                  "Records: on $self->{current_record_num} of " . scalar(@{$self->return_data}) . "\n",
                  "Executed? $self->{is_executed}; Finished? $self->{is_finished}"
                  );
}

# PROPERTIES

# boolean

sub is_executed {
    my ($self, $yes_no) = @_;
    $self->{is_executed} = $yes_no if defined $yes_no;
    return ($self->{is_executed} eq 'yes') ? 'yes' : 'no';
}

# single-element fields

sub statement {
    my ($self, $value) = @_;
    $self->{statement} = $value if defined $value;
    return $self->{statement};
}

sub current_record_num {
    my ($self, $value) = @_;
    $self->{current_record_num} = $value if defined $value;
    return $self->{current_record_num};
}

# multi-element fields

sub return_data {
    my ($self, @values) = @_;
    push @{$self->{return_data}}, @values if scalar @values;
    return $self->{return_data};
}

sub fields {
    my ($self, @values) = @_;
    push @{$self->{fields}}, @values if scalar @values;
    return $self->{fields};
}

sub bound_params {
    my ($self, @values) = @_;
    push @{$self->{bound_params}}, @values if scalar @values;
    return $self->{bound_params};
}

package
    DBD::Mock::StatementTrack::Iterator;

use strict;
use warnings;

sub new {
    my ($class, $history) = @_;
    return bless {
            pointer => 0,
            history => $history || []
            } => $class;
}

sub next {
    my ($self) = @_;
    return unless $self->{pointer} < scalar(@{$self->{history}});
    return $self->{history}->[$self->{pointer}++];
}

sub reset { (shift)->{pointer} = 0 }

package
    DBD::Mock::Session;

use strict;
use warnings;

my $INSTANCE_COUNT = 1;

sub new {
    my $class = shift;
    (@_) || die "You must specify at least one session state";
    my $session_name;
    if (ref($_[0])) {
        $session_name = 'Session ' . $INSTANCE_COUNT;
    }
    else {
        $session_name = shift;
    }
    my @session_states = @_;
    (@session_states)
        || die "You must specify at least one session state";
    (ref($_) eq 'HASH')
        || die "You must specify session states as HASH refs"
            foreach @session_states;
    $INSTANCE_COUNT++;
    return bless {
        name        => $session_name,
        states      => \@session_states,
        state_index => 0
    } => $class;
}

sub name  { (shift)->{name} }
sub reset { (shift)->{state_index} = 0 }
sub num_states { scalar( @{ (shift)->{states} } ) }

sub has_states_left {
    my $self = shift;
    return $self->{state_index} < scalar(@{$self->{states}});
}

sub verify_statement {
    my ($self, $dbh, $statement) = @_;

    ($self->has_states_left)
        || die "Session states exhausted, only '" . scalar(@{$self->{states}}) . "' in DBD::Mock::Session (" . $self->{name} . ")";

    my $current_state = $self->{states}->[$self->{state_index}];
    # make sure our state is good
    (exists ${$current_state}{statement} && exists ${$current_state}{results})
        || die "Bad state '" . $self->{state_index} .  "' in DBD::Mock::Session (" . $self->{name} . ")";
    # try the SQL
    my $SQL = $current_state->{statement};
    unless (ref($SQL)) {
        ($SQL eq $statement)
            || die "Statement does not match current state in DBD::Mock::Session (" . $self->{name} . ")\n" .
                   "      got: $statement\n" .
                   " expected: $SQL";
    }
    elsif (ref($SQL) eq 'Regexp') {
        ($statement =~ /$SQL/)
            || die "Statement does not match current state (with Regexp) in DBD::Mock::Session (" . $self->{name} . ")\n" .
                   "      got: $statement\n" .
                   " expected: $SQL";
    }
    elsif (ref($SQL) eq 'CODE') {
        ($SQL->($statement, $current_state))
            || die "Statement does not match current state (with CODE ref) in DBD::Mock::Session (" . $self->{name} . ")";
    }
    else {
        die "Bad 'statement' value '$SQL' in current state in DBD::Mock::Session (" . $self->{name} . ")";
    }
    # copy the result sets so that
    # we can re-use the session
    $dbh->STORE('mock_add_resultset' => [ @{$current_state->{results}} ]);
}

sub verify_bound_params {
    my ($self, $dbh, $params) = @_;
    my $current_state = $self->{states}->[$self->{state_index}];
    if (exists ${$current_state}{bound_params}) {
        my $expected = $current_state->{bound_params};
        (scalar(@{$expected}) == scalar(@{$params}))
            || die "Not the same number of bound params in current state in DBD::Mock::Session (" . $self->{name} . ")\n" .
                   "      got: " . scalar(@{$params}) . "\n" .
                   " expected: " . scalar(@{$expected});
        for (my $i = 0; $i < scalar(@{$params}); $i++) {
            no warnings;
            if (ref($expected->[$i]) eq 'Regexp') {
                ($params->[$i] =~ /$expected->[$i]/)
                    || die "Bound param $i do not match (using regexp) in current state in DBD::Mock::Session (" . $self->{name} . ")\n" .
                           "      got: " . $params->[$i] . "\n" .
                           " expected: " . $expected->[$i];
            }
            else {
                ($params->[$i] eq $expected->[$i])
                    || die "Bound param $i do not match in current state in DBD::Mock::Session (" . $self->{name} . ")\n" .
                           "      got: " . $params->[$i] . "\n" .
                           " expected: " . $expected->[$i];
            }
        }
    }
    # and make sure we go to
    # the next statement
    $self->{state_index}++;
}

1;

__END__

#line 2113
