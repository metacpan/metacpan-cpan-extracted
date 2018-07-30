package Assert::Refute::T::Tester;

use strict;
use warnings;
our $VERSION = '0.1301';

=head1 NAME

Assert::Refute::T::Tester - test the test conditions themselves

=head1 DESCRIPTION

This module is inspired by L<Test::Tester>.
While C<contract_is> is a good way to quickly determine
whether a test condition holds any water, a more detailed
inspection is desirable.

B<[EXPERIMENTAL]> This module is under active development and
its interface may change in the future.

=head1 SYNOPSIS

    use Test::More;
    use Assert::Refute::T::Tester;

    use My::Refute::Module qw(check_this check_that);

    my $report = try_refute {
        check_this(...); # pass
        check_that(...); # fail
    };

    test_test
        $report->get_result_details(0),
        { diag => [] },
        "No premature output";

    test_test
        $report->get_result_details(1),
        { ok => 1 },
        "Passing test";

    test_test
        $report->get_result_details(2),
        { ok => 0, diag => [ qr/foo/, qr/bar/ ] },
        "Failing test";

=head1 EXPORT

The following functions are exported by default:

=cut

use Carp;
use parent qw(Exporter);
use Assert::Refute::Build;

=head2 test_test

    test_test \%result_details, \%spec, "Message";

Result details come from L<Assert::Refute::Report/get_result_details($id)>.

The exact format MAY change in the future, but this test should keep working.

%spec may include:

=over

=item * C<ok> - whether the test passed or not.

=item * C<name> - test name (without the number)
Can be exact string or regular expression.

=item * C<diag> - an array of exact strings or regular expressions.
Each line of output will be matched against exactly one expectation.

Output produced by C<note()> is ignored.

=back

=cut

build_refute test_test => \&_test_test, manual => 1, args => 2, export => 1;

my %allow;
$allow{$_}++ for qw( ok name diag );
sub _test_test {
    my ($self, $hash, $spec, $external_name) = @_;

    croak "Usage: test_test( \%test_result, \%spec, [ \"message\" ] )"
        if (ref $hash ne 'HASH' or ref $spec ne 'HASH');

    my @extra = grep { !$allow{$_} } keys %$spec;
    croak "test_test(): Unknown fields (@extra) in spec"
        if @extra;

    my $ok = $spec->{ok};
    my $name = $spec->{name};
    my $diag = $spec->{diag};

    croak "test_test(): diag() must be an array of strings and/or regular expressions"
        if $diag and ref $diag ne 'ARRAY';

    $external_name ||= "Assert::Refute contract entry as expected";

    $self->subcontract( $external_name => sub {
        my $rep = shift;

        if (defined $ok) {
            $rep->refute( ($ok xor $hash->{ok}), "test ".($ok?"passed":"failed"));
        };

        if (defined $name) {
            _like_or_ok( $rep, $hash->{name}, $name, "Test name is $name" );
        };

        if (defined $diag) {
            _lines_like( $rep, $hash->{diag}, $diag, "Diagnostics" );
        };
    } );
};

sub _lines_like {
    my ($rep, $got, $exp, $message) = @_;

    foreach (0 .. @$exp-1) {
        _like_or_ok( $rep, $got->[$_], $exp->[$_],
            "$message: Line $_ matches ".to_scalar( $exp->[$_] ) );
    };
    $rep->is( scalar @$got, scalar @$exp,
        "$message: Exactly ".(scalar @$exp)." lines present" );
};

sub _like_or_ok {
    my ($rep, $got, $exp, $msg) = @_;

    if (ref $exp eq 'Regexp') {
        $rep->like( $got, $exp, $msg );
    } else {
        $rep->is( $got, $exp, $msg );
    };
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017-2018 Konstantin S. Uvarin. C<< <khedin at cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
