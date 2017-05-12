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

CC::AdminVob - XXX

=cut

##############################################################################
package CC::AdminVob;
##############################################################################

# AdminVob is a subclass of  Vob

@ISA = qw(CC::Vob);


use CC::CC;
use CC::Vob;
use strict;
# use Trace;

sub root_folder{
    # my $trace();
    my $this   = shift;

    return new CC::Folder('RootFolder', $this);
}



##############################################################################
sub list
##############################################################################
{
    # my $trace();
    my $this   = shift;

    # List components in the specified VOB.  Convert each component
    # object selector into a CC::Component object.

    my $aa = $this->{cleartool}->exec("lscomp", "-fmt", '%Xn\n', "-invob", $this->tag());
    my @objsels = split /\n/,$aa;
    return  $this->{cleartool}->status? 0 : map { new CC::Component($_); } @objsels;
}



1;
