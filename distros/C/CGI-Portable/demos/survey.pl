#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/darren/perl_lib';

require CGI::Portable;
my $globals = CGI::Portable->new();

require CGI::Portable::AdapterCGI;
my $io = CGI::Portable::AdapterCGI->new();
$io->fetch_user_input( $globals );

$globals->default_application_title( 'Demo Email Form' );
$globals->default_maintainer_name( 'Darren Duncan' );
$globals->default_maintainer_email_address( 'demo@DarrenDuncan.net' );

my %CONFIG = (
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
	email_subj => 'Another Survey Response',
	msg_new_title => 'Try Our Survey',  # custom title for new messages
	msg_new_head => <<__endquote,   # custom heading for new messages
<H1>Leave A Message</H1>
<P>Please leave a message after the beep.  Answer the questions as faithfully
and truthfully as you can, as we have a lie detector set up and any false 
answers will be met with spam.</P>
__endquote
);

$globals->set_prefs( \%CONFIG );
$globals->call_component( 'DemoMailForm' );

$io->send_user_output( $globals );

1;
