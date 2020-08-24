package App::UpfUtils;

our $DATE = '2020-04-29'; # DATE
our $VERSION = '0.060'; # VERSION

use 5.010001;

1;
# ABSTRACT: CLI interface for Unix::Passwd::File (as separate scripts)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::UpfUtils - CLI interface for Unix::Passwd::File (as separate scripts)

=head1 VERSION

This document describes version 0.060 of App::UpfUtils (from Perl distribution App-UpfUtils), released on 2020-04-29.

=head1 SYNOPSIS

See the included C<upf-*> scripts.

=head1 DESCRIPTION

This distribution includes CLI scripts C<upf-*>, one for each corresponding
function in L<Unix::Passwd::File>:

=over

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-UpfUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-UpfUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-UpfUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Unix::Passwd::File>

L<App::upf>, which includes a single CLI script L<upf> containing subcommands,
instead of one script for each function like included in this distribution.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
