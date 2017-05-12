package Business::DE::KontoCheck;
require 5.00503;
$VERSION = '0.12';
use strict;
use warnings;
use Cwd;
use Carp qw(carp croak);
use Business::DE::Konto qw(:errorcodes);
use vars qw($cache $CACHE_ON $CACHE_ALL $STORABLE);
$CACHE_ALL = 0;
$CACHE_ON = 1;
#use Data::Dumper;

my $check_code = {
	# METHODE, MODULO, [GEWICHTUNGEN], PRUEFZIFFER-STELLE, FALLBACKMWTHODE
	"00" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "00"],
	"01" => ["NORMAL",10,[3, 7, 1, 3, 7, 1, 3, 7, 1], 10, "01"],
	"02" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 2], 10, "02"],
	"03" => ["NORMAL",10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "01"],
	"04" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], 10, "02"],
	"05" => ["NORMAL",10,[7, 3, 1, 7, 3, 1, 7, 3, 1], 10, "01"],
	"06" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], 10, "06"],
	"07" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 10],10, "02"],
	"08" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "08"],
	"09" => ["NORMAL",11,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "09"],
	"10" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 10],10, "06"],
	"11" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 10],10, "11"],
	"12" => ["NORMAL",10,[1, 3, 7, 1, 3, 7, 1, 3, 7], 10, "01"],
	"13" => ["QUER",  10,[0, 0, 2, 1, 2, 1, 2, 1, 0],  8, "13"],# bugfix 12.09.02
	"14" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], 10, "14"],
	"15" => ["NORMAL",11,[2, 3, 4, 5, 2, 3, 4, 5, 2], 10, "06"],
	"16" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], 10, "16"],
	"17" => ["NORMAL",11,[1, 2, 1, 2, 1, 2, 1, 2, 1],  8, "17"],
	"18" => ["NORMAL",10,[3, 9, 7, 1, 3, 9, 7, 1, 3], 10, "01"],
	"19" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 1], 10, "06"],
	"20" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 3], 10, "06"],
	"21" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "21"],
	"22" => ["ONES",  10,[3, 1, 3, 1, 3, 1, 3, 1, 3], 10, "00"],
	"23" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4],  7, "16"],
	"24" => ["NORMAL",11,[1, 2, 3, 1, 2, 3, 1, 2, 3], 10, "24"],
	"25" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 0], 10, "25"],
	"26" => ["NORMAL",11,[0, 0, 2, 3, 4, 5, 6, 7, 2], 10, "06"],
	"27" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "00"],
	"28" => ["NORMAL",11,[0, 0, 2, 3, 4, 5, 6, 7, 8],  8, "06"],
	"29" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "27"],
	"30" => ["NORMAL",10,[2, 0, 0, 0, 0, 1, 2, 1, 2], 10, "00"],
	"31" => ["NORMAL",11,[9, 8, 7, 6, 5, 4, 3, 2, 1], 10, "31"],
	"32" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 0, 0, 0], 10, "06"],
	"33" => ["NORMAL",11,[2, 3, 4, 5, 6, 0, 0, 0, 0], 10, "06"],
	"34" => ["NORMAL",11,[0, 0, 2, 4, 8, 5,10, 9, 7],  8, "06"],
	"35" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9,10], 10, "35"],
	"36" => ["NORMAL",11,[2, 4, 8, 5, 0, 0, 0, 0, 0], 10, "06"],
	"37" => ["NORMAL",11,[2, 4, 8, 5,10, 0, 0, 0, 0], 10, "06"],
	"38" => ["NORMAL",11,[2, 4, 8, 5,10, 9, 0, 0, 0], 10, "06"],
	"39" => ["NORMAL",11,[2, 4, 8, 5,10, 9, 7, 0, 0], 10, "06"],
	"40" => ["NORMAL",11,[2, 4, 8, 5,10, 9, 7, 3, 6], 10, "06"],
	"41" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "00"],
	"42" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 0], 10, "06"],
	"43" => ["NORMAL",10,[1, 2, 3, 4, 5, 6, 7, 8, 9], 10, "01"],
	"44" => ["NORMAL",11,[2, 4, 8, 5,10, 0, 0, 0, 0], 10, "06"],
	"45" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "00"],
	"46" => ["NORMAL",11,[0, 0, 2, 3, 4, 5, 6, 0, 0],  8, "06"],
	"47" => ["NORMAL",11,[0, 2, 3, 4, 5, 6, 0, 0, 0],  9, "06"],
	"48" => ["NORMAL",11,[0, 2, 3, 4, 5, 6, 7, 0, 0],  9, "06"],
	"49" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "00"],
	"50" => ["NORMAL",11,[0, 0, 0, 2, 3, 4, 5, 6, 7],  7, "06"],
	"51" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 0, 0, 0], 10, "06"],
	"52" => ["NORMAL",11,[2, 4, 8, 5,10, 9, 7, 3, 6, 1, 2, 4], 6, "52"],
	"53" => ["NORMAL",11,[2, 4, 8, 5,10, 9, 7, 3, 6, 1, 2, 4], 6, "52"],
	"54" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 0, 0], 10, "06"],
	"55" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 7, 8], 10, "06"],
	"56" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], 10, "06"],
	"57" => ["QUER",  10,[1, 2, 1, 2, 1, 2, 1, 2, 1], 10, "00"],
	"58" => ["NORMAL",11,[2, 3, 4, 5, 6, 0, 0, 0, 0], 10, "02"],
	"59" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "00"],
	"60" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 0, 0], 10, "00"],
	"61" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2],  8, "01"],
	"62" => ["QUER",  10,[0, 0, 2, 1, 2, 1, 2, 0, 0],  8, "00"],
	"63" => ["QUER",  10,[0, 0, 2, 1, 2, 1, 2, 1, 0],  8, "00"],
	"64" => ["NORMAL",11,[0, 0, 0, 2, 4, 8, 5,10, 9],  7, "06"],
	"65" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2],  8, "00"],
	"66" => ["NORMAL",11,[2, 3, 4, 5, 6, 0, 0, 7, 0], 10, "01"],
	"67" => ["QUER",  10,[0, 0, 2, 1, 2, 1, 2, 1, 2],  8, "00"],
	"68" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "00"],
	"69" => ["NORMAL",11,[0, 0, 2, 3, 4, 5, 6, 7, 8], 10, "06"],
	"70" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], 10, "06"],
	"71" => ["NORMAL",11,[0, 0, 1, 2, 3, 4, 5, 6, 0], 10, "06"],
	"72" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 0, 0, 0], 10, "00"],
	"73" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "00"],
	"74" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], 10, "00"],
};

sub new {
	my ($class, %args) = @_;
	my $self = bless {}, $class;
	$self->{BLZFILE} = "./BLZ.dat";
	$self->{BLZFILE} = $args{BLZFILE} if defined $args{BLZFILE};
	$self->{MODE_BLZ_FILE} = $args{MODE_BLZ_FILE} || 'BANK';
	croak "Could not find BLZFILE ".cwd."/$self->{BLZFILE}." unless -f $self->{BLZFILE};
	$self->_cache_all() if $CACHE_ALL;
	if ($self->{MODE_BLZ_FILE} eq 'MINIMAL') {
		#eval qq{use Storable;warn "loaded Storable\n"};
		require Storable;
	} 
	return $self;
	
}
############################
sub check {
	my ($self, %args) = @_;
	$self->{ERRORS} = {};
	$self->{KONTONR} = $args{KONTONR} if defined $args{KONTONR};
	$self->{BLZ} = $args{BLZ} if defined $args{BLZ};
	#print "new Konto...\n";
	my $konto = Business::DE::Konto->new;
	unless ($self->_validBLZ($self->{BLZ}) && $self->_validKONTONR($self->{KONTONR})) {
		$konto->_setError($_) for keys %{ $self->{ERRORS} };
#print Dumper $self->{ERRORS};
		return $konto;
	}
	my $result = $self->get_info_for_blz($self->{BLZ}, $konto);
	#print Dumper $result;
	# ok, input is okay, so now let's go into details
	if ($result) {
		#print Dumper $konto;
		$konto->_setValue(KONTONR => $self->{KONTONR});
		$konto->_setErrorCodes($self->{ERRORCODES}) if $self->{ERRORCODES};
		#print "_pruefe ($konto->{KONTONR}, $konto->{METHOD})\n";
		unless ($self->_pruefe($konto)) {
			$konto->_setError("ERR_KNR_INVALID");
			return $konto;
		}
	}
	$konto->_setError($_) for keys %{$self->{ERRORS}};
	return $konto;
}
############################
sub _validBLZ {
	my $self = shift;
	my $blz = shift;
	$self->{ERRORS}->{ERR_NO_BLZ}++,return unless defined $blz;
	$self->{ERRORS}->{ERR_BLZ}++,return if ($blz =~ tr/0-9//) != 8;
	#print Dumper $self;
	#print "valid blz $blz\n";
	return 1;
}
############################
sub _validKONTONR {
	my $self = shift;
	my $kontonr = shift;
	$self->{ERRORS}->{ERR_NO_KNR}++,return unless defined $kontonr;
	$self->{ERRORS}->{ERR_KNR}++,return if $kontonr =~ m/\D/;
	return 1;
}
############################
sub _cache_all {
	my $self = shift;
	$CACHE_ON = 1;
	my $mode = $self->{MODE_BLZ_FILE} || 'BANK';
	open BLZ, "<$self->{BLZFILE}" or die "Could not open BLZ-File $self->{BLZFILE}: $!";
	if ($mode eq 'BANK') {
		while (my $line = <BLZ>) {
			my (
                $D_BLZ, $D_EIGEN, $OLD_BLZ, undef, undef,
                undef, $D_INST, $D_K_ORT, $D_PLZ, $D_ORT,
                undef, undef, undef, $D_BIC, $D_METHOD,
                undef
            ) = 
				unpack "A8A1A8AA4A5A58A20A5A29A27A5AA9A2A5", $line;
				$cache->{$D_BLZ}->{METHOD} = $D_METHOD;
				#$cache->{$D_BLZ}->{OLD_BLZ} = $OLD_BLZ;
				$cache->{$OLD_BLZ}->{METHOD} = $D_METHOD if $D_BLZ eq "00000000";
		}
	}
	elsif ($mode eq 'POST') {
		while (my $line = <BLZ>) {
			if (my ($D_BLZ, $D_INST, $D_PLZ, $D_ORT, $D_METHOD, $REST) = 
						$line =~ m/^(\d{8})(.{58})(\d{5})(.{30})(\d\d)(\d)/ ) {
				$D_INST =~ s/^\s+|\s+$//;
				$D_ORT =~ s/^\s+|\s+$//;
				$cache->{$D_BLZ}->{METHOD} = $D_METHOD;
			}
		}
	}
	#warn "blz read...\n";
	#<STDIN>;
	my $count = keys %$cache;
	warn "count: $count (line $.)\n";
	close BLZ;
	#warn "closed file\n";
	#<STDIN>;
}
############################
sub get_info_for_blz {
    my ($self, $blz, $konto) = @_;
	my $mode = $self->{MODE_BLZ_FILE} || 'BANK';
    unless ($konto) {
        $konto = Business::DE::Konto->new;
    }
	my ($line,$result);
	unless ($mode eq 'MINIMAL') {
		open BLZ, "<$self->{BLZFILE}" or die "Could not open BLZ-File $self->{BLZFILE}: $!";
		while (defined ($line = <BLZ>)) {
			last if $line =~ m/^$blz/ || ($mode eq 'BANK' && $line =~ m/^\d{8}.$blz/);
		}
		unless ($line) {
			$self->{ERRORS}->{ERR_BLZ_EXIST}++;
			return;
		}
		close BLZ;
	}
	unless ($CACHE_ON && $cache->{$blz}->{METHOD}) {
		if ($mode eq 'POST') {
			if (my ($D_BLZ, $D_INST, $D_PLZ, $D_ORT, $D_METHOD, $REST) = 
						$line =~ m/^(\d{8})(.{58})(\d{5})(.{30})(\d\d)(\d)/ ) {
				$D_INST =~ s/^\s+|\s+$//;
				$D_ORT =~ s/^\s+|\s+$//;
				@{$result}{qw(BLZ INST PLZ ORT METHOD REST)} =
					($D_BLZ, $D_INST, $D_PLZ, $D_ORT, $D_METHOD, $REST);
				$cache->{$blz}->{METHOD} = $D_METHOD if $CACHE_ON;
			}
			else {
				$self->{ERRORS}->{ERR_BLZ_FILE}++;
				return;
			}
		}
		elsif ($mode eq 'BANK') {
			chomp $line;
			my (
                $D_BLZ, $D_EIGEN, $D_INST, $D_PLZ, $D_ORT,
                $D_KURZ, $D_PAN, $D_BIC, $D_METHOD, $D_NUMBER
            ) = 
				unpack "A8A1A58A5A35A27A5A11A2A6", $line;
			if ($D_BLZ ne $blz) {
				#print "if ($D_BLZ ne $blz) {$blz = $D_BLZ};\n";
				$blz = $D_BLZ;
			}
			@$result{qw(BLZ INST PLZ ORT METHOD BIC)} =
					($blz, $D_INST, $D_PLZ, $D_ORT, $D_METHOD, $D_BIC);
			$cache->{$blz}->{METHOD} = $D_METHOD if $CACHE_ON;
		}
		elsif ($self->{MODE_BLZ_FILE} eq 'MINIMAL') {
			my $file = $self->{BLZFILE};
			$STORABLE ||= Storable::retrieve( $file);
			my $D_BLZ = $STORABLE->{$blz};
			unless ($D_BLZ) {
				$self->{ERRORS}->{ERR_BLZ_EXIST}++; # BUGFIX 2.10.2002
				return;
			}
			@$result{qw(BLZ METHOD )} =
					($blz, $STORABLE->{$blz});
		} 
	}
	else {
		# reading blz from cache...
		$result->{METHOD} = $cache->{$blz}->{METHOD};
		$result->{BLZ} = $blz;
	}
    if ($result) {
        $konto->_setValue(%$result);
        return $konto;
    }
	return $result;
}
############################
sub _quersumme {
	my $num = shift;
	return $num if length $num == 1;
	my $sum = 0;
    foreach (split //, $num) {$sum += $_}
	return $sum;
}
############################
sub _pruefe {
	no strict 'refs';
	my $self = shift;
	my $konto = shift;
	my $k = $konto->{KONTONR};
	my $m = $konto->{METHOD};
	my ($ziffer,$pruefziffer);
	#print Dumper $check_code->{$m};
	if (exists $check_code->{$m}) {
		my ($method,$mod,$array,$pz_stelle,$m_alias) = @{$check_code->{$m}};
		$pz_stelle--;
		my $sum = $self->_add($array, $k, {METHOD => $method});
		my $sub = "_m$m_alias";
			#print "methode $sub\n";
		if ($m == 13) {
			$k = sprintf "%010s",$k;
			$pruefziffer = substr(($k),7,1);
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			unless ($pruefziffer == $ziffer) {
				substr($k,0,2) = '';
				$k .= '00';
				$pruefziffer = substr($k,7,1);
				$sum = $self->_add($array, $k, {METHOD => $method});
				$ziffer = $sub->($self,$array,"$k",$sum,$mod);
			}
		}
		elsif ($m eq "15") {
			substr($k,0,5) = "00000";
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = $k % 10;
		}
		elsif ($m eq "14") {
			$k = sprintf "%010s",$k; # BUGFIX tina
			substr($k,0,3) = "000";
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = $k % 10;
		}
		elsif ($m eq "23") {
			substr($k,-3,3) = "";
			$pruefziffer = substr((sprintf "%010s",$k),7,1);
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = $k % 10;
		}
		elsif ($m eq "26") {
			$k = sprintf "%010s",$k;
			$k = substr($k,0,8). '00'  if $k =~ s/^00//; # Kris 2001/11/22
			$sum = $self->_add($array, $k, {METHOD => $method});
			#print "method $sub, knr: $k\n";
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,-3,1); # Kris 2001/11/22;
			#$pruefziffer = substr($k,-3,1); # Kris 2001/11/22;
			#print "$ziffer == $pruefziffer\n";
		}
		elsif ($m eq "27" && $k > 999999999) {
			$sub = "_m27";
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = $k % 10;
		}
		elsif ($m eq "28" || $m eq "34") {
			#$k = substr($k,0,8).'00';
			$k = sprintf "%010s",$k;
			$pruefziffer = substr($k,$pz_stelle,1); # Kris 2001/11/22;
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
		}
		elsif ($m eq "35") {
			$k = sprintf "%010s",$k;
			$pruefziffer = substr($k,$pz_stelle,1); # Kris 2001/11/22;
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$ziffer = $pruefziffer if substr($k,-2,1) eq substr($k,-2,1);
		}
		elsif ($m eq "41" && substr((sprintf "%010s",$k),3,1) == 9) {
			$k = sprintf "%010s",$k;
			$k =~ s/^.../000/;
			$pruefziffer = substr($k,$pz_stelle,1); # Kris 2001/11/22;
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
		}
		elsif ($m eq "45"
			&& (substr((sprintf "%010s",$k),0,1) == 0
			|| substr((sprintf "%010s",$k),4,1) == 1)
		) {
			$k = sprintf "%010s",$k;
			$pruefziffer = substr($k,$pz_stelle,1); # Kris 2001/11/22;
			$ziffer = $pruefziffer;
		}
		elsif ($m == 49) {
			# method 00, and if error, use method 01
			$k = sprintf "%010s",$k; #bugfix 12.09.02
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,$pz_stelle,1);
			#print "$ziffer == $pruefziffer? (m $mod)\n";
			unless ($ziffer == $pruefziffer) {
				my ($method,$mod,$array,$pz_stelle,$m_alias) = @{$check_code->{"01"}};
				$pz_stelle--;
				$sub = "_m01";
				$sum = $self->_add($array, $k, {METHOD => $method});
				$pruefziffer = substr($k,$pz_stelle,1);
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
				#print "$ziffer == $pruefziffer?\n";
			}
		}
		elsif ($m == 50) {
			$k = sprintf "%010s",$k; #bugfix 12.09.02
			# method 00, and if error, append "000" at the end
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,$pz_stelle,1);
			unless ($ziffer == $pruefziffer) {
				$k = sprintf "%010s",$k;
				$k .= "000";
				$k =~ s/...//;
				$sum = $self->_add($array, $k, {METHOD => $method});
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
			}
		}
		elsif ($m == 51) {
			$k = sprintf "%010s",$k;
			unless (substr($k,2,2) eq '99') {
#				print "no 99 $k\n";
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
				$pruefziffer = substr($k,$pz_stelle,1);
				# method 00, and if error, use method plan B (33)
				unless ($ziffer == $pruefziffer) {
					my ($method,$mod,$array,$pz_stelle,$m_alias) = @{$check_code->{$m}};
					$pz_stelle--;
					my $sum = $self->_add($array, $k, {METHOD => $method});
					my $sub = "_m$m_alias";
					#print "new test B ($k) $sub\n";
					$ziffer = $sub->($self,$array,$k,$sum,$mod);
				}
				# if error, use method plan C (33, but $sum / 7)
				unless ($ziffer == $pruefziffer) {
					my ($method,$mod,$array,$pz_stelle,$m_alias) = @{$check_code->{$m}};
					$pz_stelle--;
					$mod = 7;
					my $sum = $self->_add($array, $k, {METHOD => $method});
					my $sub = "_m$m_alias";
					#print "new test C ($k) $sub\n";
					$ziffer = $sub->($self,$array,$k,$sum,$mod);
				}
			}
			else {
				# number has '99' at substr 3 and 4 => method 10
				# this method sucks...
					#print "new test method 10\n";
					my ($method,$mod,$array,$pz_stelle,$m_alias) = @{$check_code->{10}};
					$pz_stelle--;
					my $sum = $self->_add($array, $k, {METHOD => $method});
					my $sub = "_m$m_alias";
					$pruefziffer = substr($k,$pz_stelle,1);
					$ziffer = $sub->($self,$array,$k,$sum,$mod);
			}
		}
		elsif ($m == 52 || $m == 53) {
			if ($k =~ m/^9\d{9}$/) {
				my ($method,$mod,$array,$pz_stelle,$m_alias) = @{$check_code->{20}};
				$pz_stelle--;
				my $sum = $self->_add($array, $k, {METHOD => $method});
				my $sub = "_m$m_alias";
				$pruefziffer = substr($k,$pz_stelle,1);
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
			}
			else {
				if ($m == 52) {
					my $blz = $konto->{BLZ};
					my ($s1) = $blz =~ m/^...5(.*)$/; # bugfix 12.09.02
					my $s2 = substr($k,0,2,'');
					$k =~ s/^0+//;
					$k = $s1.$s2.$k;
					$pruefziffer = substr($k,$pz_stelle,1,0);
					$k = sprintf "%012s",$k;
					#print "($k) p: $pruefziffer ($pz_stelle)\n";
					my $sum = $self->_add($array, $k, {METHOD => $method, M => $m});
					$ziffer = $sub->($self,$array,$k,$sum,$mod);
				}
				else {
					my $blz = $konto->{BLZ};
					$k =~ s/^0+//;
					#print "BLZ $blz, knr: $k\n";
					my ($s1) = $blz =~ m/^...5(.*)$/; # bugfix 12.09.02
					my $s2 = substr($k,0,3,'');
					my ($x,$t,$p) = split //,$s2;
					substr($s1,2,1) = $t;
					$s2 = $x.$p;
					$k = $s1.$s2.$k;
					#print "altkonto: $k\n";
					$pruefziffer = substr($k,$pz_stelle,1,0);
					$k = sprintf "%012s",$k;
					#print "($k) p: $pruefziffer ($pz_stelle)\n";
					my $sum = $self->_add($array, $k, {METHOD => $method, M => $m});
					$ziffer = $sub->($self,$array,$k,$sum,$mod);
					#print "$pruefziffer == $ziffer?\n";
				}
			}
		}
		elsif ($m == 56 && $k =~ m/^9\d{9}/) {
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$ziffer = 7 if $ziffer == 10;
			$ziffer = 8 if $ziffer == 11;

		}
		elsif ($m == 57) {
			$k = sprintf "%010s",$k;
			my $d = substr($k,0,2);
			if ($d <= 50 || $d == 91 ||
($d >=96 && $d <= 99) || $k=~m/^[78]{6}/) {
				my ($method,$mod,$array,$pz_stelle,$m_alias) = @{$check_code->{$m}};
				$pz_stelle--;
				my $sum = $self->_add($array, $k, {METHOD => $method});
				my $sub = "_m$m_alias";
				$pruefziffer = substr($k,$pz_stelle,1);
				$ziffer = $pruefziffer;
			}
			else {
				$pruefziffer = substr($k,$pz_stelle,1);
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
			}
		}
		elsif ($m == 59) {
			$pruefziffer = substr($k,$pz_stelle,1);
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$ziffer = $pruefziffer if length $k < 9;
		}
		elsif ($m == 61) {
			$k = sprintf "%010s",$k;
			$pruefziffer = substr($k,$pz_stelle,1);
			if (substr($k,8,1) == 8) {
				substr($k,7,1) = '';
				$k .= $pruefziffer;
			}
			else {
				substr($k,7,2) = '000';
			}
			my $sum = $self->_add($array, $k, {METHOD => $method, M => $m});
			$ziffer = 10 - $sum % 10;
			$ziffer = 0 if $ziffer == 10; #bugfix 12.09.02
		}
		elsif ($m == 63) {
			$k = sprintf "%010s",$k;
			if ($k =~ m/^000/) {$k =~ s/^00//;$k .= "00"}
			my $sum = $self->_add($array, $k, {METHOD => $method, M => $m});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,$pz_stelle,1);
		}
		elsif ($m == 65) {
			$k = sprintf "%010s",$k;
			unless (substr($k,8,1) eq '9') {
				$pruefziffer = substr($k,$pz_stelle,1);
				substr($k,7,2) = "00";
			}
			my $sum = $self->_add($array, $k, {METHOD => $method, M => $m});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
		}
		elsif ($m == 68) {
			if (length($k) == 10) {
				substr($k,0,3) = "000";
				#print "new k: $k\n";
				my $sum = $self->_add($array, $k, {METHOD => $method, M => $m});
				$pruefziffer = substr($k,$pz_stelle,1);
				#print "sum: $sum $pruefziffer\n";
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
			}
			elsif ($k >= 400000000 && $k <=499999999) {
				$ziffer = $pruefziffer = 1;
			}
			else {
				$k = sprintf "%010s",$k;
				my $sum = $self->_add($array, $k, {METHOD => $method, M => $m});
				$pruefziffer = substr($k,$pz_stelle,1);
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
				if ($ziffer != $pruefziffer) {
					substr($k,2,2) = "00";
					my $sum = $self->_add($array, $k, {METHOD => $method, M => $m});
					$ziffer = $sub->($self,$array,$k,$sum,$mod);
				}
			}
		}
		elsif ($m == 69) {
			$k = sprintf "%010s",$k;
			if ($k ge 9300000000 && $k lt 9400000000) {
				$sub = "_m06";
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
				$pruefziffer = substr($k,$pz_stelle,1);
			}
			elsif ($k ge 9700000000  && $k lt 9800000000) {
				$sub = "_m27";
				$pruefziffer = substr($k,$pz_stelle,1); # Kris 2001/11/22;
				$sum = $self->_add($array, $k, {METHOD => $method});
				$mod = 10;
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
			}
			else {
				$sub = "_m06";
				$pz_stelle = 8;
				$pz_stelle--;
				$pruefziffer = substr($k,$pz_stelle,1); # Kris 2001/11/22;
				$sum = $self->_add($array, $k, {METHOD => $method});
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
				unless ($ziffer == $pruefziffer) {
					$sub = "_m27";
					$pz_stelle = 9;
					$pruefziffer = substr($k,$pz_stelle,1); # Kris 2001/11/22;
					$mod = 10;
					$sum = $self->_add($array, $k, {METHOD => $method});
					$ziffer = $sub->($self,$array,$k,$sum,$mod);
				}
			}
		}
		elsif ($m == 70) {
			$k = sprintf "%010s",$k;
			$k =~ s/^.../000/ if (substr($k,3,1)==5) || substr($k,3,2) eq 69;
			$sum = $self->_add($array, $k, {METHOD => $method});
			$pruefziffer = substr($k,$pz_stelle,1);
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
		}
		elsif ($m == 73) {
			$k = sprintf "%010s",$k;
			if (substr($k,2,1)==9) {
				my ($method,$mod,$array,$pz_stelle,$m_alias) = @{$check_code->{"06"}};
				$pz_stelle--;
				my $sum = $self->_add($array, $k, {METHOD => $method});
				my $sub = "_m$m_alias";
				$pruefziffer = substr($k,$pz_stelle,1);
				$ziffer = $pruefziffer;
			}
			else {
				$k =~ s/^.../000/ if (substr($k,2,1)!=9);
				$sum = $self->_add($array, $k, {METHOD => $method});
				$pruefziffer = substr($k,$pz_stelle,1);
				$ziffer = $sub->($self,$array,$k,$sum,$mod);
			}
		}
		elsif ($m == 74) {
			$k = sprintf "%010s",$k;
			$sum = $self->_add($array, $k, {METHOD => $method});
			$pruefziffer = substr($k,$pz_stelle,1);
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			unless ($ziffer == $pruefziffer) {
				# nächste "halbdekade"
				$ziffer = 5- $sum % 5;
			}
		}
		else {
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$k = sprintf "%010s",$k;
			$pruefziffer = substr($k,$pz_stelle,1);
			#$pruefziffer = $k % 10;
		}
	#print "PRUEFZIFFER: $pruefziffer, $ziffer\n";
		return 0 unless defined $ziffer;
		$pruefziffer ||=0;
		return ($ziffer == $pruefziffer)? 1 : 0
	}
	else {
		#warn "Method $m not implemented yet\n";
		$konto->_setError("ERR_METHOD");
		return 0;
	}
}
############################
sub _add {
	my $self = shift;
	my ($array, $k, $args) = @_;
	$array = [reverse @$array];
	$k = sprintf "%010s",$k;
	my $sum;
	my $last_index = 9;
	#print Dumper $args;
	$args->{M}||=0;
	if ($args->{M} == 52 || $args->{M} == 53) { $last_index = 11 }
	#print "(0..$last_index)\n";
	for my $x (0..$last_index) {
		my $add = ($array->[$x]||0) * substr($k,$x,1);
		$add = _quersumme($add) if $args->{METHOD} eq "QUER";
		#print "$add = $array->[$x] * (substr($k,$x,1) ".substr($k,$x,1)."\n";
		$add = $add % 10 if $args->{METHOD} eq "ONES";
		$sum += $add;
	}
	return $sum;
}
############################
sub _summe {
	my $self = shift;
	my $sum;
	$sum += $_ for @_;
	return $sum;
}
############################
sub getMethod2BLZ {
    my ($self, $blz) = @_;
    my $konto = Business::DE::Konto->new();
	my $result = $self->get_info_for_blz($blz, $konto) or return;
	return $konto->get_method;
}
############################
# Modulus 10, Gewichtung 2, 1, 2, 1, 2, 1, 2, 1, 2
# Die Stellen der Kontonummer sind von rechts nach links mit
# den Ziffern 2, 1, 2, 1, 2 usw. zu multiplizieren. Die jeweiligen
# Produkte werden addiert, nachdem jeweils aus den
# zweistelligen Produkten die Quersumme gebildet wurde
# (z. B. Produkt 16 = Quersumme 7). Nach der Addition
# bleiben außer der Einerstelle alle anderen Stellen
# unberücksichtigt. Die Einerstelle wird von dem Wert 10
# subtrahiert. Das Ergebnis ist die Prüfziffer (10. Stelle der
# Kontonummer). Ergibt sich nach der Subtraktion der
# Rest 10, ist die Prüfziffer 0.
# Testkontonummern:9290701, 539290858, 1501824, 1501832
sub _m00 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $ziffer = $mod - $sum % 10;
	#print "$ziffer = $mod - $sum % 10\n";
	$ziffer = 0 if $ziffer == 10;
	return $ziffer;
}
############################
sub _m01 {
	my ($self,$array,$k,$sum,$mod)= @_;
	$sum = $sum % $mod;
	my $ziffer = $mod - $sum;
	return ($ziffer == 10)? 0 : $ziffer;
}
############################
sub _m02 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	return if ($rest == 1);
	return 0 if($rest == 0); # BUGFIX kristian
	return $mod - $rest;
}
############################
sub _m06 {
	my ($self,$array,$k,$sum,$mod)= @_;
	$k = sprintf "%010s", $k;
	my $rest = $sum % $mod;
	my $ziffer;
	if ($rest == 1) {$ziffer = 0}
	elsif ($rest == 0) {$ziffer = 0}
	else {
		$ziffer = $mod - $rest;
	}
#	print "$sum, z: $ziffer, mod: $mod\n";
	return $ziffer;
}
############################
sub _m08 {
	no strict 'refs';
	my ($self,$array,$k,$sum,$mod)= @_;
	return unless $k > 60000;
	my $method = "_m00"; # BUGFIX kristian
	$self->$method($array,$k,$sum,$mod);
}
############################
sub _m09 {
	my ($self,$array,$k,$sum,$mod)= @_;
	return $k % 10;
}
############################
sub _m11 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	my $ziffer;
	if ($rest == 1) {$ziffer = 9}
	elsif ($rest == 0) {$ziffer = 0} # BUGFIX kristian
	else {
		$ziffer = $mod - $rest;
	}
	return $ziffer;

}
############################
sub _m13 {
	my ($self,$array,$k,$sum,$mod)= @_;
	substr($k,0,1)=0;
	$sum = $sum % 10;
	my $ziffer = $mod - $sum;
	$ziffer = 0 if $ziffer == 10;
	return $ziffer;

}
############################
sub _m14 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	return if ($rest == 1);
	return 0 if($rest == 0); # BUGFIX kristian
	return $mod - $rest;
}
############################
sub _m16 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	my $ziffer;
	if ($rest == 1) {$ziffer = substr($k,-2,1);}
	elsif ($rest == 0) {$ziffer = 0}
	else {
		$ziffer = $mod - $rest;
	}
	return $ziffer;
}
############################
sub _m17 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my @k = (split //, (sprintf "%010s",$k))[1..7];
	my $pruef = pop @k;
	$sum = $k[0] + _quersumme($k[1]*2) +
						$k[2] + _quersumme($k[3]*2) +
						$k[4] + _quersumme($k[5]*2);
	$sum--;
	my $ziffer = $sum % $mod;
	if ($ziffer == 0) {
		$ziffer = 0;
	}
	else {
		$ziffer = 10 - $ziffer;
	}
	if($ziffer == $pruef){
		return $k % 10;
	}
	else{
		return undef;
	}
}
############################
sub _m21 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $ziffer = _quersumme $sum;
	while ($ziffer > 9) {
		$ziffer = _quersumme $ziffer;
	}
	$ziffer = $mod - $ziffer;
	return $ziffer;

}
############################
sub _m24 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $blz = $self->{BLZ};
	$k = sprintf "%010s", $k;
	if ($k =~ m/^[3456]/) {
		substr($k,0,1) = 0;
	}
	if (substr($k,0,1) == 9) {
		substr($k,0,3) = "000";
	}
	$k = $k + 0;
	my @k = split //,$k;
	my $pruef = pop @k;
	$sum = 0;
	my ($i) =0;
	for (@k) {
		$sum += (($k[$i] * $array->[$i]) + $array->[$i]) % $mod;
		$i++;
	}
	my $ziffer = $sum % 10;
	return $ziffer;
}
############################
sub _m25 {
	my ($self,$array,$k,$sum,$mod)= @_;
	$k = sprintf "%010s", $k;
	my $rest = $sum % $mod;
	my ($ziffer);
	if ($rest == 0) {
		$ziffer = 0;
	}
	elsif ($rest == 1) {
		$ziffer = 0;
		return undef unless (substr($k,1,1) =~ m/^[89]$/);
	}
	else {
		$ziffer = $mod - $rest;
	}
	return $ziffer;
}
############################
sub _m26 {
	my ($self,$array,$k,$sum,$mod)= @_;

}
############################
sub _m27 {
	#print "method 27\n";
	my ($self,$array,$k,$sum,$mod)= @_;
	my $ergebnis;
	my @trans = qw(1 4 3 2 1 4 3 2 1);
	my @zeilen = ([qw(0 1 5 9 3 7 4 8 2 6)],
								[qw(0 1 7 6 9 8 3 2 5 4)],
								[qw(0 1 8 4 6 2 9 5 7 3)],
								[qw(0 1 2 3 4 5 6 7 8 9)],
							);
	my @k = split //, $k;
	my $pruef = pop @k;
	for my $z (0..@k-1) {
		my $trans = $trans[$z] - 1;
		$ergebnis += $zeilen[$trans][$k[$z]];
		#print "$k[$z] => $zeilen[$trans][$k[$z]] ($ergebnis)\n";
	}
	$ergebnis %= 10;
	#print "10 - $ergebnis (mod: $mod)\n";
	my $ziffer = $mod - $ergebnis;
	$ziffer %= 10;
	return $ziffer;

}
sub _m31 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $ziffer = $sum % $mod;
	return if $ziffer == 10;
	return $ziffer;
}

sub _m35 {
	my ($self,$array,$k,$sum,$mod)= @_;
	$k = sprintf "%010s", $k;
	my $rest = $sum % $mod;
	my $ziffer = $rest;
	#print "$sum, z: $ziffer, mod: $mod\n";
	return $ziffer;
}
sub _m52 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $ix = 0;
	$ix++ while $k =~ s/^0//g;
	$ix += 5;
	$ix = 11-$ix;
	my $rest = $sum % $mod;
	#print "k: $k, sum: $sum, rest: $rest (ix: $ix)\n";
#	my ($method,$mod,$array,$pz_stelle,$m_alias) = @{$check_code->{$m}};
#	$pz_stelle--;
	my $gewicht = $array->[$ix];
	#print "gewicht $gewicht (@$array)\n";
	my $ziffer;
	for (0..11) {
		my $test = $rest + $_ * $gewicht;
		my $rest1 = $test % $mod;
		#print "($rest + $_ * $gewicht) % $mod = $rest1\n";
		$ziffer = $_, last if $rest1 == 10;
	}
	return $ziffer;
}
############################
1;
__END__

=head1 NAME

Business::DE::KontoCheck - Validating Bank-Account Numbers for Germany

=head1 IMPORTANT NOTE

I won't implement other methods and I won't update old ones.
This is too time consuming for me. Anyone who likes to do this,
please contact me.

This is just a release to note the above.

I might develop the interface to get the bank name for a bank number, though.

The included blz file is also not uptodate. The format of the file hash changed
since June 5th, 2006.

=head1 SYNOPSIS

    use Business::DE::KontoCheck;
    my $kcheck = Business::DE::KontoCheck->new(
        BLZFILE => "path/to/blzpc.txt",
    );
    my $konto = $kcheck->get_info_for_blz($blz);
    # $konto is a Business::DE::Konto
    my $bankname = $konto->get_bankname;

=head1 DESCRIPTION

  use Business::DE::KontoCheck;
  my $kcheck = Business::DE::KontoCheck->new(%hash);

  where %hash can have zero, one or more of the following entries:
  BLZFILE => '/path/to/BLZ.dat'
  MODE_BLZ_FILE => 'BANK' # either 'BANK', 'POST' or 'MINIMAL'

  e.g.:

  my $kcheck = Business::DE::KontoCheck->new(
    BLZFILE => '/path/to/BLZ.dat',
    MODE_BLZ_FILE => 'BANK',
  );
  If the BLZ-file is from POSTBANK, MODE_BLZ_FILE has to be 'POST'.
  If the file is from the BUNDESBANK, it'S 'BANK'.
  Set MODE_BLZ_FILE to 'MINIMAL' if you have a converted BLZ-file
  (see below at Section "CACHING, SPEED-UPS")

  my $konto = $kcheck->check(%hash);
  # where %hash can have zero, one or more of the following entries:
  # BLZ     => 12345678
  # KONTONR   => 1234567890
  # e.g.:
  my $konto = $kcheck->check(BLZ => 12345678, KONTONR => 1234567890);
  if (my $res = $konto->check(%hash)) {
    # BLZ/account-number is okay
  }
  elsif (!defined $res) {
    # account number is invalid
  }
  else {
    # there were some other errors
    $konto->printErrors();
  }

  check() returns 1 for success and 0 or undef for failure.
  If the input was okay but the account number is invalid it
  returns undef; in case of any other error it returns 0.
  So you should check
  In case of
  failure you can do $konto->printError() to see why it failed.
  Alternatively you can get errorcodes with:

--------------------------------------------
  my $errors = $konto->getErrors(); # reference to list of errors
  Here's the list of errors:

  ERR_NO_BLZ      => Please supply a BLZ'
  ERR_BLZ         => Please suplly a BLZ with 8 digits'
  ERR_BLZ_EXIST   => BLZ doesn't exist'
  ERR_BLZ_FILE    => BLZ-File corrupted'
  ERR_NO_KNR      => Please supply an account number'
  ERR_KNR         => Please supply a valid account number with only digits'
  ERR_KNR_INVALID => Account-number is invalid'
  ERR_METHOD      => Method not implemented yet'

--------------------------------------------

=head2 CACHING, SPEED-UPS

If this script is running as a daemon or within mod_perl it would
be rather slow because it has to read in the BLZ-file every time.
You can speed this up by either doing:

  $Business::DE::KontoCheck::CACHE_ON = 1; # DEFAULT is 1
  This caches a BLZ, so if this BLZ is asked for a second
  time the file doesn't have to be opened.

or

  $Business::DE::KontoCheck::CACHE_ALL = 1; # DEFAULT is 0
  This will read the whole BLZ-file at startup (when creating a
  new Business::DE::KontoCheck-Object) and will
  cache the method for every BLZ, so that the file will
  not be opened any more.
  The hash which holds the cached BLZs will have about
  5000 entries at the moment.

  So if you run this within mod_perl, for example, you can do
  at startup:
  use Business::DE::KontoCheck;
  $Business::DE::KontoCheck::CACHE_ALL = 1;
  my $kcheck = Business::DE::KontoCheck->new(
    BLZFILE => "path/to/blzpc.txt",
    MODE_BLZ_FILE => 'BANK'
  );
  
  and then make this $kcheck-Object available for the apache-childs
  and call:
  my $konto = $kcheck->check(BLZ=>$blz, KONTONR=>$kontonr);
  if (my $res = $konto->check()) {
   ...
  }

  You also have the possibility to make the BLZ-file much smaller
  (about 2% of the size) by using the tools/convert.pl script.
  Just call the script to get instructions.
  If you are using this file as BLZ-source, the MODE_BLZ_FILE
  has to be: 'MINIMAL'.
  my $kcheck = Business::DE::KontoCheck->new(
    BLZFILE => "path/to/blzpc_converted.txt",
    MODE_BLZ_FILE => 'MINIMAL',
  );
	Then you don't have to use one of the caching methods described
  above. This requires the Storable-Module.

=head2 METHODS

  Beside checking a BLZ/AccountNo. there are the following
  methods available:

=over 4

=item getMethod2BLZ (BLZ)

    Returns the Check-method for that BLZ.
    my $method = $kcheck->getMethod2BLZ($blz);
    Returns the method (element in "00".."A1").
    If the BLZ doesn't exist, it returns undef.

=item check

Creates a Business::DE::Konto object and checks if account number is valid.
This method should not be used as not all check methods are implemented.

=item C<new>

The Constructor.

=item get_info_for_blz

    my $kcheck = Business::DE::KontoCheck->new(
        BLZFILE => "path/to/blzpc.txt",
    );
    my $konto = $kcheck->get_info_for_blz($blz);
    my $bankname = $konto->get_bankname;

See L<Business::DE::Konto> for other methods.


=back

=head2 EXPORT

None by default. All methods are accessed over the object.

=head2 VERSION

Version 0.09

=head1 AUTHOR

Tina Mueller (see http://tinita.de/projects/perl/en)

=head1 SEE ALSO

perl(1)

=cut
