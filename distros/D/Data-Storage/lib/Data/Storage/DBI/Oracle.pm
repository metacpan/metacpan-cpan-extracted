use 5.008;
use strict;
use warnings;

package Data::Storage::DBI::Oracle;
BEGIN {
  $Data::Storage::DBI::Oracle::VERSION = '1.102720';
}
# ABSTRACT: Base class for Oracle DBI storages
use parent 'Data::Storage::DBI';

sub connect_string {
    my $self = shift;
    sprintf("dbi:Oracle:%s", $self->dbname);
}

# Database type-specifc rewrites
sub rewrite_query_for_dbd {
    my ($self, $query) = @_;
    $query =~ s/<USER>/user/g;
    $query =~ s/<NOW>/sysdate/g;
    $query =~ s/<NEXTVAL>\((.*?)\)/$1.NEXTVAL/g;
    $query =~ s/<BOOL>\((.*?)\)/sprintf "DECODE(%s, '%s', 1, '%s', 0)", $1,
        $self->delegate->YES, $self->delegate->NO
    /eg;
    $query;
}
1;


__END__
=pod

=head1 NAME

Data::Storage::DBI::Oracle - Base class for Oracle DBI storages

=head1 VERSION

version 1.102720

=head1 METHODS

=head2 connect_string

FIXME

=head2 rewrite_query_for_dbd

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

