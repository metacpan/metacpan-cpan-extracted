package Data::Serializer::YAML;
BEGIN { @Data::Serializer::YAML::ISA = qw(Data::Serializer) }

use warnings;
use strict;
use YAML;
local $YAML::LoadBlessed = 0;

use vars qw($VERSION @ISA);

$VERSION = '0.03';

sub serialize {
    return Dump($_[1]);
}

sub deserialize {
    return Load($_[1]);
}



1;
__END__
#

=head1 NAME

Data::Serializer::YAML - Creates bridge between Data::Serializer and YAML

=head1 SYNOPSIS

  use Data::Serializer::YAML;

=head1 DESCRIPTION

Module is used internally to Data::Serializer


=over 4

=item B<serialize> - Wrapper to normalize serializer method name

=item B<deserialize> - Wrapper to normalize deserializer method name

=back

=head1 AUTHOR

Florian Helmberger <fh@laudatio.com>

=head1 COPYRIGHT

  Copyright 2002 by Florian Helmberger.  All rights reserved.
  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Data::Serializer(3), YAML(3).

=cut

