use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::Download::GitHub;
use Test::Alien::Build;
use JSON::PP qw( encode_json );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

subtest 'basic load' => sub {

  my @mock_calls;
  my %mock_response = (
    type     => 'file',
    filename => 'releases',
  );

  my $mock1 = mock 'Alien::Build::Plugin::Download::Negotiate' => (
    override => [
      init => sub {
        my($self, $meta) = @_;
        push @mock_calls, [ 'init_download', { prefer => $self->prefer, version => $self->version } ];
        $meta->register_hook(
          fetch => sub {
            my($build, $url) = @_;
            push @mock_calls, [ 'fetch', { url => $url } ];
            $url ||= $build->meta_prop->{start_url};
            if($url eq 'https://api.github.com/repos/Perl5-Alien/dontpanic/releases')
            {
              return \%mock_response;
            }
            else
            {
              die "unhandled url: $url";
            }
          }
        );
      },
    ],
  );
  my $mock2 = mock 'Alien::Build::Plugin::Extract::Negotiate' => (
    override => [
      init => sub {
        my($self, $meta) = @_;
        push @mock_calls, [ 'init_extract', { format => $self->format } ];
      },
    ],
  );

  subtest 'basic' => sub {

    @mock_calls = ();
    local $mock_response{content} = encode_json([
      {
        tag_name => 'v1.01',
        tarball_url => 'https://api.github.com/repos/Perl5-Alien/dontpanic/tarball/v1.01',
      },
      {
        tag_name => '1.00',
        tarball_url => 'https://api.github.com/repos/Perl5-Alien/dontpanic/tarball/1.00',
      },
    ]);

    my $build = alienfile q{

      use alienfile;

      probe sub { 'share' };

      share {
        plugin 'Download::GitHub' => (
          github_user => 'Perl5-Alien',
          github_repo => 'dontpanic',
        );
      };

    };

    alienfile_skip_if_missing_prereqs;

    is
      \@mock_calls,
      array {
        item array {
          item 'init_download';
          item hash sub {
            field prefer => 0;
            field version => qr/^v?(.*)$/;
          },
        };
        item array {
          item 'init_extract';
          item hash sub {
            field format => 'tar.gz';
          },
        },
      },
      'called init'
    ;

    alien_install_type_is 'share';

    is
      $build->fetch,
      {
        type => 'list',
        list => [
          { filename => 'v1.01', url => 'https://api.github.com/repos/Perl5-Alien/dontpanic/tarball/v1.01', version => '1.01' },
          { filename => '1.00',  url => 'https://api.github.com/repos/Perl5-Alien/dontpanic/tarball/1.00',  version => '1.00' },
        ],
      },
      'response'
    ;

    is
      \@mock_calls,
      array {
        item array { etc; };
        item array { etc; };
        item array {
          item 'fetch';
          item hash sub {
            field url => U();
          };
        };
      },
      'called fetch'
    ;
  };

  subtest 'temp file' => sub {

    @mock_calls = ();
    my $file = path( tempdir( CLEANUP => 1 ) )->child('release');
    local $mock_response{path} = "$file";

    $file->spew_utf8(encode_json([
      {
        tag_name => 'v1.01',
        tarball_url => 'https://api.github.com/repos/Perl5-Alien/dontpanic/tarball/v1.01',
      },
      {
        tag_name => '1.00',
        tarball_url => 'https://api.github.com/repos/Perl5-Alien/dontpanic/tarball/1.00',
      },
    ]));

    my $build = alienfile q{

      use alienfile;

      probe sub { 'share' };

      share {
        plugin 'Download::GitHub' => (
          github_user => 'Perl5-Alien',
          github_repo => 'dontpanic',
        );
      };

    };

    alienfile_skip_if_missing_prereqs;

    is
      \@mock_calls,
      array {
        item array {
          item 'init_download';
          item hash sub {
            field prefer => 0;
            field version => qr/^v?(.*)$/;
          },
        };
        etc;
      },
      'called init'
    ;

    alien_install_type_is 'share';

    is
      $build->fetch,
      {
        type => 'list',
        list => [
          { filename => 'v1.01', url => 'https://api.github.com/repos/Perl5-Alien/dontpanic/tarball/v1.01', version => '1.01' },
          { filename => '1.00',  url => 'https://api.github.com/repos/Perl5-Alien/dontpanic/tarball/1.00',  version => '1.00' },
        ],
      },
      'response'
    ;
  };

  subtest 'override prefer and version' => sub {

    @mock_calls = ();

    alienfile q{

      use alienfile;

      probe sub { 'share' };

      share {
        plugin 'Download::GitHub' => (
          github_user => 'Perl5-Alien',
          github_repo => 'dontpanic',
          prefer => 1,
          version => qr/^foo([0-9]+)$/,
        );
      };

    };

    alienfile_skip_if_missing_prereqs;

    # just want to make sure that we pass on prefer
    # and version to the download negotiator
    is
      \@mock_calls,
      array {
        item array {
          item 'init_download';
          item hash sub {
            field prefer => 1;
            field version => qr/^foo([0-9]+)$/;
          },
        };
        etc;
      },
      'called init'
    ;

    alien_install_type_is 'share';
  };

};

subtest 'live tests' => sub {

  # TODO: prior to merging with AB core, these tests should be skipped
  # unless either turned on by an environment variable, or we can be
  # certain that we have a connection with GH

  # This doesn't catch results form the curl plugin, for example.
  # but it does add useful diagnostic if we are using HTTP::Tiny.
  require HTTP::Tiny;
  my $mock = mock 'HTTP::Tiny' => (
    around => [
      get => sub {
        my $orig = shift;
        my $res = $orig->(@_);
        unless($res->{success})
        {
          require Data::Dumper;
          note Data::Dumper::Dumper($res);
        }
        $res;
      },
    ],
  );

  my $build = alienfile q{

    use alienfile;

    probe sub { 'share' };

    share {
      plugin 'Download::GitHub' => (
        github_user => 'Perl5-Alien',
        github_repo => 'dontpanic',
      );
    };

  };

  alienfile_skip_if_missing_prereqs;

  alien_install_type_is 'share';

  my($diag, $default, $ex) = capture_merged {
    my $res = eval { $build->fetch };
    ($res, $@);
  };
  is($ex, '') || do {
    diag $diag;
    diag "\$\@ = $ex";
    return;
  };

  note $diag;

  is
    $default,
    hash {
      field type => 'list';
      field list => bag {
        item hash sub {
          field filename => '1.02';
          field url => match qr/https:/;
          field version => '1.02';
        };
        item hash sub {
          field filename => '1.01';
          field url => match qr/https:/;
          field version => '1.01';
        };
        item hash sub {
          field filename => '1.00';
          field url => match qr/https:/;
          field version => '1.00';
        };
        item hash sub {
          field filename => '0.90';
          field url => match qr/https:/;
          field version => '0.90';
        };
        etc;
      };
    },
    'see that we have 0.90, 1.00, 1.01 and 1.02 at least',
  ;

  alien_download_ok;

  my $download = $build->install_prop->{download};
  ok(-f $download, "download file exists");
  note("install_prop.download = $download");

  alien_extract_ok;

  my $extract = $build->install_prop->{extract};

  ok(-d $extract, "extracted to directory");
  note("install_prop.extract = $extract");
  ok(-f "$extract/configure", "has a configure file");
};

done_testing
