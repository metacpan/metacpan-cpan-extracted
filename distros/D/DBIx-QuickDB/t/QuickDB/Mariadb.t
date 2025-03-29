BEGIN {
    $ENV{PATH}="$ENV{HOME}/dbs/mariadb11/bin:$ENV{PATH}" if -d "$ENV{HOME}/dbs/mariadb11/bin";
}

$main::DRIVERS = ['MariaDB'];
my $file = __FILE__;
$file =~ s{[^/]+\.t$}{QuickDB.pm}g;
$file = "./$file" if -f "./$file";
do $file;
