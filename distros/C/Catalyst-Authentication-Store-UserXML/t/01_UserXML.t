#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use File::Temp qw/tempdir/;
use Path::Class 0.26 'file';

use_ok("Catalyst::Authentication::Store::UserXML::Folder");

my $tmp_dir = Path::Class::Dir->new(tempdir( CLEANUP => 1 ));
my $userxml_folder = Catalyst::Authentication::Store::UserXML::Folder->new({
    folder => $tmp_dir
});
file($tmp_dir, 'uname01.xml')->spew(user01_xml());
file($tmp_dir, 'uname02.xml')->spew(user02_xml());

can_ok($userxml_folder, "user_supports");
ok( $userxml_folder->user_supports(qw/password self_check/), "user_supports password self_check" );

can_ok($userxml_folder, "find_user");
isa_ok( my $user = $userxml_folder->find_user({username=>"uname01"}), "Catalyst::Authentication::Store::UserXML::User");
isa_ok( $user, "Catalyst::Authentication::User");
isa_ok( my $user2 = $userxml_folder->find_user({username=>"uname02"}), "Catalyst::Authentication::Store::UserXML::User");

is( $user->username, 'uname01', '$user->id()');

can_ok( $user, "check_password");
ok( $user->check_password( "secretX" ), "password is secretX");
ok( !$user->check_password( "secretx" ), "password is not secretx");

# change password
$user->set_password( "secretX2" );
isa_ok( my $user_reload = $userxml_folder->find_user({username=>"uname01"}), "Catalyst::Authentication::Store::UserXML::User");
ok( $user_reload->check_password( "secretX2" ), "password is now secretX2");

# user status
is($user->status, 'active', 'default status is active');
$user->set_status('expired');
is($user->status, 'expired', 'set_status()');
ok(!$user->check_password( "secretX2" ), 'password no more valid');
$user->set_status('active');
ok($user->check_password( "secretX2" ), 'password valid again when set back to active');

# user roles
can_ok( $user, "roles");
is_deeply( [$user->roles], [], "user->roles()");
is_deeply( [$user2->roles], [qw(member admin)], "user2->roles()");

can_ok( $userxml_folder, "from_session" );
can_ok( $user, "for_session" );
my $recovered = $userxml_folder->from_session( undef, $user->for_session );
is( $recovered->username, $user->username, "recovery from session works");

eq_or_diff(
    squash_password(scalar(file($tmp_dir, 'uname01.xml')->slurp)),
    user01_final_xml(),
    'user01 after changes',
);

done_testing();


sub user01_xml {
    return q{
<root-element xmlns="http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML-test">
<user xmlns="http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML">
    <username>uname01</username>
    <password>{CLEARTEXT}secretX</password>
</user>
</root-element>
};
}
sub user01_final_xml {
    return q{<?xml version="1.0"?>
<root-element xmlns="http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML-test">
<user xmlns="http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML">
    <username>uname01</username>
    <password>---</password>
    <status>active</status>
</user>
</root-element>
};
}
sub user02_xml {
    return q{
<root-element xmlns="http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML-test">
<user xmlns="http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML">
    <username>uname02</username>
    <password>{CLEARTEXT}secret-02</password>
    <roles>
        <role>member</role>
        <role>admin</role>
    </roles>
</user>
</root-element>
};
}

sub squash_password {
    my $xml = shift;
    $xml =~ s{(<password>).+?(</password>)}{$1---$2}xms;
    return $xml;
}
