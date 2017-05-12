package Data::Dump::Patch::Deparse;

our $DATE = '2017-02-11'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
no warnings;
#use Log::Any '$log';

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

our %config;

# stolen from Data::Dmp, with minor mods
our $OPT_REMOVE_PRAGMAS = 1;
our $OPT_PERL_VERSION = 5.010;
sub _dump_code {
    my $code = shift;

    state $deparse = do {
        require B::Deparse;
        B::Deparse->new("-l"); # -i option doesn't have any effect?
    };

    my $res = $deparse->coderef2text($code);

    my ($res_before_first_line, $res_after_first_line) =
        $res =~ /(.+?)^(#line .+)/ms;

    if ($OPT_REMOVE_PRAGMAS) {
        $res_before_first_line = "{ ";
    } elsif ($OPT_PERL_VERSION < 5.016) {
        # older perls' feature.pm doesn't yet support q{no feature ':all';}
        # so we replace it with q{no feature}.
        $res_before_first_line =~ s/no feature ':all';/no feature;/m;
    }
    $res_after_first_line =~ s/^#line .+//gm;

    $res = "sub " . $res_before_first_line . $res_after_first_line;
    $res =~ s/^\s+//gm;
    $res =~ s/\n+//g;
    $res =~ s/;\}\z/ }/;
    $res;
}

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'wrap',
                sub_name => '_dump',
                code => sub {
                    my $ctx = shift;
                    my $res = $ctx->{orig}->(@_);
                    if ($res eq 'sub { ... }') {
                        $res = _dump_code($_[0]);
                    } elsif ($res =~ /\A\Qbless(sub { ... }, \E(".+")\)\z/) {
                        $res = "bless("._dump_code($_[0]).", $1)";
                    }
                    $res;
                },
            },
        ],
    };
}

1;
# ABSTRACT: Patch Data::Dump so it deparses code references

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dump::Patch::Deparse - Patch Data::Dump so it deparses code references

=head1 VERSION

This document describes version 0.001 of Data::Dump::Patch::Deparse (from Perl distribution Data-Dump-Patch-Deparse), released on 2017-02-11.

=head1 SYNOPSIS

In your source code:

 use Data::Dump::Patch::Deparse;
 use Data::Dump;

 dd(sub { [1,2] }); # now prints "sub { [1, 2] }" instead of "sub { ... }"

On the command-line:

 % perl -MData::Dump::Patch::Deparse -MData::Dump -e'dd ...'

=head1 DESCRIPTION

=for Pod::Coverage ^(patch_data)$

=head1 PACKAGE VARIABLES

=head2 $OPT_REMOVE_PRAGMAS

Like in L<Data::Dmp>.

=head2 $OPT_PERL_VERSION

Like in L<Data::Dmp>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-Patch-Deparse>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-Patch-Deparse>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-Patch-Deparse>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Dump>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
