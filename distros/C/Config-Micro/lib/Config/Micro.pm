package Config::Micro;

use strict;
use warnings FATAL => 'all';
use File::Spec;
use File::Basename 'dirname';

=head1 NAME

Config::Micro - micro config loader

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    package Your::App::Class;
    use Config::Micro;
    use File::Spec;
    
    my $conf_dir  = File::Spec->catdir(qw/.. etc/);
    my $conf_file = Config::Micro->file( env => 'development', dir => $conf_dir );
    my $config = require( $conf_file );
    ...

=head1 SUBROUTINES/METHODS

=head2 file

Return a path of config file that matches for application environment.

You may specify following options.

=over 4

=item env

Specifier for deploy environment.

Default is $ENV{PLACK_ENV} || 'development' .

=item dir

Specifier for dir of config file.

Default is '../etc' .

=back

=cut

sub file {
    my ($class, %opts) = @_;
    $opts{env} ||= $ENV{PLACK_ENV} || 'development';
    $opts{dir} ||= File::Spec->catdir('..', 'etc'); 
    my ($caller_class, $caller_file, $line) = caller();
    my $basedir = dirname($caller_file);
    my $confdir = File::Spec->file_name_is_absolute($opts{dir}) ? 
        $opts{dir} : 
        File::Spec->catdir($basedir, $opts{dir})
    ;
    return File::Spec->catfile($confdir, $opts{env}. '.pl');
}

=head1 AUTHOR

ytnobody, C<< <ytnobody aaaattttt gmail> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-micro at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Micro>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Micro


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Micro>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Micro>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Micro>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Micro/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Artistic

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

1; # End of Config::Micro
