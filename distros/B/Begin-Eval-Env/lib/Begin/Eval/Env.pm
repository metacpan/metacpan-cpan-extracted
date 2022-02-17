# minimalist
## no critic: TestingAndDebugging::RequireUseStrict
package Begin::Eval::Env;

##BEGIN ifunbuilt
use strict;
use warnings;
##END ifunbuilt

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-05'; # DATE
our $DIST = 'Begin-Eval-Env'; # DIST
our $VERSION = '0.001'; # VERSION

my @envs;
sub import {
    my $class = shift;
    push @envs, @_;
    push @envs, 'PERL_BEGIN_EVAL_ENV' unless @envs;
    for my $env (@envs) {
        next unless defined $ENV{$env};
        print "DEBUG: eval-ing ENV{$env}: $ENV{$env} ...\n" if $ENV{DEBUG};
        eval "no strict; no warnings; $ENV{$env};";
        die if $@;
    }
}

1;
# ABSTRACT: Take code from environment variable(s), then eval them

__END__

=pod

=encoding UTF-8

=head1 NAME

Begin::Eval::Env - Take code from environment variable(s), then eval them

=head1 VERSION

This document describes version 0.001 of Begin::Eval::Env (from Perl distribution Begin-Eval-Env), released on 2022-02-05.

=head1 SYNOPSIS

On the command-line:

 % PERL_BEGIN_EVAL_ENV='use Data::Dump; dd \%INC' perl -MBegin::Eval::Env `which some-perl-script.pl` ...
 % PERL_BEGIN_EVAL_ENV='use Data::Dump; dd \%INC' PERL5OPT=-MBegin::Eval::Env some-perl-script.pl ...

Customize the environment variables:

 % perl -MBegin::Eval::Env=ENVNAME1,ENVNAME2 `which some-perl-script.pl` ...
 % PERL5OPT=-MBegin::Eval::Env=ENVNAME1,ENVNAME2 some-perl-script.pl ...

=head1 DESCRIPTION

This module allows you to evaluate code(s) in environment variable(s), basically
for convenience in one-liners. If name(s) of environment variables are not
specified, C<PERL_BEGIN_EVAL_ENV> is the default.

# INSERT_BLOCK_FROM_MODULE: End::Eval::FirstArg description

=head1 ENVIRONMENT

=head2 DEBUG

Bool. Can be turned on to print the code to STDOUT before eval-ing it.

=head2 PERL_BEGIN_EVAL_ENV

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Begin-Eval-Env>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Begin-Eval-Env>.

=head1 SEE ALSO

Other C<Begin::Eval::*> modules, like L<Begin::Eval::FirstArg>.

C<End::Eval::*> modules.

Other L<Begin::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Begin-Eval-Env>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
