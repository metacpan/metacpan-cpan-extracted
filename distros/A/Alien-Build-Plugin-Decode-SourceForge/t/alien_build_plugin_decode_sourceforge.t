use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Decode::SourceForge;

my $build = alienfile_ok q{
  use alienfile;
  
  share {
  
    plugin 'Decode::Mojo';
    plugin 'Decode::SourceForge';
  
  };
};

is $build->requires('configure')->{'Alien::Build::Plugin::Decode::SourceForge'}, D(), 'plugin is a configure requires';

$build->load_requires('share');

is(
  $build->decode({
    type    => 'html',
    base    => 'http://sourceforge.net/foo/bar/',
    content => q{
      <html>
        <head>
          <title>hey</title>
        </head>
        <body>
          <ul>
            <li><a href="http://sourceforge.net/foo/bar/foo-1.2.3.tar.gz/download">foo-1.2.3.tar.gz</a></li>
            <li><a href="foo-1.2.4.tar.gz/download">foo-1.2.4.tar.gz</a></li>
            <li><a href="baz/other/link">other link</a></li>
          </ul>
        </body>
      </html>
    },
  }),
  {
    type => 'list',
    list => [
      { filename => 'foo-1.2.3.tar.gz', url => 'http://sourceforge.net/foo/bar/foo-1.2.3.tar.gz/download' },
      { filename => 'foo-1.2.4.tar.gz', url => 'http://sourceforge.net/foo/bar/foo-1.2.4.tar.gz/download' },
      { filename => 'link',             url => 'http://sourceforge.net/foo/bar/baz/other/link'            },
    ],
  },
  'links are rewritten',
);

done_testing
