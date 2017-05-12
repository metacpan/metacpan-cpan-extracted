package # hide from PAUSE
App::YTDL::SelectQuality;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( set_preferred_qualities fmt_quality );

use List::MoreUtils qw( none );
use Term::Choose    qw( choose );

use App::YTDL::Helper qw( read_json write_json );



sub set_preferred_qualities {
    my ( $opt, $info, $ex, $video_id ) = @_;
    my $fmt_to_info = $info->{$ex}{$video_id}{fmt_to_info};
    my ( @qualities, @format_ids );
    if ( $ex eq 'youtube' ) {
        for my $fmt ( sort { $a <=> $b } keys %$fmt_to_info ) {
            if ( $fmt_to_info->{$fmt}{format} =~ /^\Q$fmt\E\s*-\s*(.+)\z/ ) {
                push @qualities, sprintf '%3s - %s %s', $fmt, $1, $fmt_to_info->{$fmt}{ext};
            }
            else {
                push @qualities, $fmt_to_info->{$fmt}{format} . ' ' . $fmt_to_info->{$fmt}{ext};
            }
            push @format_ids, $fmt;
        }
    }
    else {
        for my $fmt ( sort { $a cmp $b } keys %$fmt_to_info ) {
            push @qualities, $fmt_to_info->{$fmt}{format} . ' ' . $fmt_to_info->{$fmt}{ext};
            push @format_ids, $fmt;
        }
    }
    my $pref_qual = read_json( $opt, $opt->{preferred_file} ) // {};

    CHOICE: while ( 1 ) {
        my @pre = ( undef );
        my @choices = map {
            sprintf '%d. choice: %s', $_, join ', ', map( $_ // '', @{$pref_qual->{$ex}[$_-1]} )
        } 1 .. $opt->{pref_qual_slots};
        my $idx_choice = choose(
            [ @pre, @choices ],
            { prompt => "Set preferred qualities ($ex):", layout => 3, index => 1, undef => '<<' }
        );
        if ( ! $idx_choice ) {
            write_json( $opt, $opt->{preferred_file}, $pref_qual );
            return;
        }
        $idx_choice -= @pre;
        @pre = ( undef, 'RESET' );
        my $prompt = "Set preferred qualities ($ex):\n$choices[$idx_choice]";
        # Choose
        my @idx = choose(
            [ @pre, @qualities ],
            { prompt => $prompt, index => 1, order => 1, undef => '<<', no_spacebar => [ 0 .. $#pre ] }
        );
        if ( ! $idx[0] ) {
            next CHOICE;
        }
        elsif ( $idx[0] == 1 ) {
            $pref_qual->{$ex}[$idx_choice] = [];
            next CHOICE;
        }
        else {
            my @fmt_res_idx = map { $_ - @pre } @idx;
            my $fmt_list = [ @format_ids[@fmt_res_idx] ];
            $pref_qual->{$ex}[$idx_choice] = $fmt_list;
            next CHOICE;
        }
    }
}


sub fmt_quality {
    my ( $opt, $info, $fmt_list, $ex, $video_id ) = @_;
    my $auto_quality = $opt->{auto_quality};
    my $fmt_ok = 0;
    if ( $auto_quality eq 'keep_uploader_playlist' && $info->{$ex}{$video_id}{from_list} ) {
        my $list_id = $info->{$ex}{$video_id}{playlist_id};
        if ( ! length $list_id ) {
            $list_id = $info->{$ex}{$video_id}{uploader_id};
        }
        if ( length $list_id ) {
            if ( ! defined $opt->{$list_id} ) {
                $fmt_list = _choose_fmt( $opt, $info, $ex, $video_id );
                return if ! defined $fmt_list;
                $opt->{$list_id} = $fmt_list;
            }
            else {
                $fmt_list = $opt->{$list_id};
            }
            $fmt_ok = 1;
        }
    }
    elsif ( $auto_quality eq 'keep_extractor' ) {
        if ( ! defined $opt->{$ex} ) {
            $fmt_list = _choose_fmt( $opt, $info, $ex, $video_id );
            return if ! defined $fmt_list;
            $opt->{$ex} = $fmt_list;
        }
        else {
            $fmt_list = $opt->{$ex};
        }
        $fmt_ok = 1;

    }
    elsif ( $auto_quality eq 'preferred' ) {
        my $pref_qual = read_json( $opt, $opt->{preferred_file} ) // {};
        my @pref_qualities = @{$pref_qual->{$ex}//[]};
        PQ: for my $slot ( @pref_qualities ) {
            for my $fmt ( @$slot ) {
                $fmt_ok = 1;
                if ( none { $fmt eq $_ } keys %{$info->{$ex}{$video_id}{fmt_to_info}} ) {
                    $fmt_ok = 0;
                    next PQ;
                }
            }
            $fmt_list = $slot;
            last PQ;
        }
        if ( ! $fmt_ok ) {
            $fmt_list = [];
            print "\n";
            $opt->{up}++;
            printf "video_id %s - %s\n", $video_id, ! @pref_qualities
                ? 'no preferred qualities found!'
                : 'no matches between preferred fmts and available fmts!';
            $opt->{up}++;
        }
    }
    elsif ( $auto_quality eq 'default' && defined $info->{$ex}{$video_id}{format_id} ) {
        $fmt_list = [ split /\s*\+\s*/, $info->{$ex}{$video_id}{format_id} ];
        $fmt_ok = 1;
    }
    for my $fmt ( @$fmt_list ) {
        if ( none { $fmt eq $_ } keys %{$info->{$ex}{$video_id}{fmt_to_info}} ) {
            $fmt_ok = 0;
            last;
        }
    }
    if ( ! $fmt_ok ) {
        $fmt_list = _choose_fmt( $opt, $info, $ex, $video_id );
        return if ! defined $fmt_list;
    }
    return $fmt_list;
}


sub _choose_fmt {
    my ( $opt, $info, $ex, $video_id ) = @_;
    my $fmt_to_info = $info->{$ex}{$video_id}{fmt_to_info};
    my ( @choices, @format_ids );
    if ( $ex eq 'youtube' ) {
        for my $fmt ( sort { $a <=> $b } keys %$fmt_to_info ) {
            if ( $fmt_to_info->{$fmt}{format} =~ /^\Q$fmt\E\s*-\s*(.+)\z/ ) {
                push @choices, sprintf '%3s - %s %s', $fmt, $1, $fmt_to_info->{$fmt}{ext};
            }
            else {
                push @choices, $fmt_to_info->{$fmt}{format} . ' ' . $fmt_to_info->{$fmt}{ext};
            }
            push @format_ids, $fmt;
        }
    }
    else {
        for my $fmt ( sort { $a cmp $b } keys %$fmt_to_info ) {
            push @choices, $fmt_to_info->{$fmt}{format} . ' ' . $fmt_to_info->{$fmt}{ext};
            push @format_ids, $fmt;
        }
    }
    my @pre = ( undef );
    print "\n";
    $opt->{up}++;
    # Choose
    my @idx = choose(
        [ @pre, @choices ],
        { prompt => 'Your choice: ', index => 1, order => 1, undef => 'Menu', no_spacebar => [ 0 .. $#pre ] }
    );
    return if ! $idx[0];
    my @fmt_res_idx = map { $_ - @pre } @idx;
    my $fmt_list = [ @format_ids[@fmt_res_idx] ];
    return $fmt_list;
}



1;


__END__
