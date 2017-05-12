#!/usr/bin/perl -w

use strict;
use ExtUtils::MakeMaker;

my @bins = ();
my @libs = ( "Test::MockObject" , "Test::Warn" , "Test::NoWarnings" , "LWP" , "Net::SSLeay" , "URI::Escape" );

my $install_gnome_bin = prompt( "Do you wish to install the gnome2 applet?" , "n" );

if( $install_gnome_bin =~ /y/i )
{
	push(@libs , "Gtk2::TrayIcon" , "POSIX" );
	push(@bins , "bin/utv_usage_applet.pl" );
}

my $install_win_bin = prompt( "Do you wish to install the windows system tray?" , "n" );
if( $install_win_bin =~ /y/i )
{
	push(@libs , "Win32::GUI" );
	push(@bins , "bin/guiperl.ico" , "bin/utv_usage_tray.pl" );
}
		


WriteMakefile(
        NAME            => "Business::UTV",
        VERSION_FROM    => "lib/Business/UTV.pm",
	AUTHOR		=> "Peter Sinnott link\@redbrick.dcu.ie",
	EXE_FILES	=> \@bins,
	PREREQ_PM	=> { map { $_ => 0 } @libs },
	LICENSE		=> "perl"
);
