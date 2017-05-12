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

CC::Component - XXX

=cut

##############################################################################
package CC::Component;
##############################################################################

# Component is a subclass of VobObject

@ISA = qw(CC::VobObject);

use CC::CC;
use CC::Baseline;
use CC::Element;
use CC::VobObject;
use strict;
# use Trace;

##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class  = shift @_;
    my $objsel = CC::CC::make_objsel('component', @_);
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
    my $root   = $args{root};
    my $name   = $args{name};
    my $vob    = $args{vob};
    my @cmd_args;

    CC::CC::assert($name);
    CC::CC::assert($vob);
    
    if ($root) {
        @cmd_args = ('-root', $root);
    }

    my $sel = CC::CC::make_objsel('component', $name, $vob);

    my @rv = ClearCase::CtCmd::exec('mkcomp', '-nc', @cmd_args, $sel);
    return $rv[0]? 0 : new CC::Component($sel);
}

##############################################################################
sub root_directory
##############################################################################
{
    # my $trace();
    my $this  = shift;

    CC::CC::assert($this);

    my $name = $this->describe('%[root_dir]p');
    $name =~ s/\"//g;    #wjs
    return new CC::Element($name);
}

##############################################################################
sub root_dir_path
##############################################################################
{
    # my $trace();
    my $this  = shift;

    CC::CC::assert($this);

    # TODO: This is wrong - fix it!

    return $this->root_directory()->vob()->tag();
}

##############################################################################
sub baselines
##############################################################################
{
    # my $trace();
    my $this  = shift;

    CC::CC::assert($this);

    # List baselines (as selectors), then convert selectors to baseline objects.
    #wjs

    my $objsel = $this->{cleartool}->exec("lsbl", "-fmt", '%Xn\n', "-comp", $this->objsel());
    my @objsels = split /\n/,$objsel;
    return $this->{cleartool}->status? 0 : map { new CC::Baseline($_); } @objsels;
}

##############################################################################
sub initial_baseline
##############################################################################
{
    # my $trace();
    my $this  = shift;
    my @bls   = $this->baselines();

    CC::CC::assert($this);

    # XXX Need "%[initial_baseline]p" property.

    scalar(@bls) || die("Component has no baselines");

    return $bls[0];
}

1;   # Make "use" and "require" happy
