package App::rshasum;
$App::rshasum::VERSION = '0.10.0';
use 5.016;
use strict;
use warnings;

use File::Find::Object ();
use Digest             ();

use Getopt::Long qw/ GetOptions /;
use List::Util 1.33 qw/ any /;

sub _line
{
    my ( $d, $path ) = @_;

    return $d->hexdigest . '  ' . $path . "\n";
}

sub _worker
{
    my ( $self, $args ) = @_;

    my $digest     = $args->{digest};
    my $output_cb  = $args->{output_cb};
    my @prunes     = ( map { qr/$_/ } @{ $args->{prune_re} || [] } );
    my $start_path = ( $args->{start_path} // "." );

    my $t = Digest->new($digest);

    my $ff = File::Find::Object->new( {}, $start_path );
FILES:
    while ( my $r = $ff->next_obj )
    {
        my $path = join '/', @{ $r->full_components };
        if (@prunes)
        {
            if ( any { $path =~ $_ } @prunes )
            {
                $ff->prune;
                next FILES;
            }
        }
        if ( $r->is_file )
        {
            my $fh;
            if ( not( open $fh, '<', $r->path ) )
            {
                warn "Could not open @{[$r->path]} ; skipping";
                next FILES;
            }
            binmode $fh;
            my $d = Digest->new($digest);
            $d->addfile($fh);
            close $fh;
            my $s = _line( $d, $path, );
            $output_cb->( { str => $s } );
            $t->add($s);
        }
    }
    my $s = _line( $t, '-', );
    $output_cb->( { str => $s } );

    return;
}

sub run
{
    my $digest;
    my @skips;
    my $start_path = '.';
    GetOptions(
        'digest=s'     => \$digest,
        'skip=s'       => \@skips,
        'start-path=s' => \$start_path,
    ) or die "Unknown flags $!";
    if ( not defined($digest) )
    {
        die "Please give a --digest=[digest] argument.";
    }
    if (@ARGV)
    {
        die
qq#Leftover arguments "@ARGV" in the command line. (Did you intend to use --start-path ?)#;
    }
    return shift()->_worker(
        {
            digest     => $digest,
            output_cb  => sub { print shift()->{str}; },
            prune_re   => ( \@skips ),
            start_path => $start_path,
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::rshasum - recursive shasum.

=head1 VERSION

version 0.10.0

=head1 SYNOPSIS

    rshasum --digest=SHA-256
    rshasum --digest=SHA-256 --skip='\.sw[a-zA-Z]*\z' --skip='~\z'
    rshasum --digest=SHA-256 --start-path='/home/random-j-user'

=head1 DESCRIPTION

A recursive digest calculator that prints digests for all files
in a directory tree, as well as a total, summary, digest of the output.

=head1 FLAGS

=head2 --digest

The digest algorithm to use. Required. E.g:

    --digest=SHA-256
    --digest=SHA-512
    --digest=MD5

=head2 --skip

Perl 5 regexes which when matched against the relative paths,
skip and prune them.

Can be specified more than one time.

=head2 --start-path

The start path for the traversal. Defaults to "." (the
current working directory).

=head1 METHODS

=head2 run

Runs the app.

=head1 DEMO

    ~/progs/rshasum/App-rshasum/ rshasum --digest=MD5 --start .
    0556790e903a2fc303667096f90c6315  .tidyallrc
    931a4f3fc883b18717e6ef03dee71d74  Changes
    87181bcf0b5931d00583c4fa551a44d7  MANIFEST.SKIP
    033802795280cbc3651ee7fca1ee1609  bin/rshasum
    b1bf159fafba49e433c9daa6527889cf  dist.ini
    7ec9c5217c0c0883c8d35718840e5ee1  inc/Test/Run/Builder.pm
    ef6115acd4410c0a31f7cbf170b368d3  lib/App/rshasum.pm
    ab9cbcab840eda9a13d6b0c9234cb9b0  t/argv.t
    6f8db599de986fab7a21625b7916589c  t/data/1/0.txt
    2dae34ccf201ecf9a998b6cbac7d0170  t/data/1/2.txt
    d41d8cd98f00b204e9800998ecf8427e  t/data/1/foo/empty
    d41d8cd98f00b204e9800998ecf8427e  t/data/1/zempty
    0b79ca3f5ce0d456e864f0734edb9f93  t/run.t
    5463d4de034510c60218c60e48096797  weaver.ini
    b1e9362662fc9aea954284e694213352  -

( B<WARNING:> do not use MD5 in production. )

=head1 SEE ALSO

L<https://github.com/rhash/RHash> - "recursive hash". Seems to emit the
tree in an unpredictable, not-always-sorted, order.

L<https://www.shlomifish.org/open-source/projects/File-Dir-Dumper/> - also
on CPAN. Dumps metadata and supports caching the digests.

L<https://github.com/gokyle/rshasum> - written in golang, but slurps
entire files into memory (see L<https://github.com/gokyle/rshasum/issues/1> ).

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-rshasum>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-rshasum>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-rshasum>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-rshasum>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-rshasum>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::rshasum>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-rshasum at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-rshasum>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/rshasum>

  git clone https://github.com/shlomif/rshasum.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/rshasum/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
