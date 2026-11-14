package DBIO::ResultSet;
# ABSTRACT: Lazy query object for fetching and manipulating DBIO rows

use strict;
use warnings;

our $VERSION = '0.900005';

use base qw/DBIO::Base/;
use DBIO::Carp;
use DBIO::ResultSetColumn;
use Scalar::Util qw/blessed weaken reftype/;
use DBIO::Util qw(
  assert_no_list_context fail_on_internal_call UNRESOLVABLE_CONDITION
  assert_no_internal_indirect_calls
  help_url is_literal_value is_plain_value bare_binds assert_column_value
  stresstest_utf8_upgrade_generated_collapser_source
);
use Try::Tiny;

BEGIN {
  # De-duplication in _merge_attr() is disabled, but left in for reference
  # (the merger is used for other things that ought not to be de-duped)
  *__HM_DEDUP = sub () { 0 };
}

# FIXME - get rid of this
use Hash::Merge ();

use namespace::clean;

use overload
        # numification passes (undef, "") - count() must see no arguments
        '0+'     => sub { $_[0]->count },
        'bool'   => "_bool",
        fallback => 1;

sub _bool () { 1 }

__PACKAGE__->mk_group_accessors('simple' => qw/_result_class result_source/);


sub new {
  my $class = shift;

  if (ref $class) {
    assert_no_internal_indirect_calls and fail_on_internal_call;
    return $class->new_result(@_);
  }

  my ($source, $attrs) = @_;

  $attrs = { %{$attrs||{}} };
  delete @{$attrs}{qw(_last_sqlmaker_alias_map _simple_passthrough_construction)};

  if ($attrs->{page}) {
    $attrs->{rows} ||= 10;
  }

  $attrs->{alias} ||= 'me';

  my $self = bless {
    result_source => $source,
    cond => $attrs->{where},
    pager => undef,
    attrs => $attrs,
  }, $class;

  # if there is a dark selector, this means we are already in a
  # chain and the cleanup/sanification was taken care of by
  # _search_rs already
  $self->_normalize_selection($attrs)
    unless $attrs->{_dark_selector};

  $self->result_class(
    $attrs->{result_class} || $source->result_class
  );

  $self;
}


sub search {
  my $self = shift;

  # ADR 0042: DBIO has no wantarray-dependent return types. search() used to
  # return the rows in list context; it now refuses that outright so that a
  # later "fix" cannot turn `my @cds = $rs->search(...)` into a silent
  # one-element list containing the ResultSet.
  assert_no_list_context('->search') if wantarray;

  my $rs = $self->search_rs( @_ );

  if (defined wantarray) {
    return $rs;
  }
  else {
    # we can be called by a relationship helper, which in
    # turn may be called in void context due to some braindead
    # overload or whatever else the user decided to be clever
    # at this particular day. Thus limit the exception to
    # external code calls only
    $self->throw_exception ('->search is *not* a mutator, calling it in void context makes no sense')
      if (caller)[0] !~ /^\QDBIO::/;

    return ();
  }
}


sub search_rs {
  my $self = shift;

  my $rsrc = $self->result_source;
  my ($call_cond, $call_attrs);

  # Special-case handling for (undef, undef) or (undef)
  # Note that (foo => undef) is valid deprecated syntax
  @_ = () if not scalar grep { defined $_ } @_;

  # just a cond
  if (@_ == 1) {
    $call_cond = shift;
  }
  # fish out attrs in the ($condref, $attr) case
  elsif (@_ == 2 and ( ! defined $_[0] or (ref $_[0]) ne '') ) {
    ($call_cond, $call_attrs) = @_;
  }
  elsif (@_ % 2) {
    $self->throw_exception('Odd number of arguments to search')
  }
  # legacy search
  elsif (@_) {
    carp_unique 'search( %condition ) is deprecated, use search( \%condition ) instead';

    for my $i (0 .. $#_) {
      next if $i % 2;
      $self->throw_exception ('All keys in condition key/value pairs must be plain scalars')
        if (! defined $_[$i] or ref $_[$i] ne '');
    }

    $call_cond = { @_ };
  }

  # see if we can keep the cache (no $rs changes)
  my $cache;
  my %safe = (alias => 1, cache => 1);
  if ( ! grep { !$safe{$_} } keys %$call_attrs and (
    ! defined $call_cond
      or
    ref $call_cond eq 'HASH' && ! keys %$call_cond
      or
    ref $call_cond eq 'ARRAY' && ! @$call_cond
  )) {
    $cache = $self->get_cache;
  }

  my $old_attrs = { %{$self->{attrs}} };
  my ($old_having, $old_where) = delete @{$old_attrs}{qw(having where)};

  my $new_attrs = { %$old_attrs };

  # take care of call attrs (only if anything is changing)
  if ($call_attrs and keys %$call_attrs) {

    # copy for _normalize_selection
    $call_attrs = { %$call_attrs };

    my @selector_attrs = qw/select as columns cols +select +as +columns include_columns/;

    # reset the current selector list if new selectors are supplied
    delete @{$old_attrs}{(@selector_attrs, '_dark_selector')}
      if grep { exists $call_attrs->{$_} } qw(columns cols select as);

    # Normalize the new selector list (operates on the passed-in attr structure)
    # Need to do it on every chain instead of only once on _resolved_attrs, in
    # order to allow detection of empty vs partial 'as'
    $call_attrs->{_dark_selector} = $old_attrs->{_dark_selector}
      if $old_attrs->{_dark_selector};
    $self->_normalize_selection ($call_attrs);

    # start with blind overwriting merge, exclude selector attrs
    $new_attrs = { %{$old_attrs}, %{$call_attrs} };
    delete @{$new_attrs}{@selector_attrs};

    for (@selector_attrs) {
      $new_attrs->{$_} = $self->_merge_attr($old_attrs->{$_}, $call_attrs->{$_})
        if ( exists $old_attrs->{$_} or exists $call_attrs->{$_} );
    }

    # older deprecated name, use only if {columns} is not there
    if (my $c = delete $new_attrs->{cols}) {
      carp_unique( "Resultset attribute 'cols' is deprecated, use 'columns' instead" );
      if ($new_attrs->{columns}) {
        carp "Resultset specifies both the 'columns' and the legacy 'cols' attributes - ignoring 'cols'";
      }
      else {
        $new_attrs->{columns} = $c;
      }
    }


    # join/prefetch use their own crazy merging heuristics
    foreach my $key (qw/join prefetch/) {
      $new_attrs->{$key} = $self->_merge_joinpref_attr($old_attrs->{$key}, $call_attrs->{$key})
        if exists $call_attrs->{$key};
    }

    # stack binds together
    $new_attrs->{bind} = [ @{ $old_attrs->{bind} || [] }, @{ $call_attrs->{bind} || [] } ];
  }


  for ($old_where, $call_cond) {
    if (defined $_) {
      $new_attrs->{where} = $self->_stack_cond (
        $_, $new_attrs->{where}
      );
    }
  }

  if (defined $old_having) {
    $new_attrs->{having} = $self->_stack_cond (
      $old_having, $new_attrs->{having}
    )
  }

  my $rs = (ref $self)->new($rsrc, $new_attrs);

  $rs->set_cache($cache) if ($cache);

  # A bound async context propagates across search_rs clones, so
  # $rs->with_context($ctx)->search({...}) keeps routing async ops onto the
  # pinned connection. Kept OUT of {attrs} on purpose -- attrs are copied,
  # merged and serialized, and a live connection pin has no business there.
  $rs->{_async_context} = $self->{_async_context}
    if $self->{_async_context};

  return $rs;
}


my %UNTRUSTED_OPERAND_OPERATORS = (
  ( map { $_ => 'scalar' } ('=', '!=', '<>', '<', '<=', '>', '>=', '-like', '-not_like') ),
  ( map { $_ => 'list' } ('-in', '-not_in') ),
  ( map { $_ => 'pair' } ('-between', '-not_between') ),
  ( map { $_ => 'null' } ('-is', '-is_not') ),
);

sub search_untrusted {
  my $self = shift;

  assert_no_list_context('->search_untrusted') if wantarray;

  $self->throw_exception('->search_untrusted takes exactly one argument, a condition')
    unless @_ == 1;

  my $cond = $_[0];

  my %aliases;
  for my $chunk (@{ $self->_resolved_attrs->{from} || [] }) {
    my $head = ref $chunk eq 'ARRAY' ? $chunk->[0] : $chunk;
    next unless ref $head eq 'HASH' and $head->{-alias} and $head->{-rsrc};
    $aliases{ $head->{-alias} } = $head->{-rsrc};
  }

  $self->_assert_untrusted_node($cond, '', \%aliases, {});

  return $self->search_rs($cond);
}

sub _untrusted_fail {
  my ($self, $path, $what) = @_;
  $self->throw_exception(sprintf '->search_untrusted: %s%s', (length $path ? "$path: " : ''), $what);
}

sub _assert_untrusted_node {
  my ($self, $node, $path, $aliases, $seen) = @_;

  my $type = ref $node;
  $self->_untrusted_fail($path, 'a condition is a hash or array reference, not '
    . (defined $node ? ($type ? DBIO::Util::refdesc($node) : 'a scalar') : 'undef'))
    unless $type eq 'HASH' or $type eq 'ARRAY';

  my $addr = Scalar::Util::refaddr($node);
  $self->_untrusted_fail($path, 'the condition holds a cycle') if $seen->{$addr};
  local $seen->{$addr} = 1;

  if ($type eq 'ARRAY') {
    for my $i (0 .. $#$node) {
      $self->_assert_untrusted_node($node->[$i], "$path\[$i]", $aliases, $seen);
    }
    return;
  }

  for my $key (sort keys %$node) {
    my $kpath = "$path\{$key}";
    my $val = $node->{$key};

    if ($key eq '-and' or $key eq '-or') {
      $self->_untrusted_fail($kpath, "$key takes an array or hash reference of conditions")
        unless ref $val eq 'HASH' or ref $val eq 'ARRAY';
      $self->_assert_untrusted_node($val, $kpath, $aliases, $seen);
      next;
    }

    $self->_untrusted_fail($kpath, "'$key' is not a column")
      if $key =~ /\A-/;

    $self->_assert_untrusted_column($key, $kpath, $aliases);
    $self->_assert_untrusted_operand($val, $kpath);
  }
}

sub _assert_untrusted_column {
  my ($self, $key, $path, $aliases) = @_;

  my ($rsrc, $col) = ($self->result_source, $key);
  if ($key =~ /\A(.+)\.([^.]+)\z/) {
    $rsrc = $aliases->{$1};
    $col = $2;
    $self->_untrusted_fail($path, "'$1' is not an alias of this resultset")
      unless $rsrc;
  }

  $self->_untrusted_fail($path, "'$key' is not a column")
    unless $rsrc->has_column($col);
}

sub _assert_untrusted_operand {
  my ($self, $val, $path) = @_;

  if (! ref $val) {
    return;
  }
  elsif (ref $val eq 'ARRAY') {
    for my $i (0 .. $#$val) {
      $self->_untrusted_fail("$path\[$i]", 'a list of values holds scalars only, not '
        . DBIO::Util::refdesc($val->[$i])) if ref $val->[$i];
    }
    return;
  }
  elsif (ref $val eq 'HASH') {
    $self->_untrusted_fail($path, 'an operand holds exactly one operator')
      unless keys %$val == 1;

    my ($op) = keys %$val;
    my $opath = "$path\{$op}";
    my $arg = $val->{$op};

    my $kind = $UNTRUSTED_OPERAND_OPERATORS{$op}
      or $self->_untrusted_fail($opath, "'$op' is not an allowed operator");

    if ($kind eq 'scalar') {
      $self->_untrusted_fail($opath, "'$op' takes a scalar") if ref $arg;
    }
    elsif ($kind eq 'null') {
      $self->_untrusted_fail($opath, "'$op' takes undef") if defined $arg;
    }
    else {
      $self->_untrusted_fail($opath, "'$op' takes an array reference of "
        . ($kind eq 'pair' ? 'two scalars' : 'scalars'))
        unless ref $arg eq 'ARRAY' and ! grep { ref } @$arg
          and ($kind ne 'pair' or @$arg == 2);
    }
    return;
  }

  $self->_untrusted_fail($path, 'a value is a scalar, not ' . DBIO::Util::refdesc($val));
}


sub with_context {
  my ($self, $ctx) = @_;
  $self->throw_exception(
    'with_context requires an async context object (the one passed to a '
  . 'txn_do_async / pipeline coderef)'
  ) unless defined $ctx and blessed($ctx) and $ctx->can('select_async');
  my $storage = $self->result_source->storage;
  $storage->_assert_async_context_owner($ctx);
  my $clone = $self->search_rs;
  $clone->{_async_context} = $ctx;

  # A bound clone that already carries a pre-filled row cache (an explicit
  # set_cache, or a prefetch cache copied by search_rs) returns those rows
  # directly from the cache -- so all/all_async off it would hand back
  # context-less rows and a write-back on one would miss the pin. Rebind the
  # cached rows onto the context in a FRESH cache, leaving the unbound source's
  # shared rows untouched (karr k195, ADR 0045).
  if (my $cache = $clone->get_cache) {
    $clone->set_cache([
      map { blessed $_ && $_->can('with_context') ? $_->with_context($ctx) : $_ } @$cache
    ]);
  }

  return $clone;
}

# ADR 0045: the pinned async context bound via with_context (undef if unbound).
# Read on every RS async op before the pooled backend; see _rs_run_async.
sub _async_context { $_[0]->{_async_context} }

my $dark_sel_dumper;
sub _normalize_selection {
  my ($self, $attrs) = @_;

  # legacy syntax
  if ( exists $attrs->{include_columns} ) {
    carp_unique( "Resultset attribute 'include_columns' is deprecated, use '+columns' instead" );
    $attrs->{'+columns'} = $self->_merge_attr(
      $attrs->{'+columns'}, delete $attrs->{include_columns}
    );
  }

  # columns are always placed first, however

  # Keep the X vs +X separation until _resolved_attrs time - this allows to
  # delay the decision on whether to use a default select list ($rsrc->columns)
  # allowing stuff like the remove_columns helper to work
  #
  # select/as +select/+as pairs need special handling - the amount of select/as
  # elements in each pair does *not* have to be equal (think multicolumn
  # selectors like distinct(foo, bar) ). If the selector is bare (no 'as'
  # supplied at all) - try to infer the alias, either from the -as parameter
  # of the selector spec, or use the parameter whole if it looks like a column
  # name (ugly legacy heuristic). If all fails - leave the selector bare (which
  # is ok as well), but make sure no more additions to the 'as' chain take place
  for my $pref ('', '+') {

    my ($sel, $as) = map {
      my $key = "${pref}${_}";

      my $val = [ ref $attrs->{$key} eq 'ARRAY'
        ? @{$attrs->{$key}}
        : $attrs->{$key} || ()
      ];
      delete $attrs->{$key};
      $val;
    } qw/select as/;

    if (! @$as and ! @$sel ) {
      next;
    }
    elsif (@$as and ! @$sel) {
      $self->throw_exception(
        "Unable to handle ${pref}as specification (@$as) without a corresponding ${pref}select"
      );
    }
    elsif( ! @$as ) {
      # no as part supplied at all - try to deduce (unless explicit end of named selection is declared)
      # if any @$as has been supplied we assume the user knows what (s)he is doing
      # and blindly keep stacking up pieces
      unless ($attrs->{_dark_selector}) {
        SELECTOR:
        for (@$sel) {
          if ( ref $_ eq 'HASH' and exists $_->{-as} ) {
            push @$as, $_->{-as};
          }
          # assume any plain no-space, no-parenthesis string to be a column spec
          # FIXME - this is retarded but is necessary to support shit like 'count(foo)'
          elsif ( ! ref $_ and $_ =~ /^ [^\s\(\)]+ $/x) {
            push @$as, $_;
          }
          # if all else fails - raise a flag that no more aliasing will be allowed
          else {
            $attrs->{_dark_selector} = {
              plus_stage => $pref,
              string => ($dark_sel_dumper ||= do {
                  require Data::Dumper;
                  Data::Dumper->new([])->Indent(0)->Terse(1)->Sortkeys(1);
                })->Values([$_])->Dump
              ,
            };
            last SELECTOR;
          }
        }
      }
    }
    elsif (@$as < @$sel) {
      $self->throw_exception(
        "Unable to handle an ${pref}as specification (@$as) with less elements than the corresponding ${pref}select"
      );
    }
    elsif ($pref and $attrs->{_dark_selector}) {
      $self->throw_exception(
        "Unable to process named '+select', resultset contains an unnamed selector $attrs->{_dark_selector}{string}"
      );
    }


    # merge result
    $attrs->{"${pref}select"} = $self->_merge_attr($attrs->{"${pref}select"}, $sel);
    $attrs->{"${pref}as"} = $self->_merge_attr($attrs->{"${pref}as"}, $as);
  }
}

sub _stack_cond {
  my ($self, $left, $right) = @_;

  (
    (ref $_ eq 'ARRAY' and !@$_)
      or
    (ref $_ eq 'HASH' and ! keys %$_)
  ) and $_ = undef for ($left, $right);

  # either one of the two undef
  if ( (defined $left) xor (defined $right) ) {
    return defined $left ? $left : $right;
  }
  # both undef
  elsif ( ! defined $left ) {
    return undef
  }
  else {
    return $self->result_source->schema->storage->_collapse_cond({ -and => [$left, $right] });
  }
}


sub search_literal {
  my ($self, $sql, @bind) = @_;

  assert_no_list_context('->search_literal') if wantarray;

  my $attr;
  if ( @bind && ref($bind[-1]) eq 'HASH' ) {
    $attr = pop @bind;
  }
  return $self->search_rs(\[ $sql, map [ {} => $_ ], @bind ], ($attr || () ));
}


sub find {
  my $self = shift;
  my ($final_cond, $attrs, $is_miss) = $self->_resolve_find_query(@_);
  return undef if $is_miss;

  # Run the query, passing the result_class since it should propagate for find
  my $rs = $self->search ($final_cond, {result_class => $self->result_class, %$attrs});
  if ($rs->_resolved_attrs->{collapse}) {
    my $row = $rs->next;
    carp "Query returned more than one row" if $rs->next;
    return $row;
  }
  else {
    return $rs->single;
  }
}

# Resolve find()'s arguments down to a (condition, attrs) pair ready to hand to
# ->search, shared verbatim by find() and find_async() so the two can never
# drift: same constraint check (key => ... or any covered constraint), same
# relationship-valued-key resolution (ADR 0034). $is_miss is true only for the
# non-concrete-relation-condition guard, in which case $final_cond is
# meaningless and no query should be run at all.
#
# Every key of the passed condition goes into the query (ADR 0070); the
# constraint check decides whether the condition is allowed to run, it never
# narrows it.
sub _resolve_find_query {
  my $self = shift;
  my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});

  my $rsrc = $self->result_source;

  my $constraint_name;
  if (exists $attrs->{key}) {
    $constraint_name = defined $attrs->{key}
      ? $attrs->{key}
      : $self->throw_exception("An undefined 'key' resultset attribute makes no sense")
    ;
  }

  # Parse out the condition from input
  my $call_cond;

  if (ref $_[0] eq 'HASH') {
    $call_cond = { %{$_[0]} };
  }
  else {
    # if only values are supplied we need to default to 'primary'
    $constraint_name = 'primary' unless defined $constraint_name;

    my @c_cols = $rsrc->unique_constraint_columns($constraint_name);

    $self->throw_exception(
      "No constraint columns, maybe a malformed '$constraint_name' constraint?"
    ) unless @c_cols;

    $self->throw_exception (
      'find() expects either a column/value hashref, or a list of values '
    . "corresponding to the columns of the specified unique constraint '$constraint_name'"
    ) unless @c_cols == @_;

    @{$call_cond}{@c_cols} = @_;
  }

  return (undef, $attrs, 1) if $self->_fold_relation_conditions($call_cond);

  my $alias = exists $attrs->{alias} ? $attrs->{alias} : $self->{attrs}{alias};
  my $merged_values = ($self->_merge_with_rscond($call_cond))[0];

  if (defined $constraint_name) {
    # the named constraint must be covered by the condition: a column that is
    # missing or undef throws (undef is no concrete value, ADR 0070)
    my $fixed = $rsrc->storage->_extract_fixed_condition_columns($merged_values, 'consider_nulls');
    my @undef = grep {
      exists $fixed->{$_} and ! defined $fixed->{$_}
    } $rsrc->unique_constraint_columns($constraint_name);

    $self->throw_exception(sprintf(
      "find() with key '%s': column(s) %s %s undef; a unique constraint is covered by defined values, "
    . "to look rows up by any other condition use search(...)->single",
      $constraint_name,
      join(', ', map { "'$_'" } sort @undef),
      @undef > 1 ? 'are' : 'is',
    )) if @undef;

    $rsrc->_minimal_valueset_satisfying_constraint(
      constraint_name => $constraint_name,
      values => $merged_values,
    );
  }
  else {
    $self->_assert_covered_constraint($call_cond, $merged_values, 'find');
  }

  return ($self->_qualify_cond_columns($call_cond, $alias), $attrs, 0);
}

# Fold the relationship-valued keys of a find() condition into columns of this
# source, in place (belongs_to given a related row or a condition hashref
# resolves to its foreign-key columns). An explicitly passed column keeps its
# value: a relationship resolving to a different value for it is a
# contradiction and throws. Returns true when a relationship does not reduce to
# a concrete condition (the find is a miss, ADR 0034).
sub _fold_relation_conditions {
  my ($self, $call_cond) = @_;

  my $rsrc = $self->result_source;
  my %explicit = %$call_cond;

  for my $key (sort keys %explicit) {
    next unless length ref $explicit{$key} and $rsrc->relationship_info($key);

    $self->throw_exception(
      "A list value for relationship '$key' is unsupported in find()"
    ) if ref $explicit{$key} eq 'ARRAY';

    my $val = delete $call_cond->{$key};
    my ($rel_cond, $crosstable) = $self->_resolve_related_cond($rsrc, $key, $val);

    $self->throw_exception("Complex condition via relationship '$key' is unsupported in find()")
       if $crosstable or ref($rel_cond) ne 'HASH';

    # A relation that reduces to a join-free but NON-concrete condition (e.g. a
    # might_have searched by a non-key column resolves to { self_pk => undef })
    # is not crosstable and IS a hashref, so it slips past the guard above --
    # merging it would clobber a real key column with an undef foreign key.
    # No row can match a condition that does not resolve to concrete columns,
    # so this find() is a MISS (ADR 0034).
    return 1 unless $self->_related_cond_is_concrete($rel_cond, $crosstable);

    for my $col (sort keys %$rel_cond) {
      next if $col eq $key or ! exists $explicit{$col};

      my $given = ref $explicit{$col} eq 'HASH'
        && keys %{$explicit{$col}} == 1
        && exists $explicit{$col}{'='}
          ? $explicit{$col}{'='}
          : $explicit{$col};

      my $resolved = $rel_cond->{$col};

      my $same
        = ( ! defined $given or ! defined $resolved ) ? ( ! defined $given and ! defined $resolved )
        : ( ref $given or ref $resolved )             ? ( ref $given and ref $resolved and $given == $resolved )
        :                                               $given eq $resolved;

      $self->throw_exception(
        "The condition passes '$col' explicitly and relationship '$key' resolves it to a different value"
      ) unless $same;
    }

    @{$call_cond}{keys %$rel_cond} = values %$rel_cond;
  }

  return 0;
}

# The unique constraints a condition covers: every column of the constraint is
# a concrete equality -- a defined scalar, or { '=' => $scalar } -- on the top
# AND level, after the resultset's own condition and the relationship values
# are merged in. Operators, value lists, undef and a column that only appears
# inside an OR branch do not count. Takes the merged values, returns constraint
# names, 'primary' first, constraints sharing a column set once.
sub _covered_constraints {
  my ($self, $merged_values) = @_;

  my $rsrc  = $self->result_source;
  my $fixed = $rsrc->storage->_extract_fixed_condition_columns($merged_values);

  my (@covered, %seen, @fc_exceptions, $ci);

  for my $c_name ( sort {
      $a eq 'primary' ? -1
    : $b eq 'primary' ? 1
    : $a cmp $b
  } $rsrc->unique_constraint_names) {

    my @c_cols = $rsrc->unique_constraint_columns($c_name);
    next unless @c_cols;

    next if $seen{ join "\x00", sort @c_cols }++;

    next unless @c_cols == grep {
      exists $fixed->{$_}
        and defined $fixed->{$_}
        and ( ! ref $fixed->{$_} or is_plain_value $fixed->{$_} )
        and $fixed->{$_} ne UNRESOLVABLE_CONDITION
    } @c_cols;

    # FilterColumn values are not usable for a lookup; that throw has to be
    # seen here
    try {
      $rsrc->_minimal_valueset_satisfying_constraint(
        constraint_name => $c_name,
        values => $merged_values,
        columns_info => ($ci ||= $rsrc->columns_info),
      );
      push @covered, $c_name;
    }
    catch {
      push @fc_exceptions, $_ if $_ =~ /\bFilterColumn\b/;
    };
  }

  $self->throw_exception(join "; ", map { $_ =~ /(.*) at .+ line \d+$/s } @fc_exceptions)
    if ! @covered and @fc_exceptions;

  return @covered;
}

# Throws unless the condition covers a unique constraint; returns the covered
# constraint names. $caller names the public method in the message.
sub _assert_covered_constraint {
  my ($self, $call_cond, $merged_values, $caller) = @_;

  my @covered = $self->_covered_constraints($merged_values);
  return @covered if @covered;

  my $rsrc = $self->result_source;
  my %constraints = $rsrc->unique_constraints;

  $self->throw_exception(sprintf(
    "%s() needs a condition that gives every column of one unique constraint "
  . "of source '%s' a concrete value. Columns given: %s. Unique constraints: %s. "
  . "To look rows up by any other condition use search(...)->single",
    $caller,
    $rsrc->source_name,
    ( join(', ', sort map { "'$_'" } keys %$call_cond) || '(none)' ),
    ( join('; ', map { "$_ (" . join(', ', @{$constraints{$_}}) . ')' } sort keys %constraints) || '(none)' ),
  ));
}

# The find() a find_or_* / update_or_* method runs: only the columns of the one
# covered unique constraint (the one named by key => ...) go into the lookup;
# the remaining values are data for create or update. Several covered
# constraints without key throw, none covered throws. Returns
# ($lookup_cond, $lookup_attrs, $is_miss).
sub _lookup_for_write {
  my ($self, $cond, $attrs, $caller) = @_;

  my $call_cond = $self->_lookup_data($cond);
  return (undef, $attrs, 1) if $self->_fold_relation_conditions($call_cond);

  my $c_name;
  if (exists $attrs->{key}) {
    $c_name = defined $attrs->{key}
      ? $attrs->{key}
      : $self->throw_exception("An undefined 'key' resultset attribute makes no sense")
    ;
  }
  else {
    my @covered = $self->_assert_covered_constraint(
      $call_cond, ($self->_merge_with_rscond($call_cond))[0], $caller,
    );

    $self->throw_exception(sprintf(
      "%s() condition covers the unique constraints %s -- pass key => '...' to name the one to look up",
      $caller, join(' and ', map { "'$_'" } @covered),
    )) if @covered > 1;

    $c_name = $covered[0];
  }

  my %lookup = map {
    exists $call_cond->{$_} ? ( $_ => $call_cond->{$_} ) : ()
  } $self->result_source->unique_constraint_columns($c_name);

  return (\%lookup, $self->_read_modify_write_attrs({ %$attrs, key => $c_name }), 0);
}

# The read of a read-then-write call goes where the write goes. The storage
# names the pool through _read_pool_for_read_modify_write (nothing by default,
# 'master' for DBIO::Replicated::Storage); a force_pool the caller gave stays.
sub _read_modify_write_attrs {
  my ($self, $attrs) = @_;

  my $pool = $self->result_source->storage->_read_pool_for_read_modify_write;
  $attrs->{force_pool} = $pool if defined $pool and ! exists $attrs->{force_pool};

  return $attrs;
}

# The part of the data that identifies a row, as a copy: the alias removed from
# the keys (me.title is title), and without the lists under relationship names,
# which are the data of rows created along with this one (multi-create).
sub _lookup_data {
  my ($self, $data) = @_;

  my $rsrc = $self->result_source;
  return $self->_remove_alias(
    { map {
      ( ref $data->{$_} eq 'ARRAY' and $rsrc->relationship_info($_) ) ? () : ( $_ => $data->{$_} )
    } keys %$data },
    $self->{attrs}{alias},
  );
}

# The existing row that nested multi-create data identifies, if any: the data
# is looked up by the columns of the unique constraints it covers (all of them,
# ANDed); data covering none identifies nothing and finds no row, so the caller
# creates it. Used by the row layer, which builds related rows from data it
# does not control.
sub _find_identified {
  my ($self, $data) = @_;

  my $call_cond = $self->_lookup_data($data);

  return undef if $self->_fold_relation_conditions($call_cond);

  my @covered = $self->_covered_constraints(($self->_merge_with_rscond($call_cond))[0])
    or return undef;

  my %lookup = map {
    exists $call_cond->{$_} ? ( $_ => $call_cond->{$_} ) : ()
  } map { $self->result_source->unique_constraint_columns($_) } @covered;

  return $self->find(\%lookup);
}

# find() for the find_or_* / update_or_* family, see _lookup_for_write
sub _find_for_write {
  my ($self, $cond, $attrs, $caller, $lookup_cols) = @_;

  my ($lookup, $lattrs, $is_miss) = $self->_lookup_for_write($cond, $attrs, $caller);
  return undef if $is_miss;

  @$lookup_cols = keys %$lookup if $lookup_cols;

  return $self->find($lookup, $lattrs);
}

# What update_or_create / update_or_new hand to update() for the row they
# found (ADR 0071): the caller's data may not contradict the resultset's
# condition, and the columns of the lookup, which name the row and assign
# nothing, are left out where they are guarded.
sub _update_data_for_found_row {
  my ($self, $cond, $lookup_cols) = @_;

  $self->_merge_with_rscond($cond, 1);

  my $columns = $self->result_source->_columns;
  my %lookup = map { $_ => 1 } @{ $lookup_cols || [] };

  return { map {
    ( $lookup{$_} and $columns->{$_} and $columns->{$_}{is_guarded} )
      ? ()
      : ( $_ => $cond->{$_} )
  } keys %$cond };
}

sub _find_for_write_async {
  my ($self, $cond, $attrs, $caller, $lookup_cols) = @_;

  my ($lookup, $lattrs, $is_miss) = $self->_lookup_for_write($cond, $attrs, $caller);
  @$lookup_cols = keys %$lookup if $lookup_cols and ! $is_miss;

  return $is_miss
    ? $self->_rs_run_async('find', sub { $_[1]->done(undef) }, sub { undef })
    : $self->find_async($lookup, $lattrs);
}

# Resolve a related-object sub-condition down to a condition on THIS source's
# own columns, exactly as find() does when folding a related sub-hash into the
# main search. Returns ($resolved_cond, $crosstable): $crosstable is true when
# the relationship cannot be reduced to a join-free condition on the main table
# at all. Note that even when $crosstable is false the individual values in
# $resolved_cond may be undef/UNRESOLVABLE_CONDITION -- e.g. a has_many searched
# by its own non-key columns resolves join-free to { self_pk => undef }, which
# does NOT pin a concrete foreign key. This is the single resolution seam shared
# by find()'s complex-condition guard and update_or_create()'s _find_lookup_cond
# lookup builder; each caller interprets the result for itself (ADR 0034).
sub _resolve_related_cond {
  my ($self, $rsrc, $rel_name, $val) = @_;

  my $relinfo = $rsrc->relationship_info($rel_name)
    or return (undef, undef);

  return $rsrc->_resolve_condition( $relinfo->{cond}, $val, $rel_name, $rel_name );
}

# Predicate over ( $resolved_cond, $crosstable ) as returned by
# _resolve_related_cond: true only when the relation reduces to a concrete,
# fully-defined condition on THIS source's own columns (a resolvable
# belongs_to). A crosstable relation, a non-hashref resolution, an empty
# condition, or any undef / UNRESOLVABLE_CONDITION value counts as non-concrete
# -- folding such a condition into a lookup would clobber real columns with an
# undef foreign key. Shared by find()'s guard and update_or_create()'s lookup-
# condition builder, so the two agree on what "usable in a lookup" means (ADR
# 0034).
sub _related_cond_is_concrete {
  my ($self, $rel_cond, $crosstable) = @_;

  return
       ! $crosstable
    && ref $rel_cond eq 'HASH'
    && keys %$rel_cond
    && ! grep { ! defined $_ } values %$rel_cond;
}

sub _qualify_cond_columns {
  my ($self, $cond, $alias) = @_;

  my %aliased = %$cond;
  for (keys %aliased) {
    $aliased{"$alias.$_"} = delete $aliased{$_}
      if $_ !~ /\./;
  }

  return \%aliased;
}

sub _build_unique_cond {
  carp_unique sprintf
    '_build_unique_cond is a private method, and moreover is about to go '
  . 'away. Please contact the development team at %s if you believe you '
  . 'have a genuine use for this method, in order to discuss alternatives.',
    help_url,
  ;

  my ($self, $constraint_name, $cond, $croak_on_null) = @_;

  $self->result_source->_minimal_valueset_satisfying_constraint(
    constraint_name => $constraint_name,
    values => $cond,
    carp_on_nulls => !$croak_on_null
  );
}


sub search_related {
  my ($self, $rel, @args) = @_;

  assert_no_list_context('->search_related') if wantarray;

  return $self->related_resultset($rel)->search(@args);
}


sub search_related_rs {
  return shift->related_resultset(shift)->search_rs(@_);
}


sub cursor {
  my $self = shift;

  return $self->{cursor} ||= do {
    my $attrs = $self->_resolved_attrs;
    $self->result_source->storage->select(
      $attrs->{from}, $attrs->{select}, $attrs->{where}, $attrs
    );
  };
}


sub single {
  my ($self, $where) = @_;
  if(@_ > 2) {
      $self->throw_exception('single() only takes search conditions, no attributes. You want ->search( $cond, $attrs )->single()');
  }

  my @select_args = $self->_single_select_args($where);

  my $data = [ $self->result_source->storage->select_single(@select_args) ];

  return undef unless @$data;
  $self->{_stashed_rows} = [ $data ];
  $self->_construct_results->[0];
}

# Build the (from, select, where, attrs) argument list for the single-row
# storage select that backs both single() and single_async(). Factored out so
# the async path issues the identical query (and the same has_many-collapse
# assertion) the synchronous path does.
sub _single_select_args {
  my ($self, $where) = @_;

  my $attrs = { %{$self->_resolved_attrs} };

  $self->throw_exception(
    'single() can not be used on resultsets collapsing a has_many. Use find( \%cond ) or next() instead'
  ) if $attrs->{collapse};

  if ($where) {
    if (defined $attrs->{where}) {
      $attrs->{where} = {
        '-and' =>
            [ map { ref $_ eq 'ARRAY' ? [ -or => $_ ] : $_ }
               $where, delete $attrs->{where} ]
      };
    } else {
      $attrs->{where} = $where;
    }
  }

  return ($attrs->{from}, $attrs->{select}, $attrs->{where}, $attrs);
}


sub get_column {
  my ($self, $column) = @_;
  my $new = DBIO::ResultSetColumn->new($self, $column);
  return $new;
}


sub search_like {
  my $class = shift;
  assert_no_list_context('->search_like') if wantarray;
  carp_unique (
    'search_like() is deprecated.'
   .' Instead use ->search({ x => { -like => "y%" } })'
   .' (note the outer pair of {}s - they are important!)'
  );
  my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
  my $query = ref $_[0] eq 'HASH' ? { %{shift()} }: {@_};
  $query->{$_} = { 'like' => $query->{$_} } for keys %$query;
  return $class->search_rs($query, { %$attrs });
}


sub slice {
  my ($self, $min, $max) = @_;

  assert_no_list_context('->slice') if wantarray;

  my $attrs = {}; # = { %{ $self->{attrs} || {} } };
  $attrs->{offset} = $self->{attrs}{offset} || 0;
  $attrs->{offset} += $min;
  $attrs->{rows} = ($max ? ($max - $min + 1) : 1);
  return $self->search_rs(undef, $attrs);
}


sub next {
  my ($self) = @_;

  if (my $cache = $self->get_cache) {
    $self->{all_cache_position} ||= 0;
    return $cache->[$self->{all_cache_position}++];
  }

  if ($self->{attrs}{cache}) {
    delete $self->{pager};
    $self->{all_cache_position} = 1;
    return ($self->all)[0];
  }

  return shift(@{$self->{_stashed_results}}) if @{ $self->{_stashed_results}||[] };

  $self->{_stashed_results} = $self->_construct_results
    or return undef;

  return shift @{$self->{_stashed_results}};
}

# Constructs as many results as it can in one pass while respecting
# cursor laziness. Several modes of operation:
#
# * Always builds everything present in @{$self->{_stashed_rows}}
# * If called with $fetch_all true - pulls everything off the cursor and
#   builds all result structures (or objects) in one pass
# * If $self->_resolved_attrs->{collapse} is true, checks the order_by
#   and if the resultset is ordered properly by the left side:
#   * Fetches stuff off the cursor until the "master object" changes,
#     and saves the last extra row (if any) in @{$self->{_stashed_rows}}
#   OR
#   * Just fetches, and collapses/constructs everything as if $fetch_all
#     was requested (there is no other way to collapse except for an
#     eager cursor)
# * If no collapse is requested - just get the next row, construct and
#   return
sub _construct_results {
  my ($self, $fetch_all) = @_;

  my $rsrc = $self->result_source;
  my $attrs = $self->_resolved_attrs;

  if (
    ! $fetch_all
      and
    ! $attrs->{order_by}
      and
    $attrs->{collapse}
      and
    my @pcols = $rsrc->primary_columns
  ) {
    # default order for collapsing unless the user asked for something
    $attrs->{order_by} = [ map { join '.', $attrs->{alias}, $_} @pcols ];
    $attrs->{_ordered_for_collapse} = 1;
    $attrs->{_order_is_artificial} = 1;
  }

  # this will be used as both initial raw-row collector AND as a RV of
  # _construct_results. Not regrowing the array twice matters a lot...
  # a surprising amount actually
  my $rows = delete $self->{_stashed_rows};

  my $cursor; # we may not need one at all

  my $did_fetch_all = $fetch_all;

  if ($fetch_all) {
    # FIXME SUBOPTIMAL - we can do better, cursor->next/all (well diff. methods) should return a ref
    $rows = [ ($rows ? @$rows : ()), $self->cursor->all ];
  }
  elsif( $attrs->{collapse} ) {

    # a cursor will need to be closed over in case of collapse
    $cursor = $self->cursor;

    $attrs->{_ordered_for_collapse} = (
      (
        $attrs->{order_by}
          and
        $rsrc->schema
              ->storage
               ->_extract_colinfo_of_stable_main_source_order_by_portion($attrs)
      ) ? 1 : 0
    ) unless defined $attrs->{_ordered_for_collapse};

    if (! $attrs->{_ordered_for_collapse}) {
      $did_fetch_all = 1;

      # instead of looping over ->next, use ->all in stealth mode
      # *without* calling a ->reset afterwards
      if (! $cursor->is_exhausted) {
        $rows = [ ($rows ? @$rows : ()), $cursor->all ];
        $cursor->mark_exhausted;
      }
    }
  }

  if (! $did_fetch_all and ! @{$rows||[]} ) {
    # FIXME SUBOPTIMAL - we can do better, cursor->next/all (well diff. methods) should return a ref
    $cursor ||= $self->cursor;
    if (scalar (my @r = $cursor->next) ) {
      $rows = [ \@r ];
    }
  }

  return undef unless @{$rows||[]};

  # sanity check - people are too clever for their own good
  if ($attrs->{collapse} and my $aliastypes = $attrs->{_last_sqlmaker_alias_map} ) {

    my $multiplied_selectors;
    for my $sel_alias ( grep { $_ ne $attrs->{alias} } keys %{ $aliastypes->{selecting} } ) {
      if (
        $aliastypes->{multiplying}{$sel_alias}
          or
        $aliastypes->{premultiplied}{$sel_alias}
      ) {
        $multiplied_selectors->{$_} = 1 for keys %{$aliastypes->{selecting}{$sel_alias}{-seen_columns}}
      }
    }

    for my $i (0 .. $#{$attrs->{as}} ) {
      my $sel = $attrs->{select}[$i];

      if (ref $sel eq 'SCALAR') {
        $sel = $$sel;
      }
      elsif( ref $sel eq 'REF' and ref $$sel eq 'ARRAY' ) {
        $sel = $$sel->[0];
      }

      $self->throw_exception(
        'Result collapse not possible - selection from a has_many source redirected to the main object'
      ) if ($multiplied_selectors->{$sel} and $attrs->{as}[$i] !~ /\./);
    }
  }

  # hotspot - skip the setter
  my $res_class = $self->_result_class;

  my $inflator_cref = $self->{_result_inflator}{cref} ||= do {
    $res_class->can ('inflate_result')
      or $self->throw_exception("Inflator $res_class does not provide an inflate_result() method");
  };

  my $infmap = $attrs->{as};

  $self->{_result_inflator}{is_core_row} = ( (
    $inflator_cref
      ==
    ( \&DBIO::Row::inflate_result || die "No ::Row::inflate_result() - can't happen" )
  ) ? 1 : 0 ) unless defined $self->{_result_inflator}{is_core_row};

  $self->{_result_inflator}{is_hri} = ( (
    ! $self->{_result_inflator}{is_core_row}
      and
    $inflator_cref == (
      require DBIO::ResultClass::HashRefInflator
        &&
      DBIO::ResultClass::HashRefInflator->can('inflate_result')
    )
  ) ? 1 : 0 ) unless defined $self->{_result_inflator}{is_hri};


  if ($attrs->{_simple_passthrough_construction}) {
    # construct a much simpler array->hash folder for the one-table HRI cases right here
    if ($self->{_result_inflator}{is_hri}) {
      for my $r (@$rows) {
        $r = { map { $infmap->[$_] => $r->[$_] } 0..$#$infmap };
      }
    }
    # FIXME SUBOPTIMAL this is a very very very hot spot
    # while rather optimal we can *still* do much better, by
    # building a smarter Row::inflate_result(), and
    # switch to feeding it data via a much leaner interface
    #
    # crude unscientific benchmarking indicated the shortcut eval is not worth it for
    # this particular resultset size
    elsif ( $self->{_result_inflator}{is_core_row} and @$rows < 60 ) {
      for my $r (@$rows) {
        $r = $inflator_cref->($res_class, $rsrc, { map { $infmap->[$_] => $r->[$_] } (0..$#$infmap) } );
      }
    }
    else {
      eval sprintf (
        ( $self->{_result_inflator}{is_core_row}
          ? '$_ = $inflator_cref->($res_class, $rsrc, { %s }) for @$rows'
          # a custom inflator may be a multiplier/reductor - put it in direct list ctx
          : '@$rows = map { $inflator_cref->($res_class, $rsrc, { %s } ) } @$rows'
        ),
        ( join (', ', map { "\$infmap->[$_] => \$_->[$_]" } 0..$#$infmap ) )
      ) . '; 1' or die;
    }
  }
  else {
    my $parser_type =
        $self->{_result_inflator}{is_hri}       ? 'hri'
      : $self->{_result_inflator}{is_core_row}  ? 'classic_pruning'
      :                                           'classic_nonpruning'
    ;

    # $args and $attrs to _mk_row_parser are separated to delineate what is
    # core collapser stuff and what is dbic $rs specific
    @{$self->{_row_parser}{$parser_type}}{qw(cref nullcheck)} = $rsrc->_mk_row_parser({
      eval => 1,
      inflate_map => $infmap,
      collapse => $attrs->{collapse},
      premultiplied => $attrs->{_main_source_premultiplied},
      hri_style => $self->{_result_inflator}{is_hri},
      prune_null_branches => $self->{_result_inflator}{is_hri} || $self->{_result_inflator}{is_core_row},
    }, $attrs) unless $self->{_row_parser}{$parser_type}{cref};

    # column_info metadata historically hasn't been too reliable.
    # We need to start fixing this somehow (the collapse resolver
    # can't work without it). Add an explicit check for the *main*
    # result, hopefully this will gradually weed out such errors
    #
    # FIXME - this is a temporary kludge that reduces performance
    # It is however necessary for the time being
    my ($unrolled_non_null_cols_to_check, $err);

    if (my $check_non_null_cols = $self->{_row_parser}{$parser_type}{nullcheck} ) {

      $err =
        'Collapse aborted due to invalid ResultSource metadata - the following '
      . 'selections are declared non-nullable but NULLs were retrieved: '
      ;

      my @violating_idx;
      COL: for my $i (@$check_non_null_cols) {
        ! defined $_->[$i] and push @violating_idx, $i and next COL for @$rows;
      }

      $self->throw_exception( $err . join (', ', map { "'$infmap->[$_]'" } @violating_idx ) )
        if @violating_idx;

      $unrolled_non_null_cols_to_check = join (',', @$check_non_null_cols);

      utf8::upgrade($unrolled_non_null_cols_to_check)
        if stresstest_utf8_upgrade_generated_collapser_source;
    }

    my $next_cref =
      ($did_fetch_all or ! $attrs->{collapse})  ? undef
    : defined $unrolled_non_null_cols_to_check  ? eval sprintf <<'EOS', $unrolled_non_null_cols_to_check
sub {
  # FIXME SUBOPTIMAL - we can do better, cursor->next/all (well diff. methods) should return a ref
  my @r = $cursor->next or return;
  if (my @violating_idx = grep { ! defined $r[$_] } (%s) ) {
    $self->throw_exception( $err . CORE::join (', ', map { "'$infmap->[$_]'" } @violating_idx ) )
  }
  \@r
}
EOS
    : sub {
        # FIXME SUBOPTIMAL - we can do better, cursor->next/all (well diff. methods) should return a ref
        my @r = $cursor->next or return;
        \@r
      }
    ;

    $self->{_row_parser}{$parser_type}{cref}->(
      $rows,
      $next_cref ? ( $next_cref, $self->{_stashed_rows} = [] ) : (),
    );

    # simple in-place substitution, does not regrow $rows
    if ($self->{_result_inflator}{is_core_row}) {
      $_ = $inflator_cref->($res_class, $rsrc, @$_) for @$rows
    }
    # Special-case multi-object HRI - there is no $inflator_cref pass at all
    elsif ( ! $self->{_result_inflator}{is_hri} ) {
      # the inflator may be a multiplier/reductor - put it in list ctx
      @$rows = map { $inflator_cref->($res_class, $rsrc, @$_) } @$rows;
    }
  }

  # The @$rows check seems odd at first - why wouldn't we want to warn
  # regardless? The issue is things like find() etc, where the user
  # *knows* only one result will come back. In these cases the ->all
  # is not a pessimization, but rather something we actually want
  carp_unique(
    'Unable to properly collapse has_many results in iterator mode due '
  . 'to order criteria - performed an eager cursor slurp underneath. '
  . 'Consider using ->all() instead'
  ) if ( ! $fetch_all and @$rows > 1 );

  # Rows constructed from a context-bound resultset inherit the pinned
  # async context, so $rs->with_context($ctx)->first_async->then(sub {
  # $_[0]->update_async }) writes back on the same pinned connection instead of
  # the pool. The stamp cascades into eagerly-prefetched children (their related
  # resultsets and cached child rows) so a prefetched child fetched off a bound
  # parent stays pinned too (karr k195). Only Row objects can carry it (HRI
  # hashrefs cannot), and only when a context is actually bound -- otherwise this
  # loop never runs and the sync/pooled path is bit-for-bit unchanged. A result
  # class with its own inflate_result still hands back Row objects, so what it
  # built is asked rather than assumed from the inflator (karr k325).
  if ( my $ctx = $self->{_async_context} ) {
    my $is_core_row = $self->{_result_inflator}{is_core_row};
    for (@$rows) {
      $_->_bind_async_context($ctx)
        if $is_core_row or ( blessed $_ and $_->can('_bind_async_context') );
    }
  }

  return $rows;
}


sub result_class {
  my ($self, $result_class) = @_;
  if ($result_class) {

    # don't fire this for an object
    if (! ref $result_class) {

      # DBIx::Class::Helper::ResultSet::ResultClassDWIM resolved a leading '::'
      # against the ResultClass namespace. DBIO does not adopt that idiom, but
      # the string used to travel straight into ensure_class_loaded and die
      # with "Can't locate /HRI.pm" out of Class::C3::Componentised, which says
      # nothing about DBIO or about what is supported instead.
      $self->throw_exception(
        "result_class '$result_class' uses the '::'-prefixed shorthand of "
      . "DBIx::Class::Helper::ResultSet::ResultClassDWIM, which DBIO does not "
      . "implement -- pass the fully qualified class name instead"
      . ( $result_class eq '::HRI'
            ? " ('DBIO::ResultClass::HashRefInflator', which \$rs->hri sets for you)"
            : ''
        )
      ) if $result_class =~ /^::/;

      $self->ensure_class_loaded($result_class);
    }

    if ($self->get_cache) {
      carp_unique('Changing the result_class of a ResultSet instance with cached results is a noop - the cache contents will not be altered');
    }
    elsif ($self->{cursor} && $self->{cursor}->position) {
      $self->throw_exception('Changing the result_class of a ResultSet instance with an active cursor is not supported');
    }

    $self->_result_class($result_class);

    delete $self->{_result_inflator};
  }
  $self->_result_class;
}


sub count {
  my $self = shift;
  return $self->search_rs(@_)->count if @_;
  return scalar @{ $self->get_cache } if $self->get_cache;

  my $attrs = { %{ $self->_resolved_attrs } };

  # this is a little optimization - it is faster to do the limit
  # adjustments in software, instead of a subquery
  my ($rows, $offset) = delete @{$attrs}{qw/rows offset/};

  my $crs;
  if ($self->_has_resolved_attr (qw/collapse group_by/)) {
    $crs = $self->_count_subq_rs ($attrs);
  }
  else {
    $crs = $self->_count_rs ($attrs);
  }
  my $count = $crs->next;

  $count -= $offset if $offset;
  $count = $rows if $rows and $rows < $count;
  $count = 0 if ($count < 0);

  return $count;
}


sub count_rs {
  my $self = shift;
  return $self->search(@_)->count_rs if @_;

  # this may look like a lack of abstraction (count() does about the same)
  # but in fact an _rs *must* use a subquery for the limits, as the
  # software based limiting can not be ported if this $rs is to be used
  # in a subquery itself (i.e. ->as_query)
  if ($self->_has_resolved_attr (qw/collapse group_by offset rows/)) {
    return $self->_count_subq_rs($self->{_attrs});
  }
  else {
    return $self->_count_rs($self->{_attrs});
  }
}

#
# returns a ResultSetColumn object tied to the count query
#
sub _count_rs {
  my ($self, $attrs) = @_;

  my $rsrc = $self->result_source;

  my $tmp_attrs = { %$attrs };
  # take off any limits, record_filter is cdbi, and no point of ordering nor locking a count
  delete @{$tmp_attrs}{qw/rows offset order_by record_filter for/};

  # overwrite the selector (supplied by the storage)
  my $count_rs = $rsrc->resultset_class->new($rsrc, {
    %$tmp_attrs,
    select => $rsrc->storage->_count_select ($rsrc, $attrs),
    as => 'count',
  });

  # ADR 0045 / karr k281: the count of a context-bound resultset keeps the pin
  # (get_column passes it on to the ResultSetColumn).
  $count_rs->{_async_context} = $self->{_async_context} if $self->{_async_context};

  return $count_rs->get_column ('count');
}

#
# same as above but uses a subquery
#
sub _count_subq_rs {
  my ($self, $attrs) = @_;

  my $rsrc = $self->result_source;

  my $sub_attrs = { %$attrs };
  # extra selectors do not go in the subquery and there is no point of ordering it, nor locking it
  delete @{$sub_attrs}{qw/collapse columns as select order_by for/};

  # if we multi-prefetch we group_by something unique, as this is what we would
  # get out of the rs via ->next/->all. We *DO WANT* to clobber old group_by regardless
  if ( $attrs->{collapse}  ) {
    $sub_attrs->{group_by} = [ map { "$attrs->{alias}.$_" } @{
      $rsrc->_identifying_column_set || $self->throw_exception(
        'Unable to construct a unique group_by criteria properly collapsing the '
      . 'has_many prefetch before count()'
      );
    } ]
  }

  # Calculate subquery selector
  if (my $g = $sub_attrs->{group_by}) {

    my $sql_maker = $rsrc->storage->sql_maker;

    # necessary as the group_by may refer to aliased functions
    my $sel_index;
    for my $sel (@{$attrs->{select}}) {
      $sel_index->{$sel->{-as}} = $sel
        if (ref $sel eq 'HASH' and $sel->{-as});
    }

    # anything from the original select mentioned on the group-by needs to make it to the inner selector
    # also look for named aggregates referred in the having clause
    # having often contains scalarrefs - thus parse it out entirely
    my @parts = @$g;
    if ($attrs->{having}) {
      local $sql_maker->{having_bind};
      local $sql_maker->{quote_char} = $sql_maker->{quote_char};
      local $sql_maker->{name_sep} = $sql_maker->{name_sep};
      unless (defined $sql_maker->{quote_char} and length $sql_maker->{quote_char}) {
        $sql_maker->{quote_char} = [ "\x00", "\xFF" ];
        # if we don't unset it we screw up retarded but unfortunately working
        # 'MAX(foo.bar)' => { '>', 3 }
        $sql_maker->{name_sep} = '';
      }

      my ($lquote, $rquote, $sep) = map { quotemeta $_ } ($sql_maker->_quote_chars, $sql_maker->name_sep);

      my $having_sql = $sql_maker->_parse_rs_attrs ({ having => $attrs->{having} });
      my %seen_having;

      # search for both a proper quoted qualified string, for a naive unquoted scalarref
      # and if all fails for an utterly naive quoted scalar-with-function
      while ($having_sql =~ /
        $rquote $sep $lquote (.+?) $rquote
          |
        [\s,] \w+ \. (\w+) [\s,]
          |
        [\s,] $lquote (.+?) $rquote [\s,]
      /gx) {
        my $part = $1 || $2 || $3;  # one of them matched if we got here
        unless ($seen_having{$part}++) {
          push @parts, $part;
        }
      }
    }

    for (@parts) {
      my $colpiece = $sel_index->{$_} || $_;

      # unqualify join-based group_by's. Arcane but possible query
      # also horrible horrible hack to alias a column (not a func.)
      if ($colpiece =~ /\./ && $colpiece !~ /^$attrs->{alias}\./) {
        my $as = $colpiece;
        $as =~ s/\./__/;
        $colpiece = \ sprintf ('%s AS %s', map { $sql_maker->_quote ($_) } ($colpiece, $as) );
      }
      push @{$sub_attrs->{select}}, $colpiece;
    }
  }
  else {
    my @pcols = map { "$attrs->{alias}.$_" } ($rsrc->primary_columns);
    $sub_attrs->{select} = @pcols ? \@pcols : [ 1 ];
  }

  my $sub_rs = $rsrc->resultset_class->new ($rsrc, $sub_attrs);

  # ADR 0045 / karr k281: the count of a context-bound resultset keeps the pin
  # (as_subselect_rs, search and get_column below each pass it on).
  $sub_rs->{_async_context} = $self->{_async_context} if $self->{_async_context};

  return $sub_rs
          ->as_subselect_rs
           ->search ({}, { columns => { count => $rsrc->storage->_count_select ($rsrc, $attrs) } })
            ->get_column ('count');
}



sub count_literal { shift->search_literal(@_)->count; }


sub count_literal_async { shift->search_literal(@_)->count_async; }


sub all {
  my $self = shift;
  if(@_) {
    $self->throw_exception("all() doesn't take any arguments, you probably wanted ->search(...)->all()");
  }

  delete @{$self}{qw/_stashed_rows _stashed_results/};

  if (my $c = $self->get_cache) {
    return @$c;
  }

  $self->cursor->reset;

  my $objs = $self->_construct_results('fetch_all') || [];

  $self->set_cache($objs) if $self->{attrs}{cache};

  return @$objs;
}


sub reset {
  my ($self) = @_;

  delete @{$self}{qw/_stashed_rows _stashed_results/};
  $self->{all_cache_position} = 0;
  $self->cursor->reset;
  return $self;
}


sub first {
  return $_[0]->reset->next;
}

# Shared dispatch for the ResultSet/Row *_async methods (ADR 0030/0031).
# Mirrors the storage-level _run_async three-way contract one tier up:
#
#   * a live embedded async backend  -> route the read/write through the
#     storage's *_async op and inflate the raw result in the Future's ->then,
#     so it is genuinely non-blocking on a real backend (real async)
#   * the 'immediate' mode           -> run the ordinary synchronous method and
#     (mode chosen, no backend)          wrap its result in an immediately-
#                                        resolved Future via future_class
#   * a sync instance                -> croak loudly: *_async was called but no
#     (no async mode chosen)             async mode was selected at connect time
#
# $backend_build builds the real-async Future given ($backend, $future_class);
# $sync_run is the synchronous fallback invoked for the immediate mode.
# $validate (optional) checks the arguments of the call; it runs once the
# backend (or bound context) is known and its return list is passed to
# $backend_build after ($backend, $fc). In the immediate mode $sync_run validates.
#
# Runtime failures arrive as a failed Future, misuse as an exception: on the
# pooled path whatever fails while the backend is resolved or the statement is
# built fails the Future (of the storage's future_class) with the message as
# thrown; misuse throws at the call -- a bound context that is expired or
# foreign (ADR 0045), a connection without an async mode, and whatever
# $validate throws (an invalid option, no data, a missing capability).
sub _rs_run_async {
  my ($self, $name, $backend_build, $sync_run, $validate) = @_;

  my $storage = $self->result_source->storage;
  my $fc = $storage->future_class;

  # An explicitly bound pinned context (from txn_do_async / pipeline)
  # takes precedence over the pooled backend, so RS async inside a transaction
  # or pipeline runs on the pinned connection instead of a sibling pool
  # connection outside it. A carried-but-expired context -- either a pipeline
  # context after its synchronous batch coderef returned or a transaction
  # context after its terminal path -- must NOT silently fall back to the pool;
  # it fails loudly (ADR 0045 / dbio-async ADR 0003). No context bound => the
  # historical path below, bit-for-bit.
  if (my $ctx = $self->_async_context) {
    _assert_async_context_active($self, $ctx, $name);
    $storage->_assert_async_context_owner($ctx);
    return $backend_build->($ctx, $fc, $validate ? $validate->() : ());
  }

  # On the pooled path an exception from getting the backend or building the
  # statement (the owner cannot connect for its sql_maker, say) is a runtime
  # failure and arrives as a failed Future, as the message was thrown (k403).
  # Misuse above and below stays an exception at the call.
  my ($backend, $error);
  {
    local $@;
    my $ok = eval { $backend = $storage->_async_storage; 1 };
    $error = $@ unless $ok;
  }
  return $fc->fail($error) if defined $error;

  if ($backend) {
    # What is misuse of the call is checked by $validate, outside the net, and
    # throws at the call; what it returns goes on to $backend_build.
    my @validated = $validate ? $validate->() : ();
    my ($future, $build_error);
    {
      local $@;
      my $ok = eval {
        # A Future derived from the storage's own is reported to the pool (k397).
        $future = $backend->can('_note_pooled_derivation')
          ? $backend->_note_pooled_derivation(sub { $backend_build->($backend, $fc, @validated) })
          : $backend_build->($backend, $fc, @validated);
        1;
      };
      $build_error = $@ unless $ok;
    }
    return $fc->fail($build_error) if defined $build_error;
    return $future;
  }

  $self->throw_exception(
    "not an async connection -- connect with { async => ... } to use ${name}_async"
  ) unless defined $storage->_async_mode;

  my @r = eval { $sync_run->() };
  if (my $error = $@) {
    # Inside an immediate txn_do_async this is a statement of the transaction
    # like any other: its failure fails it, awaited or not (karr k331).
    $storage->_note_immediate_failure($error);
    return $fc->fail($error);
  }
  return $fc->done(@r);
}

# Shared active-context assertion for the RS/Row/RSC async paths. A bound
# pinned context that has been invalidated -- a pipeline context after its batch
# coderef or a transaction context after its terminal path -- must refuse loudly
# rather than route work onto a connection already back in the pool.
sub _assert_async_context_active {
  my ($invocant, $ctx, $name) = @_;
  return if !$ctx->can('_context_active') || $ctx->_context_active;
  $invocant->throw_exception(
    "the async context bound to this result is no longer active; ${name}_async "
  . "cannot be routed onto it. Pipeline contexts stop accepting work when their "
  . "synchronous batch coderef returns; transaction contexts stop on their "
  . "terminal BEGIN / COMMIT / ROLLBACK path. Issue the async work while its "
  . "owning context remains active, not from a resultset held past it."
  );
}

# An operation that cannot be expressed as a single pinned async statement
# (Row multi-create/cascade, upsert cascade/fallback/count) must NOT silently
# run through the synchronous storage while a pinned context is bound -- that
# would execute on a pooled sync connection OUTSIDE the pinned
# transaction/pipeline (consequence 4). Refuse, named. With no context this is
# the historical "punt to sync and resolve immediately" path, unchanged.
#
# In the 'immediate' mode the context is the storage itself (ADR 0055), and
# the fallback would run inside the transaction. The refusal stands there too,
# so that a bound resultset behaves the same in every async mode; only the
# reason given is the one that is true there (karr k282).
sub _async_ctx_or_sync_punt {
  my ($self, $fc, $op, $why, $sync_cref) = @_;
  if (my $ctx = $self->_async_context) {
    $self->throw_exception(
      "${op}_async cannot run on a bound async context: it is not expressible "
    . "as a single pinned statement ($why). In the 'immediate' mode the "
    . "synchronous fallback would run inside the transaction, but a bound "
    . "object refuses it in every async mode alike. Restructure so this runs "
    . "unbound -- in this mode that is still inside the transaction."
    ) if $ctx == $self->result_source->storage;

    my $where = $ctx->can('in_txn') && $ctx->in_txn ? 'transaction' : 'pipeline';
    $self->throw_exception(
      "${op}_async cannot run on a bound async context: it is not expressible "
    . "as a single pinned statement ($why), and the synchronous fallback would "
    . "run outside the pinned $where. Restructure so this runs outside the "
    . "context, or perform the equivalent explicit steps on the context."
    );
  }
  my $r = eval { $sync_cref->() };
  return $@ ? $fc->fail($@) : $fc->done($r);
}

# Inflate raw fetched rows (arrayrefs in $attrs->{select} order, exactly what a
# real cursor's ->all would yield) into result objects with full fetch_all
# collapse/prefetch parity, by feeding them to the very same
# _construct_results('fetch_all') the synchronous ->all path uses. A pre-filled
# cursor stands in for the storage cursor so no synchronous query is issued;
# _construct_results pulls the rows from it via ->all just as it would from a
# real eager cursor, then runs the identical collapser/inflator. Returns the
# arrayref of constructed result objects (possibly empty).
sub _inflate_fetched_rows {
  my ($self, $raw_rows) = @_;

  delete @{$self}{qw/_stashed_rows _stashed_results/};
  local $self->{cursor} = DBIO::ResultSet::_PrefetchedCursor->new($raw_rows);
  return $self->_construct_results('fetch_all') || [];
}


sub all_async {
  my $self = shift;
  if (@_) {
    $self->throw_exception("all_async() doesn't take any arguments, you probably wanted ->search(...)->all_async()");
  }

  return $self->_rs_run_async('all',
    sub {
      my ($backend, $fc) = @_;

      if (my $c = $self->get_cache) {
        return $fc->done(@$c);
      }

      my $attrs = $self->_resolved_attrs;
      return $backend->select_async(
        $attrs->{from}, $attrs->{select}, $attrs->{where}, $attrs,
      )->then(sub {
        my @raw = @_;
        my $objs = $self->_inflate_fetched_rows(\@raw);
        $self->set_cache($objs) if $self->{attrs}{cache};
        # Resolve with the object LIST via an explicit Future, not a bare
        # `return @$objs`. A real Future's ->then invokes a non-Future-returning
        # callback in SCALAR context, so `return @$objs` would collapse to the
        # element count (the DBIO::Future::Immediate shim's ->then uses list
        # context, which hid this until the first live real-async run). Matches
        # the get_cache branch above, which already returns $fc->done(@$c).
        return $fc->done(@$objs);
      });
    },
    sub { $self->all },
  );
}


sub first_async {
  my $self = shift;

  return $self->_rs_run_async('first',
    sub {
      my ($backend, $fc) = @_;

      my $attrs = $self->_resolved_attrs;
      return $backend->select_async(
        $attrs->{from}, $attrs->{select}, $attrs->{where}, $attrs,
      )->then(sub {
        my @raw = @_;
        my $objs = $self->_inflate_fetched_rows(\@raw);
        return $objs->[0];
      });
    },
    sub { $self->first },
  );
}


sub single_async {
  my ($self, @args) = @_;
  if (@args > 1) {
    $self->throw_exception('single() only takes search conditions, no attributes. You want ->search( $cond, $attrs )->single()');
  }

  return $self->_rs_run_async('single',
    sub {
      my ($backend, $fc) = @_;

      my @select_args = $self->_single_select_args($args[0]);
      return $backend->select_single_async(@select_args)->then(sub {
        my ($raw_row) = @_;
        return undef unless defined $raw_row;
        $self->{_stashed_rows} = [ $raw_row ];
        return $self->_construct_results->[0];
      });
    },
    sub { $self->single(@args) },
  );
}


sub find_async {
  my $self = shift;
  my @args = @_;
  my ($final_cond, $attrs, $is_miss) = $self->_resolve_find_query(@args);

  return $self->_rs_run_async('find',
    sub {
      my ($backend, $fc) = @_;
      return $fc->done(undef) if $is_miss;

      my $rs = $self->search($final_cond, {result_class => $self->result_class, %$attrs});

      if ($rs->_resolved_attrs->{collapse}) {
        my $rattrs = $rs->_resolved_attrs;
        return $backend->select_async(
          $rattrs->{from}, $rattrs->{select}, $rattrs->{where}, $rattrs,
        )->then(sub {
          my @raw = @_;
          my $objs = $rs->_inflate_fetched_rows(\@raw);
          carp "Query returned more than one row" if @$objs > 1;
          return $objs->[0];
        });
      }
      else {
        my @select_args = $rs->_single_select_args;
        return $backend->select_single_async(@select_args)->then(sub {
          my ($raw_row) = @_;
          return undef unless defined $raw_row;
          $rs->{_stashed_rows} = [ $raw_row ];
          return $rs->_construct_results->[0];
        });
      }
    },
    sub { $self->find(@args) },
  );
}


sub count_async {
  my $self = shift;
  return $self->search_rs(@_)->count_async if @_;

  return $self->_rs_run_async('count',
    sub {
      my ($backend, $fc) = @_;

      return $fc->done( scalar @{ $self->get_cache } ) if $self->get_cache;

      my $attrs = { %{ $self->_resolved_attrs } };

      # software-side limit adjustment, identical to count()
      my ($rows, $offset) = delete @{$attrs}{qw/rows offset/};

      my $crs = $self->_has_resolved_attr (qw/collapse group_by/)
        ? $self->_count_subq_rs ($attrs)
        : $self->_count_rs ($attrs);

      my $cattrs = $crs->_resultset->_resolved_attrs;

      return $backend->select_single_async(
        $cattrs->{from}, $cattrs->{select}, $cattrs->{where}, $cattrs,
      )->then(sub {
        my ($raw) = @_;
        my $count = (defined $raw && ref $raw eq 'ARRAY') ? ($raw->[0] // 0) : ($raw // 0);

        $count -= $offset if $offset;
        $count = $rows if $rows and $rows < $count;
        $count = 0 if ($count < 0);

        return $count;
      });
    },
    sub { $self->count },
  );
}


sub create_async {
  my ($self, @args) = @_;

  return $self->_rs_run_async('create',
    sub {
      my ($backend, $fc) = @_;
      return $self->new_result($args[0])->insert_async;
    },
    sub { $self->create(@args) },
  );
}

{
  # A stand-in cursor carrying already-fetched raw rows into
  # _construct_results('fetch_all') without issuing any synchronous query. Only
  # ->all (and ->reset/->next for safety) are exercised by the fetch_all path.
  package DBIO::ResultSet::_PrefetchedCursor;

  sub new {
    my ($class, $rows) = @_;
    return bless { rows => $rows || [] }, $class;
  }

  sub all {
    my $self = shift;
    return @{ $self->{rows} };
  }

  sub reset { $_[0]->{rows} = []; return $_[0] }

  sub next { return () }
}

# The release for a statement over an unrestricted resultset (condition true):
# only the call says it, with { all => 1 }. rows/offset restrict.
sub _assert_restricted_or_all {
  my ($self, $op, $options) = @_;

  if (defined $options) {
    $self->throw_exception("$op options must be a hash")
      unless ref $options eq 'HASH';
    my @unknown = grep { $_ ne 'all' } sort keys %$options;
    $self->throw_exception("$op does not know the option(s): " . join(', ', @unknown))
      if @unknown;
    return if $options->{all};
  }

  return if $self->_has_resolved_attr(qw/rows offset/);

  my ($sql) = $self->result_source->storage->sql_maker->_recurse_where($self->{cond});
  return if defined $sql and length $sql;

  $self->throw_exception("$op on an unrestricted resultset: pass { all => 1 }");
}

# _rs_update_delete
#
# Determines whether and what type of subquery is required for the $rs operation.
# If grouping is necessary either supplies its own, or verifies the current one
# After all is done delegates to the proper storage method.

sub _rs_update_delete {
  my ($self, $op, $values) = @_;

  my $rsrc = $self->result_source;
  my $storage = $rsrc->schema->storage;

  my $attrs = { %{$self->_resolved_attrs} };

  my $join_classifications;
  my ($existing_group_by) = delete @{$attrs}{qw(group_by _grouped_by_distinct)};

  # do we need a subquery for any reason?
  my $needs_subq = (
    defined $existing_group_by
      or
    # if {from} is unparseable wrap a subq
    ref($attrs->{from}) ne 'ARRAY'
      or
    # limits call for a subq
    $self->_has_resolved_attr(qw/rows offset/)
  );

  # simplify the joinmap, so we can further decide if a subq is necessary
  if (!$needs_subq and @{$attrs->{from}} > 1) {

    ($attrs->{from}, $join_classifications) =
      $storage->_prune_unused_joins ($attrs);

    # any non-pruneable non-local restricting joins imply subq
    $needs_subq = grep { $_ ne $attrs->{alias} } keys %{ $join_classifications->{restricting} || {} };
  }

  # check if the head is composite (by now all joins are thrown out unless $needs_subq)
  $needs_subq ||= (
    (ref $attrs->{from}[0]) ne 'HASH'
      or
    ref $attrs->{from}[0]{ $attrs->{from}[0]{-alias} }
  );

  my ($cond, $guard);
  # do we need anything like a subquery?
  if (! $needs_subq) {
    # Most databases do not allow aliasing of tables in UPDATE/DELETE. Thus
    # a condition containing 'me' or other table prefixes will not work
    # at all. Tell SQLMaker to dequalify idents via a gross hack.
    $cond = do {
      my $sqla = $rsrc->storage->sql_maker;
      local $sqla->{_dequalify_idents} = 1;
      \[ $sqla->_recurse_where($self->{cond}) ];
    };
  }
  else {
    # we got this far - means it is time to wrap a subquery
    my $idcols = $rsrc->_identifying_column_set || $self->throw_exception(
      sprintf(
        "Unable to perform complex resultset %s() without an identifying set of columns on source '%s'",
        $op,
        $rsrc->source_name,
      )
    );

    # make a new $rs selecting only the PKs (that's all we really need for the subq)
    delete $attrs->{$_} for qw/select as collapse/;
    $attrs->{columns} = [ map { "$attrs->{alias}.$_" } @$idcols ];

    # this will be consumed by the pruner waaaaay down the stack
    $attrs->{_force_prune_multiplying_joins} = 1;

    my $subrs = (ref $self)->new($rsrc, $attrs);

    if (@$idcols == 1) {
      $cond = { $idcols->[0] => { -in => $subrs->as_query } };
    }
    elsif ($storage->_use_multicolumn_in) {
      # no syntax for calling this properly yet
      # !!! EXPERIMENTAL API !!! WILL CHANGE !!!
      $cond = $storage->sql_maker->_where_op_multicolumn_in (
        $idcols, # how do I convey a list of idents...? can binds reside on lhs?
        $subrs->as_query
      ),
    }
    else {
      # if all else fails - get all primary keys and operate over a ORed set
      # wrap in a transaction for consistency
      # this is where the group_by/multiplication starts to matter
      if (
        $existing_group_by
          or
        # we do not need to check pre-multipliers, since if the premulti is there, its
        # parent (who is multi) will be there too
        keys %{ $join_classifications->{multiplying} || {} }
      ) {
        # make sure if there is a supplied group_by it matches the columns compiled above
        # perfectly. Anything else can not be sanely executed on most databases so croak
        # right then and there
        if ($existing_group_by) {
          my @current_group_by = map
            { $_ =~ /\./ ? $_ : "$attrs->{alias}.$_" }
            @$existing_group_by
          ;

          if (
            join ("\x00", sort @current_group_by)
              ne
            join ("\x00", sort @{$attrs->{columns}} )
          ) {
            $self->throw_exception (
              "You have just attempted a $op operation on a resultset which does group_by"
              . ' on columns other than the primary keys, while DBIO internally needs to retrieve'
              . ' the primary keys in a subselect. All sane RDBMS engines do not support this'
              . ' kind of queries. Please retry the operation with a modified group_by or'
              . ' without using one at all.'
            );
          }
        }

        $subrs = $subrs->search({}, { group_by => $attrs->{columns} });
      }

      $guard = $storage->txn_scope_guard;

      for my $row ($subrs->cursor->all) {
        push @$cond, { map
          { $idcols->[$_] => $row->[$_] }
          (0 .. $#$idcols)
        };
      }
    }
  }

  my $res = $cond ? $storage->$op (
    $rsrc,
    $op eq 'update' ? $values : (),
    $cond,
  ) : '0E0';

  $guard->commit if $guard;

  return $res;
}


sub update {
  my ($self, $values, $options) = @_;
  $self->throw_exception('Values for update must be a hash')
    unless ref $values eq 'HASH';
  $self->_assert_restricted_or_all('update', $options);

  # no row is involved: every value goes to the storage as it is
  assert_column_value($_, $values->{$_}) for sort keys %$values;

  return $self->_rs_update_delete ('update', $values);
}


sub update_all {
  my ($self, $values, $options) = @_;
  $self->throw_exception('Values for update_all must be a hash')
    unless ref $values eq 'HASH';
  $self->_assert_restricted_or_all('update_all', $options);

  my $guard = $self->result_source->schema->txn_scope_guard;
  $_->update({%$values}) for $self->all;  # shallow copy - update will mangle it
  $guard->commit;
  return 1;
}


sub delete {
  my ($self, $options) = @_;
  $self->_assert_restricted_or_all('delete', $options);

  return $self->_rs_update_delete ('delete');
}


sub delete_all {
  my ($self, $options) = @_;
  $self->_assert_restricted_or_all('delete_all', $options);

  my $guard = $self->result_source->schema->txn_scope_guard;
  $_->delete for $self->all;
  $guard->commit;
  return 1;
}


sub populate {
  my $self = shift;

  # this is naive and just a quick check
  # the types will need to be checked more thoroughly when the
  # multi-source populate gets added
  my $data = (
    ref $_[0] eq 'ARRAY'
      and
    ( @{$_[0]} or return )
      and
    ( ref $_[0][0] eq 'HASH' or ref $_[0][0] eq 'ARRAY' )
      and
    $_[0]
  ) or $self->throw_exception('Populate expects an arrayref of hashrefs or arrayref of arrayrefs');

  # FIXME - no cref handling
  # At this point assume either hashes or arrays

  if(defined wantarray) {
    my (@results, $guard);

    if (ref $data->[0] eq 'ARRAY') {
      # column names only, nothing to do
      return if @$data == 1;

      $guard = $self->result_source->schema->storage->txn_scope_guard
        if @$data > 2;

      @results = map
        { my $vals = $_; $self->new_result({ map { $data->[0][$_] => $vals->[$_] } 0..$#{$data->[0]} })->insert }
        @{$data}[1 .. $#$data]
      ;
    }
    else {

      $guard = $self->result_source->schema->storage->txn_scope_guard
        if @$data > 1;

      @results = map { $self->new_result($_)->insert } @$data;
    }

    $guard->commit if $guard;
    return wantarray ? @results : \@results;
  }

  # we have to deal with *possibly incomplete* related data
  # this means we have to walk the data structure twice
  # whether we want this or not
  # jnap, I hate you ;)
  my $rsrc = $self->result_source;
  my $rel_info = { map { $_ => $rsrc->relationship_info($_) } $rsrc->relationships };

  my ($colinfo, $colnames, $slices_with_rels);
  my $data_start = 0;

  DATA_SLICE:
  for my $i (0 .. $#$data) {

    my $current_slice_seen_rel_infos;

### Determine/Supplement collists
### BEWARE - This is a hot piece of code, a lot of weird idioms were used
    if( ref $data->[$i] eq 'ARRAY' ) {

      # positional(!) explicit column list
      if ($i == 0) {
        # column names only, nothing to do
        return if @$data == 1;

        $colinfo->{$data->[0][$_]} = { pos => $_, name => $data->[0][$_] } and push @$colnames, $data->[0][$_]
          for 0 .. $#{$data->[0]};

        $data_start = 1;

        next DATA_SLICE;
      }
      else {
        for (values %$colinfo) {
          if ($_->{is_rel} ||= (
            $rel_info->{$_->{name}}
              and
            (
              ref $data->[$i][$_->{pos}] eq 'ARRAY'
                or
              ref $data->[$i][$_->{pos}] eq 'HASH'
                or
              ( defined blessed $data->[$i][$_->{pos}] and $data->[$i][$_->{pos}]->isa('DBIO::Row') )
            )
              and
            1
          )) {

            # moar sanity check... sigh
            for ( ref $data->[$i][$_->{pos}] eq 'ARRAY' ? @{$data->[$i][$_->{pos}]} : $data->[$i][$_->{pos}] ) {
              if ( defined blessed $_ and $_->isa('DBIO::Row' ) ) {
                carp_unique("Fast-path populate() with supplied related objects is not possible - falling back to regular create()");
                return my $throwaway = $self->populate(@_);
              }
            }

            push @$current_slice_seen_rel_infos, $rel_info->{$_->{name}};
          }
        }
      }

     if ($current_slice_seen_rel_infos) {
        push @$slices_with_rels, { map { $colnames->[$_] => $data->[$i][$_] } 0 .. $#$colnames };

        # this is needed further down to decide whether or not to fallback to create()
        $colinfo->{$colnames->[$_]}{seen_null} ||= ! defined $data->[$i][$_]
          for 0 .. $#$colnames;
      }
    }
    elsif( ref $data->[$i] eq 'HASH' ) {

      for ( sort keys %{$data->[$i]} ) {

        $colinfo->{$_} ||= do {

          $self->throw_exception("Column '$_' must be present in supplied explicit column list")
            if $data_start; # it will be 0 on AoH, 1 on AoA

          push @$colnames, $_;

          # RV
          { pos => $#$colnames, name => $_ }
        };

        if ($colinfo->{$_}{is_rel} ||= (
          $rel_info->{$_}
            and
          (
            ref $data->[$i]{$_} eq 'ARRAY'
              or
            ref $data->[$i]{$_} eq 'HASH'
              or
            ( defined blessed $data->[$i]{$_} and $data->[$i]{$_}->isa('DBIO::Row') )
          )
            and
          1
        )) {

          # moar sanity check... sigh
          for ( ref $data->[$i]{$_} eq 'ARRAY' ? @{$data->[$i]{$_}} : $data->[$i]{$_} ) {
            if ( defined blessed $_ and $_->isa('DBIO::Row' ) ) {
              carp_unique("Fast-path populate() with supplied related objects is not possible - falling back to regular create()");
              return my $throwaway = $self->populate(@_);
            }
          }

          push @$current_slice_seen_rel_infos, $rel_info->{$_};
        }
      }

      if ($current_slice_seen_rel_infos) {
        push @$slices_with_rels, $data->[$i];

        # this is needed further down to decide whether or not to fallback to create()
        $colinfo->{$_}{seen_null} ||= ! defined $data->[$i]{$_}
          for keys %{$data->[$i]};
      }
    }
    else {
      $self->throw_exception('Unexpected populate() data structure member type: ' . ref $data->[$i] );
    }

    if ( grep
      { $_->{attrs}{is_depends_on} }
      @{ $current_slice_seen_rel_infos || [] }
    ) {
      carp_unique("Fast-path populate() of belongs_to relationship data is not possible - falling back to regular create()");
      return my $throwaway = $self->populate(@_);
    }
  }

  if( $slices_with_rels ) {

    # need to exclude the rel "columns"
    $colnames = [ grep { ! $colinfo->{$_}{is_rel} } @$colnames ];

    # extra sanity check - ensure the main source is in fact identifiable
    # the localizing of nullability is insane, but oh well... the use-case is legit
    my $ci = $rsrc->columns_info($colnames);

    $ci->{$_} = { %{$ci->{$_}}, is_nullable => 0 }
      for grep { ! $colinfo->{$_}{seen_null} } keys %$ci;

    unless( $rsrc->_identifying_column_set($ci) ) {
      carp_unique("Fast-path populate() of non-uniquely identifiable rows with related data is not possible - falling back to regular create()");
      return my $throwaway = $self->populate(@_);
    }
  }

### what the caller assigns (ADR 0071), checked as new_result checks it: no
### guarded column or relationship, no value against the resultset's condition
  for my $name (sort keys %{ $colinfo || {} }) {
    $colinfo->{$name}{is_rel}
      ? $rsrc->_assert_relationship_not_guarded($name)
      : $rsrc->_assert_columns_not_guarded($name)
    ;
  }

  if ( my %scope = %{ $self->_scope_values } ) {
    for my $name (grep { exists $scope{$_} } @$colnames) {
      my $pos = $colinfo->{$name}{pos};

      $rsrc->_assert_scope_agrees(
        { $name => ref $data->[$_] eq 'ARRAY' ? $data->[$_][$pos] : $data->[$_]{$name} },
        { $name => $scope{$name} },
      ) for $data_start .. $#$data;
    }
  }

### inherit the data locked in the conditions of the resultset
  my ($rs_data) = $self->_merge_with_rscond({});
  delete @{$rs_data}{@$colnames};  # passed-in stuff takes precedence

  # if anything left - decompose rs_data
  my $rs_data_vals;
  if (keys %$rs_data) {
     push @$rs_data_vals, $rs_data->{$_}
      for sort keys %$rs_data;
  }

### start work
  my $guard;
  $guard = $rsrc->schema->storage->txn_scope_guard
    if $slices_with_rels;

### main source data
  # FIXME - need to switch entirely to a coderef-based thing,
  # so that large sets aren't copied several times... I think
  my $bulk_cols = [ @$colnames, sort keys %$rs_data ];
  my $bulk_rows = [ map {
    ref $data->[$_] eq 'ARRAY'
    ? (
        $slices_with_rels ? [ @{$data->[$_]}[0..$#$colnames], @{$rs_data_vals||[]} ]  # the collist changed
      : $rs_data_vals     ? [ @{$data->[$_]}, @$rs_data_vals ]
      :                     $data->[$_]
    )
    : [ @{$data->[$_]}{@$colnames}, @{$rs_data_vals||[]} ]
  } $data_start .. $#$data ];

  # the bulk path goes to the storage as it is: every value is a storage value
  for my $row (@$bulk_rows) {
    assert_column_value($bulk_cols->[$_], $row->[$_]) for 0 .. $#$bulk_cols;
  }

  $rsrc->storage->_insert_bulk($rsrc, $bulk_cols, $bulk_rows);

### do the children relationships
  if ( $slices_with_rels ) {
    my @rels = grep { $colinfo->{$_}{is_rel} } keys %$colinfo
      or die 'wtf... please report a bug with DBIO_TRACE=1 output (stacktrace)';

    for my $sl (@$slices_with_rels) {

      my ($main_proto, $main_proto_rs);
      for my $rel (@rels) {
        next unless defined $sl->{$rel};

        $main_proto ||= {
          %$rs_data,
          (map { $_ => $sl->{$_} } @$colnames),
        };

        unless (defined $colinfo->{$rel}{rs}) {

          $colinfo->{$rel}{rs} = $rsrc->related_source($rel)->resultset;

          $colinfo->{$rel}{fk_map} = { reverse %{ $rsrc->_resolve_relationship_condition(
            rel_name => $rel,
            self_alias => "\xFE", # irrelevant
            foreign_alias => "\xFF", # irrelevant
          )->{identity_map} || {} } };

        }

        $colinfo->{$rel}{rs}->search({ map # only so that we inherit them values properly, no actual search
          {
            $_ => { '=' =>
              ( $main_proto_rs ||= $rsrc->resultset->search($main_proto) )
                ->get_column( $colinfo->{$rel}{fk_map}{$_} )
                 ->as_query
            }
          }
          keys %{$colinfo->{$rel}{fk_map}}
        })->populate( ref $sl->{$rel} eq 'ARRAY' ? $sl->{$rel} : [ $sl->{$rel} ] );

        1;
      }
    }
  }

  $guard->commit if $guard;
}


sub pager {
  my ($self) = @_;

  return $self->{pager} if $self->{pager};

  my $attrs = $self->{attrs};
  if (!defined $attrs->{page}) {
    $self->throw_exception("Can't create pager for non-paged rs, you need to call page(\$num) first");
  }
  elsif ($attrs->{page} <= 0) {
    $self->throw_exception('Invalid page number (page-numbers are 1-based)');
  }
  $attrs->{rows} ||= 10;

  # throw away the paging flags and re-run the count (possibly
  # with a subselect) to get the real total count
  my $count_attrs = { %$attrs };
  delete @{$count_attrs}{qw/rows offset page pager/};

  my $total_rs = (ref $self)->new($self->result_source, $count_attrs);

  # a bound resultset counts through its context (karr k331), as the async
  # recipe in DBIO::ResultSet::Pager does
  $total_rs->{_async_context} = $self->{_async_context} if $self->{_async_context};

  require DBIO::ResultSet::Pager;
  return $self->{pager} = DBIO::ResultSet::Pager->new(
    sub { $total_rs->count },  #lazy-get the total
    $attrs->{rows},
    $self->{attrs}{page},
  );
}


sub page {
  my ($self, $page) = @_;
  my $rs = (ref $self)->new($self->result_source, { %{$self->{attrs}}, page => $page });
  # ADR 0045 / karr k195: a page derived from a context-bound resultset inherits
  # the pin so ->page(N)->all_async stays on the pinned connection.
  $rs->{_async_context} = $self->{_async_context} if $self->{_async_context};
  return $rs;
}


sub new_result {
  my ($self, $values) = @_;

  $self->throw_exception( "new_result takes only one argument - a hashref of values" )
    if @_ > 2;

  $self->throw_exception( "Result object instantiation requires a hashref as argument" )
    unless (ref $values eq 'HASH');

  # ADR 0071: the keys of $values are what the caller assigns (new_related
  # names its own, its values hold the parent's foreign key as well); what the
  # condition holds is inherited
  my ($merged_cond, $cols_from_relations) = $self->_merge_with_rscond($values, 1);
  my $scope_values = $self->_scope_values;

  my $new = $self->result_class->new({
    %$merged_cond,
    ( @$cols_from_relations
      ? (-cols_from_relations => $cols_from_relations)
      : ()
    ),
    -caller_keys => $self->{_caller_keys}
      || [ keys %{ $self->_remove_alias($values, $self->{attrs}{alias}) } ],
    ( %$scope_values
      ? (-scope_values => $scope_values)
      : ()
    ),
    -result_source => $self->result_source, # DO NOT REMOVE THIS, REQUIRED
  });

  if (
    reftype($new) eq 'HASH'
      and
    ! keys %$new
      and
    blessed($new)
  ) {
    carp_unique (sprintf (
      "%s->new returned a blessed empty hashref - a strong indicator something is wrong with its inheritance chain",
      $self->result_class,
    ));
  }

  # A row built from a context-bound resultset (create_async,
  # find_or_new_async, update_or_new_async, ...) inherits the pinned async
  # context so its own insert_async/update_async stays on the pinned connection.
  $new->{_async_context} = $self->{_async_context}
    if $self->{_async_context} and blessed($new);

  $new;
}

# _merge_with_rscond
#
# Takes a simple hash of K/V data and returns its copy merged with the
# condition already present on the resultset. Additionally returns an
# arrayref of value/condition names, which were inferred from related
# objects (this is needed for in-memory related objects)
#
# A true second argument says $data is what the caller assigns to the new row
# (ADR 0071): a plain value that contradicts an equality of the condition
# throws. A relationship value is resolved to columns by the row layer, which
# checks those the same way.
sub _merge_with_rscond {
  my ($self, $data, $assignment) = @_;

  my ($implied_data, @cols_from_relations);

  my $alias = $self->{attrs}{alias};

  if (! defined $self->{cond}) {
    # just massage $data below
  }
  elsif ($self->{cond} eq UNRESOLVABLE_CONDITION) {
    $implied_data = $self->{attrs}{related_objects};  # nothing might have been inserted yet
    @cols_from_relations = keys %{ $implied_data || {} };
  }
  else {
    $implied_data = $self->_scope_values;

    if ($assignment) {
      my $rsrc = $self->result_source;
      my $given = $self->_remove_alias($data, $alias);

      $rsrc->_assert_scope_agrees(
        { map {
          ( ref $given->{$_} and ! is_literal_value($given->{$_}) and $rsrc->relationship_info($_) )
            ? ()
            : ( $_ => $given->{$_} )
        } keys %$given },
        $implied_data,
      );
    }
  }

  return (
    { map
      { %{ $self->_remove_alias($_, $alias) } }
      # precedence must be given to passed values over values inherited from
      # the cond, so the order here is important.
      ( $implied_data||(), $data)
    },
    \@cols_from_relations
  );
}

# _scope_values
#
# The equalities the resultset's own condition holds, as { column => value }
# with the alias removed and undef for IS NULL -- the values a row created
# through this resultset inherits.
sub _scope_values {
  my ($self) = @_;

  return {}
    if ! defined $self->{cond} or $self->{cond} eq UNRESOLVABLE_CONDITION;

  my $eqs = $self->result_source->schema->storage->_extract_fixed_condition_columns($self->{cond}, 'consider_nulls');

  return $self->_remove_alias(
    { map {
      ( ($eqs->{$_}||'') eq UNRESOLVABLE_CONDITION ) ? () : ( $_ => $eqs->{$_} )
    } keys %$eqs },
    $self->{attrs}{alias},
  );
}

# _has_resolved_attr
#
# determines if the resultset defines at least one
# of the attributes supplied
#
# used to determine if a subquery is necessary
#
# supports some virtual attributes:
#   -join
#     This will scan for any joins being present on the resultset.
#     It is not a mere key-search but a deep inspection of {from}
#

sub _has_resolved_attr {
  my ($self, @attr_names) = @_;

  my $attrs = $self->_resolved_attrs;

  my %extra_checks;

  for my $n (@attr_names) {
    if (grep { $n eq $_ } (qw/-join/) ) {
      $extra_checks{$n}++;
      next;
    }

    my $attr =  $attrs->{$n};

    next if not defined $attr;

    if (ref $attr eq 'HASH') {
      return 1 if keys %$attr;
    }
    elsif (ref $attr eq 'ARRAY') {
      return 1 if @$attr;
    }
    else {
      return 1 if $attr;
    }
  }

  # a resolved join is expressed as a multi-level from
  return 1 if (
    $extra_checks{-join}
      and
    ref $attrs->{from} eq 'ARRAY'
      and
    @{$attrs->{from}} > 1
  );

  return 0;
}

# _remove_alias
#
# Remove the specified alias from the specified query hash. A copy is made so
# the original query is not modified.

sub _remove_alias {
  my ($self, $query, $alias) = @_;

  my %orig = %{ $query || {} };
  my %unaliased;

  foreach my $key (keys %orig) {
    if ($key !~ /\./) {
      $unaliased{$key} = $orig{$key};
      next;
    }
    $unaliased{$1} = $orig{$key}
      if $key =~ m/^(?:\Q$alias\E\.)?([^.]+)$/;
  }

  return \%unaliased;
}


sub as_query {
  my $self = shift;

  my $attrs = { %{ $self->_resolved_attrs } };

  my $aq = $self->result_source->storage->_select_args_to_query (
    $attrs->{from}, $attrs->{select}, $attrs->{where}, $attrs
  );

  $aq;
}


sub find_or_new {
  my $self     = shift;
  my $attrs    = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
  my $hash     = ref $_[0] eq 'HASH' ? shift : {@_};
  if (keys %$hash and my $row = $self->_find_for_write($hash, $attrs, 'find_or_new') ) {
    return $row;
  }
  return $self->new_result($hash);
}


sub find_or_new_async {
  my $self  = shift;
  my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
  my $hash  = ref $_[0] eq 'HASH' ? shift : {@_};

  return $self->_rs_run_async('find_or_new',
    sub {
      my ($backend, $fc) = @_;
      return $fc->done($self->new_result($hash)) unless keys %$hash;

      return $self->_find_for_write_async($hash, $attrs, 'find_or_new')->then(sub {
        my ($row) = @_;
        return $row if $row;
        return $self->new_result($hash);
      });
    },
    sub { $self->find_or_new($hash, $attrs) },
  );
}


sub create {
  #my ($self, $col_data) = @_;
  assert_no_internal_indirect_calls and fail_on_internal_call;
  return shift->new_result(shift)->insert;
}


sub find_or_create {
  my $self     = shift;
  my $attrs    = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
  my $hash     = ref $_[0] eq 'HASH' ? shift : {@_};
  if (keys %$hash and my $row = $self->_find_for_write($hash, $attrs, 'find_or_create') ) {
    return $row;
  }
  return $self->new_result($hash)->insert;
}


sub find_or_create_async {
  my $self  = shift;
  my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
  my $hash  = ref $_[0] eq 'HASH' ? shift : {@_};

  return $self->_rs_run_async('find_or_create',
    sub {
      my ($backend, $fc) = @_;
      return $self->create_async($hash) unless keys %$hash;

      return $self->_find_for_write_async($hash, $attrs, 'find_or_create')->then(sub {
        my ($row) = @_;
        return $row if $row;
        return $self->create_async($hash);
      });
    },
    sub { $self->find_or_create($hash, $attrs) },
  );
}


sub update_or_create {
  my $self = shift;
  my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
  my $cond = ref $_[0] eq 'HASH' ? shift : {@_};

  # find() only accepts a condition it can reduce to concrete columns on this
  # table, so the lookup drops any relation-valued key that does not resolve to
  # a concrete foreign-key condition. The FULL condition -- relation keys
  # included -- still reaches the row layer via update()/insert below, which
  # owns nested-relation semantics.
  my @lookup_cols;
  my $row = $self->_find_for_write($self->_find_lookup_cond($cond), $attrs, 'update_or_create', \@lookup_cols);
  if (defined $row) {
    $row->update($self->_update_data_for_found_row($cond, \@lookup_cols));
  }
  else {
    $row = $self->new_result($cond)->insert;
  }

  return $row;
}

# Build the find() lookup for update_or_create: the passed condition with every
# relation-valued key that does NOT reduce to a concrete foreign-key condition
# on this table removed. A resolvable belongs_to (FK-bearing hashref, or a
# blessed related object) resolves join-free to { self_fk => <defined value> }
# and stays, so find() folds it in as before. A has_many / has_one / might_have
# searched by its own non-key columns is either crosstable, or resolves join-free
# to { self_pk => undef }; leaving it in the lookup would make find() reject it
# (before the guard, it silently clobbered the key with an undef FK). Such keys
# are dropped from the LOOKUP only -- update_or_create still passes the full
# condition to the row layer, which owns nested-relation semantics. See ADR 0034.
sub _find_lookup_cond {
  my ($self, $cond) = @_;

  my $rsrc = $self->result_source;
  my %lookup = %$cond;

  for my $key (keys %lookup) {
    next unless ref $lookup{$key} eq 'HASH';
    next unless $rsrc->relationship_info($key);

    my ($rel_cond, $crosstable)
      = $self->_resolve_related_cond($rsrc, $key, $lookup{$key});

    delete $lookup{$key}
      unless $self->_related_cond_is_concrete($rel_cond, $crosstable);
  }

  return \%lookup;
}


sub update_or_create_async {
  my $self  = shift;
  my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
  my $cond  = ref $_[0] eq 'HASH' ? shift : {@_};

  return $self->_rs_run_async('update_or_create',
    sub {
      my ($backend, $fc) = @_;

      my @lookup_cols;
      return $self->_find_for_write_async($self->_find_lookup_cond($cond), $attrs, 'update_or_create', \@lookup_cols)->then(sub {
        my ($row) = @_;
        return $row->update_async($self->_update_data_for_found_row($cond, \@lookup_cols)) if defined $row;
        return $self->create_async($cond);
      });
    },
    sub { $self->update_or_create($cond, $attrs) },
  );
}


my %_upsert_options = map { $_ => 1 } qw(
  key conflict_target on_conflict update update_where result fallback relations
);

my %_upsert_result_shapes = map { $_ => 1 } qw(
  row_or_undef row_or_die count void
);

# What a single entry of the `relations` structure may say. Deliberately just
# the conflict target plus its own nesting: on_conflict, update and result are
# whole-cascade or whole-statement decisions, not per-part ones.
my %_upsert_relation_options = map { $_ => 1 } qw(
  key conflict_target relations
);


sub upsert_async {
  my ($self, $data, $opts) = @_;

  my $rsrc  = $self->result_source;
  my $sname = $rsrc->source_name || $rsrc->result_class || 'this result source';

  return $self->_rs_run_async('upsert',
    sub {
      my ($backend, $fc, $mode, @rest) = @_;

      # Cascade and fallback are each already more than one statement (a
      # transactional multi-part write, and a racy client-side read-then-write
      # respectively) -- not expressible as a single insert_async. Run
      # synchronously and resolve immediately, same precedent as
      # create_async's related-object multi-create (ADR 0031).
      if ($mode eq 'cascade') {
        return $self->_async_ctx_or_sync_punt($fc, 'upsert',
          'a cascade upsert is a transactional multi-part write',
          sub { $self->_upsert_cascade($data, $opts, $rest[0]) });
      }
      if ($mode eq 'fallback') {
        return $self->_async_ctx_or_sync_punt($fc, 'upsert',
          'the fallback upsert is a racy client-side read-then-write',
          sub { $self->_upsert_fallback($data, $opts, $rest[0]) });
      }

      my ($storage, $new, $rowdata, $storage_opts, $shape, $action) = @rest;

      # No async transport contract carries an affected-row count for INSERT
      # SQL (insert_async always resolves the returned-columns hashref) -- see
      # the POD above. Same sync-and-resolve degrade as cascade/fallback.
      if ($shape eq 'count') {
        return $self->_async_ctx_or_sync_punt($fc, 'upsert',
          'no async transport carries an affected-row count for an upsert',
          sub { $self->upsert($data, $opts) });
      }

      return $backend->insert_async($rsrc, { %$rowdata }, $storage_opts)->then(sub {
        my ($returned) = @_;
        return $fc->done() if $shape eq 'void';
        return $fc->done(
          $self->_upsert_finish($rsrc, $sname, $shape, $opts, $action, $new, $rowdata, $returned)
        );
      });
    },
    sub { $self->upsert($data, $opts) },
    sub { $self->_upsert_prepare($data, $opts) },
  );
}

# $prebuilt is internal: the cascade has already built the Row (it needed one
# as the vehicle for set_from_related) and hands it over so that column
# setters run exactly as often here as they do on a flat call.
sub upsert {
  my ($self, $data, $opts, $prebuilt) = @_;

  my $rsrc  = $self->result_source;
  my $sname = $rsrc->source_name || $rsrc->result_class || 'this result source';

  my ($mode, @rest) = $self->_upsert_prepare($data, $opts, $prebuilt);

  return $self->_upsert_cascade($data, $opts, $rest[0])  if $mode eq 'cascade';
  return $self->_upsert_fallback($data, $opts, $rest[0]) if $mode eq 'fallback';

  my ($storage, $new, $rowdata, $storage_opts, $shape, $action) = @rest;

  my $returned = $storage->insert($rsrc, { %$rowdata }, $storage_opts);

  return if $shape eq 'void';

  # DBI hands back the string '0E0' -- zero but true -- for a statement that
  # affected no rows, which is exactly what a conflicting upsert can do.
  # if (my $n = $rs->upsert(..., { result => 'count' })) must not read
  # "nothing happened" as true, and upsert throws on failure, so the
  # zero-but-true signal carries no information here: hand back a number.
  return 0 + ( $storage_opts->{affected_rows} || 0 ) if $shape eq 'count';

  return $self->_upsert_finish($rsrc, $sname, $shape, $opts, $action, $new, $rowdata, $returned);
}

# Shared, non-DB-touching preparation for upsert() and upsert_async(): option
# validation, conflict-target/update-set resolution, the capability gate.
# Exists so the async twin cannot drift from the sync rules --
# there is exactly one place that decides what a given call means. Returns a
# mode plus whatever the caller needs for it; every validation failure and the
# unsupported-without-fallback capability gate throw here, same as always, and
# the caller lets that propagate:
#
#   ('cascade',  $shape)
#   ('fallback', $shape)
#   ('flat', $storage, $new, \%rowdata, \%storage_opts, $shape, $action)
#
# $prebuilt is internal: the cascade has already built the Row (it needed one
# as the vehicle for set_from_related) and hands it over so that column
# setters run exactly as often here as they do on a flat call.
sub _upsert_prepare {
  my ($self, $data, $opts, $prebuilt) = @_;

  my $rsrc  = $self->result_source;
  my $sname = $rsrc->source_name || $rsrc->result_class || 'this result source';

  $self->throw_exception(
    'upsert() takes a non-empty hashref of column data as its first argument'
  ) unless ref $data eq 'HASH' and keys %$data;

  $opts ||= {};
  $self->throw_exception('upsert() takes a hashref of options as its second argument')
    unless ref $opts eq 'HASH';

  # ---- option validation. Engine-independent and complete before any SQL is
  # ---- built, so an invalid call is invalid everywhere (ADR 0036).

  if (my @unknown = sort grep { ! $_upsert_options{$_} } keys %$opts) {
    $self->throw_exception(
      "upsert(): unknown option(s) '" . CORE::join("', '", @unknown) . "' -- valid "
    . 'options are ' . CORE::join(', ', sort keys %_upsert_options)
    );
  }

  $self->throw_exception(
    "upsert(): relations must be a hashref of relationship => "
  . '{ key => $constraint | conflict_target => \@columns }'
  ) if exists $opts->{relations} and ref $opts->{relations} ne 'HASH';

  my $action = defined $opts->{on_conflict} ? $opts->{on_conflict} : 'update';
  $self->throw_exception(
    "upsert(): on_conflict must be 'update' or 'nothing', not '$action'"
  ) unless $action eq 'update' or $action eq 'nothing';

  my $shape = defined $opts->{result} ? $opts->{result} : 'row_or_undef';
  $self->throw_exception(
    "upsert(): result must be one of " . CORE::join(', ', sort keys %_upsert_result_shapes)
  . " -- '$shape' is not a return shape upsert can guarantee"
  ) unless $_upsert_result_shapes{$shape};

  # row_or_die means "never hand back nothing"; DO NOTHING exists in order to
  # possibly write nothing. The combination is refused before any SQL is built.
  $self->throw_exception(
    "upsert(): result => 'row_or_die' cannot be combined with "
  . "on_conflict => 'nothing' -- DO NOTHING may legitimately write no row"
  ) if $shape eq 'row_or_die' and $action eq 'nothing';

  # ---- the conditional conflict branch: DO UPDATE ... WHERE
  #
  # Core does not look inside the condition, exactly as search() does not look
  # inside its \%cond: the shape is checked, the content is the driver's and
  # the engine's. What core does own is the combinations in which a condition
  # cannot mean anything.
  my $update_where;
  if (exists $opts->{update_where}) {
    $update_where = $opts->{update_where};

    $self->throw_exception(
      'upsert(): update_where must be a SQL::Abstract condition (a hashref or '
    . "an arrayref) or a literal (\\'sql' / \\[ 'sql', \@bind ])"
    ) unless ref $update_where eq 'HASH'
          or ref $update_where eq 'ARRAY'
          or is_literal_value($update_where);

    # An empty condition is not "nothing excluded", it is a condition that was
    # meant to say something -- most likely built from a variable that came out
    # empty. Silently writing everything is the one outcome the option exists
    # to prevent.
    $self->throw_exception(
      'upsert(): update_where is empty -- an empty condition would make the '
    . 'conflict branch write unconditionally, which is what leaving the '
    . 'option out already does'
    ) if ( ref $update_where eq 'HASH'  and ! keys %$update_where )
      or ( ref $update_where eq 'ARRAY' and ! @$update_where );

    $self->throw_exception(
      "upsert(): update_where has no meaning with on_conflict => 'nothing' -- "
    . 'there is no update branch to put a condition on'
    ) if $action eq 'nothing';

    # Same class of refusal as row_or_die + DO NOTHING above, and for the same
    # reason: a conditional update exists in order to possibly write nothing,
    # so the two promises contradict each other by construction rather than by
    # data. Refusing it here also keeps the runtime diagnosis honest -- the
    # row_or_die throw further down blames the table shape ("this follows from
    # the table shape, not from the data"), which is precisely the wrong
    # explanation for a condition that did not hold.
    $self->throw_exception(
      "upsert(): result => 'row_or_die' cannot be combined with update_where "
    . '-- a conditional DO UPDATE writes no row when the condition does not '
    . 'hold, so a row cannot be guaranteed'
    ) if $shape eq 'row_or_die';
  }

  if (defined $opts->{fallback}) {
    $self->throw_exception(
      "upsert(): the only supported fallback is 'update_or_create', not "
    . "'$opts->{fallback}'"
    ) unless $opts->{fallback} eq 'update_or_create';

    # update_or_create always writes, and always writes everything it is
    # given. Rather than let the fallback path mean something else than the
    # atomic path, refuse the two combinations where it would.
    $self->throw_exception(
      "upsert(): fallback => 'update_or_create' cannot express "
    . "on_conflict => 'nothing' -- update_or_create always writes. Use "
    . 'find_or_create() at the call site for that shape'
    ) if $action eq 'nothing';

    $self->throw_exception(
      "upsert(): fallback => 'update_or_create' cannot express a restricted "
    . "'update' set -- update_or_create writes every supplied column"
    ) if exists $opts->{update};

    # ... and it writes them unconditionally. Dropping the condition on the
    # fallback path would turn the guard the caller asked for into the
    # last-write-wins overwrite it exists to prevent, on whichever engine the
    # fallback happens to engage.
    $self->throw_exception(
      "upsert(): fallback => 'update_or_create' cannot express update_where "
    . '-- update_or_create writes unconditionally, so the fallback path would '
    . 'overwrite exactly the rows the condition protects'
    ) if exists $opts->{update_where};

    # update_or_create finds by a *named* unique constraint; there is no way
    # to hand it a bare column list. Silently dropping the target would aim
    # the fallback at whatever constraint find()'s heuristics like best --
    # i.e. at a different row than the atomic path targets.
    $self->throw_exception(
      "upsert(): fallback => 'update_or_create' cannot express "
    . 'conflict_target -- update_or_create looks the row up by a named unique '
    . 'constraint, so the fallback would target a different constraint than '
    . 'the atomic statement. Name the constraint with key => $constraint if a '
    . 'fallback is wanted'
    ) if defined $opts->{conflict_target};
  }

  $self->throw_exception(
    "upsert(): 'key' and 'conflict_target' are mutually exclusive -- name the "
  . 'unique constraint with key, or its columns with conflict_target'
  ) if defined $opts->{key} and defined $opts->{conflict_target};

  # Nested relationship data is the cascading upsert: N atomic upserts in
  # dependency order inside one transaction. Everything above this point is
  # shared; from here the two are different operations.
  my $nested = ( $self->_upsert_split_nested($rsrc, $data) )[1];

  if (keys %$nested) {
    # A count across a cascade has no defined meaning, and void would deny the
    # cascade the identity it structurally needs to hand a parent's key to its
    # children. Refused here rather than half-way through the tree.
    $self->throw_exception(
      "upsert(): result => '$shape' cannot be used with nested relationship "
    . 'data -- a cascade is more than one statement, so there is no single '
    . 'affected-row count, and void would withhold the identity the cascade '
    . 'needs to link the parts. Use row_or_undef or row_or_die'
    ) if $shape eq 'count' or $shape eq 'void';

    # update_or_create takes one named constraint for the top-level row and
    # nothing at all for the parts, so a fallback cascade would look every
    # part up by find()'s heuristics -- a different row than the atomic path
    # writes, which is exactly what refusing conflict_target here prevents.
    $self->throw_exception(
      "upsert(): fallback => 'update_or_create' cannot express a cascade -- "
    . 'it has no way to state a conflict target per part, so every nested '
    . "part would be looked up by find()'s heuristics. Branch on "
    . '$storage->_use_supports_upsert and call update_or_create() yourself if '
    . 'the racy client-side cascade is what you want'
    ) if defined $opts->{fallback};

    return ('cascade', $shape);
  }

  # A per-relation target with no nested part to apply it to is a typo, not a
  # no-op -- the caller believes a cascade is happening and none is.
  if (my @orphan = sort keys %{ $opts->{relations} || {} }) {
    $self->throw_exception(
      "upsert(): relations names '" . CORE::join("', '", @orphan) . "', but "
    . '%col_data has no nested data for '
    . (@orphan > 1 ? 'those relationships' : 'that relationship')
    . ' -- a per-relation conflict target with nothing to apply it to would '
    . 'silently do nothing'
    );
  }

  # Route the data through new_result: it validates the column names, folds in
  # the resultset's own condition exactly as create() does, and deflates
  # inflated columns. By the check above it cannot carry relationship data.
  my $new = $prebuilt || $self->new_result($data);
  my %rowdata = $new->get_columns;

  # ---- conflict target

  my ($target, @target_cols);
  if (defined $opts->{key}) {
    # throws on an unknown constraint name -- before any SQL is built
    @target_cols = $rsrc->unique_constraint_columns($opts->{key});

    # Both halves travel down. The name is what an engine that can name a
    # constraint wants (PostgreSQL's ON CONSTRAINT); the resolved columns are
    # what the engines whose grammar knows a column list only can use at all
    # (SQLite). A SQLMaker is handed ($table, $data, $options) and no
    # ResultSource, so it cannot resolve the name itself -- passing the name
    # alone is what made key => $constraint unusable on those engines.
    $target = { constraint => $opts->{key}, columns => [ @target_cols ] };
  }
  elsif (defined( my $ct = $opts->{conflict_target} )) {
    if (ref $ct eq 'ARRAY') {
      $self->throw_exception('upsert(): conflict_target is an empty list')
        unless @$ct;
      @target_cols = @$ct;
      $target = [ @$ct ];
    }
    elsif (! length ref $ct and $ct eq 'any') {
      $target = 'any';
    }
    elsif (! length ref $ct) {
      $self->throw_exception(
        "upsert(): conflict_target '$ct' is not a column of $sname -- pass an "
      . "arrayref of columns, the string 'any', or name a unique constraint "
      . "with key => '$ct'"
      ) unless $rsrc->has_column($ct);
      @target_cols = ($ct);
      $target = [ $ct ];
    }
    else {
      $self->throw_exception(
        'upsert(): conflict_target must be an arrayref of columns, a single '
      . "column name, or the string 'any'"
      );
    }

    for my $col (@target_cols) {
      $self->throw_exception(
        "upsert(): conflict_target column '$col' is not a column of $sname"
      ) unless $rsrc->has_column($col);
    }
  }
  else {
    my @pk = $rsrc->primary_columns;
    $self->throw_exception(
      "upsert(): $sname has no primary key, so there is no conflict target to "
    . 'default to -- name one with key => $constraint or '
    . 'conflict_target => \@columns. upsert does not guess among the unique '
    . 'constraints'
    ) unless @pk;

    if (my @missing = grep { ! defined $rowdata{$_} } @pk) {
      $self->throw_exception(
        "upsert(): no conflict target given and the data does not supply the "
      . "primary key of $sname (missing: " . CORE::join(', ', @missing) . ') -- the '
      . 'statement could never collide and would silently degenerate into a '
      . 'plain INSERT. Name the target with key => $constraint or '
      . 'conflict_target => \@columns'
      );
    }

    @target_cols = @pk;
    $target = [ @pk ];
  }

  # ---- the update set

  my $set;
  if ($action eq 'nothing') {
    $self->throw_exception(
      "upsert(): the 'update' option has no meaning with "
    . "on_conflict => 'nothing'"
    ) if exists $opts->{update};
  }
  else {
    my %skip = map { $_ => 1 } (@target_cols, $rsrc->primary_columns);

    if (ref $opts->{update} eq 'ARRAY') {
      for my $col (@{ $opts->{update} }) {
        $self->throw_exception(
          "upsert(): update column '$col' is not a column of $sname"
        ) unless $rsrc->has_column($col);

        $self->throw_exception(
          "upsert(): update column '$col' is not among the values being "
        . 'inserted, so there is no attempted value to set it to -- supply it '
        . 'in the data, or use the update => { col => $expr } form'
        ) unless exists $rowdata{$col};
      }
      $set = { map { $_ => { -attempted => $_ } } @{ $opts->{update} } };
    }
    elsif (ref $opts->{update} eq 'HASH') {
      for my $col (sort keys %{ $opts->{update} }) {
        $self->throw_exception(
          "upsert(): update column '$col' is not a column of $sname"
        ) unless $rsrc->has_column($col);
      }
      $set = { %{ $opts->{update} } };
    }
    elsif (exists $opts->{update}) {
      $self->throw_exception(
        'upsert(): update must be an arrayref of columns or a hashref of '
      . 'column => expression pairs'
      );
    }
    else {
      $set = {
        map  { $_ => { -attempted => $_ } }
        grep { ! $skip{$_} }
        sort keys %rowdata
      };
    }

    $self->throw_exception(
      'upsert(): the conflict branch would set no column at all -- every '
    . "supplied column is part of the conflict target or the primary key of "
    . "$sname. Use on_conflict => 'nothing' if that is what you mean"
    ) unless keys %$set;
  }

  my $on_conflict = {
    target => $target,
    action => $action,
    set    => $set
  };

  # Only when there is one: a driver that never sees the key renders exactly
  # the statement it rendered before this option existed.
  $on_conflict->{where} = $update_where if defined $update_where;

  # ---- capability gate. No silent degradation: an engine without an atomic
  # ---- upsert throws unless the caller opted into the race for this call.

  my $storage = $rsrc->storage;
  my $supported = $storage->can('_use_supports_upsert')
    ? $storage->_use_supports_upsert
    : 0;

  unless ($supported) {
    return ('fallback', $shape)
      if defined $opts->{fallback};

    $self->_upsert_unsupported($storage);
  }

  # A second gate, for the one part of the structure a driver can ignore
  # without producing a single symptom. Every other dialect difference is
  # self-announcing: a driver that drops the conflict target emits invalid SQL
  # on PostgreSQL, one that ignores action => 'nothing' has no set to write.
  # A dropped WHERE renders a perfectly valid unconditional UPDATE -- the
  # last-write-wins overwrite the condition was written to prevent, silently.
  # So the driver has to say it renders conditions before core sends one.
  if (defined $update_where) {
    my $conditional = $storage->can('_use_supports_upsert_where')
      ? $storage->_use_supports_upsert_where
      : 0;

    $self->throw_exception(
      ref($storage) . ' does not declare the supports_upsert_where '
    . 'capability: this engine has no conditional conflict branch, or its '
    . 'driver does not render one. MySQL is the engine that cannot -- '
    . 'ON DUPLICATE KEY UPDATE has no WHERE, and a per-column IF() does not '
    . 'suppress the write. Drop update_where, or branch on '
    . '$storage->_use_supports_upsert_where'
    ) unless $conditional;
  }

  my %storage_opts = ( on_conflict => $on_conflict );
  $storage_opts{no_retrieve} = 1 if $shape eq 'void' or $shape eq 'count';

  return ('flat', $storage, $new, \%rowdata, \%storage_opts, $shape, $action);
}

# Shared tail for the row_or_undef/row_or_die shapes of the flat upsert path
# (both upsert() and upsert_async(), once each has its own $returned
# hashref) -- void/count are decided by the caller before this is reached
# (upsert_async's count degrades to sync entirely, see its POD). $returned is
# the returned-columns hashref the write produced, same shape sync
# $storage->insert and async insert_async both resolve.
sub _upsert_finish {
  my ($self, $rsrc, $sname, $shape, $opts, $action, $new, $rowdata, $returned) = @_;

  # row_or_undef / row_or_die: the written row can be named only when the
  # engine handed back every primary key column for it.
  my @pk = $rsrc->primary_columns;
  if (@pk and ! grep { ! defined $returned->{$_} } @pk) {
    return $new->_store_inserted_columns($rowdata, $returned);
  }

  $self->throw_exception(
    "upsert(): result => 'row_or_die' asked for the written row, but the "
  . "engine did not name it (no primary key came back for $sname). This "
  . 'follows from the table shape, not from the data'
  ) if $shape eq 'row_or_die';

  # The default is the one value nobody types, so its name cannot teach the
  # caller who needs teaching -- the runtime has to. Silenceable by passing
  # result => 'row_or_undef' explicitly.
  #
  # Not on the DO NOTHING branch though: a conflicting DO NOTHING writes no
  # row, so RETURNING yields none and no primary key can come back. That is
  # the documented, legitimate outcome of what the caller asked for, not an
  # engine failing to name what it wrote -- warning there would be false.
  carp_once(
    "upsert() on $sname could not name the row it wrote -- no primary key "
  . 'came back for it, so undef is returned. Pass result => "row_or_undef" '
  . 'explicitly to silence this, or result => "count" / "void" if the row is '
  . 'not needed'
  ) unless exists $opts->{result} or $action eq 'nothing';

  return undef;
}

# No capability, no upsert -- never a silent client-side two-step. Shared by
# the flat path and the cascade, which asserts it before opening its
# transaction rather than after (ADR 0036 section 3).
sub _upsert_unsupported {
  my ($self, $storage) = @_;

  $self->throw_exception(
    ref($storage) . ' does not declare the supports_upsert capability: this '
  . 'engine has no atomic upsert. Branch on '
  . '$storage->_use_supports_upsert and call update_or_create() (racy, '
  . "client-side) yourself, or pass fallback => 'update_or_create' to accept "
  . 'the race for this call'
  );
}

# The explicit, per-call fallback for engines without an atomic upsert. The
# return mapping is pinned so the same call never changes return *type* with
# the engine (ADR 0036 section 3).
sub _upsert_fallback {
  my ($self, $data, $opts, $shape) = @_;

  # The fallback has to look the row up by the constraint the atomic statement
  # would have conflicted on -- anything else writes a different row than the
  # engine would have. Option validation refused fallback together with
  # conflict_target, so only two targets can reach here, and both are
  # expressible as update_or_create's key: the named constraint, or the
  # primary-key default (which upsert only takes when the data supplies every
  # PK column, so the lookup is always satisfiable). Without the explicit key
  # update_or_create would fall into find()'s heuristics mode, which ORs every
  # satisfiable unique constraint together.
  my $row = $self->update_or_create(
    $data,
    { key => defined $opts->{key} ? $opts->{key} : 'primary' }
  );

  return    if $shape eq 'void';
  return 1  if $shape eq 'count';   # synthetic, not an affected-rows figure
  return $row;
}

# ---- the cascading upsert (ADR 0036 section 1) --------------------------
#
# What is promised, and it is deliberately not "an atomic upsert": N atomic
# upserts, in dependency order, inside one transaction -- all-or-nothing, and
# every part individually free of the read-then-write race. No engine has a
# multi-table upsert, so a cascade is inherently more than one statement.

# Split \%data into this source's own columns and its nested relationship
# parts. Same criterion DBIO::Row::new applies when it sorts multicreate data:
# a non-literal ref under a key that names a relationship is a part; anything
# else -- an inflated object, a literal \'NOW()', a plain value -- is a column.
sub _upsert_split_nested {
  my ($self, $rsrc, $data) = @_;

  my (%cols, %nested);

  for my $key (keys %$data) {
    my $val = $data->{$key};

    if (
      length ref $val
        and
      ! is_literal_value($val)
        and
      ( ref $val eq 'HASH' or ref $val eq 'ARRAY' or blessed $val )
    ) {
      if ($rsrc->has_relationship($key)) {
        $nested{$key} = $val;
        next;
      }

      # A many_to_many is an accessor over a bridge table, not a relationship,
      # so it would fall through to "no such column" and read like a typo.
      # Out of scope, and it says why: writing bridge rows reopens the very
      # deletion question has_many is deliberately kept out of.
      my $rclass = $rsrc->result_class;
      $self->throw_exception(
        "upsert(): '$key' is a many_to_many accessor, which the cascading "
      . 'upsert does not handle -- it would have to write link rows, and what '
      . 'to do with the link rows you did not list has no safe answer. Nest '
      . 'the bridge relationship itself instead, or use set_' . $key . '()'
      ) if $rclass
        and $rclass->can('_m2m_metadata')
        and $rclass->_m2m_metadata->{$key};
    }

    $cols{$key} = $val;
  }

  return (\%cols, \%nested);
}

# Build the whole cascade plan before the first statement runs.
#
# Everything checked here follows from static schema metadata and the shape of
# the options -- never from data the server holds -- so a cascade that cannot
# work fails on the first call in development rather than the day the "other"
# unique constraint finally collides in production (ADR 0036 section 4).
#
# $want is the result shape this node has to deliver: 'row_or_die' whenever
# something downstream needs the written row's identity, which is what makes
# the identity preconditions apply.
sub _upsert_plan {
  my ($self, $rs, $data, $opts, $want, $filled, $path) = @_;

  my $rsrc  = $rs->result_source;
  my $sname = $rsrc->source_name || $rsrc->result_class || 'this result source';
  my $at    = length $path ? " for the nested '$path'" : '';
  my $hint  = length $path
    ? "relations => { '$path' => { key => \$constraint } }"
    : 'key => $constraint or conflict_target => \@columns';

  my ($cols, $nested) = $self->_upsert_split_nested($rsrc, $data);

  # ---- the per-relation targets

  my $relopts = $opts->{relations} || {};
  $self->throw_exception(
    "upsert(): relations$at must be a hashref of relationship => "
  . '{ key => $constraint | conflict_target => \@columns }'
  ) unless ref $relopts eq 'HASH';

  for my $rel (sort keys %$relopts) {
    $self->throw_exception(
      "upsert(): relations$at names '$rel', but there is no nested data for "
    . 'it -- a per-relation conflict target with nothing to apply it to would '
    . 'silently do nothing'
    ) unless exists $nested->{$rel};

    $self->throw_exception(
      "upsert(): relations$at => { '$rel' => ... } must be a hashref"
    ) unless ref $relopts->{$rel} eq 'HASH';

    if (
      my @unknown =
        sort grep { ! $_upsert_relation_options{$_} } keys %{ $relopts->{$rel} }
    ) {
      $self->throw_exception(
        "upsert(): unknown option(s) '" . CORE::join("', '", @unknown) . "' for the "
      . "nested '$rel'$at -- a per-relation entry takes "
      . CORE::join(', ', sort keys %_upsert_relation_options)
      . '. on_conflict, update, update_where and result are decisions about '
      . 'the whole call, not about one part'
      );
    }

    $self->throw_exception(
      "upsert(): 'key' and 'conflict_target' are mutually exclusive, also for "
    . "the nested '$rel'$at"
    ) if defined $relopts->{$rel}{key}
     and defined $relopts->{$rel}{conflict_target};
  }

  # ---- dependency order: whose primary key becomes whose foreign key.
  #
  # This is the split DBIO::Row::insert performs for multicreate, applied to
  # the data instead of to constructed Row objects: _pk_depends_on answers
  # "must the part be written before us" (belongs_to -- its key becomes our
  # foreign key) or "does the part need us" (has_many / might_have -- our key
  # becomes theirs).

  my (@before, @after, @from_before);

  for my $rel (sort keys %$nested) {
    my $val      = $nested->{$rel};
    my $info     = $rsrc->relationship_info($rel);
    my $acc      = $info->{attrs}{accessor} || '';
    my $rel_rsrc = $rsrc->related_source($rel);
    my $sub_path = length $path ? "$path.$rel" : $rel;
    my $sub_opts = $relopts->{$rel} || {};

    my @list = ref $val eq 'ARRAY' ? @$val : ($val);

    for my $part (@list) {
      # A Row object is already a decision about identity: "link this one" and
      # "write these values" are different asks, and guessing between them is
      # the DWIM this API exists to avoid. The cascade upserts data.
      next if ref $part eq 'HASH';

      $self->throw_exception(
        "upsert(): the nested '$sub_path' is "
      . ( blessed $part ? 'a ' . ref($part) . ' object'
        : ref $part     ? 'a ' . ref($part) . ' reference'
        :                 'a plain scalar' )
      . ' -- the cascade upserts column data, so pass the columns '
      . '({ $row->get_columns }) or set the foreign key yourself. An existing '
      . 'Result object does not say whether you want it written or only linked'
      );
    }

    if (ref $val eq 'ARRAY') {
      $self->throw_exception(
        "upsert(): the nested '$sub_path' is a list, but '$rel' is not a "
      . 'has_many -- pass a single hashref for a single related row'
      ) unless $acc eq 'multi';
    }
    else {
      $self->throw_exception(
        "upsert(): the nested '$sub_path' is a single hashref, but '$rel' is "
      . 'a has_many -- pass an arrayref of hashrefs'
      ) if $acc eq 'multi';
    }

    my $cond = $info->{cond};

    # multi is always "after us" -- exactly as multicreate treats it. For a
    # single/filter accessor the direction is a schema question, and
    # _pk_depends_on is the one place in the codebase that answers it.
    my ($flat_part) = $acc eq 'multi'
      ? ({})
      : $self->_upsert_split_nested($rel_rsrc, $val);

    if ($acc ne 'multi' and $rsrc->_pk_depends_on($rel, $flat_part)) {
      # its key becomes our foreign key: written before us, and it must be
      # able to name what it wrote
      push @before, {
        rel  => $rel,
        node => $self->_upsert_plan(
          $rel_rsrc->resultset, $val, $sub_opts, 'row_or_die', [], $sub_path,
        ),
      };

      push @from_before, map { m/^self\.(.+)\z/ ? $1 : () } values %$cond
        if ref $cond eq 'HASH';

      next;
    }

    # our key becomes theirs: written after us. The foreign key is set the way
    # multicreate sets it, through the reverse relationship -- without one
    # nothing would link the child to us and the cascade would quietly write
    # an orphan.
    my @revs = sort keys %{ $rsrc->reverse_relationship_info($rel) };
    $self->throw_exception(
      "upsert(): '$rel'$at has no reverse relationship back to $sname, so "
    . 'there is no way to derive the foreign key of the nested rows from the '
    . 'row written for it -- they would be written unlinked. Declare the '
    . "opposing relationship on @{[ $rel_rsrc->source_name || $rel_rsrc->result_class ]}"
    ) unless @revs;

    my @child_filled = ref $cond eq 'HASH'
      ? map { m/^foreign\.(.+)\z/ ? $1 : () } keys %$cond
      : ();

    push @after, {
      rel   => $rel,
      revs  => \@revs,
      nodes => [
        map {
          $self->_upsert_plan(
            $rel_rsrc->resultset, $_, $sub_opts, 'void', \@child_filled,
            $sub_path,
          )
        } @list
      ],
    };
  }

  # A part may legitimately carry no column of its own -- a might_have whose
  # only column is the foreign key it is handed. Carrying none and being
  # handed none is nothing at all.
  $self->throw_exception(
    'upsert(): ' . (length $path ? "the nested '$path'" : $sname)
  . ' supplies no column of its own and is handed none by the rows around it '
  . '-- there is no row there to upsert'
  ) unless keys %$cols or @$filled or @from_before;

  # Children need our key, so we have to be able to name the row we wrote --
  # whatever the caller asked to get back.
  $want = 'row_or_die' if @after;
  my $identity = $want eq 'row_or_die';

  # ---- the preconditions, all decided from static metadata

  my @pk = $rsrc->primary_columns;

  if ($identity) {
    $self->throw_exception(
      "upsert(): the cascade needs the key of the row written for $sname"
    . ($at || ' at the top level')
    . ', but the source has no primary key, so no row it writes can be named'
    ) unless @pk;

    my $ct = $opts->{conflict_target};
    $self->throw_exception(
      "upsert(): conflict_target => 'any'$at cannot take part in a cascade -- "
    . 'it asks the engine to resolve on whichever unique constraint collides, '
    . 'which is exactly the shape in which the written row cannot be named. '
    . 'Name the constraint the parts are linked on'
    ) if defined $ct and ! length ref $ct and $ct eq 'any';

    $self->throw_exception(
      "upsert(): on_conflict => 'nothing' cannot take part in a cascade with "
    . 'nested rows that depend on this one -- DO NOTHING may write no row, '
    . 'and then there is no key to hand to them'
    ) if ($opts->{on_conflict} || 'update') eq 'nothing';

    # Same shape, same reason: whether the condition holds is a fact about the
    # stored data, so a row the children need may or may not exist -- and the
    # cascade would find that out half-way through, in production, on the day
    # the condition first fails.
    $self->throw_exception(
      'upsert(): update_where cannot take part in a cascade with nested rows '
    . 'that depend on this one -- a conditional DO UPDATE may write no row, '
    . 'and then there is no key to hand to them'
    ) if exists $opts->{update_where};
  }

  # The three-way primary-key default rule, per part. A foreign key this node
  # is handed -- by its parent, or by a part written before it -- counts as
  # supplied even though it is not in the data yet.
  if (! defined $opts->{key} and ! defined $opts->{conflict_target}) {
    my %have = map { $_ => 1 } (
      ( grep { defined $cols->{$_} } keys %$cols ), @$filled, @from_before,
    );

    $self->throw_exception(
      "upsert(): $sname$at has no primary key, so there is no conflict target "
    . "to default to -- name one with $hint. upsert does not guess among the "
    . 'unique constraints'
    ) unless @pk;

    if (my @missing = grep { ! $have{$_} } @pk) {
      $self->throw_exception(
        "upsert(): no conflict target given for $sname$at and the data does "
      . 'not supply its primary key (missing: ' . CORE::join(', ', @missing) . ') -- '
      . 'the statement could never collide and would silently degenerate into '
      . "a plain INSERT. Name the target with $hint"
      );
    }
  }

  my %flat_opts = ( result => $want );
  for my $k (qw/ key conflict_target on_conflict update update_where /) {
    $flat_opts{$k} = $opts->{$k} if exists $opts->{$k};
  }

  # The columns the conflict branch must not treat as "something to update".
  # Resolved here so the run can tell an empty update set from a real one --
  # a bare key resolves through the same unique_constraints as everywhere
  # else, and an unknown constraint name is caught before any statement.
  my @target_cols =
      defined $opts->{key}             ? $rsrc->unique_constraint_columns($opts->{key})
    : ! defined $opts->{conflict_target} ? @pk
    : ref $opts->{conflict_target} eq 'ARRAY' ? @{ $opts->{conflict_target} }
    : ( ! length ref $opts->{conflict_target}
          and $opts->{conflict_target} ne 'any' ) ? ( $opts->{conflict_target} )
    : ();

  return {
    rs          => $rs,
    cols        => $cols,
    opts        => \%flat_opts,
    target_cols => \@target_cols,
    before      => \@before,
    after       => \@after,
  };
}

# Plan first, then one transaction around the whole tree.
sub _upsert_cascade {
  my ($self, $data, $opts, $shape) = @_;

  my $storage = $self->result_source->storage;

  # Ahead of the transaction, so an unsupporting engine does not get a BEGIN
  # and a ROLLBACK to show for a call that could never have worked.
  $self->_upsert_unsupported($storage)
    unless $storage->can('_use_supports_upsert')
       and $storage->_use_supports_upsert;

  my $plan = $self->_upsert_plan($self, $data, $opts, $shape, [], '');

  # All-or-nothing. Already inside a transaction? Then this JOINS it -- a
  # failing cascade takes the caller's outer work down with it. Deliberately
  # no savepoint magic: a caller who wants the cascade isolated from
  # surrounding work opens their own savepoint.
  my $guard = $storage->txn_scope_guard;
  my $row = $self->_upsert_run($plan);
  $guard->commit;

  return $row;
}

# A row identified entirely by its own conflict target -- the lookup row that
# a belongs_to part almost always is, { name => 'Y' } keyed on name -- leaves
# the conflict branch with nothing to set. Flat, that is a caller mistake and
# upsert says so, pointing at on_conflict => 'nothing'. In a cascade it is not
# a choice the caller can make: DO NOTHING writes no row, and a part something
# hangs off has to be nameable. So the branch re-asserts the target instead --
# col = <the value that was attempted> -- which is a no-op on the value and
# keeps the row returned. Exactly the idiom ADR 0036 section 4 blesses for
# MySQL's identity set, for the same reason.
sub _upsert_node_opts {
  my ($self, $node, $row) = @_;

  my %opts = %{ $node->{opts} };

  return \%opts
    if exists $opts{update}
    or ( $opts{on_conflict} || 'update' ) eq 'nothing'
    or ! @{ $node->{target_cols} };

  my %rowdata = $row->get_columns;
  my %skip = map { $_ => 1 }
    @{ $node->{target_cols} }, $node->{rs}->result_source->primary_columns;

  return \%opts if grep { ! $skip{$_} } keys %rowdata;

  my @noop = grep { exists $rowdata{$_} } @{ $node->{target_cols} };
  $opts{update} = \@noop if @noop;

  return \%opts;
}

# Walk the plan: parts whose key we need first, us, then the parts that need
# ours. $prebuilt is the Row the caller of this node already had to build in
# order to set the foreign key on it.
sub _upsert_run {
  my ($self, $node, $prebuilt) = @_;

  my $rs  = $node->{rs};
  my $row = $prebuilt || $rs->new_result($node->{cols});

  $row->set_from_related(
    $_->{rel}, $self->_upsert_run($_->{node})
  ) for @{ $node->{before} };

  $row = $rs->upsert(
    { $row->get_columns }, $self->_upsert_node_opts($node, $row), $row,
  );

  for my $after (@{ $node->{after} }) {
    for my $child (@{ $after->{nodes} }) {
      my $crow = $child->{rs}->new_result($child->{cols});
      $crow->set_from_related($_, $row) for @{ $after->{revs} };
      $self->_upsert_run($child, $crow);
    }
  }

  return $row;
}


sub update_or_new {
    my $self  = shift;
    my $attrs = ( @_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {} );
    my $cond  = ref $_[0] eq 'HASH' ? shift : {@_};

    my @lookup_cols;
    my $row = $self->_find_for_write( $cond, $attrs, 'update_or_new', \@lookup_cols );
    if ( defined $row ) {
        $row->update($self->_update_data_for_found_row($cond, \@lookup_cols));
        return $row;
    }

    return $self->new_result($cond);
}


sub update_or_new_async {
  my $self  = shift;
  my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
  my $cond  = ref $_[0] eq 'HASH' ? shift : {@_};

  return $self->_rs_run_async('update_or_new',
    sub {
      my ($backend, $fc) = @_;

      my @lookup_cols;
      return $self->_find_for_write_async($cond, $attrs, 'update_or_new', \@lookup_cols)->then(sub {
        my ($row) = @_;
        return $row->update_async($self->_update_data_for_found_row($cond, \@lookup_cols)) if defined $row;
        return $self->new_result($cond);
      });
    },
    sub { $self->update_or_new($cond, $attrs) },
  );
}


sub get_cache {
  shift->{all_cache};
}


sub set_cache {
  my ( $self, $data ) = @_;
  $self->throw_exception("set_cache requires an arrayref")
      if defined($data) && (ref $data ne 'ARRAY');

  # If set_cache is called after a related resultset has been created,
  # we expect subsequent calls to related_resultset to include cached
  # results (if they are present on the objects in $data).
  #
  # This won't be true if we've cached the related_resultsets already,
  # so clear them.
  $self->{related_resultsets} = {};
  $self->{all_cache} = $data;
}


sub clear_cache {
  shift->set_cache(undef);
}


sub is_paged {
  my ($self) = @_;
  return !!$self->{attrs}{page};
}


sub is_ordered {
  my ($self) = @_;
  return scalar $self->result_source->storage->_extract_order_criteria($self->{attrs}{order_by});
}


sub related_resultset {
  my ($self, $rel) = @_;

  my $rrs = defined $self->{related_resultsets}{$rel}
    ? $self->{related_resultsets}{$rel}
    : ( $self->{related_resultsets}{$rel} = do {
    my $rsrc = $self->result_source;
    my $rel_info = $rsrc->relationship_info($rel);

    $self->throw_exception(
      "search_related: result source '" . $rsrc->source_name .
        "' has no such relationship $rel")
      unless $rel_info;

    my $attrs = $self->_chain_relationship($rel);

    my $join_count = $attrs->{seen_join}{$rel};

    my $alias = $self->result_source->storage
        ->relname_to_table_alias($rel, $join_count);

    # since this is search_related, and we already slid the select window inwards
    # (the select/as attrs were deleted in the beginning), we need to flip all
    # left joins to inner, so we get the expected results
    # read the comment on top of the actual function to see what this does
    $attrs->{from} = $rsrc->schema->storage->_inner_join_to_node ($attrs->{from}, $alias);


    #XXX - temp fix for result_class bug. There likely is a more elegant fix -groditi
    delete @{$attrs}{qw(result_class alias)};

    my $rel_source = $rsrc->related_source($rel);

    my $new = do {

      # The reason we do this now instead of passing the alias to the
      # search_rs below is that if you wrap/overload resultset on the
      # source you need to know what alias it's -going- to have for things
      # to work sanely (e.g. RestrictWithObject wants to be able to add
      # extra query restrictions, and these may need to be $alias.)

      my $rel_attrs = $rel_source->resultset_attributes;
      local $rel_attrs->{alias} = $alias;

      $rel_source->resultset
                 ->search_rs(
                     undef, {
                       %$attrs,
                       where => $attrs->{where},
                   });
    };

    if (my $cache = $self->get_cache) {
      my @related_cache = map
        { $_->related_resultset($rel)->get_cache || () }
        @$cache
      ;

      $new->set_cache([ map @$_, @related_cache ]) if @related_cache == @$cache;
    }

    $new;
  } );

  # ADR 0045 / karr k195: a related resultset derived from a context-bound
  # resultset inherits the pin, so with_context($ctx)->search_related(...)
  # routes onto the pinned connection instead of a sibling pool connection.
  $rrs->{_async_context} = $self->{_async_context}
    if $self->{_async_context} and blessed $rrs;

  return $rrs;
}


sub current_source_alias {
  return (shift->{attrs} || {})->{alias} || 'me';
}


sub as_subselect_rs {
  my $self = shift;

  my $attrs = $self->_resolved_attrs;

  my $fresh_rs = (ref $self)->new (
    $self->result_source,
    {},
  );

  # these pieces will be locked in the subquery
  delete $fresh_rs->{cond};
  delete @{$fresh_rs->{attrs}}{qw/where bind/};

  # ADR 0045 / karr k195: a subselect wrapper of a context-bound resultset keeps
  # the pin (the ->search_rs below propagates it onto the returned clone).
  $fresh_rs->{_async_context} = $self->{_async_context} if $self->{_async_context};

  return $fresh_rs->search_rs( {}, {
    from => [{
      $attrs->{alias} => $self->as_query,
      -alias  => $attrs->{alias},
      -rsrc   => $self->result_source,
    }],
    alias => $attrs->{alias},
  });
}

# This code is called by search_related, and makes sure there
# is clear separation between the joins before, during, and
# after the relationship. This information is needed later
# in order to properly resolve prefetch aliases (any alias
# with a relation_chain_depth less than the depth of the
# current prefetch is not considered)
#
# The increments happen twice per join. An even number means a
# relationship specified via a search_related, whereas an odd
# number indicates a join/prefetch added via attributes
#
# Also this code will wrap the current resultset (the one we
# chain to) in a subselect IFF it contains limiting attributes
sub _chain_relationship {
  my ($self, $rel) = @_;
  my $source = $self->result_source;
  my $attrs = { %{$self->{attrs}||{}} };

  # we need to take the prefetch the attrs into account before we
  # ->_resolve_join as otherwise they get lost - captainL
  my $join = $self->_merge_joinpref_attr( $attrs->{join}, $attrs->{prefetch} );

  delete @{$attrs}{qw/join prefetch collapse group_by distinct _grouped_by_distinct select as columns +select +as +columns/};

  my $seen = { %{ (delete $attrs->{seen_join}) || {} } };

  my $from;
  my @force_subq_attrs = qw/offset rows group_by having/;

  if (
    ($attrs->{from} && ref $attrs->{from} ne 'ARRAY')
      ||
    $self->_has_resolved_attr (@force_subq_attrs)
  ) {
    # Nuke the prefetch (if any) before the new $rs attrs
    # are resolved (prefetch is useless - we are wrapping
    # a subquery anyway).
    my $rs_copy = $self->search;
    $rs_copy->{attrs}{join} = $self->_merge_joinpref_attr (
      $rs_copy->{attrs}{join},
      delete $rs_copy->{attrs}{prefetch},
    );

    $from = [{
      -rsrc   => $source,
      -alias  => $attrs->{alias},
      $attrs->{alias} => $rs_copy->as_query,
    }];
    delete @{$attrs}{@force_subq_attrs, qw/where bind/};
    $seen->{-relation_chain_depth} = 0;
  }
  elsif ($attrs->{from}) {  #shallow copy suffices
    $from = [ @{$attrs->{from}} ];
  }
  else {
    $from = [{
      -rsrc  => $source,
      -alias => $attrs->{alias},
      $attrs->{alias} => $source->from,
    }];
  }

  my $jpath = ($seen->{-relation_chain_depth})
    ? $from->[-1][0]{-join_path}
    : [];

  my @requested_joins = $source->_resolve_join(
    $join,
    $attrs->{alias},
    $seen,
    $jpath,
  );

  push @$from, @requested_joins;

  $seen->{-relation_chain_depth}++;

  # if $self already had a join/prefetch specified on it, the requested
  # $rel might very well be already included. What we do in this case
  # is effectively a no-op (except that we bump up the chain_depth on
  # the join in question so we could tell it *is* the search_related)
  my $already_joined;

  # we consider the last one thus reverse
  for my $j (reverse @requested_joins) {
    my ($last_j) = keys %{$j->[0]{-join_path}[-1]};
    if ($rel eq $last_j) {
      $j->[0]{-relation_chain_depth}++;
      $already_joined++;
      last;
    }
  }

  unless ($already_joined) {
    push @$from, $source->_resolve_join(
      $rel,
      $attrs->{alias},
      $seen,
      $jpath,
    );
  }

  $seen->{-relation_chain_depth}++;

  return {%$attrs, from => $from, seen_join => $seen};
}

sub _resolved_attrs {
  my $self = shift;
  return $self->{_attrs} if $self->{_attrs};

  my $attrs  = { %{ $self->{attrs} || {} } };
  my $source = $attrs->{result_source} = $self->result_source;
  my $alias  = $attrs->{alias};

  $self->throw_exception("Specifying distinct => 1 in conjunction with collapse => 1 is unsupported")
    if $attrs->{collapse} and $attrs->{distinct};

  # The engine behind the remove_columns attribute and its shortcut method:
  # turn "everything except these" into an explicit column list.
  # Deliberately lazy and resolved here rather than eagerly in the shortcut, so
  # that an explicit columns/select from anywhere in the chain always wins over
  # a remove_columns. Guard as upstream: it falls through untouched whenever
  # remove_columns is not in play.
  if (!$attrs->{columns} && !$attrs->{select} && $attrs->{remove_columns}) {
    my %rc = map { $_ => 1 } @{$attrs->{remove_columns}};
    $attrs->{columns} = [ grep { !$rc{$_} } $source->columns ];
  }

  # default selection list
  $attrs->{columns} = [ $source->columns ]
    unless grep { exists $attrs->{$_} } qw/columns cols select as/;

  # merge selectors together
  for (qw/columns select as/) {
    $attrs->{$_} = $self->_merge_attr($attrs->{$_}, delete $attrs->{"+$_"})
      if $attrs->{$_} or $attrs->{"+$_"};
  }

  # disassemble columns
  my (@sel, @as);
  if (my $cols = delete $attrs->{columns}) {
    for my $c (ref $cols eq 'ARRAY' ? @$cols : $cols) {
      if (ref $c eq 'HASH') {
        for my $as (sort keys %$c) {
          push @sel, $c->{$as};
          push @as, $as;
        }
      }
      else {
        push @sel, $c;
        push @as, $c;
      }
    }
  }

  # when trying to weed off duplicates later do not go past this point -
  # everything added from here on is unbalanced "anyone's guess" stuff
  my $dedup_stop_idx = $#as;

  push @as, @{ ref $attrs->{as} eq 'ARRAY' ? $attrs->{as} : [ $attrs->{as} ] }
    if $attrs->{as};
  push @sel, @{ ref $attrs->{select} eq 'ARRAY' ? $attrs->{select} : [ $attrs->{select} ] }
    if $attrs->{select};

  # assume all unqualified selectors to apply to the current alias (legacy stuff)
  $_ = (ref $_ or $_ =~ /\./) ? $_ : "$alias.$_" for @sel;

  # disqualify all $alias.col as-bits (inflate-map mandated)
  $_ = ($_ =~ /^\Q$alias.\E(.+)$/) ? $1 : $_ for @as;

  # de-duplicate the result (remove *identical* select/as pairs)
  # and also die on duplicate {as} pointing to different {select}s
  # not using a c-style for as the condition is prone to shrinkage
  my $seen;
  my $i = 0;
  while ($i <= $dedup_stop_idx) {
    if ($seen->{"$sel[$i] \x00\x00 $as[$i]"}++) {
      splice @sel, $i, 1;
      splice @as, $i, 1;
      $dedup_stop_idx--;
    }
    elsif ($seen->{$as[$i]}++) {
      $self->throw_exception(
        "inflate_result() alias '$as[$i]' specified twice with different SQL-side {select}-ors"
      );
    }
    else {
      $i++;
    }
  }

  $attrs->{select} = \@sel;
  $attrs->{as} = \@as;

  $attrs->{from} ||= [{
    -rsrc   => $source,
    -alias  => $self->{attrs}{alias},
    $self->{attrs}{alias} => $source->from,
  }];

  # Auto-discover joins from WHERE/HAVING condition keys that reference
  # relationships (e.g. 'artist.name' implies join => 'artist').
  # Skip if from is already custom (joins were resolved by a prior
  # _resolved_attrs call, e.g. count internals building a new RS from
  # already-resolved attrs), or if FROM is a subquery (as_subselect_rs).
  if (
    ! $attrs->{_auto_joins_done}
      and
    ref $attrs->{from} eq 'ARRAY'
      and
    @{ $attrs->{from} } == 1  # only the base table, no joins resolved yet
      and
    ref( $attrs->{from}[0]{ $attrs->{from}[0]{'-alias'} || $alias } ) ne 'REF'  # not a subquery
  ) {
    if ( my $auto_joins = $self->_extract_condition_rels(
      [ $attrs->{where}, $attrs->{having} ], $source, $alias
    )) {
      # Only add auto-discovered joins that are not already in join/prefetch
      # to preserve the user's explicit join ordering
      if (defined $attrs->{join} || defined $attrs->{prefetch}) {
        my %existing = map { $_ => 1 } $self->_flatten_join_attr($attrs->{join});
        %existing = (%existing, map { $_ => 1 } $self->_flatten_join_attr($attrs->{prefetch}));
        my @novel;
        for my $j ($self->_flatten_join_attr($auto_joins)) {
          push @novel, $j unless $existing{$j};
        }
        if (@novel) {
          my $novel_joins = @novel == 1 ? $novel[0] : \@novel;
          $attrs->{join} = defined $attrs->{join}
            ? $self->_merge_joinpref_attr( $attrs->{join}, $novel_joins )
            : $novel_joins;
        }
      }
      else {
        $attrs->{join} = $auto_joins;
      }
    }
    $attrs->{_auto_joins_done} = 1;
  }

  if ( $attrs->{join} || $attrs->{prefetch} ) {

    $self->throw_exception ('join/prefetch can not be used with a custom {from}')
      if ref $attrs->{from} ne 'ARRAY';

    my $join = (delete $attrs->{join}) || {};

    if ( defined $attrs->{prefetch} ) {
      $join = $self->_merge_joinpref_attr( $join, $attrs->{prefetch} );
    }

    $attrs->{from} =    # have to copy here to avoid corrupting the original
      [
        @{ $attrs->{from} },
        $source->_resolve_join(
          $join,
          $alias,
          { %{ $attrs->{seen_join} || {} } },
          ( $attrs->{seen_join} && keys %{$attrs->{seen_join}})
            ? $attrs->{from}[-1][0]{-join_path}
            : []
          ,
        )
      ];
  }

  for my $attr (qw(order_by group_by)) {

    if ( defined $attrs->{$attr} ) {
      $attrs->{$attr} = (
        ref( $attrs->{$attr} ) eq 'ARRAY'
        ? [ @{ $attrs->{$attr} } ]
        : [ $attrs->{$attr} || () ]
      );

      delete $attrs->{$attr} unless @{$attrs->{$attr}};
    }
  }

  # generate selections based on the prefetch helper
  my ($prefetch, @prefetch_select, @prefetch_as);
  $prefetch = $self->_merge_joinpref_attr( {}, delete $attrs->{prefetch} )
    if defined $attrs->{prefetch};

  if ($prefetch) {

    $self->throw_exception("Unable to prefetch, resultset contains an unnamed selector $attrs->{_dark_selector}{string}")
      if $attrs->{_dark_selector};

    $self->throw_exception("Specifying prefetch in conjunction with an explicit collapse => 0 is unsupported")
      if defined $attrs->{collapse} and ! $attrs->{collapse};

    $attrs->{collapse} = 1;

    # this is a separate structure (we don't look in {from} directly)
    # as the resolver needs to shift things off the lists to work
    # properly (identical-prefetches on different branches)
    my $join_map = {};
    if (ref $attrs->{from} eq 'ARRAY') {

      my $start_depth = $attrs->{seen_join}{-relation_chain_depth} || 0;

      for my $j ( @{$attrs->{from}}[1 .. $#{$attrs->{from}} ] ) {
        next unless $j->[0]{-alias};
        next unless $j->[0]{-join_path};
        next if ($j->[0]{-relation_chain_depth} || 0) < $start_depth;

        my @jpath = map { keys %$_ } @{$j->[0]{-join_path}};

        my $p = $join_map;
        $p = $p->{$_} ||= {} for @jpath[ ($start_depth/2) .. $#jpath]; #only even depths are actual jpath boundaries
        push @{$p->{-join_aliases} }, $j->[0]{-alias};
      }
    }

    my @prefetch = $source->_resolve_prefetch( $prefetch, $alias, $join_map );

    # save these for after distinct resolution
    @prefetch_select = map { $_->[0] } @prefetch;
    @prefetch_as = map { $_->[1] } @prefetch;
  }

  # run through the resulting joinstructure (starting from our current slot)
  # and unset collapse if proven unnecessary
  #
  # also while we are at it find out if the current root source has
  # been premultiplied by previous related_source chaining
  #
  # this allows to predict whether a root object with all other relation
  # data set to NULL is in fact unique
  if ($attrs->{collapse}) {

    if (ref $attrs->{from} eq 'ARRAY') {

      if (@{$attrs->{from}} == 1) {
        # no joins - no collapse
        $attrs->{collapse} = 0;
      }
      else {
        # find where our table-spec starts
        my @fromlist = @{$attrs->{from}};
        while (@fromlist) {
          my $t = shift @fromlist;

          my $is_multi;
          # me vs join from-spec distinction - a ref means non-root
          if (ref $t eq 'ARRAY') {
            $t = $t->[0];
            $is_multi ||= ! $t->{-is_single};
          }
          last if ($t->{-alias} && $t->{-alias} eq $alias);
          $attrs->{_main_source_premultiplied} ||= $is_multi;
        }

        # no non-singles remaining, nor any premultiplication - nothing to collapse
        if (
          ! $attrs->{_main_source_premultiplied}
            and
          ! grep { ! $_->[0]{-is_single} } @fromlist
        ) {
          $attrs->{collapse} = 0;
        }
      }
    }

    else {
      # if we can not analyze the from - err on the side of safety
      $attrs->{_main_source_premultiplied} = 1;
    }
  }

  # generate the distinct induced group_by before injecting the prefetched select/as parts
  if (delete $attrs->{distinct}) {
    if ($attrs->{group_by}) {
      carp_unique ("Useless use of distinct on a grouped resultset ('distinct' is ignored when a 'group_by' is present)");
    }
    else {
      $attrs->{_grouped_by_distinct} = 1;
      # distinct affects only the main selection part, not what prefetch may add below
      ($attrs->{group_by}, my $new_order) = $source->storage->_group_over_selection($attrs);

      # FIXME possibly ignore a rewritten order_by (may turn out to be an issue)
      # The thinking is: if we are collapsing the subquerying prefetch engine will
      # rip stuff apart for us anyway, and we do not want to have a potentially
      # function-converted external order_by
      # ( there is an explicit if ( collapse && _grouped_by_distinct ) check in QueryRewrite )
      $attrs->{order_by} = $new_order unless $attrs->{collapse};
    }
  }

  # inject prefetch-bound selection (if any)
  push @{$attrs->{select}}, @prefetch_select;
  push @{$attrs->{as}}, @prefetch_as;

  $attrs->{_simple_passthrough_construction} = !(
    $attrs->{collapse}
      or
    grep { $_ =~ /\./ } @{$attrs->{as}}
  );

  # if both page and offset are specified, produce a combined offset
  # even though it doesn't make much sense, this is what pre 081xx has
  # been doing
  if (my $page = delete $attrs->{page}) {
    $attrs->{offset} =
      ($attrs->{rows} * ($page - 1))
            +
      ($attrs->{offset} || 0)
    ;
  }

  return $self->{_attrs} = $attrs;
}

sub _rollout_attr {
  my ($self, $attr) = @_;

  if (ref $attr eq 'HASH') {
    return $self->_rollout_hash($attr);
  } elsif (ref $attr eq 'ARRAY') {
    return $self->_rollout_array($attr);
  } else {
    return [$attr];
  }
}

sub _rollout_array {
  my ($self, $attr) = @_;

  my @rolled_array;
  foreach my $element (@{$attr}) {
    if (ref $element eq 'HASH') {
      push( @rolled_array, @{ $self->_rollout_hash( $element ) } );
    } elsif (ref $element eq 'ARRAY') {
      #  XXX - should probably recurse here
      push( @rolled_array, @{$self->_rollout_array($element)} );
    } else {
      push( @rolled_array, $element );
    }
  }
  return \@rolled_array;
}

sub _rollout_hash {
  my ($self, $attr) = @_;

  my @rolled_array;
  foreach my $key (keys %{$attr}) {
    push( @rolled_array, { $key => $attr->{$key} } );
  }
  return \@rolled_array;
}

sub _calculate_score {
  my ($self, $a, $b) = @_;

  if (defined $a xor defined $b) {
    return 0;
  }
  elsif (not defined $a) {
    return 1;
  }

  if (ref $b eq 'HASH') {
    my ($b_key) = keys %{$b};
    $b_key = '' if ! defined $b_key;
    if (ref $a eq 'HASH') {
      my ($a_key) = keys %{$a};
      $a_key = '' if ! defined $a_key;
      if ($a_key eq $b_key) {
        return (1 + $self->_calculate_score( $a->{$a_key}, $b->{$b_key} ));
      } else {
        return 0;
      }
    } else {
      return ($a eq $b_key) ? 1 : 0;
    }
  } else {
    if (ref $a eq 'HASH') {
      my ($a_key) = keys %{$a};
      return ($b eq $a_key) ? 1 : 0;
    } else {
      return ($b eq $a) ? 1 : 0;
    }
  }
}

# Walk condition structures and extract relationship names referenced
# via dotted column notation (e.g. 'artist.name' -> 'artist').
# Supports nested relationships ('artist.producer.name') and builds
# the appropriate join structure ({ artist => 'producer' }).
# Returns undef if no auto-joins are needed.
sub _extract_condition_rels {
  my ($self, $conds, $source, $alias) = @_;

  my %rels;
  $self->_walk_condition_keys($_, $source, $alias, \%rels) for grep { defined } @$conds;

  return undef unless %rels;

  # Convert flat relationship hash into join structure
  # e.g. { artist => undef, 'cd.artist' => undef }
  # becomes [ 'artist', { cd => 'artist' } ]
  my @joins;
  for my $path (sort keys %rels) {
    my @parts = split /\./, $path;
    if (@parts == 1) {
      push @joins, $parts[0];
    } else {
      # Build nested: [a, b, c] -> { a => { b => 'c' } }
      my $leaf = pop @parts;
      my $node = $leaf;
      for my $part (reverse @parts) {
        $node = { $part => $node };
      }
      push @joins, $node;
    }
  }

  return @joins == 1 ? $joins[0] : \@joins;
}

sub _walk_condition_keys {
  my ($self, $cond, $source, $alias, $rels) = @_;

  return unless defined $cond;

  if (ref $cond eq 'HASH') {
    for my $key (keys %$cond) {
      if ($key =~ /^-(?:and|or|not|not_bool|bool)$/i) {
        $self->_walk_condition_keys($cond->{$key}, $source, $alias, $rels);
      }
      elsif ($key =~ /^-/) {
        # Other SQL::Abstract operators, skip
        next;
      }
      else {
        $self->_check_column_rel($key, $source, $alias, $rels, $cond->{$key});
        # Also walk into the value for nested conditions
        if (ref $cond->{$key} eq 'HASH' || ref $cond->{$key} eq 'ARRAY') {
          # Value-side hashrefs are operator conditions ({ '>' => 3 }), not column refs
          # No need to recurse into them
        }
      }
    }
  }
  elsif (ref $cond eq 'ARRAY') {
    # Array conditions: could be [ -and => cond1, cond2 ] or [ cond1, cond2 ]
    my @items = @$cond;
    for my $item (@items) {
      if (ref $item) {
        $self->_walk_condition_keys($item, $source, $alias, $rels);
      }
      # Skip scalar items like -and, -or
    }
  }
  # Literal SQL (SCALAR/REF) is intentionally NOT scanned for auto-discover.
  # Literal SQL may contain correlated sub-query references, function calls,
  # or other constructs where table.column patterns should not trigger joins.
  # Users writing literal SQL are responsible for declaring their own joins.
}

sub _flatten_join_attr {
  my ($self, $attr) = @_;
  return () unless defined $attr;
  if (!ref $attr) {
    return ($attr);
  }
  elsif (ref $attr eq 'ARRAY') {
    return map { $self->_flatten_join_attr($_) } @$attr;
  }
  elsif (ref $attr eq 'HASH') {
    return map { $_, $self->_flatten_join_attr($attr->{$_}) } keys %$attr;
  }
  return ();
}

sub _check_column_rel {
  my ($self, $key, $source, $alias, $rels, $value) = @_;

  # Only process dotted column names
  return unless $key =~ /\./;

  my @parts = split /\./, $key;

  # Skip if first part is the current table alias (e.g. 'me.column')
  return if $parts[0] eq $alias;

  # Skip auto-join when the value is a pure correlation reference
  # (-ident / literal SQL), not a filter value. A condition like
  #   'books.owner' => { -ident => 'owner.id' }
  # is an identifier-to-identifier comparison: it expresses a join/
  # correlation *condition*, not "filter the related table by a value".
  # Auto-joining it here would materialise a LOCAL "books" range table
  # inside a subquery and, by SQL lexical scoping, shadow an outer
  # correlated "books" alias -- silently de-correlating the subquery.
  # Matching upstream, such keys never auto-join; the user
  # declares the join explicitly via { join => ... } when an inner
  # traversal is actually intended. Auto-join stays active for genuine
  # filters ('artist.name' => 'McCrae'), see t/search/auto_join.t.
  return if $self->_cond_value_is_correlation($value);

  # Walk relationship chain to verify each part is a valid relationship
  my $cur_source = $source;
  my @rel_path;
  for my $i (0 .. $#parts - 1) {  # all parts except the last (which is the column)
    my $rel_name = $parts[$i];
    if ($cur_source->has_relationship($rel_name)) {
      push @rel_path, $rel_name;
      $cur_source = $cur_source->related_source($rel_name);
    } else {
      # Not a valid relationship chain, skip
      return;
    }
  }

  # Record the full relationship path
  $rels->{CORE::join('.', @rel_path)} = 1 if @rel_path;
}

# True when a condition RHS is a pure correlation/identifier reference
# rather than a filter value -- i.e. it carries an -ident anywhere, or is
# literal SQL (SCALAR/REF). Such a value means the dotted LHS is part of a
# join/correlation condition, so the LHS must NOT trigger an auto-join (it
# would shadow an outer correlated alias inside a subquery).
sub _cond_value_is_correlation {
  my ($self, $value) = @_;

  return 0 unless defined $value;

  my $r = ref $value;

  # Literal SQL: \'...' or \[ '...', @bind ]. Already never walked into for
  # join-discovery; an LHS compared against literal SQL is the user's own
  # correlation/expression, not a filter we should auto-join.
  return 1 if $r eq 'SCALAR' or $r eq 'REF';

  if ($r eq 'HASH') {
    for my $k (keys %$value) {
      return 1 if $k eq '-ident';
      # Operator wrappers: { '!=' => { -ident => ... } }, { '=' => \'...' }
      return 1 if $self->_cond_value_is_correlation($value->{$k});
    }
    return 0;
  }

  if ($r eq 'ARRAY') {
    # e.g. { '!=' => ['-and', { -ident => 'me.cdid' }, 23414] }: a single
    # -ident anywhere marks the whole comparison as a correlation condition.
    for my $el (@$value) {
      return 1 if ref $el and $self->_cond_value_is_correlation($el);
    }
    return 0;
  }

  return 0;
}

sub _merge_joinpref_attr {
  my ($self, $orig, $import) = @_;

  return $import unless defined($orig);
  return $orig unless defined($import);

  $orig = $self->_rollout_attr($orig);
  $import = $self->_rollout_attr($import);

  my $seen_keys;
  foreach my $import_element ( @{$import} ) {
    # find best candidate from $orig to merge $b_element into
    my $best_candidate = { position => undef, score => 0 }; my $position = 0;
    foreach my $orig_element ( @{$orig} ) {
      my $score = $self->_calculate_score( $orig_element, $import_element );
      if ($score > $best_candidate->{score}) {
        $best_candidate->{position} = $position;
        $best_candidate->{score} = $score;
      }
      $position++;
    }
    my ($import_key) = ( ref $import_element eq 'HASH' ) ? keys %{$import_element} : ($import_element);
    $import_key = '' if not defined $import_key;

    if ($best_candidate->{score} == 0 || exists $seen_keys->{$import_key}) {
      push( @{$orig}, $import_element );
    } else {
      my $orig_best = $orig->[$best_candidate->{position}];
      # merge orig_best and b_element together and replace original with merged
      if (ref $orig_best ne 'HASH') {
        $orig->[$best_candidate->{position}] = $import_element;
      } elsif (ref $import_element eq 'HASH') {
        my ($key) = keys %{$orig_best};
        $orig->[$best_candidate->{position}] = { $key => $self->_merge_joinpref_attr($orig_best->{$key}, $import_element->{$key}) };
      }
    }
    $seen_keys->{$import_key} = 1; # don't merge the same key twice
  }

  return @$orig ? $orig : ();
}

{
  my $hm;

  sub _merge_attr {
    $hm ||= do {
      my $hm = Hash::Merge->new;

      $hm->specify_behavior({
        SCALAR => {
          SCALAR => sub {
            my ($defl, $defr) = map { defined $_ } (@_[0,1]);

            if ($defl xor $defr) {
              return [ $defl ? $_[0] : $_[1] ];
            }
            elsif (! $defl) {
              return [];
            }
            elsif (__HM_DEDUP and $_[0] eq $_[1]) {
              return [ $_[0] ];
            }
            else {
              return [$_[0], $_[1]];
            }
          },
          ARRAY => sub {
            return $_[1] if !defined $_[0];
            return $_[1] if __HM_DEDUP and grep { $_ eq $_[0] } @{$_[1]};
            return [$_[0], @{$_[1]}]
          },
          HASH  => sub {
            return [] if !defined $_[0] and !keys %{$_[1]};
            return [ $_[1] ] if !defined $_[0];
            return [ $_[0] ] if !keys %{$_[1]};
            return [$_[0], $_[1]]
          },
        },
        ARRAY => {
          SCALAR => sub {
            return $_[0] if !defined $_[1];
            return $_[0] if __HM_DEDUP and grep { $_ eq $_[1] } @{$_[0]};
            return [@{$_[0]}, $_[1]]
          },
          ARRAY => sub {
            my @ret = @{$_[0]} or return $_[1];
            return [ @ret, @{$_[1]} ] unless __HM_DEDUP;
            my %idx = map { $_ => 1 } @ret;
            push @ret, grep { ! defined $idx{$_} } (@{$_[1]});
            \@ret;
          },
          HASH => sub {
            return [ $_[1] ] if ! @{$_[0]};
            return $_[0] if !keys %{$_[1]};
            return $_[0] if __HM_DEDUP and grep { $_ eq $_[1] } @{$_[0]};
            return [ @{$_[0]}, $_[1] ];
          },
        },
        HASH => {
          SCALAR => sub {
            return [] if !keys %{$_[0]} and !defined $_[1];
            return [ $_[0] ] if !defined $_[1];
            return [ $_[1] ] if !keys %{$_[0]};
            return [$_[0], $_[1]]
          },
          ARRAY => sub {
            return [] if !keys %{$_[0]} and !@{$_[1]};
            return [ $_[0] ] if !@{$_[1]};
            return $_[1] if !keys %{$_[0]};
            return $_[1] if __HM_DEDUP and grep { $_ eq $_[0] } @{$_[1]};
            return [ $_[0], @{$_[1]} ];
          },
          HASH => sub {
            return [] if !keys %{$_[0]} and !keys %{$_[1]};
            return [ $_[0] ] if !keys %{$_[1]};
            return [ $_[1] ] if !keys %{$_[0]};
            return [ $_[0] ] if $_[0] eq $_[1];
            return [ $_[0], $_[1] ];
          },
        }
      } => 'DBIO_RS_ATTR_MERGER');
      $hm;
    };

    return $hm->merge ($_[1], $_[2]);
  }
}

sub STORABLE_freeze {
  my ($self, $cloning) = @_;
  my $to_serialize = { %$self };

  # A cursor in progress can't be serialized (and would make little sense anyway)
  # the parser can be regenerated (and can't be serialized)
  # an async context is a live object (a storage or a transaction
  # connection), meaningless after thaw: a frozen resultset is unbound
  delete @{$to_serialize}{qw/cursor _row_parser _result_inflator _async_context/};

  # nor is it sensical to store a not-yet-fired-count pager
  if ($to_serialize->{pager} and ref $to_serialize->{pager}{total_entries} eq 'CODE') {
    delete $to_serialize->{pager};
  }

  Storable::nfreeze($to_serialize);
}


sub STORABLE_thaw {
  my ($self, $cloning, $serialized) = @_;

  %$self = %{ Storable::thaw($serialized) };

  $self;
}



sub throw_exception {
  my $self=shift;

  if (ref $self and my $rsrc = $self->result_source) {
    $rsrc->throw_exception(@_)
  }
  else {
    DBIO::Exception->throw(@_);
  }
}

# ============================================================
# Integrated helper methods (from DBIx::Class::Helpers by FREW)
# These are available natively without load_components.
# ============================================================


sub me { CORE::join('.', $_[0]->current_source_alias, $_[1] || q{}) }


sub order_by {
  my ($self, @order) = @_;

  # Belt and braces, no longer load bearing: since every top level ref is
  # handed to SQL::Abstract untouched anyway, this produces the same SQL as
  # the parser below - it only keeps the attribute value bit-for-bit identical
  # (the ref itself, not a list holding it) for the documented single ref call.
  return $self->search_rs(undef, { order_by => $order[0] })
    if @order == 1 && ref $order[0];

  return $self->search_rs(undef, {
    order_by => [ $self->_order_by_clauses(\@order) ],
  });
}

# Turns a flat order_by() argument list into an ordered list of ORDER BY
# clauses, preserving the argument order. See the order_by POD for the forms.
sub _order_by_clauses {
  my ($self, $args) = @_;

  my @queue = @$args;
  my @clauses;

  while (@queue) {
    my $item = shift @queue;

    if (ref $item eq 'ARRAY') {
      # A ref is native SQL::Abstract - we stay out of it. The list is only
      # flattened so that following arguments append after it; the elements
      # themselves are taken over verbatim and never parsed.
      push @clauses, @$item;
    }
    elsif (ref $item) {
      # hashrefs and literals (\'sql', \['sql', @bind]) pass through untouched
      push @clauses, $item;
    }
    elsif (defined $item and $item =~ /^-(asc|desc)$/i) {
      $self->throw_exception(
        "Missing value after '$item' in order_by()"
      ) unless @queue and defined $queue[0];
      push @clauses, $self->_order_by_direction_clauses(lc $1, shift @queue);
    }
    else {
      push @clauses, $self->_order_by_magic_clauses($item);
    }
  }

  return @clauses;
}

# The value side of a flat '-asc'/'-desc' pair
sub _order_by_direction_clauses {
  my ($self, $dir, $value) = @_;

  return map { $self->_order_by_direction_clauses($dir, $_) } @$value
    if ref $value eq 'ARRAY';

  # anything else that is a ref goes to the direction untouched
  return { "-$dir" => $value } if ref $value;

  return map { +{ "-$dir" => $self->_order_by_qualify($_) } }
    split(/\s*,\s*/, $value);
}

# The FREW magic string syntax: '!' prefix means DESC, commas split columns
sub _order_by_magic_clauses {
  my ($self, $spec) = @_;

  my @clauses;
  for my $col (split(/\s*,\s*/, $spec)) {
    my $dir = 'asc';
    if (substr($col, 0, 1) eq '!') {
      $col = substr($col, 1);
      $dir = 'desc';
    }
    push @clauses, { "-$dir" => $self->_order_by_qualify($col) };
  }
  return @clauses;
}

sub _order_by_qualify {
  my ($self, $col) = @_;

  return $col if index($col, '.') != -1;
  return CORE::join('.', $self->current_source_alias, $col);
}


sub columns { $_[0]->search_rs(undef, { columns => $_[1] }) }


sub add_columns {
  return $_[0]->search_rs(undef, { '+columns' => $_[1] });
}


sub remove_columns {
  return $_[0]->search_rs(undef, { remove_columns => $_[1] });
}


sub distinct { $_[0]->search_rs(undef, { distinct => defined $_[1] ? $_[1] : 1 }) }


sub group_by { $_[0]->search_rs(undef, { group_by => $_[1] }) }


sub where {
  my $self = shift;

  # no args: return a clone without touching the condition
  return $self->search_rs if !@_;

  # a single ref is a full condition structure, passed through verbatim
  return $self->search_rs($_[0]) if @_ == 1 && ref $_[0];

  $self->throw_exception('Odd number of elements in where() condition')
    if @_ % 2;

  for my $i (0 .. $#_) {
    next if $i % 2;
    $self->throw_exception('All keys in condition key/value pairs must be plain scalars')
      if (! defined $_[$i] or ref $_[$i] ne '');
  }

  return $self->search_rs({ @_ });
}


sub having {
  my $self = shift;

  return $self->search_rs if !@_;

  return $self->search_rs(undef, { having => $_[0] }) if @_ == 1 && ref $_[0];

  $self->throw_exception('Odd number of elements in having() condition')
    if @_ % 2;

  for my $i (0 .. $#_) {
    next if $i % 2;
    $self->throw_exception('All keys in condition key/value pairs must be plain scalars')
      if (! defined $_[$i] or ref $_[$i] ne '');
  }

  return $self->search_rs(undef, { having => { @_ } });
}


sub offset { $_[0]->search_rs(undef, { offset => $_[1] }) }


sub join { $_[0]->search_rs(undef, { join => $_[1] }) }


sub select {
  my $self = shift;

  # no args: return a clone without touching the projection
  return $self->search_rs if !@_;

  my $sel = $_[0];
  my $as  = $_[1];

  return $self->search_rs(undef, {
    select => $sel,
    (defined $as ? (as => $as) : ()),
  });
}


sub as {
  my ($self, $as) = @_;

  my $sel = $self->{attrs}{select}
    or $self->throw_exception(
      'as() needs a preceding select() - chain ->select(\@cols)->as(\@aliases), '
      . 'or pass both at once: ->select(\@cols, \@aliases)'
    );

  return $self->search_rs(undef, { select => $sel, as => $as });
}


sub hri {
  $_[0]->search_rs(undef, {
    result_class => 'DBIO::ResultClass::HashRefInflator'
  })
}


sub rows { $_[0]->search_rs(undef, { rows => $_[1] }) }


sub limit { $_[0]->rows($_[1]) }


sub has_rows { !! $_[0]->rows(1)->next }


sub limited_page {
  my $self = shift;
  if (@_ == 1) {
    my $arg = shift;
    if (ref $arg) {
      return $self->page($arg->{page})->rows($arg->{rows});
    }
    return $self->page($arg);
  }
  elsif (@_ == 2) {
    return $self->page($_[0])->rows($_[1]);
  }
  $self->throw_exception('Invalid args passed to limited_page');
}


sub prefetch { $_[0]->search_rs(undef, { prefetch => @_ > 2 ? [@_[1..$#_]] : $_[1] }) }


sub null {
  my ($self, @columns) = @_;
  return $self->_helper_apply_search(undef, @columns);
}


sub not_null {
  my ($self, @columns) = @_;
  return $self->_helper_apply_search({ '!=' => undef }, @columns);
}


sub like {
  my ($self, $columns, $cond) = @_;
  $self->throw_exception(
    'like() expects a column name or an ARRAY reference of column names'
  ) if ref $columns and ref $columns ne 'ARRAY';
  return $self->_helper_apply_search({ -like => $cond }, $columns);
}


sub not_like {
  my ($self, $columns, $cond) = @_;
  $self->throw_exception(
    'not_like() expects a column name or an ARRAY reference of column names'
  ) if ref $columns and ref $columns ne 'ARRAY';
  return $self->_helper_apply_search({ -not_like => $cond }, $columns);
}

# Shared plumbing for null/not_null/like/not_like: unwrap an optional arrayref
# of columns and chain one search() per column. Stays wordless - the public
# method above is the one that validates its arguments and throws.
sub _helper_apply_search {
  my ($self, $cond, @columns) = @_;

  @columns = @{ $columns[0] } if @columns == 1 && ref $columns[0] eq 'ARRAY';

  my $rs = $self;
  $rs = $rs->search_rs({ $self->_helper_meify($_) => $cond }) for @columns;
  return $rs;
}

# A leading '.' means "qualify me with this ResultSet's source alias", so that
# '.title' becomes 'me.title' and stays unambiguous once a join is in play.
sub _helper_meify {
  my ($self, $column) = @_;

  return $self->current_source_alias . $column if $column =~ m/^\./;
  return $column;
}


sub results_exist {
  my ($self, $cond) = @_;

  my $storage = $self->result_source->schema->storage;
  my ($sql, @bind)
    = $self->_results_exist_statement($storage, 'results_exist', $cond);

  my (undef, $sth) = $storage->_execute_rendered($sql, \@bind);

  my $row = $sth->fetchall_arrayref->[0];
  return ($row && $row->[0]) ? 1 : 0;
}


sub results_exist_async {
  my ($self, $cond) = @_;

  my $storage = $self->result_source->schema->storage;
  my ($sql, @bind)
    = $self->_results_exist_statement($storage, 'results_exist_async', $cond);

  return $self->_rs_run_async('results_exist',
    sub {
      my ($backend, $fc) = @_;

      # The binds of the statement are as_query's, pairs [ \%attrs => $value ].
      # A transport's runner takes bare values (DBIO::Storage::Async::_query_async,
      # karr k342), so a context or backend that is not a sync storage gets them
      # unpacked. The immediate mode runs the statement on the sync storage itself,
      # which takes pairs and keeps their column attributes: left as they are.
      my @run_bind = $backend->isa('DBIO::Storage::DBI') ? @bind : bare_binds(@bind);

      return $backend->_query_async($sql, \@run_bind)->then(sub {
        my ($raw_row) = @_;
        return ($raw_row && $raw_row->[0]) ? 1 : 0;
      });
    },
    sub { $self->results_exist($cond) },
  );
}


sub results_exist_as_query {
  my ($self, $cond) = @_;

  my $storage = $self->result_source->schema->storage;
  my ($sql, @bind)
    = $self->_results_exist_statement($storage, 'results_exist_as_query', $cond);

  return \[ "( $sql )", @bind ];
}

# The complete 1/0 statement all three results_exist* methods run on, plus its
# binds. Core builds the inner subquery and hands it to the storage, which
# renders the whole fragment (ADR 0037 section 2) -- core adds nothing to what
# comes back, and holds no dummy-table knowledge.
sub _results_exist_statement {
  my ($self, $storage, $method, $cond) = @_;

  $self->_assert_exists_query_supported($storage, $method);

  my $reified = $self->search_rs($cond, {
    columns => { _results_existence_check => \ '42' }
  })->as_query;

  my ($inner_sql, @bind) = @{$$reified};

  return ($storage->_exists_value_sql($inner_sql), @bind);
}

# No capability, no EXISTS query -- and never a silent degrade to has_rows:
# the caller asked for the cheap server-side check and would get a different
# query shape without being told, which is the over-promise ADR 0036 refused
# for upsert. Rejecting the *silent* fallback is not rejecting the
# alternative, so the message names it, together with the branch that picks
# it. Thrown before any SQL is built or executed.
sub _assert_exists_query_supported {
  my ($self, $storage, $method) = @_;

  return 1
    if $storage->can('_use_supports_exists_query')
       and $storage->_use_supports_exists_query;

  $self->throw_exception(
    "$method(): " . ref($storage) . ' does not declare the '
  . 'supports_exists_query capability -- this engine\'s driver has not '
  . 'declared that it can render a boolean-valued EXISTS query. Use '
  . '$rs->has_rows, which is portable and works everywhere, or branch on the '
  . 'capability: '
  . '$storage->_use_supports_exists_query ? $rs->results_exist : $rs->has_rows'
  );
}


sub correlate {
  my ($self, $rel) = @_;

  my $source = $self->result_source;

  my $fresh_rs = $source->related_source($rel)->resultset;

  # ADR 0045 / karr k281: correlated to a context-bound resultset, it keeps the
  # pin (the ->search_rs below propagates it onto the returned clone).
  $fresh_rs->{_async_context} = $self->{_async_context} if $self->{_async_context};

  return $fresh_rs
    ->search_rs(
      $source->_resolve_relationship_condition(
        rel_name      => $rel,
        foreign_alias => "${rel}_alias",
        self_alias    => $self->current_source_alias,
      )->{condition},
      { alias => "${rel}_alias" }
    );
}


sub search_or {
  my $self = shift;
  my @others = @{shift @_};

  $self->throw_exception(
    'All ResultSets passed to search_or must have the same result_source'
  ) if grep { $self->result_source != $_->result_source } @others;

  $self->search_rs({
    -or => [ map $_->_resolved_attrs->{where}, @others ],
  });
}


# The canonical operation name IS the method name. It goes to the storage
# rather than a keyword, so there is exactly one call site asking (ADR 0039)
# and the driver can refuse an operation as well as spell it. The old
# driver-name comparison this replaced -- sqlt_type eq 'Oracle' -- reached
# $dbh->{Driver}{Name} through _get_dbh, so it opened a database connection at
# query-build time, on every call, purely to choose a word.
sub union         { $_[0]->_set_operation('union'         => $_[1]) }
sub union_all     { $_[0]->_set_operation('union_all'     => $_[1]) }
sub intersect     { $_[0]->_set_operation('intersect'     => $_[1]) }
sub intersect_all { $_[0]->_set_operation('intersect_all' => $_[1]) }

sub except        { $_[0]->_set_operation('except'        => $_[1]) }
sub except_all    { $_[0]->_set_operation('except_all'    => $_[1]) }

# cribbed from perlfaq4
sub _compare_arrays {
  my ($self, $first, $second) = @_;

  no warnings; # silence spurious -w undef complaints
  return 0 unless @$first == @$second;
  for (my $i = 0; $i < @$first; $i++) {
    return 0 if $first->[$i] ne $second->[$i];
  }
  return 1;
}

sub _set_operation {
  my ($self, $op, $other) = @_;

  my @operands = ($self, ref $other eq 'ARRAY' ? @$other : $other);

  # ADR 0045 / karr k324: the operands must be bound alike -- all unbound, or
  # all to the one context (identity). Asked first of all, before the engine
  # and before any operand is rendered, so the refusal depends on nothing the
  # driver answers and leaves nothing behind.
  {
    my @bound = map { $_->_async_context } @operands;
    my $key   = sub { defined $_[0] ? Scalar::Util::refaddr($_[0]) : '' };
    my $own   = $key->($bound[0]);
    my @odd   = grep { $key->($bound[$_]) ne $own } 1 .. $#bound;

    if (@odd) {
      my $says = sub {
        defined $bound[$_[0]] ? "bound to $bound[$_[0]]" : 'unbound';
      };
      $self->throw_exception(
        "$op: the operands of a set operation must be bound alike, all "
      . 'unbound or all to the same async context -- operand 0 (the caller) is '
      . CORE::join(', ', $says->(0), map { "operand $_ is " . $says->($_) } @odd)
      );
    }
  }

  # Then, before a single operand is rendered: the engine either spells this
  # operation or refuses it (ADR 0039). Doing it here rather than after the
  # loop is the contract, not an accident -- a refusing engine must throw at
  # query-build time and never produce a fragment that could end up embedded
  # in a larger query.
  my $operation = $self->result_source->schema->storage
    ->_set_operation_keyword($op);

  my @sql;
  my @params;
  my $as = $self->_resolved_attrs->{as};

  for (@operands) {
    $self->throw_exception('ResultClass of ResultSets do not match!')
      unless $self->result_class eq $_->result_class;

    my $attrs = $_->_resolved_attrs;

    $self->throw_exception('ResultSets do not all have the same selected columns!')
      unless $self->_compare_arrays($as, $attrs->{as});

    my ($sql, @bind) = @{${$_->as_query}};
    $sql =~ s/^\s*\((.*)\)\s*$/$1/;

    push @sql, $sql;
    push @params, @bind;
  }

  my $query = q<(> . CORE::join(" $operation ", @sql) . q<)>;
  my $attrs = $self->_resolved_attrs;

  my $fresh_rs = $self->result_source->resultset;

  # ADR 0045 / karr k281: the result takes the binding of the operands, which
  # are all bound alike (karr k324, checked above); the ->search_rs below
  # propagates it onto the returned clone.
  $fresh_rs->{_async_context} = $self->{_async_context} if $self->{_async_context};

  return $fresh_rs->search_rs(undef, {
    alias => $self->current_source_alias,
    from => [{
      $self->current_source_alias => \[ $query, @params ],
      -alias                      => $self->current_source_alias,
      -rsrc                       => $self->result_source,
    }],
    columns      => $attrs->{as},
    result_class => $self->result_class,
  });
}


# --- one_row: safe alternative to first() that exhausts cursor ---
sub one_row {
  my $self = shift;
  $self->search_rs(shift, { rows => 1 })->next;
}


# --- no_columns: clear column selection for custom projections ---
sub no_columns { $_[0]->search_rs(undef, { columns => [] }) }


# --- bare: get unsearched ResultSet from a searched one ---
sub bare {
  my $self = shift;
  my $fresh_rs = $self->result_source->resultset;
  # ADR 0045 / karr k281: the search conditions and attributes go, the pin of a
  # context-bound resultset stays -- it is neither.
  $fresh_rs->{_async_context} = $self->{_async_context} if $self->{_async_context};
  return $fresh_rs;
}


# --- rand: get random rows ---
sub rand {
  my $self   = shift;
  my $amount = @_ ? shift : 1;
  $self->throw_exception('rand can only return a positive amount of rows')
    unless $amount > 0;
  $self->throw_exception('rand can only return an integer amount of rows')
    unless $amount == int $amount;
  my $rand_func = $self->result_source->storage->_random_function;
  $self->search_rs(undef, { rows => $amount, order_by => \$rand_func });
}


# --- explain: get query plan for debugging ---
sub explain {
  my $self = shift;
  my $storage = $self->result_source->storage;
  my ($sql, @bind) = @{${$self->as_query}};
  # as_query parenthesises its output for use as a subquery; EXPLAIN wants the
  # statement. Stripped for every engine, not only SQLite (upstream's Helper
  # did it in the SQLite branch of a DBIx::Introspector dispatch).
  $sql =~ s/^\s*\((.*)\)\s*$/$1/s;

  # ADR 0040: the storage owns the WHOLE operation, not just the
  # spelling. Half this family cannot obtain a plan with one statement --
  # Oracle's EXPLAIN PLAN FOR returns no rows and needs a second query, SQL
  # Server drives it through a session setting across three round-trips,
  # Firebird reads it off the prepared statement -- so there is nothing left
  # here to compose. (Sybase ASE cannot be served at all: its plan arrives as
  # server messages rather than rows. ADR 0040 section 7.) The bind pairs
  # travel as they come:
  # [ \%attrs, $value ] is the native format of the statement path.
  #
  # What that path buys is listed here, and _explain_query's contract requires
  # every driver override to keep it: tracing and therefore redact_bind_value,
  # dbh_do retry, NoBindVars interpolation, and the read handler rather than
  # the master's handle on a replicated storage.
  return $storage->_explain_query($sql, \@bind);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ResultSet - Lazy query object for fetching and manipulating DBIO rows

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

  my $users_rs = $schema->resultset('User');
  while( $user = $users_rs->next) {
    print $user->username;
  }

  my $registered_users_rs = $schema->resultset('User')->search({ registered => 1 });
  my @cds_in_2005 = $schema->resultset('CD')->search({ year => 2005 })->all();

  # Async: same query, non-blocking on a connection with an async mode chosen
  # (see L</ASYNC> below)
  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'future_io' });
  $schema->resultset('CD')->search({ year => 2005 })->all_async->then(sub {
    my @cds_in_2005 = @_;
    ...
  });

See F<t/resultset/as_query.t> for a runnable example.

=head1 DESCRIPTION

A ResultSet stores the conditions and attributes that make up a query. It is
the central query object in DBIO and the main way rows are searched, updated,
deleted, joined, paged, and prefetched.

Creating a ResultSet does not execute SQL. It only stores the information
needed to build the eventual query.

A basic ResultSet representing the data of an entire table is returned
by calling C<resultset> on a L<DBIO::Schema> and passing in a
L<Source|DBIO::Manual::Glossary/ResultSource> name.

  my $users_rs = $schema->resultset('User');

A new ResultSet is returned from calling L</search> on an existing
ResultSet. The new one will contain all the conditions of the
original, plus any new conditions added in the C<search> call.

ResultSets also act as iterators. L</next> and L</reset> let you walk through
the L<DBIO::Row> objects represented by the query.

The query is B<only> executed when you call methods such as:
L</find>, L</next>, L</all>, L</first>, L</single>, L</count>.

If a resultset is used in a numeric context it returns the L</count>.
However, if it is used in a boolean context it is B<always> true.  So if
you want to check if a resultset has any results, you must use C<if $rs
!= 0>.

=head1 METHODS

=head2 new

=over 4

=item Arguments: L<$source|DBIO::ResultSource>, L<\%attrs?|/ATTRIBUTES>

=item Return Value: L<$resultset|/search>

=back

The resultset constructor. Takes a source object (usually a
L<DBIO::ResultSourceProxy>) and an attribute hash (see
L</ATTRIBUTES> below).  Does not perform any queries -- these are
executed as needed by the other methods.

Generally you never construct a resultset manually. Instead you get one
from e.g. a
C<< $schema->L<resultset|DBIO::Schema/resultset>('$source_name') >>
or C<< $another_resultset->L<search|/search>(...) >>:

  my $rs = $schema->resultset('CD')->search({ title => '100th Window' });

=over

=item WARNING

If called on an object, proxies to L</new_result> instead, so

  my $cd = $schema->resultset('CD')->new({ title => 'Spoon' });

will return a CD object, not a ResultSet, and is equivalent to:

  my $cd = $schema->resultset('CD')->new_result({ title => 'Spoon' });

Please also keep in mind that many internals call L</new_result> directly,
so overloading this method with the idea of intercepting new result object
creation B<will not work>. See also warning pertaining to L</create>.

=back

=head2 search

=over 4

=item Arguments: L<$cond|DBIO::SQLMaker> | undef, L<\%attrs?|/ATTRIBUTES>

=item Return Value: L<$resultset|/search>

=back

  my $cds    = $cd_rs->search({ year => 2001 }); # "... WHERE year = 2001"
  my $new_rs = $cd_rs->search({ year => 2005 });

  my $new_rs = $cd_rs->search([ { year => 2005 }, { year => 2004 } ]);
                 # year = 2005 OR year = 2004

Search returns a L<DBIO::ResultSet> and throws in list context (ADR 0042);
called in void context from outside DBIO it throws as well. To get the
matching rows, call C<< ->all() >> on the result:

  my @cds = $cd_rs->search({ year => 2001 })->all;

Where the call may land in list context -- as a function argument, inside a
list constructor, as the last statement of a method -- use L</search_rs>, which
returns the resultset in every context.

If you need to pass in additional attributes but no additional condition,
call it as C<search(undef, \%attrs)>.

  # "SELECT name, artistid FROM $artist_table"
  my @all_artists = $schema->resultset('Artist')->search(undef, {
    columns => [qw/name artistid/],
  })->all;

For a list of attributes that can be passed to C<search>, see
L</ATTRIBUTES>. For more examples of using this function, see
L<Searching|DBIO::Manual::Cookbook/SEARCHING>. For a complete
documentation for the first argument, see
L<SQL::Abstract/"WHERE CLAUSES"> and its extension
L<DBIO::SQLMaker>.

For more help on using joins with search, see L<DBIO::Manual::Joining>.

=head3 Truth value of a condition

Every node of a condition is true, false or SQL, the same for SELECT, UPDATE
and DELETE:

=over 4

=item true

C<{}>, C<undef>, C<< -and => [] >>, C<< -and => {} >>, C<< -not_in => [] >>,
and an C<-and> group of nothing but true nodes. A true condition is no
restriction and renders no WHERE.

=item false

C<[]> as a whole condition, C<< -or => [] >>, C<< -in => [] >>, and an C<-or>
group of nothing but false nodes. A false condition renders as C<0=1>.

=back

In an C<-and> group a false member makes the group false and true members drop
out; in an C<-or> group a true member makes the group true and false members
drop out.

  $rs->search({ name => 'a', -or => [] });   # WHERE ( 0=1 )
  $rs->search({ name => 'a', -and => [] });  # WHERE ( name = 'a' )

L</update> and L</delete> refuse a resultset whose condition is true.

=head3 Untrusted input

The structure of a condition is code: its keys, its operators and its hashes
decide what the statement does. Only values come from a request.

  # keys and operator are written in the program, the value comes in
  $cd_rs->search({ year => { '>=' => $params->{year} } });

The same holds for every attribute (C<order_by>, C<columns>, C<having>,
C<result_class>, ...): it is written in the program. A condition whose
structure is not written in the program goes through L</search_untrusted>,
which accepts columns of the resultset as keys, scalars as values and a fixed
list of operators.

=head3 CAVEAT

Note that L</search> does not process/deflate any of the values passed in the
L<SQL::Abstract>-compatible search condition structure. This is unlike
other condition-bound methods L</new_result>, L</create> and L</find>. The user
must ensure manually that any value passed to this method will stringify to
something the RDBMS knows how to deal with. A notable example is the handling
of L<DateTime> objects, for more info see:
L<DBIO::Manual::Cookbook/Formatting DateTime objects in queries>.

=head2 search_rs

=over 4

=item Arguments: L<$cond|DBIO::SQLMaker>, L<\%attrs?|/ATTRIBUTES>

=item Return Value: L<$resultset|/search>

=back

This method does the same exact thing as search() except it will
always return a resultset, even in list context.

=head2 search_untrusted

=over 4

=item Arguments: \%cond | \@cond

=item Return Value: L<$resultset|/search>

=back

  my $rs = $cd_rs->search_untrusted($decoded_json_body);

Does what L</search> does for a condition whose structure does not come from
the program (see L</Untrusted input>). The condition is checked first and
handed to L</search> unchanged; the first form outside the following grammar
throws, naming the path of its key. The method takes exactly one argument, an
unblessed hash or array reference.

A B<condition node> is a hash reference (key to operand) or an array reference
of condition nodes (OR). C<-and> and C<-or> take an array or hash reference of
condition nodes. A scalar as an element of a condition, a blessed container
and a cycle throw.

A B<key> is a column of the source of the resultset, or C<alias.column> where
C<alias> is an alias of the resolved attributes (the resultset itself or one of
its joins) and the column belongs to the source of that alias.

An B<operand> is

=over 4

=item * a scalar (C<undef> included)

=item * an array reference of scalars (a list of values, an OR of equalities)

=item * a hash reference with exactly one operator of C<=>, C<!=>, C<< <> >>,
C<< < >>, C<< <= >>, C<< > >>, C<< >= >>, C<-like>, C<-not_like>, C<-in>,
C<-not_in>, C<-between>, C<-not_between>, C<-is> and C<-is_not>

=back

C<-in> and C<-not_in> take an array reference of scalars, C<-between> and
C<-not_between> an array reference of exactly two scalars, C<-is> and
C<-is_not> C<undef>, every other operator a scalar.

Everything else throws: C<-literal>, C<-func>, C<-op>, C<-ident>, C<-value>,
C<-bool>, C<-not>, and every reference as a value.

The attributes are not part of the method; they are written in the program
(see L</Untrusted input>).

=head2 with_context

=over 4

=item Arguments: $async_context

=item Return Value: L<$resultset|/search>

=back

  $schema->storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $rs->with_context($ctx)->all_async->then(sub { ... });
  });

Returns a clone of this resultset bound to a pinned async context -- the object
handed to the coderef of L<DBIO::Storage::Async/txn_do_async> or
L<DBIO::Storage::Async/pipeline>. Once bound, every C<*_async> method on the
clone (and on rows and L<DBIO::ResultSetColumn>s derived from it) routes its
storage read/write onto the context's pinned connection instead of taking a
fresh connection out of the pool. Inside a transaction that means the async
read actually runs I<inside> the transaction rather than on a sibling
connection that sees pre-C<BEGIN> state; inside a pipeline it means the
statement is batched onto the bracketed connection.

The binding is carried, not resolved: the resultset already knows its source
and schema, so C<with_context> only threads the context through -- it does not
reach back into storage for an ambient "current context" (there is none; an
async program may have two transactions in flight at once). The context
propagates across L</search> / L</search_rs> clones and is inherited by rows
(L</all_async>, L</first_async>, L</create_async>, ...) and column resultsets
(L</get_column>) produced from the bound resultset. The same pin follows these
derivations too (ADR 0045): L</page>, L</as_subselect_rs>,
L</related_resultset> / L</search_related> (and the generated relationship
accessors), every chaining shortcut built on L</search_rs>, prefetched
children, cache-served rows, and the row refetch/copy helpers. So do the
derivations that build a fresh resultset: L</bare>, L</correlate>,
L</count_rs> (the L<DBIO::ResultSetColumn> it returns) and the set operations
L</union>, L</union_all>, L</intersect>, L</intersect_all>, L</except> and
L</except_all>. A set operation needs its operands bound alike -- see there.

The rows are bound whichever C<inflate_result> built them, a result class's own
included; what L<DBIO::ResultClass::HashRefInflator> returns is
plain data and carries nothing. What a bound row or column resultset hands out
in turn stays bound as well -- see L<DBIO::Row/with_context> and
L<DBIO::ResultSetColumn/with_context>. The one exception: the related rows a
multi-create builds from nested data (L</new_result>, L</create>) are not
bound, only the row they are nested in is.

A context is only valid while its owning scope remains active. A L<pipeline
context|DBIO::Storage::Async::PipelineContext> stops accepting work the moment
its synchronous batch coderef returns. A transaction context remains active
while its callback Future is pending and ends as its C<COMMIT> or C<ROLLBACK>
goes out. A bound resultset used after either boundary throws rather than
silently falling back to the pool (ADR 0045). See L<DBIO::Manual::AsyncStorage>
for the full picture.

A transaction context keeps track of every statement issued on it, the ones a
bound resultset or row sends included. If one of them fails, the transaction is
rolled back and fails with that statement's error -- also when your code
catches the failure and carries on (L<DBIO::Storage::Async/txn_do_async>). A
caught failure does not rescue the transaction.

In the C<immediate> mode C<txn_do_async> hands its coderef the storage itself
(ADR 0055), and C<with_context> takes it, so the pattern above is the same in
every async mode. A resultset bound that way runs its C<*_async>
in-process, inside the transaction; a statement of it that fails rolls the
transaction back, awaited or not; what a bound resultset refuses on a real
backend it refuses there; and held past the transaction it is refused. A
storage is taken only as the context of its B<own> resultsets and only in the
C<immediate> mode.

Two things are particular to that mode. There is one connection and no pool,
so an unbound resultset runs inside the transaction too -- but its failed
statements are not the transaction's, only a bound one's are. And every
C<immediate> transaction on a storage has that one storage for its context:
a resultset bound in one transaction and used inside a B<later> one runs in
the later one, where a real backend refuses it.

=head2 search_literal

B<CAVEAT>: C<search_literal> is a legacy convenience method. It is equivalent
to calling C<< $rs->search(\[]) >>, but if you want to ensure columns are
bound correctly, use L</search>.

See L<DBIO::Manual::Cookbook/SEARCHING> and
L<DBIO::Manual::FAQ/Searching> for searching techniques that do not
require C<search_literal>.

=over 4

=item Arguments: $sql_fragment, @standalone_bind_values

=item Return Value: L<$resultset|/search>

=back

  my $cds   = $cd_rs->search_literal('year = ? AND title = ?', qw/2001 Reload/);
  my $newrs = $artist_rs->search_literal('name = ?', 'Metallica');

Pass a literal chunk of SQL to be added to the conditional part of the
resultset query. Returns a L<DBIO::ResultSet> and throws in list context
(ADR 0042).

Example of how to use C<search> instead of C<search_literal>

  my @cds = $cd_rs->search_literal('cdid = ? AND (artist = ? OR artist = ?)', (2, 1, 2))->all;
  my @cds = $cd_rs->search(\[ 'cdid = ? AND (artist = ? OR artist = ?)', [ 'cdid', 2 ], [ 'artist', 1 ], [ 'artist', 2 ] ])->all;

=head2 find

=over 4

=item Arguments: \%columns_values | @pk_values, { key => $unique_constraint, L<%attrs|/ATTRIBUTES> }?

=item Return Value: L<$result|DBIO::Manual::ResultClass> | undef

=back

Finds and returns a single row based on supplied criteria. Takes either a
hashref with the same format as L</create> (including inference of foreign
keys from related objects), or a list of primary key values in the same
order as the L<primary columns|DBIO::ResultSource/primary_columns>
declaration on the L</result_source>.

The condition of the resultset and the condition passed to this method are
combined: C<find> looks up exactly the row the condition describes. Every key
of the passed condition goes into the query as one C<AND>, and a key given as
C<undef> stays in it as C<IS NULL>.

The condition has to cover a L<unique constraint|DBIO::ResultSource/add_unique_constraint>
(the constraint corresponding to the
L<primary columns|DBIO::ResultSource/primary_columns> is always named
C<primary>): every column of the constraint has a concrete equality in the
condition, that is a defined plain value or C<< { '=' => $value } >>, on the
top C<AND> level, after the condition of the resultset and the values of
relationships are merged in. Operators, value lists, C<undef> and a constraint
that only appears inside an C<OR> branch do not cover it. A condition that
covers no constraint throws an exception that names the given columns and the
constraints of the source. To search by any other condition use
C<< $rs->search(\%cond)->single >>.

A relationship value (a related row object or a condition hashref for a
C<belongs_to>) resolves to the foreign key columns of this source. A foreign
key column passed explicitly keeps its value; a relationship resolving it to a
different one throws an exception.

The C<key> attribute names the unique constraint that has to be covered; it is
the name of a constraint. If a column of the named unique constraint is missing
from the condition, an exception is thrown, and so it is for a column supplied
as C<undef>: only defined values cover a constraint. Without C<key>, a column
given as C<undef> beside a covered constraint stays in the query as C<IS NULL>.

In addition to C<key>, L</find> recognizes and applies standard
L<resultset attributes|/ATTRIBUTES> in the same way as L</search> does.

Pass the condition with the columns named, as in C<< find({ id => $id }) >>,
whenever a value comes from outside the program; a bare C<< find($input) >> is
for values the program itself controls.

For example, to find a row by its primary key:

  my $cd = $schema->resultset('CD')->find(5);

A condition of a unique constraint plus further columns finds the row only if
it matches all of them, which is how to look up a row of an owner:

  my $cd = $schema->resultset('CD')->find({ cdid => $id, owner_id => $me });

You can also find a row by a specific unique constraint:

  my $cd = $schema->resultset('CD')->find(
    {
      artist => 'Massive Attack',
      title  => 'Mezzanine',
    },
    { key => 'cd_artist_title' }
  );

See also L</find_or_create>, L</update_or_create> and L</find_async>.

=head2 search_related

=over 4

=item Arguments: $rel_name, $cond?, L<\%attrs?|/ATTRIBUTES>

=item Return Value: L<$resultset|/search>

=back

  $new_rs = $cd_rs->search_related('artist', {
    name => 'Emo-R-Us',
  });

Searches the specified relationship, optionally specifying a condition and
attributes for matching records. See L</ATTRIBUTES> for more information.

Returns a L<DBIO::ResultSet> and throws in list context (ADR 0042) -- call
C<< ->all >> on the result to fetch rows, or use L</search_related_rs>, which
returns the resultset in every context.

See also L</search_related_rs>.

=head2 search_related_rs

This method works exactly the same as search_related, except that
it guarantees a resultset, even in list context.

=head2 cursor

=over 4

=item Arguments: none

=item Return Value: L<$cursor|DBIO::Cursor>

=back

Returns a storage-driven cursor to the given resultset. See
L<DBIO::Cursor> for more information.

=head2 single

=over 4

=item Arguments: L<$cond?|DBIO::SQLMaker>

=item Return Value: L<$result|DBIO::Manual::ResultClass> | undef

=back

  my $cd = $schema->resultset('CD')->single({ year => 2001 });

Inflates the first result without creating a cursor if the resultset has
any records in it; if not returns C<undef>. Used by L</find> as a lean version
of L</search>.

While this method can take an optional search condition (just like L</search>)
being a fast-code-path it does not recognize search attributes. If you need to
add extra joins or similar, call L</search> and then chain-call L</single> on the
L<DBIO::ResultSet> returned.

=over

=item B<Note>

This method enforces the assumption that the preceding
query returns only one row. If more than one row is returned, you will receive
a warning:

  Query returned more than one row

In this case, you should be using L</next> or L</find> instead, or if you really
know what you are doing, use the L</rows> attribute to explicitly limit the size
of the resultset.

This method will also throw an exception if it is called on a resultset prefetching
has_many, as such a prefetch implies fetching multiple rows from the database in
order to assemble the resulting object.

=back

=head2 get_column

=over 4

=item Arguments: $column_name

=item Return Value: L<$resultsetcolumn|DBIO::ResultSetColumn>

=back

  my $max_length = $rs->get_column('length')->max;

Returns a L<DBIO::ResultSetColumn> instance for a column of the ResultSet.

=head2 search_like

=over 4

=item Arguments: L<$cond|DBIO::SQLMaker>, L<\%attrs?|/ATTRIBUTES>

=item Return Value: L<$resultset|/search>

=back

  # WHERE title LIKE '%blue%'
  $cd_rs = $rs->search_like({ title => '%blue%'});

Performs a search, but uses C<LIKE> instead of C<=> as the condition. Note
that this is simply a legacy convenience method.
You most likely want to use L</search> with specific operators.

For more information, see L<DBIO::Manual::Cookbook>.

This method is deprecated. Use L<search()|/search>
instead. An example conversion is:

  ->search_like({ foo => 'bar' });

  # Becomes

  ->search({ foo => { like => 'bar' } });

=head2 slice

=over 4

=item Arguments: $first, $last

=item Return Value: L<$resultset|/search>

=back

Returns a resultset representing a subset of elements from the resultset
slice is called on. It is a L<DBIO::ResultSet>; in list context slice throws
(ADR 0042).
Indexes are from 0, i.e., to get the first three records, call:

  my ($one, $two, $three) = $rs->slice(0, 2)->all;

=head2 next

=over 4

=item Arguments: none

=item Return Value: L<$result|DBIO::Manual::ResultClass> | undef

=back

Returns the next element in the resultset (C<undef> is there is none).

Can be used to efficiently iterate over records in the resultset:

  my $rs = $schema->resultset('CD')->search;
  while (my $cd = $rs->next) {
    print $cd->title;
  }

Note that you need to store the resultset object, and call C<next> on it.
Calling C<< resultset('Table')->next >> repeatedly will always return the
first record from the resultset.

=head2 result_source

=over 4

=item Arguments: L<$result_source?|DBIO::ResultSource>

=item Return Value: L<$result_source|DBIO::ResultSource>

=back

An accessor for the primary ResultSource object from which this ResultSet
is derived.

=head2 result_class

=over 4

=item Arguments: $result_class?

=item Return Value: $result_class

=back

An accessor for the class to use when creating result objects. Defaults to
C<< result_source->result_class >> - which in most cases is the name of the
L<"table"|DBIO::Manual::Glossary/"ResultSource"> class.

Note that changing the result_class will also remove any components
that were originally loaded in the source class via
L<load_components|Class::C3::Componentised/load_components( @comps )>.
Any overloaded methods in the original source class will not run.

The C<'::HRI'>-style shorthand of L<DBIx::Class::Helper::ResultSet::ResultClassDWIM>
is deliberately not supported and throws: pass the fully qualified class name,
or use L</hri> for L<DBIO::ResultClass::HashRefInflator>.

The value is a class name -- Perl identifiers joined by C<::> -- or an
object; anything else throws C<'...' is not a class name>
(L<DBIO::Componentised/ensure_class_loaded>).

=head2 count

=over 4

=item Arguments: L<$cond|DBIO::SQLMaker>, L<\%attrs?|/ATTRIBUTES>

=item Return Value: $count

=back

Performs an SQL C<COUNT> with the same query as the resultset was built
with to find the number of elements. Passing arguments is equivalent to
C<< $rs->search ($cond, \%attrs)->count >>, also with an undefined
C<$cond>. L</count_async> and L</count_rs> take the same arguments.

=head2 count_rs

=over 4

=item Arguments: L<$cond|DBIO::SQLMaker>, L<\%attrs?|/ATTRIBUTES>

=item Return Value: L<$count_rs|DBIO::ResultSetColumn>

=back

Same as L</count> but returns a L<DBIO::ResultSetColumn> object.
This can be very handy for subqueries:

  ->search( { amount => $some_rs->count_rs->as_query } )

As with regular resultsets the SQL query will be executed only after
the resultset is accessed via L</next> or L</all>. That would return
the same single value obtainable via L</count>.

=head2 count_literal

B<CAVEAT>: C<count_literal> is a legacy convenience method.
See L</search_literal> for further info.

=over 4

=item Arguments: $sql_fragment, @standalone_bind_values

=item Return Value: $count

=back

Counts the results in a literal query. Equivalent to calling L</search_literal>
with the passed arguments, then L</count>.

=head2 count_literal_async

  my $future = $rs->count_literal_async($sql_fragment, @standalone_bind_values);
  $future->then(sub { my $count = shift; ... });

Async variant of L</count_literal>. Equivalent to calling L</search_literal>
with the passed arguments, then L</count_async>; carries C<count_async>'s own
backend routing, immediate degrade, and croak-on-sync-instance contract with
no further wrapping needed here.

=head2 all

=over 4

=item Arguments: none

=item Return Value: L<@result_objs|DBIO::Manual::ResultClass>

=back

Returns all elements in the resultset.

=head2 reset

=over 4

=item Arguments: none

=item Return Value: $self

=back

Resets the resultset's cursor, so you can iterate through the elements again.
Implicitly resets the storage cursor, so a subsequent L</next> will trigger
another query.

=head2 first

=over 4

=item Arguments: none

=item Return Value: L<$result|DBIO::Manual::ResultClass> | undef

=back

L<Resets|/reset> the resultset (causing a fresh query to storage) and returns
an object for the first result (or C<undef> if the resultset is empty).

=head2 all_async

  my $future = $rs->all_async;
  $future->then(sub { my @rows = @_; ... });

Async variant of L</all>. Returns a L<DBIO::Future> that resolves with all
result objects, fully inflated with the same prefetch/collapse handling as
L</all> (the raw rows fetched through the backend's C<select_async> are run
through the same C<_construct_results> path).

Requires an async connection (C<< connect(..., { async => ... }) >>); on a sync
instance it croaks. In the C<immediate> mode it runs synchronously and resolves
immediately. See ADR 0030/0031.

=head2 first_async

  my $future = $rs->first_async;

Async variant of L</first>. Returns a L<DBIO::Future> that resolves with the
first result object (or undef). The backend path fetches and collapses the full
result set (the only collapse-correct way to obtain the first object under a
prefetch) and resolves with its first element.

=head2 single_async

  my $future = $rs->single_async;

Async variant of L</single>. Routes the single-row fetch through the backend's
C<select_single_async> and inflates the row with the same single-row collapse
assertion as L</single>.

=head2 find_async

  my $future = $rs->find_async(\%cond, \%attrs?);
  $future->then(sub { my $row = shift; ... });   # $row may be undef

Async variant of L</find>. Shares find()'s own condition resolution -- the
same covered-constraint check (C<< key => ... >> or any covered constraint) and
the same relationship-valued-key handling (a belongs_to given a related row
object or condition hashref resolves to a concrete foreign-key value exactly
as for sync L</find>; a relation that does not resolve to a concrete
condition is a safe miss, resolving with C<undef> and issuing no query at
all -- ADR 0034). Routes the backend fetch through C<select_single_async>
(the same path L</single_async> uses), or, when the resultset collapses a
has_many, through the collapse-aware fetch-all path L</all_async> uses,
carping if more than one row was returned (matching find()'s own "Query
returned more than one row" duplicate check).

Note this is I<not> the same thing as calling L</single_async> directly:
C<single_async>, like sync L</single>, takes its condition raw and does no
relationship-key resolution at all -- handing it a relationship-valued key is
the caller's own responsibility, exactly as with plain C<single>. Reach for
C<find_async> when you want find()'s lookup semantics async; reach for
C<single_async> only where you would also reach for plain C<single>.

=head2 count_async

  my $future = $rs->count_async;
  $future->then(sub { my $count = shift; ... });

Async variant of L</count>. Routes the count query through the backend's
C<select_single_async> and resolves with the integer count (applying the same
software-side C<rows>/C<offset> adjustment as L</count>).

=head2 create_async

  my $future = $rs->create_async(\%vals);
  $future->then(sub { my $row = shift; ... });

Async variant of L</create>. For a plain single-row create the row's own insert
is routed through the backend's C<insert_async> and the resulting result object
is built in the Future's C<then> (reusing the same column store-back as the
synchronous L<DBIO::Row/insert>). Data that carries an object for a column
with an inflator, or a row already in storage for a C<belongs_to>, is still a
plain single-row create: the object is deflated and the row lends its key, as
in L</create>.

A create that involves related-object multi-create -- a C<belongs_to> given as
a hashref or as a row not yet in storage, a C<has_many> given as an arrayref
-- does not go out as a single C<insert_async> (delegated to
L<DBIO::Row/insert_async>, which has the full rule). On an unbound resultset it
is run synchronously and the Future is returned settled: resolved with the row,
or failed with what the insert threw. On a resultset bound with
L</with_context> it throws C<insert_async cannot run on a bound async context>
instead -- an exception out of C<create_async>, not a failed Future, naming the
relationship that makes it a cascade -- since the synchronous insert would run
outside the pinned transaction or pipeline (ADR 0045). A C<belongs_to> hashref
has by then been looked up with a synchronous statement, outside the
transaction.

=head2 update

=over 4

=item Arguments: \%values, \%options

=item Return Value: $underlying_storage_rv

=back

Sets the specified columns in the resultset to the supplied values in a
single query. Note that this will not run any accessor/set_column/update
triggers, nor will it update any result object instances derived from this
resultset (this includes the contents of the L<resultset cache|/set_cache>
if any). See L</update_all> if you need to execute any on-update
triggers or cascades defined either by you or a
L<result component|DBIO::Manual::Component/WHAT IS A COMPONENT>.

The return value is a pass through of what the underlying
storage backend returned, and may vary. See L<DBI/execute> for the most
common case.

A resultset whose condition is true (see L</search>) is unrestricted, and
C<update> refuses it: the call must say so with C<< { all => 1 } >>, the one
key C<\%options> takes; any other key throws. A resultset with C<rows> or
C<offset> counts as restricted.

  $rs->update({ rank => 1 }, { all => 1 });   # the whole table

A column value is a value: a plain scalar, C<undef>, an object, an arrayref
(an array data type, always bound) or explicit literal SQL (C<\'NOW()'>,
C<< \[ 'UPPER(?)', $v ] >>). A hash, code or glob reference, or a reference to
a reference, is no value and throws, naming the column and the type.

=head3 CAVEAT

Note that L</update> does not process/deflate any of the values passed in.
This is unlike the corresponding L<DBIO::Row/update>. The user must
ensure manually that any value passed to this method will stringify to
something the RDBMS knows how to deal with. A notable example is the
handling of L<DateTime> objects, for more info see:
L<DBIO::Manual::Cookbook/Formatting DateTime objects in queries>.

=head2 update_all

=over 4

=item Arguments: \%values, \%options

=item Return Value: 1

=back

Fetches all objects and updates them one at a time via
L<DBIO::Row/update>. Note that C<update_all> will run DBIO defined
triggers, while L</update> will not. An unrestricted resultset needs
C<< { all => 1 } >> as for L</update>.

=head2 delete

=over 4

=item Arguments: \%options

=item Return Value: $underlying_storage_rv

=back

Deletes the rows matching this resultset in a single query. Note that this
will not run any delete triggers, nor will it alter the
L<in_storage|DBIO::Row/in_storage> status of any result object instances
derived from this resultset (this includes the contents of the
L<resultset cache|/set_cache> if any). See L</delete_all> if you need to
execute any on-delete triggers or cascades defined either by you or a
L<result component|DBIO::Manual::Component/WHAT IS A COMPONENT>.

The return value is a pass through of what the underlying storage backend
returned, and may vary. See L<DBI/execute> for the most common case.

A resultset whose condition is true (see L</search>) is unrestricted, and
C<delete> refuses it: the call must say so with C<< { all => 1 } >>, the one
key C<\%options> takes; any other key throws. A resultset with C<rows> or
C<offset> counts as restricted.

  $rs->delete({ all => 1 });   # the whole table

=head2 delete_all

=over 4

=item Arguments: \%options

=item Return Value: 1

=back

Fetches all objects and deletes them one at a time via
L<DBIO::Row/delete>. Note that C<delete_all> will run DBIO defined
triggers, while L</delete> will not. An unrestricted resultset needs
C<< { all => 1 } >> as for L</delete>.

=head2 populate

=over 4

=item Arguments: [ \@column_list, \@row_values+ ] | [ \%col_data+ ]

=item Return Value: L<\@result_objects|DBIO::Manual::ResultClass> (scalar context) | L<@result_objects|DBIO::Manual::ResultClass> (list context)

=back

Accepts either an arrayref of hashrefs or alternatively an arrayref of
arrayrefs.

Every column value is a value, in void context as well: a plain scalar,
C<undef>, an object, an arrayref (an array data type, always bound) or
explicit literal SQL. A hash, code or glob reference (or a reference to a
reference) under a column name throws, naming the column and the type; a hash
or array under a relationship name is related data.

=over

=item NOTE

The context of this method call has an important effect on what is
submitted to storage. In void context data is fed directly to fastpath
insertion routines provided by the underlying storage (most often
L<DBI/execute_for_fetch>), bypassing the L<new|DBIO::Row/new> and
L<insert|DBIO::Row/insert> calls on the
L<Result|DBIO::Manual::ResultClass> class, including any
augmentation of these methods provided by components. For example if you
are using something like L<DBIO::UUIDColumns> to create primary
keys for you, you will find that your PKs are empty.  In this case you
will have to explicitly force scalar or list context in order to create
those values.

=back

In non-void (scalar or list) context, this method is simply a wrapper
for L</create>. Depending on list or scalar context either a list of
L<Result|DBIO::Manual::ResultClass> objects or an arrayref
containing these objects is returned. C<populate> is in this an exception to
ADR 0042, under which a DBIO method does not change its return type by call
context.

When supplying data in "arrayref of arrayrefs" invocation style, the
first element should be a list of column names and each subsequent
element should be a data value in the earlier specified column order.
For example:

  $schema->resultset("Artist")->populate([
    [ qw( artistid name ) ],
    [ 100, 'A Formally Unknown Singer' ],
    [ 101, 'A singer that jumped the shark two albums ago' ],
    [ 102, 'An actually cool singer' ],
  ]);

For the arrayref of hashrefs style each hashref should be a structure
suitable for passing to L</create>. Multi-create is also permitted with
this syntax.

  $schema->resultset("Artist")->populate([
     { artistid => 4, name => 'Manufactured Crap', cds => [
        { title => 'My First CD', year => 2006 },
        { title => 'Yet More Tweeny-Pop crap', year => 2007 },
      ],
     },
     { artistid => 5, name => 'Angsty-Whiny Girl', cds => [
        { title => 'My parents sold me to a record company', year => 2005 },
        { title => 'Why Am I So Ugly?', year => 2006 },
        { title => 'I Got Surgery and am now Popular', year => 2007 }
      ],
     },
  ]);

If you attempt a void-context multi-create as in the example above (each
Artist also has the related list of CDs), and B<do not> supply the
necessary autoinc foreign key information, this method will proxy to the
less efficient L</create>, and then throw the Result objects away. In this
case there are obviously no benefits to using this method over L</create>.

=head2 pager

=over 4

=item Arguments: none

=item Return Value: L<$pager|DBIO::ResultSet::Pager>

=back

Returns a L<DBIO::ResultSet::Pager> object tied to the current
resultset. Requires the C<page> attribute to have been previously set on
the resultset object, usually via a call to L</page>.

To get the full count of entries for a paged resultset, call
L<total_entries|DBIO::ResultSet::Pager/total_entries> on the pager
object.

A resultset bound with L</with_context> hands its context on to the count
resultset the pager builds, so the count resultset belongs to the same transaction or pipeline, as the
hand-built count of the async recipe in L<DBIO::ResultSet::Pager/ASYNC>.
An unbound resultset counts as before.

=head2 page

=over 4

=item Arguments: $page_number

=item Return Value: L<$resultset|/search>

=back

Returns a resultset for the $page_number page of the resultset on which page
is called, where each page contains a number of rows equal to the 'rows'
attribute set on the resultset (10 by default).

=head2 new_result

=over 4

=item Arguments: \%col_data

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Creates a new result object in the resultset's result class and returns
it. The row is not inserted into the database at this point, call
L<DBIO::Row/insert> to do that. Calling L<DBIO::Row/in_storage>
will tell you whether the result object has been inserted or not.

Passes the hashref of input on to L<DBIO::Row/new>.

=head2 as_query

=over 4

=item Arguments: none

=item Return Value: \[ $sql, L<@bind_values|/DBIO BIND VALUES> ]

=back

Returns the SQL query and bind vars associated with the invocant.

This is generally used as the RHS for a subquery.

=head2 find_or_new

=over 4

=item Arguments: \%col_data, { key => $unique_constraint, L<%attrs|/ATTRIBUTES> }?

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

  my $artist = $schema->resultset('Artist')->find_or_new(
    { artist => 'fred' }, { key => 'artists' });

  $cd->cd_to_producer->find_or_new({ producer => $producer },
                                   { key => 'primary' });

Find an existing record from this resultset using L</find>. if none exists,
instantiate a new result object and return it. The object will not be saved
into your storage until you call L<DBIO::Row/insert> on it.

The lookup identifies the row: it uses the columns of the one unique constraint
the data covers (see L</find>), or of the constraint named by C<key>; the other
values are the data of the new object. When the data covers several unique
constraints, C<key> names the one to look up; when it covers none, the method
throws.

You most likely want this method when looking for existing rows using a unique
constraint that is not the primary key, or looking for related rows.

If you want objects to be saved immediately, use L</find_or_create> instead.

B<Note>: L</find> describes what a condition has to cover and what the C<key>
attribute names.

B<Note>: Take care when using C<find_or_new> with a table having
columns with default values that you intend to be automatically
supplied by the database (e.g. an auto_increment primary key column).
In normal usage, the value of such columns should NOT be included at
all in the call to C<find_or_new>, even when set to C<undef>.

=head2 find_or_new_async

  my $future = $rs->find_or_new_async(\%col_data, { key => $unique_constraint, L<%attrs|/ATTRIBUTES> }?);
  $future->then(sub { my $row = shift; ... });

Async variant of L</find_or_new>. Composed of L</find_async> (shared
condition-resolution and lookup semantics, including the ADR 0034
relationship-valued-key handling) and a plain, synchronous L</new_result> for
the not-found branch. Carries C<find_async>'s own backend routing, immediate
degrade, and croak-on-sync-instance contract; a race between the async lookup
and any concurrent write is the same one documented for the sync method.

=head2 create

=over 4

=item Arguments: \%col_data

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Attempt to create a single new row or a row with multiple related rows
in the table represented by the resultset (and related tables). This
will not check for duplicate rows before inserting, use
L</find_or_create> to do that.

To create one row for this resultset, pass a hashref of key/value
pairs representing the columns of the table and the values you wish to
store. If the appropriate relationships are set up, foreign key fields
can also be passed an object representing the foreign row, and the
value will be set to its primary key.

To create related objects, pass a hashref of related-object column values
B<keyed on the relationship name>. If the relationship is of type C<multi>
(L<DBIO::Relationship/has_many>) - pass an arrayref of hashrefs.
The process will correctly identify columns holding foreign keys, and will
transparently populate them from the keys of the corresponding relation.
This can be applied recursively, and will work correctly for a structure
with an arbitrary depth and width, as long as the relationships actually
exists and the correct column data has been supplied.

Instead of hashrefs of plain related data (key/value pairs), you may
also pass new or inserted objects. New objects (not inserted yet, see
L</new_result>), will be inserted into their appropriate tables.

A column value is a value: a plain scalar, C<undef>, an object, an arrayref
(an array data type, always bound), explicit literal SQL (C<\'NOW()'>,
C<< \[ 'UPPER(?)', $v ] >>), or what an inflated column type deflates. A hash
under a relationship name is a relationship; a hash, code or glob reference
(or a reference to a reference) under a column name is no value and throws,
naming the column and the type.

Effectively a shortcut for C<< ->new_result(\%col_data)->insert >>.

Passing a request hash to C<create> is mass assignment: what ends up in the
columns is what is checked.

=over

=item *

A value of the hash that contradicts an equality of the resultset's own
condition throws (C<create on a scoped resultset: 'artist' is fixed to a value
by the condition, got another value>, naming the column and never a value);
the same value is allowed. C<undef> is the same value as a condition
C<IS NULL> and contradicts a defined value. This holds for a relationship
value as well: what it resolves to is the value that is checked.

=item *

A column marked L<is_guarded|DBIO::ResultSource/is_guarded> takes no value from
the hash, also when a relationship value of the hash sets it as foreign key; a
relationship marked C<is_guarded> takes no hash of related data. The values the
resultset's condition holds, and the foreign keys the rows created along inherit
from their parent, are no assignment of the hash's.

=item *

A hash of related data is looked up with L</find> only for a C<belongs_to>
relationship, and only when it gives every column of a unique constraint of the
related source (see L</find>); any other related data, and every C<has_many>,
C<might_have> and C<has_one> row, is created. Being unique is no permission to
link a row: mark the relationship or its foreign key C<is_guarded> where a
caller may not link existing rows.

=back

Example of creating a new row.

  $person_rs->create({
    name=>"Some Person",
    email=>"somebody@someplace.com"
  });

Example of creating a new row and also creating rows in a related C<has_many>
or C<has_one> resultset.  Note Arrayref.

  $artist_rs->create(
     { artistid => 4, name => 'Manufactured Crap', cds => [
        { title => 'My First CD', year => 2006 },
        { title => 'Yet More Tweeny-Pop crap', year => 2007 },
      ],
     },
  );

Example of creating a new row and also creating a row in a related
C<belongs_to> resultset. Note Hashref.

  $cd_rs->create({
    title=>"Music for Silly Walks",
    year=>2000,
    artist => {
      name=>"Silly Musician",
    }
  });

=over

=item WARNING

When subclassing ResultSet never attempt to override this method. Since
it is a simple shortcut for C<< $self->new_result($attrs)->insert >>, a
lot of the internals simply never call it, so your override will be
bypassed more often than not. Override either L<DBIO::Row/new>
or L<DBIO::Row/insert> depending on how early in the
L</create> process you need to intervene. See also warning pertaining to
L</new>.

=back

=head2 find_or_create

=over 4

=item Arguments: \%col_data, { key => $unique_constraint, L<%attrs|/ATTRIBUTES> }?

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

  $cd->cd_to_producer->find_or_create({ producer => $producer },
                                      { key => 'primary' });

Tries to find a record based on a unique constraint; if none is found, creates
one and returns that instead.

The lookup identifies the row: it uses the columns of the one unique constraint
the data covers (see L</find>), the other values are the data of the row to
create.

  my $cd = $schema->resultset('CD')->find_or_create({
    artist => 'Massive Attack',
    title  => 'Mezzanine',
    year   => 2005,
  });

When the data covers several unique constraints, the C<key> attribute names the
one to look up; when it covers none, the method throws. For example:

  my $cd = $schema->resultset('CD')->find_or_create(
    {
      artist => 'Massive Attack',
      title  => 'Mezzanine',
    },
    { key => 'cd_artist_title' }
  );

B<Note>: L</find> describes what a condition has to cover and what the C<key>
attribute names.

B<Note>: Because find_or_create() reads from the database and then
possibly inserts based on the result, this method is subject to a race
condition. Another process could create a record in the table after
the find has completed and before the create has started. To avoid
this problem, use find_or_create() inside a transaction.

B<Note>: Take care when using C<find_or_create> with a table having
columns with default values that you intend to be automatically
supplied by the database (e.g. an auto_increment primary key column).
In normal usage, the value of such columns should NOT be included at
all in the call to C<find_or_create>, even when set to C<undef>.

See also L</find> and L</update_or_create>. For information on how to declare
unique constraints, see L<DBIO::ResultSource/add_unique_constraint>.

If you need to know if an existing row was found or a new one created use
L</find_or_new> and L<DBIO::Row/in_storage> instead. Don't forget
to call L<DBIO::Row/insert> to save the newly created row to the
database!

  my $cd = $schema->resultset('CD')->find_or_new({
    artist => 'Massive Attack',
    title  => 'Mezzanine',
    year   => 2005,
  });

  if( !$cd->in_storage ) {
      # do some stuff
      $cd->insert;
  }

=head2 find_or_create_async

  my $future = $rs->find_or_create_async(\%col_data, { key => $unique_constraint, L<%attrs|/ATTRIBUTES> }?);
  $future->then(sub { my $row = shift; ... });

Async variant of L</find_or_create>. Composed of L</find_async> for the
lookup and L</create_async> for the not-found branch; carries whichever of
the two methods' own backend routing, immediate degrade, and
croak-on-sync-instance contract applies. Subject to the same race as sync
L</find_or_create> -- another process may insert between the lookup and the
create -- so use this inside a transaction if that matters: on a resultset
bound to the transaction's context with L</with_context>. A create that fails
there fails the whole transaction, also when the failure is caught -- catching
it and looking the row up again does not save the transaction.

=head2 update_or_create

=over 4

=item Arguments: \%col_data, { key => $unique_constraint, L<%attrs|/ATTRIBUTES> }?

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

  $resultset->update_or_create({ col => $val, ... });

Like L</find_or_create>, but if a row is found it is immediately updated via
C<< $found_row->update (\%col_data) >>.

The lookup identifies the row: it uses the columns of the one unique constraint
the data covers (see L</find>), or of the constraint named by C<key>; the other
values are the data the found row is updated with or the new row is created
with. When the data covers several unique constraints, C<key> names the one to
look up; when it covers none, the method throws.

Takes an optional C<key> attribute to search on a specific unique constraint.
For example:

  # In your application
  my $cd = $schema->resultset('CD')->update_or_create(
    {
      artist => 'Massive Attack',
      title  => 'Mezzanine',
      year   => 1998,
    },
    { key => 'cd_artist_title' }
  );

  $cd->cd_to_producer->update_or_create({
    producer => $producer,
    name => 'harry',
  }, {
    key => 'primary',
  });

If C<%col_data> mixes plain columns of this table with a value keyed on a
relationship name (C<< { some_col => $x, some_relation => \%data } >>), the row
is looked up using the plain columns plus any C<belongs_to> that reduces to a
concrete foreign-key condition on this table. A relation that does not so reduce
(a C<has_many> / C<has_one> / C<might_have> sub-structure, or a C<belongs_to>
whose value is not a resolvable foreign key) is omitted from the lookup, so that
find() is never handed a condition that would clobber a key column with an undef
foreign key. The FULL C<%col_data>, relation keys included, is then passed to
C<< $found_row->update >> or C<< $new_row->insert >>. How those relation keys
are treated from there is the row layer's responsibility: a resolvable
C<belongs_to> is folded into this row's own foreign-key columns, whereas a
nested C<has_many> / C<might_have> sub-structure is rejected unless the result
class composes in a component that owns nested-relation semantics. The C<key>
attribute constrains only the lookup.

B<Note>: For such a nested C<has_many> / C<might_have> sub-structure the create
and update branches behave asymmetrically in stock DBIO. When no row is found the
row is created and the nested rows are multi-created alongside it (the row layer's
insert-time nested-write path), so the call succeeds; when a row is found it is
updated via C<< $found_row->update >>, whose C<set_from_related> guard refuses the
same sub-structure, so the call throws. This is the honest pre-0.900001 contract
-- there is an insert-time nested-write path but as yet no update-time one -- not a
designed feature; a row-layer seam for nested update is expected to follow (see the
C<Changes> entry for this release).

B<Note>: L</find> describes what a condition has to cover and what the C<key>
attribute names.

B<Note>: Take care when using C<update_or_create> with a table having
columns with default values that you intend to be automatically
supplied by the database (e.g. an auto_increment primary key column).
In normal usage, the value of such columns should NOT be included at
all in the call to C<update_or_create>, even when set to C<undef>.

See also L</find> and L</find_or_create>. For information on how to declare
unique constraints, see L<DBIO::ResultSource/add_unique_constraint>.

If you need to know if an existing row was updated or a new one created use
L</update_or_new> and L<DBIO::Row/in_storage> instead. Don't forget
to call L<DBIO::Row/insert> to save the newly created row to the
database!

=head2 update_or_create_async

  my $future = $rs->update_or_create_async(\%col_data, { key => $unique_constraint, L<%attrs|/ATTRIBUTES> }?);
  $future->then(sub { my $row = shift; ... });

Async variant of L</update_or_create>. Reuses C<_find_lookup_cond> as-is for
the lookup (the same relation-valued-key dropping ADR 0034 gives sync
C<update_or_create>), then composes L</find_async> with
L<update_async|DBIO::Row/update_async> (found)
or L</create_async> (not found) -- the FULL, unsplit condition reaches the row
layer via C<update_async>/C<create_async> either way, exactly like sync. No
transaction is opened, matching current sync behaviour. Carries whichever of
the composed methods' own backend routing, immediate degrade, and
croak-on-sync-instance contract applies, and is subject to the same
find/create race documented for sync L</update_or_create>.

=head2 upsert

=over 4

=item Arguments: \%col_data, \%opts?

=item Return Value: L<$result|DBIO::Manual::ResultClass> | undef | $count | ()

=back

  my $row = $schema->resultset('Artist')->upsert(
    { artistid => 5, name => 'Aphex Twin', rank => 1 },
  );

A B<single-statement, server-side atomic upsert>: one C<INSERT> that carries a
conflict clause, so the engine -- not the client -- resolves the collision.
Unlike L</find_or_create>, L</update_or_create> and
L<DBIO::Row/insert_or_update>, which read and then write and are therefore
subject to a time-of-check/time-of-use race, C<upsert> has no window between
the two.

C<upsert> is only available on engines whose driver declares the
C<supports_upsert> capability (PostgreSQL / SQLite C<ON CONFLICT>,
MySQL C<ON DUPLICATE KEY UPDATE>). On any other engine it B<throws>; it never
degrades silently to a client-side two-step. See L</Unsupported engines> below.

C<\%col_data> may also carry B<nested relationship data>, in which case
C<upsert> upserts the parts too -- see L</Cascading upsert>. The batch name
C<upsert_all> is reserved and not implemented.

=head3 Options

=over 4

=item C<key> / C<conflict_target>

Which unique constraint the statement conflicts on. C<key> names a unique
constraint declared with L<DBIO::ResultSource/add_unique_constraint>, exactly as
L</find> uses it. C<conflict_target> names the columns directly: an arrayref, a
single column name, or the string C<'any'>.

The two are mutually exclusive -- passing both throws.

C<key> works on every supporting engine, including those whose conflict-clause
grammar knows a column list only: the constraint name I<and> its resolved
columns are both handed to the driver, which picks whichever its grammar takes.

C<< conflict_target => 'any' >> is the engine-native "whichever unique
constraint collides" of MySQL's C<ON DUPLICATE KEY UPDATE>. It is a legitimate
want but not a portable one: PostgreSQL and SQLite require a target for
C<DO UPDATE> and will reject it (C<< on_conflict => 'nothing' >> works
everywhere, see below).

When neither option is given the B<primary key> is the target, but only if
C<\%col_data> supplies every primary key column. If it does not -- or the
source has no primary key at all -- C<upsert> throws. With an unsupplied
auto-increment key the statement could never collide, so the upsert would
silently degenerate into a plain C<INSERT>: a call that does nothing, with no
error to show for it. C<upsert> deliberately does B<not> fall back to a lone
unique constraint; with no primary key, name the target.

=item C<on_conflict>

C<'update'> (the default) or C<'nothing'>.

=item C<update>

Which columns the conflict branch writes. By default every supplied column that
is not part of the conflict target and not a primary key column is set to the
value that was attempted to be inserted (the engine's C<EXCLUDED.col> /
C<VALUES(col)> -- core stays abstract, the driver renders the token).

  update => [qw/ score seen_at /]                      # restrict to these
  update => { count => \'count + 1', seen_at => \'NOW()' }   # expressions

The arrayref form restricts the default set; every listed column must be among
the inserted values. The hashref form B<replaces> the set: values are used
verbatim, so a literal C<\'count + 1'> passes straight through to the engine.

=item C<update_where>

A condition on the conflict branch: the engine performs the update only where
it holds and leaves the stored row untouched otherwise. This is what makes the
last-write-wins guard -- "insert, or update only if the incoming row is newer"
-- expressible in a single statement, instead of choosing between overwriting
newer data and giving up atomicity:

  $rs->upsert(
    { id => 5, payload => $blob, updated_at => $ts },
    { update_where => { updated_at => { '<' => { -attempted => 'updated_at' } } } },
  );

It is the C<WHERE> of the C<DO UPDATE> branch, not a search condition on the
resultset -- the resultset's own condition is folded into the inserted values
the way L</create> folds it in, and a second plain C<where> at the call site
would be indistinguishable from it. Hence the name.

The interesting conditions compare the two rows the statement knows about, and
both are sayable without engine tokens:

=over 4

=item *

an B<unqualified column> is the B<stored> row -- the row the statement collided
with.

=item *

C<< { -attempted => $column } >> is the value the statement B<tried to insert>.
That is the same engine-neutral marker the C<update> set uses; the driver
renders it as its excluded-row reference (C<EXCLUDED.col> on PostgreSQL and
SQLite), and it may appear anywhere in the condition.

=back

A literal is the escape hatch for what the abstract form cannot say:
C<< \'excluded.updated_at > artist.updated_at' >> or C<< \[ $sql, @bind ] >>
passes through verbatim -- and is engine-specific by construction, which is
the honest trade for writing engine SQL by hand.

Core validates the shape and nothing else, exactly as L</search> does not look
inside its C<\%cond>: a column that does not exist is an error from the engine,
not from C<upsert>.

Needs the C<supports_upsert_where> capability on top of C<supports_upsert>, and
throws without it. A driver that does not render the condition would emit a
valid unconditional C<UPDATE> -- the very overwrite the option exists to
prevent -- so the driver has to declare that it renders one before core sends
one. MySQL cannot: C<ON DUPLICATE KEY UPDATE> has no C<WHERE>, and a per-column
C<IF()> does not suppress the write.

Refused up front together with C<< on_conflict => 'nothing' >> (no update
branch to condition), C<< result => 'row_or_die' >> (a condition that does not
hold writes no row, so no row can be guaranteed) and C<fallback>
(L</update_or_create> writes unconditionally).

=item C<result>

What the call returns. See L</Return shapes>.

=item C<fallback>

C<< fallback => 'update_or_create' >> -- explicitly accept the client-side race
for this one call on an engine that has no atomic upsert. Per call only; there
is deliberately no schema- or storage-level default, because a global switch is
exactly the lever that would re-enable the race application-wide, including
inside libraries that never asked for it.

=item C<relations>

The per-relation conflict targets for a cascade. See L</Cascading upsert>.

=back

=head3 Return shapes

  result => ...   returns

=over 4

=item C<'row_or_undef'> (default)

A stored L<Result|DBIO::Manual::ResultClass> when the written row can be named,
C<undef> when nothing was written or the engine could not name what it wrote.
The first time the unnameable case is hit, a warning naming the source is
emitted; pass C<< result => 'row_or_undef' >> explicitly to silence it.

=item C<'row_or_die'>

Guarantees a Result -- throws rather than hand back nothing. Refused up front in
combination with C<< on_conflict => 'nothing' >> and with C<update_where>, both
of which exist in order to possibly write nothing.

=item C<'count'>

The statement's affected-row count, as a plain number -- notably C<0>, not
DBI's zero-but-true C<'0E0'>, so C<< if (my $n = $rs->upsert(...)) >> reads
false when nothing was written. (C<upsert> throws on failure, so there is no
success-versus-failure information for a zero-but-true value to carry.) The
count itself is engine-specific. MySQL and MariaDB connect with
C<CLIENT_FOUND_ROWS> by default (both C<DBD::mysql> and C<DBD::MariaDB>), which
counts matched rows: an insert reports 1, an update that changes the row 2, and
an update that leaves it unchanged still 1 -- as does C<< on_conflict =>
'nothing' >>, whether it inserted or skipped. Only a connection with that flag
switched off reports 0 for the unchanged cases.

=item C<'void'>

Returns nothing and spends nothing obtaining it: no C<RETURNING> tail, no
C<last_insert_id>, no follow-up C<SELECT> -- one round-trip.

Literally nothing: the empty list, not C<undef>. In list context it therefore
contributes no element at all, which silently eats an argument --
C<< is $rs->upsert(\%data, { result => 'void' }), undef, 'name' >> becomes
C<< is(undef, 'name') >>. Call it in void or scalar context.

=back

There is no plain C<'row'>: not every engine can name the row it just wrote, and
every value in this set says what happens in that case.

B<Portable code passes C<result> explicitly.> The default is uniform across
engines in I<type>, but what an engine can prove differs; stating the shape you
need turns an engine difference into either a Result or a clear exception at the
call site instead of a silent C<undef>.

The returned Result carries the columns you supplied plus whatever the engine
handed back (primary key, C<retrieve_on_insert> columns) -- like L</create>, it
is not a re-read of the stored row, so columns the statement did not touch are
not populated from the database.

C<< on_conflict => 'nothing' >> with C<row_or_undef> returns C<undef> when the
row was already there: C<DO NOTHING> makes C<RETURNING> yield zero rows, which
is the legitimate outcome rather than a failure -- and, unlike the unnameable
case above, it is not warned about: nothing was written, so no identity is
missing. On an engine without C<RETURNING> the identity comes from
C<last_insert_id>, which cannot distinguish "skipped" from "inserted". The
affected-row count does not reliably either: it tells them apart only where the
engine counts changed rows (on MySQL and MariaDB, only with C<CLIENT_FOUND_ROWS>
switched off -- see C<'count'> above).

=head3 Cascading upsert

  my $cd = $schema->resultset('CD')->upsert(
    {
      title  => 'Bad',
      year   => 1987,
      artist => { name => 'Michael Jackson' },        # belongs_to
      tracks => [ { position => 1, title => 'Bad' },  # has_many
                  { position => 2, title => 'Speed Demon' } ],
    },
    {
      conflict_target => [qw/ artist title /],
      relations => {
        artist => { key => 'artist_name' },
        tracks => { conflict_target => [qw/ cd position /] },
      },
    },
  );

When C<\%col_data> nests relationship data, C<upsert> writes the parts as well.
What that buys you, in exactly these words and not a word more:

B<N atomic upserts, in dependency order, inside one transaction -- all-or-nothing,
and every part individually free of the read-then-write race.>

No engine has a multi-table upsert, so a cascade is inherently more than one
statement; this is B<not> "an atomic upsert". It is strictly stronger than the
L</update_or_create> cascade, which has to guess at every part, and strictly
weaker than a single statement.

=over 4

=item Order

C<belongs_to> parts are written B<before> the row -- their key becomes its
foreign key. C<has_many> and C<might_have> parts are written B<after> it -- its
key becomes theirs. This is the same dependency split
L<DBIO::Row/insert> performs for multi-create, and the same
metadata decides it, so a relationship that multi-creates in one order
cascades in that order too. Parts of the same kind run in relationship-name
order.

=item Targets, per relation, never inferred

C<relations> mirrors the nested data: one entry per nested relationship,
holding C<key> or C<conflict_target> (mutually exclusive) and, for data nested
deeper, its own C<relations>. Naming a relationship that has no nested data
throws rather than doing nothing.

C<on_conflict>, C<update>, C<update_where> and C<result> are decisions about
the whole call and have no per-relation form.

The three-way default rule from L</Options> applies B<per part>: a part whose
data does not supply the related source's primary key, and which has no target
of its own, throws. A foreign key the part will be I<handed> -- by its parent,
or by a part written before it -- counts as supplied.

=item Identity is a precondition, not a nicety

Setting a child's foreign key needs the key of the parent part just written, so
every part something depends on must be nameable in the sense of
L</Return shapes>: it is upserted as C<row_or_die> whatever you asked to get
back. A shape in which the written row cannot be named -- a source with no
primary key, C<< conflict_target => 'any' >>, C<< on_conflict => 'nothing' >>
or C<update_where> on a row that children hang off -- makes the cascade
impossible and B<throws>. A conditional update on a row nothing depends on is
fine: it may write nothing and hand back C<undef>, exactly as it does flat.

All of that follows from schema metadata and the options, so it is checked
B<before the first statement runs>: an impossible cascade fails on the first
call in development, not data-dependently in production. What core cannot see
statically is whether a given engine can name the row for a given table shape
(MySQL's is the one that cannot always) -- that surfaces as the part's own
C<row_or_die> exception, inside the rolled-back transaction.

=item C<result> is restricted

Only C<row_or_undef> and C<row_or_die>; C<count> and C<void> throw at
option-validation time. A count across a cascade has no defined meaning, and
C<void> would withhold the identity the cascade structurally needs. The return
value is the B<top-level Result only> -- related rows are not collected, just
as L</create> with nested data does not hand them back. With C<has_many> or
C<might_have> parts the top-level row is written as C<row_or_die> regardless,
because the children need its key.

Leaf parts nobody depends on are written with C<< result => 'void' >>: one
round-trip, no identity work spent on a row that is not handed back.

=item One transaction

The cascade wraps itself in a L<txn_scope_guard|DBIO::Storage::TxnScopeGuard>.
If the caller is B<already inside a transaction it joins it>, so a failing
cascade rolls the caller's outer work back too. There is deliberately no
savepoint magic here: a caller who wants the cascade isolated from surrounding
work opens their own savepoint.

=item C<has_many> upserts the listed children and B<never deletes> the others

Children not in the list are left untouched. "Replace the set" is
C<< set_$rel >> semantics and something else entirely; implicit deletion would
be the nastiest surprise this API could offer.

=item C<many_to_many> throws

It would mean writing bridge rows, which reopens the deletion question above
for the link table. Nest the bridge relationship itself, or use
C<< set_$rel >>.

=item Result objects in the data throw

A nested part is a hashref of columns. An existing Result object does not say
whether you want it written or only linked, and guessing is the DWIM this API
exists to avoid -- pass C<< { $row->get_columns } >>, or set the foreign key
yourself.

=item C<fallback> cannot express a cascade

L</update_or_create> takes one named constraint for the top-level row and
nothing at all for the parts, so a fallback cascade would look every part up by
L</find>'s heuristics -- a different row than the atomic path writes. The
combination throws.

=back

=head3 Unsupported engines

  $rs->result_source->storage->_use_supports_upsert
    ? $rs->upsert(\%data, \%opts)
    : $rs->update_or_create(\%data);   # racy, and visible at the call site

is the capability-based branch for portable library code -- no driver-name
string match anywhere. Alternatively, C<< fallback => 'update_or_create' >>
folds the same branch into the call. On the fallback path the return mapping is
kept identical so the same call never changes I<type> per engine:
C<row_or_undef> / C<row_or_die> hand back the Result C<update_or_create>
produced, C<void> discards it, and C<'count'> returns a synthetic C<1> --
B<not> a real affected-rows figure, since no single statement ran. No warning is
emitted when the fallback engages: it was explicitly requested.

The fallback looks the row up by the same constraint the atomic statement would
have conflicted on -- C<key> if given, otherwise the primary key.
C<conflict_target> cannot be expressed that way (L</update_or_create> takes a
constraint I<name>, never a column list), so combining the two throws and the
message points at C<< key => $constraint >>.

Because the fallback always writes every supplied column, it likewise cannot
honour C<< on_conflict => 'nothing' >> or a restricted C<update> set. All three
combinations throw at option-validation time, on every engine, rather than
drifting semantically on the one engine where the fallback engages.

See ADR 0036 for the full decision record.

=head2 upsert_async

  my $future = $rs->upsert_async(\%col_data, \%opts?);
  $future->then(sub { my $row_or_count_or_undef = shift; ... });

Async variant of L</upsert>. Shares every validation rule, conflict-target
resolution and capability gate with the synchronous method verbatim (both
route through the private C<_upsert_prepare>, so the two cannot drift) -- an
invalid call is invalid on both, identically.

The single-statement, C<row_or_undef>/C<row_or_die> case is genuinely
non-blocking: the write is routed through the backend's C<insert_async> and
the result is inflated in the Future's C<then>, exactly like L</create_async>.
Two shapes cannot be: nested relationship data is a multi-statement
transactional cascade (C<_upsert_cascade>), and C<< fallback =>
'update_or_create' >> is itself a client-side two-step -- neither is a single
C<insert_async>. C<< result => 'count' >> also cannot: the affected-row count
sync reads off a storage-specific side channel that the generic async insert
path does not populate (see L<DBIO::Storage::Async/insert_async> -- it
resolves the returned-columns hashref, never a count). On an unbound resultset
all three run the synchronous L</upsert> -- blocking, on the owning storage's own
connection, not on a pooled one -- and return a settled Future --
resolved with its result, or failed with what it threw -- the same precedent
L</create_async> sets for related-object multi-create (ADR 0030/0031). On a
resultset bound with L</with_context> all three throw C<upsert_async cannot run
on a bound async context> instead -- an exception out of C<upsert_async>, not
a failed Future -- since the synchronous fallback would run outside the pinned
transaction or pipeline (ADR 0045).

Requires an async connection; on a sync instance it croaks, and in the
C<immediate> mode it degrades to a synchronous L</upsert> wrapped in an
immediately-resolved Future. See ADR 0036 for the option contract.

=head2 update_or_new

=over 4

=item Arguments: \%col_data, { key => $unique_constraint, L<%attrs|/ATTRIBUTES> }?

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

  $resultset->update_or_new({ col => $val, ... });

Like L</find_or_new> but if a row is found it is immediately updated via
C<< $found_row->update (\%col_data) >>.

The lookup identifies the row, as for L</update_or_create>: the columns of the
one unique constraint the data covers, or of the constraint named by C<key>.

For example:

  # In your application
  my $cd = $schema->resultset('CD')->update_or_new(
    {
      artist => 'Massive Attack',
      title  => 'Mezzanine',
      year   => 1998,
    },
    { key => 'cd_artist_title' }
  );

  if ($cd->in_storage) {
      # the cd was updated
  }
  else {
      # the cd is not yet in the database, let's insert it
      $cd->insert;
  }

B<Note>: L</find> describes what a condition has to cover and what the C<key>
attribute names.

B<Note>: Take care when using C<update_or_new> with a table having
columns with default values that you intend to be automatically
supplied by the database (e.g. an auto_increment primary key column).
In normal usage, the value of such columns should NOT be included at
all in the call to C<update_or_new>, even when set to C<undef>.

See also L</find>, L</find_or_create> and L</find_or_new>.

=head2 update_or_new_async

  my $future = $rs->update_or_new_async(\%col_data, { key => $unique_constraint, L<%attrs|/ATTRIBUTES> }?);
  $future->then(sub { my $row = shift; ... });

Async variant of L</update_or_new>. Composed of L</find_async> (looking up by
the columns of the covered unique constraint, exactly like sync) and
L<update_async|DBIO::Row/update_async> for the found
branch, or a plain, synchronous L</new_result> for the not-found branch.
Carries the composed methods' own backend routing, immediate degrade, and
croak-on-sync-instance contract.

=head2 get_cache

=over 4

=item Arguments: none

=item Return Value: L<\@result_objs|DBIO::Manual::ResultClass> | undef

=back

Gets the contents of the cache for the resultset, if the cache is set.

The cache is populated either by using the L</prefetch> attribute to
L</search> or by calling L</set_cache>.

=head2 set_cache

=over 4

=item Arguments: L<\@result_objs|DBIO::Manual::ResultClass>

=item Return Value: L<\@result_objs|DBIO::Manual::ResultClass>

=back

Sets the contents of the cache for the resultset. Expects an arrayref
of objects of the same class as those produced by the resultset. Note that
if the cache is set, the resultset will return the cached objects rather
than re-querying the database even if the cache attr is not set.

The contents of the cache can also be populated by using the
L</prefetch> attribute to L</search>.

=head2 clear_cache

=over 4

=item Arguments: none

=item Return Value: undef

=back

Clears the cache for the resultset.

=head2 is_paged

=over 4

=item Arguments: none

=item Return Value: true, if the resultset has been paginated

=back

=head2 is_ordered

=over 4

=item Arguments: none

=item Return Value: true, if the resultset has been ordered with C<order_by>.

=back

=head2 related_resultset

=over 4

=item Arguments: $rel_name

=item Return Value: L<$resultset|/search>

=back

Returns a related resultset for the supplied relationship name.

  $artist_rs = $schema->resultset('CD')->related_resultset('Artist');

=head2 current_source_alias

=over 4

=item Arguments: none

=item Return Value: $source_alias

=back

Returns the current table alias for the result source this resultset is built
on, that will be used in the SQL query. Usually it is C<me>.

Currently the source alias that refers to the result set returned by a
L</search>/L</find> family method depends on how you got to the resultset: it's
C<me> by default, but eg. L</search_related> aliases it to the related result
source name (and keeps C<me> referring to the original result set). The long
term goal is to make L<DBIO> always alias the current resultset as C<me>
(and make this method unnecessary).

Thus it's currently necessary to use this method in predefined queries (see
L<DBIO::Manual::Cookbook/Predefined searches>) when referring to the
source alias of the current result set:

  # in a result set class
  sub modified_by {
    my ($self, $user) = @_;

    my $me = $self->current_source_alias;

    return $self->search({
      "$me.modified" => $user->id,
    });
  }

The alias of L<newly created resultsets|/search> can be altered by the
L<alias attribute|/alias>.

=head2 as_subselect_rs

=over 4

=item Arguments: none

=item Return Value: L<$resultset|/search>

=back

Act as a barrier to SQL symbols.  The resultset provided will be made into a
"virtual view" by including it as a subquery within the from clause.  From this
point on, any joined tables are inaccessible to ->search on the resultset (as if
it were simply where-filtered without joins).  For example:

 my $rs = $schema->resultset('Bar')->search({'x.name' => 'abc'},{ join => 'x' });

 # 'x' now pollutes the query namespace

 # So the following works as expected
 my $ok_rs = $rs->search({'x.other' => 1});

 # But this doesn't: instead of finding a 'Bar' related to two x rows (abc and
 # def) we look for one row with contradictory terms
 my $broken_rs = $rs->search({'x.name' => 'def'});

 my $rs2 = $rs->as_subselect_rs;

 # doesn't work - 'x' is no longer accessible in $rs2, having been sealed away
 my $not_joined_rs = $rs2->search({'x.other' => 1});

 # works as expected: finds a 'Bar' row related to two x rows (abc and def).
 # The join has to be named: one is not inferred from the condition once the
 # FROM is a subquery
 my $correctly_joined_rs = $rs2->search({'x.name' => 'def'}, { join => 'x' });

Another example of when one might use this would be to select a subset of
columns in a group by clause:

 my $rs = $schema->resultset('Bar')->search(undef, {
   group_by => [qw{ id foo_id baz_id }],
 })->as_subselect_rs->search(undef, {
   columns => [qw{ id foo_id }]
 });

In the above example normally columns would have to be equal to the group by,
but because we isolated the group by into a subselect the above works.

=head2 STORABLE_thaw

The L<Storable> hook that restores a frozen resultset. Thaw only data of
your own, from a source you trust -- Storable creates objects of whatever
class the data names. The result source inside is resolved and checked by
L<DBIO::ResultSource/STORABLE_thaw>.

=head1 EXAMPLES

=head2 Chaining resultsets

Let's say you've got a query that needs to be run to return some data
to the user. But, you have an authorization system in place that
prevents certain users from seeing certain information. So, you want
to construct the basic query in one method, but add constraints to it in
another.

  sub get_data {
    my $self = shift;
    my $request = $self->get_request; # Get a request object somehow.
    my $schema = $self->result_source->schema;

    my $cd_rs = $schema->resultset('CD')->search({
      title => $request->param('title'),
      year => $request->param('year'),
    });

    $cd_rs = $self->apply_security_policy( $cd_rs );

    return $cd_rs->all();
  }

  sub apply_security_policy {
    my $self = shift;
    my ($rs) = @_;

    return $rs->search({
      subversive => 0,
    });
  }

=head3 Resolving conditions and attributes

When a resultset is chained from another resultset (e.g.:
C<< my $new_rs = $old_rs->search(\%extra_cond, \%attrs) >>), conditions
and attributes with the same keys need resolving.

If any of L</columns>, L</select>, L</as> are present, they reset the
original selection, and start the selection "clean".

The L</join>, L</prefetch>, L</+columns>, L</+select>, L</+as> attributes
are merged into the existing ones from the original resultset.

The L</where> and L</having> attributes, and any search conditions, are
merged with an SQL C<AND> to the existing condition from the original
resultset.

All other attributes are overridden by any new ones supplied in the
search attributes.

=head2 Multiple queries

Since a resultset just defines a query, you can do all sorts of
things with it with the same object.

  # Don't hit the DB yet.
  my $cd_rs = $schema->resultset('CD')->search({
    title => 'something',
    year => 2009,
  });

  # Each of these hits the DB individually.
  my $count = $cd_rs->count;
  my $most_recent = $cd_rs->get_column('date_released')->max();
  my @records = $cd_rs->all;

And it's not just limited to SELECT statements.

  $cd_rs->delete();   # "... WHERE title = 'something' AND year = 2009"

This is even cooler:

  $cd_rs->create({ artist => 'Fred' });

Which is the same as:

  $schema->resultset('CD')->create({
    title => 'something',
    year => 2009,
    artist => 'Fred'
  });

See: L</search>, L</count>, L</get_column>, L</all>, L</create>.

=head2 Custom ResultSet classes

To add methods to your resultsets, you can subclass L<DBIO::ResultSet>, similar to:

  package MyApp::Schema::ResultSet::User;

  use strict;
  use warnings;

  use base 'DBIO::ResultSet';

  sub active {
    my $self = shift;
    $self->search({ $self->current_source_alias . '.active' => 1 });
  }

  sub unverified {
    my $self = shift;
    $self->search({ $self->current_source_alias . '.verified' => 0 });
  }

  sub created_n_days_ago {
    my ($self, $days_ago) = @_;
    $self->search({
      $self->current_source_alias . '.create_date' => {
        '<=',
      $self->result_source->schema->storage->datetime_parser->format_datetime(
        DateTime->now( time_zone => 'UTC' )->subtract( days => $days_ago )
      )}
    });
  }

  sub users_to_warn { shift->active->unverified->created_n_days_ago(7) }

  1;

A method that ends in L</search> hands its caller's context on to it, and
L</search> throws in list context (ADR 0042). End the method in L</search_rs>
if it is to be called there, as in C<< [ $rs->active, $rs->unverified ] >>.

See L<DBIO::Schema/load_namespaces> on how DBIO can discover and
automatically attach L<Result|DBIO::Manual::ResultClass>-specific
L<ResulSet|DBIO::ResultSet> classes.

=head3 ResultSet subclassing with custom constructors

DBIO does not require Moose, Moo, or any other constructor layer for custom
ResultSet classes. A plain subclass of L<DBIO::ResultSet> is usually enough.

If you do use an external constructor provider, you must adapt its constructor
to DBIO's C<< ->new($source, \%args) >> calling convention.

In order to write custom ResultSet classes with L<Moo> you need to use the
following template. The L<BUILDARGS|Moo/BUILDARGS> is necessary due to the
unusual signature of the L<constructor provided by DBIO
|DBIO::ResultSet/new> C<< ->new($source, \%args) >>.

  use Moo;
  extends 'DBIO::ResultSet';
  sub BUILDARGS { $_[2] || {} } # ::RS::new() expects my ($class, $rsrc, $args) = @_

  ...your code...

  1;

If you want to build your custom ResultSet classes with L<Moose>, you need
a similar, though a little more elaborate template in order to interface the
inlining of the L<Moose>-provided
L<object constructor|Moose::Manual::Construction/WHERE'S THE CONSTRUCTOR?>,
with the DBIO one.

  package MyApp::Schema::ResultSet::User;

  use Moose;
  use MooseX::NonMoose;
  extends 'DBIO::ResultSet';

  sub BUILDARGS { $_[2] || {} } # ::RS::new() expects my ($class, $rsrc, $args) = @_

  ...your code...

  __PACKAGE__->meta->make_immutable;

  1;

The L<MooseX::NonMoose> is necessary so that the L<Moose> constructor does not
entirely overwrite the DBIO one (in contrast L<Moo> does this automatically).
Alternatively, you can skip L<MooseX::NonMoose> and get by with just L<Moose>
instead by doing:

  __PACKAGE__->meta->make_immutable(inline_constructor => 0);

=head1 ASYNC

An async mode is chosen B<per connection> (ADR 0030), not by naming a storage
class -- C<< MyApp::Schema->connect($dsn, $user, $pass, { async => 'future_io' }) >>
(or C<'ev'>, C<'immediate'>, C<'forked'> -- see L<DBIO::Storage::Async>). With
a mode that has a backend behind it, the C<*_async> methods below are genuinely
non-blocking on that connection, not a synchronous call wrapped in a resolved
Future (ADR 0031). The C<'immediate'> mode has no backend and is that wrapper
(see the dispatch contract below), and a few operations that do not go out as
one async statement run synchronously in every mode -- L</create_async> and
L</upsert_async> name them.

A runtime failure arrives as a failed Future: an error while the pooled
backend is resolved or the statement is built (the connection cannot be made,
say) fails the Future the call returns, with the message as thrown. Misuse is
an exception at the call: a connection without an async mode, a resultset
bound to a context that is expired or not its own (L</with_context>), and
arguments the call refuses (an unknown option, no data, a capability the
storage does not declare, as with L</upsert_async>).

The full C<*_async> surface on a ResultSet is:

=over 4

=item * Reads: L</all_async>, L</first_async>, L</single_async>, L</count_async>, L</count_literal_async>, L</find_async>, L</results_exist_async>

=item * Writes: L</create_async>, L</find_or_create_async>, L</update_or_create_async>, L</upsert_async>

=item * Composite finders (may or may not write): L</find_or_new_async>, L</update_or_new_async>

=back

C<find_async> is worth calling out on its own: it is not simply C<single_async>
wrapped in a Future. It shares C<find>'s own unique-constraint-narrowed,
relationship-key-aware condition resolution, so a relationship-valued key
resolves to a concrete foreign-key value exactly as sync C<find> does, and a
relation that cannot resolve to one is a safe miss -- C<undef>, no query issued
at all (ADR 0034). C<single_async>, like sync C<single>, takes its condition raw
with no such resolution; reach for C<find_async> when you want C<find>'s lookup
semantics, C<single_async> only where you would also reach for plain C<single>.

ResultSet's other write/helper methods (C<update>, C<update_all>, C<delete>,
C<delete_all>, C<populate>) have no async twin. Row by row, use
L<DBIO::Row/update_async> and L<DBIO::Row/delete_async>.

Every C<*_async> method shares one three-way dispatch contract:

=over 4

=item * a live embedded async backend

The read/write is routed through the storage's own C<*_async> operation and
the raw result is inflated (with full prefetch/collapse parity to the
synchronous method) in the returned L<DBIO::Future>'s C<then>. Genuinely
non-blocking.

=item * the C<immediate> mode (an async mode is chosen, but no event-loop backend)

The ordinary synchronous method runs in-process and its result is wrapped in
an already-resolved Future via L<DBIO::Storage/future_class>.

=item * a plain synchronous connection (no async mode chosen at C<connect>)

Croaks: C<< "not an async connection -- connect with { async => ... } to use
${name}_async" >>. There is no silent degrade.

=back

See F<t/resultset/async_backend.t> and F<t/resultset/find_async.t> for
runnable examples of all of the above against a mock async backend (no event
loop, no real database).

=head2 throw_exception

See L<DBIO::Schema/throw_exception> for details.

=head2 me

 $rs->search({ $rs->me.'title' => 'foo' })
 $rs->search({ $rs->me('title') => 'foo' })

Returns the current source alias with a dot appended (e.g. C<me.>),
suitable for use in search conditions. If an argument is passed, it is
appended to the alias.

=head2 order_by

 $rs->order_by('col1')                    # col1 ASC
 $rs->order_by('!col1')                   # col1 DESC
 $rs->order_by('col1,!col2')              # col1 ASC, col2 DESC
 $rs->order_by(qw(col1 !col2))            # same
 $rs->order_by(-desc => 'col1')           # col1 DESC
 $rs->order_by(-asc => 'col1,col2')       # col1 ASC, col2 ASC
 $rs->order_by(-desc => [qw(col1 col2)])  # col1 DESC, col2 DESC
 $rs->order_by({ -desc => 'col' })
 $rs->order_by({ -desc => 'col', -nulls => 'last' })  # col DESC NULLS LAST
 $rs->order_by(\'name DESC')
 $rs->order_by('col1', -desc => 'col2', { -asc => 'col3' })

Shortcut for C<< ->search(undef, { order_by => ... }) >>.

Takes a flat argument list whose elements may appear in any order and in
any mixture; the resulting order of the C<ORDER BY> clauses always follows
the order of the arguments. Accepted forms:

=over 4

=item * Magic strings

A bare string is a "magic string": a C<!> prefix means DESC (otherwise
ASC), and commas separate multiple columns, so C<'a,!b'> means C<a ASC, b
DESC>.

=item * Flat direction pairs

C<< -asc => $value >> and C<< -desc => $value >> set the direction for
C<$value> explicitly. C<$value> may be a single column, a comma separated
list of columns (each of them gets the given direction), or an arrayref of
either (one clause per element). The direction token is recognised strictly
as C<-asc> / C<-desc> with a leading dash, so a real column named C<desc>
is still treated as a column. A direction without a following value (or with
an undefined one) throws an exception. A C<$value> that is a ref other than
an arrayref is given the direction but is otherwise left untouched, so
C<< -desc => \'LENGTH(name)' >> orders by the literal descending.

=item * Refs, at any position

A ref means "the caller speaks native L<SQL::Abstract>" and is passed on
untouched: hashrefs are taken over as-is, literals (C<< \'name DESC' >> and
C<< \['name = ? DESC', $bind] >>) are handed through verbatim. An arrayref is
flattened one level, so that arguments following it append after its
contents, but its elements are B<not> parsed either - no magic string, no
qualification, no direction detection inside a ref.

=item * Position of NULLs

A hashref may carry C<-nulls> beside the direction, C<'first'> or C<'last'>,
and the clause renders as C<col DESC NULLS LAST>. It is kept through every
limit dialect, so it holds with C<rows>/C<offset> and with prefetch as well:

 $rs->order_by({ -desc => 'me.col', -nulls => 'last' })

=back

B<Qualification rule>: only what this method parses itself gets qualified
with the current source alias, and that is exactly two things - magic strings
at the top level, and the column names of top level C<-asc>/C<-desc> pairs
(in both cases only when they do not already contain a dot, so C<'rel.col'>
is left alone). Every ref at the top level belongs to L<SQL::Abstract> and is
never touched, its elements included. Note the deliberate asymmetry: an
arrayref I<as an argument> is native syntax and stays unqualified, while an
arrayref as the I<value of a direction pair> is this method's own sugar and
is qualified:

 $rs->order_by([qw(a b)])       # ORDER BY a, b
 $rs->order_by(-asc => [qw(a b)])  # ORDER BY me.a ASC, me.b ASC

The pass-through is the escape hatch for ordering by an output alias
introduced via C<+select>/C<-as>: pass it inside a ref and no C<me.> prefix
is added.

A single argument that is a ref is handed to the C<order_by> attribute
verbatim rather than inside a list; the resulting SQL is the same either way.

=head2 columns

 $rs->columns([qw/ col1 col2 /])

Shortcut for C<< ->search(undef, { columns => ... }) >>.

=head2 add_columns

 $rs->add_columns([qw/ extra_col1 extra_col2 /])

Shortcut for C<< ->search(undef, { '+columns' => ... }) >>.

=head2 remove_columns

 $rs->remove_columns([qw/ unwanted_col /])

Shortcut for C<< ->search(undef, { remove_columns => ... }) >>.

=head2 distinct

 $rs->distinct
 $rs->distinct(1)

Shortcut for C<< ->search(undef, { distinct => 1 }) >>.

=head2 group_by

 $rs->group_by([qw/ col1 col2 /])

Shortcut for C<< ->search(undef, { group_by => ... }) >>.

=head2 where

 $rs->where(col1 => 'value')          # flat list -> { col1 => 'value' }
 $rs->where({ -or => [ ... ] })       # single ref passed through verbatim
 $rs->where([ { a => 1 }, { b => 2 } ])
 $rs->where(\'raw sql')
 $rs->where()                         # no-op clone
 $rs->where('a')                      # throws: odd number of elements

Condition-only chaining shortcut for L</search_rs>: always returns a new
L<DBIO::ResultSet>, in every context. Takes I<either> a flat key/value list
(which is collapsed into a condition hashref), I<or> a single condition ref
(hashref/arrayref/literal, handed to the C<where> attribute untouched). A flat
list with an odd number of elements throws, as does an empty one-element call
like C<< where('a') >> -- both are unambiguous mistakes. No attributes are
accepted here: they belong to L</order_by>, L</group_by>, L</columns>,
L</rows> and L</offset>. Repeated C<< where() >> calls stack (AND semantics),
exactly like repeated L</search> conditions.

See ADR 0042 for the chaining contract.

=head2 having

 $rs->having(cnt => { '>' => 3 })     # flat list -> { cnt => { '>' => 3 } }
 $rs->having({ cnt => { '>' => 3 } }) # single ref passed through verbatim

Condition-only chaining shortcut for the C<having> search attribute, with the
same flat-list-or-single-ref signature as L</where> (odd flat lists throw).
Always returns a new L<DBIO::ResultSet>; repeated C<< having() >> calls stack
like L</where>.

=head2 offset

 $rs->offset(20)

Shortcut for C<< ->search(undef, { offset => ... }) >>. Always returns a new
L<DBIO::ResultSet>.

=head2 join

 $rs->join('artist')

Shortcut for C<< ->search(undef, { join => ... }) >>. Always returns a new
L<DBIO::ResultSet>. The join type comes from the relationship's
L<join_type|DBIO::Relationship::Base/join_type> attribute, exactly as it does
for a plain C<< search(undef, { join => ... }) >>: C<has_many>-style
relationships default to C<LEFT JOIN>, C<belongs_to> defaults to C<INNER
JOIN>. There is deliberately no C<left_join> helper: the
relationship declares the join type, and a C<belongs_to> that should join
left does so via its own C<join_type> attribute.

=head2 select

 $rs->select(\@cols, [\@as])
 $rs->select(\@cols)->as(\@aliases)
 $rs->select('me.cdid')
 $rs->select()                         # no-op clone

Shortcut for C<< ->search(undef, { select => ..., (as => ...) }) >>. Always
returns a new L<DBIO::ResultSet>. The select list may be an arrayref, a single
scalar, or any other C<select> structure SQL::Abstract understands. An optional
second argument supplies the alias list together with the select list (the
C<select>/C<as> pair must always be given together in a single search call --
see L</as>). Calling C<< select() >> with no arguments returns a clone without
changing the projection -- consistent with L</where> and L</having> (ADR 0042).

=head2 as

 $rs->select(\@cols)->as(\@aliases)

Sets the alias list for a L</select> already applied to the resultset. Always
returns a new L<DBIO::ResultSet>. Because the C<select>/C<as> pair is
normalized together (search_rs throws when C<as> is supplied without a
matching C<select>), C<as()> re-applies the current C<select> alongside the
new aliases rather than setting C<as> alone; calling it without a preceding
L</select> throws.

=head2 hri

 $rs->hri

Shortcut to set C<result_class> to
L<DBIO::ResultClass::HashRefInflator>.

=head2 rows

 $rs->rows(10)

Shortcut for C<< ->search(undef, { rows => ... }) >>.

=head2 limit

 $rs->limit(10)

Alias for L</rows>.

=head2 has_rows

 if ($rs->has_rows) { ... }

Lightweight check if the ResultSet contains any data, without counting
all rows.

=head2 limited_page

 $rs->limited_page(2, 10)
 $rs->limited_page({ page => 2, rows => 10 })

Combined L</page> + L</rows> shortcut.

=head2 prefetch

 $rs->prefetch('rel')
 $rs->prefetch('rel1', 'rel2')

Shortcut for C<< ->search(undef, { prefetch => ... }) >>.

=head2 null

 $rs->null('col')
 $rs->null([qw/ col1 col2 /])
 $rs->null('.col')

Search for rows where the given column(s) are NULL.

A column name starting with C<.> is qualified with the ResultSet's
L</current_source_alias>, so C<'.col'> becomes C<'me.col'>. Use it to stay
unambiguous when a join brings in a second column of the same name.

=head2 not_null

 $rs->not_null('col')
 $rs->not_null([qw/ col1 col2 /])

Search for rows where the given column(s) are NOT NULL. The C<.> prefix
described under L</null> works here too.

=head2 like

 $rs->like('col', '%pattern%')
 $rs->like([qw/ col1 col2 /], '%pattern%')

Search for rows where the given column(s) match the LIKE pattern. The C<.>
prefix described under L</null> works here too. Anything other than a plain
column name or an ARRAY reference of them throws.

=head2 not_like

 $rs->not_like('col', '%pattern%')
 $rs->not_like([qw/ col1 col2 /], '%pattern%')

Search for rows where the given column(s) do NOT match the LIKE pattern. Same
C<.> prefix and same argument check as L</like>.

=head2 results_exist

 my $bool = $rs->results_exist
 my $bool = $rs->results_exist(\%cond)

Uses SQL C<EXISTS> to efficiently check if the query would return any rows.
Much lighter than C<< $rs->count >>.

The statement executed is the one the storage's
L<DBIO::Storage::DBI/_exists_value_sql> hook renders -- a complete statement
yielding C<1> or C<0>, in the base rendering
C<SELECT CASE WHEN EXISTS E<lt>innerE<gt> THEN 1 ELSE 0 END> -- and it is only
issued when the storage declares the C<supports_exists_query> capability (ADR
0037). On an engine whose driver has not declared it, this throws instead of
sending SQL the engine may not parse; it never degrades silently to a
different query shape. The portable alternative is L</has_rows>, which works
everywhere:

  $storage->_use_supports_exists_query ? $rs->results_exist : $rs->has_rows

=head2 results_exist_async

  my $future = $rs->results_exist_async
  my $future = $rs->results_exist_async(\%cond)
  $future->then(sub { my $bool = shift; ... });

Async variant of L</results_exist>, resolving the B<identical> statement: the
one L<DBIO::Storage::DBI/_exists_value_sql> renders. That statement is complete
(its base form has no C<FROM> at all), so it carries no ident / select / where
to hand to the CRUD entry points; it goes to the transport's raw-SQL seam
C<_query_async>, the same seam L<DBIO::Storage::Async/_execute_ddl_async> uses
for statements core has rendered itself.

The capability check is a static precondition, decidable without I/O, so it
throws B<synchronously> here rather than failing the Future -- exactly as
C<_rs_run_async> already does for "not an async connection" (ADR 0037
section 4).

=head2 results_exist_as_query

 my $query = $rs->results_exist_as_query
 my $query = $rs->results_exist_as_query(\%cond)

Returns a subquery reference that evaluates to a boolean via SQL C<EXISTS>.
Useful for correlated subqueries.

The fragment is the storage's own rendering (see L</results_exist>) in a pair
of parentheses -- a parenthesised scalar subquery is universal, and that is the
entire decoration core adds. It is gated by the same C<supports_exists_query>
capability, and throws for the same reason: the fragment would otherwise be
embedded in a larger query and fail far from its cause.

=head2 correlate

 $rs->correlate('relationship')

Returns a ResultSet for the given relationship that is correlated to the
current ResultSet, suitable for use in subqueries.

 # count books per author
 $author_rs->search(undef, {
   '+columns' => {
     book_count => $author_rs->correlate('books')->count_rs->as_query
   }
 });

=head2 search_or

 $rs->search_or([ $rs->method1, $rs->method2 ])

Combine multiple ResultSet searches with OR logic. All ResultSets must
share the same result source.

The methods in the arrayref are called in list context. One that ends in
L</search> throws there (ADR 0042); it has to return its resultset through
L</search_rs>.

=head2 union

 $rs1->union($rs2)
 $rs1->union([$rs2, $rs3])

=head2 union_all

=head2 intersect

=head2 intersect_all

=head2 except

=head2 except_all

SQL set operations on ResultSets. All operands must select the same
columns and use the same result class.

All six take their keyword from the storage's
L<DBIO::Storage::DBI/_set_operation_keyword> hook, which is asked once per
call with the canonical operation name -- the method's own name (ADR 0039).
The base implementation answers with the ANSI spelling of each, so nothing
changes for an engine that has them all; C<DBIO::Oracle::Storage> answers
C<MINUS> for L</except>. Building the query therefore needs no database
connection.

The same hook is where an engine B<refuses> an operation it does not have
(Oracle has no C<MINUS ALL> before 21c; SQLite and SQL Server have no
C<EXCEPT ALL> / C<INTERSECT ALL>). The keyword is resolved B<before any
operand SQL is assembled>, so a refusing engine throws at query-build time
and never hands back a fragment that could be embedded in a larger query --
the same argument ADR 0037 section 4 made for
L</results_exist_as_query>.

The operands must be bound alike (ADR 0045): all of them unbound, or all of
them bound with L</with_context> to the same context -- the same object, not an
equal one. The result carries that binding. A mixture is refused when the
operation is built, before any operand is rendered: an unbound resultset with a
bound operand, a bound one with an unbound operand, and operands bound to two
different contexts (two transactions) alike. The exception names the operation
and the operands that differ from the one the operation is called on, which is
operand 0:

  union: the operands of a set operation must be bound alike, all unbound or
  all to the same async context -- operand 0 (the caller) is unbound,
  operand 2 is bound to DBIO::Storage::Async::...=HASH(0x...)

The rule is about the binding alone and holds for the result's synchronous use
as well. A statement cannot run partly inside a transaction and partly outside
it; bind every operand to the context, or none.

=head2 one_row

  my $result = $rs->one_row;
  my $result = $rs->one_row(\%cond);

Returns a single result object, or C<undef> if there are none. Applies a
C<< rows => 1 >> limit and returns L</next>, so only one row is requested from
the database rather than the whole set being pulled into a cursor first. An
optional search condition is applied before fetching.

=head2 no_columns

  my $rs = $rs->no_columns;

Returns a new resultset with the column selection cleared (C<< columns => [] >>),
as a starting point for a custom projection built up with C<+columns> or
C<+select>.

=head2 bare

  my $rs = $rs->bare;

Returns a fresh, unsearched resultset for the same result source, discarding
any search conditions and attributes accumulated on the current resultset. A
binding made with L</with_context> is neither and stays.

=head2 rand

  my $rs = $rs->rand;       # one random row
  my $rs = $rs->rand($n);   # $n random rows

Returns a resultset ordered by the storage's random function
(L<DBIO::Storage::DBI/_random_function>) and limited to C<$amount> rows
(default 1). C<$amount> must be a positive integer, otherwise an exception is
thrown.

=head2 explain

  my $plan = $rs->explain;

Returns the database query plan for this resultset's query. The whole operation
is delegated to the storage's L<DBIO::Storage::DBI/_explain_query> hook; the
return value is the plan as an arrayref of row arrayrefs, whose columns are
engine-specific.

=head1 ATTRIBUTES

Attributes are used to refine a ResultSet in various ways when
searching for data. They can be passed to any method which takes an
C<\%attrs> argument. See L</search>, L</search_rs>, L</find>,
L</count>.

Default attributes can be set on the result class using
L<DBIO::ResultSource/resultset_attributes>.  (Please read
the CAVEATS on that feature before using it!)

These are in no particular order:

=head2 order_by

=over 4

=item Value: ( $order_by | \@order_by | \%order_by )

=back

Which column(s) to order the results by.

[The full list of suitable values is documented in
L<SQL::Abstract/"ORDER BY CLAUSES">; the following is a summary of
common options.]

If a single column name, or an arrayref of names is supplied, the
argument is passed through directly to SQL. The hashref syntax allows
for connection-agnostic specification of ordering direction:

 For descending order:

  order_by => { -desc => [qw/col1 col2 col3/] }

 For explicit ascending order:

  order_by => { -asc => 'col' }

 For a chosen position of the NULLs ('first' or 'last'):

  order_by => { -desc => 'col', -nulls => 'last' }  # col DESC NULLS LAST

The old scalarref syntax (i.e. order_by => \'year DESC') is still
supported, although you are strongly encouraged to use the hashref
syntax as outlined above.

=head2 columns

=over 4

=item Value: \@columns | \%columns | $column

=back

Shortcut to request a particular set of columns to be retrieved. Each
column spec may be a string (a table column name), or a hash (in which
case the key is the C<as> value, and the value is used as the C<select>
expression). Adds the L</current_source_alias> onto the start of any column without a C<.> in
it and sets C<select> from that, then auto-populates C<as> from
C<select> as normal. (You may also use the C<cols> attribute, as in
earlier versions of DBIx::Class, but this is deprecated)

Essentially C<columns> does the same as L</select> and L</as>.

    columns => [ 'some_column', { dbic_slot => 'another_column' } ]

is the same as

    select => [qw(some_column another_column)],
    as     => [qw(some_column dbic_slot)]

If you want to individually retrieve related columns (in essence perform
manual L</prefetch>) you have to make sure to specify the correct inflation slot
chain such that it matches existing relationships:

    my $rs = $schema->resultset('Artist')->search({}, {
        # required to tell DBIO to collapse has_many relationships
        collapse => 1,
        join     => { cds => 'tracks' },
        '+columns'  => {
          'cds.cdid'         => 'cds.cdid',
          'cds.tracks.title' => 'tracks.title',
        },
    });

Like elsewhere, literal SQL or literal values can be included by using a
scalar reference or a literal bind value, and these values will be available
in the result with C<get_column> (see also
L<SQL::Abstract/Literal SQL and value type operators>):

    # equivalent SQL: SELECT 1, 'a string', IF(my_column,?,?) ...
    # bind values: $true_value, $false_value
    columns => [
        {
            foo => \1,
            bar => \q{'a string'},
            baz => \[ 'IF(my_column,?,?)', $true_value, $false_value ],
        }
    ]

=head2 +columns

B<NOTE:> You B<MUST> explicitly quote C<'+columns'> when using this attribute.
Not doing so causes Perl to incorrectly interpret C<+columns> as a bareword
with a unary plus operator before it, which is the same as simply C<columns>.

=over 4

=item Value: \@extra_columns

=back

Indicates additional columns to be selected from storage. Works the same as
L</columns> but adds columns to the current selection. (You may also use the
C<include_columns> attribute, as in earlier versions of DBIx::Class, but this is
deprecated)

  $schema->resultset('CD')->search(undef, {
    '+columns' => ['artist.name'],
    join => ['artist']
  });

would return all CDs and include a 'name' column to the information
passed to object inflation. Note that the 'artist' is the name of the
column (or relationship) accessor, and 'name' is the name of the column
accessor in the related table.

=head2 remove_columns

=over 4

=item Value: \@columns

=back

Selects every column of the result source except the listed ones. The list is
resolved when the query is built, so a L</columns> or L</select> anywhere in
the chain wins and the attribute is then ignored; L</+columns> and L</+select>
add to what is left. A later C<remove_columns> replaces an earlier one, the
two lists are not combined.

  # every column of 'artist' but 'rank'
  my $rs = $schema->resultset('Artist')->search(undef, { remove_columns => ['rank'] });

=head2 select

=over 4

=item Value: \@select_columns

=back

Indicates which columns should be selected from the storage. You can use
column names, or in the case of RDBMS back ends, function or stored procedure
names:

  $rs = $schema->resultset('Employee')->search(undef, {
    select => [
      'name',
      { count => 'employeeid' },
      { max => { length => 'name' }, -as => 'longest_name' }
    ]
  });

  # Equivalent SQL
  SELECT name, COUNT( employeeid ), MAX( LENGTH( name ) ) AS longest_name FROM employee

B<NOTE:> You will almost always need a corresponding L</as> attribute when you
use L</select>, to instruct DBIO how to store the result of the column.

Also note that the L</as> attribute has B<nothing to do> with the SQL-side
C<AS> identifier aliasing. You B<can> alias a function (so you can use it e.g.
in an C<ORDER BY> clause), however this is done via the C<-as> B<select
function attribute> supplied as shown in the example above.

=head2 +select

B<NOTE:> You B<MUST> explicitly quote C<'+select'> when using this attribute.
Not doing so causes Perl to incorrectly interpret C<+select> as a bareword
with a unary plus operator before it, which is the same as simply C<select>.

=over 4

=item Value: \@extra_select_columns

=back

Indicates additional columns to be selected from storage.  Works the same as
L</select> but adds columns to the current selection, instead of specifying
a new explicit list.

=head2 as

=over 4

=item Value: \@inflation_names

=back

Indicates DBIO-side names for object inflation. That is L</as> indicates the
slot name in which the column value will be stored within the
L<Row|DBIO::Row> object. The value will then be accessible via this
identifier by the C<get_column> method (or via the object accessor B<if one
with the same name already exists>) as shown below.

The L</as> attribute has B<nothing to do> with the SQL-side identifier
aliasing C<AS>. See L</select> for details.

  $rs = $schema->resultset('Employee')->search(undef, {
    select => [
      'name',
      { count => 'employeeid' },
      { max => { length => 'name' }, -as => 'longest_name' }
    ],
    as => [qw/
      name
      employee_count
      max_name_length
    /],
  });

If the object against which the search is performed already has an accessor
matching a column name specified in C<as>, the value can be retrieved using
the accessor as normal:

  my $name = $employee->name();

If on the other hand an accessor does not exist in the object, you need to
use C<get_column> instead:

  my $employee_count = $employee->get_column('employee_count');

You can create your own accessors if required - see
L<DBIO::Manual::Cookbook> for details.

=head2 +as

B<NOTE:> You B<MUST> explicitly quote C<'+as'> when using this attribute.
Not doing so causes Perl to incorrectly interpret C<+as> as a bareword
with a unary plus operator before it, which is the same as simply C<as>.

=over 4

=item Value: \@extra_inflation_names

=back

Indicates additional inflation names for selectors added via L</+select>. See L</as>.

=head2 join

=over 4

=item Value: ($rel_name | \@rel_names | \%rel_names)

=back

Contains a list of relationships that should be joined for this query.

B<Note:> In most cases you do not need to specify C<join> explicitly. DBIO
automatically discovers required joins from dotted column names in your
search conditions. For example, C<< 'artist.name' => 'Nine Inch Nails' >>
will automatically add the C<artist> join. You only need explicit C<join>
when referencing relationships in C<select>, C<order_by>, or other
attributes that are not part of the WHERE/HAVING conditions.

  # Automatic -- join is discovered from the condition:
  my $rs = $schema->resultset('CD')->search(
    { 'artist.name' => 'Nine Inch Nails' }
  );

  # Equivalent explicit form (still supported):
  my $rs = $schema->resultset('CD')->search(
    { 'artist.name' => 'Nine Inch Nails' },
    { join => 'artist' }
  );

Can also contain a hash reference to refer to the other relation's relations.
For example:

  package MyApp::Schema::Track;
  use base qw/DBIO/;
  __PACKAGE__->table('track');
  __PACKAGE__->add_columns(qw/trackid cd position title/);
  __PACKAGE__->set_primary_key('trackid');
  __PACKAGE__->belongs_to(cd => 'MyApp::Schema::CD');
  1;

  # In your application
  my $rs = $schema->resultset('Artist')->search(
    { 'track.title' => 'Teardrop' },
    {
      join     => { cd => 'track' },
      order_by => 'artist.name',
    }
  );

You need to use the relationship (not the table) name in  conditions,
because they are aliased as such. The current table is aliased as "me", so
you need to use me.column_name in order to avoid ambiguity. For example:

  # Get CDs from 1984 with a 'Foo' track
  my $rs = $schema->resultset('CD')->search(
    {
      'me.year' => 1984,
      'tracks.name' => 'Foo'
    },
    { join => 'tracks' }
  );

If the same join is supplied twice, it will be aliased to <rel>_2 (and
similarly for a third time). For e.g.

  my $rs = $schema->resultset('Artist')->search({
    'cds.title'   => 'Down to Earth',
    'cds_2.title' => 'Popular',
  }, {
    join => [ qw/cds cds/ ],
  });

will return a set of all artists that have both a cd with title 'Down
to Earth' and a cd with title 'Popular'.

If you want to fetch related objects from other tables as well, see L</prefetch>
below.

 NOTE: An internal join-chain pruner will discard certain joins while
 constructing the actual SQL query, as long as the joins in question do not
 affect the retrieved result. This for example includes 1:1 left joins
 that are not part of the restriction specification (WHERE/HAVING) nor are
 a part of the query selection.

For more help on using joins with search, see L<DBIO::Manual::Joining>.

=head2 collapse

=over 4

=item Value: (0 | 1)

=back

When set to a true value, indicates that any rows fetched from joined has_many
relationships are to be aggregated into the corresponding "parent" object. For
example, the resultset:

  my $rs = $schema->resultset('CD')->search({}, {
    '+columns' => [ qw/ tracks.title tracks.position / ],
    join => 'tracks',
    collapse => 1,
  });

While executing the following query:

  SELECT me.*, tracks.title, tracks.position
    FROM cd me
    LEFT JOIN track tracks
      ON tracks.cdid = me.cdid

Will return only as many objects as there are rows in the CD source, even
though the result of the query may span many rows. Each of these CD objects
will in turn have multiple "Track" objects hidden behind the has_many
generated accessor C<tracks>. Without C<< collapse => 1 >>, the return values
of this resultset would be as many CD objects as there are tracks (a "Cartesian
product"), with each CD object containing exactly one of all fetched Track data.

When a collapse is requested on a non-ordered resultset, an order by some
unique part of the main source (the left-most table) is inserted automatically.
This is done so that the resultset is allowed to be "lazy" - calling
L<< $rs->next|/next >> will fetch only as many rows as it needs to build the next
object with all of its related data.

If an L</order_by> is already declared, and orders the resultset in a way that
makes collapsing as described above impossible (e.g. C<< ORDER BY
has_many_rel.column >> or C<ORDER BY RANDOM()>), DBIO will automatically
switch to "eager" mode and slurp the entire resultset before constructing the
first object returned by L</next>.

Setting this attribute on a resultset that does not join any has_many
relations is a no-op.

The C<*_async> read methods (see L</ASYNC>) honour C<collapse> with full
parity to their synchronous counterparts.

For a more in-depth discussion, see L</PREFETCHING>.

=head2 prefetch

=over 4

=item Value: ($rel_name | \@rel_names | \%rel_names)

=back

This attribute is a shorthand for specifying a L</join> spec, adding all
columns from the joined related sources as L</+columns> and setting
L</collapse> to a true value. It can be thought of as a rough B<superset>
of the L</join> attribute.

For example, the following two queries are equivalent:

  my $rs = $schema->resultset('Artist')->search({}, {
    prefetch => { cds => ['genre', 'tracks' ] },
  });

and

  my $rs = $schema->resultset('Artist')->search({}, {
    join => { cds => ['genre', 'tracks' ] },
    collapse => 1,
    '+columns' => [
      (map
        { +{ "cds.$_" => "cds.$_" } }
        $schema->source('Artist')->related_source('cds')->columns
      ),
      (map
        { +{ "cds.genre.$_" => "genre.$_" } }
        $schema->source('Artist')->related_source('cds')->related_source('genre')->columns
      ),
      (map
        { +{ "cds.tracks.$_" => "tracks.$_" } }
        $schema->source('Artist')->related_source('cds')->related_source('tracks')->columns
      ),
    ],
  });

Both producing the following SQL:

  SELECT  me.artistid, me.name, me.rank, me.charfield,
          cds.cdid, cds.artist, cds.title, cds.year, cds.genreid, cds.single_track,
          genre.genreid, genre.name,
          tracks.trackid, tracks.cd, tracks.position, tracks.title, tracks.last_updated_on, tracks.last_updated_at
    FROM artist me
    LEFT JOIN cd cds
      ON cds.artist = me.artistid
    LEFT JOIN genre genre
      ON genre.genreid = cds.genreid
    LEFT JOIN track tracks
      ON tracks.cd = cds.cdid
  ORDER BY me.artistid

While L</prefetch> implies a L</join>, it is ok to mix the two together, as
the arguments are properly merged and generally do the right thing. For
example, you may want to do the following:

  my $artists_and_cds_without_genre = $schema->resultset('Artist')->search(
    { 'genre.genreid' => undef },
    {
      join => { cds => 'genre' },
      prefetch => 'cds',
    }
  );

Which generates the following SQL:

  SELECT  me.artistid, me.name, me.rank, me.charfield,
          cds.cdid, cds.artist, cds.title, cds.year, cds.genreid, cds.single_track
    FROM artist me
    LEFT JOIN cd cds
      ON cds.artist = me.artistid
    LEFT JOIN genre genre
      ON genre.genreid = cds.genreid
  WHERE genre.genreid IS NULL
  ORDER BY me.artistid

The C<*_async> read methods (see L</ASYNC>) inflate prefetched relations
with full parity to their synchronous counterparts.

For a more in-depth discussion, see L</PREFETCHING>.

=head2 alias

=over 4

=item Value: $source_alias

=back

Sets the source alias for the query.  Normally, this defaults to C<me>, but
nested search queries (sub-SELECTs) might need specific aliases set to
reference inner queries.  For example:

   my $q = $rs
      ->related_resultset('CDs')
      ->related_resultset('Tracks')
      ->search({
         'track.id' => { -ident => 'none_search.id' },
      })
      ->as_query;

   my $ids = $self->search({
      -not_exists => $q,
   }, {
      alias    => 'none_search',
      group_by => 'none_search.id',
   })->get_column('id')->as_query;

   $self->search({ id => { -in => $ids } })

This attribute is directly tied to L</current_source_alias>.

=head2 page

=over 4

=item Value: $page

=back

Makes the resultset paged and specifies the page to retrieve. Effectively
identical to creating a non-pages resultset and then calling ->page($page)
on it.

If L</rows> attribute is not specified it defaults to 10 rows per page.

When you have a paged resultset, L</count> will only return the number
of rows in the page. To get the total, use the L</pager> and call
C<total_entries> on it.

=head2 rows

=over 4

=item Value: $rows

=back

Specifies the maximum number of rows for direct retrieval or the number of
rows per page if the L</page> attribute or method is used.

See also L</offset>, L</page> and L</software_limit>.

=head2 offset

=over 4

=item Value: $offset

=back

Specifies the (zero-based) row number of the first row to be returned, or of
the first row of the first page if paging is used.

See also L</rows>, L</page> and L</software_limit>.

=head2 software_limit

=over 4

=item Value: (0 | 1)

=back

When combined with L</rows> and/or L</offset> the generated SQL will not
include any limit dialect stanzas. Instead the entire result will be selected
as if no limits were specified, and DBIO will perform the limit locally, by
artificially advancing and finishing the resulting L</cursor>.

This is the recommended way of performing resultset limiting when no sane RDBMS
implementation is available (e.g.
L<Sybase ASE|DBIO::Sybase::Storage::ASE> using the Generic Sub Query
hack)

=head2 group_by

=over 4

=item Value: \@columns

=back

An arrayref of columns to group by. Can include columns of joined tables.

  group_by => [qw/ column1 column2 ... /]

See also L</having> for post-grouping constraints, and L</distinct>, which
generates a C<group_by> automatically from the selection.

=head2 having

=over 4

=item Value: $condition

=back

The HAVING operator specifies a B<secondary> condition applied to the set
after the grouping calculations have been done. In other words it is a
constraint just like L</where> (and accepting the same
L<SQL::Abstract syntax|SQL::Abstract/WHERE CLAUSES>) applied
to the data as it exists after GROUP BY has taken place. Specifying L</having>
without L</group_by> is a logical mistake, and a fatal error on most RDBMS
engines.

E.g.

  having => { 'count_employee' => { '>=', 100 } }

or with an in-place function in which case literal SQL is required:

  having => \[ 'count(employee) >= ?', 100 ]

=head2 distinct

=over 4

=item Value: (0 | 1)

=back

Set to 1 to automatically generate a L</group_by> clause based on the selection
(including intelligent handling of L</order_by> contents). Note that the group
criteria calculation takes place over the B<final> selection. This includes
any L</+columns>, L</+select> or L</order_by> additions in subsequent
L</search> calls, and standalone columns selected via
L<DBIO::ResultSetColumn> (L</get_column>). A notable exception are the
extra selections specified via L</prefetch> - such selections are explicitly
excluded from group criteria calculations.

If the final ResultSet also explicitly defines a L</group_by> attribute, this
setting is ignored and an appropriate warning is issued.

=head2 where

=over 4

=item Value: $condition

=back

Adds to the WHERE clause, accepting the same
L<SQL::Abstract syntax|SQL::Abstract/WHERE CLAUSES> as the condition passed
to L</search>. Most useful as a default set on the result class, so that
every search from that source carries the restriction:

  # only return rows WHERE deleted IS NULL for all searches
  __PACKAGE__->resultset_attributes({ where => { deleted => undef } });

A C<where> set this way cannot be taken off again by a later search: every
further condition, a C<where> attribute included, is ANDed onto it, and
C<< { where => undef } >> leaves it in place. See also L</having> for a
constraint applied after L</group_by>.

=head2 cache

=over 4

=item Value: (0 | 1)

=back

Set to 1 to cache search results. This prevents extra SQL queries if you
revisit rows in your ResultSet:

  my $resultset = $schema->resultset('Artist')->search( undef, { cache => 1 } );

  while( my $artist = $resultset->next ) {
    ... do stuff ...
  }

  $rs->first; # without cache, this would issue a query

By default, searches are not cached.

For more examples of using these attributes, see
L<DBIO::Manual::Cookbook>.

=head2 for

=over 4

=item Value: ( 'update' | 'shared' | \$scalar )

=back

Set to 'update' for a SELECT ... FOR UPDATE or 'shared' for a SELECT
... FOR SHARE. If \$scalar is passed, its content is appended after the keyword
C<FOR>: C<< for => \'UPDATE SKIP LOCKED' >> renders C<FOR UPDATE SKIP LOCKED>.

=head1 PREFETCHING

DBIO supports arbitrary related data prefetching from multiple related
sources. Any combination of relationship types and column sets are supported.
If L<collapsing|/collapse> is requested, there is an additional requirement of
selecting enough data to make every individual object uniquely identifiable.

Here are some more involved examples, based on the following relationship map:

  # Assuming:
  My::Schema::CD->belongs_to( artist      => 'My::Schema::Artist'     );
  My::Schema::CD->might_have( liner_note  => 'My::Schema::LinerNotes' );
  My::Schema::CD->has_many(   tracks      => 'My::Schema::Track'      );

  My::Schema::Artist->belongs_to( record_label => 'My::Schema::RecordLabel' );

  My::Schema::Track->has_many( guests => 'My::Schema::Guest' );



  my $rs = $schema->resultset('Tag')->search(
    undef,
    {
      prefetch => {
        cd => 'artist'
      }
    }
  );

The initial search results in SQL like the following:

  SELECT tag.*, cd.*, artist.* FROM tag
  JOIN cd ON tag.cd = cd.cdid
  JOIN artist ON cd.artist = artist.artistid

L<DBIO> has no need to go back to the database when we access the
C<cd> or C<artist> relationships, which saves us two SQL statements in this
case.

Simple prefetches will be joined automatically, so there is no need
for a C<join> attribute in the above search.

The L</prefetch> attribute can be used with any of the relationship types
and multiple prefetches can be specified together. Below is a more complex
example that prefetches a CD's artist, its liner notes (if present),
the cover image, the tracks on that CD, and the guests on those
tracks.

  my $rs = $schema->resultset('CD')->search(
    undef,
    {
      prefetch => [
        { artist => 'record_label'},  # belongs_to => belongs_to
        'liner_note',                 # might_have
        'cover_image',                # has_one
        { tracks => 'guests' },       # has_many => has_many
      ]
    }
  );

This will produce SQL like the following:

  SELECT cd.*, artist.*, record_label.*, liner_note.*, cover_image.*,
         tracks.*, guests.*
    FROM cd me
    JOIN artist artist
      ON artist.artistid = me.artistid
    JOIN record_label record_label
      ON record_label.labelid = artist.labelid
    LEFT JOIN track tracks
      ON tracks.cdid = me.cdid
    LEFT JOIN guest guests
      ON guests.trackid = track.trackid
    LEFT JOIN liner_notes liner_note
      ON liner_note.cdid = me.cdid
    JOIN cd_artwork cover_image
      ON cover_image.cdid = me.cdid
  ORDER BY tracks.cd

Now the C<artist>, C<record_label>, C<liner_note>, C<cover_image>,
C<tracks>, and C<guests> of the CD will all be available through the
relationship accessors without the need for additional queries to the
database.

=head3 CAVEATS

Prefetch does a lot of deep magic. As such, it may not behave exactly
as you might expect.

=over 4

=item *

Prefetch uses the L</cache> to populate the prefetched relationships. This
may or may not be what you want.

=item *

If you specify a condition on a prefetched relationship, ONLY those
rows that match the prefetched condition will be fetched into that relationship.
This means that adding prefetch to a search() B<may alter> what is returned by
traversing a relationship. So, if you have C<< Artist->has_many(CDs) >> and you do

  my $artist_rs = $schema->resultset('Artist')->search({
      'cds.year' => 2008,
  }, {
      join => 'cds',
  });

  my $count = $artist_rs->first->cds->count;

  my $artist_rs_prefetch = $artist_rs->search( {}, { prefetch => 'cds' } );

  my $prefetch_count = $artist_rs_prefetch->first->cds->count;

  cmp_ok( $count, '==', $prefetch_count, "Counts should be the same" );

That cmp_ok() may or may not pass depending on the datasets involved. In other
words the C<WHERE> condition would apply to the entire dataset, just like
it would in regular SQL. If you want to add a condition only to the "right side"
of a C<LEFT JOIN> - consider declaring and using a L<relationship with a custom
condition|DBIO::Relationship::Base/condition>

=back

=head1 DBIO BIND VALUES

Because DBIO may need more information to bind values than just the column name
and value itself, it uses a special format for both passing and receiving bind
values.  Each bind value should be composed of an arrayref of
C<< [ \%args => $val ] >>.  The format of C<< \%args >> is currently:

=over 4

=item dbd_attrs

If present (in any form), this is what is being passed directly to bind_param.
Note that different DBD's expect different bind args.  (e.g. DBD::SQLite takes
a single numerical type, while DBD::Pg takes a hashref if bind options.)

If this is specified, all other bind options described below are ignored.

=item sqlt_datatype

If present, this is used to infer the actual bind attribute by passing to
C<< $resolved_storage->bind_attribute_by_data_type() >>.  Defaults to the
"data_type" from the L<add_columns column info|DBIO::ResultSource/add_columns>.

Note that the data type is somewhat freeform (hence the sqlt_ prefix);
currently drivers are expected to "Do the Right Thing" when given a common
datatype name.  (Not ideal, but that's what we got at this point.)

=item sqlt_size

Currently used to correctly allocate buffers for bind_param_inout().
Defaults to "size" from the L<add_columns column info|DBIO::ResultSource/add_columns>,
or to a sensible value based on the "data_type".

=item dbic_colname

Used to fill in missing sqlt_datatype and sqlt_size attributes (if they are
explicitly specified they are never overridden).  Also used by some weird DBDs,
where the column name should be available at bind_param time (e.g. Oracle).

=back

For backwards compatibility and convenience, the following shortcuts are
supported:

  [ $name => $val ] === [ { dbic_colname => $name }, $val ]
  [ \$dt  => $val ] === [ { sqlt_datatype => $dt }, $val ]
  [ undef,   $val ] === [ {}, $val ]
  $val              === [ {}, $val ]

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
