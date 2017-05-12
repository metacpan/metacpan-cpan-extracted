package Data::Serializer::XML::Dumper;
BEGIN { @Data::Serializer::XML::Dumper::ISA = qw(Data::Serializer) }

use warnings;
use strict;
use XML::Dumper qw(); 
use vars qw($VERSION @ISA);

$VERSION = '0.02';



sub serialize {
    my $self = (shift);
    my $xml = new XML::Dumper;
    if (defined $self->{options} && $self->{options}->{dtd}) {
      $xml->dtd;
    }
    return $xml->pl2xml( (shift) );
}

sub deserialize {
    my $xml = new XML::Dumper;
    return $xml->xml2pl($_[1]);
}

1;
__END__
#

=head1 NAME

Data::Serializer::XML::Dumper - Creates bridge between Data::Serializer and XML::Dumper

=head1 SYNOPSIS

  use Data::Serializer::XML::Dumper;

=head1 DESCRIPTION

Module is used internally to Data::Serializer

The only option currently supported is B<dtd>.  This just calls the dtd method of XML::Dumper
prior to serializing the data.   See XML::Dumper(3) for details.


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

perl(1), Data::Serializer(3), XML::Dumper(3).

=cut


