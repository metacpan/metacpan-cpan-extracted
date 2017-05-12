package Bio::PDB::Structure::Atom;

use Math::Trig;

#define an atom object containing all the fields of a pdb file
    sub new
        {
        my $self = {};
        $self->{TYPE} = undef;
        $self->{NUMBER} = undef;
        $self->{NAME} = undef;
        $self->{RESIDUE_NAME} = undef;
        $self->{CHAIN} = undef;
        $self->{RESIDUE_NUMBER} = undef;
        $self->{X} = undef;
        $self->{Y} = undef;
        $self->{Z} = undef;
        $self->{OCCUPANCY} = undef;
        $self->{BETA} = undef;
        $self->{ALT} = undef;
        $self->{INSERTION_CODE} = undef;
        bless($self);
        return $self;
        }

#accesor methods for atom objects
    sub type
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{TYPE} = $val;
            return;
            }
        return $self->{TYPE};
        }

    sub number
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{NUMBER} = $val;
            return;
            }
        return $self->{NUMBER};
        }

    sub name
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{NAME} = $val;
            return;
            }
        return $self->{NAME};
        }

    sub chain
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{CHAIN} = $val;
            return;
            }
        return $self->{CHAIN};
        }

    sub residue_number
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{RESIDUE_NUMBER} = $val;
            return;
            }
        return $self->{RESIDUE_NUMBER};
        }

    sub residue_name
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{RESIDUE_NAME} = $val;
            return;
            }
        return $self->{RESIDUE_NAME};
        }

    sub x
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{X} = $val;
            return;
            }
        return $self->{X};
        }

    sub y
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{Y} = $val;
            return;
            }
        return $self->{Y};
        }

    sub z
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{Z} = $val;
            return;
            }
        return $self->{Z};
        }

    sub occupancy
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{OCCUPANCY} = $val;
            return;
            }
        return $self->{OCCUPANCY};
        }

    sub beta
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{BETA} = $val;
            return;
            }
        return $self->{BETA};
        }

    sub alt
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{ALT} = $val;
            return;
            }
        return $self->{ALT};
        }

    sub insertion_code
        {
        my $self= shift;
        if (@_)
            {
            my $val = shift;
            $self->{INSERTION_CODE} = $val;
            return;
            }
        return $self->{INSERTION_CODE};
        }

#compute usefull stuff for atom objects
    sub distance
        {
        shift;
        my $n = @_;
        die "Error in distance calculation: need two atoms as argument" if ($n != 2);
        my $obj1 = shift;
        my $obj2 = shift;
        my $dist = ($obj1 -> x - $obj2 ->x )**2;
        $dist += ($obj1 ->y - $obj2 ->y )**2;
        $dist += ($obj1 -> z - $obj2 ->z )**2;
        $dist = sqrt($dist);
        return $dist;
        }

    #given three atoms a1-a2-a3 , compute the angle betwen bonds a1-a2 and a2-a3
    sub angle
        {
        shift;
        my $n = @_;
        die "Error in angle calculation: need three atoms as argument" if ($n != 3);
        my $obj1 = shift;
        my $obj2 = shift;
        my $obj3 = shift;
        my $d1 = $obj1->distance($obj1,$obj2); #so the class is not hard coded
        my $d2 = $obj1->distance($obj2,$obj3);
        my $dx1 = ($obj1 -> x - $obj2 ->x)/$d1;
        my $dy1 = ($obj1 -> y - $obj2 ->y)/$d1;
        my $dz1 = ($obj1 -> z - $obj2 ->z)/$d1;
        my $dx2 = ($obj3 -> x - $obj2 ->x)/$d2;
        my $dy2 = ($obj3 -> y - $obj2 ->y)/$d2;
        my $dz2 = ($obj3 -> z - $obj2 ->z)/$d2;   
        my $dot = $dx1*$dx2 + $dy1*$dy2 + $dz1*$dz2;
        return 180.0/pi * acos( $dot ); 
        }

    #given four atoms a1-a2-a3-a4, compute the dihedral that lies between a2 and a3
    sub dihedral
        {
        shift;
        my $n = @_;
        die "Error in dihedral calculation: need four atoms as argument" if ($n != 4);
        my @object;
        for (my $i=0; $i <4; $i++)
            {
            $object[$i] = shift;
            }
        my @v;
        for (my $j=0; $j < 4; $j++)
            {
            $v[0][$j] = $object[$j] ->x; 
            $v[1][$j] = $object[$j] ->y;
            $v[2][$j] = $object[$j] ->z;
            }
        my @b;
        for(my $i=0;$i<3;$i++)
            {
            $b[$i][0] = $v[$i][0] - $v[$i][1];
            $b[$i][1] = $v[$i][2] - $v[$i][1];
            $b[$i][2] = $v[$i][3] - $v[$i][2];
            } 
        my @t1;
        my @t2;
        #cross product b[][1] x b[][0]
        $t1[0] =$b[1][1]*$b[2][0] - $b[2][1]*$b[1][0];
        $t1[1] =$b[2][1]*$b[0][0] - $b[0][1]*$b[2][0];
        $t1[2] =$b[0][1]*$b[1][0] - $b[1][1]*$b[0][0];
        #cross product b[][1] x b[][2]
        $t2[0] =$b[1][1]*$b[2][2] - $b[2][1]*$b[1][2];
        $t2[1] =$b[2][1]*$b[0][2] - $b[0][1]*$b[2][2];
        $t2[2] =$b[0][1]*$b[1][2] - $b[1][1]*$b[0][2];
        my $norm1 = sqrt($t1[0]**2 + $t1[1]**2 + $t1[2]**2);
        my $norm2 = sqrt($t2[0]**2 + $t2[1]**2 + $t2[2]**2);
        my $dot1=0;
        my $dot2=0;
        for (my $i=0; $i < 3; $i++)
            {
            $t1[$i] /= $norm1;
            $t2[$i] /= $norm2;
            $dot1 += $t1[$i] * $t2[$i];
            $dot2 += $b[$i][2] * $t1[$i];
            }
        my $dihedral = 180.0/pi * acos($dot1);
        $dihedral *= -1.0 if ( $dot2 < 0.0);
        return $dihedral;
        }



package Bio::PDB::Structure::Molecule;

use 5.012003;
use strict;
use warnings;

our $VERSION = '0.01';

sub new
    {
    my $self = [];
    bless ($self);
    return $self;
    }
#count the number of atoms in a molecule object
sub size
    {
    my $self= shift;
    my $n = @{ $self };
    return $n; 
    }

#return the ith atom
sub atom
    {
    my $self = shift;
    my $n = @_;
    die "Error in atom: need one atom position\n" unless ($n == 1);
    my $pos = shift;
    return $self ->[$pos];
    }

#add an atom or a molecule to a molecule
sub push
    {
    my $self = shift;
    my $n = @_;
    die "Eror in push: need  one atom or molecule\n" unless ( $n == 1);
    my $object = shift;
    push (@{$self},$object) if (ref($object) eq "Bio::PDB::Structure::Atom");
    if ( ref($object) eq "Bio::PDB::Structure::Molecule")
        {
        my $nm = $object -> size;
        for (my $i=0; $i < $nm; $i++)
            {
            push (@{$self},$object->[$i]);
            }
        }
    return;
    }

#return number of models in a pdb file
sub models
    {
    shift;
    my $fname = shift;
    open(CMDFPDB,"<$fname") or die "Error in models: File $fname not found\n";
    my $count = 0;
    while (<CMDFPDB>)
        {
        $count++ if (/^END/);
        }
    close CMDFPDB;
    return $count;
    }

#read a pdb file into a molecule, can specify a specific model to read
sub read
    {
    my $type;
    my $anum;
    my $aname;
    my $altloc;
    my $rname;
    my $chain;
    my $rnum;
    my $icode;
    my $xx;
    my $yy;
    my $zz;
    my $coor;
    my $beta;
    my @data;
    my $inum = 0;
    my $record = 0;
    my $self = shift;
    die "Error in read: pdb file must be specified\n" unless (@_);
    my $fname = shift;
    $record = shift if ( @_ );
    open(FPDB,"<$fname") or die "File $fname not found\n";
    if ( $record > 0 )
        {
        my $rcount=1;
        while (<FPDB>)
            {
            if (/^END/)
                {
                last if ( $rcount == $record);
                $rcount++;
                }
            }
        } 
    while(<FPDB>)
        {
        last if (/^END/);
        next unless (/^ATOM |^HETATM / );
        my $atom = Bio::PDB::Structure::Atom -> new;
        ($type,$anum,$aname,$altloc,$rname,$chain,$rnum,$icode,$xx,$yy,$zz,$coor,$beta ) =(/^(.{6})(.{5})(.{5})(.{1})(.{3})(.{2})(.{4})(.{1}).{3}(.{8})(.{8})(.{8})(.{0,6})(.{0,6})/);
        #take out unecessary spaces
        $type =~ s/^\s*(\S+)\s*$/$1/;
        $anum =~ s/^\s*(\S+)\s*$/$1/;
        $aname =~s/^\s*(\S*\s*\S)\s*$/$1/;
        $chain =~s/^\s*(\S*)\s*$/$1/;
        $chain = " " if ($chain eq "");
        $rname =~s/^\s*(\S+)\s*$/$1/;
        $rnum =~s/^\s*(\S+)\s*$/$1/;
        $coor =~s/^\s*(\S+)\s*$/$1/;
        $coor = 1.00 unless ( $coor =~ /\d/);      
        $beta =~s/^\s*(\S+)\s*$/$1/;
        $beta = 0.00 unless ( $beta =~ /\d/);
        
        $atom -> type($type);
        $atom -> number($anum);
        $atom -> name($aname);
        $atom -> residue_name($rname);
        $atom -> chain($chain);
        $atom -> residue_number($rnum);
        $atom ->x($xx);
        $atom ->y($yy);
        $atom ->z($zz);
        $atom -> occupancy($coor);
        $atom -> beta($beta);
        #since alterate location and insertion code are seldomly used only include them for atoms that have them
        $atom -> alt($altloc) if ( $altloc  ne " ");
        $atom -> insertion_code($icode) if ( $icode ne " ");
        $self-> push($atom);
        }
    close FPDB;
    return;
    }

#print out a molecule to stdout or to a file
sub print
    {

    #names of all the pdb atoms with correct justification for pdb print out
    #these are set by convention and are important for some programs to work correctly
    my %atom_name = (
    'C'    => ' C  ',
    'C1'   => ' C1 ',
    'C1A'  => ' C1A',
    'C1B'  => ' C1B',
    'C1C'  => ' C1C',
    'C1D'  => ' C1D',
    'C2'   => ' C2 ',
    'C2A'  => ' C2A',
    'C2B'  => ' C2B',
    'C2C'  => ' C2C',
    'C2D'  => ' C2D',
    'C3'   => ' C3 ',
    'C3A'  => ' C3A',
    'C3B'  => ' C3B',
    'C3C'  => ' C3C',
    'C3D'  => ' C3D',
    'C4'   => ' C4 ',
    'C4A'  => ' C4A',
    'C4A'  => ' C4A',
    'C4B'  => ' C4B',
    'C4C'  => ' C4C',
    'C4D'  => ' C4D',
    'C5'   => ' C5 ',
    'C6'   => ' C6 ',
    'CA'   => ' CA ',
    'CAA'  => ' CAA',
    'CAB'  => ' CAB',
    'CAC'  => ' CAC',
    'CAD'  => ' CAD',
    'CB'   => ' CB ',
    'CBA'  => ' CBA',
    'CBB'  => ' CBB',
    'CBC'  => ' CBC',
    'CBD'  => ' CBD',
    'CD'   => ' CD ',
    'CD1'  => ' CD1',
    'CD2'  => ' CD2',
    'CE'   => ' CE ',
    'CE1'  => ' CE1',
    'CE2'  => ' CE2',
    'CE3'  => ' CE3',
    'CG'   => ' CG ',
    'CG1'  => ' CG1',
    'CG2'  => ' CG2',
    'CGA'  => ' CGA',
    'CGD'  => ' CGD',
    'CH2'  => ' CH2',
    'CHA'  => ' CHA',
    'CHB'  => ' CHB',
    'CHC'  => ' CHC',
    'CHD'  => ' CHD',
    'CMA'  => ' CMA',
    'CMB'  => ' CMB',
    'CMC'  => ' CMC',
    'CMD'  => ' CMD',
    'CZ'   => ' CZ ',
    'CZ2'  => ' CZ2',
    'CZ3'  => ' CZ3',
    'FE'   => 'FE  ',
    'H'    => ' H  ',
    'HA'   => ' HA ',
    'HB'   => ' HB ',
    'HG'   => ' HG ',
    'HE'   => ' HE ',
    'HZ'   => ' HZ ',
    'HH'   => ' HH ',
    '1H'   => '1H  ',
    '2H'   => '2H  ',
    '3H'   => '3H  ',
    '1HA'  => '1HA ',
    '1HB'  => '1HB ',
    '1HD'  => '1HD ',
    '1HE'  => '1HE ',
    '1HG'  => '1HG ',
    '1HZ'  => '1HZ ',
    '2HA'  => '2HA ',
    '2HB'  => '2HB ',
    '2HD'  => '2HD ',
    '2HE'  => '2HE ',
    '2HG'  => '2HG ',
    '1HZ'  => '1HZ ',
    '2HZ'  => '2HZ ',
    '3HB'  => '3HB ',
    '3HE'  => '3HE ',
    '3HZ'  => '3HZ ',
    'N'    => ' N  ',
    'NA'   => ' NA ',
    'NB'   => ' NB ',
    'NC'   => ' NC ',
    'ND'   => ' ND ',
    'N A'  => ' N A',
    'N B'  => ' N B',
    'N C'  => ' N C',
    'N D'  => ' N D',
    'N1'   => ' N1 ',
    'N2'   => ' N2 ',
    'N3'   => ' N3 ',
    'ND1'  => ' ND1',
    'ND2'  => ' ND2',
    'NE'   => ' NE ',
    'NE1'  => ' NE1',
    'NE2'  => ' NE2',
    'NH1'  => ' NH1',
    'NH2'  => ' NH2',
    'NZ'   => ' NZ ',
    'O'    => ' O  ',
    'O1'   => ' O1 ',
    'O1A'  => ' O1A',
    'O1D'  => ' O1D',
    'O2'   => ' O2 ',
    'O2A'  => ' O2A',
    'O2D'  => ' O2D',
    'O3'   => ' O3 ',
    'O4'   => ' O4 ',
    'O5'   => ' O5 ',
    'O6'   => ' O6 ',
    'OD1'  => ' OD1',
    'OD2'  => ' OD2',
    'OE1'  => ' OE1',
    'OE2'  => ' OE2',
    'OG'   => ' OG ',
    'OG1'  => ' OG1',
    'OH'   => ' OH ',
    'OXT'  => ' OXT',
    'S'    => ' S  ',
    'SD'   => ' SD ',
    'SG'   => ' SG '
        );

    my $self = shift;
    my $n = @_;
    my $type;
    my $anum;
    my $aname;
    my $rname;
    my $chain;
    my $rnum;
    my $xx;
    my $yy;
    my $zz;
    my $coor;
    my $beta;
    local *OFIL;
    my $nmodels = 0;    
    if ($n == 0)
        {
        *OFIL = *STDOUT;
        }
    else
        {
        #$nmodels=&models(0,"$_[0]") if (-e $_[0]);
        open (OFIL,">>$_[0]") or die "Error in print $!\n";
        }
    #$nmodels++;
    #printf OFIL "MODEL %8i\n",$nmodels;
    my $nm = $self -> size;
    my $line;
    for (my $i = 0; $i < $nm; $i++)
        {
        my $iatom = $self -> atom($i); 
        $type  = $iatom->type;
        $anum  = $iatom->number;
        $aname = $iatom->name;
        $rname = $iatom->residue_name;
        $chain = $iatom->chain;
        $rnum  = $iatom->residue_number;
        $xx    = $iatom->x;
        $yy    = $iatom->y;
        $zz    = $iatom->z;
        $coor  = $iatom->occupancy;
        $beta  = $iatom->beta;
        #give the correct indentation to the atom name
        $aname = $atom_name{$aname} if ( defined $atom_name{$aname} );
        $line = sprintf "%-6s%5i %4s %3s %1s%4i    %8.3f%8.3f%8.3f%6.2f%6.2f\n",$type,$anum,$aname,$rname,$chain,$rnum,$xx,$yy,$zz,$coor,$beta;
        print OFIL $line;
        }
    print OFIL "END\n";
    close OFIL if ($n >= 1);
   }


#compute the geometric center of an atom selection
sub center
   {
    my $self = shift;
    my $nrd = $self->size;
    my $xx=0.00e0;
    my $yy=0.00e0;
    my $zz=0.00e0;
    for(my $i=0;$i < $nrd; $i++)
        {
        my $iatom = $self -> atom($i); 
        $xx+=$iatom ->x;
        $yy+=$iatom ->y;
        $zz+=$iatom ->z;
        }
    $xx /= $nrd if ( $nrd > 0);
    $yy /= $nrd if ( $nrd > 0);
    $zz /= $nrd if ( $nrd > 0);
    my $centroid = Bio::PDB::Structure::Atom -> new;
    $centroid ->x($xx);
    $centroid ->y($yy);
    $centroid ->z($zz);
    $centroid ->type("HETATM");
    $centroid ->name("CM");
    $centroid ->number(0);
    $centroid ->residue_name("DUM");
    $centroid ->residue_number("0");
    $centroid ->chain(" ");    
    return $centroid;
    }

#compute the center of mass of an atom selection
sub cm
    {
    #These atoms usually have additional letters or numbers in their names
    my %mass1=(
            H => 1,
            N => 14,
            C => 12,
            O => 16,
            P => 15,
            S => 32
            );
    #These atoms usually appear without extra characters in their names
    my %mass2=(
            K => 39,
           FE => 56,
           CO => 59,
           CL => 35,
           MG => 24,
           NA => 23,
           NI => 59,
           CU => 64,
           ZN => 65
           );
    my $self = shift;
    my $nrd = $self -> size;
    my $ii;
    my $jj;
    my $xx=0;
    my $yy=0;
    my $zz=0;
    my $pre;
    my $match;
    my $aname;
    my $tmass =0;
    my @kmass1 = keys %mass1;

    for(my $i=0;$i < $nrd; $i++)
        {
        $pre = 0;
        $match = 0;
        my $iatom = $self->atom($i);
        $aname = uc($iatom -> name);
        $match = 2 if ( defined($mass2{$aname}) );
        unless ($match)
            {
            foreach $ii (@kmass1)
                {
                if ( $aname =~/$ii/ )
                    {
                    $match = 1;
                    $jj = $ii;
                    last;
                    }
                }
            }
        if ($match == 1)
            {
            $pre = $mass1{$jj};
            }
        elsif ($match == 2)
            {
            $pre = $mass2{$aname};
            }
        else
            {
            #atom's mass is not known, assume carbonlike
            $pre = 12;
            }
        $xx+= $pre * $iatom->x;
        $yy+= $pre * $iatom->y;
        $zz+= $pre * $iatom->z;
        $tmass+=$pre;
        }
    $xx /= $tmass if ( $tmass > 0);
    $yy /= $tmass if ( $tmass > 0);
    $zz /= $tmass if ( $tmass > 0);
    my $centroid = Bio::PDB::Structure::Atom -> new;
    $centroid ->x($xx);
    $centroid ->y($yy);
    $centroid ->z($zz);
    $centroid ->type("HETATM");
    $centroid ->name("CM");
    $centroid ->number(0);
    $centroid ->residue_name("DUM");
    $centroid ->residue_number("0");
    $centroid ->chain(" ");    
    return $centroid;
    }


#translate an atom selection by the specified vector
sub translate
    {
    my $self = shift;
    my $n = @_;
    die "Error in translate: need an atom list an x,y,z\n" unless ($n == 3);   
    my $xt = shift;
    my $yt = shift;
    my $zt = shift;
    my $nrd = $self->size;

    for (my $i=0; $i < $nrd; $i++)
        {
        my $iatom = $self->atom($i);
        $iatom->x(($iatom->x + $xt));
        $iatom->y(($iatom->y + $yt));
        $iatom->z(($iatom->z + $zt));
        }
    return
    }

#rotate an atom selection by the specified matrix, Ax = x'.
#the matrix is specified by a flat list of the matrix elements.
sub rotate
    {
    my $self = shift;
    my $n = @_;
    die "Error in rotate: need an atom list and a 9 element array\n"
                      unless ($n == 9);
    my $u11 = shift;
    my $u12 = shift;
    my $u13 = shift;
    my $u21 = shift;
    my $u22 = shift;
    my $u23 = shift;
    my $u31 = shift;
    my $u32 = shift;
    my $u33 = shift;
    my ($x1,$y1,$z1);
    my ($x2,$y2,$z2);

    my $nrd = $self->size;
 
    for (my $i=0; $i < $nrd; $i++)
        {
        my $iatom = $self -> atom($i);
        $x1 = $iatom ->x;
        $y1 = $iatom ->y;
        $z1 = $iatom ->z;
        $x2 = $u11*$x1 + $u12*$y1 + $u13*$z1;
        $y2 = $u21*$x1 + $u22*$y1 + $u23*$z1;
        $z2 = $u31*$x1 + $u32*$y1 + $u33*$z1;
        $iatom->x($x2);
        $iatom->y($y2);
        $iatom->z($z2);
        }
    return
    }

#combine rotate and translate to facilitate supperposition of structures
#first 9 components represent rotation 3 last components rep. translation
sub rotate_translate 
    {
    my $self = shift;
    my $n = @_;
    die "Error in rotate_translate: need a rotation matrix and a translation vector\n" unless ($n == 12);   
   my @mt;
   my @vt;
   for(my $i=0; $i < 9; $i++)
      {
      $mt[$i] = shift;
      }
   for(my $i=0; $i < 3; $i++)
      {
      $vt[$i] = shift;
      }
    $self->rotate(@mt);
    $self->translate(@vt);
    return
    }

#do a superposition of an atom list to a reference (2nd argument)
#selections must have the same number of atoms
#Using method from: S. Kearsley, Acta Cryst. A45, 208-210 1989
sub superpose
   {
    my $self1 = shift;
    my $n = @_;
    die "Error in superpose: need an atom list (reference)\n" 
         unless ($n == 1);
    my $self2 = shift;
    my $nrd1 = $self1->size;
    my $nrd2 = $self2->size;
    my ($x1,$y1,$z1);
    my ($x2,$y2,$z2);
    my ($xm,$ym,$zm);
    my ($xp,$yp,$zp);
    my ($Sxmxm, $Sxpxp, $Symym, $Sypyp, $Szmzm, $Szpzp); 
    my ($Sxmym, $Sxmyp, $Sxpym, $Sxpyp);
    my ($Sxmzm, $Sxmzp, $Sxpzm, $Sxpzp);
    my ($Symzm, $Symzp, $Sypzm, $Sypzp); 
    die "superpose error: lists must have same number of atoms\n" 
                                 unless ($nrd1 == $nrd2);

    #get the geometric center of the molecules
    my $gc1 = $self1 -> center;
    my $gc2 = $self2 -> center;

    #construct a 4X4 matrix in the quaternion representation
    for(my $i=0; $i<$nrd1 ; $i++) 
        {
        my $iatom1=$self1->atom($i);
        $x1 =  $iatom1->x - $gc1->x;
        $y1 =  $iatom1->y - $gc1->y;
        $z1 =  $iatom1->z - $gc1->z;
        
        my $iatom2=$self2->atom($i);
        $x2 =  $iatom2->x - $gc2->x;
        $y2 =  $iatom2->y - $gc2->y;
        $z2 =  $iatom2->z - $gc2->z;

        $xm = ($x1 - $x2);
        $xp = ($x1 + $x2);           
        $ym = ($y1 - $y2);
        $yp = ($y1 + $y2);             
        $zm = ($z1 - $z2);
        $zp = ($z1 + $z2);

        $Sxmxm  += $xm*$xm; 
        $Sxpxp  += $xp*$xp;
        $Symym  += $ym*$ym; 
        $Sypyp  += $yp*$yp; 
        $Szmzm  += $zm*$zm; 
        $Szpzp  += $zp*$zp; 

        $Sxmym  += $xm*$ym; 
        $Sxmyp  += $xm*$yp; 
        $Sxpym  += $xp*$ym; 
        $Sxpyp  += $xp*$yp; 

        $Sxmzm  += $xm*$zm; 
        $Sxmzp  += $xm*$zp; 
        $Sxpzm  += $xp*$zm; 
        $Sxpzp  += $xp*$zp; 

        $Symzm  += $ym*$zm; 
        $Symzp  += $ym*$zp; 
        $Sypzm  += $yp*$zm; 
        $Sypzp  += $yp*$zp;
        }
   my @m;
   $m[0]= $Sxmxm + $Symym + $Szmzm;
   $m[1]= $Sypzm - $Symzp;
   $m[2]= $Sxmzp - $Sxpzm;
   $m[3]= $Sxpym - $Sxmyp;
   $m[4]= $m[1];
   $m[5]= $Sypyp + $Szpzp + $Sxmxm;
   $m[6]= $Sxmym - $Sxpyp;
   $m[7]= $Sxmzm - $Sxpzp;
   $m[8]= $m[2];
   $m[9]= $m[6];
   $m[10]= $Sxpxp + $Szpzp + $Symym;
   $m[11]= $Symzm - $Sypzp;
   $m[12]= $m[3];
   $m[13]= $m[7];
   $m[14]= $m[11];
   $m[15]=$Sxpxp + $Sypyp + $Szmzm;
   #compute the egienvectors and eigenvalues of the matrix
   my ( $revec, $reval ) = &__diagonalize(@m);
   #the smallest eigenvalue is the rmsd for the optimal alignment
   my $rmsd = sqrt(abs($reval->[0])/ $nrd1 );
   #fetch the optimal quaternion
   my @q;
   $q[0]=$revec->[0][0];
   $q[1]=$revec->[1][0];
   $q[2]=$revec->[2][0];
   $q[3]=$revec->[3][0];
   #construct the rotation matrix given by the quaternion
   my @mt;
   $mt[0] = $q[0]*$q[0] + $q[1]*$q[1] - $q[2]*$q[2] - $q[3]*$q[3];
   $mt[1] = 2.0 * ($q[1] * $q[2] - $q[0] * $q[3]);
   $mt[2] = 2.0 * ($q[1] * $q[3] + $q[0] * $q[2]);


   $mt[3] = 2.0 * ($q[2] * $q[1] + $q[0] * $q[3]);
   $mt[4] = $q[0]*$q[0] - $q[1]*$q[1] + $q[2]*$q[2] - $q[3]*$q[3];
   $mt[5] =  2.0 * ($q[2] * $q[3] - $q[0] * $q[1]);

   $mt[6] = 2.0 *($q[3] * $q[1] - $q[0] * $q[2]);
   $mt[7] = 2.0 * ($q[3] * $q[2] + $q[0] * $q[1]);
   $mt[8] = $q[0]*$q[0] - $q[1]*$q[1] - $q[2]*$q[2] + $q[3]*$q[3];

   #compute the displacement vector
   my @vt;
   $vt[0] = $gc2->x - $mt[0]*$gc1->x - $mt[1]*$gc1->y - $mt[2]*$gc1->z;
   $vt[1] = $gc2->y - $mt[3]*$gc1->x - $mt[4]*$gc1->y - $mt[5]*$gc1->z;  
   $vt[2] = $gc2->z - $mt[6]*$gc1->x - $mt[7]*$gc1->y - $mt[8]*$gc1->z;

   #return the transformation as one list rotation first
   return ( @mt,@vt );
   }

#compute the rmsd between two atom selections (must have same number of atoms)
sub rmsd
    {
    my $self1 =shift;
    my $n = @_;
    die "Error in rmsd: an atom list\n" unless ($n == 1);
    my $self2 = shift;
    my $nrd1 = $self1 ->size;
    my $nrd2 =  $self2 ->size;
    my ($dx,$dy,$dz);
    my $rmsd=0;

    die "rmsd error: lists must have same number of atoms\n" 
                                 unless ($nrd1 == $nrd2);
    for(my $i=0;$i<$nrd1;$i++)
        {
        my $iatom1 = $self1->atom($i);
        my $iatom2 = $self2->atom($i);

        $dx = $iatom1->x - $iatom2->x;
        $dy = $iatom1->y - $iatom2->y;
        $dz = $iatom1->z - $iatom2->z;
        $rmsd += $dx**2 + $dy**2 + $dz**2;
      }
    $rmsd =sqrt($rmsd /$nrd1) if ( $nrd1 > 0.0E0 );
    return $rmsd;
    }

#some predefined atom lists
#return protein or nucleic acid atoms
sub protein
    {
    my $self = shift;
    my $n = $self->size;
    my $mol= Bio::PDB::Structure::Molecule -> new;
    for( my $i=0; $i < $n; $i++)
        {
        my $iatom = $self->atom($i);
        $mol -> push($iatom) if ( $iatom->type eq "ATOM");
        }
    return $mol;
    }

sub hetatoms
    {
    my $self = shift;
    my $n = $self->size;
    my $mol= Bio::PDB::Structure::Molecule -> new;
    for( my $i=0; $i < $n; $i++)
        {
        my $iatom = $self->atom($i);
        $mol -> push($iatom) if ( $iatom->type eq "HETATM");
        }
    return $mol;
    }

sub alpha
    {
    my $self = shift;
    my $n = $self->size;
    my $mol= Bio::PDB::Structure::Molecule -> new;
    for( my $i=0; $i < $n; $i++)
        {
        my $iatom = $self->atom($i);
        $mol -> push($iatom) if ( $iatom->type eq "ATOM" && $iatom->name eq "CA");
        }
    return $mol;
    }

sub backbone
    {
    my $self = shift;
    my $n = $self->size;
    my $mol= Bio::PDB::Structure::Molecule -> new;
    my @batoms = ("N","C","CA","O","OXT");
    for( my $i=0; $i < $n; $i++)
        {
        my $iatom = $self->atom($i);
        next if ($iatom->type ne "ATOM");
        my $name = $iatom->name;
        $mol -> push($iatom) if ( grep /^$name$/,@batoms );
        }
    return $mol;
    }

sub sidechains
    {
    my $self = shift;
    my $n = $self->size;
    my $mol= Bio::PDB::Structure::Molecule -> new;
    my @batoms = ("N","C","CA","O","H","HA","OXT");
    for( my $i=0; $i < $n; $i++)
        {
        my $iatom = $self->atom($i);
        next if ($iatom->type ne "ATOM");
        my $name = $iatom->name;
        $mol -> push($iatom) if (not grep /^$name$/,@batoms );
        }
    return $mol;
    }

#get a list of atoms specified by user input residue_name,residue_number,
#chain_name,atom_name,atom_number;
sub list_atoms
    {
    my $self = shift;
    my $ni = @_;
    die "Error in list_atom: need a logical expression\n" if ($ni != 1);
    my $logic = shift;
    my $n = $self->size;
    my @i2n = (
        "RESIDUE_NAME",
        "RESIDUE_NUMBER",
        "TYPE",
        "NUMBER",
        "NAME",
        "CHAIN",
        "X",
        "Y",
        "Z",
        "OCCUPANCY",
        "BETA",
        "ALT",
        "INSERTION_CODE"
        );
    my @i2v = (
        '$iatom->residue_name',
        '$iatom->residue_number',
        '$iatom->type',
        '$iatom->number',
        '$iatom->name',
        '$iatom->chain',
        '$iatom->x',
        '$iatom->y',
        '$iatom->z',
        '$iatom->occupancy',
        '$iatom->beta',
        '$iatom->alt',
        '$iatom->insertion_code'
        );
    #so as to be able to write logical expressions in a natural format we have 
    #to do a bit of extra processing
    #save expressions between quotes to protect them
    my @temp;
    while ($logic =~s/(\"\w+\")/!!/)
        {
        CORE::push (@temp,$1);
        }
    $logic= uc($logic);
    #now substitute with method calls
    for (my $i =0; $i<13; $i++)
        {
        $logic =~ s/$i2n[$i]/$i2v[$i]/g;
        }
    $logic= lc($logic);
    #restore expressions between quotes
    foreach my $itemp (@temp)
        {
        $logic=~s/!!/$itemp/;
        }
    #print "$logic\n";
    my $mol = Bio::PDB::Structure::Molecule -> new;
    my $iatom= $self-> atom(0);
    eval $logic;
    die "Error with logical expression for list_atoms call\n" if $@;
    for (my $i=0; $i< $n; $i++)
        {
        $iatom = $self-> atom($i);
        $mol -> push($iatom) if ( eval $logic );
        }
    return $mol;
    }

#Jacobi diagonalizer
   sub __diagonalize {
   my ($onorm, $dnorm);
   my ($b,$dma,$q,$t,$c,$s);
   my ($atemp, $vtemp, $dtemp);
   my ($i,$j,$k,$l);
   my @a;
   my @v;
   my @d;
   my $nrot = 30; #number of sweeps

   for ($i = 0; $i < 4; $i++) 
      {
      for ($j = 0; $j < 4; $j++)
         {
         $a[$i][$j] =$_[4*$i + $j];
         $v[$i][$j] = 0.0;
         }
      }

   for ($j = 0; $j <= 3; $j++) 
      {
      $v[$j][$j] = 1.0;
      $d[$j] = $a[$j][$j];
      }

   for ($l = 1; $l <= $nrot; $l++) 
      {
      $dnorm = 0.0;
      $onorm = 0.0;
      for ($j = 0; $j <= 3; $j++)
         {
         $dnorm +=  abs($d[$j]);
         for ($i = 0; $i <= $j - 1; $i++)
            {
            $onorm += abs($a[$i][$j]);
            }
         }
      last if(($onorm/$dnorm) <= 1.0e-12);
      for ($j = 1; $j <= 3; $j++) 
         {
         for ($i = 0; $i <= $j - 1; $i++) 
            {
            $b = $a[$i][$j];
            if(abs($b) > 0.0) 
               {
               $dma = $d[$j] - $d[$i];
               if((abs($dma) + abs($b)) <=  abs($dma)) 
                  {
                  $t = $b / $dma;
                  }
               else 
                  {
                  $q = 0.5 * $dma / $b;
                  $t = 1.0/(abs($q) + sqrt(1.0+$q*$q));
                  $t *= -1.0 if($q < 0.0); 
                  }
               $c = 1.0/sqrt($t * $t + 1.0);
               $s = $t * $c;
               $a[$i][$j] = 0.0;
               for ($k = 0; $k <= $i-1; $k++) 
                  {
                  $atemp = $c * $a[$k][$i] - $s * $a[$k][$j];
                  $a[$k][$j] = $s * $a[$k][$i] + $c * $a[$k][$j];
                  $a[$k][$i] = $atemp;
                  }
               for ($k = $i+1; $k <= $j-1; $k++)
                  {
                  $atemp = $c * $a[$i][$k] - $s * $a[$k][$j];
                  $a[$k][$j] = $s * $a[$i][$k] + $c * $a[$k][$j];
                  $a[$i][$k] = $atemp;
                  }
               for ($k = $j+1; $k <= 3; $k++) 
                  {
                  $atemp = $c * $a[$i][$k] - $s * $a[$j][$k];
                  $a[$j][$k] = $s * $a[$i][$k] + $c * $a[$j][$k];
                  $a[$i][$k] = $atemp;
                  }
               for ($k = 0; $k <= 3; $k++) 
                  {
                  $vtemp = $c * $v[$k][$i] - $s * $v[$k][$j];
                  $v[$k][$j] = $s * $v[$k][$i] + $c * $v[$k][$j];
                  $v[$k][$i] = $vtemp;
                  }
               $dtemp = $c*$c*$d[$i] + $s*$s*$d[$j] - 2.0*$c*$s*$b;
               $d[$j] = $s*$s*$d[$i] + $c*$c*$d[$j] +  2.0*$c*$s*$b;
               $d[$i] = $dtemp;
               } 
            }  
         }
      } 

   $nrot = $l;
   for ($j = 0; $j <= 2; $j++) 
      {
      $k = $j;
      $dtemp = $d[$k];
      for ($i = $j+1; $i <= 3; $i++) 
         {
         if($d[$i] < $dtemp) 
            {
            $k = $i;
            $dtemp = $d[$k];
            }
         }

      if($k > $j) 
         {
         $d[$k] = $d[$j];
         $d[$j] = $dtemp;
         for ($i = 0; $i <= 3; $i++) 
            {
            $dtemp = $v[$i][$k];
            $v[$i][$k] = $v[$i][$j];
            $v[$i][$j] = $dtemp;
            }
         }
      }
   
   return (\@v,\@d)
   }

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Bio::PDB::Structure - Perl module for parsing and manipulating Protein Databank (PDB) files

=head1 SYNOPSIS

  use Bio::PDB::Structure;
  
  $mol1= Bio::PDB::Structure::Molecule -> new;
  $mol2= Bio::PDB::Structure::Molecule -> new;
  $mol1 -> read("molecule.pdb",0);         #read the first model
  $mol2 -> read("molecule.pdb",1);         #read the second model
  $mol1b = $mol1 -> backbone;              #create a list with the backbone of mol1
  $mol2b = $mol2 -> backbone;              #create a list with the backbone of mol2
  @transform = $mol2b ->superpose($mol1b); #compute alignment of mol2 to mol1
  $mol2 ->rotate_translate(@transform);    #rotate and translate mol2
  $rmsd = $mol2 -> rmsd($mol1);            #compute the rmsd between mol2 and mol1
  $mol2 -> print("new.pdb");               #save the molecule to a file

=head1 DESCRIPTION

This module combines tools that are commonly used to analyze proteins and
nucleic acids from a pdb file stuctures. The main benefits of using the module
are its ability to parse and print out a pdb structure with minimum effort.
However in addition to that it is possible to do structural alignments, RMSD
calculations, atom editons, center of mass calculations, molecule editions
and so forth. Both Atom objects and Molecule objects are defined within
this module. 

=head2 Methods for Atom objects

=over 4

=item * $object->type

=item * $object->type("ATOM")

    Get/set the atom's type


=item * $object->number

=item * $object->number(50)

    Get/set the atom's number


=item * $object->name

=item * $object->name("CA")

    Get/set the atom's name


=item * $object->chain

=item * $object->chaini("X")

    Get/set the atom's chain 


=item * $object->chain

=item * $object->residue_number(100)

    Get/set the atom's residue number 


=item * $object->residue_name

=item * $object->residue_name("ALA")

    Get/set the atom's residue name 


=item * $object->x

=item * $object->x(5.5)

    Get/set the atom's x coordinate 


=item * $object->y

=item * $object->y(5.5)

    Get/set the atom's y coordinate 


=item * $object->z

=item * $object->z(5.5)

    Get/set the atom's z coordinate 


=item * $object->occupancy

=item * $object->occupancy(1.0)

    Get/set the atom's occupancy


=item * $object->beta

=item * $object->beta(0.3)

    Get/set the atom's temperature factor


=item * $object->alt

=item * $object->alt("I")

    Get/set the atom's alternate location field


=item * $object->insertion_code

=item * $object->insertion_code("K")

    Get/set the atom's insertion code


=item * distance Bio::PDB::Structure::Atom($atom1,$atom2)

    Compute the distance between atom1 and atom2


=item * distance Bio::PDB::Structure::Atom($atom1,$atom2,$atom3)

    Compute the angle in degrees sustended by  atom1--atom2--atom3


=item * dihedral Bio::PDB::Structure::Atom($atom1,$atom2,$atom3,$atom4)

    Compute the dihedral in degrees sustended by atom1--atom2--atom3--atom4


=back

=head2 Methods for Molecule objects

=over 4


=item * models Bio::PDB::Structure::Molecule "file.pdb"

    Return the number of models in a pdb file


=item * $object->read("file.pdb")

=item * $object->read("file.pdb",i)

    Read the contents of file.pdb into a molecule. If a second numeric argument is
    specified it will read  model (i+1) from the file  (counting from zero).


=item * $object->print

=item * $object->print("file.pdb")

    Write the molecule to STDOUT when no argument is provided or to a file when an
    argument is provided.


=item * $object->size

    Return the number of atoms contained in the molecule.


=item * $object->atom(5)

    Return the atom located at position five (starting from zero).


=item * $object->push(atom)

    Push atom object at the end of the molecule.


=item * $object->proten

    Return a molecule that only contains atoms with type ATOM


=item * $object->hetatoms

    Retruns a molecule that only contains HETATM records


=item * $object->alpha

    Returns a molecule with the alpha carbons


=item * $object->backbone

    Returns a molecule with the backbone of a protein


=item * $object->sidechains

    Returns a molecule with the sidechains of a protein


=item * $object->list_atoms('logical expression')

    Creates a molecule with a custom atom selection. The logical expression must use
    Perl's logical operators and the properties of atoms. For example to select all
    atoms from residue 50 onwards and only belonging to ALA residues on would use
    the logical expression: 'residue_number >= 50 && residue_name eq "ALA"'


=item * $object->center

    Return an atom object that respresents the centroid for the given molecule.


=item * $object->cm

    Return an atom object that sits at the center of mass for the given molecule.


=item * $object->translate(x,y,z)

    Translate the molecule as a rigid object by x,y,z.


=item * $object->rotate(u11,u12,u13,u21,u22,u23,u31,u32,u33)

    Do a rigid rotation of the molecule using matrix u.


=item * $object->rotate_translate(@matrix,@vector)

    Apply a rotation matrix followed by a translation. To facilitate structural
    supperpositions.


=item * $object->superpose($reference)

    Find the transformation that overlaps $object on to $reference. The resulting
    transformation is in the format @transformation= (@matrix,@vector). Molecules
    must have the same number of atoms.


=item * $object->rmsd($reference)

    Compute the RMSD between two molecules. The molecules must have the same number
    of atoms


=back

=head1 SEE ALSO

http://www.pdb.org

=head1 AUTHOR

Raul Alcantara Aragon, E<lt>rulix@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Raul Alcantara

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
