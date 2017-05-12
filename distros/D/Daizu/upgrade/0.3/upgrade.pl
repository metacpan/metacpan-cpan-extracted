#!/usr/bin/perl
use warnings;
use strict;

=head1 NAME

upgrade.pl - upgrade the database for a S<Daizu 0.2> installation to work with S<Daizu 0.3>

=head1 DESCRIPTION

Run this once after you've installed the S<Daizu 0.3> code and made any
necessary changes to your content repository.

If this won't be able to find your Daizu configuration file automatically
you can provide it as an argument when you run this program.

This will drop and recreate an index which was previously not unique
but should have been, and also drop some tables which were never used
in any public release of Daizu.  It will also change any URLs with the
method C<google_sitemap> to C<xml_sitemap>, since that's what the code now
uses.  None of this should cause any problems.

All the database changes are made within a transaction, so any errors
should cause it all to be rolled back to how it started.

Unlike the previous version's upgrade script, this one is idempotent,
so it won't do any harm to run it on a database which has already been
upgraded.

=cut

use Daizu;
use Daizu::Util qw( db_row_exists transactionally );

my $cms = Daizu->new(@ARGV);
my $db = $cms->db;

transactionally($db, sub {


print STDERR "Correcting unique URL index:\n",
             " * drop url_unique_idx\n";
$db->do('drop index url_unique_idx');
print STDERR " * recreate url_unique_idx\n";
$db->do('create unique index url_unique_idx on url (url, wc_id)');


print STDERR "Drop unnecessary tables:\n";
for (qw( job_property job_file publish_job )) {
    print STDERR " * $_\n";
    my $table_exists = db_row_exists($db, 'information_schema.tables',
        table_schema => 'public',
        table_name => $_,
    );

    if ($table_exists) {
        $db->do("drop table $_");
    }
    else {
        print STDERR "   (already gone)\n";
    }
}


print STDERR "Rename 'google_sitemap' method to 'xml_sitemap'.\n";
$db->do(q{
    update url
    set method = 'xml_sitemap'
    where generator = 'Daizu::Gen'
      and method = 'google_sitemap'
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
