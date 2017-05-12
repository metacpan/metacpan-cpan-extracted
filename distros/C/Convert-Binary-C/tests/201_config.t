################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

use constant SUCCEED => 1;
use constant FAIL    => 0;

$^W = 1;

BEGIN { plan tests => 2070 }

$debug = Convert::Binary::C::feature( 'debug' );

ok( defined $debug );

$RDBG = $debug ? '' : 'no debugging';

# passing references as options is not legal, so this is
# always checked for non-list options
@refs = (
  { in =>  [12], result => FAIL },
  { in =>  \123, result => FAIL },
  { in => {1,2}, result => FAIL },
);

$thisfile = quotemeta "at $0";

sub check_config
{
  my $opt = ref($_[0]) eq 'HASH' ? shift : {};
  my $reason = $opt->{skip} || '';
  my $option = shift;
  my $value;


  for my $config ( @_ ) {
    my @warn;

    {
      local $SIG{__WARN__} = sub { push @warn, shift };

      my $reference = $config->{out} || $config->{in};

      eval { $p = new Convert::Binary::C };
      skip($reason, $@, '', "failed to create Convert::Binary::C object");

      print "# \$p->configure( $option => $config->{in} )\n";
      eval { $p->configure( $option => $config->{in} ) };
      if( $@ ) {
        my $err = $@;
        $err =~ s/^/#   /g;
        print "# failed due to:\n$err";
      }
      skip( $reason, ($@ eq '' ? SUCCEED : FAIL), $config->{result},
            "$option => $config->{in}" );
      skip( $reason, $@, qr/$option must be.*not.*$thisfile/ ) if $config->{result} == FAIL;

      print "# \$p->$option( $config->{in} )\n";
      eval { $p->$option( $config->{in} ) };
      if( $@ ) {
        my $err = $@;
        $err =~ s/^/#   /g;
        print "# failed due to:\n$err";
      }
      skip( $reason, ($@ eq '' ? SUCCEED : FAIL), $config->{result},
            "$option => $config->{in}" );
      skip( $reason, $@, qr/$option must be.*not.*$thisfile/ ) if $config->{result} == FAIL;

      if( $config->{result} == SUCCEED ) {
        print "# \$value = \$p->configure( $option )\n";
        eval { $value = $p->configure( $option ) };
        skip( $reason, $@, '', "cannot get value for '$option' via configure" );
        skip( $reason, $value, $reference, "invalid value for '$option' via configure" );

        print "# \$value = \$p->$option\n";
        eval { $value = $p->$option() };
        skip( $reason, $@, '', "cannot get value for '$option' via $option" );
        skip( $reason, $value, $reference, "invalid value for '$option' via $option" );
      }
    }

    if( exists $config->{warnings} ) {
      my $fail = 0;
      for my $warning ( @warn ) {
        print "# $warning";
        my $expected = 0;
        $warning =~ $_ and $expected++ for @{$config->{warnings}};
        $expected == 1 or $fail++;
      }
      skip( $reason, $fail, 0, "unexpected warnings issued for option '$option'" );
    }
    else {
      for my $warning ( @warn ) {
        print "# unexpected warning: $warning";
      }
      skip( $reason, scalar @warn, 0, "warnings issued for option '$option'" );
    }
  }

  print "# \$p->configure( $option )\n";
  my @warn;
  {
    local $SIG{__WARN__} = sub { push @warn, shift };
    eval { $p->configure( $option ) };
  }
  skip( $reason, $@, '', "failed to call configure in void context" );
  if( @warn ) { print "# issued warnings:\n", map "#   $_", @warn }
  skip( $reason, scalar @warn, 1, "invalid number of warnings issued" );
  skip( $reason, $warn[0], qr/Useless use of configure in void context.*$thisfile/ );

  print "# \$p->$option\n";
  @warn = ();
  {
    local $SIG{__WARN__} = sub { push @warn, shift };
    eval { $p->$option() };
  }
  skip( $reason, $@, '', "failed to call $option in void context" );
  if( @warn ) { print "# issued warnings:\n", map "#   $_", @warn }
  skip( $reason, scalar @warn, 1, "invalid number of warnings issued" );
  skip( $reason, $warn[0], qr/Useless use of $option in void context.*$thisfile/ );
}

sub check_config_bool
{
  my $opt = ref($_[0]) eq 'HASH' ? shift : {};
  my $option = shift;

  my @tests = (
     { in =>     0, out => 0, result => SUCCEED },
     { in =>     1, out => 1, result => SUCCEED },
     { in =>  4711, out => 1, result => SUCCEED },
     { in =>   -42, out => 1, result => SUCCEED },
     @refs
  );

  check_config( $opt, $option, @tests );
}

sub check_option_strlist
{
  my $option = shift;
  my @warn;
  my @tests = (
    { in => \4711,             result => FAIL, error => qr/$option wants an array reference/ },
    { in => [],                result => SUCCEED },
    { in => { key => 'val' },  result => FAIL, error => qr/$option wants an array reference/ },
    { in => ['const', 'void'], result => SUCCEED },
  );

  local $SIG{__WARN__} = sub { push @warn, shift };

  for my $config ( @tests ) {
    @warn = ();

    eval { $p = new Convert::Binary::C };
    ok($@, '', "failed to create Convert::Binary::C object");

    print "# \$p->configure( $option => $config->{in} )\n";
    eval { $p->configure( $option => $config->{in} ) };
    if( $@ ) {
      my $err = $@;
      $err =~ s/^/#   /g;
      print "# failed due to:\n$err";
    }
    ok( ($@ eq '' ? SUCCEED : FAIL), $config->{result},
        "$option => $config->{in}" );
    ok( $@, $config->{error} ) if $config->{result} == FAIL;

    print "# \$p->$option( $config->{in} )\n";
    eval { $p->$option( $config->{in} ) };
    if( $@ ) {
      my $err = $@;
      $err =~ s/^/#   /g;
      print "# failed due to:\n$err";
    }
    ok( ($@ eq '' ? SUCCEED : FAIL), $config->{result},
        "$option => $config->{in}" );
    ok( $@, $config->{error} ) if $config->{result} == FAIL;

    if( $config->{result} == SUCCEED ) {
      print "# \$value = \$p->configure( $option )\n";
      eval { $value = $p->configure( $option ) };
      ok( $@, '', "cannot get value for '$option' via configure" );
      ok( "@$value", "@{$config->{in}}", "invalid value for '$option' via configure" );

      print "# \$value = \$p->$option\n";
      eval { $value = $p->$option() };
      ok( $@, '', "cannot get value for '$option' via $option" );
      ok( "@$value", "@{$config->{in}}", "invalid value for '$option' via $option" );
    }

    for my $warning ( @warn ) {
      print "# unexpected warning: $warning";
    }
    ok( scalar @warn, 0, "warnings issued for option '$option'" );
  }

  @warn = ();
  print "# \$p->configure( $option )\n";
  eval { $p->configure( $option ) };
  ok( $@, '', "failed to call configure in void context" );
  if( @warn ) { print "# issued warnings:\n", map "#   $_", @warn }
  ok( scalar @warn, 1, "invalid number of warnings issued" );
  ok( $warn[0], qr/Useless use of configure in void context.*$thisfile/ );

  @warn = ();
  print "# \$p->$option\n";
  eval { $p->$option() };
  ok( $@, '', "failed to call $option in void context" );
  if( @warn ) { print "# issued warnings:\n", map "#   $_", @warn }
  ok( scalar @warn, 1, "invalid number of warnings issued" );
  ok( $warn[0], qr/Useless use of $option in void context.*$thisfile/ );
}

sub check_option_strlist_args {
  my $option = shift;
  my @warn;
  eval {
    $p = new Convert::Binary::C;
    $p->$option( [qw(foo bar)] );
    $p->$option( 'include' );
    $p->$option( qw(a b c) );
    $value = $p->$option();
  };
  ok( $@, '', "failed to call $option with various arguments" );
  if( @warn ) { print "# issued warnings:\n", map "#   $_", @warn }
  ok( scalar @warn, 0, "invalid number of warnings issued" );
  ok( "@$value", "@{[qw(foo bar include a b c)]}", "invalid value for '$option'" );
}

sub compare_config
{
  my($cfg1, $cfg2) = @_;
  my $fail = 0;
  scalar keys %$cfg1 == scalar keys %$cfg2 or $fail++;
  for my $key ( keys %$cfg1 ) {
    if( ref $cfg1->{$key} eq 'ARRAY' ) {
      "@{$cfg1->{$key}}" eq "@{$cfg2->{$key}}" or $fail++;
    }
    elsif( ref $cfg1->{$key} eq 'HASH' ) {
      "@{[sort keys %{$cfg1->{$key}}]}" eq "@{[sort keys %{$cfg1->{$key}}]}" or $fail++;
      for( sort keys %{$cfg1->{$key}} ) {
        if( defined( $cfg1->{$key}{$_} ) != defined( $cfg2->{$key}{$_} ) ) {
          $fail++;
        }
        if( defined( $cfg1->{$key}{$_} ) and defined( $cfg2->{$key}{$_} )
            and $cfg1->{$key}{$_} ne $cfg2->{$key}{$_} ) {
          $fail++;
        }
      }
    }
    else {
      if (defined($cfg1->{$key}) && defined($cfg2->{$key})) {
        $cfg1->{$key} eq $cfg2->{$key} or $fail++;
      }
      else {
        defined($cfg1->{$key}) == defined($cfg2->{$key}) or $fail++;
      }
    }
  }
  return $fail == 0;
}

sub checkrc
{
  my $rc = shift;
  my $fail = 0;
  my $succ = 0;
  while( $rc =~ /SV\s*=\s*(\S+).*?REFCNT\s*=\s*(\d+)/g ) {
    if( $2 == 1 ) {
      $succ++
    }
    elsif ($1 eq 'NULL' && $2 >= 1) { # we hit &PL_sv_undef...
      $succ++
    }
    else {
      print "# REFCNT = $2 for Sv$1, should be 1\n";
      $fail++;
    }
  }
  return $succ > 0 && $fail == 0;
}

@tests = (
  { in => -2,  result => FAIL    },
  { in => -1,  result => SUCCEED },
  { in =>  0,  result => SUCCEED },
  { in =>  1,  result => SUCCEED },
  { in =>  2,  result => SUCCEED },
  { in =>  3,  result => FAIL    },
  { in =>  4,  result => SUCCEED },
  { in =>  5,  result => FAIL    },
  { in =>  6,  result => FAIL    },
  { in =>  7,  result => FAIL    },
  { in =>  8,  result => SUCCEED },
  { in =>  9,  result => FAIL    },
  @refs
);

check_config( 'EnumSize', @tests );

@tests = (
  { in => -1,  result => FAIL    },
  { in =>  0,  result => SUCCEED },
  { in =>  1,  result => SUCCEED },
  { in =>  2,  result => SUCCEED },
  { in =>  3,  result => FAIL    },
  { in =>  4,  result => SUCCEED },
  { in =>  5,  result => FAIL    },
  { in =>  6,  result => FAIL    },
  { in =>  7,  result => FAIL    },
  { in =>  8,  result => SUCCEED },
  { in =>  9,  result => FAIL    },
  @refs
);

check_config( $_, @tests ) for qw( PointerSize
                                   IntSize
                                   CharSize
                                   ShortSize
                                   LongSize
                                   LongLongSize );

@tests = (
  { in => -1, result => FAIL    },
  { in =>  0, result => SUCCEED },
  { in =>  1, result => SUCCEED },
  { in =>  2, result => SUCCEED },
  { in =>  3, result => FAIL    },
  { in =>  4, result => SUCCEED },
  { in =>  5, result => FAIL    },
  { in =>  6, result => FAIL    },
  { in =>  7, result => FAIL    },
  { in =>  8, result => SUCCEED },
  { in =>  9, result => FAIL    },
  { in => 10, result => FAIL    },
  { in => 11, result => FAIL    },
  { in => 12, result => SUCCEED },
  { in => 13, result => FAIL    },
  { in => 14, result => FAIL    },
  { in => 15, result => FAIL    },
  { in => 16, result => SUCCEED },
  { in => 17, result => FAIL    },
  @refs
);

check_config( $_, @tests ) for qw( FloatSize
                                   DoubleSize
                                   LongDoubleSize );

@tests = (
  { in => -1, result => FAIL    },
  { in =>  0, result => SUCCEED },
  { in =>  1, result => SUCCEED },
  { in =>  2, result => SUCCEED },
  { in =>  3, result => FAIL    },
  { in =>  4, result => SUCCEED },
  { in =>  5, result => FAIL    },
  { in =>  6, result => FAIL    },
  { in =>  7, result => FAIL    },
  { in =>  8, result => SUCCEED },
  { in =>  9, result => FAIL    },
  { in => 10, result => FAIL    },
  { in => 11, result => FAIL    },
  { in => 12, result => FAIL    },
  { in => 13, result => FAIL    },
  { in => 14, result => FAIL    },
  { in => 15, result => FAIL    },
  { in => 16, result => SUCCEED },
  { in => 17, result => FAIL    },
  @refs
);

check_config( $_, @tests ) for qw( Alignment CompoundAlignment );

check_config( 'ByteOrder',
  { in => 'BigEndian',    result => SUCCEED },
  { in => 'LittleEndian', result => SUCCEED },
  { in => 'NoEndian',     result => FAIL    },
  @refs
);

check_config( 'EnumType',
  { in => 'Integer', result => SUCCEED },
  { in => 'String',  result => SUCCEED },
  { in => 'Both',    result => SUCCEED },
  { in => 'None',    result => FAIL    },
  @refs
);

check_config_bool( $_ ) for qw( UnsignedBitfields
                                UnsignedChars
                                Warnings
                                HasCPPComments
                                HasMacroVAARGS );

check_option_strlist( $_ ) for qw( Include
                                   Define
                                   Assert
                                   DisabledKeywords );

check_option_strlist_args( $_ ) for qw( Include
                                        Define
                                        Assert);

{
  my @warn;

  eval { require Tie::Hash::Indexed };
  $@ and eval { require Tie::IxHash };
  $@ and push @warn, qr/^Couldn't load a module for member ordering.*$thisfile/;

  @tests = (
     { in =>     0, out => 0, result => SUCCEED, warnings => [] },
     { in =>     1, out => 1, result => SUCCEED, warnings => \@warn },
     { in =>  4711, out => 1, result => SUCCEED, warnings => \@warn },
     { in =>   -42, out => 1, result => SUCCEED, warnings => \@warn },
     @refs
  );

  check_config( 'OrderMembers', @tests );
}

#===================================================================
# check DisabledKeywords option
#===================================================================

eval {
  $p = new Convert::Binary::C;
  $p->configure( DisabledKeywords => ['void', 'foo', 'const'] );
};
ok( $@, qr/Cannot disable unknown keyword 'foo'.*$thisfile/ );

eval {
  $p = new Convert::Binary::C;
  $p->DisabledKeywords( 'void', 'foo', 'const' );
};
ok( $@, qr/DisabledKeywords cannot take more than one argument.*$thisfile/ );

eval {
  $p = new Convert::Binary::C;
  $p->DisabledKeywords( ['auto', 'enum'] );
  $p->DisabledKeywords( ['void', 'while', 'register'] );
};
ok( $@, qr/Cannot disable unknown keyword 'while'.*$thisfile/ );
$kw = $p->DisabledKeywords;
ok( "@$kw", "auto enum", 'DisabledKeywords did not preserve configuration' );

#===================================================================
# check KeywordMap option
#===================================================================

eval {
  $p = new Convert::Binary::C;
  $p->configure( KeywordMap => 5 );
};
ok( $@, qr/KeywordMap wants a hash reference.*$thisfile/ );

eval {
  $p = new Convert::Binary::C;
  $p->configure( KeywordMap => [ __xxx__ => 'foo' ] );
};
ok( $@, qr/KeywordMap wants a hash reference.*$thisfile/ );

eval {
  $p = new Convert::Binary::C;
  $p->KeywordMap( { '' => 'int' } );
};
ok( $@, qr/Cannot use empty string as a keyword.*$thisfile/ );

eval {
  $p = new Convert::Binary::C;
  $p->KeywordMap( { '1_d' => 'int' } );
};
ok( $@, qr/Cannot use '1_d' as a keyword.*$thisfile/ );

eval {
  $p = new Convert::Binary::C;
  $p->KeywordMap( { '_d' => [] } );
};
ok( $@, qr/Cannot use a reference as a keyword.*$thisfile/ );

eval {
  $p = new Convert::Binary::C;
  $p->KeywordMap( { '_d' => 'foo' } );
};
ok( $@, qr/Cannot use 'foo' as a keyword.*$thisfile/ );

eval {
  $p = new Convert::Binary::C;
  $p->KeywordMap( {'__const' => 'const', '__restrict' => undef} );
  $p->KeywordMap( {'__volatile' => 'volatile', '__foo' => 'foo'} );
};
ok( $@, qr/Cannot use 'foo' as a keyword.*$thisfile/ );
$kw = $p->KeywordMap;
ok( "@{[sort keys %$kw]}", "__const __restrict", 'KeywordMap did not preserve configuration' );

#===================================================================
# check invalid configuration
#===================================================================
@tests = (
  { value => [1, 2, 3], result => FAIL, error => qr/Invalid number of arguments to configure.*$thisfile/ },
  { value => [[1], 2],  result => FAIL, error => qr/Option name must be a string, not a reference.*$thisfile/ },
);
foreach $config ( @tests )
{
  eval {
    $p = new Convert::Binary::C;
    $p->configure( @{$config->{value}} );
  };
  ok( ($@ eq '' ? SUCCEED : FAIL), $config->{result},
      "invalid configuration: " . join(', ', @{$config->{value}}) );
  ok( $@, $config->{error} ) if exists $config->{error};
}

#===================================================================
# check invalid option
#===================================================================
eval {
  $p = new Convert::Binary::C;
  $p->configure(
    Something => 'xxx',
    ByteOrder => 'BigEndian',
    EnumSize  => 0,
  );
};
ok( $@, qr/Invalid option 'Something'.*$thisfile/ );

#===================================================================
# check invalid method
#===================================================================
eval {
  $p = new Convert::Binary::C;
  $p->some_method( 1, 2, 3 );
};
ok( $@, qr/Invalid method some_method called.*$thisfile/ );

#===================================================================
# check configure returning the whole configuration
#===================================================================

%config = (
  'KeywordMap' => {},
  'DisabledKeywords' => [],
  'UnsignedBitfields' => 0,
  'UnsignedChars' => 0,
  'CharSize' => 1,
  'ShortSize' => 2,
  'EnumType' => 'Integer',
  'EnumSize' => 4,
  'Include' => [ '/usr/include' ],
  'DoubleSize' => 4,
  'FloatSize' => 4,
  'HasCPPComments' => 1,
  'Alignment' => 1,
  'CompoundAlignment' => 1,
  'Define' => [ 'DEBUGGING', 'FOO=123' ],
  'HasMacroVAARGS' => 1,
  'LongSize' => 4,
  'Warnings' => 0,
  'ByteOrder' => 'LittleEndian',
  'Assert' => [],
  'IntSize' => 4,
  'PointerSize' => 4,
  'LongLongSize' => 8,
  'LongDoubleSize' => 12,
  'OrderMembers' => 0,
  'Bitfields' => { Engine => 'Simple', BlockSize => 2 },
  'StdCVersion' => undef,
  'HostedC' => 0,
);

eval {
  $p = new Convert::Binary::C %config;
  $cfg = $p->configure;
};
ok( $@, '', "failed to retrieve configuration" );

ok( compare_config( \%config, $cfg ) );

#===================================================================
# check option chaining
#===================================================================

%newcfg = (
  'KeywordMap' => {'__signed__' => 'signed', '__restrict' => undef},
  'DisabledKeywords' => ['const', 'register'],
  'UnsignedBitfields' => 1,
  'UnsignedChars' => 1,
  'CharSize' => 2,
  'ShortSize' => 4,
  'EnumType' => 'Both',
  'EnumSize' => 0,
  'Include' => [ '/usr/local/include', '/usr/include', '/include' ],
  'DoubleSize' => 8,
  'FloatSize' => 8,
  'HasCPPComments' => 1,
  'Alignment' => 2,
  'CompoundAlignment' => 4,
  'Define' => [ 'DEBUGGING', 'FOO=123', 'BAR=456' ],
  'HasMacroVAARGS' => 1,
  'LongSize' => 4,
  'Warnings' => 1,
  'ByteOrder' => 'BigEndian',
  'Assert' => [],
  'IntSize' => 4,
  'PointerSize' => 2,
  'LongLongSize' => 8,
  'LongDoubleSize' => 12,
  'OrderMembers' => 0,
  'Bitfields' => { Engine => 'Simple', BlockSize => 4 },
  'StdCVersion' => 199901,
  'HostedC' => undef,
);

@warn = ();

eval {
  local $SIG{__WARN__} = sub { push @warn, shift };

  $p = new Convert::Binary::C %config;

  $p->UnsignedChars( 1 )->configure( ShortSize => 4, EnumType => 'Both', EnumSize => 0 )
    ->Include( ['/usr/local/include'] )->DoubleSize( 8 )
    ->CompoundAlignment( 4 );

  $p->FloatSize( 8 )->Include( qw( /usr/include /include ) )->DisabledKeywords( [qw( const register )] )
    ->Alignment( 2 )->Define( qw( BAR=456 ) )->configure( ByteOrder => 'BigEndian' );

  $p->configure( PointerSize => 2 )->Warnings( 1 )->UnsignedBitfields( 1 )
    ->KeywordMap( {'__signed__' => 'signed', '__restrict' => undef} );

  $p->CharSize(2);

  $p->Bitfields( { BlockSize => 4 } );

  $p->configure(StdCVersion => 199901);

  $p->HostedC(undef);

  $cfg = $p->configure;
};
ok( $@, '', "failed to configure object" );

if( @warn ) { print "# issued warnings:\n", map "#   $_", @warn }
ok( scalar @warn, 0, "invalid number of warnings issued" );

ok( compare_config( \%newcfg, $cfg ) );

$debug and $result = checkrc( Convert::Binary::C::__DUMP__( $cfg ) );
skip( $RDBG, $result );
