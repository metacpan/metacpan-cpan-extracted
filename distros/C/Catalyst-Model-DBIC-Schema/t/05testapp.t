use strict;
use Test::More;
use FindBin;
use File::Spec::Functions qw/catfile catdir/;
use File::Find;
use Config;
use DBI;
use IPC::Open3 'open3';

plan skip_all => 'Enable this optional test with $ENV{C_M_DBIC_SCHEMA_TESTAPP}'
    unless $ENV{C_M_DBIC_SCHEMA_TESTAPP};

my $test_params = [
    [ 'TestSchema', 'DBIC::Schema', '' ],
    [ 'TestSchemaDSN', 'DBIC::Schema', qw/fakedsn fakeuser fakepass/, '{ AutoCommit => 1 }' ],
    [ 'TestSchemaDSN', 'DBIC::Schema', 'create=static', 'traits=Caching', q|moniker_map={ roles => 'ROLE' }|, 'constraint=^users\z', 'dbi:SQLite:testdb.db' ],
    [ 'TestSchemaDSN', 'DBIC::Schema', 'create=static', 'traits=Caching', q|moniker_map={ roles => 'ROLE' }|, 'constraint=^users\z', 'dbi:SQLite:testdb.db', '', '', q|on_connect_do=['select 1', 'select 2']| ],
    [ 'TestSchemaDSN', 'DBIC::Schema', 'create=static', 'traits=Caching', q|moniker_map={ roles => 'ROLE' }|, 'dbi:SQLite:testdb.db', q|on_connect_do=['select 1', 'select 2']| ],
    [ 'TestSchemaDSN', 'DBIC::Schema', 'create=static', 'traits=Caching', 'inflect_singular=sub { $_[0] =~ /\A(.+?)(_id)?\z/; $1 }', q{moniker_map=sub { return join('', map ucfirst, split(/[\W_]+/, lc $_[0])); }}, 'dbi:SQLite:testdb.db' ],
];

my $test_dir   = $FindBin::Bin;
my $blib_dir   = catdir ($test_dir, '..', 'blib', 'lib');
my $cat_dir    = catdir ($test_dir, 'TestApp');
my $catlib_dir = catdir ($cat_dir, 'lib');
my $schema_dir = catdir ($catlib_dir, 'TestSchemaDSN');
my $creator    = catfile($cat_dir, 'script', 'testapp_create.pl');
my $model_dir  = catdir ($catlib_dir, 'TestApp', 'Model');
my $db         = catfile($cat_dir, 'testdb.db');

my $catalyst_pl;

foreach my $bin (split /(?:$Config{path_sep}|:)/, $ENV{PATH}) {
   my $file = catfile($bin, 'catalyst.pl');
   if (-f $file) {
      $catalyst_pl = $file;
      last;
   }
}

plan skip_all => 'catalyst.pl not found' unless $catalyst_pl;

chdir($test_dir);
silent_exec("$^X $catalyst_pl TestApp");
chdir($cat_dir);

# create test db
my $dbh = DBI->connect("dbi:SQLite:$db", '', '', {
   RaiseError => 1, PrintError => 0
});
$dbh->do(<<'EOF');
CREATE TABLE users (                       
        id            INTEGER PRIMARY KEY,
        username      TEXT,
        password      TEXT,
        email_address TEXT,
        first_name    TEXT,
        last_name     TEXT,
        active        INTEGER
);
EOF
$dbh->do(<<'EOF');
CREATE TABLE roles (
        id   INTEGER PRIMARY KEY,
        role TEXT
);
EOF
$dbh->disconnect;

foreach my $tparam (@$test_params) {
   my ($model, $helper, @args) = @$tparam;

   cleanup_schema();

   silent_exec($^X, "-I$blib_dir", $creator, 'model', $model, $helper, $model, @args);

   my $model_path = catfile($model_dir, $model . '.pm');
   ok( -f $model_path, "$model_path is a file" );
   my $compile_rv = silent_exec($^X, "-I$blib_dir", "-I$catlib_dir", "-c", $model_path);
   ok($compile_rv == 0, "perl -c $model_path");

   if (grep /create=static/, @args) {
      my @result_files = result_files();

      if (grep /constraint/, @args) {
         is scalar @result_files, 1, 'constraint works';
      } else {
         is scalar @result_files, 2, 'correct number of tables';
      }

      for my $file (@result_files) {
         my $code = code_for($file);

         like $code, qr/use Moose;\n/, 'use_moose enabled';
         like $code, qr/__PACKAGE__->meta->make_immutable;\n/, 'use_moose enabled';
      }
   }
}

# Test that use_moose=1 is not applied to existing non-moose schemas (RT#60558)
{
   cleanup_schema();

   silent_exec($^X, "-I$blib_dir", $creator, 'model',
      'TestSchemaDSN', 'DBIC::Schema', 'TestSchemaDSN',
      'create=static', 'use_moose=0', 'dbi:SQLite:testdb.db'
   );

   my @result_files = result_files();

   for my $file (@result_files) {
      my $code = code_for($file);

      unlike $code, qr/use Moose;\n/, 'non use_moose=1 schema';
      unlike $code, qr/__PACKAGE__->meta->make_immutable;\n/, 'non use_moose=1 schema';
   }

   silent_exec($^X, "-I$blib_dir", $creator, 'model',
      'TestSchemaDSN', 'DBIC::Schema', 'TestSchemaDSN',
      'create=static', 'dbi:SQLite:testdb.db'
   );

   for my $file (@result_files) {
      my $code = code_for($file);

      unlike $code, qr/use Moose;\n/,
         'non use_moose=1 schema not upgraded to use_moose=1';
      unlike $code, qr/__PACKAGE__->meta->make_immutable;\n/,
         'non use_moose=1 schema not upgraded to use_moose=1';
   }
}

# Test that a moose schema is not detected as a non-moose schema due to an
# errant file.
{
   cleanup_schema();

   silent_exec($^X, "-I$blib_dir", $creator, 'model',
      'TestSchemaDSN', 'DBIC::Schema', 'TestSchemaDSN',
      'create=static', 'dbi:SQLite:testdb.db'
   );

   mkdir "$schema_dir/.svn";
   open my $fh, '>', "$schema_dir/.svn/foo"
      or die "Could not open $schema_dir/.svn/foo for writing: $!";
   print $fh "gargle\n";
   close $fh;

   mkdir "$schema_dir/Result/.svn";
   open $fh, '>', "$schema_dir/Result/.svn/foo"
      or die "Could not open $schema_dir/Result/.svn/foo for writing: $!";
   print $fh "hlagh\n";
   close $fh;

   silent_exec($^X, "-I$blib_dir", $creator, 'model',
      'TestSchemaDSN', 'DBIC::Schema', 'TestSchemaDSN',
      'create=static', 'dbi:SQLite:testdb.db'
   );

   for my $file (result_files()) {
      my $code = code_for($file);

      like $code, qr/use Moose;\n/,
         'use_moose detection not confused by version control files';
      like $code, qr/__PACKAGE__->meta->make_immutable;\n/,
         'use_moose detection not confused by version control files';
   }
}

done_testing;

sub rm_rf {
    my $name = $File::Find::name;
    if(-d $name) { rmdir $name or warn "Cannot rmdir $name: $!" }
    else { unlink $name or die "Cannot unlink $name: $!" }
}

sub cleanup_schema {
   return unless -d $schema_dir;
   finddepth({ wanted => \&rm_rf, no_chdir => 1 }, $schema_dir);
   unlink "${schema_dir}.pm";
}

sub code_for {
   my $file = shift;

   open my $fh, '<', $file;
   my $code = do { local $/; <$fh> };
   close $fh;

   return $code;
}

sub result_files {
   my $result_dir = catfile($schema_dir, 'Result');

   my @results;

   opendir my $dir, $result_dir
      or die "Could not open $result_dir: $!";

   while (my $file = readdir $dir) {
      next unless $file =~ /\.pm\z/;

      push @results, catfile($result_dir, $file);
   }

   closedir $dir;

   return @results;
}

sub silent_exec {
   local *NULL;
   open NULL, '+<', File::Spec->devnull;

   my $pid = open3('<&NULL', '>&NULL', '>&NULL', @_);

   waitpid $pid, 0;

   return $?;
}

END {
    if ($ENV{C_M_DBIC_SCHEMA_TESTAPP}) {
        chdir($test_dir);
        finddepth({ wanted => \&rm_rf, no_chdir => 1 }, $cat_dir);
    }
}

# vim:sts=3 sw=3 et tw=80:
