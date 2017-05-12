#!/usr/bin/perl -w

use strict;
use warnings;

use Win32::GUI;
use Business::UTV;

$SIG{QUIT} = "DEFAULT";

# you need to add your utv id/password and your name
# your name is used to verify the login so it should
# be the name of the account owner
my $id = "";
my $password = "";
my $name = "";

# most people would like to hide the console while the script is 
# running
my $hideConsole = 1;

my ($DOS) = Win32::GUI::GetPerlWindow() if $hideConsole;
Win32::GUI::Hide($DOS) if $hideConsole;


my $utv;
my $usage;


my $main = Win32::GUI::Window->new( -name => 'Main', -text => 'UTV Usage',-width => 100, -height => 100);
my $icon = new Win32::GUI::Icon('GUIPERL.ICO');
my $ni = $main->AddNotifyIcon(-name => "NI", -id => 1,-icon => $icon, -tip => "retrieving data" );

my $popupMenu = Win32::GUI::Menu->new("Options" => "Options",
                                       ">Quit" => {-name => "Quit" , -onClick => sub { return -1; } } );

updateUsageText_Timer();
$main->AddTimer( "updateUsageText" , 60000 );


Win32::GUI::Dialog();
Win32::GUI::Show($DOS) if $hideConsole;


sub NI_RightClick
{	
   my ($x, $y) = Win32::GUI::GetCursorPos;
   Win32::GUI::TrackPopupMenu($main->{-handle}, $popupMenu->{Options}, $x, $y);
}


sub getUsageText
{
	unless($utv)
	{
		$utv = Business::UTV->login( $id , $password , { "name" => $name } );
	}

	if( $utv )
	{
		my $usage = $utv->usage();
		if( $usage )
		{
			$usage = "up " . int($usage->{"upload"}) . " Down " . int($usage->{"download"});
		}
		else
		{
			$usage = "ERROR - " . $Business::UTV::errstr;
		}
	}
	else
	{
		$usage = "ERROR - " . $Business::UTV::errstr;
	}
}	


sub updateUsageText_Timer
{
	my $text = getUsageText();
	$ni->Change( -name => "NI" , -id => 1, -icon => $icon, -tip => $text );
	return 1;
}


=head1 NAME 

utv_usage_tray.pl - Windows system tray icon displaying monthly bandwidth usage

=head1 SYNOPSIS

This script adds a tray icon to your system tray.
When the mouse pointer hovers over it the tray icon will display the current 
monthly upload/download usage in megabytes of your UTV internet account.
To remove the icon right click on it and select quit.

The displayed values will be updated every 60 minutes but
typically the values provided by the utv website only update
every couple of day.

=head1 CONFIGURATION

Currently the script is configured by editing 4 perl variables.

 id		- utv internet id
 password	- utv internet password
 name		- name of the account holder
 hideConsole	- by default perl displays a console while it is running
		  with this set to true no console is displayed

=head1 WARNING

This warning is (mostly) from Simon Cozens' Finance::Bank::LloydsTSB, and seems almost as apt here.
 
This is code for pretending to be you online, and that could mean your money, and that means BE CAREFUL. 
You are encouraged, nay, expected, to audit the source of this module yourself to reassure yourself 
that I am not doing anything untoward with your account data. This software is useful to me, but is 
provided under NO GUARANTEE, explicit or implied.

=head1 SEE ALSO

Business::UTV
utv_usage_applet.pl
