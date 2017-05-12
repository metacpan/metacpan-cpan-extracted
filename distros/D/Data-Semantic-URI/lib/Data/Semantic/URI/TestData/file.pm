use 5.008;
use strict;
use warnings;

package Data::Semantic::URI::TestData::file;
our $VERSION = '1.100850';
# ABSTRACT: Test data class for the file URI semantic data class
no warnings 'qw';    # Possible attempt to put comments in qw() list
use constant TESTDATA => (
    {   args  => {},
        valid => [
            qw(
              file://localhost/
              file://use.perl.org/hanekomu/journal
              file:///Users/marcel/file.txt
              )
        ],
        invalid => [
            qw(
              news://localhost/
              file://?123
              http://use.perl.org/hanekomu/journal?entry=12345
              http://use.perl.org/~hanekomu/journal
              file:///Users/marcel/file.txt#foobar
              )
        ],
    },
);
1;


__END__
=pod

=head1 NAME

Data::Semantic::URI::TestData::file - Test data class for the file URI semantic data class

=head1 VERSION

version 1.100850

=head1 DESCRIPTION

Defines test data for L<Data::Semantic::URI::file_TEST>, but it is also used
in the corresponding value and domain classes, i.e.,
L<Class::Value::URI::file_TEST> and L<Data::Domain::URI::file_TEST>.

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

