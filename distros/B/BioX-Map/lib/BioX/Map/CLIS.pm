package BioX::Map::CLIS;
use Modern::Perl;
use IO::All;
use Moo;
use Types::Standard qw/Int Str/;
use MooX::Cmd;
use MooX::Options prefer_commandline => 1;

our $VERSION = '0.0.12'; # VERSION
# ABSTRACT: a mapping toolkit



sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my $pre_message = "\nWarning:\n  this is a apps collection, your can only execute it's sub_command or sub_sub_command. more detail can be obtain by --man paramter\n";
  unless (@$args_ref) {
    say $pre_message;
    $self->options_usage;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BioX::Map::CLIS - a mapping toolkit

=head1 VERSION

version 0.0.12

=head1 DESCRIPTION

=head1 SYNOPOSIS

  use BioX::Map::CLIS;
  BioX::Map::CLIS->new_with_cmd;

=head2 execute

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
