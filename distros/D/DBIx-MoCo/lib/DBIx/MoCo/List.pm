package DBIx::MoCo::List;
use strict;
use warnings;
use Carp qw/croak/;
use List::Util ();
use List::MoreUtils ();

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = $_[0];
    my $class = ref($self) || $self;
    $self = undef unless ref($self);
    (my $method = $AUTOLOAD) =~ s!.+::!!;
    return if $method eq 'DESTROY';
    no strict 'refs';
    if ($method =~ /^map_(.+)$/o) {
        *$AUTOLOAD = $class->_map_handler($1);
        goto &$AUTOLOAD;
    }
}

sub _map_handler {
    my $class = shift;
    my $method = shift;
    return sub {
        shift->map(sub { $_->$method() });
    };
}

sub new {
    my ($class, $array) = @_;
    $class = ref $class || $class;
    $array ||= [];
    croak sprintf("Argument must be an array reference (%s)", ref $array)
        unless ref $array eq 'ARRAY';
    bless $array, $class;
}

sub push {
    my $self = shift;
    push @$self, @_;
    $self;
}

sub unshift {
    my $self = shift;
    unshift @$self, @_;
    $self;
}

sub shift {
    shift @{$_[0]};
}

sub pop {
    pop @{$_[0]};
}

sub first {
    $_[0]->[0];
}

sub last {
    $_[0]->[-1];
}

sub slice {
    my $self = CORE::shift;
    my ($s, $e) = @_;
    my $last = $#{$self};
    # warn "s: $s, e: $e, last: $last";
    if (defined $e) {
        if ($s == 0 && $last <= $e) {
            return $self;
        } else {
            $e = $last if ($last < $e);
            return $self->new([ @$self[ $s .. $e ] ]);
        }
    } elsif (defined $s && 0 < $s && $last <= $s) {
        # warn $self->first . "s: $s, e: $e, self:" . $#{$self};
        return $self->new([]);
    } else {
        return $self;
    }
}

sub dump {
    my $self = CORE::shift;
    require Data::Dumper;
    Data::Dumper->new([ $self->to_a ])->Purity(1)->Terse(1)->Dump;
}

sub zip {
    my $self = CORE::shift;
    my $array = \@_;
    my $index = 0;
    $self->collect(sub { 
         my $ary = $self->new([$_]);
         $ary->push($_->[$index]) for @$array;
         $index++;
         $ary;
    });
}

sub delete {
    my ($self, $value, $code) = @_;
    my $found = 0;
    do { my $item = $self->shift; $item == $value ? $found = 1 : $self->push($item) } for (0..$self->_last_index);
    $found ? $value 
           : ref $code eq 'CODE' ? do { local $_ = $value; return $code->($_) }
                                 : return ;
}

sub delete_at {
    my ($self, $pos) = @_;
    my $last_index = $self->_last_index;
    return if $pos > $last_index ;
    my $result;
    $_ == $pos ? $result = $self->shift 
               : $self->push($self->shift) for 0..$last_index;
    return $result;
}

sub delete_if {
    my ($self, $code) = @_;
    croak "Argument must be a code" unless ref $code eq 'CODE';
    my $last_index = $self->_last_index;
    for (0..$last_index) {
        my $item = $self->shift;
        local $_ = $item;
        $self->push($item) if $code->($_);
    }
    return $self;
}

sub inject {
    my ($self, $result, $code) = @_;
    croak "Argument must be a code" unless ref $code eq 'CODE';
    $result = $code->($result, $_) for @{$self->dup};
    return $result;
}

sub join {
    my ($self, $delimiter) = @_;
    join $delimiter, @$self;
}

sub each_index {
    my ($self, $code) = @_;
    $self->new([ 0..$self->_last_index ])->each($code);
}

sub _last_index {
    my $self = CORE::shift;
    $self->length ? $self->length - 1 : 0;
};

sub concat {
    my ($self, $array) = @_;
    $self->push(@$array);
    $self;
}

*append = \&concat;

sub prepend {
    my ($self, $array) = @_;
    $self->unshift(@$array);
    $self;
}

sub _append_undestructive {
    my ($self, $array) = @_;
    $self->dup->push(@$array);
}

sub _prepend_undestructive {
    my ($self, $array) = @_;
    $self->dup->unshift(@$array);
}

sub add {
    my ($self, $array, $bool) = @_;
    $bool ? $self->_prepend_undestructive($array)
          : $self->_append_undestructive($array);
}

sub each {
    my ($self, $code) = @_;
    croak "Argument must be a code" unless ref $code eq 'CODE';
    $code->($_) for @{$self->dup};
    $self;
}

sub collect {
    my ($self, $code) = @_;
    croak "Argument must be a code" unless ref $code eq 'CODE';
    my @collected = CORE::map &$code, @{$self->dup};
    wantarray ? @collected : $self->new(\@collected);
}

*map = \&collect;

sub grep {
    my ($self, $code) = @_;
    $code or return;
    my @grepped;
    if (!ref($code)) {
        for (@$self) {
            CORE::push @grepped, $_ if $_->$code;
        }
    } elsif (ref $code eq 'CODE') {
        @grepped = CORE::grep &$code, @$self;
    } else {
        croak "Invalid code";
    }
    wantarray ? @grepped : $self->new(\@grepped);
}

sub find {
    my ($self, $code) = @_;
    croak "Argument must be a code" unless ref $code eq 'CODE';
    for (@$self) { &$code and return $_ }
}

sub index_of {
    my ($self, $target) = @_;
    my $code = (ref $target eq 'CODE') ? $target : sub { CORE::shift eq $target };
    for (my $i = 0; $i < $self->length; $i++) {
        &$code($self->[$i]) and return $i;
    }
}

sub sort {
    my ($self, $code) = @_;
    my @sorted = $code ? CORE::sort { $code->($a, $b) } @$self : CORE::sort @$self;
    wantarray ? @sorted : $self->new(\@sorted);
}

sub compact {
    CORE::shift->grep(sub { defined  });
}

sub length {
    scalar @{$_[0]};
}

*size = \&length;

sub flatten {
    my $self = CORE::shift;
    $self->collect(sub { _flatten($_)  });
}

sub _flatten {
    my $element = CORE::shift;
    (ref $element and ref $element eq 'ARRAY')
        ? CORE::map { _flatten($_) } @$element
        : $element;
}

sub is_empty {
    !$_[0]->length;
}

sub uniq {
    my $self = CORE::shift;
    $self->new([ List::MoreUtils::uniq(@$self) ]);
}

sub reduce {
    my ($self, $code) = @_;
    croak "Argument must be a code" unless ref $code eq 'CODE';
    List::Util::reduce { $code->($a, $b) } @$self;
}

sub to_a {
    my @unblessed = @{$_[0]};
    \@unblessed;
}

sub as_list { # for Template::Iterator
    CORE::shift;
}

sub dup {
    __PACKAGE__->new($_[0]->to_a);
}

sub reverse {
    my $self = CORE::shift;
    $self->new([ reverse @$self ]);
}

sub sum {
    List::Util::sum @{$_[0]};
}

1;

=head1 NAME

DBIx::MoCo::List - Array iterator for DBIx::MoCo.

=head1 SYNOPSIS

  my $array_ref = [
    {name => 'jkondo'},
    {name => 'cinnamon'}
  ];
  my $list = DBIx::MoCo::List->new($array_ref);

  $list->size;              #=> 2
  my $first = $list->shift; #=> {name => 'jkondo'}
  $list->push($first);      #=> [{name => 'cinnamon'}, {name => 'jkondo'}];

  # DBIx::MoCo::List provides much more useful methods. For more
  # details, see the sections below.

=head1 METHODS

=over 4

=item dump ()

Dump the content of C<$self> using L<Data::Dumper>.

=item push ( I<@array> )

=item unshift ( I<@array> )

Sets the argument into C<$self>, a refernce to an array blessed by
DBIx::MoCo::List, like the same name functions provided by Perl core,
then returns a DBIx::MoCo::List object.

  my $list = DBIx::MoCo::List->new([qw(1 2 3)]);
  $list->push(4, 5); #=> [1, 2, 3, 4, 5]
  $list->unshift(0); #=> [0, 1, 2, 3, 4, 5]

=item concat ( I<\@array> )

=item prepend ( I<\@array> )

They're almost the same as C<push()>/C<unshift()> described above
except that the argument shoud be a reference to an array.

  my $list = DBIx::MoCo::List->new([1, 2, 3]);
  $list->concat([4, 5]); #=> [1, 2, 3, 4, 5]
  $list->prepend([0]);   #=> [0, 1, 2, 3, 4, 5]

=item shift ()

=item pop ()

Pulls out the first/last element from C<$self>, a refernce to an array
blessed by DBIx::MoCo::List, then returns it like the same name
functions in Perl core.

  $list = DBIx::MoCo::List->new([1, 2, 3]);
  $list->shift; #=> 1
  $list->pop;   #=> 3
  $list->dump   #=> [2]

=item first ()

=item last ()

Returns the first/last element of C<$self>, a refernce to an array
blessed by DBIx::MoCo::List. These methods aren't destructive contrary
to C<shift()>/C<pop()> method.

  $list = DBIx::MoCo::List->new([1, 2, 3]);
  $list->first; #=> 1
  $list->last;  #=> 3
  $list->dump   #=> [1, 2, 3]

=item slice ( I<$start>, I<$end> )

Returns the elements whose indexes are between C<$start> and C<$end>
as a DBIx::MoCo::List object.

  $list = DBIx::MoCo::List->new([qw(1 2 3 4)]);
  $list->slice(1, 2) #=> [2, 3]

=item zip ( I<\@array1>, I<\@array2>, ... )

Bundles up the elements in each arguments into an array or a
DBIx::MoCo::List object along with the context.

  my $list = DBIx::MoCo::List->new([1, 2, 3]);
  $list->zip([4, 5, 6], [7, 8, 9]);
      #=> [[1, 4, 7], [2, 5, 8], [3, 6, 9]]

  # When the numbers of each list are different...
  $list = DBIx::MoCo::List->new([1, 2, 3]);
  $list->zip([4, 5], [7, 8, 9]);
      #=> [[1, 4, 7], [2, 5, 8], [3, undef, 9]]

  my $list   = DBIx::MoCo::List->new([1, 2]);
  $list->zip([4, 5], [7, 8, 9]);
      #=> [[1, 4, 7], [2, 5, 8]]

=item delete ( I<$value>, I<$code> )

Deletes the same values as C<$value> in C<$self>, a refernce to an
array blessed by DBIx::MoCo::List, and returns the value if found. If
the value is not found in C<$self> and C<$code> is passed in, the code
is executed using the value as an argument to find the value to be
deleted.

  $list = DBIx::MoCo::List->new([1, 2, 3, 2, 1]);
  $list->delete(2); #=> 2
  $list->dump       #=> [1, 3, 1]

=item delete_at ( I<$pos> )

Deletes the element at C<$pos> and returns it.

  $list = DBIx::MoCo::List->new([1, 2, 3, 2, 1]);
  $list->delete_at(3); #=> 2
  $list->dump          #=> [1, 2, 3, 1]

=item delete_if ( I<$code> )

Deletes the elements if C<$code> returns false value with each element
as an argument.

  $list = DBIx::MoCo::List->new([1, 2, 3, 4]);
  $list->delete_if(sub { ($_ % 2) == 0) });
  $list->dump #=> [2, 4]

=item inject ( I<$result>, I<$code> )

Executes folding calculation using C<$code> through each element and
returns the result.

  $list = DBIx::MoCo::List->new([1, 2, 3, 4]);
  $list->inject(0, sub { $_[0] + $_[1] }); #=> 10

=item join ( I<$delimiter> )

Joins all the elements by C<$delimiter>.

  $list = DBIx::MoCo::List->new([0 1 2 3]);
  $list->join(', ') #=> '0, 1, 2, 3'

=item each_index ( I<$code> )

Executes C<$code> with each index of C<$self>, a refernce to an array
blessed by DBIx::MoCo::List.

  $list = DBIx::MoCo::List->new([1, 2, 3]);
  $list->each_index(sub { do_something($_) });

=item each ( I<$code> )

Executes C<$code> with each value of C<$self>, a refernce to an array
blessed by DBIx::MoCo::List.

  $list = DBIx::MoCo::List->new([1, 2, 3]);
  $list->each(sub { do_something($_) });

=item collect ( I<$code> )

Executes C<$code> with each element of C<$self>, a refernce to an
array blessed by DBIx::MoCo::List using CORE::map() and returns the
results as a list or DBIx::MoCo:List object along with the context.

  $list = DBIx::MoCo::List->new([1, 2, 3]);
  $list->map(sub { $_ * 2 }); #=> [2, 4, 6]

=item map ( I<$code> )

An alias of C<collect()> method described above.

=item grep ( I<$code> )

Executes C<$code> with each element of C<$self>, a refernce to an
array blessed by DBIx::MoCo::List using CORE::grep() and returns the
results as a list or DBIx::MoCo:List object along with the context.

  $list = DBIx::MoCo::List->new([qw(1 2 3 4)]);
  $list->grep(sub { ($_ % 2) == 0 }); #=> [2, 4]

=item find ( I<$code> )

Returns the first value found in C<$self>, a refernce to an array
blessed by DBIx::MoCo::List, as a result of C<$code>..

  $list = DBIx::MoCo::List->new([1, 2, 3, 4]);
  $list->find(sub { ($_ % 2) == 0 }); #=> 2

=item index_of ( I<$arg> )

Returns index of given target or given code returns true.

  $list = DBIx::MoCo::List->new([qw(foo bar baz)]);
  $list->index_of('bar');                  #=> 1
  $list->index_of(sub { shift eq 'bar' }); #=> 1

=item sort ( I<$code> )

Sorts out each element and returns the result as a list or
DBIx::MoCo:List object along with the context.

  $list = DBIx::MoCo::List->new([qw(3 2 4 1]);
  $list->sort;                          #=> [1, 2, 3, 4]
  $list->sort(sub { $_[1] <=> $_[0] }); #=> [4, 3, 2, 1]

=item compact ()

Eliminates undefined values in C<$self>, a refernce to an array
blessed by DBIx::MoCo::List.

  $list = DBIx::MoCo::List->new([1, 2, undef, 3, undef, 4]);
  $list->compact; #=> [1, 2, 3, 4]

=item length ()

Returns the length of C<$self>, a refernce to an array blessed by
DBIx::MoCo::List.

  $list = DBIx::MoCo::List->new([qw(1 2 3 4)]);
  $list->length; #=> 4

=item size ()

An alias of C<length()> method described above.

=item flatten ()

Returns a list or DBIx::MoCo::List object which is recursively
flattened out.

  $list = DBIx::MoCo::List->new([1, [2, 3, [4], 5]]);
  $list->flattern; #=> [1, 2, 3, 4, 5]

=item is_empty ()

Returns true if C<$self>, a refernce to an array blessed by
DBIx::MoCo::List, is empty.

=item uniq ()

Uniquifies the elements in C<$self>, a refernce to an array blessed by
DBIx::MoCo::List, and returns the result.

  $list = DBIx::MoCo::List->new([1, 2, 2, 3, 3, 4])
  $list->uniq; #=> [1, 2, 3, 4]

=item reduce ( I<$code> )

Reduces the list by C<$code>.

  # finds the maximum value
  $list = DBIx::MoCo::List->new([4, 1, 3, 2])
  $list->reduce(sub { $_[0] > $_[1] ? $_[0] : $_[1] }); #=> 4

See L<List::Util> to get to know about details of C<reduce()>.

=item reverse ()

Returns an reversely ordered C<$self>, a refernce to an array blessed
by DBIx::MoCo::List.

  $list = DBIx::MoCo::List->new([4, 1, 3, 2])
  $list->reverse; #=> [2, 3, 1, 4]

=item dup ()

Returns a duplicated C<$self>, a refernce to an array blessed by
DBIx::MoCo::List.

=item sum ()

Returns the sum of each element in C<$self>, a refernce to an array
blessed by DBIx::MoCo::List.

  $list = DBIx::MoCo::List->new([1, 2, 3, 4]);
  $list->sum; #=> 10

=back

=head1 AUTO-GENERATED METHODS

=over 4

=item map_XXX ()

Returns the results of C<XXX()> method of each elements as a list or a
DBIx::MoCo::List object along with the context.

  my $list  = Your::MoCo::Class->retrieve_all;
  my $names = $list->map_name;

In this case, C<$names> is a list of the return values of C<name()>
method of each element in C<$list>.

=back

=head1 SEE ALSO

L<DBIx::MoCo>, L<List::Util>, L<List::MoreUtils>

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.comE<gt>,
Naoya Ito, E<lt>naoya@hatena.ne.jpE<gt>,
Kentaro Kuribayashi, E<lt>kentarok@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
