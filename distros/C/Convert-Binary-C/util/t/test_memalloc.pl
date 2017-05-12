use strict;
use IO::File;
use IPC::Open3;
use Data::Dumper;
use Test;

my $CC     = 'cc';
my @CFLAGS = qw( -Wall -g );
my $TEST   = './ma_test';

END {
  $ENV{MEMALLOC_TEST_NO_CLEANUP} or cleanup();
}

sub test {
  my %opt = (
    PLAN   => 0,
    CFLAGS => [],
    TESTS  => [
      {
        ENV => {},
      },
      {
        ENV => {
                 MEMALLOC_TEST_DEBUG  => 1,
               },
      },
      {
        ENV => {
                 MEMALLOC_TEST_ASSERT => 1,
               },
      },
      {
        ENV => {
                 MEMALLOC_TEST_ASSERT => 1,
                 MEMALLOC_TEST_DEBUG  => 1,
               },
      },
      {
        ENV => {
                 MEMALLOC_CHECK_FREED => 1,
               },
      },
      {
        ENV => {
                 MEMALLOC_CHECK_FREED => 1,
                 MEMALLOC_TEST_DEBUG  => 1,
               },
      },
      {
        ENV => {
                 MEMALLOC_CHECK_FREED => 1,
                 MEMALLOC_TEST_ASSERT => 1,
               },
      },
      {
        ENV => {
                 MEMALLOC_CHECK_FREED => 1,
                 MEMALLOC_TEST_ASSERT => 1,
                 MEMALLOC_TEST_DEBUG  => 1,
               },
      },
    ],
    @_
  );

  plan( tests => $opt{PLAN} );

  my @tests = @{$opt{TESTS}};

  push @tests, map { { %$_, FILE => 'test.out' } } @tests;

  cleanup();
  ok(1);

  build( %opt, SOURCE => 'memalloc.c', OUTPUT => $TEST )
    or die "couldn't build test\n";
  ok(1);

  for my $t ( @tests ) {
    my %env = %{$t->{ENV}};

    if (exists $t->{FILE}) {
      $env{MEMALLOC_TEST_DEBUG_FILE} = $t->{FILE};
    }

    $env{MEMALLOC_SOFT_ASSERT} = 1;

    comment(Dumper(\%env));

    my $rv = run( \%env, $TEST );
    comment(Dumper($rv));

    $rv->{didnotrun} and die "couldn't run test\n";

    ok($rv->{status}, 0);
    ok(not exists $rv->{core});
    ok(not exists $rv->{signal});

    ok(scalar @{$rv->{stdout}}, 0, "output on stdout");

    -f 'test.ref' or die "no reference file\n";
    ok(1);

    my @ref = slurp('test.ref');
    my @out;

    if (exists $t->{FILE}) {
      ok(scalar @{$rv->{stderr}}, 0, "output on stderr");
      ok(-f $t->{FILE});
      @out = slurp($t->{FILE});
    }
    else {
      @out = @{$rv->{stderr}};
    }

    ok(scalar @out, scalar @ref, "differing number of lines in output/reference");

    comment( "[Output]\n", @out, "[/Output]\n" );
    comment( "[Reference]\n", @ref, "[/Reference]\n" );

    chomp @ref;
    chomp @out;

    for my $i ( 0 .. $#ref ) {
      print qq(# "$out[$i]" - "$ref[$i]"\n);
      ok($out[$i], $ref[$i]);
    }

    rm( qw( test.out test.ref ) );
  }
}

sub slurp {
  my $file = new IO::File $_[0] or die "$_[0]: $!\n";
  <$file>;
}

sub cleanup { rm( qw( test.out test.ref ), $TEST ) }

sub rm { -f and unlink || warn "$_: $!" for @_ }

sub build {
  my %opt = (
    CC     => $CC,
    CFLAGS => [],
    @_
  );

  my @cflags = (@CFLAGS, @{$opt{CFLAGS}});

  my $target;

  if (exists $opt{OBJECT}) {
    push @cflags, '-c';
    $target = $opt{OBJECT};
  }
  elsif (exists $opt{OUTPUT}) {
    $target = $opt{OUTPUT};
  }
  else {
    return 0;
  }

  unless (exists $opt{SOURCE}) {
    return 0;
  }

  my $source = ref $opt{SOURCE} ? $opt{SOURCE} : [$opt{SOURCE}];

  for my $s (@$source) {
    unless (-f $s) {
      return 0;
    }
  }

  my $rv = run( $opt{CC}, @cflags, '-o', $target, @$source );

  comment(Dumper($rv));

  @{$rv->{stderr}} and print STDERR "compiler output on stderr\n";
  @{$rv->{stdout}} and print STDERR "compiler output on stdout\n";

  if ($rv->{didnotrun} || $rv->{status}) {
    return 0;
  }

  return $target;
}

sub comment
{
  my @d = @_;
  s/^/# /gm for @d;
  print @d;
}

sub run
{
  my $env = ref $_[0] ? shift : {};
  my $prog = shift;
  my @args = @_;

  local(*W, *S, *E);

  for my $e ( keys %$env ) {
    $ENV{$e} = $env->{$e};
  }

  my $pid = open3(\*W, \*S, \*E, $prog, @args);

  my @sout = <S>;
  my @serr = <E>;

  waitpid($pid, 0);

  for my $e ( keys %$env ) {
    delete $ENV{$e};
  }

  my %rval = (
    status => $? >> 8,
    stdout => \@sout,
    stderr => \@serr,
  );

  $rval{didnotrun} = 0;

  if( @serr && $serr[0] =~ /^Can't exec "\Q$prog\E":/ ) {
    $rval{didnotrun} = 1;
  }

  if( $^O eq 'MSWin32' && $rval{status} == 1 ) {
    $rval{didnotrun} = 1;
  }

  $? & 128 and $rval{core}   = 1;
  $? & 127 and $rval{signal} = $? & 127;

  \%rval;
}

