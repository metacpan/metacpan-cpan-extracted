# $Id: Constraint.pm,v 1.9 2007/03/05 09:12:49 cmungall Exp $
# -------------------------------------------------------
#
# Copyright (C) 2003 Chris Mungall <cjm@fruitfly.org>
#
# This module is free software.
# You may distribute this module under the same terms as perl itself

#---
# POD docs at end of file
#---

package DBIx::DBStag::Constraint;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS $DEBUG $AUTOLOAD);
use Carp;
use DBI;
use Data::Stag qw(:all);
use DBIx::DBStag;
$VERSION='0.12';


sub DEBUG {
    $DBIx::DBStag::DEBUG = shift if @_;
    return $DBIx::DBStag::DEBUG;
}

sub trace {
    my ($priority, @msg) = @_;
    return unless $ENV{DBSTAG_TRACE};
    print "@msg\n";
}

sub dmp {
    use Data::Dumper;
    print Dumper shift;
}


sub new {
    my $proto = shift; 
    my $class = ref($proto) || $proto;

    my $self = {};
    bless $self, $class;
    $self->bindings({});
    $self->children([]);
    $self;
}

# takes a simple hash of bindings
# and makes an ANDed set of constraints
sub from_hash {
    my $class = shift;
    my $h = shift;
    my $cons = $class->new;
    $cons->bool('and');
    $cons->children([
                     map {
                         my $sc = $class->new;
                         $sc->bindings({$_ => $h->{$_}});
                         $sc;
                     } keys %$h
                    ]);
    return $cons;
}

sub throw {
    my $self = shift;
    my $fmt = shift;

    print STDERR "\nERROR:\n";
    printf STDERR $fmt, @_;
    print STDERR "\n";
    confess;
}

#AND, OR, NOT
sub bool {
    my $self = shift;
    $self->{_bool} = shift if @_;
    return $self->{_bool};
}


# eg AND(cons1, cons2, cons3)
sub children {
    my $self = shift;
    $self->{_children} = shift if @_;
    return $self->{_children};
}

sub is_leaf {
    my $self = shift;
    return !scalar(@{$self->children});
}

# value to replace => in option block with
sub op {
    my $self = shift;
    $self->{_op} = shift if @_;
    return $self->{_op};
}

# variable bindings - hash of varname => varval
sub bindings {
    my $self = shift;
    $self->{_bindings} = shift if @_;
    return $self->{_bindings};
}



1;

__END__

=head1 NAME

  DBIx::DBStag::Constraint -

=head1 SYNOPSIS


=cut

=head1 DESCRIPTION

A constraint is a recursive structure for representing query constraints;


  AND ---  x=1
    \
     \---- OR   ---  y>2
            \
             \-----  boolfunc(z)

A constraint is either a bool (AND, OR, NOT) with >0 children,
or it can be a leaf node representing an atomic constraint

the constraint corresponds to a SQLTemplate option block; eg

  [ name LIKE &name& ]
  [ name => &name& ]
  [ start > &min_start& ]
  [ start => &start& ]
  [ somefunc(&x&) ]
  [ somefunc(&x&, &y&) ]
  [ somefunc(t.col, &x&, &y&) => &z& ]

the constraint consists of an operator (represented by => in the
option block). If no => is present, then it is a simple variable binding.

A constraint can consist of multiple variable bindings

=head1 WEBSITE

L<http://stag.sourceforge.net>

=head1 AUTHOR

Chris Mungall <F<cjm@fruitfly.org>>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Mungall

This module is free software.
You may distribute this module under the same terms as perl itself

=cut



1;

