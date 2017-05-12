package Data::COW;

use 5.006001;
use strict;
no warnings;

use Exporter;
use Scalar::Util qw<reftype blessed>;
use overload ();  # we're not overloading anything, but we'd like to
                  # check if they're already implementing a value type

use base 'Exporter';

our @EXPORT = qw<make_cow_ref>;

our $VERSION = '0.02';

sub tied_any {
    my ($ref) = @_;
    if (ref $ref) {
        if (reftype($ref) eq 'SCALAR') {
            tied $$ref;
        }
        elsif (reftype($ref) eq 'ARRAY') {
            tied @$ref;
        }
        elsif (reftype($ref) eq 'HASH') {
            tied %$ref;
        }
    }

}

sub cow_object {
    my ($ref) = @_;
    my $tied = tied_any $ref;
    $tied && $tied->isa('Data::COW') && $tied;
}

sub make_cow_ref {
    my ($ref, $parent, $key) = @_;

    make_cow_ref_nocheck($ref, $parent, $key);
}

sub make_temp_cow_ref {
    my ($ref, $parent, $key) = @_;

    if (my $obj = cow_object $ref) {
        if ($obj->{parent} == $parent) {
            $ref;
        }
        else {
            make_cow_ref_nocheck($ref, $parent, $key);
        }
    }
    else {
        make_cow_ref_nocheck($ref, $parent, $key);
    }
}

sub make_cow_ref_nocheck {
    my ($ref, $parent, $key) = @_;

    if (ref $ref && 
        # check if they already think they're a value type
        !(overload::Overloaded($ref) && overload::Method($ref, '=')))
    {
        my $ret;
        if (reftype($ref) eq 'SCALAR') {
            tie my $it => 'Data::COW::Scalar', $ref, $parent, $key;
            $ret = \$it;
        }
        elsif (reftype($ref) eq 'ARRAY') {
            tie my @it => 'Data::COW::Array', $ref, $parent, $key;
            $ret = \@it;
        }
        elsif (reftype($ref) eq 'HASH') {
            tie my %it => 'Data::COW::Hash', $ref, $parent, $key;
            $ret = \%it;
        }
        else {
            # code and glob are not aggregates that we can take control
            # of, so punt and just return them like anything else
            return $ref;
        }
        
        if (blessed($ref)) {
            bless $ret => blessed($ref);
        }
        
        return $ret;
    }
    else {
        return $ref;
    }
}

sub clone_using {
    my ($self, $copier) = @_;

    return unless $self->{const};
    my $old = $self->{ref};
    my $new = $copier->($old);

    if (blessed $old) {
        bless $new => blessed $old;
    }
    if ($self->{parent}) {
        my $cnew = make_cow_ref $new, $self->{parent}, undef;
        tied_any($cnew)->{const} = 0;
        $self->{parent}->clone($self->{key} => $cnew);
    }
    $self->{ref} = $new;
    $self->{const} = 0;
}

package Data::COW::Scalar;

use Tie::Scalar;
use base 'Tie::Scalar';
use base 'Data::COW';

sub TIESCALAR {
    my ($class, $ref, $parent, $key) = @_;
    bless {
        ref => $ref,
        parent => $parent,
        key => $key,
        const => 1,
    } => ref $class || $class;
}

sub clone {
    my ($self, $key, $value) = @_;

    $self->clone_using(sub { my $v = ${$_[0]}; \$v });
    ${$self->{ref}} = $value if defined $key;
}

sub FETCH {
    my ($self) = @_;
    Data::COW::make_temp_cow_ref(${$self->{ref}}, $self, 1);
}

sub STORE {
    my ($self, $value) = @_;
    $self->clone(1 => $value);
    $value;
}

package Data::COW::Array;

use Tie::Array;
use base 'Tie::Array';
use base 'Data::COW';

sub TIEARRAY {
    my ($class, $ref, $parent, $key) = @_;
    bless {
        ref => $ref,
        parent => $parent,
        key => $key,
        const => 1,
    } => ref $class || $class;
}

sub clone {
    my ($self, $key, $value) = @_;
    $self->clone_using(sub { [ @{$_[0]} ] });
    $self->{ref}[$key] = $value if defined $key;
}

sub FETCH {
    my ($self, $key) = @_;
    Data::COW::make_temp_cow_ref($self->{ref}[$key], $self, $key);
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->clone($key => $value);
    $value;
}

sub FETCHSIZE {
    my ($self) = @_;
    scalar @{$self->{ref}};
}

sub STORESIZE {
    my ($self, $size) = @_;
    $self->clone;
    $#{$self->{ref}} = $size-1;
}

sub DELETE {
    my ($self, $key) = @_;
    $self->clone;
    delete $self->{ref}[$key];
}

sub EXISTS {
    my ($self, $key) = @_;
    exists $self->{ref}[$key];
}

package Data::COW::Hash;

use Tie::Hash;
use base 'Tie::Hash';
use base 'Data::COW';

sub TIEHASH {
    my ($class, $ref, $parent, $key) = @_;
    bless {
        ref => $ref,
        parent => $parent,
        key => $key,
        const => 1,
    } => ref $class || $class;
}

sub clone {
    my ($self, $key, $value) = @_;
    $self->clone_using(sub { 
        my $ret = { %{$_[0]} };
        $ret;
    });
    $self->{ref}{$key} = $value if defined $key;
}

sub FETCH {
    my ($self, $key) = @_;
    Data::COW::make_temp_cow_ref($self->{ref}{$key}, $self, $key);
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->clone($key => $value);
    $value;
}

sub EXISTS {
    my ($self, $key) = @_;
    exists $self->{ref}{$key};
}

sub DELETE {
    my ($self, $key) = @_;
    $self->clone;
    delete $self->{ref}{$key};
}

sub CLEAR {
    my ($self) = @_;
    $self->clone_using(sub { {} });
    ();
}

sub FIRSTKEY {
    my ($self) = @_;
    my $a = keys %{$self->{ref}};  # reset iterator
    each %{$self->{ref}};
}

sub NEXTKEY {
    my ($self) = @_;
    each %{$self->{ref}};
}

sub SCALAR {
    my ($self) = @_;
    scalar %{$self->{ref}};
}

1;

=head1 NAME

Data::COW - clone deep data structures copy-on-write

=head1 SYNOPSIS

    use Data::COW;

    my $array = [ 0, 1, 2 ];
    my $copy = make_cow_ref $array;

    push @$array, 3;
    # $copy->[3] is 3
    push @$copy, 4;
    # $array->[4] is not defined (and doesn't even exist)
    # $copy is a real copy now
    push @$array, 5;
    # $copy is unaffected

=head1 DESCRIPTION

Data::COW makes copies of data structures copy-on-write, or "lazily".
So if you have a data structure that takes up ten megs of memory, it
doesn't take ten megs to copy it.  Even if you change part of it,
Data::COW only copies the parts that need to be copied in order to
reflect the change.

Data::COW exports one function: C<make_cow_ref>.  This takes a reference
and returns a copy-on-write reference to it.  If you don't want this
in your namespace, and you want to use it as C<Data::COW::make_cow_ref>,
use the module like this:

    use Data::COW ();

Data::COW won't be able to copy filehandles or glob references.  But how
do you change those anyway?  It's also probably a bad idea to give it
objects that refer to XS internal state without providing a value type
interface.  Also, don't use stringified references from this data
structure: they're different each time you access them!

=head1 SEE ALSO

L<Clone>

=head1 AUTHOR

Luke Palmer <luke@luqui.org>

=head1 COPYRIGHT

    Copyright (C) 2005 by Luke Palmer

    This library is free software; you can redistribute it and/or modify it under
    the same terms as Perl itself, either Perl version 5.8.3 or, at your option,
    any later version of Perl 5 you may have available.
