package Data::StackedHash;
our $VERSION = '0.99';

#
# Copyright (C) 2003 Riccardo Murri, <riccardomurri@yahoo.it>. All
# rights reserved.

# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the same terms as Perl itself.
#

=pod

=head1 NAME

Data::StackedHash - Stack of PERL Hashes

=head1 SYNOPSIS

  use Data::StackedHash;

  tie %h, Data::StackedHash;

  $h{'a'}=1;
  $h{'b'}=2;
  tied(%h)->push; # put a new hash on the stack
  $h{'a'}=3;      # override value of key 'a'
    ...
  tied(%h)->pop;  # remove top hash from the stack,
                  # $h{'a'} == 1 again


=head1 DESCRIPTION

The Data::StackedHash module implements a stack of hashes; the whole
stack acts collectively and transparently as a single PERL hash, that
is, you can perform the usual operations (fetching/storing values,
I<keys>, I<delete>, etc.)  on it.  All the PERL buitlins which operate
on hashes are supported.

Assigning a value to a key, as in C<< $h{'a'}=1 >>, puts the key/value
pair into the hash at the top of the stack. Reading a key off the
stack of hashes searches the whole stack, from the topmost hash to the
bottom one, until it finds a hash which holds some value associated to
the given key; returns C<< undef >> if no match was found.

The built-in functions I<keys>, I<values>, I<each> act on the whole
collection of all key/value defined in any hash of the stack.

You can add a hash on top of the stack by the method I<push>, and
remove the topmost hash by the method I<pop>.

Clearing a stack of hashes only clears the topmost one: that is,

    use Data::StackedHash;
    tie %h, Data::StackedHash, {'a'=>1};

    # put some hash on top of the stack
    tied(%h)->push({'a'=>2}); 

    print $h{'a'}; # prints 2

    %h = {}; # clear topmost hash

    print $h{'a'}; # prints 1

=cut

use 5.006;
use strict;
use warnings;

sub TIEHASH {
    my $proto = shift;
    my $initial = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    $self->{KEYS} = {};
    if ($initial) {
	$self->{STACK} = [$initial];
	my $key;
	foreach $key (keys %$initial) {
	    $self->{KEYS}->{$key}++;
	}
    } else {
	$self->{STACK} = [{}];
    }
    bless($self, $class);
    return $self;
};

sub STORE {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->{KEYS}->{$key}++ unless exists @{$self->{STACK}}[0]->{$key};
    @{$self->{STACK}}[0]->{$key} = $value;
};

sub CLEAR {
    my $self = shift;
    @{$self->{STACK}}[0] = {};
    # rebuild the KEYS hash...
    %{$self->{KEYS}} = ();
    my $hash;
    my $key;
    foreach $hash (@{$self->{STACK}}) {
	foreach $key (keys %{$hash}) {
	    $self->{KEYS}->{$key} = 1;
	};
    };
};

=pod

=head2 METHODS

=head3 push()

The I<push()> method puts a new hash on top of the stack: you can
either pass to it a reference to the hash to put on top, or call
I<push()> with no arguments, in which case an empty hash is pushed
onto the stack.

    use Data::StackedHash; 
    tie %h, Data::StackedHash;

    # put some hash on top of the stack
    tied(%h)->push({'a'=>1, 'b'=>2}); 
    
    # put an empty hash on top of the stack
    tied(%h)->push;

=cut
    
sub push {
    my $self = shift;
    unshift @{$self->{STACK}}, $_[0] || {};
    if ($_[0]) {
	my $key;
	foreach $key (keys %{$_[0]}) {
	    $self->{KEYS}->{$key}++;
	};
    };
};

=pod

=head3 pop()

The I<pop()> method removes the hash on top of the stack and returns a
reference to it; all key/value pairs defined only in that hash are
lost.

=cut

sub pop {
    my $self = shift;
    my $hash = shift @{$self->{STACK}};
    my $key;
    foreach $key (keys %$hash) {
	$self->{KEYS}->{$key}--;
    }
    return $hash;
};

=pod

=head3 delete(), delete_all()

A call to the built-in I<delete> will remove only the first-found key,
and return the associated value, or C<< undef >> if no such key was
found.  

    use Data::StackedHash; 
    tie %h, Data::StackedHash, { 'a'=>1 };

    # put one more hash on top of the stack
    tied(%h)->push(); 
    $h{'a'}=2;
    print "$h{a}\n"; # 2

    # delete the topmost occurrence of the 'a' key
    delete $h{'a'};
    print "$h{a}\n"; # 1

The I<delete_all> method deletes the specified key from all hashes in
the stack; it returns the array of values found in the stack, or the
empty array if no value was associated with the given key.  Values
from the topmost stack are first in the returned array.

    use Data::StackedHash; 
    tie %h, Data::StackedHash, { 'a'=>1 };

    # put one more hash on top of the stack
    tied(%h)->push(); 
    $h{'a'}=2;
    print "$h{a}\n"; # 2

    # delete all occurrences of the 'a' key
    tied(%h)->delete_all('a');
    print "$h{a}\n"; # undef

=cut

sub DELETE {
    my $self = shift;
    my $key = shift;
    
    return undef unless exists $self->{KEYS}->{$key};
    
    $self->{KEYS}->{$key}--;
    delete $self->{KEYS}->{$key} if $self->{KEYS}->{$key} == 0;
    my $hash;
    foreach $hash (@{$self->{STACK}}) {
	next unless exists $hash->{$key};
	# From perltie(3): ``If you want to emulate the
	#       normal behavior of delete(), you should return what-
	#       ever FETCH would have returned for this key.''
	return delete $hash->{$key};
    }
    return undef;
};

sub delete_all {
    my $self = shift;
    my $key = shift;
    my $hash;
    my @value = ();
    foreach $hash (@{$self->{STACK}}) {
	CORE::push @value, $hash->{$key} if exists $hash->{$key};
	  delete $hash->{$key};
      }
    delete $self->{KEYS}->{$key};
    # From perltie(3): ``If you want to emulate the
    #       normal behavior of delete(), you should return what-
    #       ever FETCH would have returned for this key.''
    return @value;
};

=pod

=head3 fetch_all(key)

Returns all values associated with the given key; values from topmost
hash are first in the returned array.

=cut

sub FETCH {
    my $self = shift;
    my $key = shift;
    my $hash;
    foreach $hash (@{$self->{STACK}}) {
	return $hash->{$key} if exists $hash->{$key};
    };
    # PERL hashes return the "undefined empty string" if
    # one requests a non-existing key...
    return undef;
};

sub fetch_all {
    my $self = shift;
    my $key = shift;
    my $hash;
    my @values;
    foreach $hash (@{$self->{STACK}}) {
	CORE::push @values, $hash->{$key} if exists $hash->{$key};
      };
    return @values;
};

=pod

=head3 keys(), values(), each()

The built-in functions I<keys>, I<values> and I<each> operate on the
union of all key/value pairs defined in any hash of the stack.

    use Data::StackedHash; 
    tie %h, Data::StackedHash, { 'a'=>1 };

    # put one more hash on top of the stack
    tied(%h)->push(); 
    $h{'b'}=2;

    # print all defined keys
    print keys %h; # ab

=cut

sub EXISTS {
    my $self = shift;
    my $key = shift;
    return exists ($self->{KEYS}->{$key}) ? 1 : 0;
};

sub FIRSTKEY {
    my $self = shift;
    # reset the 'each' internal iterator
    keys %{$self->{KEYS}};
    return each %{$self->{KEYS}};
};

sub NEXTKEY {
	my $self = shift;
	return each %{$self->{KEYS}};
}

=pod

=head3 height()

The I<height> method returns the current height of the stack of hashes. 

    use Data::StackedHash; 
    tie %h, Data::StackedHash, { 'a'=>1 };

    # put one more hash on top of the stack
    tied(%h)->push(); 

    print tied(%h)->height; # prints 2

=cut

sub height {
	my $self = shift;
	return $#{$self->{STACK}};
}

=pod

=head3 count(key)

Given a key, the I<count> method returns the number of hashes in which
that key is associated to a value.

    use Data::StackedHash; 
    tie %h, Data::StackedHash, { 'a'=>1 };

    # put one more hash on top of the stack
    tied(%h)->push({'b'=>2}); 

    print tied(%h)->count('a'); # prints 1

=cut

sub count {
	my $self = shift;
	my $key = shift;
	return $self->{KEYS}->{$key};
}

1; # so the require or use succeeds

__END__

=head1 SEE ALSO

L<Data::MultiValuedHash>, L<perlfunc/delete>, L<perlfunc/keys>, 
L<perlfunc/values>, L<perlfunc/each>.

=head1 AUTHOR

Riccardo Murri, E<lt>riccardomurri@yahoo.itE<gt>

=head1 LICENCE

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut
