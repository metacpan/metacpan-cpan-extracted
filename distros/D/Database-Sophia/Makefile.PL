use strict;
use utf8;

use File::Fetch;
use Archive::Extract;

use FindBin;
use ExtUtils::MakeMaker;

my $sophia     = $FindBin::Bin ."/Sophia-src";
my $sophia_src = "$sophia/db";

my $rc = eval
{
	require 5.010;
	Term::ReadKey->import();
	1;
};

if($rc)
{
	eval {
		my $ff = File::Fetch->new(uri => "http://github.com/pmwkaa/sophia/archive/v1.1.zip");
		
		if(my $file = $ff->fetch())
		{
			my $ae = Archive::Extract->new( archive => $file );
			if($ae->extract( to => '.' ))
			{
				$sophia     = $FindBin::Bin ."/sophia-1.1";
				$sophia_src = "$sophia/db";
			}
		}
	};
}

`make -C $sophia_src libsophia.a`;


WriteMakefile(
    AUTHOR         => 'Alexander Borisov <lex.borisov@gmail.com>',
    ABSTRACT_FROM  => 'Sophia.pm',
    VERSION_FROM   => 'Sophia.pm',
    NAME           => 'Database::Sophia',
    LICENSE        => 'perl',
    LINKTYPE       => 'dynamic',
    LIBS           => ["-L$sophia_src -lsophia -lpthread"],
    INC            => '-I'. $sophia_src
);


