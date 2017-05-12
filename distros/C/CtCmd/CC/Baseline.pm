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

CC::Baseline - XXX

=cut

##############################################################################
package CC::Baseline;
##############################################################################

# Baseline is a subclass of UCMObject (formerly of VobObject wjs)

@ISA = qw(CC::UCMObject);

use CC::CC;
use CC::UCMObject;
use CC::Activity;
use CC::Component;
use CC::VobObject;
use CC::Vob;
use strict;
# use Trace;

##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class  = shift @_;
    my $objsel = CC::CC::make_objsel('baseline', @_);
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
    my $view     = shift @_;
    my $comp     = shift @_;
    my $basename = shift @_;
    my $lbstat   = shift @_;
    my $ident    = shift @_;

    CC::CC::assert($view);
    CC::CC::assert($comp);
    CC::CC::assert($basename);

    my ($status,$out,$err) = ClearCase::CtCmd::exec('mkbl', '-view', $view->tag(), $lbstat, $ident,
                             '-comp', $comp->objsel(), $basename);
    my @out = split /\n/,$out;
    @out = grep { s/Created baseline "(.*?)".*/$1/ } @out;
    CC::CC::assert(scalar(@out) == 1);

    # Convert baseline name to baseline object.

    return $status? 0 : new CC::Baseline($out[0], $comp->vob());
}

##############################################################################
sub create_composite
##############################################################################
{
    # my $trace();
    my $view     = shift @_;
    my $basename = shift @_;

    # Get latest baselines in stream associated with the specified view.
    # These will be the dependencies of the new composite baseline.

    my @deps = $view->stream()->latest_baselines();

    # Filter out composite baseline.  Verify that the composite component
    # is actually in stream's foundation.

    my $comp   = _composite_component();
    my $ncomps = scalar(@deps);
    @deps      = grep { ! $comp->equals($_->component()); } @deps;
    CC::CC::assert($ncomps == scalar(@deps) + 1);

    # Create baseline of composite component.
    # Record the new composite's dependencies.

    my $newbl = create($view, $comp, $basename, '-nlabel', '-ident');
    $newbl->_record_dependencies(@deps);

    return $newbl;
}

##############################################################################
sub component
##############################################################################
{
    # my $trace();
    my $this  = shift;

    return new CC::Component($this->describe('%[component]Xp'));
}

##############################################################################
sub lbtype
##############################################################################
{
    # my $trace();
    my $this   = shift;
    my $objsel = $this->{cleartool}->exec('des -s -ahlink BaselineLbtype', $this->objsel());

    chomp($objsel);

    $objsel =~ s/-> //g;

    return $this->{cleartool}->status? 0 :  new CC::VobObject($objsel) ;
}

##############################################################################
sub has_dependencies
##############################################################################
{
    my $this = shift @_;
    return(scalar($this->dependencies()) > 0);
}

##############################################################################
sub dependencies
##############################################################################
{
    my $this = shift @_;

    if ( ! $this->{dependencies_ref}) {

        # Read in the dependency info, which was saved in the form of a
        # perl hash table (see '_record_dependencies()' above.  Use 'eval' to
        # reconstitute the hash table.

        my $saved = $this->get_attr('Dependencies');
        my @deps;

        if ($saved) {
            eval "\@deps = ($saved);"; die($@) if $@;
            @deps = map { new CC::Baseline($_); } @deps;
        }

        # Add the dependency info 
        $this->{dependencies_ref} = \@deps;
    }

    my $dep_ref = $this->{dependencies_ref};
    return @$dep_ref;
}

##############################################################################
sub _record_dependencies
##############################################################################
{
    # my $trace();
    my $this  = shift @_;
    my @deps  = @_;
    my $ss;

    # Save this object in the form of a Perl string list.  This lets us
    # restore it simply by reading it back in and eval'ing it.

    $ss .= sprintf("\n");
    $ss .= sprintf("# DO NOT EDIT THIS ATTRIBUTE!\n");
    $ss .= sprintf("# It is automatically generated by %s\n", $0);
    $ss .= sprintf("# Dependencies for baseline '%s'\n", $this->objsel());
    $ss .= sprintf("\n");

    $ss .= sprintf("'%s'\n", join("',\n'", map { $_->objsel(); } @deps));

    $this->set_attr('Dependencies', $ss);
    $this->{dependencies_ref} = \@deps;

    return 1;
}

my $_comp_comp;

##############################################################################
sub _composite_component
##############################################################################
{
    if ( ! $_comp_comp) {
#XXX    $_comp_comp = new CC::Component('component:composite@/vobs/projects');
        $_comp_comp = new CC::Component('component:composite@/var/tmp/smoke.sum.21088');
    }
    return $_comp_comp;
}

1;   # Make "use" and "require" happy
