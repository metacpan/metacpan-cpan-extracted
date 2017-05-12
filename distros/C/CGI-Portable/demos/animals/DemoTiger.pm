package DemoTiger;
use strict;
use warnings;
use CGI::Portable;
use HTML::FormTemplate;

sub main {
	my ($class, $globals) = @_;
	my $ra_field_defs = $globals->resolve_prefs_node_to_array( 
		$globals->pref( 'field_defs' ) );
	if( $globals->get_error() ) {
		$globals->set_page_body( 
			"Sorry I can not do that form thing now because we are missing ", 
			"critical settings that say what the questions are.",
			"Reason: ", $globals->get_error(),
		);
		$globals->add_no_error();
		return( 0 );
	}
	my $form = HTML::FormTemplate->new();
	$form->form_submit_url( $globals->recall_url() );
	$form->field_definitions( $ra_field_defs );
	$form->user_input( $globals->user_post() );
	$globals->set_page_body(
		'<H1>Here Are Some Questions</H1>',
		$form->make_html_input_form( 1 ),
		'<HR>',
		'<H1>Answers From Last Time If Any</H1>',
		$form->new_form() ? '' : $form->make_html_input_echo( 1 ),
	);
}

1;
