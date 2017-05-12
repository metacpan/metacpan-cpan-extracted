package AnyData2;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use Module::Runtime qw(require_module);

=head1 NAME

AnyData2 - access to data in many formats

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

    use AnyData2 ();

    my $ad = AnyData2->new( $src_format => { %src_format_flags },
                            $src_storage => { %src_storage_flags } );
    my $ad_out = AnyData2->new( $tgt_format => { %tgt_format_flags },
                                $tgt_storage => { %tgt_storage_flags } );
    while( my $datum = $ad->read ) {
        $ad_out->write( $datum );
    }

=head1 DESCRIPTION

The rather wacky idea behind this module is that any data, regardless of
source or format should be accessible and maybe modifiable with the same
simple set of methods.

AnyData2 is reduced to the maximum, all extended features like tied access,
import from a different source, automatic conversion on export etc. should
be done in external logic. This will make the core more maintainable.

=head1 METHODS

=head2 new

  my $af = AnyData->new(
    CSV              => {},
    "File::Linewise" => { filename => File::Spec->catfile( $test_dir, "simple.csv" ) }
  );

Instantiates a combination of AnyData::Storage and AnyData::Parser.

C<AnyData::Parser::> and C<AnyData::Storage::> are automatically prepended
when necessary.

=cut

sub new
{
    my ( $class, $fmt, $fmt_flags, $stor, $stor_flags ) = @_;
    $stor =~ m/^AnyData2::Storage::/ or $stor = "AnyData2::Storage::" . $stor;
    $fmt =~ m/^AnyData2::Format::/   or $fmt  = "AnyData2::Format::" . $fmt;
    require_module($stor);
    require_module($fmt);
    my $s = $stor->new(%$stor_flags);
    $fmt->new( $s, %$fmt_flags );
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-AnyData2 at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyData2>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyData2

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyData2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyData2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyData2>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyData2/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015,2016 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

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
direct or contributory patent infringement, then this License
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

1;    # End of AnyData2
