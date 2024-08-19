use Modern::Perl;

package    # hide from PAUSE
  DBIx::Squirrel::it;


BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::it::VERSION         = $DBIx::Squirrel::VERSION;
    $DBIx::Squirrel::it::DEFAULT_SLICE   = [];                         # Faster!
    $DBIx::Squirrel::it::DEFAULT_MAXROWS = 1;                          # Initial buffer size and autoscaling increment
    $DBIx::Squirrel::it::BUF_MULT        = 2;                          # Autoscaling factor, 0 to disable autoscaling together
    $DBIx::Squirrel::it::BUF_MAXROWS     = 8;                          # Absolute maximum buffersize
}

use namespace::autoclean;
use Data::Dumper::Concise;
use Scalar::Util         qw/weaken/;
use DBIx::Squirrel::util qw/cbargs throw transform whine/;

use constant E_BAD_SLICE   => 'Slice must be a reference to an ARRAY or HASH';
use constant E_BAD_MAXROWS => 'Maximum row count must be an integer greater than zero';
use constant W_MORE_ROWS   => 'Query returned more than one row';

sub DEFAULT_SLICE () {$DBIx::Squirrel::it::DEFAULT_SLICE}

sub DEFAULT_MAXROWS () {$DBIx::Squirrel::it::DEFAULT_MAXROWS}

sub BUF_MULT () {$DBIx::Squirrel::it::BUF_MULT}

sub BUF_MAXROWS () {$DBIx::Squirrel::it::BUF_MAXROWS}


sub new {
    my($callbacks, $class_or_self, $sth, @bindvals) = cbargs(@_);
    return
      unless UNIVERSAL::isa($sth, 'DBI::st');
    my $self = {};
    bless $self, ref($class_or_self) || $class_or_self;
    for my $k (keys(%{$sth})) {
        if (ref($sth->{$k})) {
            weaken($self->{$k} = $sth->{$k});
        }
        else {
            $self->{$k} = $sth->{$k};
        }
    }
    $self->finish;
    $self->_private_attributes({
        id        => 0+ $self,
        st        => $sth->_private_attributes({Iterator => $self}),
        bindvals  => [@bindvals],
        callbacks => $callbacks,
        slice     => $self->_slice->{Slice},
        maxrows   => $self->_maxrows->{MaxRows},
    });
    return do {$_ = $self};
}


sub all {
    my $self = shift;
    my @rows;
    push @rows, $self->remaining
      if $self->execute(@_);
    return @rows
      if wantarray;
    return \@rows;
}


sub count {
    my $self  = shift;
    my $count = 0;
    $count += 1 while $self->next;
    return do {$_ = $count};
}


sub count_all {
    return do {$_ = scalar(@{shift->all(@_)})};
}


sub execute {
    my($attr, $self) = shift->_private_attributes;
    my $sth = $attr->{st};
    return
      unless $sth;
    $self->reset
      if $attr->{executed} || $attr->{finished};
    $attr->{executed} = !!1;
    if (defined($sth->execute(@_ ? @_ : @{$attr->{bindvals}}))) {
        $attr->{executed}  = !!1;
        $attr->{row_count} = 0;
        if ($sth->{NUM_OF_FIELDS}) {
            my $count = $self->_fetch;
            $attr->{finished} = !$count;
            return do {$_ = $count || '0E0'};
        }
        $attr->{finished} = !!1;
        return do {$_ = '0E0'};
    }
    $attr->{finished} = !!1;
    return do {$_ = undef};
}


sub find {
    my($attr, $self) = shift->_private_attributes;
    $self->reset()
      if @_;
    my $row;
    if ($self->execute(@_)) {
        if ($row = $self->_fetch_row()) {
            $attr->{row_count} = 1;
        }
        else {
            $attr->{row_count} = 0;
        }
        $self->reset();
    }
    return do {$_ = $row};
}


sub finish {
    my($attr, $self) = shift->_private_attributes;
    if ($attr->{st}) {
        $attr->{st}->finish
          if $attr->{st}{Active};
    }
    $attr->{finished}     = !!0;
    $attr->{executed}     = !!0;
    $attr->{rows_fetched} = 0;
    $attr->{buffer}       = undef;
    $attr->{buf_inc}      = DEFAULT_MAXROWS;
    $attr->{buf_mul}      = BUF_MULT && BUF_MULT < 11 ? BUF_MULT : 0;
    $attr->{buf_lim}      = BUF_MAXROWS || $attr->{buf_inc};
    return do {$_ = $self};
}


sub first {
    my($attr, $self) = shift->_private_attributes;
    if (@_ || $attr->{executed} || $attr->{st}{Active}) {
        $self->reset(@_);
    }
    my $row = $self->_fetch_row;
    $attr->{row_count} = 1
      if $row;
    return do {$_ = $row};
}


sub iterate {
    my $self = shift;
    return
      unless defined($self->execute(@_));
    return do {$_ = $self};
}


sub _transform {
    my $self = shift;
    return transform($self->_private_attributes->{callbacks}, @_);
}


sub _auto_manage_maxrows {
    my($attr, $self) = shift->_private_attributes;
    return
      unless my $limit = $attr->{buf_lim};
    my $dirty;
    my $maxrows = $attr->{maxrows};
    my $new_mr  = do {
        if (my $mul = $attr->{buf_mul}) {
            if ($mul > 1) {
                $dirty = !!1;
                $maxrows * $mul;
            }
            else {
                if (my $inc = $attr->{buf_inc}) {
                    $dirty = !!1;
                    $maxrows + $inc;
                }
            }
        }
        else {
            if (my $inc = $attr->{buf_inc}) {
                $dirty = !!1;
                $maxrows + $inc;
            }
        }
    };
    if ($dirty && $new_mr <= $limit) {
        $attr->{maxrows} = $new_mr;
    }
    return $dirty;
}

{
    my %attr_by_id;


    sub _private_attributes {
        my $self = shift;
        return
          unless ref($self);
        my $id   = 0+ $self;
        my $attr = do {
            $attr_by_id{$id} = {}
              unless defined($attr_by_id{$id});
            $attr_by_id{$id};
        };
        unless (@_) {
            return $attr, $self
              if wantarray;
            return $attr;
        }
        unless (defined($_[0])) {
            delete $attr_by_id{$id};
            shift;
        }
        if (@_) {
            $attr_by_id{$id} = {}
              unless defined($attr_by_id{$id});
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


sub _fetch {
    my($attr, $self) = shift->_private_attributes;
    my($sth, $slice, $maxrows, $buf_lim) = @{$attr}{qw/st slice maxrows buf_lim/};
    unless ($sth && $sth->{Active}) {
        $attr->{finished} = !!1;
        return;
    }
    my $r = $sth->fetchall_arrayref($slice, $maxrows || 1);
    my $c = $r ? @{$r} : 0;
    unless ($c) {
        $attr->{finished} = !!1;
        return 0;
    }
    if ($attr->{buffer}) {
        $attr->{buffer} = [@{$attr->{buffer}}, @{$r}];
    }
    else {
        $attr->{buffer} = $r;
    }
    if ($c == $maxrows && $maxrows < $buf_lim) {
        ($maxrows, $buf_lim) = @{$attr}{qw/maxrows buf_lim/}
          if $self->_auto_manage_maxrows;
    }
    return do {$attr->{rows_fetched} += $c};
}


sub _is_empty {
    my $attr = shift->_private_attributes;
    return !@{$attr->{buffer}};
}


sub _no_more_rows {
    my($attr, $self) = shift->_private_attributes;
    $self->execute
      unless $attr->{executed};
    return $attr->{finished};
}


sub _fetch_row {
    my($attr, $self) = shift->_private_attributes;
    return
      if $self->_no_more_rows;
    return
      if $self->_is_empty && !$self->_fetch;
    my($head, @tail) = @{$attr->{buffer}};
    $attr->{buffer}     = \@tail;
    $attr->{row_count} += 1;
    return $self->_transform($head)
      if @{$attr->{callbacks}};
    return $head;
}


sub next {
    my $self = shift;
    $self->_slice_maxrows(@_)
      if @_;
    return do {$_ = $self->_fetch_row};
}


sub remaining {
    my($attr, $self) = shift->_private_attributes;
    my @rows;
    unless ($self->_no_more_rows) {
        until ($attr->{finished}) {
            push @rows, $self->_fetch_row;
        }
        $attr->{row_count} += scalar(@rows);
        $self->reset if $attr->{row_count};
    }
    return @rows
      if wantarray;
    return \@rows;
}


sub _maxrows {
    my $self = shift;
    throw E_BAD_MAXROWS
      if ref($_[0]);
    $self->{MaxRows} = int(shift || DEFAULT_MAXROWS);
    return $self->_private_attributes({maxrows => $self->{MaxRows}});
}


sub _slice {
    my $self = shift;
    unless (@_) {
        $self->{Slice} = DEFAULT_SLICE
          unless defined($self->{Slice});
        return $self->_private_attributes({slice => $self->{Slice}});
    }
    if (defined($_[0])) {
        if (UNIVERSAL::isa($_[0], 'ARRAY')) {
            $self->{Slice} = [];
        }
        elsif (UNIVERSAL::isa($_[0], 'HASH')) {
            $self->{Slice} = {};
        }
        else {
            throw E_BAD_SLICE;
        }
    }
    else {
        $self->{Slice} = DEFAULT_SLICE;
    }
    return $self->_private_attributes({slice => $self->{Slice}});
}


sub _slice_maxrows {
    my $self = shift;
    return $self
      unless @_;
    return $self->_slice(shift)->_maxrows(shift)
      if ref($_[0]);
    return $self->_maxrows(shift)->_slice(shift);
}


BEGIN {
    *_maxrows_slice = *_slice_maxrows;    # Don't make me think!
}


sub reset {
    my $self = shift;
    $self->_slice_maxrows(@_)
      if @_;
    return do {$_ = $self->finish};
}


sub single {
    my($attr, $self) = shift->_private_attributes;
    $self->reset()
      if @_;
    my $row;
    if (my $count = $self->execute(@_)) {
        whine W_MORE_ROWS
          if $count > 1;
        if ($row = $self->_fetch_row()) {
            $attr->{row_count} = 1;
        }
        else {
            $attr->{row_count} = 0;
        }
        $self->reset();
    }
    return do {$_ = $row};
}


BEGIN {
    *one = *single;
}


sub DESTROY {
    return
      if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    local($., $@, $!, $^E, $?, $_);
    my $self = shift;
    $self->finish;
    $self->_private_attributes(undef);
    return;
}


BEGIN {
    *results          = *rs           = sub {shift->sth->rs(@_)};
    *statement_handle = *sth          = sub {shift->_private_attributes->{st}};
    *done             = *finished     = sub {shift->_private_attributes->{finished}};
    *not_done         = *not_finished = sub {!shift->_private_attributes->{finished}};
    *not_pending      = *executed     = sub {shift->_private_attributes->{executed}};
    *pending          = *not_executed = sub {!shift->_private_attributes->{executed}};
}

1;
