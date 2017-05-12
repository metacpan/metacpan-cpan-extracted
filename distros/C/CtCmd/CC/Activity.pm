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

CC::Activity - XXX

=cut

##############################################################################
package CC::Activity;
##############################################################################

# Activity is not a subclass of UCMObject in CAL. Why not? wjs

@ISA = qw(CC::UCMObject);

use CC::CC;
use CC::UCMObject;
use CC::VobObject;
use CC::Version;
use strict;
# use Trace;


##############################################################################
sub new
##############################################################################
{
#    my $trace  = new Trace();
    my $class  = shift @_;
    my $objsel = CC::CC::make_objsel('activity', @_);
    my $this   = new CC::VobObject($objsel);
    $this || return 0;
    my $cleartool = ClearCase::CtCmd->new;
    my $status;
    $this->{cleartool}=$cleartool;
    $this->{status}=0;
    return bless($this, $class);
}

##############################################################################
sub create
##############################################################################
{
#    my $trace  = new Trace();
    my %args   = @_;
    my $stream = $args{stream};
    my $name   = $args{name};
    my $title  = $args{title};
    my @cmd;
    
    CC::CC::assert($stream);
    CC::CC::assert($name);

    my $objsel = CC::CC::make_objsel('activity', $name, $stream->vob());

    $title or $title = $name;
    my @title_args = ('-headline', qq("$title"));

    @cmd = ('mkactivity', '-nc', '-in', $stream->objsel(), @title_args, $objsel);

    my @aa = ClearCase::CtCmd::exec(@cmd);

    return $aa[0]? 0 : new CC::Activity($objsel);
}

##############################################################################
sub headline
##############################################################################
{
#    my $trace = new Trace();
    my $this  = shift;
    my $title;

    CC::CC::assert($this);
    my $rv = $this->describe('%[title]p');
    return $this->{status}? $rv : 0;
}

##############################################################################
sub start_work
##############################################################################
{
#    my $trace = new Trace();
    my $this  = shift;
    my $view  = shift;

    CC::CC::assert($this);
    CC::CC::assert($view);

    $this->{cleartool}->exec('setactivity', '-nc', '-view', $view->tag(), $this->objsel());
    return $this->{cleartool}->status? 0 : 1;
}

##############################################################################
sub cset_versions
##############################################################################
{
#    my $trace = new Trace();
    my $this  = shift;

    CC::CC::assert($this);

    my @names = split(' ', $this->describe('%[versions]p'));

    return $this->{status}? map { new CC::Version($_); } @names : 0;
}

##############################################################################
sub stream
##############################################################################

# sub stream wjs

{
#    my $trace = new Trace();
    my $this  = shift;

    CC::CC::assert($this);
    my $name=$this->describe('%[stream]p');
    return  $this->{cleartool}->status? 0 : CC::Stream->new($name,$this->vob());
}

##############################################################################
sub changeset
##############################################################################

# sub changeset wjs

{
#    my $trace = new Trace();
    my $this  = shift;
    my @tmp;
    CC::CC::assert($this);
    my @rv = $this->{cleartool}->exec('lsactivity','-l',$this->name());
    my @acts = split "\n",$rv[1];
    my $flag=0;
    while (@acts){
	my $val = shift @acts;
	if ($val =~ /change set versions/){$flag=1;next;}
	if ($flag){ 
	    $val=~s/\s//g;
	    push @tmp,$val
	    }
    }
    return $this->{cleartool}->status? 0 : map {new CC::Version($_); } @tmp;
}

1;   # Make "use" and "require" happy
