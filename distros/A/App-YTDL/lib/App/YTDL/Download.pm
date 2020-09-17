package # hide from PAUSE
App::YTDL::Download;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( download );

use Term::ANSIScreen qw( :cursor :screen );
use Term::Choose     qw( choose );

use App::YTDL::Helper qw( HIDE_CURSOR SHOW_CURSOR uni_system );

END { print SHOW_CURSOR }


sub _choose_fmts {
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
    my @relative_formats = ( 'best', 'bestaudio' );
    push @choices, @relative_formats;
    push @format_ids, @relative_formats;
    my @fmt_data;

    while ( 1 ) {
        my $prompt = 'Fmt: ';
        my @pre = ( undef );
        my $menu = [ @pre, @choices ];
        # Choose
        my $idx = choose(
            $menu,
            { prompt => $prompt . join( '', @fmt_data ), index => 1, order => 1, undef => '<<', info => $title }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return if ! @fmt_data;
            pop @fmt_data;
            pop @fmt_data;
            next;
        }

        push @fmt_data, @format_ids[ $idx - @pre ];
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
            { prompt => $prompt . join( '', @fmt_data ), undef => '  <<', info => $title, layout => 3, index => 1 }
        );
        if ( ! defined $idx_op || ! defined $menu->[$idx_op] ) {
            pop @fmt_data;
            next;
        }
        if ( $menu->[$idx_op] eq $enough ) {
            return @fmt_data;
        }
        push @fmt_data, $ops->[$idx_op - @pre][0];
    }
}


sub download {
    my ( $set, $opt, $data, $chosen ) = @_;
    if ( ! defined $chosen || ! keys %$chosen ) {
        return;
    }
    my $qty = $opt->{quality};
    my $total_chosen_videos = 0;
    for my $ex ( keys %$data ) {
        for my $up ( keys %{$data->{$ex}} ) {
            if ( ! exists $chosen->{$ex}{$up} ) {
                next;
            }
            $total_chosen_videos += @{$chosen->{$ex}{$up}};
        }
    }
    print up( 2 ) if $total_chosen_videos == 0;
    print HIDE_CURSOR;

    RETRY: while ( 1 ) {
        my %download_cmds;

        EXTRACTOR_KEY: for my $ex ( sort keys %$data ) {

            UPLOADER_ID: for my $up ( sort keys %{$data->{$ex}} ) {
                if ( ! exists $chosen->{$ex}{$up} ) {
                    next;
                }
                my @sorted_ids = sort { $data->{$ex}{$up}{$a}{count} <=> $data->{$ex}{$up}{$b}{count} } @{$chosen->{$ex}{$up}};
                my $keep_fmt_choices;
                if ( $qty eq 'manually' && @sorted_ids > 1 ) {
                    my ( $yes, $no ) = (  '- YES', '- NO' );
                    my $prompt = "\n" . ( $data->{$ex}{$up}{$sorted_ids[0]}{uploader} // $up ) . ':' . "\n";
                    $prompt .= 'Keep format choices?';
                    # Choose
                    my $choice = choose(
                        [ undef, $yes, $no ],
                        { prompt => $prompt, undef => '<<', layout => 3 }
                    );
                    if ( ! defined $choice ) {
                        next UPLOADER_ID;
                    }
                    elsif ( $choice eq $no ) {
                        $keep_fmt_choices = 0;
                    }
                    else {
                        $keep_fmt_choices = 1;
                    }
                }
                my $fmt_str;
                my $count = {};
                my @fmt_data;
                my @backup_fmt_data;

                VIDEO_ID: for my $id ( @sorted_ids ) {
                    my $count_of_total = $data->{$ex}{$up}{$id}{count} . '/' . $total_chosen_videos;
                    if ( ! defined $data->{$ex}{$up}{$id}{fmt_to_info} ) {
                        $download_cmds{$ex}{$up}{$id} = [ sprintf "[%s] %s\n%s\nSkipped: %s\n", $ex, $id, $data->{$ex}{$up}{$id}{title}, $set->{failed_fetching_data} ];
                        next VIDEO_ID;
                    }
                    my @cmd = @{$set->{youtube_dl}};
                    if ( $qty eq 'manually' ) {
                        if ( ! $fmt_str ) {
                            ( my $duration = $data->{$ex}{$up}{$id}{duration} ) =~ s/^[^1-9]+//;
                            my $title = "\n" . $count_of_total . ' "' . $data->{$ex}{$up}{$id}{title} . '" (' . $duration . ')';
                            @fmt_data = _choose_fmts( $data, $ex, $up, $id, $title );
                            if ( ! @fmt_data ) {
                                $download_cmds{$ex}{$up}{$id} = [ sprintf "[%s] %s\n%s\nSkipped: user request\n", $ex, $id, $data->{$ex}{$up}{$id}{title} ];
                                next VIDEO_ID;
                            }
                        }
                        elsif ( $keep_fmt_choices ) {
                            my @fmts = @fmt_data[ grep { ! ( $_ % 2 ) } 0 .. $#fmt_data ];
                            my @unavailable_fmts = grep { $_ !~ /^best/ && ! exists $data->{$ex}{$up}{$id}{fmt_to_info}{$_} } @fmts;
                            if ( @unavailable_fmts ) {
                                my $info = "\n" . $id . "\n";
                                $info .= $data->{$ex}{$up}{$id}{title} . "\n";
                                $info .= "Requested formats (@unavailable_fmts) not available!\n";
                                my $answer = choose(
                                    [ undef, 'Choose from available formats' ],
                                    { info => $info, undef => 'Skip this video', prompt => '', layout => 3 }
                                );
                                if ( ! defined $answer ) {
                                    $download_cmds{$ex}{$up}{$id} = [ sprintf "[%s] %s\n%s\nSkipped: user request\n", $ex, $id, $data->{$ex}{$up}{$id}{title} ];
                                    next VIDEO_ID;
                                }
                                else {
                                    @backup_fmt_data = @fmt_data;
                                    @fmt_data = ();
                                    $fmt_str = undef;
                                    redo VIDEO_ID;
                                }
                            }
                        }
                    }
                    else {
                        @fmt_data = ( $qty );
                    }
                    for my $el ( @fmt_data ) {
                        if ( $el =~ /^\s*(\d+) or less\z/ ) {
                            my $tmp = '<=';
                            $tmp .= '?' if $opt->{no_height_ok};
                            $tmp .= $1;
                            $el = "bestvideo[height$tmp]+bestaudio/best[height$tmp]";
                        }
                        elsif ( $el eq 'best' ) {
                            $el = 'bestvideo+bestaudio/best';
                        }
                    }
                    $fmt_str = join '', @fmt_data;
                    push @cmd, '-f', $fmt_str;
                    if ( ! $keep_fmt_choices ) {
                        $fmt_str = undef;
                    }
                    my $output = $opt->{video_dir};
                    $output .= '/%(extractor)s' if $opt->{use_extractor_dir};
                    $output .= '/%(uploader)s'  if $opt->{use_uploader_dir} == 1 || $opt->{use_uploader_dir} == 2 && $data->{$ex}{$up}{$id}{from_list};
                    if    ( $opt->{filename_format} == 0 ) { $output .= '/%(title)s.%(ext)s'; }
                    elsif ( $opt->{filename_format} == 1 ) { $output .= '/%(title)s_%(height)s.%(ext)s'; }
                    elsif ( $opt->{filename_format} == 2 ) { $output .= '/%(title)s_%(format_id)s.%(ext)s'; }
                    elsif ( $opt->{filename_format} == 3 ) { $output .= '/%(title)s_%(format_id)s_%(height)s.%(ext)s'; }
                    else                                   { $output .= '/%(title)s_%(format)s.%(ext)s'; }

                    push @cmd, '-o', $output;
                    push @cmd, '--', $data->{$ex}{$up}{$id}{webpage_url};
                    $download_cmds{$ex}{$up}{$id} = [ @cmd ];
                    if ( @backup_fmt_data ) {
                        @fmt_data = @backup_fmt_data;
                        @backup_fmt_data = ();
                    }
                }
            }
        }
        say "";
        my %download_failed;
        my $count_downloads = 0;
        my $total_downloads = 0;
        for my $ex ( keys %download_cmds ) {
            for my $up ( keys %{$download_cmds{$ex}} ) {
                for my $id ( keys %{$download_cmds{$ex}{$up}} ) {
                    ++$total_downloads;
                }
            }
        }
        my $attempts = 1;

        for my $ex ( sort keys %download_cmds ) {

            for my $up ( sort keys %{$download_cmds{$ex}} ) {
                my @sorted_ids = sort { $data->{$ex}{$up}{$a}{count} <=> $data->{$ex}{$up}{$b}{count} } keys %{$download_cmds{$ex}{$up}};

                VIDEO_DOWNLOAD: for my $id ( @sorted_ids ) {
                    $count_downloads++;
                    my $cmd = $download_cmds{$ex}{$up}{$id};
                    my $retries = sprintf " (%d|%d)", $attempts, $opt->{retries};
                    printf "%d/%d%s\n", $count_downloads, $total_downloads, $attempts > 1 ? $retries : '';
                    if ( $cmd->[0] ne $set->{youtube_dl}[0] ) {
                        print $cmd->[0];
                        next VIDEO_DOWNLOAD;
                    }
                    my $exit_value = uni_system( @$cmd );
                    if ( $exit_value != 0 ) {
                        $attempts++;
                        if ( $attempts > $opt->{retries} ) {
                            $attempts = 1;
                            push @{$download_failed{$ex}{$up}}, $id;
                            next VIDEO_DOWNLOAD;
                        }
                        sleep $attempts * 3;
                        $count_downloads--;
                        redo VIDEO_DOWNLOAD;
                    }
                }
            }
        }
        if ( %download_failed ) {
            my $info = "\nDownload failed for:\n";
            for my $ex ( keys %download_failed ) {
                for my $up ( keys %{$download_failed{$ex}} ) {
                    for my $id ( @{$download_failed{$ex}{$up}} ) {
                        $info .= "$id : $data->{$ex}{$up}{$id}{title}\n";
                    }
                }
            }
            my $answer = choose(
                [ undef, 'Yes' ],
                { undef => 'No', prompt => 'Retry with a different format?', info => $info }
            );
            if ( ! $answer ) {
                last RETRY;
            }
            else {
                $qty = 'manually';
                $chosen = { %download_failed };
                next RETRY;
            }
        }
        last RETRY;
    }
    print SHOW_CURSOR;
    return $total_chosen_videos;
}


1;


__END__
