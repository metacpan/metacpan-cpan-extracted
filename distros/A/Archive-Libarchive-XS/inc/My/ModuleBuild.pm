package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );
use Alien::Base::Wrapper qw( Alien::Libarchive3 !export );
use File::Spec;
use DynaLoader;
use File::Temp qw( tempdir );
use File::Spec;
use Text::ParseWords qw( shellwords );
use Capture::Tiny qw( capture_merged );

sub new
{
  my($class, %args) = @_;

  %args = (%args, Alien::Base::Wrapper->mb_args);
  $args{include_dirs} = 'xs';
  $args{c_source}     = 'xs';
  
  my $self = $class->SUPER::new(%args);

  $self->add_to_cleanup(
    File::Spec->catfile('xs', 'func.h.tmp'),
    File::Spec->catfile('xs', 'func.h'),
    '*.core',
    'test-*',
  );
  
  $self;
}

sub ACTION_build_prep
{
  my($self) = shift;

  return if -e File::Spec->catfile('xs', 'func.h');
  
  print "creating xs/func.h\n";
  
  open(my $fh, '<', File::Spec->catfile('inc', 'symbols.txt'));
  my @symbols = <$fh>;
  close $fh;
  chomp @symbols;
    
  push @symbols, map { "archive_read_support_compression_$_" } qw( all bzip2 compress gzip lzip lzma none program program_signature rpm uu xz );
  push @symbols, map { "archive_write_set_compression_$_" } qw( bzip2 compress gzip lzip lzma none program xz );
  push @symbols, 'archive_write_set_format_old_tar';
  
  open($fh, '>', File::Spec->catfile('xs', 'func.h.tmp'));
  print $fh "#ifndef FUNC_H\n";
  print $fh "#define FUNC_H\n\n";

  print "probing with compiler...\n";
  foreach my $symbol (sort @symbols)
  {
    if($symbol =~ /^archive_write_set_format_/ && $symbol !~ /^archive_write_set_format_(program|by_name)/)
    {
      print $fh "#define HAS_$symbol 1\n"
        if $self->_test_write_format($symbol);
    }
    else
    {
      print $fh "#define HAS_$symbol 1\n"
        if $self->_test_symbol($symbol);
    }
  }

  print $fh "\n#endif\n";
  close $fh;
  rename(File::Spec->catfile('xs', 'func.h.tmp'), File::Spec->catfile('xs', 'func.h')) || die "unable to rename $!";
}

sub ACTION_build
{
  my $self = shift;
  $self->depends_on('build_prep');
  $self->SUPER::ACTION_build(@_);
}

sub ACTION_test
{
  # doesn't seem like this should be necessary, but without
  # this, it doesn't call my ACTION_build
  my $self = shift;
  $self->depends_on('build');
  $self->SUPER::ACTION_test(@_);
}

sub ACTION_install
{
  # doesn't seem like this should be necessary, but without
  # this, it doesn't call my ACTION_build
  my $self = shift;
  $self->depends_on('build');
  $self->SUPER::ACTION_install(@_);
}

my $dir;
my $count = 0;
my $cc;

sub _cc
{
  require ExtUtils::CChecker;

  unless(defined $cc)
  {
    require Text::ParseWords;
    $cc = ExtUtils::CChecker->new;
    $cc->push_extra_compiler_flags(shellwords(Alien::Libarchive3->cflags)) if Alien::Libarchive3->cflags !~ /^\s*$/;
    $cc->push_extra_linker_flags(shellwords(Alien::Libarchive3->libs))     if Alien::Libarchive3->libs   !~ /^\s*$/;
  }
}


sub _test_write_format
{
  my($self, $symbol) = @_;
  my $ok;
  _cc();
  capture_merged { $ok = $cc->try_compile_run(source => <<EOF1) };
#include <archive.h>
#include <archive_entry.h>
int main(int argc, char **argv)
{
  struct archive *a = archive_write_new();
  $symbol(a);
#if ARCHIVE_VERSION_NUMBER < 3000000
  archive_write_finish(a);
#else
  archive_write_free(a);
#endif
  return 0;
}
EOF1
  printf "%-50s %s\n", $symbol, ($ok ? 'yes' : 'no');
  return $ok;
}

sub _test_symbol
{
  my($self, $symbol) = @_;
  my $ok;
  _cc();
  capture_merged { $ok = $cc->try_compile_run(source => <<EOF2) };
#include <stdio.h>
#include <archive.h>
#include <archive_entry.h>
int main(int argc, char **argv)
{
  void *ptr = (void*)$symbol;
  printf("%p\\n", ptr);
  return 0;
}
EOF2

  printf "%-50s %s\n", $symbol, ($ok ? 'yes' : 'no');
  return $ok;
}

1;
