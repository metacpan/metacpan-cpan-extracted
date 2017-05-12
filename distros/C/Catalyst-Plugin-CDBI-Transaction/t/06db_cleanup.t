use Test::More;
BEGIN: {
    my @missing = ();
    eval "use Catalyst::Model::CDBI";
    push @missing, "Catalyst::Model::CDBI" if $@;
    eval "use Class::DBI::SQLite";
    push @missing, "Class::DBI::SQLite" if $@;
    eval "use YAML";
    push @missing, "YAML" if $@;
    if ( @missing ) {
        plan skip_all => "The following are required to run the test app: " .
                         join(', ', @missing);
    }
    else {
        plan tests => 1;
    }
}
use lib 't/MyApp/lib';
use FindBin;
use File::Spec;

my $home = File::Spec->catfile($FindBin::Bin, 'MyApp');
my $db_file = File::Spec->catfile($home, 'myapp.db');

ok(
    do{ unlink $db_file or die "Couldn't unlink $db_file: $!" },
    "Delete $db_file"
);
