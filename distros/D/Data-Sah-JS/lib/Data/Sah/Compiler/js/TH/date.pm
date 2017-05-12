package Data::Sah::Compiler::js::TH::date;

our $DATE = '2016-09-14'; # DATE
our $VERSION = '0.87'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;
use Scalar::Util qw(blessed looks_like_number);

extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::date';

sub handle_type {
    my ($self, $cd) = @_;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = join(
        ' && ',
        "($dt instanceof Date)",
    );
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "+($dt) === +($ct)");
    } elsif ($which eq 'in') {
        if ($cd->{cl_is_expr}) {
            # i'm lazy, technical debt
            $c->_die($cd, "date's in clause with expression not yet supported");
        }
        $ct = '['.join(', ', map { "+($_)" } @$cv).']';
        $c->add_ccl($cd, "($ct).indexOf(+($dt)) > -1");
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        # i'm lazy, technical debt
        $c->_die($cd, "date's comparison with expression not yet supported");
    }

    if ($which eq 'min') {
        $c->add_ccl($cd, "+($dt) >= +($cv)");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "+($dt) > +($cv)");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "+($dt) <= +($cv)");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "+($dt) < +($cv)");
    } elsif ($which eq 'between') {
        $c->add_ccl($cd, "+($dt) >= +($cv->[0]) && +($dt) <= +($cv->[1])");
    } elsif ($which eq 'xbetween') {
        $c->add_ccl($cd, "+($dt) >  +($cv->[0]) && +($dt) <  +($cv->[1])");
    }
}

1;
# ABSTRACT: js's type handler for type "date"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::js::TH::date - js's type handler for type "date"

=head1 VERSION

This document describes version 0.87 of Data::Sah::Compiler::js::TH::date (from Perl distribution Data-Sah-JS), released on 2016-09-14.

=head1 DESCRIPTION

Unlike in perl compiler where the C<date> type can be represented either as int
(epoch), L<DateTime> object or L<Time::Moment> object, in js compiler we only
represent date with the C<Date> object.

Date() accept various kinds of arguments, including:

=over

=item * Date()

Current date.

=item * Date(milliseconds epoch)

=item * Date(year, month, date, hour, minute, sec, millisec)

But year is 114 utk 2014, month=0 for January.

=item * Date(datestring)

This saves us from doing date parsing ourselves.

=item * Date(another Date object)

=back

But note that if the arguments are invalid, Date() will still return a Date
object, but if we try to do C<d.getMonth()> or C<d.getYear()> it will return
NaN. This can be used to check that a date is invalid: C<< isNaN(d.getYear()) >>
or simply C<<isNaN(d)>>.

To compare 2 Date object, we can use C<< d1 > d2 >>, C<< d1 < d2 >>, but for
anything involving equality check, we need to prefix using C<+>, C<+d1 === +d2>.

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-JS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-JS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-JS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
