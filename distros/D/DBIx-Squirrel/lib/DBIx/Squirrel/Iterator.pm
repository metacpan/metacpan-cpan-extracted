package    # hide from PAUSE
    DBIx::Squirrel::Iterator;

use 5.010_001;
use strict;
use warnings;
use Scalar::Util qw/weaken looks_like_number/;
use Sub::Name;
use DBIx::Squirrel::Utils qw/args_partition throw whine/;
use namespace::clean;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    require Exporter;
    $DBIx::Squirrel::Iterator::VERSION   = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::Iterator::ISA       = qw/Exporter/;
    @DBIx::Squirrel::Iterator::EXPORT_OK = qw/
        database
        iterator
        result
        result_current
        result_first
        result_number
        result_offset
        result_original
        result_prev
        result_previous
        result_transform
        statement
        /;
    @DBIx::Squirrel::Iterator::EXPORT = @DBIx::Squirrel::Iterator::EXPORT_OK;
    $DBIx::Squirrel::Iterator::DEFAULT_SLICE      = [];    # Faster!
    $DBIx::Squirrel::Iterator::DEFAULT_CACHE_SIZE = 2;     # Initial buffer size and autoscaling increment
    $DBIx::Squirrel::Iterator::CACHE_SIZE_LIMIT   = 64;    # Absolute maximum buffersize
}

use constant E_BAD_STH   => 'Expected a statement handle object';
use constant E_BAD_SLICE => 'Slice must be a reference to an ARRAY or HASH';
use constant E_BAD_CACHE_SIZE =>
    'Maximum row count must be an integer greater than zero';
use constant W_MORE_ROWS     => 'Query would yield more than one result';
use constant E_EXP_ARRAY_REF => 'Expected an ARRAY-REF';

sub DEFAULT_SLICE () {$DBIx::Squirrel::Iterator::DEFAULT_SLICE}

sub DEFAULT_CACHE_SIZE () {$DBIx::Squirrel::Iterator::DEFAULT_CACHE_SIZE}

sub CACHE_SIZE_LIMIT () {$DBIx::Squirrel::Iterator::CACHE_SIZE_LIMIT}

sub DESTROY {
    return if DBIx::Squirrel::Utils::global_destruct_phase();
    local($., $@, $!, $^E, $?, $_);
    my $self = shift;
    $self->_private_state_clear;
    $self->_private_state(undef);
    return;
}

sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my($transforms, $sth, @bind_values) = args_partition(@_);
    throw E_BAD_STH unless UNIVERSAL::isa($sth, 'DBIx::Squirrel::st');
    my $self = bless {}, $class;
    $self->_private_state({
        sth                 => $sth,
        bind_values_initial => [@bind_values],
        transforms_initial  => $transforms,
    });
    return $self;
}

sub _cache_charge {
    my($attr, $self) = shift->_private_state;
    my $sth = $attr->{sth};
    unless ($sth->{Executed}) {
        return unless defined($self->start);
    }
    return unless $sth->{Active};
    my($slice, $cache_size) = @{$attr}{qw/slice cache_size/};
    my $rows = $sth->fetchall_arrayref($slice, $cache_size);
    return 0 unless $rows;
    unless ($attr->{cache_size_fixed}) {
        if ($attr->{cache_size} < CACHE_SIZE_LIMIT) {
            $self->_cache_size_auto_adjust if @{$rows} >= $attr->{cache_size};
        }
    }
    $attr->{buffer}
        = [defined($attr->{buffer}) ? (@{$attr->{buffer}}, @{$rows}) : @{$rows}];
    return scalar(@{$attr->{buffer}});
}

sub _cache_empty {
    my($attr, $self) = shift->_private_state;
    return $attr->{buffer} && @{$attr->{buffer}} < 1;
}

# Where rows are buffered until fetched.
sub _cache_init {
    my($attr, $self) = shift->_private_state;
    $attr->{buffer} = [] if $attr->{sth}->{NUM_OF_FIELDS};
    return $self;
}

sub _cache_size_auto_adjust {
    my($attr, $self) = shift->_private_state;
    $attr->{cache_size} *= 2;
    $attr->{cache_size}  = CACHE_SIZE_LIMIT
        if $attr->{cache_size} > CACHE_SIZE_LIMIT;
    return $self;
}

# How many rows to buffer at a time.
sub _cache_size_init {
    my($attr, $self) = shift->_private_state;
    if ($attr->{sth}->{NUM_OF_FIELDS}) {
        $attr->{cache_size}       ||= DEFAULT_CACHE_SIZE;
        $attr->{cache_size_fixed} ||= !!0;
    }
    return $self;
}

{
    my %attr_by_id;

    sub _private_state {
        my $self = shift;
        my $id   = 0+ $self;
        my $attr = do {
            $attr_by_id{$id} = {} unless defined($attr_by_id{$id});
            $attr_by_id{$id};
        };
        unless (@_) {
            return $attr, $self if wantarray;
            return $attr;
        }
        unless (defined($_[0])) {
            delete $attr_by_id{$id};
            shift;
        }
        if (@_) {
            $attr_by_id{$id} = {} unless defined($attr_by_id{$id});
            if (UNIVERSAL::isa($_[0], 'HASH')) {
                $attr_by_id{$id} = {%{$attr}, %{$_[0]}};
            }
            elsif (UNIVERSAL::isa($_[0], 'ARRAY')) {
                $attr_by_id{$id} = {%{$attr}, @{$_[0]}};
            }
            else {
                $attr_by_id{$id} = {%{$attr}, @_};
            }
        }
        return $self;
    }
}

sub _private_state_clear {
    local($_);
    my($attr, $self) = shift->_private_state;
    delete $attr->{$_} foreach grep {exists($attr->{$_})} qw/
        buffer
        execute_returned
        results_pending
        results_count
        results_first
        results_last
        /;
    return $self;
}

sub _private_state_init {
    shift->_cache_init->_cache_size_init->_results_count_init;
}

sub _private_state_reset {
    shift->_private_state_clear->_private_state_init;
}

{
    # The following package globals are intended to be private. They are
    # modified by private methods in this lexical block, using runtime-
    # scoping. Their current values can be inspected, within any stage of
    # a transformation pipeline, by importing and using the public
    # subroutines in this lexical block.
    our(
        $_DATABASE,
        $_ITERATOR,
        $_RESULT,
        $_RESULT_FIRST,
        $_RESULT_NUMBER,
        $_RESULT_OFFSET,
        $_RESULT_ORIGINAL,
        $_RESULT_PREV,
        $_STATEMENT,
    );

    sub database {$_DATABASE}

    sub iterator {$_ITERATOR}

    sub result {$_RESULT}

    BEGIN {
        *result_current = subname(result_current => \&result);
    }

    sub result_first {$_RESULT_FIRST}

    sub result_number {$_RESULT_NUMBER}

    sub result_offset {$_RESULT_OFFSET}

    sub result_original {$_RESULT_ORIGINAL}

    sub result_prev {$_RESULT_PREV}

    BEGIN {
        *result_previous = subname(result_previous => \&result_prev);
    }

    sub statement {$_STATEMENT}

    sub result_transform {    ## not a method
        my @transforms
            = UNIVERSAL::isa($_[0], 'ARRAY') ? @{+shift}
            : UNIVERSAL::isa($_[0], 'CODE')  ? shift
            :                                  ();
        my @results = @_;
        if (@transforms && @_) {
            local($_RESULT_ORIGINAL) = @results;
            for my $transform (@transforms) {
                last unless @results = do {
                    local($_) = local($_RESULT) = @results;
                    $transform->(@results);
                };
            }
        }
        return @results if wantarray;
        $_ = $results[0];
        return @results;
    }

    sub _result_fetch {
        my($attr, $self) = shift->_private_state;
        my $sth = $attr->{sth};
        my($transformed, $results, $result);
        do {
            return $self->_result_fetch_pending if $self->_results_pending;
            return unless $sth->{Active};
            if ($self->_cache_empty) {
                return unless $self->_cache_charge;
            }
            $result = shift(@{$attr->{buffer}});
            ($results, $transformed) = $self->_result_process($result);
        } while $transformed && !@{$results};
        $result = shift(@{$results});
        $self->_results_push_pending($results) if @{$results};
        $attr->{results_first} = $result unless $attr->{results_count}++;
        $attr->{results_last}  = $result;
        return do {$_ = $result};
    }

    sub _result_fetch_pending {
        my($attr, $self) = shift->_private_state;
        return unless defined($attr->{results_pending});
        my $result = shift(@{$attr->{results_pending}});
        $attr->{results_first} = $result unless $attr->{results_count}++;
        $attr->{results_last}  = $result;
        return do {$_ = $result};
    }

    # Seemingly pointless, here, but intended to be overridden in subclasses.
    sub _result_preprocess {$_[1]}

    sub _result_process {
        local($_);
        my($attr, $self) = shift->_private_state;
        my $result    = $self->_result_preprocess(shift);
        my $transform = !!@{$attr->{transforms}};
        my @results   = do {
            if ($transform) {
                local($_DATABASE)      = $self->sth->{Database};
                local($_ITERATOR)      = $self;
                local($_RESULT_FIRST)  = $attr->{results_first};
                local($_RESULT_NUMBER) = $attr->{results_count} + 1;
                local($_RESULT_OFFSET) = $attr->{results_count};
                local($_RESULT_PREV)   = $attr->{results_last};
                local($_STATEMENT)     = $self->sth;
                map {result_transform($attr->{transforms}, $self->_result_preprocess($_))}
                    $result;
            }
            else {
                $result;
            }
        };
        return \@results, $transform if wantarray;
        return \@results;
    }
}

# The total number of rows fetched since execute was called.
sub _results_count_init {
    my($attr, $self) = shift->_private_state;
    $attr->{results_count} = 0 if $attr->{sth}->{NUM_OF_FIELDS};
    return $self;
}

sub _results_pending {
    my($attr, $self) = shift->_private_state;
    return unless defined($attr->{results_pending});
    return !!@{$attr->{results_pending}};
}

sub _results_push_pending {
    my($attr, $self) = shift->_private_state;
    return unless @_;
    return unless UNIVERSAL::isa($_[0], 'ARRAY');
    my $results = shift;
    $attr->{results_pending} = [] unless defined($attr->{results_pending});
    push @{$attr->{results_pending}}, @{$results};
    return $self;
}

sub all {shift->reset->remaining}

sub cache_size {
    my($attr, $self) = shift->_private_state;
    if (@_) {
        throw E_BAD_CACHE_SIZE unless looks_like_number($_[0]);
        throw E_BAD_CACHE_SIZE
            if $_[0] < DEFAULT_CACHE_SIZE || $_[0] > CACHE_SIZE_LIMIT;
        $attr->{cache_size}       = shift;
        $attr->{cache_size_fixed} = !!1;
        return $self;
    }
    else {
        $attr->{cache_size} = DEFAULT_CACHE_SIZE unless defined($attr->{cache_size});
        return $attr->{cache_size};
    }
}

BEGIN {
    *buffer_size = subname(buffer_size => \&cache_size);

}

sub cache_size_slice {
    my $self = shift;
    return $self->cache_size, $self->slice unless @_;
    if (ref($_[0])) {
        $self->slice(shift);
        $self->cache_size(shift) if @_;
    }
    else {
        $self->cache_size(shift);
        $self->slice(shift) if @_;
    }
    return $self;
}

BEGIN {
    *buffer_size_slice = subname(buffer_size_slice => \&cache_size_slice);
}

sub count {
    my($attr, $self) = shift->_private_state;
    unless ($attr->{sth}->{Executed}) {
        return unless defined($self->start);
    }
    while (defined($self->_result_fetch)) {;}
    return do {$_ = $attr->{results_count}};
}

sub count_fetched {
    my($attr, $self) = shift->_private_state;
    unless ($attr->{sth}->{Executed}) {
        return unless defined($self->start);
    }
    return do {$_ = $attr->{results_count}};
}

sub first {
    my($attr, $self) = shift->_private_state;
    unless ($attr->{sth}->{Executed}) {
        return unless defined($self->start);
    }
    return do {
        $_
            = exists($attr->{results_first})
            ? $attr->{results_first}
            : $self->_result_fetch;
    };
}

sub is_active {!!$_[0]->_private_state->{sth}->{Active}}

sub iterate {
    my $self = shift;
    return unless defined($self->start(@_));
    return do {$_ = $self};
}

sub last {
    my($attr, $self) = shift->_private_state;
    unless ($attr->{sth}->{Executed}) {
        return unless defined($self->start);
        while (defined($self->_result_fetch)) {;}
    }
    return do {$_ = $attr->{results_last}};
}

sub last_fetched {
    my($attr, $self) = shift->_private_state;
    unless ($attr->{sth}->{Executed}) {
        $self->start;
        return;
    }
    return do {$_ = $attr->{results_last}};
}

sub next {
    my $self = shift;
    my $sth  = $self->sth;
    unless ($sth->{Executed}) {
        return unless defined($self->start);
    }
    return do {$_ = $self->_result_fetch};
}

sub not_active {!$_[0]->_private_state->{sth}->{Active}}

sub remaining {
    my $self = shift;
    my $sth  = $self->sth;
    unless ($sth->{Executed}) {
        return unless defined($self->start);
    }
    my @rows;
    push @rows, $self->_result_fetch while $sth->{Active};
    return @rows if wantarray;
    return \@rows;
}

sub reset {
    my $self = shift;
    if (@_) {
        if (ref($_[0])) {
            $self->slice(shift);
            $self->cache_size(shift) if @_;
        }
        else {
            $self->cache_size(shift);
            $self->slice(shift) if @_;
        }
    }
    $self->start;
    return $self;
}

sub rows {shift->sth->rows}

sub single {
    my($attr, $self) = shift->_private_state;
    return unless defined($self->start);
    return unless defined($self->_result_fetch);
    whine W_MORE_ROWS if @{$attr->{buffer}};
    return do {$_ = exists($attr->{results_first}) ? $attr->{results_first} : ()};
}

BEGIN {
    *one = subname(one => \&single);
}

sub slice {
    my($attr, $self) = shift->_private_state;
    if (@_) {
        if (ref($_[0])) {
            if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                $attr->{slice} = shift;
                return $self;
            }
            if (UNIVERSAL::isa($_[0], 'HASH')) {
                $attr->{slice} = shift;
                return $self;
            }
        }
        throw E_BAD_SLICE;
    }
    else {
        $attr->{slice} = DEFAULT_SLICE unless $attr->{slice};
        return $attr->{slice};
    }
}

sub slice_cache_size {
    my $self = shift;
    return $self->slice, $self->cache_size unless @_;
    if (ref($_[0])) {
        $self->slice(shift);
        $self->cache_size(shift) if @_;
    }
    else {
        $self->cache_size(shift);
        $self->slice(shift) if @_;
    }
    return $self;
}

BEGIN {
    *slice_buffer_size = subname(slice_buffer_size => \&slice_cache_size);
}

sub start {
    my($attr,       $self)        = shift->_private_state;
    my($transforms, @bind_values) = args_partition(@_);
    if (@{$transforms}) {
        $attr->{transforms} = [@{$attr->{transforms_initial}}, @{$transforms}];
    }
    else {
        $attr->{transforms} = [@{$attr->{transforms_initial}}]
            unless defined($attr->{transforms}) && @{$attr->{transforms}};
    }
    if (@bind_values) {
        $attr->{bind_values} = [@bind_values];
    }
    else {
        $attr->{bind_values} = [@{$attr->{bind_values_initial}}]
            unless defined($attr->{bind_values}) && @{$attr->{bind_values}};
    }
    my $sth = $attr->{sth};
    $self->_private_state_reset;
    return
        do {$_ = $attr->{execute_returned} = $sth->execute(@{$attr->{bind_values}})};
}

BEGIN {
    *execute = subname(execute => \&start);
}

sub sth {shift->_private_state->{sth}}

1;
