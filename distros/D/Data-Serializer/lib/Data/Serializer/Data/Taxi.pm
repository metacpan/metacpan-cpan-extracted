package Data::Serializer::Data::Taxi;
BEGIN { @Data::Serializer::Data::Taxi::ISA = qw(Data::Serializer) }

use warnings;
use strict;
use Data::Taxi;
use vars qw($VERSION @ISA);

$VERSION = '0.02';


sub serialize {
    return Data::Taxi::freeze($_[1]);
}

sub deserialize {
    my ($obj) = Data::Taxi::thaw($_[1]);
    return $obj;
}



1;
__END__
# 

=head1 NAME

Data::Serializer::Data::Taxi - Creates bridge between Data::Serializer and Data::Taxi

=head1 SYNOPSIS

  use Data::Serializer::Data::Taxi;

=head1 DESCRIPTION

Module is used internally to Data::Serializer


=over 4

=item B<serialize> - Wrapper to normalize serializer method name

=item B<deserialize> - Wrapper to normalize deserializer method name

=back

=head1 AUTHOR

Neil Neely <neil@neely.cx>

=head1 COPYRIGHT

  Copyright 2001 by Neil Neely.  All rights reserved.
  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Data::Serializer(3), Data::Taxi(3).

=cut
