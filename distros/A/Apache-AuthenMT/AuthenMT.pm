package Apache::AuthenMT;

$VERSION = "1.00";

use strict;
use Apache::Constants qw(:common);
use MT::App;
use MT::Author;

# authentication handler
sub handler {
    my $r      = shift;
    my $MT_DIR = $r->dir_config("MT_DIR");
    my $reason;

    # get user's authentication credentials
    my($res, $sent_pw) = $r->get_basic_auth_pw;
    return $res if $res != OK;
    my $user = $r->connection->user;
    
    # start up Movable Type
    my $app = MT::App->new( 
        Config    => $MT_DIR . 'mt.cfg',
        Directory => $MT_DIR 
    ) or $reason = MT::App::->errstr;

    # check password
    $reason = authenticate($r, $user, $sent_pw) unless ($reason);

    # reason for failure
    if ($reason) {
       #$r->note_basic_auth_failure;
       #$r->log_reason($reason, $r->filename);
       return AUTH_REQUIRED;
    }

    # authenticated
    return OK;
}

# check user and password against Movable Type's database
sub authenticate {
    my $r       = shift;
    my $user    = shift;
    my $sent_pw = shift;
    my $crypted = 0;
    # print STDERR "authmt: $user $sent_pw\n";

    if (my $author = MT::Author->load({ name => $user })) {
        if ($author->is_valid_password($sent_pw, $crypted)) {
            return "";
        } else {
            return "invalid pass";
        }
    } else {
        return "invalid user";
    }
}

=head1 NAME

Apache::AuthenMT - Authenticate using Movable Type's database

=head1 SYNOPSIS

Example 1: F<.htaccess>:

    <%Perl>
    use lib '/www/htdocs/apps/mt/lib';
    use lib '/www/htdocs/apps/mt/extlib';
    </%Perl>
    PerlModule Apache::AuthenMT
    AuthName MindsIsland
    AuthType Basic
    PerlSetVar MT_DIR /www/htdocs/apps/mt/
    PerlAuthenHandler Apache::AuthenMT
    require valid-user

Example 2: F<httpd.conf>:

    <%Perl>
    use lib '/www/htdocs/apps/mt/lib';
    use lib '/www/htdocs/apps/mt/extlib';
    </%Perl>
    PerlModule Apache::AuthenMT
    <Location /somewhere>
        AuthName MindsIsland
        AuthType Basic
        PerlSetVar MT_DIR /www/htdocs/apps/mt/
        PerlAuthenHandler Apache::AuthenMT
        require valid-user
    <Location /somewhere>

=head1 REQUIRES

=over 4

=item Movable Type

Movable Type is a popular blogging system.

=item mod_perl

mod_perl embeds a perl interpreter into apache.

=back

=head1 DESCRIPTION

This is a mod_perl authentication handler that authenticates using
Movable Type's database.  Setting it up requires that you already
have Movable Type installed on your system.  Configuring it is then
a simple matter of adding a few lines to F<httpd.conf> or F<.htaccess>
to tell Apache that you'd like L<Apache::AuthenMT|Apache::AuthenMT>
to handle authentication for a URL.  The synopsis provides some
example configurations you can adapt to your needs.

=head1 METHODS

=over 4

=item handler

mod_perl auth handler

=item authenticate

This checks the user and password against database.

=back

=head1 VARIABLES

=over 4

=item MT_DIR

This variable should contain the path to your Movable Type perl modules.
It needs to be set in your httpd.conf using the C<PerlSetVar> directive.

=back

=head1 AUTHOR

John BEPPU <beppu@cpan.org>

=head1 SEE ALSO

http://www.modperl.com/ and http://www.movabletype.org/

=cut

# $Id: AuthenMT.pm,v 1.8 2003/07/29 17:20:07 beppu Exp $
