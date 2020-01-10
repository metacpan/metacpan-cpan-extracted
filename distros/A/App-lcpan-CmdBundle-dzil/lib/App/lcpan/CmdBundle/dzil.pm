package App::lcpan::CmdBundle::dzil;

our $DATE = '2019-11-20'; # DATE
our $VERSION = '0.060'; # VERSION

1;
# ABSTRACT: lcpan subcommands related to Dist::Zilla

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::dzil - lcpan subcommands related to Dist::Zilla

=head1 VERSION

This document describes version 0.060 of App::lcpan::CmdBundle::dzil (from Perl distribution App-lcpan-CmdBundle-dzil), released on 2019-11-20.

=head1 SYNOPSIS

Install this distribution, then the lcpan subcommands below will be available:

 # List plugins available on CPAN
 % lcpan dzil-plugins

 # List bundles available on CPAN
 % lcpan dzil-bundles

 # List roles available on CPAN
 % lcpan dzil-roles


 # Find plugins most depended by other CPAN distributions
 % lcpan dzil-plugins-by-rdep-count

 # Find bundles most depended by other CPAN distributions
 % lcpan dzil-bundles-by-rdep-count

 # Find roles most depended by other CPAN distributions
 % lcpan dzil-roles-by-rdep-count


 # Who release the largest number of plugins
 % lcpan dzil-authors-by-plugin-count

 # Who release the largest number of bundles
 % lcpan dzil-authors-by-bundle-count

 # Who release the largest number of roles
 % lcpan dzil-authors-by-role-count

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan dzil-role|App::lcpan::Cmd::dzil_role>

=item * L<lcpan dzil-authors-by-bundle-count|App::lcpan::Cmd::dzil_authors_by_bundle_count>

=item * L<lcpan dzil-plugin|App::lcpan::Cmd::dzil_plugin>

=item * L<lcpan dzil-authors-by-role-count|App::lcpan::Cmd::dzil_authors_by_role_count>

=item * L<lcpan dzil-bundle|App::lcpan::Cmd::dzil_bundle>

=item * L<lcpan dzil-roles-by-rdep-count|App::lcpan::Cmd::dzil_roles_by_rdep_count>

=item * L<lcpan dzil-bundles|App::lcpan::Cmd::dzil_bundles>

=item * L<lcpan dzil-plugins|App::lcpan::Cmd::dzil_plugins>

=item * L<lcpan dzil-bundles-by-rdep-count|App::lcpan::Cmd::dzil_bundles_by_rdep_count>

=item * L<lcpan dzil-plugins-by-rdep-count|App::lcpan::Cmd::dzil_plugins_by_rdep_count>

=item * L<lcpan dzil-authors-by-plugin-count|App::lcpan::Cmd::dzil_authors_by_plugin_count>

=item * L<lcpan dzil-roles|App::lcpan::Cmd::dzil_roles>

=back

This distribution packages several lcpan subcommands related to L<Dist::Zilla>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-dzil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-dzil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-dzil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>

L<Dist::Zilla>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
