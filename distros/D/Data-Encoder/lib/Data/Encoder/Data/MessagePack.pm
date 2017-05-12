package Data::Encoder::Data::MessagePack;

use strict;
use warnings;
use Data::MessagePack;

my $ooish = $Data::MessagePack::VERSION >= 0.36;

sub new {
    my ($class, $args) = @_;
    my $mp = 'Data::MessagePack';
    if ($ooish) {
        $mp = Data::MessagePack->new;
        $args ||= {};
        for my $method (keys %$args) {
            $mp->$method(defined $args->{$method} ? $args->{$method} : ());
        }
    }
    bless { mp => $mp }, __PACKAGE__;
}

sub encode {
    my ($self, $stuff, @args) = @_;
    $self->{mp}->pack($stuff);
}

sub decode {
    my ($self, $stuff, @args) = @_;
    $self->{mp}->unpack($stuff);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Data::Encoder::Data::MessagePack - Data::Encoder gateway for Data::MessagePack

=head1 SYNOPSIS

  use Data::Encoder;
  
  my $encoder = Data::Encoder->load('Data::MessagePack');
  my $packed = $encoder->encode([qw/foo bar/]);
  my $unpacked = $encoder->deocde($packed);

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::MessagePack>

=cut
