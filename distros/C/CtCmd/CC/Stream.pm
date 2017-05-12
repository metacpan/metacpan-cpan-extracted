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

CC::Stream - XXX

=cut

##############################################################################
package CC::Stream;
##############################################################################

# Stream is a subclass of UCMObject.

@ISA = qw(CC::UCMObject);

use CC::CC;
use CC::View;      #wjs
use CC::UCMObject;
use CC::Activity;
use CC::Baseline;
use CC::Project;
use CC::VobObject;
use strict;
# use Trace;


##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class  = shift @_;
    my $objsel = CC::CC::make_objsel('stream', @_);
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
    my $integ  = $args{integration};
    my @cmd_args;
    
    CC::CC::assert($parent);
    CC::CC::assert($name);

    if ($integ =~ /true|yes/i) {
        push(@cmd_args, '-integration');
    }

    $title or $title = $name;
    push(@cmd_args, '-title', qq("$title"));

    my $sel = CC::CC::make_objsel('stream', $name, $parent->vob());

    my @rv = ClearCase::CtCmd::exec('mkstream', '-nc',
                   '-in', $parent->objsel(),
                   @cmd_args, $sel);
    $rv[0] ? 0 : new CC::Stream($sel);
}

##############################################################################
sub current_view_stream
##############################################################################
{
    # my $trace();
    my @rv = ClearCase::CtCmd::exec('lsstream -cvi -fmt %Xn');
    return $rv[0] ? 0 : new CC::Stream($rv[1]);
}


##############################################################################
sub project
##############################################################################
{
    # my $trace();
    my $this  = shift @_;

    return new CC::Project($this->describe('%[project]Xp'));
}

##############################################################################
sub create_activity
##############################################################################
{
    # my $trace();
    my $this  = shift @_;
    my %args  = @_;

    CC::CC::assert($this);

    $args{stream} = $this;

    return CC::Activity::create(%args);
}

##############################################################################
sub foundation_baseline
##############################################################################
{
    my $this = shift @_;
    my $comp = shift @_;
    my $fbl;

    foreach $fbl ($this->foundation_baselines()) {
        if ($fbl->component()->equals($comp)) {
            return $fbl;
        }
    }

    CC::CC::assert(0);
}

##############################################################################
sub foundation_baselines
##############################################################################
{
    # my $trace();
    my $this  = shift @_;

    my @objsels = split(' ', $this->describe('%[found_bls]Xp'));

    return map { new CC::Baseline($_); } @objsels;
}

##############################################################################
sub latest_baselines
##############################################################################
{
    # my $trace();
    my $this  = shift @_;

    my @objsels = split(' ', $this->describe('%[latest_bls]Xp'));

    return map { new CC::Baseline($_); } @objsels;
}

##############################################################################
sub latest_baseline
##############################################################################
{
    # my $trace();
    my $this  = shift @_;
    my $comp  = shift @_;

    # Return latest (last) baseline of the specified component in this stream.
    # If there are no such baselines, return 0.

    my @bls = $this->baselines_in_stream($comp);

    return(scalar(@bls) == 0 ? 0 : $bls[$#bls]);
}

##############################################################################
sub baselines_in_stream
##############################################################################
{
    # my $trace();
    my $this  = shift @_;
    my $comp  = shift @_;

    # Get all baselines of specified component that have been created
    # in this stream.  NOTE: This does *not* include the component's
    # foundation baseline in the stream.

    my @objsels = split /\n/,$this->{cleartool}->exec("lsbl", -fmt, '%Xn\n','-stream',$this->objsel(),'-comp',$comp->objsel()); 
    $this->{status} = $this->{cleartool}->status;
    return map { new CC::Baseline($_); } @objsels;
}

##############################################################################
sub components
##############################################################################
{
    # my $trace();
    my $this  = shift @_;

    return map { $_->component(); } $this->foundation_baselines();
}


##############################################################################
sub activities
##############################################################################

{
    # my $trace();
    my $this  = shift @_;
    my @names = split(' ', $this->describe('%[activities]Xp'));
    return map {new CC::Activity($_); } @names;
}


##############################################################################
sub views
##############################################################################

{
    # my $trace();
    my $this  = shift @_;
    my @names = split(' ', $this->describe('%[views]Xp'));
    return map {new CC::View($_); } @names;
}


##############################################################################
sub deliver
##############################################################################
{
    # my $trace();
    my $this  = shift;
    my %args = @_;
#
#  How many views does the integration stream have? wjs
#
    my @views=$this->project->integration_stream->views;
    my $view = $views[0];
    $args{-to}=$view unless $args{-to};
    $args{-stream}=$this unless $args{-stream};

#    
# -activity comes from the deliver method of an Activity object;
#

    $args{-to}=$args{-to}->tag;
    $args{-stream}=$args{-stream}->name.'@'.$args{-stream}->vob->tag;
    $args{-activity}=$args{-activity}->name if $args{-activity};

    my @args=%args;
    my $rv = $this->{cleartool}->exec("deliver",@args);
    my @rv = split "\n",$rv;
    for (@rv){
	if (/^\s*(activity:\S+)/){
	    chomp;
	    my $activity=CC::Activity->new($1);
	    return $activity;
	}
    }
    $this->{status} = $this->{cleartool}->status;
    return $rv;
}

1;   # Make "use" and "require" happy

