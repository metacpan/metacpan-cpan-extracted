=head1 NAME

DemoUsage - Demo of CGI::Portable that tracks web site usage details, 
as well as e-mail backups of usage counts to the site owner.

=cut

######################################################################

package DemoUsage;
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
use vars qw($VERSION);
$VERSION = '0.51';

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

=cut

######################################################################

use CGI::Portable 0.50;

######################################################################

=head1 SYNOPSIS

=head2 A multiple page website with static html, mail, gb, redir, usage tracking

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

	if( $globals->user_query_param( 'debugging' ) eq 'on' ) {
		$globals->is_debug( 1 );
		$globals->url_query_param( 'debugging', 'on' );
	}
	
	$globals->default_application_title( 'Demo Web Site' );
	$globals->default_maintainer_name( 'Tony Simons' );
	$globals->default_maintainer_email_address( 'tony@aardvark.net' );
	$globals->default_maintainer_email_screen_url_path( '/mailme' );

	my $content = $globals->make_new_context();
	$content->current_user_path_level( 1 );
	$content->navigate_file_path( 'content' );
	$content->set_prefs( 'content_prefs.pl' );
	$content->call_component( 'CGI::Portable::AppSplitScreen' );
	$globals->take_context_output( $content );

	my $usage = $globals->make_new_context();
	$usage->http_redirect_url( $globals->http_redirect_url() );
	$usage->navigate_file_path( $globals->is_debug() ? 'usage_debug' : 'usage' );
	$usage->set_prefs( '../usage_prefs.pl' );
	$usage->call_component( 'DemoUsage' );
	$globals->take_context_output( $usage, 1 );

	if( $globals->is_debug() ) {
		$globals->append_page_body( <<__endquote );
<p>Debugging is currently turned on.</p>
__endquote
	}

	$globals->search_and_replace_url_path_tokens( '__url_path__' );

	$io->send_user_output( $globals );

	1;

=head2 Content of settings file "content_prefs.pl"

I<Please see the included demo called "website" for this file.>

=head2 Content of settings file "usage_prefs.pl", tracking as much as possible

	my $rh_preferences = { 
		email_logs => 1,  # do we want to be sent daily reports?
		fn_dcm => 'date_counts_mailed.txt',  # our lock file to track mailings
		mailing => [  # keep different types of reports in own emails
			{
				filenames => 'env.txt',
				subject_unique => ' -- usage (env) to ',
			}, {
				filenames => 'site_vrp.txt',
				subject_unique => ' -- usage (page views) to ',
			}, {
				filenames => 'redirect_urls.txt',
				subject_unique => ' -- usage (external) to ',
			}, {
				filenames => [qw(
					ref_urls.txt ref_se_urls.txt 
					ref_se_keywords.txt ref_discards.txt
				)],
				subject_unique => ' -- usage (references) to ',
				erase_files => 1,  # start over listing each day
			},
		],
		env => {  # what misc info do we want to know (low value distrib)
			filename => 'env.txt',
			var_list => [qw(
				DOCUMENT_ROOT GATEWAY_INTERFACE HTTP_CONNECTION HTTP_HOST
				REQUEST_METHOD SCRIPT_FILENAME SCRIPT_NAME SERVER_ADMIN 
				SERVER_NAME SERVER_PORT SERVER_PROTOCOL SERVER_SOFTWARE
			)],
		},
		site => {  # which pages on our own site are viewed?
			filename => 'site_vrp.txt',
		},
		redirect => {  # which of our external links are followed?
			filename => 'redirect_urls.txt',
		},
		referrer => {  # what sites are referring to us?
			filename => 'ref_urls.txt',   # normal websites go here
			fn_search => 'ref_se_urls.txt',  # search engines go here
			fn_keywords => 'ref_se_keywords.txt',  # their keywords go here
			fn_discards => 'ref_discards.txt',  # uris we filter out
			discards => [qw(  # filter uri's we want to ignore
				^(?!http://)
				deja
				mail
			)],
			search_engines => {  # match domain with query param holding keywords
				alltheweb => 'query', # AllTheWeb
				altavista => 'q',     # Altavista
				'aj.com' => 'ask',    # Ask Jeeves
				aol => 'query',       # America Online
				'ask.com' => 'ask',   # Ask Jeeves
				askjeeves => 'ask',   # Ask Jeeves
				'c4.com' => 'searchtext', # C4
				'cs.com' => 'sterm',  # CompuServe
				dmoz => 'search',     # Mozilla Open Directory
				dogpile => 'q',       # DogPile
				excite => 's',        # Excite
				google => 'q',        # Google
				'goto.com' => 'keywords', # GoTo.com, Inc
				'icq.com' => 'query', # ICQ
				infogrid => 'search', # InfoGrid
				intelliseek => 'queryterm', # "Infrastructure For Intelligent Portals"
				iwon => 'searchfor',  # I Won
				looksmart => 'key',   # LookSmart
				lycos => 'query',     # Lycos
				mamma => 'query',     # "Mother of Search Engines"
				metacrawler => 'general', # MetaCrawler
				msn => ['q','mt'],    # Microsoft
				nbci => 'keyword',    # NBCi
				netscape => 'search', # Netscape
				ninemsn => 'q',       # nine msn
				northernlight => 'qr', # Northern Light Search
				'search.com' => 'q',  # CNET
				'searchalot' => 'search', # SearchALot
				snap => 'keyword',    # Microsoft
				webcrawler => 'search', # Webcrawler
				yahoo => 'p',         # Yahoo
			},
		},
	};

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

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site page preferences:

my $PKEY_TOKEN_TOTAL = 'token_total'; # token counts number of file updates
my $PKEY_TOKEN_NIL   = 'token_nil'; # token counts number of '' values
my $PKEY_EMAIL_LOGS  = 'email_logs'; # true if logs get emailed
my $PKEY_FN_DCM      = 'fn_dcm';  # filename for "date counts mailed" record
my $PKEY_MAILING     = 'mailing';  # array of hashes
my $PKEY_LOG_ENV      = 'env'; # misc env variables go in here
	# Generally only ENVs with a low distribution of values go here.
my $PKEY_LOG_SITE     = 'site'; # pages within this site (vrp) go in here
my $PKEY_LOG_REDIRECT = 'redirect'; # urls we redirect to go in here
my $PKEY_LOG_REFERRER  = 'referrer'; # urls that refer to us go in here
	# note that urls for common search engines are stored separately 
	# from those that aren't

# Keys for elements in $PKEY_MAILING hash:
my $MKEY_FILENAMES      = 'filenames'; # list of filenames to include in mailing
my $MKEY_ERASE_FILES    = 'erase_files'; # if true, then erase files afterwards
my $MKEY_SUBJECT_UNIQUE = 'subject_unique'; # unique part of e-mail subject
	# this text would go following site title and before today's date in subject

# Keys in common for $KEY_LOG_* hashes:
my $LKEY_FILENAME = 'filename';

# Keys used only in $KEY_LOG_ENV hash:
my $EKEY_VAR_LIST = 'var_list'; # name misc env variables to watch

# Keys used only in $KEY_LOG_SITE hash:
my $SKEY_TOKEN_REDIRECT = 'token_redirect';

# Keys used only in $KEY_LOG_REFERRER hash:
my $RKEY_FN_SEARCH       = 'fn_search'; # urls for ref common search engines
	# note that search engine query strings are removed here, go next
my $RKEY_FN_KEYWORDS     = 'fn_keywords'; # keywords used in sea eng ref url
	# note that only se are counted, normal site kw kept with their urls
my $RKEY_FN_DISCARDS     = 'fn_discards'; # urls such as news:// go only here
my $RKEY_TOKEN_REF_SELF  = 'token_ref_self'; # indicates referer was same site
my $RKEY_TOKEN_REF_OTHER = 'token_ref_other'; # ref not self but in other file
my $RKEY_DISCARDS        = 'discards'; # if ref url matches these, filter junk
my $RKEY_SEARCH_ENGINES  = 'search_engines'; # search engines and kw param names

######################################################################

sub main {
	my ($class, $globals) = @_;
	my $self = bless( {}, ref($class) || $class );

	UNIVERSAL::isa( $globals, 'CGI::Portable' ) or 
		die "initializer is not a valid CGI::Portable object";

	$self->{$KEY_SITE_GLOBALS} = $globals;
	$self->main_dispatch();
}

######################################################################

sub main_dispatch {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();

	$rh_prefs->{$PKEY_TOKEN_TOTAL} ||= '__total__';
	$rh_prefs->{$PKEY_TOKEN_NIL} ||= '__nil__';

	$self->email_and_reset_counts_if_new_day();
	
	$self->update_env_counts();
	$self->update_site_vrp_counts();
	$self->update_redirect_counts();
	$self->update_referrer_counts();
	
	# Note that we don't presently print hit counts to the webpage.
	# But that'll likely be added later, along with web usage reports.
}

######################################################################

sub email_and_reset_counts_if_new_day {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();

	$rh_prefs->{$PKEY_EMAIL_LOGS} or return( 1 );

	my $dcm_file = 
		DemoUsage::CountFile->new( $globals, $rh_prefs->{$PKEY_FN_DCM} );
	$dcm_file->open_and_lock( 1 ) or return( undef );
	$dcm_file->read_all_records();
	if( $dcm_file->key_was_incremented_today( 
			$rh_prefs->{$PKEY_TOKEN_TOTAL} ) ) {
		$dcm_file->unlock_and_close();
		return( 1 );
	}
	$dcm_file->key_increment( $rh_prefs->{$PKEY_TOKEN_TOTAL} );
	$dcm_file->write_all_records();
	$dcm_file->unlock_and_close();

	my $ra_mail_prefs = $rh_prefs->{$PKEY_MAILING};
	ref( $ra_mail_prefs ) eq 'ARRAY' or $ra_mail_prefs = [$ra_mail_prefs];

	foreach my $rh_mail_pref (@{$ra_mail_prefs}) {
		ref( $rh_mail_pref ) eq 'HASH' or next;

		my $ra_filenames = $rh_mail_pref->{$MKEY_FILENAMES} || [];
		ref( $ra_filenames ) eq 'ARRAY' or $ra_filenames = [$ra_filenames];
		my $erase_files = $rh_mail_pref->{$MKEY_ERASE_FILES};

		my @mail_body = ();

		foreach my $filename (@{$ra_filenames}) {
			$filename or next;
			my $count_file = 
				DemoUsage::CountFile->new( $globals, $filename );
			$count_file->open_and_lock( 1 ) or do {
				push( @mail_body, "\n\n".$globals->get_error()."\n" );
				next;
			};
			$count_file->read_all_records();
			push( @mail_body, "\n\ncontent of '$filename':\n\n" );
			push( @mail_body, $count_file->get_sorted_file_content() );
			if( $erase_files ) {
				$count_file->delete_all_keys();
			} else {
				$count_file->set_all_day_counts_to_zero();
			}
			$count_file->write_all_records();
			$count_file->unlock_and_close();
		}

		my ($today_str) = ($self->today_date_utc() =~ m/^(\S+)/ );
		my $subject_unique = $rh_mail_pref->{$MKEY_SUBJECT_UNIQUE};
		defined( $subject_unique) or $subject_unique = ' -- usage to ';

		my $err_msg = $self->send_email_message(
			$globals->default_maintainer_name(),
			$globals->default_maintainer_email_address(),
			$globals->default_maintainer_name(),
			$globals->default_maintainer_email_address(),
			$globals->default_application_title().$subject_unique.$today_str,
			join( '', @mail_body ),
			<<__endquote,
This is a daily copy of the site usage count logs.
The first visitor activity on $today_str has just occurred.
__endquote
		);

		if( $err_msg ) {
			$globals->add_error( "can't e-mail usage counts: $err_msg" );
		}
	}
}

######################################################################

sub update_env_counts {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();
	
	my $rh_log_prefs = $rh_prefs->{$PKEY_LOG_ENV};
	ref( $rh_log_prefs ) eq 'HASH' or return( 0 );
	
	my $filename = $rh_log_prefs->{$LKEY_FILENAME} or return( 0 );
	my $ra_var_list = $rh_log_prefs->{$EKEY_VAR_LIST};
	ref( $ra_var_list ) eq 'ARRAY' or $ra_var_list = [$ra_var_list];
	
	# save miscellaneous low-distribution environment vars
	$self->update_one_count_file( $filename, 
		(map { "\$ENV{$_} = \"$ENV{$_}\"" } @{$ra_var_list}) );
}

######################################################################

sub update_site_vrp_counts {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();
	
	my $rh_log_prefs = $rh_prefs->{$PKEY_LOG_SITE};
	ref( $rh_log_prefs ) eq 'HASH' or return( 0 );
	
	my $filename = $rh_log_prefs->{$LKEY_FILENAME} or return( 0 );
	my $t_rd = $rh_log_prefs->{$SKEY_TOKEN_REDIRECT} || '__external_url__';
	
	# save which page within this site was hit
	$self->update_one_count_file( $filename, 
		$globals->user_path_string(), 
		$globals->http_redirect_url() ? $t_rd : () );
}

######################################################################

sub update_redirect_counts {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();
	
	my $rh_log_prefs = $rh_prefs->{$PKEY_LOG_REDIRECT};
	ref( $rh_log_prefs ) eq 'HASH' or return( 0 );
	
	my $filename = $rh_log_prefs->{$LKEY_FILENAME} or return( 0 );
	
	# save which url this site referred the visitor to, if any
	$self->update_one_count_file( $filename, $globals->http_redirect_url() );
}

######################################################################

sub update_referrer_counts {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();
	
	my $rh_log_prefs = $rh_prefs->{$PKEY_LOG_REFERRER};
	ref( $rh_log_prefs ) eq 'HASH' or return( 0 );
	
	my $fn_normal = $rh_log_prefs->{$LKEY_FILENAME};
	my $fn_search = $rh_log_prefs->{$RKEY_FN_SEARCH};
	my $fn_keywords = $rh_log_prefs->{$RKEY_FN_KEYWORDS};
	my $fn_discards = $rh_log_prefs->{$RKEY_FN_DISCARDS};
	
	my $t_rfs = $rh_log_prefs->{$RKEY_TOKEN_REF_SELF} || '__self_reference__';
	my $t_rfo = $rh_log_prefs->{$RKEY_TOKEN_REF_OTHER} || '__other_reference__';
	
	my $ra_discards = $rh_log_prefs->{$RKEY_DISCARDS} || [];
	ref( $ra_discards ) eq 'ARRAY' or $ra_discards = [$ra_discards];
	
	my $rh_engines = $rh_log_prefs->{$RKEY_SEARCH_ENGINES};
	ref( $rh_engines ) eq 'HASH' or $rh_engines = {};
	
	# save which url had referred visitors to this site
	my (@ref_norm, @ref_sear, @ref_keyw, @ref_disc);

	SWITCH: {
		my $referer = $globals->referer();
		my ($ref_filename, $query) = split( /\?/, $referer, 2 );
		$ref_filename =~ s|/$||;     # lose trailing "/"s
		$referer = ($query =~ /[a-zA-Z0-9]/) ? 
			"$ref_filename?$query" : $ref_filename;
		$ref_filename =~ m|^http://([^/]+)(.*)|;
		my ($domain, $path) = ($1, $2);
		
		# first check if visitor is moving within our own site
		my $site_url = $globals->url_base();
		if( $ref_filename =~ m|$site_url|i ) {
			push( @ref_norm, $t_rfs );
			push( @ref_sear, $t_rfs );
			push( @ref_keyw, $t_rfs );
			push( @ref_disc, $t_rfs );			
			last SWITCH;
		}

		# else check if visitor came from checking an e-mail online
		foreach my $ident (@{$ra_discards}) {
			if( $ref_filename =~ m|$ident|i ) {
				push( @ref_norm, $t_rfo );
				push( @ref_sear, $t_rfo );
				push( @ref_keyw, $t_rfo );
				push( @ref_disc, $referer );
				last SWITCH;
			}
		}
		
		# else check if the referring domain is a search engine
		foreach my $dom_frag (keys %{$rh_engines}) {
			if( ".$domain." =~ m|[/\.]$dom_frag\.|i ) { # CHANGED THIS LINE 0-43
				my $se_query = CGI::MultiValuedHash->new( 1, $query );
				my @se_keywords;
				
				my $kwpn = $rh_engines->{$dom_frag};
				my @kwpn = ref($kwpn) eq 'ARRAY' ? @{$kwpn} : $kwpn;
				foreach my $query_param (@kwpn) {
					push( @se_keywords, split( /\s+/, 
						$se_query->fetch_value( $query_param ) ) );
				}

				foreach my $kw (@se_keywords) {
					$kw =~ s/^[^a-zA-Z0-9]+//;  # remove framing junk
					$kw =~ s/[^a-zA-Z0-9]+$//;
					$kw = lc( $kw ); # ADDED THIS LINE 0-43
				}

				# save both the file name and the search words used
				push( @ref_norm, $t_rfo );
				push( @ref_sear, $ref_filename );
				push( @ref_keyw, @se_keywords );
				push( @ref_disc, $t_rfo );
				last SWITCH;
			}
		}

		# otherwise, referer is probably a normal web site
		push( @ref_norm, $referer );
		push( @ref_sear, $t_rfo );
		push( @ref_keyw, $t_rfo );
		push( @ref_disc, $t_rfo );
	}

	$fn_normal and $self->update_one_count_file( $fn_normal, @ref_norm );
	$fn_search and $self->update_one_count_file( $fn_search, @ref_sear );
	$fn_keywords and $self->update_one_count_file( $fn_keywords, @ref_keyw );
	$fn_discards and $self->update_one_count_file( $fn_discards, @ref_disc );
}

######################################################################

sub update_one_count_file {
	my ($self, $filename, @keys_to_inc) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();

	push( @keys_to_inc, $rh_prefs->{$PKEY_TOKEN_TOTAL} );

	my $count_file = 
		DemoUsage::CountFile->new( $globals, $filename );
	$count_file->open_and_lock( 1 ) or return( undef );
	$count_file->read_all_records();

	foreach my $key (@keys_to_inc) {
		$key eq '' and $key = $rh_prefs->{$PKEY_TOKEN_NIL};
		$count_file->key_increment( $key );
	}

	$count_file->write_all_records();
	$count_file->unlock_and_close();
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

package DemoUsage::CountFile;
use Fcntl qw(:DEFAULT :flock);
use Symbol;

# Names of properties for objects of this class are declared here:
#my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values
my $KEY_FILEHANDLE = 'filehandle';  # stores the filehandle
my $KEY_FILENAME  = 'filename';   # external name of this file
my $KEY_FILE_LINES = 'file_lines';  # hold content of file when open

# Indexes into array of record fields:
my $IND_KEY_TO_COUNT   = 0;  # name of what we are counting
my $IND_DATE_ACC_FIRST = 1;  # date of first access
my $IND_DATE_ACC_LAST  = 2;  # date of last access
my $IND_COUNT_ACC_ALL  = 3;  # count of accesses btwn first and last
my $IND_COUNT_ACC_DAY  = 4;  # count of accesses today only

# Constant values used in this class go here:
my $DELIM_RECORDS = "\n";     # this is standard
my $DELIM_FIELDS = "\t";  # this is a standard
my $BYTES_TO_KILL = '[\00-\31]';  # remove all control characters

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$self->{$KEY_SITE_GLOBALS} = shift( @_ );
	$self->{$KEY_FILEHANDLE} = gensym;
	$self->{$KEY_FILENAME} = shift( @_ );
	return( $self );
}

sub open_and_lock {
	my ($self, $read_and_write) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $fh = $self->{$KEY_FILEHANDLE};
	my $filename = $self->{$KEY_FILENAME};
	
	my $physical_path = $globals->physical_filename( $filename );
	my $flags = $read_and_write ? O_RDWR|O_CREAT : O_RDONLY;
	my $perms = 0666;

	$globals->add_no_error();

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

sub unlock_and_close {
	my ($self) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $fh = $self->{$KEY_FILEHANDLE};
	my $filename = $self->{$KEY_FILENAME};
	
	$globals->add_no_error();

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

sub read_all_records {
	my ($self) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $fh = $self->{$KEY_FILEHANDLE};
	my $filename = $self->{$KEY_FILENAME};
	
	$globals->add_no_error();

	seek( $fh, 0, 0 ) or do {
		$globals->add_virtual_filename_error( "seek start of", $filename );
		return( undef );
	};

	local $/ = undef;

	defined( my $file_content = <$fh> ) or do {
		$globals->add_virtual_filename_error( "read records from", $filename );
		return( undef );
	};
	
	my @record_list = split( $DELIM_RECORDS, $file_content );
	my %record_hash = ();
	
	foreach my $record_str (@record_list) {
		my $key = substr( $record_str, 0, index( 
			$record_str, $DELIM_FIELDS ) );  # faster then reg exp?
		$record_hash{$key} = $record_str;
	}

	$self->{$KEY_FILE_LINES} = \%record_hash;
	
	return( 1 );
}

sub write_all_records {
	my ($self) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $fh = $self->{$KEY_FILEHANDLE};
	my $filename = $self->{$KEY_FILENAME};
	
	my @record_list = values %{$self->{$KEY_FILE_LINES}};
	my $file_content = join( $DELIM_RECORDS, @record_list );
	
	$globals->add_no_error();

	seek( $fh, 0, 0 ) or do {
		$globals->add_virtual_filename_error( "seek start of", $filename );
		return( undef );
	};

	truncate( $fh, 0 ) or do {
		$globals->add_virtual_filename_error( "truncate to start of", $filename );
		return( undef );
	};

	local $\ = undef;

	print $fh "$file_content" or do {
		$globals->add_virtual_filename_error( "write records to", $filename );
		return( undef );
	};
	
	return( 1 );
}

sub key_increment {
	my ($self, $key) = @_;
	$key =~ s/$BYTES_TO_KILL//;
	my @fields = split( $DELIM_FIELDS, $self->{$KEY_FILE_LINES}->{$key} );
	
	my $today_str = $self->today_date_utc();

	$fields[$IND_KEY_TO_COUNT] = $key;
	if( $fields[$IND_COUNT_ACC_ALL] == 0 ) {
		$fields[$IND_DATE_ACC_FIRST] = $today_str;
	}
	$fields[$IND_DATE_ACC_LAST] = $today_str;
	$fields[$IND_COUNT_ACC_ALL]++;
	$fields[$IND_COUNT_ACC_DAY]++;  # call different method to reset

	$self->{$KEY_FILE_LINES}->{$key} = join( $DELIM_FIELDS, @fields );
	return( wantarray ? @fields : \@fields );
}

sub delete_all_keys {
	my ($self) = @_;
	$self->{$KEY_FILE_LINES} = {};
}

sub key_was_incremented_today {
	my ($self, $key) = @_;
	$key =~ s/$BYTES_TO_KILL//;
	my @fields = split( $DELIM_FIELDS, $self->{$KEY_FILE_LINES}->{$key} );
	my ($today) = ($self->today_date_utc() =~ m/^(\S+)/ );
	my ($last_acc) = ($fields[$IND_DATE_ACC_LAST] =~ m/^(\S+)/ );
	return( $last_acc eq $today );
}

sub set_all_day_counts_to_zero {
	my ($self) = @_;
	my $rh_file_lines = $self->{$KEY_FILE_LINES};
	foreach my $key (keys %{$rh_file_lines}) {
		my @fields = split( $DELIM_FIELDS, $rh_file_lines->{$key} );
		$fields[$IND_COUNT_ACC_DAY] = 0;
		$rh_file_lines->{$key} = join( $DELIM_FIELDS, @fields );
	}
}

sub get_sorted_file_content {
	return( join( "\n", sort values %{$_[0]->{$KEY_FILE_LINES}} ) );
}

sub today_date_utc {
	my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time);
	$year += 1900;  # year counts from 1900 AD otherwise
	$mon += 1;      # ensure January is 1, not 0
	my @parts = ($year, $mon, $mday, $hour, $min, $sec);
	return( sprintf( "%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d UTC", @parts ) );
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

perl(1), CGI::Portable, Net::SMTP, Fcntl, Symbol, CGI::Portable::AdapterCGI.

=cut
