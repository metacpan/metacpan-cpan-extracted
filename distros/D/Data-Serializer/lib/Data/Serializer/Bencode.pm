package Data::Serializer::Bencode;
BEGIN { @Data::Serializer::Bencode::ISA = qw(Data::Serializer) }

use warnings;
use strict;
use Bencode;
use vars qw($VERSION @ISA);

$VERSION = '0.03';

sub serialize {
	return Bencode::bencode($_[1]);
}

sub deserialize {
	return Bencode::bdecode($_[1]);
}

1;
__END__



=head1 NAME

Data::Serializer::Bencode - Creates bridge between Data::Serializer and Bencode

=head1 SYNOPSIS

  use Data::Serializer::Bencode;

=head1 DESCRIPTION

Module is used internally to Data::Serializer

=over 4
       
=item B<serialize> - Wrapper to normalize serializer method name

=item B<deserialize> - Wrapper to normalize deserializer method name


=back

=head1 AUTHOR

Neil Neely <F<neil@neely.cx>>.

http://neil-neely.blogspot.com/

=head1 BUGS

Please report all bugs here:

http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Serializer


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Neil Neely.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1), Data::Serializer(3), Bencode(3).

=cut

