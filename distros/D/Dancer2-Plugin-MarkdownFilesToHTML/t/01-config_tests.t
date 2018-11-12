use strict;
use warnings;
use File::Path;
use Data::Dumper qw(Dumper);
use Test::NoWarnings;
use Test::Output;
use Test::Most tests => 19, 'die';

BEGIN {
  $ENV{'DANCER_ENVIRONMENT'} = 'testing';

  $SIG{__WARN__} = sub {
    my $warn = shift;
    return if $warn =~ /fallback to PP version/;
    warn $warn;
  };
}


# Set up our app

use Plack::Test;
use HTTP::Request::Common;
{ package TestApp;
  use Dancer2;
  use Dancer2::Plugin::MarkdownFilesToHTML;
  use Data::Dumper qw(Dumper);

  get '/' =>   sub { return template 'index' };
  get '/intro' => sub {
    my $html = md2html('intro.md', {linkable_headers => 1});
    template 'index.tt', {
      html => $html,
    },
  };

  get '/intro2' => sub {
    my $html = md2html('intro.md');
    template 'index.tt', {
      html => $html,
    },
  };

  get '/all_tut_files' => sub {
    my $html = md2html('dzil_tutorial', { header_class => 'special' });
    template 'index.tt', {
      html => $html,
    },
  };

  get '/get_toc' => sub {
    my ($html, $toc) = md2html('dzil_tutorial', {generate_toc => 1});
    template 'index.tt', {
      html => $html,
      toc => $toc
    },
  };
}

### TESTS ###
# warnings are thrown with

set_failure_handler( sub { clean_cache_dir(); die; } );

my $test = Plack::Test->create( TestApp->to_app );
my $res;

my $skip = 0;

{ # 1
  SKIP: {
    skip 'test isolation', 1, if $skip;
    my $res = $test->request( GET '/' );
    ok( $res->is_success, 'Non-plugin get request can be made' );
  }
}

{ #2, 3
  SKIP: {
    skip 'test isolation', 2, if $skip;
    $res = $test->request( GET 'dzil_tutorial' );
    ok( $res->is_success, 'Can load page using basic config file' );
    like ($res->content, qr/<li>Beginning developers/, 'gets content');
  }
}

{ #4, 5
  SKIP: {
    skip 'test isolation', 2, if $skip;
    $res = $test->request( GET 'intro' );
    ok( $res->is_success, 'mdfile_2html call works');
    like ($res->content, qr/In the Beginning/, 'gets content');
  }
}

{ #6, 7
  SKIP: {
    skip 'test isolation', 2, if $skip;
    $res = $test->request( GET 'intro2' );
    ok( $res->is_success, 'mdfile_2html call works');
    unlike $res->content, qr/id="header_/, 'no headers added';
  }
}

{ # 8, 9, 10, 11
  SKIP: {
    skip 'test isolation', 4, if $skip;
    $res = $test->request( GET 'all_tut_files' );
    ok( $res->is_success, 'gets all tutorial files');
    like ($res->content, qr/<li>Beginning developers/, 'gets content');
    like ($res->content, qr/class="single-line"/, 'can add single line class');
    like ($res->content, qr/class="special"/, 'can add header class');
  }
}

{ # 12, 13, 14, 15
  SKIP: {
    skip 'test_isolation', 3, if $skip;
    $res = $test->request( GET 'get_toc' );
    ok( $res->is_success, 'passed option works');
    like ($res->content, qr/href="#header_0_aprereqs"/, 'generates toc');
    unlike ($res->content, qr/class="special"/, 'header class doesn\'t carry over');
    stdout_like {$test->request( GET 'get_toc' )} qr/cache hit:.*\n.*cache hit:.*\n.*cache hit:/m, 'cache works';
  }
}

{ # 16, 17, 18
  SKIP: {
    $skip = 0;
    skip 'test_isolation', 3, if $skip;
    $res = $test->request( GET 'no_resource' );
    ok( $res->is_success, 'missing resource returns legit page' );
    like ($res->content, qr/route is not properly configured/, 'displays proper message' );
    $res = $test->request( GET 'blah/prefix_test' );
    ok( $res->is_success, 'prefixes work' );
  }
}

# Delete cached files
clean_cache_dir();

sub clean_cache_dir {
  rmtree 't/data/md_file_cache' or die "Unable to delete cache directory\n";
  mkdir  't/data/md_file_cache' or die "Unable to make cache directory\n";
}
