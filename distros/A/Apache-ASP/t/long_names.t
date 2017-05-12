
use Apache::ASP::CGI;
use File::Basename qw(dirname);
use strict;
use Cwd;

# we build the long directory structure ourselves, and not
# include it in the distribution because some tar programs
# like Archive::Tar and solaris tar do not deal with long path
# names very well
# --jc 7/3/2002

# make sure we are building the files in the test directory

my $cwd = cwd();
dirname($0) && chdir(dirname($0));

my $long_dir_name = 'long_directory_path_test';
my @long_dirs;
for(1..6) {
    push(@long_dirs, $long_dir_name);
    my $curr_dir = join('/', @long_dirs);
    next if -e $curr_dir;
    my $old_umask = umask(0000);
    mkdir($curr_dir, 0755) || die("can't mkdir for $curr_dir: $!");
    umask($old_umask);
}	  	  
my $long_dir = join('/', @long_dirs);
length($long_dir) > 100 or die("$long_dir is not longer than 100");
-d $long_dir || die("$long_dir does not exist");

open(FILE, ">$long_dir/ok.inc") || die("can't write to $long_dir/ok.inc");
print FILE "1..1\nok\n";
close FILE;

$main::LONG_FILE = "$long_dir/ok.inc";
-e $main::LONG_FILE || die("main::LONG_FILE does not exist\n");
chdir($cwd);

&Apache::ASP::CGI::do_self(
			   NoState => 1, 
			   Global => $long_dir,
			   Debug => 0,
			   );

__END__

<% $Response->Include("$main::LONG_FILE"); %>
