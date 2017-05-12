use utf8;
use strict;
use warnings;

=head1 NAME

DR::Tarantool::Tuple - a tuple container for L<DR::Tarantool>

=head1 SYNOPSIS

    my $tuple = new DR::Tarantool::Tuple([ 1, 2, 3]);
    my $tuple = new DR::Tarantool::Tuple([ 1, 2, 3], $space);
    my $tuple = unpack DR::Tarantool::Tuple([ 1, 2, 3], $space);


    $tuple->next( $other_tuple );

    $f = $tuple->raw(0);

    $f = $tuple->name_field;


=head1 DESCRIPTION

A tuple contains normalized (unpacked) fields. You can access the fields
by their indexes (see L<raw> function) or by their names (if they are
described in the space).

Each tuple can contain references to L<next> tuple and L<iter>ator,
so that if the server returns more than one tuple, all of them
can be accessed.

=head1 METHODS

=cut

package DR::Tarantool::Tuple;
use DR::Tarantool::Iterator;
use Scalar::Util 'weaken', 'blessed';
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;


=head2 new

A constructor.

    my $t = DR::Tarantool::Tuple->new([1, 2, 3]);
    my $t = DR::Tarantool::Tuple->new([1, 2, 3], $space);

=cut

sub new :method {
    my ($class, $tuple, $space) = @_;

    $class = ref $class if ref $class;

    # hack to replace default autoload
    $class = $space->tuple_class if $space and $class eq __PACKAGE__;

    croak 'wrong space' if defined $space and !blessed $space;

    croak 'tuple must be ARRAYREF [of ARRAYREF]' unless 'ARRAY' eq ref $tuple;
    croak "tuple can't be empty" unless @$tuple;

    $tuple = [ $tuple ] unless 'ARRAY' eq ref $tuple->[0];

    my $iterator = DR::Tarantool::Iterator->new(
        $tuple,
        data                => $space,
        item_class          => ref($class) || $class,
        item_constructor    => '_new'
    );

    return bless {
        idx         => 0,
        iterator    => $iterator,
    } => ref($class) || $class;
}


sub _new {
    my ($class, $item, $idx, $iterator) = @_;
    return bless {
        idx         => $idx,
        iterator    => $iterator,
    } => ref($class) || $class;
}


=head2 unpack

Another way to construct a tuple.

    my $t = DR::Tarantool::Tuple->unpack([1, 2, 3], $space);

=cut

sub unpack :method {
    my ($class, $tuple, $space) = @_;
    croak 'wrong space' unless blessed $space;
    return undef unless defined $tuple;
    croak 'tuple must be ARRAYREF [of ARRAYREF]' unless 'ARRAY' eq ref $tuple;
    return undef unless @$tuple;

    if ('ARRAY' eq ref $tuple->[0]) {
        my @tu;

        push @tu => $space->unpack_tuple($_) for @$tuple;
        return $class->new(\@tu, $space);
    }

    return $class->new($space->unpack_tuple($tuple), $space);
}


=head2 raw

Return raw data from the tuple.

    my $array = $tuple->raw;

    my $field = $tuple->raw(0);

=cut

sub raw :method {
    my ($self, $fno) = @_;

    my $item = $self->{iterator}->raw_item( $self->{idx} );

    return $item unless defined $fno;

    croak 'wrong field number' unless $fno =~ /^-?\d+$/;

    return undef if $fno < -@$item;
    return undef if $fno >= @$item;
    return $item->[ $fno ];
}


=head2 next

Append or return the next tuple, provided there is more than one
tuple in the result set.

    my $next_tuple = $tuple->next;

=cut

sub next :method {

    my ($self, $tuple) = @_;

    my $iterator = $self->{iterator};
    my $idx = $self->{idx} + 1;

    # if tuple is exists next works like 'iterator->push'
    if ('ARRAY' eq ref $tuple) {
        $iterator->push( $tuple );
        $idx = $iterator->count - 1;
    }

    return undef unless $idx < $iterator->count;

    my $next = bless {
        idx         => $idx,
        iterator    => $iterator,
    } => ref($self);

    return $next;
}


=head2 iter

Return an iterator object associated with the tuple.


    my $iterator = $tuple->iter;

    my $iterator = $tuple->iter('MyTupleClass', 'new');

    while(my $t = $iterator->next) {
        # the first value of $t and $tuple are the same
        ...
    }

=head3 Arguments

=over

=item package (optional)

=item method (optional)

If 'package' and 'method' are present, $iterator->L<next> method
constructs objects using C<< $package->$method( $next_tuple ) >>

If 'method' is not present and 'package' is present, the iterator
blesses the  raw array with 'package'.

=back

=cut

sub iter :method {
    my ($self, $class, $method) = @_;

    my $iterator = $self->{iterator};

    if ($class) {
        return $self->{iterator}->clone(
            item_class => $class,
            item_constructor => sub {
                my ($c, $item, $idx) = @_;

                if ($method) {
                    my $bitem = bless {
                        idx => $idx,
                        iterator => $iterator,
                    } => ref($self);


                    return $c->$method( $bitem );
                }
                return bless [ @$item ] => ref($c) || $c;
            }
        );
    }

    return $self->{iterator};
}


=head2 tail

Return the tail of the tuple (array of unnamed fields). The function always
returns B<ARRAYREF> (as L<raw>).

=cut

sub tail {
    my ($self) = @_;
    my $space = $self->{iterator}->data;
    my $raw = $self->raw;

    return [ @$raw[ $space->tail_index .. $#$raw ] ] if $space;
    return $raw;
}



sub DESTROY {  }


=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=head1 VCS

The project is placed git repo on github:
L<https://github.com/dr-co/dr-tarantool/>.

=cut

1;
