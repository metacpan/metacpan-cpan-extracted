package Data::Serializer::Config::General;
BEGIN { @Data::Serializer::Config::General::ISA = qw(Data::Serializer) }
use warnings;
use strict;
use Config::General;
use vars qw($VERSION @ISA);

$VERSION = '0.02';
sub options {
  return (shift)->{options};
}

sub serialize {
  my $self = (shift);
  my $ref = (shift);
  return (new Config::General(%{$self->options()}, -ConfigHash => $ref))->save_string();
}

sub deserialize {
  my $self = (shift);
  my $ref = (shift);
  my %hash =  (new Config::General(%{$self->options()}, -String => $ref))->getall();
  return \%hash;
}

1;

__END__

=head1 NAME

Data::Serializer::Config::General - Creates bridge between Data::Serializer and Config::General

=head1 SYNOPSIS

  use Data::Serializer::Config::General;

=head1 DESCRIPTION

Module is used internally to Data::Serializer

=head1 METHODS
                  
=over 4
                  
=item B<serialize> - Wrapper to normalize serializer method name

=item B<deserialize> - Wrapper to normalize deserializer method name

=item B<options> - Pass options through to underlying serializer


=back

=head1 CAVEAT

Base data structure to serialize must be a hash reference

=head1 AUTHOR

Thomas Linden <tom@daemon.de>

=head1 COPYRIGHT

  Copyright 2002 by Thomas Linden.  All rights reserved.
  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Data::Serializer(3), Config::General(3)

=cut
