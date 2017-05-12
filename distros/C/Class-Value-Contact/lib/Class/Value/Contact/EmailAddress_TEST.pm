use 5.008;
use strict;
use warnings;

package Class::Value::Contact::EmailAddress_TEST;
our $VERSION = '1.100840';
# ABSTRACT: Contact-related value objects
use Test::More;
use parent 'Class::Value::Test';
use constant TESTDATA => (
    {   args  => {},
        valid => [
            qw(
              gr@univie.ac.at
              123@456.789.zz
              *@q.to
              a+b@c.com
              0@0.0
              )
        ],
        invalid => [
            qw(
              Borg
              a.test
              foo@bar.com@blah.com
              0@0
              foo@at
              fh@@univie.ac.at
              fh@univie.ac.at@univie.ac.at
              12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890@foo.at
              z.o.m.@gmx.net
              "z.o.m.@gmx.net"
              )
        ],
    },
);
1;


__END__
=pod

=head1 NAME

Class::Value::Contact::EmailAddress_TEST - Contact-related value objects

=head1 VERSION

version 1.100840

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Value-Contact>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Value-Contact/>.

The development version lives at
L<http://github.com/hanekomu/Class-Value-Contact/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

