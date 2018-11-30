package # hide from PAUSE
App::YTDL::ChooseVideos;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( choose_videos set_sort_videolist );

use Encode qw( decode );

use Encode::Locale  qw();
use List::MoreUtils qw( any none );
use Term::Choose    qw( choose );
use Term::Form      qw();


sub _my_sort {
    my ( $sort_item, $sort_order, $h_ref, $a, $b ) = @_;
    my @s = $sort_order eq 'Asc'
                ? ( $h_ref->{$a}{$sort_item}, $h_ref->{$b}{$sort_item} )
                : ( $h_ref->{$b}{$sort_item}, $h_ref->{$a}{$sort_item} );
    if ( $sort_item eq 'view_count_raw' || $sort_item eq 'date_sort' ) {
       $s[0] <=> $s[1] || $h_ref->{$a}{title} cmp $h_ref->{$b}{title};
    }
    else {
       $s[0] cmp $s[1] || $h_ref->{$a}{title} cmp $h_ref->{$b}{title};
   }
}


sub choose_videos {
    my ( $opt, $info, $tmp, $ex, $prompt ) = @_;
    my $length_view_count  = 0;
    my $length_video_id    = 0;
    my $length_upload_date = 0;
    my $has_date_sort      = 0;
    my $has_view_count     = 0;
    my $has_duration       = 0;
    for my $video_id ( keys %{$tmp->{$ex}} ) {
        $has_duration++   if $tmp->{$ex}{$video_id}{duration} ne '-:--:--';
        $has_date_sort++  if $tmp->{$ex}{$video_id}{date_sort};
        $has_view_count++ if $tmp->{$ex}{$video_id}{view_count};
        $length_video_id    = length $video_id                           if length $video_id > $length_video_id;
        $length_view_count  = length $tmp->{$ex}{$video_id}{view_count}  if length $tmp->{$ex}{$video_id}{view_count} > $length_view_count;
        $length_upload_date = length $tmp->{$ex}{$video_id}{upload_date} if length $tmp->{$ex}{$video_id}{upload_date} > $length_upload_date;
    }
    if ( $length_upload_date && $length_upload_date < 10 ) {
        $length_upload_date = 10;
    }
    my $regexp;
    my $back   = sprintf "%*s", $length_video_id, '   BACK';
    my $filter = sprintf "%*s", $length_video_id, ' FILTER';
    my $sort   = sprintf "%*s", $length_video_id, '   SORT';
    my $enter  = sprintf "%*s", $length_video_id, '  ENTER';
    my %chosen_video_ids;
    my @last_chosen_video_ids = ();

    FILTER: while ( 1 ) {
        my @pre  = ( length $regexp ? ( undef, $enter ) : ( undef, $filter, $sort, $enter ) );
        my @videos;
        my @tmp_video_ids;
        my $index = $#pre;
        my $mark = [];
        my $sort_item  = $opt->{list_sort_item};
        my $sort_order = $opt->{list_sort_order};
        if ( $sort_item eq 'view_count_raw' && ! $has_view_count ) {
            $sort_item = 'upload_date';
        }
        if ( $sort_item eq 'duration' && ! $has_duration ) {
            $sort_item = 'upload_date';
        }
        if ( $sort_item eq 'upload_date' ) {
            if ( ! $length_upload_date ) {
                $sort_item = 'title';
                $sort_order = 'Asc';
            }
            elsif ( $has_date_sort ) {
                $sort_item = 'date_sort';
                $sort_order = $sort_order eq 'Asc' ? 'Desc' : 'Asc';
            }
        }
        my @video_ids = sort { _my_sort( $sort_item, $sort_order, $tmp->{$ex}, $a, $b ) }  keys %{$tmp->{$ex}};

        VIDEO_ID: for my $video_id ( @video_ids ) {
            my $title = $tmp->{$ex}{$video_id}{title};
            $title =~ s/\s+/ /g;
            $title =~ s/^\s+|\s+\z//g;
            if ( length $regexp ) {
                if ( $regexp =~ /^!~\s(.+)\z/ ) {
                    my $r = $1;
                    next VIDEO_ID if $title =~ /$r/i;
                }
                else {
                    next VIDEO_ID if $title !~ /$regexp/i;
                }
            }
            $tmp->{$ex}{$video_id}{from_list} = 1;
            if ( $ex eq 'youtube' ) {
                $tmp->{$ex}{$video_id}{extractor} = 'youtube';
            }
            my $line = sprintf "%*s |", $length_video_id, $video_id;
            $line .= sprintf " %7s", $tmp->{$ex}{$video_id}{duration}                          if $has_duration;
            $line .= sprintf "  %*s", $length_upload_date, $tmp->{$ex}{$video_id}{upload_date} if $length_upload_date;
            if ( ( $opt->{list_sort_item} eq 'view_count_raw' || $opt->{show_view_count} ) && $has_view_count ) {
                $line .= sprintf "  %*s", $length_view_count, $tmp->{$ex}{$video_id}{view_count};
            }
            $line .= sprintf "  %s", $title;
            push @videos, $line;
            push @tmp_video_ids, $video_id;
            $index++;
            push @$mark, $index if any { $video_id eq $_ } keys %chosen_video_ids;
        }
        my $choices = [ @pre, @videos ];
        # Choose
        my @idx = choose(
            $choices,
            { prompt => $prompt . ':', layout => 3, index => 1, clear_screen => 1, mark => $mark,
              undef => $back, meta_items => [ 0 .. $#pre ], include_highlighted => 2 }
        );
        if ( ! defined $idx[0] || ! defined $choices->[$idx[0]] ) {
            if ( length $regexp ) {
                delete @{$info->{$ex}}{ @last_chosen_video_ids };
                $regexp = '';
                next FILTER;
            }
            delete @{$info->{$ex}}{ keys %chosen_video_ids };
            return;
        }
        my $choice = $choices->[$idx[0]];
        if ( $choice eq $filter ) {
            shift @idx;
            @last_chosen_video_ids = ();
            for my $i ( @idx ) {
                my $video_id = $tmp_video_ids[$i - @pre];
                $info->{$ex}{$video_id} = $tmp->{$ex}{$video_id};
                $chosen_video_ids{$video_id}++;
                push @last_chosen_video_ids, $video_id;
            }
            for my $m ( @$mark ) {
                if ( none { $m == $_ } @idx ) {
                    my $video_id = $tmp_video_ids[$m - @pre];
                    delete $chosen_video_ids{$video_id};
                    delete $info->{$ex}{$video_id};
                }
            }
            my $trs = Term::Form->new();
            $regexp = $trs->readline( "Regexp: " );
            next FILTER;
        }
        elsif ( $choice eq $sort ) {
            set_sort_videolist( $opt );
        }
        else {
            if ( $choice eq $enter ) {
                shift @idx;
            }
            @last_chosen_video_ids = ();
            for my $i ( @idx ) {
                my $video_id = $tmp_video_ids[$i - @pre];
                $info->{$ex}{$video_id} = $tmp->{$ex}{$video_id};
                $chosen_video_ids{$video_id}++;
                push @last_chosen_video_ids, $video_id;
            }
            for my $m ( @$mark ) {
                if ( none { $m == $_ } @idx ) {
                    my $video_id = $tmp_video_ids[$m - @pre];
                    delete $chosen_video_ids{$video_id};
                    delete $info->{$ex}{$video_id};
                }
            }
            if ( length $regexp ) {
                $regexp = '';
                next FILTER;
            }
            else {
                return;
            }
        }
    }
}


sub set_sort_videolist {
    my ( $opt ) = @_;
    my $backup_item  = $opt->{list_sort_item};
    my $backup_order = $opt->{list_sort_order};
    my $sort_items = [ 'upload_date', 'title', 'view_count_raw', 'duration' ];
    my $confirm = '  CONFIRM';
    my @pre = ( undef, $confirm );
    my $choices = [ @pre, map { my $s = $_; $s =~ s/_raw\z//; $s =~ s/_/ /g; '- ' . $s } @$sort_items ];

    ITEM: while ( 1 ) {
        my $current = $opt->{list_sort_item};
        $current =~ s/_raw\z//;
        $current =~ s/_/ /g;
        my $prompt = sprintf 'Sort item: [%s]', $current;
        my $idx = choose (
            $choices,
            { prompt => $prompt, clear_screen => 0, layout => 3, index => 1, undef => '  BACK' }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            $opt->{list_sort_item} = $backup_item;
            return;
        }
        if ( $choices->[$idx] eq $confirm ) {
            last ITEM;
        }
        $idx -= @pre;
        $opt->{list_sort_item} = $sort_items->[$idx];
    }

    ORDER: while ( 1 ) {
        my $curr_sort_item = $opt->{list_sort_item};
        $curr_sort_item =~ s/_raw\z//;
        $curr_sort_item =~ s/_/ /g;
        my $order_prompt = sprintf 'Sort order "%s": [%s]', $curr_sort_item, $opt->{list_sort_order};
        my $choice = choose (
            [ @pre, '- Asc', '- Desc' ],
            { prompt => $order_prompt, clear_screen => 0, layout => 3, undef => '  BACK' }
        );
        if ( ! defined $choice ) {
            $opt->{list_sort_order} = $backup_order;
            return;
        }
        if ( $choice eq $confirm ) {
            $opt->{change}++;
            return;
        }
        $choice =~ s/^-\s//;
        $opt->{list_sort_order} = $choice;
    }
}


1;


__END__
