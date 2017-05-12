package MyInstall;

use base qw(App::Install);

MyInstall->files(
    "installed/foo.txt" => "foo.tmpl",
    "installed/bar.txt" => "bar.tmpl",
);

MyInstall->permissions("installed/foo.txt" => 0755);

# MyInstall->delimiters('[', ']');


