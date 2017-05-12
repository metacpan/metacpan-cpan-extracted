#!perl

use utf8;
use strict;
use warnings;
use Amazon::MWS::Uploader;
use Data::Dumper;
use Test::More;
use DateTime;
use DBI;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $feed_dir = 't/feeds';

if (-d 'schemas') {
    plan tests => 12;
}
else {
    plan skip_all => q{Missing "schemas" directory with the xsd from Amazon, skipping feeds tests};
}



unless (-d $feed_dir) {
    mkdir $feed_dir or die "Cannot create $feed_dir $!";
}

my %constructor = (
                   merchant_id => '__MERCHANT_ID__',
                   shop_id => 'shoppe',
                   access_key_id => '12341234',
                   secret_key => '123412341234',
                   marketplace_id => '123412341234',
                   endpoint => 'https://mws-eu.amazonservices.com',
                   feed_dir => $feed_dir,
                   schema_dir => 'schemas',
                   db_dsn => 'dbi:SQLite:dbname=t/test.db',
                   db_username => '',
                   db_password => '',
                  );



my $uploader = Amazon::MWS::Uploader->new(%constructor);
ok ($uploader->dbh);
my $create_table =<<'SQL';
CREATE TABLE amazon_mws_jobs (
      amws_job_id VARCHAR(64) NOT NULL,
      shop_id VARCHAR(64) NOT NULL,
      task VARCHAR(64) NOT NULL,
      -- if complete one or those has to be set.
      aborted BOOLEAN NOT NULL DEFAULT FALSE,
      success BOOLEAN NOT NULL DEFAULT FALSE,
      last_updated TIMESTAMP,
      job_started_epoch INTEGER,
      status VARCHAR(255),
      PRIMARY KEY (amws_job_id, shop_id)
); 
SQL
my $create_p_table = <<'SQL';
CREATE TABLE amazon_mws_products (
       -- don't enforce the sku format
       sku VARCHAR(255) NOT NULL,
       shop_id VARCHAR(64) NOT NULL,
       -- given that we just test for equality, don't enforce a type.
       -- So an epoch will do just fine, as it would be a random date,
       -- as long as the script sends consistent data
       timestamp_string VARCHAR(255) NOT NULL DEFAULT '0',
       status VARCHAR(32),
       -- this can be null
       amws_job_id VARCHAR(64) REFERENCES amazon_mws_jobs(amws_job_id),
       error_code integer NOT NULL DEFAULT '0',
       error_msg TEXT,
       listed_date DATETIME,
       -- our update
       last_updated TIMESTAMP,
       PRIMARY KEY (sku, shop_id)
);
SQL
$uploader->dbh->do('DROP TABLE IF EXISTS amazon_mws_jobs');
$uploader->dbh->do($create_table) or die;
$uploader->dbh->do('DROP TABLE IF EXISTS amazon_mws_products');
$uploader->dbh->do($create_p_table) or die;

my $dbh = $uploader->dbh;


my @populate = get_sample_records('t/jobs.txt');
my $pop_sth = $dbh->prepare("INSERT INTO amazon_mws_jobs (amws_job_id, shop_id, task, aborted, success, last_updated, job_started_epoch, status) values (?, ?, ?, 0, 0, ?, ?, NULL)");
$dbh->begin_work;
foreach my $sample (@populate) {
    $pop_sth->execute(@$sample);
}
$dbh->commit;

sub get_sample_records {
    my $file = shift;
    my @records;
    open (my $fh, '<', $file) or die "Cannot open $file $!";
    while (my $row = <$fh>) {
        my @things;
        while ($row =~ m/(?<=\|)\s*(.+?)\s*(?=\|)/g) {
            my $v = $1;
            push @things, $v;
        }
        push @records, \@things if @things;
    }
    close $fh;
    return @records;
}
my @jobs = $uploader->get_pending_jobs;
ok (@jobs > 0, "Found " . scalar(@jobs) . " jobs\n");
# diag Dumper([$uploader->get_pending_jobs]);
is $jobs[0]->{task}, 'product_deletion', "First job is product_deletion";
is ((grep { $_->{task} ne 'product_deletion' } @jobs)[0]{task}, 'upload',
    "next in line is upload");
is $jobs[$#jobs]{task}, 'order_ack', "Last is order_ack";
ok (scalar(grep { $_->{task} eq 'shipping_confirmation' } @jobs), "Found shipconfirms");

# db is bogus, will just remove them
{
    my @named = $uploader->get_pending_jobs({ task => [qw/upload/] });
    ok (scalar(@named), "Found jobs");
    is (scalar(grep { $_->{task} ne 'upload' } @named), 0, "Only upload found");
    diag "Resuming all uploads";
    $uploader->resume({ task => 'upload' });
}
{
    my @named = $uploader->get_pending_jobs('product_deletion-2016-04-20-22-00-08');
    is (scalar(@named), 1, "Found a single job");
    is $named[0]{amws_job_id}, 'product_deletion-2016-04-20-22-00-08';
    diag "Resuming a single job";
    $uploader->resume('product_deletion-2016-04-20-22-00-08');
}

diag "Doing ship confirm and deletion";
$uploader->resume({ task => [qw/shipping_confirmation product_deletion/] });

diag "Resuming everything";
$uploader->resume;

@jobs = grep { $_->{task} ne 'order_ack' } $uploader->get_pending_jobs;
ok (!@jobs, "No regular jobs expected now");
@jobs = $uploader->get_pending_jobs;
ok (@jobs, "But there are still order_ack jobs pending");
