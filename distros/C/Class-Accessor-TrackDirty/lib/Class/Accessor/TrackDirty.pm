package Class::Accessor::TrackDirty;
use 5.008_001;
use strict;
use warnings;
use List::MoreUtils qw(any);
use Storable qw(dclone freeze);
our $VERSION = '0.11';

our $RESERVED_FIELD = '_original';
our $NEW = 'new';
our $FROM_HASH = 'from_hash';
our $RAW = 'raw';
our $TO_HASH = 'to_hash';
our $IS_MODIFIED = 'is_dirty';
our $MODIFIED_FIELDS = 'dirty_fields';
our $IS_NEW = 'is_new';
our $REVERT = 'revert';

{
    my %package_info;
    sub _package_info($) {
        my $package = shift;
        $package_info{$package} ||= {tracked_fields => {}, fields => {}};
    }
}

sub _is_different_deeply($$) {
    my ($ref_x, $ref_y) = @_;
    (freeze $ref_x) ne (freeze $ref_y);
}

sub _is_different($$) {
    my ($x, $y) = @_;
    if (defined $x && defined $y) {
        if (ref $x && ref $y) {
            return _is_different_deeply $x, $y;
        } else {
            return ref $x || ref $y || $x ne $y;
        }
    } else {
        return defined $x || defined $y;
    }
}

sub _make_tracked_accessor($$) {
    no strict 'refs';
    my ($package, $name) = @_;

    *{"$package\::$name"} = sub {
        my $self = shift;

        # getter
        my $value;
        if (exists $self->{$name}) {
            $value = $self->{$name};
        } elsif (defined $self->{$RESERVED_FIELD})  {
            $value = $self->{$RESERVED_FIELD}{$name};

            # Defensive copying
            $value = ($self->{$name} = dclone $value) if ref $value;
        }

        # setter
        $self->{$name} = $_[0] if @_;

        return $value;
    };
}

sub _make_accessor($$) {
    no strict 'refs';
    my ($package, $name) = @_;

    *{"$package\::$name"} = sub {
        my $self = shift;
        my $value = $self->{$name};
        $self->{$name} = $_[0] if @_;
        $value;
    };
}

sub _mk_tracked_accessors($@) {
    my $package = shift;
    _make_tracked_accessor $package => $_ for @_;
    @{(_package_info $package)->{tracked_fields}}{@_} = (1,) x @_;
}

sub _mk_helpers($) {
    no strict 'refs';
    my $package = shift;
    my ($tracked_fields, $fields) =
        @{_package_info $package}{qw(tracked_fields fields)};

    # cleate helper methods
    *{"$package\::$FROM_HASH"} = sub {
        my $package = shift;
        my %modified = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

        my %origin;
        for my $name (keys %$tracked_fields) {
            $origin{$name} = delete $modified{$name} if exists $modified{$name};
        }

        $modified{$RESERVED_FIELD} = \%origin;
        bless \%modified, $package;
    };

    *{"$package\::$RAW"} = sub {
        my ($self) = @_;

        my %hash = (
            (map {
                # Don't store undefined values.
                my $v = $self->$_;
                defined $v ? ($_ => $v) : ();
            } keys %$tracked_fields, keys %$fields),
        );

        return \%hash;
    };

    *{"$package\::$TO_HASH"} = sub {
        my ($self) = @_;
        my $raw = $self->$RAW;

        # Move published data for cleaning.
        $self->{$RESERVED_FIELD} ||= {};
        $self->{$RESERVED_FIELD}{$_} = delete $self->{$_}
                         for grep { exists $self->{$_} } keys %$tracked_fields;

        return $raw;
    };

    *{"$package\::$IS_MODIFIED"} = sub {
        my ($self, $field) = @_;
        return any { $self->$IS_MODIFIED($_) } keys %$tracked_fields
                                                                 unless $field;

        return unless $tracked_fields->{$field};
        return defined $self->{$field} unless defined $self->{$RESERVED_FIELD};

        exists $self->{$field} &&
               _is_different $self->{$field}, $self->{$RESERVED_FIELD}{$field};
    };

    *{"$package\::$MODIFIED_FIELDS"} = sub {
        my $self = shift;
        grep { $self->$IS_MODIFIED($_) } keys %$tracked_fields;
    };

    *{"$package\::$IS_NEW"} = sub {
        my $self = shift;
        exists $self->{$RESERVED_FIELD} ? 0 : 1;
    };

    *{"$package\::$REVERT"} = sub {
        my $self = shift;
        delete $self->{$_} for keys %$tracked_fields;
    };
}

sub _mk_accessors($@) {
    my $package = shift;
    _make_accessor $package => $_ for @_;
    @{(_package_info $package)->{fields}}{@_} = (1,) x @_;
}

sub _mk_new($) {
    no strict 'refs';
    my $package = shift;

    *{"$package\::$NEW"} = sub {
        my $package = shift;
        my %modified = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

        bless \%modified => $package;
    };
}

sub mk_tracked_accessors {
    (undef, my @tracked_fields) = @_;
    my $package = caller(0);
    _mk_tracked_accessors $package => @tracked_fields;
    _mk_helpers $package;
}

sub mk_accessors {
    (undef, my @fields) = @_;
    my $package = caller(0);
    _mk_accessors $package => @fields;
}

sub mk_new {
    my $package = caller(0);
    _mk_new $package;
}

sub mk_new_and_tracked_accessors {
    (undef, my @tracked_fields) = @_;
    my $package = caller(0);
    _mk_tracked_accessors $package => @tracked_fields;
    _mk_helpers $package;
    _mk_new $package;
}

1;
__END__

=encoding utf-8

=head1 NAME

Class::Accessor::TrackDirty - Define simple entities stored in some places.

=head1 SYNOPSIS

    package UserInfo;
    use Class::Accessor::TrackDirty;
    Class::Accessor::TrackDirty->mk_new_and_tracked_accessors("name", "password");
    Class::Accessor::TrackDirty->mk_accessors("modified");

    package main;
    my $user = UserInfo->new({name => 'honma', password => 'F!aS3l'});
    store_into_someplace($user->to_hash) if $user->is_dirty;
    # ...
    $user = UserInfo->from_hash(restore_from_someplace());
    $user->name('hiratara');
    $user->revert; # but decided not to
    $user->name('honma');
    $user->name('hiratara');
    $user->name('honma'); # I can't make up my mind...
    # ... blabla ...

    # Check the status of fields if needed
    $user->is_dirty('name') and warn "Did you change name?";
    my @dirty_fields = $user->dirty_fields;

    # Store it only if $user was really modified.
    store_into_someplace($user->to_hash) if $user->is_dirty;

=head1 DESCRIPTION

Class::Accessor::TrackDirty defines simple entities stored in files, RDBMS,
KVS, and so on. It tracks dirty columns and you can store it only when the
instance was really modified.

=head1 INTERFACE

=head2 Functions

=head3 C<< Class::Accessor::TrackDirty->mk_new; >>

Create the C<<new>> methods in your class.
You can pass a hash-ref or hash-like list to C<<new>> method.

=over 4

=item C<< my $object = YourClass->new({name1 => "value1", ...}); >>

The instance created by C<<new>> is regarded as `dirty' if it has some nonempty
fields. It's because it hasn't been stored yet.

=back

=head3 C<< Class::Accessor::TrackDirty->mk_tracked_accessors("name1", "name2", ...); >>

Create accessor methods and helper methods in your class.
Following helper methods will be created automatically.

=over 4

=item C<< $your_object->is_dirty; >>
=item C<< $your_object->is_dirty("field_name"); >>

Check that the instance is modified. If it's true, you should store this
instance into some place through using C<<to_hash>> method.

When you pass the name of a field, you can know if the field contains the same
value as the stored object.

=item C<< my @fields = $your_object->dirty_fields; >>

Gets the name of all dirty fields of C<$your_object>.

=item C<< $your_object->is_new; >>

Checks if the instance might be in a storage. Returns false value when
the instance comes from C<from_hash> method, or after you call
C<to_hash> method.

=item C<< my $hash_ref = $your_object->to_hash; >>

Eject data from this instance as plain hash-ref format.
C<<$your_object>> is regarded as `clean' after calling this method.

You'd better store C<<$hash_ref>> into some place ASAP. It's up to you how
C<<$hash_ref>> should be serialized.

=item C<< $your_object->raw; >>

Retrieves the row data from the instance. The return value is the same as
C<to_hash> method, but this method doesn't change the state of the
instance.

=item C<< my $object = YourClass->from_hash({name1 => "value1", ...}); >>

Rebuild the instance from a hash-ref ejected by C<<to_hash>> method.
The instance constructed by C<<from_hash>> is regarded as `clean'.

=item C<< $your_object->revert; >>

Revert all `dirty' changes. Fields created by C<<mk_tracked_accessors>> returns to
the point where you call C<<new>>, C<<to_hash>>, or C<<from_hash>>.

The volatile fields will be never reverted.

=back

You'd better *NOT* store references in tracked fields. Though following codes
work well, to make C<revert> work well, we'll have to copy references deeply
when you call getter.

  my $your_object = YourClass->new(some_refs => {key => 'value'});
  # some_refs are copyied deeply :(
  $your_object->some_refs->{key} = '<censored>';

  $your_object->revert;
  print $your_object->some_refs, "\n"; # printed "value"

=head3 C<< Class::Accessor::TrackDirty->mk_accessors("name1", "name2", ...); >>

Define the field which isn't tracked. You can freely change these fields,
and it will never be marked as `dirty'.

=head3 C<< Class::Accessor::TrackDirty->mk_new_and_tracked_accessors("name1", "name2", ...); >>

This method is a combination of C<<mk_tracked_accessors>> and C<<mk_new>>.

=head1 SEE ALSO

L<Class::Accessor>, L<Class::Accessor::Lite>, L<MooseX::TrackDirty::Attributes>, L<Hash::Dirty>

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Masahiro Honma. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
