package Class::DBI::Replicated::Test;

use strict;
use warnings;
use Class::Trigger;

=head1 NAME

Class::DBI::Replicated::Test

=cut

sub _mk_output {
  my $text = shift;
  return sub {
    my $class = shift;
    my $tmp = $text;
    $tmp .= " @_" if @_;
    return unless $class->repl_output;
    push @{$class->repl_output}, $tmp;
  };
}

sub _mk_trigger {
  my ($class, $name) = @_;
  $class->add_trigger(
    $name => _mk_output($name),
  );
}

sub _test_init {
  my ($class) = @_;
  $class->mk_class_accessors('repl_output');

  for (qw(
          switch_to_master
          switch_to_slave
          repl_db
          repl_check
          repl_mark
        )) {
    $class->_mk_trigger($_);
  }
}

1;
