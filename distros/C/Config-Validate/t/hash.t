#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::Hash;

use base qw(Test::Class);
use Test::More;
use Data::Dumper;
use Storable qw(dclone);

use Config::Validate;

sub setup :Test(setup => 1) {
  my ($self) = @_;

  $self->{cv} = Config::Validate->new;
  isa_ok($self->{cv}, 'Config::Validate', "Created object in fixture");

  $self->{schema} = {hashtest => { type => 'hash',
                                   keytype => 'string',
                                   child => { 
                                     test => { type => 'string',
                                               default => 'blah'
                                              },
                                     test2 => { type => 'boolean'},
                                   },
                                 }
                    };
  return;
}

sub child_with_default :Test(3) {
  my ($self) = @_;
  $self->{cv}->schema($self->{schema});
  my $data = { hashtest => 
               { test1 => { test2 => 1 },
                 test2 => { test => 'foo',
                            test2 => 0 },
               },
             };
  my $result;
  eval { $result = $self->{cv}->validate($data) };
  is($@, '', 'hash test w/default');
  is($result->{hashtest}{test1}{test}, 'blah', "default successful");
  is($result->{hashtest}{test2}{test}, 'foo', "explicitly setting default successful");

  return;
}

sub hash_without_child :Test(3) {
  my ($self) = @_;
  my $schema = dclone($self->{schema});
  delete $schema->{hashtest}{child};
  $self->{cv}->schema($schema);

  my $data = { hashtest => 
               { test1 => 1,
                 test2 => 2,
               },
             };

  my $result;
  eval { $result = $self->{cv}->validate($data) };
  is($@, '', 'hash test w/default');
  is($result->{hashtest}{test1}, 1, 'key1 validated');
  is($result->{hashtest}{test2}, 2, 'key2 validated');
  return;
}

sub child_without_keytype :Test(1) {
  my ($self) = @_;
  my $schema = dclone($self->{schema});
  delete $schema->{hashtest}{keytype};
  $self->{cv}->schema($schema);

  my $data = { hashtest => 
               { test1 => { test2 => 1 },
                 test2 => { test => 'foo',
                            test2 => 0 },
               },
             };

  eval { $self->{cv}->validate($data) };
  like($@, qr/No keytype specified/, 'No keytype specified');
  return;
}

sub child_with_bad_keytype :Test(1) { # Test child w/bad keytype
  my ($self) = @_;
  my $schema = dclone($self->{schema});
  $schema->{hashtest}{keytype} = 'badkeytype';
  $self->{cv}->schema($schema);

  my $data = { hashtest => 
               { test1 => { test2 => 1 },
                 test2 => { test => 'foo',
                            test2 => 0 },
               },
             };

  eval { $self->{cv}->validate($data) };
  like($@, qr/Invalid keytype 'badkeytype' specified/, 'Bad keytype specified');
  return;
}

sub child_is_not_a_hash :Test(1) { # Test child w/bad keytype
  my ($self) = @_;

  $self->{cv}->schema($self->{schema});
  my $data = { hashtest => 'not a hash ref' };
  eval { $self->{cv}->validate($data) };
  like($@, qr/should be a 'HASH', but instead is /, 'non-hashref found');
  return;
}

