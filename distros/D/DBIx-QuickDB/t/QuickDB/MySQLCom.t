BEGIN {
    $ENV{PATH} = "$ENV{HOME}/dbs/mysql8/bin:$ENV{PATH}" if -d "$ENV{HOME}/dbs/mysql8/bin";
}

$main::DRIVERS = ['MySQLCom'];
my $file = __FILE__;
$file =~ s{[^/]+\.t$}{QuickDB.pm}g;
$file = "./$file" if -f "./$file";
do $file;
