package App::lcpan::CmdBundle::cpanlists;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.01'; # VERSION

1;
# ABSTRACT: lcpan subcommands related to Acme::CPANLists

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::cpanlists - lcpan subcommands related to Acme::CPANLists

=head1 VERSION

This document describes version 0.01 of App::lcpan::CmdBundle::cpanlists (from Perl distribution App-lcpan-CmdBundle-cpanlists), released on 2017-01-20.

=head1 SYNOPSIS

Install this distribution, then the lcpan subcommands below will be available:

 # List Acme::CPANLists modules available on CPAN
 % lcpan cpanlists-mods

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan cpanlists-mods|App::lcpan::Cmd::cpanlists_mods>

=back

This distribution packages several lcpan subcommands related to
L<Acme::CPANLists>. More subcommands will be added in future releases.

Some ideas:

B<cpanlists-stats>. Number of modules. But we will want to also know the number
of lists, total number of entries, average number of entries per list, average
number of lists per modules.

Perhaps an indexing hook could be added, so that lcpan indexes the lists
themselves? To be safer, an Acme::CPANLists module could export the lists to a
JSON, so lcpan does not have to load the module.

The indexing part could be modularized, so we can have a SQLite database
containing list information without having to have lcpan, because lcpan database
is huge.

Or (easier)... lcpan could just call this indexer. The cpanlists indexer indexes
to a separate SQLite database. But note that the cpanlists indexer *will*
eval/load the modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-cpanlists>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-cpanlists>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-cpanlists>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>

L<Acme::CPANLists> and L<acme-cpanlists>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
