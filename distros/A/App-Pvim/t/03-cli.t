use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
my $pvim="$FindBin::Bin/../pvim";
my $dir=tempdir(CLEANUP=>1);
# Redirect real descriptors so subprocess capture works on older Windows Perl too.
sub invoke {
    my (@args)=@_;
    open my $input,'<',File::Spec->devnull or die $!;
    open my $output,'+>',"$dir/stdout" or die $!;
    open my $errors,'+>',"$dir/stderr" or die $!;
    my ($saved_in,$saved_out,$saved_err);
    open $saved_in,'<&',\*STDIN or die $!;
    open $saved_out,'>&',\*STDOUT or die $!;
    open $saved_err,'>&',\*STDERR or die $!;
    open STDIN,'<&',$input or die $!;
    open STDOUT,'>&',$output or die $!;
    open STDERR,'>&',$errors or die $!;
    my $status=system($^X,$pvim,@args);
    open STDIN,'<&',$saved_in or die $!;
    open STDOUT,'>&',$saved_out or die $!;
    open STDERR,'>&',$saved_err or die $!;
    seek($output,0,0) or die $!; seek($errors,0,0) or die $!;
    local $/;
    return ($status,scalar <$output>,scalar <$errors>);
}
sub exit_status { my ($status)=invoke(@_); return $status }
my $file=File::Spec->catfile($dir,'file with spaces.pl');
open my $f,'>',$file or die $!; print {$f} "old old\n"; close $f;
is(exit_status('--batch','-c','%s/old/new/g','-c','w',$file),0,'batch editing process');
open $f,'<',$file or die $!; is(<$f>,"new new\n",'batch saved result'); close $f;
is(exit_status('--batch','-c','s/new/unsaved/',$file),0,'batch without write succeeds');
open $f,'<',$file or die $!; is(<$f>,"new new\n",'batch never implicitly writes'); close $f;
my ($bad_status,$bad_out,$bad_err)=invoke('--batch','-c','s/[/bad/',$file);
ok($bad_status!=0,'invalid command nonzero');
like($bad_err,qr/Invalid regex:/,'invalid regex diagnostic');
is($bad_out,'','invalid regex has no stdout');
is(exit_status('--version'),0,'version');
is(exit_status('-v'),0,'short version flag exits without a tty');
require $pvim;
my @banners;
for my $option ('-v','--version') {
    my $banner=''; my $status;
    { local *STDOUT; open STDOUT,'>',\$banner or die $!; $status=main::run($option) }
    is($status,0,"$option returns success"); push @banners,$banner;
}
is($banners[0],$banners[1],'short and long version output are identical');
like($banners[0],qr/^pvim \Q$main::VERSION\E \(Perl [^)]+\)\n$/, 'version output contains editor and interpreter versions');
is(exit_status('--help'),0,'help');
is(exit_status('--manual'),0,'manual without perldoc');
my ($tty_status,$tty_out,$tty_err)=invoke($file);
ok($tty_status!=0,'no tty rejected');
like($tty_err,qr/Interactive mode requires a POSIX tty/,'no tty diagnostic');
is($tty_out,'','no terminal escapes or output without a tty');
done_testing;
