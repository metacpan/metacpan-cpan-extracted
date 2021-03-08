package Text::ANSITable::StyleSet::Calendar::Indonesia::Holiday::HolidayType;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-17'; # DATE
our $DIST = 'App-IndonesianHolidayUtils'; # DIST
our $VERSION = '0.061'; # VERSION

use 5.010;
use Moo;
use experimental 'smartmatch';
use namespace::clean;

use List::MoreUtils ();

has holiday_bgcolor     => (is => 'rw');
has holiday_fgcolor     => (is => 'rw');
has joint_leave_bgcolor => (is => 'rw');
has joint_leave_fgcolor => (is => 'rw');

sub summary {
    "Set foreground and/or background color for different holiday types";
}

sub apply {
    my ($self, $table) = @_;

    $table->add_cond_row_style(
        sub {
            my ($t, %args) = @_;
            my %styles;

            my $r = $args{row_data};
            my $cols = $t->columns;

            my $is_h_idx  = List::MoreUtils::firstidx(
                sub {$_ eq 'is_holiday'}, @$cols);
            my $is_jl_idx = List::MoreUtils::firstidx(
                sub {$_ eq 'is_joint_leave'}, @$cols);

            if ($is_h_idx >= 0 && $r->[$is_h_idx]) {
                $styles{bgcolor} = $self->holiday_bgcolor
                    if defined $self->holiday_bgcolor;
                $styles{fgcolor}=$self->holiday_fgcolor
                    if defined $self->holiday_fgcolor;
            } elsif ($is_jl_idx >= 0 && $r->[$is_jl_idx]) {
                $styles{bgcolor} = $self->joint_leave_bgcolor
                    if defined $self->joint_leave_bgcolor;
                $styles{fgcolor} = $self->joint_leave_fgcolor
                    if defined $self->joint_leave_fgcolor;
            }
            \%styles;
        },
    );
}

1;
# ABSTRACT: Set foreground and/or background color for different holiday types

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable::StyleSet::Calendar::Indonesia::Holiday::HolidayType - Set foreground and/or background color for different holiday types

=head1 VERSION

This document describes version 0.061 of Text::ANSITable::StyleSet::Calendar::Indonesia::Holiday::HolidayType (from Perl distribution App-IndonesianHolidayUtils), released on 2021-01-17.

=for Pod::Coverage ^(summary|apply)$

=head1 ATTRIBUTES

=head2 holiday_bgcolor

=head2 holiday_fgcolor

=head2 joint_leave_bgcolor

=head2 joint_leave_fgcolor

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-IndonesianHolidayUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-IndonesianHolidayUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-IndonesianHolidayUtils/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
