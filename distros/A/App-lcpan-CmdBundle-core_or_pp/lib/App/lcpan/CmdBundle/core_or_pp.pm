package App::lcpan::CmdBundle::core_or_pp;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.03'; # VERSION

1;
# ABSTRACT: Check whether a module + its prereqs are core/PP

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::core_or_pp - Check whether a module + its prereqs are core/PP

=head1 VERSION

This document describes version 0.03 of App::lcpan::CmdBundle::core_or_pp (from Perl distribution App-lcpan-CmdBundle-core_or_pp), released on 2017-01-20.

=head1 SYNOPSIS

Install this distribution, then the lcpan subcommands below will be available:

 # Check that a module is core/PP (without checking its prereqs)
 % lcpan core-or-pp JSON::MaybeXS

 # Check that a module and its prereqs are all core/PP
 % lcpan core-or-pp --with-deps JSON::MaybeXS

 # Check that a module and its recursive prereqs are all core/PP
 % lcpan core-or-pp --with-recursive-deps JSON::MaybeXS

 # Check that a module and its prereqs are all core
 % lcpan core-or-pp --with-deps --core JSON::MaybeXS

 # Check that a module and its prereqs are all PP
 % lcpan core-or-pp --with-deps --pp JSON::MaybeXS

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan core-or-pp|App::lcpan::Cmd::core_or_pp>

=back

The subcommand C<core-or-pp> checks that a module with its (recursive) (runtime
requires) prereqs are all core/PP. Doing this check is useful when we want to
fatpack said module along with its prereqs.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-core_or_pp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-core_or_pp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-core_or_pp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
