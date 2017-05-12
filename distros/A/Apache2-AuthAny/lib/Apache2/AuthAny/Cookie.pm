package Apache2::AuthAny::Cookie;

use strict;

use CGI::Cookie ();
use Apache2::Cookie ();
use Apache2::Request ();
use Digest::MD5 qw(md5_hex);

use Apache2::AuthAny::DB ();
use Apache2::AuthAny::AuthUtil ();
use Data::Dumper qw(Dumper);

use Apache2::Const -compile => qw(HTTP_UNAUTHORIZED REDIRECT OK);
our $aaDB;
our $VERSION = '0.201';

sub post_login {
    my $r = shift;
    my $uri = $r->uri;

    my ($authProvider) =  ($uri =~ m{/aa_auth/(.*?)/});
    $authProvider =~ s/_aa-key_.*//;

    my $get_params = Apache2::Request->new($r);
    my $location = $get_params->param('req');
    unless ($location) {
        $r->log->warn("Apache2::AuthAny::Cookie: missing req redirect after login with $authProvider");
        $location = "/";
    }

    $aaDB = Apache2::AuthAny::DB->new() unless $aaDB;
    unless ($aaDB) {
        my $msg = "Cannot connect to database.";
        $r->log->crit("AuthAny::Cookie: $msg");
        return Apache2::AuthAny::AuthUtil::goToGATE($r, 'tech', {msg => $msg});
    }

    my $authId = $ENV{REMOTE_USER} || $r->user;
    if ($authId) {
        my $map_file = "$ENV{AUTH_ANY_CONFIG_ROOT}/provider-mapping.pl";
        if (-f $map_file) {
            open(MAPPING, "<$map_file") || die "$map_file ?? $!";
            my @cts = <MAPPING>;
            my $contents = "@cts";
            close(MAPPING);
            my $mapping = eval $contents;
            if ($mapping->{$authProvider}) {
                my $orig = $authId;
                $authId =~ s/$mapping->{$authProvider}//;
                if ($authId eq $orig) {
                    $r->log->error("AuthAny::Cookie: mapping had no effect");
                }
            }
        }
    } else {
        my $msg = 'Please try another login method';
        $r->log->error("Cookie: Auth method at '$uri' did not set REMOTE_USER");
        return Apache2::AuthAny::AuthUtil::goToGATE($r, 'authen', {msg => $msg});
    }

    ######################################################################
    # Cookie
    ######################################################################

    my $pid = $r->pnotes('pid');
    my $sCookie = md5_hex(time . rand);
    if ($aaDB->loginPCookie($pid->{PID}, $sCookie, $authId, $authProvider)) {
        my $new_sid_cookie = CGI::Cookie->new(-name  => 'AA_SID',
                                              -value => $sCookie,
                                             );
        $r->err_headers_out->add('Set-Cookie' => $new_sid_cookie);
    } else {
        my $msg = "Could not write to DB";
        $r->log->crit("Apache2::AuthAny::Cookie: " . $msg);
        return Apache2::AuthAny::AuthUtil::goToGATE($r, 'authen', {msg => $msg});
    }

    blank_shibsession($r);

    $r->headers_out->set(Location => $location);
    $r->log->info("Apache2::AuthAny::Cookie: Location => $location");
    return Apache2::Const::REDIRECT;

}

# NOTE: These are not a handlers
sub cookie_util {
    my $r = shift;
    $aaDB = Apache2::AuthAny::DB->new() unless $aaDB;
    my $jar = Apache2::Cookie::Jar->new($r);
    my @cookies;
    my ($pidCookie, $sidCookie);

    eval {
        if ($jar && $jar->cookies) {
            $sidCookie = $jar->cookies->get('AA_SID')->value if $jar->cookies->get('AA_SID');
            $pidCookie = $jar->cookies->get('AA_PID')->value if $jar->cookies->get('AA_PID');
            @cookies = $jar->cookies;
        }
    };
    if ($@) {
        $r->log->error("Cookie error $@");
    }
    my $shibsession_name;
    my $shibsession_value;
    foreach my $cookie (@cookies) {
        if ($cookie =~ /_shibsession_/) {
            $r->log->error("Cookie: duplicate shibsession cookies found") if $shibsession_name;
            $shibsession_name  = $cookie;
            $shibsession_value = $jar->cookies($shibsession_name);
        }
    }

    return {pidCookie => $pidCookie,
            sidCookie => $sidCookie,
            shibsession_name  => $shibsession_name,
            shibsession_value => $shibsession_value,
           };
}

sub blank_shibsession {
    my $r = shift;

    my $cookies = cookie_util($r);
    if ($cookies->{shibsession_value}) {
        my $shib_empty = CGI::Cookie->new(-name  => $cookies->{shibsession_name},
                                          -value => '',
                                         );
        $r->err_headers_out->add('Set-Cookie' => $shib_empty);
    }
}

sub pid {
    my $r = shift;
    my $cookies = cookie_util($r);
    my $pid;
    my $pCookie = $cookies->{pidCookie};
    my $sCookie = $cookies->{sidCookie};

    if ($pCookie) {
       $pid = $aaDB->getUserCookieByPID($pCookie) || {};
       if ($pid && $pid->{PID}) {
           unless ($sCookie && $pid->{SID} && $sCookie eq $pid->{SID}) {
               # There has been no login during this session
               $pid->{SID} = '';
           }
       } else {
           $r->log->error("AuthAny: " . "PID, '$pCookie' missing from DB");
           $pid = generate_pid($r);
       }
    } else {
        $pid = generate_pid($r);
    }
#    warn $r->uri . " --- " . Dumper($pid);
    return $pid;
}

sub generate_pid {
    my $r = shift;

    my $pCookie       = md5_hex(time . rand);
    my $sCookie       = md5_hex(time . rand);
    my $logout_key = md5_hex(time . rand);

    if ($aaDB->insertPCookie($pCookie, $sCookie, $logout_key)) {
        my $new_pid_cookie = CGI::Cookie->new(-name  => 'AA_PID',
                                              -value => $pCookie,
                                              -expires => '+3y',
                                             );
        my $new_sid_cookie = CGI::Cookie->new(-name  => 'AA_SID',
                                              -value => $sCookie,
                                             );
        $r->err_headers_out->add('Set-Cookie' => $new_pid_cookie);
        $r->err_headers_out->add('Set-Cookie' => $new_sid_cookie);
        return {PID => $pCookie,
                SID => $sCookie,
                logoutKey => $logout_key,
                state => 'logged_out',
               };
    } else {
        die "AuthAny::Cookie: Could not write to DB";
    }
}


1;
