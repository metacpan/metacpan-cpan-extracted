package Data::Encoder::Storable;

use strict;
use warnings;
use Storable;

sub new {
    my ($class) = @_;
    bless \my $obj, __PACKAGE__;
}

sub encode {
    my ($self, $stuff, @args) = @_;
    Storable::nfreeze($stuff);
}

sub decode {
    my ($self, $stuff, @args) = @_;
    Storable::thaw($stuff);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Data::Encoder::Storable - Data::Encoder gateway for Storable

=head1 SYNOPSIS

  use Data::Encoder;
  
  my $encoder = Data::Encoder->load('Storable');
  my $packed = $encoder->encode($data);
  my $unpacked = $encoder->decode($packed);

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Storable>

=cut
