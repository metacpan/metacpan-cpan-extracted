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

CC::Version - XXX

=cut

##############################################################################
package CC::Version;
##############################################################################

# Version is a subclass of File  (was VobObject) wjs

@ISA = qw(CC::File);


use CC::CC;
use CC::File;
use CC::VobObject;
use strict;
# use Trace;

##############################################################################
sub new
##############################################################################
{
#    my $trace  = new Trace();
    my $class  = shift;
    my $objsel = shift;
    my $this   = new CC::VobObject($objsel);
    my $cleartool = ClearCase::CtCmd->new;
    my $status;
    $this->{cleartool}=$cleartool;
    $this->{status}=$cleartool->status;
    return bless($this, $class);
}

##############################################################################
sub full_path
##############################################################################
{
#    my $trace = new Trace();
    my $this  = shift;

    return $this->describe('%Xn');
}

##############################################################################
sub ischeckedout
##############################################################################

# wjs  returns something only if version is checked out to this view.

{
#    my $trace = new Trace();
    my $this  = shift;

    return $this->describe('%f');

}

##############################################################################
sub checkout
##############################################################################



{
#    my $trace = new Trace();
    my $this  = shift;
    my $element = shift;
    my @aa = $this->{cleartool}->exec("co","-nc",$element->name());
    my @x = split /\n/,$aa[1];
    my @line = grep(/Checked out /,@x);
    $line[0] =~ /Checked out \"([^\"]+)/;
    if ($1){
	return CC::Version->new($1)
	}
    else{return 0}
}



##############################################################################
sub checkin
##############################################################################

# sub checkin.   wjs

{
#    my $trace = new Trace();
    my $this  = shift;
    my $element = shift;
    my $x=$this->{cleartool}->exec("ci","-nc",$element->name());
    return $this->{cleartool}->status? 0 : $x;
}



1;   # Make "use" and "require" happy
