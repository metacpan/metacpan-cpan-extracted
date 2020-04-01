package # hide from PAUSE
App::YTDL::Download;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( download_youtube );

use Term::ANSIScreen qw( :cursor :screen );
use Term::Choose     qw( choose );

use App::YTDL::Helper  qw( HIDE_CURSOR SHOW_CURSOR uni_system );

END { print SHOW_CURSOR }


sub _choose_fmt {
    my ( $data, $ex, $video_id, $title ) = @_;
    my $fmt_to_info = $data->{$ex}{$video_id}{fmt_to_info};
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
    my @fmt_str;

    while ( 1 ) {
        my $prompt = 'Fmt: ';
        my @pre = ( undef );
        my $menu = [ @pre, @choices ];
        # Choose
        my $idx = choose(
            $menu,
            { prompt => $prompt . join( '', @fmt_str ), index => 1, order => 1, undef => '<<', info => $title }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return if ! @fmt_str;
            pop @fmt_str;
            pop @fmt_str;
            next;
        }

        push @fmt_str, @format_ids[ $idx - @pre ];
        my $enough = '  OK';
        @pre = ( undef, $enough );
        my $ops = [
            [ '+', "  +  " ],
            [ ',', "  ,  " ],
            [ '/', "  /  " ],
        ];
        $menu = [ @pre, map( $_->[1], @$ops ) ];
        # Choose
        my $idx_op = choose(
            $menu,
            { prompt => $prompt . join( '', @fmt_str ), undef => '  <<', info => $title, layout => 3, index => 1 }
        );
        if ( ! defined $idx_op || ! defined $menu->[$idx_op] ) {
            pop @fmt_str;
            next;
        }
        if ( $menu->[$idx_op] eq $enough ) {
            return join '', @fmt_str;
        }
        push @fmt_str, $ops->[$idx_op - @pre][0];
    }
}

sub download_youtube {
    my ( $set, $opt, $data, $from_list ) = @_;
    my $qty;
    if ( $opt->{quality} =~ /^\s*(\d+) or less$/ ) {
        $qty = '<=';
        $qty .= '?' if $opt->{no_height_ok};
        $qty .= $1;
    }
    elsif ( $opt->{quality} =~ /^\s*(\d+) or better$/ ) {
        $qty = '>=';
        $qty .= '?' if $opt->{no_height_ok};
        $qty .= $1;
    }
    else {
        $qty = $opt->{quality};
    }
    my $nr = 0;
    my $total = 0;
    for my $ex ( keys %$data ) {
        $total += keys %{$data->{$ex}};
    }
    print up( 2 ) if $total == 0;
    print HIDE_CURSOR;

    EX: for my $ex ( sort keys %$data ) {
        my @sorted_video_ids = sort { $data->{$ex}{$a}{count} <=> $data->{$ex}{$b}{count} } keys %{$data->{$ex}};
        my $ask_fmt_for_each_video = 0;
        if ( $qty eq 'manually' && @sorted_video_ids > 1 ) {
            my ( $yes, $no ) = (  '- YES', '- NO' );
            my $prompt = 'Keep format choices for all videos?';
            # Choose
            my $choice = choose(
                [ undef, $yes, $no ],
                { prompt => $prompt, undef => 'EXIT', layout => 3 }
            );
            if ( ! defined $choice ) {
                exit;
            }
            elsif ( $choice eq $no ) {
                $ask_fmt_for_each_video = 1;
            }
            else {
                $ask_fmt_for_each_video = 0;
            }
        }
        my $fmt_str;
        my $count = {};

        VIDEO: for my $video_id ( @sorted_video_ids ) {
            my @cmd = @{$set->{youtube_dl}};
            #push @cmd, '--skip-download';
            if ( $qty eq 'manually' ) {
                if ( $ask_fmt_for_each_video || ! $fmt_str ) {
                    my $count_of_total = $data->{$ex}{$video_id}{count} . '/' . $total;
                    my $title;
                    if ( $ask_fmt_for_each_video ) {
                        $title = "\n" . $count_of_total . ' "' . $data->{$ex}{$video_id}{title} . '"';
                    }
                    $fmt_str = _choose_fmt( $data, $ex, $video_id, $title );
                    if ( ! defined $fmt_str ) {
                        print $count_of_total . ' skipped' . "\n";
                        next VIDEO;
                    }
                }
                push @cmd, '-f', $fmt_str;
            }
            elsif ( $qty eq 'best' ) { #
                # no format required, because 'best' is default
            }
            else {
                push @cmd, '-f', "bestvideo[height$qty]+bestaudio/best[height$qty]";
            }
            my $output = $opt->{video_dir};
            $output .= '/%(extractor)s' if $opt->{use_extractor_dir};
            $output .= '/%(uploader)s'  if $opt->{use_uploader_dir} == 1 || $opt->{use_uploader_dir} == 2 && $data->{$ex}{$video_id}{from_list};
               if ( $opt->{filename_format} == 0 ) { $output .= '/%(title)s.%(ext)s'; }
            elsif ( $opt->{filename_format} == 1 ) { $output .= '/%(title)s_%(height)s.%(ext)s'; }
            elsif ( $opt->{filename_format} == 2 ) { $output .= '/%(title)s_%(format_id)s.%(ext)s'; }
            elsif ( $opt->{filename_format} == 3 ) { $output .= '/%(title)s_%(format_id)s_%(height)s.%(ext)s'; }
            else                                   { $output .= '/%(title)s_%(format)s.%(ext)s'; }
            push @cmd, '-o', $output;
            push @cmd, '--', $data->{$ex}{$video_id}{webpage_url};
            print $data->{$ex}{$video_id}{count} . '/' . $total . ' ';
            my $exit_value = uni_system( @cmd );
            if ( $exit_value != 0 ) {
                $count->{$video_id}++;
                if ( $count->{$video_id} > $opt->{retries} ) {
                    next VIDEO;
                }
                sleep $count->{$video_id};
                $fmt_str = undef;
                redo VIDEO;
            }
        }
    }
    if ( $from_list && $total ) {
        choose(
            [ " " ],
            { prompt => "Press Enter:" }
        );
    }
    print SHOW_CURSOR;
    return;
}



1;


__END__
