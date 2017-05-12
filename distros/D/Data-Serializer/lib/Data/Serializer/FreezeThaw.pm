package Data::Serializer::FreezeThaw;
BEGIN { @Data::Serializer::FreezeThaw::ISA = qw(Data::Serializer) }

use warnings;
use strict;
use FreezeThaw;
use vars qw($VERSION @ISA);

$VERSION = '0.02';


sub serialize {
    return FreezeThaw::freeze($_[1]);
}

sub deserialize {
    my ($obj) = FreezeThaw::thaw($_[1]);
    return $obj;
}

1;
__END__
# 

=head1 NAME

Data::Serializer::FreezeThaw - Creates bridge between Data::Serializer and FreezeThaw

=head1 SYNOPSIS

  use Data::Serializer::FreezeThaw;

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

perl(1), Data::Serializer(3), FreezeThaw(3).

=cut

