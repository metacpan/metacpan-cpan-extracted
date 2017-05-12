package CGI::Lazy::Template;

use strict;

use HTML::Template;
use CGI::Lazy::Globals;
use CGI::Lazy::Template::Boilerplate;

#----------------------------------------------------------------------------------------
sub boilerplate {
	my $self 	= shift;
	my $widget 	= shift;

	return CGI::Lazy::Template::Boilerplate->new($self, $widget);
}

#----------------------------------------------------------------------------------------
sub config {
	my $self = shift;

	return $self->q->config;
}

#----------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

#----------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;
	my $tmplname = shift;
	

	my $self = {_q => $q, _tmplname => $tmplname};

	bless $self, $class;

	if ($self->config->tmplDir && $tmplname) {
		eval {
			$self->{_template} = HTML::Template->new( 
								filename => $self->config->tmplDir."/".$tmplname, 
								die_on_bad_params => 0,
							);
		};
	}

	if ($@) {
		$self->q->errorHandler->tmplCreateError;
		exit;
	}

	return $self;
}

#----------------------------------------------------------------------------------------
sub process {
	my $self = shift;
	my $vars = shift;

	eval {	
		$self->template->param($vars);
	};

	if ($@) {
		$self->q->errorHandler->tmplParamError($self->tmplName);
		exit;
	}
	
	my $output;

	eval {
		$output = $self->template->output;
	};

	if ($@) {
		$self->q->errorHandler->tmplParamError($self->tmplName);
		exit;
	}

	return $output;
}

#----------------------------------------------------------------------------------------
sub template {
	my $self = shift;

	return $self->{_template};
}

#----------------------------------------------------------------------------------------
sub tmplName {
	my $self = shift;

	return $self->{_tmplname};
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

CGI::Lazy::Template

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new('/path/to/config/file');

	print $q->template('topbanner1.tmpl')->process({ mainTitle => 'Main Title', secondaryTitle => 'Secondary Title', versionTitle => 'version 0.1', messageTitle => 'blah blah blah', });

=head1 DESCRIPTION

CGI::Lazy::Template is pretty much just a wrapper to HTML::Template.  It takes a template name as its single argument, and has a single useful method: process, which takes a hashref of variables to shuffle together with the template for subsequent printing to the browser.

=head1 METHODS

=head2 boilerplate (widget)

Returns a boilerplate object for generating boilerplate templates for widget.  See CGI::Lazy::Template::Boilerplate for details.

=head3 widget

A CGI::Lazy widget of some kind.

=head2 config

Returns CGI::Lazy::Config object

=head2 q

Returns CGI::Lazy object.

=head2 new (q, template)

Constructor.

=head3 q

CGI::Lazy object

=head3 template

Template file name.  File must be in the template directory as specified by the config file.

=head2 process (vars)

Shuffles values contained in vars together with template for output.

=head3 vars

hashref of variables expected by template

=cut

