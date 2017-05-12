#!/usr/bin/perl -T
use CGI::Carp 'fatalsToBrowser';

use lib '/www/jsmith/cgi-bin/lib';
use CGI::ContactForm;

contactform (
    recname   => 'John Smith',
    recmail   => 'john.smith@example.com',
    styleurl  => '/style/ContactForm.css',
);

# $Id: contact.pl,v 1.6 2004/08/10 23:25:21 gunnarh Exp $
