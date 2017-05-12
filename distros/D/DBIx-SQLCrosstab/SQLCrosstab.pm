package DBIx::SQLCrosstab;
use strict;
use warnings;
use DBI;
use Data::Dumper;
use Tree::DAG_Node;

our $VERSION = '1.17';
# 07-Jan-2004

require 5.006;

require Exporter;
our @ISA= qw(Exporter);
our @EXPORT=qw();
our @EXPORT_OK=qw();

our $errstr = "";
my $_RaiseError = 0;
my $_PrintError = 0;

my %_xkeywords = (
   dbh                => 1,
   rows               => 1,
   cols               => 1,
   op                 => 1,
   op_col             => 0, # DEPRECATED - KEPT for backward compatibility
   from               => 1,

   add_op             => 0, # DEPRECATED - KEPT for backward compatibility
   records            => 0,
   col_names          => 0,

   where              => 0,
   having             => 0,
   title              => 0,
   remove_if_null     => 0,
   remove_if_zero     => 0,
   row_total          => 0,
   row_sub_total      => 0,
   col_total          => 0,
   col_sub_total      => 0,
   col_exclude        => 0,

   complete_html_page => 0,
   only_html_header   => 0,

   add_colors         => 0,
   text_color         => 0,
   number_color       => 0,
   header_color       => 0,
   footer_color       => 0,
   table_border       => 0,
   table_cellspacing  => 0,
   table_cellpadding  => 0,
   commify            => 0,
   title_in_header    => 0,

   add_real_names     => 0,
   use_real_names     => 0,
   RaiseError         => 0,
   PrintError         => 0,
);

my %_rowkeywords = (
    col         => 1,
    alias       => 0
);

my %_colkeywords = (
    id             => 1,
    from           => 1,
    value          => 0,
    group          => 0,
    exclude_value  => 0,
    where          => 0,
    orderby        => 0,
    col_list       => 0,
);

my $_stub = {
    dbh    => {dsn=>"dbi:ExampleP:test"},
    op     => [ [ 'COUNT' =>  'dummy' ] ], 
    from   => 'dummy',
    cols => [ {id  => 'dummy', from => 'dummy'}],
    rows => [ {col => 'dummy'}],
};

my  @_operations = map {qr/^\s*$_\s*$/i} 
    (qw(count sum avg std var max min));

sub new {
    my $class = shift;
    my $opt = shift;
    my $self = bless {
        }, $class;
    return seterr("Parameters required in $class constructor")
        unless $opt;
    if (ref $opt eq 'HASH') {
        for (keys %$opt) {
            $self->{ $_} = $opt->{$_};
        }
    }
    elsif ($opt =~/^stub$/i) {
        for (keys %$_stub) {
            $self->{$_} = $_stub->{$_}
        }             
    }
    if ($self->_check_allowed) {
        if ($self->{RaiseError}) {
            $_RaiseError = 1;
        }
        return $self->_check_required
    }
    return undef;
}

#
# set_param( cols => [{id => 'mycol', from => 'mytable'}] )
#

sub set_param {
    my $self = shift;
    while (@_) {
        return seterr("odd number of parameters in set_param")
            unless 2 <= scalar(@_) ;
        my $param = shift;
        my $value = shift;
        if (exists $_xkeywords{$param}) {
            $self->{$param} = $value;
        }
        else {
            return seterr("unrecognized parameter $param ");
        }
    }
    return $self->_check_required;
}

sub op_list{
    my $self = shift;
    return join ",", map { uc( $_->[0]) ."($_->[1])" } @{$self->{op}};
}

sub op {
    my $self = shift;
    return join ",", map { uc $_->[0] } @{$self->{op}};
}

sub op_col {
    my $self = shift;
    return join ",", map { $_->[1] } @{$self->{op}};
}

sub get_params {
    my $self = shift;
    my $params_name = "params";
    my %params =();
    for (keys %_xkeywords) {
        next if /^dbh$/;
        if (exists $self->{$_} and defined($self->{$_})) {
            $params{$_} = $self->{$_};
        }
    }
    local $Data::Dumper::Indent = 1;
    return Data::Dumper->Dump([\%params],[$params_name]);
}

sub save_params {
    my $self = shift;
    my $param_file_name = shift || "xtab_params.pl";
    open PARAMS, "> $param_file_name"
        or return seterr("can't open $param_file_name");
    print PARAMS $self->get_params();
    close(PARAMS) or return seterr("can't close $param_file_name");
    return 1;
}

sub load_params {
    my $self = shift;
    my $params_file_name = shift;
    my $params = undef;
    return seterr("filename required to load_params()")
        unless $params_file_name;
    open PARAMS, "< $params_file_name"
        or return seterr("can't open $params_file_name");
    $errstr = undef;
    {
        local $/;
        my $value = <PARAMS>;
        if ($value) {
            eval $value;
            if ($@) {
                seterr("error retrieving parameters from $params_file_name");
            }
            seterr("no params found in $params_file_name") 
                unless $params;
        }
        else {
            seterr("no params found in $params_file_name") 
        }
    }
    close(PARAMS) or return seterr("can't close $params_file_name");
    return undef if $errstr;
    return seterr("invalid parameters in $params_file_name")
        unless ref($params) eq 'HASH';
    for (keys %$params) {
        return seterr("unrecognized option ($_) in file $params_file_name")
            unless exists $_xkeywords{$_};
        $self->{$_} = $params->{$_};
    }
    return $self->_check_required;
}

sub seterr {
    my $msg = shift || "-- no msg --";
    $errstr = $msg ;
    if ($_RaiseError) {
        die "$msg\n ";
    }
    elsif ($_PrintError) {
        warn "$msg\n";
    }
    return undef;
}

sub _check_allowed{
    my $self = shift;
    $_RaiseError = (exists($self->{RaiseError}) && $self->{RaiseError} )  ;
    $_PrintError = (exists($self->{PrintError}) && $self->{PrintError});
    for (keys %$self) {
        return seterr("unrecognized option '$_'")
            unless defined $_xkeywords{$_} ;
    }
    if ($self->{col_exclude}) {
        return seterr ("list required with parameter 'col_exclude'")
            unless ref $self->{col_exclude} eq 'ARRAY';
    }
    return $self;
}

sub _check_required_kw {
    my ($set, $kw, $opt) = @_;
    for (grep {$kw->{$_}} keys %$kw)
    {
        return seterr("required $opt '$_' not defined")
            unless defined $set->{$_}
    }
    return $set;
}

sub _check_required {
    my $self = shift;
    for (grep {$_xkeywords{$_}} keys %_xkeywords) {
        return seterr("required option '$_' not defined")
            unless defined $self->{$_};
    }
    if (defined $self->{dbh}) {
        if ( ref($self->{dbh}) 
            && ( (ref $self->{dbh}) =~ 'DBI::db' )) 
        {
            # OK
        }
        elsif (ref($self->{dbh}) 
              && ( ref( $self->{dbh}) eq "HASH")) 
        {
            my $par = $self->{dbh};
            my $dbh;
            eval {$dbh = DBI->connect($par->{dsn}, 
                    $par->{user}, $par->{password},
                    $par->{params}) or die "$DBI::errstr"
                };
            if ($@) {
                return seterr("error in connection $@")
            }
            else {
                $self->{dbh} = $dbh;
            }
        }
        else 
        {
            return seterr("invalid \$dbh parameter")
        }
    }
    else {
        return seterr("\$dbh parameter required")
    }
    for my $row (@{$self->{rows}}) {
        for (grep {$_rowkeywords{$_}} keys %_rowkeywords) {
            return seterr(
                    "missing required parameter ($_) in row definition")
                unless exists $row->{$_}
                && defined $row->{$_}
        }
        for (keys %$row) {
            return seterr("unrecognized row parameter ($_)")
                unless exists $_rowkeywords{$_};
        }
    }
    for my $col (@{$self->{cols}}) {
        for (grep {$_colkeywords{$_}} keys %_colkeywords) {
            return seterr(
                    "missing required parameter ($_) in column definition")
                unless exists $col->{$_}
                && defined $col->{$_}
        }
        for (keys %$col) {
            return seterr("unrecognized row parameter ($_)")
                unless exists $_colkeywords{$_};
        }
    }
    my $op_allowed = 0;
   
    unless ( ref($self->{op}) )
    # compatibility code for {op}
    {
        my $tmpop;
        return seterr("Parameter 'op_col' undefined")
            unless defined $self->{op_col};
        push @$tmpop, [ $self->{op}, $self->{op_col}];
        if ($self->{add_op}) {
            return seterr("Parameter 'add_op' must be an array reference")
                unless (ref($self->{add_op}) 
                       && (ref($self->{add_op}) eq 'ARRAY'));
            for my $aop(@{$self->{add_op}}) {
                push @$tmpop, [$aop, $self->{op_col}];
            }
            delete $self->{add_op};
        }
        delete $self->{op_col};
        $self->{op} = $tmpop;    
    }

    return seterr("Parameter 'op' must be an array reference") 
        unless ref($self->{op}) eq 'ARRAY';
    for my $op (@{$self->{op}}) {
        return 
        seterr("All items in parameter {op} must be array references")
            unless (ref($op) && (ref($op) eq 'ARRAY'));
        for my $item (@_operations) {
           return seterr("unrecognized operator $op->[0]")
               unless grep { $op->[0] =~ $_ } @_operations; 
           return seterr("Invalid opertator definition (@{$op})")
               unless @$op eq 2;
        }
        if (scalar @{$self->{op}} > 1) {
            $self->{col_total} = 0;
        }
    }
        
    #for my $op (@_operations) {
    #    if ($self->{op} =~ $op ) {
    #        $op_allowed =1;
    #        last;
    #    }
    #}
    #return seterr("operation not allowed (" . $self->{op} . ")")
    #    unless $op_allowed;
    #if ($self->{add_op}) {
    #    if (ref $self->{add_op} eq 'ARRAY') {
    #        my %seen =();
    #        my @ops = grep {
    #                ($_ ne $self->{op})
    #                and (not $seen{$_}++) } @{$self->{add_op}};
    #        if (@ops) {
    #            $self->{col_total} = 0;
    #            $self->{add_op} = \@ops;
    #        }
    #        else {
    #            $self->{add_op} = undef;
    #        }
    #    }
    #    elsif (lc($self->{add_op}) eq lc($self->{op})) 
    #    {
    #        $self->{add_op} = undef;
    #    }
    #    else {
    #        $self->{col_total} = 0;
    #    }
    #}
    if ($self->{add_real_names} and $self->{use_real_names}) {
        $self->{add_real_names} = 0;
    }
    return $self;
}

# _permute function written by Randal L. Schwartz,
# aka merlyn
# http://www.perlmonks.org/index.pl?node_id=24270
# 
sub _permute { 
   my $last = pop @_;
   unless (@_) {
     return map [$_], @$last;
   }
   return map { my $left = $_; map [@$left, $_], @$last } _permute(@_);
 }

# _permute_group is not permuting anything, actually,
# since the data coming from the distinct query
# is already a permutation. The only task performed here
# is returning the appropriate structure.
sub _permute_group {
    my $array = shift;
    my @permutations;
    for my $row (@$array) {
        push @permutations, [map { {xcol_id => $_, xcol_alias=> $_} } @$row ];
    }
    return \@permutations;
}

# _add_values fills the tree to create
# the appropriate permutations
# 
sub _add_values {
    my ($top, $array, $level) = @_;
    return if $level > $#$array;
    my $values = $array->[$level];
    $top->new_daughter
        ->attributes( {contents => $_} ) for @$values;
    _add_values($_, $array, $level+1) for $top->daughters;
}

# _add_group_values fills the tree without
# permutations, which were already found 
# in the DISTINCT query
# 
sub _add_group_values {
    my ($tr, $array) = @_;
    for my $row (@$array) {
        my $top = $tr;
        for my $col(@$row) {
            my $node = undef;
            if ($top->daughters) {
                ($node) = grep {$_->name eq $col} $top->daughters;
            }
            unless ($node) {
                $node = Tree::DAG_Node->new;
                $node->name($col);
                $node->attributes( {contents => { 
                                        xcol_id => $col, xcol_alias=>$col
                                        }} );
                $top->add_daughter($node)
            }
            $top = $node;
        }
    }
}

#
# _xpermute creates a permutation tree
# 
sub _xpermute {
    my $array = shift;
    my $mode = shift || "normal";
    my $tree = Tree::DAG_Node->new;
    $tree->name('xtab');
    if ($mode eq "normal") {
        _add_values($tree, $array, 0);
    }
    elsif ($mode eq "group") {
        _add_group_values ($tree,$array)
    }
    else {
        return seterr("unrecognized tree-filling mode ($mode)");
    }
    #print map {"$_\n"} @{$tree->draw_ascii_tree}; exit;
    my @permuted;
    $tree->walk_down (
        {
        callbackback => sub {
            my $node = shift;
            return 1 unless $node->ancestors;
            push @permuted,
                [
                    reverse
                    map {$_->attributes->{contents}}
                    grep {$_->address ne '0'}
                    $node, $node->ancestors
                ];
                1;
            }
        }
    );
    $tree->delete_tree;
    return \@permuted;
}

sub from {
    my $self = shift;
    my $val = shift;
    if ($val) {
        $self->{from} = $val;
        $self->rows($self->{rows});
    }
    return $self->{from};
}

sub rows {
    my $self = shift;
    my $val = shift;
    if ($val) {
        $self->{rows} = $val;
        $self->{query} = "";
        $self->{recs} = undef;
        $self->columns($self->{cols});
    }
    return $self->{rows};
}

sub columns {
    my $self = shift;
    my $val = shift;
    if ($val) {
        $self->{cols} = $val;
        $self->{xvalues} = undef;
    }
    return $self->{cols};
}

# _check_query_separator_applicability checks
# if the query separator is present in any of the
# column values, changing the separator if
# necessary
# 
sub _check_query_separator_applicability {
    my $self = shift;
    my $permutations =shift;
    my $separator = shift;
    my %words =();
    for my $row (@{$self->{rows}}) {
        for (qw(id alias value)) {
            if (exists $row->{$_}) {
                $words{$row->{$_}}++;
            }
        }
    }    
    for my $p (@$permutations) {
        $words{$_}++ for @$p;
    }
    if ($separator =~ /[a-z?*+]/i) {
        $separator ='#';
    }
    my @separators = ( '#', '/', '-', '=', ',');
    unless (grep {$_ eq $separator} @separators) {
        unshift @separators, $separator;
    }
    my $ok = 0;
    my $count =0;
    while (! $ok) {
        SEPARATOR:
        for my $sep (@separators) {
            $ok =1;
            for my $k (keys %words) {
                if ($k =~ /\Q$sep\E/) {
                    $ok =0;
                    next SEPARATOR;
                } 
            }
            if ($ok) {
                $separator = $sep;
                last;
            }
        }
        if (! $ok) {
            @separators = map {$_ . substr($_,0,1) } @separators;
            if ($count++ > 3 ) {
                return seterr("unable to find a suitable column separator char");
            }
        }
    } 
    return $separator;
}

#
# gets the values for the column headers
# 
sub _get_xvalues {
    my $self = shift;
    my $dbh = $self->{dbh};

    my @xvalues;
    $self->{xvalues} =  undef;
    #
    # group values required
    # columns are evaluated in a unique query
    # rather than separately
    # 
    if (grep {exists $_->{group}}  @{$self->{cols}})
    {
        my $colquery = qq{SELECT DISTINCT };
        my $fieldlist = "";

        $fieldlist = join ", ", map {
                $_->{id} . (exists $_->{alias}? " AS $_->{alias}" : "") }  
                @{$self->{cols}};
        $colquery .= "$fieldlist\n";
        my ($from) = map {$_->{from}} 
                grep {$_->{from} and  ($_->{from} ne "1") }
                @{$self->{cols}};
        $from =~ s/^\s*from//i;
        $colquery .= qq{ FROM $from\n};
        my ($orderby) = map {$_->{orderby}} 
                grep {$_->{orderby} }
                @{$self->{cols}};
        if ($orderby) {
            $orderby =~ s/^\s*order by//i;
            $colquery .= qq{ ORDER BY $orderby\n}
        }
        my $sth;
        my $colrecs;
        #print $colquery,$/;
        eval {
            $sth = $dbh->prepare($colquery);
            $sth->execute;
        };
        if ($@) {
            return seterr("Error building group column query ($@)");
        }
        eval {
            $colrecs = $sth->fetchall_arrayref;
        };
        if ($@) {
            return seterr("Error retrieving group column records ($@)");
        }
        $self->{colrecs} = $colrecs;
        for my $r (@$colrecs) {
            my $count =0;
            for my $c (@$r) {
                push @{$xvalues[$count++]}, { xcol_id => $_ , xcol_alias => $_};
            }
        }
        $self->{use_group} = 1;
    }
    else 
    # column values
    # are retrieved separately 
    # and stored in a bi-dimensional array
    # 
    {
      for (@{$self->{cols}}) {
        my $xvals;
        my $xcol_alias = exists $_->{alias} ? $_->{alias} : "xcol_alias";
        # 
        # if a list of values is provided
        # then no query is issued, but the values are
        # simply stored in the array
        # 
        if ($_->{col_list}) {
            my $list = $_->{col_list};
            unless (ref $list eq 'ARRAY') {
                return seterr("list of values expected in parameter 'col_list'");
            }
            for my $val (@$list) {
                return seterr("elements in {col_list} must be hash references")
                    unless (ref $val eq 'HASH');
                return seterr("elements in {col_list} must have an {id} key")
                    unless (defined $val->{id} );
                unless (defined $val->{value}) {
                    $val->{value} = $val->{id};
                }
                push @$xvals, {xcol_id=> $val->{id}, $xcol_alias => $val->{value} };
            }
        }
        else
        # normal operation
        # The values are retrieved from the database
        # with a query 
        {
            my $fields = qq[$_->{id} AS xcol_id];
            if (exists $_->{value}) {
                $fields .= qq[, $_->{value} AS $xcol_alias] ;
            }
            my $colquery = qq[SELECT DISTINCT $fields FROM $_->{from}];
            if (exists $_->{where} ) {
                $_->{where} =~ s/^\s*where\b//i;
                $colquery .= " WHERE ". $_->{where} ." ";
            }
            if (exists $_->{orderby} ) {
                $_->{orderby} =~ s/^\s*order\s+by\b//i;
                $colquery .= " ORDER BY ". $_->{orderby} ." ";
            }
            my $sth;
            eval {
                $sth = $dbh->prepare($colquery);
                $sth->execute;
            };
            if ($@) {
                return seterr
                "error while retrieving column values for $_->{id}\n"
                . qq(query: "$colquery"\n)
                . "error: $DBI::errstr\n";
            }
            eval { $xvals = $sth->fetchall_arrayref({}) };
            if ($@) {
                return seterr("Error while fetching column values "
                        ."($DBI::errstr)");
            }
            unless (exists $_->{value}) {
                for my $row (@$xvals) {
                    $row->{$xcol_alias} = $row->{xcol_id};
                }
            }
        }
        # 
        # remove values if required
        # 
        if ($_->{exclude_value}) {
            unless  (ref $_->{exclude_value} eq 'ARRAY') {
                return seterr(
                  "list of value expected in parameter"
                  . " '\$cols->{exclude_value}'");
            }
            my @copy_xvals;
            my %exclude_value = map {$_, 1} @{$_->{exclude_value}};
            @copy_xvals = grep {
                    not (exists ($exclude_value{$_->{xcol_id}}) 
                         or exists ($exclude_value{ $_->{$xcol_alias} }) )  
                    } @$xvals; 
            $xvals = \@copy_xvals;
        }
        push @xvalues, $xvals;
        my $label = exists $_->{value} ? $_->{value} : $_->{id};
        push @{$self->{xvalues}}, { label => $label, value => $xvals};
        }
    }
    return \@xvalues;
}

sub get_query {
    my $self = shift;
    my $separator = shift || '#';
    return undef unless $self->_check_required;
    my $dbh = $self->{dbh};

    my $xvalues = $self->_get_xvalues
        or return undef; # seterr is already called with the real reason

    for my $row ( @{$self->{rows}} ) {
        $row->{alias} = $row->{col} unless $row->{alias}
    }
    my $xrows = join ", ",
        map { "$_->{col} AS $_->{alias}" }
            @{$self->{rows}};

    my $query = qq{SELECT $xrows \n};

    my @xcols;

    my @permutations;
    if ($self->{use_group}) {
        if ( $self->{col_sub_total}) {
            @permutations = @{_xpermute($self->{colrecs}, "group")};
        }
        else {
            @permutations = @{_permute_group( $self->{colrecs} ) };
        }
    }
    elsif ($self->{col_sub_total}) {
        @permutations = @{_xpermute($xvalues)};
    }
    else {
        @permutations = _permute(@$xvalues);
    }
    #for (@permutations) { print "@$_\n"; } exit;
    $self->{query_separator} = 
        $self->_check_query_separator_applicability(\@permutations, $separator)
                or return undef;

    my %realnames =();
    my $col_count ="xfld001";

    for my $op_pair (@{$self->{op}})  
    {
        my ($operator, $opcolumn) = @$op_pair;
        for my $val (@permutations) 
        {
            my @cn = @{$self->{cols}};
            my $condition = join " AND ",
                map {
                    "$cn[$_]->{id} = "
                    . ($dbh->quote($val->[$_]->{xcol_id}))
                    ." "
                    }
                    (0 .. $#$val);
            my $name = join $self->{query_separator},
                map {$val->[$_]->{xcol_alias}}
                    (0..$#$val);
            next if ($self->{col_exclude} and 
                    ( grep {$name eq $_} @{$self->{col_exclude}} ));
            if ($self->{check_group} and $self->{keepcols}) {
                next unless grep { $name =~ /^$_/ } @{$self->{keepcols}};
            }
            #
            # name manipulation
            #
            if (@{$self->{op}} > 1 ) { 
                $name = "x" . lc($operator) 
                    . $self->{query_separator} . $name ;
            }
            if ($self->{use_real_names}) {
                $name = $dbh->quote($name);
            }
            else {
                $realnames{$col_count} = $name;
                $name = $col_count;
                $col_count++;
            }
            #
            #
            #
            my $line =
                qq[,$operator(CASE WHEN $condition THEN ]
                .qq[ $opcolumn ELSE NULL END) AS $name ] ;
            if ($self->{add_real_names} )
            {
                $line .= qq[ -- ($realnames{$name}) \n];
            }
            else {
                $line .= "\n";
            }

            push @xcols, $line;
        }
        if ((@{$self->{op}} > 1) and $self->{col_sub_total})
        {
            my $opname = "x".lc($operator);
            my $line = qq[,$operator($opcolumn) AS $opname\n];
            push @xcols, $line;
        }
    }
    if (@{$self->{op}} > 1) {
        unshift @{$self->{cols}},  { id => 'op', value=>'op',  
            col_list => [map {"x". lc($_->[0])} @{$self->{op}} ] }
    }
    $self->{realnames} = \%realnames;

    $self->{from} =~ s/^\s*from\b//i;
    if ($self->{where}) {
       $self->{where}  =~ s/^\s*where\b//i;
    }
    if ($self->{having}) {
       $self->{having}  =~ s/^\s*having\b//i;
    }

    $query .= $_ for @xcols;
    my $total1 = 'total';
    if ($self->{col_total}) {
        my ($operator, $opcolumn) = @{$self->{op}->[0]};
        $query .= qq[,$operator($opcolumn) AS $total1\n];
    }
    $query .= qq[ FROM $self->{from}\n ];
    if ($self->{where}) {
        $query.= " WHERE ". $self->{where} . " \n";
    }
    $query .= qq[GROUP BY ]
              . join(", ", map {$_->{alias}} @{$self->{rows}})
              . "\n";

    if ($self->{having}) {
        $query.= " HAVING ". $self->{having} . " \n";
    }

    my $numrows = @{$self->{rows}} -1;
    my $nr = $numrows;
    if ($self->{row_sub_total}) {
        for my $row (0..$numrows -1) {
            $xrows = join ", ",
                map {
                    my $val = $self->{rows}->[$_]->{col};
                    $val ="'zzzz'" if $_ >= $nr;
                    "$val AS $self->{rows}->[$_]->{alias}"
                    }
                    (0..$numrows);
            $nr--;
            $query .= qq{UNION\n SELECT $xrows \n};
            $query .= $_ for @xcols;
            if ($self->{col_total} ) {
                my ($operator, $opcolumn) = @{$self->{op}->[0]};
                $query .= qq[,$operator($opcolumn) AS $total1\n];
            }
            $query .= qq[ FROM $self->{from}\n ];
            $xrows = join ", ",
                    map {
                        $self->{rows}->[$_]->{alias}
                        }
                        (0 .. $nr);

            if ($self->{where}) {
                $query.= " WHERE ". $self->{where} . " \n";
            }
            $query .= qq{GROUP BY $xrows\n};
            if ($self->{having}) {
                $query.= " HAVING ". $self->{having} . " \n";
            }
        }
    }

    if ($self->{row_total}) {
        $xrows = join ", ",
                map {"'zzzz' AS $self->{rows}->[$_]->{alias}" }
                    (0..$numrows);
        $query .= qq{UNION\n SELECT $xrows\n};
        $query .= $_ for @xcols;
        if ($self->{col_total}) {
            my ($operator, $opcolumn) = @{$self->{op}->[0]};
            $query .= qq[,$operator($opcolumn) AS $total1\n];
        }
        $query .= qq[ FROM $self->{from}\n ];

        if ($self->{where}) {
            $query.= " WHERE ". $self->{where} . " \n";
        }
    }

    $xrows = join ", ",
         map { $self->{rows}->[$_]->{alias} } (0..$numrows);
    $query .= qq[ORDER BY $xrows\n];
    $query =~ s/ +/ /g;
    $query =~ s/\n\s*\n/\n/sg;
    $query =~ s/^ +//g;
    $self->{query} = $query;
    return $query;
}

sub _max {
    my $max = 0;
    for (@_) {
        $max = $_ if $_ > $max;
    }
    return $max;
}

sub get_recs {
    my $self = shift;
    if ($self->{records} && $self->{col_names}) {
        return seterr("Parameter 'col_names' must be an array reference")
            unless (ref($self->{col_names}) eq 'ARRAY');
        return seterr("Parameter 'records' must be an array reference")
            unless (ref($self->{records}) eq 'ARRAY')
                    and (ref($self->{records}->[0]) eq 'ARRAY');
        $self->{query} = qq{SELECT 'DUMMY'};
        $self->{recs} = $self->{records};
        $self->{NAME} = $self->{col_names};
        $self->{query_separator} = '#';
        return $self->{recs};
    }
    return seterr("call to get_recs() without get_query()")
        unless $self->{query};
    my $sth;
    local $self->{dbh}->{RaiseError} = 1;
    local $self->{dbh}->{PrintError} = 0;
    eval {
        $sth = $self->{dbh}->prepare($self->{query});
    };
    if ($@) {
        return
            seterr "error preparing Crosstab query ($DBI::errstr)\n";
    }
    eval {
        $sth->execute;
    };
    if ($@) {
        return
            seterr "error executing Crosstab query ($DBI::errstr)\n";
    }

    my @fnames = map {exists $self->{realnames}{$_} ?
            $self->{realnames}{$_} : $_ } @{$sth->{NAME}};
    my @lengths =  map {
            my @L =  map {length $_ } split $self->{query_separator}, $_;
            _max( @L)
            } @fnames;

    my $numfields = $sth->{NUM_OF_FIELDS};

    my $recs;
    eval {$recs = $sth->fetchall_arrayref()};
    if ($@) { 
        return seterr ("error fetching records ($DBI::errstr)")
    }
    if($self->{remove_if_zero}) {
        my @zeroes = map {defined $_? 0 : 1 } @{$recs->[0]} ; 
        for my $r (@$recs) {
            my $count =0;
            for my $c (@$r) {
                if (defined( $c) && ($c ne "0")) {
                    $zeroes[$count] = 1;
                }
                $count++;
            }
        }
        my @voids;
        my @filled;
        for (0..$#zeroes){
            if ( $zeroes[$_] ) 
            {
                push @filled, $_
            }
            else {
                push @voids, $_
            }
        }
        if (@voids) {
            @fnames = @fnames[@filled];
            $numfields -= @voids;
            for my $rec (@$recs) {
                $rec = [@$rec[@filled]];
            }
            @lengths = @lengths[@filled];
        }
    }

    if($self->{remove_if_null}) {
        my @nulls = map {0} @{$recs->[0]} ;
        for my $r (@$recs) {
            my $count =0;
            for (@$r) {
                if (defined $_) {
                    $nulls[$count] = 1;
                }
                $count++;
            }
        }
        my @voids;
        my @filled;
        for (0..$#nulls){
            if ( $nulls[$_] ) 
            {
                push @filled, $_
            }
            else {
                push @voids, $_
            }
        }
        if (@voids) {
            @fnames = @fnames[@filled];
            $numfields -= @voids;
            for my $rec (@$recs) {
                $rec = [@$rec[@filled]];
            }
            @lengths = @lengths[@filled];
        }
    }

    for (my $i = 0 ; $i < $numfields; $i++) {
        for (@$recs) {
            my $len = $_->[$i] ? (length($_->[$i])) : 0;
            if (defined($_->[$i]) && $_->[$i] =~ /^\d+\.(\d+)/) 
            {
                if (length($1) > 2) {
                    $len -= (length($1) - 2);
                }
            }
            $lengths[$i] = 0 unless defined $lengths[$i];
            $len = 0 unless defined $len;
            $lengths[$i] = $len
                if $lengths[$i] < $len;
        }
    }
    $self->{recs} = $recs;
    $self->{NAME} = \@fnames;
    $self->{LENGTH} = \@lengths;
    $self->{NUM_OF_FIELDS} = $numfields;
    return $recs;
}
1;

__END__

=head1 NAME

DBIx::SQLCrosstab - creates a server-side cross tabulation from a database

=head1 SYNOPSIS

    use DBIx::SQLCrosstab;
    my $dbh=DBI->connect("dbi:driver:database"
        "user","password", {RaiseError=>1})
            or die "error in connection $DBI::errstr\n";

    my $params = {
        dbh    => $dbh,
        op     => [ ['SUM', 'salary'] ], 
        from   => 'person INNER JOIN departments USING (dept_id)',
        rows   => [
                    { col => 'country'},
                  ],
        cols   => [
                    {
                       id => 'dept',
                       value =>'department',
                       from =>'departments'
                    },
                    {
                        id => 'gender', from => 'person'
                    }
                  ]
    };
    my $xtab = DBIx::SQLCrosstab->new($params)
        or die "error in creation ($DBIx::SQLCrosstab::errstr)\n";

    my $query = $xtab->get_query("#")
        or die "error in query building $DBIx::SQLCrosstab::errstr\n";

    # use the query or let the module do the dirty job for you
    my $recs = $xtab->get_recs
        or die "error in execution $DBIx::SQLCrosstab::errstr\n";

    # do something with records, or use the child class 
    # DBIx::SQLCrosstab::Format to produce well 
    # formatted HTML or XML output
    #

    my $xtab = DBIx::SQLCrosstab::Format->new($params)
        or die "error in creation ($DBIx::SQLCrosstab::errstr)\n";
    if ($xtab->get_query and $xtab->get_recs) { 
        print $xtab->as_html;
        my $xml_data = $xtab->as_xml;
    }

=head1 DESCRIPTION

DBIx::SQLCrosstab produces a SQL query to interrogate a database and generate
a cross-tabulation report. The amount of parameters needed to achieve
the result is kept to a minimum. You need to indicate which columns and
rows to cross and from which table(s) they should be taken.
Acting on your info, DBIx::SQLCrosstab creates an appropriate query to get 
the desired result.
Compared to spreadsheet based cross-tabulations, DBIx::SQLCrosstab has two
distinct advantages, i.e. it keeps the query in the database work space,
fully exploiting the engine capabilities, and does not limit the data extraction
to one table.

See L<http://gmax.oltrelinux.com/cgi-bin/xtab.cgi> for an interactive example.

=head2 Cross tabulation basics

Cross tabulations are statistical reports where the values from one or
more given columns are used as column headers, and GROUP functions are
applied to retrieve totals that apply to such values.

     SELECT
        id, name, gender, dept
     FROM
        person
        INNER JOIN depts ON (depts.dept_id=perspn.dept_id)

     +----+--------+--------+-------+
     | id | name   | gender | dept  |
     +----+--------+--------+-------+
     |  1 | John   | m      | pers  |
     |  2 | Mario  | m      | pers  |
     |  7 | Mary   | f      | pers  |
     |  8 | Bill   | m      | pers  |
     |  3 | Frank  | m      | sales |
     |  5 | Susan  | f      | sales |
     |  6 | Martin | m      | sales |
     |  4 | Otto   | m      | dev   |
     |  9 | June   | f      | dev   |
     +----+--------+--------+-------+

A simple example will clarify the concept. Given the above raw data,
a count of employees by dept and gender would look something like
this:

     +-------+----+----+-------+
     | dept  | m  | f  | total |
     +-------+----+----+-------+
     | dev   |  1 |  1 |     2 |
     | pers  |  3 |  1 |     4 |
     | sales |  2 |  1 |     3 |
     +-------+----+----+-------+

The query to create this result is

    SELECT
        dept,
        COUNT(CASE WHEN gender = 'm' THEN id ELSE NULL END) as m,
        COUNT(CASE WHEN gender = 'f' THEN id ELSE NULL END) as f,
        COUNT(*) as total
    FROM
        person
        INNER JOIN depts ON (person.dept_id = depts.dept_id)
    GROUP BY
        dept

Although this query doesn't look easy, it is actually quite easy to
create and the resulting data is straightforward. Creating the query
requires advance knowledge of the values for the "gender" column, which
can be as easy as m/f or as complex as male/female/unknown/undeclared/
former male/former female/pending (don't blame me. This is a "real" case!).
Give the uncertainity, the method to get the column values id to issue
a preparatory query

    SELECT DISTINCT gender FROM person

Then we can use the resulting values to build the final query

    my $query = "SELECT dept \n";
    $query .=
            ",COUNT(CASE WHEN gender = '$_' THEN id ELSE NULL END) AS $_ \n"
              for   @$columns;
    $query .= ",COUNT(*) as total \n"
              . "FROM person INNER JOIN depts \n"
              . "ON (person.dept_id=depts.dept_id) \n"
              . "GROUP BY dept\n";

If you have to do it once, you can just use the above idiom and you are
done. But if you have several cases, and your cross-tab has more than
one level, then you could put this module to good use.
Notice that, to create this query, you needed also the knowledge of which
column to test (gender) and to which column apply the GROUP function (id)

=head2 Multi-level cross tabulations

If single-level cross tables haven't worried you, multiple level tables 
should give you something to think.
In addition to everything said before, multiple level crosstabs have:

    - query composition complexity. Each column is the combination
      of several conditions, one for each level;
    - column subtotals, to be inserted after the appropriate section;
    - row subtotals, to be inserted after the relevant rows;
    - explosive increase of column number. For a three-level crosstab
      where each level has three values you get 27 columns. If you
      include sub-totals, your number rises to 36. If you have just a few
      levels with five or six values , you may be counting rows by the 
      hundreds;    
    - visualization problems. While the result set from the DBMS
      is a simple matrix, the conceptual table has a visualization tree
      at the top (for columns) and a visualization tree at the left
      side (for rows).

  +----+----+--------------------+--------------------+--+
  | A  | B  |        C1          |       C2           |  |  1
  |    |    +--------------------+--------------------+  |  
  |    |    |   D1   |   D2   |  |   D1   |   D2   |  |  |  2
  |    |    +--------+--------|  +--------+--------+  |  |  
  |    |    |E1 E2 T |E1 E2 T |T |E1 E2 T |E1 E2 T |T |T |  3
  +----+----+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  | A1 | B1 |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  4
  |    |----+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |    | B2 |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  5
  |    |----+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |    |  T |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  6
  +----+----+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  | A2 | B1 |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  7
  |    |----+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |    | B2 |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  8
  |    |----+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |    |  T |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  9
  +----+----+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  | T  | -- |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 10
  +----+----+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   a    b    c  d  e  f  g  h  i  g  k  l  m  n  o  p  q

  Some definitions

  columns headers               : 1-3
  column headers 1st level      : 1
  column headers 2nd level      : 2
  column headers 3rd level      : 3

  row headers                   : a, b
  row header 1st level          : a
  row header 2nd level          : b

  row sub totals                : 6, 9
  row total                     : 10
  column sub totals             : e, h, i, l, o, p
  column total                  : q


=head2 Column headers choice strategies

The easiest way of choosing columns is to tell DBIx::SQLCrosstab to get the 
values from a given column and let it extract them and combine the values
from the various levels to make the appropriate conditions.
Sometimes this is not desirable. For instance, if your column values come from 
the main dataset, the one that will be used for the crosstab, you are querying
the database twice with two possibly expensive queries. Sometimes you can't help
it, but there are a few workarounds.

If uou know the values in advance, you can pass them to the SQLCrosstab object, 
saving one query. This is when the values come from a constraint, for example.
You may have a "grade" column and you know that the values can only be "A" to "F",
or a "game result" column with values "1", "2", "x", "suspended", "camncelled".
Or you can run the full query once, and when you are satisfied that the column 
values are the ones you know they should be, you pass the values for the subsequent
calls.

The list option is also useful when you only want to make a crosstab for a given
set of values, rather than having a mammoth result table with values you don't need.

=head2 Hidden JOINs

The normal case, in a well normalized database, should be to get the column values
from a lookup table. If such table was created dynamically, so that it only contains
values referred from the main table, then there is no problem. If, on the contrary,
the lookup table was pre-loaded with all possible values for a given column, you may 
come out with a huge number of values, of which only a few were used. In this case, 
you need to run the query with a JOIN to the main table, to exclude the unused values.

When yoo use a lookup table, though, you can optimize the main query, by removing a 
JOIN that you have already used in the preparatory query. Let's see an example.

You have the table "person", which includes "dept_id", a foreign key referencing
the table "depts".
If you pass SQLCrosstab a column description including a {value} key, it will get 
from the lookup table both {id} and {value}, so that, instead of creating a 
main query with columns like

   ,COUNT(CASE WHEN dept = 'pers' THEN id ELSE NULL END) AS 'pers' 

It will create this:

   ,COUNT(CASE WHEN dept_id = '1' THEN id ELSE NULL END) AS 'pers'

    or (depending on the parameters you passed) this:

   ,COUNT(CASE WHEN dept_id = '1' THEN id ELSE NULL END) AS fld001 -- pers 

The difference is that in the first case your final query needs a JOIN to depts, while
in the second case it won't need it. Therefore the final query, the expensive one, will be
much faster. The reasoning is, once you went through a lookup table to get the distinct values,
you should not use that table again in the main query.

=head1 Class methods

=over 4

=item new

Create a new DBIx::SQLCrosstab object.

    my $xtab = DBIx::SQLCrosstab->new($params)
        or die "creation error $DBIx::SQLCrosstab::errstr\n"

$params is a hash reference containing at least the following parameters:


    dbh     
            either a valid database handler (DBI::db) or a hash reference
            with the appropriate parameters to create one

            dbh =>  {
                        dsn      => "dbi:driver:database",
                        user     => "username",
                        password => "secretpwd",
                        params   => {RaiseError => 1}
                    }

    op      
            the operation to perform (SUM, COUNT, AVG, MIN, MAX, STD,
            VAR, provided that your DBMS supports them)
            and the column to summarize. It must be an array reference,
            with each item a pair of operation/column.
            E.g.: 
            op => [ [ 'COUNT', 'id'], ['SUM', 'salary'] ],
        
            *** WARNING ***
            Use of this parameter as a scalar is still supported
            but it is DEPRECATED.
    

    op_col  
            The column on which to perform the operation
            *** DEPRECATED ***
            Use {op} as an array reference instead.

    from    
            Where to get the data. It could be as short as
            a table name or as long as a comlex FROM statement
            including INNER and OUTER JOINs. The syntax is not 
            checked. It must be accepted by the DBMS you are 
            using underneath.

    rows    
            a reference to an array of hashes, each
            defining one header for a crosstab row level.
            The only mandatory key is  
                {col}  identifying the column name
            Optionally, you can add an {alias} key, to be used
            with the AS keyword. 

    cols    
            a reference to an array of hashes, each defining
            one header for a cross tab column level.
            Two keys are mandatory
                {id}      the column name
                {from}    where to get it from.
                          If the {group} option is
                          used, the other columns can have
                          a value of "1" instead.

            Optionally, the following keys can be added

                {group}   If this option is set, then all the
                          columns are queried at once, with the
                          {from} statement of the first column
                          definition. 

                {alias}   an alias for the column name. Useful
                          for calculated fields.
                {value}   an additional column, related to {id}
                          whose values you want to use instead of
                          {id} as column headers. See below "The
                          hidden join" for more explanation.
                {col_list}
                         Is a referenece to an array of values
                         that will be used as column headers, instead
                         of querying the database. If you know the
                         values in advance, or if you want to use only
                         a few known ones, then you can specify them
                         in this list. Each element in col_list must be
                         a hash reference with at least an {id} key. A 
                         {value} key is optional.
                {exclude_value}
                         Is a reference to an array of values to exclude
                         from the headers. Unlike the general option
                         "col_exclude", this option will remove all the
                         combinations containing the given values.

                {where}   to limit the column to get
                {orderby} to order the columns in a different
                          way.


    The following parameters are optional.

    where   
            a WHERE clause that will be added to the resulting query
            to limit the amount of data to fetch.

    having  
            Same as WHERE, but applies to the grouped values

    add_op  
            either a scalar or an array reference containing one or
            more functions to be used in addition to the main 'op'.
            For example, if 'op' is 'COUNT', you may set add_op to
            ['SUM', 'AVG'] and the crosstab engine will produce 
            a table having the count, sum and average of the 
            value in 'op_col'.
            *** DEPRECATED *** Use {op} as an array reference instead.

    title   
            A title for the crosstab. Will be used for HTML and XML
            creation

    remove_if_null
    remove_if_zero
            Remove from the record set all the columns where all
            values are respectively NULL or zero. Notice that there 
            is a difference between a column with all zeroes and a 
            column with all NULLs.
            All zeroes with a SUM means that all the values were 0,
            while all NULLs means that no records matching the given 
            criteria were met.
            However, it also depends on the DBMS. According to ANSI
            specifications, SUM/AVG(NULL) should return NULL, while
            COUNT(NULL) should return 0. Rather than assuming
            strict compliance, I leave you the choice.

    col_exclude
            Is a reference to an array of columns to be excluded from
            the query. The values must be complete column names.
            To know the column names, you can use the "add_real_names"
            option and then the get_query method.        

    add_real_names
            Add the real column names as comments to the query text.
            In order to avoid conflicts with the database, the default
            behavior is to create fake column names (fld001, fld002, etc)
            that will  be later replaced. 
            This feature may cause problems with the database engines
            that don't react well to embedded comments.

    use_real_names
            use the real column values as column names. This may be a
            problem if the column value contains characters that are not
            allowed in column names. Even though the names are properly
            quoted, it id not 100% safe.

    row_total
    row_sub_total
            If activated, adds a total row at the end of the result set
            or the total rows at the end of each row level. Your DBMS
            must support the SQL UNION keyword for this option to work.

            ********
            CAVEAT!
            ********

            Be aware that these two options will double the server load
            for each row level beyond 1, plus one additional query for
            the grand total.
            The meaning of this warning is that the query generated
            by DBIx::SQLCrosstab will contain one UNION query with a
            different GROUP BY clause for each row level. The grand
            total is a UNION query without GROUP BY clause. If your
            dataset is several million records large, you may consider
            skipping these options and perform subtotals and grand 
            total in the client.
            For less than one million records, any decent database
            engine should be able to execute the query in an acceptable
            timeframe.

    col_total
    col_sub_total
            If activated, add a total column at the end of the result set
            or the total columns at the end of each column level. 

    RaiseError
            If actviated, makes all errors fatal. Normally, errors are 
            trapped and recorded in $DBIx::SQLCrosstab. RaiseError will 
            raise an exception instead.

    PrintError
            If activated, will issue a warning with the message that 
            caused the exception, but won't die.

    ************************************************
    The following options only apply when creating a 
    DBIx::SQLCrosstab::Format object.
    ************************************************

    commify
            Used for HTML and XML output. If true, will insert commas
            as thousand separators in all recordset numbers.

    complete_html_page
            Returns HTML header and end tags, so that the resulting
            text is a complete HTML page.

    only_html_header
            Returns only the header part of the table, without records.
            Useful to create templates.

    add_colors
            If true, default colors are applied to the resulting
            table.
            text    => "#009900", # green
            number  => "#FF0000", # red
            header  => "#0000FF", # blue
            footer  => "#000099", # darkblue

    text_color
    number_color
    header_color
    footer_color
            Change the default colors to custom ones  

     table_border       
     table_cellspacing 
     table_cellpadding 
            Change the settings for HTML table borders. Defaults are:
            border      => 1
            cellspacing => 0
            cellpadding => 2

=item set_param

Allows to set one or more parameters that you couldn't pass with the constructor.

       $xtab->set_param( cols => [ { id => 'dept', from => 'departments' } ]  )
            or die "error setting parameter: DBIx::SQLCrosstab::errstr\n";

       $xtab->set_param( 
                            remove_if_null => 1,
                            remove_if_zero => 1,
                            title          => 'Some nice number crunching'
                        )
            or die "error setting parameter: DBIx::SQLCrosstab::errstr\n";

You can use this method together with a dummy constructor call:

        my $xtab = DBIx::SQLCrosstab->new ('STUB')
            or die "can't create ($DBIx::SQLCrosstab::errstr)\n";

        $xtab->set_param( 
                          dbh    => $dbh,
                          op     => 'SUM',
                          op_col => 'amount',
                          cols   => $mycolumns,
                          rows   => $myrows,
                          from   => 'mytable'
                          )
            or die "error setting parameter: DBIx::SQLCrosstab::errstr\n";

=item get_params

Returns a string containing te parameters to replicate the current 
DBIx::SQLCrosstab object. The data is represented as Perl code, and it can
be evaluated as such. The variable's name is 'params'.
It does not include the 'dbh' parameter.

    my $params = $xtab->get_params
        or warn "can't get params ($DBIx::SQLCrosstab::errstr)";

=item save_params

Saves the parameters necessary to rebuild the current object to a given file.
This function stores what is returned by get_params into a text file.
Notice that the 'dbh' option is not saved.

    unless ($xtab->save_params('myparams.pl')
        die "can't save current params ($DBIx::SQLCrosstab::errstr)";

=item load_params

Loads previously saved parameters into the current object.
Remember that 'dbh' is not restored, and must be set separately with
set_param().

    my $xtab = DBIx::SQLCrosstab->new('stub')
        or die "$DBIx::SQLCrosstab::errstr";
    $xtab->load_params('myparams.pl')
        or die "$DBIx::SQLCrosstab::errstr";
    $xtab->set_param( dbh => $dbh )
        or die "$DBIx::SQLCrosstab::errstr";

=item get_query

Returns the query to get the final cross-tabulation, or undef
in case of errors. Check $DBIx::SQLCrosstab::errstr for the reason.
You may optionally pass a parameter for the character to be used as 
separator between column names. 
The default is a pound sign ('#'). If the separator character is 
present in any of the column values (i.e. the values from a candidate
column header), the engine will try in sequence '#', '/', '-', '=', 
doubling them if necessary, and eventually giving up only if all these 
characters are present in any column values. If this happens,
then you need to pass an appropriate character, or group of charecters
that you are reasonably sure doesn't recur in column values.

=item get_recs

Executes the query and returns the recordset as an arrayref of
array references, or undef on failure.
After this method is called, several attributes become available:
    - recs           the whole recordset
    - NAME           an arrayref with the list of column names
    - LENGTH         an arrayref with the maximum size of each column
    - NUM_OF_FIELDS  an integer with the number of felds in the result set

=back

=head1 Class attributes

There are attributes that are available for external consumption.
Like the DBI, these attributes become available after a given
event.

=over 4

=item {NAME}

This attribute returns the raw column names for the recordset as
an array reference.
Even if {use_real_names} was not defined, this attribute returns
the real names rather than fld001, fld002, and so on.
It is available after get_recs() was called.

    my $fnames = $xtab->{NAMES};
    print "$_\n" for @{$fnames};

=item {recs}

This attribute contains the raw recordset as returned from the 
database. Available after get_recs().

=item {NUM_OF_FIELDS}

The number of fields in the recordset. 
Available after get_recs().

=item {LENGTH}

Contains an array reference to the maximum lengths of each column.
The length is calculated taking into account the length of the column
name and the length of all values in that column.
Available after get_recs().

=back

=head1 DEPENDENCIES

    DBI
    a DBD driver
    Tree::DAG_Node

=head1 EXPORT

None by default.

=head1 AUTHOR

Giuseppe Maxia (<gmax_at_cpan.org>)

=head1 SEE ALSO

DBI

An article at OnLamp, "Generating Database Server-Side Cross Tabulations" (L<http://www.onlamp.com/pub/a/onlamp/2003/12/04/crosstabs.html>) and one at PerlMonks, "SQL Crosstab, a hell of a DBI idiom" (L<http://www.perlmonks.org/index.pl?node_id=313934>).

=head1 COPYRIGHT

Copyright 2003 by Giuseppe Maxia (<gmax_at_cpan.org>)

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

