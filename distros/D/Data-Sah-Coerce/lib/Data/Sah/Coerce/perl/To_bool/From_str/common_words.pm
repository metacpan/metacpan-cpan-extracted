package Data::Sah::Coerce::perl::To_bool::From_str::common_words;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-03'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.046'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Convert common true/false words (e.g. "yes","true","on","1" to "1", and "no","false","off","0" to "")',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "1",
    );

    $res->{expr_coerce} = "$dt =~ /\\A(yes|true|on)\\z/i ? 1 : $dt =~ /\\A(no|false|off|0)\\z/i ? '' : $dt";

    $res;
}

1;
# ABSTRACT: Convert common true/false words (e.g. "yes","true","on","1" to "1", and "no","false","off","0" to "")

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_bool::From_str::common_words - Convert common true/false words (e.g. "yes","true","on","1" to "1", and "no","false","off","0" to "")

=head1 VERSION

This document describes version 0.046 of Data::Sah::Coerce::perl::To_bool::From_str::common_words (from Perl distribution Data-Sah-Coerce), released on 2020-01-03.

=head1 DESCRIPTION

This coercion rule converts "true", "yes", "on" (matched case-insensitively) to
"1"; and "false", "no", "off", "0" (matched case-insensitively) to "". All other
strings are left untouched.

B<Note that this rule is incompatible with Perl's notion of true/false.> Perl
regards all non-empty string that isn't "0" (including "no", "false", "off") as
true. But this might be useful in CLI's or other places.

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

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
