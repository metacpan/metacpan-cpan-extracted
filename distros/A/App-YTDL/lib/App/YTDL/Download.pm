package # hide from PAUSE
App::YTDL::Download;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( download_youtube );

use Term::ANSIScreen qw( :cursor :screen );
use Term::Choose     qw( choose );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::YTDL::Helper  qw( HIDE_CURSOR SHOW_CURSOR uni_system );

END { print SHOW_CURSOR }


sub _choose_fmt {
    my ( $opt, $info, $ex, $video_id, $keep_chosen ) = @_;
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
    my @fmt_str;
    my @pre = ( undef );
    while ( 1 ) {
        # Choose
        my $idx = choose(
            [ @pre, @choices ],
            { prompt => 'fmt: ' . join( '', @fmt_str ), index => 1, order => 1, undef => '<<' }
        );
        if ( ! $idx ) {
            return if ! @fmt_str;
            pop @fmt_str;
            pop @fmt_str;
            next;
        }
        push @fmt_str, @format_ids[ $idx - @pre ];
        my $enough = 'OK';
        my @ops = ( undef, $enough, '+', ',', '/', );
        my $op = choose( \@ops, { prompt => 'fmt: ' . join( '', @fmt_str ), undef => '<<' } );
        if ( ! defined $op ) { #
            pop @fmt_str;
            next;
        }
        if ( $op eq $enough ) {
            return join '', @fmt_str;
        }
        push @fmt_str, $op;
    }
}

sub download_youtube {
    my ( $opt, $info ) = @_;
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
    for my $ex ( keys %$info ) {
        $total += keys %{$info->{$ex}};
    }
    print up( 2 ) if $total == 0;
    print HIDE_CURSOR;

    EX: for my $ex ( sort keys %$info ) {
        my @sorted_video_ids = sort { $info->{$ex}{$a}{count} <=> $info->{$ex}{$b}{count} } keys %{$info->{$ex}};
        my $ask_each = @sorted_video_ids == 1 ? 0 : 1;
        my $ask_fmt  = 1;
        my $choice = '';
        my $keep = 'YES';
        my $fmt_str;

        VIDEO: for my $video_id ( @sorted_video_ids ) {
            my @cmd = @{$opt->{youtube_dl}};
            #push @cmd, '--skip-download';
            if ( $qty eq 'manually' ) {
                if ( $ask_each ) {
                    my $prompt = 'Keep format choices for all videos?';
                    $choice = choose( [ 'NO', $keep ], { prompt => $prompt } );
                    if ( ! defined $choice ) {
                        print $info->{$ex}{$video_id}{count} . '/' . $total . ' skipped' . "\n";
                        next VIDEO;
                    }
                    $ask_each = 0;
                }

                if ( $ask_fmt ) {
                    $fmt_str = _choose_fmt( $opt, $info, $ex, $video_id, $choice eq $keep );
                    if ( ! defined $fmt_str ) {
                        print $info->{$ex}{$video_id}{count} . '/' . $total . ' skipped' . "\n";
                        next VIDEO;
                    }
                    $ask_fmt = 0 if $choice eq $keep;
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
            $output .= '/%(uploader)s'  if $opt->{use_uploader_dir} == 1 || $opt->{use_uploader_dir} == 2 && $info->{$ex}{$video_id}{from_list};
            $output .= '/%(title)s_%(height)s.%(ext)s';
            push @cmd, '-o', $output;
            push @cmd, '--', $info->{$ex}{$video_id}{webpage_url};
            print $info->{$ex}{$video_id}{count} . '/' . $total . ' ';
            uni_system( @cmd );
        }
    }
    print SHOW_CURSOR;
    return;
}



1;


__END__
