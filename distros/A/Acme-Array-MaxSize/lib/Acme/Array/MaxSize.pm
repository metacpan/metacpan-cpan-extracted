package Acme::Array::MaxSize;

use 5.006;
use strict;
use warnings;

use parent 'Tie::Array';
use Carp;

my %max_size;
my $last_index = sub { $max_size{+shift} - 1 };


sub TIEARRAY {
    my ($class, $max_size) = @_;
    my $self = bless [], $class;
    $max_size{$self} = $max_size;
    return $self
}

sub STORE {
    my ($self, $index, $value) = @_;
    if ($index > $self->$last_index) {
        carp 'Array too long';
        return
    }
    $self->[$index] = $value;
}

sub FETCH {
    my ($self, $index) = @_;
    $self->[$index]
}

sub FETCHSIZE {
    my $self = shift;
    @$self
}

sub STORESIZE {
    my ($self, $count) = @_;
    if ($count > $max_size{$self}) {
        carp 'Array too long';
        $count = $max_size{$self};
    }
    $#{$self} = $count - 1;
}

sub SPLICE {
    my ($self, $offset, $length, @list) = @_;
    if ($offset > $max_size{$self}) {
        carp 'Array too long';
        return;
    }

    if ($offset + $length > $max_size{$self}) {
        carp 'Array too long';
        $length = $max_size{$self} - $offset;
    }

    my $asked = @$self - $length + @list;
    if ($asked > $max_size{$self}) {
        carp 'Array too long';
        if ($offset == 0) {
            splice @list, 0, $asked - $max_size{$self};
        } else {
            splice @list, $max_size{$self} - $asked;
        }
    }
    $self->SUPER::SPLICE($offset, $length, @list);
}


=head1 NAME

Acme::Array::MaxSize - Limit the maximal size your arrays can get.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Your array will never grow bigger over a given limit.

  use Acme::Array::MaxSize;

  tie my @short, 'Acme::Array::MaxSize', 3;
  @short = (1 .. 10);
  print "@short";  # 1 2 3

=head1 DETAILS

When adding new elements, if the maximal size is reached, all other
elements are thrown away.

  tie my @short, 'Acme::Array::MaxSize', 3;
  @short = ('a');
  push @short, 'b' .. 'h';
  print "@short";  # a b c

Inserting elements at the B<very beginning> behaves differently,
though. Each C<unshift> or C<splice> would insert the maximal possible
number of elements B<at the end> of the inserted list:

  tie my @short, 'Acme::Array::MaxSize', 3;
  @short = ('a');
  unshift @short, 'b' .. 'h';
  print "@short";  # g h a

=head1 AUTHOR

E. Choroba, C<< <choroba at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub repository
L<https://github.com/choroba/Acme-Array-MaxSize/issues>, or
C<bug-acme-array-maxsize at rt.cpan.org>, or through the web interface
at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Array-MaxSize>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Array::MaxSize


You can also look for information at:

=over 4

=item * Meta CPAN

L<https://metacpan.org/pod/Acme::Array::MaxSize>

=item * GitHub Repository

L<https://github.com/choroba/Acme-Array-MaxSize/>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Array-MaxSize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Array-MaxSize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Array-MaxSize>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Array-MaxSize/>

=back


=head1 ACKNOWLEDGEMENTS

Dedicated to L<Discipulus|http://www.perlmonks.org/?node=Discipulus>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 E. Choroba.

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

__PACKAGE__
