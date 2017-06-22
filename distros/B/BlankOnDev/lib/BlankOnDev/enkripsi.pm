package BlankOnDev::enkripsi;
use strict;
use warnings FATAL => 'all';

# Use or Require Module :
require BlankOnDev::Version;
use Data::Dumper;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use MIME::Base64 ();
use BlankOnDev::Utils::Char;

# Version :
our $VERSION = '0.1005';

# Subroutine for Web Encoder :
# ------------------------------------------------------------------------
=head1 SUBROUTINE Encoder()

	Deskripsi subroutine Encoder() :
	----------------------------------------
	Subroutine yang berfungsi untuk encoder content vital web.

	Format arrayref $plankey :
	----------------------------------------
	$plankey = {
		'num1' => [ Berisi Num1 Random ],
		'num2' => [ Berisi Num2 Random ],
		'key_enc' => [ Berisi Key En-decoder ],
	};

	Parameter subroutine Encoder() :
	----------------------------------------
	$plain_text			=>	Merupakan string yang akan dirandom.
	$plankey			=>	Berisi arrayref untuk plankey random.

	Output Parameter :
	----------------------------------------
	#

=cut
sub Encoder {
    # Define parameter subroutine :
    my ($self, $plain_text, $plankey) = @_;

    # Get NumLoop :
    my $num1 = $plankey->{'num1'};
    my $num11 = $num1 * 2;
    my $num2 = $plankey->{'num2'};
    my $num21 = $num2 * 2;
    my $key_enc = $plankey->{'key_enc'} + 3;

    # Convert string to array :
    my $r_pltxt = $self->random($plain_text, $num1, $num2, 2);
    my @arr_str = BlankOnDev::Utils::Char->split_blen($r_pltxt, 1);

    # While loop to encoder Step 1 :
    my $i = 0;
    my $until = scalar keys(@arr_str);
    my @temp1 = ();
    my $pre1 = undef;
    while ($i < $until) {
        # Convert data array into decimal :
        $pre1 = ord $arr_str[$i];
        $pre1 = $pre1 + $key_enc;

        # Place result into array :
        $temp1[$i] = sprintf("%X", $pre1);

        # Auto Increment :
        $i++;
    }
    #	print "Step 1 Encoder\n";
    #	print Dumper \@temp1;
    #	print "--- Batas ---\n";

    # While loop to encoder Step 2 :
    my @e1 = ('J', 'i', 'o', 'R', 'p', 'I', 'W', 'q', 'M', 'x');
    my %e2 = ("a" => "h", "b" => "j", "c" => "k", "d" => "v", "e" => "t", "f" => "n");
    my $i2 = 0;
    my $until2 = scalar keys(@temp1);
    my $temp2 = '';
    my @temp21 = ();
    my ($pre2, $pre21, $get_int);
    while ($i2 < $until2) {
        # Replace string :
        $pre2 = $temp1[$i2];
        if ($pre2 =~ /(\d)/) {
            $get_int = int $1;
            $pre2 =~ s/$1/$e1[$get_int]/g;
        }
        if ($pre2 =~ /(\d)/) {
            $get_int = int $1;
            $pre2 =~ s/$1/$e1[$get_int]/g;
        }
        $pre2 =~ s/a/$e2{"a"}/;
        $pre2 =~ s/b/$e2{"b"}/;
        $pre2 =~ s/c/$e2{"c"}/;
        $pre2 =~ s/d/$e2{"d"}/;
        $pre2 =~ s/e/$e2{"e"}/;
        $pre2 =~ s/f/$e2{"f"}/;
        $temp21[$i2] = $pre2;
        $temp2 .= $pre2;
        $i2++;
    }
    #	print "Step 2 Encoder : \n";
    #	print "$temp2\n";
    #	print "--- Batas ---\n";

    # Final Random :
    my $data = $self->random($temp2, $num11, $num21, 2);

    # Return :
    return $data;
}
# End of Subroutine for Web Encoder
# ===========================================================================================================

# Subroutine for Web Decoder :
# ------------------------------------------------------------------------
=head1 SUBROUTINE Decoder()

	Deskripsi subroutine Decoder() :
	----------------------------------------
	Subroutine yang berfungsi untuk decoder content vital web.

	Format arrayref $plankey :
	----------------------------------------
	$plankey = [
		(Berisi "num1" random),
		(Berisi "num2" random),
		(Berisi "key_enc" Encoder)
	];

	Parameter subroutine Decoder() :
	----------------------------------------
	$chiper				=>	Merupakan string random yang akan dikembalikan.
	$plankey			=>	Berisi arrayref untuk plankey random.

	Output Parameter :
	----------------------------------------
	#

=cut
sub Decoder {
    # Define parameter subroutine :
    my ($self, $chiper, $plankey) = @_;

    # Define scalar for place result :
    my $data = undef;

    # Get NumLoop :
    my $num1 = $plankey->{'num1'};
    my $num11 = $num1 * 2;
    my $num2 = $plankey->{'num2'};
    my $num21 = $num2 * 2;
    my $key_enc = $plankey->{'key_enc'} + 3;

    # Extract Final Random :
    my $chiper0 = $self->extract_random($chiper, $num11, $num21, 2);

    # While loop to decoder Step 1 :
    my %d1 = ('J' => "0", 'i' => "1", 'o' => "2", 'R' => "3", 'p' => "4", 'I' => "5", 'W' => "6", 'q' => "7", 'M' => "8", 'x' => "9");
    my @pre_chiper = BlankOnDev::Utils::Char->split_blen($chiper0, 1);
    my $i1 = 0;
    my $until1 = scalar keys(@pre_chiper);
    my @temp0 = ();
    my ($match_d1, $pre1_chiper);
    my $temp01 = '';
    my $pre1;
    while ($i1 < $until1) {
        $pre1_chiper = $pre_chiper[$i1];
        if (exists $d1{$pre1_chiper}) {
            $match_d1 = $d1{$pre1_chiper};
            $pre1_chiper =~ s/$pre1_chiper/$match_d1/;
        }
        $temp0[$i1] = $pre1_chiper;
        $temp01 .= $pre1_chiper;
        $i1++;
    }

    #	print "Decoder Step 1\n";
    #	print Dumper \@temp0;
    #	print "--- Batas Step 1 ---\n";

    # While loop to decoder Step 2 :
    my %d2 = ("h" => "a", "j" => "b", "k" => "c", "v" => "d", "t" => "e", "n" => "f");
    my $i2 = 0;
    my $until2 = scalar keys(@temp0);
    my @temp1 = ();
    my ($match_dl1, $pre2_chiper);
    my $temp11 = '';
    while ($i2 < $until2) {
        $pre2_chiper = $temp0[$i2];
        if (exists $d2{$pre2_chiper}) {
            $match_dl1 = $d2{$pre2_chiper};
            $pre2_chiper =~ s/$pre2_chiper/$match_dl1/;
        }
        $temp1[$i2] = $pre2_chiper;
        $temp11 .= $pre2_chiper;
        $i2++;
    }

    #	print "Decoder Step 2\n";
    #	print Dumper \@temp1;
    #	print "--- Batas Step 2 ---\n";

    # Convert $temp1 into array :
    my @arr_chiper = BlankOnDev::Utils::Char->split_blen($temp11, 2);

    # While loop to decoder Step 3 :
    my $i3 = 0;
    my $until3 = scalar keys(@arr_chiper);
    my $temp2 = '';
    my ($pre2, $pre3);
    my @temp21 = ();
    while ($i3 < $until3) {
        $pre2 = sprintf("%d", hex($arr_chiper[$i3]) - $key_enc);
        $pre3 = chr $pre2;
        $temp21[$i3] = $pre3;
        $temp2 .= $pre3;
        $i3++;
    }

    #	print "Decoder Step 3\n";
    #	print Dumper $temp2;
    #	print "--- Batas Step 3 ---\n";

    # Extract Loop :
    $data = $self->extract_random($temp2, $num1, $num2, 2);
#    $data = $temp2;

    # Return result :
    return $data;
}
# End of Subroutine for Web Decoder
# ===========================================================================================================

# Subroutine for Random String :
# ------------------------------------------------------------------------
=head1 SUBROUITNE random()

	Deskripsi subroutine random() :
	----------------------------------------
	Subroutine yang berfungsi untuk membuat random karakter.

	Parameter subroutine random() :
	----------------------------------------
	$string			=>	Berisi string yang akan dirandom.
	$c_odd2even		=>	Berisi Nomor random odd2even.
	$c_even2odd		=>	berisi Nomor random even2odd.
	$nested			=>	Berisi Nested Loop. Ex: 0, 1, 2

	Output Parameter :
	----------------------------------------
	#

=cut
sub random {
    # Define parameter subroutine :
    my ($self, $string, $c_odd2even, $c_even2odd, $nested) = @_;

    # Define scalar for place result :
    my $data = undef;

    # Prepare Stirng :
    my $len_str = length $string;
    my $str = '';

    # Check String, Jika angka genap.
    if (($len_str % 2) eq 0) {
        $str = $string;
    }
    # Check String, jika angka ganjil
    else {
        $str = $string . '|';
    }

    # Action Random :
    $data = $self->loop_odoe2eood($str, $c_odd2even, $c_even2odd, $nested);

    # Return :
    return $data;
}
# End of Subroutine for Random String.
# ===========================================================================================================

# Subroutine for Extract Random String :
# ------------------------------------------------------------------------
=head1 SUBROUTINE extract_random()

	Deskripsi subroutine extract_random() :
	----------------------------------------
	Subroutine yang berfungsi untuk mengekstrak Random String.

	Parameter subroutine extract_random() :
	----------------------------------------
	$string			=>	Berisi string random.
	$c_odd2even		=>	Berisi Nomor random odd2even.
	$c_even2odd		=>	berisi Nomor random even2odd.
	$nested			=>	Berisi Nested Loop. Ex: 0, 1, 2

	Output Parameter :
	----------------------------------------
	#

=cut
sub extract_random {
    # Define parameter subroutine :
    my ($self, $string, $c_odd2even, $c_even2odd, $nested) = @_;

    # Define scalar for place result :
    my $data = undef;

    # Action Extract Random String :
    my $extract = $self->extract_loop_odoe2eood($string, $c_odd2even, $c_even2odd, $nested);

    # Filter Result :
    $extract =~ s/\|$//g;

    # Return result :
    return $extract
}
# End of Subroutine for Extract Random String
# ===========================================================================================================

# Subroutine for get key Encoder and Decoder :
# ------------------------------------------------------------------------
=head1 SUBROUTINE getKey_enc()

	Deskripsi subroutine getKey_enc() :
	----------------------------------------
	Subroutine yang berfungsi untuk membuat key enc
	berdasarkan string yang dimasukkan.

	Parameter subroutine getKey_enc() :
	----------------------------------------
	$string		=>	Berisi string yang akan diubah menjadi
					Key Encoder dan Decoder.

	Output Parameter :
	----------------------------------------
	#

=cut
sub getKey_enc {
    # Define parameter subroutine :
    my ($self, $string) = @_;

    # Define scalar for place result :
    my %data = ();

    # Define scalar to prepare get Key Enc :
    my @arrStr = BlankOnDev::Utils::Char->split_blen($string, 1);

    # While loop to get key enc - Step 1 :
    my $i = 0;
    my $len_arr = scalar keys(@arrStr);
    my $temp1 = 0;
    my $decimal;
    while ($i < $len_arr) {
        $decimal = ord $arrStr[$i];
        $temp1 = int $decimal + $temp1;
        $i++;
    }

    # While loop to get key enc - Step 2 :
    my $ip = 1;
    my $temp2 = $temp1;
    while ($i < $temp1) {
        $temp2 = $temp2 / 2;
        if ($temp2 > 10 and $temp2 < 50) {
            $temp2 = $temp2;
            last;
        }
        $ip++;
    }

    # get Key enc - Final :
    my @getNum = BlankOnDev::Utils::Char->split_blen($temp2, 1);
    my $num1 = $getNum[0];
    my $num2 = $getNum[1];
    my $key_enc = int $temp2;
    $data{num1} = $num1;
    $data{num2} = $num2;
    $data{key_enc} = $key_enc;

    # Return result :
    return \%data;
}
# End of Subroutine for get key Encoder and Decoder
# ===========================================================================================================

# Subroutine for Odd Index :
# ------------------------------------------------------------------------
=head1 SUBROUTINE nkti_odd_index()

	Deskripsi subroutine nkti_odd_index() :
	----------------------------------------
	Subroutine for index odd.

	Parameter subroutine nkti_odd_index() :
	----------------------------------------
	$string

	Output Parameter :
	----------------------------------------
	#

=cut
sub nkti_odd_index {
    # Declare Parameter Module :
    my ($string) = @_;

    # Scalar for placing convert string into array :
    my @arr_string = BlankOnDev::Utils::Char->split_blen($string, 1);

    # Declare scalar for placing result :
    my $data = '';

    # Prepare while loop to Create Even Index:
    my $i = 0;
    my $key_arrstr = scalar keys(@arr_string);
    my $until_loop = $key_arrstr;

    # While loop to Create Even Index :
    while ($i < $until_loop) {

        # Check IF $i % 2 eq 1 :
        if (($i % 2) eq 1) {

            # Placing Even Index into scalar $data :
            $data .= $arr_string[$i];
        }
        # End of check IF $i % 2 eq 1.

        # Auto Increment :
        $i++;
    }
    # End of While loop to Create Even Index.
    # ========================================================================

    # Return Result :
    return $data;
}
# End of Subroutine for Odd Index
# ===========================================================================================================

# Subroutine for Even Index :
# ------------------------------------------------------------------------
=head1 SUBROUTINE nkti_even_index()

	Deskripsi subroutine nkti_even_index() :
	----------------------------------------
	Subroutine for make even index.

	Parameter subroutine nkti_even_index() :
	----------------------------------------
	$string     =>  Berisi string yang akan diambil data even index.

	Output Parameter :
	----------------------------------------
	#

=cut
sub nkti_even_index {

    # Declare Parameter Module :
    my ($string) = @_;

    # Scalar for placing convert string into array :
    my @arr_string = BlankOnDev::Utils::Char->split_blen($string, 1);

    # Declare scalar for placing result :
    my $data = '';

    # Prepare while loop to Create Even Index :
    my $i = 0;
    my $key_arrstr = scalar keys(@arr_string);
    my $until_loop = $key_arrstr;

    # While loop to Create Even Index :
    while ($i < $until_loop) {

        # Check IF $i % 2 eq 0 :
        # ----------------------------------------------------------------
        if (($i % 2) eq 0) {

            # Placing Even Index into scalar $data :
            $data .= $arr_string[$i];
        }
        # End of check IF $i % 2 eq 0.
        # =================================================================

        # Auto Increment :
        $i++;
    }
    # End of While loop to Create Even Index.
    # ========================================================================

    # Return Result :
    return $data;
}
# End of Subroutine for Even Index
# ===========================================================================================================

# Subroutine for Extract odd character to even character :
# ------------------------------------------------------------------------
=head1 SUBROUTINE nkti_extract_odd2even()

	Deskripsi subroutine nkti_extract_odd2even() :
	----------------------------------------
	Subroutine yang berfungsi untuk meng-ekstract character odd ke even.

	Parameter subroutine nkti_extract_odd2even() :
	----------------------------------------
	$string

	Output Parameter :
	----------------------------------------
	#

=cut
sub nkti_extract_odd2even {

    # Declare parameter subroutine :
    my ($string) = @_;

    # Scalar for get count length char in odd and even index :
    my $get_odd = nkti_odd_index($string);
    my $get_even = nkti_even_index($string);
    my $len_odd = length $get_odd;
    my $len_even = length $get_even;
    my @arr_odd = BlankOnDev::Utils::Char->split_blen(substr($string, 0, $len_odd), 1);
    my @arr_even = BlankOnDev::Utils::Char->split_blen(substr($string, $len_odd, $len_even), 1);

    # Scalar for placing result :
    my $data = '';

    # Check IF Len Odd < len Even :
    if ($len_odd lt $len_even) {

        # Prepare while loop to Extract Odd 2 Even:
        my $i = 0;
        my $until_loop = $len_even;
        my $string_even = '';
        my $string_odd = '';

        # While loop to Extract Odd 2 Even :
        while ($i < $len_even) {

            # Check IF $i ne $len_even :
            if ($i ne $len_even) {

                # Define String Even and Odd :
                if (exists $arr_odd[$i]) { $string_odd = $arr_odd[$i]; }

                # Placing result for IF $i eq $len_odd :
                $data .= $arr_even[$i];
                $data .= $string_odd;
            }
            # End of check IF $i ne $len_even.
            # =================================================================

            # Check IF $i eq $len_even :
            elsif ($i eq $len_even) {

                # Placing result for IF $i eq $len_odd :
                $data .= $arr_even[$i];
            }
            # End of check IF $i eq $len_even.
            # =================================================================

            # Auto Increment :
            $i++;
        }
        # End of While loop to Extract Odd 2 Even.
        # ========================================================================
    }
    # End of check IF Len Odd < len Even.
    # =================================================================

    # Check IF Len Odd == Len Even :
    elsif ($len_odd eq $len_even) {

        # Prepare while loop to Extract Odd2Even:
        my $i_oe = 0;
        my $until_loop = $len_even;

        # While loop to Extract Odd2Even :
        while ($i_oe < $until_loop) {

            # Placing result :
            $data .= $arr_even[$i_oe] . $arr_odd[$i_oe];

            # Auto Increment :
            $i_oe++;
        }
        # End of While loop to Extract Odd2Even.
        # ========================================================================
    }
    # End of check IF Len Odd == Len Even.
    # =================================================================

    # Return Result :
    return $data;
}
# End of Subroutine for Extract odd character to even character
# ===========================================================================================================

# Subroutine for Extract string even2odd :
# ------------------------------------------------------------------------
=head1 SUBROUTINE nkti_extract_even2odd()

	Deskripsi subroutine nkti_extract_even2odd() :
	----------------------------------------
	Subroutine yang berfungsi untuk meng-ekstrak string even-odd.

	Parameter subroutine nkti_extract_even2odd() :
	----------------------------------------
	$string

	Output Parameter :
	----------------------------------------
	#

=cut
sub nkti_extract_even2odd {

    # Declare parameter subroutine
    my ($string) = @_;

    # Scalar for get count length char in odd and even index :
    my $get_odd = nkti_odd_index($string);
    my $get_even = nkti_even_index($string);
    my $len_odd = length $get_odd;
    my $len_even = length $get_even;
    my @arr_even = BlankOnDev::Utils::Char->split_blen(substr($string, 0, $len_even), 1);
    my @arr_odd = BlankOnDev::Utils::Char->split_blen(substr($string, $len_even, $len_odd), 1);

    # Scalar for placing result :
    my $data = '';
    my $str_odd = '';
    my $str_even = '';

    # Check IF Len Odd < len Even :
    if ($len_odd lt $len_even) {

        # Prepare while loop to Extract Odd 2 Even:
        my $i = 0;
        my $until_loop = $len_even;

        # While loop to Extract Odd 2 Even :
        while ($i < $len_even) {

            # Check IF $arr_odd[$i] is exist :
            if (exists $arr_odd[$i]) {$str_odd = $arr_odd[$i];}
            if (exists $arr_even[$i]) {$str_even = $arr_even[$i];}

            # Placing result for IF $i eq $len_odd :
            $data .= $str_even;
            $data .= $str_odd;

            # Auto Increment :
            $i++;
        }
        # End of While loop to Extract Odd 2 Even.
        # ========================================================================
    }
    # End of check IF Len Odd < len Even.
    # =================================================================

    # Check IF Len Odd == Len Even :
    elsif ($len_odd eq $len_even) {

        # Prepare while loop to Extract Odd2Even:
        my $i_oe = 0;
        my $until_loop = $len_even;

        # While loop to Extract Odd2Even :
        while ($i_oe < $until_loop) {

            # Check IF $arr_odd[$i] is exist :
            if (exists $arr_odd[$i_oe]) {$str_odd = $arr_odd[$i_oe];}
            if (exists $arr_even[$i_oe]) {$str_even = $arr_even[$i_oe];}

            # Placing result :
            $data .= $arr_even[$i_oe] . $arr_odd[$i_oe];

            # Auto Increment :
            $i_oe++;
        }
        # End of While loop to Extract Odd2Even.
        # ========================================================================
    }
    # End of check IF Len Odd == Len Even.
    # =================================================================

    # Return Result :
    return $data;
}
# End of Subroutine for Extract string even2odd
# ===========================================================================================================

# Subroutine for convert odd character to even character :
# ------------------------------------------------------------------------
=head1 SUBROUTINE nkti_odd2even()

	Deskripsi subroutine nkti_odd2even() :
	----------------------------------------
	Subroutine yang berfungsi untuk convert karakter odd ke even.

	Parameter subroutine nkti_odd2even() :
	----------------------------------------
	$string

	Output Parameter :
	----------------------------------------
	#

=cut
sub nkti_odd2even {

    # Declare Parameter Subroutine :
    my ($string) = @_;

    # Scalar for get odd and even index :
    my $odd_index = nkti_odd_index($string);
    my $even_index = nkti_even_index($string);

    # Scalar for join value of odd and even index :
    my $result = $odd_index . $even_index;

    # Return Result :
    return $result;
}
# End of Subroutine for convert odd character to even character
# ===========================================================================================================

# Subroutine for convert even character to odd character :
# ------------------------------------------------------------------------
=head1 SUBROUTINE nkti_even2odd()

	Deskripsi subroutine nkti_even2odd() :
	----------------------------------------
	Subroutine yang berfungsi untuk convert karakter even ke odd.

	Parameter subroutine nkti_even2odd() :
	----------------------------------------
	$string

	Output Parameter :
	----------------------------------------
	#

=cut
sub nkti_even2odd {

    # Declare Parameter Subroutine :
    my ($string) = @_;

    # Scalar for get even and odd index :
    my $even_index = nkti_even_index($string);
    my $odd_index = nkti_odd_index($string);

    # Scalar for join value of even and odd index :
    my $result = $even_index . $odd_index;

    # Return Result :
    return $result;
}
# End of Subroutine for convert even character to odd character
# ===========================================================================================================

# Subroutine for Action acak odd-to-even ke even-to-odd :
# ------------------------------------------------------------------------
=head1 SUBROUTINE action_loop_odoe2eood()

	Deskripsi subroutine action_loop_odoe2eood() :
	----------------------------------------
	Subroutine yang berfungsi untuk melakukan action acak karakter
	odd-to-even ke even-to-odd.

	Parameter subroutine action_loop_odoe2eood() :
	----------------------------------------
    $count_loop		=>	Berisi Jumlah Nilai Loop.
    $string			=>	Berisi String yang akan diacak.
    $type_acak		=>	Berisi Type Acak String.
    					Ex: "even2odd"	=>	Acak Genap Ganjil.
    						"odd2even"	=>	Acak Ganjil Genap.

	Output Parameter :
	----------------------------------------
	#

=cut
sub action_loop_odoe2eood {

    # Define parameter module :
    my ($count_loop, $string, $type_acak) = @_;

    # Define scalar for action and result :
    my $result = $string;
    my $i = 0;

    # FOR $type_acak == 'even2odd' :
    if ($type_acak eq 'even2odd') {

        # While for extract acak loop even2odd :
        while ($i < $count_loop) {
            $result = nkti_even2odd($result);
            $i++;
        }
    }

    # FOR $type_acak == 'odd2even' :
    elsif ($type_acak eq 'odd2even') {

        # While for extract acak loop odd2even :
        while ($i < $count_loop) {
            $result = nkti_odd2even($result);
            $i++;
        }
    }

    # Return Result :
    return $result;
}
# End of Subroutine for Action acak odd-to-even ke even-to-odd
# ===========================================================================================================

# Subroutine for Acak odd-to-even ke even-to-odd :
# ------------------------------------------------------------------------
=head1 SUBROUTINE loop_odoe2eood()

	Deskripsi subroutine loop_odoe2eood() :
	----------------------------------------
	Subroutine yang berfungsi untuk acak karakter
	odd-to-even ke even-to-odd.

	Parameter subroutine loop_odoe2eood() :
	----------------------------------------
    $string				=>	Berisi String yang akan diacak.
    $count_odd2even		=>	Count Acak Odd TO Even.
    $count_even2odd		=>	Count Acak Even TO Odd
    $status_nested		=>	Berisi status Nested.
    						Ex: 1 => Antara "odd2even" dan "even2odd".
    							2 => "odd2even" dan "even2odd".
    							0 => Gabungan antara "odd2even" dan "even2odd"

	Output Parameter :
	----------------------------------------
	#

=cut
sub loop_odoe2eood {

    # Declare Scalar for placing arguments/parameters Subroutine :
    # ----------------------------------------------------------------
    my $self = shift;
    my $string = undef;
    my $count_odd2even = undef;
    my $count_even2odd = undef;
    my $status_nested = undef;
    my $sizeof_args = scalar keys(@_);

    # FOR Check IF arguments == 2
    # ----------------------------------------------------------------
    if ($sizeof_args == 2) {
        $string = $_[0];
        $count_odd2even = $_[1];
        $count_even2odd = 0;
        $status_nested = 0;
    }

    # FOR Check IF arguments == 3
    # ----------------------------------------------------------------
    elsif ($sizeof_args == 3) {
        $string = $_[0];
        $count_odd2even = $_[1];
        $count_even2odd = $_[2];
        $status_nested = 0;
    }

    # FOR Check IF Arguments > 4
    # ----------------------------------------------------------------
    elsif ($sizeof_args >= 4) {
        $string = $_[0];
        $count_odd2even = $_[1];
        $count_even2odd = $_[2];
        if ($_[3] eq 0) {
            $status_nested = 0;
        } else {
            $status_nested = $_[3];
        }
    }

    # Declare Scalar for looop :
    # ----------------------------------------------------------------
    my $result = undef;
    my $i_1 = undef;
    my $i_2 = undef;

    # Check IF $status_nested == 1 :
    # ----------------------------------------------------------------
    if ($status_nested == 1) {

        # For ODD 2 Even :
        if ($count_odd2even ne 0 and $count_even2odd eq 0) {
            # While for acak string odd 2 even :
            $result = $string;
            $i_1 = 0;
            my $untloop_1 = $count_odd2even;
            while ($i_1 < $untloop_1) {
                $result = nkti_odd2even($result);
                $i_1++;
            }
        }

        # For EVEN 2 Odd :
        elsif ($count_odd2even eq 0 and $count_even2odd ne 0) {
            # While for acak string even 2 odd :
            $result = $string;
            $i_2 = 0;
            my $untloop_2 = $count_even2odd;
            while ($i_2 < $untloop_2) {
                $result = nkti_even2odd($result);
                $i_2++;
            }
        }
    }
    # End of check IF $status_nested == 1.
    # =================================================================

    # Check IF $status_nested == 2 :
    # ----------------------------------------------------------------
    elsif ($status_nested == 2) {

        # For ODD 2 Even Combine EVEN 2 ODD :
        if ($count_odd2even ne 0 and $count_even2odd ne 0) {
            # While for acak string odd2even And even2odd :
            $result = $string;
            $i_1 = 0;
            $i_2 = 0;
            while ($i_1 < $count_odd2even) {
                $result = nkti_odd2even($result);
                $result = action_loop_odoe2eood($count_even2odd, $result, 'even2odd');
                $i_1++;
            }
        }

        # For ODD 2 Even :
        elsif ($count_odd2even ne 0 and $count_even2odd eq 0) {
            # While for acak string odd 2 even :
            $result = $string;
            $i_1 = 0;
            my $untloop_1 = $count_odd2even;
            while ($i_1 < $untloop_1) {
                $result = nkti_odd2even($result);
                $i_1++;
            }
        }

        # For EVEN 2 Odd :
        elsif ($count_odd2even eq 0 and $count_even2odd ne 0) {
            # While for acak string even 2 odd :
            $result = $string;
            $i_2 = 0;
            my $untloop_2 = $count_even2odd;
            while ($i_2 < $untloop_2) {
                $result = nkti_even2odd($result);
                $i_2++;
            }
        }
    }
    # End of check IF $status_nested == 2.
    # =================================================================

    # Check IF $status_nested == 0 :
    # ----------------------------------------------------------------
    else {

        # For ODD 2 Even and EVEN 2 Odd :
        if ($count_odd2even ne 0 and $count_even2odd ne 0) {
            # While for acak string odd2even and even2odd :
            $result = $string;
            $i_1 = 0;
            $i_2 = 0;
            my $result1 = action_loop_odoe2eood($count_odd2even, $string, 'odd2even');
            $result = action_loop_odoe2eood($count_even2odd, $result1, 'even2odd');
        }

        # For ODD 2 Even :
        elsif ($count_odd2even ne 0 and $count_even2odd eq 0) {
            # While for acak string odd2even :
            $result = $string;
            $i_1 = 0;
            while ($i_1 < $count_odd2even) {
                $result = nkti_odd2even($result);
                $i_1++;
            }
        }

        # For EVEN 2 Odd :
        elsif ($count_odd2even eq 0 and $count_even2odd ne 0) {
            # While for acak string even2odd :
            $result = $string;
            $i_2 = 0;
            while ($i_2 < $count_even2odd) {
                $result = nkti_even2odd($result);
                $i_2++;
            }
        }
    }
    # End of check IF $status_nested == 0.
    # =================================================================

    # Return Result :
    # ----------------------------------------------------------------
    return $result;
}
# End of Subroutine for Acak odd-to-even ke even-to-odd
# ===========================================================================================================

# Subroutine for Get Loop Extract for even2odd OR odd2even :
# ------------------------------------------------------------------------
=head1 SUBROUTINE loop_extract_eood2odoe()

	Deskripsi subroutine loop_extract_eood2odoe() :
	----------------------------------------
	Subroutine yang berfungsi untuk melakukan extract
	even-to-odd ke odd-to-even.

	Parameter subroutine loop_extract_eood2odoe() :
	----------------------------------------
	$count_loop
    $string
    $type_acak

	Output Parameter :
	----------------------------------------
	#

=cut
sub loop_extract_eood2odoe {

    # Define parameter module :
    my ($count_loop, $string, $type_acak) = @_;

    # Define scalar for action and result :
    my $result = $string;
    my $i = 0;

    # FOR $type_acak == 'even2odd' :
    if ($type_acak eq 'even2odd') {

        # While for extract acak loop even2odd :
        while ($i < $count_loop) {
            $result = nkti_extract_even2odd($result);
            $i++;
        }
    }

    # FOR $type_acak == 'odd2even' :
    elsif ($type_acak eq 'odd2even') {

        # While for extract acak loop odd2even :
        while ($i < $count_loop) {
            $result = nkti_extract_odd2even($result);
            $i++;
        }
    }

    # Return Result :
    return $result;
}
# End of Subroutine for Get Loop Extract for even2odd OR odd2even
# ===========================================================================================================

# Subroutine for Extarct Loop odd2even OR even2odd :
# ------------------------------------------------------------------------
=head1 SUBROUTINE extract_loop_odoe2eood()

	Deskripsi subroutine extract_loop_odoe2eood() :
	----------------------------------------
	Subroutine yang berfungsi untuk mengembalikan Hasil
    acak string dalam bentuk semula.

	Parameter subroutine extract_loop_odoe2eood() :
	----------------------------------------
	$string				=>	Berisi String Acak yang akan dikembalikan.
    $count_odd2even		=>	Count Acak Odd TO Even.
    $count_even2odd		=>	Count Acak Even TO Odd
    $status_nested		=>	Berisi status Nested.
    						Ex: 1 => Antara "odd2even" dan "even2odd".
    							2 => "odd2even" dan "even2odd".
    							0 => Gabungan antara "odd2even" dan "even2odd"

	Output Parameter :
	----------------------------------------
	#

=cut
sub extract_loop_odoe2eood {

    # Declare Scalar for placing arguments/parameters Subroutine :
    my $self = shift;
    my $string = undef;
    my $count_odd2even = undef;
    my $count_even2odd = undef;
    my $status_nested = undef;
    my $sizeof_args = scalar keys @_;

    # FOR Check IF arguments == 2
    if ($sizeof_args eq 2) {
        $string = $_[0];
        $count_odd2even = $_[1];
        $count_even2odd = 0;
        $status_nested = 0;
    }

    # FOR Check IF arguments == 3
    if ($sizeof_args eq 3) {
        $string = $_[0];
        $count_odd2even = $_[1];
        $count_even2odd = $_[2];
        $status_nested = 0;
    }

    # FOR Check IF Arguments > 4
    if ($sizeof_args >= 4) {
        $string = $_[0];
        $count_odd2even = $_[1];
        $count_even2odd = $_[2];
        if ($_[3] eq 0) {
            $status_nested = 0;
        } else {
            $status_nested = $_[3];
        }
    }

    # Declare Scalar for loop :
    my $result = $string;
    my $i_1 = undef;
    my $i_2 = undef;

    # Check IF $status_nested == 1 :
    if ($status_nested eq 1) {

        # For ODD 2 even Extract :
        if ($count_odd2even ne 0 and $count_even2odd eq 0) {
            # While for extract acak string odd2even :
            $i_1 = 0;
            while ($i_1 < $count_odd2even) {
                $result = nkti_extract_odd2even($result);
                $i_1++;
            }
        }

        # For EVEN 2 Odd Extract :
        if ($count_odd2even eq 0 and $count_even2odd ne 0) {
            # While for extract acak string even2odd :
            $i_2 = 0;
            while ($i_2 < $count_even2odd) {
                $result = nkti_extract_even2odd($result);
                $i_2++;
            }
        }
    }
    # End of check IF $status_nested == 1.
    # =================================================================

    # Check IF $status_nested == 2 :
    elsif ($status_nested eq 2) {
        # For ODD 2 Even Combine EVEN 2 ODD Extract :
        if ($count_odd2even ne 0 and $count_even2odd ne 0) {
            # While for Extract acak string odd2even And even2odd :
            $i_1 = 0;
            while ($i_1 < $count_odd2even) {
                $result = loop_extract_eood2odoe($count_even2odd, $result, 'even2odd');
                $result = nkti_extract_odd2even($result);
                $i_1++;
            }
        }

        # For EVEN 2 Odd Extract :
        if ($count_odd2even ne 0 and $count_odd2even eq 0) {
            # While for Extract acak string odd 2 even :
            $i_1 = 0;
            while ($i_1 < $count_odd2even) {
                $result = nkti_extract_odd2even($result);
                $i_1++;
            }
        }

        # For EVEN 2 Odd Extract :
        if ($count_odd2even eq 0 and $count_even2odd ne 0) {
            # While for Extract acak string even 2 odd :
            $i_1 = 0;
            while ($i_1 < $count_odd2even) {
                $result = nkti_extract_even2odd($result);
                $i_1++;
            }
        }
    }
    # End of check IF $status_nested == 2.
    # =================================================================

    # Check IF $status_nested == 0 :
    else {

        # For ODD 2 Even and EVEN 2 Odd :
        if ($count_odd2even ne 0 and $count_even2odd ne 0) {
            # While for acak string odd2even and even2odd :
            $i_1 = 0;
            $i_2 = 0;
            my $result1 = loop_extract_eood2odoe($count_even2odd, $result, 'even2odd');
            $result = loop_extract_eood2odoe($count_odd2even, $result1, 'odd2even');
        }

        # For ODD 2 Even :
        if ($count_odd2even ne 0 and $count_even2odd eq 0) {
            # While for acak string odd2even :
            $i_1 = 0;
            while ($i_1 < $count_odd2even) {
                $result = nkti_extract_odd2even($result);
                $i_1++;
            }
        }

        # For EVEN 2 Odd :
        if ($count_odd2even eq 0 and $count_even2odd ne 0) {
            # While for acak string even2odd :
            $i_2 = 0;
            while ($i_2 < $count_even2odd) {
                $result = nkti_extract_even2odd($result);
                $i_2++;
            }
        }
    }
    # End of check IF $status_nested == 0.
    # =================================================================

    # Return Result :
    return $result;

}
# End of Subroutine for Extarct Loop odd2even OR even2odd
# ===========================================================================================================

1;
__END__
#