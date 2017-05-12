# SmartHouse - A Web-based X10 Device Controller in Perl.
# This demo is based on a college lab assignment.  It doesn't actually 
# control any hardware, but is a simple web interface for such a program 
# should one want to extend it in that manner.  This is meant to show how 
# CGI::Portable can be used in a wide variety of environments, not just 
# ordinary database or web sites.  If you wanted to extend it then you 
# should use modules like ControlX10::CM17, ControlX10::CM11, or 
# Device::SerialPort.  On the other hand, if you want a very complete 
# (and complicated) Perl solution then you can download Bruce Winter's 
# free open-source MisterHouse instead at "http://www.misterhouse.net".

my $rh_prefs = {
	handlers => {
		bed_lamp => {
			menu_name => 'Bed Room Lamp',
			mod_name => 'DemoLM465',
			mod_prefs => { address => 'A2', },
		},
		shop_lamp => {
			menu_name => 'Workshop Light',
			mod_name => 'DemoLM465',
			mod_prefs => { address => 'A5', },
		},
		living_lamp => {
			menu_name => 'Living Room Lamp',
			mod_name => 'DemoLM465',
			mod_prefs => { address => 'A6', },
		},
	},
};
