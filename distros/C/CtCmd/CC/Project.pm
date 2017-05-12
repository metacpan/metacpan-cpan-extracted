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

CC::Project - XXX

=cut

##############################################################################
package CC::Project;
##############################################################################

# Project is a subclass of UCMObject.

@ISA = qw(CC::UCMObject);

use CC::CC;
use CC::UCMObject;
use CC::Stream;
use CC::VobObject;
use strict;
# use Trace;


##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class  = shift @_;
    my $objsel = CC::CC::make_objsel('project', @_);
    my $this   = new CC::VobObject($objsel);
    my $cleartool = ClearCase::CtCmd->new;
    $this->{cleartool}=$cleartool;
    $this->{status} = 0;
    return bless($this, $class);
}

##############################################################################
sub create
##############################################################################
{
    # my $trace();
    my %args   = @_;
    my $parent = $args{parent};
    my $name   = $args{name};
    my $title  = $args{title};
    
    CC::CC::assert($parent);
    CC::CC::assert($name);

    my $objsel = CC::CC::make_objsel('project', $name, $parent->vob());

    $title or $title = $name;
    my @title_args = ('-title', qq("$title"));

    my @cmd = ('mkproject', '-nc', '-in', $parent->objsel(), @title_args, $objsel);

    my ($status,$out,$err) = ClearCase::CtCmd::exec(@cmd);

    return  $status? 0 : new CC::Project($objsel);
}

##############################################################################
sub current_view_project
##############################################################################
{
    # my $trace();
    my ($status,$out,$err) = ClearCase::CtCmd::exec('lsproj -cvi -fmt %Xn');
    return  $status? 0 : new CC::Project(ClearCase::CtCmd::exec($out));
}

##############################################################################
sub integration_stream
##############################################################################

# wjs integration_stream

{
    # my $trace();
    my $this  = shift;
    my $rv=$this->describe('%[istream]Xp');
    if ($rv){
	return new CC::Stream($rv);
    }else{
	return $rv
	}
}


##############################################################################
sub development_streams
##############################################################################

# wjs development_stream
#added "if ($rv){..." to try to cover the case where the project
# does not yet have an integration stream    wjs   

{
    # my $trace();
    my $this  = shift;
    my $rv=$this->describe('%[dstreams]Xp');
    my @rv = split " ",$rv;
    if ($#rv > -1){
	return map { new CC::Stream($_);} @rv;
    }else{
	return @rv
	}
}



##############################################################################
sub recommended_baselines
##############################################################################
{
    # my $trace();
    my $this  = shift;

    my @objsels = split(' ', $this->describe('%[rec_bls]Xp'));

    return map { new CC::Baseline($_); } @objsels;
}

##############################################################################
sub add_mod_comps
##############################################################################
{
    # my $trace();
    my $this   = shift;
    my @comps  = @_;

    CC::CC::assert($this);
    CC::CC::assert(@comps);

    my @objsels = map { $_->objsel() } @comps;

    $this->{cleartool}->exec('chproject', '-nc',
                   '-amodcomp', join(',',@objsels),
                   $this->objsel());

    return $this->{cleartool}->status? 0 : 1;
}

1;   # Make "use" and "require" happy
