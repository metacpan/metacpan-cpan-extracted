package Chorus::Frame;

use 5.006;
use strict;

our $VERSION = '2.01';

=encoding utf8

=head1 NAME

Chorus::Frame - Frame-based knowledge representation with inheritance and procedural attachments.

=head1 VERSION

2.01

=head1 SYNOPSIS

  use Chorus::Frame;

  my $f1 = Chorus::Frame->new(
      color => { _DEFAULT => 'blue' },
  );

  my $f2 = Chorus::Frame->new(
      _ISA  => $f1,
      label => sub { 'I am ' . $SELF->color },   # $SELF = frame calling get()
  );

  print $f2->color;   # 'blue'   (inherited _DEFAULT)
  print $f2->label;   # 'I am blue'

  # Inheritance mode affects how _VALUE/_DEFAULT/_NEEDED are resolved
  Chorus::Frame::setMode(GET => 'Z');
  Chorus::Frame::setMode(GET => 'N');   # back to default

  # Select frames by slot (uses internal registry for fast lookup)
  my @colored = fmatch(slot => 'color');
  my @both    = fmatch(slot => ['color', 'score']);

  # Select the best-matching prototype frame given observed properties
  my $proto = fselect(color => 'blue', can_fly => 1);   # highest-scoring prototype
  my @all   = fselect(color => 'blue', _all => 1);      # all candidates, ranked

  # Frame networks: restrict fselect to a prototype and its declared alternatives
  my $Bird  = Chorus::Frame->new(can_fly => 1, legs => 2, _ALTERNATIVES => [$Bat]);
  my $match = fselect(can_fly => 1, _alternatives => $Bird);

  # Terminal slots: declare which slots must hold real data for a frame to be complete
  my $proto = Chorus::Frame->new(_TERMINAL_SLOTS => ['color', 'size']);
  my $inst  = Chorus::Frame->new(_ISA => $proto, color => 'blue', size => 'large');
  $inst->complete;   # 1

  # _ON_DELETE hook (if-removed demon, completes the Minsky triad)
  my $f = Chorus::Frame->new(
      tag       => 'active',
      _ON_DELETE => sub { print "Slot '${\$_[0]}' removed from frame\n" },
  );
  $f->delete('tag');   # → prints "Slot 'tag' removed from frame"

=head1 DESCRIPTION

A B<frame> is a Perl hash blessed into C<Chorus::Frame>.  Its entries are called B<slots>.

Key features:

=over 4

=item * B<Inheritance> via the C<_ISA> slot (single frame or arrayref of frames).

=item * B<Procedural slots> -- any slot value may be a C<sub {}>, evaluated lazily on
access.  The variable C<$SELF> holds the frame on which C<get()> was originally called,
making it available inside coderefs.

=item * B<Target-information slots> -- C<_VALUE>, C<_DEFAULT> and C<_NEEDED> are tested
in that order to resolve the I<value> of a frame.

=item * B<Lifecycle hooks> -- C<_BEFORE>, C<_AFTER> and C<_REQUIRE> intercept writes.

=item * B<Global registry> -- every frame is registered automatically; C<fmatch()> uses
this registry for O(1) slot-based lookups.

=back

=head2 Special slots

The following names are reserved.  Never use them as application slot names
(except C<_ISA> and C<_NOFRAME>):

  _KEY          Unique MD5 key assigned at construction.  Never set manually.
  _PARENT_KEY   Tracks sub-frame ownership for Copy-on-Write inside set().
  _ISA          Inheritance: a single frame or an arrayref of frames.
  _VALUE        Primary target information of this frame.
  _DEFAULT      Fallback when _VALUE is absent.
  _NEEDED       Last-resort coderef called when both _VALUE and _DEFAULT are absent
                (backward chaining).
  _BEFORE           Hook called before a slot value changes.
  _AFTER            Hook called after a slot value changes (forward propagation).
  _ON_DELETE        Hook called after a slot is deleted; receives the slot name
                    (if-removed demon, completing the Minsky triad).
  _REQUIRE          Validation hook: return REQUIRE_FAILED to block the write.
  _NOFRAME          Prevents automatic promotion of a nested hash to a frame.
  _TERMINAL_SLOTS   Arrayref of slot names that must hold a real (_VALUE) value
                    for the frame to be considered complete (see complete()).
  _ALTERNATIVES     Arrayref of sibling prototype frames used by fselect()
                    as an alternative candidate pool (Minsky frame network).

=head2 Inheritance modes N and Z

The global mode controls how C<get()> walks the inheritance chain.

B<Mode N> (default) -- each valuation key is scanned across the whole inheritance tree
before the next key is tried:

  _VALUE  on (frame, frame._ISA, frame._ISA._ISA, ...)
  _DEFAULT on the same tree
  _NEEDED  on the same tree

B<Mode Z> -- the full sequence C<(_VALUE, _DEFAULT, _NEEDED)> is tried on each frame
before descending to its parents:

  frame     : _VALUE, _DEFAULT, _NEEDED
  frame._ISA: _VALUE, _DEFAULT, _NEEDED  ...

Switch with C<< Chorus::Frame::setMode(GET => 'Z') >> or C<< setMode(GET => 'N') >>.

=head2 Exports

C<Chorus::Frame> exports by default:

  $SELF          Current frame context, updated by get() and set().
  &fmatch        Slot-based frame selection function.
  &fselect       Prototype selection by scored slot/value matching (Minsky-style).
  &setMode       Switches the inheritance mode (N or Z).
  REQUIRE_FAILED Constant (-1) returned by _REQUIRE to abort a write.

=cut

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

  @ISA         = qw(Exporter);
  @EXPORT      = qw($SELF &fmatch &fselect &setMode REQUIRE_FAILED );
  @EXPORT_OK   = qw();

  # %EXPORT_TAGS = ( );		# eg: TAG => [ qw!name1 name2! ];
}

use strict;
use warnings;
use Carp;			# warn of errors (from perspective of caller)
use Digest::MD5;
use Scalar::Util qw(weaken);

use constant DEBUG_MEMORY => 0;

use vars qw($AUTOLOAD);

use constant SUCCESS        =>  1;
use constant FAILED         =>  0;
use constant REQUIRE_FAILED => -1;

use constant VALUATION_ORDER => ('_VALUE', '_DEFAULT', '_NEEDED');

use constant MODE_N => 1;
use constant MODE_Z => 2;

my $getMode = MODE_N;       # DEFAULT IS N !!!

my %REPOSITORY;
my %FMAP;
my %INSTANCES;

our $SELF;
my @Heap = ();

sub AUTOLOAD {
  my $frame = shift || $SELF;
  my $slotName = $AUTOLOAD;
  $slotName =~ s/.*://;       # strip fully-qualified portion
  get($frame, $slotName, @_); # or getN or getZ !!
}

sub _isa {
  my ($ref, $str) = @_;
  return (ref($ref) eq $str);
}

=head1 FUNCTIONS

=head2 setMode

Sets the global inheritance mode used by C<get()> to resolve target information
(C<_VALUE>, C<_DEFAULT>, C<_NEEDED>).

  Chorus::Frame::setMode(GET => 'N');   # Mode N -- default
  Chorus::Frame::setMode(GET => 'Z');   # Mode Z
  Chorus::Frame::setMode('N');          # short form

See L</Inheritance modes N and Z> in the DESCRIPTION for a detailed comparison.

=cut

sub setMode {
  if (@_ == 1) {
    # short form: setMode('Z') or setMode('N')
    my $m = uc(shift);
    $getMode = MODE_N if $m eq 'N';
    $getMode = MODE_Z if $m eq 'Z';
  } else {
    my (%opt) = @_;
    $getMode = MODE_N if defined($opt{GET}) and uc($opt{GET}) eq 'N';
    $getMode = MODE_Z if defined($opt{GET}) and uc($opt{GET}) eq 'Z';
  }
}

=head1 METHODS

=head2 _keys

Returns the slot names of the frame, excluding the internal keys C<_KEY> and C<_PARENT_KEY>.

  my @slots = $frame->_keys;

Use this instead of C<keys %$frame> when you need to iterate over application slots
without exposing internal bookkeeping entries.

=cut

sub _keys {
  my ($this) = @_;
  grep { $_ ne '_KEY' && $_ ne '_PARENT_KEY' } keys %{$this}; # WARN - frames have EXTRA _KEY and _PARENT_KEY slots !!
}

sub pushself {
  unshift(@Heap, $SELF) if $SELF;
  $SELF = shift;
}

sub popself {
  $SELF = shift @Heap;
}

sub expand {
    my ($info, @args) = @_;
    return expand(&$info(@args)) if _isa($info, 'CODE');
    return $info;
}

=head2 _push

Appends one or more elements to a slot, converting it to an arrayref when necessary.

  $frame->_push('tags', 'red', 'big');

=cut

sub _push {
  my ($this, $slot, @elems) = @_;
  return unless scalar(@elems);
  $this->{$slot} = [ defined($this->{$slot}) ? ($this->{$slot}) : () ] unless ref($this->{$slot}) eq 'ARRAY';
  push @{$this->{$slot}}, @elems;
}

sub _addInstance {
  my ($this, $instance) = @_;
  my $k = $instance->{_KEY};
  $INSTANCES{$this->{_KEY}}->{$k} = $instance;


  # weaken($INSTANCES{$instance);         # TOCHECK - does the SAME !!??
  #
  weaken($INSTANCES{$this->{_KEY}}->{$k}); # Will not increase garbage ref counter to $instance !!
}

=head2 _inherits

Adds one or more parent frames to the inheritance chain outside the constructor.
Each parent is added at most once; duplicates are silently ignored.

  $frame->_inherits($parent1, $parent2);

Used internally by C<Chorus::Engine::new()> to wire agent instances to the engine
prototype.

=cut

sub _inherits {
  my ($this, @inherited) = @_;
  my $k = $this->{_KEY};
  for (grep { ! $INSTANCES{$_->{_KEY}}->{$k} } @inherited) { # clean list
    $_->_addInstance($this);  # will use weaken on 
    $this->_push('_ISA', $_);
  }
  return $this;
}

sub _removeInstance {
  my ($this, $instance) = @_;
  my $k = $instance->{_KEY};
  (warn "Instance NOT FOUND !?", return) unless $INSTANCES{$this->{_KEY}}->{$k};
  delete $INSTANCES{$this->{_KEY}}->{$k};
}

sub _register {
  my ($this) = @_;
  my $k;
  do { $k = Digest::MD5::md5_base64(rand) } while exists($FMAP{$k});

  foreach my $slot (keys(%$this)) { # register all slots      # not yet _KEY
    $REPOSITORY{$slot} = {} unless exists $REPOSITORY{$slot};
    $REPOSITORY{$slot}->{$k} = 'Y';
  }

  $this->{_KEY} = $k; # _KEY SET HERE !!
  $FMAP{$k} = $this;

  weaken($FMAP{$k}); # will not increase garbage ref counter to $this !!
  return $this;
}

sub _blessToFrameRec {
  local $_ = shift;

  if (_isa($_,'Chorus::Frame')) {
    while(my ($k, $val) = each %$_) {
       if (_isa($val,'HASH')) { # Warn - Will convert all hash tables to Chorus::Frame -> be carefull with function ref() !!
          next if $val->{_NOFRAME};
          bless($val, 'Chorus::Frame');
          _register($val);
          $val->{_PARENT_KEY} //= $_->{_KEY} if _isa($_, 'Chorus::Frame') && exists $_->{_KEY};
          _blessToFrameRec($val);
       } else {
          _blessToFrameRec($_->{$k}) if _isa($val,'ARRAY');
       }
       if ($k eq '_ISA') {
         foreach my $inherited (_isa($val,'ARRAY') ? map { expand($_) || () } @{$val}
                                                       : (expand($val))) {
            $inherited->_addInstance($_) if $inherited;
         }
       }
    }
    return;
  }

  if (_isa($_,'ARRAY')) {
    foreach my $idx (0 .. scalar(@$_) - 1) {
      if (_isa($_->[$idx], 'HASH')) {
        next if exists $_->[$idx]->{_NOFRAME};
        bless($_->[$idx], 'Chorus::Frame');
        _register($_->[$idx]);
        _blessToFrameRec($_->[$idx]);
      } else {
        _blessToFrameRec($_->[$idx]) if _isa($_->[$idx],'ARRAY');
      }
    }
  }
}

sub blessToFrame {
  my $res = shift;
  return $res if _isa($res, 'Chorus::Frame'); # already blessed

  SWITCH: {

    _isa($res, 'HASH') && do {
      return $res if exists $res->{_NOFRAME};
      _register(bless($res, 'Chorus::Frame'));
      _blessToFrameRec $res if _keys($res); # will ignore _KEY !
      last SWITCH;;
    };

    _isa($res, 'ARRAY') && do {
      return $res unless scalar(@$res);
      _blessToFrameRec $res;
      last SWITCH;
    };

  }; # SWITCH

  return $res;
}

=head2 new

Constructor.  Converts a flat list of key/value pairs into a C<Chorus::Frame> object.

  my $f = Chorus::Frame->new(
      slot_a => 'value',
      slot_b => sub { 'computed: ' . $SELF->slot_a },   # procedural slot
      nested => {
          _ISA    => $proto,
          _NEEDED => sub { compute_default() },
      },
  );

All nested plain hashes are automatically and recursively promoted to
C<Chorus::Frame>, unless they contain the C<_NOFRAME> flag.  Every frame
receives a unique C<_KEY> and is registered in the global repository so
that C<fmatch()> can find it.

Do B<not> set C<_KEY> or C<_PARENT_KEY> manually.

=cut

sub new {
  my ($this, @desc) = @_;
  return blessToFrame({@desc});
}

=head2 _reset

Clears all global registries (C<%FMAP>, C<%REPOSITORY>, C<%INSTANCES>),
resets the C<$SELF> context stack and restores the inheritance mode to B<N>.

  Chorus::Frame::_reset();

B<For testing only.>  Call between test cases to guarantee frame isolation.

=cut

sub _reset {
  %REPOSITORY = ();
  %FMAP       = ();
  %INSTANCES  = ();
  $SELF       = undef;
  @Heap       = ();
  $getMode    = MODE_N;
}

# WARN - Should be automatically called by carbage collector EVEN with those 2 remaining references : $INSTANCES{$k} AND $FMAP{$k} !!!
#
sub DESTROY {
  my ($this) = @_;

    my $k = $this->{_KEY};

    delete $INSTANCES{$k} if exists $INSTANCES{$k};

    foreach my $inherited (_isa($this->{_ISA}, 'ARRAY') ? map { expand($_) || () } @{$this->{_ISA}} : (expand($this->{_ISA}))) {
      my $ik = $inherited->{_KEY} or next;
      delete $INSTANCES{$ik}->{$k} if exists $INSTANCES{$ik}->{$k};
    }

    foreach my $slot (keys(%$this)) {
      delete($REPOSITORY{$slot}->{$k}) if exists $REPOSITORY{$slot} and exists $REPOSITORY{$slot}->{$k};
    }

    delete $FMAP{$k}; # is a weak reference (not counted by garbage collector)
}


=head2 get

Returns the value associated with a space-separated slot path.

  $frame->get('slot')
  $frame->get('slot_a slot_b')   # traverse slot_a, then resolve slot_b
  $frame->slot_a                 # AUTOLOAD short form -- equivalent to get('slot_a')

The last step in the path is resolved through C<_VALUE>, C<_DEFAULT> and C<_NEEDED>
in that order (subject to the current L</Inheritance modes N and Z>).

C<get()> pushes the current frame onto a stack and sets C<$SELF> to it, so procedural
slots can refer back to the calling frame:

  my $f = Chorus::Frame->new(
      name  => 'Chorus',
      label => sub { 'Module: ' . $SELF->name },
  );
  print $f->label;   # "Module: Chorus"

The short form C<< $f->slotname >> is equivalent to C<< $f->get('slotname') >>.
Arguments are forwarded when the resolved value is a coderef:

  $f->slotname(@args);   # calls get('slotname'), then invokes the result with @args

=cut

# first() - returns expanded $slot if explicitly (not inherited) provided by $this
#           ret = SUCCESS whatever the slot expansion returns !!
sub _first {
  my ($this, $slots, @args) = @_;
  for (@{$slots}) {
    return { ret => SUCCESS, res => expand($this->{$_}, @args) } if exists $this->{$_};
  }
  return;
}

sub _expandInherits {
  my ($this, $tryValuations, @args) = @_;

  my $res = _first($this, $tryValuations, @args);
  return $res if defined($res) and $res->{ret};

  if (exists($this->{_ISA})) {
    my @h = _isa($this->{_ISA}, 'ARRAY') ? map { expand($_) || () } @{$this->{_ISA}} : (expand($this->{_ISA}) || ());
    for (@h) { # upper level
      $res = _expandInherits($_, $tryValuations, @args);
      return $res if defined($res) and $res->{ret};
    }
  }
  return { ret => FAILED };
}

sub _inherited {
  my ($this, $slot, @rest) = @_;

  return $this->{$slot} if exists($this->{$slot}); # first that match (better than buildtree) !!

  $this->{_ISA} and push @rest, _isa($this->{_ISA}, 'ARRAY') ? @{$this->{_ISA}} : $this->{_ISA};
  my $next = shift @rest;

  return unless $next;
  return _inherited($next, $slot, @rest);
}

# _all_slot_frames($this, $slot, $seen)
# BFS over the outer inheritance tree of $this, collecting all frames that
# directly provide $slot (no inner _ISA traversal inside the slot values).
sub _all_slot_frames {
  my ($this, $slot, $seen) = @_;
  $seen //= {};
  my $k = $this->{_KEY} // '';
  return () if $seen->{$k}++;

  my @res;
  push @res, $this->{$slot} if exists $this->{$slot};

  if (exists $this->{_ISA}) {
    my @parents = _isa($this->{_ISA}, 'ARRAY')
                  ? map { expand($_) || () } @{$this->{_ISA}}
                  : (expand($this->{_ISA}) || ());
    for my $p (@parents) {
      push @res, _all_slot_frames($p, $slot, $seen);
    }
  }
  return @res;
}

sub _value_Z {
  my ($info, @args) = @_;

  return expand($info, @args) unless _isa($info, 'Chorus::Frame');

  my $res = _expandInherits($info, [VALUATION_ORDER], @args);

  return $res->{res} if defined($res) and $res->{ret};
  return $info;
}

sub _getZ {
  my ($this, $way, @args) = @_;

  return _value_Z($this, @args) unless $way;

  $way =~ /^\s*(\S*)\s*(.*?)\s*$/o or die "Unexpected way format : '$way'";
  my ($nextStep, $followWay) = ($1, $2);

  unless ($followWay) {
    # Mode Z last step: test each valuation key across ALL candidates before
    # moving to the next key — i.e. VALUE on all, then DEFAULT on all, then NEEDED.
    my @candidates = _all_slot_frames($this, $nextStep);
    for my $vkey (VALUATION_ORDER) {
      for my $cand (@candidates) {
        next unless _isa($cand, 'Chorus::Frame');
        if (exists $cand->{$vkey}) {
          return expand($cand->{$vkey}, @args);
        }
      }
    }
    # fallback: return first candidate as-is (scalar value or frame)
    return @candidates ? expand($candidates[0], @args) : undef;
  }

  my $next = _inherited($this, $nextStep);
  return _isa($next, 'Chorus::Frame') ? _getZ($next, $followWay, @args) : undef;
}

sub _value_N {
  my ($info, @args) = @_;

  return expand($info, @args) unless _isa($info, 'Chorus::Frame');

  for (VALUATION_ORDER) {
    my $res = _expandInherits($info, [$_], @args);
    return $res->{res} if defined($res) and $res->{ret};
  }

  return $info;
}

sub _getN {
  my ($this, $way, @args) = @_;

  return _value_N($this, @args) unless $way;

  $way =~ /^\s*(\S*)\s*(.*?)\s*$/o or die "Unexpected way format : '$way'";
  my ($nextStep, $followWay) = ($1, $2);

  return _value_N(_inherited($this, $nextStep), @args) unless $followWay;

  my $next = _inherited($this, $nextStep);
  return _isa($next, 'Chorus::Frame') ? _getN($next, $followWay, @args) : undef;
}

sub get {
  pushself(shift);
  my $res = $getMode == MODE_N ? _getN($SELF, @_) : _getZ($SELF, @_);
  popself();
  return $res;
}

=head2 delete

Removes a slot and unregisters it from the global repository.

  $frame->delete('slot');
  $frame->delete('slot_a slot_b');   # deletes slot_b inside slot_a

Always use this method instead of C<delete $frame->{slot}>.  Direct hash deletion
bypasses the registry, causing C<fmatch()> to return stale results for that slot.

After the slot is removed, the C<_ON_DELETE> hook is invoked (if present),
receiving the deleted slot name as its argument.  This is the I<if-removed> demon
that completes the Minsky triad (C<_NEEDED> / C<_AFTER> / C<_ON_DELETE>).

=cut

sub _unregisterSlot {
  my ($this, $slot) = @_;
  return unless exists $REPOSITORY{$slot};
  delete $REPOSITORY{$slot}->{$this->{_KEY}} if exists $REPOSITORY{$slot}->{$this->{_KEY}};
}

sub _deleteSlot {
  my ($this, $slot) = @_;
  _unregisterSlot($this, $slot);
  delete($this->{$slot}) if exists $this->{$slot};
  _getN($this, '_ON_DELETE', $slot);   # if-removed demon (Minsky triad)
}

sub _deleteN {
  my ($this, $way) = @_;

  return unless $way;

  $way =~ /^\s*(\S*)\s*(.*?)\s*$/o or die "Unexpected way format : '$way'";
  my ($nextStep, $followWay) = ($1, $2);

  return _deleteSlot($this, $nextStep) unless $followWay;

  my $next = _inherited($this, $nextStep);
  return _isa($next, 'Chorus::Frame') ? _deleteN($next, $followWay) : undef;
}

sub delete {
  pushself(shift);
  my $res = _deleteN($SELF, @_);
  popself();
  return $res;
}

=head2 set

Associates a value to a slot (or slot path) and updates the global registry.

  $frame->set('slot', $value);
  $frame->set('slot_a slot_b', $value);

Always use this method instead of C<< $frame->{slot} = $value >>.  Direct hash
assignment bypasses C<_registerSlot()>, so C<fmatch(slot =E<gt> 'slot')> will B<not>
return this frame -- the slot exists on the hash but is invisible to the inference
engine.

B<Lifecycle hooks> -- when the terminal slot has them, they fire in order:

  1. _REQUIRE is called with the new value.
     Return REQUIRE_FAILED (-1) to abort the write.
  2. _BEFORE is called with the new value.
  3. The value is stored in _VALUE and registered.
  4. _AFTER is called with the new value (forward chaining).

B<Copy-on-Write> -- when traversing a sub-frame whose C<_PARENT_KEY> differs from
the current frame's C<_KEY>, a shadow frame (C<_ISA =E<gt> $shared>) is created
locally before writing.  This prevents mutations from affecting shared structures.

  my $f = Chorus::Frame->new(a => { b => { _VALUE => 'old' } });
  $f->set('a b', 'new');
  print $f->get('a b');   # "new"

=cut

sub _registerSlot {
  my ($this, $slot) = @_;
  $REPOSITORY{$slot} = {} unless exists $REPOSITORY{$slot};
  $REPOSITORY{$slot}->{$this->{_KEY}} = 'Y';
}

sub _setValue {
  my ($this, $val) = @_;

  my $req = _getN($this, '_REQUIRE', $val);
  return if defined($req) && !ref($req) && $req =~ /^-?\d+$/ && $req == REQUIRE_FAILED;

  _getN($this, '_BEFORE', $val); # or return;

  blessToFrame($val);
  $this->{'_VALUE'} = $val;
  _registerSlot($this, '_VALUE');

  _getN($this, '_AFTER', $val); # or return;

  return $val;
}

sub _setSlot {
  my ($this, $slot, $info) = @_;
  blessToFrame($info);
  $info->{_PARENT_KEY} //= $this->{_KEY} if _isa($info, 'Chorus::Frame');
  $this->{$slot} = $info;
  _registerSlot($this, $slot);
  return $info;
}

sub _setN {
  my ($this, $way, $info) = @_;

  return _setValue($this, $info) unless $way;

  $way =~ /^\s*(\S*)\s*(.*?)\s*$/o or die "Unexpected way format : '$way'";
  my ($nextStep, $followWay) = ($1, $2);
  my $crossedValue = $this->{$nextStep};

  if (_isa($crossedValue, 'Chorus::Frame')) {
    # CoW : tout franchissement d'un Frame non-propriétaire crée un shadow local,
    # quelle que soit la profondeur du chemin (followWay vide ou non).
    unless (defined($crossedValue->{_PARENT_KEY}) && $crossedValue->{_PARENT_KEY} eq $this->{_KEY}) {
      my $shadow = Chorus::Frame->new(_ISA => $crossedValue);
      $shadow->{_PARENT_KEY} = $this->{_KEY};
      _setSlot($this, $nextStep, $shadow);
      return _setN($shadow, $followWay, $info);
    }
    return _setN($crossedValue, $followWay, $info);
  }

  # Le slot n'est pas localement un Frame : chercher via héritage pour chemin multi-niveaux
  if ($followWay) {
    my $inherited_frame = _inherited($this, $nextStep);
    if (_isa($inherited_frame, 'Chorus::Frame')) {
      # Créer un shadow CoW depuis le frame hérité
      my $shadow = Chorus::Frame->new(_ISA => $inherited_frame);
      $shadow->{_PARENT_KEY} = $this->{_KEY};
      _setSlot($this, $nextStep, $shadow);
      return _setN($shadow, $followWay, $info);
    }
    # Aucun Frame trouvé par héritage : laisser tomber vers la création d'un nouveau frame
  }

  unless ($followWay) {
    if ($nextStep eq '_VALUE') {
      return _setValue($this, $info);
    } else {
      if (_isa($this->{$nextStep}, 'Chorus::Frame') and exists($this->{$nextStep}->{_VALUE})) {
        return _setValue($this->{$nextStep}, $info);
      } else {
        return _setSlot($this, $nextStep, $info);
      }
    }
  }

  $this->{$nextStep} = (exists($this->{$nextStep})) ? new Chorus::Frame (_VALUE => $crossedValue)
                                                    : new Chorus::Frame;
  $this->{$nextStep}->{_PARENT_KEY} = $this->{_KEY};

  return _setN($this->{$nextStep}, $followWay, $info); # (keep current context)
}

sub set {
  pushself(shift);

  my %desc = @_;
  my $res;

  while(my($k, $val) = each %desc) {
    $res = _setN($SELF, $k, $val);
  }

  popself();
  return $res;  # will return last set if multiple pairs (key=>val) !!
}

=head2 fmatch

Returns all frames that provide the given slot(s), either directly or by inheritance,
using the internal registry for efficient lookups.

  my @frames = fmatch(slot => 'color');                      # all frames having 'color'
  my @frames = fmatch(slot => ['color', 'score']);           # intersection
  my @frames = fmatch(slot => 'color', from => \@list);      # restricted space
  my @high   = grep { $_->score > 5 } fmatch(slot => 'score');

C<slot> may be a scalar or an arrayref.  Multiple slot names return only frames
providing B<all> of them.  The optional C<from> arrayref narrows the search to a
known subset.

=cut

=head2 complete

Returns C<1> if every slot listed in C<_TERMINAL_SLOTS> (on this frame or
inherited) holds a defined value via C<get()>, C<undef> otherwise.

  my $proto = Chorus::Frame->new(_TERMINAL_SLOTS => ['color', 'size']);
  my $inst  = Chorus::Frame->new(_ISA => $proto, color => 'blue', size => 'large');

  $inst->complete;   # 1

  my $partial = Chorus::Frame->new(_ISA => $proto, color => 'red');
  $partial->complete;   # undef  (size not filled)

C<_TERMINAL_SLOTS> is inherited: a child frame that does not redeclare it will
use its parent's list.  Each slot is resolved with C<get()>, so procedural slots
(C<sub {}>) and C<_DEFAULT> values count as filled.

B<Relationship to Minsky's model>: terminal slots correspond to Minsky's
I<terminal nodes> -- positions in the frame that must be grounded in actual
observed data for the frame to describe a real situation rather than a generic
prototype.

=cut

sub complete {
  my ($this) = @_;
  pushself($this);
  my $terminals = _inherited($SELF, '_TERMINAL_SLOTS');
  unless ($terminals && ref($terminals) eq 'ARRAY' && @$terminals) {
    popself();
    return undef;
  }
  for my $slot (@$terminals) {
    my $val = eval { $SELF->get($slot) };
    unless (defined $val) {
      popself();
      return undef;
    }
  }
  popself();
  return 1;
}

# firstInheriting() : returns frames inheriting DIRECTLY from $this (via %INSTANCES)
sub _firstInheriting {
  my ($this) = @_;
  my $k = $this->{_KEY};
  return ($INSTANCES{$k} ? values(%{$INSTANCES{$k}}) : ());
}

# _hasSlot() : all frames providing $slot DIRECTLY (from %REPOSITORY)
sub _hasSlot {
  my ($slot) = @_;
  return map { $FMAP{$_} || () } keys(%{$REPOSITORY{$slot}});
}

# _wholeTree() : recursive, produces the full list of inheriting frames
sub _wholeTree {
  my ($res, @dig) = @_;
  return $res unless $dig[0];
  my @inheriting = map { _firstInheriting($_) } @dig;
  push(@$res, @inheriting);
  return _wholeTree($res, @inheriting);
}

# _framesProvidingSlot() : all frames providing $slot DIRECTLY OR BY INHERITANCE
sub _framesProvidingSlot {
  my ($slot) = @_;

  my @res = _hasSlot($slot);
  my @inheriting = map { _firstInheriting($_) } @res;

  push @res, @inheriting;
  return _wholeTree(\@res, @inheriting);
}

# TODO - bench fmatch() versions !
#
sub fmatch {
  my %opts = @_;
  $opts{slot} = [ $opts{slot} || () ] unless _isa($opts{slot}, 'ARRAY');
  my ($firstslot, @otherslots) = @{$opts{slot} || []};

  return () unless $firstslot;

  my %filter = map { $_->{_KEY} ? ($_->{_KEY} => 'Y') : () } @{_framesProvidingSlot($firstslot)};

  for (@otherslots) {
    %filter = map { $filter{$_->{_KEY}} ? ($_->{_KEY} => 'Y') : () } @{_framesProvidingSlot($_)};
  }

  return grep { $filter{$_->{_KEY}} } @{$opts{from}} if $opts{from};
  return map { $FMAP{$_} || () } keys(%filter);

} # fmatch

=head2 fselect

Selects the best-matching frame(s) from the global registry given a set of
observed slot/value pairs.  This implements the frame-selection mechanism
described by Minsky (1974): given a situation described by a set of properties,
find the prototype that fits it best.

  # Best single match (highest score)
  my $proto = fselect(color => 'blue', can_fly => 1);

  # All candidates with a positive score, ranked best-first
  my @ranked = fselect(color => 'blue', can_fly => 1, _all => 1);

  # Restrict the search space
  my $proto = fselect(color => 'blue', _from => \@candidates);

  # Frame network: search seed + its declared _ALTERNATIVES
  my $Bird = Chorus::Frame->new(can_fly => 1, _ALTERNATIVES => [$Bat, $Insect]);
  my $best = fselect(can_fly => 1, legs => 6, _alternatives => $Bird);

  # Accept candidates with zero matching slots (score >= 0)
  my @all = fselect(color => 'blue', _all => 1, _min => 0);

B<Scoring> -- for each candidate frame, one point is awarded for each
C<< slot => value >> pair where the frame provides the slot B<and> its resolved
value (via C<get()>) matches the observed value.  Frames with a score strictly
below C<_min> (default: 1) are excluded.

B<Options> (prefixed with C<_> to avoid collision with slot names):

  _all          If true, return all matching frames ranked by descending score
                instead of just the best one.  In list context, the return value
                is a list of frames.  In scalar context, it is an arrayref.

  _from         Arrayref -- restrict the candidate pool to this list of frames.
                If absent, all registered frames are considered.

  _alternatives Seed frame -- restrict the candidate pool to the seed frame plus
                all frames listed in its C<_ALTERNATIVES> slot.  This implements
                Minsky's frame network: when a prototype does not fit, try its
                declared siblings.  Cannot be combined with C<_from>.

  _min          Minimum score to be included in the result (default: 1).
                Pass C<_min =E<gt> 0> to include frames that match none of the
                observed slots.

Returns C<undef> (scalar) or C<()> (list) when no candidate meets the
minimum score.

=cut

sub fselect {
  my %obs = @_;

  # Extract control options
  my $want_all     = delete $obs{_all};
  my $from         = delete $obs{_from};
  my $alternatives = delete $obs{_alternatives};
  my $min          = exists $obs{_min} ? delete $obs{_min} : 1;

  return wantarray ? () : undef unless %obs;

  # Build candidate pool
  my @candidates;
  if ($alternatives) {
    # Frame network: seed + its _ALTERNATIVES
    my $alts = _inherited($alternatives, '_ALTERNATIVES');
    @candidates = ($alternatives,
                   ($alts && ref($alts) eq 'ARRAY' ? @$alts : ()));
  } elsif ($from) {
    @candidates = @$from;
  } else {
    # All registered frames (skip destroyed/GC'd weak refs)
    @candidates = grep { defined } values %FMAP;
  }

  # Score each candidate
  my @scored;
  for my $frame (@candidates) {
    next unless ref($frame) eq 'Chorus::Frame';
    my $score = 0;
    for my $slot (keys %obs) {
      # Award one point when the frame provides the slot AND the value matches
      if (exists $REPOSITORY{$slot} && exists $REPOSITORY{$slot}->{$frame->{_KEY}}) {
        my $val = do {
          local $SELF = $frame;
          eval { $frame->get($slot) };
        };
        $score++ if defined $val && defined $obs{$slot} && $val eq $obs{$slot};
      }
    }
    push @scored, { frame => $frame, score => $score } if $score >= $min;
  }

  return wantarray ? () : undef unless @scored;

  # Sort by descending score
  my @ranked = map  { $_->{frame} }
               sort { $b->{score} <=> $a->{score} }
               @scored;

  return $want_all ? (wantarray ? @ranked : \@ranked) : $ranked[0];

} # fselect

=head1 AUTHOR

Christophe Ivorra

=head1 BUGS

Please report bugs via the CPAN request tracker:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chorus-Frame>

=head1 SUPPORT

  perldoc Chorus::Frame

=over 4

=item * RT -- L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chorus-Frame>

=item * AnnoCPAN -- L<http://annocpan.org/dist/Chorus-Frame>

=item * CPAN Ratings -- L<http://cpanratings.perl.org/d/Chorus-Frame>

=item * Search CPAN -- L<http://search.cpan.org/dist/Chorus-Frame/>

=back

=head1 SEE ALSO

L<Chorus::Engine>, L<Chorus::Expert>, L<Chorus::Collection::List>,
L<Chorus::Collection::Filter>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Christophe Ivorra.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Chorus::Frame
