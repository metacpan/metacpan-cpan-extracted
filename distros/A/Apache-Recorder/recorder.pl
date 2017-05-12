#!/usr/bin/perl -wT
#<[tmpl:99]>
use strict;
use CGI;
use CGI::Cookie;

my ( $q ) = new CGI;

my ( $action ) = $q->param( 'action' ) || 'welcome';

if ( $action eq 'welcome' ) {
    print $q->header;
    &print_welcome();
}
elsif ( $action eq 'set_cookie' ) {
    my ( $semi_random ) = &get_semi_random;
    &set_cookie( $q, $semi_random );
    print $q->header;
    &print_confirmation( $semi_random );
}

sub set_cookie {
    my ( $q ) = shift; 
    my ( $semi_random ) = shift;
    my ( %cookies ) = fetch CGI::Cookie;
    my ( $id, $return );
    foreach my $key (keys %cookies ) {
        if ( $key eq 'HTTPRecorderID' ) {
	    $id = $cookies{ 'HTTPRecorderID' }->value;    
	}
    }

    unless ( $id ) {
	my ( $cookie ) = $q->cookie(
	    -name => 'HTTPRecorderID',
	    -value => $semi_random,
	    -path => '/'
	);
	print $q->header(-cookie=> $cookie);
	$return = 1;
    }
    $return; 
}

sub get_semi_random {
    my ( @chars ) = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
    my ( $semi_random ) = join("", @chars[ map { rand @chars } (1 .. 8) ]);
    return $semi_random;
}

sub print_welcome {
print qq~
    <html>
        <head>
	    <title>Launch page for Apache::Recorder configuration</title>
	</head>
	<body bgcolor='FFFFFF'>
	    <p>
	    Welcome to Apache::Recorder. By clicking the button below, you will 
	    set a cookie that will allow a handler to track all of your movements on the 
	    present domain.  That handler, in turn, will create a map of your "click-through" 
	    of the site, including GET and POST parameters.  Upon returning to this script, 
	    you will be able to disable that cookie, and then create a simple script that 
	    will allow automated testing of the path that you followed.  
	    </p>
	    <p>
	    When you are ready to begin, please click on the "Set Cookie" button below.
	    </p>
	    <form action='/cgi-bin/recorder.pl' method='POST'>
	        <input type='submit' value='Set Cookie'>
		<input type='hidden' name='action' id='action' value='set_cookie'>
	    </form>
	</body>
    </html>
~;
}

sub print_confirmation {
    my ( $semi_random ) = shift;
    print qq~
        <html>
	    <head>
	        <title>Recorder is ready to go.</title>
	    </head>
	    <body>
	        The recorder has been configured correctly.  
		<p>You are now free to visit static pages and scripts that exist on this domain.  
		(Note: if you leave this domain, you will no longer have a valid cookie -- 
		this will stop Apache::Recorder from recording your path.</p>
                <p>When you have finished visiting the pages and scripts that you want to record, 
		you will need to write a brief script to automate the testing process.  See 
		<font face='courier'>perldoc HTTP::RecordedSession</font> for a sample program.  
		You will need to record the following session id for use in this script: 
		<strong>$semi_random</strong>.</p>

	    </body>
	</html>
    ~;
}
