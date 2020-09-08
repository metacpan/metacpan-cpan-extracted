package # hide from PAUSE
App::YTDL::Options;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( read_config_file set_options get_defaults );

use Encode;
use File::Spec::Functions qw( catfile curdir );
use File::Temp            qw();
use FindBin               qw( $RealBin $RealScript );
use Pod::Usage            qw( pod2usage );

use File::HomeDir      qw();
use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_directory choose_a_file choose_a_number settings_menu insert_sep );
use Term::Form         qw();

use App::YTDL::ChooseVideos qw( set_sort_videolist );
use App::YTDL::Helper       qw( write_json read_json uni_capture HIDE_CURSOR SHOW_CURSOR );


sub _show_info {
    my ( $set, $opt ) = @_;
    my ( $youtube_dl_version, $ffmpeg_version, $ffprobe_version );
    if ( ! eval { $youtube_dl_version = uni_capture( @{$set->{youtube_dl}}, '--version' ); 1 } ) {
        $youtube_dl_version = $@;
    }
    chomp $youtube_dl_version;
    eval {
        $ffmpeg_version = uni_capture( $set->{ffmpeg}, '-version' );
        if ( $ffmpeg_version && $ffmpeg_version =~ /^ffmpeg version (\S+)/m ) {
            $ffmpeg_version = $1;
        }
        else {
            $ffmpeg_version = '';
        }
    };
    eval {
        $ffprobe_version = uni_capture( $set->{ffprobe}, '-version' );
        if ( $ffprobe_version && $ffprobe_version =~ /^ffprobe version (\S+)/m ) {
            $ffprobe_version = $1;
        }
        else {
            $ffprobe_version = '';
        }
    };
    my $prompt = "INFO\n\n";
    $prompt .= "Directories:\n";
    $prompt .= "    Video : $opt->{video_dir}"   . "\n";
    $prompt .= "    Config: $set->{config_file}" . "\n";
    $prompt .= "\n";
    $prompt .= "Versions:\n";
    $prompt .= '    ' . catfile( $RealBin, $RealScript ) . ": " . $main::VERSION                 . "\n";
    $prompt .= '    ' . $set->{youtube_dl}[0]            . ": " . ( $youtube_dl_version // '?' ) . "\n";
    if ( $set->{ffmpeg} ) {
        $prompt .= '    ' . $set->{ffmpeg} . " : " . ( $ffmpeg_version // '?' ) . "\n";
    }
    if ( $set->{ffprobe} ) {
        $prompt .= '    ' . $set->{ffprobe} . ": " . ( $ffprobe_version // '?' ) . "\n";
    }
    # Choose
    choose(
        [ 'Close' ],
        { prompt => $prompt }
    );
}


sub get_defaults {
    return {
        entries_with_info            => 0,
        filename_format              => 3,
        list_sort_item               => 'upload_date',
        max_info_width               => 120,
        max_processes                => 5,
        max_rows_description         => 3,
        max_size_history             => 50,
        no_height_ok                 => 1,
        no_warnings                  => 0,
        prefer_free_formats          => 1,
        quality                      => 'manually',
        retries                      => 7,
        show_video_id                => 0,
        show_view_count              => 0,
        sort_history_by_timestamp    => 1,
        timeout                      => 60,
        useragent                    => 'Mozilla/5.0',
        use_extractor_dir            => 1,
        use_uploader_dir             => 1,
        video_dir                    => File::HomeDir->my_videos() // File::HomeDir->my_home() // curdir,
        yt_dl_config_location        => undef,
        yt_dl_ignore_config          => 0,
    };
}


sub _main {
    return [
        [ 'show_help_text',          "  HELP"                   ],
        [ 'show_info',               "  INFO"                   ],
        [ 'group_directory',         "- Directories"            ],
        [ 'group_quality',           "- Video format"           ],
        [ 'group_download',          "- Download"               ],
        [ 'group_history',           "- History"                ],
        [ 'group_list_menu',         "- Uploader video list"    ],
        [ 'group_output',            "- Info output"            ],
        [ 'group_yt_dl_config_file', "- Youtube-dl config file" ],
        [ 'avail_extractors',        "  List extractors"        ],
        [ 'extractor_descriptions',  "  Extractor descriptions" ],
    ];
}


sub _groups {
    return {
        group_directory => [
            [ 'video_dir',         "- Main video directory" ],
            [ 'use_extractor_dir', "- Extractor directory"  ],
            [ 'use_uploader_dir',  "- Uploader directory"   ],
            [ 'filename_format',   "- Filename format info" ],
        ],
        group_quality => [
            [ 'quality',             "- Resolution"          ],
            [ 'no_height_ok',        "- No video height"     ],
            [ 'prefer_free_formats', "- Prefer free formats" ],
        ],
        group_download => [
            [ 'useragent',  "- UserAgent"        ],
            [ 'retries',    "- Download retries" ],
            [ 'timeout',    "- Timeout"          ],
        ],
        group_output => [
            [ 'no_warnings',          "- Disable warnings" ],
            [ 'max_info_width',       "- Max info width"   ],
            [ 'max_rows_description', "- Max rows of description" ],
        ],
        group_history => [
            [ 'max_size_history',          "- Size history" ],
            [ 'sort_history_by_timestamp', "- History sort" ],
        ],
        group_list_menu => [
            [ 'entries_with_info', "- Additional info" ],
            [ 'max_processes',     "- Max processes"   ],
            [ 'list_sort_item',    "- Sort order"      ],
            [ 'show_view_count',   "- Show view count" ],
            [ 'show_video_id',     "- Show video id"   ],
        ],
        group_yt_dl_config_file => [
            [ 'yt_dl_config_location',        "- set yt-dl config location"   ],
            [ '_reset_yt_dl_config_location', "- reset yt-dl config location" ],
            [ 'yt_dl_ignore_config',          "- Ignore yt-dl config file"    ],
        ],
    };
}


sub set_options {
    my ( $set, $opt ) = @_;
    my $main = _main();
    my $old_idx_main = 0;

    MAIN_MENU: while ( 1 ) {
        my $back_main     = '  QUIT';
        my $continue_main = '  CONTINUE';
        my @pre  = ( undef, $continue_main );
        my @choices_main = map( $_->[1], @$main );
        my $menu_main = [ @pre, @choices_main ];
        # Choose
        my $idx_main = choose(
            $menu_main,
            { prompt => 'Options:', layout => 3, index => 1, clear_screen => 1,
              undef => $back_main, default => $old_idx_main }
        );
        if ( ! defined $idx_main || ! defined $menu_main->[$idx_main] ) {
            if ( $set->{change} ) {
                _write_config_file( $opt, $set->{config_file} );
                delete $set->{change};
            }
            exit;
        }
        if ( $old_idx_main == $idx_main ) {
            $old_idx_main = 0;
            next MAIN_MENU;
        }
        $old_idx_main = $idx_main;
        my $choice = $menu_main->[$idx_main];
        if ( $choice eq $continue_main ) {
            if ( $set->{change} ) {
                _write_config_file( $opt, $set->{config_file} );
                delete $set->{change};
            }
            last MAIN_MENU;
        }
        my ( $main_key, $main_prompt ) = @{$main->[$idx_main-@pre]};
        $main_prompt =~ s/^-\s//;
        if ( $main_key !~ /^group_/ ) {
            if ( $main_key eq "show_help_text" ) {
                pod2usage( { -exitval => 'NOEXIT', -verbose => 2 } );
            }
            elsif ( $main_key eq "show_info" ) {
                _show_info( $set, $opt );
            }
            elsif ( $main_key eq "avail_extractors" ) {
                say 'Close with ENTER';
                my @capture;
                if ( ! eval { @capture = uni_capture( @{$set->{youtube_dl}}, '--list-extractors' ); 1 } ) {
                    say "List extractors: $@";
                }
                if ( @capture ) {
                    # Choose
                    choose(
                        [ map { "  $_" } @capture ],
                        { layout => 3 }
                    );
                }
            }
            elsif ( $main_key eq "extractor_descriptions" ) {
                say 'Close with ENTER';
                my @capture;
                if ( ! eval { @capture = uni_capture( @{$set->{youtube_dl}}, '--extractor-descriptions' ); 1 } ) {
                    say "Extractor descriptions: $@";
                }
                if ( @capture ) {
                    # Choose
                    choose(
                        [ map { '  ' . decode( 'UTF-8', $_ ) } @capture ],
                        { layout => 3 }
                    );
                }
            }
            next MAIN_MENU;
        }
        my $groups = _groups();
        my $group = $groups->{$main_key};
        my $old_idx_group = 0;

        GROUP: while ( 1 ) {
            my $back_group     = '  <<';
            my $continue_group = '  CONTINUE';
            my @pre  = ( undef );
            my @choices_group = map( $_->[1], @$group );
            my $menu_group = [ @pre, @choices_group ];
            # Choose
            my $idx_group = choose(
                $menu_group,
                { prompt => $main_prompt, layout => 3, index => 1, clear_screen => 1, undef => $back_group, default => $old_idx_group }
            );
            if ( ! defined $idx_group || ! defined $menu_group->[$idx_group] ) {
                next MAIN_MENU;
            }
            if ( $old_idx_group == $idx_group ) {
                $old_idx_group = 0;
                next GROUP;
            }
            $old_idx_group = $idx_group;
            my $choice = $menu_group->[$idx_group];
            if ( $choice eq $continue_group ) {
                next MAIN_MENU;
            }
            my $key = $group->[$idx_group-@pre][0];
            if ( $key eq "video_dir" ) {
                my $info = "Video Directory\nNow: " . $opt->{$key} // 'current directory';
                my $name = 'New: ';
                _opt_choose_a_directory( $set, $opt, $key, $info, $name );
            }
            elsif ( $key eq "use_extractor_dir" ) {
                my $prompt = 'Use extractor directories';
                my $list = [ 'no', 'yes' ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "use_uploader_dir" ) {
                my $prompt = 'Use uploader directories';
                my $list = [
                    'no',
                    'yes',
                    'if from list-menu',
                ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "filename_format" ) {
                my $prompt = 'Filename: choose the format info:';
                my $list = [
                    'none (unsafe)',
                    'video-height (unsafe)',
                    'fmt-id',
                    'fmt-id and video-height',
                    'fmt-string',
                ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "useragent" ) {
                my $prompt = 'Set the UserAgent';
                my $list = [
                    [ 'UserAgent', $opt->{useragent} ]
                ];
                _local_readline( $set, $opt, $key, $prompt, $list );
                $opt->{useragent} = '' if $opt->{useragent} eq '""';
            }
            elsif ( $key eq "quality" ) {
                my $prompt = 'Video resolution';
                my $list = [
                    'manually',
                    ' 180 or less',
                    ' 360 or less',
                    ' 720 or less',
                    '1080 or less',
                    '1440 or less',
                    '2160 or less',
                    'best'
                ];
                _opt_choose_from_list_value( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "no_height_ok" ) {
                my $prompt = 'Download videos with unkown height';
                my $list = [ 'no', 'yes' ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "retries" ) {
                my $digits = 2;
                my $info = sprintf "Download retries\nNow: %${digits}s", insert_sep( $opt->{$key} );
                my $name = 'New: ';
                _opt_number_range( $set, $opt, $key, $name, $info, $digits );
            }
            elsif ( $key eq "timeout" ) {
                my $digits = 3;
                my $info = sprintf "Connection timeout (s)\nNow: %${digits}s", insert_sep( $opt->{$key} );
                my $name = 'New: ';
                _opt_number_range( $set, $opt, $key, $name, $info, $digits );
            }
            elsif ( $key eq "no_warnings" ) {
                my $prompt = 'Disable youtube-dl warnings';
                my $list = [ 'no', 'yes' ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "prefer_free_formats" ) {
                my $prompt = 'Prefer free formats';
                my $list = [ 'no', 'yes' ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "max_size_history" ) {
                my $digits = 3;
                my $info = sprintf "Max size of history\nNow: %${digits}s", insert_sep( $opt->{$key} );
                my $name = 'New: ';
                _opt_number_range( $set, $opt, $key, $name, $info, $digits );
            }
            elsif ( $key eq "sort_history_by_timestamp" ) {
                my $prompt = 'Sort history by';
                my $list = [ 'by name', 'by timestamp' ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "entries_with_info" ) {
                my $digits = 4;
                my $sep_w = 1;
                my $w = $digits + int( ( $digits - 1 ) / 3 ) * $sep_w;
                my $info = sprintf "Number of entries with additional information\nNow: %${w}s", insert_sep( $opt->{$key} );
                my $name = 'New: ';
                _opt_number_range( $set, $opt, $key, $name, $info, $digits );
            }
            elsif ( $key eq "max_processes" ) {
                my $digits = 2;
                my $info = sprintf "Fetching additional information: the maximum number of parallel downloads\nNow: %${digits}s", insert_sep( $opt->{$key} );
                my $name = 'New: ';
                _opt_number_range( $set, $opt, $key, $name, $info, $digits );
            }
            elsif ( $key eq "list_sort_item" ) {
                set_sort_videolist( $set, $opt );
            }
            elsif ( $key eq "show_view_count" ) {
                my $prompt = 'Show the view-count in list-menus';
                my $list = [ 'if sorted by "view count"', 'always' ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "show_video_id" ) {
                my $prompt = 'Show the video-id in list-menus';
                my $list = [ 'no', 'yes' ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            elsif ( $key eq "max_info_width" ) {
                my $digits = 3;
                my $info = sprintf "Max Info width\nNow: %${digits}s", insert_sep( $opt->{$key} );
                my $name = 'New: ';
                _opt_number_range( $set, $opt, $key, $name, $info, $digits );
            }
            elsif ( $key eq "max_rows_description" ) {
                my $digits = 2;
                my $info = sprintf "Max Rows of description\nNow: %${digits}s", insert_sep( $opt->{$key} );
                my $name = 'New: ';
                _opt_number_range( $set, $opt, $key, $name, $info, $digits );
            }
            elsif ( $key eq "yt_dl_config_location" ) {
                my $info = "Youtube-dl Config File\nNow: ";
                if ( defined $opt->{$key} ) {
                    $info .= $opt->{$key};
                }
                else {
                    $info .= 'default (';
                    $info .= $^O eq 'MSWin32' ? "%APPDATA%/youtube-dl/config.txt" : "~/.config/youtube-dl/config";
                    $info .= ')';
                }
                my $name = 'New: ';
                _opt_choose_a_file( $set, $opt, $key, $info, $name );
            }
            elsif ( $key eq "_reset_yt_dl_config_location" ) {
                my $prompt = 'Reset the youtube-dl config location to default';
                my $list = [ 'no', 'yes' ];
                $opt->{_reset_yt_dl_config_location} = 0;
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
                if ( $opt->{_reset_yt_dl_config_location} ) {
                    $opt->{yt_dl_config_location} = undef;
                }
                delete $opt->{_reset_yt_dl_config_location};
            }
            elsif ( $key eq "yt_dl_ignore_config" ) {
                my $prompt = 'Ignore youtube-dl config file';
                my $list = [ 'no', 'yes' ];
                _opt_choose_from_list_idx( $set, $opt, $key, $prompt, $list );
            }
            else { die $key }
        }
    }
    return;
}


sub _opt_settings_menu {
    my ( $set, $opt, $sub_menu, $current, $prompt ) = @_;
    # Settings_menu
    my $changed = settings_menu( $sub_menu, $current, { prompt => $prompt } );
    return if ! $changed;
    for my $key ( keys %$current ) {
        $opt->{$key} = $current->{$key};
    }
    $set->{change}++;
}


sub _opt_choose_a_directory {
    my( $set, $opt, $key, $info, $name ) = @_;
    # Choose_a_directory
    my $new_dir = choose_a_directory( { init_dir => $opt->{$key}, cs_label => $name, info => $info } );
    return if ! defined $new_dir;
    if ( $new_dir ne $opt->{$key} ) {
        if ( ! eval {
            my $fh = File::Temp->new( TEMPLATE => 'XXXXXXXXXXXXXXX', UNLINK => 1, DIR => $new_dir ); ##
            1 }
        ) {
            print "$@";
            # Choose
            choose(
                [ 'Press Enter:' ],
                { prompt => '' }
            );
        }
        else {
            $opt->{$key} = $new_dir;
            $set->{change}++;
        }
    }
}


sub _opt_choose_a_file {
    my( $set, $opt, $key, $info, $name ) = @_;
    # Choose_a_file
    my $file = choose_a_file( { cs_label => $name, info => $info } );
    return if ! defined $file;
    $opt->{$key} = $file;
    $set->{change}++;
}


sub _local_readline {
    my ( $set, $opt, $key, $prompt, $list ) = @_;
    # Fill_form
    my $trs = Term::Form->new();
    my $new_list = $trs->fill_form(
        $list,
        { prompt => $prompt, auto_up => 2, confirm => 'CONFIRM', back => 'BACK   ' }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$new_list ) {
            $opt->{$key} = $new_list->[$i][1];
        }
        $set->{change}++;
    }
}


sub _opt_number_range {
    my ( $set, $opt, $key, $name, $info, $digits ) = @_;
    # Choose_a_number
    my $choice = choose_a_number( $digits, { cs_label => $name, info => $info, small_first => 1 } );
    return if ! defined $choice;
    $opt->{$key} = $choice eq '--' ? undef : $choice;
    $set->{change}++;
    return;
}


sub _opt_choose_from_list_idx {
    my ( $set, $opt, $key, $prompt, $list ) = @_;
    my $backup = $opt->{$key};
    my $confirm = '  CONFIRM';
    my @pre = ( undef, $confirm );
    my $choices = [ @pre, map { "- $_" } @$list ];
    while ( 1 ) {
        my $local_prompt = $prompt . ': [' . ( $list->[$opt->{$key}] // '--' ) . ']';
        # Choose
        my $idx = choose(
            $choices,
            { prompt => $local_prompt, layout => 3, undef => '  BACK', index => 1 }
        );
        if ( ! defined $idx || $idx == 0 ) {
            $opt->{$key} = $backup;
            return;
        }
        elsif ( $choices->[$idx] eq $confirm ) {
            $set->{change}++;
            return;
        }
        else {
            $opt->{$key} = $idx - @pre;
        }
    }
}


sub _opt_choose_from_list_value {
    my ( $set, $opt, $key, $prompt, $list ) = @_;
    my $backup = $opt->{$key};
    my $confirm = '  CONFIRM';
    my @pre = ( undef, $confirm );
    while ( 1 ) {
        my $local_prompt = $prompt . ': [' . ( $opt->{$key} // '--' ) . ']';
        # Choose
        my $choice = choose(
            [ @pre,  map { "- $_" } @$list ],
            { prompt => $local_prompt, layout => 3, undef => '  BACK', index => 0 }
        );
        if ( ! defined $choice ) {
            $opt->{$key} = $backup;
            return;
        }
        elsif ( $choice eq $confirm ) {
            $set->{change}++;
            return;
        }
        else {
            $choice =~ s/^-\s//;
            $opt->{$key} = $choice;
        }
    }
}


sub _write_config_file {
    my ( $opt, $file ) = @_;
    my $tmp = {};
    for my $key ( sort keys %{ get_defaults() } ) {
        $tmp->{$key} = $opt->{$key};
    }
    write_json( $file, $tmp );
}


sub read_config_file {
    my ( $opt, $file ) = @_;
    my $tmp = read_json( $file ) // {};
    my @keys = keys %$tmp;
    for my $key ( @keys ) {
        $opt->{$key} = $tmp->{$key} if defined $tmp->{$key};
    }
    ################################################### "... or better" removed in 0.413 - Keep this for a while.
    if ( $opt->{quality} =~ /^\s*\d+\sor\sbetter\z/ ) {
        $opt->{quality} = 'manually';
    }
    ###################################################
}


1;


__END__
