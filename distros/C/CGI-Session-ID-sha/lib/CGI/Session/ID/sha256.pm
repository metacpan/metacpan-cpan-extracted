# CGI::Session::ID::sha256 copyright 2008 Michael De Soto. This program is 
# distributed under the terms of the GNU General Public License, version 3.
#
# $Id: sha256.pm 7 2008-11-04 04:27:03Z desoto@cpan.org $

package CGI::Session::ID::sha256;

use strict;
use warnings;

use Digest::SHA;
use CGI::Session::ErrorHandler;

$CGI::Session::ID::sha256::VERSION = '1.01';
@CGI::Session::ID::sha256::ISA = qw/CGI::Session::ErrorHandler/;

*generate = \&generate_id;
sub generate_id {
    my $sha = Digest::SHA->new(256);
    $sha->add($$ , time() , rand(time));
    return $sha->hexdigest();
}

1;

=pod

=head1 NAME

CGI::Session::ID::sha256 - CGI::Session ID driver for generating SHA-256 based IDs

=head1 SYNOPSIS

    use CGI::Session;
    $session = new CGI::Session('id:sha256', undef);

=head1 DESCRIPTION

Use this module to generate SHA-256 encoded hexadecimal IDs for L<CGI::Session> 
objects. This library does not require any arguments. To use it, add 
C<id:sha256> to the DSN string when creating L<CGI::Session> objects.

=head2 Keep in mind

Keep in mind that a SHA-256 encoded hexadecimal string will have 64 characters. 
Don't forget to take this into account when using a database to store your 
session. For example, when using the default table layout with MySQL you'd want 
to create a table like:

    CREATE TABLE sessions (
        id CHAR(64) NOT NULL PRIMARY KEY,
        a_session NOT NULL,
    );

=head1 CAVEATS

There are no caveats with this module, but rather with the way L<CGI::Session> 
loads this module:

=head2 DSN string converted to lower case

For in depth discourse about this, please read the L<CGI::Session::ID::sha> 
documentation.

=head1 SEE ALSO

L<CGI::Session>, L<Digest::SHA>, and our Web site: 
L<http://code.google.com/p/perl-cgi-session-id-sha/>.


=head1 AUTHOR

Michael De Soto, E<lt>desoto@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Michael De Soto. All rights reserved.

This program is free software: you can redistribute it and/or modify it under 
the terms of the GNU General Public License as published by the Free Software 
Foundation, either version 3 of the License, or (at your option) any later 
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY 
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with 
this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

