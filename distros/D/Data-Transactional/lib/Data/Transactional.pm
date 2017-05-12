package Data::Transactional;

use strict;
use warnings;

our $VERSION = '1.04';

use Data::Dumper;

=head1 NAME

Data::Transactional - data structures with RDBMS-like transactions

=head1 SYNOPSIS

    use Data::Transactional;

    my $data = Data::Transactional->new(type => 'hash');
    $data->{food_and_drink} = [ [], [] ];
    $data->checkpoint();
    $data->{food_and_drink}->[0] = [qw(pie curry chips)];
    $data->checkpoint();
    $data->{food_and_drink}->[1] = [qw(beer gin whisky)];
    $data->rollback();   # back to last checkpoint

=head1 METHODS

=over

=item new

The constructor.  This takes named parameters.  The only parameter
so far is:

=over

=item type

Optional parameter, taking either 'ARRAY' or 'HASH' as its value (case-
insensitive), to determine what data type to base the structure on.
Regardless of what you choose for the first level of the structure, you
may use whatever you like further down the tree.  If not supplied, this
defaults to 'HASH'.

=back

=cut

sub new {
    my($class, %args) = @_;
    my $self;

    $args{type} ||= 'HASH'; $args{type} = uc($args{type});

    if($args{type} eq 'HASH') {
        tie %{$self}, __PACKAGE__.'::Hash';
    } elsif($args{type} eq 'ARRAY') {
        tie @{$self}, __PACKAGE__.'::Array';
    } else {
        die(__PACKAGE__."::new(): type '$args{type}' unknown\n");
    }

    return bless $self, $class;
}

=item checkpoint

Saves the current state of the structure so that we can roll back to it.

=cut

sub checkpoint {
    my $self = shift;
    (tied %{$self})->checkpoint();
}

=item commit

Discards the most recent saved state, so it can no longer be rolled back.
Why do this?  Well, throwing away the history saves a load of memory.
It is a fatal error to commit() when there's no saved states.

=cut

# should this also commit_all in sub-structures?
sub commit {
    my $self = shift;
    (tied %{$self})->commit();
}

=item commit_all

Throws away all saved states, effectively committing all current transactions.

=cut

sub commit_all {
    my $self = shift;
    undef $@;
    while(!$@) { eval { $self->commit(); }; }
}

=item rollback

Revert the data structure to the last checkpoint.  To roll back beyond the
first checkpoint is a fatal error.

=cut

sub rollback {
    my $self = shift;
    (tied %{$self})->rollback();
}

=item rollback_all

Roll back all changes.

=cut

sub rollback_all {
    my $self = shift;
    undef $@;
    while(!$@) { eval { $self->rollback(); }; }
}

=item current_state

Return a reference to the current state of the underlying object.

=cut

sub current_state {
    my $self = shift;
    return $self->isa('HASH') ?
        tied(%{$self})->current_state() :
        tied(@{$self})->current_state();
}

=back

=head1 IMPLEMENTATION NOTES

This module relies on two other packages which are included in the same
file - Data::Transactional::Hash and Data::Transactional::Array.  These
are where the magic really happens.  These implement everything needed
for C<tie()>ing those structures, plus their own C<checkpoint()>,
C<commit()> and C<rollback()> methods.  When you create a
Data::Transactional object, what you really get is one of these tied
structures, reblessed into the Data::Transactional class.  The
transactional methods simply call through to the same method on the
underlying tied structure.

This is loosely inspired by L<DBM::Deep>.

=head1 BUGS/WARNINGS

I assume that C<$[> is zero.

Storing blessed objects in a C<Data::Transactional> structure is not
supported.  I suppose it could be, but there's no sane way that they
could be transactionalised.  This also applies to tie()d objects.
Please note that in the case of tie()d objects, we don't do a great deal
of checking, so things may break in subtle and hard-to-debug ways.

The precise details of how the transactional methods affect sub-structures
in your data may change before a 1.0 release.  If you have suggestions for
how it could be improved, do please let me know.

The SPLICE() operation is *not defined* for transactionalised arrays,
because it makes my brane hurt.  If you want to implement this please
do!  Remember that you should use STORE() to put each new entry in the
array, as that will properly handle adding complex data structures.

No doubt there are others.  When submitting a bug report please please
please include a test case, in the form of a .t file, which will fail
with my version of the module and pass once the bug is fixed.  If you
include a patch as well, that's even better!

=head1 FEEDBACK

I welcome all comments - both praise and constructive criticism - about
my code.  If you have a question about how to use it please read *all*
of the documentation first, and let me know what you have tried and how
the results differ from what you wanted or expected.

I do not consider blind, automatically generated and automatically sent
error reports to be constructive.
Don't send them, you'll only get flamed.

=head1 AUTHOR

David Cantrell E<lt>david@cantrell.org.ukE<gt>

=head1 LICENCE

This software is Copyright 2004 David Cantrell.  You may use, modify and
distribute it under the same terms as perl itself.

=cut

package Data::Transactional::Hash;
use Storable qw(dclone);
use strict;use warnings;

sub TIEHASH {
    my $class = shift;
    my $self = {
        STACK           => [],
        CURRENT_STATE   => {},
    };

    return bless $self, $class;
}

sub CLEAR {
    my $self=shift;
    $self->{CURRENT_STATE}={};
}

sub STORE {
    my($self, $key, $value)=@_;
    my $newobj = $value;
    if(ref($value)) {
        if(ref($value) eq 'ARRAY') {
	    $newobj = Data::Transactional->new(type => 'ARRAY');
	    # @{$newobj} = @{$value};
	    push @{$newobj}, $_ foreach(@{$value});
	} elsif(ref($value) eq 'HASH') {
	    $newobj = Data::Transactional->new(type => 'HASH');
	    # %{$newobj} = %{$value};
	    $newobj->{$_} = $value->{$_} foreach(keys %{$value});
	} else {
            die(__PACKAGE__."::STORE(): don't know how to store a ".ref($value)."\n");
	}
    }
    $self->{CURRENT_STATE}->{$key} = $newobj;
}

sub FETCH {
    my($self, $key) = @_;
    $self->{CURRENT_STATE}->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    scalar keys %{$self->{CURRENT_STATE}};   # reset iterator
    # scalar each %{$self->{CURRENT_STATE}};
    $self->NEXTKEY();
}

sub NEXTKEY { my $self = shift; scalar each %{$self->{CURRENT_STATE}}; }
sub DELETE { my($self, $key) = @_; delete $self->{CURRENT_STATE}->{$key}; }
sub EXISTS { my($self, $key) = @_; exists($self->{CURRENT_STATE}->{$key}); }

sub checkpoint {
    my $self = shift;
    # make a new copy of CURRENT_STATE before putting on stack,
    # otherwise CURRENT_STATE and top-of-STACK will reference the
    # same data structure, which would be a Bad Thing
    push @{$self->{STACK}}, dclone($self->{CURRENT_STATE});
}

sub commit {
    my $self = shift;
    # $self->{STACK}=[];                     # clear all checkpoints
    defined(pop(@{$self->{STACK}})) ||
        die("Attempt to commit without a checkpoint");
}

sub rollback {
    my $self = shift;
    die("Attempt to rollback too far") unless(@{$self->{STACK}});
    # no copying required, just update a pointer
    $self->{CURRENT_STATE}=pop @{$self->{STACK}};
}

sub current_state {
    shift->{CURRENT_STATE};
}

package Data::Transactional::Array;
use Storable qw(dclone);
use strict;use warnings;

sub TIEARRAY {
    my $class = shift;
    my $self = {
        STACK           => [],
        CURRENT_STATE   => [],
    };

    return bless $self, $class;
}

sub CLEAR {
    my $self=shift;
    $self->{CURRENT_STATE}=[];
}

sub STORE {
    my($self, $index, $value)=@_;
    my $newobj = $value;
    if(ref($value)) {
        if(ref($value) eq 'ARRAY') {
	    $newobj = Data::Transactional->new(type => 'ARRAY');
	    # @{$newobj} = @{$value};
	    push @{$newobj}, $_ foreach(@{$value});
	} elsif(ref($value) eq 'HASH') {
	    $newobj = Data::Transactional->new(type => 'HASH');
	    # %{$newobj} = %{$value};
	    $newobj->{$_} = $value->{$_} foreach(keys %{$value});
	} else {
            die(__PACKAGE__."::STORE(): don't know how to store a ".ref($value)."\n");
	}
    }
    $self->{CURRENT_STATE}->[$index] = $newobj;
}

sub FETCH {
    my($self, $index) = @_;
    $self->{CURRENT_STATE}->[$index];
}

sub DELETE { my($self, $index) = @_; delete $self->{CURRENT_STATE}->[$index]; }
sub EXISTS { my($self, $index) = @_; exists($self->{CURRENT_STATE}->[$index]); }
sub POP { my $self = shift; pop @{$self->{CURRENT_STATE}}; }
sub SHIFT { my $self = shift; shift @{$self->{CURRENT_STATE}}; }

sub PUSH {
    my($self, @list) = @_;
    $self->STORE($self->FETCHSIZE(), $_) foreach (@list);
}

sub UNSHIFT {
    my($self, @list) = @_;
    my @oldlist = @{$self->{CURRENT_STATE}};
    # shuffle existing contents along
    for(my $i = $self->FETCHSIZE() - 1; $i >= 0; $i--) {
        $self->{CURRENT_STATE}->[$i + scalar(@list)] =
	    $self->{CURRENT_STATE}->[$i];
    }
    $self->STORE($_, $list[$_]) foreach(0..$#list);
    return $self->FETCHSIZE();
}

# # FIXME - this needs to shuffle stuff as UNSHIFT does, then use STORE
# # for anything we insert
# sub SPLICE {
# }

sub FETCHSIZE { my $self = shift; scalar(@{$self->{CURRENT_STATE}}); }
sub STORESIZE {
    my($self, $count) = @_;
    $self->{CURRENT_STATE} = [(@{$self->{CURRENT_STATE}})[0..$count - 1]];
}
sub EXTEND { 'the voices told me to write this method' }

sub checkpoint {
    my $self = shift;
    push @{$self->{STACK}}, dclone($self->{CURRENT_STATE});
}

sub commit {
    my $self = shift;
    # $self->{STACK}=[];                     # clear all checkpoints
    defined(pop(@{$self->{STACK}})) ||
        die("Attempt to commit without a checkpoint");
}

sub rollback {
    my $self = shift;
    die("Attempt to rollback too far") unless(@{$self->{STACK}});
    # no copying required, just update a pointer
    $self->{CURRENT_STATE} = pop @{$self->{STACK}};
}

sub current_state {
    shift->{CURRENT_STATE};
}
