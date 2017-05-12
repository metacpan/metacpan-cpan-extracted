# CGI::Session::ID::sha copyright 2008 Michael De Soto. This program is 
# distributed under the terms of the GNU General Public License, version 3.
#
# $Id: sha.pm 7 2008-11-04 04:27:03Z desoto@cpan.org $

package CGI::Session::ID::sha;

use strict;
use warnings;

use Digest::SHA;
use CGI::Session::ErrorHandler;

$CGI::Session::ID::sha::VERSION = '1.01';
@CGI::Session::ID::sha::ISA = qw/CGI::Session::ErrorHandler/;

*generate = \&generate_id;
sub generate_id {
    my $sha = Digest::SHA->new(1);
    $sha->add($$ , time() , rand(time));
    return $sha->hexdigest();
}

1;

=pod

=head1 NAME

CGI::Session::ID::sha - CGI::Session ID driver for generating SHA-1 based IDs

=head1 SYNOPSIS

    use CGI::Session;
    $session = new CGI::Session('id:sha', undef);

=head1 DESCRIPTION

Use this module to generate SHA-1 encoded hexadecimal IDs for L<CGI::Session> 
objects. This library does not require any arguments. To use it, add 
C<id:sha> to the DSN string when creating L<CGI::Session> objects.

=head2 Keep in mind

Keep in mind that a SHA-1 encoded hexadecimal string will have 40 characters. 
Don't forget to take this into account when using a database to store your 
session. For example, when using the default table layout with MySQL you'd want 
to create a table like:

    CREATE TABLE sessions (
        id CHAR(40) NOT NULL PRIMARY KEY,
        a_session NOT NULL,
    );

=head1 CAVEATS

There are no caveats with this module, but rather with the way L<CGI::Session> 
loads this module:

=head2 DSN string converted to lower case

I suppose I'm nitpicking -- this isn't a big deal --  but I am the captious 
sort. I did spend the better part of of an afternoon trying to figure out 
what was going on.

When calling the L<CGI::Session> constructor  C<new>, one has the option of 
passing a DSN string that should look something like this:

    'driver:file;serializer:default;id:md5'

Notice how the string is all lowercase. However the following is equally valid:

    'DRIVER:FILE;SERIALIZER:DEFAULT;ID:MD5'

Most of us are more inclined to use the former rather than the later. The point 
is it doesn't matter. The string is converted to lowercase before 
L<CGI::Session> attempts to load each part:

    # driver:file loads
    CGI::Session::Driver::file
    
    # serializer:default loads
    CGI::Session::Serialize::default
    
    # id:md5 loads
    CGI::Session::ID::md5

The problem comes when you want to load a module that uses upper and lowercase 
letters in its name. Now this isn't a big problem because there aren't a lot of 
modules written to plug into this part of L<CGI::Session>. However, when 
researching I found three on CPAN that do:

=over 4

=item *

L<CGI::Session::ID::Base32>

=item *

L<CGI::Session::ID::MD5_Base64>

=item *

L<CGI::Session::ID::MD5_Base32>

=back

Since I find consistent style aesthetically pleasing I prefer mixed case module 
names. Especially since the underlying module (L<Digest::MD5>) is mixed case. 
So keeping this in mind, I originally named my module CGI::Session::ID::SHA. 
SHA is an acronym for Secure Hash Algorithm and the underlying module is 
L<Digest::SHA>, and so it just makes sense to name it that way.

No dice.

It took me a while to realize that mixed case just wont work. Despite those 
other modules on CPAN using mixed case, L<CGI::Session> just isn't able to load 
them. I don't know if it's always been this way, or if this is a recent 
development. I didn't really do any research on it.

On one hand, I can't imagine Daniel Peder (who wrote the three above) would 
release to CPAN modules that can't be used by the code they're meant to plug 
into. On the other hand, I can't imagine Mark Stosberg (who wrote 
L<CGI::Session>) would change how modules are loaded into L<CGI::Session>.

None of this is is included in the L<CGI::Session> documentation. I don't know 
that it should be. This behavior isn't wrong, it's just curious. Now, I should 
have prefaced this by saying that I didn't really research too deeply beyond 
the documentation on CPAN. For all I know there exists reams of documentation 
or discussions on this very matter.

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

