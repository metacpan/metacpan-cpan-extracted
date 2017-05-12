#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use App::PM::Announce;
my $app = App::PM::Announce->new;
my $feed = App::PM::Announce::Feed::linkedin->new(
    app => $app,
    username => 'robertkrimen+alice8378@gmail.com',
    password => 'test8378',
    uri => 'http://www.linkedin.com/groupAnswers?start=&gid=1873425',
);
my $key = int rand $$;
$feed->announce(
    title => "Event title ($key)",
    description => "Event description ($key)",
);

ok(1);

__END__

use WWW::Mechanize;
use HTTP::Request::Common qw/POST/;

my $agent = WWW::Mechanize->new;

$agent->get("https://www.linkedin.com/secure/login");

$agent->submit_form(
    fields => {
        session_key => 'robertkrimen+alice8378@gmail.com',
        session_password => 'test8378',
    },
    form_number => 2,
    button => 'session_login',
);

die "Wasn't logged in" unless $agent->content =~ m/If you are not automatically redirected/;

$agent->get("http://www.linkedin.com/groupAnswers?start=&gid=1873425");

$agent->submit_form(
    fields => {
        question => 'Hello, World (' . int( rand $$ ) . ')',
        questionDetail => 'Lorem ipsum',
    },
    form_number => 4,
    button => 'createQuestion',
);

die "Not sure if discussion was posted" unless $agent->content =~ m/Your discussion has been posted successfully/;

#$agent->request(
#    POST "http://sf.pm.org/cgi-bin/greymatter/gm.cgi", {
#        authorname => 'Test',
#        authorpassword => '',
#        newentrysubject => 'Test subject',
#        newentrymaintext => 'Test maintext',
#        newentrymoretext => '',
#        newentryallowkarma => 'no',
#        newentryallowcomments => 'no',
#        newentrystayattop => 'no',
#        thomas => 'Add This Entry',
#    },
#);

ok(1);
