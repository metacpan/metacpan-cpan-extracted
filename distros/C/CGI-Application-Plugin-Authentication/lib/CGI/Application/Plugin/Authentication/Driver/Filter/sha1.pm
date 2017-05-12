package CGI::Application::Plugin::Authentication::Driver::Filter::sha1;
$CGI::Application::Plugin::Authentication::Driver::Filter::sha1::VERSION = '0.21';
use strict;
use warnings;

use UNIVERSAL::require;

sub check {
    my $class    = shift;
    my $param    = shift;
    my $plain    = shift;
    my $filtered = shift;

    if ($param) {
        return ( $class->filter( $param, $plain ) eq $filtered ) ? 1 : 0;
    } elsif ( length($filtered) == 20 ) {
        return ( $class->filter( 'binary', $plain ) eq $filtered ) ? 1 : 0;
    } elsif ( length($filtered) == 27 ) {
        return ( $class->filter( 'base64', $plain ) eq $filtered ) ? 1 : 0;
    } else {
        return ( $class->filter( undef, $plain ) eq $filtered ) ? 1 : 0;
    }
}

sub filter {
    my $class = shift;
    my $param = lc (shift || 'hex');
    my $plain = shift;

    Digest::SHA->require || die "Digest::SHA is required to check SHA1 passwords";
    if ( $param eq 'hex' ) {
        return Digest::SHA::sha1_hex($plain);
    } elsif ( $param eq 'base64' ) {
        return Digest::SHA::sha1_base64($plain);
    } elsif ( $param eq 'binary' ) {
        return Digest::SHA::sha1($plain);
    }
    die "Unknown SHA1 format $param";
}

1;
__END__


=head1 NAME

CGI::Application::Plugin::Authentication::Driver::Filter::sha1 - SHA1 Password filter

=head1 METHODS


=head2 filter ( (hex base64 binary), $string )

This will generate an SHA1 hash of the string in the requested format.  By default,
hex encoding is used.

 my $filtered = $class->filter('base64', 'foobar'); # iEPX+SQWIR3p67lj/0zigSWTKHg

 -or-

 my $filtered = $class->filter(undef, 'foobar'); # 8843d7f92416211de9ebb963ff4ce28125932878


=head2 check ( (hex base64 binary), $string, $sha1 )

This will generate an SHA1 hash of the string, and compare it against the provided SHA1 string.
If no encoding type is specified, the length of the SHA1 string will be tested to see what format it
is in.

 if ($class->check(undef, 'foobar', '8843d7f92416211de9ebb963ff4ce28125932878')) {
     # they match
 }


=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Driver>, L<Digest::SHA>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
