package Apache2::AuthAny::AuthUtil;

use strict;
use URI::Escape;
use Data::Dumper;
use Apache2::Const -compile => qw(OK DECLINED HTTP_UNAUTHORIZED REDIRECT);
use CGI::Cookie ();

use Apache2::AuthAny::DB ();
our $aaDB;
our $VERSION = '0.201';

sub goToGATE {
    my $r = shift;
    my $reason = shift;

    my $subReason = shift;
    my $request = uri_escape($r->unparsed_uri);

    # prevent redirect loops
    $request =~ s/aalogin/aadisabled/g;

    my $dumped_subReason = $subReason ? ", subReason => " . Data::Dumper::Dumper($subReason) : '';
    $r->log->info("Apache2::AuthAny::AuthUtil: Going to gate with request => '$request'" .
                  "reason => '$reason' $dumped_subReason" );

    my $cf = Apache2::Module::get_config('Apache2::AuthAny', $r->server, $r->per_dir_config) || {};
    my $gateURL = $cf->{AuthAnyGateURL};

    my $gate = "$gateURL?req=$request";

    if ($reason) {
        $gate .= "&reason=$reason";
        if ($reason eq 'unknown') {
            $gate .= "&authProvider=$ENV{AA_PROVIDER}&authId=$ENV{AA_USER}";
        }
        if ($reason eq 'authz') {
            $gate .= "&username=$ENV{REMOTE_USER}";
        }
        if ($subReason && $subReason->{req_roles}) {
            $gate .= "&req_roles=$subReason->{req_roles}";
            $gate .= "&user_roles=$subReason->{user_roles}";
        }
        if ($subReason && $subReason->{msg}) {
            $gate .= "&msg=$subReason->{msg}";
        }
    }

    $r->headers_out->set(Location => $gate);
    return Apache2::Const::REDIRECT;
}

sub logout {
    my $r = shift;
    my $pid = shift;
    my $aaDB = Apache2::AuthAny::DB->new() unless $aaDB;
    unless ($aaDB->logoutPCookie($pid)) {
        die "logout failed";
    }

    my $request = $r->unparsed_uri;

    # prevent redirect loops
    $request =~ s/aalogout/aadisabled/g;

    $r->headers_out->set(Location => $request);
    return Apache2::Const::REDIRECT;
}

sub login {
    my $r = shift;
    my $pid = shift;
    my $aaDB = Apache2::AuthAny::DB->new() unless $aaDB;
    unless ($aaDB->logoutPCookie($pid)) {
        die "logout failed";
    }

    my $request = $r->unparsed_uri;

    # prevent redirect loops
    $request =~ s/aalogout/aadisabled/g;

    $r->headers_out->set(Location => $request);
    return Apache2::Const::REDIRECT;
}


1;

