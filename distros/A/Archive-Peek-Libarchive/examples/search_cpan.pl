#!perl
use strict;
use warnings;
use 5.12.0;
use Archive::Peek::Libarchive;
use Parse::CPAN::Packages;
use Path::Class;
use Term::ANSIColor;

my $CPAN   = shift || die "Must pass path to local CPAN mirror";
my $search = shift || die "Must pass regular expression to use";

my $packages
    = Parse::CPAN::Packages->new("$CPAN/modules/02packages.details.txt.gz");

my $lines;

my @distributions = $packages->latest_distributions;

@distributions = grep {
    !(     $_->prefix =~ m{/(?:emb|syb|bio)?perl-\d}i
        || $_->prefix =~ m{/(?:parrot|ponie)-\d}i
        || $_->prefix =~ m{/(?:kurila)-\d}i
        || $_->prefix =~ m{/\bperl-?5\.004}i
        || $_->prefix =~ m{/\bperl_mlb\.zip}i )
} @distributions;

foreach my $distribution ( sort { $a->distvname cmp $b->distvname }
    @distributions )
{

    #$progress->message( $distribution->distvname );
    my $archive = file( $CPAN, 'authors', 'id', $distribution->prefix );

    eval {
        my $peek = Archive::Peek::Libarchive->new( filename => $archive );
        $peek->iterate(
            sub {
                my ( $filename, $contents ) = @_;
                return unless $filename =~ /\.(pl|pm)$/;
                my $key = $archive . ':' . $filename;
                while ( $contents =~ /$search/g ) {
                    my $pos = pos($contents);

                    my $previous = rindex( $contents, "\n", $-[0] );
                    $previous = 1 + rindex( $contents, "\n", $previous - 1 )
                        if $previous > 0;
                    my $next = index( $contents, "\n", $+[0] );
                    $next = index( $contents, "\n", 1 + $next ) if $next > 0;

              # Limit length of snippet, 200 bytes should be enough for anyone
                    if ( $next > $previous + 200 ) {
                        $previous
                            = $previous < $-[0] - 100
                            ? $-[0] - 100
                            : $previous;
                        $next = $next > $+[0] + 100 ? $+[0] + 100 : $next;
                    }

                    my $snippet
                        = substr( $contents, $previous, $next - $previous );
                    $snippet
                        =~ s{$search}{color('black on_yellow') . $& . color('reset')}eg;
                    say '' if $lines++;
                    say color('bold green'), $key, color('reset');
                    say "$snippet";
                }
            }
        );
    };
}

