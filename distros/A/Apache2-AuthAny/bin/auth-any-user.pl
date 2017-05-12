#!/usr/bin/perl

use strict;
use warnings;

use Apache2::AuthAny::DB ();
use Getopt::Long;

use Data::Dumper qw(Dumper);

my $usage = "Usage: auth-any-user.pl [options] user\n" .
  "Use 'auth-any-user.pl --help' for complete documentation\n";

my $full_usage = <<'USAGE';
Usage: auth-any-user.pl [options] user

Options:

 --help                  Print this documentation
 --get                   Return user's settings (default)
 --report [full|line|email] Report style for --get or --search
 --add                   Add user
 --update                Update user
 --search                Search for users matching input fields
 --verbose               Verbose output (used by --search)

 --organization str
 --firstName str
 --lastName str
 --phone str
 --email str
 --active [0|1]          Defaults to 1

 --role str
 --no-role str           The role is removed if in "--update" mode

 --ident                 Identity for use with --search
 --protectnetIdent str   Identity, +, or - (see below)
 --uwIdent str
 --googleIdent str
 --basicIdent str
 --ldapIdent str

The provider arguments (--xxxIdent) all take "+" or "-" as well as the user's
identity string. If "+" is used, the identity will be the username appended
with the default for the provider. For example, "--uwIdent + joe" would
produce the identity, "joe@washington.edu". If "-" is used, that identity
is removed.

EXAMPLES:
Search for an existing president who has the preview role
$ auth-any-user.pl --search --verbose --ident pres

Add new user, "boboma"
$ auth-any-user.pl --add --googleIdent president@whitehouse.gov boboma

Update "bobama", adding a second Google ident and the contributor role. The
plus (+) sign after '--google' results in the default identity, 
"boboma@gmail.com".
Note the use of abbreviated flags. They only need to be unambiguous.
$ auth-any-user.pl --up --google + -r contributor boboma

Get information about "boboma"
$ auth-any-user.pl boboma

Update "bobama", removing all Google identities and the contributor role. The
preview role is added along with Protect Network and UW identities.
$ auth-any-user.pl -up -go - -no-role contributor -r preview -uw + -pr + boboma

Deactivate. User will not be able to sign in with any identity
auth-any-user.pl --active 0 boboma

USAGE

my $get = 0;
my $report;
my $add = 0;
my $update = 0;
my $search = 0;
my $verbose = 0;
my $help = 0;
my ($organization, $firstName, $lastName, $phone, $email, $active);
my ($ident, $protectnetIdent, $uwIdent, $googleIdent, $basicIdent, $ldapIdent);

my (@role, @norole);

GetOptions(
           'help'           =>  \$help,
           'get'            =>  \$get,
           'report:s'       =>  \$report,
           'add'            =>  \$add,
           'update'         =>  \$update,
           'search'         =>  \$search,
           'verbose'        =>  \$verbose,
           'organization:s' =>  \$organization,
           'firstName:s'    =>  \$firstName,
           'lastName:s'     =>  \$lastName,
           'phone:s'        =>  \$phone,
           'email:s'        =>  \$email,
           'active:i'       =>  \$active,

           'role:s'         => \@role,
           'no-role:s'      => \@norole,

           'ident:s'        => \$ident,
           'protectnetIdent:s'   => \$protectnetIdent,
           'uwIdent:s'           => \$uwIdent,
           'googleIdent:s'       => \$googleIdent,
           'basicIdent:s'        => \$basicIdent,
           'ldapIdent:s'         => \$ldapIdent,
          );

# warn "roles are\n" . Dumper(\@role);

die "$full_usage\n" if $help;

my $username = shift;

die "username required\n\n$usage" unless $search || $username;

die "invalid arguments, @ARGV\n\n$usage" if @ARGV;

$get = 1 unless $add || $update || $search;
die "Choose one of search, get, add, or update\n\n$usage" if ($get + $add + $update + $search) > 1;

my $db = Apache2::AuthAny::DB->new();
my @valid_roles = @{$db->getValidRoles()};

my %user;
$user{username}     = $username;
$user{organization} =  $organization if $organization;
$user{firstName}    =  $firstName    if $firstName;
$user{lastName}     =  $lastName     if $lastName;
$user{phone}        =  $phone        if $phone;
$user{email}        =  $email        if $email;
if ( defined($active) ) {
    $user{active} = ($active ? 1 : 0);
} else {
    $user{active} = 1; # default to 1 if no option supplied
}

my $UID;
if ($add) {
    $UID = $db->addUser(%user);
} elsif ($get) {
    %user = %{$db->getUserByUsername($username) || {} };
    $UID = $user{UID};
} elsif ($update) {
    $UID = $db->updateUser(%user);
} elsif (!$search) {
    die "Really bad program error";
}

die "No user by name '$username' exists\n\n$usage" unless $UID || $search;

if ($get) {
    my $roles = $db->getUserRoles($UID);
    my $identities = $db->getUserIdentities($UID);
    print report(\%user, $roles, $identities, $report);

    exit;
}

if ($search) {
    my $ident = $ident || $protectnetIdent || $uwIdent || $googleIdent || $basicIdent || $ldapIdent;
    my $ulist = $db->searchUsers(\%user, \@role, \@norole, $ident,);

    my @usernames = @{ $ulist || [] };

    if (@usernames) {
        if ($verbose || $report) {
            $report ||= 'full';
            foreach my $n (@usernames) {
                system("$0 --get --report $report $n");
            }
        } else {
            print join("\n", @usernames) . "\n";
        }
    } else {
        warn "No matching users found\n";
    }
    exit;
}

if ($add || $update) {
    foreach my $r (@role) {
        unless (grep {$r eq $_} @valid_roles) {
            warn "invalid role, '$r'\n";
            next;
        }
        $db->addUserRole($UID, $r);
    }
    warn "Added user, '$username' with no role\n" if $add && ! @role;
}

if ($update) {
    foreach my $r (@norole) {
        unless (grep {$r eq $_} @valid_roles) {
            warn "invalid role, '$r'\n";
            next;
        }
        $db->removeUserRole($UID, $r);
    }
}

if ($add && 
    ! ($googleIdent || $uwIdent || $protectnetIdent || $basicIdent || $ldapIdent)) {
    warn "Added user, '$username' with no identities\n";
}

if (defined($protectnetIdent)) {
    if ($update && $protectnetIdent eq '-') {
        $db->removeUserIdent($UID, 'protectnet');
    } else {
        $protectnetIdent = '' if $protectnetIdent eq '+';
        my $authId = $protectnetIdent ? $protectnetIdent : $username . '@idp.protectnetwork.org';

        if ($authId =~ /\@idp.protectnetwork.org$/) {
            $db->addUserIdent($UID, $authId, 'protectnet');
        } else {
            warn "invalid protectnetwork id, '$authId'";
        }
    }
}

if (defined($uwIdent)) {
    if ($update && $uwIdent eq '-') {
        $db->removeUserIdent($UID, 'uw');
    } else {
        $uwIdent = '' if $uwIdent eq '+';
        my $authId = $uwIdent ? $uwIdent : $username . '@washington.edu';

        if ($authId =~ /\@washington.edu$/) {
            $db->addUserIdent($UID, $authId, 'uw');
        } else {
            warn "invalid uw id, '$authId'";
        }
    }
}

if (defined($basicIdent)) {
    if ($update && $basicIdent eq '-') {
        $db->removeUserIdent($UID, 'basic');
    } else {
        $basicIdent = '' if $basicIdent eq '+';
        my $authId = $basicIdent || $username;
        $db->addUserIdent($UID, $authId, 'basic');
    }
}

if (defined($ldapIdent)) {
    if ($update && $ldapIdent eq '-') {
        $db->removeUserIdent($UID, 'ldap');
    } else {
        $ldapIdent = '' if $ldapIdent eq '+';
        my $authId = $ldapIdent || $username;
        $db->addUserIdent($UID, $authId, 'ldap');
    }
}

if (defined($googleIdent)) {
    if ($update && $googleIdent eq '-') {
        $db->removeUserIdent($UID, 'google');
    } else {
        $googleIdent = '' if $googleIdent eq '+';
        my $authId = $googleIdent ? $googleIdent : $username . '@gmail.com';

        $db->addUserIdent($UID, $authId, 'google');
    }
}

sub report {
    my ($user, $roles, $identities, $report) = @_;
    $report ||= 'full';
    my $out = '';

    if ($report eq 'full') {
        print "\n=======================\n";
        $out .= "USER:\n";
        foreach my $field (keys %$user) {
            next unless defined($user->{$field});
            $out .= sprintf "    %-20s%s\n", $field, $user->{$field};
        }
        $out .= "\nROLES:\n";
        foreach my $role (@$roles) {
            $out .= sprintf "    $role\n";
        }
        $out .= "\nIDENTITIES:\n";
        foreach my $row (@$identities) {
            $out .= sprintf "    %-20s%s\n", $row->{authProvider}, $row->{authId};
        }
    } elsif ($report eq 'email') {
        if ($user->{email}) {
            my $name;
            if ($user->{firstName} && $user->{lastName}) {
                $name = "$user->{firstName} $user->{lastName}";
            } else {
                $name = $user->{email};
            }
            $out .= qq["$name" <$user->{email}>,\n];
        } else {
            warn "no email address for $user->{username}\n";
        }
    } elsif ($report eq 'line') {
        die "Sorry. Report type 'line' not yet implemented\n";
    } else {
        die "Invalid report type, '$report'\n";
    }
    return "$out";
}
