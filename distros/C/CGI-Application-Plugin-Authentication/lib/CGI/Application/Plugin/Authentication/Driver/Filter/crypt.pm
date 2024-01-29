package CGI::Application::Plugin::Authentication::Driver::Filter::crypt;
$CGI::Application::Plugin::Authentication::Driver::Filter::crypt::VERSION = '0.24';
use strict;
use warnings;

sub check {
    my $class    = shift;
    my $param    = shift;
    my $plain    = shift;
    my $filtered = shift;

    return ( $class->filter( $param, $plain, $filtered ) eq $filtered ) ? 1 : 0;
}

sub filter {
    my ($class, undef, $plain, $salt) = @_;
    if (!$salt) {
        my @alphabet = ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );
        $salt = join '', @alphabet[ rand 64, rand 64 ];
    }
    return crypt( $plain, $salt );
}

1;
__END__


=head1 NAME

CGI::Application::Plugin::Authentication::Driver::Filter::crypt - crypt Filter

=head1 METHODS


=head2 filter ( undef, $string [, salt ] )

This will generate a crypted string.  The first parameter is always ignored,
since there is only one way to use the crypt function.  You can pass in an
extra parameter to act as the salt.


 my $filtered = $class->filter(undef, 'foobar'); # mQvbWI43eDCAk

 -or-

 my $filtered = $class->filter(undef, 'foobar', 'AA'); # AAZk9Aj5/Ue0E


=head2 check ( undef, $string, $crypted )

This will crypt the string, and compare it against the provided crypted string.
The first parameter is always ignored, since there is only one way to use the
crypt function.

 if ($class->check(undef, 'foobar', 'mQvbWI43eDCAk')) {
     # they match
 }


=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Driver>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
