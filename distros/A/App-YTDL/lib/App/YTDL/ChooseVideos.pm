package # hide from PAUSE
App::YTDL::ChooseVideos;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( choose_videos set_sort_videolist );

use Encode qw( decode );

use Encode::Locale  qw();
use List::MoreUtils qw( any none minmax firstidx );
use Term::Choose    qw( choose );
use Term::Form      qw();


sub _my_sort {
    my ( $sort_item, $sort_order, $h_ref, $a, $b ) = @_;
    my @s = $sort_order eq 'Asc'
                ? ( $h_ref->{$a}{$sort_item}, $h_ref->{$b}{$sort_item} )
                : ( $h_ref->{$b}{$sort_item}, $h_ref->{$a}{$sort_item} );
    if ( $sort_item eq 'view_count_raw' || $sort_item eq 'date_sort' ) {
          ( $s[0] // 0 )      <=> ( $s[1] // 0 )
       || $h_ref->{$a}{title} cmp $h_ref->{$b}{title};
    }
    else {
          ( $s[0] // '' )     cmp ( $s[1] // '' )
       || $h_ref->{$a}{title} cmp $h_ref->{$b}{title};
   }
}


sub choose_videos {
    my ( $set, $opt, $data, $ex, $up, $ids, $prompt ) = @_;
    my $view_count_w  = 0;
    my $id_w          = 0;
    my $upload_date_w = 0;
    my $duration_w    = 7;
    my $has_date_sort   = 0;
    my $has_view_count  = 0;
    my $has_duration    = 0;
    my $has_upload_date = 0;
    my $dummy;
    for my $id ( keys %{$data->{$ex}{$up}} ) {
        $has_duration++    if defined $data->{$ex}{$up}{$id}{duration} && $data->{$ex}{$up}{$id}{duration} ne '-:--:--';
        $has_date_sort++   if defined $data->{$ex}{$up}{$id}{date_sort};
        $has_view_count++  if defined $data->{$ex}{$up}{$id}{view_count};
        $has_upload_date++ if defined $data->{$ex}{$up}{$id}{upload_date} && $data->{$ex}{$up}{$id}{upload_date} ne '';
        ( $dummy, $id_w )    = minmax( length $id, $id_w );
        ( $dummy, $view_count_w )  = minmax( length( $data->{$ex}{$up}{$id}{view_count}  // '' ), $view_count_w );
        ( $dummy, $upload_date_w ) = minmax( length( $data->{$ex}{$up}{$id}{upload_date} // '' ), $upload_date_w );
    }
    if ( $upload_date_w && $upload_date_w < 10 ) {
        $upload_date_w = 10;
    }
    my $regexp;
    my $back   = 'BACK';
    my $filter = 'FILTER';
    my $sort   = 'SORT';
    my $enter  = 'ENTER';
    my $add_info = $has_view_count + $has_duration + $has_upload_date;
    my $chosen_ids = {};
    my @last_chosen_ids = ();

    FILTER: while ( 1 ) {
        my $sort_item  = $opt->{list_sort_item};
        my $sort_order = $set->{list_sort_order};
        if ( $sort_item eq 'view_count_raw' && ! $has_view_count ) {
            $sort_item = 'upload_date';
        }
        if ( $sort_item eq 'duration' && ! $has_duration ) {
            $sort_item = 'upload_date';
        }
        if ( $sort_item eq 'upload_date' ) {
            if ( ! $upload_date_w ) {
                $sort_item = 'title';
                $sort_order = 'Asc';
            }
            elsif ( $has_date_sort ) {
                $sort_item = 'date_sort';
                $sort_order = $sort_order eq 'Asc' ? 'Desc' : 'Asc';
            }
        }
        my @pre  = (
            length $regexp ?
                ( undef, $enter )
              : ( undef, $filter, $add_info ? $sort : (), $enter )
        );
        my $index = $#pre;
        my $mark = [];
        my @tmp_ids = @$ids;
        my @tmp_ids_fmt =
            sort { _my_sort( $sort_item, $sort_order, $data->{$ex}{$up}, $a, $b ) }
            splice( @tmp_ids, 0, $opt->{entries_with_info} );
        my @str_videos;
        my @avail_ids;

        VIDEO_ID: for my $id ( @tmp_ids_fmt, @tmp_ids ) {
            my $title = $data->{$ex}{$up}{$id}{title};
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
            $data->{$ex}{$up}{$id}{from_list} = 1;
            my $line = '';
            $line .= sprintf "%*s | ", $id_w, $id if $opt->{show_video_id};
            if ( $opt->{entries_with_info} ) {
                $line .= sprintf "%*s  ",  $duration_w,   $data->{$ex}{$up}{$id}{duration}    // '' if $has_duration;
                $line .= sprintf "%*s  ", $upload_date_w, $data->{$ex}{$up}{$id}{upload_date} // '' if $has_upload_date;
                $line .= sprintf "%*s  ", $view_count_w,  $data->{$ex}{$up}{$id}{view_count}  // '' if $has_view_count && ( $opt->{list_sort_item} eq 'view_count_raw' || $opt->{show_view_count} );
            }
            $line .= sprintf "%s", $title;
            push @str_videos, $line;
            push @avail_ids, $id;
            $index++;
            push @$mark, $index if any { $id eq $_ } keys %$chosen_ids;
        }
        my $menu = [ @pre, @str_videos ];
        # Choose
        my @idx = choose(
            $menu,
            { prompt => $prompt . ':', layout => 3, index => 1, clear_screen => 1, mark => $mark,
              undef => $back, meta_items => [ 0 .. $#pre ], include_highlighted => 2 }
        );
        if ( ! defined $idx[0] || ! defined $menu->[$idx[0]] ) {
            if ( length $regexp ) {
                $regexp = '';
                next FILTER;
            }
            return;
        }
        my $choice = $menu->[$idx[0]];
        if ( $choice eq $filter ) {
            shift @idx;
            @last_chosen_ids = ();
            for my $i ( @idx ) {
                my $id = $avail_ids[$i - @pre];
                $chosen_ids->{$id}++;
                push @last_chosen_ids, $id;
            }
            for my $m ( @$mark ) {
                if ( none { $m == $_ } @idx ) {
                    my $id = $avail_ids[$m - @pre];
                    delete $chosen_ids->{$id};
                }
            }
            my $trs = Term::Form->new();
            $regexp = $trs->readline( "Regexp: " );
            next FILTER;
        }
        elsif ( $choice eq $sort ) {
            set_sort_videolist( $set, $opt );
            next FILTER;
        }
        else {
            if ( $choice eq $enter ) {
                shift @idx;
            }
            @last_chosen_ids = ();
            for my $i ( @idx ) {
                my $id = $avail_ids[$i - @pre];
                $chosen_ids->{$id}++;
                push @last_chosen_ids, $id;
            }
            for my $m ( @$mark ) {
                if ( none { $m == $_ } @idx ) {
                    my $id = $avail_ids[$m - @pre];
                    delete $chosen_ids->{$id};
                }
            }
            if ( length $regexp ) {
                $regexp = '';
                next FILTER;
            }
            else {
                my $chosen = [
                    sort { ( firstidx { $_ eq $a } @avail_ids ) <=> ( firstidx { $_ eq $b } @avail_ids ) }
                    keys %$chosen_ids
                ];
                return $chosen;
            }
        }
    }
}


sub set_sort_videolist {
    my ( $set, $opt ) = @_;
    my $backup_item  = $opt->{list_sort_item};
    my $backup_order = $set->{list_sort_order};
    my $sort_items = [ 'upload_date', 'title', 'view_count_raw', 'duration' ];
    my $confirm = '  CONFIRM';
    my @pre = ( undef, $confirm );
    my $menu = [ @pre, map { my $s = $_; $s =~ s/_raw\z//; $s =~ s/_/ /g; '- ' . $s } @$sort_items ];

    ITEM: while ( 1 ) {
        my $current = $opt->{list_sort_item};
        $current =~ s/_raw\z//;
        $current =~ s/_/ /g;
        my $prompt = sprintf 'Sort item: [%s]', $current;
        my $idx = choose (
            $menu,
            { prompt => $prompt, clear_screen => 0, layout => 3, index => 1, undef => '  BACK' }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            $opt->{list_sort_item} = $backup_item;
            return;
        }
        if ( $menu->[$idx] eq $confirm ) {
            last ITEM;
        }
        $idx -= @pre;
        $opt->{list_sort_item} = $sort_items->[$idx];
    }

    ORDER: while ( 1 ) {
        my $curr_sort_item = $opt->{list_sort_item};
        $curr_sort_item =~ s/_raw\z//;
        $curr_sort_item =~ s/_/ /g;
        my $order_prompt = sprintf 'Sort order "%s": [%s]', $curr_sort_item, $set->{list_sort_order};
        my $choice = choose (
            [ @pre, '- Asc', '- Desc' ],
            { prompt => $order_prompt, clear_screen => 0, layout => 3, undef => '  BACK' }
        );
        if ( ! defined $choice ) {
            $set->{list_sort_order} = $backup_order;
            return;
        }
        if ( $choice eq $confirm ) {
            $set->{change}++;
            return;
        }
        $choice =~ s/^-\s//;
        $set->{list_sort_order} = $choice;
    }
}


1;


__END__
