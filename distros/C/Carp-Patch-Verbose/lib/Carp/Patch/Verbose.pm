package Carp::Patch::Verbose;

use 5.010001;
use strict;
no warnings;

use Module::Patch qw();
use base qw(Module::Patch);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-21'; # DATE
our $DIST = 'Carp-Patch-Verbose'; # DIST
our $VERSION = '0.001'; # VERSION

my $old_MaxArgLen;
my $old_MaxArgNums;
our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
        ],
        config => {
        },
        after_patch => sub {
            my $old_MaxArgLen  = $Carp::MaxArgLen ; $Carp::MaxArgLen  = 999_999;
            my $old_MaxArgNums = $Carp::MaxArgNums; $Carp::MaxArgNums = 0;
        },
        after_unpatch => sub {
            $Carp::MaxArgLen  = $old_MaxArgLen  if defined $old_MaxArgLen ; undef $old_MaxArgLen;
            $Carp::MaxArgNums = $old_MaxArgNums if defined $old_MaxArgNums; undef $old_MaxArgNums;
        },
   };
}

1;
# ABSTRACT: Set some Carp variables so stack trace is more verbose

__END__

=pod

=encoding UTF-8

=head1 NAME

Carp::Patch::Verbose - Set some Carp variables so stack trace is more verbose

=head1 VERSION

This document describes version 0.001 of Carp::Patch::Verbose (from Perl distribution Carp-Patch-Verbose), released on 2022-01-21.

=head1 SYNOPSIS

 % perl -MCarp::Patch::Verbose -d:Confess ...

=head1 DESCRIPTION

This is not so much a "patch" for L<Carp>, but just a convenient way to set some
Carp package variables from the command-line. Currently can set these variables:

 $Carp::MaxArgLen  # from the default 64 to 0 (print all)
 $Carp::MaxArgNums # from the default  8 to 0 (print all)

=head1 PATCH CONTENTS

=over

=back

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Carp-Patch-Verbose>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Carp-Patch-Verbose>.

=head1 SEE ALSO

L<Module::Patch>

L<Carp>

L<Carp::Patch::Config>

L<Devel::Confess>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Patch-Verbose>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
