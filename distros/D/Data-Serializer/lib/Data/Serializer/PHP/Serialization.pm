package Data::Serializer::PHP::Serialization;
BEGIN { @Data::Serializer::PHP::Serialization::ISA = qw(Data::Serializer) }

use warnings;
use strict;
use PHP::Serialization qw(); 
use vars qw($VERSION @ISA);

$VERSION = '0.02';

sub serialize {
    return PHP::Serialization::serialize($_[1]);
}

sub deserialize {
    return PHP::Serialization::unserialize($_[1]);
}




1;
__END__
#

=head1 NAME

Data::Serializer::PHP::Serialization - Creates bridge between Data::Serializer and PHP::Serialization

=head1 SYNOPSIS

  use Data::Serializer::PHP::Serialization;

=head1 DESCRIPTION

Module is used internally to Data::Serializer


=over 4

=item B<serialize> - Wrapper to normalize serializer method name

=item B<deserialize> - Wrapper to normalize deserializer method name

=back

=head1 AUTHOR
 
Neil Neely <neil@neely.cx>
    
=head1 COPYRIGHT
 
  Copyright 2004 by Neil Neely.  All rights reserved.
  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.
  
=head1 SEE ALSO

perl(1), Data::Serializer(3), PHP::Serialization(3).

=cut

