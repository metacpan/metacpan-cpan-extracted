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

CC::DiffBl - XXX

=cut

##############################################################################
package CC::DiffBl;
##############################################################################

use CC::CC;
use CC::Baseline;
use CC::Component;
# use Trace;
use strict;

##############################################################################
sub compare
##############################################################################
{
    # my $trace();
    my $lhs      = new CC::DiffBl(shift @_);
    my $rhs      = new CC::DiffBl(shift @_);
    my %lhs_hash = $lhs->component_to_operand_hash();
    my %rhs_hash = $rhs->component_to_operand_hash();
    my @comps    = _remove_duplicates(keys(%lhs_hash), keys(%rhs_hash));
    my $comp;

    for $comp (@comps) {

        my $lhs_op = $lhs_hash{$comp};
        my $rhs_op = $rhs_hash{$comp};

        printf("DEBUG: comp: %s // lhs: %s // rhs: %s\n", $comp,
               ($lhs_op ? $lhs_op->name() : "<>"),
               ($rhs_op ? $rhs_op->name() : "<>"));

        CC::CC::assert($lhs_op || $rhs_op);

        if ( ! $rhs_op) {
            printf("<< %s\n", $lhs_op->objsel());
        } elsif ( ! $lhs_op) {
            printf(">> %s\n", $rhs_op->objsel());
        } elsif ($lhs_op->equals($rhs_op)) {
            printf("== %s\t%s\n", $lhs_op->objsel(), $rhs_op->objsel());
        } else {
            printf("<> %s\t%s\n", $lhs_op->objsel(), $rhs_op->objsel());
        }
    }

    return 1;
}

##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class  = shift @_;
    my $op     = shift @_;
    my $this   = { };
    
    $this->{operand} = $op;
    $this->{status} = 0;
    return bless($this, $class);
}

##############################################################################
sub DESTROY
##############################################################################
{
    return 1;  # no-op
}

##############################################################################
sub operand
##############################################################################
{
    my $this = shift @_;
    return $this->{operand};
}

##############################################################################
sub component_to_operand_hash
##############################################################################
{
    my $this = shift @_;
    my $op   = $this->operand();
    my ($dep, $comp);
    my %hash;

    printf("DEBUG: %s // %s\n", $op->name());

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
    my @list = @_;
    my %item_hash;
    my $item;

    for $item (@list) {
        $item_hash{$item} = 0;
    }

    printf("DEBUG: rem deps: %d\n", scalar(@list));

    return keys(%item_hash);
}

##############################################################################
package CC::DiffBl;
##############################################################################

1;   # Make "use" and "require" happy
