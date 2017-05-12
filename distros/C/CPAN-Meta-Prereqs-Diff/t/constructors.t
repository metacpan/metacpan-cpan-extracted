use strict;
use warnings;

use Test::More tests => 3;

# ABSTRACT: Test alternative contstructor args

use CPAN::Meta::Prereqs::Diff;
use CPAN::Meta::Prereqs;
use CPAN::Meta;
our $context = "";

sub my_subtest ($$) {

  #note "Beginning: $_[0] ]---";
  local $context = " ($_[0])";
  $_[1]->();

  #note "Ending: $_[0] ]---";
}

my_subtest "Explicit Prereqs object" => sub {
  my $prereqs = CPAN::Meta::Prereqs->new( { runtime => { requires => { "Foo" => "1.0" } } } );

  local $@;
  my $lives = 0;
  eval {
    my $diff = CPAN::Meta::Prereqs::Diff->new(
      new_prereqs => $prereqs,
      old_prereqs => $prereqs->clone,
    );
    my @items = $diff->diff();
    $lives = 1;
  };
  ok( $lives, "Did not bail$context" ) or diag explain $@;
};

my_subtest "Explicit CPAN::Meta object" => sub {
  my $meta = CPAN::Meta->create(
    {
      prereqs        => { runtime => { requires => { "Foo" => "1.0" } } },
      release_status => "testing",
      author         => ["Kent Fredric"],
      abstract       => "A Mock CPAN::Meta",
      dynamic_config => 0,
      version        => '1.0',
      name           => "Mock-Meta",
      license        => ["perl_5"],
    }
  );

  local $@;
  my $lives = 0;
  eval {
    my $diff = CPAN::Meta::Prereqs::Diff->new(
      new_prereqs => $meta,
      old_prereqs => $meta->effective_prereqs,
    );
    my @items = $diff->diff;
    $lives = 1;
  };
  ok( $lives, "Did not bail$context" ) or diag explain $@;
};

my_subtest "Invalid" => sub {
  local $@;
  my $lives = 0;
  eval {

    my $diff = CPAN::Meta::Prereqs::Diff->new(
      new_prereqs => "String",
      old_prereqs => "String",
    );
    my @items = $diff->diff;
    $lives = 1;
  };
  ok( !$lives, "Did bail$context" ) and note $@;
};
