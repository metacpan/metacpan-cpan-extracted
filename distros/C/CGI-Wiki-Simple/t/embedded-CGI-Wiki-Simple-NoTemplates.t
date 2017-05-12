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

my $Original_File = 'D:lib\CGI\Wiki\Simple\NoTemplates.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module CGI::Wiki::Simple::NoTemplates
  eval { require CGI::Wiki::Simple::NoTemplates };
  skip "Need module CGI::Wiki::Simple::NoTemplates to run this test", 1
    if $@;

  # Check for module CGI::Wiki::Store::MySQL
  eval { require CGI::Wiki::Store::MySQL };
  skip "Need module CGI::Wiki::Store::MySQL to run this test", 1
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

#line 24 lib/CGI/Wiki/Simple/NoTemplates.pm

  use strict;
  use CGI::Wiki::Simple::NoTemplates;
  use CGI::Wiki::Store::MySQL; # Change this to match your setup

  my $store = CGI::Wiki::Store::MySQL->new( dbname => "test",
                                            dbuser => "master",
                                            dbpass => "master" );


  my $search = undef;
  my $wiki = CGI::Wiki::Simple::NoTemplates
             ->new( PARAMS => {
                                store => $store,
                              })->run;

;

  }
};
is($@, '', "example from line 24");

};
SKIP: {
    # A header testing whether we find all prerequisites :
    
    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};
