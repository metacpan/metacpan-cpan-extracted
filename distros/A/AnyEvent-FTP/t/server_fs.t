use strict;
use warnings;
use File::Spec;
use Test::More;
use Test::AnyEventFTPServer;
use File::Temp qw( tempdir );
use Cwd ();

*my_abs_path = $^O eq 'MSWin32' ? sub ($) { $_[0] } : \&Cwd::abs_path ;

foreach my $type (qw( FS FSRW ))
{
  my $tmp = my_abs_path(tempdir( CLEANUP => 1 ));
  my $tmp_unmodified = $tmp;

  if($^O eq 'MSWin32')
  {
    chdir $tmp;
    note "changing to $tmp";
    (undef, $tmp) = File::Spec->splitpath($tmp,1);
    $tmp =~ s{\\}{/}g;
  }
  
  mkdir "$tmp/a";
  mkdir "$tmp/b";

  my $t = create_ftpserver_ok($type);

  my $context;
  $t->on_connect(sub {
    $context = shift->context;
  });

  $t->help_coverage_ok;

  ok -d $context->cwd, "cwd " . $context->cwd . " exists";

  $t->command_ok('CWD')
    ->code_is(550)
    ->message_like(qr{CWD error});

  $t->command_ok('CWD', "$tmp/a")
    ->code_is(250)
    ->message_like(qr{CWD command successful});

  is $context->cwd, File::Spec->catdir($tmp_unmodified, 'a'), "cwd = $tmp_unmodified/a";

  $t->command_ok('CDUP')
    ->code_is(250)
    ->message_like(qr{CDUP command successful});

  is $context->cwd, "$tmp_unmodified", "cwd = $tmp_unmodified";
  
  $t->command_ok('PWD')
    ->code_is(257)
    ->message_like(qr{"$tmp" is the current directory});
    
  my $size = do {
    open my $fh, '>', "$tmp/roger.txt";
    print $fh "hello there";
    close $fh;
    -s "$tmp/roger.txt";
  };
  
  $t->command_ok('SIZE')
    ->code_is(550);
    
  $t->command_ok('SIZE', "roger.txt")
    ->code_is(213)
    ->message_like(qr{^$size$});
    
  $t->command_ok('SIZE', "$tmp/a")
    ->code_is(550)
    ->message_like(qr{\: not a regular file});
    
  $t->command_ok("MKD")
    ->code_is(550)
    ->message_like(qr{MKD error});
    
  $t->command_ok("MKD", "c")
    ->code_is(257)
    ->message_like(qr{Directory created});
    
  ok -d "$tmp/c", "MKD created directory $tmp/c";
  
  $t->command_ok("RMD")
    ->code_is(550)
    ->message_like(qr{RMD error});

  $t->command_ok("RMD", "d")
    ->code_is(550)
    ->message_like(qr{RMD error});
  
  $t->command_ok("RMD", "b")
    ->code_is(250)
    ->message_like(qr{Directory removed});
  
  ok ! -d "$tmp/b", "RMD deleted directory $tmp/b";
  
  $t->command_ok("DELE")
    ->code_is(550)
    ->message_like(qr{DELE error});
  
  $t->command_ok("DELE", "bogus.txt")
    ->code_is(550)
    ->message_like(qr{DELE error});
  
  $t->command_ok("DELE", "roger.txt")
    ->code_is(250)
    ->message_like(qr{File removed});
    
  ok ! -e "$tmp/roger.txt", "roger.txt was deleted";
  
  $t->command_ok("RNFR")
    ->code_is(501)
    ->message_like(qr{Invalid number of arguments});
  
  $t->command_ok("RNFR", "foo.txt")
    ->code_is(550)
    ->message_like(qr{No such file or directory});
  
  $size = do {
    open my $fh, '>', "$tmp/foo.txt";
    print $fh "some not so random data\n";
    close $fh;
    -s "$tmp/foo.txt";
  };
  
  $t->command_ok("RNFR", "foo.txt")
    ->code_is(350)
    ->message_like(qr{File or directory exists, ready for destination name});
    
  # TODO more RNTO tests (RNFR has good coverage)
  $t->command_ok("RNTO", "bar.txt")
    ->code_is(250)
    ->message_like(qr{Rename successful});
    
  $t->command_ok("STAT")
    ->code_is(211);
  
  $t->command_ok("STAT", "bar.txt")
    ->code_is(211)
    ->message_like(qr{file});
  
  $t->command_ok("STAT", "$tmp/a")
    ->code_is(211)
    ->message_like(qr{dir});
}

if($^O eq 'MSWin32')
{
  note "changing to " . File::Spec->rootdir;
  chdir(File::Spec->rootdir);
}

done_testing;
