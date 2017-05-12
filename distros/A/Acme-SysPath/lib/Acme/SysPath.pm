package Acme::SysPath;

use warnings;
use strict;

use Acme::SysPath::SPc;
use File::Spec;
use IO::Any;

=head1 NAME

Acme::SysPath - example distribution for Sys::Path

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

    use Acme::SysPath;
    print Acme::SysPath->config;
    print Acme::SysPath->template;
    print Acme::SysPath->image;
    use Data::Dumper; print "dump> ", Dumper(Acme::SysPath->paths), "\n";

=head1 FUNCTIONS

=head2 paths

Returns sysconfdir and datadir in a hash.

=cut

sub paths {
    return {
        'sysconfdir' => Acme::SysPath::SPc->sysconfdir,
        'datadir'    => Acme::SysPath::SPc->datadir,
    }
}

=head2 config

Returns config file name.

=cut

sub config {
    return File::Spec->catfile( Acme::SysPath::SPc->sysconfdir, 'acme-syspath.cfg' );
}

=head2 template

Return template file name.

=cut

sub template {
    return File::Spec->catfile( Acme::SysPath::SPc->datadir, 'acme-syspath', 'tt', 'index.tt2' );
}

=head2 image

Return image.

=cut

sub image {
    return IO::Any->slurp([ Acme::SysPath::SPc->datadir, 'acme-syspath', 'images', 'smile.ascii' ]);
}


=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-syspath at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-SysPath>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::SysPath


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-SysPath>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-SysPath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-SysPath>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-SysPath>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Acme::SysPath
