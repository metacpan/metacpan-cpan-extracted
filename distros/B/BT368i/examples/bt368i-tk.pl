#!/usr/bin/perl
#
# Written by Travis Kent Beste
# Mon Aug  9 08:47:24 CDT 2010

use lib qw( ./lib ../lib );
use BT368i;

use strict;
use warnings;
use Tk;
use Tk::Dialog;
use Tk::Graph;
use Tk::NoteBook;
use Data::Dumper;

#----------------------------------------#
# main
#----------------------------------------#
my $bt368i = new BT368i(
	Port => '/dev/tty.BT-GPS-38BD5D-BT-GPSCOM',
	Baud => '115200',
);
my $rmc = new BT368i::NMEA::GP::RMC();
my $gsa = new BT368i::NMEA::GP::GSA();
my $gga = new BT368i::NMEA::GP::GGA();
my $gsv = new BT368i::NMEA::GP::GSV();
my $gll = new BT368i::NMEA::GP::GLL();
my $vtg = new BT368i::NMEA::GP::VTG();

$bt368i->BT368i::log('./log/all.log');
$rmc->BT368i::log('./log/rmc.log');
$gsa->BT368i::log('./log/gsa.log');
$gga->BT368i::log('./log/gga.log');
$gsv->BT368i::log('./log/gsv.log');
$gll->BT368i::log('./log/gll.log');
$vtg->BT368i::log('./log/vtg.log');

my $VERSION = '1.0';
my $mw      = MainWindow->new;
my $notebook;
my $menubar;

# tabs
my $gga_tab;
my $gll_tab;
my $gsa_tab;
my $vtg_tab;
my $gsv_tab;
my $gsv_graph;
my $gsv_graph_data;
my $rmc_tab;

init();

MainLoop();

#----------------------------------------#
# subroutines
#----------------------------------------#

#----------------------------------------#
# process all serial data
#----------------------------------------#
sub parse_serial_data {
	my $sentances = $bt368i->get_sentances();

	foreach my $sentance (@$sentances) {
		if ($sentance =~ /^\$GPGSA/) {
			$gsa->parse($sentance);
			#$gsa->print();
		} elsif ($sentance =~ /^\$GPRMC/) {
			$rmc->parse($sentance);
			#$rmc->print();
		} elsif ($sentance =~ /^\$GPGGA/) {
			$gga->parse($sentance);

			#$gga->print();
		} elsif ($sentance =~ /^\$GPGSV/) {
			$gsv->parse($sentance);

			if ( defined($gsv->{'sentance_1'}->{'prn_0'}->{'id'}) && ( $gsv->{'sentance_1'}->{'prn_0'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_1'}->{'prn_0'}->{'id'}} = $gsv->{'sentance_1'}->{'prn_0'}->{'signal_to_noise'}; }
			if ( defined($gsv->{'sentance_1'}->{'prn_1'}->{'id'}) && ( $gsv->{'sentance_1'}->{'prn_1'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_1'}->{'prn_1'}->{'id'}} = $gsv->{'sentance_1'}->{'prn_1'}->{'signal_to_noise'}; }
			if ( defined($gsv->{'sentance_1'}->{'prn_2'}->{'id'}) && ( $gsv->{'sentance_1'}->{'prn_2'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_1'}->{'prn_2'}->{'id'}} = $gsv->{'sentance_1'}->{'prn_2'}->{'signal_to_noise'}; }
			if ( defined($gsv->{'sentance_1'}->{'prn_3'}->{'id'}) && ( $gsv->{'sentance_1'}->{'prn_3'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_1'}->{'prn_3'}->{'id'}} = $gsv->{'sentance_1'}->{'prn_3'}->{'signal_to_noise'}; }

			if ( defined($gsv->{'sentance_2'}->{'prn_0'}->{'id'}) && ( $gsv->{'sentance_2'}->{'prn_0'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_2'}->{'prn_0'}->{'id'}} = $gsv->{'sentance_2'}->{'prn_0'}->{'signal_to_noise'}; }
			if ( defined($gsv->{'sentance_2'}->{'prn_1'}->{'id'}) && ( $gsv->{'sentance_2'}->{'prn_1'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_2'}->{'prn_1'}->{'id'}} = $gsv->{'sentance_2'}->{'prn_1'}->{'signal_to_noise'}; }
			if ( defined($gsv->{'sentance_2'}->{'prn_2'}->{'id'}) && ( $gsv->{'sentance_2'}->{'prn_2'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_2'}->{'prn_2'}->{'id'}} = $gsv->{'sentance_2'}->{'prn_2'}->{'signal_to_noise'}; }
			if ( defined($gsv->{'sentance_2'}->{'prn_3'}->{'id'}) && ( $gsv->{'sentance_2'}->{'prn_3'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_2'}->{'prn_3'}->{'id'}} = $gsv->{'sentance_2'}->{'prn_3'}->{'signal_to_noise'}; }

			if ( defined($gsv->{'sentance_3'}->{'prn_0'}->{'id'}) && ( $gsv->{'sentance_3'}->{'prn_0'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_3'}->{'prn_0'}->{'id'}} = $gsv->{'sentance_3'}->{'prn_0'}->{'signal_to_noise'}; }
			if ( defined($gsv->{'sentance_3'}->{'prn_1'}->{'id'}) && ( $gsv->{'sentance_3'}->{'prn_1'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_3'}->{'prn_1'}->{'id'}} = $gsv->{'sentance_3'}->{'prn_1'}->{'signal_to_noise'}; }
			if ( defined($gsv->{'sentance_3'}->{'prn_2'}->{'id'}) && ( $gsv->{'sentance_3'}->{'prn_2'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_3'}->{'prn_2'}->{'id'}} = $gsv->{'sentance_3'}->{'prn_2'}->{'signal_to_noise'}; }
			if ( defined($gsv->{'sentance_3'}->{'prn_3'}->{'id'}) && ( $gsv->{'sentance_3'}->{'prn_3'}->{'id'} ne "" ) ) { $gsv_graph_data->{$gsv->{'sentance_3'}->{'prn_3'}->{'id'}} = $gsv->{'sentance_3'}->{'prn_3'}->{'signal_to_noise'}; }

			if (defined ($gsv_graph) ) {
				$gsv_graph->set($gsv_graph_data);
			}

			#$gsv->print();
		} elsif ($sentance =~ /^\$GPGLL/) {
			$gll->parse($sentance);
			#$gll->print();
		} elsif ($sentance =~ /^\$GPVTG/) {
			$vtg->parse($sentance);
			#$vtg->print();
		} else {
			#print "sentance : $sentance\n";
		}
	}
}

#----------------------------------------#
# initialization
#----------------------------------------#
sub init {
	$mw->geometry("500x450+1000+100");
	$mw->repeat(100, \&parse_serial_data);
	$mw->title("bt368i $VERSION");
	$mw->iconname('bt368i');

	# notebook
	$notebook = $mw->NoteBook()->pack(-fill=>'both', -expand=>1);

	# build menubar
	$menubar = build_menubar();

	$gsv_tab = $notebook->add("Sheet 5", -label=>"GSV", -createcmd=>\&gsv);
	$rmc_tab = $notebook->add("Sheet 6", -label=>"RMC", -createcmd=>\&rmc);
	$gga_tab = $notebook->add("Sheet 2", -label=>"GGA", -createcmd=>\&gga);
	$gll_tab = $notebook->add("Sheet 4", -label=>"GLL", -createcmd=>\&gll);
	$gsa_tab = $notebook->add("Sheet 1", -label=>"GSA", -createcmd=>\&gsa);
	$vtg_tab = $notebook->add("Sheet 3", -label=>"VTG", -createcmd=>\&vtg);
}

#----------------------------------------#
#
#----------------------------------------#
sub rmc {
 	$rmc_tab->Label(-height=>1, -text => "utc_time", -anchor=>'w', -width=>25)->grid(-row=>0, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'utc_time'})->grid(-row=>0, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "status", -anchor=>'w', -width=>25)->grid(-row=>1, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'status'})->grid(-row=>1, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "latitude", -anchor=>'w', -width=>25)->grid(-row=>2, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'latitude'})->grid(-row=>2, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "latitude_hemisphere", -anchor=>'w', -width=>25)->grid(-row=>3, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'latitude_hemisphere'})->grid(-row=>3, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "longitude", -anchor=>'w', -width=>25)->grid(-row=>4, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'longitude'})->grid(-row=>4, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "longitude_hemisphere", -anchor=>'w', -width=>25)->grid(-row=>5, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'longitude_hemisphere'})->grid(-row=>5, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "speed", -anchor=>'w', -width=>25)->grid(-row=>6, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'speed'})->grid(-row=>6, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "course", -anchor=>'w', -width=>25)->grid(-row=>7, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'course'})->grid(-row=>7, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "utc_date", -anchor=>'w', -width=>25)->grid(-row=>8, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'utc_date'})->grid(-row=>8, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "magnetic_variation", -anchor=>'w', -width=>25)->grid(-row=>9, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'magnetic_variation'})->grid(-row=>9, -column=>1);

 	$rmc_tab->Label(-height=>1, -text => "magnetic_variation_direction", -anchor=>'w', -width=>25)->grid(-row=>10, -column=>0);
	$rmc_tab->Entry(-textvariable=>\$rmc->{'magnetic_variation_direction'})->grid(-row=>10, -column=>1);
}

#----------------------------------------#
#
#----------------------------------------#
sub gsv {
 	$gsv_tab->Label(-height=>1, -text => "gsv_sentance_count", -anchor=>'w', -width=>25)->grid(-row=>0, -column=>0);
	$gsv_tab->Entry(-textvariable=>\$gsv->{'gsv_sentance_count'})->grid(-row=>0, -column=>1);

 	$gsv_tab->Label(-height=>1, -text => "current_gsv_sentance", -anchor=>'w', -width=>25)->grid(-row=>1, -column=>0);
	$gsv_tab->Entry(-textvariable=>\$gsv->{'current_gsv_sentance'})->grid(-row=>1, -column=>1);

 	$gsv_tab->Label(-height=>1, -text => "number_of_satilites", -anchor=>'w', -width=>25)->grid(-row=>2, -column=>0);
	$gsv_tab->Entry(-textvariable=>\$gsv->{'number_of_satilites'})->grid(-row=>2, -column=>1);

	$gsv_graph = $gsv_tab->Graph(
		-type        => 'HBARS',
		-printvalue  => '%s %d',
		-max         => 99,
		-width       => 300,
		-barwidth    => 20,
		-xformat     => '',
		-height      => 300,
		-sortnames   => 'alpha',
		-sortreverse => '1',
	)->grid(-row=>3, -column=>0, -columnspan=>2);

	#$gsv_graph->set($gsv_graphdata); # no need to assign nothing to the graph, it'll show up soon enough
}

#----------------------------------------#
#
#----------------------------------------#
sub gga {
 	$gga_tab->Label(-height=>1, -text => "utc_time", -anchor=>'w', -width=>25)->grid(-row=>0, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'utc_time'})->grid(-row=>0, -column=>1);

	$gga_tab->Label(-text => "latitude", -anchor=>'w', -width=>25)->grid(-row=>1, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'latitude'})->grid(-row=>1, -column=>1);

	$gga_tab->Label(-text => "latitude_hemisphere", -anchor=>'w', -width=>25)->grid(-row=>2, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'latitude_hemisphere'})->grid(-row=>2, -column=>1);

	$gga_tab->Label(-text => "longitude", -anchor=>'w', -width=>25)->grid(-row=>3, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'longitude'})->grid(-row=>3, -column=>1);

	$gga_tab->Label(-text => "longitude_hemisphere", -anchor=>'w', -width=>25)->grid(-row=>4, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'longitude_hemisphere'})->grid(-row=>4, -column=>1);

	$gga_tab->Label(-text => "fix_type", -anchor=>'w', -width=>25)->grid(-row=>5, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'fix_type'})->grid(-row=>5, -column=>1);

	$gga_tab->Label(-text => "satilites_in_use", -anchor=>'w', -width=>25)->grid(-row=>6, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'satilites_in_use'})->grid(-row=>6, -column=>1);

	$gga_tab->Label(-text => "antenna_height", -anchor=>'w', -width=>25)->grid(-row=>7, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'antenna_height'})->grid(-row=>7, -column=>1);

	$gga_tab->Label(-text => "geoidal_height", -anchor=>'w', -width=>25)->grid(-row=>8, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'geoidal_height'})->grid(-row=>8, -column=>1);

	$gga_tab->Label(-text => "dgps_data_age", -anchor=>'w', -width=>25)->grid(-row=>9, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'dgps_data_age'})->grid(-row=>9, -column=>1);

	$gga_tab->Label(-text => "dgps_reference_station_id", -anchor=>'w', -width=>25)->grid(-row=>10, -column=>0);
	$gga_tab->Entry(-textvariable=>\$gga->{'dgps_reference_station_id'})->grid(-row=>10, -column=>1);
}

#----------------------------------------#
#
#----------------------------------------#
sub gll {
	$gll_tab->Label(-text => "latitude", -anchor=>'w', -width=>25)->grid(-row=>0, -column=>0);
	$gll_tab->Entry(-textvariable=>\$gll->{'latitude'})->grid(-row=>0, -column=>1);

	$gll_tab->Label(-text => "latitude_hemisphere", -anchor=>'w', -width=>25)->grid(-row=>1, -column=>0);
	$gll_tab->Entry(-textvariable=>\$gll->{'latitude_hemisphere'})->grid(-row=>1, -column=>1);

	$gll_tab->Label(-text => "longitude", -anchor=>'w', -width=>25)->grid(-row=>2, -column=>0);
	$gll_tab->Entry(-textvariable=>\$gll->{'longitude'})->grid(-row=>2, -column=>1);

	$gll_tab->Label(-text => "longitude_hemisphere", -anchor=>'w', -width=>25)->grid(-row=>3, -column=>0);
	$gll_tab->Entry(-textvariable=>\$gll->{'longitude_hemisphere'})->grid(-row=>3, -column=>1);

	$gll_tab->Label(-text => "utc_time", -anchor=>'w', -width=>25)->grid(-row=>4, -column=>0);
	$gll_tab->Entry(-textvariable=>\$gll->{'utc_time'})->grid(-row=>4, -column=>1);

	$gll_tab->Label(-text => "data_valid", -anchor=>'w', -width=>25)->grid(-row=>5, -column=>0);
	$gll_tab->Entry(-textvariable=>\$gll->{'data_valid'})->grid(-row=>5, -column=>1);
}

#----------------------------------------#
#
#----------------------------------------#
sub gsa {
	$gsa_tab->Label(-text => "mode", -anchor=>'w', -width=>25)->grid(-row=>0, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'mode'})->grid(-row=>0, -column=>1);

	$gsa_tab->Label(-text => "fix_type", -anchor=>'w', -width=>25)->grid(-row=>1, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'fix_type'})->grid(-row=>1, -column=>1);

	$gsa_tab->Label(-text => "prn_00", -anchor=>'w', -width=>25)->grid(-row=>2, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_00'})->grid(-row=>2, -column=>1);

	$gsa_tab->Label(-text => "prn_01", -anchor=>'w', -width=>25)->grid(-row=>3, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_01'})->grid(-row=>3, -column=>1);

	$gsa_tab->Label(-text => "prn_02", -anchor=>'w', -width=>25)->grid(-row=>4, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_02'})->grid(-row=>4, -column=>1);

	$gsa_tab->Label(-text => "prn_03", -anchor=>'w', -width=>25)->grid(-row=>5, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_03'})->grid(-row=>5, -column=>1);

	$gsa_tab->Label(-text => "prn_04", -anchor=>'w', -width=>25)->grid(-row=>6, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_04'})->grid(-row=>6, -column=>1);

	$gsa_tab->Label(-text => "prn_05", -anchor=>'w', -width=>25)->grid(-row=>7, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_05'})->grid(-row=>7, -column=>1);

	$gsa_tab->Label(-text => "prn_06", -anchor=>'w', -width=>25)->grid(-row=>8, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_06'})->grid(-row=>8, -column=>1);

	$gsa_tab->Label(-text => "prn_07", -anchor=>'w', -width=>25)->grid(-row=>9, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_07'})->grid(-row=>9, -column=>1);

	$gsa_tab->Label(-text => "prn_08", -anchor=>'w', -width=>25)->grid(-row=>10, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_08'})->grid(-row=>10, -column=>1);

	$gsa_tab->Label(-text => "prn_09", -anchor=>'w', -width=>25)->grid(-row=>11, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_09'})->grid(-row=>11, -column=>1);

	$gsa_tab->Label(-text => "prn_10", -anchor=>'w', -width=>25)->grid(-row=>12, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_10'})->grid(-row=>12, -column=>1);

	$gsa_tab->Label(-text => "prn_11", -anchor=>'w', -width=>25)->grid(-row=>13, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'prn_11'})->grid(-row=>13, -column=>1);

	$gsa_tab->Label(-text => "position_diliution", -anchor=>'w', -width=>25)->grid(-row=>14, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'position_diliution'})->grid(-row=>14, -column=>1);

	$gsa_tab->Label(-text => "horizontal_diliution", -anchor=>'w', -width=>25)->grid(-row=>15, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'horizontal_diliution'})->grid(-row=>15, -column=>1);

	$gsa_tab->Label(-text => "vertical_diliution", -anchor=>'w', -width=>25)->grid(-row=>16, -column=>0);
	$gsa_tab->Entry(-textvariable=>\$gsa->{'vertical_diliution'})->grid(-row=>16, -column=>1);
}

#----------------------------------------#
#
#----------------------------------------#
sub vtg {
	$vtg_tab->Label(-text => "true_track", -anchor=>'w', -width=>25)->grid(-row=>0, -column=>0);
	$vtg_tab->Entry(-textvariable=>\$vtg->{'true_track'})->grid(-row=>0, -column=>1);

	$vtg_tab->Label(-text => "magnetic_track", -anchor=>'w', -width=>25)->grid(-row=>1, -column=>0);
	$vtg_tab->Entry(-textvariable=>\$vtg->{'magnetic_track'})->grid(-row=>1, -column=>1);

	$vtg_tab->Label(-text => "ground_speed_knots", -anchor=>'w', -width=>25)->grid(-row=>2, -column=>0);
	$vtg_tab->Entry(-textvariable=>\$vtg->{'ground_speed_knots'})->grid(-row=>2, -column=>1);

	$vtg_tab->Label(-text => "ground_speed_kilometers", -anchor=>'w', -width=>25)->grid(-row=>3, -column=>0);
	$vtg_tab->Entry(-textvariable=>\$vtg->{'ground_speed_kilometers'})->grid(-row=>3, -column=>1);
}

#----------------------------------------#
#
#----------------------------------------#
sub select_port {
	my $port = shift;

	#print "selecing $port...\n";

	if ($port ne $bt368i->{serialport}) {
		if ($bt368i->{serial}) {
			$bt368i->{serial}->close || die "failed to close serialport";
			undef $bt368i->{serial}; # frees memory back to perl
		}

		# assign what they selected
		$bt368i->{serialport} = $port;

		# connect to the serial port
		$bt368i->connect();
	}

}

#----------------------------------------#
# build the menu bar
#----------------------------------------#
sub build_menubar {
	# Create the menubar and File and Quit menubuttons.  Note
	# that the cascade's menu widget is automatically created.
	my $menubar = $mw->Menu;

	$mw->configure(-menu => $menubar);

	my $file = $menubar->cascade(-label => '~File');
	my $port = $menubar->cascade(-label => '~Port');
	my $help = $menubar->cascade(-label => '~Help', -tearoff => 0);

	open(CMD, "ls -l /dev/tty.*|");
	while(<CMD>) {
		chomp();
		$_ =~ /tty\.(.*)$/;
		my $tty = $1;
		# Create the menuitems for each menu.  First, the File menu item.
		$port->command(-label => $tty, -command => [\&select_port, $tty]);
	}
	close(CMD);

	# Create the menuitems for each menu.  First, the File menu item.
	$file->command(-label => "~Quit", -command => \&quit);

	# Finally, the Help menuitems.
	$help->command(-label => 'Version');
	$help->separator;
	$help->command(-label => 'About');
	my $ver_dialog =   $mw->Dialog(
		-title   => 'BT368i Version',
		-text    => "BT368i\n\nVersion $VERSION",
		-buttons => ['OK'],
		-bitmap  => 'info');
	my $about_dialog = $mw->Dialog(
		-title   => 'About BT368i',
		-text    => 'BT368i was built by Travis Kent Beste.  He can be reached at travis@tencorners.com',
		-buttons => ['OK']);
	my $menu = $help->cget('-menu');
	$menu->entryconfigure('Version', -command => [$ver_dialog   => 'Show']);
	$menu->entryconfigure('About',   -command => [$about_dialog => 'Show']);

	$menubar;                       # return the menubar
}

#----------------------------------------#
# quit
#----------------------------------------#
sub quit {
	exit(0);
}
