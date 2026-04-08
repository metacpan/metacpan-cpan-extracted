BEGIN {
    $ENV{PATH}="$ENV{HOME}/dbs/percona8/bin:$ENV{PATH}" if $ENV{HOME} && -d "$ENV{HOME}/dbs/percona8/bin";
}

$main::DRIVERS = ['Percona'];
my $file = __FILE__;
$file =~ s{[^/]+\.t$}{QuickDB.pm}g;
$file = "./$file" if -f "./$file";
do $file;
