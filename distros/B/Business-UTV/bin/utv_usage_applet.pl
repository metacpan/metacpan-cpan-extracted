#!/usr/bin/perl -w

use strict;
use warnings;

use Business::UTV;

use Gtk2::TrayIcon;
use POSIX;

# you need to add your utv id/password and your name
# your name is used to verify the login so it should
# be the name of the account owner
my $id = ;
my $password = "";
my $name = "";

my $label;

my $utv = Business::UTV->login( $id , $password ,  { "name" => $name } );
if( $utv )
{
	my $usage = $utv->usage();
	if( $usage )
	{
		print "Upload  - " . $usage->{"upload"} . "\n";
		print "Download - " . $usage->{"download"} . "\n"; 

		Gtk2->init();
		my $icon = Gtk2::TrayIcon->new( "utv broadband usage notification" );
		$label = Gtk2::Label->new( "loading" );
		$icon->add( $label );
		update_text();
		$icon->show_all;

		Glib::Timeout->add ( 3600000 , \&update_text );
		
		Gtk2->main;
		exit(0);
	}
	else
	{
		print "Failed to get usage :(\n";
		exit(1);
	}
}
else
{
	print "Login failed :(\n";
	exit(1);
}

sub update_text
{
	my $usage = $utv->usage();
	my $up = $usage->{"upload"};
	my $down = $usage->{"download"};

	Gtk2::Label::set_text( $label , strftime( "%H:%M" , localtime() ) . " Up " . int($up) . " Down " . int($down ) );
	
	return 1;
}


=head1 NAME 

utv_usage_applet.pl - Gnome2 tray icon displaying monthly bandwidth usage

=head1 SYNOPSIS

This script adds a tray icon to your gnome notification area.
The tray icon will display the current monthly upload/download
usage in megabytes of your UTV internet account.

The displayed values will be updated every 60 minutes but
typically the values provided by the utv website only update
every couple of day.

=head1 CONFIGURATION

Currently the script is configured by editing 3 perl variables.

 id		- utv internet id
 password	- utv internet password
 name		- name of the account holder


=head1 WARNING

This warning is (mostly) from Simon Cozens' Finance::Bank::LloydsTSB, and seems almost as apt here.
 
This is code for pretending to be you online, and that could mean your money, and that means BE CAREFUL. 
You are encouraged, nay, expected, to audit the source of this module yourself to reassure yourself 
that I am not doing anything untoward with your account data. This software is useful to me, but is 
provided under NO GUARANTEE, explicit or implied.

=head1 SEE ALSO

Business::UTV
utv_usage_tray.pl
