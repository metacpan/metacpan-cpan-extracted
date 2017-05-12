package Class::Struct::FIELDS;

require 5.005_64;
use strict;
use warnings::register;

use Carp;

# AutoLoader would be nice, but it mucks up with evaling the package
# definitions in 'struct'.  Hmmm.

use AutoLoader qw(AUTOLOAD);
use base qw(Exporter);

# Items to export into callers namespace by default. Note: do not
# export names by default without a very good reason. Use EXPORT_OK
# instead.  Do not simply export all your public
# functions/methods/constants.

# This allows declaration use Class::Struct::FIELDS ':all'; If you do
# not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = (all => [qw(struct)]);
our @EXPORT_OK = (@{$EXPORT_TAGS{all}});
our @EXPORT = qw(struct);

# I'd like to say "our $VERSION = v1.1;", but MakeMaker--even in perl
# 5.6.0--, doesn't grok that and has trouble creating a Makefile.
our $VERSION = '1.1';
my $rcs = qq$Id: FIELDS.pm,v 1.1.1.1 2001/04/08 23:28:31 binkley Exp $;

# my %SEEN_PKGS = ();

sub struct;

sub _array ($$;$);
sub _arraytie ($$);
sub _arrayref ($$;$);
sub _code ($$;$);
sub _coderef ($$;$);
sub _baseclass_warning ($$);
sub _get_isa ($$);
sub _hash ($$;$);
sub _hashtie ($$);
sub _hashref ($$;$);
sub _mini_prolog ($$);
sub _new_new_warning ($);
sub _object ($$$$;$);
sub _array_object ($$$$;$);
sub _hash_object ($$$$;$);
sub _objectref ($$$$;$);
sub _override_warning ($$);
sub _postlog ( );
sub _prolog ($$$);
sub _regexp ($$;$);
sub _regexpref ($$;$);
sub _scalar ($$;$);
sub _scalarref ($$;$);
sub _stringify ( );
sub _usage_error;

# Preloaded methods go here.

sub import {
  my ($class) = shift;

  # We consume all of @_, so don't pass it along.
  $class->export_to_level (1);

  # Consume our own frame so that &struct thinks our caller is the
  # real caller.
  goto &struct if @_;
}

sub struct {
  my ($class, $isa, $decls);
  my $caller = caller;

  if (my $ref = ref $_[0]) { # guess class from caller
    if ($ref eq 'ARRAY') {
      if ($ref = ref $_[1]) {
	if ($ref eq 'HASH') { # called as "{LIST}, [LIST]"
	  ($class, $isa, $decls) = ($caller, shift, shift);
	  _usage_error if @_;
	}

	else {
	  _usage_error;
	}
      }

      else { # called as "[LIST], LIST"
	($class, $isa, $decls) = ($caller, shift, {@_});
      }
    }

    elsif ($ref eq 'HASH') { # called as "{LIST}"
      ($class, $isa, $decls) = ($caller, [], shift);
      _usage_error if @_;
    }

    else {
      _usage_error;
    }
  }

  else { # caller listed
    if ($ref = ref $_[1]) {
      if ($ref eq 'ARRAY') {
	if ($ref = ref $_[2]) {
	  if ($ref eq 'HASH') { # called as "[LIST], {LIST}"
	    ($class, $isa, $decls) = (shift, shift, shift);
	    _usage_error if @_;
	  }

	  else {
	    _usage_error;
	  }
	}

	else { # called as "[LIST], LIST"
	  ($class, $isa, $decls) = (shift, shift, {@_});
	}
      }

      elsif ($ref eq 'HASH') { # called as "CLASS, {LIST}"
	($class, $isa, $decls) = (shift, [], shift);
	_usage_error if @_;
      }

      else {
	_usage_error;
      }
    }

    else {
      if (@_) {
	if (@_ % 2) { # called as "LIST" with CLASS
	  ($class, $isa, $decls) = (shift, [], {@_});
	}

	else { # called as "LIST" without CLASS
	  ($class, $isa, $decls) = ($caller, [], {});
	}
      }

      else { # called as plain "&struct"
	($class, $isa, $decls) = ($caller, [], {});
      }
    }
  }

  eval _mini_prolog ($class, $isa); # baseclass warnings
  my $eval = _prolog ($class, $isa, $decls);

  # Automagic overload support.
  $eval .= _stringify
    if (do { no strict qw(refs); exists &{"$class\::as_string"} });

  while (my ($k, $v) = each %$decls) {
    my $hidden = undef;

    # Don't make subroutines for "private" keys; you should access
    # them directly: $self->{_blah_blah};  See fields.
    next if $k =~ /^_/o;

    # Check for three cases:
    #
    # 1. Caller has already defined an accessor.
    #
    # 2. Base class has a same-named method.
    #
    # 3. Take care to use exists instead of defined so that caller can
    #    use sub declarations before actually defining the access
    #    method.

    if (do { no strict qw(refs); exists &{"$class\::$k"} }) {
      _override_warning ($class, $k);
      $hidden = 1;
      # next;
    }

    # This doesn't work?  XXX
    _baseclass_warning ($class, $k) if UNIVERSAL::can ($class, $k);

    if ($v eq '$') {
      $eval .= _scalar ($class, $k, $hidden);
    }

    elsif ($v eq '\$' or $v eq '*$') {
      $eval .= _scalarref ($class, $k, $hidden);
    }

    elsif ($v eq '@') {
      $eval .= _array ($class, $k, $hidden);
    }

    # EXPERIMENTAL  XXX
    elsif ($v eq '+@') {
      $eval .= _arraytie ($class, $k);
      $eval .= _array ($class, $k, $hidden);
    }

    elsif ($v eq '\@' or $v eq '*@') {
      $eval .= _arrayref ($class, $k, $hidden);
    }

    elsif ($v eq '%') {
      $eval .= _hash ($class, $k, $hidden);
    }

    # EXPERIMENTAL  XXX
    elsif ($v eq '+%') {
      $eval .= _hashtie ($class, $k);
      $eval .= _hash ($class, $k, $hidden);
    }

    elsif ($v eq '\%' or $v eq '*%') {
      $eval .= _hashref ($class, $k, $hidden);
    }

    elsif ($v eq '&') {
      $eval .= _code ($class, $k, $hidden);
    }

    elsif ($v eq '\&' or $v eq '*&') {
      $eval .= _coderef ($class, $k, $hidden);
    }

    elsif ($v eq '/') {
      $eval .= _regexp ($class, $k, $hidden);
    }

    elsif ($v eq '\/' or $v eq '*/') {
      $eval .= _regexpref ($class, $k, $hidden);
    }

    # EXPERIMENTAL  XXX
    elsif ($v =~ s/^\+@(\w+(?:::\w+)*)$/$1/o) {
#       $SEEN_PKGS{$class}->{$k} = $v;
      $eval .= _arraytie ($class, $k);
      $eval .= _array_object ($class, $caller, $k, $v, $hidden);
    }

    # EXPERIMENTAL  XXX
    elsif ($v =~ s/^@(\w+(?:::\w+)*)$/$1/o) {
#       $SEEN_PKGS{$class}->{$k} = $v;
      $eval .= _array_object ($class, $caller, $k, $v, $hidden);
    }

    # EXPERIMENTAL  XXX
    elsif ($v =~ s/^\+%(\w+(?:::\w+)*)$/$1/o) {
#       $SEEN_PKGS{$class}->{$k} = $v;
      $eval .= _hashtie ($class, $k);
      $eval .= _hash_object ($class, $caller, $k, $v, $hidden);
    }

    # EXPERIMENTAL  XXX
    elsif ($v =~ s/^%(\w+(?:::\w+)*)$/$1/o) {
#       $SEEN_PKGS{$class}->{$k} = $v;
      $eval .= _hash_object ($class, $caller, $k, $v, $hidden);
    }

    elsif ($v =~ s/^[\\*](\w+(?:::\w+)*)$/$1/o) {
#       $SEEN_PKGS{$class}->{$k} = $v;
      $eval .= _objectref ($class, $caller, $k, $v, $hidden);
    }

    elsif ($v =~ /^\w+(?:::\w+)*$/o) {
#       $SEEN_PKGS{$class}->{$k} = $v;
      $eval .= _object ($class, $caller, $k, $v, $hidden);
    }

    else {
      _usage_error;
    }
  }

  $eval .= _postlog;

  eval $eval;
  carp $@ if $@;

  $class;
}

# Work around a broken UNIVERSAL::isa in 5.6.0:
if ($^V eq v5.6.0) {
  no warnings;

  # sub UNIVERSAL::isa {
  sub isa {
    my ($class, $super) = @_;
    $class = ref $class || $class;
    return 1 if $class eq $super; # trivial case

    my $f = sub {
      no strict qw(refs);

      my ($class, $super, $g) = @_;
      my @supers = @{"$class\::ISA"};

      foreach my $s (@supers) {
	return 1 if $s eq $super;
	# Does Perl optimizer understand tail recursion?
	return $g->($s, $super, $g);
      }

      return '';
    };

    return $f->($class, $super, $f);
  }

  *UNIVERSAL::isa = \&isa;
}

sub _get_isa ($$) {
  my ($class, $isa) = @_;
  my @isa;

  {
    no strict qw(refs);

    @isa = (@{"$class\::ISA"}, @$isa); # preserve the existing @ISA
  }

  return @isa;
}

sub _mini_prolog ($$) {
  my ($class, $isa) = @_;
  my @isa = _get_isa ($class, $isa);

  <<EOC;
{
  package $class;
  use base qw(@isa);
}
EOC
}

sub _prolog ($$$) {
  my ($class, $isa, $decls) = @_;
  my @isa = _get_isa ($class, $isa);
  my @fields = keys %$decls;

  <<EOC;
{
  package $class;

  require 5.005_64;
  use strict;
  use warnings;

  use Carp;

  use base qw(@isa);
  use fields qw(@fields);

  # Allow user to provide their own new as long as they return
  # \$self->_init (\@_);
  unless (do { no strict qw(refs); exists &{$class\::new} }) {
    *{$class\::new} = sub {
      my \$this = shift;
      my \$class = ref \$this || \$this || __PACKAGE__;
      my $class \$self = fields::new (\$class);

      \$self->_init (\@_);
    };
  }

  else {
    Class::Struct::FIELDS::_new_new_warning ('$class');
  }

  # Two-step initialization so that user-defined init's will have the
  # parents' fields all ready to go.  This relies on cooperation from
  # sub new.
  sub _init {
    my $class \$self = shift;
    my \%init = \@_;

    # Simple solution for now.  Some problems:
    #
    # 1. Diamond inheritance can call _init multiple times.  I don't
    # know if it's a good thing, or a bad thing, but fields forbids
    # multiple inheritance.
    #
    # 2. Member initialization gets called every time through.

    for (qw(@isa)) {
      eval { bless \$self, \$_; \$self = \$self->_init (\@_) };
    }

    bless \$self, qw($class);

    # Init our fields to be like Class::Struct.  According to the
    # documentation for fields, the call to fields::new should have
    # set up our parents as well, so that we can init their fields
    # too.  Make sure to call the accessors so that user-defined ones
    # are invoked (instead of assigning directly to the pseudo-hash.)
    {
      no strict qw(refs);

      # Only invoke valid keys; pass the rest through unmolested.
      my \$c;

      while (my (\$k, \$v) = each \%init) {
        \$self->\$c (\$v) if \$c = $class\::->can (\$k);
      }
    }

    eval { \$self = \$self->init (\@_) }; # if \$self->can ('init');

    \$self;
  }
EOC
}

sub _postlog ( ) {
  <<EOC;

  1;
}
EOC
}

1;

# Autoload methods go after __END__, and are processed by the
# autosplit program.

__END__

sub _stringify ( ) {
  <<EOC;

  use overload
    '""' => sub { \$_[0]->as_string },
    bool => sub { 1 };
EOC
}

sub _usage_error {
  croak <<EOE;
'struct' usage error
EOE
}

sub _baseclass_warning ($$) {
  warnings::warn <<EOE if warnings::enabled ( );
Accessor '$_[1]' exists in package '$_[0]' hides method in base class
EOE
}

sub _override_warning ($$) {
  warnings::warn <<EOE if warnings::enabled ( );
Method '$_[1]' exists in package '$_[0]' overrides accessor
EOE
}

sub _new_new_warning ($) {
  warnings::warn <<EOE if warnings::enabled ( );
Method 'new' already exists in package '$_[0]'
EOE
}

# Until lvalue subs work right under the debugger, fall back on old
# get/set syntax.

sub _scalar ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$) {
    my $class \$self = \$_[0];

    \@_ == 2 ? \$self->{$k} = \$_[1] : \$self->{$k};
  }
EOC
}

sub _scalarref ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$) {
    my $class \$self = \$_[0];

    \\(\@_ == 2 ? \$self->{$k} = \$_[1] : \$self->{$k});
  }
EOC
}

sub _array ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$\$) {
    my $class \$self = \$_[0];

    if (\@_ == 3) {
      \$self->{$k}->[\$_[1]] = \$_[2];
    }

    elsif (\@_ == 2) {
      if (my \$ref = ref \$_[1]) {
        croak "Initializer for '$k' must be ARRAY reference"
          if \$ref ne 'ARRAY';
        \$self->{$k} = \$_[1];
      }

      else {
        \$self->{$k}->[\$_[1]];
      }
    }

    else {
      \$self->{$k} ||= [];
    }
  }
EOC
}

sub _arraytie ($$) {
  my ($class, $k) = @_;

  <<EOC;

  use base qw(Tie::Array);

  sub TIEARRAY
  {
    (shift)->new (\@_);
  }

  if (do { no strict qw(refs); exists &{$class\::FETCH} }) {
    *{$class\::_FETCH} = sub {
      my $class \$self = \$_[0];
      \$self->$k \(\$_[1]);
    };
  }

  else {
    *{$class\::FETCH} = sub {
      my $class \$self = \$_[0];
      \$self->$k \(\$_[1]);
    };
  }

  if (do { no strict qw(refs); exists &{$class\::FETCHSIZE} }) {
    *{$class\::_FETCHSIZE} = sub {
      my $class \$self = \$_[0];
      scalar \@{\$self->$k};
    };
  }

  else {
    *{$class\::FETCHSIZE} = sub {
      my $class \$self = \$_[0];
      scalar \@{\$self->$k};
    };
  }

  if (do { no strict qw(refs); exists &{$class\::STORE} }) {
    *{$class\::_STORE} = sub {
      my $class \$self = \$_[0];
      \$self->$k \(\$_[1], \$_[2]);
    };
  }

  else {
    *{$class\::STORE} = sub {
      my $class \$self = \$_[0];
      \$self->$k \(\$_[1], \$_[2]);
    };
  }

  if (do { no strict qw(refs); exists &{$class\::STORESIZE} }) {
    *{$class\::_STORESIZE} = sub {
      my $class \$self = \$_[0];
      \$#{\$self->$k} = \$_[1] - 1;
    };
  }

  else {
    *{$class\::STORESIZE} = sub {
      my $class \$self = \$_[0];
      \$#{\$self->$k} = \$_[1] - 1;
    };
  }

  if (do { no strict qw(refs); exists &{$class\::EXISTS} }) {
    *{$class\::_EXISTS} = sub {
      my $class \$self = \$_[0];
      exists \$self->$k\->[\$_[1]];
    };
  }

  else {
    *{$class\::EXISTS} = sub {
      my $class \$self = \$_[0];
      exists \$self->$k\->[\$_[1]];
    };
  }

  if (do { no strict qw(refs); exists &{$class\::DELETE} }) {
    *{$class\::_DELETE} = sub {
      my $class \$self = \$_[0];
      delete \$self->$k\->[\$_[1]];
    };
  }

  else {
    *{$class\::DELETE} = sub {
      my $class \$self = \$_[0];
      delete \$self->$k\->[\$_[1]];
    };
  }
EOC
}

sub _arrayref ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$\$) {
    my $class \$self = \$_[0];

    if (\@_ == 3) {
      \\(\$self->{$k}->[\$_[1]] = \$_[2]);
    }

    elsif (\@_ == 2) {
      if (my \$ref = ref \$_[1]) {
        croak "Initializer for '$k' must be ARRAY reference"
          if \$ref ne 'ARRAY';
        \\(\$self->{$k} = \$_[1]);
      }

      else {
        \\(\$self->{$k}->[\$_[1]]);
      }
    }

    else {
      \$self->{$k} ||= [];
    }
  }
EOC
}

sub _hash ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$\$) {
    my $class \$self = \$_[0];

    if (\@_ == 3) {
      \$self->{$k}->{\$_[1]} = \$_[2];
    }

    elsif (\@_ == 2) {
      if (my \$ref = ref \$_[1]) {
        croak "Initializer for '$k' must be HASH reference"
          if \$ref ne 'HASH';
        \$self->{$k} = \$_[1];
      }

      else {
        \$self->{$k}->{\$_[1]};
      }
    }

    else {
      \$self->{$k} ||= {};
    }
  }
EOC
}

sub _hashtie ($$) {
  my ($class, $k) = @_;

  <<EOC;

  use base qw(Tie::Hash);

  sub TIEHASH
  {
    (shift)->new (\@_);
  }

  if (do { no strict qw(refs); exists &{$class\::FETCH} }) {
    *{$class\::_FETCH} = sub {
      my $class \$self = \$_[0];
      \$self->$k \(\$_[1]);
    };
  }

  else {
    *{$class\::FETCH} = sub {
      my $class \$self = \$_[0];
      \$self->$k \(\$_[1]);
    };
  }

  if (do { no strict qw(refs); exists &{$class\::STORE} }) {
    *{$class\::_STORE} = sub {
      my $class \$self = \$_[0];
      \$self->$k \(\$_[1], \$_[2]);
    };
  }

  else {
    *{$class\::STORE} = sub {
      my $class \$self = \$_[0];
      \$self->$k \(\$_[1], \$_[2]);
    };
  }

  if (do { no strict qw(refs); exists &{$class\::FIRSTKEY} }) {
    *{$class\::_FIRSTKEY} = sub {
      my $class \$self = \$_[0];
      # Why does Tie::StdHash ensure the keys are auto-vivified?
      my \$a = scalar keys %{\$self->$k};
      each %{\$self->$k};
    };
  }

  else {
    *{$class\::FIRSTKEY} = sub {
      my $class \$self = \$_[0];
      # Why does Tie::StdHash ensure the keys are auto-vivified?
      my \$a = scalar keys %{\$self->$k};
      each %{\$self->$k};
    };
  }

  if (do { no strict qw(refs); exists &{$class\::NEXTKEY} }) {
    *{$class\::_NEXTKEY} = sub {
      my $class \$self = \$_[0];
      each %{\$self->$k};
    };
  }

  else {
    *{$class\::NEXTKEY} = sub {
      my $class \$self = \$_[0];
      each %{\$self->$k};
    };
  }

  if (do { no strict qw(refs); exists &{$class\::EXISTS} }) {
    *{$class\::_EXISTS} = sub {
      my $class \$self = \$_[0];
      exists \$self->$k\->[\$_[1]];
    };
  }

  else {
    *{$class\::EXISTS} = sub {
      my $class \$self = \$_[0];
      exists \$self->$k\->[\$_[1]];
    };
  }

  if (do { no strict qw(refs); exists &{$class\::DELETE} }) {
    *{$class\::_DELETE} = sub {
      my $class \$self = \$_[0];
      delete \$self->$k\->{\$_[1]};
    };
  }

  else {
    *{$class\::DELETE} = sub {
      my $class \$self = \$_[0];
      delete \$self->$k\->{\$_[1]};
    };
  }

  if (do { no strict qw(refs); exists &{$class\::CLEAR} }) {
    *{$class\::_CLEAR} = sub {
      my $class \$self = \$_[0];
      \$self->$k ({});
    };
  }

  else {
    *{$class\::CLEAR} = sub {
      my $class \$self = \$_[0];
      \$self->$k ({});
    };
  }
EOC
}

sub _hashref ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$\$) {
    my $class \$self = \$_[0];

    if (\@_ == 3) {
      \\(\$self->{$k}->{\$_[1]} = \$_[2]);
    }

    elsif (\@_ == 2) {
      if (my \$ref = ref \$_[1]) {
        croak "Initializer for '$k' must be HASH reference"
          if \$ref ne 'HASH';
        \\(\$self->{$k} = \$_[1]);
      }

      else {
        \\(\$self->{$k}->{\$_[1]});
      }
    }

    else {
      \$self->{$k} ||= {};
    }
  }
EOC
}

sub _code ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$) {
    my $class \$self = \$_[0];

    if (\@_ == 2) {
      croak "Initializer for '$k' must be code reference"
        if defined (\$_[1]) && ref (\$_[1]) ne 'CODE';
      \$self->{$k} = \$_[1];
    }

    else {
      \$self->{$k};
    }
  }
EOC
}

sub _coderef ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$) {
    my $class \$self = \$_[0];

    if (\@_ == 2) {
      croak "Initializer for '$k' must be code reference"
        if defined (\$_[1]) && ref (\$_[1]) ne 'CODE';
      \\(\$self->{$k} = \$_[1]);
    }

    else {
      \\(\$self->{$k});
    }
  }
EOC
}

sub _regexp ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$) {
    my $class \$self = \$_[0];

    if (\@_ == 2) {
      croak "Initializer for '$k' must be regular expression"
        if defined (\$_[1]) && ref (\$_[1]) ne 'Regexp';
      \$self->{$k} = \$_[1];
    }

    else {
      \$self->{$k};
    }
  }
EOC
}

sub _regexpref ($$;$) {
  my ($class, $k, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  <<EOC;

  sub $sub (\$;\$) {
    my $class \$self = \$_[0];

    if (\@_ == 2) {
      croak "Initializer for '$k' must be regular expression"
        if defined (\$_[1]) && ref (\$_[1]) ne 'Regexp';
      \\(\$self->{$k} = \$_[1]);
    }

    else {
      \\(\$self->{$k});
    }
  }
EOC
}

sub _object ($$$$;$) {
  my ($class, $caller, $k, $v, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  # In caller's package:
  # From base.pm:
  eval "package $caller; require $v";
  # Only ignore "Can't locate" errors from our eval require.  Other
  # fatal errors (syntax etc) must be reported.
  die if $@ && $@ !~ /^Can't locate .*? at \(eval /;

  <<EOC;

  # From base.pm:
  eval "require $v";
  # Only ignore "Can't locate" errors from our eval require.  Other
  # fatal errors (syntax etc) must be reported.
  die if \$@ && \$@ !~ /^Can't locate .*? at \\(eval /;

  sub $sub (\$;\$) {
    my $class \$self = \$_[0];

    if (\@_ == 2) {
      croak "Initializer for '$k' must be $v object"
        if (defined \$_[1] and not UNIVERSAL::isa (\$_[1], '$v'));
      \$self->{$k} = \$_[1];
    }

    else {
      \$self->{$k} ||= $v\::->new;
    }
  }
EOC
}

sub _array_object ($$$$;$) {
  my ($class, $caller, $k, $v, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  # In caller's package:
  # From base.pm:
  eval "package $caller; require $v";
  # Only ignore "Can't locate" errors from our eval require.  Other
  # fatal errors (syntax etc) must be reported.
  die if $@ && $@ !~ /^Can't locate .*? at \(eval /;

  <<EOC;

  # From base.pm:
  eval "require $v";
  # Only ignore "Can't locate" errors from our eval require.  Other
  # fatal errors (syntax etc) must be reported.
  die if \$@ && \$@ !~ /^Can't locate .*? at \\(eval /;

  sub $sub (\$;\$\$) {
    my $class \$self = \$_[0];

    if (\@_ == 3) {
      croak "Initializer for '$k' must be $v"
        if not UNIVERSAL::isa (\$_[2], '$v');
      \$self->{$k}->[\$_[1]] = \$_[2];
    }

    elsif (\@_ == 2) {
      if (my \$ref = ref \$_[1]) {
        croak "Initializer for '$k' must be ARRAY reference"
          if not UNIVERSAL::isa (\$_[2], 'ARRAY');
        \$self->{$k} = \$_[1];
      }

      else {
        \$self->{$k}->[\$_[1]] ||= $v\::->new;
      }
    }

    else {
      \$self->{$k} ||= [];
    }
  }
EOC
}

sub _hash_object ($$$$;$) {
  my ($class, $caller, $k, $v, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  # In caller's package:
  # From base.pm:
  eval "package $caller; require $v";
  # Only ignore "Can't locate" errors from our eval require.  Other
  # fatal errors (syntax etc) must be reported.
  die if $@ && $@ !~ /^Can't locate .*? at \(eval /;

  <<EOC;

  # From base.pm:
  eval "require $v";
  # Only ignore "Can't locate" errors from our eval require.  Other
  # fatal errors (syntax etc) must be reported.
  die if \$@ && \$@ !~ /^Can't locate .*? at \\(eval /;

  sub $sub (\$;\$\$) {
    my $class \$self = \$_[0];

    if (\@_ == 3) {
      croak "Initializer for '$k' must be $v"
        if not UNIVERSAL::isa (\$_[2], '$v');
      \$self->{$k}->{\$_[1]} = \$_[2];
    }

    elsif (\@_ == 2) {
      if (my \$ref = ref \$_[1]) {
        croak "Initializer for '$k' must be HASH reference"
          if not UNIVERSAL::isa (\$_[2], 'HASH');
        \$self->{$k} = \$_[1];
      }

      else {
        \$self->{$k}->{\$_[1]} ||= $v\::->new;
      }
    }

    else {
      \$self->{$k} ||= {};
    }
  }
EOC
}

sub _objectref ($$$$;$) {
  my ($class, $caller, $k, $v, $hidden) = @_;
  my $sub = $hidden ? "__$k" : $k;

  # In caller's package:
  # From base.pm:
  eval "package $caller; require $v";
  # Only ignore "Can't locate" errors from our eval require.  Other
  # fatal errors (syntax etc) must be reported.
  die if $@ && $@ !~ /^Can't locate .*? at \(eval /;

  <<EOC;

  # From base.pm:
  eval "require $v";
  # Only ignore "Can't locate" errors from our eval require.  Other
  # fatal errors (syntax etc) must be reported.
  die if \$@ && \$@ !~ /^Can't locate .*? at \\(eval /;

  sub $sub (\$;\$) {
    my $class \$self = \$_[0];

    if (\@_ == 2) {
      croak "Initializer for '$k' must be $v object"
        if (defined \$_[1] and not UNIVERSAL::isa (\$_[1], '$v'));
      \\(\$self->{$k} = \$_[1]);
    }

    else {
      \\(\$self->{$k} ||= $v\::->new);
    }
  }
EOC
}

=head1 NAME

Class::Struct::FIELDS - Combine Class::Struct, base and fields

=head1 SYNOPSIS

(This page documents C<Class::Struct::FIELDS> v.1.1.)

    use Class::Struct::FIELDS;
            # declare struct, based on fields, explicit class name:
    struct (CLASS_NAME => { ELEMENT_NAME => ELEMENT_TYPE, ... });

    use Class::Struct::FIELDS;
            # declare struct, based on fields, explicit class name
            # with inheritance:
    struct (CLASS_NAME => [qw(BASE_CLASSES ...)],
	    { ELEMENT_NAME => ELEMENT_TYPE, ... });

    package CLASS_NAME;
    use Class::Struct::FIELDS;
            # declare struct, based on fields, implicit class name:
    struct (ELEMENT_NAME => ELEMENT_TYPE, ...);

    package CLASS_NAME;
    use Class::Struct::FIELDS;
            # declare struct, based on fields, implicit class name
            # with inheritance:
    struct ([qw(BASE_CLASSES ...)], ELEMENT_NAME => ELEMENT_TYPE, ...);

    package MyObj;
    use Class::Struct::FIELDS;
            # declare struct with four types of elements:
    struct (s => '$', a => '@', h => '%', x => '&', c => 'My_Other_Class');

    $obj = new MyObj;               # constructor

                                    # scalar type accessor:
    $element_value = $obj->s;           # element value
    $obj->s ('new value');              # assign to element

                                    # array type accessor:
    $ary_ref = $obj->a;                 # reference to whole array
    $ary_element_value = $obj->a->[2];  # array element value
    $ary_element_value = $obj->a (2);   # same thing
    $obj->a->[2] = 'new value';         # assign to array element
    $obj->a (2, 'newer value');         # same thing

                                    # hash type accessor:
    $hash_ref = $obj->h;                # reference to whole hash
    $hash_element_value = $obj->h->{x}; # hash element value
    $hash_element_value = $obj->h (x);  # same thing
    $obj->h->{x} = 'new value';         # assign to hash element
    $obj->h (x, 'newer value');         # same thing

                                    # code type accessor:
    $code_ref = $obj->x;                # reference to code
    $obj->x->(...);                     # call code
    $obj->x (sub {...});                # assign to element

                                    # regexp type accessor:
    $regexp = $obj->r;                  # reference to code
    $string =~ m/$obj->r/;              # match regexp
    $obj->r (qr/ ... /);                # assign to element

                                    # class type accessor:
    $element_value = $obj->c;            # object reference
    $obj->c->method (...);               # call method of object
    $obj->c (My_Other_Class::->new);     # assign a new object

=head1 DESCRIPTION

C<Class::Struct::FIELDS> exports a single function, C<struct>.  Given
a list of element names and types, and optionally a class name and/or
an array reference of base classes, C<struct> creates a Perl 5 class
that implements a "struct-like" data structure with inheritance.

The new class is given a constructor method, C<new>, for creating
struct objects.

Each element in the struct data has an accessor method, which is
used to assign to the element and to fetch its value.  The
default accessor can be overridden by declaring a C<sub> of the
same name in the package.  (See Example 2.)

Each element's type can be scalar, array, hash, code or class.

=head2 Differences from C<Class::Struct> C<base> and C<fields>

C<Class::Struct::FIELDS> is a combination of C<Class::Struct>, C<base>
and C<fields>.

Unlike C<Class::Struct>, inheritance is explicitly supported, and
there is better support for user overrides of constructed accessor
methods.  One result is that you may no longer use the array (C<[]>)
notation for indicating internal representation.  Also,
C<Class::Struct::FIELDS> relies on C<fields> for internal
representation.

Also, C<Class::Struct::FIELDS> supports code and regular expression
elements.  (C<Class::Struct> handles code and regular expressions as
scalars.)

Lastly, C<Class::Struct::FIELDS> passes it's import list, if any, from
the call to C<use Class::Struct::FIELDS ...> to C<struct> so that you
may create new packages at compile-time.

Unlike C<fields>, each element has a data type, and is automatically
created at first access.

=head2 Calling C<use Class::Struct::FIELDS>

You may call C<use Class::Struct::FIELDS> just as with any module
library:

    use Class::Struct::FIELDS;
    struct Bob => [];

However, if you try C<my Dog $spot> syntax with this example:

    use Class::Struct::FIELDS;
    struct Bob => [];
    my Bob $bob = Bob::->new;

you will get a compile-time error:

    No such class Bob at <filename> line <number>, near "my Bob"
    Bareword "Bob::" refers to nonexistent package at <filename> line
    <number>.

since the compiler has not seen your class declarations yet until
after the call to C<struct>, by which time it has already seen your
C<my> declarations.  Oops, too late.  Instead, create the package for
C<Bob> during compilation:

    use Class::Struct::FIELDS qw(Bob);
    my Bob $bob = Bob::->new;

This compiles without error as C<import> for C<Class::Struct::FIELDS>
calls C<struct> for you if you have any arguments in the C<use>
statement.  A more interesting example is:

    use Class::Struct::FIELDS Bob => { a => '$' };
    use Class::Struct::FIELDS Fred => [qw(Bob)];
    my Bob $bob = Bob::->new;
    my Fred $fred = Fred::->new;

=head2 The C<struct> subroutine

The C<struct> subroutine has three forms of parameter-list:

    struct (CLASS_NAME => { ELEMENT_LIST });
    struct (CLASS_NAME, ELEMENT_LIST);
    struct (ELEMENT_LIST);

The first form explicitly identifies the name of the class being
created.  The second form is equivalent.  The second form assumes the
current package name as the class name.  The second and third forms
are distinguished by the parity of the argument list: an odd number of
arguments is taken to be of the second form.

Optionally, you may specify base classes with an array reference as
the first non-class-name argument:

    struct (CLASS_NAME => [qw(BASE_CLASSES ...)], { ELEMENT_LIST });
    struct (CLASS_NAME => [qw(BASE_CLASSES ...)], ELEMENT_LIST);
    struct ([qw(BASE_CLASSES ...)], { ELEMENT_LIST });
    struct ([qw(BASE_CLASSES ...)], ELEMENT_LIST);

(Since there is no ambiguity between CLASS_NAME and ELEMENT_LIST with
the interposing array reference, you may always make ELEMENT_LIST a
list or a hash reference with this form.)

The class created by C<struct> may be either a subclass or superclass
of other classes.  See L<base> and L<fields> for details.

The I<ELEMENT_LIST> has the form

    NAME => TYPE, ...

Each name-type pair declares one element of the struct. Each element
name will be usually be defined as an accessor method of the same name
as the field, unless a method by that name is explicitly defined
(called a "user override") by the caller prior to the C<use> statement
for C<Class::Struct::FIELDS>.  (See L</Replacing member access methods
with user overrides>.)

C<struct> returns the name of the newly-constructed package.

=head2 Element Types and Accessor Methods

The five element types -- scalar, array, hash, code and class -- are
represented by strings -- C<$>, C<@>, C<%>, C<&>, C</> and a class
name.

The accessor method provided by C<struct> for an element depends on
the declared type of the element.

=over

=item Scalar (C<$>, C<\$> or C<*$>)

The element is a scalar, and by default is initialized to C<undef>
(but see L<Initializing with new>).

The accessor's argument, if any, is assigned to the element.

If the element type is C<$>, the value of the element (after
assignment) is returned. If the element type is C<\$> or C<*$>, a
reference to the element is returned.

=item Array (C<@>, C<\@> or C<*@>)

The element is an array, initialized by default to C<()>.

With no argument, the accessor returns a reference to the element's
whole array (whether or not the element was specified as C<@>, C<\@>
or C<*@>).

With one or two arguments, the first argument is an index specifying
one element of the array; the second argument, if present, is assigned
to the array element.  If the element type is C<@>, the accessor
returns the array element value.  If the element type is C<\@> or
C<*@>, a reference to the array element is returned.

=item Hash (C<%>, C<\%> or C<*%>)

The element is a hash, initialized by default to C<()>.

With no argument, the accessor returns a reference to the element's
whole hash (whether or not the element was specified as C<%>,
C<\%> or C<*%>).

With one or two arguments, the first argument is a key specifying one
element of the hash; the second argument, if present, is assigned to
the hash element.  If the element type is C<%>, the accessor returns
the hash element value.  If the element type is C<\%> or C<*%>, a
reference to the hash element is returned.

=item Code (C<&>, C<\&> or C<*&>)

The element is code, and by default is initialized to C<undef> (but
see L<Initializing with new>).

The accessor's argument, if any, is assigned to the element.

If the element type is C<&>, the value of the element (after
assignment) is returned.  If the element type is C<\&> or C<*&>, a
reference to the element is returned.  (It is unclear of what value
this facility is.  XXX)

=item Regexp (C</>, C<\/> or C<*/>)

If the element type is C</>, the value of the element (after
assignment) is returned.  If the element type is C<\/> or C<*/>, a
reference to the element is returned.  (It is unclear of what value
this facility is.  XXX)

Regular expressions really are special in that you create them with
special syntax, not with a call to a constructor:

  $obj->r (qr/^$/); # fine
  $obj->r (Regexp->new); # WRONG

=item Class (C<Class_Name>, C<\Class_Name> or C<*Class_Name>)

The element's value must be a reference blessed to the named class or
to one of its subclasses. The element is initialized to the result of
calling the C<new> constructor of the named class.

The accessor's argument, if any, is assigned to the element. The
accessor will C<croak> if this is not an appropriate object reference.

If the element type does not start with a C<\> or C<*>, the accessor
returns the element value (after assignment). If the element type
starts with a C<\> or C<*>, a reference to the element itself is
returned.

The class is automatically required for you so that, for example, you
can safely write:

    struct MyObj {io => 'IO::Scalar'};

and access C<io> immediately.  The same applies for nested structs:

    BEGIN {
      struct Alice { when => '$' };
      struct Bob { who => 'Alice' };
    }

    my Bob $b = Bob::->new;
    $b->who->when ('what');

Note, however, the C<BEGIN> block so that this example can use the
C<my Dog $spot> syntax for C<my Bob $b>.  Also, no actual import
happens for the caller -- the automatic use is only for convenience in
auto-constructing members, not magic.  Another way to do this is:

    { package Bob; use Class::Struct::FIELDS; struct }
    my Bob $b = Bob::->new;

And of course the best way to do this is simply:

    use Class::Struct::FIELDS qw(Bob);
    my Bob $b = Bob::->new;

=item What about globs (C<*>) and other funny types?

At present, C<Class::Struct::FIELDS> does not support special notation
for other intrinsic types.  Use a scalar to hold a reference to globs
and other unusual specimens, or wrap them in a class such as
C<IO::Handle> (globs).  XXX

=back

=head2 Initializing with C<new>

C<struct> always creates a constructor called C<new>. That constructor
may take a list of initializers for the various elements of the new
struct.

Each initializer is a pair of values: I<element name>C< =E<gt>
>I<value>.  The initializer value for a scalar element is just a
scalar value.  The initializer for an array element is an array
reference.  The initializer for a hash is a hash reference.  The
initializer for code is a code reference.

The initializer for a class element is also a hash reference, and the
contents of that hash are passed to the element's own constructor.

C<new> tries to be as clever as possible in deducing what type of
object to construct.  All of these are valid:

    use Class::Struct::FIELDS qw(Bob);
    my Bob $b = Bob::->new; # good style
    my Bob $b2 = $b->new; # works fine
    my Bob $b3 = &Bob::new; # if you insist
    my Bob $b4 = Bob::new (apple => 3, banana => 'four'); # WRONG!

The last case doesn't behave as hoped for: C<new> tries to construct
an object of package C<apple> (and hopefully fails, unless you
actually have a package named C<apple>), not an object of package
C<Bob>.

See Example 3 below for an example of initialization.

=head2 Initializing with C<init>

You may also use C<init> as a constructor to assign initial values to
new objects.  (In fact, this is the preferred method.)  C<struct> will
see to it that you have a ready object to work with, and pass you any
arguments used in the call to C<new>:

  sub init {
    my MyObj $self = shift;

    @self->a->[0..3] = (a..d);

    return $self;
  }

It is essential that you return an object from C<init>, as this is
returned to the caller of C<new>.  You may return a different object
if you wish, but this would be rather uncommon.

First, C<new> arranges for any constructor argument list to be
processed first before calling C<init>.

Second, C<new> arranges to call C<init> for base classes, calling them
in bottom-up order, before calling C<init>.  This is so that ancestors
may construct an object before descendents.

There is no corresponding facility for DESTROY.  XXX

=head2 Replacing member access methods with user overrides

You might want to create custom access methods, or user overrides.
The most straight forward way to do this and still retain C<string>
and C<warnings> is:

    use strict;
    use warnings;

    sub Bob::ff ($;$$); # declare sub so Class::Struct::FIELDS can see

    use Class::Struct::FIELDS Bob => { ff => '$' };

    sub Bob::ff ($;$$) {
      my Bob $self = shift;

      &some_other_sub (@_);
    }

If you do not declare the user override prior to the C<use> statement,
a warning is issued if the warning flag (B<-w>) is set.

Notice that we changed the default sub signature for I<ff> from
C<($;$)> to C<($;$$)>.  Normally, this might generate a warning if we
redefine the sub, but declaring the sub ahead of time keeps C<strict>
and C<warnings> happy.  You might prefer this construction:

    { package Bob; }

    sub Bob::ff ($;$$) {
      my Bob $self = shift;

      &some_other_sub (@_);
    }

    use Class::Struct::FIELDS Bob => { ff => '$' };

You might still want the advantages of the the constructed accessor
methods, even with user overrides (for example, checking that an
assigned value is the right type or package). C<Class::Struct::FIELDS>
constructs the accessor with a special name, so that you may use it
yourself in the user override.  That special name is the regular field
name prepended by a double underscore, C<__>.  You can access these
so:

    use strict;
    use warnings;

    sub Bob::ff ($;$); # declare sub so Class::Struct::FIELDS can see
    sub Bob::gg ($;$); # declare sub so Class::Struct::FIELDS can see

    use Class::Struct::FIELDS Bob => { ff => '$', gg => '$' };

    # This example is identical to having no user override.
    sub Bob::ff ($;$) {
      my Bob $self = shift;
      $self->__ff (@_);
    }

    # This example illustrates a workaround for v5.6.0.
    sub Bob::gg ($;$) {
      # This silliness is due to a bug in 5.6.0: it thinks you can't
      # fiddle with @_ if you've given it a prototype.  XXX
      my @args = @_;
      $args[1] *= 2 if @args == 2 and defined $args[1];
      @_ = @args;
      goto &Bob::__gg;
    }

=head2 Private fields

Fields starting with a leading underscore, C<_>, are private: they are
still valid fields, but C<Class::Struct::FIELDS> does not create
subroutines to access them.  Instead, you should access them the usual
way for hash members:

    $self->{_private_key}; # ok
    $self->_private_key; # Compilation error

See L<fields> for more details.

=head2 Extra magic: auto-stringify

If there exists a subroutine named C<as_string> at the time you invoke
C<struct> (or, equivalently, during the call to C<use>), then
C<Class::Struct::FIELDS> will glue that into auto-stringification with
C<overload> for you.

=head1 EXAMPLES

=over

=item Example 1

Giving a struct element a class type that is also a struct is how
structs are nested.  Here, C<timeval> represents a time (seconds and
microseconds), and C<rusage> has two elements, each of which is of
type C<timeval>.

    use Class::Struct::FIELDS;

    struct (rusage => {
      ru_utime => timeval,  # seconds
      ru_stime => timeval,  # microseconds
    });

    struct (timeval => {
      tv_secs  => '$',
      tv_usecs => '$',
    });

        # create an object:
    my $t = new rusage;

        # $t->ru_utime and $t->ru_stime are objects of type timeval.
        # set $t->ru_utime to 100.0 sec and $t->ru_stime to 5.0 sec.
    $t->ru_utime->tv_secs (100);
    $t->ru_utime->tv_usecs (0);
    $t->ru_stime->tv_secs (5);
    $t->ru_stime->tv_usecs (0);

=item Example 2

An accessor function can be redefined in order to provide additional
checking of values, etc.  Here, we want the C<count> element always to
be nonnegative, so we redefine the C<count> accessor accordingly.

    package MyObj;
    use Class::Struct::FIELDS;

    # declare the struct
    struct (MyObj => {count => '$', stuff => '%'});

    # override the default accessor method for 'count'
    sub count {
      my MyObj $self = shift;

      if (@_) {
        die 'count must be nonnegative' if $_[0] < 0;
        $self->{count} = shift;
        warn "Too many args to count" if @_;
      }

      return $self->{count};
    }

    package main;
    $x = new MyObj;
    print "\$x->count (5) = ", $x->count (5), "\n";
                            # prints '$x->count (5) = 5'

    print "\$x->count = ", $x->count, "\n";
                            # prints '$x->count = 5'

    print "\$x->count (-5) = ", $x->count (-5), "\n";
                            # dies due to negative argument!

=item Example 3

The constructor of a generated class can be passed a list of
I<element>=>I<value> pairs, with which to initialize the struct.  If
no initializer is specified for a particular element, its default
initialization is performed instead. Initializers for non-existent
elements are silently ignored.

Note that the initializer for a nested struct is specified as an
anonymous hash of initializers, which is passed on to the nested
struct's constructor.

    use Class::Struct::FIELDS;

    struct Breed =>
    {
      name  => '$',
      cross => '$',
    };

    struct Cat =>
    {
      name     => '$',
      kittens  => '@',
      markings => '%',
      breed    => 'Breed',
    };

    my $cat = Cat->new
      (name     => 'Socks',
       kittens  => ['Monica', 'Kenneth'],
       markings => { socks => 1, blaze => "white" },
       breed    => { name => 'short-hair', cross => 1 });

    print "Once a cat called ", $cat->name, "\n";
    print "(which was a ", $cat->breed->name, ")\n";
    print "had two kittens: ", join(' and ', @{$cat->kittens}), "\n";

=item Example 4

C<Class::Struct::FIELDS> has a very elegant idiom for creating
inheritance trees:

    use Class::Struct::FIELDS Fred => [];
    use Class::Struct::FIELDS Barney => [qw(Fred)];
    use Class::Struct::FIELDS Wilma => [qw(Barney)],
      { aa => '@',
        bb => 'IO::Scalar' };

That's all the code it takes!

=back

=head1 EXPORTS

C<Class::Struct::FIELDS> export C<struct> for backwards-compatibility
with C<Class::Struct>.

=head1 DIAGNOSTICS

The following are diagnostics generated by B<Class::Struct::Fields>.
Items marked "(W)" are non-fatal (invoke C<Carp::carp>); those marked
"(F)" are fatal (invoke C<Carp::croak>).

=over

=item 'struct' usage error

(F) The caller failed to read the documentation for
C<Class::Struct::FIELDS> and follow the advice therein.

=item Accessor '%s' exists in package '%s' hides method in base class

(W) There is already a subroutine, with the name of one of the
accessors, located in a base class of the given package.  You should
consider renaming the field with the given name.

=item Method '%s' exists in package '%s' overrides accessor

(W) There is already a subroutine, with the name of one of the
accessors, located in the given package.  You may have intended this,
however, if defining your own custom accessors.

=item Method 'new' already exists in package '%s'

(W) There is already a 'new' subroutine located in the given package.
As long as the caveats for defining your own C<new> are followed, this
warning is harmless; otherwise your objects may not be properly
initialized.

=item Initializer for '%s' must be %s reference

(F) At runtime, the caller tried to assign the wrong type of argument
to the element.  An example which triggers this message:

    use Class::Struct::FIELDS Bob => { ary => '@' };
    my $b = Bob::->new;
    $b->ary ({hash => 'reference'}); # croaks

The last statement will croak with the message, "Initializer for 'ary'
must be ARRAY reference".

=item Initializer for '%s' must be %s object

(F) At runtime, the caller tried to assign the wrong class of argument
to the element.  An example which triggers this message:

    use Class::Struct::FIELDS Bob => { mary => 'Mary' };
    use Class::Struct::FIELDS qw(Fred); # NOT inherit from Mary
    my $b = Bob::->new;
    $b->ary (Fred::->new); # croaks

The last statement will croak with the message, "Initializer for 'aa'
must be Mary object".

=back

=head1 BUGS AND CAVEATS

Please see the F<TODO> list.

B<GIANT MAN-EATING HOLE>: due to bugs in lvalue subs in 5.6.0 (try
running some under the debugger), I had to disable the obvious
syntax:

    use Class::Struct::FIELDS Bob => { s => '$' };
    my Bob $b = Bob::->new;
    $b->s = 3;

and provide the clumsier:

    use Class::Struct::FIELDS Bob => { s => '$' };
    my Bob $b = Bob::->new;
    $b->s (3);

Some of these constructs work fine as long as you don't try to debug
the generated code.

=head1 CREDITS

Dean Roehrich, Jim Miner <jfm@winternet.com> and Dr. Damian Conway
E<lt>damian@conway.orgE<gt> wrote the original C<Class::Struct> which
inspired this module and provided much of its documentation.

=head1 AUTHOR

B. K. Oxley (binkley) E<lt>binkley@bigfoot.comE<gt>

Copyright (c) 2000 B. K. Oxley (binkley). All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item L<Class::Contract>

C<Class::Contract> is an extension module by Damian Conway for writing
in a design-by-contract object-oriented style.  It has many of the
features of C<Class::Struct::FIELDS>, and many more besides.

=item L<Class::Struct>

C<Class::Struct> is a standard module for creating simple, uninherited
data structures.

=item L<base>

C<base> is a standard pragma for establishing IS-A relationships with
base classes at compile time.

=item L<fields>

C<fields> is a standard pragma for imbuing your class with efficient
pseudo-hashes for data members.

=item L<overload>

C<overload> is a standard pragma for overloading Perl syntax with your
own subroutines.

=back

=cut
