package Authen::Krb5::KDB::Utils;

# $Id: Utils.pm,v 1.2 2002/10/09 20:42:21 steiner Exp $

use Carp;
use POSIX qw(strftime);
use strict;
use vars qw($VERSION @ISA @EXPORT);

$VERSION = do{my@r=q$Revision: 1.2 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(strdate check_length);

sub strdate ($) {
    my $when = shift;
    return "[never]"  if (not $when);
    my @tm = localtime($when);
    return strftime("%a %b %d %H:%M:%S %Z %Y", @tm);
}

# Returns true if two values don't "match", false if they do "match".
#  To "match": If the first value is 0, the second one must be -1;
#              Or the first value must be the length of the second.
sub check_length ($$) {
    my $len = shift;
    my $data = shift;

    if ($len == 0) {
	return (not ($data == -1));
    } else {
	return ($len != length($data));
    }
}

1;
__END__

=head1 NAME

Authen::Krb5::KDB::Utils - utility functions for Kerberos V5 database modules


=head1 SYNOPSIS

    use Authen::Krb5::KDB::Utils;

    print strdate($principal->last_success()), "\n";

    if (check_length($principal->e_length, $principal->e_data) {
	carp "principal e_data length field not ok";
    }


=head1 DESCRIPTION

Generally this functions are only used internally within other KDB modules.

=over 4

=item  strdate( DATE )

Return localtime-format date in readable format similar to dates used
in B<kadmin>.

=item  check_length( LENGTH, DATA )

Function to compare various length fields with their data
counterparts.  Returns true if the two values don't "match", false if
they do "match".  "Matching" is defined as follows: If the first value
is 0, the second value must be -1, or the first value must be the length
of the second.

=back


=head1 AUTHOR

Dave Steiner, E<lt>steiner@bakerst.rutgers.eduE<gt>


=head1 COPYRIGHT

Copyright (c) 2002 David K. Steiner.  All rights reserved.  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), kerberos(1), Authen::Krb5::KDB, Authen::Krb5::KDB::V3.

=cut
