package Claude::Agent::Code::Review::Types;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

our (@SEVERITIES, @CATEGORIES);

BEGIN {
    @SEVERITIES = qw(critical high medium low info);
    @CATEGORIES = qw(bugs security style performance maintainability);

    my $enum = sub {
        my %ok = map { $_ => 1 } @_;
        return sub { defined $_[0] && !ref $_[0] && $ok{$_[0]} };
    };

    Object::Proto::register_type('ReviewSeverity', $enum->(@SEVERITIES));
    Object::Proto::register_type('ReviewCategory', $enum->(@CATEGORIES));
}

1;

__END__

=head1 NAME

Claude::Agent::Code::Review::Types - Slot types shared by the review classes

=head1 SYNOPSIS

    use Claude::Agent::Code::Review::Types;

    BEGIN {
        Object::Proto::define('My::Issue',
            'severity:ReviewSeverity:required',
            'category:ReviewCategory:required',
        );
    }

=head1 DESCRIPTION

Registers the two enumerations the review classes validate against. Load
it before the C<BEGIN> block that defines a class using one of them.

=head1 TYPES

=over 4

=item * ReviewSeverity - one of C<@Claude::Agent::Code::Review::Types::SEVERITIES>:
C<critical>, C<high>, C<medium>, C<low>, C<info>

=item * ReviewCategory - one of C<@Claude::Agent::Code::Review::Types::CATEGORIES>:
C<bugs>, C<security>, C<style>, C<performance>, C<maintainability>

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
