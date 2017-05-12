#!/usr/local/bin/perl -w

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

my $Original_File = 'lib/Cisco/ACL.pm';

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

#line 12 lib/Cisco/ACL.pm

  use Cisco::ACL;
  my $acl = Cisco::ACL->new(
    permit   => 1,
    src_addr => '10.1.1.1/24',
    dst_addr => '10.1.2.1/24',
  );
  print "$_\n" for( $acl->acls );

;

  }
};
is($@, '', "example from line 12");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 738 lib/Cisco/ACL.pm

  my $acl = Cisco::ACL->new(
    src_addr => '192.168.0.1',
    dst_addr => '10.1.1.1/16',
    dst_port => 21937,
  );
  print "$_\n" for( $acl->acls );

;

  }
};
is($@, '', "example from line 738");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 752 lib/Cisco/ACL.pm

  my $acl = Cisco::ACL->new(
    src_addr => '24.223.251.222',
    protocol => 'ip',
  );
  print "$_\n" for( $acl->acls );
  $acl->src_addr_clear;
  $acl->dst_addr( '24.223.251.222' );
  print "$_\n" for( $acl->acls );

;

  }
};
is($@, '', "example from line 752");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 768 lib/Cisco/ACL.pm

  my $acl = Cisco::ACL->new(
    src_addr => [ '192.168.1.1/25', '10.1.1.1/26' ],
    dst_port => [ 22, 25 ],
  );
  print "$_\n" for( $acl->acls );

;

  }
};
is($@, '', "example from line 768");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 781 lib/Cisco/ACL.pm

  my $acl = Cisco::ACL->new( established => 1 );
  print "$_\n" for( $acl->acls );

;

  }
};
is($@, '', "example from line 781");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

