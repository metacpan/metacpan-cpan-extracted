1;
__END__

=pod

=head1 NAME

DBD::Plibdata - a DBI driver for Jenzabar's Plibdata/cisaps access method for CX systems

=head1 SYNOPSIS

 use strict;
 use DBI;
 my $dbh = DBI->connect("dbi:Plibdata:host=$HOSTNAME;port=$PORT", 
                     $USERNAME, $PASSWORD, {PrintError => 0});
 my $sql = "SELECT fullname FROM id_rec WHERE id = 1";
 my ($name) = $dbh->selectrow_array($sql);
 
 $sql =<<EOT;
 SELECT txt
 FROM runace_aps 
 WHERE ace = '/opt/carsi/install/arc/hr/acereport.arc'
 AND params = '';
 EOT
 my ($acetxt) = $dbh->selectrow_array($sql);

=head1 DESCRIPTION

Jenzabar's Plibdata provides access to many appservers including ACE reports via
runace_aps. It also supports rudimentary SQL statements.

=head1 AUTHOR

Stephen Olander-Waters < stephenw AT stedwards.edu >

=head1 LICENSE

Copyright (c) 2005-2007 by Stephen Olander-Waters, all rights reserved.

You may freely distribute and/or modify this module under the terms of either
the GNU General Public License (GPL) or the Artistic License, as specified in
the Perl README file.

No Jenzabar code or intellectual property was used or misappropriated in the
making of this module.

=head1 SEE ALSO

L<DBI>, L<DBD::Informix>, L<DBI::DBD>, L<IO::Socket::INET>, L<Digest::MD5>

=cut
