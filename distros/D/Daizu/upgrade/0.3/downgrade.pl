#!/usr/bin/perl
use warnings;
use strict;

=head1 NAME

downgrade.pl - downgrade the database for a S<Daizu 0.3> installation to work with S<Daizu 0.2>

=head1 DESCRIPTION

This adjust the Daizu database for a S<Daizu 0.3> installation to work
with S<Daizu 0.2>.

The only change this makes it to change the method of C<xml_sitemap>
URLs back to C<google_sitemap>.  The other changes made by the
corresponding upgrade script are backwards compatible anyway, so they
are left in the upgraded state.

This script is idempotent, so it won't do any harm to run it on a
database which has already been downgraded.

=cut

use Daizu;
use Daizu::Util qw( transactionally );

my $cms = Daizu->new(@ARGV);
my $db = $cms->db;

transactionally($db, sub {


print STDERR "Rename 'xml_sitemap' method back to 'google_sitemap'.\n";
$db->do(q{
    update url
    set method = 'google_sitemap'
    where generator = 'Daizu::Gen'
      and method = 'xml_sitemap'
});


print STDERR "Committing.\n";
});
print STDERR "Done.\n";

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

# vi:ts=4 sw=4 expandtab
