package ARS::CodeTemplate;
use Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( include modByRegex );


*opt = *main::opt;
#our $LINE_INDENT = ''; 


sub compile {
	my( $input ) = @_;

	my @input = split( /\n/, $input );
	my( $pFlag, $pCode, $output ) = ( 0, '', '' );
	my $line;

	foreach $line ( @input ){
		if( $line =~ /^@@\s+(\S+)\s+(.*)$/ ){
			my( $openMode, $outFile ) = ( $1, $2 );
			if( $outFile =~ /^<@(.*)@>\s*$/ ){
				eval( 'package '.caller()."; \$outFile = $1; package ARS::CodeTemplate;" );
#				print "OUTFILE: $outFile\n";
			}
#			print "OM($openMode) FILE($outFile)\n";
			die "Syntax error in \"$line\"\n" unless $openMode =~ /^[>|]+$/;
			if( defined $opt{debug} ){
				print "#------------------------------------------------------------\n";
				print "# OUTPUT:  $line\n";
				print $pCode;
				print "#------------------------------------------------------------\n\n";
			}else{
				eval( 'package '.caller()."; $pCode; package ARWT::Template;" );
				if( $@ ){
					warn $@, "\n";
					exit 1;
				}
				open( OUTPUT, "$openMode $outFile" ) or die "Open Error($openMode $outFile): $!\n";
				print OUTPUT $output;
				close OUTPUT;
			}
			( $pFlag, $pCode, $output ) = ( 0, '', '' );
		}elsif( $line =~ s/^@>+// ){
			$pCode .= "$line\n";
		}else{
			$pCode .= '$output .= $LINE_INDENT;';
			$pCode .= '$output .= ';
			$pCode .= "'' . \"\\n\";\n" if $line eq '';
			while( $line ){
				if( $pFlag ){
					if( $line =~ s/^(.*?)@>// ){
						$pFlag = 0;
						$pCode .= "$1 ). ";
						$pCode .= "\"\\n\";\n" unless $line;
					}else{
						$pCode .= $line . "\\n";
						$line = '';
					}
				}else{
					if( $line =~ s/^(.*?)<@// ){
						$pFlag = 1;
						my $str = $1;
						$str =~ s/\\/\\\\/g;
						$str =~ s/'/\\'/g;
						$pCode .= "'$str' .( ";
					}else{
						$line =~ s/\\/\\\\/g;
						$line =~ s/'/\\'/g;
						$pCode .= "'$line' . \"\\n\";\n";
						$line = '';
					}
				}
			}
		}
	}

	if( defined $opt{debug} ){
		print $pCode;
		exit;
	}else{
		eval( 'package '.caller()."; $pCode; package ARWT::Template;" );
		if( $@ ){
			warn $@, "\n";
			exit 1;
		}
	}
	return $output;
}


use Getopt::Long;



sub init_template {
	%opt = ();
	Getopt::Long::Configure( 'no_ignore_case' );
	Getopt::Long::GetOptions( \%opt, 'o=s', 'x!', 'debug!', @_ );
}

sub procdef {
	my( $text ) = @_;
	my $outfile;
	if( defined $opt{'o'} ){
		$outfile = $opt{'o'};
	}else{
		$outfile = '-';
	}
	open( OUTFILE, ">$outfile" ) or die "$outfile: $!\n";
	print OUTFILE get_header( $outfile, $0 ) if $opt{'o'};
	print OUTFILE $text;
	close OUTFILE;
}

sub include {
	my( $file ) = @_;

	local $/ = undef;
	local *FILE;
	open( FILE, $file ) or do {
		warn "Cannot open \"$file\": $!\n";
		return undef;
	};
	my $data = <FILE>;
	close FILE;
	return $data;
}

sub modByRegex {
	package main;
	my( $val, @regex ) = @_;
	foreach my $regex ( @regex ){
		eval "\$val =~ $regex";
		warn $@, "\n" if $@;
	}
	return $val;
}


sub get_header {
	my( $of, $tpt ) = @_;

my $HEADER = << "+";
/*******************************************************************************
**                                                                            **
**               Automatically genenerated <OUTFILE> file.
**                      D O   N O T   E D I T  ! ! ! !                        **
**               Edit <TEMPLATE> instead.
**                                                                            **
*******************************************************************************/
+

	my @HEADER = split( /\n/, $HEADER );
	$HEADER = '';
	$of  =~ s|.*[\\/]||;
	$tpt =~ s|.*[\\/]||;
	foreach $line ( @HEADER ){
		if( $line =~ s/<OUTFILE>/$of/ || $line =~ s/<TEMPLATE>/$tpt/ ){
			$line .= ' ' x (78 - length($line)) . '*/';
		}
		$HEADER .= "$line\n";
	}
	return $HEADER;
}


1;

