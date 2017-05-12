use 5.008;
use strict;
use warnings;

package Data::Storage::DBI::Mock;
BEGIN {
  $Data::Storage::DBI::Mock::VERSION = '1.102720';
}
# ABSTRACT: Base class for mock DBI storages
use parent 'Data::Storage::Mock';

sub die_on_connect {
    my $self = shift;

    # simulate the bare minimum of a ::DBH exception
    throw Error::Hierarchy::Internal::DBI::DBH(
        error  => "can't connect",
        errstr => "can't connect",
        err    => 1,
    );
}
1;


__END__
=pod

=head1 NAME

Data::Storage::DBI::Mock - Base class for mock DBI storages

=head1 VERSION

version 1.102720

=head1 METHODS

=head2 die_on_connect

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Storage>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Storage/>.

The development version lives at L<http://github.com/hanekomu/Data-Storage>
and may be cloned from L<git://github.com/hanekomu/Data-Storage>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

