package # hide from PAUSE
App::YTDL::Options;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( read_config_file set_options );

use Encode;
use File::Spec::Functions qw( catfile );
use File::Temp            qw();
use FindBin               qw( $RealBin $RealScript );
use Pod::Usage            qw( pod2usage );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_dir choose_a_file choose_a_number settings_menu insert_sep );
use Term::Form         qw();

use App::YTDL::ChooseVideos qw( set_sort_videolist );
use App::YTDL::Helper       qw( write_json read_json uni_capture HIDE_CURSOR SHOW_CURSOR );


sub _show_info {
    my ( $opt ) = @_;
    my ( $youtube_dl_version, $ffmpeg_version, $ffprobe_version );
    if ( ! eval { $youtube_dl_version = uni_capture( @{$opt->{youtube_dl}}, '--version' ); 1 } ) {
        $youtube_dl_version = $@;
    }
    chomp $youtube_dl_version;
    eval {
        $ffmpeg_version = uni_capture( $opt->{ffmpeg}, '-version' );
        if ( $ffmpeg_version && $ffmpeg_version =~ /^ffmpeg version (\S+)/m ) {
            $ffmpeg_version = $1;
        }
        else {
            $ffmpeg_version = '';
        }
    };
    eval {
        $ffprobe_version = uni_capture( $opt->{ffprobe}, '-version' );
        if ( $ffprobe_version && $ffprobe_version =~ /^ffprobe version (\S+)/m ) {
            $ffprobe_version = $1;
        }
        else {
            $ffprobe_version = '';
        }
    };
    my $info = "INFO\n\n";
    $info .= "Directories:\n";
    $info .= "    Video : $opt->{video_dir}"   . "\n";
    $info .= "    Config: $opt->{config_file}" . "\n";
    $info .= "\n";
    $info .= "Versions:\n";
    $info .= '    ' . catfile( $RealBin, $RealScript ) . ": " . $main::VERSION                 . "\n";
    $info .= '    ' . $opt->{youtube_dl}[0]            . ": " . ( $youtube_dl_version // '?' ) . "\n";
    if ( $opt->{ffmpeg} ) {
        $info .= '    ' . $opt->{ffmpeg} . " : " . ( $ffmpeg_version // '?' ) . "\n";
    }
    if ( $opt->{ffprobe} ) {
        $info .= '    ' . $opt->{ffprobe} . ": " . ( $ffprobe_version // '?' ) . "\n";
    }
    choose( [ 'Close' ], { prompt => "\n$info" } );
}


sub _menus {
    my $menus = {
        main => [
            [ 'show_help_text',             "  HELP"              ],
            [ 'show_info',                  "  INFO"              ],
            [ 'group_directory',            "- Directory"         ],
            [ 'group_quality',              "- Quality"           ],
            [ 'group_download',             "- Download"          ],
            [ 'group_output',               "- Info Output"       ],
            [ 'group_history',              "- History"           ],
            [ 'group_list_menu',            "- Uploader Videos"   ],
            [ 'group_yt_dl_config_file',    "- yt-dl config file" ],
            [ 'group_avail_extractors',     "- Extractors"        ],
        ],
        group_avail_extractors => [
        ],
        group_directory => [
            [ 'video_dir',         "- Main video directory" ],
            [ 'use_extractor_dir', "- Extractor directory"  ],
            [ 'use_uploader_dir',  "- Uploader directory"   ],
        ],
        group_quality => [
            [ 'quality',             "- Resolution"          ],
            [ 'no_height_ok',        "- No video height"     ],
            [ 'prefer_free_formats', "- Prefer free formats" ],
        ],
        group_download => [
            [ 'useragent',           "- UserAgent"        ],
            [ 'retries',             "- Download retries" ],
            [ 'timeout',             "- Timeout"          ],

        ],
        group_output => [
            [ 'no_warnings',     "- Disable warnings" ],
            [ 'max_info_width',  "- Max info width"   ],
        ],
        group_history => [
            [ 'max_size_history',          "- Size history" ],
            [ 'sort_history_by_timestamp', "- History sort" ],
        ],
        group_list_menu => [
            [ '_type_listmenu',  "- List type" ],
            [ 'list_sort_item',  "- Sort order"          ],
            [ 'show_view_count', "- Show view count"     ],
        ],

        group_yt_dl_config_file => [
            [ 'yt_dl_config_location',       "- set yt-dl config location"   ],
            [ 'reset_yt_dl_config_location', "- reset yt-dl config location" ],
            [ 'yt_dl_ignore_config',         "- Ignore yt-dl config file" ],
        ],
        group_avail_extractors => [
            [ '_avail_extractors',        "  List Extractors"        ],
            [ '_extractor_descriptions',  "  Extractor descriptions" ],

        ],
    };
    return $menus;
}


sub _sub_menus {
    my ( $key ) = @_;
    my $sub_menus = {
        _type_listmenu => [
            [ 'list_type_vimeo',   "- vimeo",   [ 'all standard', 'all fast', 'latest fast' ] ],
            [ 'list_type_youtube', "- youtube", [ 'all standard', 'all fast', 'latest fast' ] ],
        ],
    };
    return $sub_menus->{$key} if $key;
    return $sub_menus;
}


sub _group_prompt {
    my ( $group ) = @_;
    my $group_prompt = {
        group_directory             => "Directories:",
        group_quality               => "Video format:",
        group_download              => "Download:",
        group_history               => "History:",
        group_list_menu             => "Uploader video list:",
        group_output                => "Info Outpupt:",
        group_youtube_dl            => "youtube_dl:",
        group_yt_dl_config_file     => "Youtube-dl config file:",
        group_avail_extractors      => "Available extractors:",
    };
    return $group_prompt->{$group};
}


sub set_options {
    my ( $opt ) = @_;
    my $menus     = _menus();
    my $sub_menus = _sub_menus();
    my @keys;
    for my $group ( keys %$menus ) {
        next if $group eq 'main';
        push @keys, grep { ! /^_/ } map { $_->[0] } @{$menus->{$group}};
    }
    for my $key ( keys %$sub_menus ) {
        push @keys, map { $_->[0] } @{$sub_menus->{$key}};
    }
    my $group = 'main';
    my $backup_old_idx = 0;
    my $old_idx = 0;

    GROUP: while ( 1 ) {
        my $menu = $menus->{$group};

        OPTION: while ( 1 ) {
            my $back     = $group eq 'main' ? '  QUIT' : '  <<';
            my $continue = '  CONTINUE';
            my @pre  = ( undef, $group eq 'main' ? $continue : () );
            my @real = map( $_->[1], @$menu );
            my $prompt = _group_prompt( $group ) // 'Options:';
            # Choose
            my $idx = choose(
                [ @pre, @real ],
                { prompt => $prompt, layout => 3, index => 1, clear_screen => 1, undef => $back, default => $old_idx }
            );
            if ( ! $idx ) {
                if ( $group eq 'main' ) {
                    _write_config_file( $opt, $opt->{config_file}, @keys );
                    exit;
                }
                else {
                    $old_idx = $backup_old_idx;
                    $group = 'main';
                    next GROUP;
                }
            }
            if ( $old_idx == $idx ) {
                $old_idx = 0;
                next OPTION;
            }
            $old_idx = $idx;
            my $choice = $idx <= $#pre ? $pre[$idx] : $menu->[$idx - @pre][0];
            if ( $choice =~ /^group_/ ) {
                $backup_old_idx = $old_idx;
                $old_idx = 0;
                $group = $choice;
                redo GROUP;
            }
            if ( $choice eq $continue ) {
                if ( $group =~ /^group_/ ) {
                    $group = 'main';
                    redo GROUP;
                }
                _write_config_file( $opt, $opt->{config_file}, @keys );
                last GROUP;
            }
            if ( $choice eq "show_help_text" ) {
                pod2usage( { -exitval => 'NOEXIT', -verbose => 2 } );
            }
            elsif ( $choice eq "show_info" ) {
                _show_info( $opt );
            }
            elsif ( $choice eq "_avail_extractors" ) {
                say 'Close with ENTER';
                my @capture;
                if ( ! eval { @capture = uni_capture( @{$opt->{youtube_dl}}, '--list-extractors' ); 1 } ) {
                    say "List extractors: $@";
                }
                if ( @capture ) {
                    choose(
                        [ map { "  $_" } @capture ],
                        { layout => 3 }
                    );
                }
            }
            elsif ( $choice eq "_extractor_descriptions" ) {
                say 'Close with ENTER';
                my @capture;
                if ( ! eval { @capture = uni_capture( @{$opt->{youtube_dl}}, '--extractor-descriptions' ); 1 } ) {
                    say "Extractor descriptions: $@";
                }
                if ( @capture ) {
                    choose(
                        [ map { '  ' . decode( 'UTF-8', $_ ) } @capture ],
                        { layout => 3 }
                    );
                }
            }
            elsif ( $choice eq "video_dir" ) {
                my $info = "Video Directory\nNow: " . $opt->{$choice} // 'current directory';
                my $name = 'New: ';
                _opt_choose_a_directory( $opt, $choice, $info, $name );
            }
            elsif ( $choice eq "use_extractor_dir" ) {
                my $prompt = 'Use extractor directories';
                my $list = [ qw( no yes ) ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "use_uploader_dir" ) {
                my $prompt = 'Use uploader directories';
                my $list = [
                    'no',
                    'yes',
                    'if from list-menu',
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "useragent" ) {
                my $prompt = 'Set the UserAgent';
                my $list = [
                    [ 'UserAgent', $opt->{useragent} ]
                ];
                _local_readline( $opt, $choice, $prompt, $list );
                $opt->{useragent} = '' if $opt->{useragent} eq '""';
            }
            elsif ( $choice eq "quality" ) {
                my $prompt = 'Video resolution';
                my $list = [
                    ' 180 or less',
                    ' 360 or less',
                    ' 720 or less',
                    '1080 or less',
                    '1440 or less',
                    '2160 or less',
                    'manually',
                    ' 180 or better',
                    ' 360 or better',
                    ' 720 or better',
                    '1080 or better',
                    '1440 or better',
                    '2160 or better',
                    'best'
                ];
                _opt_choose_from_list_value( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "no_height_ok" ) {
                my $prompt = 'Download videos with unkown height';
                my $list = [
                    'no',
                    'yes'
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "retries" ) {
                my $digits = 3;
                my $info = sprintf "Download retries\nNow: %${digits}s", insert_sep( $opt->{$choice} );
                my $name = 'New: ';
                _opt_number_range( $opt, $choice, $name, $info, $digits );
            }
            elsif ( $choice eq "timeout" ) {
                my $digits = 3;
                my $info = sprintf "Connection timeout (s)\nNow: %${digits}s", insert_sep( $opt->{$choice} );
                my $name = 'New: ';
                _opt_number_range( $opt, $choice, $name, $info, $digits );
            }
            elsif ( $choice eq "no_warnings" ) {
                my $prompt = 'Disable youtube-dl warnings';
                my $list = [
                    'no',
                    'yes'
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "prefer_free_formats" ) {
                my $prompt = 'Prefer free formats';
                my $list = [
                    'no',
                    'yes'
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "max_size_history" ) {
                my $digits = 3;
                my $info = sprintf "Max size of history\nNow: %${digits}s", insert_sep( $opt->{$choice} );
                my $name = 'New: ';
                _opt_number_range( $opt, $choice, $name, $info, $digits );
            }
            elsif ( $choice eq "sort_history_by_timestamp" ) {
                my $prompt = 'Sort history by';
                my $list = [
                    'by name',
                    'by timestamp'
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "_type_listmenu" ) {
                my $sub_menu = _sub_menus( $choice );
                my $current = { map { $_->[0] => $opt->{$_->[0]} } @$sub_menu };
                my $prompt = 'Uploader/Playlist video list type';
                _opt_settings_menu( $opt, $sub_menu, $current, $prompt );
            }
            elsif ( $choice eq "list_sort_item" ) {
                set_sort_videolist( $opt );
            }
            elsif ( $choice eq "show_view_count" ) {
                my $prompt = 'Show view count in list-menus';
                my $list = [
                    'if sorted by "view count"',
                    'always',
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "max_info_width" ) {
                my $digits = 3;
                my $info = sprintf "Max Info width\nNow: %${digits}s", insert_sep( $opt->{$choice} );
                my $name = 'New: ';
                _opt_number_range( $opt, $choice, $name, $info, $digits );
            }
            elsif ( $choice eq "yt_dl_config_location" ) {
                my $info = "Youtube-dl Config File\nNow: ";
                if ( defined $opt->{$choice} ) {
                    $info .= $opt->{$choice};
                }
                else {
                    $info .= 'default (';
                    $info .= $^O eq 'MSWin32' ? "%APPDATA%/youtube-dl/config.txt" : "~/.config/youtube-dl/config";
                    $info .= ')';
                }
                my $name = 'New: ';
                _opt_choose_a_file( $opt, $choice, $info, $name );
            }
            elsif ( $choice eq "reset_yt_dl_config_location" ) {
                my $prompt = 'Reset the youtube-dl config location to default';
                my $list = [
                    'no',
                    'yes'
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
                if ( $opt->{reset_yt_dl_config_location} ) {
                    $opt->{yt_dl_config_location} = undef;
                    $opt->{reset_yt_dl_config_location} = 0;
                }
            }
            elsif ( $choice eq "yt_dl_ignore_config" ) {
                my $prompt = 'Ignore youtube-dl config file';
                my $list = [
                    'no',
                    'yes'
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            else { die $choice }
        }
    }
    return;
}


sub _opt_settings_menu {
    my ( $opt, $sub_menu, $current, $prompt ) = @_;
    my $changed = settings_menu( $sub_menu, $current, { prompt => $prompt } );
    return if ! $changed;
    for my $key ( keys %$current ) {
        $opt->{$key} = $current->{$key};
    }
    $opt->{change}++;
}


sub _opt_choose_a_directory {
    my( $opt, $choice, $info, $name ) = @_;
    my $new_dir = choose_a_dir( { dir => $opt->{$choice}, name => $name, info => $info } );
    return if ! defined $new_dir;
    if ( $new_dir ne $opt->{$choice} ) {
        if ( ! eval {
            my $fh = File::Temp->new( TEMPLATE => 'XXXXXXXXXXXXXXX', UNLINK => 1, DIR => $new_dir ); ##
            1 }
        ) {
            print "$@";
            choose( [ 'Press Enter:' ], { prompt => '' } );
        }
        else {
            $opt->{$choice} = $new_dir;
            $opt->{change}++;
        }
    }
}


sub _opt_choose_a_file {
    my( $opt, $choice, $info, $name ) = @_;
    my $file = choose_a_file( { name => $name, info => $info } );
    return if ! defined $file;
    $opt->{$choice} = $file;
    $opt->{change}++;
}


sub _local_readline {
    my ( $opt, $section, $prompt, $list ) = @_;
    my $trs = Term::Form->new();
    my $new_list = $trs->fill_form(
        $list,
        { prompt => $prompt, auto_up => 2, confirm => '  CONFIRM', back => '  BACK' }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$new_list ) {
            $opt->{$section} = $new_list->[$i][1];
        }
        $opt->{change}++;
    }
}


sub _opt_number_range {
    my ( $opt, $section, $name, $info, $digits ) = @_;
    # Choose_a_number
    my $choice = choose_a_number( $digits, { name => $name, info => $info } );
    return if ! defined $choice;
    $opt->{$section} = $choice eq '--' ? undef : $choice;
    $opt->{change}++;
    return;
}


sub _opt_choose_from_list_idx {
    my ( $opt, $section, $prompt, $list ) = @_;
    my $backup = $opt->{$section};
    my $confirm = '  CONFIRM';
    my @pre = ( undef, $confirm );
    my $choices = [ @pre, map { "- $_" } @$list ];
    while ( 1 ) {
        my $local_prompt = $prompt . ': [' . ( $list->[$opt->{$section}] // '--' ) . ']';
        my $idx = choose(
            $choices,
            { prompt => $local_prompt, layout => 3, undef => '  BACK', index => 1 }
        );
        if ( ! defined $idx || $idx == 0 ) {
            $opt->{$section} = $backup;
            return;
        }
        elsif ( $choices->[$idx] eq $confirm ) {
            $opt->{change}++;
            return;
        }
        else {
            $opt->{$section} = $idx - @pre;
        }
    }
}


sub _opt_choose_from_list_value {
    my ( $opt, $section, $prompt, $list ) = @_;
    my $backup = $opt->{$section};
    my $confirm = '  CONFIRM';
    my @pre = ( undef, $confirm );
    while ( 1 ) {
        my $local_prompt = $prompt . ': [' . ( $opt->{$section} // '--' ) . ']';
        my $choice = choose(
            [ @pre,  map { "- $_" } @$list ],
            { prompt => $local_prompt, layout => 3, undef => '  BACK', index => 0 }
        );
        if ( ! defined $choice ) {
            $opt->{$section} = $backup;
            return;
        }
        elsif ( $choice eq $confirm ) {
            $opt->{change}++;
            return;
        }
        else {
            $choice =~ s/^-\s//;
            $opt->{$section} = $choice;
        }
    }
}


sub _write_config_file {
    my ( $opt, $file, @keys ) = @_;
    return if ! $opt->{change};
    my $tmp = {};
    for my $section ( sort @keys ) {
        $tmp->{$section} = $opt->{$section};
    }
    write_json( $opt, $file, $tmp );
    delete $opt->{change};
}


sub read_config_file {
    my ( $opt, $file ) = @_;
    my $tmp = read_json( $opt, $file ) // {};
    my @keys = keys %$tmp;
    for my $section ( @keys ) {
        $opt->{$section} = $tmp->{$section} if defined $tmp->{$section};
    }
    return @keys;
}


1;


__END__
