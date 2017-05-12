#!/tmp/perl5

use Getopt::Std 'getopts';
use Config '%Config';

@MMargs = qw(
	PERL_SRC=~/xlib/Perl5
	PERL=~/bin/perl5
	INST_ARCHLIB=~/usr/lib/perl5
	INST_LIB=~/usr/lib/perl5
	INST_EXE=~/bin
	INST_SCRIPT=~/bin
	INST_MAN3DIR=~/usr/lib/perl5/pod
	INST_MAN1DIR=~/usr/lib/perl5/pod
	INSTALLDIRS=perl
) if( ($ENV{LOGNAME} eq 'roehrich') && ($Config{osname} eq 'solaris'));


getopts( 'f:Cce:T' );
# -C	  all C++ examples
# -c	  all C examples
# -e ex	  only example <ex>
# -f ex   begin at example <ex>, do everything from that point and on
# -T	  print list, but don't run them

@C = qw( Ex1 Ex2 Ex3 Ex4 Ex5 Ex6 Ex8 Ex_SDV );
@CC = qw( Ex7 );
@all = (@C,@CC);

if( defined $opt_c ){
	@all = @C;
}
elsif( defined $opt_C ){
	@all = @CC;
}
elsif( defined $opt_e ){
	@all = split( ' ', $opt_e );
}

if( defined $opt_f ){
	my @tmp = ();
	my $on = 0;
	while( @all ){
		$_ = shift @all;
		if( $on ){
			push @tmp, $_;
		}
		if( $_ eq $opt_f ){
			$on++;
			push @tmp, $_;
		}
	}
	@all = @tmp;
}


if( defined $opt_T ){
	print "all=(", join(",", @all), ")\n";
	exit(0);
}


$args = join( " ", @MMargs );
$PLcmd = "perl5 Makefile.PL $args";

foreach (@all){
	chdir( $_ ) || die;
	myrun( $PLcmd );
	myrun( 'make' );
	myrun( 'make test' );
	myrun( 'make realclean' );
	unlink( 'perl' ) if -f 'perl';
	chdir( '..' );
}


sub myrun {
	my $cmd = shift;

	system $cmd;
	if( ($? / 256) > 0 ){
		die "failed with status ", ($? / 256), "";
	}
}
