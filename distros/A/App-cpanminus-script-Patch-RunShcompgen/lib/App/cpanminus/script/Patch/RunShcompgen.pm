package App::cpanminus::script::Patch::RunShcompgen;

our $DATE = '2018-02-18'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.270 qw();
use base qw(Module::Patch);

use File::Which;

my $p_install = sub {
    my $ctx = shift;
    my $orig = $ctx->{orig};

    my $res = $orig->(@_);

    {
        warn __PACKAGE__.": Running install() ...\n" if $ENV{DEBUG};
        unless ($res) {
            # installation failed
            warn "  Returning, installation failed\n" if $ENV{DEBUG};
            last;
        }

        unless (which("shcompgen")) {
            warn __PACKAGE__.": Skipped, shcompgen not found\n" if $ENV{DEBUG};
            last;
        }

        # list the exes that got installed
        my @exes;
        for (glob("blib/bin/*"), glob("blib/script/*")) {
            s!.+/!!;
            push @exes, $_;
        }

        unless (@exes) {
            warn __PACKAGE__.": Skipped, no exes found\n" if $ENV{DEBUG};
            return;
        }

        warn __PACKAGE__.": Running shcompgen generate --replace ".join(" ", @exes)."\n" if $ENV{DEBUG};
        system "shcompgen", "generate", "--replace", @exes;
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

This document describes version 0.003 of App::cpanminus::script::Patch::RunShcompgen (from Perl distribution App-cpanminus-script-Patch-RunShcompgen), released on 2018-02-18.

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

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
