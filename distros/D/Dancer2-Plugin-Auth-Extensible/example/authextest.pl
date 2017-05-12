#!/usr/bin/perl

use Dancer2;
use lib '../lib';
use Dancer2::Plugin::Auth::Extensible;

get '/' => sub {
    my $content = "<h1>Non-secret home page!</h1>";
    if (my $user = logged_in_user()) {
        $content .= "<p>Hi there, $user->{name}!</p>";
        $content .= '<p><a href="/logout">logout</a></p>';
    } else {
        $content .= "<p>Why not <a href=\"/login\">log in</a>?</p>";
        $content .= '<p>Users:<br>';
        $content .= 'beerdrinker/password<br>';
        $content .= 'vodkadrinker/secret<br>';
        $content .= 'arakdrinker/arak<br>';
        $content .= '</p>';
    }

    $content .= <<LINKS;
<p><a href="/secret">Psst, wanna know a secret?</a></p>
<p><a href="/beer">Or maybe you want a beer</a></p>
<p><a href="/vodka">Or, a vodka?</a></p>
<p><a href="/sake">Or, sake?</a></p>
LINKS

    if (user_has_role('Beer_Drinker')) {
        $content .= "<p>You can drink beer</p>";
    }
    if (user_has_role('Wine_Drinker')) {
        $content .= "<p>You can drink wine</p>";
    }
    if (user_has_role('Vodka_Drinker')) {
        $content .= "<p>You can drink vodka</p>";
    }
    if (user_has_role('Arak_Drinker')) {
        $content .= "<p>You can drink Arak</p>";
    }
    if (user_has_role('Heavy_Drinker')) {
        $content .= "<p>You can drink anything</p>";
    }

    return $content;
};

get '/secret' => require_login sub { "Only logged-in users can see this. You are logged in as user " . logged_in_user->{name} };

get '/beer' => require_any_role [qw(Beer_Drinker Vodka_Drinker)], sub {
    "Any drinker can get beer.";
};

get '/vodka' => require_role Vodka_Drinker => sub {
    "Only vode drinkers get vodka";
};

get '/sake' => require_role Heavy_Drinker => sub {
    "Only heavy drinkers get sake";
};

get '/realm' => require_login sub {
    "You are logged in using realm: " . session->{logged_in_user_realm};
};
dance();
