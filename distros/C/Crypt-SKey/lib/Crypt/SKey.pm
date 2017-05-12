package Crypt::SKey;

use strict;
use Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION $HASH $HEX);
@ISA = qw(Exporter);
@EXPORT_OK = qw( key compute key_md4 key_md5 compute_md4 compute_md5 );
@EXPORT = qw( key key_md4 key_md5 );
$VERSION = '0.10';
$HASH = 'MD4';  # set default here, could be 4 or 5
$HEX= 0; # if true, return key as a hex digit string

my @HEXDIGITS= qw( 0 1 2 3 4 5 6 7 8 9 A B C D E F);

my @WORDS = qw(
 A ABE ACE ACT AD ADA ADD AGO AID AIM AIR ALL ALP AM AMY AN ANA AND ANN
 ANT ANY APE APS APT ARC ARE ARK ARM ART AS ASH ASK AT ATE AUG AUK AVE
 AWE AWK AWL AWN AX AYE BAD BAG BAH BAM BAN BAR BAT BAY BE BED BEE BEG
 BEN BET BEY BIB BID BIG BIN BIT BOB BOG BON BOO BOP BOW BOY BUB BUD
 BUG BUM BUN BUS BUT BUY BY BYE CAB CAL CAM CAN CAP CAR CAT CAW COD COG
 COL CON COO COP COT COW COY CRY CUB CUE CUP CUR CUT DAB DAD DAM DAN
 DAR DAY DEE DEL DEN DES DEW DID DIE DIG DIN DIP DO DOE DOG DON DOT DOW
 DRY DUB DUD DUE DUG DUN EAR EAT ED EEL EGG EGO ELI ELK ELM ELY EM END
 EST ETC EVA EVE EWE EYE FAD FAN FAR FAT FAY FED FEE FEW FIB FIG FIN
 FIR FIT FLO FLY FOE FOG FOR FRY FUM FUN FUR GAB GAD GAG GAL GAM GAP
 GAS GAY GEE GEL GEM GET GIG GIL GIN GO GOT GUM GUN GUS GUT GUY GYM GYP
 HA HAD HAL HAM HAN HAP HAS HAT HAW HAY HE HEM HEN HER HEW HEY HI HID
 HIM HIP HIS HIT HO HOB HOC HOE HOG HOP HOT HOW HUB HUE HUG HUH HUM HUT
 I ICY IDA IF IKE ILL INK INN IO ION IQ IRA IRE IRK IS IT ITS IVY JAB
 JAG JAM JAN JAR JAW JAY JET JIG JIM JO JOB JOE JOG JOT JOY JUG JUT KAY
 KEG KEN KEY KID KIM KIN KIT LA LAB LAC LAD LAG LAM LAP LAW LAY LEA LED
 LEE LEG LEN LEO LET LEW LID LIE LIN LIP LIT LO LOB LOG LOP LOS LOT LOU
 LOW LOY LUG LYE MA MAC MAD MAE MAN MAO MAP MAT MAW MAY ME MEG MEL MEN
 MET MEW MID MIN MIT MOB MOD MOE MOO MOP MOS MOT MOW MUD MUG MUM MY NAB
 NAG NAN NAP NAT NAY NE NED NEE NET NEW NIB NIL NIP NIT NO NOB NOD NON
 NOR NOT NOV NOW NU NUN NUT O OAF OAK OAR OAT ODD ODE OF OFF OFT OH OIL
 OK OLD ON ONE OR ORB ORE ORR OS OTT OUR OUT OVA OW OWE OWL OWN OX PA
 PAD PAL PAM PAN PAP PAR PAT PAW PAY PEA PEG PEN PEP PER PET PEW PHI PI
 PIE PIN PIT PLY PO POD POE POP POT POW PRO PRY PUB PUG PUN PUP PUT QUO
 RAG RAM RAN RAP RAT RAW RAY REB RED REP RET RIB RID RIG RIM RIO RIP
 ROB ROD ROE RON ROT ROW ROY RUB RUE RUG RUM RUN RYE SAC SAD SAG SAL
 SAM SAN SAP SAT SAW SAY SEA SEC SEE SEN SET SEW SHE SHY SIN SIP SIR
 SIS SIT SKI SKY SLY SO SOB SOD SON SOP SOW SOY SPA SPY SUB SUD SUE SUM
 SUN SUP TAB TAD TAG TAN TAP TAR TEA TED TEE TEN THE THY TIC TIE TIM
 TIN TIP TO TOE TOG TOM TON TOO TOP TOW TOY TRY TUB TUG TUM TUN TWO UN
 UP US USE VAN VAT VET VIE WAD WAG WAR WAS WAY WE WEB WED WEE WET WHO
 WHY WIN WIT WOK WON WOO WOW WRY WU YAM YAP YAW YE YEA YES YET YOU ABED
 ABEL ABET ABLE ABUT ACHE ACID ACME ACRE ACTA ACTS ADAM ADDS ADEN AFAR
 AFRO AGEE AHEM AHOY AIDA AIDE AIDS AIRY AJAR AKIN ALAN ALEC ALGA ALIA
 ALLY ALMA ALOE ALSO ALTO ALUM ALVA AMEN AMES AMID AMMO AMOK AMOS AMRA
 ANDY ANEW ANNA ANNE ANTE ANTI AQUA ARAB ARCH AREA ARGO ARID ARMY ARTS
 ARTY ASIA ASKS ATOM AUNT AURA AUTO AVER AVID AVIS AVON AVOW AWAY AWRY
 BABE BABY BACH BACK BADE BAIL BAIT BAKE BALD BALE BALI BALK BALL BALM
 BAND BANE BANG BANK BARB BARD BARE BARK BARN BARR BASE BASH BASK BASS
 BATE BATH BAWD BAWL BEAD BEAK BEAM BEAN BEAR BEAT BEAU BECK BEEF BEEN
 BEER BEET BELA BELL BELT BEND BENT BERG BERN BERT BESS BEST BETA BETH
 BHOY BIAS BIDE BIEN BILE BILK BILL BIND BING BIRD BITE BITS BLAB BLAT
 BLED BLEW BLOB BLOC BLOT BLOW BLUE BLUM BLUR BOAR BOAT BOCA BOCK BODE
 BODY BOGY BOHR BOIL BOLD BOLO BOLT BOMB BONA BOND BONE BONG BONN BONY
 BOOK BOOM BOON BOOT BORE BORG BORN BOSE BOSS BOTH BOUT BOWL BOYD BRAD
 BRAE BRAG BRAN BRAY BRED BREW BRIG BRIM BROW BUCK BUDD BUFF BULB BULK
 BULL BUNK BUNT BUOY BURG BURL BURN BURR BURT BURY BUSH BUSS BUST BUSY
 BYTE CADY CAFE CAGE CAIN CAKE CALF CALL CALM CAME CANE CANT CARD CARE
 CARL CARR CART CASE CASH CASK CAST CAVE CEIL CELL CENT CERN CHAD CHAR
 CHAT CHAW CHEF CHEN CHEW CHIC CHIN CHOU CHOW CHUB CHUG CHUM CITE CITY
 CLAD CLAM CLAN CLAW CLAY CLOD CLOG CLOT CLUB CLUE COAL COAT COCA COCK
 COCO CODA CODE CODY COED COIL COIN COKE COLA COLD COLT COMA COMB COME
 COOK COOL COON COOT CORD CORE CORK CORN COST COVE COWL CRAB CRAG CRAM
 CRAY CREW CRIB CROW CRUD CUBA CUBE CUFF CULL CULT CUNY CURB CURD CURE
 CURL CURT CUTS DADE DALE DAME DANA DANE DANG DANK DARE DARK DARN DART
 DASH DATA DATE DAVE DAVY DAWN DAYS DEAD DEAF DEAL DEAN DEAR DEBT DECK
 DEED DEEM DEER DEFT DEFY DELL DENT DENY DESK DIAL DICE DIED DIET DIME
 DINE DING DINT DIRE DIRT DISC DISH DISK DIVE DOCK DOES DOLE DOLL DOLT
 DOME DONE DOOM DOOR DORA DOSE DOTE DOUG DOUR DOVE DOWN DRAB DRAG DRAM
 DRAW DREW DRUB DRUG DRUM DUAL DUCK DUCT DUEL DUET DUKE DULL DUMB DUNE
 DUNK DUSK DUST DUTY EACH EARL EARN EASE EAST EASY EBEN ECHO EDDY EDEN
 EDGE EDGY EDIT EDNA EGAN ELAN ELBA ELLA ELSE EMIL EMIT EMMA ENDS ERIC
 EROS EVEN EVER EVIL EYED FACE FACT FADE FAIL FAIN FAIR FAKE FALL FAME
 FANG FARM FAST FATE FAWN FEAR FEAT FEED FEEL FEET FELL FELT FEND FERN
 FEST FEUD FIEF FIGS FILE FILL FILM FIND FINE FINK FIRE FIRM FISH FISK
 FIST FITS FIVE FLAG FLAK FLAM FLAT FLAW FLEA FLED FLEW FLIT FLOC FLOG
 FLOW FLUB FLUE FOAL FOAM FOGY FOIL FOLD FOLK FOND FONT FOOD FOOL FOOT
 FORD FORE FORK FORM FORT FOSS FOUL FOUR FOWL FRAU FRAY FRED FREE FRET
 FREY FROG FROM FUEL FULL FUME FUND FUNK FURY FUSE FUSS GAFF GAGE GAIL
 GAIN GAIT GALA GALE GALL GALT GAME GANG GARB GARY GASH GATE GAUL GAUR
 GAVE GAWK GEAR GELD GENE GENT GERM GETS GIBE GIFT GILD GILL GILT GINA
 GIRD GIRL GIST GIVE GLAD GLEE GLEN GLIB GLOB GLOM GLOW GLUE GLUM GLUT
 GOAD GOAL GOAT GOER GOES GOLD GOLF GONE GONG GOOD GOOF GORE GORY GOSH
 GOUT GOWN GRAB GRAD GRAY GREG GREW GREY GRID GRIM GRIN GRIT GROW GRUB
 GULF GULL GUNK GURU GUSH GUST GWEN GWYN HAAG HAAS HACK HAIL HAIR HALE
 HALF HALL HALO HALT HAND HANG HANK HANS HARD HARK HARM HART HASH HAST
 HATE HATH HAUL HAVE HAWK HAYS HEAD HEAL HEAR HEAT HEBE HECK HEED HEEL
 HEFT HELD HELL HELM HERB HERD HERE HERO HERS HESS HEWN HICK HIDE HIGH
 HIKE HILL HILT HIND HINT HIRE HISS HIVE HOBO HOCK HOFF HOLD HOLE HOLM
 HOLT HOME HONE HONK HOOD HOOF HOOK HOOT HORN HOSE HOST HOUR HOVE HOWE
 HOWL HOYT HUCK HUED HUFF HUGE HUGH HUGO HULK HULL HUNK HUNT HURD HURL
 HURT HUSH HYDE HYMN IBIS ICON IDEA IDLE IFFY INCA INCH INTO IONS IOTA
 IOWA IRIS IRMA IRON ISLE ITCH ITEM IVAN JACK JADE JAIL JAKE JANE JAVA
 JEAN JEFF JERK JESS JEST JIBE JILL JILT JIVE JOAN JOBS JOCK JOEL JOEY
 JOHN JOIN JOKE JOLT JOVE JUDD JUDE JUDO JUDY JUJU JUKE JULY JUNE JUNK
 JUNO JURY JUST JUTE KAHN KALE KANE KANT KARL KATE KEEL KEEN KENO KENT
 KERN KERR KEYS KICK KILL KIND KING KIRK KISS KITE KLAN KNEE KNEW KNIT
 KNOB KNOT KNOW KOCH KONG KUDO KURD KURT KYLE LACE LACK LACY LADY LAID
 LAIN LAIR LAKE LAMB LAME LAND LANE LANG LARD LARK LASS LAST LATE LAUD
 LAVA LAWN LAWS LAYS LEAD LEAF LEAK LEAN LEAR LEEK LEER LEFT LEND LENS
 LENT LEON LESK LESS LEST LETS LIAR LICE LICK LIED LIEN LIES LIEU LIFE
 LIFT LIKE LILA LILT LILY LIMA LIMB LIME LIND LINE LINK LINT LION LISA
 LIST LIVE LOAD LOAF LOAM LOAN LOCK LOFT LOGE LOIS LOLA LONE LONG LOOK
 LOON LOOT LORD LORE LOSE LOSS LOST LOUD LOVE LOWE LUCK LUCY LUGE LUKE
 LULU LUND LUNG LURA LURE LURK LUSH LUST LYLE LYNN LYON LYRA MACE MADE
 MAGI MAID MAIL MAIN MAKE MALE MALI MALL MALT MANA MANN MANY MARC MARE
 MARK MARS MART MARY MASH MASK MASS MAST MATE MATH MAUL MAYO MEAD MEAL
 MEAN MEAT MEEK MEET MELD MELT MEMO MEND MENU MERT MESH MESS MICE MIKE
 MILD MILE MILK MILL MILT MIMI MIND MINE MINI MINK MINT MIRE MISS MIST
 MITE MITT MOAN MOAT MOCK MODE MOLD MOLE MOLL MOLT MONA MONK MONT MOOD
 MOON MOOR MOOT MORE MORN MORT MOSS MOST MOTH MOVE MUCH MUCK MUDD MUFF
 MULE MULL MURK MUSH MUST MUTE MUTT MYRA MYTH NAGY NAIL NAIR NAME NARY
 NASH NAVE NAVY NEAL NEAR NEAT NECK NEED NEIL NELL NEON NERO NESS NEST
 NEWS NEWT NIBS NICE NICK NILE NINA NINE NOAH NODE NOEL NOLL NONE NOOK
 NOON NORM NOSE NOTE NOUN NOVA NUDE NULL NUMB OATH OBEY OBOE ODIN OHIO
 OILY OINT OKAY OLAF OLDY OLGA OLIN OMAN OMEN OMIT ONCE ONES ONLY ONTO
 ONUS ORAL ORGY OSLO OTIS OTTO OUCH OUST OUTS OVAL OVEN OVER OWLY OWNS
 QUAD QUIT QUOD RACE RACK RACY RAFT RAGE RAID RAIL RAIN RAKE RANK RANT
 RARE RASH RATE RAVE RAYS READ REAL REAM REAR RECK REED REEF REEK REEL
 REID REIN RENA REND RENT REST RICE RICH RICK RIDE RIFT RILL RIME RING
 RINK RISE RISK RITE ROAD ROAM ROAR ROBE ROCK RODE ROIL ROLL ROME ROOD
 ROOF ROOK ROOM ROOT ROSA ROSE ROSS ROSY ROTH ROUT ROVE ROWE ROWS RUBE
 RUBY RUDE RUDY RUIN RULE RUNG RUNS RUNT RUSE RUSH RUSK RUSS RUST RUTH
 SACK SAFE SAGE SAID SAIL SALE SALK SALT SAME SAND SANE SANG SANK SARA
 SAUL SAVE SAYS SCAN SCAR SCAT SCOT SEAL SEAM SEAR SEAT SEED SEEK SEEM
 SEEN SEES SELF SELL SEND SENT SETS SEWN SHAG SHAM SHAW SHAY SHED SHIM
 SHIN SHOD SHOE SHOT SHOW SHUN SHUT SICK SIDE SIFT SIGH SIGN SILK SILL
 SILO SILT SINE SING SINK SIRE SITE SITS SITU SKAT SKEW SKID SKIM SKIN
 SKIT SLAB SLAM SLAT SLAY SLED SLEW SLID SLIM SLIT SLOB SLOG SLOT SLOW
 SLUG SLUM SLUR SMOG SMUG SNAG SNOB SNOW SNUB SNUG SOAK SOAR SOCK SODA
 SOFA SOFT SOIL SOLD SOME SONG SOON SOOT SORE SORT SOUL SOUR SOWN STAB
 STAG STAN STAR STAY STEM STEW STIR STOW STUB STUN SUCH SUDS SUIT SULK
 SUMS SUNG SUNK SURE SURF SWAB SWAG SWAM SWAN SWAT SWAY SWIM SWUM TACK
 TACT TAIL TAKE TALE TALK TALL TANK TASK TATE TAUT TEAL TEAM TEAR TECH
 TEEM TEEN TEET TELL TEND TENT TERM TERN TESS TEST THAN THAT THEE THEM
 THEN THEY THIN THIS THUD THUG TICK TIDE TIDY TIED TIER TILE TILL TILT
 TIME TINA TINE TINT TINY TIRE TOAD TOGO TOIL TOLD TOLL TONE TONG TONY
 TOOK TOOL TOOT TORE TORN TOTE TOUR TOUT TOWN TRAG TRAM TRAY TREE TREK
 TRIG TRIM TRIO TROD TROT TROY TRUE TUBA TUBE TUCK TUFT TUNA TUNE TUNG
 TURF TURN TUSK TWIG TWIN TWIT ULAN UNIT URGE USED USER USES UTAH VAIL
 VAIN VALE VARY VASE VAST VEAL VEDA VEIL VEIN VEND VENT VERB VERY VETO
 VICE VIEW VINE VISE VOID VOLT VOTE WACK WADE WAGE WAIL WAIT WAKE WALE
 WALK WALL WALT WAND WANE WANG WANT WARD WARM WARN WART WASH WAST WATS
 WATT WAVE WAVY WAYS WEAK WEAL WEAN WEAR WEED WEEK WEIR WELD WELL WELT
 WENT WERE WERT WEST WHAM WHAT WHEE WHEN WHET WHOA WHOM WICK WIFE WILD
 WILL WIND WINE WING WINK WINO WIRE WISE WISH WITH WOLF WONT WOOD WOOL
 WORD WORE WORK WORM WORN WOVE WRIT WYNN YALE YANG YANK YARD YARN YAWL
 YAWN YEAH YEAR YELL YOGA YOKE
);

sub compute_md4 {
  local $HASH = 'MD4';
  &compute;
}

sub compute_md5 {
  local $HASH = 'MD5';
  &compute;
}

sub compute_sha1 {
  local $HASH = 'SHA1';
  &compute;
}

sub compute {
  my ($n, $seed, $passwd, $cnt) = @_;
  $cnt ||= 1;
  
  my @out;
  die "'$n' not positive\n" if $n < 0;
  die "'count' ($cnt) greater than 'n' ($n)\n" if $cnt > $n;
  
  my $key = hash($seed.$passwd) or die "keycrunch error";
  for (0..$n-$cnt) {$key = hash($key)}

  for (1..$cnt) {
    push @out, $HEX ? btoh($key) : btoe($key);
    $key = hash($key);
  }
  return wantarray ? @out : $out[0];
}

sub key_md4 {
  local $HASH = 'MD4';
  &key;
}

sub key_md5 {
  local $HASH = 'MD5';
  &key;
}

sub key_sha1 {
  local $HASH = 'SHA1';
  &key;
}

sub key {
  # Meant to be run from the command line, so it looks at @ARGV instead of @_
  die "Usage: perl -mCrypt::Skey -e key <sequence> <seed> [<count>]\n" unless @ARGV;
  require Term::ReadKey;
  Term::ReadKey->import('ReadMode');
  my ($n, $seed, $cnt) = @ARGV;

  # Could be: key <sequence>/<seed> [<count>]
  if ($n =~ m{(.+)/(.+)}) { ($n, $seed, $cnt) = ($1, $2, $_[1]) }
  $cnt = 1 unless defined $cnt;
  die "'$n' not positive\n" if $n < 0;

  warn "Reminder - Do not use this program while logged in via telnet or rlogin.\n";
  print STDERR "Enter secret password: ";
  ReadMode('noecho');
  chomp(my $passwd = <STDIN>);
  ReadMode('normal');
  print "\n";
  
  my $i = 1;
  my $last;
  foreach my $line (compute($n, $seed, $passwd, $cnt)) {
    print $n-$cnt+$i++, ': ' if $cnt > 1;
    print "$line\n";
    $last = $line; # For 'make test', a bit of a kludge
  }
  return $last;
}

sub hash {
  my $d;
  if ($HASH eq 'MD5') {
    require Digest::MD5;
    $d = Digest::MD5::md5($_[0]);
    return substr($d,0,8) ^ substr($d,8,8); # Fold 16-byte result to 8 bytes
  } elsif ($HASH eq 'SHA1') {
    require Digest::SHA1;
    $d = Digest::SHA1::sha1($_[0]);
    # Fold 20-byte result to 8 bytes
    my $folded= substr($d,0,8) ^ substr($d,8,8);
    $folded= (substr($folded,0,4) ^ substr($d,16,4)) . substr($folded,4,4);
    # SHA1 is big-endian, but RFC2289 mandates little-endian result
    return pack("N2", unpack("V2", $folded));
  } elsif ($HASH eq 'MD4') {
    require Digest::MD4;
    $d = Digest::MD4->hash($_[0]);
    return substr($d,0,8) ^ substr($d,8,8); # Fold 16-byte result to 8 bytes
  } else {
    die "Unrecognized algorithm: '$HASH'";
  }
}

sub checksum {
  # Gotta be a better way to do this.
  my ($data,$n) = @_;
  my $sum = 0;
  my $bin_string = unpack("B64",$data);
  
  for (0..length($bin_string)/$n-1) {
    $sum += unpack("n", pack("B16", ('0'x(16-$n)) . substr($bin_string, $_*$n, $n)));
  }
  $sum %= 2**$n;
  
  return $sum;
}

sub btoh {
  # Binary to hex
  my $binary = shift;
  return join '', map $HEXDIGITS[extract($binary, 4*$_, 4)], 0..15;
}

sub btoe {
  # Binary to english
  my $binary = shift;

  my $p = checksum($binary,2);
  $binary .= chr($p << 6);

  return join ' ', map $WORDS[extract($binary,11*$_,11)], 0..5;
}

sub extract {
  # Extracts $length bits from $binary, starting at $offset, and
  # converts to an integer.
  my ($binary,$offset,$length) = @_;
  
  my $binstring = '0'x32 . substr(unpack('B*',$binary),$offset,$length);
  return unpack('N', pack('B32', substr($binstring, -32)));
}

1;
__END__

=head1 NAME

Crypt::SKey - Perl S/Key calculator

=head1 SYNOPSIS

  # In perl script:
  use Crypt::SKey qw(compute);
  $output = compute($sequence_num, $seed, $password);
  @output = compute($sequence_num, $seed, $password, $count);
  
  # Command line:
  perl -MCrypt::SKey -e key 500 fo099804
  perl -MCrypt::SKey -e key 500 fo099804 100
  perl -MCrypt::SKey=key_md4 -e key_md4 500 fo099804
  
  # The following shell alias may be useful:
  alias key 'perl -MCrypt::SKey -e key'
  # This allows you to simply type:
  key 500 fo099804

=head1 DESCRIPTION

This module contains a simple S/Key calculator (as described in RFC
1760) implemented in Perl.  It exports the function C<key> by default,
and may optionally export the function C<compute>.

C<compute_md4>, C<compute_md5>, C<compute_sha1>, C<key_md4>, C<key_md5>, and C<key_sha1> are provided
as convenience functions for selecting MD4, MD5, or SHA1 hashes.  The
default is MD4; this may be changed with with the C<$Crypt::SKey::HASH>
variable, assigning it the value of C<MD4>, C<MD5>, or C<SHA1>.  You can access
any of these functions by exporting them in the same manner as
C<compute> in the above example.

Most S/Key systems use MD4 hashing, but a few (notably OPIE) use MD5.

=head1 INSTALLATION

Follow the usual steps for installing any Perl module:

  perl Makefile.PL
  make test
  make install

=head1 FUNCTIONS

=head2 C<compute($sequence_num, $seed, $password [, $count])>

=head2 C<compute_md4($sequence_num, $seed, $password [, $count])>

=head2 C<compute_md5($sequence_num, $seed, $password [, $count])>

=head2 C<compute_sha1($sequence_num, $seed, $password [, $count])>

Given three arguments, computes the hash value and returns it as a
string containing six words separated by spaces (or as a string of 16
hex digits if C<$Crypt::SKey::HEX> is set to a true value).  If $count is
specified and greater than one, returns a list of several such
strings.  The meanings of the arguments is as follows:

=over 4

=item * sequence_number

Which output in the sequence of calculated S/Key responses to
generate.  This is called C<N> in RFC 1760.  It will usually be the
first number shown in an S/Key challenge.

=item * seed

This is a random seed.  It is usually the second number/string shown
in an S/Key challenge.

=item * password

This is your secret password.

=item * count

This argument is optional and defaults to C<1>.  It specifies the
number of S/Key responses to generate.  This may be useful if you want
to pre-generate a bunch of responses and print them on a piece of
paper so that you don't need to have an S/Key calculator around later.

=back


=head2 C<key()>

=head2 C<key_md4()>

=head2 C<key_md5()>

=head2 C<key_sha1()>

Acts just like the 'key' executable program that comes with the
standard distribution of s/key.  Reads several arguments from the
command line (C<@ARGV>), prompts for the user's password, and prints
one or more calculated s/key responses to C<STDOUT>.  The command line
arguments are, in order:

=over 4

=item * sequence_number

=item * seed

=item * count (optional)

=back

Their meanings are exactly the same as with the C<compute> function above.

=head1 NOTES

If you care about security, you'd probably be better off using SSH
than S/Key, because SSH encrypts your entire session whereas S/Key
only encrypts your password.  I wrote this module because nobody else
seemed to have done it yet, and because sometimes I'm on systems with
neither SSH nor the C<key> program, but I want to telnet to a system
that offers S/Key password transmission.

The original C<key> program takes the C<count> parameter using the
C<-n> flag, but this version takes it as an optional final argument.
Unless I hear from someone that needs the behavior changed, I'm not
likely to add the C<-n> flag.

I currently have no plans to write any code that checks the validity
of S/Key responses at login, i.e. the code that the server has to run
when authenticating users.  It shouldn't be hard, though, and if
someone wants to send me a patch implementing this functionality I'll
be happy to add it.

=head1 AUTHOR

Ken Williams, kwilliams@cpan.org

Thanks to Chris Nandor and Allen Chen for testing MD5 functionality.

=head1 COPYRIGHT

Copyright 2000-2009 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).  L<RFC 1760|"http://rfc.net/rfc1760.html">.  Digest::MD4(1).
Digest::MD5(1).  Term::ReadKey(1).

=cut
