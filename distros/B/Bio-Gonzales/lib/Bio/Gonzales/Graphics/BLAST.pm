package Bio::Gonzales::Graphics::BLAST;

use warnings;
use strict;
use Carp;

use 5.010;

use Log::Log4perl qw(:easy);
use Bio::Graphics;
use Bio::SearchIO;
use Bio::SeqFeature::Generic;
use Data::Dumper;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(render render_sep);

sub render {
    my ( $src, $options ) = @_;

    my %opts = ( blast_format => 'blast', img_format => 'png', %{ $options // {} } );

    my $fh;
    my $fh_was_open;
    if ( ref $src && ref $src ne 'SCALAR' ) {
        $fh          = $src;
        $fh_was_open = 1;
    } else {
        open $fh, '<', $src or confess "Can't open filehandle: $!";
    }

    my $searchio = Bio::SearchIO->new(
        -fh     => $fh,
        -format => $opts{format}
    ) or die "parse failed";

    my %panel_imgs;
    while ( my $result = $searchio->next_result() ) {

        my $panel = Bio::Graphics::Panel->new(
            -length    => $result->query_length,
            -width     => 800,
            -pad_left  => 10,
            -pad_right => 10,
        );

        my $full_length = Bio::SeqFeature::Generic->new(
            -start        => 1,
            -end          => $result->query_length,
            -display_name => $result->query_name,
        );
        $panel->add_track(
            $full_length,
            -glyph   => 'arrow',
            -tick    => 2,
            -fgcolor => 'black',
            -double  => 1,
            -label   => 1,
        );

        my $track = $panel->add_track(
            -glyph       => 'graded_segments',
            -label       => 1,
            -connector   => 'dashed',
            -bgcolor     => 'blue',
            -font2color  => 'red',
            -sort_order  => 'high_score',
            -description => sub {
                my $feature = shift;
                return unless $feature->has_tag('description');
                my ($description) = $feature->each_tag_value('description');
                my $score = $feature->score;
                "$description, score: $score";
            },
        );

        while ( my $hit = $result->next_hit ) {
            next
                unless ( !exists( $opts{evalue} )
                || ( exists( $opts{evalue} ) && $hit->significance < $opts{evalue} ) );
            my $feature = Bio::SeqFeature::Generic->new(
                -score        => $hit->raw_score,
                -display_name => $hit->name,
                -tag          => { description => sprintf( "len: %d", $hit->length ) },
            );
            while ( my $hsp = $hit->next_hsp ) {
                $feature->add_sub_SeqFeature( $hsp, 'EXPAND' );
            }

            $track->add_feature($feature);
        }

        my $img_result;
        if ( $opts{img_format} =~ /svg/i ) {
            $img_result = $panel->svg;
        } elsif ( $opts{img_format} =~ /png/i ) {
            $img_result = $panel->png;
        }

        $panel_imgs{ $result->query_name } = $img_result;
        $panel->finished;
    }
    $fh->close unless ($fh_was_open);

    return \%panel_imgs;
}

sub render_sep {
    my ( $src, $options ) = @_;

    my %opts = ( blast_format => 'blast', img_format => 'png', %{ $options // {} } );

    my $fh;
    my $fh_was_open;
    if ( ref $src && ref $src ne 'SCALAR' ) {
        $fh          = $src;
        $fh_was_open = 1;
    } else {
        open $fh, '<', $src or confess "Can't open filehandle: $!";
    }

    my $searchio = Bio::SearchIO->new(
        -fh     => $fh,
        -format => $opts{format}
    ) or die "parse failed";

    my %panel_imgs;
    while ( my $result = $searchio->next_result() ) {

        my $panel = Bio::Graphics::Panel->new(
            -length    => $result->query_length,
            -width     => 1200,
            -pad_left  => 30,
            -pad_right => 370,
        );

        my $full_length = Bio::SeqFeature::Generic->new(
            -start        => 1,
            -end          => $result->query_length,
            -display_name => $result->query_name,
        );
        $panel->add_track(
            $full_length,
            -glyph   => 'arrow',
            -tick    => 2,
            -fgcolor => 'black',
            -double  => 1,
            -label   => 1,
        );

        my $track_merged = $panel->add_track(
            -glyph       => 'segments',
            -label       => 1,
            -connector   => 'dashed',
            -bgcolor     => 'blue',
            -font2color  => 'red',
            -sort_order  => 'high_score',
            -description => sub {
                my $feature = shift;
                return "all hits merged" unless $feature->has_tag('description');
                my ($description) = $feature->each_tag_value('description');
                my $score = $feature->score;
                "$description, score: $score";
            },
        );

        my $track = $panel->add_track(
            -glyph       => 'segments',
            -label       => 1,
            -bgcolor     => 'blue',
            -font2color  => 'red',
            -description => sub {
                my $feature = shift;
                return unless $feature->has_tag('description');
                my ($description) = $feature->each_tag_value('description');
                my $score = $feature->score;
                "$description, score: $score";
            },
        );

        while ( my $hit = $result->next_hit ) {
            next
                unless ( !exists( $opts{evalue} )
                || ( exists( $opts{evalue} ) && $hit->significance < $opts{evalue} ) );

            my $feature_merged = Bio::SeqFeature::Generic->new(
                -score        => $hit->raw_score,
                -display_name => $hit->name,
                #-tag          => { description => $hit->description },
            );
            while ( my $hsp = $hit->next_hsp ) {

                #Bio::Search::HSP::GenericHSP
                #Bio::Search::HSP::HSPI
                my $qb = $hsp->start('query');
                my $qe = $hsp->end('query');

                my $sb = $hsp->start('subject');
                my $se = $hsp->end('subject');

                my $dist;
                if ( $qb > $se ) {
                    $dist = $qb - $se;
                } elsif ( $sb > $qe ) {
                    $dist = $sb - $qe;
                } else {
                    next;
                }

                $feature_merged->add_sub_SeqFeature( $hsp, 'EXPAND' );

                next if ( $dist < 30000 );

                my $feature = Bio::SeqFeature::Generic->new(
                    -score        => $hsp->bits,
                    -start        => $hsp->start,
                    -end          => $hsp->end,
                    -display_name => $hit->name,
                    -tag          => { description => "S: $sb - $se, Q: $qb - $qe" },
                );
                $track->add_feature($feature);
            }
            $track_merged->add_feature($feature_merged);

        }
        my $img_result;
        if ( $opts{img_format} =~ /svg/i ) {
            $img_result = $panel->svg;
        } elsif ( $opts{img_format} =~ /png/i ) {
            $img_result = $panel->png;
        }

        $panel_imgs{ $result->query_name } = $img_result;
        $panel->finished;
    }

    $fh->close unless ($fh_was_open);

    return \%panel_imgs;
}
1;

__END__

=head1 NAME

Bio::Gonzales::Graphics::BLAST - make your blast result nice

=head1 SYNOPSIS

    Bio::Gonzales::Graphics::BLAST qw(render);

=head1 DESCRIPTION

=head1 OPTIONS

=head1 SUBROUTINES

=over 4

=item B<< $raw_image_data = render($file, \%options) >>

=item B<< $raw_image_data = render($fh, \%options) >>

Reads C<$file> or uses C<$fh> to get the results. Renders the results either as png or as svg graphics.

    %standard_options = (
        blast_format => 'blast',
        img_format =>  'png',
        evalue => undef,
    );

=back


=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
