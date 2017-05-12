package Apache::Emulator::Apache::TableHash;
package Apache::TableHash;
use strict;

sub TIEHASH {
    my $class = shift;
    return bless {}, ref $class || $class;
}

sub _canonical_key {
    my $key = lc shift;
    # CGI really wants a - before each header
    return substr( $key, 0, 1 ) eq '-' ? $key : "-$key";
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->{_canonical_key $key} = [ $key => ref $value ? "$value" : $value ];
}

sub add {
    my ($self, $key) = (shift, shift);
    return unless defined $_[0];
    my $value = ref $_[0] ? "$_[0]" : $_[0];
    my $ckey = _canonical_key $key;
    if (exists $self->{$ckey}) {
        if (ref $self->{$ckey}[1]) {
            push @{$self->{$ckey}[1]}, $value;
        } else {
            $self->{$ckey}[1] = [ $self->{$ckey}[1], $value ];
        }
    } else {
        $self->{$ckey} = [ $key => $value ];
    }
}

sub DELETE {
    my ($self, $key) = @_;
    my $ret = delete $self->{_canonical_key $key};
    return $ret->[1];
}

sub FETCH {
    my ($self, $key) = @_;
    # Grab the values first so that we don't autovivicate the key.
    my $val = $self->{_canonical_key $key} or return;
    if (my $ref = ref $val->[1]) {
        return unless $val->[1][0];
        # Return the first value only.
        return $val->[1][0];
    }
    return $val->[1];
}

sub get {
    my ($self, $key) = @_;
    my $ckey = _canonical_key $key;
    return unless exists $self->{$ckey};
    return $self->{$ckey}[1] unless ref $self->{$ckey}[1];
    return wantarray ? @{$self->{$ckey}[1]} : $self->{$ckey}[1][0];
}

sub CLEAR {
    %{shift()} = ();
}

sub EXISTS {
    my ($self, $key)= @_;
    return exists $self->{_canonical_key $key};
}

sub FIRSTKEY {
    my $self = shift;
    # Reset perl's iterator.
    keys %$self;
    # Get the first key via perl's iterator.
    my $first_key = each %$self;
    return undef unless defined $first_key;
    return $self->{$first_key}[0];
}

sub NEXTKEY {
    my ($self, $nextkey) = @_;
    # Get the next key via perl's iterator.
    my $next_key = each %$self;
    return undef unless defined $next_key;
    return $self->{$next_key}[0];
}

sub cgi_headers {
    my $self = shift;
    map { $_ => $self->{$_}[1] } keys %$self;
}

1;

