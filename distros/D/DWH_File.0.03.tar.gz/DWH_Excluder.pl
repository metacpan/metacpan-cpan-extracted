#!/usr/bin/perl
#
# Excluder script verision 0.1
#
# When running DWH_File form a remote site (eg. in CGI scripts) this
# make this script setuid and use "muEx: fork" in the DWH_Config. Thus it
# can be avoided that all scripts using DWH_File need to be setuid.
#
# Don't run this script or make it available to users. It shouldn't be
# possible to do any damage with it, but it's utterly useless on it's own
#
# Used by DWH_File with three command line arguments:
#  the PID of the script wishing to lock a file
#  the name of the file to lock
#  the permissions desired (O_RDONLY, O_RDWR, O_CREAT, O_WRONLY)
#
# Jakob Schmidt <sumus@aut.dk> 1999 nov 24
# Visit http://aut.dk/orqwood/dwh for complete info on DWH_File and
# it's accomplices

use Fcntl; # for O_* constants

( $pid, $file, $fc ) = @ARGV;

# if write lock exists no lock can be granted
opendir DIR, ".";
my $i;
my @locks;
for ( $i = 1 ; $i <= 10 ; $i++ )
{
    rewinddir DIR;
    @locks = grep /^W_.+_$file/, readdir DIR;
    @locks or last;
    sleep 1;
}
@locks and &_PurgeLocks( \@locks );
@locks and die "Previous write locks pending";


if ( $fc & O_WRONLY or $fc & O_RDWR )
{
    # write lock needed

    $file =~ /[^\/]+$/; # match all chars from after the last slash
    $lock = $` . "W_" . $$ . "_$&";
    link( $file, $lock ) or die "Write lock denied, link failed: $!";

    for ( $i = 1 ; $i <= 10 ; $i++ )
    {
	rewinddir DIR;
	@locks = grep /^R_.+_$file/, readdir DIR;
	@locks or last;
	sleep 1;
    }
    @locks and &_PurgeLocks( \@locks );
    @locks and die "Previous locks pending";

    # check that the link count is 2
    open( STAT, "stat $file |" ) or die "Couldn't stat $file: $!";
    my $links;
    while ( <STAT> ) { ( $links ) = /Links: +(\d+)/ and last }
    close STAT;
    if ( $links != 2 ) { die "Link count on $file is $links. Should be 2" }

    # acknowledge
    print $lock;
}
else
{
    # read lock needed

    $lock = "R_" . $$ . "_$file";
    link( $file, $lock ) or die "Read lock denied, link failed: $!";
    print $lock;
}

sub _PurgeLocks
{
    # make sure that locks' processes are alive
    my $locksref = shift;

    my $i = 0;
    for ( @$locksref )
    {
	/[WR]_(\d+)_/;
	my $lpid = $1;
	my @ps = `ps c $2`;
	# remove the lock if the embedded pid doesn't match a perly process
	unless ( $ps[ 1 ] =~ /\bperl\b/ )
	{
	    if ( unlink $_ )  { undef $_ }
	    else { warn "couldn't unlink lock file: $_" }
	}
    }
    @$locksref = grep defined, @$locksref;
}

