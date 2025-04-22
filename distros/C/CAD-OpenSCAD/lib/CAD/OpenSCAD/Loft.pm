use strict;use warnings;

use Object::Pad;
use CAD::OpenSCAD::Math;

our $VERSION='0.14';

our $Math=new CAD::OpenSCAD::Math;

class CAD::OpenSCAD::Loft{
	field $scad :param;	
	
	method loftSolid{
		my ($name,$face1,$face2)=@_;
		my $pts=[@$face1,@$face2];
		my $faces=[[reverse(0..$#$face1)],@{$self->loftShell($face1,$face2)},[$#$face1+1..$#$face1*2+1]];
		if ($name){
			$scad->polyhedron($name,{points=>$pts,faces=>$faces});
			return $scad
		}
		return {points=>$pts,faces=>$faces}
	}

	method helix{
		my $name=shift;
		my ($profile,$radius,$steps,$turns,$verticalShift,$radialShift);
		unless (ref $_[0] eq "HASH"){
			($profile,$radius,$steps,$turns,$verticalShift,$radialShift)=@_;
		}
		else{
			my $params=$_[0];
			($profile,$radius,$steps,$turns,$verticalShift,$radialShift)=
			   map {$params->{$_}}(qw/profile radius steps turns verticalShift radialShift/);
		}
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
		if ($name){
			$scad->polyhedron($name,{points=>$points,faces=>$faces});
		}
		return {points=>$points,faces=>$faces}
	}	

	method spheroid{# this generates a spheroid using a series of lofts between polygons
	  my $name=shift;
      my ($sides,$radius);
	  unless (ref $_[0]){
		($sides,$radius)=@_;
	  }
	  else{
		my $params=$_[0];
		($sides,$radius)=
		   map {$params->{$_}}(qw/sides radius/);
	  }
	  my $angle=2*$Math->pi/$sides;
	  my $pts=[];my $layers=[];my $faces;my $index=0;
	  my $start=$sides/4+1;
	  my $end=3*$sides/4 -($sides%4?0:1);
	  for my $lat ($start..$end){
		my $layer=[];
		for my $long(0..$sides-1){
		  unshift @$layer,[$radius*cos($lat*$angle)*sin($long*$angle),$radius*cos($lat*$angle)*cos($long*$angle),$radius*sin($lat*$angle)]
		}
		push @$pts,@$layer;
		push @$layers,[@$layer];
		if ( 1 == @$layers ){
			push @$faces,[reverse(0..$#$layer)]; #top polygon
		}
		else{
			push @$faces,@{$self->loftShell($layers->[-2],$layers->[-1],$index)};# the lofted faces added
			$index+=scalar @{$layers->[-2]};
		}
	   }
	   push @$faces,[$#$pts-$sides+1..$#$pts];# bottom polygon;
	   if ($name){
		   $scad->polyhedron($name,{points=>$pts,faces=>$faces});
		   return $scad
	   }
	   return {points=>$pts,faces=>$faces};
    }

	method regularPolygon{
	  my $name=shift;
      my ($sides,$radius);
	  unless (ref $_[0]){
		($sides,$radius)=@_;
	  }
	  else{
		my $params=$_[0];
		($sides,$radius)=
		   map {$params->{$_}}(qw/sides radius/);
	  }
	  my $angle=2*$Math->pi/$sides;
	  my $pts=[];
	  for (0..$sides-1){
		  push @$pts,[$radius*sin($_*$angle),$radius*cos($_*$angle)]
	  }
	  if ($name) {
		  $scad->polygon($name,$pts);
		  return $scad;
	  }
	  return $pts;
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
   
   method profilePlane{
	   my $profile=shift;
	   my $plane=shift;
	   for ($plane){
		   ~/0|x/i && do{
			   $profile=map{[0,$_[0],$_[1]]}@$profile;
			   last;
		   };
		   ~/1|y/i && do{
			   $profile=map{[$_[0],0,$_[1]]}@$profile;
			   last;
		   };
		   ~/2|z/i && do{
			   $profile=map{[$_[0],$_[1],0]}@$profile;
			   last;
		   };
		   die "Unrecognised plane"
	   }
	   return $profile;
	   
   }
   
   method conoid{
	  my $name=shift;
      my ($apex,$sides,$radius);
	  unless (ref $_[0] eq "HASH"){
		($apex,$sides,$radius)=@_;
	  }
	  else{
		my $params=$_[0];
		($sides,$radius)=
		   map {$params->{$_}}(qw/apex sides radius/);
	  }
	  my $profile=$self->regularPolygon(undef,$sides,$radius);
	  my $pts=[$apex,$profile->[-1]];my $faces=[];
	  foreach(0..$#$profile){
		  push @$faces,[0,$_+1,$_+2];
		  push @$pts,$profile->[$_];
	  }
	  push @$faces,([0,$#$profile+2,1],[reverse(1..$sides+1)]);
	  $faces=$self->reverseFaces($faces) if $apex->[2]<0;
	  $scad->polyhedron($name,{points=>$pts,faces=>$faces});
   }
   
   method reverseFaces{
	   my $faces=shift;
	   return [map {[reverse @$_]}@$faces]
   }
   
   method arc{
		my $name=shift;
		my ($profile,$radius,$steps,$angle);
		unless (ref $_[0] eq "HASH"){
			($profile,$radius,$steps,$angle)=@_;
		}
		else{
			my $params=$_[0];
			($profile,$radius,$steps,$angle)=
			   map {$params->{$_}}(qw/profile radius steps angle/);
		}
		my $face1=[];
		my $faces=[[reverse(0..$#$face1)]];
		push @$face1,[0,$_->[0],$_->[1]] foreach(@$profile);  # map profile in Y and Z plane
		$face1=$Math->add($face1,[0,$radius,0]);              # shift profile $radius distance along X
		my $stepAngle=$Math->deg2rad($angle/$steps);
		my $points=[@$face1];my $index=0;                     # first face   
		for (0..$steps-1){
			my $face2=$Math->rotz($face1,$stepAngle);  # rotate and shift to get next face
			#$face2=$Math->add($face2,[$radius*sin($stepAngle),$radius*cos($stepAngle),0]);
			push @$points,@$face2;                           # add to points list
			push @$faces, @{$self->loftShell($face1,$face2,$index)};# the lofted faces added
			$face1=[@$face2];                                # last face becomes first for the next loft;
			$index+=scalar @$face1;
		}
		push @$faces,[$#$faces..$#$faces+scalar @$face1];
		if ($name){
			$scad->polyhedron($name,{points=>$points,faces=>$faces});
		}
		return {points=>$points,faces=>$faces}
	}	
   

}
