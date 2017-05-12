package Atompub::Util;

use warnings;
use strict;

use Atompub;
use Atompub::MediaType qw(media_type);
use Perl6::Export::Attrs;
use XML::Atom::Category;

sub is_acceptable_media_type :Export {
    my($coll, $content_type) = @_;

    return 1 unless $coll;

    my @accepts = map { split /[\s,]+/ } $coll->accept;
    @accepts = (media_type('entry')) unless @accepts; # assign default type

    grep { media_type($content_type)->is_a($_) } @accepts;
}

sub is_allowed_category :Export {
    my($coll, @tests) = @_;

    return 1 unless $coll;
    return 1 unless $coll->categories;

    return 1 if grep { ! $_->fixed || $_->fixed ne 'yes' } $coll->categories;

    my @allowed;
    for my $cats ($coll->categories) {
	push @allowed, map { my $cat = XML::Atom::Category->new;
			     my $scheme = $_->scheme || $cats->scheme;
			     $cat->term($_->term);
			     $cat->scheme($scheme) if $scheme;
			     $cat }
	                   $cats->category;
    }

    return 0 if ! @allowed && @tests;

    for my $t (@tests) {
	return 0 unless grep { _match_category($_, $t) } @allowed;
    }

    1;
}

sub _match_category {
    my($allowed, $test) = @_;
    return $allowed->term eq $test->term
	&& (!$allowed->scheme || $test->scheme && $allowed->scheme eq $test->scheme);
}

1;
__END__

=head1 NAME

Atompub::Util - Utility functions

=head1 FUNCTIONS

=head2 is_acceptable_media_type($collection, $content_type)

=head2 is_allowed_category($collection, $category, ...)

=head1 INTERNAL INTERFACES

=head2 _match_category


=head1 SEE ALSO

L<Atompub>


=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
