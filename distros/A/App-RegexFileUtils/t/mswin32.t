use Test2::V0 -no_srand => 1;
use App::RegexFileUtils;

skip_all 'only test on MSWin32' unless $^O eq 'MSWin32';

my $dir = App::RegexFileUtils->_share_dir;
ok -d $dir, "dir = $dir";

foreach my $cmd (qw( cp rm touch mv ))
{
  ok -e "$dir/ppt/$cmd.pl", "$dir/ppt/$cmd.pl";
}

done_testing;
