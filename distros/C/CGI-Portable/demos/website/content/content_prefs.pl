my $rh_preferences = { 
	add_page_style_code => [
		'body {background-color: white; background-image: none}', 
		'h1, h2 {text-align: center}', 
		'td {text-align: left; vertical-align: top}',
	],
	delegate_list => [
		{
			module_name => 'CGI::Portable::AppStatic',
			preferences => 'menu_prefs.pl',
			leave_scalars => 1,
		},
		{
			module_name => 'CGI::Portable::AppMultiScreen',
			preferences => {
				prepend_page_body => "\n<hr />\n",
				delegate_list => {
					external => {
						module_name => 'DemoRedirect',
						preferences => { low_http_window_target => 'external_link_window' },
					},
					frontdoor => {
						module_name => 'DemoTextFile',
						preferences => { filename => 'frontdoor.html' },
					},
					resume => {
						module_name => 'DemoTextFile',
						preferences => { filename => 'resume.html' },
					},
					mysites => {
						module_name => 'DemoTextFile',
						preferences => { filename => 'mysites.html' },
					},
					mailme => {
						module_name => 'DemoMailForm',
						preferences => {},
					},
					guestbook => {
						module_name => 'DemoGuestBook',
						preferences => {
							custom_fd => 1,
							field_defn => 'guestbook_questions.txt',
							fd_in_seqf => 1,
							fn_messages => 'guestbook_messages.txt',
						},
					},
					links => {
						module_name => 'DemoTextFile',
						preferences => { filename => 'links.html' },
					},
				},
				default_delegate => 'frontdoor',
				append_page_body => "\n<hr />\n",
			},
		},
		{
			module_name => 'CGI::Portable::AppStatic',
			preferences => 'menu_prefs.pl',
			leave_scalars => 1,
		},
	],
	append_page_body => <<__endquote,
<p><em>This site is a simple example of what can be done with CGI::Portable and 
the Dynamic Website Generator collection of Perl 5 modules, copyright (c) 
1999-2001, Darren R. Duncan.</em></p>
__endquote
	page_search_and_replace => {
		__mailme_url__ => "__url_path__=/mailme",
		__external_id__ => "__url_path__=/external&url",
	},
};
