#!/usr/bin/perl
# Author: Michele Beltrame
# Inspired by the original code by Dave Newquist (Peoplesign creator)
# License: perl5

use strict;
use warnings;

use lib '../lib';

use CGI::Carp qw/fatalsToBrowser/;
use CGI;
use HTML::Tiny;

use Captcha::Peoplesign;

# Sample testing key (might not work in the future)!
my $peoplesignKey = "5543333573134de45c8fdf9b4e8c1733";

# Name for this location (must match the one used when creating the key)
my $clientLocation = "PerlTest";

my $peoplesignOptions = "language=english&useDispersedPics=false&numPanels=2&numSmallPhotos=6&useDragAndDrop=false&challengeType=pairThePhoto&category=(all)&hideResponseAreaWhenInactive=false";
# ...it could also be an hash
#my $peoplesignOptions = {
#    challengeType         => "pairThePhoto",
#    numPanels             => "2",
#    numSmallPhotos        => "8",
#    useDispersedPics      => "false",
#    smallPhotoAreaWidth   => ""
#};

# Pass { html_mode => 'xml' } if you use XHTML
my $ps = Captcha::Peoplesign->new();

my $query = CGI->new();
my $h = HTML::Tiny->new(mode => 'html');

print $query->header(
    -type       => 'text/html'
);

if ( $ENV{REQUEST_METHOD} eq 'POST' ) {
    my $challengeSessionID = $query->param('challengeSessionID');
    my $challengeResponseString = $query->param('captcha_peoplesignCRS');
    
    #Use the peoplesign client the check the users's response
    my $res = $ps->check_answer({
        ps_key          => $peoplesignKey,
        ps_location     => $clientLocation, 
        ps_sessionid    => $challengeSessionID,
        ps_response     => $challengeResponseString,
    });
    
    if ( $res->{is_valid} ) {
        print _make_page($h->p([
            $h->strong('OK, you\'re human!')
        ]));
        exit 0;
    }
    
    warn $res->{error}; # This goes to error_log

    # If you redirect to the original form, be sure to pass the
    # challengeSessionID (via session, cookie, GET parameter, ...)
    # (we do not redirect here, we just re-display the form, which
    # is likely what most people do)
}

my $challengeSessionID = $query->param('challengeSessionID') || '';

my $peoplesignHTML = $ps->get_html({
    ps_key          => $peoplesignKey,
    ps_location     => $clientLocation,
    ps_options      => $peoplesignOptions,
    ps_clientip     => $query->remote_addr,
    ps_sessionid    => $challengeSessionID,
});

my $form = $h->form({
    method  => 'POST',
    action  => $query->request_uri,
}, [
    $peoplesignHTML,
    $h->input({
        type    => 'submit',
        value   => 'submit',
    }),
]);

print _make_page($form);

exit 0;


sub _make_page {
    my $content = shift;
       
    my $html = '<!DOCTYPE HTML>';
    
    $html .= $h->html([
        $h->head([
            $h->meta({
                'http-equiv'    => 'pragma',
                'content'       => 'no-cache',
            }),
            $h->meta({
                'http-equiv'    => 'expires',
                'content'       => '-1',
            }),
            $h->meta({
                'http-equiv'    => 'content-type',
                'content'       => 'text/html; charset=UTF-8',
            }),
            $h->title('Peoplesign Perl integration demo'),
        ]),
        $h->body([
            $h->div({
                style   => 'width:500px; margin: 0 auto 0 auto',
            }, [
                $h->p('This page is a demonstration of the peoplesign perl plugin'),
                $content,
            ])
        ]),
    ]);
    
    return $html;
}
