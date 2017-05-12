### This is a dummy file so CPAN will find the file and VERSION
### This file is generated from 'KDB.in' by 'gen_dummy_kdb_pm.plx'

package Authen::Krb5::KDB;
$VERSION = do{my@r=q$Revision: 1.10 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

# This is to make sure require will return an error
0;
__END__

=head1 NAME

Authen::Krb5::KDB - Parse Kerberos V5 database dumps

=head1 SYNOPSIS

    use Authen::Krb5::KDB;
    $db = Authen::Krb5::KDB->new( file => 'slave_datatrans' );
    while ($p = $db->next) {
       print "Found" if ($p->name eq 'foo@TEST.ORG');
    }
    $db->close;

    use Authen::Krb5::KDB;
    $db = Authen::Krb5::KDB->new( realm => 'TEST.ORG' );
    $db->read;
    $db->close;
    $policies = $db->policies;
    foreach my $p (@{$policies}) {
        $p->print_policy;
    }


=head1 DESCRIPTION

Constructor and methods to parse Kerberos V5 database files, either
directly from kerberos (via B<kdb5_util>) or from already dumped files
(e.g. F<slave_datatrans>).

=over 4

=item  new()

Open the database file and return a new database object.  You can either
read from a file or read directly from Kerberos (done via "B<kdb5_util> B<-r>
E<lt>B<realm>E<gt> B<dump |>"; this is the default).

Arguments are:

realm => E<lt>realm_nameE<gt>

The realm which should be extracted via B<kdb5_util>.  This is ignored
if you use the file argument.

file => E<lt>filenameE<gt>

Read from a file instead of Kerberos directly.

checks => E<lt>levelE<gt>

Data checking level.  Level 0 means no checks; level 1 (the default)
does basic checks like checking that the lengths in the records are
correct; level 2 does much further consistency checks on the data.

save => 1

Save the principal objects in the database object.  Normally the
objects are not saved for space considerations.  Note that policy
objects are always kept.

=item  next()

Returns the next principal or policy object.

=item  read()

Reads all principals and policies. The objects are saved in the
database object.

=item  principals()

Returns a reference to array of principal objects

=item  policies()

Returns a reference to array of policy objects

=item  close()

Closes FH to database.  It's especially important to call C<close>
when reading directly via B<kdb5_util> to make sure there are no
errors from the pipe.

=back

=head1 AUTHOR

Dave Steiner, E<lt>steiner@bakerst.rutgers.eduE<gt>

=head1 COPYRIGHT

Copyright (c) 2002 David K. Steiner.  All rights reserved.  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), kerberos(1), Authen::Krb5::KDB::V5, Authen::Krb5::KDB::V4,
Authen::Krb5::KDB::V3, Authen::Krb5::KDB::V2, Authen::Krb5::KDB_H.

=cut
