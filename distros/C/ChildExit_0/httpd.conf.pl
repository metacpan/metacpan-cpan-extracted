$WWWHOME = $ARGV[0] or die ;
	
$HTTPD_BIN = "$WWWHOME/bin/httpd" ;
$HTTPD_CONF = "$WWWHOME/conf/httpd.conf" ;

my @newcode = map { "$_\n" } split /\n/, <<EOF ;

<IfModule mod_perl.c>
    PerlChildExitHandler Apache::ChildExit
</IfModule>
EOF

my $fh = do { local *FH ; } ;


while (1) {
	print "\nAutomatically update httpd.conf [y/n]? " ;
	my $r = <STDIN> ;
	
	exit 0 if $r =~ /^n/i ;
	last if $r =~ /^y/i ;
	}

unless ( -f $HTTPD_BIN ) {
	print STDERR "Cannot locate file $HTTPD_BIN", "\n" ;
	exit 1 ;
	}

unless ( grep /mod_perl\.c/, `$HTTPD_BIN -l` ) {
	print STDERR "$HTTPD_BIN is not built with mod_perl", "\n" ;
	exit 1 ;
	}

unless ( -f $HTTPD_CONF && open( $fh, $HTTPD_CONF ) ) {
	print STDERR "$HTTPD_CONF is unreadable", "\n" ;
	exit 1 ;
	}

my @fh = <$fh> ;
close $fh ;


foreach ( grep $fh[$_] =~ /PerlChildExitHandler/i, 0 .. $#fh ) {
	my $t = $fh[$_] ;
	$t =~ s/PerlChildExitHandler.*// ;
	next if $t =~ /#/ ;

	print STDERR "$HTTPD_CONF already contains a PerlChildExitHandler directive:", "\n" ;
	printf STDERR "\t(line %d)  %s\n", $_ +1, $fh[$_] ;
	exit 0 ;
	}

my @ifconfig = grep( $fh[$_] =~ /<\s*ifmodule\s.*>/i, 0 .. $#fh ) ;
my @unifconfig = grep( $fh[$_] =~ /<\s*\/ifmodule.*>/i, 0 .. $#fh ) ;

unless ( @ifconfig && @unifconfig ) {
	print STDERR "Trouble parsing $HTTPD_CONF", "\n" ;
	print STDERR "Please edit this file manually", "\n" ;
	exit 0 ;
	}

my %ifconfig = sort { $a <=> $b } @ifconfig,
		grep( $fh[$_] =~ /<\s*\/ifmodule.*>/i, 0 .. $#fh ) ;

if ( my @t = grep $fh[$_] =~ /mod_perl\.c/, @ifconfig ) {
	splice @fh, $ifconfig{ $t[0] }, 0, @newcode[2] ;
	}
else {
	splice @fh, $ifconfig{ $ifconfig[0] } +1, 0, @newcode ;
	}

unless ( rename $HTTPD_CONF, "${HTTPD_CONF}." . time ) {
	print STDERR "Cannot replace $HTTPD_CONF", "\n" ;
	exit 1 ;
	}

open $fh, "> $HTTPD_CONF" or die "Error writing $HTTPD_CONF" ;
print $fh @fh ;
close $fh ;

exit 0 ;
