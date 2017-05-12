#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/darren/perl_lib';

require CGI::Portable;
my $globals = CGI::Portable->new();

use Cwd;
$globals->file_path_root( cwd() );  # let us default to current working dir
$globals->file_path_delimiter( $^O=~/Mac/i ? ":" : $^O=~/Win/i ? "\\" : "/" );

require CGI::Portable::AdapterCGI;
my $io = CGI::Portable::AdapterCGI->new();
$io->fetch_user_input( $globals );

$globals->default_application_title( 'Demo Guest Book' );
$globals->default_maintainer_name( 'Darren Duncan' );
$globals->default_maintainer_email_address( 'demo@DarrenDuncan.net' );

my %CONFIG = (
	fn_messages => 'guestbook_messages.txt',  # file in simple Boulder format
	custom_fd => 1,
	field_defn => [
		{
			visible_title => "What's your age?",
			type => 'textfield',
			name => 'age',
			is_required => 1,
			validation_rule => '\d',
			error_message => 'You must enter a number.',
		}, {
			visible_title => "What's the combination?",
			type => 'checkbox_group',
			name => 'words',
			'values' => ['eenie', 'meenie', 'minie', 'moe'],
			default => ['eenie', 'minie'],
			labels => [qw( This That And Another )],
		}, {
			visible_title => "Who do you love?",
			type => 'textfield',
			name => 'name',
		}, {
			visible_title => "What's your favorite colour?",
			type => 'popup_menu',
			name => 'color',
			'values' => ['red', 'green', 'blue', 'chartreuse'],
		},
	],
	sign_by_default => 1,
	msg_list_show_email => 1,
	email_subj => 'Your Visitor Has Left A Message',
	msg_new_title => 'Leave A Message',  # custom title for new messages
	msg_new_head => <<__endquote,   # custom heading for new messages
<H1>Leave A Message</H1>
<P>Please leave a message after the beep.  Answer the questions as faithfully
and truthfully as you can, as we have a lie detector set up and any false 
answers will be met with spam.</P>
__endquote
	msg_list_title => 'Previous Reflections',  # custom title when reading
	msg_list_head => <<__endquote,   # custom heading for reading
<H1>Wise Words That You Never Wrote</H1>
<P>Here are the messages that previous visitors wrote.  Please stay awhile 
and soak in the goodness.  You never know what you don't read.</P>
__endquote
);

$globals->current_user_path_level( 1 );
$globals->set_prefs( \%CONFIG );
$globals->call_component( 'DemoGuestBook' );

$io->send_user_output( $globals );

1;
