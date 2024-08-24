use Modern::Perl;

package    # hide from PAUSE
  DBIx::Squirrel::it;

BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::it::VERSION             = $DBIx::Squirrel::VERSION;
    $DBIx::Squirrel::it::DEFAULT_SLICE       = [];                         # Faster!
    $DBIx::Squirrel::it::DEFAULT_BUFFER_SIZE = 2;                          # Initial buffer size and autoscaling increment
    $DBIx::Squirrel::it::BUFFER_SIZE_LIMIT   = 64;                         # Absolute maximum buffersize
}

use namespace::autoclean;
use Data::Alias  qw/alias/;
use Scalar::Util qw/weaken/;
use Sub::Name;
use DBIx::Squirrel::util qw/throw transform whine/;

use constant E_BAD_STH         => 'Expected a statement handle object';
use constant E_BAD_SLICE       => 'Slice must be a reference to an ARRAY or HASH';
use constant E_BAD_BUFFER_SIZE => 'Maximum row count must be an integer greater than zero';
use constant E_EXP_BIND_VALUES => 'Expected bind values but none have been presented';
use constant W_MORE_ROWS       => 'Query would yield more than one row';
use constant E_EXP_ARRAY_REF   => 'Expected an ARRAY-REF';

sub DEFAULT_SLICE () {$DBIx::Squirrel::it::DEFAULT_SLICE}

sub DEFAULT_BUFFER_SIZE () {$DBIx::Squirrel::it::DEFAULT_BUFFER_SIZE}

sub BUFFER_SIZE_LIMIT () {$DBIx::Squirrel::it::BUFFER_SIZE_LIMIT}

{
    my %attr_by_id;

    sub _private {
        my $self = shift;
        return unless ref($self);
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

sub DESTROY {
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    local($., $@, $!, $^E, $?, $_);
    my $self = shift;
    $self->finish;
    $self->_private(undef);
    return;
}

sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my($transforms, $sth, @bind_values) = DBIx::Squirrel::util::part_args(@_);
    throw E_BAD_STH unless UNIVERSAL::isa($sth, 'DBIx::Squirrel::st');
    my $self = bless({}, $class);
    alias $self->{$_} = $sth->{$_} foreach qw/
      Active
      Executed
      NUM_OF_FIELDS
      NUM_OF_PARAMS
      NAME
      NAME_lc
      NAME_uc
      NAME_hash
      NAME_lc_hash
      NAME_uc_hash
      TYPE
      PRECISION
      SCALE
      NULLABLE
      CursorName
      Database
      Statement
      ParamValues
      ParamTypes
      ParamArrays
      RowsInCache
      /;
    $self->_private({
        sth                 => $sth,
        bind_values_initial => [@bind_values],
        transforms_initial  => $transforms,
    });
    return do {$_ = $self};
}

sub _buffer_charge {
    my($attr, $self) = shift->_private;
    unless ($self->{Executed}) {
        return unless defined($self->execute);
    }
    return unless $self->{Active};
    my($sth, $slice, $buffer_size) = @{$attr}{qw/sth slice buffer_size/};
    my $rows = $sth->fetchall_arrayref($slice, $buffer_size);
    return 0 unless $rows;
    if ($attr->{buffer_size} < BUFFER_SIZE_LIMIT) {
        $self->_buffer_size_adjust if @{$rows} >= $attr->{buffer_size};
    }
    $attr->{buffer} = [defined($attr->{buffer}) ? (@{$attr->{buffer}}, @{$rows}) : @{$rows}];
    return do {$_ = scalar(@{$attr->{buffer}})};
}

sub _buffer_empty {
    my($attr, $self) = shift->_private;
    undef $_;
    return $attr->{buffer} && @{$attr->{buffer}} < 1;
}

# Where rows are buffered until fetched.
sub _buffer_init {
    my($attr, $self) = shift->_private;
    my $key = 'buffer';
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{$key} = @_ ? shift : [];
    }
    return $self;
}

sub _buffer_size_adjust {
    my($attr, $self) = shift->_private;
    $attr->{buffer_size} *= 2;
    $attr->{buffer_size}  = BUFFER_SIZE_LIMIT if $attr->{buffer_size} > BUFFER_SIZE_LIMIT;
    return $self;
}

# How many rows to buffer at a time.
sub _buffer_size_init {
    my($attr, $self) = shift->_private;
    my $key = 'buffer_size';
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{$key} = @_ ? shift : DEFAULT_BUFFER_SIZE;
    }
    return $self;
}

# The total number of rows fetched since execute was called.
sub _results_count_init {
    my($attr, $self) = shift->_private;
    my $key = 'results_count';
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{$key} = @_ ? shift : 0;
    }
    return $self;
}

sub _results_fetch {
    my($attr, $self) = $_[0]->_private;
    return $self->_results_pending_fetch if $self->_results_pending;
    return unless $self->{Active};
    if ($self->_buffer_empty) {
        return unless $self->_buffer_charge;
    }
    my $result = shift(@{$attr->{buffer}});
    my($results, $transformed) = $self->_results_transform($result);
    goto &_results_fetch if $transformed && !@{$results};
    $result = shift(@{$results});
    $self->_results_pending_push($results) if @{$results};
    $attr->{results_first} = $result unless $attr->{results_count}++;
    $attr->{results_last}  = $result;
    return do {$_ = $result};
}

sub _results_pending {
    my($attr, $self) = shift->_private;
    return unless defined($attr->{results_pending});
    return !!@{$attr->{results_pending}};
}

sub _results_pending_fetch {
    my($attr, $self) = shift->_private;
    return unless defined($attr->{results_pending});
    my $result = shift(@{$attr->{results_pending}});
    $attr->{results_first} = $result unless $attr->{results_count}++;
    $attr->{results_last}  = $result;
    return do {$_ = $result};
}

sub _results_pending_push {
    my($attr, $self) = shift->_private;
    return unless @_;
    my $results = shift;
    return                        unless UNIVERSAL::isa($results, 'ARRAY');
    $attr->{results_pending} = [] unless defined($attr->{results_pending});
    push @{$attr->{results_pending}}, @{$results};
    return $self;
}

sub _results_prep_for_transform {
    my($self, $result) = @_;
    return $result;
}

sub _results_transform {
    my($attr, $self) = shift->_private;
    my $result_in = $self->_results_prep_for_transform(shift);
    my @results_out;
    if (!!@{$attr->{transforms}}) {
        push @results_out, map {transform($attr->{transforms}, $self->_results_prep_for_transform($_))} $result_in;
        return \@results_out, !!1 if wantarray;
        return \@results_out;
    }
    push @results_out, $result_in;
    return \@results_out, !!0 if wantarray;
    return \@results_out;
}

sub _state_clear {
    my($attr, $self) = shift->_private;
    foreach (
        qw/
        buffer
        buffer_size
        execute_returned
        results_pending
        results_count
        results_first
        results_last
        /
    ) {
        delete $attr->{$_} if exists($attr->{$_});
    }
    return $self;
}

sub _state_init {
    my($attr, $self) = shift->_private;
    $self->_buffer_init;
    $self->_buffer_size_init;
    $self->_results_count_init;
    return $self;
}

sub all {
    my($attr, $self) = shift->_private;
    unless (defined($self->execute(@_))) {
        undef $_;
        return;
    }
    my @rows = $self->_results_fetch;
    push @rows, $_ while $self->_results_fetch;
    return @rows if wantarray;
    return \@rows;
}

sub buffer_size {
    my($attr, $self) = shift->_private;
    if (@_) {
        my $new_buffer_size = int(shift || DEFAULT_BUFFER_SIZE);
        throw E_BAD_BUFFER_SIZE
          if $new_buffer_size < DEFAULT_BUFFER_SIZE || $new_buffer_size > BUFFER_SIZE_LIMIT;
        $attr->{buffer_size} = $new_buffer_size;
        return $self;
    }
    else {
        $attr->{buffer_size} = DEFAULT_BUFFER_SIZE unless $attr->{buffer_size};
        return $attr->{buffer_size};
    }
}

sub count {
    my($attr, $self) = shift->_private;
    unless ($self->{Active} || $attr->{results_count}) {
        unless (defined($self->execute(@_))) {
            undef $_;
            return;
        }
    }
    while ($self->next) {;}
    return do {$_ = $attr->{results_count}};
}

sub execute {
    my($attr, $self) = shift->_private;
    my $sth = $attr->{sth};
    my($transforms, @bind_values) = DBIx::Squirrel::util::part_args(@_);
    if (@{$transforms}) {
        $attr->{transforms} = $transforms;
    }
    else {
        $attr->{transforms} ||= [@{$attr->{transforms_initial}}];
    }
    if (@bind_values) {
        $attr->{bind_values} = [@bind_values];
    }
    else {
        $attr->{bind_values} ||= [@{$attr->{bind_values_initial}}];
    }
    throw E_EXP_BIND_VALUES if $self->{NUM_OF_PARAMS} && @{$attr->{bind_values}} < 1;
    $self->_state_clear;
    my $rv = $sth->execute(@{$attr->{bind_values}});
    return unless defined($rv);
    $self->_state_init;
    return do {$attr->{execute_returned} = $rv};
}

sub first {
    my($attr, $self) = shift->_private;
    return do {
        if (exists($attr->{results_first})) {
            $_ = $attr->{results_first};
        }
        else {
            $_ = $self->_results_fetch;
        }
    };
}

sub iterate {
    my($attr, $self) = shift->_private;
    unless (defined($self->execute(@_))) {
        undef $_;
        return;
    }
    return do {$_ = $self}
}

sub last {
    my($attr, $self) = shift->_private;
    $self->count;
    return do {
        if (exists($attr->{results_last})) {
            $_ = $attr->{results_last};
        }
        else {
            undef $_;
            ();
        }
    };
}

sub next {
    return do {$_ = shift->_results_fetch};
}

sub remaining {
    my($attr, $self) = shift->_private;
    my @rows = $self->_results_fetch;
    push @rows, $_ while $self->_results_fetch;
    return @rows if wantarray;
    return \@rows;
}

sub reset {
    my $self = shift;
    $self->slice_buffer_size(@_) if @_;
    return unless defined($self->execute);
    return $self;
}

sub rows {
    my($attr, $self) = shift->_private;
    return $attr->{sth}->rows;
}

sub single {
    my($attr, $self) = shift->_private;
    unless (defined($self->execute(@_))) {
        undef $_;
        return;
    }
    $self->_results_fetch;
    whine W_MORE_ROWS if @{$attr->{buffer}} > 0;
    return do {
        if (exists($attr->{results_first})) {
            $_ = $attr->{results_first};
        }
        else {
            undef $_;
            ();
        }
    };
}

BEGIN {
    *one = subname(one => \&single);
}

sub slice {
    my($attr, $self) = shift->_private;
    if (@_) {
        my $new_slice = shift;
        if (ref($new_slice)) {
            if (UNIVERSAL::isa($new_slice, 'ARRAY')) {
                $attr->{slice} = $new_slice;
                return $self;
            }
            if (UNIVERSAL::isa($new_slice, 'HASH')) {
                $attr->{slice} = $new_slice;
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
    return ($self->slice, $self->buffer_size) unless @_;
    return $self->slice(shift)->buffer_size(shift) if ref($_[0]);
    return $self->buffer_size(shift)->slice(shift);
}

BEGIN {
    *buffer_size_slice = subname(buffer_size_slice => \&slice_buffer_size);
}

sub sth {
    my($attr, $self) = shift->_private;
    return $attr->{sth};
}

1;
