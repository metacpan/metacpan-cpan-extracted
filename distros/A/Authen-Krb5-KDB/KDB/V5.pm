package Authen::Krb5::KDB::V5;

# $Id: V5.pm,v 1.8 2002/10/09 20:41:42 steiner Exp $

use Carp;
use Authen::Krb5::KDB::V4;
use strict;
use vars qw($VERSION @ISA);

@ISA = ( "Authen::Krb5::KDB::V4" );

$VERSION = do{my@r=q$Revision: 1.8 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

# Basic format of the data is the same as V4, just the encoded data
# is different.

1;
__END__

=head1 NAME

Authen::Krb5::KDB::V5 - objects for Kerberos V5 database V5 principals and policies


=head1 SYNOPSIS

Generally you won't load this library or call it's C<new> methods directly.
See L<Authen::Krb5::KDB> for more information.

    use Authen::Krb5::KDB::V5;

    $p = Authen::Krb5::KDB::V5->new( data => "..." );

    if ($p->type eq 'princ') {
	print $p->name, ": ", $p->fail_auth_count"\n";
    } elsif ($p->type eq 'policy') {
	print $p->name, ": ", $p->policy_refcnt, "\n";
    }


=head1 DESCRIPTION

=over 4

=item  new( data => "..." )

Parses version 5 principal and policy entries and returns the data via
an object.  Calls either C<new_princ> or C<new_policy> depending on the data.

Arguments are:

data => E<lt>stringE<gt>

Data to be parsed.  This argument is required.

checks => E<lt>levelE<gt>

Data checking level.  Level 0 means no checks; level 1 (the default)
does basic checks like checking that the lengths in the records are
correct; level 2 does much further consistency checks on the data.

lineno => E<lt>NE<gt>

Line number of the data file where this data came from (for error messages).

=back


=head2 Principals

=over 4

=item  new_princ( data => "..." )

Parses version 5 principal entries and returns the data via an object.

Arguments are:

data => E<lt>stringE<gt>

Data to be parsed.  This argument is required.

checks => E<lt>levelE<gt>

Data checking level.  Level 0 means no checks; level 1 (the default)
does basic checks like checking that the lengths in the records are
correct; level 2 does much further consistency checks on the data.

lineno => E<lt>NE<gt>

Line number of the data file where this data came from (for error messages).

=back


Methods to retrieve and set data fields are:

=over 4

=item  type (I<read only>)

=item  len (I<read only>)

=item  name_len (I<read only>)

=item  n_tl_data (I<read only>)

=item  n_key_data (I<read only>)

=item  e_length (I<read only>)

=item  name

=item  attributes

=item  max_life

=item  max_renew_life

=item  expiration

=item  pw_expiration

=item  last_success

=item  last_success_dt (I<read only>)

=item  last_failed

=item  last_failed_dt (I<read only>)

=item  fail_auth_count

=item  tl_data

See the L<Authen::Krb5::KDB::TL> for methods to deal with TL objects.

=item  key_data

See the L<Authen::Krb5::KDB::Key> for methods to deal with Key
objects.

=item  e_data

=back

Other methods include:

=over 4

=item  print_principal

Print out the data on a principal, similar to the B<get_principal>
command in B<kadmin>, but more verbose.

=item  get_attributes

Return a string of all the attributes set for this principal.

=back


=head2 Policies

=over 4

=item  new_policy( data => "..." )

Parses version 5 policy entries and returns the data via an object.

Arguments are:

data => E<lt>stringE<gt>

Data to be parsed.  This argument is required.

checks => E<lt>levelE<gt>

Data checking level.  Level 0 means no checks; level 1 (the default)
does basic checks like checking that the lengths in the records are
correct; level 2 does much further consistency checks on the data.

lineno => E<lt>NE<gt>

Line number of the data file where this data came from (for error messages).

=back


Methods to retrieve and set policy data fields are:

=over 4

=item  type (I<read only>)

=item  name

=item  pw_max_life

=item  pw_min_life

=item  pw_min_length

=item  pw_min_classes

=item  pw_history_num

=item  policy_refcnt

=back

Other methods include:

=over 4

=item  print_policy

Print out the policy data, similar to the B<get_policy> command in
B<kadmin>.

=back


=head1 AUTHOR

Dave Steiner, E<lt>steiner@bakerst.rutgers.eduE<gt>


=head1 COPYRIGHT

Copyright (c) 2002 David K. Steiner.  All rights reserved.  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), kerberos(1), Authen::Krb5::KDB, Authen::Krb5::KDB_H,
Authen::Krb5::KDB::TL, Authen::Krb5::KDB::Key.

=cut
