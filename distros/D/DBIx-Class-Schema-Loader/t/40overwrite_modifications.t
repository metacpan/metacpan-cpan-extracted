use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;
use lib qw(t/lib);
use make_dbictest_db;

use File::Copy;
use File::Spec;
use File::Temp qw/ tempdir tempfile /;

use DBIx::Class::Schema::Loader;
use DBIx::Class::Schema::Loader::Utils qw/ slurp_file /;

my $tempdir = tempdir( CLEANUP => 1 );
my $foopm = File::Spec->catfile( $tempdir,
    qw| DBICTest Schema Overwrite_modifications Result Foo.pm |);
dump_schema();

# check that we dumped
ok( -f $foopm, 'looks like it dumped' );

# now modify one of the files
rewrite_file($foopm, qr{"bars"}, q{"somethingelse"});

# and dump again without overwrites
throws_ok {
    dump_schema();
} qr/mismatch/, 'throws error dumping without overwrite_modifications';

# and then dump with overwrite
lives_ok {
    dump_schema( overwrite_modifications => 1 );
} 'does not throw when dumping with overwrite_modifications';

# Replace the md5 with a bad MD5 in Foo.pm
my $foopm_content = slurp_file($foopm);
my ($md5) = $foopm_content =~/md5sum:(.+)$/m;
# This cannot be just any arbitrary value, it has to actually look like an MD5
# value or DBICSL doesn't even see it as an MD5 at all (which makes sense).
my $bad_md5 = reverse $md5;
rewrite_file($foopm, qr{md5sum:.+$}, "md5sum:$bad_md5");

# and dump again without overwrites
throws_ok {
    dump_schema();
} qr/mismatch/, 'throws error dumping without overwrite_modifications';

$foopm_content = slurp_file($foopm);
like(
    $foopm_content,
    qr/\Q$bad_md5/,
    'bad MD5 is not rewritten when overwrite_modifications is false'
);

# and then dump with overwrite
lives_ok {
    dump_schema( overwrite_modifications => 1 );
} 'does not throw when dumping with overwrite_modifications';

$foopm_content = slurp_file($foopm);
unlike(
    $foopm_content,
    qr/\Q$bad_md5/,
    'bad MD5 is rewritten when overwrite_modifications is true'
);

sub dump_schema {

    # need to poke _loader_invoked in order to be able to rerun the
    # loader multiple times.
    DBICTest::Schema::Overwrite_modifications->_loader_invoked(0)
        if @DBICTest::Schema::Overwrite_modifications::ISA;

    my $args = \@_;

    warnings_exist {
        DBIx::Class::Schema::Loader::make_schema_at(
            'DBICTest::Schema::Overwrite_modifications',
            { dump_directory => $tempdir, @$args },
            [ $make_dbictest_db::dsn ],
        );
    } [qr/^Dumping manual schema/, qr/^Schema dump completed/ ],
    'schema was dumped with expected warnings';
}

sub rewrite_file {
    my ($file, $match, $replace) = @_;

    open my $in, '<', $file or die "$! reading $file";
    my ($tfh, $temp) = tempfile( UNLINK => 1 );
    while(<$in>) {
        s/$match/$replace/;
        print $tfh $_;
    }
    close $tfh;
    copy( $temp, $file );
}

done_testing();
