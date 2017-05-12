#!/usr/bin/perl -w
BEGIN { use CGI::Carp qw(fatalsToBrowser); eval qq|use lib '$ENV{DOCUMENT_ROOT}/../lib';|; } # or wherever your lib is 
use strict;
use CGI::Session::Submitted;
use CGI qw(:all);
use Smart::Comments '###';

my $s = new CGI::Session::Submitted;

$s->run({
	bkg => 'white',
	rm => 'rm_basic_settings',
	help_on => 1,
	address_line1 => undef,
	address_line2 => undef,
	address_line3 => undef,	
	address_city => undef,
	address_state => undef,
	address_zip => undef,
	message => undef,
});



my $rm = {
		rm_basic_settings		=> \&rm_basic_settings,
		rm_address_settings	=> \&rm_address_settings,
		rm_message				=> \&rm_message,
		rm_finish				=> \&rm_finish,
		rm_done					=> \&rm_done,
};

is_complete();

my @params = $s->param;

my $RM = $s->param('rm');

my $out = &{$rm->{$RM}};

print $out;

exit;




sub styl {
	my $bkg = $s->param('bkg');

	my $style = "<style>
	html {
	background-color: $bkg;
	}
</style>
	";
	return $style;
}


sub rm_done {

	
	my $out = header().start_html().styl()

	.h1('Done.')	
	.start_form('POST', $ENV{SCRIPT_NAME})

	.p('Ok. Done. Start again?');
	$s->clear;
	
	$out.= nav() .end_form(). small($s->id);
	$out.= end_html();
	return $out;



}



sub nav {
	#my $out = start_form('POST', $ENV{SCRIPT_NAME});
	my $out;

	$out.= hr(). p(
	scrolling_list(
	'rm',
	[ keys %{$rm} ],
	[$s->param('rm')],
	1,
	'',
	)
	.submit('submit','go')

	.(  
		$s->param('help_on') ? 
			a({href=>'?help_on=0'}, 'help off') : 	
			a({href=>'?help_on=1'}, 'help on') 	
	 )	
	);
	
	#$out.= end_form();
	return $out;
}



sub rm_basic_settings {

	my $out =header().start_html().styl()
	.h1('basic settings')	
	.start_form('POST', $ENV{SCRIPT_NAME});

	$out.= p(
	radio_group(
		'help_on',
		[1,0], #choices
		[$s->param('help_on')], #default choice
		'true', # linebreak
		{ 1=>'help on', 0=>'help off' }
	));
	

	$out.= p(
	radio_group(
		'bkg',
		[qw(blue red white cyan green brown orange)], #choices
		[$s->param('bkg')], #default choice
		'true', # linebreak
	));


	
	$out.= nav(). small($s->id);
	$out.= end_form().end_html();
	return $out;
}





sub rm_address_settings {
	my $out =header().start_html().styl()

	.h1('address settings')	
	.start_form('POST', $ENV{SCRIPT_NAME});

my $state = {
0 =>  'Please choose state..',
AL => "ALABAMA",
AK => "ALASKA",
AZ => "ARIZONA",
AR => "ARKANSAS",
CA => "CALIFORNIA",
CO => "COLORADO",
CT => "CONNECTICUT",
DE => "DELAWARE",
DC => "DISTRICT OF COLUMBIA",
FL => "FLORIDA",
GA => "GEORGIA",
HI => "HAWAII",
ID => "IDAHO",
IL => "ILLINOIS",
IN => "INDIANA",
IA => "IOWA",
KS => "KANSAS",
KY => "KENTUCKY",
LA => "LOUISIANA",
ME => "MAINE",
MD => "MARYLAND",
MA => "MASSACHUSETTS",
MI => "MICHIGAN",
MN => "MINNESOTA",
MS => "MISSISSIPPI",
MO => "MISSOURI",
MT => "MONTANA",
NE => "NEBRASKA",
NV => "NEVADA",
NH => "NEW HAMPSHIRE",
NJ => "NEW JERSEY",
NM => "NEW MEXICO",
NY => "NEW YORK",
NC => "NORTH CAROLINA",
ND => "NORTH DAKOTA",
OH => "OHIO",
OK => "OKLAHOMA",
OR => "OREGON",
PA => "PENNSYLVANIA",
RI => "RHODE ISLAND",
SC => "SOUTH CAROLINA",
SD => "SOUTH DAKOTA",
TN => "TENNESSEE",
TX => "TEXAS",
UT => "UTAH",
VT => "VERMONT",
VA => "VIRGINIA",
WA => "WASHINGTON",
WV => "WEST VIRGINIA",
WI => "WISCONSIN",
WY => "WYOMING",
};


	$out.= 
	 p('address line 1: ' . textfield('address_line1', $s->param('address_line1'),50,80))
	.p('address line 2: ' . textfield('address_line2', $s->param('address_line2'),50,80))
	.p('address line 3: ' . textfield('address_line3', $s->param('address_line3'),50,80))
	.p('city: ' . textfield('address_city',  $s->param('address_city'), 50,80));

	$out.= p('state: '.
	scrolling_list(
	'address_state',
	[ sort keys %{$state} ],
	[$s->param('address_state')],
	1,
	'',
	$state,
	));


	$out.=p('zip: ' . textfield('address_zip', $s->param('address_zip'),12,12));

	
	$out.= nav(). small($s->id);
	$out.= end_form().end_html();
	return $out;
}	




sub rm_message {	
	my $out =header().start_html().styl()

	.h1('message?')	
	.start_form('POST', $ENV{SCRIPT_NAME});

	$out.= p( textarea( 'message', $s->param('message'), 10, 50) );
	$out.= nav(). small($s->id);
	$out.= end_form().end_html();
	return $out;

}




sub is_complete {
	my $incomplete = 0;
	for ( qw(address_line1 address_city address_state address_zip message) ){
		$s->param($_) or $incomplete++;
	}
	
	$incomplete or return 1;
	
	delete $rm->{rm_done};

	return 0;
}

sub rm_finish {


	my $out =header().start_html().styl()

	.h1('finished?')	
	.start_form('POST', $ENV{SCRIPT_NAME});


	for ( qw(address_line1 address_city address_state address_zip message) ){
		my $key = $_;
		my $val = $s->param($key) ? $s->param($key) : '(incomplete)';		
		$out.= p("<b>$key:</b> $val");	
	}
	
	if ( is_complete() ) {
		$out.= p('All required information is entered. Feel free to revise your choices.')
		.p('Select done from the menu to finish.');
	}
	else {
		$out.= p('Sorry. Some required fields are incomplete. Please revise.');		
	}

	$out.= nav(). small($s->id);
	$out.= end_form().end_html();
	return $out;



}


