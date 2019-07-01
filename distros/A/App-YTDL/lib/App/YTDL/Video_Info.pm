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
use Term::Choose           qw( choose );
use Term::Choose::Util     qw( term_size );

use App::YTDL::GetData qw( get_download_info );


sub gather_video_infos {
    my ( $opt, $info ) = @_;
    my ( $cols, $rows ) = term_size();
    print "\n\n\n", '=' x $cols, "\n\n", "\n" x $rows;
    print locate( 1, 1 ), cldown;
    say 'Quality: ', $opt->{quality};
    say 'Agent  : ', $opt->{useragent} if defined $opt->{useragent}; ##
    print "\n";
    my $count = 0;

    EXTRACTOR: for my $ex ( sort keys %$info ) {
        my @video_ids = sort {
               $info->{$ex}{$a}{playlist_id} cmp $info->{$ex}{$b}{playlist_id}
            || $info->{$ex}{$a}{uploader_id} cmp $info->{$ex}{$b}{uploader_id}
            || $info->{$ex}{$a}{upload_date} cmp $info->{$ex}{$b}{upload_date}
            || $info->{$ex}{$a}{title}       cmp $info->{$ex}{$b}{title}
        } keys %{$info->{$ex}};
        $opt->{up} = 0;

        VIDEO: while ( @video_ids ) {
            my $video_id = shift @video_ids;
            my $key_len = 12;
            $count++;
            $info->{$ex}{$video_id}{count} = $count;
            my $print_array = linefolded_print_info( $opt, $info, $ex, $video_id, $key_len );
            print "\n";
            $opt->{up}++;
            print for @$print_array;
            $opt->{up} += @$print_array;
            print "\n";
            $opt->{up}++;
            print up( $opt->{up} ), cldown;
            $opt->{up} = 0;
            printf "%*.*s : %s\n", $key_len, $key_len, 'video', $count;
            print for @$print_array;
            print "\n";
        }
    }
    print "\n";
    return;
}


sub _download_info {
    my ( $opt, $info, $ex, $video_id ) = @_;
    return if $info->{$ex}{$video_id}{fmt_to_info};
    my $webpage_url = $info->{$ex}{$video_id}{webpage_url};
    my $message     = "** GET download info: ";
    my $tmp = get_download_info( $opt, $webpage_url, $message ); ##
    for my $video_id ( keys %{$tmp->{$ex}} ) {
        for my $key ( keys %{$tmp->{$ex}{$video_id}} ) {
            $info->{$ex}{$video_id}{$key} = $tmp->{$ex}{$video_id}{$key};
        }
    }
}


sub _prepare_print_info {
    my ( $opt, $info, $ex, $video_id ) = @_;
    _download_info( $opt, $info, $ex, $video_id );
    $info->{$ex}{$video_id}{published}  = $info->{$ex}{$video_id}{upload_date};
    $info->{$ex}{$video_id}{author}     = $info->{$ex}{$video_id}{uploader};
    $info->{$ex}{$video_id}{avg_rating} = $info->{$ex}{$video_id}{average_rating};
    if ( length $info->{$ex}{$video_id}{author} && length $info->{$ex}{$video_id}{uploader_id} ) {
        if ( $info->{$ex}{$video_id}{author} ne $info->{$ex}{$video_id}{uploader_id} ) {
            $info->{$ex}{$video_id}{author} .= ' (' . $info->{$ex}{$video_id}{uploader_id} . ')';
        }
    }
    my @keys = ( 'title', 'video_id' );
    push @keys, 'extractor'                                    if $ex ne 'youtube';
    push @keys, 'author', 'duration', 'raters', 'avg_rating';
    push @keys, 'view_count'                                   if $info->{$ex}{$video_id}{view_count};
    push @keys, 'published'                                    if $info->{$ex}{$video_id}{upload_date} ne '0000-00-00';
    push @keys, 'description'; # categories
    for my $key ( @keys ) {
        next if ! $info->{$ex}{$video_id}{$key};
        $info->{$ex}{$video_id}{$key} =~ s/\R/ /g;
    }
    return @keys;
}


sub linefolded_print_info {
    my ( $opt, $info, $ex, $video_id, $key_len ) = @_;
    my @keys = _prepare_print_info( $opt, $info, $ex, $video_id );
    my $s_tab = $key_len + length( ' : ' );
    my ( $maxcols, $maxrows ) = term_size();
    $maxcols -= $opt->{right_margin};
    my $col_max = $maxcols > $opt->{max_info_width} ? $opt->{max_info_width} : $maxcols;
    my $print_array = [];
    for my $key ( @keys ) {
        next if ! length $info->{$ex}{$video_id}{$key};
        $info->{$ex}{$video_id}{$key} =~ s/\n+/\n/g;
        $info->{$ex}{$video_id}{$key} =~ s/^\s+//;
        ( my $kk = $key ) =~ s/_/ /g;
        my $pr_key = sprintf "%*.*s : ", $key_len, $key_len, $kk;
        my $text = line_fold(
            $pr_key . $info->{$ex}{$video_id}{$key},
            $col_max,
            { init_tab => '' , subseq_tab => ' ' x $s_tab }
        );
        $text =~ s/\R+\z//;
        push @$print_array, map { "$_\n" } split /\R+/, $text;
    }
    return $print_array if ! @$print_array;
    # auto width:
    my $ratio = @$print_array / $maxrows;
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
        $print_array = [];
        for my $key ( @keys ) {
            next if ! length $info->{$ex}{$video_id}{$key};
            ( my $kk = $key ) =~ s/_/ /g;
            my $pr_key = sprintf "%*.*s : ", $key_len, $key_len, $kk;
            my $text = line_fold(
                $pr_key . $info->{$ex}{$video_id}{$key},
                $col_max,
                { init_tab => '' , subseq_tab => ' ' x $s_tab }
            );
            $text =~ s/\R+\z//;
            push @$print_array, map { "$_\n" } split /\R+/, $text;
        }
    }
    if ( @$print_array > ( $maxrows - 6 ) ) {
        $col_max = $maxcols;
        $print_array = [];
        for my $key ( @keys ) {
            next if ! length $info->{$ex}{$video_id}{$key};
            ( my $kk = $key ) =~ s/_/ /g;
            my $pr_key = sprintf "%*.*s : ", $key_len, $key_len, $kk;
            my $text = line_fold(
                $pr_key . $info->{$ex}{$video_id}{$key},
                $col_max,
                { init_tab => '' , subseq_tab => ' ' x $s_tab }
            );
            $text =~ s/\R+\z//;
            push @$print_array, map { "$_\n" } split /\R+/, $text;
        }
    }
    return $print_array;
}




1;


__END__
