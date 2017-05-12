package Test::DateTime::Format::Alami;

use 5.010001;
use strict;
use warnings;

use DateTime;
use Test::More 0.98;

use Exporter qw(import);
our @EXPORT = qw(test_datetime_format_alami);

sub test_datetime_format_alami {
    my ($class0, $tests) = @_;

    my $class = "DateTime::Format::Alami::$class0";
    eval "use $class"; die if $@;

    subtest "test suite for $class" => sub {
        my $parser = $class->new;

        for my $t (@{ $tests->{parse_datetime_tests} }) {
            my ($str, $exp_result) = @$t;
            subtest $str => sub {
                my $dt;
                eval { $dt = $parser->parse_datetime(
                    $str, {time_zone => $tests->{time_zone}}) };
                my $err = $@;
                if ($exp_result) {
                    ok(!$err, "parse should succeed") or return;
                    is("$dt", $exp_result, "result should be $exp_result");
                } else {
                    ok($err, "parse should fail");
                    return;
                }
            };
        } # parse_datetime_tests

        require DateTime::Format::Duration::ISO8601;
        my $pdur = DateTime::Format::Duration::ISO8601->new;
        for my $t (@{ $tests->{parse_datetime_duration_tests} }) {
            my ($str, $exp_result) = @$t;
            subtest $str => sub {
                my $dtdur;
                eval { $dtdur = $parser->parse_datetime_duration($str) };
                my $err = $@;
                if ($exp_result) {
                    ok(!$err, "parse should succeed") or return;
                    is($pdur->format_duration($dtdur), $exp_result,
                       "result should be $exp_result");
                } else {
                    ok($err, "parse should fail");
                    return;
                }
            };
        } # parse_datetime_duration_tests
    };
}

1;
# ABSTRACT: Test DateTime::Format::Alami

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DateTime::Format::Alami - Test DateTime::Format::Alami

=head1 VERSION

This document describes version 0.14 of Test::DateTime::Format::Alami (from Perl distribution DateTime-Format-Alami), released on 2017-04-25.

=head1 FUNCTIONS

=head2 test_datetime_format_alami($class, \%tests)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DateTime-Format-Alami>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DateTime-Format-Alami>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-Alami>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
