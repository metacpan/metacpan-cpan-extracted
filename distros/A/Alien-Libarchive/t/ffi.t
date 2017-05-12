use strict;
use warnings;
use Test::More;
use Alien::Libarchive;

BEGIN {
  plan skip_all => 'test requires FFI::Raw 0.31'
    unless eval q{ use FFI::Raw 0.31; 1 };
}

plan tests => 1;

my($dll) = Alien::Libarchive->new->dlls;

my $archive_version_number = FFI::Raw->new($dll, 'archive_version_number', FFI::Raw::int);
my $archive_read_new   = FFI::Raw->new($dll, 'archive_read_new',   FFI::Raw::ptr);
my $archive_read_free  = FFI::Raw->new($dll, $archive_version_number->() > 3000000 ? 'archive_read_free' : 'archive_read_finish',  FFI::Raw::int, FFI::Raw::ptr);
my $archive_entry_new  = FFI::Raw->new($dll, 'archive_entry_new',  FFI::Raw::ptr);
my $archive_entry_free = FFI::Raw->new($dll, 'archive_entry_free', FFI::Raw::void, FFI::Raw::ptr);

sub main
{
  my $a = $archive_read_new->();
  note "a = $a";
  unless(defined $a) {
    return 2;
  }
  
  my $r = $archive_read_free->($a);
  note "archive_read_free = $r";
  if($r != 0) {
    return 2;
  }
  
  my $e = $archive_entry_new->();
  note "e = $e";
  unless(defined $e) {
    return 2;
  }
  
  $archive_entry_free->($e);
  
  return 0;
}

is main(), 0, 'ffi';
