BEGIN {
    $ENV{PATH} = "$ENV{HOME}/dbs/mysql8/bin:$ENV{PATH}"    if -d "$ENV{HOME}/dbs/mysql8/bin";
    $ENV{PATH} = "$ENV{HOME}/dbs/percona8/bin:$ENV{PATH}"  if -d "$ENV{HOME}/dbs/percona8/bin";
    $ENV{PATH} = "$ENV{HOME}/dbs/mariadb11/bin:$ENV{PATH}" if -d "$ENV{HOME}/dbs/mariadb11/bin";
}

$main::DRIVERS = ['MySQL'];
my $file = __FILE__;
$file =~ s{[^/]+\.t$}{QuickDB.pm}g;
$file = "./$file" if -f "./$file";
do $file;
