package Data::Sah::Coerce::perl::duration::str_human;

our $DATE = '2018-12-16'; # DATE
our $VERSION = '0.031'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 3,
        enable_by_default => 1,
        might_fail => 1, # we feed most string to Time::Duration::Parse::AsHash which might croak when fed invalid string
        prio => 60,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(secs)';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "!ref($dt)",
        "$dt =~ /\\d.*[a-z]/",
    );

    $res->{modules}{"Time::Duration::Parse::AsHash"} //= 0;
    if ($coerce_to eq 'float(secs)') {
        # approximation
        $res->{expr_coerce} = qq(do { my \$p; eval { \$p = Time::Duration::Parse::AsHash::parse_duration($dt) }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid duration: \$err"] } else { [undef, (\$p->{years}||0) * 365.25*86400 + (\$p->{months}||0) * 30.4375*86400 + (\$p->{weeks}||0) * 7*86400 + (\$p->{days}||0) * 86400 + (\$p->{hours}||0) * 3600 + (\$p->{minutes}||0) * 60 + (\$p->{seconds}||0)] } });
    } elsif ($coerce_to eq 'DateTime::Duration') {
        $res->{modules}{"DateTime::Duration"} //= 0;
        $res->{expr_coerce} = qq(do { my \$p; eval { \$p = Time::Duration::Parse::AsHash::parse_duration($dt) }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid duration: \$err"] } else { [undef, DateTime::Duration->new( (years=>\$p->{years}) x !!defined(\$p->{years}), (months=>\$p->{months}) x !!defined(\$p->{months}), (weeks=>\$p->{weeks}) x !!defined(\$p->{weeks}), (days=>\$p->{days}) x !!defined(\$p->{days}), (hours=>\$p->{hours}) x !!defined(\$p->{hours}), (minutes=>\$p->{minutes}) x !!defined(\$p->{minutes}), (seconds=>\$p->{seconds}) x !!defined(\$p->{seconds}))] } });
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(secs) or DateTime::Duration";
    }

    $res;
}

1;
# ABSTRACT: Coerce duration from human notation string (e.g. "2 days 10 hours", "3h")

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::duration::str_human - Coerce duration from human notation string (e.g. "2 days 10 hours", "3h")

=head1 VERSION

This document describes version 0.031 of Data::Sah::Coerce::perl::duration::str_human (from Perl distribution Data-Sah-Coerce), released on 2018-12-16.

=head1 DESCRIPTION

The human notation is parsed using L<Time::Duration::Parse::AsHash>.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
