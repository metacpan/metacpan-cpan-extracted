package CGI::Lazy::ErrorHandler;

use strict;

use CGI::Lazy::Globals;

#----------------------------------------------------------------------------------------
sub badConfig {
	my $self = shift;
	my $filename = shift;

	my $msg = "Couldn't parse config file $filename: $@\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub badSession {
	my $self = shift;
	my $id = shift;

	my $msg = "Bad Session ID : $id\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub badSessionExpiry {
	my $self = shift;

	my $msg = "Bad Session Config.  Please check your config file or hash in the Session->{expires} key.\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub config {
	my $self = shift;

	return $self->q->config;
}


#----------------------------------------------------------------------------------------
sub couldntOpenDebugFile {
	my $self = shift;
	my $filename = shift;
	my $error = shift;
	
	my $msg = "Couldn't open Debugging Log file /tmp/$filename: $error\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub couldntOpenCssFile {
	my $self = shift;
	my $docroot = shift;
	my $cssdir = shift;
	my $file = shift;
	my $error = shift;

	my $msg = "Couldn't open CSS file $docroot$cssdir/$file: $error\n";
	
	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub couldntOpenJsFile {
	my $self = shift;
	my $docroot = shift;
	my $jsdir = shift;
	my $file = shift;
	my $error = shift;

	my $msg = "Couldn't open JS file $docroot$jsdir/$file: $error\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;
	
	return;
}

#----------------------------------------------------------------------------------------
sub dbConnectFailed {
	my $self = shift;

	my $msg = "Database connection failed: $@\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub dbError {
	my $self = shift;
	my $pkg = shift;
	my $file = shift;
	my $line = shift;
	my $query = shift;

	my $msg = "Database operation failed in $file calling $pkg at line $line :$@\ncalling: $query\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub dbReturnedMoreThanSingleValue {
	my $self = shift;

	my ($pkg, $file, $line) = caller;

	my $msg = "Database lookup return more than a single value in $pkg called by $file at line $line\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub errorref {
	my $self = shift;

	return $self->{_errors};
}

#----------------------------------------------------------------------------------------
sub errors {
	my $self = shift;

	return @{$self->{_errors}};
}

#----------------------------------------------------------------------------------------
sub getWithOtherThanArray {
	my $self = shift;

	my ($pkg, $file, $line) = caller;

	my $msg = "DB get (get, getarray, gethashlist) called with something other than an array reference in $pkg called by $file at line $line.  That won't fly.\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub noConfig {
	my $self = shift;
	my $filename = shift;

	my $msg = "Couldn't open config file $filename : $@\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

#----------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	my $self = {
		_q 	=> $q,
		_errors	=> [],
		_silent	=> $q->vars->{silent},
	};

	bless $self, $class;

	return $self;
}

#----------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

#----------------------------------------------------------------------------------------
sub tmplCreateError {
	my $self = shift;

	my $msg = "Template Creation Error: $@\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg ;

	return;
}

#----------------------------------------------------------------------------------------
sub silent {
	my $self = shift;

	return $self->{_silent};
}

#----------------------------------------------------------------------------------------
sub tmplParamError {
	my $self = shift;
	my $template = shift;

	my $msg = "Template Parameter Error in $template: $@\n";

	print STDERR $msg unless $self->silent;

	push @{$self->{_errors}}, $msg;

	return;
}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::ErrorHandler

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new('/path/to/config/');

	...

	if ($q->errorHandler->errors) {
		print STDERR "ARRGH! $_\n" for $q->errorHandler->errors;
	}

=head1 DESCRIPTION
The error handler gathers up all error messages produced by the Lazy's internals.  It has, at present, one really useful method: errors, which returns the array of error messages encountered in the execution of the request.  It returns an array, so you can use it in an if or unless to check for errors.  If it returns false, then no errors were encountered.  No news is good news. For convenience sake, the errorref method is available to return a reference to the errors array.

By default, any errors triggered are printed to STDERR.  If you wish to disable this feature, set silent => 1 in the main lazy config.

=head1 METHODS

=head2 errors ()

Returns array of error messages produced by the request.

=head2 errorref ()

Returns array ref to array of error messages produced by the request.

=cut

