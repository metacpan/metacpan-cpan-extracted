package TestApp::ASP::Welcome;

use strict;
use DateTime;
use Text::Lorem;

sub head {
    my ( $args, $html ) = @_;
    $TestApp::ASP::Response->Include( 'templates/welcome_head.inc', $args, $html );
}

sub body {
    my ( $args, $html ) = @_;

    # Storing something in $Application
    my $start_time = $main::Application->{start_time} || time;

    # Passing variables into template
    $args->{application_start_time} = DateTime->from_epoch( epoch => $start_time )->datetime;
    $args->{session_request_count} = $main::Session->{request_count};

    # Storing large amounts of text into $Session and $Application to watch for
    # memory leaks
    $main::Session->{random_text}     = Text::Lorem->new->paragraphs( 1000 );
    $main::Application->{random_text} = Text::Lorem->new->paragraphs( 1000 );

    # Store a circular reference into $Session
    my $welcome_object_1 = bless {}, __PACKAGE__;
    my $welcome_object_2 = bless {
        welcome_object_1 => $welcome_object_1,
    }, __PACKAGE__;
    my $welcome_object_3 = bless {
        welcome_object_1 => $welcome_object_1,
        welcome_object_2 => $welcome_object_2,
    }, __PACKAGE__;
    $welcome_object_1->{welcome_object_2} = $welcome_object_2;
    $welcome_object_1->{welcome_object_3} = $welcome_object_3;

    $main::Session->{welcome_object_1} = $welcome_object_1;
    $main::Session->{welcome_object_2} = $welcome_object_2;
    $main::Session->{welcome_object_3} = $welcome_object_3;

    # Do a substitution to prove this code ran
    $html =~ s/APP_NAME/TestApp::ASP/g;

    $TestApp::ASP::Response->Include( 'templates/welcome_body.inc', $args, $html );
}

1;
