package Data::Serializer::Storable;
BEGIN { @Data::Serializer::Storable::ISA = qw(Data::Serializer) }

use warnings;
use strict;
use Storable;
use vars qw($VERSION @ISA);

$VERSION = '0.03';


#
# Serialize a reference to supplied value
#
sub serialize {
	my $self = $_[0];
	my $ret;
	$ret = Storable::nfreeze($_[1]);
	#using network byte order makes sense to always do, under all circumstances to make it platform neutral
	#if ($self->{portable}) {
	#	$ret = Storable::nfreeze($_[1]);
	#} else {
	#	$ret = Storable::freeze($_[1]);
	#}
	defined($ret) ? $ret : undef;
}

#
# Deserialize and de-reference
#
sub deserialize {
    my $ret = Storable::thaw($_[1]);            # Does not care whether portable
    defined($ret) ? $ret : undef;
}

1;
__END__
# 

=head1 NAME

Data::Serializer::Storable - Creates bridge between Data::Serializer and Storable

=head1 SYNOPSIS

  use Data::Serializer::Storable;

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

perl(1), Data::Serializer(3), Data::Dumper(3).

=cut

