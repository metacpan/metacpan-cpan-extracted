#!/usr/bin/perl -w

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

my $Original_File = 'lib/Config/ApacheExtended.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 30 lib/Config/ApacheExtended.pm

  use Config::ApacheExtended
  my $conf = Config::ApacheExtended->new(source => "t/parse.conf");
  $conf->parse() or die "Unsuccessful Parsing of config file";
  # Print out all the Directives
  foreach ($conf->get())
  {
      print "$_ => " . $conf->get($_) . "\n";
  }

  # Show all the blocks at the root
  foreach ($conf->block())
  {
      foreach ($conf->block($_))
      {
          print $_->[0] . " => " . $_->[1] . "\n";
          foreach ($conf->block(@$_))
          {
              my $block = $_;
              foreach ($block->get())
			  {
                  print "$_ => " . $block->get($_) . "\n";
              }
	      }
      }
  }

;

  }
};
is($@, '', "example from line 30");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

