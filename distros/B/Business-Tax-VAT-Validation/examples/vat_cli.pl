#!/usr/bin/perl
 ############################################################################
# IT Development software                                                    #
# European VAT number validator                                              #
# command line interface           Version 1.00                              #
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
# 0.01   06/08/2003;                                                         #
#                                                                            #
 ############################################################################
my $vatNumber=$ARGV[0];

use Business::Tax::VAT::Validation;
my $val=Business::Tax::VAT::Validation->new();

if ($val->check($vatNumber)) {
    print "VAT Number exists ! ";
    print "It belongs to ".$val->informations('name')."  ".$val->informations('address')."\n";
} else {
    my $msg="Error ".$val->get_last_error_code." : ".$val->get_last_error;
    $msg=~s/[\r\n]/ /g;
    print $msg."\n"
}
