use 5.010_001;
use strict;
use warnings;

package    # hide from PAUSE
  DBIx::Squirrel::Iterator;

use Scalar::Util qw/weaken looks_like_number/;
use Sub::Name;
use DBIx::Squirrel::Utils qw/args_partition throw whine/;
use namespace::clean;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    require Exporter;
    $DBIx::Squirrel::Iterator::VERSION             = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::Iterator::ISA                 = qw/Exporter/;
    @DBIx::Squirrel::Iterator::EXPORT_OK           = qw/result result_transform/;
    $DBIx::Squirrel::Iterator::DEFAULT_SLICE       = [];                            # Faster!
    $DBIx::Squirrel::Iterator::DEFAULT_BUFFER_SIZE = 2;                             # Initial buffer size and autoscaling increment
    $DBIx::Squirrel::Iterator::BUFFER_SIZE_LIMIT   = 64;                            # Absolute maximum buffersize
}

use constant E_BAD_STH         => 'Expected a statement handle object';
use constant E_BAD_SLICE       => 'Slice must be a reference to an ARRAY or HASH';
use constant E_BAD_BUFFER_SIZE => 'Maximum row count must be an integer greater than zero';
use constant W_MORE_ROWS       => 'Query would yield more than one result';
use constant E_EXP_ARRAY_REF   => 'Expected an ARRAY-REF';

sub DEFAULT_SLICE () {$DBIx::Squirrel::Iterator::DEFAULT_SLICE}

sub DEFAULT_BUFFER_SIZE () {$DBIx::Squirrel::Iterator::DEFAULT_BUFFER_SIZE}

sub BUFFER_SIZE_LIMIT () {$DBIx::Squirrel::Iterator::BUFFER_SIZE_LIMIT}

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

sub _buffer_charge {
    my($attr, $self) = shift->_private_state;
    my $sth = $attr->{sth};
    unless ($sth->{Executed}) {
        return unless defined($self->start);
    }
    return unless $sth->{Active};
    my($slice, $buffer_size) = @{$attr}{qw/slice buffer_size/};
    my $rows = $sth->fetchall_arrayref($slice, $buffer_size);
    return 0 unless $rows;
    unless ($attr->{buffer_size_fixed}) {
        if ($attr->{buffer_size} < BUFFER_SIZE_LIMIT) {
            $self->_buffer_size_auto_adjust if @{$rows} >= $attr->{buffer_size};
        }
    }
    $attr->{buffer} = [defined($attr->{buffer}) ? (@{$attr->{buffer}}, @{$rows}) : @{$rows}];
    return scalar(@{$attr->{buffer}});
}

sub _buffer_empty {
    my($attr, $self) = shift->_private_state;
    return $attr->{buffer} && @{$attr->{buffer}} < 1;
}

# Where rows are buffered until fetched.
sub _buffer_init {
    my($attr, $self) = shift->_private_state;
    $attr->{buffer} = [] if $attr->{sth}->{NUM_OF_FIELDS};
    return $self;
}

sub _buffer_size_auto_adjust {
    my($attr, $self) = shift->_private_state;
    $attr->{buffer_size} *= 2;
    $attr->{buffer_size}  = BUFFER_SIZE_LIMIT if $attr->{buffer_size} > BUFFER_SIZE_LIMIT;
    return $self;
}

# How many rows to buffer at a time.
sub _buffer_size_init {
    my($attr, $self) = shift->_private_state;
    if ($attr->{sth}->{NUM_OF_FIELDS}) {
        $attr->{buffer_size}       ||= DEFAULT_BUFFER_SIZE;
        $attr->{buffer_size_fixed} ||= !!0;
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
    shift->_buffer_init->_buffer_size_init->_results_count_init;
}

sub _private_state_reset {
    shift->_private_state_clear->_private_state_init;
}

sub _result_fetch {
    my($attr, $self) = shift->_private_state;
    my $sth = $attr->{sth};
    my($transformed, $results, $result);
    do {
        return $self->_result_fetch_pending if $self->_results_pending;
        return unless $sth->{Active};
        if ($self->_buffer_empty) {
            return unless $self->_buffer_charge;
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
            map {result_transform($attr->{transforms}, $self->_result_preprocess($_))} $result;
        }
        else {
            $result;
        }
    };
    return \@results, $transform if wantarray;
    return \@results;
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

# Runtime scoping of $_result allows caller to import and use "result" instead
# of "$_" during result transformation.

our $_result;

sub result {$_result}

sub result_transform {
    my @transforms = do {
        if (UNIVERSAL::isa($_[0], 'ARRAY')) {
            @{+shift};
        }
        elsif (UNIVERSAL::isa($_[0], 'CODE')) {
            shift;
        }
        else {
            ();
        }
    };
    if (@transforms && @_) {
        for my $transform (@transforms) {
            last unless @_ = do {
                local($_result) = @_;
                local($_)       = $_result;
                $transform->(@_);
            };
        }
    }
    return @_ if wantarray;
    $_ = $_[0];
    return scalar(@_) if @_;
}

sub all {
    my $self = shift;
    return unless defined($self->start);
    return $self->remaining;
}

sub buffer_size {
    my($attr, $self) = shift->_private_state;
    if (@_) {
        throw E_BAD_BUFFER_SIZE unless looks_like_number($_[0]);
        throw E_BAD_BUFFER_SIZE if $_[0] < DEFAULT_BUFFER_SIZE || $_[0] > BUFFER_SIZE_LIMIT;
        $attr->{buffer_size}       = shift;
        $attr->{buffer_size_fixed} = !!1;
        return $self;
    }
    else {
        $attr->{buffer_size} = DEFAULT_BUFFER_SIZE unless defined($attr->{buffer_size});
        return $attr->{buffer_size};
    }
}

sub buffer_size_slice {
    my $self = shift;
    return $self->buffer_size, $self->slice unless @_;
    return $self->slice(shift)->buffer_size(shift) if ref($_[0]);
    return $self->buffer_size(shift)->slice(shift);
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
    return do {$_ = exists($attr->{results_first}) ? $attr->{results_first} : $self->_result_fetch};
}

sub iterate {
    my $self = shift;
    return unless defined($self->start(@_));
    return do {$_ = $self};
}

sub reset {
    my $self = shift;
    $self->start;
    return $self;
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

sub slice_buffer_size {
    my $self = shift;
    return $self->slice, $self->buffer_size unless @_;
    return $self->slice(shift)->buffer_size(shift) if ref($_[0]);
    return $self->buffer_size(shift)->slice(shift);
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
    return do {$_ = $attr->{execute_returned} = $sth->execute(@{$attr->{bind_values}})};
}

BEGIN {
    *execute = subname(execute => \&start);
}

sub sth {shift->_private_state->{sth}}

1;
