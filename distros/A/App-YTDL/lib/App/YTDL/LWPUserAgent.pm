package # hide from PAUSE
App::YTDL::LWPUserAgent;

use warnings;
use strict;
use 5.010000;

use parent qw( LWP::UserAgent );

use App::YTDL::Helper qw( HIDE_CURSOR SHOW_CURSOR );




my @ANI = qw(- \ | /);

sub progress {
    my( $self, $status, $m ) = @_;
    return unless $self->{show_progress};
    print HIDE_CURSOR;
    local( $,, $\ );
    if ( $status eq "begin" ) {
        my $uri = $m->uri;
        my $print_begin;
        if ( $uri =~ m|^(https://www\.youtube\.com/browse_ajax\?action_continuation)| ) {
            $print_begin = sprintf '** %s %s... page %d ==> ', $m->method, $1, $self->{page};
        }
        else {
            $print_begin = sprintf '** %s %s page %d ==> ', $m->method, $uri, $self->{page};
        }
        print STDERR $print_begin;
        $self->{progress_start} = time;
        $self->{progress_lastp} = "";
        $self->{progress_ani} = 0;
    }
    elsif ( $status eq "end" ) {
        delete $self->{progress_lastp};
        delete $self->{progress_ani};
        print STDERR $m->status_line;
        my $t = time - delete $self->{progress_start};
        print STDERR " (${t}s)" if $t;
        print STDERR "\n";
    }
    elsif ( $status eq "tick" ) {
        print STDERR "$ANI[$self->{progress_ani}++]\b";
        $self->{progress_ani} %= @ANI;
    }
    else {
        my $p = sprintf "%3.0f%%", $status * 100;
        return if $p eq $self->{progress_lastp};
        print STDERR "$p\b\b\b\b";
        $self->{progress_lastp} = $p;
    }
    STDERR->flush;
}




1;


__END__
