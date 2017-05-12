use strict;
use utf8;

use FindBin;
use File::Find;
use ExtUtils::MakeMaker;
use Config;

$| = 1;

my $cassandra_h_dir         = "/usr/local/include";
my $cassandra_h_file_path   = '';

my $cassandra_lib_dir       = undef;
my $cassandra_file_path     = '';

my $cassandra_lib_test_rgx  = '^libcassandra(:?\.a|\.dylib|\.so|_static\.a|\.dll)';
my $cassandra_hdr_test_rgx  = '^cassandra.h$';

my @dirs_header = split /\s+/, $Config{locincpth};
push @dirs_header, "/usr/local/include", "/usr/include";
push @dirs_header, "/opt/local/include", "/opt/include";

my @dirs_lib = split /\s+/, $Config{libpth};
push @dirs_lib, "/usr/local/lib", "/usr/lib";
push @dirs_lib, "/opt/local/lib", "/opt/lib";
push @dirs_lib, "/usr/local/lib64", "/usr/lib64";
push @dirs_lib, "/opt/local/lib64", "/opt/lib64";

($cassandra_lib_dir, $cassandra_file_path) = check_cass_exists(\@dirs_lib, $cassandra_lib_test_rgx);
unless($cassandra_file_path)
{
	
	warn "Warning: libcassandra not found\n";
}
else
{
	print "Found libcassandra in $cassandra_lib_dir\n";
}


($cassandra_h_dir, $cassandra_h_file_path) = check_cass_exists(\@dirs_header, $cassandra_hdr_test_rgx);
unless($cassandra_h_file_path)
{
	
	warn "Warning: cassandra.h not found\n";
}
else
{
	print "Found cassandra.h in $cassandra_h_dir\n";
}

WriteMakefile(
    AUTHOR         => 'Alexander Borisov <lex.borisov@gmail.com>',
    ABSTRACT_FROM  => 'Client.pm',
    VERSION_FROM   => 'Client.pm',
    NAME           => 'Database::Cassandra::Client',
    LICENSE        => 'perl',
    LINKTYPE       => 'dynamic',
    LIBS           => ["-L$cassandra_lib_dir -lcassandra -lpthread"],
    INC            => '-I'. $cassandra_h_dir
);

sub check_cass_exists {
	my ($dirs, $rgx) = @_;
	
	my $full = '';
	my $exdir;
	
	foreach my $dir_root (@$dirs)
	{
		next unless -d $dir_root;
		
		find({ wanted => sub
		{
			if($exdir || $File::Find::dir ne $dir_root)
			{
				$File::Find::prune = 1;
				return;
			}
			
			if($_ =~ /$rgx/)
			{
				$full = join("/", $dir_root, $_);
				$exdir   = $dir_root;
				$File::Find::prune   = 1;
			}
		},
		no_chdir => 0 }, $dir_root);
		
		last if $exdir;
	}
	
	($exdir, $full);
}

