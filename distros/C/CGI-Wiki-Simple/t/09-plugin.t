#!/usr/bin/perl -w
use strict;
use Test::More tests => 21;
use CGI::Wiki::Simple;

my @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, @_ };};

{
  package CGI::Simple::Plugin::Test;
  use strict;
  use Test::More;
  require CGI::Wiki::Simple::Plugin;
  no warnings 'redefine';

  {
    no warnings 'once';
    ok( defined *CGI::Wiki::Simple::Plugin::import{CODE}, "CGI::Wiki::Simple::Plugin has an import routine");
    is_deeply(\@warnings,[],"No warnings raised during run");
    @warnings = ();
  };

  {
    my ($caller,%args);
    local *CGI::Wiki::Simple::Plugin::register_nodes = sub { %args = @_; };

    CGI::Wiki::Simple::Plugin->import( name => 'test' );
    is_deeply(\%args,{module => 'CGI::Simple::Plugin::Test', names => ['test']},'Single import using "name"');
    is_deeply(\@warnings,[],"No warnings raised during run");
    @warnings = ();
  };

  {
    my ($caller,%args);
    local *CGI::Wiki::Simple::Plugin::register_nodes = sub { %args = @_; };

    CGI::Wiki::Simple::Plugin->import( names => 'test' );
    is_deeply(\%args,{module => 'CGI::Simple::Plugin::Test', names => ['test']},'Single import using "names"');
    is_deeply(\@warnings,[],"No warnings raised during run");
    @warnings = ();
  };

  {
    my ($caller,%args);
    local *CGI::Wiki::Simple::Plugin::register_nodes = sub { %args = @_; };

    CGI::Wiki::Simple::Plugin->import( name => ['test','test2','test3'] );
    is_deeply(\%args,{module => 'CGI::Simple::Plugin::Test', names => ['test','test2','test3']},'Multi import using "name"');
    is_deeply(\@warnings,[],"No warnings raised during run");
    @warnings = ();
  };

  {
    my ($caller,%args);
    local *CGI::Wiki::Simple::Plugin::register_nodes = sub { %args = @_; };

    CGI::Wiki::Simple::Plugin->import( names => ['test','test2','test3'] );
    is_deeply(\%args,{module => 'CGI::Simple::Plugin::Test', names => ['test','test2','test3']},'Multi import using "names"');
    is_deeply(\@warnings,[],"No warnings raised during run");
    @warnings = ();
  };

  {
    my ($caller,%args);
    local *CGI::Wiki::Simple::Plugin::register_nodes = sub { %args = @_; };

    CGI::Wiki::Simple::Plugin->import( name => ['test','test2','test3'], names => ['test4','test5','test6'] );
    is_deeply(\%args,{module => 'CGI::Simple::Plugin::Test', names => ['test','test2','test3','test4','test5','test6']},'Multi import using "name" and "names"');
    is_deeply(\@warnings,[],"No warnings raised during run");
    @warnings = ();
  };

  {
    my ($caller,%args);
    local *CGI::Wiki::Simple::Plugin::register_nodes = sub { %args = @_; };

    CGI::Wiki::Simple::Plugin->import( name => ['test','test2','test3'], names => ['test4','test4','test5','test6','test3'] );
    is_deeply(\%args,{module => 'CGI::Simple::Plugin::Test', names => ['test','test2','test3','test4','test5','test6']},'Multi import only creates one call per node');
    is_deeply(\@warnings,[],"No warnings raised during run");
    @warnings = ();
  };
};

{ package CGI::Wiki::Simple::Plugin::Test2;
  use strict;
  use Test::More;

  eval q!use CGI::Wiki::Simple::Plugin( name => 'test' )!;

  ok( exists $CGI::Wiki::Simple::magic_node{test},'Importing a value creates the entry in the magic node hash');
  is( ref $CGI::Wiki::Simple::magic_node{test}, 'CODE', 'A code reference was created');
  is_deeply(\@warnings,[],"No warnings raised during run");
  @warnings = ();

  my %args = (__called => 'no');
  sub retrieve_node {
    %args = (__called => "yes",@_);
    die "Callback was called";
  };

  eval { $CGI::Wiki::Simple::magic_node{test}->(undef,name => 'test') };
  die $@ if $@ and $@ !~ /^Callback was called/;

  is_deeply(\%args,{__called => 'yes', wiki => undef, name => 'test'},"Call to coderef");
  is_deeply(\@warnings,[],"No warnings raised during run");
  @warnings = ();

  {
    no warnings 'once';
    my @args;
    local *CORE::die = sub { @args = @_; goto CORE::die };
    eval { $CGI::Wiki::Simple::magic_node{test}->(undef,node => 'test') };
    like( $@,qr/^No valid node name supplied/, "Node name gets checked");
    is_deeply(\@warnings,[],"No warnings raised during run");
    @warnings = ();
  };
};
