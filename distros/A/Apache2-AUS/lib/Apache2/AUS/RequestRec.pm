#!perl

package Apache2::AUS::RequestRec;

use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestUtil;

*Apache2::RequestRec::aus_session = \&aus_session;

return 1;

sub aus_session {
    my($r, $session) = @_;
    
    my $old_session =
        $r->pnotes('aus_session') ||
        ($r->main && $r->main->pnotes('aus_session')) ||
        undef;
    
    $session = $old_session unless $session;
        
    if($session) {
        if($r->main) {
            $r->main->pnotes('aus_session', $session);
        } else {
            $r->pnotes('aus_session', $session);
        }
        
        $r->subprocess_env->set(AUS_SESSION_ID => $session->id);
    }

    return $old_session;
}

sub remove_aus_session {
    my $r = shift;
    $r->pnotes->clear('aus_session');
    return;
}
