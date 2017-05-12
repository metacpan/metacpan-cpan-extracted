package Data::CircularList;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::CircularList::Cell;
use Data::CircularList::Iterator;
use parent qw/Class::Accessor/;
__PACKAGE__->mk_accessors(qw/header/);
use Scalar::Util qw/blessed/;
use Carp;
sub DEBUG() {0}; # {0} when done

=head1 NAME

Data::CircularList - simple implementation for using CircularList data structure.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::CircularList;

    my $list = Data::CircularList->new;
    $list->insert(20);
    $list->insert(15);
    $list->insert(18);
    $list->insert(37);
    $list->insert(3);

    # display
    my $iter = $list->iterator;
    while ($iter->has_next) {
       print $iter->next->data . "\n";
    }
    # you can see result sorted
    # 3
    # 15
    # 18
    # 20
    # 37
    #  3  <= 1st value is displayed
    # 15     eternal loop
    ...
    
    # rotate display
    my $iter = $list->iterator( rotate => 2 );
    while ($iter->has_next) {
       print $iter->next->data . "\n";
    }
    # you can see result sorted
    # 3
    # 15
    # 18
    # 20
    # 37
    #  3
    # 15
    # 18
    # 20
    # 37 <= end. $iter->has_next return true until second rotation completed.
    
    # you can also use strings as cells
    $list = Data::CircularList->new;
    $list->insert('steeve');
    $list->insert('hisashi');
    $list->insert('takairo');
    $list->insert('kazuyo');
    $list->insert('jane');
    
    # display
    $iter = $list->iterator;
    while ($iter->has_next) {
       print $iter->next->data . "\n";
    }
    # you can see result sorted
    # hisashi
    # jane
    # kazuyo
    # steeve
    # takahiro
    # hisashi  <= 1st value is displayed
    # jane        eternal loop
    ...

    # display
    $iter = $list->iterator( rotate => 2 );
    while ($iter->has_next) {
       print $iter->next->data . "\n";
    }
    # you can see result sorted
    # hisashi
    # jane
    # kazuyo
    # steeve
    # takahiro
    # hisashi
    # jane
    # kazuyo
    # steeve
    # takahiro <= end. $iter->has_next return true until second rotation completed.

    # you can also use some object as cells
    $list = Data::CircularList->new;
    $list->insert(Person->new(name => 'lally'));
    $list->insert(Person->new(name => 'hisashi'));
    $list->insert(Person->new(name => 'takairo'));
    $list->insert(Person->new(name => 'kazuyo'));
    $list->insert(Person->new(name => 'jane'));
    
    # you have to implements compare_to method in you object.
    # you have to write sort logic in compare_to method.
    package Person;

    sub new {
        my $class = shift;
        my %args = @_;
        my $self = {
            name => $args{'name'},
            length => length($args{'name'}),
        };
        bless $self => $class;
        $self->length(length($args{'name'}));
        return $self;
    }

    # sort by length of name, and name
    sub compare_to {
        my $self = shift;
        my $cell = shift;

        if ($self->length > $cell->length) {
            return 1;
        } elsif ($self->length == $cell->length) {
            return $self->name gt $cell->name ? 1 : 0;
        } else {
            return 0;
        }
    }

    sub name {
        my $self = shift;
        return defined $self->{'name'} ? $self->{'name'} : undef;
    }

    sub length {
        my $self = shift;
        return defined $self->{'length'} ? $self->{'length'} : undef;
    }

=head1 SUBROUTINES/METHODS

=head2 new

constructor. Any arguments don't require.

=cut

sub new {
    my $class = shift;
    my $self = {};
    $self->{'header'} = Data::CircularList::Cell->new("!!Circular List Header!"),
    $self->{'header'}->next($self->{'header'}),
    bless $self => $class;
    return $self;
}

=head2 insert($cell)

insert a cell on the circular linked list.
You can see SYNOPSIS as a example.

=cut

sub insert {
    my $self = shift;
    my $cell = shift;
    $cell = Data::CircularList::Cell->new($cell);

    my $p = $self->header->next;
    my $q = $self->header;

    if ($p ne $q) {
        while (defined($p) && $p->can('data') && $cell->compare_to($p->data) > 0) {
            $q = $p;
            $p = $p->next;
            last if !blessed($p->data);
        }
    }

    my $new_cell = Data::CircularList::Cell->new($cell);
    $new_cell->next($p);
    $q->next($new_cell);
}

=head2 iterator

get a iterator to traverse the circular linked list.
You can see SYNOPSIS as a example.

=cut

sub iterator {
    my $self = shift;
    my %args = @_;
    my $rotate = defined $args{'rotate'} ? $args{'rotate'} : undef;
    my $iter = Data::CircularList::Iterator->new($self, $rotate);
    return $iter;
}

# free memory of cicular data
sub DESTROY {
    my $self = shift;
    delete $self->{'header'};
    if (DEBUG) {
        carp "destroying $self\n";
    }
}

=head1 AUTHOR

shinchit, C<< <shinchi.xx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datastructure-circularlist at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-CircularList>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::CircularList


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-CircularList>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-CircularList>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-CircularList>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-CircularList/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 shinchit.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Data::CircularList
