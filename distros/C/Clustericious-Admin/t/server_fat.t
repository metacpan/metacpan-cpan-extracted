use strict;
use warnings;
use 5.010;
use Test::More tests => 2;
use Capture::Tiny qw( capture );
use Path::Class qw( file );
use File::Temp qw( tempdir );
use Clustericious::Admin::Dump qw( perl_dump );
use File::Glob qw( bsd_glob );
use File::Spec;

my @perls = ($^X);

eval '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
  use File::Which qw( which );
  use autodie qw( :system );

  my $pb = which 'perlbrew';
  die "no perlbrewl" unless $pb;
  
  my($out, $err, $exit) = capture { system $pb, 'list'; $? };
  
  push @perls, 
    grep { -x $_ }
    map { File::Spec->catfile(bsd_glob('~/perl5/perlbrew/perls'), $_, 'bin', 'perl') } 
    map { s/^\s*//; $_ } 
    grep !/\@/, 
    grep !/^\*/, 
    split /\n\r?/,
    $out;
};
note "probe for perl brew failed: $@";
note "perls:";
note "  +  $_" for @perls;

my $server;

subtest 'get server code' => sub {

  plan tests => 1;

  require_ok 'Clustericious::Admin::Server';
  
  $server = file($INC{'Clustericious/Admin/Server.pm'})->slurp;
  $server =~ s{\s+$}{};
  $server .= "\n";

};

sub run_server
{
  my($remote_perl, $test_pl) = @_;
  capture {
    delete local $ENV{PERL5LIB};
    delete local $ENV{PERLLIB};
    system $remote_perl, "$test_pl";
    $?;
  };
}

subtest 'old perls' => sub {

  plan tests => scalar @perls;

  foreach my $remote_perl (@perls) {

    subtest "with $remote_perl" => sub {

      plan tests => 4;

      note "remote perl: $remote_perl";
      note `$remote_perl -v`;

      subtest 'basics' => sub {

        plan tests => 3;

        my $payload = $server . perl_dump {
          env => {},
          version => 'dev',
          command => [ $remote_perl, -e => 'print "something to out\\n"; print STDERR "something to err\\n"' ],
        };

        my $test_pl = file( tempdir( CLEANUP => 1 ), 'test.pl');
        $test_pl->spew($payload);
  
        my($out, $err, $exit) = run_server $remote_perl, $test_pl;

        is $exit, 0, 'returns 0';
        like $out, qr{something to out}, 'out';
        like $err, qr{something to err}, 'err';
      };

      subtest 'file' => sub {
      
        plan tests => 1;

        my $payload = $server . perl_dump {
          env => {},
          version => 'dev',
          command => [ $remote_perl, -e => q{ 
            open IN, "<$ENV{FILE1}";
            local $/;
            $data = <IN>;
            close IN;
            die "file content did not match" unless $data eq 'rogerramjet';
            die "FILE1 is executable" if -x $ENV{FILE1};
            die "FILE2 is NOT executable" unless -x $ENV{FILE2};
          } ],
          files => [
            { name => "foo.txt", content => 'rogerramjet', mode => '0644' },
            { name => "bar.txt", content => 'morestuff',   mode => '0755' },
          ],
        };

        my $test_pl = file( tempdir( CLEANUP => 1 ), 'test.pl');
        $test_pl->spew($payload);
  
        my($out, $err, $exit) = run_server $remote_perl, $test_pl;

        is $exit, 0, 'returns 0';
        note "[out]\n$out" if $out;
        note "[err]\n$err" if $err;

      };

      subtest 'exit' => sub {
        plan tests => 1;

        my $payload = $server . perl_dump {
          env => {},
          version => 'dev',
          command => [ $remote_perl, -e => 'exit 22' ],
        };

        my $test_pl = file( tempdir( CLEANUP => 1 ), 'test.pl');
        $test_pl->spew($payload);
  
        my($out, $err, $exit) = run_server $remote_perl, $test_pl;

        is $exit >> 8, 22, 'returns 22';
      };
      
      subtest 'stdin' => sub {
        plan tests => 2;
      
        my $payload = $server . perl_dump {
          env => {},
          version => 'dev',
          command => [ $remote_perl, -e => '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
            undef $/;
            $data = <STDIN>;
            die "does not match: $data" if $data ne 'sometext';
            print scalar reverse $data;
          } ],
          stdin => "sometext",
        };

        my $test_pl = file( tempdir( CLEANUP => 1 ), 'test.pl');
        $test_pl->spew($payload);

        my($out, $err, $exit) = run_server $remote_perl, $test_pl;
        
        is $exit, 0, 'exit = 0 ';
        is $out, 'txetemos', 'stdout matches';
        #note "[out]\n$out";
        diag "[err]\n$err" if $err;
    
      };
    }
  }
};
