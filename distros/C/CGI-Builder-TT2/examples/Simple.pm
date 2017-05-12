package Simple;
use strict;
use lib '/var/www/mod_perl/build/TT2_wip/lib';

use CGI::Builder qw/ CGI::Builder::TT2 /;
use Data::Dumper;

sub PH_index {
 	my ($self) = @_;
	
#   
#   Use your PH handler to calculate values and store them for use
#   by your templates.
#   
	$self->tt_vars(page_title => "Simple Example");
	$self->tt_vars(content => $self->myContent);

#	
#	If you wish, you can set a custom template in your PH handler,
#	instead of using the default.
#	
#	$self->tt_template('my_special_template.tt2');
#
#	If you have templates stored in other places, you may want to 
#	change your include path.
#
#   $self->tt_new_args(INCLUDE_PATH => ['/my/app/templates', '/usr/local/tt2']);
#
#   If, for some reason, you want to disable the template engine for
#   this request, just set the page content to something else.
#
#   $self->page_content("Not a Template!");
	
}#END sub PH_index


sub myContent {
	my ($self, $content) = @_;
	
	$content .= sprintf("\n<p>Page Name defaults to (%s)</p>",
		$self->page_name);
	
	$content .= sprintf("\n<p>Page Suffix defaults to (%s)</p>",
		$self->page_suffix);
	
	$content .= sprintf("\n<p>Template defaults to page_name + page_suffix 
		(%s)</p>", $self->tt_template);
	
	$content .= sprintf("\n<p>Page Path defaults to (%s)</p>", 
		$self->page_path);

	my $d = Data::Dumper->new( [scalar($self->tt_new_args)], ['tt_new_args'] );
	$content .= sprintf("\n<p>Template new args by default will contain only one
		value, it will set the INCLUDE_PATH = page_path. You may override this
		if your templates are in a different place (or in multiple places).
		<br><code><pre>%s</pre><code></p>", $d->Dump);

	return $content;
}
 

sub PH_AUTOLOAD {
 	my ($self) = @_;
	$self->tt_vars(page_title => "PH_AUTOLOAD");
	$self->tt_vars(content => "
		This content will not be seen, because PH_AUTOLOAD is only called
		when the page_content is empty, but C::B::TT2 sets the page_content
		to its own special printing routine.
	");
}#END sub PH_AUTOLOAD


"Copyright 2004 by Vincent Veselosky [[http://www.control-escape.com]]";
