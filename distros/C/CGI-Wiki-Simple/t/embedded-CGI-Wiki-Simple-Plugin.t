#!D:\Programme\indigoperl-5.6\bin\perl.exe -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'D:lib\CGI\Wiki\Simple\Plugin.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module CGI::Wiki::Simple::Plugin
  eval { require CGI::Wiki::Simple::Plugin };
  skip "Need module CGI::Wiki::Simple::Plugin to run this test", 1
    if $@;

  # Check for module Carp
  eval { require Carp };
  skip "Need module Carp to run this test", 1
    if $@;

  # Check for module strict
  eval { require strict };
  skip "Need module strict to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 29 lib/CGI/Wiki/Simple/Plugin.pm

  package CGI::Wiki::Simple::Plugin::MyPlugin;
  use strict;
  use Carp qw(croak);
  use CGI::Wiki::Simple::Plugin( name => 'MyPlugin' );

  sub retrieve_node_data {
    my ($wiki) = shift;

    my %args = scalar @_ == 1 ? ( name => $_[0] ) : @_;
    croak "No valid node name supplied"
      unless $args{name};

    # $args{name} is the node name
    # $args{version} is the node version, if no version is passed, means current
    # ... now actually retrieve the content ...
    my @results = ("Hello world",0,"");

    my %data;
    @data{ qw( content version last_modified ) } = @results;
    $data{checksum} = md5_hex($data{content});
    return wantarray ? %data : $data{content};
  };

  # Alternatively, if your plugin can handle more than one node :
  package CGI::Wiki::Simple::Plugin::MyMultiNodePlugin;
  use strict;
  use CGI::Wiki::Simple::Plugin (); # No automatic import

  sub import {
    my ($module,@nodenames) = @_;
    CGI::Wiki::Simple::Plugin::register_nodes(module => $module, names => [@nodenames]);
  };

;

  }
};
is($@, '', "example from line 29");

};
SKIP: {
    # A header testing whether we find all prerequisites :
    
    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};
