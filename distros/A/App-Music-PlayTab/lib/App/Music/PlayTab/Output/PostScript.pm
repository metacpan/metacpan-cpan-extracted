#! perl

# Author          : Johan Vromans
# Created On      : Thu Mar 27 16:46:54 2014
# Last Modified By: Johan Vromans
# Last Modified On: Sun May 18 21:29:59 2014
# Update Count    : 235
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::Output::PostScript;

use strict;
use warnings;

our $VERSION = "0.001";

# Object management.

sub new {
    bless { init => 0 }, shift;
}

# Initial default values.
my $std_width	   =  30;
my $std_height	   = -15;
my $std_margin	   =  40;

# Position control.
my $xd = 0;			# step (in bar lines)
my $yd = 0;			# vertical space between lines
my $md = 0;			# additional left margin
my $x = 0;			# actual x pos
my $y = 0;			# actual y pos

my $barno;
my $std_gridscale = 8;
my $title;
my $fh;			   # singleton

# New page, and init the backend if needed.
sub setup {			# API
    my ( $self, $args ) = @_;
    $fh = $self->{fh};
    unless ( $self->{init}++ ) {
	ps_preamble( $args->{preamble} );
	$xd = $std_width;
	$yd = $std_height;
	$md = $std_margin;
    }
}

sub setuppage {			# API
    my ( $self, $title, $stitles ) = @_;
    ps_page( 1, $title, $stitles );
    undef $barno;
}

sub finish {			# API
    my $self = shift;
    return unless $self->{init};
    ps_trailer();
    $self->{init} = 0;
}

# New print line.
sub setupline {			# API
    my ( $self, $line ) = @_;
    $xd     = $line->{width};
    $yd     = $line->{height};
    $md     = $line->{margin} || 0;
    $barno  = $line->{barno};
}

sub chord {			# API
    my ( $self, $chord, $dup ) = @_;
    if ( ref($chord) =~ /::/ ) {
	ps_chord($chord);
	$self->{_prev_chord} = $chord;
    }
    elsif ( ref($chord) eq 'ARRAY' ) {
	my $fun = "print_" . shift(@$chord);
	$self->$fun( @$chord );
    }
    else {
	my $fun = "print_$chord";
	$self->$fun;
    }
    while ( $dup-- > 1 ) {
	$self->print_space;
    }
}

sub print_again {
    my ( $self ) = @_;
    $self->chord( $self->{_prev_chord} );
}

sub bar {			# API
    my ( $self, $first ) = @_;
    ps_move();
    if ( defined($barno) ) {
	if ( $first ) {
	    $self->{fh}->print( $barno > 0 ? ("($barno) barn\n") : ("bar\n") );
	}
	else {
	    $self->{fh}->print("bar\n");
	    $barno++;
	}
    }
    else {
	$self->{fh}->print("bar\n");
    }
    ps_skip(4);
}

sub newline {			# API
    my ( $self, $count ) = @_;
    ps_advance($count);
}

sub print_space {
    ps_step();
}

sub print_rest {
    my $self = shift;
    ps_move();
    $self->{fh}->print("rest\n");
    ps_step();
}

sub print_same {
    my ( $self, $wh, $xs ) = @_;
    my $save_x = $x;
    $x += ($xs * $xd) / 2;
    ps_move();
    $self->{fh}->print("same$wh\n");	# TODO: change to "same"
    $x = $save_x;
    ps_skip($xs * $xd);
}

sub print_ta {
    my $self = shift;
    ps_move();
    $self->{fh}->print("ta\n");
    ps_step();
}

sub postfix {			# API
    my ( $self, $text ) = @_;
    ps_skip(4);
    $self->text( $text, $md );
}

sub text {			# API
    my ( $self, $text, $xxmd, $font ) = @_;
    $font ||= 'SF';
    my $xm = $md;
    $md = $xxmd || 0;
    ps_move();
    $self->{fh}->print( $font, ' (', $text, ') show', "\n");
    $md = $xm;
}

sub print_hmore {
    ps_skip(4);
}

sub print_less {
    ps_skip(-4);
}

sub grids {			# API
    my ( $self, $grids ) = @_;

    my $n = int( ( 570 - $md - 60 ) / 80 );

    my $i = 0;
    foreach my $ch ( @$grids ) {
	$self->print_grid($ch);
	if ( ++$i >= $n ) {
	    $self->newline(4);
	    $i = 0;
	}
	else {
	    ps_gridstep();
	}
    }
    $self->newline(3);
}

my @Rom = qw(I II III IV V VI VII VIII IX X XI XII);

sub print_grid {
    my ( $self, $grid ) = @_;

    my @c = @$grid;
    my $chord = shift(@c);
    my $ps = ref($chord) ? $chord->ps : "($chord) show";
    $self->{fh}->print('1000 1000 moveto', "\n",
		   $ps, "\n",
		   'currentpoint pop 1000 sub 2 div', "\n");
    ps_move();
    $self->{fh}->print(2.5*$std_gridscale, ' exch sub 8 add 0 rmoveto ',
		   $ps, "\n");
    ps_move();

    my $c = shift(@c);
    if ( $c ) {
	$c = "($Rom[$c-1])"
    }
    else {
	$c = '()';
    }

    $self->{fh}->print('8 ', -5-(4*$std_gridscale), " rmoveto @c $c dots\n");
}

################ PostScript routines ################

my $ps_pages  = 0;
my $ps_page = 1;	# first logical page
my $page_left;		# left margin of page
my $page_right;		# right margin of page
my $page_top;		# top margin of page
my $page_bottom;	# bottom margin of page;

sub ps_page {
    my ( $first, $ttle, $stitles ) = @_;
    $fh->print('end showpage', "\n") if $ps_pages;
    $fh->print('%%Page: ', ++$ps_pages. ' ', $ps_pages, "\n",
		  'tabdict begin', "\n");
    $x = $y = 0;
    $ps_page = $first ? 1 : $ps_page+1;

    $fh->print( "$page_left $page_top m TF ($ttle) show\n" );
    $title = $ttle if $first;

    if ( $ps_page > 1 ) {
	my $pp = "Page $ps_page";
	$fh->print( "$page_right $page_top m SF ($pp) rshow\n" );
    }
    ps_advance();

    my $save_md = $md;
    $md = 0;
    foreach ( @$stitles ) {
	ps_move();
	$fh->print( "SF ($_) show\n" );
	ps_advance();
    }
    $md = $save_md;
    ps_advance(2);
}

sub ps_move {

    if ( $page_top+$y < $page_bottom ) {
	ps_page( 0, $title, [] );
    }

    $fh->print($page_left+$x+$md, ' ' , $page_top+$y, ' m ');
}

sub ps_step { ps_skip($xd) }

sub ps_gridstep { ps_skip(80) } # #### TODO: what width?

sub ps_advance {
    $x = 0;
    $y += $yd;
    $y += ($_[0]-1)*$yd if defined $_[0];
}

sub ps_skip {
    $x += $_[0];
}

sub ps_chord {
    my ( $chord ) = @_;
    ps_move();
    $fh->print($chord->ps, "\n");
    ps_step();
}

sub ps_preamble {
    my ( $preamble ) = @_;
    my $data;
    if ( defined $preamble ) {
	open(DATA, $preamble) or die("$preamble: $!\n");
	local($/);
	$data = <DATA>;
	close(DATA);
    }
    else {
	require App::Music::PlayTab::Output::PostScript::Preamble;
	$data = App::Music::PlayTab::Output::PostScript::Preamble->preamble( $_[0] );
    }
    $data =~ s/\$std_gridscale/$std_gridscale/g;
    $fh->print($data);

    # A4 format is 595 pt x 842 pt.
    $page_left   =  50;
    $page_right  = 550;
    $page_top    = 800;
    $page_bottom =  50;

    $x = $y = 0;
    $ps_pages = 0;
}

sub ps_trailer {
    $fh->print( <<EOD );
end showpage
%%Trailer
%%Pages: $ps_pages
%%EOF
EOD
}

# PostScript support routines for App::Music::PlayTab::Note.

package App::Music::PlayTab::Note;

sub ps {
    my $self = shift;
    my $res = $self->name;
    if ( $res =~ /(.)b/ ) {
	$res = '('.$1.') root flat';
    }
    elsif ( $res =~ /(.)#/ ) {
	$res = '('.$1.') root sharp';
    }
    else {
	$res = '('.$res.') root';
    }
    $res;
}

# PostScript support routines for App::Music::PlayTab::Chord.

package App::Music::PlayTab::Chord;

sub ps {
    my ($self) = @_;
    my $res = $self->{key}->ps;

    my @v = @{$self->{vec}};
    my $v = "@v ";
    shift (@v);

    if ( $v =~ s/^0 (2 )?4 (6|7|8) / / ) {
	$res .= $2 == 8 ? ' plus' : '';
	$v = ' 6' . $v if $2 == 6;
	$v = ' 2' . $v if defined $1;
    }
    elsif ( $v =~ s/^0 3 6 9 / / ) {
	$res .= ' dim';
    }
    elsif ( $v =~ s/^0 (2 )?3 (6|7|8) / / ) {
	if ( $2 == 6 ) {
	    $res .= ( $v =~ s/^ 10 // ) ? ' hdim' : ' dim';
	}
	else {
	    $res .= ' minus';
	}
	$v = ' 8' . $v 	if $2 == 8;
	$v = ' 2' . $v  if defined $1;
    }
    $v =~ s/^0 5 7 / 5 7 /;
    $v =~ s/ 10 14 18 (21) / $1 /;		# 13
    $v =~ s/ 10 14 18 (20|22) / 10 $1 /;	#  7#13 7b13
    $v =~ s/ 10 14 (17) / $1 /;			# 11
    $v =~ s/ 10 14 (18) / 10 $1 /;		#  7#11
    $v =~ s/ 10 (14) / $1 /;			#  9
    $v =~ s/ 10 (15) / 10 $1 /;			#  7#9
    $v =~ s/ 11 14 18 (21|22) / $1 11 /;	# 13#5
    $v =~ s/ 11 14 (17|18) / $1 11 /;		# 11#5
    $v =~ s/ 11 (14|15) / $1 11 /;		#  9#5
    if ( $v =~ s/ 10 / / ) {
	$res .= ' (7) addn';
    }
    elsif ( $v =~ s/^( \d| 10|) 11 / $1/ ) {
	$res .= ' -2 0 rmoveto' if $res =~ / flat$/;
	$res .= ' delta';
    }
    if ( $v =~ s/ 5 7 / / ) {
	$res .= ' (4) susp';
    }
    elsif ( $v =~ s/^0 7 / / ) {
	$res .= ' (2) susp';
    }
    elsif ( $v =~ s/^0 4 / / ) {
	$res .= ' (no5) addn';
    }
    my $res1 = $res;		# for debug

    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	$res .= ' ';
	$res .= ( '(1) addn', '(2) addf', '(2) addn', '(3) addf', '(3) addn',
		  '(4) addn', '(5) addf', '(5) addn', '(5) adds', '(6) addn',
		  '(7) addn', '(7) adds', '(8) addn', '(9) addf', '(9) addn',
		  '(9) adds','(11) addf','(11) addn','(11) adds',
		 '(12) addn','(13) addf','(13) addn' )[$_];
    }

    if ( $self->{high} ) {
	my $t = join(" bslash ", map { $_->ps } @{$self->{high}});
	$t =~ s/root/hroot/g;
	$res = join(" bslash ", $res, $t);
    }

    if ( $self->{bass} ) {
	my $t = join(" slash ", map { $_->ps } @{$self->{bass}});
	$t =~ s/root/hroot/g;
	$res = join(" slash ", $res, $t);
    }

    warn("=> Chord ", $self->{_unparsed}, ": ", $self->{key}->key,
	 " (", $self->{key}->name, ") [ @{$self->{vec}} ] ->",
	 " $res1 [ $v ] -> $res\n")
      if $self->{_debug};

    return $res;
}

1;

__END__

=head1 NAME

App::Music::PlayTab::Output::PostScript - PostScript output.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
