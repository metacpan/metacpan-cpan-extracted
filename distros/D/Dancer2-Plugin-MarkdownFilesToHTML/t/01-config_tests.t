use strict;
use warnings;
use File::Path;
use Data::Dumper qw(Dumper);
use Test::More;
use Test::Most tests => 11, 'die';
use Test::NoWarnings;

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
    my $html = mdfile_2html('intro.md');
    template 'index.tt', {
      html => $html,
    },
  };

  get '/all_tut_files' => sub {
    my $html = mdfiles_2html('dzil_tutorial');
    template 'index.tt', {
      html => $html,
    },
  };

  get '/get_toc' => sub {
    my ($html, $toc) = mdfiles_2html('dzil_tutorial', {generate_toc => 1});
    template 'index.tt', {
      html => $html,
      toc => $toc
    },
  };
}

### TESTS ###
# warnings are thrown with
&Test::NoWarnings::clear_warnings;

set_failure_handler( sub { clean_cache_dir(); } );

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

{ # 6, 7, 8
  SKIP: {
    skip 'test isolation', 2, if $skip;
    $res = $test->request( GET 'all_tut_files' );
    ok( $res->is_success, 'mdfiles_2html call works');
    like ($res->content, qr/<li>Beginning developers/, 'gets content');
    like ($res->content, qr/class="single-line"/, 'can add single line class');
  }
}

{ # 9, 10
  SKIP: {
    skip 'test_isolation', 2, if $skip;
    $res = $test->request( GET 'get_toc' );
    ok( $res->is_success, 'passed option works');
    like ($res->content, qr/href="#header_0_aprereqs"/, 'generates toc');
  }
}

# Cleanup our mess
clean_cache_dir();

sub clean_cache_dir {
  rmtree 't/data/md_file_cache';
  mkdir  't/data/md_file_cache' or die "Unable to make cache directory\n";
}
