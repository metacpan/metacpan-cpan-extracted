use strict;
use warnings;
use Test::More tests => 1;
use File::Spec;
use File::Basename qw( dirname );
use Alien::MSYS qw( msys msys_path );
use FindBin ();
use File::Spec;

my $preinstall_path = File::Spec->catdir($FindBin::Bin, File::Spec->updir, qw( share msys 1.0 bin));

if(! defined $ENV{PERL_ALIEN_MSYS_BIN} && -d $preinstall_path)
{
  $ENV{PERL_ALIEN_MSYS_BIN} ||= $preinstall_path;
}

# http://www.gnu.org/software/gettext/manual/html_node/config_002eguess.html
# wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'

my $path = File::Spec->catfile(dirname(__FILE__), 'config.guess');
my $guess = msys { `sh $path` };

is $?, 0, 'ran okay';

diag '';
diag '';
diag '';
diag 'msys_path    = ' . (defined msys_path() ? msys_path() : 'undef');
diag 'config.guess = ' . $path;
diag 'guess        = ' . $guess;
diag 'uname        = ' . msys { `uname -a` };
diag '';
diag '';
