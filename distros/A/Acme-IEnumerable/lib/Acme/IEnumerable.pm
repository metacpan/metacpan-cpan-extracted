package Acme::IEnumerable;
use strict;
use warnings;
use Exporter;

use vars qw{ $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS };

BEGIN {
  @ISA = qw(Exporter);
  %EXPORT_TAGS = ( 'all' => [ qw(
  ) ] );

  @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
  @EXPORT = @EXPORT_OK;
  $VERSION = '0.6';
};

#####################################################################
#
#####################################################################
package Acme::IEnumerable::List;
use base qw/Acme::IEnumerable/;
use strict;
use warnings;
use v5.10;
use Carp;

sub _create {
  bless {
    _list => $_[0],
    _zero => 0,
    _last => scalar(@{ $_[0] }) - 1,
    _dir  => 1,
    _new => $_[1],
  }, __PACKAGE__;
}

sub count {
  my ($self) = @_;
  $self->{_dir} * ($self->{_last} - $self->{_zero}) + 1;
}

sub element_at {
  my ($self, $index) = @_;
  Carp::cluck unless defined $index;
  croak unless $self->count > $index;
  my $projected = $self->{_zero} + $index * $self->{_dir};
  $self->{_list}->[$projected];
}

sub last {
  my ($self) = @_;
  croak unless $self->count;
  $self->element_at($self->count - 1);
}

sub last_or_default {
  my ($self, $default) = @_;
  return $default unless $self->count;
  $self->element_at($self->count - 1);
}

sub first {
  my ($self) = @_;
  croak "No elements for 'first'" unless $self->count;
  $self->element_at(0);
}

sub first_or_default {
  my ($self, $default) = @_;
  return $default unless $self->count;
  $self->element_at(0);
}

sub from_list {
  my $class = shift;
  my @list = @_;
  return _create \@list, sub {
    return sub {
      state $index = 0;
      return unless $index <= $#list;
      return \($list[$index++]);
    };
  };
}

sub skip {
  my ($self, $count) = @_;
  return Acme::IEnumerable::_create(sub {
    return sub {
      state $index = $count;
      return unless $index < $self->count;
      return \($self->element_at($index++));
    };
  });
}

sub reverse {
  my ($self) = @_;

  return $self->to_list unless $self->count;

  my $new;
  $new = bless {
    _list => $self->{_list},
    _last => 0,
    _zero => scalar(@{ $self->{_list} }) - 1,
    _dir  => -1,
    _new => sub {
      return sub {
        state $index = 0;
        return unless $index < $new->count;
        return \($new->element_at($index++));
      }
    },
  }, __PACKAGE__;
}

#####################################################################
#
#####################################################################
# sub find { ... }
# sub find_index { ... }
# sub find_last { ... }
# sub find_last_idex { ... }
# sub exists { ... }
# sub find_all { ... }
# sub binary_search { ... }
# sub index_of { ... }
# sub last_index_of { ... }

1;

#####################################################################
#
#####################################################################
package Acme::IEnumerable::Ordered;
use strict;
use warnings;
use v5.10;
use Carp;
use base qw/Acme::IEnumerable/;

sub _create {
  bless {
    _key => $_[0],
    _sgn => $_[1],
    _par => $_[2],
    _new => $_[3],
  }, __PACKAGE__;
}

sub order_by {
  # This assumes to_enumerable will remove the ::Ordered base type
  my ($self) = @_;
  $self->to_enumerable->order_by(@_);
}

sub order_by_descending {
  # This assumes to_enumerable will remove the ::Ordered base type
  my ($self) = @_;
  $self->to_enumerable->order_by_descending(@_);
}

sub then_by_descending {
  _then_by(@_[0..1], -1);
}

sub then_by {
  _then_by(@_[0..1], 1);
}

sub _then_by {
  my ($self, $key_extractor, $sign) = @_;
  return _create $key_extractor, $sign, $self, sub {
    my $top = $self;
    my @ext = $key_extractor;
    my @sgn = $sign;
    for (my $c = $self; $c->isa(__PACKAGE__); $c = $c->{_par}) {
      $top = $c;
      unshift @ext, $c->{_key};
      unshift @sgn, $c->{_sgn};
    }
    my @list = $top->to_perl;

    # This is not written with efficiency in mind.
    my @ordered = sort {
      my $cmp = 0;
      for (my $ix = 0; $ix < @ext; ++$ix) {
        my $ext = $ext[$ix];
        my $k1 = do { local $_ = $a; $ext->($_) };
        my $k2 = do { local $_ = $b; $ext->($_) };
        $cmp = $sgn[$ix] * ($k1 <=> $k2);
        last if $cmp;
      };
      return $cmp;
    } @list;

    return Acme::IEnumerable->from_list(@ordered)->new;
  };
}

1;

#####################################################################
#
#####################################################################
package Acme::IEnumerable::Grouping;
use strict;
use warnings;
use v5.10;
use Carp;
use base qw/Acme::IEnumerable::List/;

sub from_list {
  my $class = shift;
  my $key = shift;
  my $self = Acme::IEnumerable->from_list(@_);
  $self->{key} = $key;
  bless $self, __PACKAGE__;
}

sub key { $_[0]->{key} }

1;

#####################################################################
#
#####################################################################
package Acme::IEnumerable;
use strict;
use warnings;
use v5.10;
use Carp;

do {
  no warnings 'once';
  *from_list = \&Acme::IEnumerable::List::from_list;
  *to_array  = \&Acme::IEnumerable::to_perl;
  *order_by  = \&Acme::IEnumerable::Ordered::then_by;
  *order_by_descending =
    \&Acme::IEnumerable::Ordered::then_by_descending;
};

sub _create {
  bless {
    _new => $_[0],
  }, __PACKAGE__;
}

sub new { $_[0]->{_new}->() }

sub range {
  my ($class, $from, $count) = @_;

  if (defined $count) {
    # ...
  }

  return _create sub {
    return sub {
      state $counter = $from // 0;
      return \($counter++);
    };
  };
}

sub take {
  my ($self, $count) = @_;
  return _create sub {
    return sub {
      state $left = $count;
      return unless $left;
      $left--;
      state $base = $self->new();
      my $item = $base->();
      return unless ref $item;
      return $item;
    };
  };
}

sub take_until {
  my ($self, $predicate) = @_;
  return $self->take_while(sub {
    !$predicate->($_);
  });
}

sub take_while {
  my ($self, $predicate) = @_;
  return _create sub {
    return sub {
      state $base = $self->new();
      my $item = $base->();
      return unless ref $item;
      local $_ = $$item;
      return unless $predicate->($_);
      return $item;
    };
  };
}

sub group_by {
  my ($self, $key_extractor) = @_;
  return _create sub {
    my $base = $self->new;
    my %temp;
    while (1) {
      my $item = $base->();
      last unless ref $item;
      local $_ = $$item;
      my $key = $key_extractor->($_);
      push @{ $temp{$key} }, $_;
    }

    my @temp = map {
      Acme::IEnumerable::Grouping->from_list($_, @{$temp{$_}})
    } keys %temp;

    return Acme::IEnumerable->from_list(@temp)->new;
  };
}

sub stack_by {
  my ($self, $key_extractor) = @_;
  return _create sub {
    # TODO: make this more lazy?
    my $base = $self->new;
    my @list;
    while (1) {
      my $item = $base->();
      last unless ref $item;
      local $_ = $$item;
      my $key = $key_extractor->($_);
      if (not @list or $key ne $list[-1]->{key}) {
        push @list, {
          key => $key,
        };
      }
      push @{ $list[-1]->{value} }, $_;
    }

    my @temp = map {
      Acme::IEnumerable::Grouping->from_list($_->{key}, @{ $_->{value} })
    } @list;

    return Acme::IEnumerable->from_list(@temp)->new;
  };
}

sub skip {
  my ($self, $count) = @_;
  return _create sub {
    return sub {
      state $base = $self->new();
      state $left = $count;
      while ($left) {
        my $item = $base->();
        return unless ref $item;
        $left--;
      }
      return $base->();
    };
  };
}

sub skip_while {
  my ($self, $predicate) = @_;
  return _create sub {
    return sub {
      state $base = $self->new();
      state $skip = 1;
      while ($skip) {
        my $item = $base->();
        return unless ref $item;
        local $_ = $$item;
        $skip &= !! $predicate->($_);
        return $item unless $skip;
      }
      return $base->();
    };
  }
}

sub element_at {
  my ($self, $index) = @_;

  Carp::cluck "Index out of range for element_at" if $index < 0;

  my $base = $self->new();
  while (1) {
    my $item = $base->();
    do {
      use Data::Dumper;
      warn Dumper[$self->count(sub { warn Data::Dumper::Dumper($_); 1; })];
      Carp::cluck "Index out of range for element_at";
    } unless ref $item;
    return $$item unless $index--;
  }
  Carp::confess("Impossible");
}

sub last {
  my ($self) = @_;
  my $base = $self->new();
  my $last;
  while (1) {
    my $item = $base->();
    croak unless ref $item or ref $last;
    return $$last unless ref $item;
    $last = $item;
  }
  Carp::confess("Impossible");
}

sub first {
  $_[0]->element_at(0);
}

sub first_or_default {
  my ($self, $default) = @_;
  my $base = $self->new();
  my $item = $base->();
  return $default unless ref $item;
  return $$item;
}

sub last_or_default {
  my ($self, $default) = @_;
  my $base = $self->new();
  my $item = $base->();
  return $default unless ref $item;
  while (1) {
    my $next = $base->();
    return $$item unless ref $next;
    $item = $next;
  }
}

sub count {
  my ($self, $predicate) = @_;
  $predicate //= sub { 1 };
  my $base = $self->new();
  while (1) {
    my $counter = 0;
    my $item = $base->();
    return $counter unless ref $item;
    local $_ = $$item;
    $counter += 0 + !! $predicate->($_);
  }
  Carp::confess("Impossible");
}

sub select {
  my ($self, $projection) = @_;
  return _create sub {
    return sub {
      state $base = $self->new();
      my $item = $base->();
      return unless ref $item;
      local $_ = $$item;
      return \($projection->($_));
    };
  };
}

sub where {
  my ($self, $predicate) = @_;
  return _create sub {
    return sub {
      state $base = $self->new();
      while (1) {
        my $item = $base->();
        return unless ref $item;
        local $_ = $$item;
        next unless $predicate->($_);
        return $item;
      }
    };
  };
}

sub zip {
  my ($self, $other) = @_;
  return _create sub {
    return sub {
      state $base1 = $self->new();
      state $base2 = $other->new();
      while (1) {
        my $item1 = $base1->();
        return unless ref $item1;
        my $item2 = $base2->();
        return unless ref $item2;
        return \[$$item1, $$item2]
      }
    };
  };
}

sub pairwise {
  # TODO: make variant with a seed?
  my ($self, $func) = @_;
  return $self->each_cons(2, $func);

  # ...
  my $base = $self->new();
  my $prev = $base->();
  return unless ref $prev;
  while (1) {
    my $curr = $base->();
    return unless ref $curr;
    $func->($$prev, $$curr);
    $prev = $curr;
  }
  Carp::confess("Impossible");
}

sub each_cons {
  my ($self, $count, $func) = @_;
  my $base = $self->new();
  my @prev;
  while ($count-- > 1) {
    my $prev = $base->();
    return unless ref $prev;
    push @prev, $$prev;
  }
  while (1) {
    my $curr = $base->();
    return unless ref $curr;
    $func->(@prev, $$curr);
    push @prev, $$curr;
    shift @prev;
  }
  Carp::confess("Impossible");
}


sub aggregate {
  my $self = shift;
  my $base = $self->new();
  my ($func, $seed);

  if (@_ == 1) {
    $func = shift;
    my $item = $base->();
    croak unless ref $item;
    $seed = $$item;
  } elsif (@_ == 2) {
    $seed = shift;
    $func = shift;
  } else {
    # ...
  }

  while (1) {
    my $item = $base->();
    return $seed unless ref $item;
    $seed = $func->($seed, $$item);
  }
  Carp::confess("Impossible");
}

sub average {
  my ($self) = @_;
  my $base = $self->new();

  my $item = $base->();
  return unless ref $item;

  my $count = 0;
  my $total = 0;

  while (1) {
    $total += $$item;
    $count += 1;
    $item = $base->();
    return $total/$count unless ref $item;
  }
}

sub min {
  my ($self) = @_;
  return $self->aggregate(sub {
    $_[0] < $_[1] ? $_[0] : $_[1]
  });
}

sub max {
  my ($self) = @_;
  return $self->aggregate(sub {
    $_[0] > $_[1] ? $_[0] : $_[1]
  });
}

sub all {
  my ($self, $predicate) = @_;
  my $base = $self->new();
  while (1) {
    my $item = $base->();
    return 1 unless ref $item;
    local $_ = $$item;
    return 0 unless $predicate->($_);
  }
  Carp::confess("Impossible");
}

sub allplus {
  my ($self, $predicate) = @_;
  my $base = $self->new();
  my $okay = 0;
  while (1) {
    my $item = $base->();
    return $okay unless ref $item;
    local $_ = $$item;
    $okay = $predicate->($_);
    return 0 unless $okay;
  }
  Carp::confess("Impossible");
}

sub any {
  my ($self, $predicate) = @_;
  $predicate //= sub { 1 };
  my $base = $self->new();
  while (1) {
    my $item = $base->();
    return 0 unless ref $item;
    local $_ = $$item;
    return 1 if $predicate->($_);
  }
  Carp::confess("Impossible");
}

sub reverse {
  my $self = shift;
  Acme::IEnumerable->from_list(reverse $self->to_perl);
}

sub sum {
  my $self = shift;
  return $self->aggregate(0, sub { $_[0] + $_[1] });
}

sub to_perl {
  my $self = shift;
  my @result;
  my $enum = $self->new();
  for (my $item = $enum->(); ref $item; $item = $enum->()) {
    push @result, $$item;
  }
  @result;
}

sub to_list {
  my ($self) = @_;
  Acme::IEnumerable->from_list($self->to_perl);
}

sub for_each {
  my ($self, $action) = @_;
  my $enum = $self->new();
  for (my $item = $enum->(); ref $item; $item = $enum->()) {
    local $_ = $$item;
    $action->($_);
  }
}

#####################################################################
#
#####################################################################
# sub select_many { ... }
# sub contains { ... }
# sub sequence_equal { ... }
# sub distinct { ... }
# sub union { ... }
# sub except { ... }
# sub intersect { ... }
# sub default_if_empty { ... }
# sub single_or_default { ... }
# sub concat { ... }
# sub group_join { ... }
# sub join { ... }
# sub empty { ... }
# sub cast { ... }
# sub to_lookup { ...}
# sub to_dictionary { ... }

#####################################################################
#
#####################################################################
# sub distinct_by { ... }
# sub min_by { ... }
# sub max_by { ... }

# sub to_enumerable { ... }


1;

__END__

=head1 NAME

Acme::IEnumerable - Proof-of-concept lazy lists, iterators, generators

=head1 SYNOPSIS

  use v5.16;
  use Acme::IEnumerable;

  my @sorted = Acme::IEnumerable
    ->from_list(qw/3 2 1/)
    ->where(sub { $_ < 3 })
    ->order_by(sub { $_ })
    ->to_perl;

  say join ' ', @sorted;

=head1 DESCRIPTION

Experimental implementation of a iterator/generator protocol and lazy
lists on top of it, with plenty of generic methods inspired by .NET's
IEnumerable interface and corresponding facilities in Ruby, Python,
and Haskell. Mainly for discussion purposes.

=head2 STATIC METHODS

=over 2

=item from_list

Creates new C<Acme::IEnumerable::List> from the supplied list.

=item range($from [, $count])

Creates a new C<Acme::IEnumerable> with $count integers from $from.

=back

=head2 INSTANCE METHODS

=over 2

=item take($count)

Creates new C<Acme::IEnumerable> containing the first $count elements
of the base enumerable.

=item ...

...

=back


=head2 EXPORTS

Nothing.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2013 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
