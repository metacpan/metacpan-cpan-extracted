package # hide from PAUSE
App::YTDL::Video_Info;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( print_video_infos );

use List::MoreUtils        qw( none );
use Term::ANSIScreen       qw( :cursor :screen );
use Term::Choose::LineFold qw( line_fold print_columns cut_to_printwidth );
use Term::Choose::Util     qw( get_term_size );

use App::YTDL::GetData     qw( get_download_info );
use App::YTDL::ExtractData qw( extract_data_single );


sub print_video_infos {
    my ( $set, $opt, $data, $chosen ) = @_;
    if ( ! %$data ) {
        return;
    }
    my ( $cols, $rows ) = get_term_size();
    print "\n\n\n\n", '=' x $cols, "\n\n", "\n" x $rows;
    print locate( 1, 1 ), cldown;
    say 'Quality: ', $opt->{quality};
    say 'Agent  : ', $opt->{useragent} if $opt->{useragent};
    print "\n";
    my $count = 0;

    EXTRACTOR_KEY: for my $ex ( sort keys %$data ) {

        UPLOADER_ID: for my $up ( sort keys %{$data->{$ex}} ) {

            VIDEO_ID: for my $id ( @{$chosen->{$ex}{$up}} ) {
                $count++;
                my $key_len = 12;
                $data->{$ex}{$up}{$id}{count} = $count;
                my @print_array = _linefolded_print_info( $set, $opt, $data, $ex, $up, $id, $key_len );
                print "\r", clline;
                printf "%*.*s : %s\n", $key_len, $key_len, 'video', $count;
                say for @print_array;
                print "\n";
            }
        }
    }
    #print "\n";
    if ( $count == 0 ) {
        print cls;
    }
    return;
}


sub _prepare_print_info {
    my ( $set, $opt, $data, $ex, $up, $id ) = @_;
    my @keys = qw(title author duration raters avg_rating view_count published id_extractor description);
    if ( ! exists $data->{$ex}{$up}{$id}{fmt_to_info} ) {
        my $url = $data->{$ex}{$up}{$id}{url};
        print "\r** GET video data: ... ";
        my $h_ref;
        if ( eval { $h_ref = get_download_info( $set, $opt, $url, 0 ); 1 } ) {
            my $single_data = extract_data_single( $set, $opt, $h_ref );
            for my $key ( keys %$single_data ) {
                $data->{$ex}{$up}{$id}{$key} = $single_data->{$key};
            }
        }
        else {
            $data->{$ex}{$up}{$id}{description} = $set->{failed_fetching_data};
        }
    }
    $data->{$ex}{$up}{$id}{published}    = $data->{$ex}{$up}{$id}{upload_date}           if defined $data->{$ex}{$up}{$id}{upload_date};
    $data->{$ex}{$up}{$id}{author}       = $data->{$ex}{$up}{$id}{uploader}              if defined $data->{$ex}{$up}{$id}{uploader};
    $data->{$ex}{$up}{$id}{avg_rating}   = $data->{$ex}{$up}{$id}{average_rating}        if defined $data->{$ex}{$up}{$id}{average_rating};
    $data->{$ex}{$up}{$id}{id_extractor} = $id . ' ' . $data->{$ex}{$up}{$id}{extractor} if defined $data->{$ex}{$up}{$id}{extractor};
    for my $key ( @keys ) {
        next if ! $data->{$ex}{$up}{$id}{$key};
        $data->{$ex}{$up}{$id}{$key} =~ s/\R/ /g;
    }
    return @keys;
}


sub _linefolded_print_info {
    my ( $set, $opt, $data, $ex, $up, $id, $key_len ) = @_;
    my @keys = _prepare_print_info( $set, $opt, $data, $ex, $up, $id );
    my $s_tab = $key_len + length( ' : ' );
    my ( $maxcols, $maxrows ) = get_term_size();
    $maxcols -= $set->{right_margin};
    my $col_max = $maxcols > $opt->{max_info_width} ? $opt->{max_info_width} : $maxcols;
    my @print_array = ();
    for my $key ( @keys ) {
        next if ! length $data->{$ex}{$up}{$id}{$key};
        $data->{$ex}{$up}{$id}{$key} =~ s/\n+/\n/g;
        $data->{$ex}{$up}{$id}{$key} =~ s/^\s+//;
        $data->{$ex}{$up}{$id}{$key} =~ s/\s+\z//;
        ( my $kk = $key ) =~ s/_/ /g;
        my $pr_key = sprintf "%*.*s : ", $key_len, $key_len, $kk;
        my @folded = line_fold(
            $pr_key . $data->{$ex}{$up}{$id}{$key},
            $col_max,
            { init_tab => '' , subseq_tab => ' ' x $s_tab, join => 0 }
        );
        if ( $key eq 'description' ) {
            if ( $opt->{max_rows_description} && @folded > $opt->{max_rows_description} ) {
                splice @folded, $opt->{max_rows_description};
                if ( print_columns( $folded[-1] ) > $col_max - 4 ) {
                    $folded[-1] =~ s/(?<=\s)\S+\s*\z//;
                    $folded[-1] .= '...';
                }
                else {
                    $folded[-1] .= $folded[-1] =~ /\s\z/ ? '...' : ' ...';
                }
            }
        }
        push @print_array, @folded;
    }
    return () if ! @print_array;
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
            next if ! length $data->{$ex}{$up}{$id}{$key};
            ( my $kk = $key ) =~ s/_/ /g;
            my $pr_key = sprintf "%*.*s : ", $key_len, $key_len, $kk;
            push @print_array, line_fold(
                $pr_key . $data->{$ex}{$up}{$id}{$key},
                $col_max,
                { init_tab => '' , subseq_tab => ' ' x $s_tab, join => 0 }
            );
        }
    }
    if ( @print_array > ( $maxrows - 6 ) ) {
        $col_max = $maxcols;
        @print_array = ();
        for my $key ( @keys ) {
            next if ! length $data->{$ex}{$up}{$id}{$key};
            ( my $kk = $key ) =~ s/_/ /g;
            my $pr_key = sprintf "%*.*s : ", $key_len, $key_len, $kk;
            push @print_array, line_fold(
                $pr_key . $data->{$ex}{$up}{$id}{$key},
                $col_max,
                { init_tab => '' , subseq_tab => ' ' x $s_tab, join => 0 }
            );
        }
    }
    return @print_array;
}




1;


__END__
