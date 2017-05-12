# $Id: RequestRec.pm 72 2013-02-10 13:57:22Z jo $
# Cindy::Apache2::RequestRec - Apache2::RequestRec with one additional 
# function
#
# Copyright (c) 2013 Joachim Zobel <jz-2013@heute-morgen.de>. All rights 
# reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This wraps the function 
# ap_make_content_type from protocol.c
# that is not wrapped by mod_perl.
#
# The content type that apache finally sends over the network is 
# make_content_type($r->content_type) - see ap_http_header_filter 
# in http_filters.c.
#
# This is (as far as I understand it) because of the meaning of default 
# (use, if no other is set). make_content_type adds the default charset 
# that has been set with AddDefaultCharset just before sending the header.
#

package Cindy::Apache2::RequestRec;

use strict;
use warnings;

use base 'Apache2::RequestRec'; 

require XSLoader;
XSLoader::load('Cindy::Apache2', $Cindy::Apache2::VERSION);

