package App::CSV2Chart::Command::xlsx;
$App::CSV2Chart::Command::xlsx::VERSION = '0.12.0';
use strict;
use warnings;

use App::CSV2Chart -command;
use App::CSV2Chart::API::ToXLSX ();

sub description
{
    return "Generate .xlsx";
}

sub abstract
{
    return shift->description();
}

sub opt_spec
{
    return @{ App::CSV2Chart::API::ToXLSX::_to_xlsx_common_opt_spec() };
}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    my $fn  = $opt->{output};
    my $exe = $opt->{exec} // [];

    my $fh = \*STDIN;

    App::CSV2Chart::API::ToXLSX::csv_to_xlsx(
        {
            input_fh   => $fh,
            output_fn  => $fn,
            height     => $opt->{height},
            width      => $opt->{width},
            title      => $opt->{title},
            chart_type => $opt->{'chart_type'},
        }
    );
    if (@$exe)
    {
        system( @$exe, $fn );
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

csv2chart xlsx - generate an .xlsx file with an embedded chart from CSV data

=head1 VERSION

version 0.12.0

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-CSV2Chart>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSV2Chart>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-CSV2Chart>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-CSV2Chart>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-CSV2Chart>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::CSV2Chart>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-csv2chart at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-CSV2Chart>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/CSV2Chart>

  git clone https://github.com/shlomif/CSV2Chart.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/app-csv2chart/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
