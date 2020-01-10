package App::lcpan::CmdBundle::weaver;

our $DATE = '2019-11-20'; # DATE
our $VERSION = '0.030'; # VERSION

1;
# ABSTRACT: lcpan subcommands related to Pod::Weaver

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::weaver - lcpan subcommands related to Pod::Weaver

=head1 VERSION

This document describes version 0.030 of App::lcpan::CmdBundle::weaver (from Perl distribution App-lcpan-CmdBundle-weaver), released on 2019-11-20.

=head1 SYNOPSIS

Install this distribution, then the lcpan subcommands below will be available:

 # List sections available on CPAN
 % lcpan weaver-sections

 # List plugins available on CPAN
 % lcpan weaver-plugins

 # List bundles available on CPAN
 % lcpan weaver-bundles

 # List roles available on CPAN
 % lcpan weaver-roles


 # Find plugins most depended by other CPAN distributions
 % lcpan weaver-sections-by-rdep-count

 # Find plugins most depended by other CPAN distributions
 % lcpan weaver-plugins-by-rdep-count

 # Find bundles most depended by other CPAN distributions
 % lcpan weaver-bundles-by-rdep-count

 # Find roles most depended by other CPAN distributions
 % lcpan weaver-roles-by-rdep-count


 # Who release the largest number of sections
 % lcpan weaver-authors-by-section-count

 # Who release the largest number of plugins
 % lcpan weaver-authors-by-plugin-count

 # Who release the largest number of bundles
 % lcpan weaver-authors-by-bundle-count

 # Who release the largest number of roles
 % lcpan weaver-authors-by-role-count

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan weaver-roles|App::lcpan::Cmd::weaver_roles>

=item * L<lcpan weaver-bundles-by-rdep-count|App::lcpan::Cmd::weaver_bundles_by_rdep_count>

=item * L<lcpan weaver-sections-by-rdep-count|App::lcpan::Cmd::weaver_sections_by_rdep_count>

=item * L<lcpan weaver-authors-by-role-count|App::lcpan::Cmd::weaver_authors_by_role_count>

=item * L<lcpan weaver-plugins-by-rdep-count|App::lcpan::Cmd::weaver_plugins_by_rdep_count>

=item * L<lcpan weaver-section|App::lcpan::Cmd::weaver_section>

=item * L<lcpan weaver-plugin|App::lcpan::Cmd::weaver_plugin>

=item * L<lcpan weaver-authors-by-bundle-count|App::lcpan::Cmd::weaver_authors_by_bundle_count>

=item * L<lcpan weaver-bundles|App::lcpan::Cmd::weaver_bundles>

=item * L<lcpan weaver-bundle|App::lcpan::Cmd::weaver_bundle>

=item * L<lcpan weaver-authors-by-plugin-count|App::lcpan::Cmd::weaver_authors_by_plugin_count>

=item * L<lcpan weaver-role|App::lcpan::Cmd::weaver_role>

=item * L<lcpan weaver-authors-by-section-count|App::lcpan::Cmd::weaver_authors_by_section_count>

=item * L<lcpan weaver-plugins|App::lcpan::Cmd::weaver_plugins>

=item * L<lcpan weaver-sections|App::lcpan::Cmd::weaver_sections>

=item * L<lcpan weaver-roles-by-rdep-count|App::lcpan::Cmd::weaver_roles_by_rdep_count>

=back

This distribution packages several lcpan subcommands related to L<Pod::Weaver>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-weaver>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-weaver>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-weaver>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>

L<Pod::Weaver>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
