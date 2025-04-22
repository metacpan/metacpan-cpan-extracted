use strict; use warnings;

use Object::Pad;
use CAD::OpenSCAD::Math;

our $VERSION='0.14';
	
our $Math=new CAD::OpenSCAD::Math;
		
class CAD::OpenSCAD::GearMaker{
	field $scad :param;	
	
	method profile{
		my %params=@_;
		my $pi=$Math->pi;
		my $module=$params{module}//2;  #  Module
		my $teeth=$params{teeth}//16;
		my $backlash=$params{backlash}//20;# profile shift degrees
		my $PressAngle=$params{pressure_angle}//20;
		
		my $PCD=$module*$teeth	;
		my $Addendum=$module;
		my $Dedendum=$Addendum*1.25;
		my $BaseD=$PCD*cos($PressAngle*$pi/180);
		my $Engagement=0;
		my $InitialAngle=$Engagement+((sin($PressAngle*$pi/180)*$PCD/2)*360/($pi*$BaseD) - $PressAngle);
		
		my $steps=3;
		my $points=[];
		for (my $ang=0;$ang<80;$ang+=$steps){
			my $colB=$InitialAngle-$ang;
			my $alpha=180*atan2($pi*$ang/180,1)/$pi;
			my $R=sqrt(($ang*$pi*$BaseD/360)**2+($BaseD/2)**2);
			my $x=cos(($InitialAngle-$ang+$alpha)*$pi/180)*$R;
			my $y=sin(($InitialAngle-$ang+$alpha)*$pi/180)*$R;
			unless ($ang){  # at the first pass insert the dip to dedendum
				my $dx=$PCD/2-$Dedendum;
				push @$points, [$dx,$y];
				unshift @$points, $Math->mirrorrotate([$dx,$y],($backlash/180+$pi)/$teeth);
			}
			last if $Math->distance([$x,$y]) > ($PCD/2+$Addendum);
			push @$points,[$x,$y]; 
			unshift @$points,$Math->mirrorrotate([$x,$y],($backlash/180+$pi)/$teeth);
			#if the involute arcs are going to collide...remove point and leave 
			if ($Math->angle($points->[-1])>($pi/(2*$teeth))){
				pop @$points;shift @$points;
				last;
			};
		}
		my $allPoints=[];
		for my $tNo (0..$teeth-1){
			foreach my $pt (@$points){
				push @$allPoints,$Math->rotate($pt,-2*$pi*$tNo/$teeth)
			}
		}
		
		return {points=>$allPoints,PCD=>$PCD};
	}
	
	method gear{
		my ($name,%params)=@_;
		my $profile=$self->profile(%params);
		my $th=$params{thickness}//($params{module}//2)*2;
		if ($params{type} and $params{type} !~ /spur/i){
			if ($params{type} =~ /bevel/i){
				my $bA=$params{bevelAngle}//45;
				my $scale=($profile->{PCD}-$th*$Math->tan($bA))/$profile->{PCD};
				$scad->polygon("GearMaker_outline",$profile->{points})
				     ->linear_extrude("GearMaker_gear","GearMaker_outline","$th, scale=$scale");
			}
			elsif($params{type} =~ /hrringbone|doublehelix/i){
				my $hA=$params{helixAngle}//10;
				my $hB=-$hA;
		        $scad->polygon("GearMaker_outline",$profile->{points})
		             ->linear_extrude("GearMaker_geara","GearMaker_outline","$th/2, twist=$hA")
		             ->linear_extrude("GearMaker_gearb","GearMaker_outline","$th/2, twist=$hB")
		             ->rotate("GearMaker_gearb",[0,0,$hB])
		             ->translate("GearMaker_gearb",[0,0,$th/2])
		             ->union(qw/GearMaker_gear GearMaker_geara GearMaker_gearb/);
			}
			elsif($params{type} =~ /helix/i){
		        my $hA=$params{helixAngle}//10;
		        $scad->polygon("GearMaker_outline",$profile->{points})
		             ->linear_extrude("GearMaker_gear","GearMaker_outline","$th, twist=$hA");
			}
		}
		else {
		   $scad->polygon("GearMaker_outline",$profile->{points})
		        ->linear_extrude("GearMaker_gear","GearMaker_outline",$th);
		}
		$scad->clone("GearMaker_gear",$name)
		     ->cleanUp(qr{^GearMaker_});
		     
		if ($params{bore}){
			$self->bore($name,%params);
		}  
		
		return $self;
	}
	
	method bore{  # pass a gear and create a bore, optionally keyed
		my ($name,%params)=@_;
		my $d=$params{bore}//5;
		my $h=$params{thickness}//5;
		$scad->cylinder("GearMaker_bore",{r=>$d/2,h=>$h+2})
		     ->translate("GearMaker_bore",[0,0,-1]);
		if ($params{key}){
			$scad->cube("GearMaker_key",[$d,$d,$h+4]) 
			     ->translate("GearMaker_key",[$d/4,-$d/2,-2])
			     ->difference("GearMaker_bore","GearMaker_bore","GearMaker_key")
		}
		 $scad->difference($name,$name,"GearMaker_bore")
		      ->cleanUp(qr{^GearMaker_});
		     
		
	}
	
	
	# https://drivetrainhub.com/notebooks/gears/tooling/Chapter%201%20-%20Basic%20Rack.html
	method rack{
		my ($name,%params)=@_;
		my $pi=$Math->pi;
		my $module=$params{module}//2;  #  Module
		my $teeth=$params{teeth}//20;
		my $rackWidth=$params{width}//10;
		my $rackDepth=$params{depth}//3;
		my $backlash=$params{backlash}//20;# profile shift degrees
		my $PressAngle=$params{pressure_angle}//20;
		
		my $pitch=$pi*$module;
		my $Addendum=$module;
		my $Dedendum=$Addendum*1.25;
		my $toothHeight=$Addendum+$Dedendum;
		my $tipWidth=$pitch/2-(2*$Addendum*$Math->tan($Math->deg2rad($PressAngle)));
		my $baseWidth=(2*$toothHeight*$Math->tan($Math->deg2rad($PressAngle)))+$tipWidth;
		my $scale=$tipWidth/$baseWidth;
		
		
		my $delta1=$toothHeight*($Math->tan($Math->deg2rad($PressAngle)));
		my $points=[[0,0]];
		foreach my $tooth(0..$teeth-1){
			push @$points,([$tooth*$pitch,$rackDepth],
			[$tooth*$pitch+$delta1,$rackDepth+$toothHeight],
			[$tooth*$pitch+$delta1+$tipWidth,$rackDepth+$toothHeight],
			[$tooth*$pitch+2*$delta1+$tipWidth,$rackDepth]);
		}
		push @$points,[($teeth-1)*$pitch+2*$delta1+$tipWidth,0];
		$scad->polygon("GearMaker_rackprofile",$points)
		     ->linear_extrude("GearMaker_rack","GearMaker_rackprofile",$rackWidth);
		if ($params{type} and $params{type} !~ /standard/i){
			if($params{type} =~ /herringbone|doublehelix/i){
		        my $hA=$params{helixAngle}//-25;
		        my $hB=-$hA;
				$scad->linear_extrude("GearMaker_rack1","GearMaker_rackprofile",$rackWidth/2+0.001)
				     ->skew("GearMaker_rack1",{xz=>$hA})
				     ->clone("GearMaker_rack1","GearMaker_rack2")
				     ->mirror("GearMaker_rack2",[0,0,1])
				     ->translate("GearMaker_rack2",[0,0,$rackWidth])
				     ->union("GearMaker_rack","GearMaker_rack1","GearMaker_rack2");

			}
			elsif($params{type} =~ /helix/i){
		        my $hA=$params{helixAngle}//-25;
				$scad->linear_extrude("GearMaker_rack","GearMaker_rackprofile",$rackWidth)
				     ->skew("GearMaker_rack",{xz=>$hA});
			}
		}
		else{
			$scad->linear_extrude("GearMaker_rack","GearMaker_rackprofile",$rackWidth);
		}     
		$scad->clone("GearMaker_rack",$name)
		     ->cleanUp(qr{^GearMaker_});
		
		
	}
}
