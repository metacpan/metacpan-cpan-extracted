package Cache::Memcached::Indexable;

use strict;
use warnings;
use UNIVERSAL::require;
use Carp;

our $VERSION = '0.03';
our $DEFAULT_LOGIC = 'Cache::Memcached::Indexable::Logic::Default';

sub new {
    my($class, $args) = @_;
    my $self = bless $args, $class;

    if (exists $self->{logic}) {
        my $logic      = delete $self->{logic};
        my $logic_args = delete $self->{logic_args};
        $self->set_logic($logic, $logic_args);
    }

    my $memd;
    if (exists $self->{memd}) {
        $memd = delete $self->{memd};
    }
    my %memd_args = map { $_ => $self->{$_} } keys %$self;
    $self->{_memd_args} = \%memd_args;

    if ($memd) {
        $self->set_memd($memd, $self->{_memd_args});
    }

    return $self;
}

sub logic {
    my $self = shift;
    if (my $logic = $self->{_logic}) {
        return $logic;
    }
    $self->set_logic($DEFAULT_LOGIC);
}

sub set_logic {
    my $self  = shift;
    my $class = shift;
    if (ref($class)) {
        $self->{_logic} = $class;
    }
    else {
        $class->use or croak $@;
        my $logic = $class->new(@_);
        $self->{_logic} = $logic;
    }
    return $self->{_logic};
}

sub memd {
    my $self = shift;
    if (my $memd = $self->{_memd}) {
        return $memd;
    }
    $self->set_memd('Cache::Memcached', $self->{_memd_args});
}

sub set_memd {
    my $self  = shift;
    my $class = shift;
    if (ref($class)) {
        $self->{_memd} = $class;
    }
    else {
        $class->use or croak $@;
        my $memd = $class->new(@_);
        $self->{_memd} = $memd;
    }
    return $self->{_memd};
}

sub set_servers { shift->memd->set_servers(@_) }

sub set_debug { shift->memd->set_debug(@_) }

sub set_readonly { shift->memd->set_readonly(@_) }

sub set_norehash { shift->memd->set_norehash(@_) }

sub set_compress_threshold { shift->memd->set_compress_threshold(@_) }

sub enable_compress { shift->memd->enable_compress(@_) }

sub get {
    my($self, $key) = @_;
    my $r = $self->get_multi($key);
    my $kval = ref($key) ? $key->[1] : $key;
    return $r->{$kval};
}

sub get_multi {
    my $self = shift;

    my %val = ();
    my $logic = $self->logic;
    my $memd  = $self->memd;

    for my $key (@_) {
        my $branch_key = $logic->branch_key($key);
        my $stored = $memd->get($branch_key);
        unless ($stored && ref($stored) eq 'HASH') {
            $val{$key} = ();
            next;
        }
        my $value = $stored->{$key};
        next unless defined $value;
        if (ref($value) eq 'ARRAY') {
            my $expires = $value->[1];
            if ($expires && time() > $expires) {
                $self->delete($key);
                $val{$key} = ();
                next;
            }
            $val{$key} = $value->[0];
            next;
        }
        $val{$key} = $value;
    }

    if ($memd->{'debug'}) {
        while (my($k, $v) = each %val) {
            print STDERR "MemCache-Indexable: got $k = $v\n";
        }
    }

    return \%val;
}

sub _exists {
    my($self, $key) = @_;

    my $logic = $self->logic;
    my $memd  = $self->memd;

    my $branch_key = $logic->branch_key($key);
    my $stored = $memd->get($branch_key);
    return unless $stored && ref($stored) eq 'HASH';

    my $value = $stored->{$key};
    return unless defined $value;

    return defined $value unless ref($value) eq 'ARRAY';

    my $expires = $value->[1];
    if ($expires && time() > $expires) {
        $self->delete($key);
        return;
    }
    return defined $value->[0];
}

sub set {
    my($self, $key, $value, $exptime) = @_;

    my $check = $self->__deleted_keys_as_hashref;
    if ($check->{$key}) {
        $self->delete($key);
        return;
    }

    my $set_value = $exptime ? [ $value, (time() + $exptime) ] : $value;

    my $memd  = $self->memd;
    my $logic = $self->logic;
    my $branch_key = $logic->branch_key($key);
    my $stored = $memd->get($branch_key);

    unless ($stored && ref($stored) eq 'HASH') {
        $stored = {};
    }
    $stored->{$key} = $set_value;
    return $memd->set($branch_key => $stored);
}

sub add {
    my $self = shift;
    my($key) = @_;
    return if $self->_exists($key);
    return $self->set(@_);
}

sub replace {
    my $self = shift;
    my($key) = @_;
    return unless $self->_exists($key);
    return $self->set(@_);
}

sub delete {
    my($self, $key, $exptime) = @_;

    my $memd  = $self->memd;
    my $logic = $self->logic;
    my $branch_key = $logic->branch_key($key);
    my $stored = $memd->get($branch_key);
    my $result;
    if ($stored && ref($stored) eq 'HASH') {
        my $deleted = delete $stored->{$key};
        $result = defined $deleted;
        $memd->set($branch_key => $stored) if $result;
    }
    else {
        $memd->set($branch_key => {});
    }

    if ($exptime) {
        $self->_set_delete_expires($key => $exptime);
    }

    return $result ? $result : ();
}

sub incr {
    my($self, $key, $value) = @_; # XXX a simple emulation of original incr()
    $value = 1 unless defined $value;
    $self->replace($key => $self->get($key) + $value);
}

sub decr {
    my($self, $key, $value) = @_; # XXX a simple emulation of original decr()
    $value = 1 unless defined $value;
    $self->replace($key => $self->get($key) - $value);
}

sub stats { shift->memd->stats(@_) }

sub disconnect_all { shift->memd->disconnect_all(@_) }

sub flush_all { shift->memd->flush_all(@_) }

sub keys {
    my $self = shift;

    my $memd  = $self->memd;
    my $logic = $self->logic;

    my $deleted = $self->__deleted_keys_as_hashref;

    my @keys = ();
    for my $trunk_key ($logic->trunk_keys) {
        my $stored = $memd->get($trunk_key);
        if ($stored && ref($stored) eq 'HASH') {
            push(@keys, (grep { ! $deleted->{$_} } keys %$stored));
        }
    }
    return @keys;
}

sub _set_delete_expires {
    my($self, $key, $exptime) = @_;

    my $memd = $self->memd;
    my $deleted_key = $self->logic->_deleted_key;
    my $deleted = $self->memd->get($deleted_key);
    unless ($deleted && ref($deleted) eq 'HASH') {
        $deleted = {};
    }
    $deleted->{$key} = time() + $exptime;
    $memd->set($deleted_key => $deleted);
}

sub _deleted_keys {
    my $self = shift;

    my $memd = $self->memd;
    my $deleted_key = $self->logic->_deleted_key;
    my $deleted = $self->memd->get($deleted_key);
    return unless $deleted && ref($deleted) eq 'HASH';

    my %new = ();
    my @deleted_keys = ();

    for my $key (CORE::keys %$deleted) {
        next if $deleted->{$key} < time();
        push @deleted_keys, $key;
        $new{$key} = $deleted->{$key};
    }
    $memd->set($deleted_key => \%new);
    return @deleted_keys;
}

sub __deleted_keys_as_hashref {
    my $self = shift;
    return +{ map { $_ => 1 } $self->_deleted_keys };
}

1;
__END__

=head1 NAME

Cache::Memcached::Indexable - A key indexable Cache::Memcached wrapper

=head1 SYNOPSIS

 use Cache::Memcached::Indexable;
 
 $memd = new Cache::Memcached::Indexable {
     'servers' => [ "10.0.0.15:11211", "10.0.0.15:11212",
                    "10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
     'debug' => 0,
     'compress_threshold' => 10_000,
 };
 $memd->set_servers($array_ref);
 $memd->set_compress_threshold(10_000);
 $memd->enable_compress(0);
 
 $memd->set("my_key", "Some value");
 $memd->set("object_key", { 'complex' => [ "object", 2, 4 ]});
 
 $val = $memd->get("my_key");
 $val = $memd->get("object_key");
 if ($val) { print $val->{'complex'}->[2]; }
 
 $memd->incr("key");
 $memd->decr("key");
 $memd->incr("key", 2);
 
 @all_keys = $memd->keys;

=head1 DESCRIPTION

B<THIS IS ALPHA SOFTWARE>

Cache::Memcached::Indexable is a key indexable memcached interface.
It is a simple wrapper class of L<Cache::Memcached>.
Usually, we can't get any key information of stored data with using memcached.
This module provides C<keys()> method (likes C<CORE::keys()>) for getting
all of stored key information.

In fact, this module uses only a few patterns of knowable key,
and it stores the key with the value of large hash-ref.
It controls the large hash-ref when you call set, get or delete methods.

It was implantated some functions of Cache::Memcached.
But the implanted functions are only documented functions.
Note that some undocumented functions weren't implanted to this module.

=head1 CONSTRUCTOR

=over 4

=item C<new>

Takes one parameter, a hashref of options.
Almost same as L<Cache::Memcached>'s constructor.
But it has some additional parameter.

=over 4

=item * logic

The parameter of C<logic> is the name of your chosen logic class or
the entity of the logic class instance.

 $memd = Cache::Memcached::Indexable->new({
     logic      => 'Cache::Memcached::Indexable::Logic::DigestSHA1',
     logic_args => { set_max_power => 0xFF },
     %memcached_args,
 })

and the following code is same as above:

 use Cache::Memcached::Indexable::Logic::DigestSHA1;

 $logic = Cache::Memcached::Indexable::Logic::DigestSHA1->new({
     set_max_power => 0xFF,
 });
 
 $memd = Cache::Memcached::Indexable->new({
     logic => $logic,
     %memcached_args,
 });

=item * logic_args

The arguments of your specified logic class (see above.)

=item * memd

You may specify your favorite memcached interface class.
But it must have Cache::Memcached compatibility (e.g. L<Cache::Memcached::XS>).

=back

=back

=head1 METHODS

=head2 keys()

You can get all of stored keys with calling this method.


And the usage of following methods. See L<Cache::Memcached> document.

=over 4

=item C<set_servers>

=item C<set_debug>

=item C<set_readonly>

=item C<set_norehash>

=item C<set_compress_threshold>

=item C<enable_compress>

=item C<get>

=item C<get_multi>

=item C<set>

=item C<add>

=item C<replace>

=item C<delete>

=item C<incr>

=item C<decr>

=item C<stats>

=item C<disconnect_all>

=item C<flush_all>

=back

=head1 WARRANTY

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
PURPOSE.

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Cache::Memcached>,
L<Cache::Memcached::Indexable::Logic>,
L<Cache::Memcached::Indexable::Logic::Default>

=cut
