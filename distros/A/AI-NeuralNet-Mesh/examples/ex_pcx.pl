=begin
	
	File:   examplex/ex_pcx.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
	Desc:
		This teaches the network to classify 
		10x10 bitmaps from a PCX file based on their 
		whiteness. (This was taught on a b&w 320x200 
		PCX of the author at an early age :-)
=cut
	
	use AI::NeuralNet::Mesh;
	
	# Set block sizes
	my ($bx,$by)=(10,10);
	
	print "Creating Neural Net...";
	my $net=AI::NeuralNet::Mesh->new(1,$bx*$by,1);
	$net->{col_width} = $bx;
	print "Done!\n";
	
	print "Loading bitmap...";
	my $img = $net->load_pcx("josiah.pcx");             
	print "Done!\n";
	
	print "Comparing blocks...\n";
	my $white = $img->get_block([0,0,$bx,$by]);
	
	my ($x,$y,$tmp,@scores,$s,@blocks,$b);
	for ($x=0;$x<320;$x+=$bx) {
		for ($y=0;$y<200;$y+=$by) {
			$blocks[$b++]=$img->get_block([$x,$y,$x+$bx,$y+$by]);
			$score[$s++]=$net->pdiff($white,$blocks[$b-1]);
			print "Block at [$x,$y], index [$s] scored ".$score[$s-1]."%\n";
		}
	}
	print "Done!";
	
	print "High score:\n";
	print_ref($blocks[$net->high(\@score)],$bx); 
	print "Low score:\n";
	print_ref($blocks[$net->low(\@score)],$bx); 
	
	$net->debug(4);
	
	if(!$net->load("pcx.mesh")) {
		print "Learning high block...\n";
		print $net->learn($blocks[$net->high(\@score)],"highest");
		
		$net->save("pcx.mesh");
		
		print "Learning low block...\n";
		$net->learn($blocks[$net->low(\@score)],"lowest");
	}
	
	print "Testing random block...\n";
	
	print "Result: ",$net->run($blocks[rand()*$b])->[0],"\n";
	
	print "Bencmark for run: ", $net->benchmarked(), "\n";
	
	$net->save("pcx2.net");
	
	sub print_ref {
		no strict 'refs';
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $map		=	shift;
		my $break   =	shift;
		my $x;
		my @els = (' ','.',',',':',';','%','#');
		foreach my $el (@{$map}) { 
			$str=$el/255*6;
			print $els[$str];
			$x++;
			if($x>$break-1) {
				print "\n";
				$x=0;
			}
		}
		print "\n";
	}
		                                         