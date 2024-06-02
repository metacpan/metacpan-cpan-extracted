use strict;
use warnings;

package TestArchiveSCS;

use Exporter 'import';
BEGIN {
  our @EXPORT = qw(
    can_test_cli
    scs_archive
    create_hashfs1
    create_hashfs2
    sample1
    sample2
    sample_base
  );
}

use Archive::SCS;
use Archive::SCS::HashFS;
use Archive::SCS::HashFS2;
use Archive::SCS::InMemory;

use Config;
use Cwd;
use IPC::Run3;
use Path::Tiny;
my @CMD = ( $Config{perlpath}, qw[ -Iblib/arch -Iblib/lib -Ilib ]);

# The cli test using a different perl than the harness leads to trouble
sub can_test_cli {
  my @run = ( '-MArchive::SCS', '-we', 'print Archive::SCS->VERSION' );
  my $bin_version = eval { perl_run(@run) } // '';
  my $versions_ok = $bin_version eq Archive::SCS->VERSION
    or warn sprintf "Version mismatch (%s/%s on %s)",
    $bin_version, Archive::SCS->VERSION, $Config{perlpath};
  $versions_ok
}

sub scs_archive {
  perl_run('blib/script/scs_archive', @_);
}

sub perl_run {
  my $in = ref $_[$#_] ? pop @_ : \undef;
  my $old_dir = getcwd;
  chdir path(__FILE__)->parent->parent->parent;
  if (wantarray) {
    my @out;
    run3 [@CMD, @_], $in, \@out, \@out;
    chdir $old_dir;
    chomp for @out;
    @out
  }
  else {
    my $out;
    run3 [@CMD, @_], $in, \$out, \$out;
    chdir $old_dir;
    $out
  }
}

sub create_hashfs1 :prototype($$) {
  my ($file, $mem) = @_;
  my $scs = Archive::SCS->new;
  $scs->mount($mem);
  Archive::SCS::HashFS::create_file($file, $scs);
  $scs->unmount($mem);
}

sub create_hashfs2 :prototype($$) {
  my ($file, $mem) = @_;
  my $scs = Archive::SCS->new;
  $scs->mount($mem);
  Archive::SCS::HashFS2::create_file($file, $scs);
  $scs->unmount($mem);
}

sub sample1 :prototype() {
  my $mem = Archive::SCS::InMemory->new;
  $mem->add_entry('ones', '1' x 100);
  $mem->add_entry('empty', '');
  $mem->add_entry('orphan', 'whats my name?');
  $mem->add_entry('', {
    dirs  => [qw( emptydir dir )],
    files => [qw( ones empty )],
  });
  $mem->add_entry('emptydir', { dirs => [], files => [] });
  $mem->add_entry('dir', { dirs => ['subdir'], files => [] });
  $mem->add_entry('dir/subdir', { dirs => [], files => ['SubDirFile'] });
  $mem->add_entry('dir/subdir/SubDirFile', 'I am in a subdirectory');
  return $mem;
}

sub sample2 :prototype() {
  my $mem = Archive::SCS::InMemory->new;
  $mem->add_entry('orphan', 'not actually an orphan in this sample');
  $mem->add_entry('', { dirs  => [], files => [qw( orphan )] });
  return $mem;
}

sub sample_base :prototype() {
  my $mem = Archive::SCS::InMemory->new;
  $mem->add_entry('version.txt', '0.0.0.0');
  return $mem;
}

1;
