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

my $Original_File = 'D:lib\CGI\Wiki\Simple\Plugin\RecentChanges.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module CGI::Wiki::Simple
  eval { require CGI::Wiki::Simple };
  skip "Need module CGI::Wiki::Simple to run this test", 1
    if $@;

  # Check for module CGI::Wiki::Simple::Plugin::RecentChanges
  eval { require CGI::Wiki::Simple::Plugin::RecentChanges };
  skip "Need module CGI::Wiki::Simple::Plugin::RecentChanges to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 21 lib/CGI/Wiki/Simple/Plugin/RecentChanges.pm

  use CGI::Wiki::Simple;
  use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'LastWeekChanges', days => 7 );
  # also
  use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'Recent20Changes', last_n_changes => 20 );
  # also
  use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'RecentFileChanges', days => 14, re => qr/^File:(.*)$/ );
  # This will display all changed nodes that match ^File:

;

  }
};
is($@, '', "example from line 21");

};
SKIP: {
    # A header testing whether we find all prerequisites :
    
    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};
