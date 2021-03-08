package App::lcpan::CmdBundle::depsort;

our $DATE = '2021-03-07'; # DATE
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: More lcpan subcommands related to sorting by dependencies

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::depsort - More lcpan subcommands related to sorting by dependencies

=head1 VERSION

This document describes version 0.002 of App::lcpan::CmdBundle::depsort (from Perl distribution App-lcpan-CmdBundle-depsort), released on 2021-03-07.

=head1 SYNOPSIS

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan depsort-dist|App::lcpan::Cmd::depsort_dist>

=item * L<lcpan depsort-rel|App::lcpan::Cmd::depsort_rel>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-depsort>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-depsort>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-depsort>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::lcpan::CmdBundle::deps>

L<Data::Graph::Util> and L<App::toposort>

L<lcpan>, particularly the C<deps> and C<rdeps> subcommands.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
