package # hide from PAUSE
App::YTDL::Download;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( download );

use Term::ANSIScreen qw( :cursor :screen );
use Term::Choose     qw( choose );

use App::YTDL::Helper  qw( HIDE_CURSOR SHOW_CURSOR uni_system );

END { print SHOW_CURSOR }


sub _choose_fmt {
    my ( $data, $ex, $up, $id, $title ) = @_;
    my $fmt_to_info = $data->{$ex}{$up}{$id}{fmt_to_info};
    my ( @choices, @format_ids );
    if ( ( keys %$fmt_to_info )[0] =~ /^\s*\d/ ) {
        no warnings 'numeric';
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
    my @named_qualities = qw(best worst bestvideo worstvideo bestaudio worstaudio);
    push @choices, @named_qualities;
    push @format_ids, @named_qualities;
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


sub download {
    my ( $set, $opt, $data, $chosen, $from_list ) = @_;
    if ( ! defined $chosen || ! keys %$chosen ) {
        return;
    }
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
    my $total = 0;
    for my $ex ( keys %$data ) {
        for my $up ( keys %{$data->{$ex}} ) {
            $total += @{$chosen->{$ex}{$up}};
        }
    }
    print up( 2 ) if $total == 0;
    print HIDE_CURSOR;

    EXTRACTOR_KEY: for my $ex ( sort keys %$data ) {

        UPLOADER_ID: for my $up ( sort keys %{$data->{$ex}} ) {
            if ( ! @{$chosen->{$ex}{$up}} ) {
                next;
            }
            my @sorted_ids = sort { $data->{$ex}{$up}{$a}{count} <=> $data->{$ex}{$up}{$b}{count} } @{$chosen->{$ex}{$up}};
            my $ask_fmt_for_each_video = 0;
            if ( $qty eq 'manually' && @sorted_ids > 1 ) {
                my ( $yes, $no ) = (  '- YES', '- NO' );
                my $prompt = 'Keep format choices for all videos?';
                # Choose
                my $choice = choose(
                    [ undef, $yes, $no ],
                    { prompt => $prompt, undef => 'EXIT', layout => 3 }
                );
                if ( ! defined $choice ) {
                    print locate 1, 1;
                    print cldown;
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
            my $backup_fmt_str;

            VIDEO_ID: for my $id ( @sorted_ids ) {
                my @cmd = @{$set->{youtube_dl}};
                #push @cmd, '--skip-download';
                if ( $qty eq 'manually' ) {
                    if ( $ask_fmt_for_each_video || ! $fmt_str ) {
                        my $count_of_total = $data->{$ex}{$up}{$id}{count} . '/' . $total;
                        my $title = "\n" . $count_of_total . ' "' . $data->{$ex}{$up}{$id}{title} . '"';
                        $fmt_str = _choose_fmt( $data, $ex, $up, $id, $title );
                        if ( ! defined $fmt_str ) {
                            print $count_of_total . ' skipped' . "\n";
                            next VIDEO_ID;
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
                $output .= '/%(uploader)s'  if $opt->{use_uploader_dir} == 1 || $opt->{use_uploader_dir} == 2 && $data->{$ex}{$up}{$id}{from_list};
                if ( $opt->{filename_format} == 0 ) { $output .= '/%(title)s.%(ext)s'; }
                elsif ( $opt->{filename_format} == 1 ) { $output .= '/%(title)s_%(height)s.%(ext)s'; }
                elsif ( $opt->{filename_format} == 2 ) { $output .= '/%(title)s_%(format_id)s.%(ext)s'; }
                elsif ( $opt->{filename_format} == 3 ) { $output .= '/%(title)s_%(format_id)s_%(height)s.%(ext)s'; }
                else                                   { $output .= '/%(title)s_%(format)s.%(ext)s'; }

                push @cmd, '-o', $output;
                push @cmd, '--', $data->{$ex}{$up}{$id}{webpage_url};
                print $data->{$ex}{$up}{$id}{count} . '/' . $total . ' ';
                my $exit_value = uni_system( @cmd );
                if ( $exit_value != 0 ) {
                    $count->{$id}++;
                    if ( $count->{$id} > $opt->{retries} ) {
                        next VIDEO_ID;
                    }
                    sleep $count->{$id};
                    $backup_fmt_str = $fmt_str;
                    $fmt_str = undef;
                    redo VIDEO_ID;
                }
                if ( $backup_fmt_str ) {
                    $fmt_str = $backup_fmt_str;
                    $backup_fmt_str = undef;
                }
            }
            if ( $opt->{entries_with_info} == 0 ) {
                for my $id ( @sorted_ids ) {
                    delete $data->{$ex}{$up}{$id}; #
                }
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
