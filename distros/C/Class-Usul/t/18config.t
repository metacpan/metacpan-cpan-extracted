use t::boilerplate;

use Test::More;
use Class::Usul::Functions qw( emit is_member list_attr_of );
use Scalar::Util qw( blessed );

use_ok 'Class::Usul::Config::Programs';

my $osname = lc $^O;
my $conf   = Class::Usul::Config::Programs->new
   (  appclass => 'Class::Usul', tempdir => 't', );

is $conf->appclass, 'Class::Usul', 'Config appclass';
$conf->cfgfiles;
$conf->binsdir;
$conf->logsdir;
is $conf->phase, 2, 'Config phase';
is $conf->root, 't', 'Config root';
is $conf->rundir, 't', 'Config rundir';
is $conf->sessdir, 't', 'Config sessdir';
is $conf->sharedir, 't', 'Config sharedir';
is $conf->owner, 'usul', 'Config owner';

$osname ne 'mswin32' and $osname ne 'cygwin'
   and is blessed $conf->shell, 'File::DataClass::IO', 'Shell is io object';

like $conf->suid, qr{ \Qusul-admin\E \z }mx, 'Default suid' ;

is $conf->datadir->name, 't', 'Default datadir';

SKIP: {
   ($osname ne 'mswin32' and $osname ne 'cygwin')
      or skip 'No shell on mswin32', 1;

   my @attr = map { $_->[ 0 ] } list_attr_of( $conf );

   ok is_member( 'appclass', @attr ), 'Lists attributes';
}

$conf->logfile->exists and $conf->logfile->unlink;

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
