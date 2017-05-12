use 5.008;
use strict;
use warnings;

package Data::Semantic::URI::TestData::http;
our $VERSION = '1.100850';
# ABSTRACT: Test data class for the http URI semantic data class
no warnings 'qw';    # Possible attempt to put comments in qw() list
use constant TESTDATA => (
    {   args  => {},
        valid => [
            qw(
              http://localhost/
              http://use.perl.org/~hanekomu/journal?entry=12345
              )
        ],
        invalid => [
            qw(
              news://localhost/
              http://?123
              https://localhost/
              https://use.perl.org/~hanekomu/journal.txt#foobar
              http://use.perl.org/~hanekomu/journal.txt#foobar
              http://use.perl.org%2F~hanekomu/journal?entry=12345
              )
        ],
    },
    {   args  => { scheme => 'https?' },
        valid => [
            qw(
              http://localhost/
              http://use.perl.org/~hanekomu/journal?entry=12345
              https://localhost/
              https://use.perl.org/~hanekomu/journal?entry=12345
              )
        ],
        invalid => [
            qw(
              news://localhost/
              http://?123
              http://use.perl.org/~hanekomu/journal.txt#foobar
              https://use.perl.org/~hanekomu/journal.txt#foobar
              http://use.perl.org%2F~hanekomu/journal?entry=12345
              )
        ],
    },
    {   args  => { scheme => 'https' },
        valid => [
            qw(
              https://localhost/
              https://use.perl.org/~hanekomu/journal?entry=12345
              )
        ],
        invalid => [
            qw(
              http://localhost/
              http://use.perl.org/~hanekomu/journal?entry=12345
              http://use.perl.org/~hanekomu/journal.txt#foobar
              https://use.perl.org/~hanekomu/journal.txt#foobar
              http://use.perl.org%2F~hanekomu/journal?entry=12345
              http://?123
              news://localhost/
              )
        ],
    },
);
1;


__END__
=pod

=for stopwords http

=head1 NAME

Data::Semantic::URI::TestData::http - Test data class for the http URI semantic data class

=head1 VERSION

version 1.100850

=head1 DESCRIPTION

Defines test data for L<Data::Semantic::URI::http_TEST>, but it is also used
in the corresponding value and domain classes, i.e.,
L<Class::Value::URI::http_TEST> and L<Data::Domain::URI::http_TEST>.

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

