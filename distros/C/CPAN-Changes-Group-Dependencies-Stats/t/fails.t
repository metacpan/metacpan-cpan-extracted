use strict;
use warnings;

use Test::More tests => 4;

# ABSTRACT: Things that fail
use CPAN::Changes::Group::Dependencies::Stats;

sub is_fail($$) {
  my ( $reason, $code ) = @_;
  local $@;
  my $failed = 1;
  eval {
    $code->();
    undef $failed;
  };
  if ($failed) {
    @_ = 'died:' . $reason;
    note explain $@;
    goto \&pass;
  }
  else {
    @_ = 'die expected:' . $reason;
    goto \&fail;
  }
}

sub isnt_fail($$) {
  my ( $reason, $code ) = @_;
  local $@;
  my $failed = 1;
  eval {
    $code->();
    undef $failed;
  };
  if ( not $failed ) {
    @_ = 'lived:' . $reason;
    goto \&pass;
  }
  else {
    @_ = 'live expected:' . $reason;
    diag explain $@;
    goto \&fail;
  }
}

is_fail 'Missing prereq' => sub {
  CPAN::Changes::Group::Dependencies::Stats->new()->changes;
};

is_fail 'Missing prereq new' => sub {
  CPAN::Changes::Group::Dependencies::Stats->new( old_prereqs => {} )->changes;
};

is_fail 'Missing prereq old' => sub {
  CPAN::Changes::Group::Dependencies::Stats->new( new_prereqs => {} )->changes;
};

isnt_fail 'Missing prereq old' => sub {
  CPAN::Changes::Group::Dependencies::Stats->new( new_prereqs => {}, old_prereqs => {} )->changes;
};
