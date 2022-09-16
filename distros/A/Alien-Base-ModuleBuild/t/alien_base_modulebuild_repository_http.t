use Test2::V0 -no_srand => 1;
use Alien::Base::ModuleBuild::Repository::HTTP;
use Path::Tiny qw( path );
use File::chdir;
use File::Temp;
use URI::file;

subtest 'network fetch' => sub {

  is(
    Alien::Base::ModuleBuild::Repository::HTTP->is_network_fetch,
    1
  );

};

subtest 'secure fetch' => sub {

  is(
    Alien::Base::ModuleBuild::Repository::HTTP->new( protocol => 'http' )->is_secure_fetch,
    F(),
  );

  is(
    Alien::Base::ModuleBuild::Repository::HTTP->new( protocol => 'https' )->is_secure_fetch,
    T(),
  );

  is(
    Alien::Base::ModuleBuild::Repository::HTTP->new( protocol => 'http', exact_filename => 'https://foo' )->is_secure_fetch,
    T(),
  );

  is(
    Alien::Base::ModuleBuild::Repository::HTTP->new( protocol => 'http', exact_filename => 'http://foo' )->is_secure_fetch,
    F(),
  );

};

subtest 'verify tls' => sub {

  local $ENV{ALIEN_DOWNLOAD_RULE};
  delete $ENV{ALIEN_DOWNLOAD_RULE};

  subtest 'HTTP::Tiny' => sub {

    my $new_args;

    my $mock = mock 'HTTP::Tiny' => (
      around => [
        new => sub {
          my($orig, $self, @args) = @_;
          $new_args = { @args };
          $self->$orig(@args);
        },
      ],
    );

    $ENV{ALIEN_DOWNLOAD_RULE} = 'warn';

    Alien::Base::ModuleBuild::Repository::HTTP->new->connection;

    is(
      $new_args,
      hash {
        field agent => match qr/^Alien-Base-ModuleBuild\/HTTP::Tiny\//;
        end;
      },
      'warn',
    );

    $ENV{ALIEN_DOWNLOAD_RULE} = 'digest_or_encrypt';
    $new_args = {};

    Alien::Base::ModuleBuild::Repository::HTTP->new->connection;

    is(
      $new_args,
      hash {
        field agent      => match qr/Alien-Base-ModuleBuild\/HTTP::Tiny\//;
        field verify_SSL => 1;
        end;
      },
      'digest_or_encrypt',
    );

  };

  subtest 'LWP' => sub {

    skip_all 'subtest requires LWP::UserAgent' unless eval { require LWP::UserAgent; 1 };

    my $new_args;

    my $mock = mock 'LWP::UserAgent' => (
      around => [
        new => sub {
          my($orig, $self, @args) = @_;
          $new_args = { @args };
          $self->$orig(@args);
        },
      ],
    );

    $ENV{ALIEN_DOWNLOAD_RULE} = 'warn';

    Alien::Base::ModuleBuild::Repository::HTTP->new( protocol_class => 'LWP::UserAgent' )->connection;

    is(
      $new_args,
      hash {
        field agent => match qr/^Alien-Base-ModuleBuild\/LWP::UserAgent\//;
        end;
      },
      'warn',
    );

    $ENV{ALIEN_DOWNLOAD_RULE} = 'digest_or_encrypt';
    $new_args = {};

    Alien::Base::ModuleBuild::Repository::HTTP->new( protocol_class => 'LWP::UserAgent' )->connection;

    is(
      $new_args,
      hash {
        field agent    => match qr/Alien-Base-ModuleBuild\/LWP::UserAgent\//;
        field ssl_opts => { verify_hostname => 1 };
        end;
      },
      'digest_or_encrypt',
    );

  };

};

my $index_path = path('corpus/alien_base_modulebuild_repository_http/index.html')->absolute->stringify;

my $mock = mock 'HTTP::Tiny' => (
  override => [
    get => sub {
      local $/ = undef;
      open my $fh, '<', $index_path or die "Could not open $index_path: $!";
      return {
        success => 1,
        content => <$fh>,
      };
    },
    mirror => sub {
      return {
        success => 1,
      };
    },
  ]
);

my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new;

# replicated in utils.t
my $html = q#Some <a href=link>link text</a> stuff. And a little <A HREF="link2">different link text</a>. AN ALL CAPS TAG <A HREF="link3">ALL CAPS</A> <A HREF=link4>ALL CAPS NO QUOTES</A>. <!--  <a href="dont_follow.html">you can't see me!</a> -->#;
my $correct = [qw/link link2 link3 link4/];

subtest 'find linsk with xtor' => sub {
  no warnings 'once';
  skip_all "HTML::LinkExtor not detected"
    unless $Alien::Base::ModuleBuild::Repository::HTTP::Has_HTML_Parser;

  my @targets = $repo->find_links_preferred($html);
  is( \@targets, $correct, "parse HTML for anchor targets (HTML::LinkExtor)");

  my @disp_targets = $repo->find_links($html);
  is( \@disp_targets, $correct, "parse HTML for anchor targets (HTML::LinkExtor, dispatched)");
};

subtest 'find links with Text::Balanced' => sub {
  my @targets = $repo->find_links_textbalanced($html);
  is( \@targets, $correct, "parse HTML for anchor targets (Text::Balanced)");

  # force Text::Balanced in dispatcher
  $Alien::Base::ModuleBuild::Repository::HTTP::Has_HTML_Parser = 0;
  my @disp_targets = $repo->find_links($html);
  is( \@disp_targets, $correct, "parse HTML for anchor targets (Text::Balanced, dispatched)");
};

subtest 'connection() and protocol_class' => sub {
  subtest 'HTTP::Tiny' => sub {
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new(
      protocol_class => 'HTTP::Tiny',
    );
    isa_ok $repo->connection, 'HTTP::Tiny';
  };

  subtest 'LWP::UserAgent' => sub {
    skip_all 'No LWP::UserAgent detected'
      unless eval { require LWP::UserAgent; 1 };
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new(
      protocol_class => 'LWP::UserAgent',
    );
    isa_ok $repo->connection, 'LWP::UserAgent';
  };

  subtest 'default' => sub {
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new;
    isa_ok $repo->connection, 'HTTP::Tiny';
  };

  subtest 'invalid class' => sub {
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new(
      protocol_class => 'THISCOULDNEVERBEAPROTOCOLCLASSWHATAREYOUTHINKING',
    );
    eval { $repo->connection };
    like $@, qr{Could not load protocol_class};
  };
};

subtest 'list_files()' => sub {
  subtest 'mock client' => sub {
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new(
      host => 'http://example.com',
      location => '/index.html',
    );
    is [ $repo->list_files ], [ 'relativepackage.txt' ];
  };
  subtest 'LWP::UserAgent' => sub {
    skip_all 'No LWP::UserAgent' unless eval { require LWP::UserAgent; 1 };
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new(
      protocol_class => 'LWP::UserAgent',
      host => URI::file->new($index_path)->as_string,
      # location doesn't work for file:// URLs
    );
    is [ $repo->list_files ], [ 'relativepackage.txt' ];
  };
};

subtest 'get_file()' => sub {
  subtest 'mock client' => sub {
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new;
    my $file = $repo->get_file( 'http://example.com/test.tar.gz' );
    is $file, 'test.tar.gz';
  };
  subtest 'LWP::UserAgent' => sub {
    skip_all 'No LWP::UserAgent' unless eval { require LWP::UserAgent; 1 };
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new(
      protocol_class => 'LWP::UserAgent',
    );
    # Change to a tempdir so our file gets automatically cleaned up
    my $tmp = File::Temp->newdir;
    local $CWD = $tmp->dirname;

    my $file = $repo->get_file( URI::file->new($index_path)->as_string );
    is $file, 'index.html';
  };
};

subtest 'get()' => sub {
  subtest 'mock client' => sub {
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new;
    my $file = Alien::Base::ModuleBuild::File->new(
      repository => $repo,
      filename => 'http://example.com/test.tar.gz',
    );
    my $filename = $file->get();
    is $filename, 'test.tar.gz';
  };
  subtest 'LWP::UserAgent' => sub {
    skip_all 'No LWP::UserAgent' unless eval { require LWP::UserAgent; 1 };
    my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new(
      protocol_class => 'LWP::UserAgent',
    );
    # Change to a tempdir so our file gets automatically cleaned up
    my $tmp = File::Temp->newdir;
    local $CWD = $tmp->dirname;

    my $file = Alien::Base::ModuleBuild::File->new(
      repository => $repo,
      filename => URI::file->new($index_path)->as_string,
    );
    my $filename = $file->get();
    is $filename, 'index.html';
  };
};

subtest 'uri' => sub {

  my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new;

  {
    my $uri = $repo->build_uri('http','host.com', 'path');
    is $uri, 'http://host.com/path', 'simplest case';
  }

  {
    my $uri = $repo->build_uri('https','host.com', 'path');
    is $uri, 'https://host.com/path', 'simplest case with the HTTPS protocol';
  }

  {
    my $uri = $repo->build_uri('http','host.com', 'my path');
    is $uri, 'http://host.com/my%20path', 'path with spaces';
  }

  {
    my $uri = $repo->build_uri('http','host.com', 'deeper/', 'my path');
    is $uri, 'http://host.com/deeper/my%20path', 'extended path with spaces';
  }

  {
    my $uri = $repo->build_uri('http','host.com/', '/path');
    is $uri, 'http://host.com/path', 'remove repeated /';
  }

  {
    my $uri = $repo->build_uri('http','host.com/', '/path/', 'file.ext');
    is $uri, 'http://host.com/path/file.ext', 'file with path';
  }

  {
    my $uri = $repo->build_uri('http','host.com/', '/path/', 'http://host.com/other/file.ext');
    is $uri, 'http://host.com/other/file.ext', 'absolute URI found in link';
  }

  {
    my $uri = $repo->build_uri('http','host.com/', '/path/', 'http://example.org/other/file.ext');
    is $uri, 'http://example.org/other/file.ext', 'absolute URI on different host';
  }

  {
    my $uri = $repo->build_uri('https', 'github.com', '/libssh2/libssh2/releases/',
                               '/libssh2/libssh2/releases/download/libssh2-1.6.0/libssh2-1.6.0.tar.gz');
    is $uri, 'https://github.com/libssh2/libssh2/releases/download/libssh2-1.6.0/libssh2-1.6.0.tar.gz';
  }
};

subtest 'content disposition' => sub {

  my $content_disposition;

  my $mock = mock 'HTTP::Tiny' => (
    override => [
      mirror => sub {
        my $response = { success => 1 };
        $response->{headers}->{'content-disposition'} = $content_disposition
          if defined $content_disposition;
        $response;
      },
    ],
  );

  my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new(
    host => 'foo.bar.com',
  );

  is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'bogus', 'no content disposition');
  $content_disposition = 'attachment; filename=foo.txt';
  is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'foo.txt', 'filename = foo.txt (bare)');
  $content_disposition = 'attachment; filename="foo.txt"';
  is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'foo.txt', 'filename = foo.txt (double quotes)');
  $content_disposition = 'attachment; filename="foo with space.txt" and some other stuff';
  is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'foo with space.txt', 'filename = foo with space.txt (double quotes with space)');
  $content_disposition = 'attachment; filename=foo.txt and some other stuff';
  is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'foo.txt', 'filename = foo.txt (space terminated)');
};

subtest 'check_http_response()' => sub {

  subtest '599 no SSL' => sub {

    my $res = {
      'reason'  => 'Internal Exception',
      'url'     => 'https://mytest.test',
      'success' => '',
      'status'  => 599,
      'headers' => {
        'content-type' => 'text/plain',
        'content-length' => 110,
      },
      'content' => "IO::Socket::SSL 1.42 must be installed for https support\n" .
                   "Net::SSLeay 1.49 must be installed for https support\n",
    };

    is(
      [Alien::Base::ModuleBuild::Repository::HTTP->check_http_response($res)],
      [1, "IO::Socket::SSL 1.42 must be installed for https support\n" .
          "Net::SSLeay 1.49 must be installed for https support\n" .
          "See https://github.com/PerlAlien/Alien-Base-ModuleBuild/issues/6#issuecomment-417097485",
          { 'content-type' => 'text/plain', 'content-length' => 110 }, "https://mytest.test" ]
    );
  };

  subtest '599 other' => sub {

    my $res = {
      'reason'  => 'Internal Exception',
      'url'     => 'https://mytest.test',
      'success' => '',
      'status'  => 599,
      'headers' => {
        'content-type' => 'text/plain',
        'content-length' => 13,
      },
      'content' => "Some Error!\n",
    };

    is(
      [Alien::Base::ModuleBuild::Repository::HTTP->check_http_response($res)],
      [1, "Some Error!\n",
          { 'content-type' => 'text/plain', 'content-length' => 13 }, "https://mytest.test" ]
    );
  };

  subtest '404 bad url' => sub {

    my $res = {
      'headers' => {
        'content-type' => 'text/plain',
        'content-length' => length("404 Not Found\n"),
      },
      'url' => 'https://mytest.test/bogus',
      'protocol' => 'HTTP/1.1',
      'status' => '404',
      'success' => '',
      'reason' => 'Not Found',
      'content' => "404 Not Found\n",
    };

    is(
      [Alien::Base::ModuleBuild::Repository::HTTP->check_http_response($res)],
      [1, "404 Not Found",
          { 'content-type' => 'text/plain', 'content-length' => 14 }, "https://mytest.test/bogus" ],
    );

  };
};

done_testing;

