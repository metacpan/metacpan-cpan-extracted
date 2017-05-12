package CLIDTest::Single::DumpMe;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub options {qw( option=s )}

sub run {
  my ($self, @args) = @_;

  my $text;
  if ( @args ) {
    $text = join '', @args;
  }
  elsif ( $self->option('option') ) {
    $text = $self->option('option');
  }
  else {
    $text = 'no args';
  }

  return $text;
}

1;

__END__

=head1 NAME

CLIDTest::Single::DumpMe - dump me

=head1 DESCRIPTION

single command test
