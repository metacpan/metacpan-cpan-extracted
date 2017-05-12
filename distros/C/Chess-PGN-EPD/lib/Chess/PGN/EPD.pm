use strict;
use warnings;

package Chess::PGN::EPD;

use v5.24;
use Chess::PGN::Moves;
use File::ShareDir qw(dist_file);
use File::Slurper qw(read_text);
use Cpanel::JSON::XS qw(decode_json);

require Exporter;

my ( $hECO, $hNIC, $hOpening );
my %hash = (
    ECO     => \$hECO,
    NIC     => \$hNIC,
    Opening => \$hOpening
);

my ( $ECO_path, $NIC_path, $Opening_path ) = _GetPaths('Chess-PGN-EPD');

$hECO     = decode_json read_text($ECO_path);
$hNIC     = decode_json read_text($NIC_path);
$hOpening = decode_json read_text($Opening_path);

sub _GetPaths {
    my $dist      = shift;
    my $dbECO     = dist_file( $dist, 'ECO.db' );
    my $dbNIC     = dist_file( $dist, 'NIC.db' );
    my $dbOpening = dist_file( $dist, 'Opening.db' );

    return ( $dbECO, $dbNIC, $dbOpening );
}

our @ISA    = qw(Exporter);
our @EXPORT = qw(
    epdcode
    epdset
    epdfromto
    epdstr
    epdlist
    epdgetboard
    epdTaxonomy
    psquares
    %font2map
);
our $VERSION = '0.34';

our %font2map = (
    'Chess Cases'           => 'leschemelle',
    'Chess Adventurer'      => 'marroquin',
    'Chess Alfonso-X'       => 'marroquin',
    'Chess Alpha'           => 'bentzen1',
    'Chess Berlin'          => 'bentzen2',
    'Chess Condal'          => 'marroquin',
    'Chess Harlequin'       => 'marroquin',
    'Chess Kingdom'         => 'marroquin',
    'Chess Leipzig'         => 'marroquin',
    'Chess Line'            => 'marroquin',
    'Chess Lucena'          => 'marroquin',
    'Chess Magnetic'        => 'marroquin',
    'Chess Mark'            => 'marroquin',
    'Chess Marroquin'       => 'marroquin',
    'Chess Maya'            => 'marroquin',
    'Chess Mediaeval'       => 'marroquin',
    'Chess Merida'          => 'marroquin',
    'Chess Millennia'       => 'marroquin',
    'Chess Miscel'          => 'marroquin',
    'Chess Montreal'        => 'katch',
    'Chess Motif'           => 'marroquin',
    'Chess Plain'           => 'hickey',
    'Chess Regular'         => 'scott1',
    'Chess Usual'           => 'scott2',
    'Chess Utrecht'         => 'bodlaender',
    'Tilburg'               => 'tilburg',
    'Traveller Standard V3' => 'cowderoy',
);

my %board = qw(
    a1 R a2 P a7 p a8 r
    b1 N b2 P b7 p b8 n
    c1 B c2 P c7 p c8 b
    d1 Q d2 P d7 p d8 q
    e1 K e2 P e7 p e8 k
    f1 B f2 P f7 p f8 b
    g1 N g2 P g7 p g8 n
    h1 R h2 P h7 p h8 r
);
my $Kc = 1;
my $Qc = 1;
my $kc = 1;
my $qc = 1;
my $w  = 1;

my @onwhite = (
    1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0,
    1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1,
    0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1,
);

my %FontMap = (
    hicky => {
        OnBlack            => 'OMASTLPNBRQK@',
        OnWhite            => 'omastlpnbrqk:',
        SingleBox          => '12345678',
        DoubleBox          => '!"#$%&\'(',
        SingleRounded      => '[]\^',
        DoubleRounded      => '<>;=/',
        SingleLeftLegend   => 'cdefghij',
        DoubleLeftLegend   => 'CDEFGHIJ',
        SingleBottomLegend => 'wxyz{|}~',
        DoubleBottomLegend => ')*+,-./0',
    },
    marroquin => {
        OnBlack            => 'OMVTWLPNBRQK+',
        OnWhite            => 'omvtwlpnbrqk ',
        SingleBox          => '12345789',
        DoubleBox          => '!"#$%/()',
        SingleRounded      => 'asdf',
        DoubleRounded      => 'ASDF',
        SingleLeftLegend   => "\300\301\302\303\034\305\306\307",
        DoubleLeftLegend   => "\340\341\342\343\344\345\346\347",
        SingleBottomLegend => "\310\311\312\313\314\315\316\317",
        DoubleBottomLegend => "\350\351\352\353\354\355\356\357",
    },
    leschemelle => {
        OnBlack            => 'OMVTWLPNBRQK+',
        OnWhite            => 'omvtwlpnbrqk ',
        SingleBox          => '12345789',
        DoubleBox          => '!"#$%/()',
        SingleRounded      => 'asdf',
        DoubleRounded      => 'ASDF',
        SingleLeftLegend   => "\300\301\302\303\034\305\306\307",
        DoubleLeftLegend   => "\340\341\342\343\344\345\346\347",
        SingleBottomLegend => "\310\311\312\313\314\315\316\317",
        DoubleBottomLegend => "\350\351\352\353\354\355\356\357",
    },
    linares => {
        OnBlack            => '0hg41i)HG$!Id',
        OnWhite            => 'pnbrqkPNBRQKw',
        SingleBox          => 'W_W[]W-W',
        DoubleBox          => 'cuC{}vlV',
        SingleRounded      => 'WWWW',
        DoubleRounded      => 'cCvV',
        SingleLeftLegend   => "\332\333\334\335\336\337\340\341",
        DoubleLeftLegend   => '(765&32%',
        SingleBottomLegend => "\301\302\303\304\305\306\307\310",
        DoubleBottomLegend => ',./9EFJM',
    },
    linares1 => {
        OnBlack            => '0hg41i)HG$!Id',
        OnWhite            => 'pnbrqkPNBRQKw',
        SingleBox          => '>;?:<A=@',
        DoubleBox          => '>;?:<A=@',
        SingleRounded      => '>?A@',
        DoubleRounded      => '>?A@',
        SingleLeftLegend   => '::::::::',
        DoubleLeftLegend   => '::::::::',
        SingleBottomLegend => '========',
        DoubleBottomLegend => '========',
    },
    linares2 => {
        OnBlack            => '0hg41i)HG$!Id',
        OnWhite            => 'pnbrqkPNBRQKw',
        SingleBox          => '^xY|yUz\\',
        DoubleBox          => '^xY|yUz\\',
        SingleRounded      => '^YU\\',
        DoubleRounded      => '^YU\\',
        SingleLeftLegend   => '||||||||',
        DoubleLeftLegend   => '||||||||',
        SingleBottomLegend => 'zzzzzzzz',
        DoubleBottomLegend => 'zzzzzzzz',
    },
    cowderoy => {
        OnBlack            => '$#!&%"*)\',+(0',
        OnWhite            => 'pnbrqkPNBRQK ',
        SingleBox          => '78946123',
        DoubleBox          => '78946123',
        SingleRounded      => '7913',
        DoubleRounded      => '7913',
        SingleLeftLegend   => '44444444',
        DoubleLeftLegend   => '44444444',
        SingleBottomLegend => '22222222',
        DoubleBottomLegend => '22222222',
    },
    bentzen1 => {
        OnBlack            => 'OJNTWLPHBRQK+',
        OnWhite            => 'ojntwlphbrqk ',
        SingleBox          => '!"#$%&\'(',
        DoubleBox          => '12345789',
        SingleRounded      => '!#&(',
        DoubleRounded      => '1379',
        SingleLeftLegend   => "\340\341\342\343\344\345\346\347",
        DoubleLeftLegend   => "\300\301\302\303\304\305\306\307",
        SingleBottomLegend => "\350\351\352\353\354\355\356\357",
        DoubleBottomLegend => "\310\311\312\313\314\315\316\317",
    },
    bentzen2 => {
        OnBlack            => 'OJNTWLPHBRQK+',
        OnWhite            => 'ojntwlphbrqk ',
        SingleBox          => '12345789',
        DoubleBox          => '12345789',
        SingleRounded      => '1379',
        DoubleRounded      => '1379',
        SingleLeftLegend   => '44444444',
        DoubleLeftLegend   => '44444444',
        SingleBottomLegend => '88888888',
        DoubleBottomLegend => '88888888',
    },
    scott1 => {
        OnBlack            => 'OJNTWLPHBRQK+',
        OnWhite            => 'ojntwlphbrqk*',
        SingleBox          => '(-)/\[_]',
        DoubleBox          => '(-)/\[_]',
        SingleRounded      => '(-)/\[_]',
        DoubleRounded      => '(-)/\[_]',
        SingleLeftLegend   => '////////',
        DoubleLeftLegend   => '////////',
        SingleBottomLegend => '________',
        DoubleBottomLegend => '________',
    },
    scott2 => {
        OnBlack            => 'OMVTWLPNBRQK+',
        OnWhite            => 'omvtwlpnbrqk ',
        SingleBox          => '12345789',
        DoubleBox          => '!"#$%/()',
        SingleRounded      => 'asdf',
        DoubleRounded      => 'ASDF',
        SingleLeftLegend   => '44444444',
        DoubleLeftLegend   => '$$$$$$$$',
        SingleBottomLegend => '44444444',
        DoubleBottomLegend => '$$$$$$$$',
    },
    bodlaender => {
        OnBlack            => 'OMVTWLomvtwl/',
        OnWhite            => 'PNBRQKpnbrqk ',
        SingleBox          => '51632748',
        DoubleBox          => '51632748',
        SingleRounded      => '51632748',
        DoubleRounded      => '51632748',
        SingleLeftLegend   => '33333333',
        DoubleLeftLegend   => '33333333',
        SingleBottomLegend => '44444444',
        DoubleBottomLegend => '44444444',
    },
    katch => {
        OnBlack            => 'OMVTWLPNBRQK/',
        OnWhite            => 'omvtwlpnbrqk ',
        SingleBox          => '12345789',
        DoubleBox          => '12345789',
        SingleRounded      => '12345789',
        DoubleRounded      => '12345789',
        SingleLeftLegend   => '44444444',
        DoubleLeftLegend   => '44444444',
        SingleBottomLegend => '88888888',
        DoubleBottomLegend => '88888888',
    },
    dummy => {
        OnBlack            => '',
        OnWhite            => '',
        SingleBox          => '',
        DoubleBox          => '',
        SingleRounded      => '',
        DoubleRounded      => '',
        SingleLeftLegend   => '',
        DoubleLeftLegend   => '',
        SingleBottomLegend => '',
        DoubleBottomLegend => '',
    },
);

my %convertPalView = (
    'r',
    '<IMG SRC="jpc/br.gif">',
    'n',
    '<IMG SRC="jpc/bn.gif">',
    'b',
    '<IMG SRC="jpc/bb.gif">',
    'q',
    '<IMG SRC="jpc/bq.gif">',
    'k',
    '<IMG SRC="jpc/bk.gif">',
    'p',
    '<IMG SRC="jpc/bp.gif">',
    'R',
    '<IMG SRC="jpc/wr.gif">',
    'N',
    '<IMG SRC="jpc/wn.gif">',
    'B',
    '<IMG SRC="jpc/wb.gif">',
    'Q',
    '<IMG SRC="jpc/wq.gif">',
    'K',
    '<IMG SRC="jpc/wk.gif">',
    'P',
    '<IMG SRC="jpc/wp.gif">',
    ' ',
    '<IMG SRC="jpc/i.gif">',
    '-',
    '<IMG SRC="jpc/i.gif">',
);

sub epdcode {
    my $key = shift;
    my $epd = shift;
    my $code;
    my $h = ${ $hash{$key} };

    for ( @{$epd} ) {
        $code = $h->{$_};    ## no critic
        last if $code;
    }
    return ( $code or 'Unknown' );
}

sub epdset {
    if ( my $epd = shift ) {
        my @array = split( /\/|\s/, $epd );
        my $file = '8';

        %board = ();
        $Kc    = 0;
        $Qc    = 0;
        $kc    = 0;
        $qc    = 0;
        for ( 0 .. 7 ) {
            $array[$_] =~ s/(\d+)/'_' x $1/ge;
            my @row = split( '', $array[$_] );
            my $rank = 'a';
            for my $piece (@row) {
                $board{"$rank$file"} = $piece if $piece ne '_';
                $rank++;
            }
            $file--;
        }
        $w = ( $array[8] eq 'w' );
        for ( split( '', $array[9] ) ) {
            if ( $_ eq 'K' ) {
                $Kc = 1;
            }
            elsif ( $_ eq 'Q' ) {
                $Qc = 1;
            }
            elsif ( $_ eq 'k' ) {
                $kc = 1;
            }
            elsif ( $_ eq 'q' ) {
                $qc = 1;
            }
        }
    }
    else {
        %board = qw(
            a1 R a2 P a7 p a8 r
            b1 N b2 P b7 p b8 n
            c1 B c2 P c7 p c8 b
            d1 Q d2 P d7 p d8 q
            e1 K e2 P e7 p e8 k
            f1 B f2 P f7 p f8 b
            g1 N g2 P g7 p g8 n
            h1 R h2 P h7 p h8 r
        );
        $w  = 1;
        $Kc = 1;
        $Qc = 1;
        $kc = 1;
        $qc = 1;
    }
    return;
}

sub epdstr {
    my %parameters = @_;
    if ( $parameters{'board'} ) {
        my %board;
        my $hashref = $parameters{'board'};

        for ( keys %$hashref ) {
            $board{$_} = $$hashref{$_};
        }
        $parameters{'epd'} = epd( 0, 0, 0, 0, 0, 0, %board );
    }
    my $epd  = $parameters{'epd'};
    my $type = lc( $parameters{'type'} );
    my ( $border, $corner, $legend ) = ( 'single', 'square', 'no' );

    $border = lc( $parameters{'border'} ) if exists( $parameters{'border'} );
    $corner = lc( $parameters{'corner'} ) if exists( $parameters{'corner'} );
    $legend = lc( $parameters{'legend'} ) if exists( $parameters{'legend'} );
    my @array = split( /\/|\s/, $epd );
    my @board;
    if ( $type eq 'diagram' ) {
        for ( 0 .. 7 ) {
            $array[$_] =~ s/(\d+)/'_' x $1/ge;
            $array[$_]
                =~ s/_/(((pos $array[$_]) % 2) xor ($_ % 2)) ? '-' : ' '/ge;
            push( @board, 8 - $_ . "  " . $array[$_] );
        }
        push( @board, '   abcdefgh' );
    }
    elsif ( $type eq 'text' ) {
        for ( 0 .. 7 ) {
            $array[$_] =~ s/(\d+)/'_' x $1/ge;
            $array[$_]
                =~ s/_/(((pos $array[$_]) % 2) xor ($_ % 2)) ? '-' : ' '/ge;
            push( @board, $array[$_] );
        }
    }
    elsif ( $type eq 'palview' ) {
        my @diagram;
        my $table;

        for ( 0 .. 7 ) {
            $array[$_] =~ s/(\d+)/'_' x $1/ge;
            $array[$_]
                =~ s/_/(((pos $array[$_]) % 2) xor ($_ % 2)) ? '-' : ' '/ge;
            push( @diagram, $array[$_] );
        }
        for (@diagram) {
            for ( split(//) ) {
                $table .= $convertPalView{$_};
            }
            $table .= "<BR>";
            push( @board, $table );
            $table = '';
        }
    }
    elsif ( $type eq 'latex' ) {
        push( @board, '\\begin{diagram}' );
        push( @board, '\\board' );
        for ( 0 .. 7 ) {
            $array[$_] =~ s/(\d+)/'_' x $1/ge;
            $array[$_]
                =~ s/_/(((pos $array[$_]) % 2) xor ($_ % 2)) ? '*' : ' '/ge;
            push( @board, '{' . $array[$_] . '}' );
        }
        push( @board, '\\end{diagram}' );
    }
    elsif ( $type eq 'tilburg' ) {
        for ( 0 .. 7 ) {
            $array[$_] =~ s/(\d+)/'_' x $1/ge;
            $array[$_]
                =~ s/([pnbrqkPNBRQK_])/_mappiece(pos $array[$_],$_,$1,"\341\345\351\355\361\365\337\343\347\353\357\363
\335","\340\344\350\354\360\364\336\342\346\352\356\362\334")/ge;
            push( @board, $array[$_] );
        }
    }
    else {
        @board = _configureboard( $type, $border, $corner, $legend );
        for ( 0 .. 7 ) {
            $array[$_] =~ s/(\d+)/'_' x $1/ge;
            $array[$_]
                =~ s/([pnbrqkPNBRQK_])/_mappiece(pos $array[$_],$_,$1,$FontMap{$type}{'OnBlack'},$FontMap{$type}
{'OnWhite'})/ge;
            substr( $board[ $_ + 1 ], 1, 8 ) = $array[$_];
        }
    }
    return @board;
}

sub _configureboard {
    my $type   = shift;
    my $border = shift;
    my $corner = shift;
    my $legend = shift;
    my $single = $border eq 'single';
    my $box    = $FontMap{$type}{ $single ? 'SingleBox' : 'DoubleBox' };
    my @board;

    if ( $corner eq 'rounded' ) {
        my $corners
            = $FontMap{$type}{ $single ? 'SingleRounded' : 'DoubleRounded' };

        substr( $box, 0, 1 ) = substr( $corners, 0, 1 );
        substr( $box, 2, 1 ) = substr( $corners, 1, 1 );
        substr( $box, 5, 1 ) = substr( $corners, 2, 1 );
        substr( $box, 7, 1 ) = substr( $corners, 3, 1 );
    }
    push( @board,
              substr( $box, 0, 1 )
            . substr( $box, 1, 1 ) x 8
            . substr( $box, 2, 1 ) );
    for ( 0 .. 7 ) {
        push( @board, substr( $box, 3, 1 ) . ' ' x 8 . substr( $box, 4, 1 ) );
    }
    push( @board,
              substr( $box, 5, 1 )
            . substr( $box, 6, 1 ) x 8
            . substr( $box, 7, 1 ) );
    if ( $legend eq 'yes' ) {
        my $left = $FontMap{$type}{
            $single
            ? 'SingleLeftLegend'
            : 'DoubleLeftLegend'
        };
        my $bottom = $FontMap{$type}{
            $single
            ? 'SingleBottomLegend'
            : 'DoubleBottomLegend'
        };

        for ( 1 .. 8 ) {
            substr( $board[$_], 0, 1 ) = substr( $left, $_ - 1, 1 );
        }
        substr( $board[-1], 1, 8 ) = $bottom;

    }
    return @board;
}

sub _mappiece {
    my $x         = shift;
    my $y         = shift;
    my $piece     = shift;
    my $ifonblack = shift;
    my $ifonwhite = shift;
    my $onwhite   = $onwhite[ ( $y * 8 ) + $x ];
    my $which     = index( 'pnbrqkPNBRQK_', $piece );

    return substr( $onwhite ? $ifonwhite : $ifonblack, $which, 1 );
}

sub epdgetboard {
    if ( my $epd = shift ) {
        epdset($epd);
    }
    return $w, $Kc, $Qc, $kc, $qc, %board;
}

sub epdfromto {
    my @moves = @_;
    my @movelist;

    epdset();
    for (@moves) {
        if ($_) {
            my ( $piece, $to, $from, $promotion ) = _movetype( $w, $_ );
            my $enpassant;
            my $ep = '-';
            my $castles = /O/ ? $_ : '';

            $Kc = 0 if $to eq 'h1';
            $Qc = 0 if $to eq 'a1';
            $kc = 0 if $to eq 'h8';
            $qc = 0 if $to eq 'a8';

            if ( $piece eq "P" ) {
                $piece = "p" if not $w;
                $promotion = lc($promotion) if $promotion and not $w;
                if ($from) {
                    $from .= substr( $to, 1, 1 );
                    if ($w) {
                        substr( $from, 1, 1 ) -= 1;
                    }
                    else {
                        $from++;
                    }
                }
                else {
                    $from = $to;

                    if ($w) {
                        substr( $from, 1, 1 ) -= 1;
                        unless ( $board{$from} ) {
                            $ep = $from;
                            substr( $from, 1, 1 ) -= 1;
                        }
                    }
                    else {
                        $from++;
                        unless ( $board{$from} ) {
                            $ep = $from;
                            $from++;
                        }
                    }
                }

                if ( substr( $from, 0, 1 ) ne substr( $to, 0, 1 ) ) {
                    if ( not $board{$to} ) {
                        $enpassant = $to;
                        if ($w) {
                            substr( $enpassant, 1, 1 )
                                = chr(
                                ord( substr( $enpassant, 1, 1 ) ) - 1 );
                        }
                        else {
                            substr( $enpassant, 1, 1 )
                                = chr(
                                ord( substr( $enpassant, 1, 1 ) ) + 1 );
                        }
                        $board{$enpassant} = undef;
                        $enpassant = defined($enpassant) ? $enpassant : '';
                        $from      = defined($from)      ? $from      : '';
                        $to        = defined($to)        ? $to        : '';
                    }
                }
                ( $board{$to}, $board{$from} )
                    = ( $promotion ? $promotion : $board{$from}, undef );
                $piece     = defined($piece)     ? $piece     : '';
                $from      = defined($from)      ? $from      : '';
                $to        = defined($to)        ? $to        : '';
                $promotion = defined($promotion) ? $promotion : '';
            }
            elsif ( $piece eq "KR" ) {
                my ( $k_from, $r_from ) = unpack( "A2A2", $from );
                my ( $k_to,   $r_to )   = unpack( "A2A2", $to );

                ( $board{$k_to}, $board{$k_from} )
                    = ( $board{$k_from}, undef );
                ( $board{$r_to}, $board{$r_from} )
                    = ( $board{$r_from}, undef );
                if ($w) {
                    $Kc = $Qc = 0;
                }
                else {
                    $kc = $qc = 0;
                }
            }
            else {
                my @piece_at;
                my @fromlist;

                $piece = lc($piece) if not $w;
                @piece_at = psquares( $piece, %board );
                if ($from) {
                    my @tmp;

                    $from = defined($from) ? $from : '';
                    if ( $from =~ /[a-h]/ ) {
                        for (@piece_at) {
                            push( @tmp, $_ )
                                if ( substr( $_, 0, 1 ) eq $from );
                        }
                    }
                    else {

                        for (@piece_at) {
                            push( @tmp, $_ )
                                if ( substr( $_, 1, 1 ) eq $from );
                        }
                    }
                    @piece_at = @tmp;
                }

                for my $square (@piece_at) {
                    for ( @{ $move_table{ uc($piece) }{$square} } ) {
                        push( @fromlist, $square ) if $_ eq $to;
                    }
                }
                if ( scalar(@fromlist) != 1 ) {
                    for (@fromlist) {
                        if (    _canmove( $piece, $to, $_, %board )
                            and _isLegal( $w, $_, $to, %board ) )
                        {
                            $from = $_;
                            last;
                        }
                    }
                }
                else {
                    $from = $fromlist[0];
                }
                if ( $piece =~ /[RrKk]/ ) {
                    if ( $piece eq 'R' ) {
                        $Kc = 0 if $from eq 'h1';
                        $Qc = 0 if $from eq 'a1';
                    }
                    elsif ( $piece eq 'r' ) {
                        $kc = 0 if $from eq 'h8';
                        $qc = 0 if $from eq 'a8';
                    }
                    elsif ( $piece eq 'K' ) {
                        $Kc = $Qc = 0;
                    }
                    else {
                        $kc = $qc = 0;
                    }
                }
                ( $board{$to}, $board{$from} ) = ( $board{$from}, undef );
                $piece = defined($piece) ? $piece : '';
                $from  = defined($from)  ? $from  : '';
                $to    = defined($to)    ? $to    : '';
            }
            my $movehash = {
                piece     => defined($piece)     ? $piece     : '',
                from      => defined($from)      ? $from      : '',
                to        => defined($to)        ? $to        : '',
                promotion => defined($promotion) ? $promotion : '',
                enpassant => defined($enpassant) ? $enpassant : '',
                castles   => defined($castles)   ? $castles   : '',
            };
            push( @movelist, $movehash );
            $w ^= 1;
        }
    }
    %board = ();
    return @movelist;
}

sub epdlist {
    my @moves = @_;
    my $debug = 0;
    my @epdlist;
    my $lineno = 1;

    if ( scalar @moves and $moves[-1] eq '1' ) {
        $debug = 1;
        pop @moves;
        if (%board) {
            print "\%board initialized\n";
        }
        else {
            print "\%board uninitialized\n";
        }
    }
    epdset();
    for (@moves) {
        _Print(%board) if $debug;
        if ($_) {
            my ( $piece, $to, $from, $promotion ) = _movetype( $w, $_ );
            my $enpassant;
            my $ep = '-';

            $Kc = 0 if $to eq 'h1';
            $Qc = 0 if $to eq 'a1';
            $kc = 0 if $to eq 'h8';
            $qc = 0 if $to eq 'a8';

            if ($debug) {
                print "Move[$lineno]='$_'";
                $lineno++;
                if ($piece) {
                    print ", piece='$piece'";
                    print ", to='$to'"               if $to;
                    print ", from='$from'"           if $from;
                    print ", promotion='$promotion'" if $promotion;
                }
                print "\n";
            }

            if ( $piece eq "P" ) {
                $piece = "p" if not $w;
                $promotion = lc($promotion) if $promotion and not $w;
                if ($from) {
                    $from .= substr( $to, 1, 1 );
                    if ($w) {
                        substr( $from, 1, 1 ) -= 1;
                    }
                    else {

                        $from++;
                    }
                }
                else {
                    $from = $to;

                    if ($w) {
                        substr( $from, 1, 1 ) -= 1;
                        unless ( $board{$from} ) {
                            $ep = $from;
                            substr( $from, 1, 1 ) -= 1;
                        }
                    }
                    else {
                        $from++;
                        unless ( $board{$from} ) {
                            $ep = $from;
                            $from++;
                        }
                    }
                }

                if ( substr( $from, 0, 1 ) ne substr( $to, 0, 1 ) ) {
                    if ( not $board{$to} ) {
                        $enpassant = $to;
                        if ($w) {
                            substr( $enpassant, 1, 1 )
                                = chr(
                                ord( substr( $enpassant, 1, 1 ) ) - 1 );
                        }
                        else {
                            substr( $enpassant, 1, 1 )
                                = chr(
                                ord( substr( $enpassant, 1, 1 ) ) + 1 );
                        }
                        $board{$enpassant} = undef;
                        if ($debug) {
                            print "\$enpassant='$enpassant' " if $enpassant;
                            print "\$from='$from' "           if $from;
                            print "\$to='$to'"                if $to;
                            print "\n";
                        }
                    }
                }
                ( $board{$to}, $board{$from} )
                    = ( $promotion ? $promotion : $board{$from}, undef );
                if ($debug) {
                    print "\$piece='$piece' "         if $piece;
                    print "\$from='$from' "           if $from;
                    print "\$to='$to' "               if $to;
                    print "\$promotion='$promotion' " if $promotion;
                }
                push( @epdlist, epd( $w, $Kc, $Qc, $kc, $qc, $ep, %board ) );
                if ($debug) {
                    print "$epdlist[-1]\n";
                }
            }
            elsif ( $piece eq "KR" ) {
                my ( $k_from, $r_from ) = unpack( "A2A2", $from );
                my ( $k_to,   $r_to )   = unpack( "A2A2", $to );

                ( $board{$k_to}, $board{$k_from} )
                    = ( $board{$k_from}, undef );
                ( $board{$r_to}, $board{$r_from} )
                    = ( $board{$r_from}, undef );
                if ($w) {
                    $Kc = $Qc = 0;
                }
                else {
                    $kc = $qc = 0;
                }
                if ($debug) {
                    print $w ? "White" : "Black",
                        " castles from $k_from to $k_to\n";
                }
                push( @epdlist, epd( $w, $Kc, $Qc, $kc, $qc, $ep, %board ) );
                if ($debug) {
                    print "$epdlist[-1]\n";
                }
            }
            else {
                my @piece_at;
                my @fromlist;

                $piece = lc($piece) if not $w;
                @piece_at = psquares( $piece, %board );
                if ($debug) {
                    print "\@piece_at=", join( ",", @piece_at ), "\n"
                        if @piece_at;
                }
                if ($from) {
                    my @tmp;

                    if ($debug) {
                        print "\$from='$from'\n" if $from;
                    }
                    if ( $from =~ /[a-h]/ ) {
                        for (@piece_at) {
                            push( @tmp, $_ )
                                if ( substr( $_, 0, 1 ) eq $from );
                        }
                    }
                    else {

                        for (@piece_at) {
                            push( @tmp, $_ )
                                if ( substr( $_, 1, 1 ) eq $from );
                        }
                    }
                    @piece_at = @tmp;
                }

                for my $square (@piece_at) {
                    for ( @{ $move_table{ uc($piece) }{$square} } ) {
                        push( @fromlist, $square ) if $_ eq $to;
                    }
                }
                print "scalar \@fromlist = ", scalar(@fromlist), "\n"
                    if $debug;
                if ( scalar(@fromlist) != 1 ) {
                    if ($debug) {
                        print "\@fromlist=", join( ",", @fromlist ), "\n"
                            if @fromlist;
                    }
                    for (@fromlist) {
                        if (    _canmove( $piece, $to, $_, %board )
                            and _isLegal( $w, $_, $to, %board ) )
                        {
                            $from = $_;
                            last;
                        }
                    }
                }
                else {
                    $from = $fromlist[0];
                }
                if ( $piece =~ /[RrKk]/ ) {
                    if ( $piece eq 'R' ) {
                        $Kc = 0 if $from eq 'h1';
                        $Qc = 0 if $from eq 'a1';
                    }
                    elsif ( $piece eq 'r' ) {
                        $kc = 0 if $from eq 'h8';
                        $qc = 0 if $from eq 'a8';
                    }
                    elsif ( $piece eq 'K' ) {
                        $Kc = $Qc = 0;
                    }
                    else {
                        $kc = $qc = 0;
                    }
                }
                ( $board{$to}, $board{$from} ) = ( $board{$from}, undef );
                if ($debug) {
                    print "\@piece_at=", join( ",", @piece_at ), "\n"
                        if @piece_at;
                    print "\$piece='$piece' " if $piece;
                    print "\$from='$from' "   if $from;
                    print "\$to='$to' "       if $to;
                }
                push( @epdlist, epd( $w, $Kc, $Qc, $kc, $qc, $ep, %board ) );
                if ($debug) {
                    print "$epdlist[-1]\n";
                }
                if ( not $from ) {
                    _ShowPieces(%board);
                    _Print(%board);
                    print "From undefined\n";
                    exit;
                }
            }
            $w ^= 1;
        }
    }
    %board = ();
    return @epdlist;
}

sub _isLegal {
    my ( $w, $from, $to, %board ) = @_;
    my %board_copy = %board;
    my $kings_square;
    my @attack_list;

    ( $board_copy{$to}, $board_copy{$from} ) = ( $board_copy{$from}, undef );
    my $findking = $w ? 'K' : 'k';
    for ( keys %board_copy ) {
        if ( $board_copy{$_} and ( $board_copy{$_} eq $findking ) ) {
            $kings_square = $_;
            last;
        }
    }
    my $mask = $w ? 'qrnbp' : 'QRNBP';
    for my $square ( keys %board_copy ) {
        if ( $board_copy{$square} and $mask =~ /$board_copy{$square}/ ) {
            for ( @{ $move_table{ uc( $board_copy{$square} ) }{$square} } ) {
                push( @attack_list, $square ) if $_ eq $kings_square;
            }
        }
    }
    for (@attack_list) {
        if ( _canmove( $board_copy{$_}, $kings_square, $_, %board_copy ) ) {
            return 0;
        }
    }
    return 1;
}

sub _ShowPieces {
    my %board = @_;

    for my $square ( keys %board ) {
        my $piece = $board{$square};
        next unless $piece;
        print "'$square' == ", $piece, "\n";
    }
    return;
}

sub _Print {
    my (%board)     = @_;
    my $whitesquare = 1;
    my @rows        = (
        [qw(a8 b8 c8 d8 e8 f8 g8 h8)], [qw(a7 b7 c7 d7 e7 f7 g7 h7)],
        [qw(a6 b6 c6 d6 e6 f6 g6 h6)], [qw(a5 b5 c5 d5 e5 f5 g5 h5)],
        [qw(a4 b4 c4 d4 e4 f4 g4 h4)], [qw(a3 b3 c3 d3 e3 f3 g3 h3)],
        [qw(a2 b2 c2 d2 e2 f2 g2 h2)], [qw(a1 b1 c1 d1 e1 f1 g1 h1)]
    );

    for ( 0 .. 7 ) {
        print "\n", 8 - $_, "  ";
        for ( @{ $rows[$_] } ) {
            if ( $board{$_} ) {
                print $board{$_};
            }
            elsif ($whitesquare) {
                print ' ';
            }
            else {
                print '-';
            }
            $whitesquare ^= 1;
        }
        $whitesquare ^= 1;
    }
    print "\n   abcdefgh\n\n";
    return;
}

sub _movetype {
    my ( $w, $move ) = @_;
    my @result = "'$move':Not yet handled";
    my $from;
    my $to;

    if ( $move =~ /^O-O(?:\+|\#)?$/ ) {
        if ($w) {
            $from = "e1h1";
            $to   = "g1f1";
        }
        else {
            $from = "e8h8";
            $to   = "g8f8";
        }
        @result = ( "KR", $to, $from );
    }
    elsif ( $move =~ /^O-O-O(?:\+|\#)?$/ ) {

        if ($w) {
            $from = "e1a1";
            $to   = "c1d1";
        }
        else {
            $from = "e8a8";
            $to   = "c8d8";
        }
        @result = ( "KR", $to, $from );
    }
    elsif ( $move =~ /^([2-7])([a-h][1-8])(?:\+|\#)?$/ ) {
        @result = ( "P", $2 );
    }
    elsif ( $move =~ /^([a-h][1-8])(?:\+|\#)?$/ ) {
        @result = ( "P", $1 );
    }
    elsif ( $move =~ /^([a-h])x?([a-h][1-8])(?:\+|\#)?$/ ) {
        @result = ( "P", $2, $1 );
    }
    elsif ( $move =~ /^([a-h][18])=?([RNBQ])(?:\+|\#)?$/ ) {
        @result = ( "P", $1, undef, $2 );
    }
    elsif ( $move =~ /^([a-h])x([a-h][18])=?([RNBQ])(?:\+|\#)?$/ ) {
        @result = ( "P", $2, $1, $3 );
    }
    elsif ( $move =~ /^([RNBQK])([a-h][1-8])(?:\+|\#)?$/ ) {
        @result = ( $1, $2 );
    }
    elsif ( $move =~ /^([RNBQK])x([a-h][1-8])(?:\+|\#)?$/ ) {
        @result = ( $1, $2 );
    }
    elsif ( $move =~ /^([RNBQK])([a-h]|[1-8])([a-h][1-8])(?:\+|\#)?$/ ) {
        @result = ( $1, $3, $2 );
    }
    elsif ( $move =~ /^([RNBQK])([a-h][1-8])([a-h][1-8])(?:\+|\#)?$/ ) {
        @result = ( $1, $3, $2 );
    }
    elsif ( $move =~ /^([RNBQK])([a-h]|[1-8])x([a-h][1-8])(?:\+|\#)?$/ ) {
        @result = ( $1, $3, $2 );
    }
    elsif ( $move =~ /^([RNBQK])([a-h][1-8])x([a-h][1-8])(?:\+|\#)?$/ ) {
        @result = ( $1, $3, $2 );
    }
    return @result;
}

sub psquares {
    my ( $piece, %board ) = @_;

    return grep { $_ and $board{$_} and ( $board{$_} eq $piece ) }
        sort keys %board;
}

sub epd {
    my ( $w, $Kc, $Qc, $kc, $qc, $ep, %board ) = @_;
    my @key = qw(
        a8 b8 c8 d8 e8 f8 g8 h8
        a7 b7 c7 d7 e7 f7 g7 h7
        a6 b6 c6 d6 e6 f6 g6 h6
        a5 b5 c5 d5 e5 f5 g5 h5
        a4 b4 c4 d4 e4 f4 g4 h4
        a3 b3 c3 d3 e3 f3 g3 h3
        a2 b2 c2 d2 e2 f2 g2 h2
        a1 b1 c1 d1 e1 f1 g1 h1
    );
    my $n;
    my $piece;
    my $epd;

    for ( 0 .. 63 ) {
        if ( $_ and ( $_ % 8 ) == 0 ) {
            if ($n) {
                $epd .= "$n";
                $n = 0;
            }
            $epd .= "/";
        }
        $piece = $board{ $key[$_] };

        if ($piece) {
            if ($n) {
                $epd .= "$n";
                $n = 0;
            }
            $epd .= $piece;
        }
        else {
            $n++;
        }
    }

    $epd .= "$n" if $n;
    $epd .= ( $w ? " b" : " w" );

    if ( $Kc or $Qc or $kc or $qc ) {
        $epd .= " ";
        $epd .= "K" if $Kc;
        $epd .= "Q" if $Qc;
        $epd .= "k" if $kc;
        $epd .= "q" if $qc;
    }
    else {
        $epd .= " -";
    }
    $epd .= " $ep";
    return $epd;
}

sub _canmove {
    my ( $piece, $to, $from, %board ) = @_;
    my $lto;
    my $rto;
    my $lfrom;
    my $rfrom;
    my $result  = 1;
    my $offset  = 1;
    my $roffset = 1;
    my $loffset = 1;
    my $c       = 0;

    $to =~ /(.)(.)/;
    ( $lto, $rto ) = ( $1, $2 );
    $from =~ /(.)(.)/;
    ( $lfrom, $rfrom ) = ( $1, $2 );

    if ( $board{$from} and $board{to} ) {
        if ( defined( $board{$from} ) and defined( $board{$to} ) ) {
            if ( $board{$from}->color() == $board{$to}->color() ) {
                $result = 0;
            }
        }
    }
    elsif ( ( $rto eq $rfrom ) or ( $lto eq $lfrom ) ) {

        if (   ( $rto eq $rfrom and $lto lt $lfrom )
            or ( $lto eq $lfrom and $rto lt $rfrom ) )
        {
            $offset = -1;
        }

        if ( $lto eq $lfrom ) {
            $c = 1;
        }
        while ( $from ne $to ) {
            substr( $from, $c, 1 )
                = chr( ord( substr( $from, $c, 1 ) ) + $offset );
            if ( defined( $board{$from} ) ) {
                $result = 0 if ( $from ne $to );
                last;
            }
        }
    }
    elsif ( $piece =~ /[bq]/i ) {

        if ( $rto lt $rfrom ) {
            $roffset = -1;
        }
        if ( $lto lt $lfrom ) {
            $loffset = -1;
        }
        while ( $from ne $to ) {
            substr( $from, 0, 1 )
                = chr( ord( substr( $from, 0, 1 ) ) + $loffset );
            substr( $from, 1, 1 )
                = chr( ord( substr( $from, 1, 1 ) ) + $roffset );
            if ( defined( $board{$from} ) ) {
                $result = 0 if ( $from ne $to );
                last;
            }
        }
    }
    return $result;
}

sub epdTaxonomy {
    my (%options) = @_;
    my @moves = @{ $options{'moves'} };
    my @results;
    my ( $eco, $nic, $opening );
    my @epd = reverse( epdlist(@moves) );

    if ( $options{'all'} ) {
        $eco     = epdcode( 'ECO',     \@epd );
        $nic     = epdcode( 'NIC',     \@epd );
        $opening = epdcode( 'Opening', \@epd );
    }
    else {
        for ( lc( keys %options ) ) {
            if ( $_ eq 'eco' ) {
                $eco = epdcode( 'ECO', \@epd );
            }
            elsif ( $_ eq 'nic' ) {
                $nic = epdcode( 'NIC', \@epd );
            }
            elsif ( $_ eq 'Opening' ) {
                $opening = epdcode( 'Opening', \@epd );
            }
        }
    }
    if ( $options{'astags'} ) {
        push( @results, "[ECO \"$eco\"]" )         if $eco;
        push( @results, "[NIC \"$nic\"]" )         if $nic;
        push( @results, "[Opening \"$opening\"]" ) if $opening;
    }
    else {
        push( @results, $eco )     if $eco;
        push( @results, $nic )     if $nic;
        push( @results, $opening ) if $opening;
    }
    return @results;
}

1;
__END__

=for readme start

=head1 NAME

Chess::PGN::EPD - Perl extension to produce and manipulate EPD text.

=head1 VERSION

version 0.34

=head1 SYNOPSIS

From "Working With Epd Files" by Steve Lopez <http://www.chessbaseusa.com/portals/6/tn/Issues_Back/1999_autumn/1999_1031.htm>,

"There's a lot of chess information available on the Internet in a variety of formats. One of these is called
EPD (Extended Position Description) format; it's just a convenient way to provide a board position (rather than
a full game) in an ASCII text notation. For example, here's what the board position after 1.e4 looks like in
EPD format:

    rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1

This was designed as a way for chess players and chess programs to pass board positions back and forth for
analysis. You'll frequently see posts to Usenet chess newsgroups or other message boards containing these
EPD positions.

There's a quick, easy way to copy and paste these board descriptions into ChessBase or any of our playing programs
(Fritz, Hiarcs, Nimzo, Junior). Just highlight the EPD line from a post or web page and hit CRTL-C on your keyboard.
Then open ChessBase, go to the Game menu, select "Setup position", and click the button marked "Paste FEN". You'll
instantly see the position appear on the board in the "Setup position" window. Click "OK" and you'll now have an
"Enter new game" window with the proper board position on it taken from the EPD file. You can then save the position
into a database just like any other game..."

Chess::PGN::EPD attempts to bring ease and convenience to its users programmatically by providing a set of
functions that manipulate EPD text.

=for readme stop

=head2 CODE examples

B<THIS>

 #!/usr/bin/perl
 #
 #
 use warnings;
 use strict;
 use Chess::PGN::Parse;
 use Chess::PGN::EPD;

 if ($ARGV[0]) {
     my $pgn = new Chess::PGN::Parse($ARGV[0]) or die "Can't open $ARGV[0]: $!\n";
     while ($pgn->read_game()) {
         $pgn->parse_game();
         print join ( "\n", epdlist(  @{$pgn->moves()} ) ), "\n\n";
     }
 }

B<OR>

 #!/usr/bin/perl
 #
 #
 use warnings;
 use strict;
 use Chess::PGN::EPD;

 my $position = 'rnbqkb1r/ppp1pppp/5n2/3P4/8/8/PPPP1PPP/RNBQKBNR w KQkq -';
 print join("\n",epdstr(epd => $position,type => 'latex'));

B<OR>

 #!/usr/bin/perl
 #
 #
 use strict;
 use warnings;
 use Chess::PGN::Parse;
 use Chess::PGN::EPD;

 if ($ARGV[0]) {
     my $pgn = new Chess::PGN::Parse($ARGV[0]) or die "Can't open $ARGV[0]: $!\n";
     while ($pgn->read_game()) {
         my @epd;

         $pgn->parse_game();
         my @moves = @{ $game{'GameMoves'} };
         print join("\n",epdTaxonomy(moves => \@moves,all => 1,astags => 1)),"\n";
     }
 }

=head1 DESCRIPTION

=head2 epdcode(I<code>,I<epdlistref>)

Determines the requested code given a list of B<epd> strings in reverse order.
Allowed codes are:

=over

=item 'ECO' from The Encyclopedia of Chess Openings.

=item 'NIC' from New in Chess.

=item 'Opening' Traditional Opening name in English.

=back

At the moment, this routine depends on three database files installed along with
the module. On demand other formats (the current is JSON) may be implemented. The 'ToDo' list
also mentions the possibility of extending the databases, although that might come in
the form of a 'How To' rather than any code solution. NOTE: This routine is deprecated
in favor of epdTaxonomy and will at some point be removed.

=head2 epdfromto(I<movelist>)

Returns an array of hashes that contain move information. Useful for conversions to other
forms of notation; i.e. telegraphic or english notation.

=head2 epdgetboard([I<epd>])

Provides access to the 'board' with the current epd postition set up. If given an EPD string,
set board accordingly. The returned values are:

=over

=item $w - boolean, white to move?

=item $Kc - boolean, has white castled king side?

=item $Qc - boolean, has white castled queen side?

=item $kc - boolean, has black castled king side?

=item $qc - boolean, has black castled queen side?

=item %board - hash board, keys are algebraic square names, values are occupying piece.

=back

=head2 epdlist(I<movelist>)

Returns an array of strings that represent the conversion of
game text into positional shorthand, one entry for each move
made in the game.

=head3 Concepts

B<EPD>

"Extended Position Description" is a standard for describing chess
positions along with an extended set of structured attribute values using the
ASCII character set.  It is intended for data and command interchange among
chessplaying programs.  It is also intended for the representation of portable
opening library repositories.

A single EPD uses one text line of variable length composed of four data field
followed by zero or more operations.  The four fields of the EPD specification
are the same as the first four fields of the FEN specification.

A text file composed exclusively of EPD data records should have a file name
with the suffix ".epd".

EPD is based in part on the earlier FEN standard; it has added extensions for
use with opening library preparation and also for general data and command
interchange among advanced chess programs.  EPD was developed by John Stanback
and Steven Edwards; its first implementation is in Stanback's master strength
chessplaying program Zarkov.

Like FEN, EPD can also be used for general position description.  However,
unlike FEN, EPD is designed to be expandable by the addition of new operations
that provide new functionality as needs arise.

B<FEN>

"Forsyth-Edwards Notation" is a standard for describing chess
positions using the ASCII character set.

A single FEN record uses one text line of variable length composed of six data
fields.  The first four fields of the FEN specification are the same as the
first four fields of the EPD specification.

A text file composed exclusively of FEN data records should have a file name
with the suffix ".fen".

B<History>

FEN is based on a 19th century standard for position recording designed by the
Scotsman David Forsyth, a newspaper journalist.  The original Forsyth standard
has been slightly extended for use with chess software by Steven Edwards with
assistance from commentators on the Internet.

B<Uses for a position notation>

Having a standard position notation is particularly important for chess
programmers as it allows them to share position databases.  For example, there
exist standard position notation databases with many of the classical benchmark
tests for chessplaying programs, and by using a common position notation format
many hours of tedious data entry can be saved.  Additionally, a position
notation can be useful for page layout programs and for confirming position
status for e-mail competition.

B<Data fields>

FEN specifies the piece placement, the active color, the castling availability,
the en passant target square, the halfmove clock, and the fullmove number.
These can all fit on a single text line in an easily read format.  The length
of a FEN position description varies somewhat according to the position. In
some cases, the description could be eighty or more characters in length and so
may not fit conveniently on some displays.  However, these positions aren't too
common.

A FEN description has six fields.  Each field is composed only of non-blank
printing ASCII characters.  Adjacent fields are separated by a single ASCII
space character.

=over

=item Piece placement data

The first field represents the placement of the pieces on the board.  The board
contents are specified starting with the eighth rank and ending with the first
rank.  For each rank, the squares are specified from file a to file h.  White
pieces are identified by uppercase SAN piece letters ("PNBRQK") and black
pieces are identified by lowercase SAN piece letters ("pnbrqk").  Empty squares
are represented by the digits one through eight; the digit used represents the
count of contiguous empty squares along a rank.  A solidus character "/" is
used to separate data of adjacent ranks.

=item Active color

The second field represents the active color.  A lower case "w" is used if
White is to move; a lower case "b" is used if Black is the active player.

=item Castling availability

The third field represents castling availability.  This indicates potential
future castling that may of may not be possible at the moment due to blocking
pieces or enemy attacks.  If there is no castling availability for either side,
the single character symbol "-" is used.  Otherwise, a combination of from one
to four characters are present.  If White has kingside castling availability,
the uppercase letter "K" appears.  If White has queenside castling
availability, the uppercase letter "Q" appears.  If Black has kingside castling
availability, the lowercase letter "k" appears.  If Black has queenside
castling availability, then the lowercase letter "q" appears.  Those letters
which appear will be ordered first uppercase before lowercase and second
kingside before queenside.  There is no white space between the letters.

=item En passant target square

The fourth field is the en passant target square.  If there is no en passant
target square then the single character symbol "-" appears.  If there is an en
passant target square then is represented by a lowercase file character
immediately followed by a rank digit.  Obviously, the rank digit will be "3"
following a white pawn double advance (Black is the active color) or else be
the digit "6" after a black pawn double advance (White being the active color).

An en passant target square is given if and only if the last move was a pawn
advance of two squares.  Therefore, an en passant target square field may have
a square name even if there is no pawn of the opposing side that may
immediately execute the en passant capture.

=item Halfmove clock

The fifth field is a nonnegative integer representing the halfmove clock.  This
number is the count of halfmoves (or ply) since the last pawn advance or
capturing move.  This value is used for the fifty move draw rule.

=item Fullmove number

The sixth and last field is a positive integer that gives the fullmove number.
This will have the value "1" for the first move of a game for both White and
Black.  It is incremented by one immediately after each move by Black.

=back

B<Examples>

Here's the FEN for the starting position:

rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1

And after the move 1. e4:

rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1

And then after 1. ... c5:

rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2

And then after 2. Nf3:

rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2

For two kings on their home squares and a white pawn on e2 (White to move) with
thirty eight full moves played with five halfmoves since the last pawn move or
capture:

4k3/8/8/8/8/8/4P3/4K3 w - - 5 39

=head3 NOTE

With only a little observation, the astute user will notice that actually this function
doesn't return either EPD or FEN, but rather a bit of both. It is mostly FEN, but it lacks
the Fullmove number field, since for most usage that information is available else where
or can easily be reconstructed. As to why the module is called EPD, well I figured since it
wasn't one and it wasn't the other, that left it up to me to choose--besides, who would want
a module named after a swamp?!

=head2 epdset(I<epd>)

For those instances where the game in question does not begin
with a complete move list, this function allows the user to
set the starting position using a 'EPD' string as described
elsewhere in the document.

=head2 epdstr(I<epd>|I<board>,I<type> [I<border>,I<corner>,I<legend>])

Returns an array of strings that represent a diagramatic conversion of the
specified B<epd> string or board postion to the specified B<type>. Parameters are passed as
a anonymous hash, i.e. epdstr(epd => $position,type => 'diagram') or similar.

=head3 Types Supported

The following types are understood by B<epdstr>:

=over

=item 'diagram'

A plain ASCII diagram with simple border showing rank and file. Typical output:

 8  rnbqkb r
 7  ppp pppp
 6   - - n -
 5  - -P- -
 4   - - - -
 3  - - - -
 2  PPPP PPP
 1  RNBQKBNR
    abcdefgh

=item 'text'

A plain ASCII diagram. Typical output:

 rnbqkb r
 ppp pppp
  - - n -
 - -P- -
  - - - -
 - - - -
 PPPP PPP
 RNBQKBNR

=item 'palview'

An array of HTML information that represents the tabular diagram information for PalView.
Typical output:

<IMG SRC="jpc/br.gif"><IMG SRC="jpc/bn.gif"><IMG SRC="jpc/bb.gif"><IMG SRC="jpc/bq.gif"><IMG
SRC="jpc/bk.gif"><IMG SRC="jpc/bb.gif"><IMG SRC="jpc/bn.gif"><IMG SRC="jpc/br.gif"><BR>
<IMG SRC="jpc/bp.gif"><IMG SRC="jpc/bp.gif"><IMG SRC="jpc/bp.gif"><IMG SRC="jpc/bp.gif"><IMG
SRC="jpc/bp.gif"><IMG SRC="jpc/bp.gif"><IMG SRC="jpc/bp.gif"><IMG SRC="jpc/bp.gif"><BR>
<IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG
SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><BR>
<IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG
SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><BR>
<IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG
SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><BR>
<IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG
SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/wn.gif"><BR>
<IMG SRC="jpc/wp.gif"><IMG SRC="jpc/wp.gif"><IMG SRC="jpc/wp.gif"><IMG SRC="jpc/wp.gif"><IMG
SRC="jpc/wp.gif"><IMG SRC="jpc/wp.gif"><IMG SRC="jpc/wp.gif"><IMG SRC="jpc/wp.gif"><BR>
<IMG SRC="jpc/wr.gif"><IMG SRC="jpc/wn.gif"><IMG SRC="jpc/wb.gif"><IMG SRC="jpc/wq.gif"><IMG
SRC="jpc/wk.gif"><IMG SRC="jpc/wb.gif"><IMG SRC="jpc/i.gif"><IMG SRC="jpc/wr.gif"><BR>

=item 'latex'

The necessary text fragment to 'set' the diagram in LaTeX using
any variation of Piet Tutelars original chess12.tar.Z package. As given, the LaTeX
command 'diagram' is used. As an example here is the source to test.tex:

 %%
 %% test.tex -- example LaTeX file to demonstrate output from Chess::PGN::EPD
 %%
 \documentclass{article}
 \usepackage{chess}
 \usepackage{bdfchess}
 \begin{document}
 \newenvironment{diagram}{\begin{nochess}}{$$\showboardwithnotation$$\end{nochess}}
 %%
 %% fragment as produced by epdstr(epd => $position,type => 'latex');
 %%
 \begin{diagram}
 \board
 {rnbqkb r}
 {ppp pppp}
 { * * n *}
 {* *P* * }
 { * * * *}
 {* * * * }
 {PPPP PPP}
 {RNBQKBNR}
 \end{diagram}
 %%
 %% end of fragment
 %%
 \end{document}

=item 'linares'

Alpine Electronics' LinaresDiagram font. Mapping also works with both HastingsDiagram
and ZurichDiagram fonts. Single or double border, With or without algebraic legend.

=item 'linares1'

Standard mapping, single border, squares offset.

=item 'linares2'

Standard mapping, thick single border.

=item 'tilburg'

A borderless font designed by Eric Schiller and Bill Cone.

=item 'marroquin'

This type refers to any font designed by Armando H. Marroquin,
excepting his FigurineSymbol fonts. They having a different purpose,
have a different mapping.

=item 'leschemelle'

The map for Chess Cases designed by Matthieu Leschemelle.

=item 'bentzen1'

The map for Chess Alpha designed by Eric Bentzen.

=item 'bentzen2'

The map for Chess Berlin designed by Eric Bentzen.

=item 'hickey'

The map for Chess Plain designed by Alan Hickey.

=item 'scott1'

The map for Chess Regular a port of Adobe Cheq ported to
True Type by Alistair Scott.

=item 'scott2'

The map for Chess Usual a modification of Chess Regular
by Armando H. Marroquin.

=item 'bodlaender'

The map for Chess Utrecht designed by Hans Bodlaender.

=item 'cowderoy'

The map for Traveller Standard v3  designed by Alan Cowderoy.

=back

Note that 'type' is not case sensative so that 'latex' and 'LaTeX' will both
work equally well.

=head3 Fonts Supported

List with font name, font author, and type name:

=over

=item Chess Cases -- Matthieu Leschemelle -- leschemelle

=item Chess Adventurer -- Armando H. Marroquin -- marroquin

=item Chess Alfonso-X -- Armando H. Marroquin -- marroquin

=item Chess Alpha -- Eric Bentzen -- bentzen1

=item Chess Berlin -- Eric Bentzen -- bentzen2

=item Chess Condal -- Armando H. Marroquin -- marroquin

=item Chess Harlequin -- Armando H. Marroquin -- marroquin

=item Chess Kingdom -- Armando H. Marroquin -- marroquin

=item Chess Leipzig -- Armando H. Marroquin -- marroquin

=item Chess Line -- Armando H. Marroquin -- marroquin

=item Chess Lucena -- Armando H. Marroquin -- marroquin

=item Chess Magnetic -- Armando H. Marroquin -- marroquin

=item Chess Mark -- Armando H. Marroquin -- marroquin

=item Chess Marroquin -- Armando H. Marroquin -- marroquin

=item Chess Maya -- Armando H. Marroquin -- marroquin

=item Chess Mediaeval -- Armando H. Marroquin -- marroquin

=item Chess Merida -- Armando H. Marroquin -- marroquin

=item Chess Millennia -- Armando H. Marroquin -- marroquin

=item Chess Miscel -- Armando H. Marroquin -- marroquin

=item Chess Montreal -- Gary Katch -- katch

=item Chess Motif -- Armando H. Marroquin -- marroquin

=item Chess Plain -- Alan Hickey -- hickey

=item Chess Regular -- Alistair Scott -- scott1

=item Chess Usual -- Armando H. Marroquin -- scott2

=item Chess Utrecht -- Hans Bodlaender -- bodlaender

=item Tilburg -- Eric Schiller and Bill Cone -- tilburg

=item Traveller Standard v3 -- Alan Cowderoy -- cowderoy

=back

These are available at L<http://www.enpassant.dk/chess/fonteng.htm> along
with a good deal of useful information on chess desktop publishing.

=head3 Font Designers Supported

=over

=item Eric Bentzen

=item Bill Cone

=item Alan Cowderoy

=item Alan Hickey

=item Gary Katch

=item Armondo H. Marroquin

=item Eric Schiller

=item Alastair Scott

=item Steve Smith

=item Piet Tutelaers

=back

=head3 Borders and Such Like

Some fonts, for example those designed by Armondo H. Marroquin support a variety of border
styles and decorations. The border may be single or double, with square corners or rounded,
and with an algebraic legend. These effects are supported by the addition of the necessary
parameters to the allowed parameter list. In particular:

=over

=item * Border, values can be either 'single' or 'double' (default is 'single')

=item * Corner, values can be either 'square' or 'rounded' (default is 'square')

=item * Legend, values can be either 'yes' or 'no' (default is 'no')

=back

Again, letter case is not particularly important, 'yes' works as well as 'Yes' etc.
As for those fonts that don't support a particular feature, B<epdstr> will fail silently, that
is, the parameter will be ignored and processing will continue as though no such request
had been made.

=head2 epdTaxonomy(I<options>)

At one point the following was required in order to properly 'tag' a PGN file with opening
names and information:

 if ($ARGV[0]) {
     my $pgn = new Chess::PGN::Parse($ARGV[0]) or die "Can't open $ARGV[0]: $!\n";
     while ($pgn->read_game()) {
         my @epd;

         $pgn->parse_game();
         @epd = reverse epdlist( @{$pgn->moves()} );
         print '[ECO,"',epdcode('ECO',\@epd),"\"]\n";
         print '[NIC,"',epdcode('NIC',\@epd),"\"]\n";
         print '[Opening,"',epdcode('Opening',\@epd),"\"]\n";
     }
 }

Not all that bad, but not all that clear either. As can be seen from the examples shown at the
begining of this documentation, I've created a new subroutine called epdTaxonomy that replaces
all of the above with:

 if ($ARGV[0]) {
     my $pgn = new Chess::PGN::Parse($ARGV[0]) or die "Can't open $ARGV[0]: $!\n";
     while ($pgn->read_game()) {
         my @epd;

         $pgn->parse_game();
         my @moves = @{ $game{'GameMoves'} };
         print join("\n",epdTaxonomy(moves => \@moves,all => 1,astags => 1)),"\n";
     }
 }

Clearly a win for the parsimonious team! This sub takes a single parameter, a hash with the following
possibilities:

=over

=item 'moves' -- required in order to have something to work with.

=item 'all' -- if true, create all three tags supported.

=item 'astags' -- if true, create complete PGN header tags for the specified codes.

=item 'eco' -- create tag information for ECO codes.

=item 'nic' -- create tag information for NIC codes.

=item 'opening' -- create tag information for Opening codes.

=back

See the description of epdcode for brief descriptions of what these codes represent.

=head2 psquares(I<piece>,I<board>)

Given a 'piece' (single character, uppercase for white, lowercase for black, KQRBNPkqrbnp) and
the current board hash, return a list of square names (algebraic) locating instances of the
piece.

=head1 EXPORT

=over

=item epdcode - given a list of EPD strings, return the requested code or 'unknown'.

=item epdfromto - given a list of moves, return an array of hashes which contain move information.

=item epdgetboard - given an EPD string setup board and related. Either way return board and related
information.

=item epdlist - given a list of moves, return a list of EPD strings.

=item epdset - allows the user to specifiy an initial position.

=item epdstr - given an EPD string or a board, convert it to the specified string representation.

=item epdTaxonomy - one stop shopping for conversion of epd array to ECO, NIC and opening tag information.

=item psquares - given the piece and the board, generate and return a list of squares occupied by that
type of piece.

=back

=head1 DEPENDENCIES

=over

=item Chess::PGN::Moves     => 0.05

=item Chess::PGN::Parse     => 0.20

=item Test::More            => 0.94

=item File::ShareDir        => 1.102

=item File::Slurper         => 0.008

=item Cpanel::JSON::XS      => 3.0213

=back

=head1 TODO

=over

=item Continue to improve documentation.

=item oo-ify support variables.

=item Allow font map customization.

=item Solve the english to algebraic problem.

=back

=head1 KNOWN BUGS

None known; Unknown? Of course, though I try to be neat...

=for readme start

=for readme plugin version

=for readme plugin changes

=for readme plugin requires

=head1 INSTALLATION

Traditional recipe based on Makefile.PL:

    perl Makefile.PL
    make
    make test
    make install

Note that some distributions will have a Build.PL file instead of
or in addition to Makefile.PL. In that case use this recipe:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=head1 AUTHOR

Hugh S. Myers <hsmyers@gmail.com>

=head1 LICENSE

             The "Artistic License"

                Preamble

The intent of this document is to state the conditions under which a
Package may be copied, such that the Copyright Holder maintains some
semblance of artistic control over the development of the package,
while giving the users of the package the right to use and distribute
the Package in a more-or-less customary fashion, plus the right to make
reasonable modifications.

Definitions:

    "Package" refers to the collection of files distributed by the
    Copyright Holder, and derivatives of that collection of files
    created through textual modification.

    "Standard Version" refers to such a Package if it has not been
    modified, or has been modified in accordance with the wishes
    of the Copyright Holder as specified below.

    "Copyright Holder" is whoever is named in the copyright or
    copyrights for the package.

    "You" is you, if you're thinking about copying or distributing
    this Package.

    "Reasonable copying fee" is whatever you can justify on the
    basis of media cost, duplication charges, time of people involved,
    and so on.  (You will not be required to justify it to the
    Copyright Holder, but only to the computing community at large
    as a market that must bear the fee.)

    "Freely Available" means that no fee is charged for the item
    itself, though there may be fees involved in handling the item.
    It also means that recipients of the item may redistribute it
    under the same conditions they received it.

1. You may make and give away verbatim copies of the source form of the
Standard Version of this Package without restriction, provided that you
duplicate all of the original copyright notices and associated disclaimers.

2. You may apply bug fixes, portability fixes and other modifications
derived from the Public Domain or from the Copyright Holder.  A Package
modified in such a way shall still be considered the Standard Version.

3. You may otherwise modify your copy of this Package in any way, provided
that you insert a prominent notice in each changed file stating how and
when you changed that file, and provided that you do at least ONE of the
following:

    a) place your modifications in the Public Domain or otherwise make them
    Freely Available, such as by posting said modifications to Usenet or
    an equivalent medium, or placing the modifications on a major archive
    site such as uunet.uu.net, or by allowing the Copyright Holder to include
    your modifications in the Standard Version of the Package.

    b) use the modified Package only within your corporation or organization.

    c) rename any non-standard executables so the names do not conflict
    with standard executables, which must also be provided, and provide
    a separate manual page for each non-standard executable that clearly
    documents how it differs from the Standard Version.

    d) make other distribution arrangements with the Copyright Holder.

4. You may distribute the programs of this Package in object code or
executable form, provided that you do at least ONE of the following:

    a) distribute a Standard Version of the executables and library files,
    together with instructions (in the manual page or equivalent) on where
    to get the Standard Version.

    b) accompany the distribution with the machine-readable source of
    the Package with your modifications.

    c) give non-standard executables non-standard names, and clearly
    document the differences in manual pages (or equivalent), together
    with instructions on where to get the Standard Version.

    d) make other distribution arrangements with the Copyright Holder.

5. You may charge a reasonable copying fee for any distribution of this
Package.  You may charge any fee you choose for support of this
Package.  You may not charge a fee for this Package itself.  However,
you may distribute this Package in aggregate with other (possibly
commercial) programs as part of a larger (possibly commercial) software
distribution provided that you do not advertise this Package as a
product of your own.  You may embed this Package's interpreter within
an executable of yours (by linking); this shall be construed as a mere
form of aggregation, provided that the complete Standard Version of the
interpreter is so embedded.

6. The scripts and library files supplied as input to or produced as
output from the programs of this Package do not automatically fall
under the copyright of this Package, but belong to whoever generated
them, and may be sold commercially, and may be aggregated with this
Package.  If such scripts or library files are aggregated with this
Package via the so-called "undump" or "unexec" methods of producing a
binary executable image, then distribution of such an image shall
neither be construed as a distribution of this Package nor shall it
fall under the restrictions of Paragraphs 3 and 4, provided that you do
not represent such an executable image as a Standard Version of this
Package.

7. C subroutines (or comparably compiled subroutines in other
languages) supplied by you and linked into this Package in order to
emulate subroutines and variables of the language defined by this
Package shall not be considered part of this Package, but are the
equivalent of input as in Paragraph 6, provided these subroutines do
not change the language in any way that would cause it to fail the
regression tests for the language.

8. Aggregation of this Package with a commercial distribution is always
permitted provided that the use of this Package is embedded; that is,
when no overt attempt is made to make this Package's interfaces visible
to the end user of the commercial distribution.  Such use shall not be
construed as a distribution of this Package.

9. The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written permission.

10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

                The End

=head1 COPYRIGHT

Copyright (C) 2017 Hugh S. Myers
=end :readme
