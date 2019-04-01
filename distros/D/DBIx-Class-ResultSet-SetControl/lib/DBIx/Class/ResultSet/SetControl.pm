use strict;
use warnings;

package DBIx::Class::ResultSet::SetControl;
use DBIx::Class::Util::ResultSet::Iterator;

our $VERSION='0.002';

my $_itr = sub {
  my $self = shift;
  return my $itr = DBIx::Class::Util::ResultSet::Iterator->new(resultset=>$self);
};

sub map {
  my ($self, $target, $sub, $fail) = @_;

  my $itr = $self->$_itr;
  while(my $row = $itr->next) {
    { 
      local $_ = $row; 
      my ($return, @err) = $sub->($itr, $row);
      $self->throw_exception("'->map' must return a scalar") if @err;
      push @$target, $return;
    };
    if($itr->has_escaped) {
      return $itr->resultset;
    }
  }

  if($fail && $itr->has_not_been_used) {
    my ($return, @err) = $fail->($self);
    $self->throw_exception("'->map' must return a scalar") if @err;
    push @$target, $return;
  }

  return $self;
}

sub each {
  my($self, $func_proto, $fail) = @_;

  ## validate and normalize the function prototype
  unless(
    $func_proto and (
    ref($func_proto) eq 'CODE' or
    ref($func_proto) eq 'ARRAY' )
  ) {
    $self->throw_exception('Argument must be a CODEREF or ARRAYREF')
  }

  ## create a local iterator for the each function
  my @funcs;
  my $func_itr = sub {
    @funcs = ref($func_proto) eq 'ARRAY' ? @$func_proto : $func_proto unless @funcs;
    return shift @funcs;
  };

  ## Iterate over the resultset
  my $itr = DBIx::Class::Util::ResultSet::Iterator->new(resultset=>$self);
  while(my $row = $itr->next) {
    { local $_ = $row; $func_itr->()->($itr, $row) };
    if($itr->has_escaped) {
      return $itr->resultset;
    }
  }

  ## Handle fails
  if($fail && $itr->has_not_been_used) {
    $fail->($self);
  }

  ## Allow chaining methods
  return $self;
}

sub once {
  my($self, $func, $fail) = @_;
  if(my $row = $self->next) {
    { local $_ = $row; $func->($row) };
  } elsif($fail) {
    $fail->();
  }
  return $self;
}

sub tap {
  my($self, $func, @args) = @_;
  my $new_rs = $self->search_rs;
  { local $_ = $new_rs; $func->($func, $new_rs, @args) };
  return $self;
}

sub times {
  my($self, $times, $func, @args) = @_;
  $self->tap($func, @args) for 1.. $times;
  return $self;
}

1;

=head1 NAME

DBIx::Class::ResultSet::SetControl - Easier Looping over resultsets

=head1 SYNOPSIS

Given a L<DBIx::Class::ResultSet> that consumes this component, such as the
following:

    package MySchema::ResultSet::Bar;

    use strict;
    use warnings;
    use parent 'DBIx::Class::ResultSet';

    __PACKAGE__->load_components('ResultSet::SetControl');

    ## Additional custom resultset methods, if any

    1;

Then later when you have a resultset of that class:

    my $rs = $schema->resultset('Bar');

You can call methods directly on your object which are related to control flow
and looping over the items in you resultset.

    $rs->tap(sub {
      print shift->find({id=>1} ? 'found one' : 'nope';
    })->each(sub {
      my ($each, $row) = @_;
      print $each->is_odd ? $row->name . ' is odd' : 'nope, not odd';
    });

B<NOTE> If you intend to use this component in many of your resultsets, its best
practice to write a 'base' resultset that loads this (and any other) components
from which all your custom resultset classes inherit.

=head1 DESCRIPTION

There are times where Perl's procedural syntax for control flow and looping
leads to excessively verbose code.  For those times we present this helper
which is designed to encapsulate some very common control flow and loop patterns
for L<DBIx::Class> users.

The methods are OO in nature and designed to be compact and concise.

Additionally, we have tried to write these methods to allow for a 'chaining'
approach that you can't replicate with traditional Perl control and looping
structures.  Each control flow method returns the original resultset so you
can proceed as though it is unaltered (unless of course you alter it somehow
like with an insert or update).

The goal it to help avoid excessive conditional logic and to allow one to write
more compact and neat code.  For example, you could replace:

    my $has_rows;
    while(my $row = $rs->next) {
      $has_rows = 1;
      ## Do something
    }
    unless($has_rows) {
      warn 'no rows!';
    }

With something like

    $rs->each(sub {
      my ($each, $row) = @_;
      ## Do Something
    }, sub {
      warn 'no rows!';
    });

The second version has less overall lines and characters, and it also carefully
encapsulates a very common pattern, which is to loop over all the rows in a
resultset and do something should no rows exist.  Also, the L</each> method
returns the original C<$rs> so you could chain commands:

    $rs->each(sub {
      my ($each, $row) = @_;
      ## Do Something
    }, sub {
      warn 'no rows!';
    })->tap(sub {
      my $rs = shift;
      ## Do something else
    });

There may be cases in your logical flow where this type of programming is more
clear and simple; in other cases traditional Perl control and looping might be
better.  These methods give you an option.  On the other hand you might think
this is all pointless line noise.  As you wish :)

=head1 METHODS

This component defines the following methods.

=head2 map

Arguments: $rs->map(\my @mapped_to, $coderef, ?$if_empty_coderef)
Returns: Original Resultset OR partly iterated Resultset

Example:

    $schema
      ->resultset('Person')
      ->map(\my @list, sub {
          my ($i, $row) = @_;
          return +{ id => $row->id };
        });

Where @list will be an array of hashes in the form +{ id => 111 }.

Basically this is like:

    my @list = map { ${ id => $_->id }  } $person_rs->all;

The two main advantages are that the method returns the resultset so you can chain it
and the $i iterator has some ability to control and escape the loop.  Also ->all will
inflate the entire set whereas map will inflate one at a time (possible memory savings.)

$i has some nice 'status of the loop' features such as if the current $row is the first
one, or if its odd/even.  Be sure to check L<DBIx::Class::Util::ResultSet::Iterator>.

It also has an optional third argument that only runs if the set is empty.  It runs once
and can be used to provide a default value to the target array:

    $schema
      ->resultset('Person')
      ->map(\my @list, sub {
          my ($i, $row) = @_;
          return +{ id => $row->id };
        }, sub {
          return 'empty list';
        });


Its not amazingly useful standalone but if you are using the other stuff its a nice to
have to make the API more complete.

=head2 each

Arguments: $rs->each($coderef|\@$coderef, ?$if_empty_coderef)
Returns: Original Resultset OR partly iterated Resultset

Where C<$coderef> is an anonymous subroutine or closure that will get the
instantiated L<DBIx::Class::Helpers::Util::ResultSet::Iterator> object and the
current C<$row> from the set returned.  For example C<$row> in the ResultSet
the $coderef will be executed once.

C<$if_empty_coderef> is an anonymous subroutine or closure that gets
executed ONLY if there were no rows in the set.  It gets the C<$resultset>
as an argument (this might change later if we discover a better thing to do
here).

In the case where the first argument is an arrayref of coderefs, we automatically
iterate over each coderef for each result in the set in turn and reset the
coderef iterator as needed to make sure we hit every item in the set.  Please
be aware that in the case where the arrayref of coderefs is longer than the
available results in the set, this means that not all coderefs will be invoked
and this happens without an exception being thrown.

Example: For the given L<DBIx::Class::ResultSet>, iterator over each result.

    $rs->each(sub {
      my ($each, $row) = @_;
      ...
    });

This is functionally similar to something like:

    my $itr = DBIx::Class::Util::ResultSet::Iterator->new(resultset=>$rs);
    while(my $row = $itr->next) {
      ...
    }

However the method will return the original $resultset used to initialize it
so that you can continue chaining or building off it.  Of course you will need
to issue a c<ResultSet->reset> for this to be useful.

Here's a more detailed example.

    $rs->each(sub {
      my ($each, $row) = @_;

      $each->first(sub {
        print "Hey, this is the first row!";
      });

      if($each->is_odd) {
        print $row->columnname;
      } else {
        return $each->escape;
      }
    }, sub {
      my ($rs) = @_;
      warn "The resultset was empty, nothing done...";
    });

Finally one example using an arrayref as the first argument:

    $rs->each(
      [
        sub { ... },
        sub { ... },
        sub { ... },
      ], sub {
        my ($rs) = @_;
        warn "The resultset was empty, nothing done...";
      }
    );

You may find this helper leads you to writing more concise and compact code.
Additionally having an iterator object available can be helpful, particularly
when you are in a template and need to display things differently based on if
the row is even/odd, first/last, etc.

You should see the documentation for L<DBIx::Class::Util::ResultSet::Iterator>
for the methods this object exposes for use.

B<NOTE> For conciseness in simple cases, we overload C<$_> to equal the value of
C<$row> as described above.

=head2 once

Arguments: $rs->once($coderef, ?$if_empty_coderef)
Returns: Partly iterated Resultset

Works just like L</each> expect instead of iterating over the entire resultset
we just take the first C<$row>.

Example

    $rs->once( sub {
      my ($row) = @_;
    }, sub {
      warn 'no rows left!';
    })->each( ... );

Useful to isolate the logic for the first row in a resultset.

B<NOTE> For conciseness in simple cases, we overload C<$_> to equal the value of
C<$row> as described above.

=head2 tap

Arguments: $coderef, ?@args
Returns: Original Resultset

Do a coderef with the resultset passed as an argument.

    $rs->tap(sub {
      my ($func, $rs, $arg) = @_;
      $rs->find({id=>$arg});
    }, 100);

If you pass more than one argument, all the extra arguments will be send to the
anonymous coderef.

B<NOTE> The resultset passed is cloned from the original and it returns the original
resultset so you can chain.

B<NOTE> the first argument passed to the coderef is the orginal coderef so that you can
call recursively.

B<NOTE> For conciseness in simple cases, we overload C<$_> to equal the value of
C<$rs> as described above.

=head2 times

Arguments: $integer, $coderef, ?@args
Returns: Original Resultset

Basically this calls L</tap> a number of times equal to the first argument.

    $rs->times(3, sub {
      my $rs = shift;
      ...
    });

B<NOTE> For conciseness in simple cases, we overload C<$_> to equal the value of
C<$rs> as described above.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 SEE ALSO

L<DBIx::Class>

=head1 COPYRIGHT & LICENSE

Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
