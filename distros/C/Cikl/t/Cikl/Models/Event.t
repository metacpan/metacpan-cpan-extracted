package TestsFor::Cikl::Models::Event;
use base qw(Test::Class);
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cikl::Models::Event;

sub testing_class { 'Cikl::Models::Event'; }

sub build {
  my %args = @_;
  return Cikl::Models::Event->new(%args);
}

sub test_required_args : Test(4) {
  my $self = shift;

  my %working_args = (
    group => "everyone",
    assessment => "malware",
  );

  lives_and { isa_ok(Cikl::Models::Event->new(%working_args), "Cikl::Models::Event") };
  dies_ok { Cikl::Models::Event->new() }  "die with no arguments";

  my %badargs = %working_args;
  delete($badargs{group});
  dies_ok { Cikl::Models::Event->new(%badargs) }  "requires group";

  %badargs = %working_args;
  delete($badargs{assessment});
  dies_ok { Cikl::Models::Event->new(%badargs) }  "requires assessment";
}

Test::Class->runtests;
