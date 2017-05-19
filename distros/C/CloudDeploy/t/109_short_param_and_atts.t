#!/usr/bin/env perl

use CCfn;

use Test::More;
use Test::Exception;

package TestShortcutsParams {
  use Moose;
  extends 'CCfnX::CommonArgs';
  has '+region' => (default => 'eu-west-1');
  has '+account' => (default => 'devel-capside');
  has '+name' => (default => 'DefaultName');
  has 'xxx' => (is => 'ro', isa => 'Str', default => 99);
}

package TestShortcutsInner {
  use Moose;
  has att => (is => 'ro', default => 'att inner value');
}

package TestShortcuts {
  use Moose;
  extends 'CCfn';
  use CCfnX::Shortcuts;

  has params => (is => 'ro', isa => 'TestShortcutsParams', default => sub { TestShortcutsParams->new });

  has att => (is => 'ro', isa => 'Str', default => 'Att Value');

  has att_object => (is => 'ro', default => sub { TestShortcutsInner->new });

  resource Param1 => 'AWS::IAM::User', {
    Path => Parameter('xxx'),
  };

  resource Param2 => 'AWS::IAM::User', {
    Path => CfString("#-#Parameter('xxx')#-#")
  };

  resource Param3 => 'AWS::IAM::User', {
     Path => UserData(<<EOUD )
#-#Parameter('xxx')#-#
EOUD
  };

  resource Param4 => 'AWS::IAM::User', {
     Path => UserData(<<EOUD )
#-#Parameter(xxx)#-#
EOUD
  };

  resource Att1 => 'AWS::IAM::User', {
    Path => Attribute('att'),
  };

  resource Att2 => 'AWS::IAM::User', {
    Path => Attribute('att_object.att'),
  };

  resource Att3 => 'AWS::IAM::User', {
    Path => CfString("#-#Attribute(att)#-#")
  };

  resource Att4 => 'AWS::IAM::User', {
     Path => UserData(<<EOUD )
#-#Attribute(att_object.att)#-#
EOUD
  };

  resource Att5 => 'AWS::IAM::User', {
     Path => UserData(<<EOUD )
#-#Attribute(params.xxx)#-#
EOUD
  };

}


my $cfn = TestShortcuts->new();

my $hash = $cfn->as_hashref;

cmp_ok($hash->{Resources}{Att1}{Properties}{Path}, 'eq', 'Att Value', 'Attribute shortcut got the right value (one level)');
cmp_ok($hash->{Resources}{Att2}{Properties}{Path}, 'eq', 'att inner value', 'Attribute shortcut got the right value (two levels)');

is_deeply($hash->{Resources}{Att3}{Properties}{Path}, {
          'Fn::Join' => [
                          '',
                          [
                            '',
                            'Att Value'
                          ]
                        ]
        }, 'Attribute in a CfString');

is_deeply($hash->{Resources}{Att4}{Properties}{Path}, {
          'Fn::Base64' => {
                            'Fn::Join' => [
                                            '',
                                            [
                                              '',
                                              'att inner value',
                                              "\n"
                                            ]
                                          ]
                          }
        }, 'Attribute in a UserData');

is_deeply($hash->{Resources}{Att5}{Properties}{Path}, {
          'Fn::Base64' => {
                            'Fn::Join' => [
                                            '',
                                            [
                                              '',
                                              99,
                                              "\n"
                                            ]
                                          ]
                          }
        }, 'Access a parameter with Attribute');

cmp_ok($hash->{Resources}{Param1}{Properties}{Path}, '==', '99', 'Parameter shortcut got the right value');

is_deeply($hash->{Resources}{Param2}{Properties}{Path}, {
          'Fn::Join' => [
                          '',
                          [
                            '',
                            99
                          ]
                        ]
        }, 'Parameter in a CfString');

is_deeply($hash->{Resources}{Param3}{Properties}{Path}, {
          'Fn::Base64' => {
                            'Fn::Join' => [
                                            '',
                                            [
                                              '',
                                              99,
                                              "\n"
                                            ]
                                          ]
                          }
        }, 'Parameter in UserData');
is_deeply($hash->{Resources}{Param4}{Properties}{Path}, {
          'Fn::Base64' => {
                            'Fn::Join' => [
                                            '',
                                            [
                                              '',
                                              99,
                                              "\n"
                                            ]
                                          ]
                          }
        }, 'Parameter in UserData (without quoting)');

done_testing;
