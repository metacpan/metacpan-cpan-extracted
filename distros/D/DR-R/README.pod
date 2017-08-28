package DR::R;

use 5.010001;
use strict;
use utf8;
use warnings;

use Carp;
our $VERSION = '0.03';

require XSLoader;
XSLoader::load('DR::R', $VERSION);

sub select :method {
    my ($self, $type, $point_or_rect, %opts) = @_;

    my $offset = $opts{offset} || 0;
    my $limit = $opts{limit};
    my @result;

    my $type_ok = 0;
    $type //= '';
    for (@{ $self->iterator_types }) {
        if ($type eq $_) {
            $type_ok = 1;
            last;
        }
    }
    croak "Unknown iterator type: '$type'" unless $type_ok;
    unless ($self->is_point_or_rect($point_or_rect)) {
        croak "Invalid point or rect";
    }


    $self->foreach($type, $point_or_rect, sub {
        my ($o, $id, $toffset) = @_;

        return if $toffset < $offset;
        push @result => $o;
        return unless defined $limit;
        return if @result < $limit;
        return 0;
    });
    return \@result;
}

1;
__END__
=head1 NAME

DR::R - Tarantool's RTREE implementation

=head1 SYNOPSIS

  use DR::R;
  
  my $tree = new DR::R dimension => 2, dist_type => 'EUCLID';

  $tree->insert([1.2, 2.2], 1);
  $tree->insert([2.3, -2.1], 2);
  ...

  $tree->foreach(NEIGHBOR => [ 1, 2 ], sub {
        my ($p) = @_;
        print "%s is neighbour to [1:2]\n", $p;

        return 1;   # continue iteration
  });

=head1 DESCRIPTION

The module includes XS for L<tarantool|http://tarantool.org> RTREE index.


=head2 Points and Rects

Point - is an array of numbers (C<double>) with C<size=$dimension>).

Rect - is an array of numbers (C<double> with C<size=2 * $dimension>).

Index always uses Rect objects, so if You use points, index converts
your points to rects.

=head3 Examples

    my $point2d = [ $x, $y ];
    my $point2d = [ $x, $y, $x, $y ]; # the same


    my $rect2d = [ $x1, $y1, $x2, $y2];


=head1 METHODS

=head2 new (constructor)

    my $tree = DR::R->new(%opts);

=head3 Constructor options.

=over

=item dimension

Dimension for RTREE. Default value is C<2>. Can have value between
C<1> AND C<20>.

=item dist_type

Algorithm to calc distance between objects. Default value is C<EUCLID>.
Can have value:

=over

=item EUCLID

=item MANHATTAN

=back

=back


=head2 insert

    my $id = $tree->insert([1,2,3,4], $order);

Insert object to tree. Return object's index ID.

=head2 remove

    $tree->remove([1,2,3,4], $id);

Remove objects from tree. Return found object or C<undef>.


=head2 foreach

Iterate through tree.

    $tree->foreach($TYPE, $point_or_rect, sub {
        my ($object) = @_;

        if (you_want_stop_iteration) {
            return 0;
        } else {
            return 1;
        }
    });

Iterators can have the following types:

=over

=item EQ

Itearate records with the same rectangle.

=item NEIGHBOR

Itearate nearest records from a given point (the point is
acluattly lowest_point of given rectangle). Records are iterated in
order of distance to given point. Yes, it is KNN iterator.

=item CONTAINS

Itearate records that contain given rectangle.

=item CONTAINS!

Itearate records that strictly contain given rectangle.

=item OVERLAPS

Itearate records that overlaps with given rectangle.

=item BELONGS

Itearate records that belongs to given rectangle.

=item BELONGS!

Itearate records that strictly belongs to given rectangle.

=item ALL

Itearate all records.

=back


=head2 select

    my $array_ref = $tree->select(NEIGHBOR => $point_or_rect,
                    limit => $limit,
                    offset => $offset
                );

Based on L</foreach> select.

Run selected iterator until C<limit> reached, since C<offset> started.
Default value for C<offset> option is C<0>.
There is no default value for C<limit> option.



=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Dmitry E. Oboukhov (the perl module).

Tarantool is a collective effort, and incorporates
many contributions from the community.

Below follows a list of people, who contributed their code.

Aleksandr Lyapunov, Aleksey Demakov, Aleksey Mashanov, Alexandre Kalendarev,
Andrey Drozdov, Anton Barabanov, Damien Lefortier, Dmitry E. Oboukhov,
Dmitry Simonenko, Elena Shebunyaeva, Eugene Blikh, Eugene Shadrin,
Georgy Kirichenko, Konstantin Knizhnik, Konstantin Nazarov, Konstantin Osipov,
Konstantin Shulgin, Mons Anderson, Marko Kevac, Nick Zavaritsky, Oleg Tsarev,
Pavel Cherenkov, Roman Antipin, Roman Tokarev, Roman Tsisyk, Teodor Sigaev,
Timofey Khryukin, Veniamin Gvozdikov, Vassiliy Soshnikov, Vladimir Rudnyh,
Yuriy Nevinitsin, Yuriy Vostrikov.


Copyright 2010-2017 Tarantool authors.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

=over

=item 1

Redistributions of source code must retain the above
copyright notice, this list of conditions and the
following disclaimer.

=item 2

Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials
provided with the distribution.

=back

THIS SOFTWARE IS PROVIDED BY AUTHORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
AUTHORS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

=cut
