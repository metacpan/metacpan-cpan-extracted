package Data::Sah::Filter::perl::Str::check;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-04'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

sub meta {
    +{
        v => 1,
        summary => 'Perform some checks',
        might_fail => 1,
        args => {
            min_len => {
                schema => 'uint*',
            },
            max_len => {
                schema => 'uint*',
            },
            match => {
                schema => 're*',
            },
            in => {
                schema => ['array*', of=>'str*'],
            },
        },
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};

    my @check_exprs;
    if (defined $gen_args->{min_len}) {
        my $val = $gen_args->{min_len} + 0;
        push @check_exprs, (@check_exprs ? "elsif" : "if") . qq( (length(\$tmp) < $val) { ["Length of data must be at least $val", \$tmp] } );
    }
    if (defined $gen_args->{max_len}) {
        my $val = $gen_args->{max_len} + 0;
        push @check_exprs, (@check_exprs ? "elsif" : "if") . qq( (length(\$tmp) > $val) { ["Length of data must be at most $val", \$tmp] } );
    }
    if (defined $gen_args->{match}) {
        my $val = ref $gen_args->{match} eq 'Regexp' ? $gen_args->{match} : qr/$gen_args->{match}/;
        push @check_exprs, (@check_exprs ? "elsif" : "if") . qq| (\$tmp !~ |.dmp($val).qq|) { ["Data must match $val", \$tmp] } |;
    }
    if (defined $gen_args->{in}) {
        my $val = $gen_args->{in};
        push @check_exprs, (@check_exprs ? "elsif" : "if") . qq| (!grep { \$_ eq \$tmp } \@{ |.dmp($val).qq| }) { ["Data must be one of ".join(", ", \@{|.dmp($val).qq|}), \$tmp] } |;
    }
    unless (@check_exprs) {
        push @check_exprs, qq(if (0) { } );
    }
    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do {",
        "    my \$tmp = $dt; ",
        @check_exprs,
        "    else { [undef, \$tmp] } ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Perform some checks

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::check - Perform some checks

=head1 VERSION

This document describes version 0.008 of Data::Sah::Filter::perl::Str::check (from Perl distribution Data-Sah-Filter), released on 2020-06-04.

=head1 SYNOPSIS

Use in Sah schema's C<prefilters> (or C<postfilters>) clause:

 ["str","prefilters",["Str::check"]]

=head1 DESCRIPTION

This is more or less a demo filter rule, to show how a filter rule can be used
to perform some checks. The standard checks performed by this rule, however,
are better done using standard schema clauses like C<in>, C<min_len>, etc.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
