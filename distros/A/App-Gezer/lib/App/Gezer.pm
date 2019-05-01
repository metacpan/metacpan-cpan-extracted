package App::Gezer;
$App::Gezer::VERSION = '0.0.3';
# ABSTRACT: HTML Postprocessor and frontend to html-minifier

use strict;
use warnings;
use 5.014;

use Carp::Always;
use Moo;
use Getopt::Long qw/ GetOptionsFromArray /;

use CHI ();
use Data::Munge qw/ list2re /;
use File::Update qw/ modify_on_change write_on_change /;
use Path::Tiny qw/ path /;

has '_minifier_conf_fn' => ( is => 'rw', );
has [ '_temp_dir', '_proc_dir' ] => ( is => 'rw', );

my $XMLNS_NEEDLE = <<'EOF';
 xmlns:db="http://docbook.org/ns/docbook" xmlns:d="http://docbook.org/ns/docbook" xmlns:vrd="http://www.shlomifish.org/open-source/projects/XML-Grammar/Vered/" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xhtml="http://www.w3.org/1999/xhtml"
EOF

my @NEEDLES = $XMLNS_NEEDLE =~ m#\b(xmlns:[a-zA-Z_]+="[^"]+")#g;

my $ALTERNATIVES_TEXT = list2re @NEEDLES;

sub _summary
{
    my $text_ref = shift;
    if ( index( $$text_ref, q#<!DOCTYPE html># ) >= 0 )
    {
        return $$text_ref =~
            s%(<table(?:\s+(?:class|style)="[^"]*"\s*)*) summary=""%$1%g;
    }
    else
    {
        my $r1 = $$text_ref =~
s%(<main(?:\s+(?:class|id|style)="[^"]*"\s*)*>)%my $s = $1; $s=~s/main/div/;$s=~s/(\sclass=")/${1}main /;$s%egms;
        my $r2 = $$text_ref =~ s%</main>%</div>%g;
        return $r1 || $r2;
    }
}

sub _call_minifier
{
    my ( $self, $filenames, $ad_filenames ) = @_;
    my $KEY   = 'HTML_POST_INCS_DATA_DIR';
    my $cache = CHI->new(
        driver   => 'File',
        root_dir => (
            $ENV{$KEY}
                || (
                ( $ENV{TMPDIR} || '/tmp' ) . '/html-post-proc-gezer-cache' )
        )
    );

    my @queue;
    my $_proc_dir = Path::Tiny->tempdir;
    $self->_proc_dir($_proc_dir);
    my $temp_dir = $self->_temp_dir;
    foreach my $rec ( @$filenames, @$ad_filenames )
    {
        my $temp_bn = $rec->{temp_bn};
        my $src     = $temp_dir->child($temp_bn);
        my $k       = $src->slurp;
        my $e       = $cache->get($k);
        if ( defined $e )
        {
            $_proc_dir->child($temp_bn)->spew($e);
            $src->remove;
        }
        else
        {
            push @queue, [ $k, $temp_bn ];
        }
    }
    if (@queue)
    {
        system(
            'html-minifier', '-c', $self->_minifier_conf_fn, '--input-dir',
            $temp_dir . '',
            '--output-dir', $_proc_dir . '',
        ) and die "html-min $!";
        foreach my $fn (@queue)
        {
            $cache->set( $fn->[0],
                scalar( $_proc_dir->child( $fn->[1] )->slurp ),
                '100000 days' );
        }
    }
    return;
}

sub run
{
    my ( $self, $args ) = @_;

    my @filenames;
    my @ad_filenames;
    my @raw_filenames;
    my $argv = $args->{ARGV};
    my $source_dir;
    my $dest_dir;
    my $mode;
    my $conf;
    my $texts_dir;
    GetOptionsFromArray(
        $argv,
        'mode=s'          => \$mode,
        'source-dir=s'    => \$source_dir,
        'dest-dir=s'      => \$dest_dir,
        'texts-dir=s'     => \$texts_dir,
        'minifier-conf=s' => \$conf,
    ) or die "$!";

    if ( $mode ne 'minify' )
    {
        die qq#--mode should be "minify"!#;
    }
    $self->_minifier_conf_fn($conf);
    my $temp_dir = Path::Tiny->tempdir;
    $self->_temp_dir($temp_dir);
    my $counter = 0;

    my $APPLY_TEXTS = $ENV{APPLY_TEXTS};
    my $INCS        = !$ENV{NO_I};
    my $ALWAYS_MIN  = $ENV{ALWAYS_MIN};

    foreach my $bn (@$argv)
    {
        my $_f = sub {
            return path("$source_dir/$bn");
        };

        eval {
            PROCESS_FILE:
            {
                my $orig_text = $_f->()->slurp_utf8;
                my $text      = $orig_text;

                if ($INCS)
                {
                    $text =~
s#^\({5}include[= ](['"])([^'"]+)\1\){5}\n#path("lib/$2")->slurp_utf8#egms;
                    $text =~
s#\({5}chomp_inc[= ](['"])([^'"]+)\1\){5}#my ($l) = path("lib/$2")->lines_utf8({count => 1});chomp$l;$l#egms;
                }

                $text =~ s# +$##gms;
                $text =~ s#</(?:div|li|html)>\n\K\n##g;

                # $text =~ s#\s+xml:space="[^"]*"##g;
                $text =~ s#(<div)(?:\s+(?:$ALTERNATIVES_TEXT))+#$1 #gms;


                my $temp_bn = ( ++$counter ) . ".html";
                my $temp_fh = $temp_dir->child($temp_bn);
                $temp_fh->spew_utf8($text);
                my $rec = +{
                    bn      => $bn,
                    temp_bn => $temp_bn,
                };
                if ( $ALWAYS_MIN // ( $text ne $orig_text ) )
                {
                    push @filenames, $rec;
                }
                elsif ($APPLY_TEXTS)
                {
                    push @ad_filenames, $rec;
                }
                else
                {
                    push @raw_filenames, $rec;
                }
            }
        };
        if ( my $err = $@ )
        {
            # In case there's an error - fail and need to rebuild.
            $_f->()->remove();
            die $err;
        }
    }

    $self->_call_minifier( \@filenames, \@ad_filenames );

    my $_proc_dir = $self->_proc_dir;
    if ($APPLY_TEXTS)
    {
        my %TEXTS =
            ( map { $_ => path("$texts_dir/texts/$_")->slurp_utf8 }
                path("$texts_dir/texts-lists.txt")->lines_utf8( { chomp => 1 } )
            );

        my $cb = %TEXTS
            ? sub {
            my $text_ref = shift;
            my $r1 =
                ( $$text_ref =~
                    s%<div id="([^"]+)">Placeholder</div>%"\n" . $TEXTS{$1}%egms
                );
            my $r2 = _summary($text_ref);
            return ( $r1 || $r2 );
            }
            : \&_summary;

        foreach my $rec ( @filenames, @ad_filenames )
        {
            modify_on_change( scalar( $_proc_dir->child( $rec->{temp_bn} ) ),
                $cb );
        }
    }
    foreach my $rec (@raw_filenames)
    {
        my $temp_bn = $rec->{temp_bn};
        $_proc_dir->child($temp_bn)
            ->spew_raw( $temp_dir->child($temp_bn)->slurp_raw );
    }
    foreach my $rec ( @filenames, @ad_filenames, @raw_filenames )
    {
        my $d = path("$dest_dir/$rec->{bn}");
        $d->parent->mkpath;
        write_on_change( $d,
            \( $_proc_dir->child( $rec->{temp_bn} )->slurp_utf8 ) );
    }
    $self->_temp_dir(undef);
    $self->_proc_dir(undef);
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Gezer - HTML Postprocessor and frontend to html-minifier

=head1 VERSION

version 0.0.3

=begin removed

                # Remove surrounding space of tags.
                $text =~
s#\s*(</?(?:body|(?:br /)|div|head|li|ol|p|title|ul)>)\s*#$1#gms;

                # Remove document trailing space.
                $text =~ s#\s+\z##ms;

=end removed

=head1 NAME

App::Gezer - HTML Postprocessor and frontend to html-minifier .

=head1 VERSION

version 0.0.3

=head1 METHODS

=head2 $app->run({ ARGV => [@ARGV]})

Run the app using the @ARGV array as command line args.

=head1 About the name

Gezer is the Hebrew word for "a carrot" (see
L<https://he.wikipedia.org/wiki/%D7%92%D7%96%D7%A8> ) and it is also
the name of L<an archaeological site|https://en.wikipedia.org/wiki/Gezer>.
I happened to eat a carrot when looking for a name for this app.

=head1 COPYRIGHT & LICENSE

Copyright 2018 by Shlomi Fish

This program is distributed under the MIT / Expat License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-Gezer>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-Gezer>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Gezer>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-Gezer>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-Gezer>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Gezer>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Gezer>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Gezer>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Gezer>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-gezer at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-Gezer>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-App-Gezer>

  git clone https://github.com/shlomif/perl-App-Gezer.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/app-gezer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
