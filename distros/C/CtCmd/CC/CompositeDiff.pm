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

CC::CompositeDiff - XXX

=cut

use CC::CC;
use CC::Activity;
use CC::Baseline;
use CC::Component;
# use Trace;
use strict;


##############################################################################
package CC::CompositeDiff;
##############################################################################

##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class  = shift @_;
    my $result = shift @_;
    my $vob    = shift @_;
    my $this   = { };

    CC::CC::assert($result);

    # 'diffbl' results look like:
    #    << MyActivity "My Activity Headline"

    ($this->{kind}, $this->{act}) = split(' ', $result);

    $this->{act} = new CC::Activity($this->{act}, $vob);
    my $cleartool = ClearCase::CtCmd->new;
    $this->{cleartool}=$cleartool;
    $this->{status} = 0;
    return bless($this, $class);
}

##############################################################################
sub kind
##############################################################################
{
    my $this = shift @_;
    return $this->{kind};
}

##############################################################################
sub activity
##############################################################################
{
    my $this = shift @_;
    return $this->{act};
}

##############################################################################
sub print
##############################################################################
{
    my $this = shift @_;

    printf("%s %s \"%s\"\n",
           $this->kind(),
           $this->activity()->name(),
           $this->activity()->headline());

    return 1;
}


##############################################################################
package CC::BaselineDiff;
##############################################################################

##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class = shift @_;
    my $lhs   = shift @_;
    my $rhs   = shift @_;
    my $this  = { };

    CC::CC::assert($lhs || $rhs);
    
    $this->{lhs} = $lhs;
    $this->{rhs} = $rhs;

    if ( ! $rhs) {
        $this->{kind} = '<<';
    } elsif ( ! $lhs) {
        $this->{kind} = '>>';
    } elsif ($lhs->equals($rhs)) {
        $this->{kind} = '==';
    } else {
        $this->{kind} = '<>';
    }

    return bless($this, $class);
}

##############################################################################
sub DESTROY
##############################################################################
{
    return 1;  # no-op
}

##############################################################################
sub lhs
##############################################################################
{
    my $this = shift @_;
    return $this->{lhs};
}

##############################################################################
sub rhs
##############################################################################
{
    my $this = shift @_;
    return $this->{rhs};
}

##############################################################################
sub kind
##############################################################################
{
    my $this = shift @_;
    return $this->{kind};
}

##############################################################################
sub print
##############################################################################
{
    my $this = shift @_;
    my $lhs  = $this->lhs();
    my $rhs  = $this->rhs();
    my $comp = ($lhs ? $lhs->component() : $rhs->component());

    printf("##### component %s:\t%20s %s %s\n",
           $comp->name(),
           ($lhs ? $lhs->name() : ''),
           $this->kind(),
           ($rhs ? $rhs->name() : ''));

    return 1;
}

##############################################################################
sub results
##############################################################################
{
    # my $trace();
    my $this  = shift @_;
    my $lhs   = $this->lhs();
    my $rhs   = $this->rhs();
    my $vob   = $lhs->vob();
    my @diffs;

    CC::CC::assert($this->kind() eq '<>');

    my @lines = $this->{cleartool}->exec('diffbl', $lhs->objsel(), $rhs->objsel());

    return  $this->{cleartool}->status? 0 : map { new CC::DiffResult($_, $vob); } @lines;
}


##############################################################################
package CC::CompositeDiff;
##############################################################################


##############################################################################
sub DESTROY
##############################################################################
{
    return 1;  # no-op
}

##############################################################################
sub lhs
##############################################################################
{
    my $this = shift @_;
    return $this->{lhs};
}

##############################################################################
sub rhs
##############################################################################
{
    my $this = shift @_;
    return $this->{rhs};
}

##############################################################################
sub results
##############################################################################
{
    # my $trace();
    my $this     = shift @_;
    my %lhs_hash = _component_to_operand_hash($this->lhs());
    my %rhs_hash = _component_to_operand_hash($this->rhs());
    my @comps    = _remove_duplicates(keys(%lhs_hash), keys(%rhs_hash));

    return map {
        new CC::BaselineDiff($lhs_hash{$_}, $rhs_hash{$_});
    } @comps;
}

##############################################################################
sub _component_to_operand_hash
##############################################################################
{
    my $op = shift @_;
    my ($dep, $comp);
    my %hash;

    if ($op->metatype() eq 'stream') {

        for $comp ($op->components()) {
            $hash{$comp->objsel()} = $op;
        }

    } elsif ($op->has_dependencies()) {

        for $dep ($op->dependencies()) {
            $hash{$dep->component()->objsel()} = $dep;
        }

    } else {

        $hash{$op->component()->objsel()} = $op;
    }

    return %hash;
}

##############################################################################
sub _remove_duplicates
##############################################################################
{
    my %item_hash;

    # Initialize hash using list items as keys, which eliminates duplicates.
    @item_hash{@_} = 0;

    # Reconsitute list from hash keys.
    return keys(%item_hash);
}

1;   # Make "use" and "require" happy
