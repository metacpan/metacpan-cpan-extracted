=head1 NAME

DemoGuestBook - Demo of CGI::Portable that implements a complete guest 
book with unlimited questions that also e-mails submissions to the website owner.

=cut

######################################################################

package DemoGuestBook;
require 5.004;

# Copyright (c) 1999-2004, Darren R. Duncan.  All rights reserved.  This module
# is free software; you can redistribute it and/or modify it under the same terms
# as Perl itself.  However, I do request that this copyright information and
# credits remain attached to the file.  If you modify this module and
# redistribute a changed version then please attach a note listing the
# modifications.  This module is available "as-is" and the author can not be held
# accountable for any problems resulting from its use.

use strict;
use warnings;
use vars qw($VERSION @ISA);
$VERSION = '0.50';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	Fcntl
	Symbol
	Net::SMTP 2.15 (earlier versions may work)

=head2 Nonstandard Modules

	CGI::Portable 0.50
	CGI::Portable::AppStatic 0.50
	CGI::MultiValuedHash 1.09
	HTML::FormTemplate 2.021

=cut

######################################################################

use Fcntl qw(:DEFAULT :flock);
use Symbol;
use CGI::Portable 0.50;
use CGI::Portable::AppStatic 0.50;
@ISA = qw(CGI::Portable::AppStatic);
use CGI::MultiValuedHash 1.09;
use HTML::FormTemplate 2.021;

######################################################################

=head1 SYNOPSIS

=head2 Use Default Question

	#!/usr/bin/perl
	use strict;
	use warnings;

	require CGI::Portable;
	my $globals = CGI::Portable->new();

	use Cwd;
	$globals->file_path_root( cwd() );  # let us default to current working dir
	$globals->file_path_delimiter( $^O=~/Mac/i ? ":" : $^O=~/Win/i ? "\\" : "/" );

	require CGI::Portable::AdapterCGI;
	my $io = CGI::Portable::AdapterCGI->new();
	$io->fetch_user_input( $globals );

	$globals->default_application_title( 'Demo Guest Book' );
	$globals->default_maintainer_name( 'Tony Simons' );
	$globals->default_maintainer_email_address( 'tony@aardvark.net' );

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',  # file in simple Boulder format
	);

	$globals->current_user_path_level( 1 );
	$globals->set_prefs( \%CONFIG );
	$globals->call_component( 'DemoGuestBook' );

	$io->send_user_output( $globals );

	1;

=head2 Use Custom Questions Defined Here

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
	);

=head2 Use Custom Questions Defined In Perl File

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',  # file in simple Boulder format
		custom_fd => 1,
		field_defn => 'guestbook_questions.txt',  # do Perl code to make array ref
	);

=head2 Use Custom Questions Defined In simple Boulder File

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',  # file in simple Boulder format
		custom_fd => 1,
		field_defn => 'guestbook_questions.txt',  # file in simple Boulder format
		fd_in_seqf => 1,
	);

=head2 Default To Signing Mode When Mode Not Specified In User Path

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',
		sign_by_default => 1,
	);

=head2 Show Email Addresses In Message Listings (Default Is No Show)

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',
		msg_list_show_email => 1,
	);

=head2 Customize Subject Of Your Emails

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',
		email_subj => 'Your Visitor Has Left A Message',
	);

=head2 Customize Webpage Intro Text

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',
		msg_new_title => 'Leave A Message',  # custom title for new messages
		msg_new_head => <<__endquote,   # custom heading for new messages
	<h1>Leave A Message</h1>
	<p>Please leave a message after the beep.  Answer the questions as faithfully
	and truthfully as you can, as we have a lie detector set up and any false 
	answers will be met with spam.</p>
	__endquote
		msg_list_title => 'Previous Reflections',  # custom title when reading
		msg_list_head => <<__endquote,   # custom heading for reading
	<h1>Wise Words That You Never Wrote</h1>
	<p>Here are the messages that previous visitors wrote.  Please stay awhile 
	and soak in the goodness.  You never know what you don't read.</p>
	__endquote
	);

=head1 DESCRIPTION

This Perl 5 object class is part of a demonstration of CGI::Portable in use.  
It is one of a set of "application components" that takes its settings and user 
input through CGI::Portable and uses that class to send its user output.  
This demo module set can be used together to implement a web site complete with 
static html pages, e-mail forms, guest books, segmented text document display, 
usage tracking, and url-forwarding.  Of course, true to the intent of 
CGI::Portable, each of the modules in this demo set can be used independantly 
of the others.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 PUBLIC FUNCTIONS AND METHODS

=head2 main( GLOBALS )

You invoke this method to run the application component that is encapsulated by 
this class.  The required argument GLOBALS is an CGI::Portable object that 
you have previously configured to hold the instance settings and user input for 
this class.  When this method returns then the encapsulated application will 
have finished and you can get its user output from the CGI::Portable object.

=head1 MODES THAT THIS MODULE OPERATES IN

DemoGuestBook has separate modes for signing the guest book and viewing 
the existing messages.  The signing mode is accessed through the relative 
user path /sign.  The reading mode is accessed through /read.  Each of the modes 
is designed to present links going to the other mode.  When the GuestBook is 
started up it defaults to the reading mode when no valid mode is specified.  
If the preference 'sign_by_default' is true then GuestBook defaults to the 
signing mode instead.

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

	custom_fd   # if true, we use a custom list of 
		# questions in the form; otherwise, we simply have a "message" field.
	field_defn  # instruc for how to make form fields
		# If array ref, this is taken literally as list of definitions.
		# Otherwise, this is name of a file containing the definitions.  
		# Field definitions are processed by HTML::FormTemplate, so please see 
		# its POD to know what options you have in your forms.
	fd_in_seqf  # if true, above file is of the 
		# format that is a simplified form of Boulder; else it is Perl code

	fn_messages  # file messages go in, if filed

	sign_by_default  # if true, we default to the signing screen; false is read
	
	msg_list_show_email  # if true, guest emails are shown, else they are not

	email_subj  # if set, use when sending e-mails

	msg_new_title  # custom title for new messages
	msg_new_head   # custom heading for new messages

	msg_list_title  # custom title when reading
	msg_list_head   # custom heading for reading

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site page preferences:
my $PKEY_CUSTOM_FD  = 'custom_fd';  # if true, we use a custom list of 
	# questions in the form; otherwise, we simply have a "message" field.
my $PKEY_FIELD_DEFN = 'field_defn';  # instruc for how to make form fields
	# If array ref, this is taken literally as list of definitions.
	# Otherwise, this is name of a file containing the definitions.
	# Field definitions are processed by HTML::FormTemplate, so please see 
	# its POD to know what options you have in your forms.
my $PKEY_FD_IN_SEQF = 'fd_in_seqf';  # if true, above file is of the 
	# format that is a simplified form of Boulder; else it is Perl code
my $PKEY_FN_MESSAGES = 'fn_messages';  # file messages go in, if filed
my $PKEY_SIGN_BY_DEFAULT = 'sign_by_default';  # if true, default to sign mode
my $PKEY_MSG_LIST_SHOW_EMAIL  = 'msg_list_show_email'; # true to show emails
my $PKEY_EMAIL_SUBJ = 'email_subj';  # if set, use when sending e-mails
my $PKEY_MSG_NEW_TITLE = 'msg_new_title'; # custom title for new messages
my $PKEY_MSG_NEW_HEAD  = 'msg_new_head'; # custom heading for new messages
my $PKEY_MSG_LIST_TITLE = 'msg_list_title'; # custom title when reading
my $PKEY_MSG_LIST_HEAD  = 'msg_list_head'; # custom heading for reading

# Names of the fields in our html form:
my $FFN_NAMEREAL = 'namereal';  # user's real name
my $FFN_EMAIL    = 'email';     # user's e-mail address
my $FFN_WANTCOPY = 'wantcopy';  # true if sender wants a copy

# This is where the user's message goes, by default.
my @DEF_FORM_QUESTIONS = ( {
	visible_title => "Your Message",
	type => 'textarea',
	name => 'message',
	rows => 5,
	columns => 50,
	is_required => 1,
	error_message => 'You must enter a message.',
} );

# Extra fields in guest book log file
my $LFN_SUBMIT_DATE   = 'submit_date';
my $LFN_SUBMIT_DOMAIN = 'submit_domain';

# Constant values used in this class go here:
my $EMPTY_FIELD_ECHO_STRING = '(no answer)';
my $VRP_SIGN = 'sign';  # in this sub path is the book signing page
	# if no sub path is chosen, we view guest book by default
my $VRP_READ = 'read';  # in this sub path is the message listing page
	# if no sub path is chosen, we default to this
my $TOKEN_SIGN = '__gb_mode_sign_token__';  # embed in text, then replace
my $TOKEN_READ = '__gb_mode_read_token__';  # embed in text, then replace

######################################################################

sub main {
	my ($class, $globals) = @_;
	my $self = bless( {}, ref($class) || $class );

	UNIVERSAL::isa( $globals, 'CGI::Portable' ) or 
		die "initializer is not a valid CGI::Portable object";

	$self->set_static_low_replace( $globals );

	$self->{$KEY_SITE_GLOBALS} = $globals;
	$self->main_dispatch();

	$self->set_static_high_replace( $globals );
	$self->set_static_attach_unordered( $globals );
	$self->set_static_attach_ordered( $globals );
	$self->set_static_search_and_replace( $globals );
}

######################################################################

sub main_dispatch {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	SWITCH: {
		my $ra_field_defs = $self->get_field_definitions();  # sets err on probl
		if( $globals->get_error() ) {
			$self->no_questions_error();
			$globals->add_no_error();  # clears it now dealt with
			last SWITCH;
		}

		my $form = HTML::FormTemplate->new();
		$form->form_submit_url( $globals->recall_url() );
		$form->field_definitions( $ra_field_defs );

		unless( $self->is_in_signing_mode() ) {
			$self->read_guest_book( $form );
			last SWITCH;
		}

		$form->user_input( $globals->user_post() )->trim_bounding_whitespace();

		if( $form->new_form() ) {  # if we're called first time
			$self->new_message( $form );
			last SWITCH;
		}

		if( $form->validate_form_input() ) {  # if there were errors
			$self->invalid_input( $form );
			last SWITCH;
		}
		
		$self->send_mail_to_me( $form ) or last SWITCH;
		
		$self->sign_guest_book( $form ) or last SWITCH;

		$self->mail_me_and_sign_guest_ok( $form );
		
		if( $globals->user_post_param( $FFN_WANTCOPY ) eq 'on' ) {
			$self->send_mail_to_writer( $form );
		}
	}

	$globals->page_search_and_replace( {
		$TOKEN_SIGN => $globals->url_as_string( $VRP_SIGN ),
		$TOKEN_READ => $globals->url_as_string( $VRP_READ ),
	} );
}

######################################################################

sub get_field_definitions {
	my $self = shift( @_ );
	my @field_definitions = ();

	push( @field_definitions, 
		{
			visible_title => "Your Name",
			type => 'textfield',
			name => $FFN_NAMEREAL,
			size => 30,
			is_required => 1,
			error_message => 'You must enter your name.',
			exclude_in_echo => 1,
		}, {
			visible_title => "Your E-mail",
			type => 'textfield',
			name => $FFN_EMAIL,
			size => 30,
			is_required => 1,
			validation_rule => '\S\@\S',
			help_message => 'E-mails are in the form "user@domain".',
			error_message => 'You must enter your e-mail.',
			exclude_in_echo => 1,
		}, {
			visible_title => "Keep A Copy",
			type => 'checkbox',
			name => $FFN_WANTCOPY,
			nolabel => 1,
			help_message => "If checked, a copy of this message is e-mailed to you.",
			exclude_in_echo => 1,
		}, 
	);

	push( @field_definitions, @{$self->get_question_field_defs()} );

	push( @field_definitions, 
		{
			type => 'submit', 
			label => 'Post',
		}, {
			type => 'reset', 
			label => 'Clear',
		},
	);

	return( \@field_definitions );
}

######################################################################

sub get_question_field_defs {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();
	
	# check if we are using default or custom questions
	unless( $rh_prefs->{$PKEY_CUSTOM_FD} ) {
		return( \@DEF_FORM_QUESTIONS );  # using default
	}
	
	my $field_defn = $rh_prefs->{$PKEY_FIELD_DEFN};
	
	# check if we have actual custom questions or filename to them
	# check if question file is executable Perl or not
	unless( $rh_prefs->{$PKEY_FD_IN_SEQF} ) {  # it is Perl file
		return( $globals->resolve_prefs_node_to_array( $field_defn ) );
	}
	
	# we will now get questions from a simple Boulder formatted file
	return( $self->fetch_all_records( $field_defn ) || [] );
}

######################################################################

sub no_questions_error {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->page_title( "Error Starting GuestBook" );

	$globals->set_page_body( <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>I'm sorry, but an error has occurred while trying to start 
the Guest Book.  We are missing critical settings information 
that is required to operate.  Specifically, we don't know what 
questions we are supposed to ask you.  Here are some details about 
what caused this problem:</p>

<p>@{[$globals->get_error()]}</p>

@{[$self->get_amendment_message()]}
__endquote
}

######################################################################

sub is_in_signing_mode {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $raw_mode = $globals->current_user_path_element();
	$raw_mode eq $VRP_SIGN and return( 1 );
	$raw_mode eq $VRP_READ and return( 0 );
	return( $globals->pref( $PKEY_SIGN_BY_DEFAULT ) );
}

######################################################################

sub read_guest_book {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $filename = $globals->pref( $PKEY_FN_MESSAGES );
	my @message_list = $self->fetch_all_records( $filename, 1 );

	if( my $err_msg = $globals->get_error() ) {
		$globals->page_title( "Error Reading GuestBook Postings" );

		$globals->set_page_body( <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>I'm sorry, but an error has occurred while trying to read the 
existing guest book messages from the log file, meaning that I can't 
show you any.</p>

<p>details: $err_msg</p>

@{[$self->get_amendment_message()]}
__endquote

		return( 0 );
	}

	unless( @message_list ) {
		$globals->page_title( "Empty Guest Book" );

		$globals->set_page_body( <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>The guest book currently has no messages in it, as either none 
were successfully posted or they were deleted since then.  You can 
still <a href="$TOKEN_SIGN">sign</a> it yourself, however.</p>
__endquote

		return( 1 );
	}

	my @message_html = ();
	
	my $show_emails = $globals->pref( $PKEY_MSG_LIST_SHOW_EMAIL );
	foreach my $message (reverse @message_list) {
		$form->user_input( $message );
		my $name_real = $message->fetch_value( $FFN_NAMEREAL );
		my $email = $show_emails ? 
			'&lt;'.$message->fetch_value( $FFN_EMAIL ).'&gt;' : '';
		my $submit_date = $message->fetch_value( $LFN_SUBMIT_DATE );
		push( @message_html, "<h3>From $name_real $email at $submit_date:</h3>" );
		push( @message_html, 
			$form->make_html_input_echo( 1, 1, $EMPTY_FIELD_ECHO_STRING ) );
		push( @message_html, "\n<hr />" );
	}
	pop( @message_html );  # get rid of trailing <hr />
	
	$globals->set_page_body( \@message_html );		
	
	$globals->prepend_page_body( <<__endquote );
<p>You may also <a href="$TOKEN_SIGN">sign</a> 
this guest book yourself, if you wish.</p>
__endquote
	$globals->append_page_body( <<__endquote );
<p>You may also <a href="$TOKEN_SIGN">sign</a> 
this guest book yourself, if you wish.</p>
__endquote

	$globals->page_title( $globals->pref( $PKEY_MSG_LIST_TITLE ) || 
		"Guest Book Messages" );

	$globals->prepend_page_body( 
		$globals->pref( $PKEY_MSG_LIST_HEAD ) || <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>Messages are ordered from newest to oldest.</p>
__endquote

	return( 1 );
}

######################################################################

sub new_message {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->page_title( $globals->pref( $PKEY_MSG_NEW_TITLE ) || 
		"Sign the Guest Book" );

	$globals->set_page_body( 
		$globals->pref( $PKEY_MSG_NEW_HEAD ) || <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>This form is provided as an easy way for you to give feedback 
concerning this web site, and at the same time, let everyone else 
know what you think.</p>
__endquote

	$globals->append_page_body( <<__endquote );
<p>The fields indicated with a '@{[$form->required_field_marker()]}' 
are required.</p>

@{$form->make_html_input_form( 1, 1 )}

<p>It may take from 1 to 30 seconds to process this form, so please be 
patient and don't click Send multiple times.  A confirmation message 
will appear if everything worked.</p>

<p>You may also <a href="$TOKEN_READ">read</a> the existing messages.</p>
__endquote
}

######################################################################

sub invalid_input {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->page_title( "Information Missing" );

	$globals->set_page_body( <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>Your submission could not be added to the guest book because some 
of the fields were not correctly filled in, which are indicated with a 
'@{[$form->bad_input_marker()]}'.  Fields with a 
'@{[$form->required_field_marker()]}' are required and can not be left 
empty.  Please make sure you have entered your name and e-mail address 
correctly, and then try sending it again.</p>

@{$form->make_html_input_form( 1, 1 )}

<p>It may take from 1 to 30 seconds to process this form, so please be 
patient and don't click Send multiple times.  A confirmation message 
will appear if everything worked.</p>

<p>You may also <a href="$TOKEN_READ">read</a> the existing messages.</p>
__endquote
}

######################################################################

sub send_mail_to_me {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $err_msg = $self->send_email_message(
		$globals->default_maintainer_name(),
		$globals->default_maintainer_email_address(),
		$globals->user_post_param( $FFN_NAMEREAL ),
		$globals->user_post_param( $FFN_EMAIL ),
		$globals->pref( $PKEY_EMAIL_SUBJ ) || 
			$globals->default_application_title().' -- GuestBook Message',
		$form->make_text_input_echo( 0, $EMPTY_FIELD_ECHO_STRING ),
		<<__endquote.
It is the result of a form submission from a site visitor, 
"@{[$globals->user_post_param( $FFN_NAMEREAL )]}" <@{[$globals->user_post_param( $FFN_EMAIL )]}>.
From: @{[$globals->client_ip()]} @{[$globals->client_domain()]}.
__endquote
		($globals->user_post_param( $FFN_WANTCOPY ) ? 
		"The visitor also requested a copy be sent to them.\n" : 
		"The visitor did not request a copy be sent to them.\n"),
	);

	if( $err_msg ) {
		$globals->add_error( $err_msg );
	
		$globals->page_title( "Error Sending Mail" );

		$globals->set_page_body( <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>I'm sorry, but an error has occurred while trying to e-mail your 
message to me.  It also hasn't been added to the guest book.  As a 
result, no one will see it.</p>

<p>This problem can occur if you enter a nonexistant or unreachable 
e-mail address into the e-mail field, in which case, please enter a 
working e-mail address and try clicking 'Send' again.  You can check 
if that is the problem by checking the following error string:</p>

<p>$err_msg</p>

@{[$self->get_amendment_message()]}

@{$form->make_html_input_form( 1, 1 )}

<p>It may take from 1 to 30 seconds to process this form, so please be 
patient and don't click Send multiple times.  A confirmation message 
will appear if everything worked.</p>

<p>You may also <a href="$TOKEN_READ">read</a> the existing messages.</p>
__endquote

		$globals->add_no_error();
		return( 0 );
	}
	
	return( 1 );
}

######################################################################

sub sign_guest_book {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $new_posting = $globals->user_post();
	$new_posting->store( $LFN_SUBMIT_DATE, $self->today_date_utc() );
	$new_posting->store( $LFN_SUBMIT_DOMAIN, 
		$globals->client_ip().':'.$globals->client_domain() );

	my $filename = $globals->pref( $PKEY_FN_MESSAGES );
	$self->append_new_records( $filename, $new_posting );

	if( my $err_msg = $globals->get_error() ) {
		$globals->add_error( $err_msg );
	
		$globals->page_title( "Error Writing to Guest Book" );

		$globals->set_page_body( <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>I'm sorry, but an error has occurred while trying to write your 
message into the guest book.  As a result it will not appear when
the guest book is viewed by others.  However, the message was
e-mailed to me.</p>

<p>details: $err_msg</p>

@{[$self->get_amendment_message()]}

@{$form->make_html_input_form( 1, 1 )}

<p>It may take from 1 to 30 seconds to process this form, so please be 
patient and don't click Send multiple times.  A confirmation message 
will appear if everything worked.</p>

<p>You may also <a href="$TOKEN_READ">read</a> the existing messages.</p>
__endquote

		$globals->add_no_error();
		return( 0 );
	}
	
	return( 1 );
}

######################################################################

sub mail_me_and_sign_guest_ok {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->page_title( "Your Message Has Been Added" );

	$globals->set_page_body( <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>Your message has been added to this guest book, and a copy was 
e-mailed to me as well.  This is what the copy e-mailed to me said:</p>

<p><strong>To:</strong> 
@{[$globals->default_maintainer_name()]}
&lt;@{[$globals->default_maintainer_email_address()]}&gt;
<br /><strong>From:</strong> 
@{[$globals->user_post_param( $FFN_NAMEREAL )]} 
&lt;@{[$globals->user_post_param( $FFN_EMAIL )]}&gt;
<br /><strong>Subject:</strong> 
@{[$globals->pref( $PKEY_EMAIL_SUBJ ) || 
	$globals->default_application_title().' -- GuestBook Message']}</p>

@{[$form->make_html_input_echo( 1, 1, $EMPTY_FIELD_ECHO_STRING )]}

<p>You may also <a href="$TOKEN_READ">read</a> the existing messages.</p>
__endquote
}

######################################################################

sub send_mail_to_writer {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $err_msg = $self->send_email_message(
		$globals->user_post_param( $FFN_NAMEREAL ),
		$globals->user_post_param( $FFN_EMAIL ),
		$globals->default_maintainer_name(),
		$globals->default_maintainer_email_address(),
		$globals->pref( $PKEY_EMAIL_SUBJ ) || 
			$globals->default_application_title().' -- GuestBook Message',
		$form->make_text_input_echo( 0, $EMPTY_FIELD_ECHO_STRING ),
		<<__endquote,
It is the result of a form submission from a site visitor, 
"@{[$globals->user_post_param( $FFN_NAMEREAL )]}" <@{[$globals->user_post_param( $FFN_EMAIL )]}>.
From: @{[$globals->client_ip()]} @{[$globals->client_domain()]}.
__endquote
	);

	if( $err_msg ) {
		$globals->add_error( $err_msg );
		$globals->append_page_body( <<__endquote );
<p>However, something went wrong when trying to send you a copy:
$err_msg.</p>
__endquote
		$globals->add_no_error();

	} else {
		$globals->append_page_body( <<__endquote );
<p>Also, a copy was successfully sent to you at 
'@{[$globals->user_post_param( $FFN_EMAIL )]}'.</p>
__endquote
	}
}

######################################################################

sub fetch_all_records {
	my ($self, $filename, $read_and_write) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	
	my $fh = gensym;
	
	$self->open_and_lock( $fh, $filename, $read_and_write ) or return( undef );

	seek( $fh, 0, 0 ) or do {
		$globals->add_virtual_filename_error( "seek start of", $filename );
		return( undef );
	};

	my $ra_record_list = CGI::MultiValuedHash->batch_from_file( $fh, 1 ) or do {
		$globals->add_virtual_filename_error( "read record from", $filename );
		return( undef );
	};

	$self->unlock_and_close( $fh, $filename ) or return( undef );

	return( wantarray ? @{$ra_record_list} : $ra_record_list );
}

######################################################################

sub append_new_records {
	my $self = shift( @_ );
	my $filename = shift( @_ );
	my $ra_record_list = (ref( $_[0] ) eq 'ARRAY') ? $_[0] : [@_];
	my $globals = $self->{$KEY_SITE_GLOBALS};
	
	my $fh = gensym;
	
	$self->open_and_lock( $fh, $filename, 1 ) or return( undef );

	seek( $fh, 0, 2 ) or do {
		$globals->add_virtual_filename_error( "seek end of", $filename );
		return( undef );
	};

	CGI::MultiValuedHash->batch_to_file( $fh, $ra_record_list ) or do {
		$globals->add_virtual_filename_error( "write record to", $filename );
		return( undef );
	};

	$self->unlock_and_close( $fh, $filename ) or return( undef );

	return( 1 );
}

######################################################################

sub open_and_lock {
	my ($self, $fh, $filename, $read_and_write) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	
	my $physical_path = $globals->physical_filename( $filename );
	my $flags = $read_and_write ? O_RDWR|O_CREAT : O_RDONLY;
	my $perms = 0666;

	sysopen( $fh, $physical_path, $flags, $perms ) or do {
		$globals->add_virtual_filename_error( "open", $filename );
		return( undef );
	};

	flock( $fh, $read_and_write ? LOCK_EX : LOCK_SH ) or do {
		$globals->add_virtual_filename_error( "lock", $filename );
		return( undef );
	};

	return( 1 );
}

######################################################################

sub unlock_and_close {
	my ($self, $fh, $filename) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	
	flock( $fh, LOCK_UN ) or do {
		$globals->add_virtual_filename_error( "unlock", $filename );
		return( undef );
	};

	close( $fh ) or do {
		$globals->add_virtual_filename_error( "close", $filename );
		return( undef );
	};

	return( 1 );
}

######################################################################

sub send_email_message {
	my ($self, $to_name, $to_email, $from_name, $from_email, 
		$subject, $body, $body_head_addition) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $EMAIL_HEADER_STRIP_PATTERN = '[,<>()"\'\n]';  #for names and addys
	$to_name    =~ s/$EMAIL_HEADER_STRIP_PATTERN//g;
	$to_email   =~ s/$EMAIL_HEADER_STRIP_PATTERN//g;
	$from_name  =~ s/$EMAIL_HEADER_STRIP_PATTERN//g;
	$from_email =~ s/$EMAIL_HEADER_STRIP_PATTERN//g;
	$globals->is_debug() and $subject .= " -- debug";
	
	my $body_header = <<__endquote.
--------------------------------------------------
This e-mail was sent at @{[$self->today_date_utc()]} 
by the web site "@{[$globals->default_application_title()]}", 
which is located at "@{[$globals->url_base()]}".
__endquote
	$body_head_addition.
	($globals->is_debug() ? "Debugging is currently turned on.\n" : 
	'').<<__endquote;
--------------------------------------------------
__endquote

	my $body_footer = <<__endquote;


--------------------------------------------------
END OF MESSAGE
__endquote
	
	my $host = $globals->default_smtp_host();
	my $timeout = $globals->default_smtp_timeout();
	my $error_msg = '';

	TRY: {
		my $smtp;

		eval { require Net::SMTP; };
		if( $@ ) {
			$error_msg = "can't open program module 'Net::SMTP'";
			last TRY;
		}
	
		unless( $smtp = Net::SMTP->new( $host, Timeout => $timeout ) ) {
			$error_msg = "can't connect to smtp host: $host";
			last TRY;
		}

		unless( $smtp->verify( $from_email ) ) {
			$error_msg = "invalid address: @{[$smtp->message()]}";
			last TRY;
		}

		unless( $smtp->verify( $to_email ) ) {
			$error_msg = "invalid address: @{[$smtp->message()]}";
			last TRY;
		}

		unless( $smtp->mail( "$from_name <$from_email>" ) ) {
			$error_msg = "from: @{[$smtp->message()]}";
			last TRY;
		}

		unless( $smtp->to( "$to_name <$to_email>" ) ) {
			$error_msg = "to: @{[$smtp->message()]}";
			last TRY;
		}

		$smtp->data( <<__endquote );
From: $from_name <$from_email>
To: $to_name <$to_email>
Subject: $subject
Content-Type: text/plain; charset=us-ascii

$body_header
$body
$body_footer
__endquote

		$smtp->quit();
	}
	
	return( $error_msg );
}

######################################################################

sub today_date_utc {
	my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time);
	$year += 1900;  # year counts from 1900 AD otherwise
	$mon += 1;      # ensure January is 1, not 0
	my @parts = ($year, $mon, $mday, $hour, $min, $sec);
	return( sprintf( "%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d UTC", @parts ) );
}

######################################################################

sub get_amendment_message {
	my ($self) = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	return( <<__endquote );
<p>This should be temporary, the result of a transient server problem or an 
update being performed at the moment.  Click @{[$globals->recall_html('here')]} 
to automatically try again.  If the problem persists, please try again later, 
or send an @{[$globals->maintainer_email_html('e-mail')]} message about the 
problem, so it can be fixed.</p>
__endquote
}

######################################################################

1;
__END__

=head1 AUTHOR

Copyright (c) 1999-2004, Darren R. Duncan.  All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.  However, I do request that this copyright information and
credits remain attached to the file.  If you modify this module and
redistribute a changed version then please attach a note listing the
modifications.  This module is available "as-is" and the author can not be held
accountable for any problems resulting from its use.

I am always interested in knowing how my work helps others, so if you put this
module to use in any of your own products or services then I would appreciate
(but not require) it if you send me the website url for said product or
service, so I know who you are.  Also, if you make non-proprietary changes to
the module because it doesn't work the way you need, and you are willing to
make these freely available, then please send me a copy so that I can roll
desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 SEE ALSO

perl(1), CGI::Portable, CGI::Portable::AppStatic, HTML::FormTemplate, 
CGI::MultiValuedHash, Net::SMTP, Fcntl, Symbol, Boulder, CGI::Portable::AdapterCGI.

=cut
