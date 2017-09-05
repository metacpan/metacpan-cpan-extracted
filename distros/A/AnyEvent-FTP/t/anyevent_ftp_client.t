use 5.010;
use lib 't/lib';
use Test2::V0 -no_srand => 1;
use Test2::Tools::ClientTests;
use AnyEvent::FTP::Client;
use File::Temp qw( tempdir );

subtest 'syst' => sub {
  reset_timeout;

  my $client = eval { AnyEvent::FTP::Client->new };
  diag $@ if $@;
  isa_ok $client, 'AnyEvent::FTP::Client';
  
  prep_client( $client );
  
  our $config;
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  
  my $res = eval { $client->syst->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  is eval { $res->code }, 215, 'code = 215';
  diag $@ if $@;
  
  $client->quit->recv;

  
};

subtest 'retr' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  my $fn = File::Spec->catfile($config->{dir}, 'foo.txt');
  do {
    open my $fh, '>', $fn;
    say $fh "line 1";
    say $fh "line 2";
    close $fh;
  };
  
  foreach my $passive (0,1)
  {
  
    my $client = AnyEvent::FTP::Client->new( passive => $passive );
  
    prep_client( $client );
  
    $client->connect($config->{host}, $config->{port})->recv;
    $client->login($config->{user}, $config->{pass})->recv;
    $client->type('I')->recv;
    $client->cwd($config->{dir})->recv;
  
    do {
      my $dest_fn = File::Spec->catdir(tempdir( CLEANUP => 1 ), 'foo.txt');
  
      my $ret = eval { $client->retr('foo.txt', $dest_fn)->recv; };
      diag $@ if $@;
      isa_ok $ret, 'AnyEvent::FTP::Response';
      my @data = split /\015?\012/, do {
        open my $fh, '<', $dest_fn;
        local $/;
        <$fh>;
      };
      is $data[0], 'line 1';
      is $data[1], 'line 2';
    };
  
    do {
      my $data = '';
      my $xfer = eval { $client->retr('foo.txt') };
      isa_ok $xfer, 'AnyEvent::FTP::Client::Transfer';
      $xfer->on_open(sub {
        my $handle = shift;
        $handle->on_read(sub {
          $handle->push_read(sub {
            $data .= $_[0]{rbuf};
            $_[0]{rbuf} = '';
          });
        });
      });
      
      my $ret = eval { $xfer->recv };
      isa_ok $ret, 'AnyEvent::FTP::Response';
      my @data = split /\015?\012/, $data;
      is $data[0], 'line 1';
      is $data[1], 'line 2';
    };
    
    do {
      my $data = '';
      my $ret = eval { $client->retr('foo.txt', sub { $data .= shift })->recv; };
      diag $@ if $@;
      isa_ok $ret, 'AnyEvent::FTP::Response';
      my @data = split /\015?\012/, $data;
      is $data[0], 'line 1';
      is $data[1], 'line 2';
    };
  
    do {
      my $data = '';
      my $ret = eval { $client->retr('foo.txt', \$data)->recv; };
      diag $@ if $@;
      isa_ok $ret, 'AnyEvent::FTP::Response';
      my @data = split /\015?\012/, $data;
      is $data[0], 'line 1';
      is $data[1], 'line 2';
    };
  
    do {
      my $data = '';
      open my $fh, '>', \$data;
      my $ret = eval { $client->retr('foo.txt', $fh)->recv; };
      diag $@ if $@;
      close $fh;
      isa_ok $ret, 'AnyEvent::FTP::Response';
      my @data = split /\015?\012/, $data;
      is $data[0], 'line 1';
      is $data[1], 'line 2';
    };
  
    $client->quit->recv;
  }
};

subtest 'help' => sub {
  reset_timeout;
  my $client = AnyEvent::FTP::Client->new;
  
  prep_client( $client );
  our $config;
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  
  do {
    my $res = eval { $client->help->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    my $code = eval { $res->code };
    diag $@ if $@;
    like $code, qr{^21[14]$}, 'code = ' . $code;
  };
  
  do {
    my $res = eval { $client->help('help')->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    my $code = eval { $res->code };
    diag $@ if $@;
    like $code, qr{^21[14]$}, 'code = ' . $code;
  };
  
  SKIP: {
    our $detect;
    skip 'pure-FTPd does not return 502 on bogus help', 2 if $detect->{pu};
    skip 'vsftp does not return 502 on bogus help', 2 if $detect->{vs};
    skip 'Net::FTPServer does not return 502 on bogus help', 2 if $detect->{pl};
    skip 'ncftpd does not return 502 on bogus help', 2 if $detect->{nc};
    skip 'bftp does not respond to help bogus', 2 if $detect->{xb};
    eval { $client->help('bogus')->recv };
    my $res = $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    my $code = eval { $res->code };
    diag $@ if $@;
    like $code, qr{^50[12]$}, 'code = ' . $code;
  };
  
  $client->quit->recv;
  
};

subtest 'type' => sub {
  reset_timeout;
  my $client = eval { AnyEvent::FTP::Client->new };
  diag $@ if $@;
  isa_ok $client, 'AnyEvent::FTP::Client';
  
  our $config;
  
  prep_client($client);
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  
  do {
    my $res = eval { $client->type('I')->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    is eval { $res->code }, 200, 'code = 200';
    diag $@ if $@;
  };
  
  do {
    my $res = eval { $client->type('A')->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    is eval { $res->code }, 200, 'code = 200';
    diag $@ if $@;
  };
  
  do {
    eval { $client->type('X')->recv };
    my $error = $@;
    isa_ok $error, 'AnyEvent::FTP::Response';
    like eval { $error->code }, qr{^50[104]$}, 'code = ' . eval { $error->code };
    diag $@ if $@;
  };
  
  $client->quit->recv;
  
};

subtest 'allo' => sub {
  reset_timeout;
  my $client = AnyEvent::FTP::Client->new;
  
  prep_client( $client );
  our $config;
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  
  our $detect;
  skip_all 'wu-ftpd does not support ALLO' if $detect->{wu};
  skip_all 'proftpd does not support ALLO' if $detect->{pr};
  
  my $res = eval { $client->allo('foo')->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  like eval { $res->code }, qr{^20[02]$}, 'code = ' . eval { $res->code };
  diag $@ if $@;
  
  SKIP: {
    skip 'pure-ftpd does not support ALLO without argument', 2 if $detect->{pu};
    skip 'IIS does not support ALLO without argument', 2 if $detect->{ms};
  
    my $res = eval { $client->allo->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    like eval { $res->code }, qr{^20[02]$}, 'code = ' . eval { $res->code };
    diag $@ if $@;
  }
  
  $client->quit->recv;
  
};

subtest 'mkd' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  my $client = AnyEvent::FTP::Client->new;
  
  prep_client( $client );
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;
  $client->cwd($config->{dir})->recv;
  
  do {
    my $ret = eval { $client->mkd('foo')->recv; };
    diag $@ if $@;
    isa_ok $ret, 'AnyEvent::FTP::Response';
      
    my $dir_name = File::Spec->catdir($config->{dir}, 'foo');
    ok -d $dir_name, "dir created: $dir_name";
      
    rmdir $dir_name;
      
    ok !-d $dir_name, "dir deleted";
  };
    
  $client->quit->recv;
};

subtest 'nlst' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  foreach my $name (qw( foo bar baz ))
  {
    my $fn = File::Spec->catfile($config->{dir}, "$name.txt");
    open my $fh, '>', $fn;
    close $fh;
  }
  
  my $dir2 = File::Spec->catdir($config->{dir}, "dir2");
  mkdir $dir2;
  
  foreach my $name (qw( dr.pepper coke pepsi ))
  {
    my $fn = File::Spec->catfile($config->{dir}, 'dir2', "$name.txt");
    open my $fh, '>', $fn;
    close $fh;
  }
  
  foreach my $passive (0,1)
  {
    my $client = AnyEvent::FTP::Client->new( passive => $passive );
  
    prep_client( $client );
  
    $client->connect($config->{host}, $config->{port})->recv;
    $client->login($config->{user}, $config->{pass})->recv;
    $client->type('I')->recv;
    $client->cwd($config->{dir})->recv;
  
    do {
      my $list = eval { $client->nlst->recv };
      diag $@ if $@;
      is $list, array { etc() };
      $list //= [];
      @$list = grep !/^dir2$/, @$list;
      is [ sort @$list ], [ sort qw( foo.txt bar.txt baz.txt ) ], 'nlst 1';
      #note 'actual:   ' . join(' ', sort @$list);
      #note 'expected: ' . join(' ', sort qw( foo.txt bar.txt baz.txt ));
    };
  
    do {
      my $list = eval { $client->nlst('dir2')->recv };
      diag $@ if $@;
      is $list, array { etc() };
      $list //= [];
      our $detect;
      # workaround here for Net::FTPServer and pure-ftpd, unlike other wu,vs and pro ftpd does not include the path name
      is [ sort @$list ], [ sort map { $detect->{pl} || $detect->{pu} || $detect->{xb} ? "$_.txt" : "dir2/$_.txt" } qw( dr.pepper coke pepsi ) ], 'nlst 1';
      #note "list: $_" for @$list;
    };
  
    $client->quit->recv;
  }
};

subtest '00' => sub {
  reset_timeout;
  my $client = eval { AnyEvent::FTP::Client->new };
  diag $@ if $@;
  isa_ok $client, 'AnyEvent::FTP::Client';
  
  prep_client( $client );
  
  our $config;
  
  $client->on_greeting(sub {
    my $res = shift;
    diag "$res";
  });
  
  $client->connect($config->{host}, $config->{port})->recv;
  
  $client->quit->recv;
  
};

subtest 'dele' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  my $client = AnyEvent::FTP::Client->new;
  
  prep_client( $client );
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;
  $client->cwd($config->{dir})->recv;
  
  do {
    my $fn = File::Spec->catfile($config->{dir}, 'foo.txt');
    do { open my $fh, '>', $fn; close $fh; };
    
    ok -e $fn, "created file";
    
    my $ret = eval { $client->dele('foo.txt')->recv; };
    diag $@ if $@;
    isa_ok $ret, 'AnyEvent::FTP::Response';
    
    ok !-e $fn, "deleted file";
  };
    
  do {
    my $fn = File::Spec->catfile($config->{dir}, 'bar.txt');
  
    ok !-e $fn, "created file";
    
    eval { $client->dele('foo.txt')->recv; };
    my $res = $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    
    ok !-e $fn, "deleted file";
  };
    
  $client->quit->recv;
};

subtest 'site_proftpd' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  my $client = AnyEvent::FTP::Client->new;
  
  prep_client( $client );
  
  eval {
    $client->connect($config->{host}, $config->{port})->recv;
    $client->login($config->{user}, $config->{pass})->recv;
    $client->type('I')->recv;
    $client->cwd($config->{dir})->recv;
    our $detect;
    unless($detect->{pr})
    {
      $client->quit->recv;
      die "not ProFTPd" unless $detect->{pr};
    }
  };
  skip_all 'requires Proftpd to test against' if $@;
  
  do {
    my $dir_name = File::Spec->catdir($config->{dir}, 'foo');
    
    do {
      my $res = eval { $client->site->proftpd->mkdir('foo')->recv };
      diag $@ if $@;
      isa_ok $res, 'AnyEvent::FTP::Response';
    };
  
    ok -d $dir_name, "dir foo created";
    
    do {
      my $res = eval { $client->site->proftpd->rmdir('foo')->recv };
      diag $@ if $@;
      isa_ok $res, 'AnyEvent::FTP::Response';
    };
  
    ok !-d $dir_name, "dir foo deleted";
  };
  
  do {
    do {
      open(my $fh, '>', File::Spec->catfile($config->{dir}, 'target'));
      close $fh;
    };
    
    do {
      my $res = eval { $client->site->proftpd->symlink('target', 'link')->recv };
      diag $@ if $@;
      isa_ok $res, 'AnyEvent::FTP::Response';
    };
    
    like readlink(File::Spec->catfile($config->{dir}, 'link')), qr{target$}, "link => target";
    
  };
    
  $client->quit->recv;
};

subtest 'remote' => sub {
  reset_timeout;
  local $ENV{AEF_REMOTE} //= tempdir( CLEANUP => 1 );
  
  our $config;
  our $detect;
  
  foreach my $passive (0,1)
  {
  
    my $client = AnyEvent::FTP::Client->new( passive => $passive );
  
    prep_client( $client );
  
    $client->connect($config->{host}, $config->{port})->recv;
    $client->login($config->{user}, $config->{pass})->recv;
    $client->type('I')->recv;
  
    isa_ok $client->cwd($ENV{AEF_REMOTE})->recv, 'AnyEvent::FTP::Response';
    
    do {
      my $dir = $client->pwd->recv;
      is $dir, net_pwd($ENV{AEF_REMOTE}), "dir = " .net_pwd($ENV{AEF_REMOTE});
    };
  
    my $dirname = join '', map { chr(ord('a') + int(rand(23))) } (1..10);
    
    isa_ok $client->mkd($dirname)->recv, 'AnyEvent::FTP::Response';
    isa_ok $client->cwd($dirname)->recv, 'AnyEvent::FTP::Response';
  
    SKIP: {
      skip 'wu-ftpd throws an exception on empty directory', 2 if $detect->{wu};
      my $res = $client->nlst->recv;
      is $res, array { etc() };
      is scalar(@$res), 0, 'list empty';
      if(scalar(@$res) > 0)
      {
        diag "~~~ nlst ~~~";
        diag $_ for @$res;
        diag "~~~~~~~~~~~~";
      }
    };
    
    isa_ok $client->stor('foo.txt', \"here is some data eh\n")->recv, 'AnyEvent::FTP::Response';
    
    do {
      my $res = $client->nlst->recv;
      is $res, array { etc() };
      is scalar(@$res), 1, 'list not empty';
      is $res->[0], 'foo.txt';
    };
    
    do {
      my $res = $client->list->recv;
      is $res, array { etc() };
      is scalar(grep /foo.txt$/, @$res), 1, 'has foo.txt in listing';
    };
    
    do {
      my $data = '';
      isa_ok $client->retr('foo.txt', \$data)->recv, 'AnyEvent::FTP::Response';
      is $data, "here is some data eh\n", 'retr ok';
    };
  
    isa_ok $client->appe('foo.txt', \"line 2\n")->recv, 'AnyEvent::FTP::Response';
  
    do {
      my $data = '';
      isa_ok $client->retr('foo.txt', \$data)->recv, 'AnyEvent::FTP::Response';
      is $data, "here is some data eh\nline 2\n", 'retr ok';
    };
  
    isa_ok $client->rename('foo.txt', 'bar.txt')->recv, 'AnyEvent::FTP::Response';
  
    do {
      my $res = $client->nlst->recv;
      is $res, array { etc() };
      is scalar(@$res), 1, 'list not empty';
      is $res->[0], 'bar.txt';
    };
    
    do {
      my $res = $client->list->recv;
      is $res, array { etc() };
      is scalar(grep /bar.txt$/, @$res), 1, 'has bar.txt in listing';
    };
  
    do {
      my $data = "here is some data";
      isa_ok $client->retr('bar.txt', \$data, restart => do { use bytes; length $data})->recv, 'AnyEvent::FTP::Response';
      is $data, "here is some data eh\nline 2\n", 'rest, retr ok';
    };
  
    isa_ok $client->dele('bar.txt')->recv, 'AnyEvent::FTP::Response';
  
    # ...  
    
    isa_ok $client->cdup->recv, 'AnyEvent::FTP::Response';
    isa_ok $client->rmd($dirname)->recv, 'AnyEvent::FTP::Response';
    isa_ok $client->quit->recv, 'AnyEvent::FTP::Response';
  }
  
};

subtest 'rmd' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  my $client = AnyEvent::FTP::Client->new;
  
  prep_client( $client );
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;
  $client->cwd($config->{dir})->recv;
  
  do {
    my $dir_name = File::Spec->catdir($config->{dir}, 'foo');
    mkdir $dir_name;
    my $ret = eval { $client->rmd('foo')->recv; };
    diag $@ if $@;
    isa_ok $ret, 'AnyEvent::FTP::Response';
    ok !-d $dir_name, "dir removed: $dir_name";
    rmdir $dir_name if -d $dir_name;
  };
    
  $client->quit->recv;
};

subtest 'stou' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  my $plan = sub {
    state $first = 0;
    return unless ++$first == 1;
    our $detect;
    skip_all 'wu-ftpd does not support STOU'
      if $detect->{wu};
    skip_all 'bftp does not support STOU'
      if $detect->{xb};
    skip_all 'vsftpd does not support STOU without an argument'
      if $detect->{vs};
  };
    
  foreach my $passive (0,1)
  {
  
    my $client = AnyEvent::FTP::Client->new( passive => $passive );
  
    prep_client( $client );
  
    $client->connect($config->{host}, $config->{port})->recv;
    $client->login($config->{user}, $config->{pass})->recv;
    $client->type('I')->recv;
    $client->cwd($config->{dir})->recv;
    
    $plan->();
  
    do {
      my $data = 'some data';
      my $xfer = eval { $client->stou(undef, \$data) };
      diag $@ if $@;
      isa_ok $xfer, 'AnyEvent::FTP::Client::Transfer';
      my $ret = eval { $xfer->recv; };
      diag $@ if $@;
      isa_ok $ret, 'AnyEvent::FTP::Response';
      
      my @list = do {
        opendir my $dh, $config->{dir};
        grep !/^\./, readdir $dh;
      };
      
      is scalar(@list), 1, 'exactly one file';
      my $fn = File::Spec->catfile($config->{dir}, $list[0]);
      is $xfer->remote_name, $list[0], "remote_name = $list[0]";
  
      my $remote = do {
        open my $fh, '<', $fn;
        local $/;
        <$fh>;
      };
      
      is $remote, $data, 'local/remote match';
      
      unlink $fn;
      
      ok !-e $fn, 'remote deleted';
    };
    
    $client->quit->recv;
  }
};

subtest 'stat' => sub {
  reset_timeout;
  my $client = AnyEvent::FTP::Client->new;
  
  prep_client( $client );
  our $config;
  our $detect;
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  
  skip_all 'ncftp return code broken' if $detect->{nc};
  
  do {
    my $res = eval { $client->stat->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    my $code = eval { $res->code };
    diag $@ if $@;
    like $code, qr{^21[123]$}, 'code = ' . $code;
  };
  
  do {
    my $res = eval { $client->stat('/')->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    my $code = eval { $res->code };
    diag $@ if $@;
    like $code, qr{^21[123]$}, 'code = ' . $code;
  };
  
  SKIP: {
    skip 'wu-ftpd does not return [45]50 on bogus file', 2 if $detect->{wu};
    skip 'pure-FTPd does not return [45]50 on bogus file', 2 if $detect->{pu};
    skip 'vsftp does not return [45]50 on bogus file', 2 if $detect->{vs};
    skip 'IIS does not return [45]50 on bogus file', 2 if $detect->{ms};
    skip 'bftp does not return [45]50 on bogus file', 2 if $detect->{xb};
    eval { $client->stat('bogus')->recv };
    my $res = $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    my $code = eval { $res->code };
    diag $@ if $@;
    like $code, qr{^[45]50$}, 'code = ' . $code;
  };
  
  $client->quit->recv;
  
};

subtest 'rename' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  my $client = AnyEvent::FTP::Client->new;
  
  prep_client( $client );
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;
  $client->cwd($config->{dir})->recv;
  
  do {
    my $from = File::Spec->catfile($config->{dir}, 'foo.txt');
    do { open my $fh, '>', $from; close $fh; };
    my $to   = File::Spec->catfile($config->{dir}, 'bar.txt');
    
    ok  -e $from, "EX: $from";
    ok !-e $to,   "NO: $to";
    
    my $res1 = eval { $client->rnfr($from)->recv };
    diag $@ if $@;
    isa_ok $res1, 'AnyEvent::FTP::Response';
    
    my $res2 = eval { $client->rnto($to)->recv };
    diag $@ if $@;
    isa_ok $res2, 'AnyEvent::FTP::Response';
    
    ok !-e $from, "NO: $from";
    ok  -e $to,   "EX: $to";
  };
    
  do {
    my $from = File::Spec->catfile($config->{dir}, 'pepper.txt');
    do { open my $fh, '>', $from; close $fh; };
    my $to   = File::Spec->catfile($config->{dir}, 'coke.txt');
    
    ok  -e $from, "EX: $from";
    ok !-e $to,   "NO: $to";
    
    my $res = eval { $client->rename($from, $to)->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    
    ok !-e $from, "NO: $from";
    ok  -e $to,   "EX: $to";
  };
    
  $client->quit->recv;
};

subtest 'list' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  foreach my $name (qw( foo bar baz ))
  {
    my $fn = File::Spec->catfile($config->{dir}, "$name.txt");
    open my $fh, '>', $fn;
    close $fh;
  }
  
  my $dir2 = File::Spec->catdir($config->{dir}, "dir2");
  mkdir $dir2;
  
  foreach my $name (qw( dr.pepper coke pepsi ))
  {
    my $fn = File::Spec->catfile($config->{dir}, 'dir2', "$name.txt");
    open my $fh, '>', $fn;
    close $fh;
  }
  
  foreach my $passive (0,1)
  {
  
    my $client = AnyEvent::FTP::Client->new( passive => $passive );
  
    prep_client( $client );
  
    $client->connect($config->{host}, $config->{port})->recv;
    $client->login($config->{user}, $config->{pass})->recv;
    $client->type('I')->recv;
    $client->cwd($config->{dir})->recv;
  
    subtest 'listing with directory' => sub {
      my $list = eval { $client->list->recv };
      diag $@ if $@;
      is $list, array { etc() };
      $list //= [];
      # wu-ftpd
      shift @$list if $list->[0] =~ / \d+$/i;
      # Net::FTPServer
      shift @$list if $list->[0] =~ /\s\.$/;
      shift @$list if $list->[0] =~ /\s\.\.$/;
      is scalar(@$list), 4, 'list length 4';
      is scalar(grep /foo.txt$/, @$list), 1, 'has foo.txt';
      is scalar(grep /bar.txt$/, @$list), 1, 'has bar.txt';
      is scalar(grep /baz.txt$/, @$list), 1, 'has baz.txt';
      is scalar(grep /dir2$/, @$list), 1, 'has dir2';
      #note "list: $_" for @$list;
    };
  
  
    subtest 'listing in sub directory' => sub {
      my $list = eval { $client->list('dir2')->recv };
      diag $@ if $@;
      is $list, array { etc() };
      $list //= [];
      # wu-ftpd
      shift @$list if $list->[0] =~ / \d+$/i;
      # Net::FTPServer
      shift @$list if $list->[0] =~ /\s\.$/;
      shift @$list if $list->[0] =~ /\s\.\.$/;
      is scalar(@$list), 3, 'list length 3';
      is scalar(grep /dr.pepper.txt$/, @$list), 1, 'has dr.pepper.txt';
      is scalar(grep /coke.txt$/, @$list), 1, 'has coke.txt';
      is scalar(grep /pepsi.txt$/, @$list), 1, 'has pepsi.txt';
      #note "list: $_" for @$list;
    };
  
    $client->quit->recv;
  }
};

subtest 'stor' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );

  foreach my $passive (0,1)
  {

    subtest "passive = $passive" => sub {
  
      my $client = AnyEvent::FTP::Client->new( passive => $passive );
  
      prep_client( $client );
  
      $client->connect($config->{host}, $config->{port})->recv;
      $client->login($config->{user}, $config->{pass})->recv;
      $client->type('I')->recv;
      $client->cwd($config->{dir})->recv;
  
      my $fn = File::Spec->catfile($config->{dir}, 'foo.txt');
  
      do {
        my $data = 'some data';
        my $src_fn = do {
          my $fn = File::Spec->catfile(tempdir(CLEANUP => 1), 'foo.txt');
          open my $fh, '>', $fn;
          print $fh $data;
          close $fh;
          $fn;
        };
  
        my $ret = eval { $client->stor('foo.txt', $src_fn)->recv; };
        diag $@ if $@;
        isa_ok $ret, 'AnyEvent::FTP::Response';
        ok -e $fn, 'remote file created';
        my $remote = do {
          open my $fh, '<', $fn;
          local $/;
          <$fh>;
        };
        is $remote, $data, 'remote matches';
      };
  
      do {
        my $data = 'some data';
        my $xfer = eval { $client->stor('foo.txt') };
        isa_ok $xfer, 'AnyEvent::FTP::Client::Transfer';
    
        my $called_open = 0;
        my $called_close = 0;
  
        $xfer->on_open(sub {
          $called_open = 1;
          my $handle = shift;
          $handle->on_drain(sub {
            $handle->push_write($data);
            $handle->on_drain(sub {
              $handle->push_shutdown;
            });
          });
        });
        
        $xfer->on_close(sub {
          $called_close = 1;
        });
      
        my $res = eval { $xfer->recv };
        isa_ok $res, 'AnyEvent::FTP::Response';
  
        ok -e $fn, 'remote file created';
        my $remote = do {
          open my $fh, '<', $fn;
          local $/;
          <$fh>;
        };
        is $remote, $data, 'remote matches';
      
        is $called_open, 1, 'open emit';
        is $called_close, 1, 'close emit';
      };
    
      unlink $fn;
      ok !-e $fn, 'remote file deleted';
  
      do {
        my $data = 'some data';
        my $xfer = eval { $client->stor('foo.txt', \$data) };
        diag $@ if $@;
        isa_ok $xfer, 'AnyEvent::FTP::Client::Transfer';
        my $ret = eval { $xfer->recv; };
        diag $@ if $@;
        isa_ok $ret, 'AnyEvent::FTP::Response';
        ok -e $fn, 'remote file created';
        my $remote = do {
          open my $fh, '<', $fn;
          local $/;
          <$fh>;
        };
        is $remote, $data, 'remote matches';
        is $xfer->remote_name, 'foo.txt', 'remote_name = foo.txt';
      };
    
      unlink $fn;
      ok !-e $fn, 'remote file deleted';
    
      do {
        my $data = 'some data';
        my $cb = do {
          my $buffer = $data;
          sub {
            my $tmp = $buffer;
            undef $buffer;
            $tmp;
          };
        };
        my $ret = eval { $client->stor('foo.txt', $cb)->recv; };
        diag $@ if $@;
        isa_ok $ret, 'AnyEvent::FTP::Response';
        ok -e $fn, 'remote file created';
        my $remote = do {
          open my $fh, '<', $fn;
          local $/;
          <$fh>;
        };
        is $remote, $data, 'remote matches';
      };
    
      unlink $fn;
      ok !-e $fn, 'remote file deleted';
  
      do {
        my $data = 'some data';
        my $glob = do {
          my $dir = tempdir( CLEANUP => 1);
          my $fn = File::Spec->catfile($dir, 'flub.txt');
          open my $out, '>', $fn;
          binmode $out;
          print $out $data;
          close $out;
          open my $in, '<', $fn;
          binmode $in;
          $in;
        };
        my $ret = eval { $client->stor('foo.txt', $glob)->recv; };
        diag $@ if $@;
        isa_ok $ret, 'AnyEvent::FTP::Response';
        ok -e $fn, 'remote file created';
        my $remote = do {
          open my $fh, '<', $fn;
          local $/;
          <$fh>;
        };
        is $remote, $data, 'remote matches';
      };
    
      unlink $fn;
      ok !-e $fn, 'remote file deleted';
    
      $client->quit->recv;
    };
  }
  
};

subtest 'login' => sub {
  reset_timeout;
  my $client = eval { AnyEvent::FTP::Client->new };
  diag $@ if $@;
  isa_ok $client, 'AnyEvent::FTP::Client';
  
  prep_client( $client );
  
  our $config;
  
  $client->connect($config->{host}, $config->{port})->recv;
  
  my $res = eval { $client->login($config->{user}, $config->{pass})->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  
  is $res->code, 230, 'code = 230';
  
  is eval { $client->quit->recv->code }, 221, 'code = 221';
  diag $@ if $@;
  
  $client->connect($config->{host}, $config->{port})->recv;
  
  eval { $client->login('bogus', 'bogus')->recv };
  my $error = $@;
  isa_ok $error, 'AnyEvent::FTP::Response';
  is $error->code, 530, 'code = 530';
  
  eval { $client->quit->recv };
};

subtest 'uri' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  skip_all 'requires URI' unless eval q{ require URI };
  
  my $client = eval { AnyEvent::FTP::Client->new };
  diag $@ if $@;
  isa_ok $client, 'AnyEvent::FTP::Client';
  
  our $config;
  our $detect;
  
  prep_client( $client );
  
  my $uri = URI->new('ftp:');
  $uri->host($config->{host});
  $uri->port($config->{port});
  $uri->user($config->{user});
  $uri->password($config->{pass});
  $uri->path(do {
    my $dir = $config->{dir};
    if($^O eq 'MSWin32')
    {
      (undef,$dir,undef) = File::Spec->splitpath($dir,1);
      $dir =~ s{\\}{/}g;
    }
    $dir;
  });
  isa_ok $uri, 'URI';
  
  do {
    my $res = eval { $client->connect($uri)->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    is $res->code, 250, 'code = 250';
    is $client->pwd->recv, net_pwd($config->{dir}), "dir = " . net_pwd($config->{dir});
    $client->quit->recv;
  };
  
  do {
    my $res = eval { $client->connect($uri->as_string)->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
    is $res->code, 250, 'code = 250';
    is $client->pwd->recv, net_pwd($config->{dir}), "dir = " . net_pwd($config->{dir});
    $client->quit->recv;
  };
  
  $uri->user('bogus');
  $uri->password('bogus');
  
  SKIP: {
    skip 'bftp quit broken', 2 if $detect->{xb};
    eval { $client->connect($uri->as_string)->recv };
    my $error = $@;
    isa_ok $error, 'AnyEvent::FTP::Response';
    is $error->code, 530, 'code = 530';
    $client->quit->recv;
  };
  
  $uri->user($config->{user});
  $uri->password($config->{pass});
  $uri->path('/bogus/bogus/bogus');
  
  SKIP: {
    skip 'bftp quit broken', 2 if $detect->{xb};
    eval { $client->connect($uri->as_string)->recv };
    my $error = $@;
    isa_ok $error, 'AnyEvent::FTP::Response';
    is $error->code, 550, 'code = 550';
    $client->quit->recv;
  };
};

subtest 'rest' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  my $fn = File::Spec->catfile($config->{dir}, 'foo.txt');
  do {
    open my $fh, '>', $fn;
    print $fh "012345678901234567890";
    close $fh;
  };
  
  foreach my $passive (0,1)
  {
  
    my $client = AnyEvent::FTP::Client->new( passive => $passive );
  
    prep_client( $client );
  
    $client->connect($config->{host}, $config->{port})->recv;
    $client->login($config->{user}, $config->{pass})->recv;
    $client->type('I')->recv;
    $client->cwd($config->{dir})->recv;
  
    do {
      my $data = '0123456789';
      my $ret1 = eval { $client->rest(10)->recv; };
      diag $@ if $@;
      isa_ok $ret1, 'AnyEvent::FTP::Response';
      
      my $ret2 = eval { $client->retr('foo.txt', sub { $data .= shift }, restart => length $data)->recv; };
      diag $@ if $@;
      isa_ok $ret2, 'AnyEvent::FTP::Response';
      is $data, "012345678901234567890", 'data = "012345678901234567890"';
    };
  
    $client->quit->recv;
  }
};

subtest 'connect' => sub {
  reset_timeout;
  my $done = AnyEvent->condvar;
  
  my $client = eval { AnyEvent::FTP::Client->new };
  diag $@ if $@;
  isa_ok $client, 'AnyEvent::FTP::Client';
  
  $client->on_close(sub { $done->send });
  
  our $config;
  
  prep_client( $client );
  
  do {
    my $condvar = eval { $client->connect($config->{host}, $config->{port}) };
    diag $@ if $@;
    
    my $res = eval { $condvar->recv };
    diag $@ if $@;
    
    isa_ok $res, 'AnyEvent::FTP::Response';
    is $res->code, 220, 'code = 220';
  };
  
  is eval { $client->push_command([USER => $config->{user}])->recv->code }, 331, 'code = 331';
  diag $@ if $@;
  is eval { $client->push_command([PASS => $config->{pass}])->recv->code }, 230, 'code = 230';
  diag $@ if $@;
  
  my $help_cv = $client->push_command(['HELP']);
  
  is eval { $client->push_command(['QUIT'])                 ->recv->code }, 221, 'code = 221';
  diag $@ if $@;
  
  $done->recv;
  $done = AnyEvent->condvar;
  
  SKIP: {
    our $detect;
    skip 'bftp quit broken', 5 if $detect->{xb};
    is eval { $client->connect($config->{host}, $config->{port})->recv->code }, 220, 'code = 220';
    diag $@ if $@;
  
    is eval { $client->push_command([USER => 'bogus'])->recv->code }, 331, 'code = 331';
    diag $@ if $@;
    eval { $client->push_command([PASS => 'bogus'])->recv };
    is $@->code, 530, 'code = 530';
    is eval { $client->push_command(['QUIT'])                 ->recv->code }, 221, 'code = 221 (2)';
    diag $@ if $@;
  
    is $help_cv->recv->code, 214, 'code = 214';
    $done->recv;
    $done = AnyEvent->condvar;
  }
  
  my $cv1 = $client->push_command([USER => $config->{user}]);
  my $cv2 = $client->push_command([PASS => $config->{pass}]);
  my $cv3 = $client->push_command(['QUIT']);
  
  is eval { $client->connect($config->{host}, $config->{port})->recv->code }, 220, 'code = 220';
  diag $@ if $@;
  
  is $cv1->recv->code, 331, 'code = 331';
  is $cv2->recv->code, 230, 'code = 230';
  is $cv3->recv->code, 221, 'code = 221';
  
  $done->recv;
};

subtest 'appe_2' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  my $remote = $config->{dir} = tempdir( CLEANUP => 1 );
  
  my $local = tempdir( CLEANUP => 1 );
  
  foreach my $passive (0,1)
  {
  
    my $client = AnyEvent::FTP::Client->new( passive => $passive );
  
    prep_client( $client );
  
    $client->connect($config->{host}, $config->{port})->recv;
    $client->login($config->{user}, $config->{pass})->recv;
    $client->type('I')->recv;
    $client->cwd($config->{dir})->recv;
  
    do {
      open my $fh, '>', "$local/data.$passive";
      binmode $fh;
      print $fh "data$_\n" for 1..200;
      close $fh;
    };
    
    $client->stor("data.$passive", "$local/data.$passive")->recv;
  
    my $size = -s "$local/data.$passive";
    is $size && -s "$remote/data.$passive", $size, "size of remote file is $size";  
    $size = $client->size("data.$passive")->recv;
    is $size, -s "$local/data.$passive", "size returned from remote file is correct";
  
    my $expected = do {
      open my $fh, '>>', "$local/data.$passive";
      binmode $fh;
      print $fh "xorxor$_\n" for 1..300;
      close $fh;
      
      open $fh, '<', "$local/data.$passive";
      binmode $fh;
      local $/;
      my $data = <$fh>;
      close $fh;
      $data;
    };
    
    do {
      open my $fh, '<', "$local/data.$passive";
      binmode $fh;
      seek $fh, $client->size("data.$passive")->recv, 0;
      $client->appe("data.$passive", $fh)->recv;
      close $fh;
    };
    
    $size = -s "$local/data.$passive";
    is $size && -s "$remote/data.$passive", $size, "size of remote file is $size";  
    $size = $client->size("data.$passive")->recv;
    is $size, -s "$local/data.$passive", "size returned from remote file is correct";
    
    my $actual = do {
      open my $fh, '<', "$remote/data.$passive";
      binmode $fh;
      local $/;
      my $data = <$fh>;
      close $fh;
      $data;
    };
    
    is $actual, $expected, "files match";
    
    $client->quit->recv;
  }
  
};

subtest 'noop' => sub {
  reset_timeout;
  my $client = eval { AnyEvent::FTP::Client->new };
  diag $@ if $@;
  isa_ok $client, 'AnyEvent::FTP::Client';
  
  prep_client( $client );
  our $config;
  
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  
  my $res = eval { $client->noop->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  is eval { $res->code }, 200, 'code = 200';
  diag $@ if $@;
  
  $client->quit->recv;
  
};

subtest 'appe' => sub {
  reset_timeout;
  skip_all 'requires client and server on localhost' if $ENV{AEF_REMOTE};
  
  our $config;
  $config->{dir} = tempdir( CLEANUP => 1 );
  
  foreach my $passive (0,1)
  {
  
    my $client = AnyEvent::FTP::Client->new( passive => $passive );
  
    prep_client( $client );
  
    $client->connect($config->{host}, $config->{port})->recv;
    $client->login($config->{user}, $config->{pass})->recv;
    $client->type('I')->recv;
    $client->cwd(translate_dir($config->{dir}))->recv;
  
    my $fn = File::Spec->catfile($config->{dir}, 'foo.txt');
  
    do {
      open my $fh, '>', $fn;
      say $fh "line1";
      close $fh;
    };
    
    do {
      my $data = 'line2';
      my $ret = eval { $client->appe('foo.txt', \$data)->recv; };
      diag $@ if $@;
      isa_ok $ret, 'AnyEvent::FTP::Response';
      ok -e $fn, 'remote file exists';
      my @remote = split /\015?\012/, do {
        open my $fh, '<', $fn;
        local $/;
        <$fh>;
      };
      is scalar(@remote), 2, 'two lines';
      is $remote[0], 'line1', 'line 1 = line1';
      is $remote[1], 'line2', 'line 2 = line2';
    };
    
    unlink $fn;
    ok !-e $fn, 'remote file deleted';
  
    $client->quit->recv;
  }
};

done_testing;
