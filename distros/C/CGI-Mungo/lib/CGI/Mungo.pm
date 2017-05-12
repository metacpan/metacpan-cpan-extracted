#main framework object
package CGI::Mungo;

=pod

=head1 NAME

CGI::Mungo - Very simple CGI web framework

=head1 SYNOPSIS

	my $options = {
		'responsePlugin' => 'Some::Class'
	};
	my $m = App->new($options);
	$m->run();	#do this thing!
	###########################
	package App;
	use base qw(CGI::Mungo);
	sub handleDefault{
		#add code here for landing page
	}

=head1 DESCRIPTION

All action subs are passed a L<CGI::Mungo> object as the only parameter, from this you should be able to reach
everything you need.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
use Class::Load qw(is_class_loaded);
use base qw(CGI::Mungo::Base CGI::Mungo::Utils CGI::Mungo::Log);
use CGI::Mungo::Response;
use CGI::Mungo::Session;	#for session management
use CGI::Mungo::Request;
our $VERSION = "1.9";
#########################################################

=head2 new(\%options)

	my $options = {
		'responsePlugin' => 'Some::Class',
		'checkReferer' => 0,
		'sessionClass' => 'Some::Class',
		'requestClass' => 'Some::Class',
		'SefUrls' => 0,
		'debug' => 1
	};
	my $m = CGI::Mungo->new($options);

Constructor, requires a hash references to be passed as the only argument. This hash reference contains any general
options for the framework.

=cut

#########################################################
sub new{
	my($class, $options) = @_;
	if($options->{'responsePlugin'}){	#this option is mandatory
		my $self = $class->SUPER::new();
		$self->{'_options'} = $options;
		my $sessionClass = $self->__getFullClassName("Session");
		if($self->getOption('sessionClass')){
			$sessionClass = $self->getOption('sessionClass');
		}
		$self->{'_session'} = $sessionClass->new();	
		my $requestClass = $self->__getFullClassName("Request");
		if($self->getOption('requestClass')){
			$requestClass = $self->getOption('requestClass');
		}
		if(!defined($self->getOption('debug'))){	#turn off debugging by default
			$self->_setOption("debug", 0);
		}
		$self->{'_request'} = $requestClass->new();
		$self->{'_response'} = CGI::Mungo::Response->new($self, $self->getOption('responsePlugin'));	#this could need access to a request object	
		$self->_init();	#perform initial setup
		return $self;
	}
	else{
		confess("No reponse plugin option provided");
	}
	return undef;
}
#########################################################

=pod

=head2 getResponse()

	my $response = $m->getResponse();

Returns an instance of the response plugin object, previously defined in the constructor options.
See L<CGI::Mungo::Response> for more details.

=cut

###########################################################
sub getResponse{
	my $self = shift;
	return $self->{'_response'};
}
#########################################################

=pod

=head2 getSession()

	my $session = $m->getSession();

Returns an instance of the L<CGI::Mungo::Session> object.

=cut

###########################################################
sub getSession{
	my $self = shift;
	return $self->{'_session'};
}
#########################################################

=pod

=head2 getRequest()

	my $request = $m->getRequest();

Returns an instance of the L<CGI::Mungo::Request> object.

=cut

###########################################################
sub getRequest{
	my $self = shift;
	my $request = $self->{'_request'};
	if(!$request){
		confess("No request object found");
	}
	return $request;
}
#########################################################

=pod

=head2 getAction()

	my $action = $m->getAction();

Returns the curent action that the web application is performing. This is the current value of the "action"
request form field or query string item.

If search engine friendly URLs are turned on the action will be determined from the last part of the script URL.

=cut

###########################################################
sub getAction{
	my $self = shift;
	my $action = "default";	
	if(defined($self->getOption('sefUrls')) && $self->getOption('sefUrls')){	#do we have search engine friendly urls
		my $sefAction = $self->_getSefAction();
		if($sefAction){
			$action = $sefAction;
		}
	}
	else{	#get action from query string or post string
		my $request = $self->getRequest();
		my $params = $request->getParameters();
		if(defined($params->{'action'})){
			$action = $params->{'action'};
		}
	}
	return $action;	
}
#########################################################

=pod

=head2 getFullUrl()

	my $url = $m->getFullUrl();

Returns the full URL for the application.

=cut

#########################################################
sub getFullUrl{
	my $self = shift;
	my $url = undef;
	if(defined($self->getOption('sefUrls')) && $self->getOption('sefUrls')){	#do we have search engine friendly urls
		$url = $self->getSiteUrl() . "/";
	}
	else{
		$url = $self->getThisUrl();
	}
	return $url;
}
#########################################################

=pod

=head2 getUrlForAction($action, $queryString)

	my $url = $m->getUrlForAction("someAction", "a=b&c=d");

Returns the Full URL for the application with the given action and query string

=cut

#########################################################
sub getUrlForAction{
	my($self, $action, $query) = @_;
	my $url = undef;
	if(defined($self->getOption('sefUrls')) && $self->getOption('sefUrls')){	#do we have search engine friendly urls
		$url = $self->getSiteUrl() . "/";
		if($query){	#add query string
			$url .= "?" . $query;
		}
	}
	else{
		$url = $self->getThisUrl() . "?action=" . $action;
		if($query){	#add query string
			$url .= "&" . $query;
		}
	}
	return $url;
}
#########################################################

=pod

=head2 run()

	$m->run();

This methood is required for the web application to deal with the current request.
It should be called after any setup is done.

If the response object decides that the response has not been modified then this 
method will not run any action functions.

The action sub run will be determined by first checking the actions hash if previously
given to the object then by checking if a method prefixed with "handle" exists in the
current class.

=cut

###########################################################
sub run{	#run the code for the given action
	my $self = shift;
	my $response = $self->getResponse();
	if($response->code() != 304){	#need to do something
		$self->log("Need to run action sub");
		my $action = $self->getAction();	
		if($self->getOption('debug')){
			$self->log("Using action: '$action'");
		}
		my $subName = "handle" . ucfirst($action);	#add prefix for security
		my $class = ref($self);
		if($class->can($subName)){	#default action sub exists
			$self->log('Using action from auto default');	
			eval{
				$self->$subName();
			};
			if($@){	#problem with sub
				$response->setError("<pre>" . $@ . "</pre>");
			}
		}
		else{	#no code to execute
			$response->code(404);
			$response->message('Not Found');
			$response->setError("No action sub found for: $action");
		}
	}
	$response->display();	#display the output to the browser
	return 1;
}
##########################################################

=pod

=head2 getOption("key")

	my $value = $m->getOption("debug");

Returns the value of the configuration option given.

=cut

##########################################################
sub getOption{
	my($self, $key) = @_;
	my $value = undef;
	if(defined($self->{'_options'}->{$key})){	#this config option has been set
		$value = $self->{'_options'}->{$key};
	}
	return $value;
}
###########################################################
# Private methods
#########################################################
sub __getFullClassName{
	my($self, $name) = @_;
	no strict 'refs';
	my $class = ref($self);
	my $baseClass = @{$class . "::ISA"}[0];	#get base classes
	my $full = $baseClass . "::" . $name;	#default to base class
	if(is_class_loaded($class . "::" . $name)){
		$full = $class . "::" . $name
	}
	return $full;
}
#########################################################
sub __getActionDigest{
	my $self = shift;
	my $sha1 = Digest::SHA1->new();
	$sha1->add($self->getAction());
	return $sha1->hexdigest();
}
###########################################################
sub _getSefAction{
	my $action = undef;
	my @checkVars = ('SCRIPT_URL', 'REDIRECT_URL');	#possible places to look for actions
	foreach my $check (@checkVars){
		if(defined($ENV{$check}) && $ENV{$check} =~ m/\/(.+)$/){	#get the action from the last part of the url
			$action = $1;
			last;
		}
	}
	return $action;
}
###########################################################
sub _init{	#things to do when this object is created
	my $self = shift;
	if(!defined($self->getOption('checkReferer')) || $self->getOption('checkReferer')){	#check the referer by default
		$self->_checkReferer();	#check this first
	}
	my $response = $self->getResponse();
	my $session = $self->getSession();
	my $existingSession = 0;
	#don't care about errors below
	if($session->read()){	#check for an existing session
		if($session->validate()){
			$existingSession = 1;
			if($self->getOption('debug')){
				$self->log("Existing session: " . $session->getId());
			}
		}
	}
	if(!$existingSession){	#start a new session
		if($session->create({}, $response)){
			if($self->getOption('debug')){
				$self->log("Created new session: " . $session->getId());
			}
		}
		else{
			$response->setError($session->getError());	#now care about errors
		}
	}
	return 1;
}
###########################################################
sub _checkReferer{	#simple referer check for very basic security
	my $self = shift;
	my $result = 0;
	my $host = $ENV{'HTTP_HOST'};
	if($host && $ENV{'HTTP_REFERER'} && $ENV{'HTTP_REFERER'} =~ m/^(http|https):\/\/$host/){	#simple check here
		$result = 1;
	}
	else{
		my $response = $self->getResponse();
		$response->setError("Details where not sent from the correct web page");
	}
	return $result;
}
##########################################################
sub _getActions{
	my $self = shift;
	return $self->{'_actions'};
}
###########################################################
sub _setOption{
	my($self, $key, $value) = @_;
	$self->{'_options'}->{$key} = $value;
	return 1;
}
###########################################################

=pod

=head1 CONFIGURATION SUMMARY

The following list gives a summary of each Mungo 
configuration options. 

=head3 responsePlugin

A scalar string consisting of the response class to use.

See L<CGI::Mungo::Response::Base> for details on how to create your own response class, or
a list of response classes provided in this package.

=head3 checkReferer

Flag to indicate if referer checking should be performed. When enabled an
error will raised when the referer is not present or does not contain the server's
hostname.

This option is enabled by default.

=head3 sessionClass

A scalar string consisting of the session class to use. Useful if you want to change the way
session are stored.

Defaults to ref($self)::Session

=head3 requestClass

A scalar string consisting of the request class to use. Useful if you want to change the way
requests are handled.

Defaults to ref($self)::Request

=head3 sefUrls

A boolean value indicating if search engine friendly URLS are to be used. The following .htaccess rewrite rule should be
used:

RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$         /cgi-bin/app.cgi [L]

=head3 debug

A boolean value indicating if debug mode is enabled. This can then be used in output views or code to print extra debug.

=head1 Notes

To change the session prefix characters use the following code at the top of your script:

	$CGI::Mungo::Session::prefix = "ABC";
	
To change the session file save path use the following code at the top of your script:

	$CGI::Mungo::Session::path = "/var/tmp";

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 Copyright

Copyright (c) 2012 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

###########################################################
return 1;
