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

CC::Element - XXX

=cut

##############################################################################
package CC::Element;
##############################################################################

# Element is a subclass of File (was VobObject) wjs

@ISA = qw(CC::File);

use CC::CC;
use CC::File;
use CC::Version;
use CC::VobObject;
use strict;
# use Trace;

##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class  = shift;
    my $objsel = shift;
    my $this   = new CC::VobObject($objsel);
    $this->{status} = 0;
    return bless($this, $class);
}

##############################################################################
sub full_path
##############################################################################
{
    # my $trace();
    my $this  = shift;

    return $this->describe('%Xn');
}

##############################################################################
sub version
##############################################################################
{
    # my $trace();
    my $this  = shift;
    my $version_selector=shift;
    $version_selector=$this->objsel() unless $version_selector;
    return CC::Version->new($version_selector);

}


1;   # Make "use" and "require" happy
