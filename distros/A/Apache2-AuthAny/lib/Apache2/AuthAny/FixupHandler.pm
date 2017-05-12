package Apache2::AuthAny::FixupHandler;

use strict;
use Apache2::Const -compile => qw(OK DECLINED HTTP_UNAUTHORIZED);
use Data::Dumper qw(Dumper);
use Apache2::AuthAny::DB qw();
our $aaDB;
our $VERSION = '0.201';

sub handler {
    my $r = shift;
    if (!$ENV{AA_SCRIPTED} && $ENV{AA_STATE} eq 'authenticated') {
        # not already timed out
        my $pid = $r->pnotes('pid');
        $aaDB = Apache2::AuthAny::DB->new() unless $aaDB;
        $aaDB->updatePCookieLastAccess($pid->{PID}) || warn "Could not update last access";
    }
    return Apache2::Const::DECLINED;
}

###!!!! MOVE THIS TO Cookie.pm
# called after basic login
sub update_logout_key {
    my $r = shift;
    my $pid = $r->pnotes('pid');
    $aaDB = Apache2::AuthAny::DB->new() unless $aaDB;
    $aaDB->updatePCookieLogoutKey($pid->{PID})  || warn "Could not update last access";
    return Apache2::Const::DECLINED;
}

1;

