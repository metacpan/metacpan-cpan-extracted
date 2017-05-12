package Class::Inflate;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(inflate commit obliterate);
our @EXPORT = ('inflate'); # @EXPORT_OK;
our $VERSION = '0.07';
$::OBJECT = undef;

use Devel::Messenger qw(note);

# Preloaded methods go here.

sub import {
    # allows 'use' syntax
    my ($class, @args) = @_;
    @args and $class->make(@args);
}

sub make {
    # sets up glue to database based on 'use' statement
    my ($generator_class, @args) = @_;
    my $target_class = $generator_class->find_target_class;
    my %persist = ();
    while (@args) {
        my ($table, $config) = splice(@args, 0, 2);
	$persist{$table} = $config;
    }
    # $generator_class->_install_method($target_class, $sub_name, $code);
    foreach my $export (@EXPORT) {
        my $generate_export = '_' . $export;
	$generator_class->$generate_export($target_class, \%persist, $export);
    }
}

sub find_target_class {
    # determines where to export generated methods
    my $class;
    my $c = 0;
    while (1) {
        $class = (caller($c++))[0];
        last unless ($class->isa('Class::Inflate') and
                     &{$class->can('ima_generator')});
    }
    return $class;
}

sub ima_generator {
    # a subclass may redefine this to return 0, if it wishes
    # to allow methods added to itself
    1;
}

sub _install_method {
    # exports method to target class
    my $generator_class = shift;
    my $target_class = shift;
    my $accessor = shift;
    my $code = shift;
    no strict 'refs';
    unless (defined *{"$target_class\::$accessor"}{CODE}) {
        note \7, "building accessor '$target_class\::$accessor'\n";
        return *{"$target_class\::$accessor"} = $code;
    }
    return;
}

sub _inflate {
    my $generator_class = shift;
    my $target_class = shift;
    my $persist = shift;
    my $sub_name = shift;
    $generator_class->_install_method($target_class, $sub_name, sub {
	my $self = shift;
	my $class = ref($self) ? ref($self) : $self;
	my $dbh = shift;
	my $filter = shift || $self;
	my @sql = inflation_sql($class, $filter, $persist);
	my @records = (); # in object format
	my @data = (); # in table/field format
	my %rows_fetched = ();
	my %awaiting_join = ();
	foreach my $sql (@sql) {
	    my @r = fetchrows($class, $dbh, $sql->{query}, $sql->{bind});
	    $rows_fetched{$sql->{table}} = \@r;
	    if (exists($persist->{$sql->{table}}{join}) and keys %{$persist->{$sql->{table}}{join}}) {
	        foreach my $table (keys %{$persist->{$sql->{table}}{join}}) {
		    note \3, "want to join $sql->{table} to $table\n";
		    if (@data and $rows_fetched{$table}) {
			join_records($class, $persist, $table, \@data, $sql->{table}, \@r);
		    } else {
			$awaiting_join{$table} ||= [];
		        push @{$awaiting_join{$table}}, $sql->{table};
			note \3, "  will wait till we have $table data\n";
		    }
		}
	    } else {
	        # this is the master/parent table
		note \3, "populating dataset from $sql->{table}\n";
		$rows_fetched{$sql->{table}} = @r;
		@data = map { { $sql->{table} => [$_] } } splice @r;
		note \3, "placed " . scalar(@data) . ' of ' . scalar(@r) . " records in dataset\n"; 
	    }
	    if (@data and $awaiting_join{$sql->{table}}) {
                my $join_awaiting_records;
                # need to recursively call this foreach loop
                $join_awaiting_records = sub {
                    my $waiting = shift;
                    return unless exists($awaiting_join{$waiting});
                    note \3, "now we have $waiting data\n";
                    while (@{$awaiting_join{$waiting}}) {
                        my $table = shift @{$awaiting_join{$waiting}};
                        join_records($class, $persist, $waiting, \@data, $table, $rows_fetched{$table});
                        $join_awaiting_records->($table);
                    }
                };
                $join_awaiting_records->($sql->{table});
	    }
	}
	# TODO remove Dumper
	#use Data::Dumper;
	#note "dataset:\n" . Dumper(\@data) . "\n";
	my $inflated_object = inflated_object($class, $persist, \@data, [ref($self) ? $self : ()]);
	while (my $record = $inflated_object->($dbh)) {
	    push @records, $record;
	}
	return @records if wantarray;
	return \@records;
    });
}

sub inflation_sql {
    my $class = shift;
    my $filter = shift;
    my $persist = shift;
    die "inflate filter must be a HASH\n" unless (UNIVERSAL::isa($filter, 'HASH'));
    my @sql = ();
    my $inflate = [];
    foreach my $table (keys %$persist) {
        push @$inflate, keys %{$persist->{$table}{methods}};
    }
    my $method_tables = method_tables($class, $persist);
    my $inflation_fields = inflation_fields($class, $inflate, $persist, $method_tables);
    my $filter_values = filter_values($class, $filter, $persist, $method_tables);
    my %join_fields = (); # fields we must select because we will use them to match records
    # newer code
    foreach my $table (keys %$inflation_fields) {
	note \5, "building query for table $table\n";
	my $table_filter = add_filter_defaults($class, $filter_values, $persist, $table);
	my @tables = ();
	my @fields = ();
	my @filter = ();
	my @bind   = ();
	my $alias  = '';
        my $has_filter = exists($filter_values->{$table}) ? 1 : 0;
	my $has_external_filter = scalar(keys %$filter_values) > $has_filter;
	if ($has_external_filter) {
	    # see if we can join to the external tables
	    my $matched = 0;
	    my $need_join = 0;
	    # add current table and fields
	    $alias = 'a';
	    my %table_alias = ( $table => $alias );
	    push @tables, $table . ' ' . $table_alias{$table};
	    push @fields, map { $table_alias{$table} . '.' . $_ } @{$inflation_fields->{$table}};
	    foreach my $external (keys %$filter_values) {
		next if ($table eq $external);
		# add external table
		$table_alias{$external} = ++$alias;
		# see if all the fields in the filter join to fields in our table
	        #foreach my $field (@{$filter_values->{$external}{fields}}) {
		#    if (exists($persist->{$table}{join}{$external}) and exists($persist->{$table}{join}{$external}{$field})) {
		#        my $my_field_name = $persist->{$table}{join}{$external}{$field};
		#	# TODO get value right now?
		#	$matched++;
		#    } else {
		#        $need_join++;
		#    }
		#}
	    }
	    # add join (field = field) to filter
	    my @aliases = keys %table_alias;
	    foreach my $external (@aliases) {
		next if ($external eq $table);
		note \6, "will need to join from $table to $external\n";
                my @pkey = exists($persist->{$table}{key}) ? @{$persist->{$table}{key}} : ();
		# iterate through tables we know how to join to
		my @partial_forward_path = ();
		my $next_path = join_path($persist, $table, $external, \@partial_forward_path, exists($persist->{$table}{join}) ? keys %{$persist->{$table}{join}} : ());
                my @paths = ();
                my ($path, $join) = run_path_iterator($next_path, $persist->{$table}, 0);
                push @paths, $path if @$path;
                # if @path, but not all primary key fields are used in join, check for additional paths and possibly use multiple paths
                while (@$path and grep { !$join->{$_} } @pkey) {
                    note \6, "checking for additional join paths\n";
                    ($path, $join) = run_path_iterator($next_path, $persist->{$table}, 0);
                    push @paths, $path if @$path;
                }
		my $static_from = $table;
                my $middle_join = 0;
		if (!@paths and exists($persist->{$external}{join})) {
		    note \6, "checking for reverse join definition\n";
		    my @partial_reverse_path = ();
		    my $reverse_path = join_path($persist, $external, $table, \@partial_reverse_path, keys %{$persist->{$external}{join}});
                    ($path, $join) = run_path_iterator($reverse_path, $persist->{$table}, -1);
                    push @paths, $path if @$path;
                    # if @path, but not all primary key fields are used in join, check for additional paths and possibly use multiple paths
                    while (@$path and grep { !$join->{$_} } @pkey) {
                        note \6, "checking for additional join paths\n";
                        ($path, $join) = run_path_iterator($reverse_path, $persist->{$table}, -1);
                        push @paths, $path if @$path;
                    }
		    $static_from = $external;
                    if (!@paths) {
                        # check for a common table both ends know how to join to, if there is no direct join path
                        my $next_path = meet_in_the_middle($table, $external, \@partial_forward_path, \@partial_reverse_path);
                        my ($path, $join) = run_path_iterator($next_path, $persist->{$table}, 0);
                        push @paths, $path if @$path;
                        # if @path, but not all primary key fields are used in join, check for additional paths and possibly use multiple paths
                        while (@$path and grep { !$join->{$_} } @pkey) {
                            note \6, "checking for additional join paths\n";
                            ($path, $join) = run_path_iterator($next_path, $persist->{$table}, 0);
                            push @paths, $path if @$path;
                        }
                        if (@paths) {
                            $static_from = $table;
                            $middle_join = 1;
                        }
                    }
		}
                foreach my $path (@paths) {
                    #my $from = $static_from;
                    my @from_table = $static_from;
                    if ($middle_join) {
                        @from_table = ($table, $external);
                        note \7, "will look for join columns between $table and $external, forwards and backwards\n";
                    } else {
                        note \7, "will look for join columns between $table and $external, forwards only\n";
                    }
                    foreach my $from (@from_table) {
                        my @path = @$path;
                        if ($middle_join and $from eq $external) {
                            note \6, "looking for reverse join columns ($external to $table)\n";
                            @path = reverse @path;
                            shift @path; # remove $external from list
                        } else {
                            note \6, "looking for join columns ($table to $external)\n";
                        }
                        note \6, "path: " . join(' -> ', $from, @path) . "\n";
                        foreach my $step (@path) {
                            # add external table
                            my $t = ($step eq $table) ? $external : $step;
                            $table_alias{$t} = ++$alias unless (exists($table_alias{$t}));
                            push @tables, $t . ' ' . $table_alias{$t} unless (grep { $_ eq ($t . ' ' . $table_alias{$t}) } @tables);
                            $join_fields{$step} ||= [];
                            foreach my $field (exists($persist->{$from}{join}{$step}) ? keys %{$persist->{$from}{join}{$step}} : ()) {
                                my $join_from = $table_alias{$from} . '.' . $persist->{$from}{join}{$step}{$field};
                                my $join_to   = $table_alias{$step} . '.' . $field;
                                my $seen = 0;
                                foreach my $filter_item (@filter) {
                                    if ($filter_item eq ($join_from . ' = ' . $join_to) or $filter_item eq ($join_to . ' = ' . $join_from)) {
                                        $seen = 1;
                                        last;
                                    }
                                }
                                if ($seen) {
                                    note \6, '  skipping ' . $from . '.' . $persist->{$from}{join}{$step}{$field} . ' = ' . $step . '.' . $field . "\n";
                                    next;
                                }
                                note \6, '  joining ' . $from . '.' . $persist->{$from}{join}{$step}{$field} . ' = ' . $step . '.' . $field . "\n";
                                push @filter, $table_alias{$from} . '.' . $persist->{$from}{join}{$step}{$field} . ' = ' . $table_alias{$step} . '.' . $field;
                                push @{$join_fields{$from}}, $persist->{$from}{join}{$step}{$field};
                                push @{$join_fields{$step}}, $field;
                            }
                            $from = $step;
                        }
                    }
                }
                unless (@paths) {
                    note \6, "no path from $table to $external found\n";
                    delete $table_alias{$external};
                }
	    }
	    foreach my $external (keys %table_alias) {
		# add external table conditions to filter
		if (exists($filter_values->{$external})) {
		    my $next_filter = expand_bind(sub { $table_alias{$external} . '.' . shift }, $filter_values->{$external}{fields}, $filter_values->{$external}{values});
		    while (my ($f, $b) = $next_filter->()) {
		        push @filter, $f;
			push @bind, @$b;
		    }
		}
	    }
	    #if ($need_join) {
	    #    # TODO join in SQL, select from both, remove other single table SQL
	    #} else {
	    #    # TODO build SQL using our fieldnames for filter parameters
	    #}
	} else {
	    # build SQL statement for this table - no joins necessary
	    push @tables, $table;
	    push @fields, @{$inflation_fields->{$table}};
	    if (exists($filter_values->{$table})) {
		my $next_filter = expand_bind(sub { shift }, $filter_values->{$table}{fields}, $filter_values->{$table}{values});
		while (my ($f, $b) = $next_filter->()) {
		    push @filter, $f;
		    push @bind, @$b;
		}
	    }
	}
	if (keys %$table_filter) {
	    my $prefix = $alias ? 'a.' : '';
	    my $next_filter = expand_bind(sub { $prefix . shift }, $table_filter->{fields}, $table_filter->{values});
	    while (my ($f, $b) = $next_filter->()) {
		push @filter, $f;
		push @bind, @$b;
	    }
	}
	next unless @filter;
	push @sql, { 
	    'bind' => \@bind, 
	    'table' => $table,
	    'tables' => \@tables,
	    'fields' => \@fields,
	    'filter' => \@filter,
	};
    }
    foreach my $sql (@sql) {
	my ($table, $alias) = split(/\s+/, $sql->{tables}[0]);
	$alias .= $alias ? '.' : '';
	if (exists($join_fields{$table})) {
	    my %current = map { $_ => 1 } @{$sql->{fields}};
	    foreach my $field (@{$join_fields{$table}}) {
	        unless (exists($current{$alias.$field})) {
		    push @{$sql->{fields}}, $alias.$field;
		    $current{$alias.$field}++;
		    note \6, "adding $table.$field to selection\n";
		}
	    }
	}
	my $query = 'SELECT ' . join(', ', @{$sql->{fields}});
	$query .= ' FROM ' . join(', ', @{$sql->{tables}});
	$query .= ' WHERE ' . join(' AND ', @{$sql->{filter}});
	$sql->{query} = $query;
	note \5, 'built query: ' . $query . " -> " . join(', ', map { defined($_) ? $_ : '' } @{$sql->{bind}}) . "\n";
    }
    return @sql if wantarray;
    return \@sql;
}

sub expand_bind {
    # returns an iterator which returns a filter "$field = ?" and bind value
    my $transform = shift;
    my $fields = shift;
    my $values = shift;
    my $c = 0;
    return sub {
	return if ($c >= @$fields);
	my $field = $transform->($fields->[$c]);
	my $value = $values->[$c++];
	my $operator = '=';
	my $placeholder = '?';
	if (UNIVERSAL::isa($value, 'ARRAY')) {
	    if (@$value == 0) {
	        push @$value, undef;
	    } elsif (@$value > 1) {
	        $operator = 'IN';
		$placeholder = '(' . join(', ', map { '?' } @$value) . ')';
	    }
	} else {
	    $value = [$value];
	}
	return ($field . ' ' . $operator . ' ' . $placeholder, $value);
    }
}

sub join_path {
    # determine possible paths to join two tables together
    my $persist = shift;
    my $launch = shift;
    my $target = shift;
    my $iterators = shift || [];
    my $spacing = '';
    note \7, "creating iterator from $launch to $target\n";
    push @$iterators, [member_of($spacing, $target, @_), []];
    my $c = 0;
    return sub {
        while ($c < @$iterators) {
	    my ($element, $match) = $iterators->[$c][0]->();
	    $spacing = '  ' x @{$iterators->[$c][1]};
	    unless (defined($element)) {
		note \7, $spacing . "iterator $c is exhausted\n";
		$c++;
		next;
	    }
	    if ($match) {
		note \7, $spacing . "iterator $c found a join path: " . join(' -> ', @{$iterators->[$c][1]}, $element) . "\n";
	        return @{$iterators->[$c][1]}, $element;
	    } else {
		if (grep { /^$element$/ } @{$iterators->[$c][1]}) {
		    note \7, $spacing . "search loop detected: " . join(' -> ', @{$iterators->[$c][1]}, $element) . "\n";
		} else {
		    $spacing .= '  ';
		    note \7, $spacing . "creating iterator from $element to $target\n";
		    push @$iterators, [member_of($spacing, $target, keys %{$persist->{$element}{join}}), [@{$iterators->[$c][1]}, $element]];
		}
	    }
	}
	note \7, "all iterators exhausted\n";
	return;
    };
}

sub member_of {
    # iterator to say if an element matches the target
    my $spacing = shift || '';
    my $target = shift;
    my @possible = @_;
    note \7, $spacing . "  determining if " . join(' or ', map { "'$_'" } @possible) . " knows how to join to '$target'\n" if @possible;
    return sub {
        while (my $element = shift(@possible)) {
	    return ($element, ($element eq $target));
	}
	return;
    }
}

sub run_path_iterator {
    # kicks the iterator to find the next path. Returns the path, and fields it will use for the join
    my $iterator = shift;
    my $table_instructions = shift;
    my $element = shift || 0; # expects 0 for forward, -1 for reverse path
    my @path = $iterator->();
    return (\@path, {}) unless @path;
    my %join = map { $_ => 1 } (exists($table_instructions->{join}) and exists($table_instructions->{join}{$path[$element]})) ? values %{$table_instructions->{join}{$path[$element]}} : ();
    return (\@path, \%join);
}

sub meet_in_the_middle {
    my $launch = shift;
    my $target = shift;
    my $forward = shift;
    my $reverse = shift;
    my @queue = ();
    foreach my $fpath (@$forward) {
        next unless @{$fpath->[1]};
        foreach my $rpath (@$reverse) {
            next unless @{$rpath->[1]};
            push @queue, [[@{$fpath->[1]}], [reverse @{$rpath->[1]}]];
        }
    }
    my %returned = ();
    return sub {
        while (my $queue = shift(@queue)) {
            my ($fqueue, $rqueue) = @$queue;
            my $c = 0;
            foreach my $element (@$rqueue) {
                $c++;
                if ($element eq $fqueue->[-1]) {
                    note \7, "found a meet-in-the-middle join at '$element': " . join(' -> ', $launch, @$fqueue) . ' | ' . join(' <- ', @$rqueue, $target) . "\n";
                    if ($returned{$element}) {
                        note \7, "  (ignorning because we have already found a join through '$element')\n";
                        next;
                    }
                    my @path = (@$fqueue, splice(@$rqueue, $c), $target);
                    note \7, "  which makes a join of: " . join(' -> ', $launch, @path) . "\n";
                    my %seen = ();
                    my @multiple = grep { $seen{$_}++ } @path;
                    if (@multiple) {
                        note \7, "  (ignoring because join goes through " . join(' and ', @multiple) . " more than once)\n";
                        next;
                    }
                    $returned{$element}++;
                    return @path;
                }
            }
        }
        return;
    }
}

sub inflation_fields {
    my $class = shift;
    my $inflate = shift;
    my $persist = shift;
    my $method_tables = shift || method_tables($class, $persist);
    my %fields = ();
    foreach my $method (@$inflate) {
	unless (exists($method_tables->{$method})) {
	    warn "ignoring unknown method '$method' for inflation\n";
	    next;
	}
        my $table = $method_tables->{$method};
	next if (exists($fields{$table})); # already did this table
	my $methods = $persist->{$table}{methods};
	my @fields = ();
	# figure out which fields to select based on method names
	foreach my $field (values %$methods) {
	    if (ref($field)) {
	        if (ref($field) eq 'HASH' and exists($field->{fields})) {
		    push @fields, ref($field->{fields}) eq 'ARRAY' ? @{$field->{fields}} : $field->{fields};
		}
	    } else {
	        push @fields, $field;
	    }
	}
	next unless @fields;
	# select any fields needed for joins
	if (exists($persist->{$table}{join})) {
	    my %selected = map { $_ => 1 } @fields;
	    foreach my $parent (keys %{$persist->{$table}{join}}) {
	        foreach my $field (values %{$persist->{$table}{join}{$parent}}) {
		    unless (exists($selected{$field})) {
			push @fields, $field;
			$selected{$field}++;
		    }
		}
	    }
	}
	note \6, "will select from table $table\n";
	note \6, "will select fields " . join(', ', @fields) . "\n";
	$fields{$table} = \@fields;
    }
    return \%fields;
}

sub filter_values {
    # returns the table name, field names and bind values for any method name
    my $class = shift;
    my $filter = shift;
    my $persist = shift;
    my $method_tables = shift || method_tables($class, $persist);
    my %values = ();
    foreach my $method (keys %$filter) {
	if (UNIVERSAL::can($filter, $method)) {
	    my $value = $filter->$method();
	    if (!defined($value) or !length($value)) {
		# undefined values of an object do not count as filter parameters
	        next;
	    }
	}
	# TODO skip warning if filter is an object, rather than a HASH
	unless (exists($method_tables->{$method})) {
	    warn "ignoring unknown filter field '$method'\n";
	    next;
	}
        my $table = $method_tables->{$method};
	my $methods = $persist->{$table}{methods};
	note \6, "filtering on $method\n";
	my $field = $methods->{$method};
	my @field = ();
	my @value = ();
	local $::OBJECT = $filter;
	if (ref($field)) {
	    if (ref($field) eq 'HASH' and exists($field->{fields})) {
		push @field, ref($field->{fields}) eq 'ARRAY' ? @{$field->{fields}} : $field->{fields};
		my $deflate = exists($field->{deflate}) ? $field->{deflate} : sub { @_ };
		if (UNIVERSAL::can($filter, $method)) {
		    push @value, $deflate->($filter->$method());
		} else {
		    push @value, $deflate->($filter->{$method});
		}
	    }
	} else {
	    push @field, $field;
	    if (UNIVERSAL::can($filter, $method)) {
		push @value, $filter->$method();
	    } else {
		push @value, $filter->{$method};
	    }
	}
	unless (@field == @value) {
	    warn "filter for $method specified " . scalar(@field) . " fields, but " . scalar(@value) . " values\n";
	}
	for (my $i = 0; $i < @field; $i++) {
	    note \6, "  ($table.$field[$i] = $value[$i])\n";
	}
	$values{$table} ||= { 'fields' => [], 'values' => [] };
	push @{$values{$table}{fields}}, @field;
	push @{$values{$table}{values}}, @value;
    }
    return \%values;
}

sub add_filter_defaults {
    # add values from table filter hash, for fields which have not been set
    my $class = shift;
    my $filter_values = shift;
    my $persist = shift;
    my $table = shift;
    my %new = ();
    if (exists($persist->{$table}{filter}) and keys(%{$persist->{$table}{filter}})) {
	note \6, "adding default filter values\n";
	my %seen = ();
	%seen = map { $_ => 1 } @{$filter_values->{$table}{fields}} if (exists($filter_values->{$table}));
	my $default = $persist->{$table}{filter};
        foreach my $field (keys %$default) {
	    unless (exists($seen{$field})) {
		push @{$new{fields}}, $field;
		push @{$new{values}}, $default->{$field};
		note \6, "  ($table.$field = $default->{$field})\n";
	    }
	}
    }
    return \%new;
}

sub fetchrows {
    my $class = shift;
    my $dbh = shift;
    my $query = shift;
    my $bind = shift;
    my @records = ();
    if ($dbh and my $sth = $dbh->prepare($query)) {
	note \2, $sth->{Statement} . ' -> ' . join(', ', map { defined($_) ? $_ : '' } @$bind) . "\n";
        if ($sth->execute(@$bind)) {
	    while (my $record = $sth->fetchrow_hashref('NAME_lc')) {
		push @records, $record;
	    }
	}
    }
    note \2, "fetched " . scalar(@records) . " records\n";
    return @records if wantarray;
    return \@records;
}

sub join_records {
    my $class = shift;
    my $persist = shift;
    my $parent = shift; # table name
    my $data = shift; # master dataset
    my $child = shift; # table name
    my $records = shift; # records
    my $join = $persist->{$child}{join}{$parent} || return; # can't join without instructions
    my %parent = (); # keyed off join identifier
    my $children = 0; # count matches
    my %joined = ();
    note \5, "joining " . scalar(@$records) . " $child to matching $parent records\n";
    foreach my $d (@$data) {
	my @identifier = ();
        foreach my $field (sort keys %$join) {
	    push @identifier, $field, $d->{$parent}[0]->{lc($field)};
	}
	my $identifier = join(':', @identifier);
	#note \7, "  building parent identifier $identifier\n";
	push @{$parent{$identifier}}, $d;
    }
    foreach my $r (@$records) {
        my @identifier = ();
	foreach my $field (sort keys %$join) {
	    push @identifier, $field, $r->{lc($join->{$field})};
	}
	my $identifier = join(':', map { defined($_) ? $_ : '' } @identifier);
	#note \7, "  building child identifier $identifier\n";
	if (exists($parent{$identifier})) {
	    #note \7, "  joining on $identifier\n";
	    foreach my $d (@{$parent{$identifier}}) {
		# TODO do not push child record onto data record more than once (in multiple join scenario)
	        push @{$d->{$child}}, $r;
		$children++;
		$joined{$identifier}++;
	    }
	}
    }
    note \5, "joined $children $child to " . scalar(keys %joined) . " $parent records\n";
    return $children;
}

sub inflated_object {
    # returns iterator to turn table/field data into an object
    my $class = shift;
    my $persist = shift;
    my $data = shift; # ARRAY ref we shift from
    my $objects = shift; # should only ever contain zero or one objects
    my $c = 0;
    return sub {
        return unless @$data;
        my ($dbh) = @_;
	my $d = shift(@$data);
	my $object = $objects->[$c++] ||= $class->new();
	local $::OBJECT = $object;
        my @postinflate = ();
	foreach my $table (keys %$d) {
	    my $records = $d->{$table};
	    note "[$c] inflating object $class with " . scalar(@$records) . " records from $table\n";
	    my $methods = $persist->{$table}{methods};
	    foreach my $method (keys %$methods) {
		note \6, "inflating method $method\n";
		my $field = $methods->{$method};
		if (ref($field)) {
		    if (ref($field) eq 'HASH' and exists($field->{fields})) {
			my @field = ();
			push @field, ref($field->{fields}) eq 'ARRAY' ? @{$field->{fields}} : $field->{fields};
			if (UNIVERSAL::can($object, $method)) {
			    my @values = ();
			    foreach my $record (@$records) {
				if (exists($field->{inflate})) {
				    push @values, $field->{inflate}->(@{$record}{@field});
				} else {
				    push @values, @{$record}{@field};
				}
				foreach my $field (@field) {
				    note \6, "  ($field = " . (defined($record->{$field}) ? $record->{$field} : '') . ")\n";
				}
			    }
			    if ($field->{forceref} or ($field->{wantref} and @values > 1)) {
				$object->$method(\@values);
			    } else {
				$object->$method(@values);
			    }
			    if (exists($field->{postinflate})) {
                                push @postinflate, $field->{postinflate};
			    }
			} else {
			    # TODO some warning - can't run method on object
			}
		    } elsif (ref($field) eq 'HASH') {
			if (exists($field->{inflate})) {
			    push my @values, $field->{inflate}->();
			    foreach my $value (@values) {
			        note \6, "  ( = $value)\n";
			    }
			    $object->$method(@values);
			}
			if (exists($field->{postinflate})) {
                            push @postinflate, $field->{postinflate};
			}
		    }
		} else {
		    if (UNIVERSAL::can($object, $method)) {
			my @values = ();
			foreach my $record (@$records) {
			    push @values, $record->{$field};
			    note \6, "  ($field = " . (defined($record->{$field}) ? $record->{$field} : 'undef') . ")\n";
			}
			$object->$method(@values);
		    } else {
			# TODO some warning - can't run method on object
		    }
		}
	    }
	}
        note \6, "running postinflate hooks\n" if @postinflate;
        foreach my $code (@postinflate) {
            $code->($dbh);
        }
	return $object;
    };
}

sub method_tables {
    my $class = shift;
    my $persist = shift;
    my %table = ();
    foreach my $table (keys %$persist) {
        foreach my $method (keys %{$persist->{$table}{methods}}) {
	    $table{$method} = $table;
	}
    }
    return \%table;
}

1;
__END__

=head1 NAME

Class::Inflate - Inflate HASH Object from Values in Database

=head1 SYNOPSIS

  # in package
  package Some::Package::Name;
  use Class::Inflate (
      $table_one => {
          key => \@primary_key_fields,
	  methods => {
	      $method_one => $field_one,
	      $method_two => {
	          inflate => sub { join('-', @_) },
		  deflate => sub { split(/-/, shift(), 2) },
		  fields  => [$field_two, $field_three],
	      },
	  },
      },
      $table_two => {
          key => \@primary_key_fields,
	  join => {
	      $table_one => {
	          $field_one => $field_1,
	      },
	  },
	  methods => {
	      $method_$three => $field_2,
	  }
      },
  );

  # in script
  use Some::Package::Name;
  my @objects = Some::Package::Name->inflate({$field_one => $value});
  
=head1 DESCRIPTION

Allows for any blessed HASH object to be populated from a database, by
describing table relationships to each method.

When specifying a database relationship to a method, there are several
hooks you can specify:

=over 4

=item inflate

Called when converting database values into method values.  Receives
the values from the database fields specified.  The return values are 
passed to the object accessor for the method.

=item postinflate

Called after object has been inflated. The variable C<$::OBJECT> is
available, and contains the object being populated.

The database handle used for inflation is available as the first
argument to C<postinflate>.

=item deflate

Called when converting method values into database values.  Receives
the values from the object accessor for the method.  The return values
are passed to the database fields specified.

=back

The database fields are specified as an ARRAY reference of field names,
if any of the hooks are used.

=head2 EXPORT

Exports C<inflate> method into caller's namespace.

=head1 SEE ALSO

Tangram(3), Class::DBI(3), which have similar concepts, but are tied
more closely to database structure.

=head1 AUTHOR

Nathan Gray, E<lt>kolibrie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2008 by Nathan Gray

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
