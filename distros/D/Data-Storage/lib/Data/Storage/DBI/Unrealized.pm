use 5.008;
use strict;
use warnings;

package Data::Storage::DBI::Unrealized;
BEGIN {
  $Data::Storage::DBI::Unrealized::VERSION = '1.102720';
}
# ABSTRACT: Proxy class for lazy DBI connections
use parent 'Class::Accessor::Complex';
__PACKAGE__
    ->mk_new
    ->mk_scalar_accessors(qw(callback));
use constant DEFAULTS               => ();
use constant FIRST_CONSTRUCTOR_ARGS => ();

sub AUTOLOAD {
    my $self = shift;
    (my $method = our $AUTOLOAD) =~ s/.*://;
    $self->callback->connect;
    $self->callback->dbh->$method(@_);
}
1;


__END__
=pod

=head1 NAME

Data::Storage::DBI::Unrealized - Proxy class for lazy DBI connections

=head1 VERSION

version 1.102720

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

