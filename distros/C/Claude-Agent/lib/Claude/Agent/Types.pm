package Claude::Agent::Types;

use 5.020;
use strict;
use warnings;

use Carp ();
use Object::Proto ();

our (@PERMISSION_MODES, @EFFORT_LEVELS);

BEGIN {
    @PERMISSION_MODES = qw(default acceptEdits bypassPermissions dontAsk plan auto manual);
    @EFFORT_LEVELS    = qw(low medium high xhigh max);

    my $enum = sub {
        my %ok = map { $_ => 1 } @_;
        return sub { defined $_[0] && !ref $_[0] && $ok{$_[0]} };
    };

    Object::Proto::register_type('StrList', sub {
        return 0 unless ref $_[0] eq 'ARRAY';
        return 0 if grep { !defined $_ || ref $_ } @{$_[0]};
        return 1;
    });
    Object::Proto::register_type('StrOrHashRef', sub {
        defined $_[0] && (!ref $_[0] || ref $_[0] eq 'HASH');
    });
    Object::Proto::register_type('StrOrArrayRef', sub {
        defined $_[0] && (!ref $_[0] || ref $_[0] eq 'ARRAY');
    });
    Object::Proto::register_type('PermissionMode', $enum->(@PERMISSION_MODES));
    Object::Proto::register_type('Effort',         $enum->(@EFFORT_LEVELS));
}

sub known_args {
    my ($class, $hash) = @_;
    my %known = map { $_ => 1 } Object::Proto::properties($class);
    return map { $_ => $hash->{$_} }
        grep { $known{$_} && defined $hash->{$_} } keys %$hash;
}

sub check_args {
    my ($class, %args) = @_;
    my %known = map { $_ => 1 } Object::Proto::properties($class);
    my @bad = sort grep { !$known{$_} } keys %args;
    Carp::croak("Unknown option(s) for $class: @bad") if @bad;
    return %args;
}

sub defined_args {
    my (%args) = @_;
    return map { defined $args{$_} ? ($_ => $args{$_}) : () } keys %args;
}

1;

__END__

=head1 NAME

Claude::Agent::Types - Slot types and constructor helpers for Claude::Agent classes

=head1 SYNOPSIS

    use Claude::Agent::Types;

    BEGIN {
        Object::Proto::define('My::Class',
            'tools:StrList:predicate',
            'mode:PermissionMode:predicate',
        );
    }

    my $obj = My::Class->new(Claude::Agent::Types::known_args('My::Class', $decoded));

=head1 DESCRIPTION

Every class in this distribution is an L<Object::Proto> class. This module
registers the slot types those classes share and provides the helpers their
factories use. Load it before the C<BEGIN> block that defines a class using
one of the types; a type name that is not registered is silently ignored.

=head1 TYPES

=over 4

=item * StrList - an array reference of defined, non-reference strings

=item * StrOrHashRef - a string or a hash reference

=item * StrOrArrayRef - a string or an array reference

=item * PermissionMode - one of C<@Claude::Agent::Types::PERMISSION_MODES>:
C<default>, C<acceptEdits>, C<bypassPermissions>, C<dontAsk>, C<plan>,
C<auto>, C<manual>

=item * Effort - one of C<@Claude::Agent::Types::EFFORT_LEVELS>: C<low>,
C<medium>, C<high>, C<xhigh>, C<max>

=back

=head1 FUNCTIONS

=head2 known_args

    my %args = Claude::Agent::Types::known_args($class, \%hash);

Returns the name/value pairs of C<%hash> whose names are slots of C<$class>
and whose values are defined. Factories that build objects from decoded JSON
call this first: an Object::Proto class with no default slot reads a pair
list positionally when its first name is unknown, and typed slots reject
C<undef>, so JSON null and unexpected keys are dropped here rather than
reaching C<new>.

=head2 check_args

    my %args = Claude::Agent::Types::check_args($class, %args);

Returns C<%args> unchanged, or croaks naming every key that is not a slot of
C<$class>. C<Claude::Agent::Options-E<gt>create> uses it to make a misspelt
option fatal; C<new> itself ignores unknown keys.

=head2 defined_args

    my %args = Claude::Agent::Types::defined_args(%args);

Returns the pairs of C<%args> whose values are defined, so a caller can pass
optional values straight through to a constructor whose slots are typed.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
