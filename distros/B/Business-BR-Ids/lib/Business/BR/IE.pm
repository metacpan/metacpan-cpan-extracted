
package Business::BR::IE;

use 5;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( canon_ie format_ie parse_ie random_ie );
our @EXPORT = qw( test_ie );

our $VERSION = '0.0022';
$VERSION = eval $VERSION;

use Business::BR::Ids::Common qw( _dot _dot_10 _canon_id );

### AC ###

# http://www.sintegra.gov.br/Cad_Estados/cad_AC.html

sub canon_ie_ac {
  return _canon_id(shift, size => 13);
}
sub test_ie_ac {
  my $ie = canon_ie_ac shift;
  return undef if length $ie != 13;
  return 0 unless $ie =~ /^01/;
  my @ie = split '', $ie;
  my $s1 = _dot([4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0], \@ie) % 11;
  unless ($s1==0 || $s1==1 && $ie[11]==0) {
    return 0;
  }
  my $s2 = _dot([5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2, 1], \@ie) % 11;
  return ($s2==0 || $s2==1 && $ie[12]==0) ? 1 : 0;

}
sub format_ie_ac {
  my $ie = canon_ie_ac shift;
  $ie =~ s|^(..)(...)(...)(...)(..).*|$1.$2.$3/$4-$5|; # 01.004.823/001-12
  return $ie;
}
sub _dv_ie_ac {
	my $base = shift; # expected to be canon'ed already ?!
	my $valid = @_ ? shift : 1;
	my $dev = $valid ? 0 : 2; # deviation (to make IE-PR invalid)
	my @base = split '', substr($base, 0, 11);
	my $dv1 = -_dot([4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2], \@base) % 11 % 10;
	my $dv2 = (-_dot([5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2], [ @base, $dv1 ]) + $dev) % 11 % 10;
	return ($dv1, $dv2) if wantarray;
	substr($base, 11, 2) = "$dv1$dv2";
	return $base;
}
sub random_ie_ac {
	my $valid = @_ ? shift : 1; # valid IE-SP by default
	my $base = sprintf "01%09s", int(rand(1E9)); # '01' and 9 digits
	return scalar _dv_ie_ac($base, $valid);
}
sub parse_ie_ac {
  my $ie = canon_ie_ac shift;
  my ($base, $dv) = $ie =~ /(\d{11})(\d{2})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { base => $base, dv => $dv };
}

### AL ###

# http://www.sefaz.al.gov.br/sintegra/cad_AL.asp
# http://www.sintegra.gov.br/Cad_Estados/cad_AL.html

my %AL_TYPES = (
  0 => "normal",
  1 => "normal",
  3 => "produtor rural",
  5 => "substituta",
  6 => "empresa pequeno porte",
  7 => "micro empresa ambulante",
  8 => "micro empresa",
  9 => "especial"
);
my @AL_TYPES = keys %AL_TYPES;

sub canon_ie_al {
  return _canon_id(shift, size => 9);
}
sub test_ie_al {
  my $ie = canon_ie_al shift;
  return undef if length $ie != 9;
  return 0 unless $ie =~ /^24/;
  my @ie = split '', $ie;
  return 0 unless $AL_TYPES{$ie[2]};
  my $s1 = _dot([90, 80, 70, 60, 50, 40, 30, 20, -1], \@ie) % 11;
  #print "ie: $ie, s1: $s1\n";
  return ($s1==0 || $s1==10 && $ie[8]==0) ? 1 : 0;

}
sub format_ie_al {
  my $ie = canon_ie_al shift;
  $ie =~ s|^(..)(...)(...)(.).*|$1.$2.$3-$4|; # 24.000.004-8
  return $ie;
}
sub _dv_ie_al {
	my $base = shift; # expected to be canon'ed already ?!
	my $valid = @_ ? shift : 1;
	my $dev = $valid ? 0 : 2; # deviation (to make IE-AL invalid)
	my @base = split '', $base;
	my $dv1 = (_dot([90, 80, 70, 60, 50, 40, 30, 20], \@base) + $dev) % 11 % 10;
	return ($dv1) if wantarray;
	substr($base, 8, 1) = $dv1;
	return $base;
}
sub random_ie_al {
	my $valid = @_ ? shift : 1; # valid IE-AL by default
	my $base = sprintf "24%1s%05s", 
		               $AL_TYPES[int(rand(@AL_TYPES))], 
		               int(rand(1E5)); # '24', type and 5 digits
	return scalar _dv_ie_al($base, $valid);
}
sub parse_ie_al {
  my $ie = canon_ie_al shift;
  my ($base, $dv) = $ie =~ /(\d{8})(\d{1})/;
  if (wantarray) {
    return ($base, $dv);
  }
  my $type = substr($ie, 2, 1);
  return { 
	  base => $base, 
	  dv => $dv, 
	  type => $type,
	  t_name => $AL_TYPES{$type}
	  
  };
}

### AP ###

#***

sub canon_ie_ap {
  return _canon_id(shift, size => 9);
}
sub test_ie_ap {
  my $ie = canon_ie_ap shift;
  return undef if length $ie != 9;
  return 0 unless $ie =~ /^03/;

  my $nr_empresa = substr($ie, 2, -1);
  my ($p, $d) = ($nr_empresa >= 1) && ($nr_empresa <= 17000) ? (5, 0) : # 1st class, 03.000.001-x up to 03.017.000-x
                ($nr_empresa >= 17001) && ($nr_empresa <= 19022) ? (9, 1) : # 2nd class, 03.017.001-x up to 03.019.022-x
                (0, 0); # 3rd class, from 03.019.023-x and on
#  print "(p, d) = ($p, $d)\n";

  my @ie = split '', $ie;
  my $sum = -($p + _dot([9, 8, 7, 6, 5, 4, 3, 2, 1], \@ie)) % 11; 

#  print "# ie: $ie, sum: $sum\n"; # ***
  return ($sum==0 || $sum==10 && $ie[8]==0) ? 1 : 0;

} # FIXME: this is not QUITE RIGHT !!!!!!!!!
sub format_ie_ap {
  my $ie = canon_ie_ap shift;
  $ie =~ s|^(..)(...)(...)(.).*|$1.$2.$3-$4|; # 03.012.245-9
  return $ie;
}
sub _dv_ie_ap {
  my $base = shift; # expected to be canon'ed already ?!
  my $valid = @_ ? shift : 1;
  my $dev = $valid ? 0 : 3; # deviation (to make IE-AP invalid)
  my @base = split '', $base;

  my $nr_empresa = substr($base, 2, -1);
  my ($p, $d) = ($nr_empresa >= 1) && ($nr_empresa <= 17000) ? (5, 0) : # 1st class, 03.000.001-x up to 03.017.000-x
                ($nr_empresa >= 17001) && ($nr_empresa <= 19022) ? (9, 1) : # 2nd class, 03.017.001-x up to 03.019.022-x
                (0, 0); # 3rd class, from 03.019.023-x and on

  my $dv1 = -($p + _dot([9, 8, 7, 6, 5, 4, 3, 2, 0], \@base) + $dev) % 11 % 10;
  return ($dv1) if wantarray;
  substr($base, 8, 1) = $dv1;
  return $base;
}
sub random_ie_ap {
  my $valid = @_ ? shift : 1; # valid IE-AP by default
  my $base = sprintf "03%06d*", 
                   int(rand(1E6)); # '03', 6 digits, dv
  return scalar _dv_ie_ap($base, $valid);
}
sub parse_ie_ap {
  my $ie = canon_ie_ap shift;
  my ($base, $dv) = $ie =~ /(\d{8})(\d{1})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { 
    base => $base, 
    dv => $dv, 
    range => '?'
  };

}



### AM ###

# http://www.sintegra.gov.br/Cad_Estados/cad_AM.html

sub canon_ie_am {
  return _canon_id( shift, size => 9 );
}
sub test_ie_am {
  my $ie = canon_ie_am(shift);
  return undef if length $ie != 9;

  my @ie = split '', $ie;
  my $s1 = _dot( [ 9, 8, 7, 6, 5, 4, 3, 2, 1 ], \@ie ) % 11;
  return ( $s1==0 || $s1==1 && $ie[8]==0 ) ? 1 : 0;
}
sub format_ie_am {
  my $ie = canon_ie_am(shift);
  $ie =~ s|^(..)(...)(...)(.).*|$1.$2.$3-$4|; # 11.111.111-0
  return $ie;
}
sub parse_ie_am {
  my $ie = canon_ie_am(shift);
  my ($base, $dv) = $ie =~ /(\d{8})(\d{1})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { 
    base => $base, 
    dv => $dv, 
  };
}
sub _dv_ie_am {
  my $base = shift; # expected to be canon'ed already ?!
  my $valid = @_ ? shift : 1;
  my $dev = $valid ? 0 : 2; # deviation (to make IE/AM invalid)
  my @base = split '', substr($base, 0, 8);
  my $dv1 = (-_dot([9, 8, 7, 6, 5, 4, 3, 2], \@base)+$dev) % 11 % 10;
  return ($dv1) if wantarray;
  substr($base, 8, 1) = $dv1;
  return $base;
}
sub random_ie_am {
  my $valid = @_ ? shift : 1; # valid IE-SP by default
  my $base = sprintf "%08s", int(rand(1E8)); # 8 digits # XXX IE/AM begins with '04'?
  return scalar _dv_ie_am($base, $valid);
}

### BA ###

# http://www.sintegra.gov.br/Cad_Estados/cad_BA.html

sub canon_ie_ba {
  return _canon_id(shift, size => 8);
}
sub test_ie_ba {
  my $ie = canon_ie_ba(shift);
  return undef if length $ie != 8;

  my @ie = split '', $ie;
  if ( $ie =~ /^[0123458]/ ) { # calculo pelo modulo 10

    my $s2 = _dot( [ 7, 6, 5, 4, 3, 2, undef, 1 ], \@ie ) % 10;
    unless ( $s2==0 ) {
      return 0;
    }
    my $s1 = _dot( [ 8, 7, 6, 5, 4, 3, 1, 2 ], \@ie ) % 10;
    return ( $s1==0 ) ? 1 : 0;

  } else { # $ie =~ /^[679]/ # calculo pelo modulo 11

    my $s2 = _dot( [ 7, 6, 5, 4, 3, 2, undef, 1 ], \@ie ) % 11;
    unless ( $s2==0 || $s2==1 && $ie[7]==0 ) {
      return 0;
    }
    my $s1 = _dot( [ 8, 7, 6, 5, 4, 3, 1, 2 ], \@ie ) % 11;
    return ( $s1==0 || $s1==1 && $ie[6]==0 ) ? 1 : 0;

  }
}
sub format_ie_ba {
  my $ie = canon_ie_ba(shift);
  $ie =~ s|^(......)(..).*|$1-$2|; # 123456-63
  return $ie;
}
sub parse_ie_ba {
  my $ie = canon_ie_ba(shift);
  my ($base, $dv) = $ie =~ /^(\d{6})(\d{2})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { 
    base => $base, 
    dv => $dv, 
  };
}
# ???
sub _dv_ie_ba {
  my $base = shift; # expected to be canon'ed already ?!
  my $valid = @_ ? shift : 1;
  my $dev = $valid ? 0 : 2; # deviation (to make IE/BA invalid)
  my @base = split '', substr($base, 0, 6);

  if ( $base =~ /^[0123458]/ ) { # calculo pelo modulo 10) 

    my $dv2 = -_dot( [ 7, 6, 5, 4, 3, 2 ], \@base) % 10;
    my $dv1 = (-_dot( [ 8, 7, 6, 5, 4, 3, 2 ], [ @base, $dv2 ])+$dev) % 10;
    return ($dv1, $dv2) if wantarray;
    substr($base, 6, 2) = "$dv1$dv2";
    return $base;

  } else { # =~ /^[679]/ # calculo pelo modulo 11

    my $dv2 = -_dot( [ 7, 6, 5, 4, 3, 2 ], \@base) % 11 % 10;
    my $dv1 = (-_dot( [ 8, 7, 6, 5, 4, 3, 2 ], [ @base, $dv2 ])+$dev) % 11 % 10;
    return ($dv1, $dv2) if wantarray;
    substr($base, 6, 2) = "$dv1$dv2";
    return $base;

  }
}
sub random_ie_ba {
  my $valid = @_ ? shift : 1; # valid IE/BA by default
  my $base = sprintf "%06s", int(rand(1E6)); # 6 digits
  return scalar _dv_ie_ba($base, $valid);
}


### CE ###

sub canon_ie_ce {
  return _canon_id(shift, size => 9);
}

### DF ###

sub canon_ie_df {
  return _canon_id(shift, size => 13);
}

### ES ###

sub canon_ie_es {
  return _canon_id(shift, size => 9);
}

### GO ###

sub canon_ie_go {
  return _canon_id(shift, size => 9);
}

### MA ###

# http://www.sintegra.gov.br/Cad_Estados/cad_MA.html

sub canon_ie_ma {
  return _canon_id(shift, size => 9);
}
sub test_ie_ma {
  my $ie = canon_ie_ma shift;
  return undef if length $ie != 9;
  return 0 unless $ie =~ /^12/;
  my @ie = split '', $ie;
  my $s1 = _dot([9, 8, 7, 6, 5, 4, 3, 2, 1], \@ie) % 11;
  return ($s1==0 || $s1==1 && $ie[8]==0) ? 1 : 0;

}
sub format_ie_ma {
  my $ie = canon_ie_ma shift;
  $ie =~ s|^(..)(...)(...)(.).*|$1.$2.$3-$4|; # 12.000.038-5
  return $ie;
}
sub _dv_ie_ma {
  my $base = shift; # expected to be canon'ed already ?!
  my $valid = @_ ? shift : 1;
  my $dev = $valid ? 0 : 2; # deviation (to make IE-MA invalid)
  my @base = split '', substr($base, 0, 8);
  my $dv1 = (-_dot([9, 8, 7, 6, 5, 4, 3, 2], \@base)+$dev) % 11 % 10;
  return ($dv1) if wantarray;
  substr($base, 8, 1) = $dv1;
  return $base;
}
sub random_ie_ma {
  my $valid = @_ ? shift : 1; # valid IE-SP by default
  my $base = sprintf "12%06s", int(rand(1E6)); # '12' and 6 digits
  return scalar _dv_ie_ma($base, $valid);
}
sub parse_ie_ma {
  my $ie = canon_ie_ma shift;
  my ($base, $dv) = $ie =~ /(\d{8})(\d{1})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { base => $base, dv => $dv };
}

### MT ###

sub canon_ie_mt {
  return _canon_id(shift, size => 11);
}

### MS ###

sub canon_ie_ms {
  return _canon_id(shift, size => 9);
}

### MG ###

# http://www.sintegra.gov.br/Cad_Estados/cad_MG.html

sub canon_ie_mg {
  return _canon_id( shift, size => 13 );
}

sub test_ie_mg {
  my $ie = canon_ie_mg( shift );
  return undef if length $ie != 13;
  my @ie = split '', $ie;

  my $c1 = - _dot_10( [1, 2, 1,  1, 2, 1, 2, 1, 2, 1, 2, undef, undef], \@ie ) % 10;
  unless ( $ie[11] eq $c1 ) {
    return 0;
  }

  my $s2 = _dot( [ 3, 2, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ], \@ie ) % 11;
  return ( $s2==0 || $s2==1 && $ie[12]==0 ) ? 1 : 0;
}

sub format_ie_mg {
  my $ie = canon_ie_mg shift;
  $ie =~ s|^(...)(...)(...)(..)(..).*|$1.$2.$3/$4$5|; # 062.307.904/0081
  return $ie;
}

sub parse_ie_mg {
  my $ie = canon_ie_mg shift;
  my ($municipio, $inscricao, $ordem, $dv) = $ie =~ /(\d{3})(\d{6})(\d{2})(\d{2})/;
  if (wantarray) {
    return ($municipio, $inscricao, $ordem, $dv);
  }
  return { 
    municipio => $municipio, 
    inscricao => $inscricao, 
    ordem     => $ordem, 
    dv        => $dv,
  };
}

sub _dv_ie_mg {
  my $base = shift; # expected to be canon'ed already ?!
  my $valid = @_ ? shift : 1;
  my $dev = $valid ? 0 : 2; # deviation (to make IE/MG invalid)
  my @base = split '', substr($base, 0, 11);
  my $dv1 = -_dot_10([ 1, 2, 1,  1, 2, 1, 2, 1, 2, 1, 2 ], \@base) % 10;
  my $dv2 = (-_dot([ 3, 2, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2 ], [ @base, $dv1 ]) + $dev) % 11 % 10;
  return ($dv1, $dv2) if wantarray;
  substr($base, 11, 2) = "$dv1$dv2";
  return $base;
}
sub random_ie_mg {
  my $valid = @_ ? shift : 1; # valid IE/MG by default
  my $base = sprintf "%011s", int(rand(1E11)); # 11 digits
  return scalar _dv_ie_mg($base, $valid);
}


### PA ###

sub canon_ie_pa {
  return _canon_id(shift, size => 9);
}

### PB ###

sub canon_ie_pb {
  return _canon_id(shift, size => 9);
}

### PR ###

#PR - http://www.fazenda.pr.gov.br/icms/calc_dgv.asp
#     Formato da Inscrição: NNN NNN NN-DD (10 dígitos)
#     Cálculo do Primeiro Dígito: Módulo 11 com pesos de 2 a 7, aplicados da direita para esquerda, sobre as 8 primeiras posições.
#     Cálculo do Segundo Dígito: Módulo 11 com pesos de 2 a 7, aplicados da direita para esquerda, sobre as 9 primeiras posições (inclui o primeiro dígito).
#     Exemplo: CAD 123.45678-50

#PR - http://www.sintegra.gov.br/Cad_Estados/cad_PR.html
#     Formato da Inscrição NNN.NNNNN-DD (1o dígitos) [ NNN NNN NN-DD ]
#     Exemplo: 123.45678-50


sub canon_ie_pr {
  return _canon_id(shift, size => 10);
}
sub test_ie_pr {
  my $ie = canon_ie_pr shift;
  return undef if length $ie != 10;
  my @ie = split '', $ie;
  my $s1 = _dot([3, 2, 7, 6, 5, 4, 3, 2, 1, 0], \@ie) % 11;
  my $s2 = _dot([4, 3, 2, 7, 6, 5, 4, 3, 2, 1], \@ie) % 11;
  unless ($s1==0 || $s1==1 && $ie[8]==0) {
    return 0;
  }
  return ($s2==0 || $s2==1 && $ie[9]==0) ? 1 : 0;

}
sub format_ie_pr {
  my $ie = canon_ie_pr shift;
  $ie =~ s|^(...)(.....)(..).*|$1.$2-$3|;
  return $ie;
}
sub _dv_ie_pr {
	my $base = shift; # expected to be canon'ed already ?!
	my $valid = @_ ? shift : 1;
	my $dev = $valid ? 0 : 2; # deviation (to make IE-PR invalid)
	my @base = split '', substr($base, 0, 8);
	my $dv1 = -_dot([3, 2, 7, 6, 5, 4, 3, 2], \@base) % 11 % 10;
	my $dv2 = (-_dot([4, 3, 2, 7, 6, 5, 4, 3, 2], [ @base, $dv1 ]) + $dev) % 11 % 10;
	return ($dv1, $dv2) if wantarray;
	substr($base, 8, 2) = "$dv1$dv2";
	return $base;
}
sub random_ie_pr {
	my $valid = @_ ? shift : 1; # valid IE-SP by default
	my $base = sprintf "%08s", int(rand(1E8)); # 8 dígitos
	return scalar _dv_ie_pr($base, $valid);
}
sub parse_ie_pr {
  my $ie = canon_ie_pr shift;
  my ($base, $dv) = $ie =~ /(\d{8})(\d{2})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { base => $base, dv => $dv };
}

### PE ###

sub canon_ie_pe {
  return _canon_id(shift, size => 14);
}

### PI ###

sub canon_ie_pi {
  return _canon_id(shift, size => 9);
}

### RJ ###

sub canon_ie_rj {
  return _canon_id(shift, size => 9);
}

### RN ###

sub canon_ie_rn {
  return _canon_id(shift, size => 9);
}

### RS ###

sub canon_ie_rs {
  return _canon_id(shift, size => 10);
}

### RO ###

# http://www.sintegra.gov.br/Cad_Estados/cad_RO.html

sub canon_ie_ro {
  return _canon_id(shift, size => 14);
}
sub test_ie_ro {
  my $ie = canon_ie_ro shift;
  return undef if length $ie != 14;
  my @ie = split '', $ie;
  my $s1 = _dot([6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2, 1], \@ie) % 11;
  return $s1==0 || $ie[13]==0 && $s1==1;
}
sub format_ie_ro {
  my $ie = canon_ie_ro shift;
  $ie =~ s|^(.............)(.).*|$1-$2|;
  return $ie;
}
sub _dv_ie_ro {
	my $base = shift; # expected to be canon'ed already ?!
	my $valid = @_ ? shift : 1;
	my $dev = $valid ? 0 : 2; # deviation (to make IE-RO invalid)
	my @base = split '', substr($base, 0, 13);
	my $dv = (-_dot([6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2], \@base)+$dev) % 11 % 10;
	return ($dv) if wantarray;
	substr($base, 13, 1) = $dv;
	return $base;
}
sub random_ie_ro {
	my $valid = @_ ? shift : 1; # valid IE-RO by default
	my $base = sprintf "%013s", int(rand(1E13)); # 13 dígitos   # devia ter maior probabilidade para 000 00000 AAAAA D
	return scalar _dv_ie_ro($base, $valid);
}
sub parse_ie_ro {
  my $ie = canon_ie_ro shift;
  my ($base, $dv) = $ie =~ /(\d{13})(\d{1})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { base => $base, dv => $dv };
}

### RR ###

# http://www.sintegra.gov.br/Cad_Estados/cad_RR.html

sub canon_ie_rr {
  return _canon_id(shift, size => 9);
}
sub test_ie_rr {
  my $ie = canon_ie_rr shift;
  return undef if length $ie != 9;
  return 0 unless $ie =~ /^24/;
  my @ie = split '', $ie;
  my $s1 = _dot([1, 2, 3, 4, 5, 6, 7, 8, -1], \@ie) % 9;
  return $s1==0 ? 1 : 0;

}
sub format_ie_rr {
  my $ie = canon_ie_rr shift;
  $ie =~ s|^(..)(...)(...)(.).*|$1.$2.$3-$4|; # 24.006.628-1
  return $ie;
}
sub _dv_ie_rr {
	my $base = shift; # expected to be canon'ed already ?!
	my $valid = @_ ? shift : 1;
	my $dev = $valid ? 0 : 2; # deviation (to make IE-PR invalid)
	my @base = split '', substr($base, 0, 8);
	my $dv1 = (_dot([1, 2, 3, 4, 5, 6, 7, 8], \@base)+$dev) % 9;
	return ($dv1) if wantarray;
	substr($base, 8, 1) = $dv1;
	return $base;
}
sub random_ie_rr {
	my $valid = @_ ? shift : 1; # valid IE-SP by default
	my $base = sprintf "24%06s", int(rand(1E6)); # '24' and 6 digits
	return scalar _dv_ie_rr($base, $valid);
}
sub parse_ie_rr {
  my $ie = canon_ie_rr shift;
  my ($base, $dv) = $ie =~ /(\d{8})(\d{1})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { base => $base, dv => $dv };
}

### SC ###

sub canon_ie_sc {
  return _canon_id(shift, size => 9);
}

### SP ###

sub canon_ie_sp {
  return _canon_id(shift, size => 12);
}   

#SP - http://www.csharpbr.com.br/arquivos/csharp_mostra_materias.asp?escolha=0021
#     Exemplo: Inscrição Estadual 110.042.490.114
#     12 dígitos, 9o. e 12o. são DVs
#     dv[1] = (1, 3, 4, 5, 6, 7, 8, 10) .* (c[1] c[2] c[3] c[4] c[5] c[6] c[7] c[8]) (mod 11)
#     dv[2] = (3 2 10 9 8 7 6 5 4 3 2 1) .* (c[1] ... c[11]) (mod 11)

sub test_ie_sp {
	my $ie = canon_ie_sp shift;
	return undef if length $ie != 12;
	my @ie = split '', $ie;
	my $s1 = _dot([1, 3, 4, 5, 6, 7, 8, 10, -1, 0, 0, 0], \@ie) % 11;
	unless ($s1==0 || $s1==10 && $ie[8]==0) {
	  return 0;
	}
	my $s2 = _dot([3, 2, 10, 9, 8, 7, 6, 5, 4, 3, 2, -1], \@ie) % 11;
	return ($s2==0 || $s2==10 && $ie[11]==0) ? 1 : 0;

}

sub format_ie_sp {
  my $ie = canon_ie_sp shift;
  $ie =~ s|^(...)(...)(...)(...).*|$1.$2.$3.$4|;
  return $ie;
}

# my ($dv1, $dv2) = _dv_ie_sp('') # => $dv1 = ?, $dv2 = ?
# my ($dv1, $dv2) = _dv_ie_sp('', 0) # computes non-valid check digits
#
# computes the check digits of the candidate IE-SP number given as argument
# (only the first 12 digits enter the computation) (9th and 12nd are ignored)
#
# In list context, it returns the check digits.
# In scalar context, it returns the complete IE-SP (base and check digits)
sub _dv_ie_sp {
	my $base = shift; # expected to be canon'ed already ?!
	my $valid = @_ ? shift : 1;
	my $dev = $valid ? 0 : 2; # deviation (to make IE-SP invalid)
	my @base = split '', substr($base, 0, 12);
	my $dv1 = _dot([1, 3, 4, 5, 6, 7, 8, 10, 0, 0, 0, 0], \@base) % 11 % 10;
	my $dv2 = (_dot([3, 2, 10, 9, 8, 7, 6, 5, 0, 3, 2, 0], \@base) + 4*$dv1 + $dev) % 11 % 10;
	return ($dv1, $dv2) if wantarray;
	substr($base, 8, 1) = $dv1;
	substr($base, 11, 1) = $dv2;
	return $base
}

# generates a random (correct or incorrect) IE-SP
# $ie = rand_ie_sp();
# $ie = rand_ie_sp($valid);
#
# if $valid==0, produces an invalid IE-SP
sub random_ie_sp {
	my $valid = @_ ? shift : 1; # correct IE-SP by default
	my $ie = sprintf "%08s0%02s0", int(rand(1E8)), int(rand(1E2)); # 10 dígitos aleatórios
	return scalar _dv_ie_sp($ie, $valid);
}

sub parse_ie_sp {
  my $ie = canon_ie_sp shift;
  my ($base, $dv) = $ie =~ /(\d{8})(\d{2})/;
  if (wantarray) {
    return ($base, $dv);
  }
  return { base => $base, dv => $dv };
}

### SE ###

sub canon_ie_se {
  return _canon_id(shift, size => 9);
}

### TO ###

sub canon_ie_to {
  return _canon_id(shift, size => 11);
}

# a dispatch table is used here, because we know beforehand 
# the list of Brazilian states. I am not sure it is
# better than using symbolic references.

my %dispatch_table = (
  # AC
  test_ie_ac => \&test_ie_ac, 
  canon_ie_ac => \&canon_ie_ac, 
  format_ie_ac => \&format_ie_ac,
  random_ie_ac => \&random_ie_ac,
  parse_ie_ac => \&parse_ie_ac,

  # AL
  test_ie_al => \&test_ie_al, 
  canon_ie_al => \&canon_ie_al, 
  format_ie_al => \&format_ie_al,
  random_ie_al => \&random_ie_al,
  parse_ie_al => \&parse_ie_al,

  # AM
  test_ie_am => \&test_ie_am, 
  canon_ie_am => \&canon_ie_am, 
  format_ie_am => \&format_ie_am, 
  random_ie_am => \&random_ie_am, 
  parse_ie_am => \&parse_ie_am, 

  # AP
  test_ie_ap => \&test_ie_ap, 
  canon_ie_ap => \&canon_ie_ap, 
  format_ie_ap => \&format_ie_ap,
  random_ie_ap => \&random_ie_ap,
  parse_ie_ap => \&parse_ie_ap,

  # BA
  test_ie_ba => \&test_ie_ba, 
  canon_ie_ba => \&canon_ie_ba, 
  format_ie_ba => \&format_ie_ba,
  random_ie_ba => \&random_ie_ba,
  parse_ie_ba => \&parse_ie_ba,

  # CE
  canon_ie_ce => \&canon_ie_ce, 

  # DF
  canon_ie_df => \&canon_ie_df, 

  # ES
  canon_ie_es => \&canon_ie_es, 

  # GO
  canon_ie_go => \&canon_ie_go, 

  # MA
  test_ie_ma => \&test_ie_ma, 
  canon_ie_ma => \&canon_ie_ma, 
  format_ie_ma => \&format_ie_ma,
  random_ie_ma => \&random_ie_ma,
  parse_ie_ma => \&parse_ie_ma,

  # MG
  test_ie_mg => \&test_ie_mg, 
  canon_ie_mg => \&canon_ie_mg, 
  format_ie_mg => \&format_ie_mg,
  random_ie_mg => \&random_ie_mg,
  parse_ie_mg => \&parse_ie_mg,

  # MT
  canon_ie_mt => \&canon_ie_mt, 

  # MS
  canon_ie_ms => \&canon_ie_ms, 

  # PE
  canon_ie_pe => \&canon_ie_pe, 

  # PA
  canon_ie_pa => \&canon_ie_pa, 

  # PB 
  canon_ie_pb => \&canon_ie_pb, 

  # PI
  canon_ie_pi => \&canon_ie_pi, 

  # PR
  test_ie_pr => \&test_ie_pr, 
  canon_ie_pr => \&canon_ie_pr, 
  format_ie_pr => \&format_ie_pr,
  random_ie_pr => \&random_ie_pr,
  parse_ie_pr => \&parse_ie_pr,

  # RJ
  canon_ie_rj => \&canon_ie_rj, 

  # RN
  canon_ie_rn => \&canon_ie_rn, 

  # RO
  test_ie_ro => \&test_ie_ro, 
  canon_ie_ro => \&canon_ie_ro, 
  format_ie_ro => \&format_ie_ro,
  random_ie_ro => \&random_ie_ro,
  parse_ie_ro => \&parse_ie_ro,
  # RR
  test_ie_rr => \&test_ie_rr, 
  canon_ie_rr => \&canon_ie_rr, 
  format_ie_rr => \&format_ie_rr,
  random_ie_rr => \&random_ie_rr,
  parse_ie_rr => \&parse_ie_rr,
  # RS
  canon_ie_rs => \&canon_ie_rs, 
  # SC
  canon_ie_sc => \&canon_ie_sc, 
  # SE
  canon_ie_se => \&canon_ie_se, 
  # SP
  test_ie_sp => \&test_ie_sp, 
  canon_ie_sp => \&canon_ie_sp, 
  format_ie_sp => \&format_ie_sp,
  random_ie_sp => \&random_ie_sp,
  #parse_ie_sp
  # TO
  canon_ie_to => \&canon_ie_to, 

);

sub _invoke {
	my $subname = shift;
	my $sub = $dispatch_table{$subname};
    die "$subname not implemented" unless $sub;
	return &$sub(@_);
}

sub test_ie {
	my $uf = lc shift;
	return _invoke("test_ie_$uf", @_);
}
sub canon_ie {
	my $uf = lc shift;
	return _invoke("canon_ie_$uf", @_);
}
sub format_ie {
	my $uf = lc shift;
	return _invoke("format_ie_$uf", @_);
}
sub random_ie {
	my $uf = lc shift;
	return _invoke("random_ie_$uf", @_);
}

sub parse_ie {
	my $uf = lc shift;
	return _invoke("parse_ie_$uf", @_);
}



1;

__END__

=head1 NAME

Business::BR::IE - Perl module to test for correct IE numbers

=head1 SYNOPSIS

  use Business::BR::IE qw(test_ie canon_ie format_ie random_ie); 

  test_ie('sp', '110.042.490.114') # 1
  test_ie('pr', '123.45678-50') # 1
  test_ie('ac', '01.004.823/001-12') # 1
  test_ie('al', '24.000.004-8') # 1
  test_ie('am', '04.117.161-6') # 1
  test_ie('ba', '123456-63') # 1
  test_ie('ma', '12.000.038-5') # 1
  test_ie('mg', '062.307.904/0081') #1
  test_ie('rr', '24.006.628-1') # 1
  test_ie('ap', '03.012.345-9') # 1

=head1 DESCRIPTION

YET TO COME. Handles IE for the states of 
Acre (AC), Alagoas (AL), Amapá (AP), Amazonas (AM),
Bahia (BA), Maranhão (MA), Minas Gerais (MG), Paraná (PR), 
Rondônia (RO), Roraima (RR) and Sao Paulo (SP) by now.

=head2 EXPORT

C<test_ie> is exported by default. C<canon_ie>, C<format_ie>,
C<random_ie> and C<parse_ie> can be exported on demand.

=head1 DETAILS

Each state has its own rules for IE numbers. In this section,
we gloss over each one of these

=head2 AC

The state of Acre uses:

=over 4

=item *

13-digits number

=item *

the last two are check digits

=item *

the usual formatting is like C<'01.004.823/001-12'>

=item *

if the IE-AC number is decomposed into digits like this

  a_1 a_2 a_3 a_4 a_5 a_6 a_7 a_8 a_9 a_10 a_11 d_1 d_2

it is correct if

  a_1 a_2 = 0 1

(that is, it always begin with "01") and if it satisfies
the check equations:

  4 a_1 + 3 a_2 + 2 a_3 + 9 a_4  + 8 a_5  + 7 a_6 + 6 a_7 +
                  5 a_8 + 4 a_9 + 3 a_10 + 2 a_11 +   d_1   = 0 (mod 11) or
                                                            = 1 (mod 11) (if d_1 = 0)

  5 a_1 + 4 a_2 + 3 a_3 + 2 a_4  + 9 a_5  + 8 a_6 + 7 a_7 +
          6 a_8 + 5 a_9 + 4 a_10 + 3 a_11 + 2 d_1 +   d_2  = 0 (mod 11) or
                                                           = 1 (mod 11) (if d_2 = 0)

=back

=head2 AL

The state of Alagoas uses:

=over 4

=item *

9-digits number

=item *

the last one is a check digit

=item *

the usual formatting is like C<'24.000.004-8'>

=item *

if the IE-AL number is decomposed into digits like this

  a_1 a_2 a_3 a_4 a_5 a_6 a_7 a_8 d_1 

it is correct if it always begin with "24" (the code for the 
state of Alagoas),

  a_1 a_2 = 2 4

if the following digit identifies a valid company type

  0 - "normal"
  1 - "normal"
  3 - "produtor rural"
  5 - "substituta"
  6 - "empresa pequeno porte"
  7 - "micro empresa ambulante"
  8 - "micro empresa"
  9 - "especial"

and if it satisfies the check equation:

  ( 9 a_1 + 2 a_2 + 3 a_3 + 4 a_4 + 5 a_5
                    6 a_6 + 7 a_7 + 8 a_8 ) * 10 - d_1 = 0  (mod 11) or
                                                       = 10 (mod 11) (if d_1 = 0)

=back

=head2 AM

The state of Amazonas uses:

=over 4

=item *

9-digits number

=item *

the last one is a check digit

=item *

the usual formatting is like C<'11.111.111-0'>

=item *

if the IE-AM number is decomposed into digits like this

  a_1 a_2 a_3 a_4 a_5 a_6 a_7 a_8 d_1 

it is correct if it satisfies the check equation:

  9 a_1 + 8 a_2 + 7 a_3 + 6 a_4 + 5 a_5
                    4 a_6 + 3 a_7 + 2 a_8   + d_1 = 0  (mod 11) or
                                                  = 1  (mod 11) (if d_1 = 0)

=back

=head2 BA

The state of Bahia uses:

=over 4

=item *

8-digits number

=item *

the last two are check digits

=item *

the usual formatting is like C<'123456-63'>

=back

=head2 MA

The state of Maranhão uses:

=over 4

=item *

9-digits number

=item *

the 9th is a check digit

=item *

the usual formatting is like C<'12.000.038-5'>

=item *

if the IE-MA number is decomposed into digits like this

  a_1 a_2 a_3 a_4 a_5 a_6 a_7 a_8 d_1 

it is correct if it always begin with "12" (the code for the 
state of Maranhão),

  a_1 a_2 = 1 2

and if it satisfies the check equation:

  ( 9 a_1 + 8 a_2 + 7 a_3 + 6 a_4 + 5 a_5
                    4 a_6 + 3 a_7 + 2 a_8 ) - d_1 = 0  (mod 11) or
                                                  = 10 (mod 11) (if d_1 = 0)

=back

=head2 MG

The state of Minas Gerais uses:

=over 4

=item *

13-digits number

=item *

the 11th and 12th are check digits

=item *

the usual formatting is like C<'062.307.904/0081'>

=item *

to determine if IE/MG number is correct, the computation rules in

  http://www.sintegra.gov.br/Cad_Estados/cad_MG.html

must be followed. (Yes, they are boring and hard to describe.)

=back

=head2 PR

The state of Paraná uses:

=over 4

=item *

10-digits number

=item *

the 9th and 10th are check digits

=item *

the usual formatting is like C<'123.45678-50'>

=back

=head2 RO

The state of Rondônia uses:

=over 4

=item *

14-digits number

=item *

the 14th is a check digit

=item *

the usual formatting is like C<'0000000062521-3'>

=item *

if the IE-RO number is decomposed into digits like this

  a_1 a_2 a_3 a_4 a_5 a_6 a_7 a_8 a_9 a_10 a_11 a_12 a_13 d_1 

it is correct if it satisfies the check equation:

  ( 6 a_1 + 5 a_2 + 4 a_3 + 3 a_4 + 2 a_5 +
    9 a_6 + 8 a_7 + 7 a_8 + 6 a_9 + 5 a_10 +
    4 a_11 + 3 a_12 + 2 a_13 + d_1            = 0  (mod 11) or
                                              = 1  (mod 11) if d_1 = 0

=back

=head2 RR

The state of Roraima uses:

=over 4

=item *

9-digits number

=item *

the 9th is a check digit

=item *

the usual formatting is like C<'24.006.628-1'>

=item *

if the IE-RR number is decomposed into digits like this

  a_1 a_2 a_3 a_4 a_5 a_6 a_7 a_8 d_1 

it is correct if it always begin with "24" (the code for the 
state of Roraima),

  a_1 a_2 = 2 4

and if it satisfies the check equation:

  ( 1 a_1 + 2 a_2 + 3 a_3 + 4 a_4 + 5 a_5
                    6 a_6 + 7 a_7 + 8 a_8 ) - d_1 = 0  (mod 9)

=back

=head2 SP

The state of São Paulo uses:

=over 4

=item *

12-digits number

=item *

the 9th and 12nd are check digits

=item *

the usual formatting is like C<'110.042.490.114'>

=back



=head1 BUGS

=over 4

=item *

This documentation is faulty

=item *

If you want handling more than AC, AL, AM, MA, MG, PR, RO, RO and SP, you'll
have to wait for the next releases

=item *

The handling of IE-SP does not include yet the special rule for 
testing correctness of registrations of rural producers.

=item *

the case of unfair digits must be handled satisfactorily
(in this and other Business::BR::Ids modules)

=back

=head1 SEE ALSO

Please reports bugs via CPAN RT, 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-BR-Ids
By doing so, the author will receive your reports and patches, 
as well as the problem and solutions will be documented.

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by A. R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
