# NAME

Config::Micro - micro config loader

# VERSION

Version 0.02

# SYNOPSIS

    package Your::App::Class;
    use Config::Micro;
    use File::Spec;
    

    my $conf_dir  = File::Spec->catdir(qw/.. etc/);
    my $conf_file = Config::Micro->file( env => 'development', dir => $conf_dir );
    my $config = require( $conf_file );
    ...

# SUBROUTINES/METHODS

## file

Return a path of config file that matches for application environment.

You may specify following options.

- env

    Specifier for deploy environment.

    Default is $ENV{PLACK\_ENV} || 'development' .

- dir

    Specifier for dir of config file.

    Default is '../etc' .

# AUTHOR

ytnobody, `<ytnobody aaaattttt gmail>`

# BUGS

Please report any bugs or feature requests to `bug-config-micro at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Micro](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Micro).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.







# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Micro



You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Micro](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Micro)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Config-Micro](http://annocpan.org/dist/Config-Micro)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Config-Micro](http://cpanratings.perl.org/d/Config-Micro)

- Search CPAN

    [http://search.cpan.org/dist/Config-Micro/](http://search.cpan.org/dist/Config-Micro/)



# ACKNOWLEDGEMENTS



# LICENSE AND COPYRIGHT

Artistic

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic\_license\_2\_0)

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


