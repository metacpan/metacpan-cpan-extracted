package App::cpanm::script;

our $DATE = '2016-11-02'; # DATE
our $VERSION = '0.001'; # VERSION

1;

# ABSTRACT: Install modules from CPAN (via script name)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cpanm::script - Install modules from CPAN (via script name)

=head1 VERSION

This document describes version 0.001 of App::cpanm::script (from Perl distribution App-cpanm-script), released on 2016-11-02.

=head1 DESCRIPTION

L<cpanm-script> is a simplistic wrapper over L<cpanm>. This command:

 % cpanm-script -n csvutil

will cause B<cpanm-script> to search for the release tarball that contains the
script (currently via scraping C<https://metacpan.org/pod/SCRIPTNAME>) and will
then run:

 % cpanm -n PERLANCAR/App-CSVUtils-0.002.tar.gz

That's about it.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cpanm-script>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cpanm-script>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cpanm-script>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
