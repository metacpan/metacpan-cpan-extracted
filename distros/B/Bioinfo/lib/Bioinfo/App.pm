package Bioinfo::App;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options;

our $VERSION = '0.1.14'; # VERSION: 
# ABSTRACT: my perl module and CLIs for Biology



sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  $self->options_usage unless (@$args_ref);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bioinfo::App - my perl module and CLIs for Biology

=head1 VERSION

version 0.1.14

=head1 SYNOPSIS

  use Bioinfo;
  ...

=head1 DESCRIPTION

=head1 METHODS

=head2 execute

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
