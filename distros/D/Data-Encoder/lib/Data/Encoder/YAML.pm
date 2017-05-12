package Data::Encoder::YAML;

use strict;
use warnings;
use YAML ();

sub new {
    my ($class, $args) = @_;
    bless \my $obj, __PACKAGE__;
}

sub encode {
    my ($self, $stuff, @args) = @_;
    YAML::Dump($stuff);
}

sub decode {
    my ($self, $stuff, @args) = @_;
    YAML::Load($stuff);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Data::Encoder::YAML - Data::Encoder gateway for YAML

=head1 SYNOPSIS

  use Data::Encoder;
  
  my $encoder = Data::Encoder->load('YAML');
  my $yaml = $encoder->encode({ foo => 'bar' });
  my $data = $encoder->decode($yaml);

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<YAML>

=cut
