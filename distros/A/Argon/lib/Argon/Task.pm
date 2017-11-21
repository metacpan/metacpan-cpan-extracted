package Argon::Task;
# ABSTRACT: Base interface for Argon-runnable tasks
$Argon::Task::VERSION = '0.18';
use strict;
use warnings;
use Argon;

sub new {
  my ($class, $code, $args) = @_;
  bless [$code, $args], $class;
}

sub run {
  Argon::ASSERT_EVAL_ALLOWED;
  my $self = shift;
  my ($str_code, $args) = @$self;
  my $code = eval "do { $str_code };";
  $code->(@$args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Task - Base interface for Argon-runnable tasks

=head1 VERSION

version 0.18

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
