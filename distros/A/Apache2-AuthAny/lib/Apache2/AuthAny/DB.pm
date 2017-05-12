package Apache2::AuthAny::DB;

use strict;

use DBI;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

my $dbHandle;
our $VERSION = '0.201';

sub new {
    my $class = shift;
    my $self = {};

    unless ($dbHandle) {
        my $dbUser = $ENV{AUTH_ANY_DB_USER} || die "Env variable AUTH_ANY_DB_USER required";
        my $dbPasswordFile = $ENV{AUTH_ANY_DB_PW_FILE} || die "Env variable AUTH_ANY_DB_PW_FILE required";
        open(PWD, "<$dbPasswordFile") || die "Could not read password file, '$dbPasswordFile'. $!";
        my $dbPassword = <PWD>;
        close(PWD) || die "ouch $!";
        chomp $dbPassword;      #remove the trailing new line
        die "Could not get password" unless $dbPassword;
        my $dbName = $ENV{AUTH_ANY_DB_NAME} || die "Env variable AUTH_ANY_DB_NAME required";
        my $db;
        $db = $ENV{AUTH_ANY_DB} || "mysql";
        my $dsn = "database=$dbName";
        my $dbHost = $ENV{AUTH_ANY_DB_HOST};

        $dsn .= ";host=$dbHost" if $dbHost;
        $dbHandle = DBI->connect("DBI:$db:$dsn", $dbUser, $dbPassword) or die "user: $dbUser, errstr: $DBI::errstr";
        $dbHandle->do('SET CHARACTER SET utf8');
    }

    bless ($self, $class);
    return $self;
}

sub useDB {
    return;
    my $self = shift;
    my $auth_any_db = $self->{auth_any_db};
    unless ($dbHandle->do("use $auth_any_db") ) {
        die $dbHandle->errstr;
    }
}

sub getValidRoles {
    my $self = shift;
    $self->useDB();
    return $dbHandle->selectcol_arrayref('SELECT DISTINCT role FROM userRole');
}

sub getUserCookieByPID {
    my $self = shift;
    $self->useDB();
    my $pid = shift;
    return unless $pid;
    my $getCookieSql = 'select * from userAACookie where PID = ? limit 1';

    my $res = $dbHandle->selectrow_hashref($getCookieSql, undef, $pid);

    if ($res) {
        return $res;
    } elsif ($dbHandle->errstr) {
        die $dbHandle->errstr;
    } else {
        warn "DB entry for PID cookie, '$pid' missing";
        return;
    }
}

sub getUserByUID {
    my $self = shift;
    $self->useDB();
    my ($UID) = @_;
        my $SQL = 'SELECT * FROM user WHERE UID = ?';

    return $dbHandle->selectrow_hashref($SQL, undef, $UID);
}

sub searchUsers {
    my $self = shift;
    $self->useDB();
    my %usernames;
    my ($u, $r, $n, $ident) = @_;
    my %user = %$u;
    my @role = @$r;
    my @norole = @$n;

    # username must be found in each query (AND) to be listed
    my $queries = 0;
    if ($user{username} || $user{lastName} || $user{firstName} || $user{organization} ) {
        $queries++;
        my @where;
        my @val;
        if ($user{username}) {
            push @where, "username LIKE ?";
            push @val, "%$user{username}%";

        }
        if ($user{lastName}) {
            push @where, "lastName LIKE ?";
            push @val, "%$user{lastName}%";

        }

        if ($user{firstName}) {
            push @where, "firstName LIKE ?";
            push @val, "%$user{firstName}%";

        }
        if ($user{organization}) {
            push @where, "organization LIKE ?";
            push @val, "%$user{organization}%";

        }
        my $where_clause = join " OR ", @where;

        my $SQL = "SELECT username FROM user WHERE $where_clause";
        my $unames = $dbHandle->selectcol_arrayref($SQL, undef, @val);
        foreach my $n (@$unames) {
            $usernames{$n}++;
        }
    }

    foreach my $role (@role) {
        $queries++;
        my $SQL = 'SELECT username FROM user, userRole
                   WHERE user.UID = userRole.UID
                   AND role = ?';
        my $unames = $dbHandle->selectcol_arrayref($SQL, undef, $role);
        foreach my $n (@$unames) {
            $usernames{$n}++;
        }
    }

    foreach my $role (@norole) {
         $queries++;
         my $SQL = 'SELECT username
                    FROM user
                    LEFT JOIN userRole ON user.UID = userRole.UID AND role = ?
                    WHERE role IS NULL';
         my $unames = $dbHandle->selectcol_arrayref($SQL, undef, $role);
         foreach my $n (@$unames) {
             $usernames{$n}++;
        }
    }

    if ($ident) {
        $queries++;
        my $SQL = 'SELECT username FROM user, userIdent
                   WHERE user.UID = userIdent.UID
                   AND userIdent.authId LIKE ?';
        my $unames = $dbHandle->selectcol_arrayref($SQL, undef, "%$ident%");
        my %identUsers;
        foreach my $n (@$unames) {
            $identUsers{$n}++;
        }
        foreach my $n (keys %identUsers) {
            $usernames{$n}++;
        }
    }

    # each query must find the name in order to return the name
    my @usernames;
    foreach my $n (keys %usernames) {
        push @usernames, $n if $usernames{$n} == $queries;
    }

    return \@usernames;
}

sub getUserByUsername {
    my $self = shift;
    my ($username) = @_;
    my $SQL = 'SELECT * FROM user WHERE username = ?';

    $self->useDB();
    return $dbHandle->selectrow_hashref($SQL, undef, $username);
}

sub getUserByAuthIdAndProvider {

    my $self = shift;
    my ($authId, $authProvider) = @_;
    return unless $authId && $authProvider;

    my $getUserSql = 'select a.* from user a, userIdent b WHERE a.UID = b.UID
                      AND authId = ? AND authProvider = ? limit 1';

    $self->useDB();
    return $dbHandle->selectrow_hashref($getUserSql, undef, $authId, $authProvider);
}

sub getBasicUser {
    my $self = shift;
    my ($user) = @_;

    my $sql = 'select user, password from basicAuth WHERE user = ?';

    $self->useDB();
    return $dbHandle->selectrow_hashref($sql, undef, $user);
}

sub getUserRoles {
    my $self = shift;
    my ($UID) = @_;

    my $getRoleSql = 'select role from userRole WHERE UID = ?';

    $self->useDB();
    return $dbHandle->selectcol_arrayref($getRoleSql, undef, $UID);
}

sub getUserRoleChoices {
    my $self = shift;
    my ($UID) = @_;

    my $getRoleSql = 'select role from userRoleChoice WHERE UID = ?';

    $self->useDB();
    return $dbHandle->selectcol_arrayref($getRoleSql, undef, $UID);
}

sub getUserIdentities {
    my $self = shift;
    my ($UID) = @_;

    my $sql = 'SELECT * FROM userIdent WHERE UID = ?';

    $self->useDB();
    return $dbHandle->selectall_arrayref($sql, { Slice => {} }, $UID);
}

sub getUserTiers {
    my $self = shift;
    my ($UID) = @_;

    my $getTierSql = 'select tier from userTier WHERE UID = ?';

    $self->useDB();
    return $dbHandle->selectall_arrayref($getTierSql, { Slice => {} }, $UID);
}

sub addUser {
    my $self = shift;
    my %user = @_;

    my @valid_cols = qw[username firstName lastName active];
    my @cols;
    my @passed_values;
    my @values;
    foreach my $col (@valid_cols) {
        if (exists $user{$col}) {
            push @cols, $col;
            push @passed_values, $user{$col};
            push @values, '?';
        }
    }
    push @cols, 'created';
    push @values, 'now()';

    my $col_list = join(",", @cols);
    my $value_list = join(",", @values);
    my $sql = "INSERT INTO user ($col_list) VALUES ($value_list)";

    $self->useDB();
    if ( $dbHandle->do($sql, undef, @passed_values) ) {
        my $UID = $dbHandle->last_insert_id(undef, undef, undef, undef);
        return $UID;
    } else {
        warn $dbHandle->errstr;
        return undef;
    }
}

sub updateUser {
    my $self = shift;
    my %user = @_;

    my $existingUser = $self->getUserByUsername($user{username}) || {};
    my $UID = $existingUser->{UID};
    unless ($UID) {
        warn "User, '$user{username}' does not exists\n";
        return;
    }

    my @valid_cols = qw[firstName lastName active];
    my @sets;
    my @passed_values;

    foreach my $col (@valid_cols) {
        if (exists $user{$col}) {
            push @sets, "$col = ?";
            push @passed_values, $user{$col};
        }
    }

    my $set_list = join(",", @sets);

    my $sql = "UPDATE user SET $set_list WHERE UID = ?";

    $self->useDB();
    if ( $dbHandle->do($sql, undef, @passed_values, $UID) ) {
        return $UID;
    } else {
        warn $dbHandle->errstr;
        return undef;
    }
}

sub addUserIdent {
    my $self = shift;
    my ($UID, $authId, $authProvider) = @_;
#     if (
#         $UID !~ /^(\d+)$/
#         || $authId !~ /^(.+)$/
#         || $authProvider !~ /^(uw|basic|openid|protectnet|google|ldap)$/) {
#         warn "bad input, '@_'";
#         return;
#     }

    # Make sure there is a user with $UID
    # This would not be necessary if we were using tables with foreign keys
    unless ($self->getUserByUID($UID)) {
        warn "UID, '$UID' not found in user table";
        return;
    }

    # make sure $authId and $authProvider do not already exist
    # A composite index in the DB should assure this, however we are using MyISAM
    # TODO: check that authId/authProvider do not exists

    my $sql = 'INSERT INTO userIdent (UID, authId, authProvider) VALUES (?, ?, ?)';

    $self->useDB();
    if ($dbHandle->do($sql, undef, $UID, $authId, $authProvider)) {
        return 1;
    } else {
        warn $dbHandle->errstr;
        return undef;
    }
}

sub removeUserIdent {
    my $self = shift;
    my ($UID, $authProvider) = @_;
#     if (
#         $UID !~ /^(\d+)$/
#         || $authProvider !~ /^(uw|basic|openid|protectnet|google|ldap)$/) {
#         warn "bad input, '@_'";
#         return;
#     }

    # Make sure there is a user with $UID
    # This would not be necessary if we were using tables with foreign keys
    unless ($self->getUserByUID($UID)) {
        warn "UID, '$UID' not found in user table";
        return;
    }

    my $sql = 'DELETE FROM userIdent WHERE UID = ? AND authProvider = ?';

    $self->useDB();
    if ($dbHandle->do($sql, undef, $UID, $authProvider)) {
        return 1;
    } else {
        warn $dbHandle->errstr;
        return undef;
    }
}

sub addUserRole {
    my $self = shift;
    my ($UID, $role) = @_;
    if ( $UID !~ /^(\d+)$/) {
        warn "bad input, '@_'";
        return;
    }

    # Make sure there is a user with $UID
    # This would not be necessary if we were using tables with foreign keys
    unless ($self->getUserByUID($UID)) {
        warn "UID, '$UID' not found in user table";
        return;
    }

    my $sql =  'INSERT INTO userRole       (UID, role) VALUES (?, ?)';
    my $sql2 = 'INSERT INTO userRoleChoice (UID, role) VALUES (?, ?)';

    $self->useDB();
    $self->removeUserRole($UID, $role); # prevent duplicate role errors
    if (   $dbHandle->do($sql,  undef, $UID, $role)
        && $dbHandle->do($sql2, undef, $UID, $role)) {
        return 1;
    } else {
        warn $dbHandle->errstr;
        return undef;
    }
}


sub removeUserRole {
    my $self = shift;
    my ($UID, $role) = @_;
    if ( $UID !~ /^(\d+)$/) {
        warn "bad input, '@_'";
        return;
    }

    # Make sure there is a user with $UID
    # This would not be necessary if we were using tables with foreign keys
    unless ($self->getUserByUID($UID)) {
        warn "UID, '$UID' not found in user table";
        return;
    }

    my $sql  = 'DELETE FROM userRole       WHERE UID = ? AND role = ?';
    my $sql2 = 'DELETE FROM userRoleChoice WHERE UID = ? AND role = ?';

    $self->useDB();
    if (   $dbHandle->do($sql,  undef, $UID, $role)
        && $dbHandle->do($sql2, undef, $UID, $role)) {
        return 1;
    } else {
        warn $dbHandle->errstr;
        return undef;
    }
}

sub loginPCookie {
    my $self = shift;
    my ($pCookie, $sCookie, $authId, $authProvider) = @_;
    unless ($pCookie && $authId && $authProvider) {
        warn "Missing pid, authId, or authProvider. Got input @_";
        return 0;
    }

    my $sql = "UPDATE userAACookie 
               SET authId = ?, authProvider = ?, SID = ?, state = ?, last = ?
               WHERE PID = ?";

    $self->useDB();
    if ($dbHandle->do($sql, undef,
                      $authId, $authProvider, $sCookie, 'authenticated', time, $pCookie)) {
        return 1;
    } else {
        warn $dbHandle->errstr;
        return 0;
    }
}

sub logoutPCookie {
    my $self = shift;
    my ($pid) = @_;
    my $pCookie = $pid->{PID};
    unless ($pCookie) {
        warn "Missing pid. Got input @_";
        return 0;
    }
    my $logout_key = md5_hex(time . rand);
    my $sql = "UPDATE userAACookie SET state = ?, logoutKey = ?
               WHERE PID = ?";

    $self->useDB();
    if ($dbHandle->do($sql, undef, 'logged_out', $logout_key, $pCookie)) {
        $pid->{state} = 'logged_out';
        return 1;
    } else {
        warn $dbHandle->errstr;
        return 0;
    }
}

sub statePCookie {
    my $self = shift;
    my ($pid, $state) = @_;
    my $pCookie = $pid->{PID};
    unless ($pCookie && $state) {
        warn "Missing pid or state. Got input @_";
        return 0;
    }
    my $sql = "UPDATE userAACookie SET state = ?
               WHERE PID = ?";

    $self->useDB();
    if ($dbHandle->do($sql, undef, $state, $pCookie)) {
        $pid->{state} = $state;
        return 1;
    } else {
        warn $dbHandle->errstr;
        return 0;
    }
}

sub insertPCookie {
    my $self = shift;
    my ($pCookie, $sCookie, $logout_key) = @_;
    unless ($pCookie && $sCookie && $logout_key) {
        warn "Missing cookies or logout_key. Got input @_";
        return 0;
    }

    my $sql = "INSERT INTO userAACookie (PID, SID, logoutKey, last, created)
                 VALUES (?, ?, ?, ?, now())";

    $self->useDB();
    if ($dbHandle->do($sql, undef, $pCookie, $sCookie, $logout_key, time)) {
        return 1;
    } else {
        warn $dbHandle->errstr;
        return 0;
    }
}

sub updatePCookieLastAccess {
    my $self = shift;
    my ($pCookie) = @_;

    unless ($pCookie) {
        warn "Missing pid";
        return 0;
    }

    my $sql = "UPDATE userAACookie
               SET last = ?
               WHERE pid = ?";

    $self->useDB();
    if ($dbHandle->do($sql, undef, time, $pCookie) eq 1) {
        return 1;
    } else {
        warn "Could not update DB with PID, '$pCookie'" . $dbHandle->errstr;
        return 0;
    }
}

sub updatePCookieLogoutKey {
    my $self = shift;
    my ($pCookie) = @_;
    unless ($pCookie) {
        warn "Missing pid";
        return 0;
    }

    my $sql = "UPDATE userAACookie
               SET logoutKey = ?
               WHERE pid = ?";

    $self->useDB();
    my $logout_key = md5_hex(time . rand);
    if ($dbHandle->do($sql, undef, $logout_key, $pCookie)) {
        return 1;
    } else {
        warn $dbHandle->errstr;
        return 0;
    }
}

sub cleanupCookies {
    my $self = shift;
    $self->useDB();
    my $sql = qq[DELETE FROM userAACookie WHERE authId IS NULL and now() - created > 300];

    my $rc = $dbHandle->do($sql);
    if ($rc) {
        return $rc;
    } else {
        warn $dbHandle->errstr;
        return 0;
    }
}
1;
