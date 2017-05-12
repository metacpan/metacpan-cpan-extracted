package Data::Encoder::Custom;

use strict;
use warnings;

sub new {
    my ($class, $args) = @_;
    $args ||= {};
    bless { %$args }, __PACKAGE__;
}

sub encode {
    my ($self, $stuff, @args) = @_;
    $self->{encoder}->($stuff, @args);
}

sub decode {
    my ($self, $stuff, @args) = @_;
    $self->{decoder}->($stuff, @args);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Data::Encoder::Custom - Data::Encoder gateway for custom

=head1 SYNOPSIS

  use Data::Encoder;
  
  my $encoder = Data::Encoder->load('Custom', {
      encoder => sub { ... },
      decoder => sub { ... },
  });
  my $encoded = $encoder->encode($data);
  my $decoded = $encoder->deocde($encoded);

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
