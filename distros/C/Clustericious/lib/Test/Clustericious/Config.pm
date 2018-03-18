package Test::Clustericious::Config;

use strict;
use warnings;
use 5.010001;
use Test2::Plugin::FauxHomeDir;
use File::Glob qw( bsd_glob );
use YAML::XS qw( DumpFile );
use File::Path qw( mkpath );
use Clustericious::Config;
use Mojo::Loader;
use Clustericious;
use Test2::API qw( context );
use base qw( Exporter );

our @EXPORT = qw( create_config_ok create_directory_ok home_directory_ok create_config_helper_ok );
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = ( all => \@EXPORT );

my $config_dir;

sub _init
{
  $config_dir = bsd_glob('~/etc');
  mkdir $config_dir;

  $ENV{CLUSTERICIOUS_CONF_DIR} = $config_dir;
  Clustericious->_testing(1);
}

BEGIN { _init() }

# ABSTRACT: Test Clustericious::Config
our $VERSION = '1.29'; # VERSION


sub create_config_ok ($;$$)
{
  my($config_name, $config, $test_name) = @_;

  my $fn = "$config_name.conf";
  $fn =~ s/::/-/g;
  
  unless(defined $config)
  {
    my $caller = caller;
    Mojo::Loader::load_class($caller) unless $caller eq 'main';
    $config = Mojo::Loader::data_section($caller, "etc/$fn");
  }
  
  my @diag;
  my $config_filename;
  
  my $ctx = context();
  my $ok = 1;
  if(!defined $config)
  {
    $config = "---\n";
    push @diag, "unable to locate text for $config_name";
    $ok = 0;
    $test_name //= "create config for $config_name";
  }
  else
  {
    $config_filename = "$config_dir/$fn";
  
    eval {
      if(ref $config)
      {
        DumpFile($config_filename, $config);
      }
      else
      {
        open my $fh, '>', $config_filename;
        print $fh $config;
        close $fh;
      }
    };
    if(my $error = $@)
    {
      $ok = 0;
      push @diag, "exception: $error";
    }
  
    $test_name //= "create config for $config_name at $config_filename";
  
    # remove any cached copy if necessary
    Clustericious->_config_uncache($config_name);
  }

  $ctx->ok($ok, $test_name);
  $ctx->diag($_) for @diag;  
  
  $ctx->release;
  
  return $config_filename;
}


sub create_directory_ok ($;$)
{
  my($path, $test_name) = @_;

  my $fullpath;
  my $ok;
  
  if(defined $path)
  {
    $fullpath = $path;
    $fullpath =~ s{^/}{};
    $fullpath = bsd_glob("~/$fullpath");
    mkpath $fullpath, 0, 0700;
  
    $test_name //= "create directory $fullpath";
    $ok = -d $fullpath;
  }
  else
  {
    $test_name //= "create directory [undef]";
    $ok = 0;
  }
  
  my $ctx = context();
  $ctx->ok($ok, $test_name);
  $ctx->release;
  return $fullpath;
}


sub home_directory_ok (;$)
{
  my($test_name) = @_;
  
  my $fullpath = bsd_glob('~');
  
  $test_name //= "home directory $fullpath";
  
  my $ctx = context();
  $ctx->ok(-d $fullpath, $test_name);
  $ctx->release;
  return $fullpath;
}


sub create_config_helper_ok ($$;$)
{
  my($helper_name, $helper_code, $test_name) = @_;
  
  $test_name //= "create config helper $helper_name";
  my $ok = 1;
  
  require Clustericious::Config::Helpers;
  do {
    no strict 'refs';
    *{"Clustericious::Config::Helpers::$helper_name"} = $helper_code;
  };
  push @Clustericious::Config::Helpers::EXPORT, $helper_name;
  
  my $ctx = context();
  $ctx->ok($ok, $test_name);
  $ctx->release;
  return $ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Clustericious::Config - Test Clustericious::Config

=head1 VERSION

version 1.29

=head1 SYNOPSIS

 use Test::Clustericious::Config;
 use Clustericious::Config;
 use Test::More tets => 2;
 
 create_config_ok 'Foo', { url => 'http://localhost:1234' };
 my $config = Clustericious::Config->new('Foo');
 is $config->url, "http://localhost:1234";

To test against a Clustericious application MyApp:

 use Test::Clustericious::Config;
 use Test::Clustericious;
 use Test::More tests => 3;

 create_config_ok 'MyApp', { x => 1, y => 2 }; 
 my $t = Test::Clustericious->new('MyApp');
 
 $t->get_ok('/');
 
 is $t->app->config->x, 1;

To test against multiple Clustericious applications MyApp1, MyApp2
(can also be the same app with different config):

 use Test::Clustericious::Config;
 use Test::Clustericious;
 use Test::More tests => 4;
 
 create_config_ok 'MyApp1', {};
 my $t1 = Test::Clustericious->new('MyApp1');
 
 $t1->get_ok('/');
 
 create_config_ok 'MyApp2', { my_app1_url => $t1->app_url };
 my $t2 = Test::Clustericious->new('MyApp2');
 
 $t2->get_ok('/');

=head1 DESCRIPTION

This module provides an interface for testing Clustericious
configurations, or Clustericious applications which use
a Clustericious configuration.

It uses L<Test2::Plugin::FauxHomeDir> to isolate your test environment
from any configurations you may have in your C<~/etc>.  Keep
in mind that this means that C<$HOME> and friends will be in
a temporary directory and removed after the test runs.  It also
means that the caveats for L<Test2::Plugin::FauxHomeDir> apply when
using this module as well (specifically this should be the first module
that you use in your test after C<use strict> and C<use warnings>).

=head1 FUNCTIONS

=head2 create_config_ok

  create_config_ok $name, $config;
  create_config_ok $name, $config, $test_name;

Create a Clustericious config with the given C<$name>.
If C<$config> is a reference then it will create the 
configuration file with C<YAML::XS::DumpFile>, if
it is a scalar, it will will write the scalar out
to the config file.  Thus these three examples should
create a config with the same values (though in different
formats):

hash reference:

 create_config_ok 'Foo', { url => 'http://localhost:1234' }];

YAML:

 create_config_ok 'Foo', <<EOF;
 ---
 url: http://localhost:1234
 EOF

JSON:

 create_config_ok 'Foo', <<EOF;
 {"url":"http://localhost:1234"}
 EOF

In addition to being a test that will produce a ok/not ok
result as output, this function will return the full path
to the configuration file created.

=head2 create_directory_ok

 create_directory_ok $path;
 create_directory_ok $path, $test_name;

Creates a directory in your test environment home directory.
This directory will be recursively removed when your test
terminates.  This function returns the full path of the 
directory created.

=head2 home_directory_ok

 home_directory_ok;
 home_directory_ok $test_name;

Tests that the temp home directory has been created okay.
Returns the full path of the home directory.

=head2 create_config_helper_ok

 create_config_helper_ok $helper_name, $helper_coderef;
 create_config_helper_ok $helper_name, $helper_coderef, $test_name;

Install a helper which can be called from within a configuration template.
Example:

 my $counter;
 create_config_helper_ok 'counter', sub { $counter++ };
 create_config_ok 'MyApp', <<EOF;
 ---
 one: <%= counter %>
 two: <%= counter %>
 three: <% counter %>
 EOF

=head1 EXAMPLES

Here is an (abbreviated) example from L<Yars> that show how to test against an app
where you need to know the port/url of the app in the configuration
file:

 use Test::Mojo;
 use Test::More tests => 1;
 use Test::Clustericious::Config;
 use Mojo::UserAgent;
 use Yars;
 
 my $t = Test::Mojo->new;
 $t->ua(do {
   my $ua = Mojo::UserAgent->new;
   create_config_ok 'Yars', {
     url => $ua->app_url,
     servers => [ {
       url => $ua->app_url,
     } ]
   };
   $ua->app(Yars->new);
   $ua
 };
 
 $t->get_ok('/status');

To see the full tests see t/073_tempdir.t in the L<Yars> distribution.

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
