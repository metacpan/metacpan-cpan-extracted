package Data::Serializer::Data::Denter;
BEGIN { @Data::Serializer::Data::Denter::ISA = qw(Data::Serializer) }

use warnings;
use strict;

use Carp;
use Data::Denter;

use vars qw($VERSION @ISA);


$VERSION = '0.02';

#
# Create a Data::Denter serializer object.
#

sub serialize {
  my $self = shift;
  my ($val) = @_;
  return undef unless defined $val;
  return $val unless ref($val);
  return Data::Denter::Indent($val);
}


sub deserialize {
  my $self = shift;
  my ($val) = @_;
  return undef unless defined $val;
  return Data::Denter::Undent($val);
}

1;
__END__

# 

=head1 NAME

Data::Serializer::Data::Denter - Creates bridge between Data::Serializer and Data::Denter

=head1 SYNOPSIS

  use Data::Serializer::Data::Denter;

=head1 DESCRIPTION

Module is used internally to Data::Serializer 


=over 4

=item B<serialize> - Wrapper to normalize serializer method name

=item B<deserialize> - Wrapper to normalize deserializer method name

=back

=head1 AUTHOR

Neil Neely <neil@neely.cx>

=head1 COPYRIGHT

  Copyright 2002 by Neil Neely.  All rights reserved.
  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Data::Serializer(3), Data::Denter(3).

=cut

