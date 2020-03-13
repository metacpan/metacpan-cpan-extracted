package App::prefixintsumcol;
$App::prefixintsumcol::VERSION = '0.0.1';
use strict;
use warnings;

use Math::GMP ();

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ( $self, $args ) = @_;

    return;
}

sub run
{
    my $s = Math::GMP->new('0');

    while ( my $l = <ARGV> )
    {
        chomp $l;
        if ( my ($diff) = ( $l =~ m#\A([0-9]+)(?:\s|\Z)# ) )
        {
            printf( "%s\t%s\n", ( $s += Math::GMP->new($diff) ), $l );
        }
        else
        {
            die "Line '$l' at $. does not start with an integer number.";
        }
    }

    return;
}

1;

__END__

=pod

=head1 NAME

App::prefixintsumcol - prefix the running sum of decimal big integers from stdin or files

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    $ (echo 2 ; echo 3) | prefixintsumcol
    2 2
    5 3

=head1 DESCRIPTION

Performs an arithmetic sum of decimal integers in the files given as command
line arguments and STDIN, and displays the intermediate results at the beggining of each line.

=head1 VERSION

=head1 METHODS

=head2 new

Constructor - for internal use.

=head2 run

Run the app - for internal use.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/app-prefixintsumcol/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-prefixintsumcol>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-prefixintsumcol>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-prefixintsumcol>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-prefixintsumcol>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-prefixintsumcol>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::prefixintsumcol>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-prefixintsumcol at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-prefixintsumcol>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/App-intsum>

  git clone https://github.com/shlomif/App-intsum.git

=cut
