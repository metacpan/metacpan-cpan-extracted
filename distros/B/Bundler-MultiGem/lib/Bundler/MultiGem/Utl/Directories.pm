package Bundler::MultiGem::Utl::Directories;

use 5.006;
use strict;
use warnings;

=head1 NAME

Bundler::MultiGem::Util::Directories - Wrapper of utility functions for directories

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use Exporter qw(import);
our @EXPORT = qw(mk_dir rm_dir);

use File::Path qw( make_path remove_tree );

=head1 SYNOPSIS

Wrapper of utility functions for directories

    use Bundler::MultiGem::Directories qw(mk_dir rm_dir);

    mk_dir($path); # create path if not exists
    rm_dir($path); # remove path if exists

=head1 EXPORT

=head2 mk_dir

creates a path if not exists

=cut

sub mk_dir {
  my $dir = shift;
  if ( !-d $dir ) {
    make_path $dir or die "Failed to create path: ${dir}";
  }
}

=head2 rm_dir

removes a path if exists

=cut

sub rm_dir {
  my $dir = shift;
  if ( -d $dir ) {
    remove_tree $dir or die "Failed to remove path: ${dir}";
  }
}

=head1 AUTHOR

Mauro Berlanda, C<< <kupta at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/mberlanda/Bundler-MultiGem/issues>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bundler::MultiGem::Directories


You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bundler-MultiGem>

=item * Github Repository

L<https://github.com/mberlanda/Bundler-MultiGem>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Mauro Berlanda.

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

1;
