package Acme::Crap;
use 5.010;

our $VERSION = '0.001002';

use warnings;
use strict;
use Carp;

sub deref { my ($self) = @_; return ${$self}; }

use overload (
    q{!}    => sub { Acme::Crap::Negated->new(&deref) },
    q{""}   => \&deref,
    q{0+}   => \&deref,
    q{bool} => \&deref,

    fallback => 1,
);

sub import {
    overload::constant q => sub { my $val = $_[1]; bless \$val, 'Acme::Crap' };

    no strict qw( refs );
    *{caller().'::crap'} = sub {
        local $Acme::Crap::no_negation = 1;
        @_ = map {"$_"} @_;
        goto &Carp::carp;
    }
}

package Acme::Crap::Negated;

sub new {
    my ($class, $val) = @_;
    bless { val => $val, degree => 1 }, $class;
}

sub value {
    my ($self) = @_;
    if ($Acme::Crap::no_negation) {
        given ($self->{degree}) {
            when (1) { return ucfirst "$self->{val}!" }
            when (2) { return join q{}, map { ucfirst $_ } split /(\s+)/, "$self->{val}!!" }
            default  { return uc $self->{val} . '!' x $_ }
        }
    }
    return !$self->{val} if $self->{degree} % 2;
    return !!$self->{val};
}

use overload (
    q{!}    => sub { my ($self) = @_; $self->{degree}++; return $self; },
    q{""}   => \&value,
    q{0+}   => \&value,
    q{bool} => \&value,

    fallback => 1,
);

1; # Magic true value required at end of module

__END__

=head1 NAME

Acme::Crap - Carp with more feeling


=head1 VERSION

This document describes Acme::Crap version 0.001002


=head1 SYNOPSIS

    use Acme::Crap;

    crap "there was a problem";

    crap! "there was a bad problem";

    crap!! "there was a really bad problem";

    crap!!! "there was a really very bad problem";


=head1 DESCRIPTION

Load the module. Now you can spell C<carp> more scatologically, and with
as many trailing exclamation marks as you need to satisfy your degree of
frustration.


=head1 INTERFACE

Always exports the C<crap> subroutine, which works just like
C<carp> but allows trailing exclamation marks on the sub name,
for emphasis.


=head1 DIAGNOSTICS

None. C<crap> I<is> a diagnostic.


=head1 CONFIGURATION AND ENVIRONMENT

Acme::Crap requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

Uses string constant overloading, so potentially incompatible with all
other modules that use string constant overloading.

No actual incompatibilities reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-crap@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
