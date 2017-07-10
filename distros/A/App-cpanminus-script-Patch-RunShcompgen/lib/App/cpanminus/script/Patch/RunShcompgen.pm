package App::cpanminus::script::Patch::RunShcompgen;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

use File::Which;

my $p_install = sub {
    my $ctx = shift;
    my $orig = $ctx->{orig};

    my $res = $orig->(@_);

    {
        last unless $res; # installation failed

        last unless which("shcompgen");

        # list the exes that got installed
        my @exes;
        for (glob("blib/bin/*"), glob("blib/script/*")) {
            s!.+/!!;
            push @exes, $_;
        }

        last unless @exes;

        system "shcompgen", "generate", @exes;
    }

    $res; # return original result
};

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'wrap',
                sub_name    => 'install',
                code        => $p_install,
            },
        ],
   };
}

1;
# ABSTRACT: Run shcompgen after distribution installation

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cpanminus::script::Patch::RunShcompgen - Run shcompgen after distribution installation

=head1 VERSION

This document describes version 0.001 of App::cpanminus::script::Patch::RunShcompgen (from Perl distribution App-cpanminus-script-Patch-RunShcompgen), released on 2017-07-10.

=head1 SYNOPSIS

In the command-line:

 % perl -MModule::Load::In::INIT=App::cpanminus::script::Patch::RunShcompgen `which cpanm` ...

=head1 DESCRIPTION

This patch makes L<cpanm> run L<shcompgen> after a distribution installation so
when there are scripts that are installed, the shell completion for those
scripts can be activated immediately for use.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cpanminus-script-Patch-RunShcompgen>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cpanminus-script-Patch-RunShcompgen>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cpanminus-script-Patch-RunShcompgen>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<shcompgen>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
