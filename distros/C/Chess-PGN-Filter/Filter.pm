package Parms;

use strict;
use warnings;
use Chess::PGN::EPD;
use vars '$AUTOLOAD';
use Carp;

sub new {
    my ($class,%arg) = @_;
    bless {
        _verbose => defined $arg{verbose} ? $arg{verbose} : 1, #default legacy verbose
        _filtertype => $arg{filtertype},
        _source => $arg{source},
        _fen => $arg{fen} || 'no',
        _position => $arg{position} || 'yes',
        _type => $arg{type} || ($arg{font} || 'marroquin'),
        _border => $arg{single} || 'single',
        _corner => $arg{square} || 'square',
        _legend => $arg{legend} || 'no',
        _size => $arg{size} || '5',
        _font => $arg{font} || 'Chess Kingdom',
        _ECO => $arg{ECO} || 'yes',
        _NIC => $arg{NIC} || 'no',
        _Opening => $arg{Opening} || 'yes',
        _substitutions => $arg{substitutions},
        _exclude => $arg{exclude},
        _comments => $arg{comments} || 'yes',
        _nags => $arg{nags} || 'yes',
        _ravs => $arg{ravs} || 'yes',
        _sticky => $arg{sticky} || 'yes',
        _autoround => $arg{autoround} || 'yes',
        _event => '',
        _site => '',
        _date => '',
        _round => '',
    }, $class;
}

sub AUTOLOAD {
    my ($self,$newval) = @_;

    $AUTOLOAD =~ /.*::get(_\w+)/ and return $self->{$1};
    $AUTOLOAD =~ /.*::set(_\w+)/ and do { $self->{$1} = $newval; return };
    $AUTOLOAD =~ /.*::if(_\w+)/ and return ($self->{$1} eq 'yes');
    croak "No such method: $AUTOLOAD\n";
}

sub DESTROY {
}

package Chess::PGN::Filter;

use 5.006;
use strict;
use warnings;
use Chess::PGN::Parse;
use Chess::PGN::EPD;
use Text::DelimMatch;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    &filter
);
our $VERSION = '0.15';


sub filter {
    my $parameters = new Parms(@_);
    my $filtered;
    if ($parameters->get_filtertype() eq 'XML') {
        $filtered = filterXML(@_);
    }
    elsif ($parameters->get_filtertype() eq 'TEXT') {
        $filtered = filterTEXT(@_);
    }
    elsif ($parameters->get_filtertype() eq 'DOM') {
        $filtered = [ filterDOM(@_) ];
    }
    else {
        die "Unknown filtertype: '$parameters->get_filtertype()' not supported.\n";
    }
    if ($parameters->get_verbose()) {
        print $parameters->get_filtertype() eq 'DOM' ? Dumper(@$filtered) : $filtered;
    }
    else {
        return $filtered;
    }
}

sub filterDOM {
    my $parms = new Parms(@_);
    my $file = $parms->get_source();
    my $filetext;
    
    {
        local $/ = undef;
        open(FILE,$file) or die "Couldn't open file:$file $!\n";
        $filetext = <FILE>;
        close(FILE);
    }
    return getDOM($filetext);
}

sub filterTEXT {
    my $parms = new Parms(@_);
    my $file = $parms->get_source();
    my @DOM;
    my $filetext;
    my $text = '';

    {
        local $/ = undef;
        open(FILE,$file) or die "Couldn't open file:$file $!\n";
        $filetext = <FILE>;
        close(FILE);
    }
    @DOM = getDOM($filetext);
    foreach (@DOM) {
        my $termination =  ($_->{'Tags'}->{'Result'} =~ /^1-0|0-1|1\/2-1\/2|\*$/ ? $_->{'Tags'}->{'Result'} : '*');
        my $movetext;
        my $move = 1;

        domExTags($parms,$_->{'Tags'}) if $parms->get_exclude();
        domSticky($parms,$_->{'Tags'}) if $parms->if_sticky();
        domAutoround($parms,$_->{'Tags'}) if $parms->if_autoround();
        domTaxonomy($parms,$_->{'Gametext'},$_->{'Tags'}) if doTax($parms);
        foreach  my $key ('Event','Site','Date','Round','White','Black','Result') {
            if ($_->{'Tags'}->{$key}) {
                if ($parms->get_substitutions()) {
                    while (my ($one,$another) = each(%{$parms->get_substitutions()})) {
                        if ($_->{'Tags'}->{$key} =~ /$one/) {
                            $_->{'Tags'}->{$key} =~ s/$one/$another/;
                        }
                    }
                }
                $text .= "[$key \"$_->{'Tags'}->{$key}\"]\n";
                delete($_->{'Tags'}->{$key});
            }
        }
        foreach my $key (sort keys %{$_->{'Tags'}}) {
            $text .= "[$key \"$_->{'Tags'}->{$key}\"]\n";
        }
        $text .= "\n";
        $movetext = domTEXTGametext($parms,$move,$_->{'Gametext'});
        $text .= join("\n",paragraph($movetext . $termination,78))."\n\n";
    }
    return $text;
}

sub doTax {
    my $parms = shift;

    return ($parms->if_ECO() or $parms->if_NIC() or $parms->if_Opening());
}

sub domExTags {
    my $parms = shift;
    my $tag = shift;
    my $array = $parms->get_exclude();

    foreach  (@$array) {
        if (exists($tag->{$_})) {
            delete($tag->{$_});
        }
    }

}

sub domAutoround {
    my $parms = shift;
    my $tag = shift;

    if (exists($tag->{'Round'})) {
        my $value = $tag->{'Round'};

        if ($value eq '' or $value eq '?') {
            my $round = $parms->get_round();

            $tag->{'Round'} = ++$round;
            $parms->set_round($round);
        }
        else {
        	$parms->set_round($value);
        }
    }
}

sub domSticky {
    my $parms = shift;
    my $tag = shift;

    if (exists($tag->{'Event'})) {
        my $value = $tag->{'Event'};

        if ($value eq '' or $value eq '?') {
            $tag->{'Event'} = $parms->get_event();
        }
        else {
        	$parms->set_event($value);
        }
    }
    if (exists($tag->{'Site'})) {
        my $value = $tag->{'Site'};

        if ($value eq '' or $value eq '?') {
            $tag->{'Site'} = $parms->get_site();
        }
        else {
        	$parms->set_site($value);
        }
    }
    if (exists($tag->{'Date'})) {
        my $value = $tag->{'Date'};

        if ($value eq '' or $value eq '??.??.??') {
            $tag->{'Date'} = $parms->get_date();
        }
        else {
        	$parms->set_date($value);
        }
    }
}

sub domTaxonomy {
    my $parms = shift;
    my $gametext = shift;
    my $tag = shift;
    my @epd = reverse domEPD($gametext);

    if (exists($tag->{'ECO'})) {
        my $tax = $tag->{'ECO'};

        if ($tax eq '?' or $tax eq '') {
            $tag->{'ECO'} = epdcode('ECO',\@epd)
        }
    }
    else {
        $tag->{'ECO'} = epdcode('ECO',\@epd) if $parms->if_ECO();
    }
    if (exists($tag->{'NIC'})) {
        my $tax = $tag->{'NIC'};

        if ($tax eq '?' or $tax eq '') {
            $tag->{'NIC'} = epdcode('NIC',\@epd)
        }
    }
    else {
        $tag->{'NIC'} = epdcode('NIC',\@epd) if $parms->if_NIC();
    }
    if (exists($tag->{'Opening'})) {
        my $tax = $tag->{'Opening'};

        if ($tax eq '?' or $tax eq '') {
            $tag->{'Opening'} = epdcode('Opening',\@epd)
        }
    }
    else {
        $tag->{'Opening'} = epdcode('Opening',\@epd) if $parms->if_Opening();
    }
}

sub domTEXTGametext {
    my $parms = shift;
    my $move = shift;
    my $Gametext = shift;
    my $movetext = '';

    foreach my $element (@{$Gametext}) {
        if ($element->{'Movenumber'} % 2) {
            $movetext .= "$move. ";
        }
        else {
            $move++;            	
        }
        $movetext .= $element->{'Movetext'} . " ";
        if ($element->{'Comment'}) {
            $movetext =~ s/\s$//;
            $movetext .= '(' . $element->{'Comment'} . ')' if $parms->if_comments();
        }
        if ($element->{'Nag'}) {
            my $s = $element->{'Nag'};

            if ($s) {
                if ($s < 6) {
                    $movetext =~ s/\s$//;
                    $movetext .= NAG($s);
                }
                else {
                    $movetext =~ s/\s$//;
                    $movetext .= "\$$s" if $parms->if_nags();
                }
            }                
        }
        if ($element->{'Rav'}) {
                my $ravtext = domTEXTGametext($parms,$move,$element->{'Rav'});

                $ravtext =~ s/\s$//;
                $movetext =~ s/\s$//;
                $movetext .= "{$ravtext}";
        }
    }
    return $movetext;
}

sub domEPD {
    my $Gametext = shift;
    my @epd;

    foreach my $element (@{$Gametext}) {
        push(@epd,$element->{'Epd'});
    }
    return @epd;
}

sub paragraph {
    my $s = shift;
    my $n = shift;
    my $m = $n;

    while ($m < length($s)) {
        while(substr($s,$m,1) ne ' ') {
            $m--;
        }
        if (substr($s,$m - 1,1) eq '.') {
            $m--;
            next;
        }
        substr($s,$m,1) = '|';
        $m += $n;
    }
    return split(/\|/,$s);
}

sub deLIMIT {
    my $t = shift;
    my $startdelim = shift;
    my $enddelim = shift;
    my $escape = shift;
    my $mc = new Text::DelimMatch($startdelim,$enddelim,$escape);
    my ($prefix,$match,$remainder) = $mc->match(' ' . $t . ' ');

    if ($match) {
        $match =~ s/^$startdelim//;
        $match =~ s/$enddelim$//;
        return ($prefix or '') . ($remainder or ''),$match;
    }
    else {
        return $t,'';
    }
}

sub parseComments {
    my $rcomments = shift;
    my $rravs = shift;
    my $rnags = shift;

    foreach  (keys %$rcomments) {
        my $t = $rcomments->{$_};
        my $NAG;
        my $RAV;
        my $COMMENT;
        
        ($t,$COMMENT) = deLIMIT($t,'\{','\}');
        ($t,$RAV) = deLIMIT($t,'\(','\)','{}');
        ($t,$NAG) = deLIMIT($t,'\$','\D');
        if ($RAV) {
            $rravs->{$_} = $RAV;
        }
        if ($NAG and $NAG ne '') {
            $rnags->{$_} = $NAG;
        }
        if ($COMMENT) {
            $rcomments->{$_} = $COMMENT;
        }
        else {
            delete($rcomments->{$_});
        }
   }
}

sub filterXML {
    my $parms = new Parms(@_);
    my $file = $parms->get_source();
    my @DOM;
    my $filetext;
    my $text = '';

    {
        local $/ = undef;
        open(FILE,$file) or die "Couldn't open file:$file $!\n";
        $filetext = <FILE>;
        close(FILE);
    }
    @DOM = getDOM($filetext);
    $file =~ s/.pgn//;
    $file = uc($file);
#-----------------------------------------------------------------------------
    $text .= <<"HEADER";
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="pgn.xsl"?>
<!DOCTYPE CHESSGAMES SYSTEM "pgn.dtd">
<CHESSGAMES NAME="$file Games">
HEADER
#-----------------------------------------------------------------------------
    $text .= dom2XML($parms,@DOM);
    $text .= "</CHESSGAMES>\n";
    return $text;
}

sub dom2XML {
    my $parms = shift;
    my @DOM = @_;
    my $level = 0;
    my $result;
    my $text = '';

    foreach (@DOM) {
        $text .= "\t<GAME>\n";
        $text .= "\t\t<TAGLIST>\n";
        foreach  my $key ('Event','Site','Date','Round','White','Black','Result') {
            if ($_->{'Tags'}->{$key}) {
                if ($key eq 'Result') {
                    $result = $_->{'Tags'}->{$key};

                    if ($result eq '1-0') {
                        $result = 'WHITEWIN';
                    }
                    elsif ($result eq '0-1') {
                        $result = 'BLACKWIN';
                    }
                    elsif ($result eq '1/2-1/2') {
                        $result = 'DRAW';
                    }
                    else {
                    	$result = 'UNKNOWN';
                    }
                    $text .= "\t\t\t<Result GAMERESULT=\"$result\"/>\n";
                }
                elsif ($key eq 'Date') {
                    my @date = split(/\./,$_->{'Tags'}->{$key});

                    $text .= "\t\t\t<Date YEAR=\"$date[0]\" MONTH=\"$date[1]\" DAY=\"$date[2]\"/>\n";
                }
                else {
                    $text .= "\t\t\t<$key>$_->{'Tags'}->{$key}</$key>\n";
                }
                delete($_->{'Tags'}->{$key});
            }
        }
        foreach my $key (sort keys %{$_->{'Tags'}}) {
            $text .= "\t\t\t<$key>$_->{Tags}->{$key}</$key>\n";
        }
        $text .= "\t\t</TAGLIST>\n";
        $text .= dom2XMLGametext($parms,$level,$result,$_->{'Gametext'});
        $text .= "\t</GAME>\n";
    }
    return $text;
}

sub dom2XMLGametext {
    my $parms = shift;
    my $level = shift;
    my $result = shift;
    my $Gametext = shift;
    my $tabs = "\t" x 2 . "\t" x $level;
    my $text = '';
    my $diagram = sub {
        my $element = shift;
        my @rows = epdstr(
            epd => $element,
            type => $parms->get_type(),
            border => $parms->get_border(),
            corner => $parms->get_corner(),
            legend => $parms->get_legend()
            );
        my $text = '';

        $text .= qq|$tabs\t<POSITION FONT="|.$parms->get_font().'" SIZE="'.($parms->get_size() - 2).qq|">\n|;
        foreach my $row (@rows) {
            $text .= "$tabs\t\t<ROW>$row</ROW>\n";
        }
        $text .= "$tabs\t</POSITION>\n";
        return $text;
    };

    $text .= qq|$tabs<GAMETEXT LEVEL="$level">\n|;
    foreach my $element (@{$Gametext}) {
        $text .= "$tabs\t<MOVENUMBER>$element->{'Movenumber'}</MOVENUMBER>\n";
        $text .= "$tabs\t<MOVE>$element->{'Movetext'}</MOVE>\n";
        if ($element->{'Rav'}) {
            $text .= dom2XMLGametext($parms,$level + 1,'UNKNOWN',$element->{'Rav'});
        }
        $text .= "$tabs\t<COMMENT>$element->{'Comment'}</COMMENT>\n" if $element->{'Comment'};
        if ($element->{'Nag'}) {
            my $s = $element->{'Nag'};
            if ($s eq '0' and ($parms->if_position() or $parms->get_position() eq 'nag')) {
                $text .= &$diagram($element->{'Epd'});
            }
            else {
            	$text .= "$tabs\t<NAG>$element->{'Nag'}</NAG>\n";
            }
        }
        $text .= "$tabs\t<FENstr>$element->{'Epd'}</FENstr>\n" if $parms->if_fen();
    }
    $text .= qq|$tabs\t<GAMETERMINATION GAMERESULT="$result"/>\n|;
    $text .= "$tabs</GAMETEXT>\n";
    if ($level == 0 and ($parms->if_position() or $parms->get_position() eq 'end')) {
        chop($tabs);
        $text .= &$diagram(@{$Gametext}[-1]->{'Epd'});
    }
    return $text;
}

sub getDOM {
    my $s = shift;
    my $pgn = new Chess::PGN::Parse undef, $s;
    my $games_ref = $pgn->read_all({save_comments => 'yes'});
    my @DOM;

    foreach  (@{$games_ref}) {
        my %comments;
        my %ravs;
        my %nags;
        my @moves;
        my @epd;
        my %tags;
        my %game;
        my @movelist;
        my @movesmade;
        my $position = 0;
        my $movenumber = 1;

        push(@DOM,\%game);
        foreach my $key  (keys %{$_}) {
            my $ref = $_->{$key};
            if (ref($ref)) {
                if ($key eq 'GameMoves') {
                    @moves = @{$ref};
                    @epd = epdlist(@moves);
                }
                elsif ($key eq 'GameComments') {
                    %comments = %{$ref};
                    parseComments(\%comments,\%ravs,\%nags);
                }
            }
            elsif ($ref) {
                if ($key ne 'Game') {
                    $tags{$key} = $ref;
                }
            }
        }
        $game{'Tags'} = \%tags;
        $game{'Gametext'} = \@movelist;
        foreach  (@moves) {
            my %move;
            my $ckey;

            $move{'Movetext'} = $_;
            $move{'Movenumber'} = $position;
            push(@movesmade,$_);
            if ($position % 2) {
                $ckey = "${movenumber}b";
                $movenumber++;
            }
            else {
                $ckey = "${movenumber}w";
            }
            $move{'Comment'} = $comments{$ckey} if (%comments and exists($comments{$ckey}));
            $move{'Nag'} = $nags{$ckey} if (%nags and exists($nags{$ckey}));
            if (%ravs and exists($ravs{$ckey})) {
                my $n = scalar(@movesmade) - 2;
                my @ravDOM = getDOM("[Result \"*\"]\n\n" . join(' ',@movesmade[0..$n++]) . " $ravs{$ckey}");

                delete($ravDOM[0]->{'Tags'});
                splice(@{$ravDOM[0]->{'Gametext'}},0,$n);
                $move{'Rav'} = $ravDOM[0]->{'Gametext'};
            }
            $move{'Epd'} = $epd[$position++];
            $move{'Movenumber'} = $position;
            push(@movelist,\%move);
        }
    }
    return @DOM;
}

1;
__END__

=head1 NAME

Chess::PGN::Filter - Perl extension for converting PGN files to other formats.

=head1 SYNOPSIS

 use Chess::PGN::Filter;

 filter(source => $pgn,filtertype => 'XML');

B<OR>
 
 my %substitutions = (
     hsmyers => 'Myers, Hugh S (ID)',
 );

 my @exclude = qw(
     WhiteElo
     BlackElo
     EventDate
 );

 filter(
     source => $pgn,
     filtertype => 'TEXT',
     substitutions => \%substitutions,
     nags => 'yes',
     exclude => \@exclude,
 );

B<OR>

 filter(
     source => $pgn,
     filtertype => 'DOM',
 );

B<OR>

 $dom = filter(
     source => $pgn,
     filtertype => 'DOM',
     verbose => 0,
 );

=head1 DESCRIPTION

This is a typical text in one side, different text out the otherside filter module. There are as of
this writing, the following supported choices:

=over

=item 1. XML -- Converts from .pgn to .xml using the included pgn.dtd as the validation document. This
is for the most part a one to one transliteration of the PGN standard into XMLese. It does have the
additional virtue of allowing positions to be encoded within the XML output. These are generated by
an embedded NAG of {0} and automatically (user controlled) at the end of each game. As a kind of adjunct
to the position diagrams, pgn.dtd optionally allows each move to include it's FEN string. This allows
scripted animation for web pages generated this information.

=item 2. TEXT -- Although the PGN standard is widely available, many program that generate .pgn do so
in an ill-formed way. This mode is an attempt to 'normalize' away the various flaws found in the 'wild'!
This includes things like game text all on a single line without a preceding blank line. Or castling
indicated with zeros rather than the letter 'O'. There is at least one application that carefully indents
the first move! The list of oddities is probably as long as the list of applications.

=item 3. DOM -- A Document Object Model (DOM) makes for a very convenient interim form, common to all
other filter types. Useful in both the design and debugging phases of filter construction. By way of
self-documentation, here is an example of a single game that shows all of the obvious features of
the DOM:

 $VAR1 = {
          'Tags' => {
                      'Site' => 'Boise (ID)',
                      'Event' => 'Cabin Fever Open',
                      'Round' => '1',
                      'ECO' => '?',
                      'Date' => '1997.??.??',
                      'White' => 'Barrett Curtis',
                      'Black' => 'Myers Hugh S',
                      'Result' => '1-0'
                    },
          'Gametext' => [
                          {
                            'Movenumber' => '1',
                            'Epd' => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3',
                            'Movetext' => 'e4'
                          },
                          {
                            'Movenumber' => '2',
                            'Epd' => 'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6',
                            'Movetext' => 'd5'
                          },
                          {
                            'Movenumber' => '3',
                            'Epd' => 'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR b KQkq -',
                            'Movetext' => 'e5'
                          },
                          {
                            'Movenumber' => '4',
                            'Comment' => 'Playing ...Bf5 before closing the c8-h3 diagonal has  some positive features.',
                            'Epd' => 'rnbqkbnr/ppp2ppp/4p3/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq -',
                            'Movetext' => 'e6'
                          },
                          {
                            'Movenumber' => '5',
                            'Epd' => 'rnbqkbnr/ppp2ppp/4p3/3pP3/3P4/8/PPP2PPP/RNBQKBNR b KQkq d3',
                            'Movetext' => 'd4'
                          },
                          {
                            'Movenumber' => '6',
                            'Comment' => 'Time to think like a Frenchie - c7-c5!',
                            'Epd' => 'r1bqkbnr/ppp2ppp/2n1p3/3pP3/3P4/8/PPP2PPP/RNBQKBNR w KQkq -',
                            'Movetext' => 'Nc6',
                            'Rav' => [
                                       {
                                         'Movenumber' => '6',
                                         'Epd' => 'rnbqkbnr/pp3ppp/4p3/2ppP3/3P4/8/PPP2PPP/RNBQKBNR w KQkq c6',
                                         'Movetext' => 'c5'
                                       }
                                     ]
                          },
 .
 .
 .
                          {
                            'Movenumber' => '29',
                            'Comment' => ' (Bxe5) Black could  still kick for a while if he had played ...Bxe5.',
                            'Epd' => 'r1bq1rk1/2p1npb1/2n1p2P/pp1pP1p1/3P2P1/2P4Q/PP2BP2/RNB1K2R b KQ -',
                            'Movetext' => 'h6'
                          }
                        ]
        };

Briefly, the DOM is a multiply nested data structure of hashes and arrays. In a sort of outline form,
it more or less follows this schematic:

=over

=item I PGN Document Root

=over

=item A. Extra-Game Comments

=over

=item 1. Before 1st Game

=item 2. After Each Game

=back

=item  B. Games

=over

=item 1. Tagset

=item 2. Extra-Gametext Comments

=item 3. Gametext

=over

=item a. Moves

=over 

=item 1.) Movetext

=item 2.) Comment

=item 3.) NAG

=item 4.) RAV (essentially an instance of Gametext)

=back

=back

=back

=back

=back

The 'extra' comments have not yet been implemented. See the TODO list.

=back

Owing to a dearth of imagination, there is but one exported routine in the module:

=head2 filter(I<parameter_hash>)

There are however, a small host of known keys for C<parameter_hash> and they are as follows:

=over

=item * keys common to all filtertypes

=over

=item * verbose -- switch between output to STDOUT and output returned as an ARRAY refference. Defaults to 1 and sends
output to STDOUT. The code for this patch comes from Gene Boggs [gene@cpan.org] for which my thanks!

=item * filtertype -- essentially which filter to use. Values implemented are:

=over

=item 1. XML -- converts from .pgn text in, to .xml file out. Validated by supplied pgn.dtd.

=item 2. TEXT -- converts from .pgn text in, to .pgn out with reformatting of ill-formed text and
other modifications possible. Global correction of tag values, error checking for game text termination etc. Blank
lines and paragraph wrapping emplemented to match PGN standard.

=item 3. DOM -- converts from .pgn text to a Document Object Model as expressed using Data::Dumper.

=back

=item * source -- name of file to convert, with output sent to STDOUT.

=back

=item * keys for filtertype TEXT

=over

=item * substitute -- simple text substitution mechanism applied globally (file scope) to all tag text.


This is actually a hash reference where the hash reffered to has the form of (text_to_change => text_to_change_to). For instance:

 my %substitutions = (
     hsmyers => 'Myers, Hugh S (ID)'
 );

as used in the B<SYNOPSIS> example would expand my user name into a full version for any tag the former might occur in.

=item * comments -- switch to include/exclude comments (defaults to 'no'.)

=item * ravs -- switch to include/exclude recursive annotated variations (defaults to 'no'.)

=item * nags -- switch to include/exclude numberic annotation glyphs (defaults to 'no'.)

=item * ECO -- switch to include/exclude ECO tag (defaults to 'yes'.)

=item * NIC -- switch to include/exclude NIC tag (defaults to 'no'.)

=item * Opening -- switch to include/exclude Opening tag (defaults to 'yes'.)

=item * exclude -- an array reference of tags to be excluded (defaults to undef.)


This is an array reference where the referent has the form of (tag_to_exclude_1..tag_to_exclude_n), i.e.:

 my @exclude = qw(
     WhiteElo
     BlackElo
     EventDate
 );

again, as used in the B<SYNOPSIS> example, this would eliminate the 'WhiteElo', 'BlackElo' and
'EventDate' tags from the .pgn file being processed.

=item * sticky -- switch to turn on/off 'sticky' nature of the data in the 'Event', 'Site' and
'Date' tags (defaults to 'yes'.) Essentially this allows a tag to remember and use the previous
games tag if the tag contents for current game is either '?' or empty.

=item * autoround -- switch to turn on/off autoincrement for the 'Round' tag (default is 'yes'.)
Similar to 'sticky', if a 'Round' tag is either empty or set to '?' then the current tag is
set to the value of the previous tag plus one.

=back

=item * keys for filtertype XML. These control the appearence of embedded positions reached 
during the game as well as the final position of the game.

=over

=item * fen -- switch to include/exclude fen information for each move (defaults to 'no'.)

=item * position -- switch to control position diagrams in a game (defaults to 'yes'.)

Possible values are:

=over

=item * 'nag' -- insert diagram for each {0} in game text.

=item * 'end' -- insert diagram at end of game.

=item * 'no' -- no diagrams from either source.

=item * 'yes' -- create diagrams based on both embedded nags as well as at end of game.

=back

=item * font -- name of font to specify for embedded diagrams (default is 'Chess Kingdom'.)

Following list shows font name, font designer. They are available from L<http://www.enpassant.dk/chess/fonteng.htm>

=over

=item * Chess Cases -- Matthieu Leschemelle

=item * Chess Adventurer -- Armando H. Marroquin

=item * Chess Alfonso-X -- Armando H. Marroquin

=item * Chess Alpha -- Eric Bentzen

=item * Chess Berlin -- Eric Bentzen

=item * Chess Condal -- Armando H. Marroquin

=item * Chess Harlequin -- Armando H. Marroquin

=item * Chess Kingdom -- Armando H. Marroquin

=item * Chess Leipzig -- Armando H. Marroquin

=item * Chess Line -- Armando H. Marroquin

=item * Chess Lucena -- Armando H. Marroquin

=item * Chess Magnetic -- Armando H. Marroquin

=item * Chess Mark -- Armando H. Marroquin

=item * Chess Marroquin -- Armando H. Marroquin

=item * Chess Maya -- Armando H. Marroquin

=item * Chess Mediaeval -- Armando H. Marroquin

=item * Chess Mérida -- Armando H. Marroquin

=item * Chess Millennia -- Armando H. Marroquin

=item * Chess Miscel -- Armando H. Marroquin

=item * Chess Montreal -- Gary Katch

=item * Chess Motif -- Armando H. Marroquin

=item * Chess Plain -- Alan Hickey

=item * Chess Regular -- Alistair Scott

=item * Chess Usual -- Armando H. Marroquin

=item * Chess Utrecht -- Hans Bodlaender

=item * Tilburg -- Eric Schiller and Bill Cone

=item * Traveller Standard v3 -- Alan Cowderoy

=back

=item * border, values can be either 'single' or 'double' (default is 'single'.)

=item * corner, values can be either 'square' or 'rounded' (default is 'square'.)

=item * legend, values can be either 'yes' or 'no' (default is 'no'.)

=item * size, value ranging from 1 to 6 that controls the size of the embedded diagram (default is 5.)

=back

B<Note> -- not all fonts support all combinations of 'border', 'corner' and 'legend'. No warnings or
errors will be generated by unsupported options, you get the best a font can do, no more!

=back

=head2 EXPORT

=over

=item filter - given a source file and specification, convert to supported output. See details in B<Description>.

=back

=head2 DEPENDENCIES

=over

=item use Chess::PGN::Parse;

=item use Chess::PGN::EPD;

=item use Text::DelimMatch;

=item use Carp;

=item use Data::Dumper;

=back

=head1 TODO

=over

=item * Add other output types, PDF, DHTML, LaTeX.

=item * Add regular expressions to substitution mechanism.

=item * Allow for 'extra' and 'inter' semicolon comments.

=back

=head1 KNOWN BUGS

None known; Unknown? Of course, though I try to be neat...

=head1 AUTHOR

B<I<Hugh S. Myers>>

=over

=item Always: hsmyers@gmail.com

=back

=cut
