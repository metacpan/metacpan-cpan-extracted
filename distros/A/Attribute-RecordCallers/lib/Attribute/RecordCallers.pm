package Attribute::RecordCallers;

use strict;
use warnings;
use Attribute::Handlers;
use Carp qw(carp);
use Time::HiRes qw(time);
use Scalar::Util qw(set_prototype);

our $VERSION = '0.02';

our @CARP_NOT = qw(Attribute::Handlers);
# arguably a bug in Carp, but Attribute::Handlers does
# nasty things with UNIVERSAL
@Attribute::Handlers::CARP_NOT = qw(attributes);

our %callers;

sub UNIVERSAL::RecordCallers :ATTR(CODE,BEGIN) {
    my ($pkg, $glob, $referent) = @_;
    no strict 'refs';
    no warnings qw(redefine once prototype);
    my $subname = *{$glob}{NAME};
    if ($subname eq 'ANON') {
        carp "Ignoring RecordCallers attribute on anonymous subroutine";
        return;
    }
    $subname = $pkg . '::' . $subname;
    *$subname = sub {
        push @{ $callers{$subname} ||= [] }, [ caller, time ];
        goto &$referent;
    };
    my $proto = prototype $referent;
    set_prototype(\&$subname, $proto) if defined $proto;
}

sub clear {
    %callers = ();
}

sub walk {
    my $coderef = shift;
    $coderef->($_, $callers{$_}) for sort keys %callers;
}

1;

=head1 NAME

Attribute::RecordCallers - keep a record of who called a subroutine

=head1 SYNOPSIS

    use Attribute::RecordCallers;
    sub call_me_and_i_ll_tell_you : RecordCallers { ... }
    ...
    END {
        use Data::Dumper;
        print Dumper \%Attribute::RecordCallers::callers;
    }

=head1 DESCRIPTION

This module defines a function attribute that will trigger collection of
callers for the designated functions.

Each time a function with the C<:RecordCallers> attribute is run, a global
hash C<%Attribute::RecordCallers::caller> is populated with caller information.
The keys in the hash are the function names, and the elements are arrayrefs
containing lists of quadruplets:

    [ $package, $filename, $line, $timestamp ]

The timestamp is obtained via C<Time::HiRes>.

=head1 FUNCTIONS

=over 4

=item clear()

(not exported) This function will clear the C<%callers> global hash.

=item walk(sub { ... })

(not exported) Invokes the subroutine passed as argument once for each
item in the C<%callers> hash. The arguments passed to it are the
recorded subroutine name, and the arrayref of arrayrefs recording
all the calls.

=back

=head1 LIMITATIONS

You cannot use the C<:RecordCaller> attribute on anonymous or lexical
subroutines, or or subroutines with any other attribute (such as
C<:lvalue>).

With perls older than version 5.16.0, setting the C<:RecordCallers>
attribute will remove the prototype of any subroutine.

=head1 LICENSE

(c) Rafael Garcia-Suarez (rgs at consttype dot org) 2014

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

A git repository for the sources is at L<https://github.com/rgs/Attribute-RecordCallers>.

=cut
