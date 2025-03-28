##########################################################################
#                                                                        #
# � Copyright IBM Corporation 2001, 2016.  All rights reserved.          #
# � Copyright HCL Technologies Ltd. 2016, 2019.  All rights reserved.    #
#                                                                        #
# This program and the accompanying materials are made available under   #
# the terms of the Common Public License v1.0 which accompanies this     #
# distribution, and is also available at http://www.opensource.org       #
# Contributors:                                                          #
#                                                                        #
# Matt Lennon - Creation and framework.                                  #
#                                                                        #
# William Spurlin - Maintenance and defect fixes                         #
#                                                                        #
##########################################################################

=head1 NAME

CC::File - XXX

=cut

##############################################################################
package CC::File;
##############################################################################

# File is a subclass of  VobObject

@ISA = qw(CC::VobObject);


use CC::CC;
use CC::VobObject;
use strict;
# use Trace;



##############################################################################
sub path
##############################################################################
{
    my $this = shift @_;

    # This method only applies to file system objects,

    return $this->describe('%En');
}


