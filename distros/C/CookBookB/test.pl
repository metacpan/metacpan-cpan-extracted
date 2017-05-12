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


getopts( 'e:' );
# -e ex	  only example <ex>

@XS = qw( Struct1 Opaque ArrayOfStruct ListOfStruct Mstruct
	  Struct2 Struct3 CCsimple );

@all = @XS;
if( defined $opt_e ){
	@all = split( ' ', $opt_e );
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
