use strict;use warnings;

use Object::Pad;
use CAD::OpenSCAD::Math;

our $VERSION='0.13';

our $Math=new CAD::OpenSCAD::Math;


class CAD::OpenSCAD::Loft{
	field $scad :param;	
	
	method loftSolid{
		my ($name,$face1,$face2)=@_;
		$scad->polyhedron($name,{points=>[@$face1,@$face2],
			faces=>[[reverse(0..$#$face1)],@{$self->loftShell($face1,$face2)},[$#$face1+1..$#$face1*2+1]]});
	}

	method helix{
		my $name=shift;
		my ($profile,$radius,$steps,$turns,$verticalShift,$radialShift)=@_;
		my $face1=[];
		push @$face1,[0,$_->[0],$_->[1]] foreach(@$profile);  # map profile in Y and Z plane
		$face1=$Math->add($face1,[0,$radius,0]);              # shift profile $radius distance along X
		my $faces=[[reverse(0..$#$face1)]];
		my $points=[@$face1];my $index=0;                     # first face   
		for (0..$turns*$steps){
			my $face2=$Math->rotz($face1,$Math->deg2rad(-360/$steps));  # rotate and shift to get next face
			$face2=$Math->add($face2,[$radialShift*sin($_*2*$Math->pi/$steps),$radialShift*cos($_*2*$Math->pi/$steps),$verticalShift]);
			push @$points,@$face2;                           # add to points list
			push @$faces, @{$self->loftShell($face1,$face2,$index)};# the lofted faces added
			$face1=[@$face2];                                # last face becomes first for the next loft;
			$index+=scalar @$face1;
		}
		push @$faces,[$#$faces..$#$faces+scalar @$face1];
		$scad->polyhedron($name,{points=>$points,faces=>$faces});
	}	

    # old version requiring matching number of faces in vertices
	#method loftShell{
		#my ($face1,$face2,$index)=@_;
		#$index//=0;
		#my $loftFaces=[];
		#foreach (0..$#$face1-1){
		   #push @$loftFaces,[$_+$index,$_+1+$index,$#$face1+2+$_+$index,$#$face1+1+$_+$index];
		#}
		#push @$loftFaces,[$#$face1+$index,0+$index,$#$face1+1+$index,$#$face1*2+1+$index];
		#return $loftFaces;
	#}

    method cable{
		my $name=shift;
		my ($profile,$path)=@_;
		
		
	}
    
    method loftShell{
		my ($face1,$face2,$index)=@_;
		$index//=0;
		my $loftFaces=[];
		my @indices=($index..$#$face1+$index,@$face1+$index..@$face1+$#$face2+$index);
		my $diff=abs(@$face2-@$face1); # difference in vertex count of faces
		if ($diff){
			my $steps=@$face2>@$face1?$#$face1/$diff:$#$face2/$diff; # smaller array needs to be padded;
			my $start=(@$face2>@$face1?$#$face1:$#indices)-$steps/2;
			for (1..$diff){
				splice (@indices,$start,0,$indices[$start]);
				$start-=$steps;
			}
		}
		
		foreach (0..@indices/2-2){
		   my $face=[$indices[$_],$indices[$_+1],$indices[(@indices/2)+1+$_],$indices[(@indices/2)+$_]];
		   push @$loftFaces,$face;
		}
		push @$loftFaces,[$indices[@indices/2-1],$indices[0],$indices[@indices/2],$indices[-1]];
		return $loftFaces;
}

}
