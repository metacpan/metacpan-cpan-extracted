package CGI::Application::Plugin::Authentication::Driver::Filter::md5;
$CGI::Application::Plugin::Authentication::Driver::Filter::md5::VERSION = '0.23';
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
    } elsif ( length($filtered) == 16 ) {
        return ( $class->filter( 'binary', $plain ) eq $filtered ) ? 1 : 0;
    } elsif ( length($filtered) == 22 ) {
        return ( $class->filter( 'base64', $plain ) eq $filtered ) ? 1 : 0;
    } else {
        return ( $class->filter( undef, $plain ) eq $filtered ) ? 1 : 0;
    }
}

sub filter {
    my $class = shift;
    my $param = lc (shift || 'hex');
    my $plain = shift;

    Digest::MD5->require || die "Digest::MD5 is required to check MD5 passwords";
    if ( $param eq 'hex' ) {
        return Digest::MD5::md5_hex($plain);
    } elsif ( $param eq 'base64' ) {
        return Digest::MD5::md5_base64($plain);
    } elsif ( $param eq 'binary' ) {
        return Digest::MD5::md5($plain);
    }
    die "Unknown MD5 format $param";
}

1;
__END__


=head1 NAME

CGI::Application::Plugin::Authentication::Driver::Filter::md5 - MD5 filter

=head1 METHODS

=head2 filter ( (hex base64 binary), $string )

This will generate an MD5 hash of the string in the requested format.  By default,
hex encoding is used.

 my $filtered = $class->filter('base64', 'foobar'); # OFj2IjCsPJFfMAxmQxLGPw

 -or-

 my $filtered = $class->filter(undef, 'foobar'); # 3858f62230ac3c915f300c664312c63f


=head2 check ( (hex base64 binary), $string, $md5 )

This will generate an MD5 hash of the string, and compare it against the provided MD5 string.
If no encoding type is specified, the length of the MD5 string will be tested to see what format it
is in.

 if ($class->check(undef, 'foobar', '3858f62230ac3c915f300c664312c63f')) {
     # they match
 }


=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Driver>, L<Digest::MD5>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
