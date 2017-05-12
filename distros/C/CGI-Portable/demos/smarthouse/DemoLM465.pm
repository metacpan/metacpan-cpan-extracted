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

package DemoLM465;
use strict;
use warnings;
use CGI::Portable;
use HTML::FormTemplate;

sub main {
	my ($class, $globals) = @_;
	my $address = $globals->pref( 'address' );
	my $ra_field_defs = [
		{
			visible_title => "Select Bright Level",
			type => 'popup_menu',
			name => 'brightness',
			values => [map { $_*10 } (0..10)],
		}, {
			type => 'submit', 
			label => 'Update',
		},
	];
	my $form = HTML::FormTemplate->new();
	$form->form_submit_url( $globals->recall_url() );
	$form->field_definitions( $ra_field_defs );
	$form->user_input( $globals->user_post() );
	$globals->set_page_body(
		$form->make_html_input_form( 1 ),
		"\n<P>Device Type: LM465 Dimmer Switch<BR>",
		"\nDevice Address: $address<BR>", 
		"\nCommunication: Write Only (Current Status Unknown)</P>",
	);
	$class->write_to_device( $globals );
}

sub write_to_device {
	# this doesn't do anything yet since we can't get hardware interface
	# working, but maybe later...
}

1;
