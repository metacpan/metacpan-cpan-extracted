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

CC::VobObject - XXX

=cut

##############################################################################
package CC::VobObject;
##############################################################################

@ISA = qw(ClearCase::CtCmd);

use CC::CC;
use CC::Vob;
# use Trace;
use strict;

##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class  = shift @_;
    my $objsel = shift @_;
    my $this   = { };
    my $dbid;
    my $vob;
    my $xname;
    my $cleartool = ClearCase::CtCmd->new;
    my $status;


    # Use 'describe' to get object's dbid and vob.

    my $fmtstring= '%Dn\n%Xn\n';


    ($dbid, $xname) = split /\n/,$cleartool->exec("des", "-fmt", $fmtstring, $objsel);

    #if ($xname =~ /^\//) {
    #xchen: handle win32 files
    if ($xname =~ /^[\/\\]/) {
        # Begins with slash (/) - must be a file.

        $vob = $cleartool->exec('des', '-fmt', '%n', "vob:$xname");

    } elsif ($xname =~ /(.*)@(.*)/) {

        # Contains '@' - must be a non-filesystem object, e.g.,
        # "activity:MyActivity@/vobs/myvob"

        $vob = $2;

    } else {
	#use $this->status to confirm result
    }

    $this->{vob}  = new CC::Vob($vob);
    $this->{dbid} = $dbid;
    $this->{cleartool}=$cleartool;
    $this->{status} = $cleartool->status;
    return bless($this, $class);
}

##############################################################################
sub DESTROY
##############################################################################
{
    return 1;  # no-op
}

##############################################################################
sub vob
##############################################################################
{
    my $this = shift @_;
    return $this->{vob};
}

##############################################################################
sub dbid
##############################################################################
{
    my $this = shift @_;
    return $this->{dbid};
}

##############################################################################
sub metatype
##############################################################################
{
    my $this = shift @_;

    if ( ! $this->{mtype}) {
        $this->{mtype} = $this->describe('%m');
    }
    return $this->{mtype};
}

##############################################################################
sub type
##############################################################################
{
    my $this = shift @_;

    if ( ! $this->{type}) {
        $this->{type} = $this->describe('%[type]p');
    }
    return $this->{type};
}

##############################################################################
sub name
##############################################################################
{
    my $this = shift @_;

    if ( ! $this->{name}) {
        $this->{name} = $this->describe('%n');
    }
    return $this->{name};
}

##############################################################################
sub objsel
##############################################################################
{
    my $this = shift @_;

    if ( ! $this->{objsel}) {
        $this->{objsel} = $this->describe('%Xn');
    }

    $this->{objsel} =~ s/\"//g;
    return $this->{objsel};
}

##############################################################################
sub describe
##############################################################################
{
    # my $trace();
    my $this   = shift @_;
    my $fmt    = shift @_;
    my $objsel = sprintf('dbid:%s@%s', $this->dbid(), $this->vob()->tag());
    my @args;

    if ($fmt) {
        @args = ('-fmt', $fmt);
    }

    my $output = $this->{cleartool}->exec('des', @args, $objsel);
    $this->{status} = $this->{cleartool}->status;
    if (wantarray()) {
        return split /\n/,$output;
    } else {
        return $output;
    }
}

##############################################################################
sub equals
##############################################################################
{
    my $this = shift @_;
    my $that = shift @_;

    return($this->dbid() == $that->dbid() &&
           $this->vob()->equals($that->vob()));
}

##############################################################################
sub get_attr
##############################################################################
{
    my $this  = shift @_;
    my $aname = shift @_;
#wjs


    my $aval = $this->{cleartool}->exec('des', '-s', '-aattr', $aname, $this->objsel());
    $this->{status} = $this->{cleartool}->status;
    # Strip off leading and trailing quotes that we had to add in 'set_attr()'.

    $aval =~ s/^\"//g;
    $aval =~ s/\"$//g;

    return($aval ? $aval : undef);
}

##############################################################################
sub has_attr
##############################################################################
{
    my $this  = shift @_;
    my $aname = shift @_;
    $this->{status} = defined($this->get_attr($aname))? 0 : 1;
    return !$this->{status};
}

##############################################################################
sub set_attr
##############################################################################
{
    my $this  = shift @_;
    my $aname = shift @_;
    my $aval  = shift @_;
    my $st;

    # cleartool 'mkattr' requires we escape embedded quotes in the attribute
    # value string and then enclose the string in quotes.

    $aval =~ s/\"/\\\"/g;    # escape embedded quotes with backslash
    $aval =  "\"$aval\"" if $aval;  # enclose attr value in quotes


    $st = $this->{cleartool}->exec('mkattr', '-replace', $aname, $aval, $this->objsel());
    $this->{status} = $this->{cleartool}->status;
    return $this->{cleartool}->status? 0 : 1;

}




1;   # Make "use" and "require" happy
