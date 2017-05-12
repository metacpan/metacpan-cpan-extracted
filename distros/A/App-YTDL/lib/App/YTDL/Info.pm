package # hide from PAUSE
App::YTDL::Info;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( get_download_infos );

use File::Path            qw( make_path );
use File::Spec::Functions qw( catfile catdir );

use Encode::Locale     qw();
use List::MoreUtils    qw( none );
use Term::ANSIScreen   qw( :cursor :screen );
use Term::Choose       qw( choose );
use Term::Choose::Util qw( term_size );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::YTDL::Helper        qw( get_filename check_mapping_stdout encode_fs sanitize_for_path );
use App::YTDL::History       qw( add_uploader_to_history new_uploader_to_history_file );
use App::YTDL::InfoPrint     qw( linefolded_print_info );
use App::YTDL::Options       qw( set_options );
use App::YTDL::SelectQuality qw( fmt_quality set_preferred_qualities );



sub get_download_infos {
    my ( $opt, $info ) = @_;
    my ( $cols, $rows ) = term_size();
    print "\n\n\n", '=' x $cols, "\n\n", "\n" x $rows;
    print locate( 1, 1 ), cldown;
    say 'Dir  : ', $opt->{video_dir};
    say 'Agent: ', $opt->{useragent} // '';
    print "\n";
    my $count = 0;

    EXTRACTOR: for my $ex ( sort keys %$info ) {
        my @video_ids = sort {
               $info->{$ex}{$a}{playlist_id} cmp $info->{$ex}{$b}{playlist_id}
            || $info->{$ex}{$a}{uploader_id} cmp $info->{$ex}{$b}{uploader_id}
            || $info->{$ex}{$a}{upload_date} cmp $info->{$ex}{$b}{upload_date}
            || $info->{$ex}{$a}{title}       cmp $info->{$ex}{$b}{title}
        } keys %{$info->{$ex}};
        my $fmt_list;
        $opt->{up} = 0;

        VIDEO: while ( @video_ids ) {
            my $video_id = shift @video_ids;
            my $key_len = 13;
            my $print_array = linefolded_print_info( $opt, $info, $ex, $video_id, $key_len );
            if ( ! keys %{$info->{$ex}{$video_id}{fmt_to_info}} ) {
                delete $info->{$ex}{$video_id};
                if ( none { $video_id eq $_ } @{$opt->{error_get_download_infos}} ) {
                    push @{$opt->{error_get_download_infos}}, $video_id;
                }
                next VIDEO;
            }
            $count++;

            MENU: while ( 1 ) {
                print "\n";
                $opt->{up}++;
                print for @$print_array;
                $opt->{up} += @$print_array;
                print "\n";
                $opt->{up}++;
                $fmt_list = fmt_quality( $opt, $info, $fmt_list, $ex, $video_id );
                if ( ! defined $fmt_list ) {
                    my ( $delete, $append, $pref_qualities, $options, $quit ) = ( 'Delete', 'Append', 'Preferred qualities', 'Options', 'Quit' );
                    # Choose
                    my $choice = choose(
                        [ undef, $quit, $delete, $append, $pref_qualities, $options ],
                        { prompt => 'Your choice: ', default => 1, undef => 'Back' }
                    );
                    if ( ! defined $choice ) {
                        print up( $opt->{up} ), cldown;
                        $opt->{up} = 0;
                        next MENU;
                    }
                    elsif ( $choice eq $quit ) {
                        my $confirm = choose(
                            [ undef, '  Confirm QUIT' ],
                            { prompt => 'Your choice: ', default => 1, layout => 3, undef => '  MENU' }
                        );
                        if ( ! defined $confirm ) {
                            print up( $opt->{up} ), cldown;
                            $opt->{up} = 0;
                            next MENU;
                        }
                        else {
                            print locate( 1, 1 ), cldown;
                            say "Quit";
                            exit;
                        }
                    }
                    elsif ( $choice eq $delete ) {
                        delete $info->{$ex}{$video_id};
                        if ( ! @video_ids ) {
                            print up( 2 ), cldown;
                            print "\n";
                        }
                        print up( $opt->{up} ), cldown;
                        $opt->{up} = 0;
                        $count--;
                        next VIDEO;
                    }
                    elsif ( $choice eq $append ) {
                        push @video_ids, $video_id;
                        print up( $opt->{up} ), cldown;
                        $opt->{up} = 0;
                        $count--;
                        next VIDEO;
                    }
                    elsif ( $choice eq $pref_qualities ) {
                        set_preferred_qualities( $opt, $info, $ex, $video_id );
                        print up( $opt->{up} ), cldown;
                        $opt->{up} = 0;
                        next MENU;
                    }
                    elsif ( $choice eq $options ) {
                        set_options( $opt );
                        unshift @video_ids, $video_id;
                        print up( $opt->{up} ), cldown;
                        $opt->{up} = 0;
                        $count--;
                        next VIDEO;
                    }
                }
                else {
                    last MENU;
                }
            }
            print up( $opt->{up} ), cldown;
            $opt->{up} = 0;
            my $video_dir = $opt->{video_dir};
            if ( $opt->{extractor_dir} ) {
                my $extractor_dir = sanitize_for_path( $opt, $ex );
                $video_dir = catdir $video_dir, $extractor_dir;
                make_path encode_fs( $opt, $video_dir );
            }
            if ( $opt->{uploader_dir} == 2 || $opt->{uploader_dir} == 1 && $info->{$ex}{$video_id}{from_list} ) {
                if ( length $info->{$ex}{$video_id}{uploader} ) {
                    my $name_uploader = sanitize_for_path( $opt, $info->{$ex}{$video_id}{uploader} );
                    $video_dir = catdir $video_dir, $name_uploader;
                    make_path encode_fs( $opt, $video_dir );
                }
            }
            $info->{$ex}{$video_id}{video_dir} = $video_dir;
            printf "%*.*s : %s\n", $key_len, $key_len, 'video', $count;
            my $joined_fmts = sprintf " (%s)\n", join ' + ', @$fmt_list;
            ( $joined_fmts ) = check_mapping_stdout( $opt, $joined_fmts );
            $print_array->[0] =~ s/\n\z//;
            $print_array->[0] .= $joined_fmts;
            print for @$print_array;
            print "\n";
            for my $fmt ( @$fmt_list ) {
                $info->{$ex}{$video_id}{video_url}{$fmt} = $info->{$ex}{$video_id}{fmt_to_info}{$fmt}{url};
                my $title = $info->{$ex}{$video_id}{title_filename};
                my $ext   = $info->{$ex}{$video_id}{fmt_to_info}{$fmt}{ext};
                $info->{$ex}{$video_id}{file_name}{$fmt} = catfile( $video_dir, get_filename( $opt, $title, $ext, $fmt ) );
                $info->{$ex}{$video_id}{count} = $count;
                $opt->{nr_videos}++;

            }
            add_uploader_to_history( $opt, $info, $ex, $video_id ) if $opt->{max_size_history};
        }
    }
    print "\n";
    new_uploader_to_history_file( $opt ) if $opt->{max_size_history};
    if ( ! $opt->{nr_videos} ) {
        print locate( 1, 1 ), cldown;
        say "No videos";
        exit;
    }
    #return $opt, $info;
    return;
}



1;


__END__
