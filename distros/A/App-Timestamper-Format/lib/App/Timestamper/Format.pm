package App::Timestamper::Format;
$App::Timestamper::Format::VERSION = '0.0.2';
use 5.014;
use strict;
use warnings;

use IO::Handle;
use Getopt::Long 2.36 qw(GetOptionsFromArray);
use Pod::Usage qw/pod2usage/;

use App::Timestamper::Format::Filter::TS;

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

    my $argv = [@{$args->{argv}}];

    my $help = 0;
    my $man = 0;
    my $version = 0;
    if (! (my $ret = GetOptionsFromArray(
        $argv,
        'help|h' => \$help,
        man => \$man,
        version => \$version,
    )))
    {
        die "GetOptions failed!";
    }

    if ($help)
    {
        pod2usage(1);
    }

    if ($man)
    {
        pod2usage(-verbose => 2);
    }

    if ($version)
    {
        print "timestamper version $App::Timestamper::VERSION .\n";
        exit(0);
    }

    $self->{_argv} = $argv;
}

sub run
{
    my ($self) = @_;

    local @ARGV = @{$self->{_argv}};
    STDOUT->autoflush(1);

    App::Timestamper::Format::Filter::TS->new->fh_filter(\*ARGV, sub {print $_[0];});

    return;
}

1;

__END__

=pod

=head1 NAME

App::Timestamper::Format - prefix lines with formatted timestamps of their arrivals.

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use App::Timestamper::Format;

    App::Timestamper::Format->new({ argv => [@ARGV] })->run();

=head1 DESCRIPTION

App::Timestamper is a pure-Perl command line program that filters the input
so the formatted timestamps based on the C<TIMESTAMPER_FORMAT> env var are
prefixed to the lines based on the time of the arrival.

So if the input was something like:

    First Line
    Second Line
    Third Line

It will become something like:

    11:12:00\tFirst Line
    11:12:02\tSecond Line
    11:12:04\tThird Line

=encoding utf-8

=head1 VERSION

version 0.0.2

=head1 SUBROUTINES/METHODS

=head2 new

A constructor. Accepts the argv named arguments.

=head2 run

Runs the program.

=head1 SEE ALSO

L<App::Timestamper> .

=head2 “ts” from “moreutils”

“ts” is a program that is reportedely similar to “timestamper” and
is contained in joeyh’s “moreutils” (see L<http://joeyh.name/code/moreutils/>)
package. It is not easy to find online.

=head2 Chumbawamba’s song “Tubthumping”

I really like the song “Tubthumping” by Chumbawamba, which was a hit during
the 1990s and whose title sounds similar to “Timestamping”, so please check it
out:

=over 4

=item * English Wikipedia Page

L<http://en.wikipedia.org/wiki/Tubthumping>

=item * YouTube Search for the Video

L<http://www.youtube.com/results?search_query=chumbawamba%20tubthumping>

=back

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/app-timestamper-format/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::Timestamper::Format

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-Timestamper-Format>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-Timestamper-Format>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Timestamper-Format>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-Timestamper-Format>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-Timestamper-Format>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Timestamper-Format>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Timestamper-Format>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Timestamper-Format>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Timestamper::Format>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-timestamper-format at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-Timestamper-Format>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/App-Timestamper-Format>

  git clone https://github.com/shlomif/App-Timestamper-Format.git

=cut
