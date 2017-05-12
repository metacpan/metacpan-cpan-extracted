##########################################################################
#                                                                        #
# © Copyright IBM Corporation 2001, 2004. All rights reserved.           #
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

CC::UCMObject - XXX

=cut

##############################################################################
package CC::UCMObject;
##############################################################################

# UCMObject is a subclass of  VobObject

@ISA = qw(CC::VobObject);


use CC::CC;
use CC::VobObject;
use strict;
# use Trace;


##############################################################################
sub title
##############################################################################
{
    # my $trace();
    my $this  = shift @_;
    my $title;

    CC::CC::assert($this);

    return $this->describe('%[title]p');
}


##############################################################################
sub name 
##############################################################################

# See "ct man fmt_ccase" .  wjs.
# Overrides VobObject::name()


{
    # my $trace();
    my $this  = shift @_;
    my $title;

    CC::CC::assert($this);

    return $this->describe('%Ln');
}




1;
