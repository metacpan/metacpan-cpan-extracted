use 5.008;
use strict;
use warnings;

package Data::Semantic::URI::TestData::ftp;
our $VERSION = '1.100850';
# ABSTRACT: Test data class for the ftp URI semantic data class
use Test::More;
no warnings 'qw';    # Possible attempt to put comments in qw() list
use constant TESTDATA => (
    {   args  => {},
        valid => [
            qw(
              ftp://ftp.example.com/**!(),,
              ftp://127.0.0.1
              ftp://127.0.0.1/
              ftp://127.0.0.1:12345/some/file
              ftp://abigail:secret:here@127.0.0.1:21/some/file
              ftp://abigail:secret@127.0.0.1:21/some/file
              ftp://abigail:secret@ftp.example.com:21/some/file
              ftp://abigail@ftp.example.com
              ftp://abigail@ftp.example.com/some/path/somewhere;type=a
              ftp://abigail@ftp.example.com:21/some/file
              ftp://ftp.example.com
              ftp://ftp.example.com/%7Eabigail/
              ftp://ftp.example.com/
              ftp://ftp.example.com/--_$.+++
              ftp://ftp.example.com/.
              ftp://ftp.example.com/;type=I
              ftp://ftp.example.com/some/directory/some/where/
              ftp://ftp.example.com/some/file/some/where
              ftp://ftp.example.com/some/path;type=A
              ftp://ftp.example.com/some/path;type=i
              ftp://ftp.example.com/~abigail/
              ftp://ftp.example.com:21/some/file
              ftp://www.example.com//////////////
              ftp://www.example.com/:@=&=
              )
        ],
        invalid => [
            qw(
              FTP://ftp.example.com/
              HTTP://ftp.example.com/
              ftp://ftp.example.com/`
              ftp://ftp.example.com/nope|nope
              ftp://ftp.example.com/some/??
              ftp://ftp.example.com/some/path;type=AI
              ftp://ftp.example.com/some/path;type=Q
              ftp://ftp.example.com/some/path?query/path
              ftp://ftp.example.com/some/path?query1?query2
              ftp://ftp.example.com:21/some/path?query
              ftp://www.example.com/some/file#target
              ftp://www.example.com/some/path;here
              http://ftp.example.com/
              )
        ],
    },
    {   args  => { password => 1 },
        valid => [
            qw(
              ftp://ftp.example.com/**!(),,
              ftp://127.0.0.1
              ftp://127.0.0.1/
              ftp://127.0.0.1:12345/some/file
              ftp://abigail:secret@127.0.0.1:21/some/file
              ftp://abigail:secret@ftp.example.com:21/some/file
              ftp://abigail@ftp.example.com
              ftp://abigail@ftp.example.com/some/path/somewhere;type=a
              ftp://abigail@ftp.example.com:21/some/file
              ftp://ftp.example.com
              ftp://ftp.example.com/%7Eabigail/
              ftp://ftp.example.com/
              ftp://ftp.example.com/--_$.+++
              ftp://ftp.example.com/.
              ftp://ftp.example.com/;type=I
              ftp://ftp.example.com/some/directory/some/where/
              ftp://ftp.example.com/some/file/some/where
              ftp://ftp.example.com/some/path;type=A
              ftp://ftp.example.com/some/path;type=i
              ftp://ftp.example.com/~abigail/
              ftp://ftp.example.com:21/some/file
              ftp://www.example.com//////////////
              ftp://www.example.com/:@=&=
              )
        ],
        invalid => [
            qw(
              FTP://ftp.example.com/
              HTTP://ftp.example.com/
              ftp://abigail:secret:here@127.0.0.1:21/some/file
              ftp://ftp.example.com/`
              ftp://ftp.example.com/nope|nope
              ftp://ftp.example.com/some/??
              ftp://ftp.example.com/some/path;type=AI
              ftp://ftp.example.com/some/path;type=Q
              ftp://ftp.example.com/some/path?query/path
              ftp://ftp.example.com/some/path?query1?query2
              ftp://ftp.example.com:21/some/path?query
              ftp://www.example.com/some/file#target
              ftp://www.example.com/some/path;here
              http://ftp.example.com/
              )
        ],
    },
    {   args  => { type => '[AIDaid]' },
        valid => [
            qw(
              ftp://ftp.example.com/**!(),,
              ftp://127.0.0.1
              ftp://127.0.0.1/
              ftp://127.0.0.1:12345/some/file
              ftp://abigail:secret:here@127.0.0.1:21/some/file
              ftp://abigail:secret@127.0.0.1:21/some/file
              ftp://abigail:secret@ftp.example.com:21/some/file
              ftp://abigail@ftp.example.com
              ftp://abigail@ftp.example.com/some/path/somewhere;type=a
              ftp://abigail@ftp.example.com:21/some/file
              ftp://ftp.example.com
              ftp://ftp.example.com/%7Eabigail/
              ftp://ftp.example.com/
              ftp://ftp.example.com/--_$.+++
              ftp://ftp.example.com/.
              ftp://ftp.example.com/;type=I
              ftp://ftp.example.com/some/directory/some/where/
              ftp://ftp.example.com/some/file/some/where
              ftp://ftp.example.com/some/path;type=A
              ftp://ftp.example.com/some/path;type=D
              ftp://ftp.example.com/some/path;type=i
              ftp://ftp.example.com/~abigail/
              ftp://ftp.example.com:21/some/file
              ftp://www.example.com//////////////
              ftp://www.example.com/:@=&=
              )
        ],
        invalid => [
            qw(
              FTP://ftp.example.com/
              HTTP://ftp.example.com/
              ftp://ftp.example.com/`
              ftp://ftp.example.com/nope|nope
              ftp://ftp.example.com/some/??
              ftp://ftp.example.com/some/path;type=AI
              ftp://ftp.example.com/some/path?query/path
              ftp://ftp.example.com/some/path?query1?query2
              ftp://ftp.example.com:21/some/path?query
              ftp://www.example.com/some/file#target
              ftp://www.example.com/some/path;here
              http://ftp.example.com/
              )
        ],
    },
);
1;


__END__
=pod

=head1 NAME

Data::Semantic::URI::TestData::ftp - Test data class for the ftp URI semantic data class

=head1 VERSION

version 1.100850

=head1 DESCRIPTION

Defines test data for L<Data::Semantic::URI::ftp_TEST>, but it is also used in
the corresponding value and domain classes, i.e.,
L<Class::Value::URI::ftp_TEST> and L<Data::Domain::URI::ftp_TEST>.

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

