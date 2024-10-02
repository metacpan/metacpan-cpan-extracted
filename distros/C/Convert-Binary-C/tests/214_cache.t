################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Carp;
use Convert::Binary::C @ARGV;
use Convert::Binary::C::Cached;

$^W = 1;

BEGIN {
  $tests = 72;
  plan tests => $tests;
}

$thisfile = quotemeta "at $0";

{
  local @INC;
  eval { require IO::File };     $IO_File = $@;
  eval { require Data::Dumper }; $Data_Dumper = $@;
}

{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, $_[0] };
  carp 'xxx';  # carp must already be working
  @warn = ();  # throw it away...
  local @INC;  # let's pretend we don't have anything
  my $what = join ' and ', ($Data_Dumper ? ('Data::Dumper') : ()), ($IO_File ? ('IO::File') : ());
  my $c = eval { Convert::Binary::C::Cached->new( Cache => 'xxx' ) };
  ok( scalar @warn, 1 );
  ok( $warn[0], qr/Cannot load $what, disabling cache $thisfile/ );
}

eval { require IO::File }; $IO_File = $@;

{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, $_[0] };
  local @INC;
  my $what = join ' and ', ($Data_Dumper ? ('Data::Dumper') : ()), ($IO_File ? ('IO::File') : ());
  my $c = eval { Convert::Binary::C::Cached->new( Cache => 'xxx' ) };
  ok( scalar @warn, 1 );
  ok( $warn[0], qr/Cannot load $what, disabling cache $thisfile/ );
}

eval { require Data::Dumper }; $Data_Dumper = $@;

if( $Data_Dumper or $IO_File ) {
  my $req;
  $req = 'IO::File' if $IO_File;
  $req = 'Data::Dumper' if $Data_Dumper;
  $req = 'Data::Dumper and IO::File' if $Data_Dumper && $IO_File;
  skip( "caching requires $req", 0 ) for 5 .. $tests;
  # silence the memory test ;-)
  eval { Convert::Binary::C->new->parse("enum { XXX };") };
  exit;
}

*main::copy = sub {
  my($from, $to) = @_;
  -e $to and unlink $to || die $!;
  my $fh = IO::File->new;
  my $th = IO::File->new;
  local $/;
  $fh->open("<$from")
    and binmode $fh
    and $th->open(">$to")
    and binmode $th
    or die $!;
  $th->print( $fh->getline );
  $fh->close
   and $th->close
   or die $!;
  -e $to or die $!;
};

$cache = 'tests/cache.cbc';

#------------------------------------------------------------------------------

# check some basic stuff first

-e $cache and unlink $cache || die $!;

eval {
  $c = Convert::Binary::C::Cached->new(
    Cache   => [$cache],
    Include => ['tests/cache']
  );
};
ok( $@, qr/Cache must be a string value, not a reference at \Q$0/ );

eval {
  $c = Convert::Binary::C::Cached->new(
    Cache   => $cache,
    Include => ['tests/cache']
  );
};
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $c->parse( 'enum { XXX };' );
};
ok($@,'',"failed to parse code");

eval {
  $c->parse_file( 'tests/include/include.c' );
};
ok( $@, qr/Cannot parse more than once for cached objects at \Q$0/ );


#------------------------------------------------------------------------------

# check what happens if the cache file cannot be created

eval {
  $c = Convert::Binary::C::Cached->new(
    Cache   => 'abc/def/ghi/jkl/mno.pqr',
    Include => ['tests/cache']
  );
};
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $c->parse( 'enum { XXX };' );
};
ok( $@, qr/Cannot open 'abc\/def\/ghi\/jkl\/mno\.pqr':\s*.*?\s*at \Q$0/ );

#------------------------------------------------------------------------------

-e $cache and unlink $cache || die $!;
cleanup();

# copy initial set of files

copy( qw( tests/cache/cache.1   tests/cache/cache.h   ) );
copy( qw( tests/cache/header.1  tests/cache/header.h  ) );
copy( qw( tests/cache/sub/dir.1 tests/cache/sub/dir.h ) );

# create reference object

@config = (
  Include    => ['tests/cache'],
  KeywordMap => {'__inline__' => 'inline', '__restrict__' => undef },
);

eval { $r = Convert::Binary::C->new( @config ) };
ok($@,'',"failed to create reference Convert::Binary::C object");

push @config, Cache => $cache;

eval { $c = Convert::Binary::C::Cached->new( @config ) };
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $c->parse_file( 'tests/cache/cache.h' );
  $r->parse_file( 'tests/cache/cache.h' );
};
ok($@,'',"failed to parse files");

# object shouldn't be using the cache file
ok( $c->__uses_cache, 0, "object is using cache file" );

# check if both objects are equivalent
ok( compare( $r, $c ) );

ok( -e $cache );

#------------------------------------------------------------------------------

# this new object should now use the cache file

eval { $c = Convert::Binary::C::Cached->new( @config ) };
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $c->parse_file( 'tests/cache/cache.h' );
};
ok($@,'',"failed to parse files");

# object should be using the cache file
ok( $c->__uses_cache, 1, "object isn't using cache file" );

ok( compare( $r, $c ) );

#------------------------------------------------------------------------------

# check if a changes in the files are detected

for( qw( tests/cache/sub/dir tests/cache/header tests/cache/cache ) ) {
  # 'dir' files are the same size, so check by timestamp
  /dir/ and sleep 2;
  copy( "$_.2", "$_.h" );
  /dir/ and sleep 2;

  eval { $c = Convert::Binary::C::Cached->new( @config ) };
  ok($@,'',"failed to create Convert::Binary::C::Cached object");

  eval {
    $r->clean->parse_file( 'tests/cache/cache.h' );
    $c->parse_file( 'tests/cache/cache.h' );
  };
  ok($@,'',"failed to parse files");

  # can't use cache
  ok( $c->__uses_cache, 0, "object is using cache file" );

  ok( compare( $r, $c ) );

  eval { $c = Convert::Binary::C::Cached->new( @config ) };
  ok($@,'',"failed to create Convert::Binary::C::Cached object");

  eval {
    $c->parse_file( 'tests/cache/cache.h' );
  };
  ok($@,'',"failed to parse files");

  # should use cache
  ok( $c->__uses_cache, 1, "object is not using cache file" );

  ok( compare( $r, $c ) );
}

#------------------------------------------------------------------------------

# changing the way we're parsing should trigger re-parsing

eval { $c = Convert::Binary::C::Cached->new( @config ) };
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $r->clean->parse( <<'ENDC' );
#include "cache.h"
ENDC
  $c->parse( <<'ENDC' );
#include "cache.h"
ENDC
};
ok($@,'',"failed to parse");

# can't use cache
ok( $c->__uses_cache, 0, "object is using cache file" );

ok( compare( $r, $c ) );

eval { $c = Convert::Binary::C::Cached->new( @config ) };
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $c->parse( <<'ENDC' );
#include "cache.h"
ENDC
};
ok($@,'',"failed to parse files");

# should use cache
ok( $c->__uses_cache, 1, "object is not using cache file" );

ok( compare( $r, $c ) );

#------------------------------------------------------------------------------

# changing the embedded code should trigger re-parsing

eval { $c = Convert::Binary::C::Cached->new( @config ) };
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $r->clean->parse( <<'ENDC' );
#define FOO
#include "cache.h"
ENDC
  $c->parse( <<'ENDC' );
#define FOO
#include "cache.h"
ENDC
};
ok($@,'',"failed to parse");

# can't use cache
ok( $c->__uses_cache, 0, "object is using cache file" );

ok( compare( $r, $c ) );

eval { $c = Convert::Binary::C::Cached->new( @config ) };
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $c->parse( <<'ENDC' );
#define FOO
#include "cache.h"
ENDC
};
ok($@,'',"failed to parse files");

# should use cache
ok( $c->__uses_cache, 1, "object is not using cache file" );

ok( compare( $r, $c ) );

#------------------------------------------------------------------------------

# changing the configuration should trigger re-parsing

push @config, Define => ['BAR'];

eval { $c = Convert::Binary::C::Cached->new( @config ) };
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $r->clean->Define(['BAR'])->parse( <<'ENDC' );
#define FOO
#include "cache.h"
ENDC
  $c->parse( <<'ENDC' );
#define FOO
#include "cache.h"
ENDC
};
ok($@,'',"failed to parse");

# can't use cache
ok( $c->__uses_cache, 0, "object is using cache file" );

ok( compare( $r, $c ) );

eval { $c = Convert::Binary::C::Cached->new( @config ) };
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $c->parse( <<'ENDC' );
#define FOO
#include "cache.h"
ENDC
};
ok($@,'',"failed to parse files");

# should use cache
ok( $c->__uses_cache, 1, "object is not using cache file" );

ok( compare( $r, $c ) );

#------------------------------------------------------------------------------

-e $cache and unlink $cache || die $!;
cleanup();

#------------------------------------------------------------------------------

# check cache file corruption

$code = 'typedef int foo;';
eval { $c = Convert::Binary::C::Cached->new( Cache => $cache ) };
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval { $c->parse( $code ) };
ok($@,'',"failed to parse");

# can't use cache
ok( $c->__uses_cache, 0, "object is using cache file" );

undef $c;

$cache_file = do { local $/; IO::File->new($cache)->getline };
$cache_file =~ s{/\*.*?\*/}{ }gs; # strip comments

$fail = 0;
$size = length($cache_file) - 5;

for( $pos = 0; $pos < $size; $pos++ ) {
  $corrupted = $cache_file;

  # corrupt the file
  substr $corrupted, $pos, 5, "\n?!'§\$\n\%&\n}=";

  IO::File->new(">$cache")->print($corrupted);

  @warn = ();

  {
    local $SIG{__WARN__} = sub { push @warn, $_[0] };

    eval { $c = Convert::Binary::C::Cached->new( Cache => $cache ) };
    if( $@ ne '' ) {
      $@ =~ s/^/# /gm;
      print "# failed to create Convert::Binary::C::Cached object\n$@";
      $fail++;
    }

    eval { $c->parse( $code ) };
    if( $@ ne '' ) {
      $@ =~ s/^/# /gm;
      print "# failed to create Convert::Binary::C::Cached object\n$@";
      $fail++;
    }
  }

  defined $c or next;

  # can't use cache
  if( $c->__uses_cache != 0 ) {
    $corrupted =~ s/^/# /gm;
    print "# object is using corrupted cache file\n$corrupted";
    $fail++;
  }

  # no warnings, please
  for( @warn ) {
    s/^/# /gm;
    print "# warning during object creation / parsing:\n$_";
    $fail++;
  }
}

ok( $fail, 0, "corrupted cache files not handled correctly" );

#------------------------------------------------------------------------------

-e $cache and unlink $cache || die $!;
cleanup();

#------------------------------------------------------------------------------

sub cleanup {
  for( qw( tests/cache/cache.h tests/cache/header.h tests/cache/sub/dir.h ) ) {
    -e and unlink || die $!;
  }
}

sub compare {
  my($ref, $obj) = @_;

  my $refcfg = $ref->configure;
  my $objcfg = $obj->configure;

  delete $_->{Cache} for $refcfg, $objcfg;

  print "# compare configurations...\n";
  reccmp( $refcfg, $objcfg ) or return 0;

  my $refdep = $ref->dependencies;
  my $objdep = $obj->dependencies;

  print "# compare dependencies...\n";
  reccmp( $refdep, $objdep ) or return 0;

  for( qw( enum_names compound_names struct_names union_names typedef_names ) ) {
    print "# compare $_ method...\n";
    reccmp( [sort $ref->$_()], [sort $obj->$_()] ) or return 0;
  }

  for my $meth ( qw( enum compound struct union typedef ) ) {
    print "# compare $meth method...\n";
    my $i;
    my %ref = map { ($i = $_->{identifier} || $_->{declarator}) ? ($i => $_) : (); } $ref->$meth();
    my %obj = map { ($i = $_->{identifier} || $_->{declarator}) ? ($i => $_) : (); } $obj->$meth();
    reccmp( [sort keys %ref], [sort keys %obj] ) or return 0;
    reccmp( [@ref{sort keys %ref}], [@obj{sort keys %obj}] ) or return 0;
  }

  return 1;
}

sub reccmp
{
  my($ref, $val) = @_;

  unless( defined $ref and defined $val ) {
    return defined($ref) == defined($val);
  }

  ref $ref or return $ref eq $val;

  if( ref $ref eq 'ARRAY' ) {
    @$ref == @$val or return 0;
    for( 0..$#$ref ) {
      reccmp( $ref->[$_], $val->[$_] ) or return 0;
    }
  }
  elsif( ref $ref eq 'HASH' ) {
    @{[keys %$ref]} == @{[keys %$val]} or return 0;
    for( keys %$ref ) {
      reccmp( $ref->{$_}, $val->{$_} ) or return 0;
    }
  }
  else { return 0 }

  return 1;
}
