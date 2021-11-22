#!perl
use strict;
use Getopt::Long;
use DBIx::Spreadsheet;
use DBIx::RunSQL;
use Filesys::Notify::Simple;
use File::Basename 'dirname';

our $VERSION = '0.01';

GetOptions();

my ($file,@queries) = @ARGV;

my %watch_directory = map { ( -d $_ ? $_ : dirname($_)) => 1 }
                      grep { -e $_ }
                      @ARGV;

my $watcher = Filesys::Notify::Simple->new([
    sort keys %watch_directory,
]);

sub update_queries {
    warn $file;
    my $sheet = DBIx::Spreadsheet->new( file => $file );
    my $dbh = $sheet->dbh;

    my @eff_queries = map { -d ? glob "$_/*.sql" : $_ } @queries;

    for my $q (@eff_queries) {
        #warn $q;
        #eval {
            DBIx::RunSQL->run(
                dbh => $dbh,
                sql => \$q,
            );
        #};
    };
};

update_queries();

while(1) {
    $watcher->wait(\&update_queries);
};
