#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use English qw(no_match_vars);

use Test::More;
use Test::Output;
use Test::Exit;

use_ok('CLI::Simple');

use vars qw(@ARGV);

my @options = qw(
  foo
  bar=s
);

########################################################################
subtest 'one command' => sub {
########################################################################

  local @ARGV = qw();

  my $app = CLI::Simple->new( commands => { foo => sub { print "Hello World\n"; return 0; } } );

  stdout_like( sub { $app->run(); }, qr/hello/xsmi, 'defaults to only command' );
};

########################################################################
subtest 'one command w/args' => sub {
########################################################################

  local @ARGV = qw(bar biz);

  my $app = CLI::Simple->new( commands => { foo => sub { print join q{,}, $_[0]->get_args; return 0; } } );

  stdout_like( sub { $app->run(); }, qr/bar,biz/xsmi, 'defaults to only command' );
};

########################################################################
subtest 'default' => sub {
########################################################################

  local @ARGV = qw();

  my $app = CLI::Simple->new(
    commands => {
      bar => sub { return 0; },
      foo => sub { print "Hello World\n"; return 0; }
    }
  );

  stdout_like(
    sub {
      exits_ok { $app->run(); }, 'exits ok';
    },
    qr/usage/xsmi
  );

};

done_testing;

1;

__END__

=pod

=head1 USAGE

 blah blah

=cut
