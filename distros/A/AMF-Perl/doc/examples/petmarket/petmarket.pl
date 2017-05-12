#!/usr/bin/perl -w

# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)

#This is a server-side script that responds to an Macromedia Flash client
#talking in ActionScript. See the AMF::Perl project site (http://www.simonf.com/amfperl)
#for more information.

use strict;
use AMF::Perl;

my $gateway = AMF::Perl->new;
$gateway->setBaseClassPath(".");
$gateway->debugDir("/tmp");
$gateway->service();

