# ABSTRACT: generate PostgreSQl password hashes
=head1 NAME
Crypt::PostgreSQL - Module for generating encrypted password for PostgreSQL


=head1 VERSION

version 0.02

=cut

use strict;
use warnings;
package Crypt::PostgreSQL;
$Crypt::PostgreSQL::VERSION = '0.02';
BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw (Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
}

use Carp;
use Crypt::URandom;
use Crypt::KeyDerivation qw(pbkdf2);
use Crypt::Mac::HMAC qw(hmac hmac_b64);
use Crypt::Digest::SHA256 qw(sha256_b64);
use MIME::Base64;
use Digest::MD5 qw(md5_hex);

=head1 SYNOPSIS

    use Crypt::PostgreSQL;

    print Crypt::PostgreSQL::encrypt_md5('my password', 'myuser');

    my $scram_hash = Crypt::PostgreSQL::encrypt_scram('my password');
    my DBI;
    my $dbh = DBI->connect("dbi:Pg:dbname=...", '', '', {AutoCommit => 0});
    $dbh->do(q{
        ALTER USER my_user SET ENCRYPTION PASSWORD '$scram_hash';
    });


=head1 DESCRIPTION

This module is for generating password suitable to generate password hashes in PostgreSQL format,
using one of the two encrypted formats: scram_sha_256 and md5


=head2 encrypt_md5

The 1st argument is the password to encrypted

The 2th argument is the postgresgl user name

The function returns hash string suitable to use with ALTER USER SQL command.

=cut

sub encrypt_md5 {
    my($password, $user) = @_;
    if(!length $user){
        croak 'The 2nd parameter with the user is missing!';
    }
    return 'md5'.md5_hex($password.$user);
}

=head2 encrypt_scram

The 1st argument is the password to encrypted

The 2nd argument, can define salt (use only for test!)

The function returns hash string suitalbe to use with ALTER USER SQL command.

=cut

sub encrypt_scram {
    my($password, $salt) = @_;
    if(!defined $salt){
        $salt = Crypt::URandom::urandom(16);
    }elsif(length($salt) != 16){
        croak 'The salt length must be 16!';
    }
    my $iterations = 4096;
    my $digest_key = pbkdf2($password, $salt, $iterations, 'SHA256', 32);
    my $client_key = hmac('SHA256', $digest_key ,'Client Key');
    my $b64_client_key = sha256_b64($client_key);
    my $b64_server_key = hmac_b64('SHA256', $digest_key, 'Server Key');
    my $b64_salt = encode_base64($salt, '');
    return "SCRAM-SHA-256\$$iterations:$b64_salt\$$b64_client_key:$b64_server_key";
}


=head1 BUGS

Please let the author know if any are caught

=head1 AUTHOR

	Guido Brugnara
	gdo@leader.it


=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

=over

=item L<https://www.postgresql.org/docs/current/auth-password.html>

PostgreSQL documentation: 20.5. Password Authentication

=item L<https://www.leader.it/Blog/PostgreSQL_SCRAM-SHA-256_authentication>

Blog article: PostgreSQL SCRAM-SHA-256 authentication with credits ...

=back

=cut

1;
