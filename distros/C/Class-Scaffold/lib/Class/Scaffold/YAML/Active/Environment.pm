use 5.008;
use warnings;
use strict;

package Class::Scaffold::YAML::Active::Environment;
BEGIN {
  $Class::Scaffold::YAML::Active::Environment::VERSION = '1.102280';
}
# ABSTRACT: Plugin for setting environment values
use Class::Scaffold::Environment;
use YAML::Active qw/assert_hashref hash_activate yaml_NULL/;
use parent 'Class::Scaffold::YAML::Active';

sub yaml_activate {
    my ($self, $phase) = @_;
    assert_hashref($self);
    my $hash = hash_activate($self, $phase);
    my $env = Class::Scaffold::Environment->getenv;
    while (my ($key, $value) = each %$hash) {
        $env->{$key} = $value;
    }
    yaml_NULL();
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::YAML::Active::Environment - Plugin for setting environment values

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 yaml_activate

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

