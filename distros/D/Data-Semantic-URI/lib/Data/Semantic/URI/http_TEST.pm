use 5.008;
use strict;
use warnings;

package Data::Semantic::URI::http_TEST;
our $VERSION = '1.100850';
# ABSTRACT: Test companion class for the http URI semantic data class
use Test::More;
use Test::Differences;
use parent qw(
  Data::Semantic::Test
  Data::Semantic::URI::TestData::http
);
use constant PLAN => 2;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    my $obj = $self->make_real_object(keep => 1);
    my $uri = 'http://use.perl.org:8081/~hanekomu/journal?entry=12345';
    ok($obj->is_valid($uri), "$uri is valid");
    my %expect = (
        abspath_full          => '/~hanekomu/journal?entry=12345',
        URI                   => $uri,
        abspath_no_query      => '~hanekomu/journal',
        query                 => 'entry=12345',
        abspath_full_no_slash => '~hanekomu/journal?entry=12345',
        scheme                => 'http',
        port                  => '8081',
        host                  => 'use.perl.org'
    );
    eq_or_diff({ $obj->kept }, \%expect, 'kept values');
}
1;


__END__
=pod

=for stopwords http

=head1 NAME

Data::Semantic::URI::http_TEST - Test companion class for the http URI semantic data class

=head1 VERSION

version 1.100850

=head1 DESCRIPTION

Test companion class for L<Data::Semantic::URI::http>. Gets its
test data from L<Data::Semantic::URI::TestData::http>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Semantic-URI>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Semantic-URI/>.

The development version lives at
L<http://github.com/hanekomu/Data-Semantic-URI/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

