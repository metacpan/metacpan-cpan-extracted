package # hide from PAUSE
App::YTDL::Video_Info;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( gather_video_infos );

use List::MoreUtils        qw( none );
use Term::ANSIScreen       qw( :cursor :screen );
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( get_term_size );

use App::YTDL::GetData qw( get_download_info );


sub gather_video_infos {
    my ( $set, $opt, $data ) = @_;
    my ( $cols, $rows ) = get_term_size();
    print "\n\n\n", '=' x $cols, "\n\n", "\n" x $rows;
    print locate( 1, 1 ), cldown;
    say 'Quality: ', $opt->{quality};
    say 'Agent  : ', $opt->{useragent} if defined $opt->{useragent}; ##
    print "\n";
    my $count = 0;

    EXTRACTOR: for my $ex ( sort keys %$data ) {
        my @video_ids = sort {
               ( $data->{$ex}{$a}{playlist_id} // '' ) cmp ( $data->{$ex}{$b}{playlist_id} // '' )
            || ( $data->{$ex}{$a}{uploader_id} // '' ) cmp ( $data->{$ex}{$b}{uploader_id} // '' )
            || ( $data->{$ex}{$a}{upload_date} // '' ) cmp ( $data->{$ex}{$b}{upload_date} // '' )
            || ( $data->{$ex}{$a}{title}       // '' ) cmp ( $data->{$ex}{$b}{title}       // '' )
        } keys %{$data->{$ex}};
        $set->{up} = 0;

        VIDEO: while ( @video_ids ) {
            my $video_id = shift @video_ids;
            my $key_len = 12;
            $count++;
            $data->{$ex}{$video_id}{count} = $count;
            my @print_array = _linefolded_print_info( $set, $opt, $data, $ex, $video_id, $key_len );
            print "\n";
            $set->{up}++;
            say for @print_array;
            $set->{up} += @print_array;
            print "\n";
            $set->{up}++;
            print up( $set->{up} ), cldown;
            $set->{up} = 0;
            printf "%*.*s : %s\n", $key_len, $key_len, 'video', $count;
            say for @print_array;
            print "\n";
        }
    }
    print "\n";
    return;
}


sub _download_info {
    my ( $set, $opt, $data, $ex, $video_id ) = @_;
    return if $data->{$ex}{$video_id}{fmt_to_info};
    my $webpage_url = $data->{$ex}{$video_id}{webpage_url};
    my $message     = "** GET download info: ";
    my $tmp = get_download_info( $set, $opt, $webpage_url, $message ); ##
    for my $video_id ( keys %{$tmp->{$ex}} ) {
        for my $key ( keys %{$tmp->{$ex}{$video_id}} ) {
            $data->{$ex}{$video_id}{$key} = $tmp->{$ex}{$video_id}{$key};
        }
    }
}


sub _prepare_print_info {
    my ( $set, $opt, $data, $ex, $video_id ) = @_;
    _download_info( $set, $opt, $data, $ex, $video_id );
    $data->{$ex}{$video_id}{published}  = $data->{$ex}{$video_id}{upload_date};
    $data->{$ex}{$video_id}{author}     = $data->{$ex}{$video_id}{uploader};
    $data->{$ex}{$video_id}{avg_rating} = $data->{$ex}{$video_id}{average_rating};
    if ( length $data->{$ex}{$video_id}{author} && length $data->{$ex}{$video_id}{uploader_id} ) {
        if ( $data->{$ex}{$video_id}{author} ne $data->{$ex}{$video_id}{uploader_id} ) {
            $data->{$ex}{$video_id}{author} .= ' (' . $data->{$ex}{$video_id}{uploader_id} . ')';
        }
    }
    my @keys = ( 'title', 'video_id' );
    push @keys, 'extractor'                                    if $ex ne 'youtube';
    push @keys, 'author', 'duration', 'raters', 'avg_rating';
    push @keys, 'view_count'                                   if $data->{$ex}{$video_id}{view_count};
    push @keys, 'published'                                    if $data->{$ex}{$video_id}{upload_date} ne '0000-00-00';
    push @keys, 'description'; # categories
    for my $key ( @keys ) {
        next if ! $data->{$ex}{$video_id}{$key};
        $data->{$ex}{$video_id}{$key} =~ s/\R/ /g;
    }
    return @keys;
}


sub _linefolded_print_info {
    my ( $set, $opt, $data, $ex, $video_id, $key_len ) = @_;
    my @keys = _prepare_print_info( $set, $opt, $data, $ex, $video_id );
    my $s_tab = $key_len + length( ' : ' );
    my ( $maxcols, $maxrows ) = get_term_size();
    $maxcols -= $set->{right_margin};
    my $col_max = $maxcols > $opt->{max_info_width} ? $opt->{max_info_width} : $maxcols;
    my @print_array = ();
    for my $key ( @keys ) {
        next if ! length $data->{$ex}{$video_id}{$key};
        $data->{$ex}{$video_id}{$key} =~ s/\n+/\n/g;
        $data->{$ex}{$video_id}{$key} =~ s/^\s+//;
        ( my $kk = $key ) =~ s/_/ /g;
        my $pr_key = sprintf "%*.*s : ", $key_len, $key_len, $kk;
        push @print_array, line_fold(
            $pr_key . $data->{$ex}{$video_id}{$key},
            $col_max,
            { init_tab => '' , subseq_tab => ' ' x $s_tab, join => 0 }
        );
    }
    return @print_array if ! @print_array;
    # auto width:
    my $ratio = @print_array / $maxrows;
    my $begin = 0.70;
    my $end   = 1.50;
    my $step  = 0.0125;
    my $div   = ( $end - $begin ) / $step + 1;
    my $plus;
    if ( $ratio >= $begin ) {
        $ratio = $end if $ratio > $end;
        $plus = int( ( ( $maxcols - $col_max ) / $div ) * ( ( $ratio - $begin  ) / $step + 1 ) );
    }
    if ( $plus ) {
        $col_max += $plus;
        @print_array = ();
        for my $key ( @keys ) {
            next if ! length $data->{$ex}{$video_id}{$key};
            ( my $kk = $key ) =~ s/_/ /g;
            my $pr_key = sprintf "%*.*s : ", $key_len, $key_len, $kk;
            push @print_array, line_fold(
                $pr_key . $data->{$ex}{$video_id}{$key},
                $col_max,
                { init_tab => '' , subseq_tab => ' ' x $s_tab, join => 0 }
            );
        }
    }
    if ( @print_array > ( $maxrows - 6 ) ) {
        $col_max = $maxcols;
        @print_array = ();
        for my $key ( @keys ) {
            next if ! length $data->{$ex}{$video_id}{$key};
            ( my $kk = $key ) =~ s/_/ /g;
            my $pr_key = sprintf "%*.*s : ", $key_len, $key_len, $kk;
            push @print_array, line_fold(
                $pr_key . $data->{$ex}{$video_id}{$key},
                $col_max,
                { init_tab => '' , subseq_tab => ' ' x $s_tab, join => 0 }
            );
        }
    }
    return @print_array;
}




1;


__END__
