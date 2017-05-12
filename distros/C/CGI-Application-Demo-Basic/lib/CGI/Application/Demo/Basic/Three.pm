package CGI::Application::Demo::Basic::Three;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html

use base 'CGI::Application';
use strict;
use warnings;

require 5.005_62;

use CGI::Application::Demo::Basic::Util::Config;
use CGI::Simple;

our $VERSION = '1.06';

# -----------------------------------------------

sub cgiapp_get_query
{
	my($self) = @_;

	return CGI::Simple -> new;

}	# End of cgiapp_get_query.

# -----------------------------------------------

sub cgiapp_init
{
	my($self)   = @_;
	my($config) = CGI::Application::Demo::Basic::Util::Config -> new('three.conf') -> config;

	$self -> param(config => $config);
	$self -> param(tmpl_name => $$config{'tmpl_name'});
	$self -> param(tmpl_path => $$config{'tmpl_path'});

}	# End of cgiapp_init.

# -----------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> run_modes(start => \&start);
	$self -> tmpl_path($self -> param('tmpl_path') );

}	# End of setup.

# -----------------------------------------------

sub start
{
	my($self)		= shift;
	my($template)	= $self -> load_tmpl($self -> param('tmpl_name') );
	my(@content)	=
	(
		'Time: ' . scalar localtime,
		'URL: ' . $self -> query -> url,
		'PathInfo: ' . $self -> query -> path_info,
		"CGI::Simple V $CGI::Simple::VERSION",
		'Template name: ' . $self -> param('tmpl_name'),
		'Template path: ' . $self -> param('tmpl_path'),
	);

	$template -> param(li_loop => [map{ {item => $_} } @content]);
	$template -> param(title => __PACKAGE__);

	return $template -> output;

}	# End of start.

# -----------------------------------------------

1;
