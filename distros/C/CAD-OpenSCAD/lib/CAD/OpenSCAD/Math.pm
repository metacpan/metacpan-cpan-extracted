use strict; use warnings;

use Object::Pad;

our $VERSION='0.12';

class CAD::OpenSCAD::Math{
	field $pi  :reader;
	field $e   :reader;
	
	BUILD{
		$pi=4*atan2(1,1);
		$e= exp(1);
	}
	method mirrorrotate{ # 2d rotate and mirror 
		my ($point,$angle)=@_;
		return [$point->[0]*cos($angle)+$point->[1]*sin($angle),
			   -$point->[1]*cos($angle)+$point->[0]*sin($angle)];
	}
	 
	method rotate{# rotate point or set of points 2d rotate with angle or 3d rotate with 3 rotations
		my ($point,$angle)=@_;
		if (ref $point->[0] ne "ARRAY"){
			if (scalar @$point ==2){  # 2d rotations
				return [$point->[0]*cos($angle)-$point->[1]*sin($angle),
					$point->[1]*cos($angle)+$point->[0]*sin($angle)];
			}
			else{                     # 3d rotations
				my $result=$self->rotx($point,$angle->[0]);
				$result=$self->roty($result,$angle->[1]);
				$result=$self->rotz($result,$angle->[2]);
				return $result;
			}
		}
		else{
			 my $tmp=[@$point];
			 foreach (0..$#$tmp){
				 $tmp->[$_]=$self->rotate($tmp->[$_],$angle);
			 }
			 return $tmp;
		}
	}		
	

	method rotx{
		my ($point,$angle)=@_;
		my $matrix=[
		             [1,0,0],
		             [0,cos($angle),-sin($angle)],
		             [0,sin($angle),cos($angle)],
		           ];
		return $self->matrixTransform($point,$matrix);
		
	}
	
	method roty{
		my ($point,$angle)=@_;
		my $matrix=[
		             [cos($angle),0,sin($angle)],
		             [0,1,0],
		             [-sin($angle),0,cos($angle)],
		           ];
		return $self->matrixTransform($point,$matrix);
		
	}
	
	method rotz{
		my ($point,$angle)=@_;
		my $matrix=[
		             [cos($angle),-sin($angle),0],
		             [sin($angle),cos($angle),0],
		             [0,0,1],
		           ];
		return $self->matrixTransform($point,$matrix);
	}
	
	
				
	method matrixTransform{
		my ($point,$matrix)=@_;
		if (ref $point->[0] ne "ARRAY"){
			my $output=[];
			foreach my $c (0..$#{$matrix->[0]}){
				my $sum=0;
				foreach my $r (0..$#$matrix){
					$sum+=$point->[$r]*$matrix->[$c]->[$r];
				}
				$output->[$c]=$sum;
			}
			return $output;
		}
		else{
			 my $tmp=[@$point];
			 foreach (0..$#$tmp){
				 $tmp->[$_]=$self->matrixTransform($tmp->[$_],$matrix);
			 }
			 return $tmp;
		}
	}
	
		
	method add{ # add vectors
		my ($point1,$point2)=@_;
		if((scalar @$point1 == scalar @$point2) && (! ref $point1->[0])){
		      return [map{$point1->[$_]+$point2->[$_]} (0..$#$point1)]
		 }
		 elsif (ref $point1->[0] eq "ARRAY"){
			 my $tmp=[@$point1];
			 foreach (0..$#$tmp){
				 $tmp->[$_]=$self->add($tmp->[$_],$point2);
			 }
			 return $tmp;
				
		}
		else {die "Math->add failed"};
	}
		
	
	# measure angle between 2 points from origin
	# if one point passed, angle from point to X-axis
	method angle{
		my ($p1,$p2)=@_;
		$p2=[1,0] unless $p2;
		return atan2($p1->[0],$p1->[1])-atan2($p2->[0],$p2->[1]);
	}
	
	method deg2rad{
		my ($deg)=@_;
		return $deg*$pi/180;
	}
	
	method rad2deg{
		my ($rad)=@_;
		return $rad*180/$pi;
	}
	
	# measure distance between 2 points
	# if only one point passed, distance between point and origin
	method distance{
		my ($p1,$p2)=@_;	
		$p2=[(0)x@$p1] unless $p2;	
		my $sum=0;
		for(0..$#$p1){$sum+=($p1->[$_]-$p2->[$_])**2};
		return sqrt($sum);
	}
	
	method dot{ #dot product of two points
		my ($p1,$p2)=@_;	
		die "Points not same dimensions in Math->dot product\n" if @$p1 !=  @$p2 ;
		my $sum=0;
		for(0..$#$p1){$sum+=$p1->[$_]*$p2->[$_]};
		return $sum;
		
	}
	
	method cross{#dot product of two 3d points
		my ($p1,$p2)=@_;	
		die "Point(s) not 3d in Math->cross product\n" if((@$p1 !=  @$p2) &&( @$p1 !=3));
		return [$p1->[1]*$p2->[2]-$p1->[2]* $p2->[1],
		        $p1->[2]*$p2->[2]-$p1->[2]* $p2->[0],
		        $p1->[0]*$p2->[1]-$p1->[1]* $p2->[0]]
	}
	
	method unit{# unit vector
		my ($p1)=@_;
		my $mag=$self->distance($p1);
		return [map{$p1->[$_]/$mag} 0..$#$p1] ;
	}
		
	method tan{
		my ($ang)=@_;
		return sin($ang)/cos($ang);
	}
	
	method serialise{
		my $st=shift;
		if (ref $st eq "ARRAY"){
			return "[".join(",",map{$self->serialise($_)}@$st)."]"
		}
		elsif (ref $st eq "HASH"){
			return "{".join(",",map{$_."=>".$self->serialise($st->{$_})}keys %$st)."}"
		}
		else{
			return $st=~/^[\d+-\.]/?$st:"\"$st\"";
		};
	}
	
	method equal{
		my ($p1,$p2)=@_;	
		if (! ref $p1){
			return $p1==$p2?1:0};
		die "Points not same dimensions in Math->equal\n" if @$p1 !=  @$p2 ;
		for(0..$#$p1){return 0 unless $self->equal($$p1[$_],$$p2[$_])};
		return 1;
	}
	
	
}
