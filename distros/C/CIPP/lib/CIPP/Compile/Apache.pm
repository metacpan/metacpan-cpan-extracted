# $Id: Apache.pm,v 1.2 2002/08/30 10:19:36 joern Exp $

package CIPP::Compile::Apache;

@ISA = qw ( CIPP::Compile::Generator );

use strict;
use Carp;
use CIPP::Compile::Generator;

#---------------------------------------------------------------------
# This interface must be implemented by the Generator/* modules
#---------------------------------------------------------------------

sub generate_start_program {
}

sub generate_project_handler {
}

sub object_exists {
	my $self = shift;
	my %par = @_;
	my  ($name, $add_message_if_not) =
	@par{'name','add_message_if_not'};

	1;
}

sub determine_object_type {
	my $self = shift;
	my %par = @_;
	my ($name) = @par{'name'};

	1;
}

sub get_object_url {
	my $self = shift;
	my %par = @_;
	my  ($name, $add_message_if_has_no) =
	@par{'name'.'add_message_if_has_no'};

	return "OBJECT_URL";
}

sub check_object_type {
	my $self = shift;
	my %par = @_;
	my ($name, $type, $message) = @par{'name','type','message'};

	# check existance and object type
	1;
}

#---------------------------------------------------------------------
# These commands exist only for CIPP/Apache
#---------------------------------------------------------------------

sub cmd_apredirect {
	my $self = shift;
	my %par = @_;
	my  ($tag, $options, $options_case, $closed) =
	@par{'tag','options','options_case','closed'};

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'url' => 1 },
		optional  => {},
	) || return $RC;

	my $url = $options->{url};
	
	$self->write (
		qq{undef \@CGI::QUERY_PARAM;\n}.
		qq{my \$cipp_old_no_db_connect = \$CIPP_Exec::no_db_connect;\n}.
		qq{\$CIPP_Exec::no_db_connect = 1;\n}.
		qq{\$cipp_apache_request->internal_redirect ("$url");}.
		qq{\$CIPP_Exec::no_db_connect = \$cipp_old_no_db_connect;\n}
	);

	return $RC;
}

sub cmd_apgetrequest {
	my $self = shift;
	my %par = @_;
	my  ($tag, $options, $options_case, $closed) =
	@par{'tag','options','options_case','closed'};

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'var' => 1 },
		optional  => { 'my' => 1 },
	) || return $RC;

	my $var = $options->{var};
	my $my = $options->{'my'} ? 'my' : '';

	$self->write("$my $var = \$cipp_apache_request;\n");

	return $RC;
}


1;
