#!perl 

use strict;
use warnings;

use lib qw(../lib);
use Confluence::Client::XMLRPC;

my ( $url, $user, $pass, $spaceKey, $directory ) = @ARGV;

die "Usage is $0 <url> <user> <password> <spacekey> <directoryname>\n"
	unless ( ( defined $url and $url =~ /\Ahttp/ )
	and ( defined $user      and $user )
	and ( defined $pass      and $pass )
	and ( defined $spaceKey  and $spaceKey )
	and ( defined $directory and -d $directory ) );

my $wiki = Confluence::Client::XMLRPC->new( $url, $user, $pass );

opendir( my $dir, $directory ) or die "Unable to access directory $directory : $!";

chdir($directory) or die "Unable to chdir to $directory";

while ( my $filename = readdir $dir ) {
	next unless -f $filename;
	my $title = $filename;
	$title =~ s/\.\w\w\w$//;    # remove filename extension (.xxx)
	                            # read in the file
	open( my $file, '<', $filename ) or die "Unable to open file $filename : $1";
	my $content = join "", <$file>;

	# create the page object
	my $newPage = { space => $spaceKey, title => $title, content => $content };
	print "loading $title\n";
	$wiki->updatePage($newPage);
}

$wiki->logout();
