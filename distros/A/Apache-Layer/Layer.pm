#
# Apache::Layer
#
# Layer is designed to allow content trees to be overlayed. This means that 
# you can have more than one directory searched when looking for a file to 
# be returned by the server.
#
# Author: Simon Matthews <sam@peritas.com>
#
# Copyright (C) 1998 Simon Matthews.  All Rights Reserved.
#
# This module is free software; you can distribute it and/or modify is under
# the same terms as Perl itself.
#

package Apache::Layer;

use strict;

# get the DECLINED and OK constants
use Apache::Constants qw(REDIRECT DECLINED OK);

use vars qw($VERSION $DEBUG);

$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

$DEBUG = 0;

sub handler {

	my ($r) = @_;

	my $LAYER_PATH;
	my $LOCATION;
	my $turi;

	# get our configuration or return DECLINED as we will not process
	# this request
  	$LAYER_PATH = $r->dir_config("apache_layer_path") || return DECLINED;
	$LOCATION = $r->dir_config("apache_layer_location") || return DECLINED;

	print STDERR "Apache::Layer called translating.....\n" if $DEBUG;

	# get a copy of the URI 
	$turi = $r->uri || '';

	# no URI is a really strange error 
	return DECLINED unless $turi;

	print STDERR "Trans URI = [$turi]\n" if $DEBUG;
	print STDERR "Location  = [$LOCATION]\n" if $DEBUG;

	# chop off the location from the uri before we look it up.
	# we do this as we are passed in stuff like /images/icons/foo.gif
	# and we want to look up stuff like /usr/www/images/icons/foo.gif
	# where the path part is /usr/www/images 

 	$turi =~ s/^${LOCATION}//;

	my $file = '';

	foreach (split(/[:,;]+/,$LAYER_PATH)) {

		next unless defined($_);

		# build a full path to the file / directory so that we can check it
		$file = "$_$turi";

		print STDERR "Trans checking [$file]\n" if $DEBUG;

		if ( -r $file ) {
			last;
		} else {
			$file = '';
		}

	}

	# when we fall out of the loop $file will be set with the file we matched
	# otherwise we failed to translate the file so return DECLINED
	return DECLINED unless $file;

	# set the file for the request and return OK
	$r->filename($file);

	print STDERR "Trans now has filename ", $r->filename() , "\n" if $DEBUG;

	return OK;


}

sub version {
	return $VERSION;
}

1;

=head1 NAME

Apache::Layer - Layer content tree over one or more others.

=head1 SYNOPSIS

    #httpd.conf
    PerlTransHandler Apache::Layer

    # anywhere you can configure a location
    <Location /project/images>
        PerlSetVar apache_layer_location /project/images
        PerlSetVar apache_layer_path     /dir1/root;/dir2/root
    </Location>

=head1 DESCRIPTION

This module is designed to allow multiple content trees to be layered on top 
of each other within the Apache server.  

I developed this module because we produce lots of web sites where a high
proportion of the site content is common.  But where specific pages / images 
are tailored to the specific project.  This module allows us to layer a sparse
directory tree on top of the main complete tree without requiring redirects.

The essence is that it will cause Apache to deliver content from a series of
directories in turn.  

In some ways Apache::Layer is similar to Apache::Stage however it does not 
require redirects.

=head1 COMMON PROBLEMS

Apache::Layer is relatively simple.  The most common problem is not setting the
apache_layer_location parameter correctly.  As a rule this parameter should 
ALWAYS match the parameter within the location i.e. <Location /parameter>.

=head1 AUTHOR

Simon Matthews E<lt>sam@peritas.comE<gt>

=head1 REVISION

$Revision: 1.7 $

=head1 COPYRIGHT 

Copyright (C) 1998 Simon Matthews.  All Rights Reserved.

This module is free software; you can distribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

Apache::Stage

=cut
