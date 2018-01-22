package # hide from PAUSE
App::YTDL::Options;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( read_config_file set_options );

use File::Spec::Functions qw( catfile );
use File::Temp            qw();
use FindBin               qw( $RealBin $RealScript );
use Pod::Usage            qw( pod2usage );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( print_hash choose_a_dir choose_a_number settings_menu insert_sep );
use Term::Form         qw();

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::YTDL::ChooseVideos qw( set_sort_videolist );
use App::YTDL::Helper       qw( write_json read_json uni_capture HIDE_CURSOR SHOW_CURSOR );



sub _show_info {
    my ( $opt ) = @_;
    my ( $youtube_dl_version, $ffmpeg_version, $ffprobe_version );
    if ( ! eval { $youtube_dl_version = uni_capture( $opt->{youtube_dl}, '--version' ); 1 } ) {
        $youtube_dl_version = $@;
    }
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
    my $version     = '  version  ';
    my $bin         = '    bin    ';
    my $video_dir   = ' video dir ';
    my $config_dir  = 'config dir ';
    my $archive_dir = 'archive dir';
    my $youtube_dl  = 'youtube-dl ';
    my $ffmpeg      = '  ffmpeg   ';
    my $ffprobe     = '  ffprobe  ';
    my $path = {
        $version     => $main::VERSION,
        $bin         => catfile( $RealBin, $RealScript ),
        $video_dir   => $opt->{video_dir},
        $config_dir  => $opt->{config_dir},
        $archive_dir => $opt->{archive_dir},
        $youtube_dl  => $youtube_dl_version // 'error',
        $ffmpeg      => $ffmpeg_version,
        $ffprobe     => $ffprobe_version,
    };
    my $keys = [ $bin, $version, $video_dir, $config_dir, $archive_dir, $youtube_dl ];
    push @$keys, $ffmpeg  if $ffmpeg_version;
    push @$keys, $ffprobe if $ffprobe_version;
    print_hash( $path, { keys => $keys, preface => ' Close with ENTER' } );
}


sub _menus {
    my $menus = {
        main => [
            [ 'show_help_text',   "  HELP"       ],
            [ 'show_info',        "  INFO"       ],
            [ 'group_directory',  "- Directory"  ],
            [ 'group_file',       "- File"       ],
            [ 'group_quality',    "- Quality"    ],
            [ 'group_download',   "- Download"   ],
            [ 'group_merge',      "- Merge"      ],
            [ 'group_history',    "- History"    ],
            [ 'group_list_menu',  "- Video List" ],
            [ 'group_output',     "- Output"     ],
            [ 'group_youtube_dl', "- Youtube-dl" ],
        ],
        group_directory => [
            [ 'video_dir',     "- Main video directory" ],
            [ 'extractor_dir', "- Extractor directory"  ],
            [ 'uploader_dir',  "- Uploader directory"   ],
        ],
        group_file => [
            [ 'max_len_f_name',      "- Max filename length" ],
            [ 'replace_spaces',      "- Replace spaces"      ],
            [ 'sanitize_filename',   "- Sanitize filename"   ],
            [ 'unmappable_filename', "- Encode filename"     ],
            [ 'modify_timestamp',    "- File timestamp"      ],
        ],
        group_quality => [
            [ 'auto_quality',     "- Set auto-quality mode"    ],
            [ 'pref_qual_slots',  "- Number of slots"          ],
            [ '_print_pref_qual', "  Preferred qualities" ],
        ],
        group_download => [
            [ 'useragent',            "- UserAgent"            ],
            [ 'skip_archived_videos', "- Skip archived videos" ],
            [ 'overwrite',            "- Overwrite"            ],
            [ 'retries',              "- Download retries"     ],
            [ 'timeout',              "- Timeout"              ],
        ],
        group_merge => [
            [ 'merge_enabled',   "- Enable Merge"      ],
            [ 'merge_overwrite', "- ffmpeg overwrites" ],
            [ 'merge_ext',       "- Output formats"    ],
            [ 'merge_loglevel',  "- Verbosity"         ],
            [ 'merged_in_files', "- Input files"       ],
        ],
        group_history => [
            [ 'max_size_history',          "- Size history"     ],
            [ 'sort_history_by_timestamp', "- History sort"     ],
            [ 'enable_download_archive',   "- Download archive" ],
        ],

        group_list_menu => [
            [ '_fast_listmenu',  "- Fast list-menu"  ],
            [ 'small_list_size', "- List size"       ],
            [ 'list_sort_item',  "- Sort order"      ],
            [ 'show_view_count', "- Show view count" ],
        ],
        group_output => [
            [ 'text_unidecode', "- Unmappable infotext" ],
            [ 'max_info_width', "- Max info width"    ],
        ],
        group_youtube_dl => [
            [ 'use_netrc',         "- Use '.netrc'" ],
            [ '_avail_extractors', "  Extractors"        ],
        ],
    };
    return $menus;
}


sub _sub_menus {
    my ( $key ) = @_;
    my $sub_menus = {
        _fast_listmenu => [
            [ 'fast_list_vimeo',   "- vimeo",   [ 'NO', 'YES' ] ],
            [ 'fast_list_youtube', "- youtube", [ 'NO', 'YES' ] ],
        ],
    };
    return $sub_menus->{$key} if $key;
    return $sub_menus;
}


sub _group_prompt {
    my ( $group ) = @_;
    my $group_prompt ={
        group_directory => "Directories:",
        group_file      => "Files:",
        group_quality   => "Quality:",
        group_download  => "Download:",
        group_merge     => "Merge:",
        group_history   => "History:",
        group_list_menu => "List menu:",
        group_output    => "Appearance:",
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
    #for my $key ( %$sub_menus ) {
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
                print HIDE_CURSOR;
                say 'Close with ENTER';
                my @capture;
                if ( ! eval { @capture = uni_capture( $opt->{youtube_dl}, '--list-extractors' ); 1 } ) {
                    say "List extractors: $@";
                }
                print SHOW_CURSOR;
                if ( @capture ) {
                    choose(
                        [ map { "  $_" } @capture ],
                        { layout => 3 }
                    );
                }
            }
            elsif ( $choice eq "video_dir" ) {
                my $prompt = 'Video directory';
                _opt_choose_a_directory( $opt, $choice, $prompt );
            }
            elsif ( $choice eq "extractor_dir" ) {
                my $prompt = 'Use extractor directories';
                my $list = [ qw( no yes ) ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "uploader_dir" ) {
                my $prompt = 'Use uploader directories';
                my $list = [
                    'no',
                    'if from list-menu', #
                    'always',
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "max_len_f_name" ) {
                my $prompt = 'Max filename length';
                my $digits = 3;
                _opt_number_range( $opt, $choice, $prompt, $digits );
            }
            elsif ( $choice eq "replace_spaces" ) {
                my $prompt = 'Replace spaces in filenames';
                my $list = [ qw( no yes ) ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "sanitize_filename" ) {
                my $prompt = 'Sanitize filenames';
                my $list = [
                    'keep all',
                    'replace  / \ : " * ? < > | &',
                    'replace  /',
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "unmappable_filename" ) {
                my $prompt = 'Filename not mappable to file system encoding';
                my $list = [
                    'don\'t encode',
                    'use Text::Unidecode',
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "modify_timestamp" ) {
                my $prompt = 'Timestamp to upload date';
                my $list = [ qw( no yes ) ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "auto_quality" ) {
                my $prompt = 'Auto quality';
                my $list = [
                    'manually',
                    'keep_uploader_playlist',
                    'keep_extractor',
                    'preferred',
                    'default',
                ];
                _opt_choose_from_list_value( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "_print_pref_qual" ) {
                my $pref = read_json( $opt, $opt->{preferred_file} ) // {};
                if ( ! %$pref ) {
                    choose( [ 'Close with ENTER' ], { prompt => 'No preferred qualities set.' } );
                }
                else {
                    my @p = ( ' ' );
                    for my $key ( sort keys %$pref ) {
                        push @p, "$key:";
                        my $c = 1;
                        push @p, map { sprintf "%4d. [%s]\n", $c++, join ',', @$_ } @{$pref->{$key}};
                        push @p, ' ';
                    }
                    choose( \@p, { prompt => 'Close with ENTER', layout => 3, justify => 0 } );
                }
            }
            elsif ( $choice eq "pref_qual_slots" ) {
                my $prompt = 'Slots \'preferred qualilties\'';
                my $digits = 2;
                _opt_number_range( $opt, $choice, $prompt, $digits );
            }
            elsif ( $choice eq "useragent" ) {
                my $prompt = 'Set the UserAgent';
                my $list = [
                    [ 'UserAgent', $opt->{useragent} ]
                ];
                _local_readline( $opt, $choice, $prompt, $list );
                $opt->{useragent} = 'Mozilla/5.0' if $opt->{useragent} eq '';
                $opt->{useragent} = ''            if $opt->{useragent} eq '""';
            }
            elsif ( $choice eq "skip_archived_videos" ) {
                my $prompt = 'Skip archived videos';
                my $list = [ qw( no yes ) ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "overwrite" ) {
                my $prompt = 'Overwrite files';
                my $list = [
                    'no (append)',
                    'yes'
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "retries" ) {
                my $prompt = 'Download retries';
                my $digits = 3;
                _opt_number_range( $opt, $choice, $prompt, $digits );
            }
            elsif ( $choice eq "timeout" ) {
                my $prompt = 'Connection timeout (s)';
                my $digits = 3;
                _opt_number_range( $opt, $choice, $prompt, $digits );
            }
            elsif ( $choice eq "merge_enabled" ) {
                my $prompt = 'Enable merge';
                my $list = [ qw( no ask yes ) ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "merge_overwrite" ) {
                my $prompt = '\'ffmpeg\' - overwrite files';
                my $list = [ qw( ask yes ) ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "merge_ext" ) {
                my $prompt = 'Output format of merged files';
                my $list = [ qw( mkv mp4 ogg webm flv ) ];
                _opt_choose_from_list_value( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "merge_loglevel" ) {
                my $prompt = '\'ffmpeg\' verbosity';
                my $list = [ qw( error warning info ) ];
                _opt_choose_from_list_value( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "merged_in_files" ) {
                my $prompt = 'The merged input files:';
                my $list = [
                    'keep',
                    'move to "' . $opt->{dir_stream_files} . '"',
                    'remove'
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "max_size_history" ) {
                my $prompt = 'Max size of history';
                my $digits = 3;
                _opt_number_range( $opt, $choice, $prompt, $digits );
            }
            elsif ( $choice eq "sort_history_by_timestamp" ) {
                my $prompt = 'Sort history by';
                my $list = [
                    'by name',
                    'by timestamp'
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "enable_download_archive" ) {
                my $prompt = 'Enable downlaod archive';
                my $list = [ qw( no yes more ) ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "_fast_listmenu" ) {
                my $sub_menu = _sub_menus( $choice );
                my $current = { map { $_->[0] => $opt->{$_->[0]} } @$sub_menu };
                my $prompt = 'Enable fast list-menu for';
                _opt_settings_menu( $opt, $sub_menu, $current, $prompt );
            }
            elsif ( $choice eq "small_list_size" ) {
                my $prompt = 'Videos in list-menu';
                my $list = [
                    'all',
                    'latest',
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
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
            elsif ( $choice eq "text_unidecode" ) {
                my $prompt = 'Characters not mappable to console out';
                my $list = [
                    'replace with *',
                    'use Text::Unidecode',
                ];
                _opt_choose_from_list_idx( $opt, $choice, $prompt, $list );
            }
            elsif ( $choice eq "max_info_width" ) {
                my $prompt = 'Max Info width';
                my $digits = 3;
                _opt_number_range( $opt, $choice, $prompt, $digits );
            }
            elsif ( $choice eq "use_netrc" ) {
                my $prompt = 'Enable the option --netrc for youtube-dl';
                my $list = [ qw( no yes ) ];
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
    my( $opt, $choice, $prompt ) = @_;
    my $new_dir = choose_a_dir( { dir => $opt->{$choice} } );
    return if ! defined $new_dir;
    if ( $new_dir ne $opt->{$choice} ) {
        if ( ! eval {
            my $fh = File::Temp->new( TEMPLATE => 'XXXXXXXXXXXXXXX', UNLINK => 1, DIR => $new_dir );
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
    my ( $opt, $section, $prompt, $digits ) = @_;
    my $current = $opt->{$section};
    $current = insert_sep( $current );
    # Choose_a_number
    my $choice = choose_a_number( $digits, { name => "\"$prompt\"", current => $current } );
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
        $opt->{$section} = $tmp->{$section};
    }
    return @keys;
}


1;


__END__
