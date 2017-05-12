# Tests utilities for Wizard
#
# DESCRIPTION
#   Description
# # AUTHORS
#   Pavel Boldin (davinchi), <boldin.pavel@gmail.com>
#
#========================================================================

package Test::Wizard;

use strict;
use warnings;
use Test::More;
use Carp ();

our ($next_url, $wid, $m);

sub ok_redirect {
    my ($get, $redirect, $text, $request) = @_;

    $get ||= $next_url;

    $m->get($get) if !defined $request || $request ne 'noget' ;

    if( $request && $request eq 'back') {
        $m->back() for (1..($_[4]||1)) ;
    }

    if ($m->status == 200 && !$redirect) {
        ok($m->success, $text);
        return;
    } elsif ($m->status == 302 && $redirect) {
        ok($m->status == 302, $text.' got');
        like ($next_url = $m->res->header('location'), 
              defined $wid ? 
                qr/^$redirect\?wid=[a-zA-Z0-9]{32}/ :
                qr/^$redirect/
                , $text.' redirect ok');

        $next_url =~ /wid=([a-zA-Z0-9]{32})/; 

        if ($wid) {
            $wid eq $1 or Carp::confess 'new wid unexpected';
        } else {
            $wid = $1;
        }

        return;
    }

    is(undef, $next_url, "no redirecting at all"); die;
}

sub import {
    my $self = shift;
    no strict 'refs';

    *{caller().'::ok_redirect'} = \&ok_redirect;
    *{caller().'::'.$_} = *{$self.'::'.$_} foreach qw(next_url m wid);
}

1;
