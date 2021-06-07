package Regexp::Common::Patch::DumpPatterns;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-25'; # DATE
our $DIST = 'App-RegexpCommonUtils'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
no warnings;

use Data::Dmp;
use parent qw(Module::Patch);

our %config;

sub _wrap_pattern {
    my $ctx = shift;
    push @main::_patterns, [@_];
    &{$ctx->{orig}}(@_);
}

END {
    print "# BEGIN DUMP $config{-tag}\n";
    local $Data::Dmp::OPT_DEPARSE = 0;
    say dmp(\@main::_patterns);
    print "# END DUMP $config{-tag}\n";
}

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'wrap',
                sub_name    => 'pattern',
                code        => \&_wrap_pattern,
            },
        ],
        config => {
            -tag => {
                schema  => 'str*',
                default => 'TAG',
            },
        },
   };
}

1;
# ABSTRACT: Patch Regexp::Common's pattern() to collect the arguments it receives and dump them all at the end

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Common::Patch::DumpPatterns - Patch Regexp::Common's pattern() to collect the arguments it receives and dump them all at the end

=head1 VERSION

This document describes version 0.003 of Regexp::Common::Patch::DumpPatterns (from Perl distribution App-RegexpCommonUtils), released on 2021-05-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-RegexpCommonUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-RegexpCommonUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-RegexpCommonUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
