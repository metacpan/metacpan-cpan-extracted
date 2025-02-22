package DBD::Mock::st;

use strict;
use warnings;

our $imp_data_size = 0;

sub bind_col {
    my ( $sth, $param_num, $ref, $attr ) = @_;

    my $tracker = $sth->FETCH('mock_my_history');
    $tracker->bind_col( $param_num, $ref );
    return 1;
}

sub bind_param {
    my ( $sth, $param_num, $val, $attr ) = @_;
    my $tracker = $sth->FETCH('mock_my_history');
    $tracker->bound_param( $param_num, $val, $attr );
    return 1;
}

sub bind_param_array {
    bind_param(@_);
}

sub bind_param_inout {
    my ( $sth, $param_num, $val, $max_len ) = @_;

    # check that $val is a scalar ref
    ( UNIVERSAL::isa( $val, 'SCALAR' ) )
      || $sth->{Database}
      ->set_err( 1, "need a scalar ref to bind_param_inout, not $val" );

    # check for positive $max_len
    ( $max_len > 0 )
      || $sth->{Database}
      ->set_err( 1, "need to specify a maximum length to bind_param_inout" );
    my $tracker = $sth->FETCH('mock_my_history');
    $tracker->bound_param( $param_num, $val );
    return 1;
}

sub execute_array {
    my ( $sth, $attr, @bind_values ) = @_;

    # no bind values means we're relying on prior calls to bind_param_array()
    # for our data
    my $tracker = $sth->FETCH('mock_my_history');
    # don't use a reference; there's some magic attached to it somewhere
    # so make it a lovely, simple array as soon as possible
    my @bound = @{ $tracker->bound_params() };
    foreach my $p (@bound) {
        my $result = $sth->execute( @$p );
        # store the result from execute() if ArrayTupleStatus attribute is
        # passed
        push @{ $attr->{ArrayTupleStatus} }, $result
            if (exists $attr->{ArrayTupleStatus});
    }

    # TODO: the docs say:
    #   When called in scalar context the execute_array() method returns the
    #   number of tuples executed, or undef if an error occurred. Like
    #   execute(), a successful execute_array() always returns true regardless
    #   of the number of tuples executed, even if it's zero. If there were any
    #   errors the ArrayTupleStatus array can be used to discover which tuples
    #   failed and with what errors.
    #   When called in list context the execute_array() method returns two
    #   scalars; $tuples is the same as calling execute_array() in scalar
    #   context and $rows is the number of rows affected for each tuple, if
    #   available or -1 if the driver cannot determine this. 
    # We have glossed over this...
    return scalar @bound;
}

sub execute {
    my ( $sth, @params ) = @_;
    my $dbh = $sth->{Database};

    unless ( $dbh->{mock_can_connect} ) {
        $dbh->set_err( 1, "No connection present" );
        return 0;
    }
    unless ( $dbh->{mock_can_execute} ) {
        $dbh->set_err( 1, "Cannot execute" );
        return 0;
    }
    $dbh->{mock_can_execute}++ if $dbh->{mock_can_execute} < 0;

    my $tracker = $sth->FETCH('mock_my_history');

    if ( $tracker->has_failure() ) {
        $dbh->set_err( $tracker->get_failure() );
        return 0;
    }

    if (@params) {
        $tracker->bind_params(@params);
    }

    if ( my $session = $dbh->{mock_session} ) {
        eval {
            my $state = $session->current_state;
            $session->verify_statement( $sth->{Statement});
            $session->verify_bound_params( $tracker->bound_params() );

            # Load a copy of the results to return (minus the field
            # names) into the tracker
            my @results = @{ $state->{results} };
            shift @results;
            $tracker->{return_data} = \@results;
        };
        if ($@) {
            my $session_error = $@;
            chomp $session_error;
            $sth->set_err( 1, "Session Error: ${session_error}" );
            return;
        }
    }

    $tracker->mark_executed;
    my $fields = $tracker->fields;
    $sth->STORE( NUM_OF_FIELDS => scalar @{ $fields ? $fields : [] } );
    $sth->STORE( NAME => $fields );

    $sth->STORE( NUM_OF_PARAMS => $tracker->num_params );

    # handle INSERT statements and the mock_last_insert_ids
    # We should only increment these things after the last successful INSERT.
    # -RobK, 2007-10-12
    #use Data::Dumper;warn Dumper $dbh->{mock_last_insert_ids};

    if ( $dbh->{Statement} =~ /^\s*?insert(?:\s+ignore)?\s+into\s+(\S+)/i ) {
        if ( $tracker->{last_insert_id} ) {
            $dbh->{mock_last_insert_id} = $tracker->{last_insert_id};

        } elsif ( $dbh->{mock_last_insert_ids}
            && exists $dbh->{mock_last_insert_ids}{$1} )
        {
            $dbh->{mock_last_insert_id} = $dbh->{mock_last_insert_ids}{$1}++;
        }
        else {
            $dbh->{mock_last_insert_id}++;
        }
    }

    #warn "$dbh->{mock_last_insert_id}\n";

    # always return 0E0 for Selects
    if ( $dbh->{Statement} =~ /^\s*?select/i ) {
        return '0E0';
    }
    return ( $sth->rows() || '0E0' );
}

sub fetch {
    my ($sth) = @_;
    my $dbh = $sth->{Database};
    unless ( $dbh->{mock_can_connect} ) {
        $dbh->set_err( 1, "No connection present" );
        return;
    }
    unless ( $dbh->{mock_can_fetch} ) {
        $dbh->set_err( 1, "Cannot fetch" );
        return;
    }
    $dbh->{mock_can_fetch}++ if $dbh->{mock_can_fetch} < 0;

    my $tracker = $sth->FETCH('mock_my_history');

    my $record = $tracker->next_record
      or return;

    if ( my @cols = $tracker->bind_cols() ) {
        for my $i ( grep { ref $cols[$_] } 0 .. $#cols ) {
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
    my ( $sth, $name ) = @_;
    my $dbh = $sth->{Database};

    # handle any errors since we are grabbing
    # from the tracker directly
    unless ( $dbh->{mock_can_connect} ) {
        $dbh->set_err( 1, "No connection present" );
        return;
    }
    unless ( $dbh->{mock_can_fetch} ) {
        $dbh->set_err( 1, "Cannot fetch" );
        return;
    }
    $dbh->{mock_can_fetch}++ if $dbh->{mock_can_fetch} < 0;

    # first handle the $name, it will default to NAME
    $name ||= 'NAME';

    # then fetch the names from the $sth (per DBI spec)
    my $fields = $sth->FETCH($name);

    # now check the tracker ...
    my $tracker = $sth->FETCH('mock_my_history');

    # and collect the results
    if ( my $record = $tracker->next_record() ) {
        my @values = @{$record};
        return { map { $_ => shift(@values) } @{$fields} };
    }

    return undef;
}

#XXX Isn't this supposed to return an array of hashrefs? -RobK, 2007-10-15
sub fetchall_hashref {
    my ( $sth, $keyfield ) = @_;
    my $dbh = $sth->{Database};

    # handle any errors since we are grabbing
    # from the tracker directly
    unless ( $dbh->{mock_can_connect} ) {
        $dbh->set_err( 1, "No connection present" );
        return;
    }
    unless ( $dbh->{mock_can_fetch} ) {
        $dbh->set_err( 1, "Cannot fetch" );
        return;
    }
    $dbh->{mock_can_fetch}++ if $dbh->{mock_can_fetch} < 0;

    # get the case conversion to use for hash key names (NAME/NAME_lc/NAME_uc)
    my $hash_key_name = $sth->{Database}->FETCH('FetchHashKeyName') || 'NAME';

    # get a hashref mapping field names to their corresponding indexes. indexes
    # start at zero
    my $names_hash = $sth->FETCH("${hash_key_name}_hash");

    # as of DBI v1.48, the $keyfield argument can be either an arrayref of field
    # names/indexes or a single field name/index
    my @key_fields = ref $keyfield ? @{$keyfield} : $keyfield;

    my $num_fields = $sth->FETCH('NUM_OF_FIELDS');

    # get the index(es) of the given key field(s). a key field can be specified
    # as either the name of a field or an integer column number
    my @key_indexes;
    foreach my $field (@key_fields) {
        if (defined $names_hash->{$field}) {
            push @key_indexes, $names_hash->{$field};
        }
        elsif (DBI::looks_like_number($field) && $field >= 1 && $field <= $num_fields) {
            # convert from column number to array index. column numbers start at
            # one, while indexes start at zero
            push @key_indexes, $field - 1;
        }
        else {
            my $err = "Could not find key field '$field' (not one of " .
                join(' ', keys %{$names_hash}) . ')';
            $dbh->set_err( 1, $err );
            return;
        }
    }

    my $tracker = $sth->FETCH('mock_my_history');
    my $rethash = {};

    # now loop through all the records ...
    while ( my $record = $tracker->next_record() ) {

        # populate the hash, adding a layer of nesting for each key field
        # specified by the user
        my $ref = $rethash;
        foreach my $index (@key_indexes) {
            my $value = $record->[$index];
            $ref->{$value} = {} if ! defined $ref->{$value};
            $ref = $ref->{$value};
        }

        # copy all of the returned data into the most-nested level of the hash
        foreach my $field (keys %{$names_hash}) {
            my $index = $names_hash->{$field};
            $ref->{$field} = $record->[$index];
        }
    }

    return $rethash;
}

sub last_insert_id {
    my ( $sth, @params ) = @_;
    return $sth->{Database}->last_insert_id( @params );
}

sub finish {
    my ($sth) = @_;
    $sth->FETCH('mock_my_history')->is_finished('yes');
}

sub rows {
    my ($sth) = @_;
    $sth->FETCH('mock_num_rows');
}

sub FETCH {
    my ( $sth, $attrib ) = @_;
    $sth->trace_msg("Fetching ST attribute '$attrib'\n");
    my $tracker = $sth->{mock_my_history};
    $sth->trace_msg( "Retrieved tracker: " . ref($tracker) . "\n" );

    # NAME attributes
    if ( $attrib eq 'NAME' ) {
        return [ @{ $tracker->fields } ];
    }
    elsif ( $attrib eq 'NAME_lc' ) {
        return [ map { lc($_) } @{ $tracker->fields } ];
    }
    elsif ( $attrib eq 'NAME_uc' ) {
        return [ map { uc($_) } @{ $tracker->fields } ];
    }

    # NAME_hash attributes
    elsif ( $attrib eq 'NAME_hash' ) {
        my $i = 0;
        return { map { $_ => $i++ } @{ $tracker->fields } };
    }
    elsif ( $attrib eq 'NAME_hash_lc' ) {
        my $i = 0;
        return { map { lc($_) => $i++ } @{ $tracker->fields } };
    }
    elsif ( $attrib eq 'NAME_hash_uc' ) {
        my $i = 0;
        return { map { uc($_) => $i++ } @{ $tracker->fields } };
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
    elsif ( exists $tracker->{driver_attributes}->{$attrib} ) {
        return $tracker->{driver_attributes}->{$attrib};
    }
    elsif ( $attrib !~ /^mock/ ) {
        if ( $sth->{Database}->{mock_attribute_aliases} ) {
            if (
                exists ${ $sth->{Database}->{mock_attribute_aliases}->{st} }
                {$attrib} )
            {
                my $mock_attrib =
                  $sth->{Database}->{mock_attribute_aliases}->{st}->{$attrib};
                if ( ref($mock_attrib) eq 'CODE' ) {
                    return $mock_attrib->($sth);
                }
                else {
                    return $sth->FETCH($mock_attrib);
                }
            }
        }
        return $sth->SUPER::FETCH($attrib);
    }

    # now do our stuff...

    if ( $attrib eq 'mock_my_history' ) {
        return $tracker;
    }
    elsif ( $attrib eq 'mock_execution_history' ) {
        return $tracker->execution_history();
    }
    elsif ( $attrib eq 'mock_statement' ) {
        return $tracker->statement;
    }
    elsif ( $attrib eq 'mock_params' ) {
        return $tracker->bound_params;
    }
    elsif ( $attrib eq 'mock_param_attrs' ) {
        return $tracker->bound_param_attrs;
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
    my ( $sth, $attrib, $value ) = @_;
    $sth->trace_msg("Storing ST attribute '$attrib'\n");
    if ( $attrib =~ /^mock/ ) {
        return $sth->{$attrib} = $value;
    }
    elsif ( $attrib =~ /^NAME/ ) {

        # no-op...
        return;
    }
    else {
        $value ||= 0;
        return $sth->SUPER::STORE( $attrib, $value );
    }
}

sub DESTROY { undef }

1;
