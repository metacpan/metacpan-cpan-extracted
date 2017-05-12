package App::SVG::Graph;

use strict;
use warnings;

use autodie;

use 5.008;

our $VERSION = '0.0.2';

use SVG::Graph::Kit;
use Getopt::Long qw( GetOptionsFromArray );
use Pod::Usage;

sub argv
{
    my $self = shift;

    if (@_)
    {
        $self->{argv} = shift;
    }

    return $self->{argv};
}

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ($self, $args) = @_;

    $self->argv($args->{argv});

    return;
}

sub _slurp_lines
{
    my $in = shift;

    my @ret = <$in>;
    chomp(@ret);

    return \@ret;
}

sub run
{
    my ($self) = @_;

    my $output_fn;
    my $man = 0;
    my $help = 0;
    my $version = 0;

    my @argv = @{$self->argv};

    GetOptionsFromArray(
        \@argv,
        "output|o" => \$output_fn,
        "help|h" => \$help,
        "man" => \$man,
        "version" => \$version,
    ) or pod2usage(2);

    if ($help)
    {
        pod2usage(1)
    }

    if ($man)
    {
        pod2usage(-verbose => 2);
    }

    if ($version)
    {
        print "svg-graph version $VERSION\n";
        exit(0);
    }

    my $in_fh;

    my $filename = shift(@argv);
    if (!defined($filename))
    {
        $in_fh = \*STDIN;
    }
    else
    {
        open $in_fh, '<', $filename;
    }

    my $out_fh;

    if (!defined($output_fn))
    {
        $out_fh = \*STDOUT;
    }
    else
    {
        open $out_fh, '>', $output_fn;
    }

    my $data = [map { [split/\t/, $_] } @{_slurp_lines($in_fh)}];

    my $g = SVG::Graph::Kit->new(data => $data);
    print {$out_fh} $g->draw;
    close ($out_fh);

    if (defined($filename))
    {
        close($in_fh);
    }

    return;
}

1;

__END__

=pod

=head1 NAME

App::SVG::Graph - generate SVG graphs from the command line.

=head1 VERSION

version 0.0.2

=head1 DESCRIPTION

This accepts tab-separated data (TSV) on STDIN and emits an SVG graph.

=head1 NOTE

Everything here is subject to change. The API is for internal use.

=head1 METHODS

=head2 my $app = App::SVG::Graph->new({argv => \@ARGV})

The constructor. Accepts the @ARGV array as a parameter and parses it.

=head2 $app->run()

Runs the application.

=head2 $app->argv()

B<For internal use.>

=head1 SEE ALSO

L<SVG::Graph::Kit> , L<SVG::Graph> .

L<https://github.com/FormidableLabs/victory-cli> is a similar tool for
Node.js/npm , but I had trouble installing it so I decided to create
L<svg-graph>. It may work well enough for you, though.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-SVG-Graph or by email to
bug-app-svg-graph@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::SVG::Graph

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/App-SVG-Graph>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-SVG-Graph>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SVG-Graph>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-SVG-Graph>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-SVG-Graph>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/App-SVG-Graph>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-SVG-Graph>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-SVG-Graph>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-SVG-Graph>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::SVG::Graph>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-svg-graph at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-SVG-Graph>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-App-SVG-Graph>

  git clone https://github.com/shlomif/perl-App-SVG-Graph.git

=cut
