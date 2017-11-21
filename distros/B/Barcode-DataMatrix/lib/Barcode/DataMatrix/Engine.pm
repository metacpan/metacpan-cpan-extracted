package Barcode::DataMatrix::Engine;

=head1 NAME

Barcode::DataMatrix::Engine - The engine which generates the data matrix
bitmap.

=cut

use strict;
use warnings;
no warnings qw(uninitialized);
use Barcode::DataMatrix::Reed;
use Barcode::DataMatrix::Constants ();
use Barcode::DataMatrix::CharDataFiller ();
use Data::Dumper;$Data::Dumper::Useqq = 1;

=head2 DEBUG

Turn on/off general debugging information.

=cut

use constant DEBUG => 0;

our %DEBUG = (
	ENC    => 0,
	EAUTO  => 0,
	CALC   => 0,
	TRACE  => 0,
	B256   => 0
);
our (@FORMATS,@C1);

*FORMATS = \@Barcode::DataMatrix::Constants::FORMATS;
*C1      = \@Barcode::DataMatrix::Constants::C1;

=head2 E_ASCII

Represent the ASCII encoding type.

=cut

sub E_ASCII { 0 }

=head2 E_C40

Represent the C40 encoding type.  (upper case alphanumeric)

=cut

sub E_C40 { 1 }

=head2 E_TEXT

Represent the TEXT encoding type.  (lower case alphanumeric)

=cut

sub E_TEXT { 2 }

=head2 E_BASE256

Represent the BASE256 encoding type.

=cut

sub E_BASE256 { 3 }

=head2 E_NONE

Represent the when there is no encoding type.

=cut

sub E_NONE { 4 }

=head2 E_AUTO

Represent the when the encoding type is automatically set.

=cut

sub E_AUTO { 5 }

our $N = 255;

=head2 Types

Return a list of encoding types.

=cut

sub Types {
	return qw( ASCII C40 TEXT BASE256 NONE AUTO );
}

=head2 stringToType (type_name)

Return the integer representing the type from the type name.

=cut

sub stringToType {
	my $m = 'E_'.shift;
	return eval { __PACKAGE__->$m(); };
}

=head2 typeToString (type_integer)

Return the type name from the integer representing the type.

=cut

sub typeToString {
	my $i = shift;
	for (Types) {
		return $_ if stringToType($_) == $i and defined $i;
	}
	return 'UNK';
}

our @encName = map { typeToString $_ } 0..5;

=head2 stringToFormat (format_string)

Convert a "width x height" format string into an internal format specification.

=cut

sub stringToFormat {
	my $sz = shift;
	return unless $sz;
	return if $sz eq 'AUTO';
	my ($w,$h) = map { +int } split /\s*x\s*/,$sz,2;
	my $r;
	for my $i (0..$#FORMATS) {
		$r = $i,last if $FORMATS[$i][0] == $w and $FORMATS[$i][1] == $h;
	}
	die "Format not supported ($sz)\n" unless defined $r;
	return $r;
}

=head2 setType (type_name)

Set the encoding type from the given type name.

=cut

sub setType {
	my $self = shift;
	my $type = shift;
	my $t = stringToType($type);
	warn "setType $type => $t\n" if $DEBUG{ENC};
	$t = E_ASCII unless defined $t;
	$self->{encoding} = $self->{currentEncoding} = $t;
	warn "Have type $t (".typeToString($t).")\n" if $DEBUG{ENC};
	return;
}

=head2 new

Construct a C<Barcode::DataMatrix::Engine> object.

=cut

sub new {
	my $self = bless{},shift;
	$self->init();
	warn "[CA] new(@_)\n" if $DEBUG{TRACE};
	$self->{orig} = $self->{code} = shift;  # text
	$self->setType(shift);                  # type of encoding
	$self->{preferredFormat} = stringToFormat(shift) || -1; # type of format
	$self->{as} = [  ]; # additional streams
	$self->ProcessTilde if (shift);         # process tilde
	return unless ( my $l = length($self->{code}) );        # no data to encode
	$self->{ac} = [ split //,$self->{code} ]; # create an char array
	$self->{ai} = [ map { +ord } @{ $self->{ac} } ]; # create an int array
	$self->CreateBitmap();
	return $self;
}

=head2 init

Initialize some of the basic C<Barcode::DataMatrix::Engine> data.

=cut

sub init {
	my $self = shift;
	my %p = (
        processTilde            => 0,#0
        encoding                => E_ASCII,
        preferredFormat         => -1,
        currentEncoding         => E_ASCII,
        C49rest                 => 0,
	);
	for (keys %p){
		$self->{$_} = $p{$_};
	}
}

=head2 ProcessTilde

Handle special or control characters, which are prefixed by a tilde C<~>
when encoding.

=cut

sub ProcessTilde {
	my $self = shift;
	my $s = $self->{code};
	my $as = $self->{as};
	for ($s) {
		s{~d(\d{3})}{ chr($1) }ge;
		s{~d.{3}}{}g;
		for my $i (0,1,4,5) {
			s{^(.{$i})~1}{ $as->[$-[0]+$i]=''; $1."\350"}ge;
		}
		s{~1}{\035}g;
		s{~2(.{3})}{ $as->[$-[0]] = $1; "\351".$2 }e;
		s{^~3}{ $as->[0] = ''; "\352" }e;
		s{^~5}{ $as->[0] = ''; "\354" }e;
		s{^~6}{ $as->[0] = ''; "\355" }e;
		s{~7(.{6})}{do{
			my $d = int $1;
			#warn "There is $d got from $1\n";
			if ($d < 127) {
				$d = chr($d+1);
			}
			elsif($d < 16383) {
				$d =
					chr( ( $d - 127 ) / 254 + 128 ).
					chr( ( $d - 127 ) % 254 + 1 );
			}
			else{
				$d =
					chr( int( ( $d - 16383 ) / 64516 + 192 ) ).
					chr( int( ( $d - 16383 ) / 254 ) % 254 + 1 ).
					chr( int( ( $d - 16383 ) % 254 + 1 ) );
			}
			$as->[$-[0]] = $d;
			warn "PT affect as[$-[0]] = ".join('+', map ord, split //, $d) if $DEBUG{TRACE};
			"\361"
		}}ge;
		s{~(.)}{$1 eq '~' ? '~' : $1}ge;
		warn "[C9] ProcessTilde($self->{code}) => ".Dumper($_) if $DEBUG{TRACE};
		return $self->{code} = $_;
	}
}

=head2 CalcReed (ai, err)

Return the message as a Reed-Solomon encoded array.

=cut

sub CalcReed { # (int ai[], int i, int j) : void
	my ($ai,$err) = @_;
	my $rv = Barcode::DataMatrix::Reed::encode($ai,$err);
	@$ai = @$rv;
	return $ai;
}

=head2 A253 (i, j)

Return padding codewords via the 253-state algorithm.

For more information see
L<http://grandzebu.net/informatique/codbar-en/datamatrix.htm>.

The relevant text for this algorithm is reproduced here.

If the symbol is not full, pad C<CW>s are required. After the last data
C<CW>, the 254 C<CW> indicates the end of the datas or the return to ASCII
method. First padding C<CW> is 129 and next padding C<CW>s are computed with
the 253-state algorithm.

=head3 The 253-state algorithm

Let C<P> be the number of data C<CW>s from the beginning of the data, C<R> a
pseudo random number and C<CW> the required pad C<CW>.

    R = ((149 * P) MOD 253) + 1
    CW = (129 + R) MOD 254

=cut

sub A253 # C8 (int i, int j) : int
{
	my ($i,$j) = @_;
    my $l = $i + (149 * $j) % 253 + 1;
    return $l <= 254 ? $l : $l - 254;
}

=head2 CreateBitmap

Generate and return the bitmap representing the message.

=cut

sub CreateBitmap #CB (int ai[], String as[]) : int[][]
{
	my $self = shift;
	my ($ai,$as) = @$self{qw(ai as)};
	warn "[CB] CreateBitmap(ai[" .join(',',@$ai).'], as[' . scalar(@$as) .  "])\n" if $DEBUG{TRACE};
    my $ai1 = [];
    my $i = 0;
	$self->{currentEncoding} = $self->{encoding} if $self->{encoding} != E_AUTO;
	for ($self->{encoding}){
		warn "[CB] Select method for $self->{encoding}, ".typeToString($self->{encoding})."\n" if $DEBUG{ENC};
		$_ == E_AUTO    && do { $i = $self->DetectEncoding($ai1); last;};
		$_ == E_ASCII   && do { $i = $self->EncodeASCII(scalar(@$ai), $ai, $ai1, $as); last;};
		$_ == E_C40     && do { $i = $self->EncodeC40TEXT(scalar(@$ai), [0], $ai, $ai1, 0, 1, 0); last;};
		$_ == E_TEXT    && do { $i = $self->EncodeC40TEXT(scalar(@$ai), [0], $ai, $ai1, 1, 1, 0); last;};
		$_ == E_BASE256 && do { $i = $self->EncodeBASE256(scalar(@$ai), [0], $ai, [0], $ai1, 0, $as); last;};
		$_ == E_NONE    && do { $ai1 = [ @$ai ]; $i = @$ai; last };
	}
	warn "[CB] selected (ai1[" .join(',',@$ai1).'], as[' . scalar(@$as) .  "])\n" if $DEBUG{TRACE};
	DEBUG and print "Use Encoding: " .typeToString($self->{currentEncoding}). "(".typeToString($self->{encoding}).")\n";
	warn "[CB]: enc res: ".typeToString($self->{encoding}).", " .typeToString($self->{currentEncoding}). "\n" if $DEBUG{ENC};
    my $k = 0;
	if($self->{preferredFormat} != -1) {
    	$k = $self->{preferredFormat};
        $k = 0 if $i > $FORMATS[$k][7];
    }
    for(; $i > $FORMATS[$k][7] && $k < 30; $k++)
    {
    	next if $self->{currentEncoding} != E_C40 && $self->{currentEncoding} != E_TEXT;
        if($self->{C49rest} == 1 && $ai1->[$i - 2] == 254 && $FORMATS[$k][7] == $i - 1) {
            $ai1->[$i - 2] = $ai1->[$i - 1];
            $ai1->[$i - 1] = 0;
            $i--;
            last;
        }
    	next if($self->{C49rest} != 0 || $ai1->[$i - 1] != 254 || $FORMATS[$k][7] != $i - 1);
        $ai1->[$i - 1] = 0;
        $i--;
        last;
    }

    return if $k == 30;
    my $l = $k;
	@$self{qw(
		rows
		cols
		datarows
		datacols
		regions
		maprows
		mapcols
		totaldata
		totalerr
		reeddata
		reederr
		reedblocks
	)} = @{$FORMATS[$l]}[0..11];
	DEBUG and print "Format: $self->{rows}x$self->{cols}; Data: $self->{totaldata}; i=$i; blocks = $self->{reedblocks}\n";
	$ai1->[$i - 1] = 129 if (
		($self->{currentEncoding} == E_C40 || $self->{currentEncoding} == E_TEXT )
		and
		$self->{C49rest} == 0 && $i == $self->{totaldata} && $ai1->[$i - 1] == 254
    );
    my $flag = 1;
    warn "Calc begin from $i..$self->{totaldata} ai1=[@{$ai1}]\n" if $DEBUG{CALC};
	for(my $i1 = $i; $i1 < $self->{totaldata}; $i1++) {
        $ai1->[$i1] = $flag ? 129 : A253(129, $i1 + 1);
        $flag = 0;
    }
    return $self->{bitmap} = $self->GenData($self->ecc($l,$ai1));
}

=head2 ecc (format, ai)

Return the ECC200 (DataMatrix) array, formatted for the appropriate matrix
size.

=cut

sub ecc {
	my $self = shift;
	my $format = shift;
	my $ai = shift;
	my ($data,$err,$blocks) = @{$FORMATS[$format]}[9..11];
	$blocks--;$data--;
    warn "ECC: ai=[@{$ai}], blocks=$blocks\n" if $DEBUG{CALC};
    my @blocks = map {[]} 0..$blocks;
    my $block = 0;
    for (@$ai) {
    	push @{$blocks[$block++]}, $_;
    	$block = 0 if $block > $blocks;
    }
    warn "Calc blocks=".Dumper \@blocks if $DEBUG{CALC};
	for (0..$#blocks) {
        $#{ $blocks[$_] } = $data; # correct padding
        if($self->{rows} == 144 and $_ > 7) {
        	$#{$blocks[$_]} -= 1;
        }

		CalcReed($blocks[$_], $err);
	}
    warn "Calc reed=\n".
    	join "\n", map { '['.join(',',@$_).']' } @blocks if $DEBUG{CALC};
    my @rv;
	for my $n (0..$data+$err) {
		for my $b (0..$#blocks) {
			if ( $n < @{$blocks[$b]} ) { # 144 fix
				push @rv, $blocks[$b][$n];
			}
		}
	}
	return \@rv;
}

=head2 isIDigit (character_code)

Return true if the character code represents a digit.

=cut

sub isIDigit { # C1
	my $i = shift;
	return ( $i >= 48 && $i <= 57 ) ? 1 : 0;
}

=head2 isILower (character_code)

Return true if the character code represents a lower case letter.

=cut

sub isILower {
	my $i = shift;
	return ( $i >= ord('a') && $i <= ord('z') ) ? 1 : 0;
}

=head2 isIUpper (character_code)

Return true if the character code represents an upper case letter.

=cut

sub isIUpper {
	my $i = shift;
	return ( $i >= ord('A') && $i <= ord('Z') ) ? 1 : 0;
}

=head2 DetectEncoding

Detect the encoding type.

=cut

sub DetectEncoding() #C4 (int i, int ai[], int ai1[], String as[]) : int
{
	my $self = shift;
	warn "[C4] DetectEncoding(@_)\n" if $DEBUG{TRACE};
	my $ai = $self->{ai};
	my $i = scalar (@$ai);
	my $as = $self->{as};
	my $ai1 = shift;
    my $ai2 = [  ];
    my $ai3 = [  ];
    my $flag = 0;
    my $j1 = 0;
    my $k1 = E_ASCII;
    my $ai4 = [ 0 ];
    my $l2 = E_ASCII;
    my $as1 = [  ];
    my $iterator = 0;
	$self->{currentEncoding} = E_ASCII;
	warn("DetectENC: starting from ".$encName[$self->{currentEncoding}]."\n") if $DEBUG{EAUTO};
    while($iterator < $i) { # while iterator less than length of data
		warn("DetectENC: at $iterator ce=$encName[$self->{currentEncoding}] k1=$encName[$k1] l2=$encName[$l2]\n") if $DEBUG{EAUTO};
    	while($self->{currentEncoding} == E_ASCII and $iterator < $i) {
			warn("DetectENC: while at $iterator ce=$encName[$self->{currentEncoding}] k1=$encName[$k1] l2=$encName[$l2]\n") if $DEBUG{EAUTO};
            my $flag1 = 0;
            if(
            	$iterator + 1 < $i
            	and isIDigit($ai->[$iterator])
            	and isIDigit($ai->[$iterator + 1])
            ){
				warn("DetectENC: 2dig $ai->[$iterator]+$ai->[$iterator+1] at $iterator ce=$encName[$self->{currentEncoding}] k1=$encName[$k1] l2=$encName[$l2]\n") if $DEBUG{EAUTO};
                $ai1->[$j1++] = 254 if($l2 != E_ASCII);
                $ai2->[0]     = $ai->[$iterator];
                $ai2->[1]     = $ai->[$iterator + 1];
                my $j = $self->EncodeASCII(2, $ai2, $ai3, $as1);
				splice(@$ai1,$j1,$j, @$ai3[0 .. $j-1 ]);
                $j1 += $j;
                $iterator++;
                $iterator++;
                $flag1 = 1;
                $l2 = E_ASCII;
            }
            if(!$flag1) {
				warn("DetectENC: !dig !flag1 at $iterator ce=$encName[$self->{currentEncoding}] k1=$encName[$k1] l2=$encName[$l2]\n") if $DEBUG{EAUTO};
            	my $l1 = $self->SelectEncoding( $iterator );
                if( $l1 != E_ASCII) {
					warn("DetectENC: $encName[$self->{currentEncoding}] => $encName[$l1]\n") if $DEBUG{EAUTO};
                	$l2 = $self->{currentEncoding};
                	$self->{currentEncoding} = $l1;
                }
            }
        	if(!$flag1 and $self->{currentEncoding} == E_ASCII){
                $ai1->[$j1++] = 254 if($l2 != E_ASCII);
                $ai2->[0] = $ai->[$iterator];
                $as1->[0] = $as->[$iterator];
                my $k = $self->EncodeASCII(1, $ai2, $ai3, $as1);
                $as1->[0] = undef;
				splice(@$ai1,$j1,$k, @$ai3[0 .. $k-1 ]);
                $j1 += $k;
                $iterator++;
                $l2 = E_ASCII;
            }
        }
		warn("DetectENC: after while at $iterator ce=$encName[$self->{currentEncoding}] k1=$encName[$k1] l2=$encName[$l2]\n") if $DEBUG{EAUTO};
        my $i2;
    	for(; $self->{currentEncoding} == E_C40 and $iterator < $i; $self->{currentEncoding} = $i2) {
            $ai4->[0] = $iterator;
            my $l = $self->EncodeC40TEXT($i, $ai4, $ai, $ai3, 0, $l2 != E_C40, 1);
            $iterator = $ai4->[0];
			splice(@$ai1,$j1,$l, @$ai3[0 .. $l-1 ]);
            $j1 += $l;
        	$i2 = $self->SelectEncoding($iterator);
        	$l2 = $self->{currentEncoding};
        }
		warn("DetectENC: after C40 at $iterator ce=$encName[$self->{currentEncoding}] k1=$encName[$k1] l2=$encName[$l2]\n") if $DEBUG{EAUTO};

        my $j2;
    	for(; $self->{currentEncoding} == E_TEXT and $iterator < $i; $self->{currentEncoding} = $j2) {
            $ai4->[0] = $iterator;
            my $i1 = $self->EncodeC40TEXT($i, $ai4, $ai, $ai3, 1, $l2 != E_TEXT, 1);
            $iterator = $ai4->[0];
			splice(@$ai1,$j1,$i1, @$ai3[0 .. $i1-1 ]);
            $j1 += $i1;
        	$j2 = $self->SelectEncoding($iterator);
        	$l2 = $self->{currentEncoding};
        }
		warn("DetectENC: after TEXT at $iterator ce=$encName[$self->{currentEncoding}] k1=$encName[$k1] l2=$encName[$l2]\n") if $DEBUG{EAUTO};

    	if($self->{currentEncoding} == E_BASE256) {
            $ai4->[0] = $iterator;
            $j1 = $self->EncodeBASE256($i, $ai4, $ai, [$j1], $ai1, 1);
            $iterator = $ai4->[0];
        	my $k2 = $self->SelectEncoding($iterator);
        	$l2 = $self->{currentEncoding};
        	$self->{currentEncoding} = $k2;
        }
		warn("DetectENC: after B256 at $iterator ce=$encName[$self->{currentEncoding}] k1=$encName[$k1] l2=$encName[$l2]\n") if $DEBUG{EAUTO};
    }
    return $j1;
}

=head2 EncodeASCII (i, ai, ai1, as)

Encode the message as ASCII.

=cut

sub EncodeASCII { #CE (int i; int ai[], int ai1[], String as[]) : int
	my $self = shift;
	warn "[CE] EncodeASCII(@_)\n" if $DEBUG{TRACE};
	my ($i,$ai,$ai1,$as) = @_;
	warn "[CE] ai:{".join(" ",grep{+defined}@$ai)."}; ai1:{".join(" ",grep{+defined}@$ai1)."}; as:{".join(" ",grep{+defined}@$as)."}\n" if $DEBUG{ENC};
    my $j = 0;
    my $flag = 0;
    for(my $k = 0; $k < $i; $k++) {
        my $flag1 = 0;
        if(
        	$k < $i - 1
        	and isIDigit($ai->[$k])
        	and isIDigit($ai->[$k+1])
        ) {
            my $l = ($ai->[$k] - 48) * 10 + ($ai->[$k + 1] - 48);
            $ai1->[$j++] = 130 + $l;
            $k++;
            $flag1 = 1;
        }
        if(!$flag1 and defined $as->[$k]) {
            if(
            	   $ai->[$k] == 234
            	or $ai->[$k] == 237
            	or $ai->[$k] == 236
            	or $ai->[$k] == 232
            ) {
                $ai1->[$j++] = $ai->[$k];
                $flag1 = 1;
            }
            if($ai->[$k] == 233 || $ai->[$k] == 241) {
                $ai1->[$j++] = $ai->[$k];
                for(my $i1 = 0; $i1 < length $as->[$k]; $i1++){
                    $ai1->[$j++] = ord substr($as->[$k],$i1,1);
                }
                $flag1 = 1;
            }
        }
        if(!$flag1){
            if($ai->[$k] < 128) {
                $ai1->[$j++] = $ai->[$k] + 1;
            } else {
                $ai1->[$j++] = 235;
                $ai1->[$j++] = ($ai->[$k] - 128) + 1;
            }
        }
    }
    warn "[CE] end $j ai1:{".join(" ",@$ai1)."};\n" if $DEBUG{ENC};
    return $j;
}

=head2 SelectEncoding (j, ai, i)

Select a new encoding type for the message.

=cut

sub SelectEncoding #C3 (int ai[], int i, int j, String as[]) : int # DefineEncoding??
                   #iterator, ai, encoding
{
	#(iterator[,ai[,encoding]])
	#(ai,i: encoding,j: iterator,as)
	my $self = shift;
	warn "[C3] SelectEncoding(@_)\n" if $DEBUG{TRACE};

	my $j = shift;

	my $ai = shift;
	$ai = $self->{ai} unless defined $ai;

	my $i = shift || $self->{currentEncoding};
	$i = $self->{currentEncoding} unless defined $i;

	my $as = $self->{as};
    my $d  = 0.0;
    my $d2 = 1.0;
    my $d3 = 1.0;
    my $d4 = 1.25;
    my $k = $j;
    if($i != E_ASCII)
    {
        $d  = 1.0;
        $d2 = 2.0;
        $d3 = 2.0;
        $d4 = 2.25;
    }
    $d2 = 0.0 if $i == E_C40;
    $d3 = 0.0 if $i == E_TEXT;
    $d4 = 0.0 if $i == E_BASE256;
    for(; $j < @$ai; $j++)
    {
    	warn "SelectEncoding: have as[$j]: $as->[$j]\n" if defined $as->[$j] and $DEBUG{EAUTO};
        my $c = $ai->[$j];
        return E_ASCII if defined $as->[$j];

        if    ( isIDigit($c) )        { $d += 0.5 }
        elsif ( $c > 127 )            { $d = int( $d + 0.5 ) + 2; }
        else                          { $d = int( $d + 0.5 ) + 1; }

        if    ( @{ $C1[$c] } == 1 )   { $d2 += 0.66000000000000003; }
        elsif ( $c > 127 )            { $d2 += 2.6600000000000001;  }
        else                          { $d2 += 1.3300000000000001;  }
        my $c1 = $c;
        if( isIUpper($c) )            { $c1 = ord lc chr $c; }
        if( isILower($c) )            { $c1 = ord uc chr $c; }

        if    ( @{ $C1[$c1] } == 1)   { $d3 += 0.66000000000000003; }
        elsif ( $c1 > 127 )           { $d3 += 2.6600000000000001;  }
        else                          { $d3 += 1.3300000000000001;  }

        $d4++;

        if($j - $k >= 4) {
            return E_ASCII   if $d  + 1.0 <= $d2 and $d + 1.0 <= $d3 and $d + 1.0 <= $d4;
            return E_BASE256 if $d4 + 1.0 <= $d;
            return E_BASE256 if $d4 + 1.0 < $d3 and $d4 + 1.0 < $d2;
            return E_TEXT    if $d3 + 1.0 < $d and $d3 + 1.0 < $d2 and $d3 + 1.0 < $d4;
            return E_C40     if $d2 + 1.0 < $d and $d2 + 1.0 < $d3 and $d2 + 1.0 < $d4;
        }
    }

    $d  = int( $d + 0.5 );
    $d2 = int( $d2 + 0.5 );
    $d3 = int( $d3 + 0.5 );
    $d4 = int( $d4 + 0.5 );
    return E_ASCII   if $d <= $d2 and $d <= $d3 and $d <= $d4;
    return E_TEXT    if $d3 < $d and $d3 < $d2 and $d3 < $d4;
    return E_BASE256 if $d4 < $d and $d4 < $d3 and $d4 < $d2;
    return E_C40;
}

=head2 EncodeC40TEXT (i, ai, ai1, ai2, flag, flag1, flag2)

Encode the message as C40/TEXT.

=cut

sub EncodeC40TEXT { # C6 #(int i, int ai[], int ai1[], int ai2[], boolean flag, boolean flag1, boolean flag2) : int
	my $self = shift;
	my ($i,$ai,$ai1,$ai2,$flag,$flag1,$flag2) = @_;
    my $j = my $k = 0;
    my $ai3 = [ 0, 0, 0 ];
    my $flag3 = 0;
    my $as = [  ];
    if($flag1) {
        $ai2->[$j++] = $flag ? 239 : 230;
    }
    for(my $j1 = $ai->[0]; $j1 < $i; $j1++) {
        my $l = $ai1->[$j1];
        if($flag) {
            my $s = chr($l);
            $s = uc($s) if($l >= 97 && $l <= 122);
            $s = lc($s) if($l >= 65 && $l <= 90);
            $l  = ord(substr($s,0,1));
        }
        my $ai4 = $C1[$l];
        for my $l1 (0 .. $#$ai4) {
            $ai3->[$k++] = $ai4->[$l1];
            if($k == 3) {
                my $i2 = $ai3->[0] * 1600 + $ai3->[1] * 40 + $ai3->[2] + 1;
                $ai2->[$j++] = int $i2 / 256;
                $ai2->[$j++] = $i2 % 256;
                $k = 0;
            }
        }

        if($flag2 && $k == 0) {
        	$self->{C49rest} = $k;
            $ai->[0] = $j1 + 1;
            $ai2->[$j++] = 254 if($ai->[0] == $i);
            return $j;
        }
    }

    $ai->[0] = $i;
    if($k > 0) {
        if($k == 1) {
            $ai2->[$j++] = 254;
            $ai2->[$j++] = $ai1->[$i - 1] + 1;
            return $j;
        }
        if($k == 2) {
            $ai3->[2] = 0;
            my $k1 = $ai3->[0] * 1600 + $ai3->[1] * 40 + $ai3->[2] + 1;
            $ai2->[$j++] = int $k1 / 256;
            $ai2->[$j++] = $k1 % 256;
            $ai2->[$j++] = 254;
        	$self->{C49rest} = $k;
            return $j;
        }
    } else {
        $ai2->[$j++] = 254;
    }
    $self->{C49rest} = $k;
    return $j;
}

=head2 state255 (V, P)

The 255-state algorithm.  Used when encoding strings with the BASE256 type.

This information originally from
L<http://grandzebu.net/informatique/codbar-en/datamatrix.htm>.

Let C<P> the number of data C<CW>s from the beginning of datas (C<CW> = code
word).  Let C<R> be a pseudo random number, C<V> the base 256 C<CW> value
and C<CW> the required C<CW>.

    R = ((149 * P) MOD 255) + 1
    CW = (V + R) MOD 256

=cut

sub state255 # (int V, int P) : int
{
    my ($V,$P) = @_;
    return ( $V + (149 * $P) % 255 + 1 ) % 256;
}

=head2 hexary (src)

Return a string representation of the input hexadecimal number.

=cut

sub hexary {
	join(" ",map{ sprintf '%02x',$_} @{ shift() } )
}

=head2 EncodeBASE256 (i, hint, src, stat, res, flag)

Encode the message as BASE256.

=cut

sub EncodeBASE256 {
	my $self = shift;
	my ($i,$hint,$src,$stat,$res,$flag) = @_;
    my $j = 0;
    my $xv = [];
    my $l = $stat->[0];
    my $flag1 = 0;
    my $j1 = 0;
    warn "AI1{".hexary($src)."}\n" if $DEBUG{B256};
    warn "AI4{".hexary($xv)."}\n" if $DEBUG{B256};
    for( $j1 = $hint->[0]; $j1 < $i; $j1++){
        $xv->[$j++] = $src->[$j1];
        last if $flag and $self->SelectEncoding($j1 + 1,$src,E_BASE256) != E_BASE256;
    }
    warn "AI1{".hexary($src)."}\n" if $DEBUG{B256};
    warn "AI4{".hexary($xv)."}\n" if $DEBUG{B256};
    $hint->[0] = $j1;
    $res->[$l++] = 231;
    if($j < 250) {
        $res->[$l++] = state255($j, $l + 1);
    } else {
        $res->[$l++] = state255(249 + ($i - $i % 250) / 250, $l + 1);
        $res->[$l++] = state255($i % 250, $l + 1);
    }
    $res->[$l++] = state255($xv->[$_], $l + 1) for 0..$j-1;
    $stat->[0] = $l;
    return $l;
}

=head2 GenData (ai)

Generate and return the data for the DataMatrix bitmap from the input array.

=cut

sub GenData { # CC (int ai[]) : int[][]
    my $self = shift;
    my ($ai) = @_;
    warn "[CC] GenData: ".join(",",@$ai)." [$self->{rows} x $self->{cols} : $self->{regions} : $self->{datacols}x$self->{datarows}]\n" if $DEBUG{TRACE};
	my $ai1 = [ map { [ (undef) x $self->{rows} ] } 1..$self->{cols} ]; # reverse cols/rows here, for correct access ->[][]

    my $i = my $j = 0;
    # Draw border
    if($self->{regions} == 2) {
		FillBorder($ai1, $i, $j, $self->{datacols} + 2, $self->{datarows} + 2);
    	FillBorder($ai1, $i + $self->{datacols} + 2, $j, $self->{datacols} + 2, $self->{datarows} + 2);
    } else {
    	my $k = int(sqrt($self->{regions}));
        for(my $l = 0; $l < $k; $l++){
            for(my $i1 = 0; $i1 < $k; $i1++) {
            	FillBorder($ai1, $i + $l * ($self->{datacols} + 2), $j
            		+ $i1 * ($self->{datarows} + 2),
            		$self->{datacols} + 2, $self->{datarows} + 2);
			}
        }

    }
    # End draw border
	my $ai2 = [ (undef) x ( ($self->{mapcols} + 10) * $self->{maprows} ) ];
    warn "[" . join (" ", grep { +defined } @$ai2)."]\n" if $DEBUG{CALC};
	FillCharData($self->{mapcols},$self->{maprows},$ai2);
    warn "[" . join (" ", grep { +defined } @$ai2)."]\n" if $DEBUG{CALC};
	warn "--------------\n" if $DEBUG{CALC};
    warn "[" . join (" ", grep { +defined } @$ai)."]\n" if $DEBUG{CALC};
    my $j1 = 1;
    my $flag = 0;
    my $flag1 = 0;
	for(my $i2 = 0; $i2 < $self->{maprows}; $i2++) {
        my $j2 = 1;
        for(my $k2 = 0; $k2 < $self->{mapcols}; $k2++) {
            my $l1 = $k2 + $j2;
            my $k1 = $i2 + $j1;
            if($ai2->[$i2 * $self->{mapcols} + $k2] > 9) {
            	my $l2 = int ( $ai2->[$i2 * $self->{mapcols} + $k2] / 10 );
            	my $i3 = $ai2->[$i2 * $self->{mapcols} + $k2] % 10;
                my $j3 = $ai->[$l2 - 1] & 1 << 8 - $i3;
                $ai1->[$l1][$k1] = $j3;
            } else {
            	$ai1->[$l1][$k1] = $ai2->[$i2 * $self->{mapcols} + $k2];
            }
        	if($k2 > 0 && ($k2 + 1) % $self->{datacols} == 0) {
                $j2 += 2;
            }
        }

    	if($i2 > 0 && ($i2 + 1) % $self->{datarows} == 0) {
            $j1 += 2;
        }
    }
    return $ai1;
}

=head2 FillBorder (ai, i, j, k, l)

Fill the border of the ECC200 data matrix bitmap.

=cut

sub FillBorder { # CD (int ai[][], int i, int j, int k, int l) : void
	my ($ai,$i,$j,$k,$l) = @_;
    my $i1 = 0;
    for(my $k1 = 0; $k1 < $k; $k1++) {
        $i1 = ($k1 % 2 == 0) ? 1 : 0;
        $ai->[$i + $k1][$j + $l - 1] = 1;
        $ai->[$i + $k1][$j] = $i1;
    }
    $i1 = 0;
    for(my $l1 = 0; $l1 < $l; $l1++) {
        my $j1 = (($l1 + 1) % 2 == 0) ? 1 : 0;
        $ai->[$i][$j + $l1] = 1;
        $ai->[$i + $k - 1][$j + $l1] = $j1;
    }
}

=head2 FillCharData (ncol, nrow, array)

Fill the data matrix with the character data in the given message array.

=cut

sub FillCharData { # (int ncol; int nrow; int array;) : void
	my ($ncol,$nrow,$array) = @_;
	Barcode::DataMatrix::CharDataFiller->new($ncol,$nrow,$array);
	return;
}

1;
