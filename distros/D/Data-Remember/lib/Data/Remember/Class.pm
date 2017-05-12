package Data::Remember::Class;
{
  $Data::Remember::Class::VERSION = '0.140490';
}
use strict;
use warnings;

# ABSTRACT: remember complex information without giving yourself a headache, now with POOP!

use Carp;
use Scalar::Util qw( reftype );
use Class::Load ();
use Data::Remember::Util 
    process_que => { -as => '_process_que' },
    init_brain  => { -as => '_init_brain' };


sub new {
    my $class   = shift;
    my $brain   = shift || 'Memory';

    my $caller = caller;

    my $gray_matter = _init_brain($brain, @_);

    return bless { brain => $gray_matter }, $class;
}


sub remember {
    my ($self, $que, $fact) = @_;

    my $clean_que = _process_que($que);;

    unless (defined $clean_que) {
        carp "Undefined que element found in call to remember().";
        return;
    }

    $self->{brain}->remember($clean_que, $fact);

    return;
}


sub remember_these {
    my ($self, $que, $fact) = @_;

    my $clean_que = _process_que($que);;

    unless (defined $clean_que) {
        carp "Undefined que element found in call to remember_these().";
        return;
    }

    my $brain = $self->{brain};

    my $fact_list = $brain->recall($clean_que);

    if (defined reftype $fact_list and reftype $fact_list eq 'ARRAY') {
        push @$fact_list, $fact;
    }

    else {
        $brain->remember($clean_que, [ $fact ]);
    }

    return;
}


sub recall {
    my ($self, $que) = @_;

    my $clean_que = _process_que($que);

    unless (defined $clean_que) {
        carp "Undefined que element used in call to recall().";
        return;
    }

    return scalar $self->{brain}->recall($clean_que);
}


sub recall_each {
    my ($self, $que) = @_;
    my $brain = $self->{brain};

    my $clean_que = _process_que($que);

    unless (defined $clean_que) {
        carp "Undefined que element used in call to recall_each().";
        return;
    }

    my $value = $brain->recall($clean_que);

    my $value_ref_type = reftype($value);
    $value_ref_type = '' unless defined $value_ref_type;

    if ($value_ref_type eq 'HASH') {
        my @keys = keys %$value;
        return sub {
            return unless @keys;
            my $k = shift @keys;
            return ($k, $value->{$k});
        };
    }

    elsif ($value_ref_type eq 'ARRAY') {
        my @indexes = 0 .. $#$value;
        return sub {
            return unless @indexes;
            my $i = shift @indexes;
            return ($i, $value->[$i]);
        };
    }

    else {
        my @values = ($value);
        return sub {
            return unless @values;
            my $v = shift @values;
            return (undef, $v);
        };
    }
}


sub recall_and_update {
    my ($self, $code, $que) = @_;

    my $clean_que = _process_que($que);

    unless (defined $clean_que) {
        carp "Undefined que element used in call to recall_and_update().";
        return;
    }

    my $brain = $self->{brain};

    # Recall and modify $_
    local $_ = $brain->recall($clean_que);
    my $result = $code->();

    # Store that value back
    $brain->remember($clean_que, $_);

    # Return the result
    return $result;
}


sub forget {
    my ($self, $que) = @_;

    my $clean_que = _process_que($que);

    unless (defined $clean_que) {
        carp "Undefined que element used in call to forget().";
        return;
    }

    $self->{brain}->forget($clean_que);

    return;
}


sub forget_when {
    my ($self, $code, $que) = @_;

    my $clean_que = _process_que($que);

    unless (defined $clean_que) {
        carp "Undefined que element used in call to forget_when().";
        return;
    }

    my $brain = $self->{brain};
    my $fact = $brain->recall($clean_que);

    if (ref $fact and reftype $fact eq 'HASH') {
        for my $key (keys %$fact) {
            my $value = $fact->{ $key };
            local $_ = $value;
            delete $fact->{ $key } if $code->($key, $value);
        }
    }

    elsif (ref $fact and reftype $fact eq 'ARRAY') {
        my $index = 0;
        my @new_fact
            = grep { my $value = $_; not $code->($index++, $value) } @$fact;
        $brain->remember($clean_que, \@new_fact);
    }

    else {
        local $_ = $fact;
        $brain->forget($clean_que) if $code->(undef, $fact);
    }

    return;
}


sub brain {
    my $self = shift;
    return $self->{brain};
}


1;

__END__

=pod

=head1 NAME

Data::Remember::Class - remember complex information without giving yourself a headache, now with POOP!

=head1 VERSION

version 0.140490

=head1 SYNOPSIS

  use Data::Remember::Class;

  my $store = Data::Remember::Class->new('Memory');

  $store->remember(foo => 1);
  $store->remember([ bar => 7 ], [ 'spaz', 'w00t', 'doof', 'flibble' ]);
  $store->remember([ 'xyz', 'abc', 'mno' ] => { some => 'thing' });

  $store->remember_these(cook => 'goose');
  $store->remember_these(cook => 'duck');
  $store->remember_these(cook => 'turkey');

  my $foo     = $store->recall('foo');        # retrieve a simple key
  my $wibbler = $store->recall([ bar => 7 ]); # retrieve a complex key
  my $alpha   = $store->recall('xyz');        # retrieve a subkey

  my $cook    = $store->recall([ 'cook' ]);   # retrieves [ qw/ goose duck turkey / ]

  $store->forget('foo');

  my $foo_again = $store->recall('foo'); # $foo_again is undef

  $store->forget_when(sub { /^duck$/ }, [ 'cook' ]); 

  my $cook_again = $store->recall('cook'); # $cook_again is [ qw/ goose turkey / ]

=head1 DESCRIPTION

While designing some IRC bots and such I got really tired of statements that looked like:

  $heap->{job}{$job} = {
      source  => $source,
      dest    => $destination,
      options => $options,
  };

and later:

  if ($heap->{job}{$job}{options}{wibble} eq $something_else) {
      # do something...
  }

I could simplify things with intermediate variables, but then I inevitably end up with 4 or 5 lines of init at the start or middle of each subroutine. Yech.

So, I decided that it would be nice to simplify the above to:

  remember [ job => $job ], {
      source  => $source,
      dest    => $destination,
      options => $options,
  };

and later:

  if (recall [ job => $job, options => 'wibble' ] eq $something_else) {
      # do something...
  }

Which I consider to far more readable.

At my next job, I decided to use L<Bread::Board> and L<Moose> and all that jazz into the internals of the new bot I wrote. As such, I couldn't really make much use of this module, but I wanted to. So, now I've added this Perl object-oriented programming interface, which does this:

  $store->remember([ job => $job ], {
      source  => $source,
      dest    => $destination,
      options => $options,
  });

and this:

  if ($store->recall([ job => $job, options => 'wibble' ]) eq $something_else) {
      # do something...
  }

Which I consider both readable and flexible.

The second aspect that this deals with is long-term storage. I started using L<DBM::Deep> to remember the important bits of state across bot restarts. This package will store your information persistently for you too if you want:

  use Data::Remember::Class;
  my $store = Data::Remember::Class->new( DBM => 'state.db' );

By using that command, the L<Data::Remember::DBM> "brain" is used instead of the usual L<Data::Remember::Memory> brain, which just stores things in a Perl data structure.

=head1 QUE

Each method takes a C<$que> argument. The que is a memory que to store the information with. This que may be a scalar, an array, or a hash, depending on what suits your needs. However, you will want to be aware of how these are translated into memory locations in the brain plugin.

Any que argument is passed to the brain as an array. A scalar que is just wrapped in an array reference:

  $store->remember(foo => 1);

is the same as:

  $store->remember([ 'foo' ] => 1);

An array que is passed exactly as it is to the brain plugin.

A hash que is converted to an array by sorting the keys in string order and keeping the pairs together. For example:

  $store->remember({ foo => 3, bar => 2, baz => 1 } => 'xyz');

is the same as:

  $store->remember([ 'bar', 2, 'baz', 1, 'foo', 3 ] => 'xyz');

This is different from storing:

  $store->remember([ foo => 3, bar => 2, baz => 1 ] => 'xyz');

The use of an anonymous array instead of an anonymous hash preserves the order of your choice.

Finally, you can get access to the root of your brain's memory by using the empty que:

  $store->remember([], { store => 1, all => 2, the => 3, things => 4 });

Once the array is built the brains are required to treat these in the same way as hash keys for a hash of hashes. For example, you can think of:

  $store->remember([ foo => 3, bar => 2, baz => 1 ] => 'xyz');

as being similar to storing:

  $memory->{foo}{3}{bar}{2}{baz}{1} = 'xyz';

This means that you could later recall a subset of the previous key:

  my $bar = $store->recall([ foo => 3, 'bar' ]);

which would return a hash reference similar to:

  my $bar = { 2 => { baz => { 1 => 'xyz' } } };

(assuming you hadn't stored anything else under C<< [ foo => 3, 'bar' ] >>).

Clear as mud? Good!

=head2 new

  my $store = Data::Remember::Class->new($brain, @options);

The C<$brain> argument lets you select a brain plugin to use. The brain plugins available with this distribution currently include:

=over

=item L<Data::Remember::Memory>

A brain that stores everything in plain Perl data structures. Data in this brain is not persistent.

=item L<Data::Remember::DBM>

A brain that stores everything via L<DBM::Deep>. Data stored here will be persistent. This brain also requires additional arguments (see the module documentation for details).

=item L<Data::Remember::YAML>

A brain that stores everything via L<YAML>. This is great for storing configuration data.

=item L<Data::Remember::Hybrid>

A brain that doesn't store anything, but lets you use mix storage mechanisms.

=item L<Data::Remember::POE>

Automagically use a brain that is stored in the L<POE::Session> heap.

=back

You can specify C<$brain> as a short name if it exists under "C<Data::Remember::>". (For example, "C<DBM>" will load "C<Data::Remember::DBM>".) if C<$brain> contains a "C<::>", then it will be treated as a fully qualified name, in case you want to create your own brain. See L<Data::Remember/CREATING A BRAIN>.

The C<@options> are whatever options described in the brain's module documentation.

=head2 remember

  $store->remember($que, $fact);

Remember the given C<$fact> at memory que C<$que>. See L</QUE> for an in depth discussion of C<$que>. The C<$fact> can be anything your brain can store. This will generally include, at least, scalars, hash references, and array references.

=head2 remember_these

  $store->remember_these($que, $fact);

Stores the given C<$fact> at the give C<$que>, but stores it by pushing it onto the back of an array stored at C<$que>. This allows you to remember a list of things at a given C<$que>:

  $store->remember_these(stooges => 'Larry');
  $store->remember_these(stooges => 'Curly');
  $store->remember_these(stooges => 'Moe');

  my $stooges = $store->recall('stooges'); 
  # ^^^ returns the array [ qw( Larry Curly Moe ) ]

=head2 recall

  my $fact = $store->recall($que);

Recalls a previously stored fact located at the memory location described by C<$que>. See L</QUE> for an in depth discussion of that argument.

If no fact is found at that que, C<undef> will be returned.

=head2 recall_each

  my $iter = $store->recall_each($que);
  while (my ($k, $v) = $iter->()) {
      ...
  }

Given a que defined as a usual L</QUE>, this will return an iterator that will iterate over all the keys in a nested part of the store. The way the iterator works will depend on what kind of data C<$que> points to.

=over

=item *

L<Hash.> For hashes, the iterator will work similar to the built-in C<each> operator. It will return each key/value pair found in the hash in no particular order.

=item *

L<Array.> For arrays, the iterator will return each index and value as a pair, in order.

=item *

L<Scalar.> For anything else, it will return a single pair. The first element in the pair will be C<undef> and the second will be the scalar value.

=back

When the iterator is finished it returns an empty list.

The iterator captures the keys and array length at the time it was created. If changes are made to the data stored, it will return the same keys or array indexes that were stored at the moment of the call, but the values returned will be whatever is current stored. If the value at the que is removed entirely, the iterator closes over the original reference and will proceed anyway.

=head2 recall_and_update

  my $count = $store->recall_and_update(sub { ... }, $que);

This helper allows you to simultaneously recall and update an entry. For example, if you want to increment the entry while recalling it:

  my $count = $store->recall_and_update(sub { $_++ }, 'count');

any modification to C<$_> will be stored back into the given que. The result of the code run is returned by the function. For example, if you wanted to replace every "G" with "Q" in the brain, but wanted to use the original unmodified string, you could:

  my $with_g = $store->recall_and_update(sub { my $copy = $_; s/G/Q/g; $copy }, 'some_que');

=head2 forget

  $store->forget($que);

Tells the brain to forget a previously remembered fact stored at C<$que>. See L</QUE> for an in depth discussion of the argument. If no fact is stored at the given C<$que>, this subroutine does nothing.

=head2 forget_when

  $store->forget_when(sub { ... }, $que);

Tells the brain to forget a previously remembered fact stored at C<$que>. The behavior of C<forget_when> changes depending on the nature of the fact stored at C<$que>.

If C<$que> is a hash, the code reference given as the first argument will be called for each key/value pair and passed the key in C<$_[0]> and the value in C<$_[1]>. When the code reference returns true, that pair will be forgotten.

If C<$que> is an array, the code reference given as the first argument will be called for each index/value pair and passed the index in C<$_[0]> and the value in C<$_[1]>, the value will be passed in C<$_> as well. If the code reference returns a true value, that value will be forgotten.

For any other type of fact stored in the brain, the code reference will be called with C<$_[0]> set to C<undef> and C<$_[1]> and C<$_> set to the value of the fact. The whole que will be forgotten if the code reference returns true.

=head2 brain

  my $brain = $store->brain;

Returns the inner object used to store data. This can be used in case the brain plugin provides additional methods or features that need manual access. For example, if you want to use L<DBM::Deep>s locking features, you could:

  $store->brain->dbm->begin_work;

  my $balance = $store->recall('balance');
  $store->remember(balance => $balance + 150);

  $store->brain->dbm->commit;

=head1 CREATING A BRAIN

If you would like to create a custom brain plugin, you need to create a package that implements four methods: C<new>, C<remember>, C<recall>, and C<forget>.

The C<new> method will take the list of options passed to L</import> for your brain in addition to the class name. It should return a blessed reference that will be used for all further method calls.

The C<remember> method will be passed a normalized reference to a que array and the fact the user has asked to store. You should read through L</QUE> and handle the first argument as described there. Then, store the second argument at the memory location described.

The C<recall> method will be passed a normalized reference to a que array, which should be treated as described in L</QUE>. Your implementation should return the fact stored at that location or C<undef>. It's important that your implementation avoid the pit-falls caused by auto-vivifying keys. The C<recall> method should never modify the memory of your brain.

The C<forget> method will be passed a normalized reference to a que array, which should be treated as described in L</QUE>. Your implementation should then delete any fact stored there. Other than deleting this key, the C<forget> method should not modify any other aspect of the memory of your brain.

To build a brain, I highly recommend extending L<Data::Remember::Memory>, which performs (or should perform) all the work of safely storing and fetching records from a Perl data structure according to the interface described here. It stores everything under C<< $self->{brain} >>. At the very least, you should read through that code before building your brain.

The L<Data::Remember::DBM> or other included brains may also be a good place to look. They extend L<Data::Remember::Memory> so that I didn't have to repeat myself.

=head1 DIAGNOSTICS

This class emits the following warnings:

=over

=item The brain BRAIN may not have loaded correctly: ERROR

This message indicates that an error occurred while loading the package named C<BRAIN>. C<ERROR> contains the nested error message. This is only a warning because it's possible that this failure is normal (e.g., if the package is not defined in it's own Perl module).

=item Undefined que element used in call to SUB.

This message indicates that you attempted to pass an undefined value as a component of the que to the named subroutine. Such calls are ignored by L<Data::Remember>. (Hence the warning.) 

=back

Whenever possible, this library attempts not to throw exceptions. The major exception that rule (HAH!) is during initialization. Any problems detected there are generally very important, so exceptions are thrown liberally.

Here are the exceptions that are emitted by this class:

=over

=item This does not look like a valid brain: BRAIN

The brain plugin name given does not look like a valid Perl class name. L<Data::Remember> won't even check to see if it is a brain plugin unless it could be a package name.

=item Your brain cannot remember facts: BRAIN

You attempted to use a brain class that does not provide a C<remember()> method.

=item Your brain cannot recall facts: BRAIN

You attempted to use a brain class that does not provide a C<recall()> method.

=item Your brain cannot forget facts: BRAIN

You attempted to use a brain class that does not provide a C<forget()> method.

=back

=head1 SEE ALSO

L<Data::Remember::Memory>, L<Data::Remember::DBM>, L<Data::Remember::YAML>, L<Data::Remember::Hybrid>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
