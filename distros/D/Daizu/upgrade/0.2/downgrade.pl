#!/usr/bin/perl
use warnings;
use strict;

=head1 NAME

downgrade.pl - downgrade the database for a S<Daizu 0.2> installation to work with S<Daizu 0.1>

=head1 DESCRIPTION

You should never need to run this, unless you've already run the upgrade
script I<upgrade-0.1-0.2.pl> and it has caused a problem.  This program
will reverse the process.  No new information is lost, so you can then
rerun the upgrade script safely.  This script will work with S<version 0.1>
S<or 0.2> installed.

If this won't be able to find your Daizu configuration file automatically
you can provide it as an argument when you run this program.

All the database changes are made within a transaction, so any errors
should cause it all to be rolled back to how it started.

=cut

use Daizu;

my $cms = Daizu->new(@ARGV);
my $db = $cms->db;

$db->begin_work;

print STDERR "Dropping tables, columns, and constraints:\n";
print STDERR " * wc_file_article_loaded_chk\n";
$db->do('alter table wc_file drop constraint wc_file_article_loaded_chk');
print STDERR " * wc_article_extra_url\n";
$db->do('drop table wc_article_extra_url');
print STDERR " * wc_article_extra_template\n";
$db->do('drop table wc_article_extra_template');
print STDERR " * wc_article_included_files\n";
$db->do('drop table wc_article_included_files');
print STDERR " * wc_file.no_index\n";
$db->do('alter table wc_file drop column no_index');
print STDERR " * wc_file.short_title\n";
$db->do('alter table wc_file drop column short_title');
print STDERR " * wc_file.article_pages_url\n";
$db->do('alter table wc_file drop column article_pages_url');
print STDERR " * wc_file.article_content\n";
$db->do('alter table wc_file drop column article_content');

print STDERR "Clear extra generator information.\n";
print STDERR " * drop wc_file.generator not null\n";
$db->do('alter table wc_file alter column generator drop not null');
print STDERR " * throw away non-root generator names\n";
$db->do(q{
    update wc_file
    set generator = null
    where root_file_id is not null
});
print STDERR " * drop wc_file.root_file_id\n";
$db->do('alter table wc_file drop column root_file_id');

print STDERR "Rename wc_file.custom_url to wc_file.base_url.\n";
$db->do('alter table wc_file rename column custom_url to base_url');

print STDERR "Committing.\n";
$db->commit;
print STDERR "Done.\n";

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

# vi:ts=4 sw=4 expandtab
