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

CC::CompHlink - XXX

=cut

##############################################################################
    package CC::CompHlink;
##############################################################################

# CompHlink is a subclass of VobObject

@ISA = qw(CC::VobObject);

use CC::CC;
use CC::VobObject;
use CC::AdminVob;
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
    my $cleartool = ClearCase::CtCmd->new;
    my $status;
    $this->{cleartool}=$cleartool;
    $this->{status}=0;
    return bless($this, $class);
}

##############################################################################
sub adminvob
##############################################################################
{
    # my $trace();
    my $this  = shift;
    my $val = $this->{cleartool}->exec('des','-fmt','%Xn','-ahlink','AdminVOB','vob:'.$this->vob()->tag());
# wjs returns AdminVob.
    $this->{status} = $this->{cleartool}->status;
    return  CC::AdminVob->new($1) if $val =~ /-\> vob\:(.*)/ ;
    return 0;
}

1;   # Make "use" and "require" happy

