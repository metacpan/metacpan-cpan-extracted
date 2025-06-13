package CallBackery::User;

# $Id: User.pm 539 2013-12-09 22:28:11Z oetiker $

# sorted hashes
use Mojo::Base -base, -signatures;
use Carp qw(croak confess);
use Mojo::Util qw(b64_decode b64_encode secure_compare);
use Mojo::JSON qw(encode_json decode_json);
use CallBackery::Exception qw(mkerror);
use Time::HiRes qw(gettimeofday);
use Mojo::Util qw(hmac_sha1_sum);

=head1 NAME

CallBackery::User - tell me about the current user

=head1 SYNOPSIS

 use CallBackery::User;
 my $user = CallBackery::User->new($self->controller);

 $user->werk;
 $user->may('right'); # does the user have the given right
 $user->id;

=head1 DESCRIPTION

All the methods if L<Mojo::Base> as well as the following

=head2 $self->controller

the controller

=cut

has controller => undef, weak => 1;

has app => sub ($self) {
    $self->controller->app;
}, weak => 1;

has log => sub ($self) {
    $self->controller ? $self->controller->log : $self->app->log;
}, weak => 1;

=head2 $self->userId

By default the userId is numeric and represents a user account. For system tasks, it gets set to alphabetic identifiers.
The following alphabetic identifiers do exist:

 __CONSOLE when running in the config console mode
 __CONFIG for backup and restore tasks

=cut




=head2 userId

return the user id if the session user is valid.

=cut

has userId => sub {
    my $self = shift;
    my $cookieUserId = $self->cookieConf->{u};
    my $db = $self->mojoSqlDb;
    my $userInfo = $self->db->fetchRow('cbuser',{id=>$cookieUserId});
    if (my $userId = $userInfo->{cbuser_id}){
        $self->userInfo($userInfo);
        $self->db->userName($userInfo->{cbuser_login});
        return $userId;
    }
    my $userCount = [$db->dbh->selectrow_array('SELECT count(cbuser_id) FROM '
        . $db->dbh->quote_identifier("cbuser"))]->[0];
    return ($userCount == 0 ? '__ROOT' : undef );
};


has db => sub {
    shift->app->database;
};

=head2 $self->mojoSqlDb

returns a pointer to one of the Database object of a Mojo::Pg instance.
=cut

sub mojoSqlDb {
    shift->db->mojoSqlDb;
};

=head2 $self->userInfo

returns a hash of information about the current user.

=cut

has userInfo => sub {
    my $self = shift;
    my $userId = $self->userId // return {};
    if ($userId eq '__ROOT'){
        return {cbuser_id => '__ROOT'};
    }
    if ($userId eq '__SHELL'){
        return {cbuser_id => '__SHELL'};
    }
    $self->db->fetchRow('cbuser',{id=>$self->userId}) // {};
};


=head2 $self->loginName

returns a human readable login name for the current user

=cut

has loginName => sub {
    shift->userInfo->{cbuser_login} // '*UNKNOWN*';
};


=head2 $self->sessionConf

Extracts the session config from the cookie from the X-Session-Cookie header or the xsc parameter.
If the xsc parameter is set, its timestamp must be no older than 2 seconds.

=cut

has headerSessionCookie => sub {
    my $self = shift;
    my $c = $self->controller;
    return $c->req->headers->header('X-Session-Cookie');
};

has paramSessionCookie => sub {
    my $self = shift;
    my $c = $self->controller;
    return $c->param('xsc');
};

has firstSecret => sub {
    shift->app->secrets()->[0];
};

sub isUserAuthenticated {
    my $self = shift;
    $self->userInfo->{cbuser_id} ? 1 : 0;
};

has cookieConf => sub {
    my $self = shift;
    my $headerCookie = $self->headerSessionCookie;
    my $paramCookie = $self->paramSessionCookie;

    my ($data,$check) = split /:/,($headerCookie || $paramCookie || ''),2;

    return {} if not ($data and $check);

    my $secret = $self->firstSecret;

    my $checkTest = Mojo::Util::hmac_sha1_sum($data, $secret);
    if (not secure_compare($check,$checkTest)){
        $self->log->debug(qq{Bad signed cookie possible hacking attempt.});
        return {};
    }

    my $conf = eval {
        local $SIG{__DIE__};
        decode_json(b64_decode($data))
    };
    if ($@){
        $self->log->debug("Invalid cookie structure in '$data': $@");
        return {};
    }

    if (ref $conf ne 'HASH'){
        $self->log->debug("Cookie structure not a hash");
        return {};
    }

    if (not $conf->{t}){
        $self->log->debug("Cookie timestamp is invalid");
        return {};
    }

    if ($paramCookie and gettimeofday() - $conf->{t} > 300.0){
        $self->log->debug(qq{Cookie is expired});
        die mkerror(38445,"cookie has expired");
    }

    return $conf;
};

=head2 $user->login($login,$password)

login the user object. If login return 1 you can then makeSessionCookie.

=cut

sub login {
    my $self = shift;
    my $login = shift;
    my $password = shift;
    my $cfg = $self->app->config->cfgHash;
    my $remoteAddress = eval { $self->controller->tx->remote_address } // 'UNKNOWN_IP';
    if ($cfg->{sesame_pass} and $cfg->{sesame_user}
        and $login and $password
        and $login eq $cfg->{sesame_user}
        and hmac_sha1_sum($password) eq $cfg->{sesame_pass}){
        $self->log->info("SESAME Login for $login from $remoteAddress successful");
        $self->session(userId=>'__ROOT');
        return 1;
    }

    my $db = $self->db;
    my $userData = $db->fetchRow('cbuser',{login=>$login});
    if (not $userData) {
        $self->log->info("Login attempt with unknown user $login from $remoteAddress failed");
        return undef;
    }

    if ($userData->{cbuser_password} and $password
        and hmac_sha1_sum($password) eq $userData->{cbuser_password} ){
        $self->userId($userData->{cbuser_id});
        $self->log->info("Login for $login from $remoteAddress successful");
        return 1;
    }
    $self->log->info("Login attempt with wrong password for $login from $remoteAddress failed");
    return undef;
}

=head2 $bool = $self->C<may>(right);

Check if the user has the right indicated.

=cut

sub may {
    my $self = shift;
    my $right = shift;
    # root has all the rights
    if (($self->userId // '') eq '__ROOT'){
        return 1;
    }
    my $db = $self->db;
    my $rightId = $db->lookUp('cbright','key',$right);
    my $userId = $self->userId;
    return ($db->matchData('cbuserright',{cbuser=>$userId,cbright=>$rightId}) ? 1 : 0);
}

=head2 makeSessionCookie()

Returns a timestamped, signed session cookie containing the current userId.

=cut

sub makeSessionCookie {
    my $self = shift;
    my $timeout = shift;
    my $now = gettimeofday;
    my $conf = b64_encode(encode_json({
        u => $self->userId,
        t => $now,
    }));
    $conf =~ s/\s+//g;
    my $secret = $self->firstSecret;
    my $check = Mojo::Util::hmac_sha1_sum($conf, $secret);
    return $conf.':'.$check;
}

sub DESTROY ($self) {
    # we are only interested in objects that get destroyed during
    # global destruction as this is a potential problem
    my $class = ref($self) // "child of ". __PACKAGE__;
    if (${^GLOBAL_PHASE} ne 'DESTRUCT') {
        # $self->log->debug($class." DESTROYed");
        return;
    }
    if ($self && ref $self->log){
        $self->log->warn("late destruction of $class object during global destruction") unless $self->{prototype};
        return;
    }
    warn "extra late destruction of $class object during global destruction\n" unless ref $self and $self->{prototype};
}


1;
__END__

=head1 COPYRIGHT

Copyright (c) 2013 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobi Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2010-06-12 to 1.0 initial
 2013-11-19 to 1.1 mojo port

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
