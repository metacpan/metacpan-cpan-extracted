use warnings;
use strict;

use Data::FormValidator::Multi;

package # Hide from PAUSE
  Test::Data::FormValidator::Multi;

use base qw(Test::Class);
use Test::More;
use Data::FormValidator::Profile;

sub skeleton_data {
  my $self = shift;

  my $data = {
    $self->toplevel,
    $self->meta,
    $self->timezones(
      [ 999, 'America/New_York',    'Home',  '01/01', '23:59'],
      [ 111, 'America/Los_Angeles', 'L. A.', '01/01', '20:59'],
    ),
    $self->hash_in_hash,
    $self->array_in_hash,
  };

  return $data;
}

sub skeleton_validator {
  my $self = shift;

  my $dfvm = Data::FormValidator::Multi->new({
    profile     => $self->main_profile->profile,
    subprofiles => {
      timezones  => $self->timezones_profile->profile,
      meta       => $self->meta_profile->profile,
    }
  });

  return $dfvm;
}

sub skeleton_profile {
  my $self = shift;

  return Data::FormValidator::Profile->new({
    filters => [qw( trim )],
    msgs    => {
      invalid_seperator => ' ## ',
      format            => 'ERROR: %s',
      missing           => 'FIELD IS REQUIRED',
      invalid           => 'FIELD IS INVALID',
      constraints       => {
          not_positive    => 'MUST BE POSITIVE',
          bad_date_format => 'DATE FORMAT MUST BE MM/DD',
      }
    },
  });
}

# startup methods are run once when you start running a test class
#sub startup : Test(startup) {
##  shift->{dbi} = DBI->connect;
#}

# setup methods are run before every test method
sub setup : Test(setup) {
  my $self = shift;

#  $self->{dfvp} = $self->skeleton_profile;
}

# teardown methods are run after every test method.
use Data::Dumper;
sub teardown : Test(teardown) {
  my $self = shift;

  my $results = $self->{results};
  diag( Data::Dumper->Dump([$results->to_json], ['json']) ) if $ENV{TEST_DIAG};
}

# shutdown methods are run once just before a test class stops running
#sub shutdown : Test(shutdown) {
##  shift->{dbi}->disconnect;
#}

# helper methods that return data structures that are combined to build input data to test the profiles with

sub toplevel { return(
  name      => 'FooBar',
  dashboard => -23,
)}

sub foobar { return(
  foo => 'Foo',
  bar => 'Bar',
)}

sub meta { return(
  meta  => {
    $_[0]->foobar,
  },
)}

sub timezones {
  my $self = shift;

  my $timezones = [];

  foreach my $data ( @_ ) {
    push @$timezones => {
      id   => $data->[0],
      zone => $data->[1],
      name => $data->[2],
      date => $data->[3],
      time => $data->[4],
    };
  }

  return( timezones => $timezones );
}

sub hash_in_hash { return(
  hash_in_hash => {
    bar => 'Bar',
    foo => {
      $_[0]->foobar,
    },
  },
)}

sub array_in_hash { return(
  array_in_hash => {
    bar => 'Bar',
    foo => [
      {
        $_[0]->foobar,
      },
      {
        $_[0]->foobar,
      },
    ],
  },
)}

# helper methods to construct dfv profiles

my $main_profile_constraint_methods = {
  'dashboard' => [
    {
      name              => 'not_positive',
      constraint_method => sub {
        my ($dfv, $val) = @_;
        return $val =~ /\A\d+\z/;
      }
    },
  ],
};

sub main_profile {
  my $self = shift;

  my $profile = $self->skeleton_profile;

  my $fields = {
    required => [
      'name',      # example field - regular dfv handling
      'dashboard', # example field - regular dfv handling
      'timezones', # array of hashes - dfvm iterates dfvr on each element
    ],
    optional => [
      'meta',      # hash - dfvm calls dfvr on it | validation succeeds if field is not present
    ],
  };

  while( my($type, $fields) = each %$fields ) {
    foreach my $field ( @$fields ) {
      $profile->add( $field,
        required    => $type eq 'required',
        constraints => $main_profile_constraint_methods->{$field},
      );
    }
  }

  return $profile;
}

my $timezones_profile_constraint_methods = {
  'id' => [
    {
      name              => 'not_positive',
      constraint_method => sub {
        my ($dfv, $val) = @_;
        return $val =~ /\A\d+\z/;
      }
    },
  ],
  'date' => [
    {
      name              => 'bad_date_format',
      constraint_method => sub {
        my ($dfv, $val) = @_;
        return $val =~ m|^\d{2}/\d{2}$|;
      }
    },
  ],
};

sub timezones_profile {
  my $self = shift;

  my $profile = $self->skeleton_profile;

  foreach my $field ( qw(id zone name date time) ) {
    $profile->add( $field,
      required    => 1,
      constraints => $timezones_profile_constraint_methods->{$field},
    );
  }

  return $profile;
};

sub meta_profile {
  my $self = shift;

  my $profile = $self->skeleton_profile;

  foreach my $field ( qw(foo bar) ) {
    $profile->add( $field,
      required => 1,
    );
  }

  return $profile;
}

1;
