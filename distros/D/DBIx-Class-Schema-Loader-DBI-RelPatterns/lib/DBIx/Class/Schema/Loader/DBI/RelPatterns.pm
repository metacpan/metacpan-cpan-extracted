package DBIx::Class::Schema::Loader::DBI::RelPatterns;

use strict;
use warnings;

our $VERSION = '0.01043';

use 5.006;

use base qw/DBIx::Class::Schema::Loader::DBI Class::Accessor::Grouped/;
use MRO::Compat;
use mro 'c3';
use Carp::Clan qw/^DBIx::Class/;

__PACKAGE__->mk_group_accessors('simple', qw/
    _rel_constraint
    _rel_exclude
/);

unless (__PACKAGE__->can('_disable_uniq_detection')) {
    # in Loader since version 0.07008
    __PACKAGE__->mk_group_accessors('simple', '_disable_uniq_detection');
}

my %INDEX_PRIORITY = (PRIMARY => 3, UNIQUE => 2, ANY => 1);


sub new {
    my ($class, %args) = @_;
    
    # let the driver-specific class load
    my $loader_class = delete $args{loader_class}; # in Loader since version 0.06000
    
    if ($loader_class && $loader_class ne $class) {
        die "Unexpected error: loader class $loader_class is not $class";
    }
    
    my $self = $class->next::method(%args);
    
    # put back the deleted value, just in case
    $self->{loader_class} = $loader_class if $loader_class;
    
    unless ($self->isa($class)) {
        my $superclass = ref $self;
        
        # security blanket: make sure prospective foster parent does not have our methods
        unless ($self->{_relpat_override} || $self->{_relpat_inherit}) {
            foreach my $method (qw/
                _columns_index_for
                _compat_table
                _match_constraint
                _normalize_rel_arg
                _schemas_eq
                _table_indexes_info
            /) {
                die "Unexpected error: $method in $class has super-method in $superclass" if $self->can($method);
                # _relpat_inherit: "*$method = $supermethod" redefinition is
                # a little too global and takes us past the point of no return.
                # instead each of the listed methods has to support _relpat_inherit
                # option and goto next::method when available.
                # not laconic but reliable.
            }
        }
        
        # inherit from the driver-specific class
        unshift our(@ISA), $superclass;
        # Class::C3 needs a kick to notice @ISA changes
        Class::C3::reinitialize();
        # ready to get back behind the wheel
        bless $self, $class;
    }
    
    $self->_rel_constraint( $self->_normalize_rel_arg('rel_constraint') );
    $self->_rel_exclude( $self->_normalize_rel_arg('rel_exclude') );
    
    if (!$self->_rel_constraint) {
        warn "RelPatterns loader class makes little sense without rel_constraint patterns\n" unless $self->quiet;
    }
    
    return $self;
}


# takes arg name and optionally raw arg value
# returns normalized arg value
sub _normalize_rel_arg {
    my $self = shift;
    my ($arg, $input) = @_;
    
    return $self->next::method(@_) if $self->{_relpat_inherit} && $self->next::can;
    
    $arg ||= '';
    
    if ($arg ne 'rel_constraint' && $arg ne 'rel_exclude') {
        die "Unexpected error: unknown arg $arg";
    }
    
    $input ||= $self->{$arg} or return;
    
    my $reftype = ref $input;
    if ($reftype ne 'ARRAY') {
        croak "Invalid type $reftype for option '$arg'; must be an array refference";
    } elsif (@$input % 2) {
        croak "Option '$arg' cannot take an arrayref with odd number of elements; must be even";
    }
    
    my %accepted = (
        type => { similar => 1, exact => 1 },
    );
    
    my %defaults = (
        local  => { sch => '', index => 'any' },
        remote => { sch => '', index => 'any', type => 'exact', diag => 0 },
    );
    
    my @input = @$input;
    my @output;
    while (@input) {
        my (%local, %remote);
        my $is_empty = 1; # for adjustment of defaults
        
        foreach my $con (\%local, \%remote) {
            my $constraint = shift @input || '';
            
            my $reftype = ref $constraint;
            if (!$reftype) {
                # reversed because both 'fooid' and 'foo.fooid' point to column fooid
                # no stripping because 'foo.' points to table foo
                @$con{ qw/col tab sch/ } = reverse split /\./, $constraint, -1;
            } elsif ($reftype eq 'ARRAY') {
                # the same principle applies to arrayrefs
                @$con{ qw/col tab sch/ } = reverse @$constraint;
            } elsif ($reftype eq 'Regexp') {
                $con->{ $con == \%local ? 'col' : 'tab' } = $constraint;
            } elsif ($reftype eq 'HASH') {
                %$con = %$constraint;
            } else {
                croak "Invalid type $reftype for option's '$arg' element; must be a scalar, qr// regexp, an arrayref or a hashref";
            }
            
            my $string = '';
            foreach my $key (reverse qw/col tab sch/) {
                my $val = $con->{$key} || '';
                next unless $val || $string;
                $string .= ', ' if $string;
                $string .= (ref $val eq 'Regexp') ? "qr/$val/" : "'$val'";
            }
            $con->{string} = '[' . $string . ']'; #for debugging purposes only
            
            # respect preserve_case
            $con->{col} = $self->_lc( $con->{col} ) if $con->{col} && !ref $con->{col};
            
            # default sch can be set only for rel_constraint
            foreach my $key ($arg eq 'rel_constraint' ? qw/col tab/ : qw/col tab sch/) {
                $is_empty = 0 if $con->{$key};
            }
        }
        
        if ($arg eq 'rel_constraint') {
            foreach my $key (qw/type diag/) {
                croak "Hashref's key '$key' applies only to relationship pattern's right-hand side" if $local{$key};
            }
            foreach my $con (\%local, \%remote) {
                my $side = ($con == \%local) ? 'local' : 'remote';
                while (my ($key, $accepted) = each %accepted) {
                    $con->{$key} = $defaults{$side}{$key} if $con->{$key} && !$accepted->{ $con->{$key} };
                }
                if ($is_empty) {
                    # adjust the defaults
                    $defaults{$side}{sch}   = $con->{sch}   if defined $con->{sch};
                    $defaults{$side}{index} = $con->{index} if $con->{index};
                    $defaults{$side}{type}  = $con->{type}  if $con->{type} && $side eq 'remote';
                    $defaults{$side}{diag}  = $con->{diag}  if defined $con->{diag} && $side eq 'remote';
                } else {
                    # apply the defaults
                    $con->{sch}     = $defaults{$side}{sch}  if !defined $con->{sch};
                    $con->{index} ||= $defaults{$side}{index};
                    $con->{type}  ||= $defaults{$side}{type} if $side eq 'remote';
                    $con->{diag}    = $defaults{$side}{diag} if !defined $con->{diag} && $side eq 'remote';
                    
                    $con->{min_index_priority} = $INDEX_PRIORITY{ uc $con->{index} } || 0;
                    
                    # force index=>'optional' when tab and col are non-empty strings
                    if ($con->{tab} && $con->{col} && !ref $con->{tab} && !ref $con->{col}) {
                        $con->{min_index_priority} = 0;
                    }
                }
            }
        }
        
        next if $is_empty;
        
        push @output, [\%local, \%remote];
    }
    
    return @output ? \@output : undef;
}


# the brain of this module.
# constraint can be a string or a qr// regexp (returns true if missing or empty)
# if captured_ref is provided, then capture groups are compared
# if captured_ref is a reference, then captured_ref is modified
sub _match_constraint {
    my $self = shift;
    my ($string, $constraint, $captured_ref) = @_;
    
    return $self->next::method(@_) if $self->{_relpat_inherit} && $self->next::can;
    
    # schema and _schema can be undef (_schema is needed for testing purposes only)
    $string ||= '';
    
    # no constraint means nothing to match
    return 1 unless $constraint;
    
    return $string eq $constraint if ref $constraint ne 'Regexp';
    
    my @cap = $string =~ /$constraint/ or return;
    
    # compare capture groups only if needed and if regexp creates them
    return 1 unless defined $captured_ref && defined $1;
    
    # if modifying the original is not desired...
    if (!ref $captured_ref) {
        my $captured = $captured_ref;
        $captured_ref = \$captured;
    }
    
    my $cap = join "\0", @cap;
    if (!defined $$captured_ref || $cap =~ /\A\Q$$captured_ref\E\0/i) {
        # update captured if cap has more contents
        $$captured_ref = $cap;
    }
    
    # ideally, cap should eq captured;
    # but also fine if captured starts with cap
    return $$captured_ref =~ /\A\Q$cap\E(?:\0|\z)/i;
}


sub _schemas_eq {
    my $self = shift;
    my ($table_a, $table_b) = @_;
    
    return $self->next::method(@_) if $self->{_relpat_inherit} && $self->next::can;
    
    # _schema is needed for testing purposes only
    return (
        ($table_a->schema || $table_a->_schema || '') eq
        ($table_b->schema || $table_b->_schema || '')
    );
}


# takes a database object
# returns a hashref of index information per column
sub _columns_index_for {
    my $self = shift;
    my ($table) = @_;
    
    return $self->next::method(@_) if $self->{_relpat_inherit} && $self->next::can;
    
    my $pks   = $self->_table_pk_info($table) || [];
    my $uniqs = $self->_table_uniq_info($table) || [];
    my $indxs = $self->_table_indexes_info($table) || []; # requires statistics_info
    
    my %indexes;
    
    foreach (
        [ $INDEX_PRIORITY{PRIMARY} => [ ['PRIMARY', $pks] ] ],
        [ $INDEX_PRIORITY{UNIQUE}  => $uniqs ],
        [ $INDEX_PRIORITY{ANY}     => $indxs ], # NB! contains other indexes as well
    ) {
        my ($priority, $index_info) = @$_;
        foreach (@$index_info) {
            my ($index_name, $cols) = @$_;
            my $index_size = @$cols;
            foreach my $position (0..$#$cols) {
                my $col = $cols->[$position];
                
                # refine the priority
                my $priority = ($priority
                    # leading column is preferable
                    + (99 - $position)   / 100
                    # larger index is preferable
                    + $index_size        / 100**2
                    # shorter name is preferable (hopefully, it's "id")
                    #+ (99 - length $col) / 100**3 # not convinced, commented out
                );
                
                # not fail-proof in general, but especially if column
                # is listed in multiple indexes with equal priority
                $indexes{$col} = {
                    # for sort and rel_constraint's 'index' key
                    priority => $priority,
                    # for is_leftmost
                    position => $position,
                    # for sort
                    size => $index_size,
                    # for composite-key relationships
                    cols => $cols,
                } unless $indexes{$col} && $indexes{$col}{priority} >= $priority;
            }
        }
    }
    
    return \%indexes;
}


# the heart of this module.
# takes a database object
# returns the identified relationships
sub _table_fk_info {
    my $self = shift;
    my $table = $self->_compat_table(shift);
    
    if (my $cached = $self->{_cache}{_table_fk_info}{$table->sql_name}) {
        return $cached;
    }
    
    my $rels = $self->next::method($table);
    
    my $rel_constraint = $self->_rel_constraint || [];
    my $rel_exclude    = $self->_rel_exclude || [];
    
    return $self->{_cache}{_table_fk_info}{$table->sql_name} = $rels if !@$rel_constraint;
    
    my $columns = $self->_table_columns($table);
    my $infos   = $self->_columns_info_for($table) || {};
    my $indexes = $self->_columns_index_for($table);
    
    # all possible single-column relationships and diagnostics of failures
    my (@rels_single, %diag);
    
    foreach my $rel_con (@$rel_constraint) {
        my ($con_local, $con_remote) = @$rel_con;
        my ($captured, $captured_sch);
        
        next unless $con_local->{col} && $con_remote->{tab}
             && $self->_match_constraint($table->schema || $table->_schema, $con_local->{sch}, \$captured_sch)
             && $self->_match_constraint($table->name, $con_local->{tab}, \$captured);
        
        my @remote_tables = grep {
               # self-referential rels are set up only if tab is specified on both sides
               ($con_local->{tab} && $con_remote->{tab} || $_->sql_name ne $table->sql_name)
            && $self->_match_constraint($_->schema || $_->_schema, $con_remote->{sch}, \$captured_sch)
            && $self->_match_constraint($_->name, $con_remote->{tab})
        } map $self->_compat_table($_), $self->tables;
        
        COL:
        foreach my $col (@$columns) {
            # vivify to keep it simple
            $indexes->{$col} ||= { priority=>0, position=>0, size=>0, cols=>[] };
            
            # limit the scope a little, so that every column could have a fresh copy
            my $captured = $captured;
            my @remote_tables = @remote_tables;
            
            next COL if $con_local->{min_index_priority} > $indexes->{$col}{priority}
                     || !$self->_match_constraint($col, $con_local->{col}, \$captured);
            
            @remote_tables = sort {
                   # tables from the same schema are preferable
                   $self->_schemas_eq($table, $b) <=> $self->_schemas_eq($table, $a)
                   # better than random
                || $a->name cmp $b->name
            } grep {
                $self->_match_constraint($_->name, $con_remote->{tab}, $captured)
            } @remote_tables;
            
            my ($r_table, $r_col, $r_indexes, @r_cols);
            
            # iterate over tables in order of priority until the corresponding column is found
            RTAB:
            while ($r_table = shift @remote_tables) {
                my $r_columns = $self->_table_columns($r_table);
                my $r_infos   = $self->_columns_info_for($r_table) || {};
                   $r_indexes = $self->_columns_index_for($r_table);
                
                @r_cols = ();
                
                RCOL:
                foreach my $r_col (@$r_columns) {
                    # vivify to keep it simple
                    $r_indexes->{$r_col} ||= { priority=>0, position=>0, size=>0, cols=>[] };
                    
                    next RCOL if ($table->sql_name eq $r_table->sql_name && $col eq $r_col)
                              || !$self->_match_constraint($r_col, $con_remote->{col}, $captured);
                    
                    if ($con_remote->{min_index_priority} > $r_indexes->{$r_col}{priority}) {
                        push @{ $diag{$rel_con} }, ['index mismatch', $col, $r_table, $r_col];
                        next RCOL;
                    }
                    
                    if (exists $infos->{$col} && exists $r_infos->{$r_col}) {
                        # referencing column type has to match
                        if (($infos->{$col}{data_type} || '') ne ($r_infos->{$r_col}{data_type} || '')) {
                            push @{ $diag{$rel_con} }, ['data type mismatch', $col, $r_table, $r_col];
                            next RCOL;
                        }
                        
                        # if size of column data type cannot be ignored...
                        if ($con_remote->{type} eq 'exact') {
                            my $col_size   = $infos->{$col}{size} || 0;
                            my $r_col_size = $r_infos->{$r_col}{size} || 0;
                            $col_size      = join "\0", @$col_size   if ref $col_size eq 'ARRAY';
                            $r_col_size    = join "\0", @$r_col_size if ref $r_col_size eq 'ARRAY';
                            if ($col_size ne $r_col_size) {
                                push @{ $diag{$rel_con} }, ['data type size mismatch', $col, $r_table, $r_col];
                                next RCOL;
                            }
                        }
                    } elsif ($con_remote->{type} eq 'exact') {
                        # force majeure, columns' info is not available;
                        # in such a case column data types still are considered to be 'similar'
                        # but certainly not 'exact'
                        push @{ $diag{$rel_con} }, ['unknown data type', $col, $r_table, $r_col];
                        next RCOL;
                    }
                    
                    foreach (@$rel_exclude) {
                        my ($exc_local, $exc_remote) = @$_;
                        my ($captured, $captured_sch);
                        next unless (
                               $self->_match_constraint($table->schema || $table->_schema, $exc_local->{sch}, \$captured_sch)
                            && $self->_match_constraint($r_table->schema || $r_table->_schema, $exc_remote->{sch}, \$captured_sch)
                            && $self->_match_constraint($table->name,   $exc_local->{tab}, \$captured)
                            && $self->_match_constraint($col,           $exc_local->{col}, \$captured)
                            && $self->_match_constraint($r_table->name, $exc_remote->{tab}, \$captured)
                            && $self->_match_constraint($r_col,         $exc_remote->{col}, \$captured)
                        );
                        push @{ $diag{$rel_con} }, ['matched but excluded', $col, $r_table, $r_col];
                        next RCOL;
                    }
                    
                    push @r_cols, $r_col;
                }
                
                @r_cols = sort {
                       # primary or unique key is preferable, basically
                       $r_indexes->{$b}{priority} <=> $r_indexes->{$a}{priority}
                       # better than random
                    || $a cmp $b
                } @r_cols;
                
                last RTAB if $r_col = shift @r_cols;
            }
            
            next COL if !$r_table;
            
            @remote_tables = grep {
                $self->_schemas_eq($table, $_) == $self->_schemas_eq($table, $r_table)
            } @remote_tables;
            
            if (@remote_tables) {
                my $remote_tables = join ', ', $r_table, @remote_tables;
                warn "Multiple tables meet the conditions for $table.$col foreign key and have equal priority: $remote_tables; $con_local->{string} => $con_remote->{string}.\n" unless $self->quiet;
                next COL;
            }
            
            next COL if !$r_col;
            
            @r_cols = grep {
                $r_indexes->{$_}{priority} == $r_indexes->{$r_col}{priority}
            } @r_cols;
            
            if (@r_cols) {
                my $r_cols = join ', ', $r_col, @r_cols;
                warn "Multiple columns in the referenced table $r_table meet the conditions for $table.$col foreign key and have equal priority: $r_cols; $con_local->{string} => $con_remote->{string}.\n" unless $self->quiet;
                next COL;
            }
            
            push @rels_single, {
                local_column       => $col,
                local_index        => $indexes->{$col},
                local_is_leftmost  => !$con_local->{min_index_priority} || !$indexes->{$col}{position},
                remote_table       => $r_table,
                remote_column      => $r_col,
                remote_index       => $r_indexes->{$r_col},
                remote_is_leftmost => !$con_remote->{min_index_priority} || !$r_indexes->{$r_col}{position},
                rel_con            => $rel_con,
            };
        }
    }
    
    # better to process the largest composite indexes first
    @rels_single = sort {
           $b->{remote_index}{size} <=> $a->{remote_index}{size}
        || $b->{local_index}{size}  <=> $a->{local_index}{size}
    } @rels_single;
    
    foreach my $rel (@rels_single) {
        next unless %$rel;
        
        my ($col, $r_table, $r_col, $rel_con) = @$rel{ qw/
            local_column remote_table remote_column rel_con
        / };
        
        my (@cols, @r_cols);
        
        # corresponding columns should form the leftmost prefixes of the indexes
        my $is_leftmost = 0;
        
        # do not require local_index to be composite as well
        # because this would require statistics_info method
        if ($rel->{remote_index}{size} > 1) {
            # iterate over columns of the composite index:
            # this can be done with either local_index or remote_index,
            # but remote_index is more likely to be unique
            # and hence not require statistics_info method
            foreach my $r_col (@{ $rel->{remote_index}{cols} }) {
                my $mapped = 0;
                foreach my $rel2 (@rels_single) {
                    # locate the corresponding relationship
                    next unless %$rel2
                         && $rel2->{remote_table}->sql_name eq $r_table->sql_name
                         && $rel2->{remote_column} eq $r_col;
                    
                    # not sure if any of these are necessary,
                    # commented out for the time being
                    #next unless $rel2->{local_is_leftmost}  || $rel2->{local_index}{position}  == @cols;
                    #next unless $rel2->{remote_is_leftmost} || $rel2->{remote_index}{position} == @r_cols;
                    # make sure all r_cols are included in this rel's remote_index
                    #my %rel2_index_cols = map {$_ => 1} @{ $rel2->{remote_index}{cols} };
                    #next if grep !$_, @rel2_index_cols{ @r_cols };
                    
                    push @cols,   $rel2->{local_column};
                    push @r_cols, $rel2->{remote_column};
                    
                    $mapped = 1;  # first mapped=1 implies remote_is_leftmost
                    $is_leftmost = 1 if $rel2->{local_is_leftmost};
                    undef %$rel2; # so this one is processed
                    last;
                }
                
                # at least the leftmost prefix of the composite index has to be mapped
                last unless $mapped;
            }
        }
        
        if (!@cols) {
            @cols   = ($col);
            @r_cols = ($r_col);
            $is_leftmost = 1 if $rel->{local_is_leftmost} && $rel->{remote_is_leftmost};
        }
        
        my $cols   = join ',', @cols;
        my $r_cols = join ',', @r_cols;
        
        unless ($is_leftmost) {
            push @{ $diag{$rel_con} }, ['matched but not leftmost', $cols, $r_table, $r_cols];
            next;
        }
        
        @cols   = map $self->_lc($_), @cols;
        @r_cols = map $self->_lc($_), @r_cols;
        
        my $is_a_duplicate = grep {
               $r_table->sql_name eq $self->_compat_table($_->{remote_table})->sql_name
            && $#cols <= $#{ $_->{local_columns} }
            && join("\0", @cols) eq join("\0", @{ $_->{local_columns} }[0..$#cols])
        } @$rels;
        
        if ($is_a_duplicate) {
            push @{ $diag{$rel_con} }, ['matched but duplicated', $cols, $r_table, $r_cols];
            next;
        }
        
        warn sprintf "Relationship matched: %s.%s => %s.%s\n", $table, $cols, $r_table, $r_cols if $self->debug && !$self->quiet;
        
        push @$rels, {
            local_columns  => \@cols,
            remote_columns => \@r_cols,
            remote_table   => $r_table,
        };
        
        undef %$rel; # just in case
    }
    
    if (%diag && !$self->quiet) {
        foreach my $rel_con (@$rel_constraint) {
            my ($con_local, $con_remote) = @$rel_con;
            
            next unless $con_remote->{diag};
            
            my $diag = $diag{$rel_con} or next;
            
            my $diagnostics = join '', map {
                my ($message, $col, $r_table, $r_col) = @$_;
                sprintf " - %-24s: %s.%s => %s.%s\n", $message, $table, $col, $r_table, $r_col;
            } @$diag;
            
            warn $table->dbic_name . ", diagnostics for rel_constraint: $con_local->{string} => $con_remote->{string}\n" . $diagnostics if $diagnostics;
        }
    }
    
    return $self->{_cache}{_table_fk_info}{$table->sql_name} = $rels;
}


# adapted from DBIx::Class::Schema::Loader::DBI::_table_uniq_info()
# with unique_only in statistics_info call set to undef instead of 1
sub _table_indexes_info {
    my $self = shift;
    my ($table) = @_;
    
    return $self->next::method(@_) if $self->{_relpat_inherit} && $self->next::can;
    
    return [] if $self->_disable_uniq_detection;
    
    if (my $cached = $self->{_cache}{_table_indexes_info}{$table->sql_name}) {
        return $cached;
    }
    
    if (not $self->dbh->can('statistics_info')) {
        warn "RelPatterns loader class is unable to obtain the non-unique index information with " . $self->dbh->{Driver}->{Name} . " driver.\n" unless $self->quiet;
        $self->_disable_uniq_detection(1);
        return [];
    }

    my %indices;
    my $sth = $self->dbh->statistics_info(undef, $table->schema, $table->name, undef, 1);
    while(my $row = $sth->fetchrow_hashref) {
        # skip table-level stats, conditional indexes, and any index missing
        #  critical fields
        next if $row->{TYPE} eq 'table'
            || defined $row->{FILTER_CONDITION}
            || !$row->{INDEX_NAME}
            || !defined $row->{ORDINAL_POSITION};

        $indices{$row->{INDEX_NAME}}[$row->{ORDINAL_POSITION}] = $self->_lc($row->{COLUMN_NAME} || '');
    }
    $sth->finish;

    my @retval;
    foreach my $index_name (sort keys %indices) {
        my (undef, @cols) = @{$indices{$index_name}};
        # skip indexes with missing column names (e.g. expression indexes)
        next unless @cols == grep $_, @cols;
        push(@retval, [ $index_name => \@cols ]);
    }
    
    return $self->{_cache}{_table_indexes_info}{$table->sql_name} = \@retval;
}


# a bit of caching to reduce the number of queries

sub _columns_info_for {
    my $self = shift;
    my $table = $self->_compat_table(shift);
    return $self->{_cache}{_columns_info_for}{$table->sql_name} ||= $self->next::method($table);
}

sub _table_columns {
    my $self = shift;
    my $table = $self->_compat_table(shift);
    return $self->{_cache}{_table_columns}{$table->sql_name} ||= $self->next::method($table);
}

sub _table_pk_info {
    my $self = shift;
    my $table = $self->_compat_table(shift);
    return $self->{_cache}{_table_pk_info}{$table->sql_name} ||= $self->next::method($table);
}

sub _table_uniq_info {
    my $self = shift;
    my $table = $self->_compat_table(shift);
    return $self->{_cache}{_table_uniq_info}{$table->sql_name} ||= $self->next::method($table);
}


# compatibility stuff

if ($DBIx::Class::Schema::Loader::DBI::VERSION < 0.07011 && !__PACKAGE__->can('quiet')) {
    __PACKAGE__->mk_group_ro_accessors('simple', 'quiet');
}

sub _lc {
    my $self = shift;
    if ($DBIx::Class::Schema::Loader::DBI::VERSION < 0.07000 && !$self->next::can) {
        return lc shift;
    }
    return $self->next::method(@_);
}

sub dbh {
    my $self = shift;
    if ($DBIx::Class::Schema::Loader::DBI::VERSION < 0.07011 && !$self->next::can) {
        return $self->schema->storage->dbh;
    }
    return $self->next::method(@_);
}

sub _compat_table {
    my $self = shift;
    my ($table) = @_;
    return $self->next::method(@_) if $self->{_relpat_inherit} && $self->next::can;
    if ($DBIx::Class::Schema::Loader::DBI::VERSION < 0.07011 && !ref $table) {
        return DBIx::Class::Schema::Loader::DBI::RelPatterns::TableCompat->new($table);
    }
    return $table;
}

package # hide from PAUSE
    DBIx::Class::Schema::Loader::DBI::RelPatterns::TableCompat;

use overload '""' => sub { $_[0]->name }, fallback => 1;

sub new {
    my $class = shift;
    return bless { name => shift }, $class;
}

sub schema    { undef }
sub _schema   { undef }
sub name      { $_[0]->{name} }
sub sql_name  { $_[0]->{name} }
sub dbic_name { $_[0]->{name} }

1;

__END__

=head1 NAME

DBIx::Class::Schema::Loader::DBI::RelPatterns - Relationship patterns for DBIx::Class::Schema::Loader

=head1 SYNOPSIS

    ### DBIx::Class::Schema::Loader synopsis with emphasis on
    ### loader_class argument and the added constructor options

    # in a script
    use DBIx::Class::Schema::Loader qw/ make_schema_at /;
    make_schema_at(
        'My::Schema',
        { debug => 1,
          dump_directory => './lib',
          rel_constraint => [
              'bar_id' => 'bars.id',
              qr/(.*?)s?_?id$/i => qr/(.*?)s?$/i,
          ],
          rel_exclude => [
              'foo_id' => 'foos.',
              'foos.' => '',
          ],
        },
        [ 'dbi:mysql:dbname="foo"', 'myuser', 'mypassword',
          { loader_class => '::DBI::RelPatterns' }
        ],
    );

    # from the command line or a shell script with dbicdump (distributed
    # with DBIx::Class::Schema::Loader). Do `perldoc dbicdump` for usage.
    dbicdump -o dump_directory=./lib \
             -o components='["InflateColumn::DateTime"]' \
             -o rel_constraint='[qr/(.*?)s?_?id$/i => qr/(.*?)s?$/i]' \
             -o rel_exclude='["foo_id" => "foos."]' \
             -o debug=1 \
             My::Schema \
             'dbi:mysql:dbname=foo' \
             myuser \
             mypassword \
             '{ loader_class => "::DBI::RelPatterns" }'

    ### or generate and load classes at runtime
    # note: this technique is not recommended
    # for use in production code
    
    package My::Schema;
    use base qw/DBIx::Class::Schema::Loader/;
    
    __PACKAGE__->loader_options(
        rel_constraint => [ qr/(.*?)s?_?id$/i => qr/(.*?)s?$/i ],
        rel_exclude    => [ 'foo_id' => 'foos.' ],
        # debug        => 1,
    );

    ### in application code elsewhere:
    
    use My::Schema;
    
    my $schema1 = My::Schema->connect($dsn, $user, $password,
           { loader_class => '::DBI::RelPatterns', %attrs });
    # -or-
    my $schema1 = "My::Schema";
    $schema1->connection(as above);
    # -or-
    my $schema1 = "My::Schema";
    $schema1->loader_class('::DBI::RelPatterns');
    $schema1->connection($dsn, $user, $password, $attrs);

=head1 DESCRIPTION

DBIx::Class::Schema::Loader::DBI::RelPatterns is a pseudo loader class that provides the means to set up the table relationships when L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader> fails to for any reason. It is designed for use with storage engines that do not support foreign keys, such as MySQL's MyISAM; but should work with pretty much any DBI driver that:

=over

=item *

properly supports C<statistics_info> method (L<DBD::mysql|DBD::mysql> does starting from version 4.029; L<DBD::SQLite|DBD::SQLite> - from 1.40)

=item *

and, more important, is explicitly supported by L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader> DBI implementation.

=back

Unlike conventional loader classes, DBIx::Class::Schema::Loader::DBI::RelPatterns allows L<DBIx::Class::Schema::Loader::DBI|DBIx::Class::Schema::Loader::DBI> to load a driver-specific class, then extends it and wraps some of its methods (hence the word "pseudo"), adding to the mix the relationship patterns, user-definable via L</rel_constraint> and L</rel_exclude> options (which are added to the base options of L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader>). If L</rel_constraint> option is not specified, DBIx::Class::Schema::Loader::DBI::RelPatterns becomes a no-op, passing through to the driver-specific class. Otherwise it helps to set up the relationships whenever corresponding columns in the referencing key and the referenced key meet all of the following conditions:

=over

=item *

they match any of the C<rel_constraint> patterns;

=item *

they match none of the C<rel_exclude> patterns;

=item *

they have exactly the same or similar data types.

=back

In general, the columns also have to be indexed. However, C<rel_constraint> patterns allow one to explicitly specify that being indexed is not mandatory. This seems like a bad idea, but you may want to (or even have to) do this if the DBI driver in use does not support C<statistics_info> method, which is required to obtain the non-unique index information (which is useless to L<DBIx::Class|DBIx::Class> but can help to avoid the false-positive C<rel_constraint> pattern matches when patterns are not specific enough). Although in such a case the composite-key relationships may be left out, thus limiting the resulting L<DBIx::Class|DBIx::Class> schema to simple-key relationships.

When multiple columns in the referenced table meet the conditions, preference is given - in order of priority - to column that is listed in:

=over

=item *

primary key;

=item *

unique key;

=item *

single-column index;

=item *

composite index as the first column or closer to the first column;

=item *

largest composite index.

=back

If a relationship pattern is way too vague, you may be warned that multiple columns or even tables meet the conditions for some foreign key and have equal priority. To avoid such warnings, either come up with a more specific relationship pattern or exclude the unwanted columns or tables via L</rel_exclude> option.

By design, all determined relationships are considered to be I<simple-key> relationships. However, when multiple relationships between two tables are identified, and columns of these relationships are listed in the corresponding composite indexes as the first columns (i.e., they form the leftmost prefixes), then a I<composite-key> relationship is set up instead of multiple I<simple-key> ones.

Note that C<rel_constraint> and C<rel_exclude> patterns do not affect the relationships that L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader> is able to identify unaided. That is, DBIx::Class::Schema::Loader::DBI::RelPatterns helps to add missing relationships but not alter or remove the ones already identified.

=head1 ADDED CONSTRUCTOR OPTIONS

=head2 rel_constraint

Specifies the relationship patterns between any two tables. Table relationship is set up only if its condition matches any of the specified patterns. The patterns are processed in the order in which they are specified - first in, first out.

This option takes an arrayref with even number of elements (like in a hashref). Every odd element (pattern's left-hand side, a key) refers to the referencing table, while every even element (pattern's right-hand side, a value) refers to the table being referenced. Elements can be strings, qr// regexps, arrayrefs or hashrefs.

Simplified syntax:

    rel_constraint => [
        # column foo_id in table bars references column id in table foos
        'bars.foo_id' => 'foos.id',
        
        # column foo_id in any table references primary key in table foos
        'foo_id' => 'foos.',
        
        # column (.+)_id in any table references primary key in table ${1}s
        # e.g., foo_id => foos.id, bar_id => bars.id, baz_id => bazs.id etc.
        qr/(.+)_id$/i => qr/(.+)s$/i,
        
        # column (.+)_id in any table references column id in table ${1}s
        # including self-referential relationships
        [ qr/(.+)s$/i, qr/(.+)_id$/i ] => [ qr/(.+)s$/i, 'id' ],
    ]

Strings, qr// regexps and arrayrefs actually are shortcuts to the hashrefs:

    rel_constraint => [
        'bar.foo_id' => 'db1.foos.id',
        # hashref equivalents:
        { tab=>'bar', col=>'foo_id' }
            => { sch=>'db1', tab=>'foos', col=>'id' },
        
        'foo_id' => 'foos.id',
        # hashref equivalents:
        { col=>'foo_id' }
            => { tab=>'foos', col=>'id' },
        
        qr/(.*?)s?_?id$/i => qr/(.*?)s?$/i,
        # hashref equivalents:
        { col=>qr/(.*?)s?_?id$/i }
            => { tab=>qr/(.*?)s?$/i },
        
        [ qr/(.+)s$/i, qr/(.+)_id$/i ] => [ qr/(.+)s$/i, 'id' ],
        # hashref equivalents:
        { tab=>qr/(.+)s$/i, col=>qr/(.+)_id$/i }
            => { tab=>qr/(.+)s$/i, col=>'id' },
    ]

If elements are qr// regexps, then the I<key> (pattern's left-hand side) refers to the referencing I<column> name, while the I<value> (pattern's right-hand side) refers to the referenced I<table> name.

If element is a string in I<'schema.table.column'> format, then it gets split from right to left into column name, table name and schema name. That is, C<'foo'> would be column, C<'bar.'> would be table, C<'baz..'> would be schema.

The same principle applies to arrayrefs in I<['schema','table','column']> format: C<['foo']> would be column, C<['bar','']> would be table, C<['baz','','']> would be schema. Such an arrayref can contain strings and qr// regexps.

If element is not a shortcut but a hashref, then it can have the following keys:

=over

=item sch

Schema name; string or qr// regexp.

=item tab

Table name; string or qr// regexp.

=item col

Column name; string or qr// regexp.

=item index

Index restrictions. Accepted values:

=over

=item *

C<'primary'> - match only primary keys;

=item *

C<'unique'> - match unique keys as well;

=item *

C<'any'> (default) - match also non-unique indexes (in other words, all indexed columns);

=item *

C<'optional'> (forced when L</tab> and L</col> are non-empty strings) - match everything, including columns that are not indexed.

=back

=item type

Level of similarity between column data types; applies to pattern's right-hand side. Accepted values:

=over

=item *

C<'similar'> - ignore the size of column data types with size restriction (e.g., allow varchar(10) to reference varchar(15));

=item *

C<'exact'> (default) - require the size to match as well.

=back

=item diag

Diagnostics of failures; false (default) or true, applies to pattern's right-hand side. If true, some diagnostic messages may be emitted, unless suppressed by the base C<quiet> option.

=back

L</sch>, L</index>, L</type> and L</diag> defaults can be adjusted by omitting L</tab> and L</col>. The following two are equivalent:

    rel_constraint => [
        # specify sch, index, type and diag explicitly, without touching the defaults
        { sch=>qr/(.*)/, col=>qr/(.*?)s?_?id$/i, index=>'optional' }
            => { sch=>qr/(.*)/, tab=>qr/(.*?)s?$/i, index=>'unique', type=>'similar', diag=>1 },
    ]

    rel_constraint => [
        # adjust the defaults to forbid cross-schema relationships
        { sch=>qr/(.*)/ } => { sch=>qr/(.*)/ },
        # adjust other defaults
        { index=>'optional' } => { index=>'unique', type=>'similar', diag=>1 },
        # the adjusted defaults are applied to all patterns below
        qr/(.*?)s?_?id$/i => qr/(.*?)s?$/i,
    ]

Note that self-referential relationships are set up only if L</tab> is specified on both sides of the relationship pattern:

    rel_constraint => [
        # self-referential relationship (tab on both sides)
        'foos.foo_id' => 'foos.id',
        
        # not including self-referential relationships;
        # i.e. does not imply the relationship above
        'foo_id' => 'foos.id',
        
        # self-referential relationships (tab on both sides)
        [ qr/(.+)s$/i, qr/(.+)_id$/i ] => [ qr/(.+)s$/i, 'id' ],
        
        # not including self-referential relationships;
        # i.e. does not imply the relationships above
        { col=>qr/(.+)_id$/i } => { tab=>qr/(.+)s$/i, col=>'id' },
    ]

If qr// regexp creates capture groups, then the relationship is set up only when the captured contents of each regular expression within the given relationship pattern do match - with the exception of the captured contents of L</sch> regular expressions because they are matched separately. For example, the following relationship pattern references column C<(foo|bar|baz)_id> with column C<${1}id> in table C<${1}s>:

    rel_constraint => [
        { col=>qr/^(foo|bar|baz)_id$/ }
            => { tab=>qr/^(foo|bar|baz)s$/, col=>qr/^(foo|bar|baz)id$/ },
    ]

Readable equivalent:

    rel_constraint => [
        'foo_id' => 'foos.fooid',
        'bar_id' => 'bars.barid',
        'baz_id' => 'bazs.bazid',
    ]

Generic version:

    rel_constraint => [
        qr/(.+)_id$/i => [ qr/(.+)s$/i, qr/(.+)id$/i ],
    ]

=head2 rel_exclude

Specifies the relationship pattern exclusions. Table relationship is set up only if its condition matches none of the specified patterns.

The syntax is borrowed from L</rel_constraint>; however, only L</sch>, L</tab>, L</col> keys in hashref elements are supported, and default L</sch> cannot be set.

    rel_exclude => [
        # column foo_id in any table should not reference column id in table foos
        'foo_id' => 'foos.id',
        
        # column (.+)_id in any table should not reference column id in table ${1}s
        qr/(.+)_id$/ => [ qr/(.+)s$/, 'id' ],
        
        # any column in table baz should not reference anything
        'baz.' => '',
        
        # any column in tables like 'foo%' should not reference anything
        { tab=>qr/^foo/ } => '',
        
        # anything in schema db1 should not reference anything in schema db2
        'db1..' => 'db2..',
        
        # self-referential relationships should not be set up
        { sch=>qr/(.*)/, tab=>qr/(.+)/ } => { sch=>qr/(.*)/, tab=>qr/(.+)/ },
    ]

=head1 DIAGNOSTICS

The following diagnostic messages, provided that C<< diag => 1 >> is in effect, may be emitted to clarify the reasons for some relationships not being set up:

=over

=item *

C<index mismatch>

Referenced column is not listed in an index that meets the chosen L</index> restrictions.

=item *

C<unknown data type>

Data type of at least one of the corresponding columns is unknown while C<< type => 'exact' >> is in effect.

=item *

C<data type mismatch>

Corresponding columns in the referencing key and the referenced key have different data types.

=item *

C<data type size mismatch>

Size restrictions of the corresponding columns' data types do not match while C<< type => 'exact' >> is in effect.

=item *

C<matched but excluded>

Relationship is excluded by a C<rel_exclude> pattern.

=item *

C<matched but not leftmost>

At least one of the corresponding columns is listed in a composite index not as the first column while a composite-key relationship cannot be set up and C<< index => 'optional' >> is not in effect.

=item *

C<matched but duplicated>

Duplicate relationship exists.

=back

=head1 CAVEATS

When DBIx::Class::Schema::Loader::DBI::RelPatterns is unable to obtain the non-unique index information, a warning is emitted, unless suppressed by the base C<quiet> option. This happens if the DBI driver in use does not support C<statistics_info> method. In such a situation, basically, C<< index => 'any' >>, which is the default, has exactly the same effect as C<< index => 'unique' >>. Most relationships cannot be identified with such restrictions because referencing keys seldom have unique constraints on them. To alleviate this problem, assuming updating the driver is not an option, L</index> defaults can be adjusted the following way:

    rel_constraint => [
        { index=>'optional' } => { index=>'unique' },
        # ...
    ]

Bear in mind that with C<< index => 'optional' >> the patterns have to be more specific to avoid the false-positive matches.

=head1 PREREQUISITES

DBIx::Class::Schema::Loader::DBI::RelPatterns cannot be used with L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader> versions prior to 0.05 because the ability to specify the loader class was not supported in the earlier versions.

=head1 SEE ALSO

L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader>, L<DBIx::Class::Relationship|DBIx::Class::Relationship>, L<DBIx::Class|DBIx::Class>.

=head1 AUTHOR

Aleksey Dvoriannikov E<lt>lewa::cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Aleksey Dvoriannikov

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. See either the GNU General Public License or the Artistic License for more details.

=cut
