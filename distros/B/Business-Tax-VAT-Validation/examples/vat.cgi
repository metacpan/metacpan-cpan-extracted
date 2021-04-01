#!/usr/bin/perl
 ############################################################################
# IT Development software                                                    #
# European VAT number validator                                              #
# CGI interface                    Version 1.00                              #
# Copyright 2003 Nauwelaerts B     bpn@it-development.be                     #
# Created 06/08/2003               Last Modified 25/03/2012                  #
 ############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 2003 Bernard Nauwelaerts  All Rights Reserved.                   #
#                                                                            #
# THIS SOFTWARE IS RELEASED UNDER THE GNU Public Licence version 3           #
# See COPYING for details                                                    #
#                                                                            #
#  This software is provided as is, WITHOUT ANY WARRANTY, without even the   #
#  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  #
#                                                                            #
 ############################################################################
# Revision history :                                                         #
#                                                                            #
# 1.00   25/03/2012; For use with the SOAP version of the Validation module  #
# 0.02   18/08/2008; Updated disclaimer URL                                  #
# 0.01   06/08/2003;                                                         #
#                                                                            #
 ############################################################################

use strict;
use Business::Tax::VAT::Validation;
use CGI qw/:standard/;

print header,
    start_html('VAT checkup example'),
    h1('A simple VAT checkup example');
    print "Uses the Business::Tax::VAT::Validation PERL module version ".$Business::Tax::VAT::Validation::VERSION;
my $hvatn=Business::Tax::VAT::Validation->new();
   
if (param()) {
    my $vat=join("-",param('MS'),param('VAT'));
    print   h2("Results"), $vat, ': ';
    
    if ($hvatn->check($vat)) {
        print 'This number exists in the VIES database. It belongs to '.$hvatn->informations('name')."  ".$hvatn->informations('address');
    } else {
        print $hvatn->get_last_error_code.' '.$hvatn->get_last_error;
    }
}

    
print hr, start_form,
    "VAT Number", p,
    popup_menu(-name=>'MS',
                -values=>[$hvatn->member_states]),
    textfield('VAT'),p,
    submit,
    end_form,
    hr,
    h2("Disclaimer"), "This interface is provided for demonstration purposes only, WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.",
    p,
    'See also this disclaimer: <a href="http://ec.europa.eu/taxation_customs/vies/viesdisc.do?selectedLanguage=EN">http://ec.europa.eu/taxation_customs/vies/viesdisc.do?selectedLanguage=EN</a>';
    end_html;

exit;
