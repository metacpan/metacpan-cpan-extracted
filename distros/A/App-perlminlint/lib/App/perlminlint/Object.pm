package App::perlminlint::Object; sub MY () {__PACKAGE__}
use strict;
use warnings FATAL => qw/all/;
use Carp;

require fields;
use parent qw/File::Spec/;

our %FIELDS;

sub new {
  my MY $self = fields::new(shift);
  $self->configure(@_);
  $self->after_new;
  $self;
}

sub after_new {}

sub configure {
  (my MY $self) = shift;

  my @args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

  my $fields = _fields_hash($self);

  my @task;
  while (my ($key, $value) = splice @args, 0, 2) {
    unless (defined $key) {
      croak "Undefined option name for class ".ref($self);
    }
    next unless $key =~ m{^[A-Za-z]\w+\z};
    unless (exists $fields->{$key}) {
      croak "Unknown option for class ".ref($self).": ".$key;
    }

    if (my $sub = $self->can("onconfigure_$key")) {
      push @task, [$sub, $value];
    } else {
      $self->{$key} = $value;
    }
  }

  $_->[0]->($self, $_->[-1]) for @task;

  $self;
}

sub import {
  $_[0]->dispatch_import(scalar caller, \@_);
  require Exporter;
  goto &Exporter::import;
}

sub dispatch_import {
  my ($myPack, $callpack, $args) = @_;

  #
  # To allow falling back to Exporter::import,
  # We need to keep original $_[0] in $args.
  # That's why we scan $args->[1]
  #
  while (@$args >= 2
	 and (ref $args->[1] or $args->[1] =~ /^-/)) {
    my $argSpec = splice @$args, 1, 1;
    my ($pragma, @args) = do {
      if (ref $argSpec) {
	@$argSpec
      } else {
	($argSpec =~ s/^-//
	 ? ($argSpec => 1)
	 : $argSpec);
      }
    };

    if (my $sub = $myPack->can("declare_$pragma")) {
      $sub->($myPack, $callpack, @args);
    } else {
      croak "Unknown pragma '$pragma' in $callpack";
    }
  }
}

sub declare_as_base {
  my ($myPack, $callpack, @fields) = @_;

  # Special case. -as_base is treated as [as_base => 1];
  if (@fields == 1 and ($fields[0] // '') eq 1) {
    pop @fields;
  }

  $myPack->declare_fields($callpack, @fields);

  $myPack->_declare_constant_in($callpack, MY => $callpack, 1);
}

sub _declare_constant_in {
  my ($myPack, $callpack, $name, $value, $or_ignore) = @_;

  my $my_sym = _globref($callpack, $name);
  if (*{$my_sym}{CODE}) {
    return if $or_ignore;
    croak "constant ${callpack}::$name is already defined";
  }

  *$my_sym = sub () {$value};
}

sub declare_fields {
  (my MY $self, my ($pack, @fields)) = @_;

  push @{*{_globref($pack, 'ISA')}}, ref($self) || $self;

  my $super = _fields_hash($self);
  my $extended = _fields_hash($pack);

  foreach my $name (keys %$super) {
    $extended->{$name} = $super->{$name}; # XXX: clone?
  }

  foreach my $spec (@fields) {
    my ($name, @rest) = ref $spec ? @$spec : $spec;
    my $has_getter = $name =~ s/^\^//;
    $extended->{$name} = \@rest; # XXX: should have better object.
    if ($has_getter) {
      *{_globref($pack, $name)} = sub { $_[0]->{$name} };
    }
  }

  $pack;
}

sub _fields_hash {
  my $sym = _fields_symbol(@_);
  unless (*{$sym}{HASH}) {
    *$sym = {};
  }
  *{$sym}{HASH};
}

sub _fields_symbol {
  _globref($_[0], 'FIELDS');
}

sub _globref {
  my ($thing, $name) = @_;
  my $class = ref $thing || $thing;
  no strict 'refs';
  \*{join("::", $class, defined $name ? $name : ())};
}

1;

__END__

