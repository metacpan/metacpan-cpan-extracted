#!/usr/bin/env perl
#
# index_cov_files.pl
#
# [ to see proper formatting set tab==2 ]
#
# 2009-2010 Victor Strelets, FlyBase.org 

##$testing= 300000;

#$debug= 1; $do_only_chr= '2L';  
#$debug= 1; $do_only_chr= '2L'; $do_only_subset= 'BS40_all_unique'; 
#$debug= 1; $do_only_subset= 'Female_Heads'; $do_only_chr= '2';

$apply_log= 0;
$log2= log(2);
%LogTabs= ( 0, 0, 1, 0 ); # for our purposes, these start values are right	
$log_magnifier= 1.0;

	if( @ARGV && $ARGV[0]=~/^\-?log/i ) { $apply_log= 1; print "applying log\n"; }
	
	print "\nIndexing COV files for use with the fb_shmiggle glyph\n";

	eval {use lib("/LS/common/system-local/perl/lib"); };
	use BerkeleyDB;

	my $filesmask= '*.cov*';
	$filemask= shift(@ARGV) if @ARGV;
	$filemask=~s/\./\\\./g;
	$filemask=~s/[\*]/\\*/g;
	indexfeatdir('./',$filesmask) ; 

	exit();

#*************************************************************************
#
#*************************************************************************

sub indexfeatdir 
{
	my($dir,$mask)= @_;

	local(*D); opendir(D, $dir) || warn "can't open $dir";
	my @files= grep( /\.(cov|wig)/i, readdir(D));
	closedir(D);
	
	my $datfilename= 'data.cat';
	system("rm $datfilename") if -e $datfilename;
	open(OUTDATF,'>'.$datfilename) || die "Cannot open $datfilename!";
	my $bdbfilename= 'index.bdbhash';
	unlink($bdbfilename) if( -e $bdbfilename );
	%ResIndexHash= (); # !!GLOBAL
	tie %ResIndexHash, "BerkeleyDB::Hash", -Filename => $bdbfilename, -Flags => DB_CREATE;

	$max_signal = 0;
	@SubsetNames= ();
	foreach my $file (sort @files) { 
		indexCoverageFile($file); # coverage files are in fact wiggle files.. 
		}
	$ResIndexHash{'subsets'}= join("\t",@SubsetNames); # record subsets, just in case..
	$ResIndexHash{'max_signal'}= $max_signal;
	my @all_keys= keys %ResIndexHash;
	foreach my $kkey ( sort @all_keys ) { print "\t$kkey => ".$ResIndexHash{$kkey}."\n"; }
	if( $max_signal>10000 ) { print "WARNING: max_signal=$max_signal - TOO HIGH!! Re-run with '-log' option\n"; } 
  untie %ResIndexHash;
	chmod(0666,$bdbfilename); # ! sometimes very important
	close(OUTDATF);

	return;
}
 
#*************************************************************************
#
#*************************************************************************

sub indexCoverageFile 
{
  my($file)= @_;
	if( $debug && defined $do_only_subset ) {
		return unless $file=~/^${do_only_subset}\./; }
	my $zcat= get_zcat($file);
	local(*INF);
	open(INF,"$zcat $file |") || die "Can't open $file";
	print "\t$file\n";
	my $SubsetName= ($file=~/^([^\.]+)\./) ? $1 : $file;
	push(@SubsetNames,$SubsetName);
  my $chromosome= "";
	my @offsets= ();
	# following setting is very important for performance (in some cases)
	# value 1000 (otherwise good) on K.White dataset was causing start of reading 100K before the actually required point..
	my $step= 1000; # step in coverage file lines ()signal reads to save start-offset
	my $coordstep= 20000; # step in coords to save start-offset
	my $counter= 0;
	my $offset= tell(OUTDATF);
	$ResIndexHash{$SubsetName}= $offset; # record offset where new subset data starts
	my $old_signal= 0;
	my $oldcoord= -200000;
	my $FileFormat= 1;
	my $StartCoord= 0;
	my $lastRecordedCoord= -200000;
	while( (my $str= <INF>) ) {
		$offset= tell(OUTDATF);

		# correct variant of GEO preferred subset spec
		if( $str=~m/^(track[ \t]+type=wiggle_0)\s*\n$/i ) { # new subset starting
			$str= $1 . ' name="' . $SubsetName ."\"\n"; }

		# following is a GEO preferred subset spec
		if( $str=~m/^track[ \t]+type=wiggle_0[ \t]+name="([^"]+)"/i ) { # new subset starting
			$FileFormat= 4;
			$SubsetName= $1;
			#$chromosome= ""; 
			next; # because it is not a signal, should not be printed in this data loop
			}

		# fix for K.White files
		elsif( $str=~m/^track[ \t]+type=bedGraph[ \t]+name="([^"]+)"/i ) { # new subset starting
			$FileFormat= 4;
			$SubsetName=~s/_(combined|coverage)$//i; $SubsetName=~s/_(combined|coverage)$//i; $SubsetName=~s/^G[A-Z]{2}\d+[_\-]//;
			#$chromosome= ""; 
			next; # because it is not a signal, should not be printed in this data loop
			}

		elsif( $str=~m/^variableStep[ \t]+(chr(om(osome)?)?|arm)=(\w+)/i ) { # potentially new arm starting
			$FileFormat= 4;
			my $new_chromosome= $4; 
			$new_chromosome=~s/^chr(omosome)?//i;
			if( $new_chromosome ne $chromosome ) {
				dumpOffsets($SubsetName.':'.$chromosome,@offsets) unless $chromosome eq ""; # previous subset:arm
				$chromosome= $new_chromosome;
				print OUTDATF "# subset=$SubsetName chromosome=$chromosome\n";
				$offset= tell(OUTDATF);
				$ResIndexHash{$SubsetName.':'.$chromosome}= $offset; # record offset where new subset:arm data starts
				@offsets= ("-200000\t$offset");
				print OUTDATF "-200000\t0\n"; # insert one fictive zero read
				$offset= tell(OUTDATF);
				print OUTDATF "0\t0\n"; # insert one more fictive zero read
				push(@offsets,"0\t$offset"); 
				print "\t\t$SubsetName:$chromosome\n";
				$counter= 0; $old_signal= 0; $oldcoord= 0; $lastRecordedCoord= 0;
				}
			next; # because it is not a signal, should not be printed in this data loop
			}

		elsif( $str=~m/^FixedStep[ \t]+(chr(om(osome)?)?|arm)=(\w+)[ \t]+Start=(\d+)/i ) { # potentially new arm starting
			$FileFormat= 3;
			my $new_chromosome= $4; 
			$StartCoord= $5;
			$new_chromosome=~s/^chr(omosome)?//i;
			if( $new_chromosome ne $chromosome ) {
				dumpOffsets($SubsetName.':'.$chromosome,@offsets) unless $chromosome eq ""; # previous subset:arm
				$chromosome= $new_chromosome;
				print OUTDATF "# subset=$SubsetName chromosome=$chromosome\n";
				$offset= tell(OUTDATF);
				$ResIndexHash{$SubsetName.':'.$chromosome}= $offset; # record offset where new subset:arm data starts
				@offsets= ("-200000\t$offset");
				print OUTDATF "-200000\t0\n"; # insert one fictive zero read
				$offset= tell(OUTDATF);
				print OUTDATF "0\t0\n"; # insert one more fictive zero read
				push(@offsets,"0\t$offset"); 
				print "\t\t$SubsetName:$chromosome\n";
				$counter= 0; $old_signal= 0; $oldcoord= 0; $lastRecordedCoord= 0;
				}
			elsif( $StartCoord>$oldcoord+1 ) { # hole, fill with zeros
				$oldcoord++; 
				#print " hole (zeros) from $oldcoord to $StartCoord-1\n" if $debug;
				print OUTDATF $oldcoord."\t0\n" unless $old_signal==0;
				$old_signal= 0;
				next if $signal==0; # no need to duplicate zeros..
				}
			elsif( $StartCoord<$oldcoord ) { print "WARNING: backward ref in $file: $str"; }
			next; # because it is not a signal, should not be printed in this data loop
			}

		elsif( $str=~m/^[#]?.*(chr(om(osome)?)?|arm)=(\w+)/ ) { # potentially new arm starting
			$FileFormat= 1;
			my $new_chromosome= $4; 
			$new_chromosome=~s/^chr(omosome)?//i;
			if( $new_chromosome ne $chromosome ) {
				dumpOffsets($SubsetName.':'.$chromosome,@offsets) unless $chromosome eq ""; # previous subset:arm
				$chromosome= $new_chromosome;
				print OUTDATF "# subset=$SubsetName chromosome=$chromosome\n";
				$offset= tell(OUTDATF);
				$ResIndexHash{$SubsetName.':'.$chromosome}= $offset; # record offset where new subset:arm data starts
				@offsets= ("-200000\t$offset");
				print OUTDATF "-200000\t0\n"; # insert one fictive zero read
				$offset= tell(OUTDATF);
				print OUTDATF "0\t0\n"; # insert one more fictive zero read
				push(@offsets,"0\t$offset"); 
				print "\t\t$SubsetName:$chromosome\n";
				$counter= 0; $old_signal= 0; $oldcoord= 0; $lastRecordedCoord= 0;
				}
			next; # because it is not a signal, should not be printed in this data loop
			}

		elsif(  $str=~m/^[#]/ ) { next; } # other unspecified comments

		elsif( $str=~m/^(\d+)[ \t]+(\d+)\s*\n/ ) { # [coord signal] format
			$FileFormat= 1;
			my($coord,$signal)= ($1,$2);
			$signal= modifySignal($signal);
			if( $signal==$old_signal ) { 
				$oldcoord= $coord;
				next;
				}
			$max_signal= $signal if $max_signal<$signal;
			if( $counter++>$step || $coord-$lastRecordedCoord>$coordstep ) { 
				push(@offsets,"$coord\t$offset"); $counter= 0; $lastRecordedCoord= $coord; }
			$str= $coord."\t".$signal."\n";
			$oldcoord= $coord;
			$old_signal= $signal;
			}

		# following is a GEO preferred format
		elsif( $str=~m/^(\w+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+[\-]?(\d+)\s*\n/ ) { # [chr coord tocoord signal] format, all positions and skipped zeros
			$FileFormat= 4;
			my($new_chromosome,$coord,$tocoord,$signal)= ($1,$2,$3,$4);
			my $samesignal_l= $tocoord-$coord;
			$new_chromosome=~s/^chr(omosome)?//i;
			if( $debug && defined $do_only_chr ) {
				next unless $new_chromosome eq $do_only_chr; }
			$signal= modifySignal($signal);
			if( $new_chromosome ne $chromosome ) {
				dumpOffsets($SubsetName.':'.$chromosome,@offsets) unless $chromosome eq ""; # previous subset:arm
				$chromosome= $new_chromosome;
				print OUTDATF "# subset=$SubsetName chromosome=$chromosome\n";
				$offset= tell(OUTDATF);
				$ResIndexHash{$SubsetName.':'.$chromosome}= $offset; # record offset where new subset:arm data starts
				@offsets= ("-200000\t$offset");
				print OUTDATF "-200000\t0\n"; # insert one fictive zero read
				$offset= tell(OUTDATF);
				print OUTDATF "0\t0\n"; # insert one more fictive zero read
				push(@offsets,"0\t$offset"); 
				print "\t\t$SubsetName:$chromosome\n";
				$counter= 0; $old_signal= 0; $oldcoord= 0; $lastRecordedCoord= 0;
				}
			if( $coord>$oldcoord+1 ) { # hole, fill with zeros
				$oldcoord++; 
				#print " hole (zeros) from $oldcoord to $coord-1\n" if $debug;
				print OUTDATF $oldcoord."\t0\n" unless $old_signal==0;
				$old_signal= 0;
				next if $signal==0; # no need to duplicate zeros..
				}
			elsif( $signal==$old_signal ) { 
				$oldcoord= $coord;
				next;
				}
			$max_signal= $signal if $max_signal<$signal;
			if( $counter++>$step || $coord-$lastRecordedCoord>$coordstep ) { 
				push(@offsets,"$coord\t$offset"); $counter= 0; $lastRecordedCoord= $coord; }
			$str= $coord."\t".$signal."\n";
			$oldcoord= $coord+$samesignal_l-1;
			$old_signal= $signal;
			}

		elsif( $str=~m/^(\w+)[ \t]+(\d+)[ \t]+(\d+)\s*\n/ ) { # [chr coord signal] format, all positions but skipped zeros
			$FileFormat= 2;
			my($new_chromosome,$coord,$signal)= ($1,$2,$3);
			$new_chromosome=~s/^chr(omosome)?//i;
			if( $debug && defined $do_only_chr ) {
				next unless $new_chromosome eq $do_only_chr; }
			$signal= modifySignal($signal);
			if( $new_chromosome ne $chromosome ) {
				dumpOffsets($SubsetName.':'.$chromosome,@offsets) unless $chromosome eq ""; # previous subset:arm
				$chromosome= $new_chromosome;
				print OUTDATF "# subset=$SubsetName chromosome=$chromosome\n";
				$offset= tell(OUTDATF);
				$ResIndexHash{$SubsetName.':'.$chromosome}= $offset; # record offset where new subset:arm data starts
				@offsets= ("-200000\t$offset");
				print OUTDATF "-200000\t0\n"; # insert one fictive zero read
				$offset= tell(OUTDATF);
				print OUTDATF "0\t0\n"; # insert one more fictive zero read
				push(@offsets,"0\t$offset"); 
				print "\t\t$SubsetName:$chromosome\n";
				$counter= 0; $old_signal= 0; $oldcoord= 0; $lastRecordedCoord= 0;
				}
			if( $coord>$oldcoord+1 ) { # hole, fill with zeros
				$oldcoord++; 
				#print " hole (zeros) from $oldcoord to $coord-1\n" if $debug;
				print OUTDATF $oldcoord."\t0\n" unless $old_signal==0;
				$old_signal= 0;
				next if $signal==0; # no need to duplicate zeros..
				}
			elsif( $signal==$old_signal ) { 
				$oldcoord= $coord;
				next;
				}
			$max_signal= $signal if $max_signal<$signal;
			if( $counter++>$step || $coord-$lastRecordedCoord>$coordstep ) { 
				push(@offsets,"$coord\t$offset"); $counter= 0; $lastRecordedCoord= $coord; }
			$str= $coord."\t".$signal."\n";
			$oldcoord= $coord;
			$old_signal= $signal;
			}

		elsif( $str=~m/^(\d+)\s*\n/ ) { # [signal] format, all positions and skipped zeros
			$FileFormat= 3;
			my($coord,$signal)= ($StartCoord++,$1);
			$signal= modifySignal($signal);
			if( $signal==$old_signal ) { 
				$oldcoord= $coord;
				next;
				}
			$max_signal= $signal if $max_signal<$signal;
			if( $counter++>$step || $coord-$lastRecordedCoord>$coordstep ) { 
				push(@offsets,"$coord\t$offset"); $counter= 0; $lastRecordedCoord= $coord; }
			$str= $coord."\t".$signal."\n";
			$oldcoord= $coord;
			$old_signal= $signal;
			}

		else { next; } # skip other data - unknown format
		print OUTDATF $str;
		}
	# don't forget to dump offsets data on file end..
	dumpOffsets($SubsetName.':'.$chromosome,@offsets) unless $chromosome eq ""; # previous subset:arm
	close(INF);
  return;
}

#*************************************************************************
#
#*************************************************************************

sub modifySignal
{
	my $signal= shift;
	return($signal) unless $apply_log;
	if( exists $LogTabs{$signal} ) { $signal= $LogTabs{$signal}; }
	else {
		my $newval= int(log($signal)*$log_magnifier/$log2); # make it larger (magnification)
		$LogTabs{$signal}= $newval;
		$signal= $newval;
		}
	return($signal);
}

#*************************************************************************
#
#*************************************************************************

sub dumpOffsets
{
	my($key,@offsetlines)= @_;
	print OUTDATF "# offsets for $key\n";
	my $offset= tell(OUTDATF);
	my $prevoffset= $offset;
	$ResIndexHash{$key.':offsets'}= $offset; # record offset where offsets VALUES for subset:arm data start (skip header)
	my $oldbigstep= 0;
	foreach my $str ( @offsetlines ) {
		print OUTDATF $str . "\n"; 
		my($coord,$floffset)= split(/[ \t]+/,$str);
		# following wasn't working properly..
		my $newbigstep= int($coord/1000000.0);
		if( $newbigstep>$oldbigstep ) {
			$ResIndexHash{$key.':offsets:'.$newbigstep}= $prevoffset; # one before is the right start
			$oldbigstep= $newbigstep;
			}
		$prevoffset= $offset;
		$offset= tell(OUTDATF);
		}
	return;
}

#***********************************************************
#
#***********************************************************

sub get_zcat {
	my $fullfile= shift; 
  if( $fullfile=~/\.gz$/i ) {
  	my $zcat= `which zcat`;
  	if( $? != 0 ) { $zcat=`which gzcat`; }
		chomp($zcat);
		return($zcat);
		}
  elsif( $fullfile=~/\.bz2$/i ) { return('bzcat'); }
  return('/bin/cat'); 
}

#***********************************************************
#
#***********************************************************

