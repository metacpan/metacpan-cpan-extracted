# ABSTRACT: dbioadmin and dbiogen take the password by --password-env and --password-stdin (karr k392)
use strict;
use warnings;

use Test::More;
use File::Temp ();
use IPC::Open3 ();
use Symbol ();

use DBIO::Util qw(file_path mkpath write_file slurp_file);

# The password of the command line is not an argument (ps and the shell
# history show those). Both tools take it from an environment variable
# (--password-env VAR) or one line of STDIN (--password-stdin) and hand it to
# the connect as the password. The connect itself is a stub that records what
# it was called with: a DBD for dbiogen, a schema class for dbioadmin.

my $lib = File::Temp->newdir;
my $rec = file_path($lib->dirname, 'recorded');
mkpath(file_path($lib->dirname, $_)) for qw(DBD K392);

write_file(file_path($lib->dirname, 'DBD', 'K392Rec.pm'), <<'PM');
package DBD::K392Rec;
use strict;
use warnings;
use DBI ();
our $drh;
sub driver { $drh ||= DBI::_new_drh("$_[0]::dr", { Name => 'K392Rec', Version => '0.01' }) }
package DBD::K392Rec::dr;
our $imp_data_size = 0;
sub connect {
  my ($drh, $dsn, $user, $auth) = @_;
  open my $fh, '>', $ENV{K392_RECORD} or die $!;
  print {$fh} join("\t", map { $_ // '<undef>' } $dsn, $user, $auth), "\n";
  close $fh;
  $drh->set_err(1, 'refused');
  return;
}
package DBD::K392Rec::db; our $imp_data_size = 0;
package DBD::K392Rec::st; our $imp_data_size = 0;
1;
PM

write_file(file_path($lib->dirname, 'K392', 'Schema.pm'), <<'PM');
package K392::Schema;
use strict;
use warnings;
sub connect {
  my ($class, @args) = @_;
  open my $fh, '>', $ENV{K392_RECORD} or die $!;
  print {$fh} join("\t", map { ref $_ eq 'HASH' ? do { my $h = $_; join(',', map { "$_=$h->{$_}" } sort keys %$h) } : $_ // '<undef>' } @args), "\n";
  close $fh;
  die "stubbed connect\n";
}
1;
PM

# An argument with a double quote in it (the JSON of --connect) does not
# survive the command line of every OS: Windows hands a program the line as one
# string and its parser takes the quotes for its own. Such a call goes through a
# launcher that has the arguments from a file, one per line, and runs the tool
# as its script; everything the tool does after that is its own.
write_file(file_path($lib->dirname, 'launch.pl'), <<'PL');
use strict;
use warnings;
use File::Spec;
open my $fh, '<', $ENV{K392_ARGS} or die "K392_ARGS: $!";
chomp(my @args = <$fh>);
close $fh;
my $script = File::Spec->rel2abs(shift @args);
@ARGV = @args;
$0 = $script;
my $rv = do $script;
die $@ if $@;
die "$script: $!" unless defined $rv;
PL

my $argfile = file_path($lib->dirname, 'args');

sub run {
  my (%a) = @_;
  unlink $rec;
  my @argv = @{ $a{argv} };
  my %launch;
  if (grep { /"/ } @argv) {
    write_file($argfile, join('', map { "$_\n" } @argv));
    %launch = (K392_ARGS => $argfile);
    @argv = (file_path($lib->dirname, 'launch.pl'));
  }
  local %ENV = (%ENV, K392_RECORD => $rec, %launch, %{ $a{env} || {} });
  my $pid = IPC::Open3::open3(my $in, my $out = Symbol::gensym, my $err = Symbol::gensym,
    $^X, '-Ilib', '-I' . $lib->dirname, @argv);
  print {$in} $a{stdin} if defined $a{stdin};
  close $in;
  my $stdout = do { local $/; <$out> } // '';
  my $stderr = do { local $/; <$err> } // '';
  waitpid $pid, 0;
  my $recorded = -e $rec ? slurp_file($rec) : '';
  chomp $recorded;
  return { rc => $? >> 8, out => $stdout . $stderr, recorded => $recorded };
}

my @gen = ('bin/dbiogen', 'My::Schema', 'dbi:K392Rec:db=x', 'bob');
my @adm = ('bin/dbioadmin', '--deploy', '--schema-class=K392::Schema', '--quiet');

# --- dbiogen
my $r = run(argv => [ @gen, '--password-env=K392_PW' ], env => { K392_PW => 'from-env-pw' });
is $r->{recorded}, "db=x\tbob\tfrom-env-pw", 'dbiogen: --password-env is the password';
unlike $r->{out}, qr/from-env-pw/, '... and is not printed';

$r = run(argv => [ 'bin/dbiogen', '--password-stdin', 'My::Schema', 'dbi:K392Rec:db=x', 'bob' ], stdin => "from-stdin-pw\nrest\n");
is $r->{recorded}, "db=x\tbob\tfrom-stdin-pw", 'dbiogen: --password-stdin reads one line';

$r = run(argv => [ @gen, '--password-env=K392_UNSET' ]);
isnt $r->{rc}, 0, 'dbiogen: an unset variable fails';
like $r->{out}, qr/K392_UNSET.*not set/, '... naming the variable';

$r = run(argv => [ @gen, '--password-env=K392_PW', '--password-stdin' ], env => { K392_PW => 'x' });
isnt $r->{rc}, 0, 'dbiogen: both options fail';

# --- dbioadmin

$r = run(argv => [ @adm, '--connect=["dbi:K392Rec:db=x","bob",null,{}]', '--password-env=K392_PW' ], env => { K392_PW => 'from-env-pw' });
like $r->{recorded}, qr/^dbi:K392Rec:db=x\tbob\tfrom-env-pw\b/, 'dbioadmin: --password-env sets the password of --connect';

$r = run(argv => [ @adm, '--connect=["dbi:K392Rec:db=x","bob"]', '--password-stdin' ], stdin => "from-stdin-pw\n");
like $r->{recorded}, qr/^dbi:K392Rec:db=x\tbob\tfrom-stdin-pw\b/, 'dbioadmin: --password-stdin sets the password';

$r = run(argv => [ @adm, '--connect-info', 'dsn=dbi:K392Rec:db=x', '--connect-info', 'user=bob', '--password-env=K392_PW' ], env => { K392_PW => 'from-env-pw' });
like $r->{recorded}, qr/password=from-env-pw/, 'dbioadmin: --connect-info gets the password';

$r = run(argv => [ @adm, '--connect=["dbi:K392Rec:db=x","bob"]', '--password-env=K392_UNSET' ]);
isnt $r->{rc}, 0, 'dbioadmin: an unset variable fails';

# the help names both
$r = run(argv => [ 'bin/dbioadmin', '--help' ]);
like $r->{out}, qr/--password-env=VAR.*--password-stdin/s, 'dbioadmin --help names both options';

done_testing;
