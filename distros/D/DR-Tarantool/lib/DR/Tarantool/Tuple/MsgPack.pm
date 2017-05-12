use utf8;
use strict;
use warnings;

=head1 NAME

DR::Tarantool::Tuple::MsgPack - a tuple container for L<DR::Tarantool> (v >= 1.6)

=head1 SYNOPSIS

    my $tuple = new DR::Tarantool::Tuple::MsgPack::MsgPack([ 1, 2, 3]);
    my $tuple = new DR::Tarantool::Tuple::MsgPack::MsgPack([ 1, 2, 3], $space);
    my $tuple = unpack DR::Tarantool::Tuple::MsgPack::MsgPack([ 1, 2, 3], $space);


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

package DR::Tarantool::Tuple::MsgPack;
use base qw(DR::Tarantool::Tuple);

$Carp::Internal{ (__PACKAGE__) }++;


=head2 new

A constructor.

    my $t = DR::Tarantool::Tuple::MsgPack->new([1, 2, 3]);
    my $t = DR::Tarantool::Tuple::MsgPack->new([1, 2, 3], $space);

=cut

# sub new {
#     my ($class, @args) = @_;
#     return $class->SUPER::new(@args);
# }



=head2 unpack

Another way to construct a tuple.

    my $t = DR::Tarantool::Tuple::MsgPack->unpack([1, 2, 3], $space);

=cut



=head2 raw

Return raw data from the tuple.

    my $array = $tuple->raw;

    my $field = $tuple->raw(0);

=cut



=head2 next

Append or return the next tuple, provided there is more than one
tuple in the result set.

    my $next_tuple = $tuple->next;

=cut



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



=head2 tail

Return the tail of the tuple (array of unnamed fields). The function always
returns B<ARRAYREF> (as L<raw>).

=cut



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

