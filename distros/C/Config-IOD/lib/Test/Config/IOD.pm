package Test::Config::IOD;

our $DATE = '2017-08-05'; # DATE
our $VERSION = '0.34'; # VERSION

## no critic (Modules::ProhibitAutomaticExportation)

use 5.010;
use strict;
use warnings;

use Test::Differences;
use Test::Exception;
use Test::More;
use Config::IOD;

use Exporter qw(import);
our @EXPORT = qw(test_modify_doc);

sub test_modify_doc {
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my ($code, $doc1, $doc2, $name) = @_;

    subtest +($name // "test_modify_doc") => sub {
        my $iod = Config::IOD->new;
        my $doc = $iod->read_string($doc1);
        if ($opts->{dies}) {
            dies_ok { $code->($doc) } "dies"
                or return 0;
            return 1;
        } else {
            lives_ok { $code->($doc) } "lives"
                or return 0;
        }
        eq_or_diff $doc->as_string, $doc2, "result";
    };
}

1;
# ABSTRACT: Testing routines for Config::IOD

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Config::IOD - Testing routines for Config::IOD

=head1 VERSION

This document describes version 0.34 of Test::Config::IOD (from Perl distribution Config-IOD), released on 2017-08-05.

=head1 FUNCTIONS

=head2 test_modify_doc($code, $doc1, $doc2[, $test_name]) => bool

Parse string C<$doc1> into a L<Config::IOD::Document> object, then run C<<
$code->($doc_obj) >>, then compare C<< $doc_obj->as_string >> with string
C<$doc2>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Config-IOD>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
