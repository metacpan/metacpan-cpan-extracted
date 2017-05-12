#! perl

use Test::More qw(no_plan);

use FindBin;
use File::Spec;

use_ok('Cache::Repository');
use_ok('Cache::Repository::Filesys');

# check constructors.
my %opts = (
            path => File::Spec->catdir($FindBin::Bin,
                                       File::Spec->updir(),
                                       '_repository'),
            #compress => undef,
            );
mkdir($opts{path});
my $remove_me = File::Spec->catdir($opts{path}, 'blah');
mkdir($remove_me);

# clear should remove the extra directory.
isa_ok(Cache::Repository->new(style => 'Filesys', %opts, clear => 1), 'Cache::Repository::Filesys');
ok(! -e $remove_me);

my $obj = Cache::Repository::Filesys->new(%opts);
isa_ok($obj, 'Cache::Repository::Filesys');

my $rc =
    $obj->add_files(
                    tag => 'test',
                    files => $0,
                    basedir => $FindBin::Bin . '/..',
                   );
ok($rc);

$rc =
    $obj->add_files(
                    tag => 'test',
                    files => $0,
                    filename_conversion => sub { s/\.t$/\.pl/ },
                    basedir => $FindBin::Bin . '/..',
                   );
ok($rc);


my $buffer = 'some
    large
    test
' x 100;
{
    open my $fh, '<', \$buffer;

    $rc =
        $obj->add_filehandle(
                             tag => 'string_test',
                             filehandle => $fh,
                             filename => 'large.txt',
                            );
    ok($rc);
}

{
    my $hash = $obj->retrieve_as_hash(tag => 'string_test');
    ok(keys %$hash == 1);
    ok($hash->{'large.txt'}{data} eq $buffer);
}

$obj->set_meta(tag => 'test',
               meta => {
                   name => 'test tag',
                   author => 'dmcbride@cpan.org',
               },
              );
my $info = $obj->get_meta(tag => 'test');
is($info->{name}, 'test tag', 'retrieving meta info');

# mismatch on number of files to change names...
eval {
    $obj->add_files(
                    tag => 'test2',
                    files => $0,
                    filename_conversion => [qw(a b)],
                   );
    fail();
};
ok($@);

# check that the file is in properly.
my @files = $obj->list_files(tag => 'test');
ok(@files == 2);
{
    my @fname = ($0, $0);
    $fname[1] =~ s/\.t$/\.pl/;
    @files = sort @files;
    @fname = sort @fname;
    ok($files[$_] eq $fname[$_]) for 0..$#files;
}

my $hash = $obj->retrieve_as_hash(
                                  tag => 'test',
                                  files => \@files,
                                 );
ok($hash);
ok(keys %$hash == 2);
isa_ok($hash->{$0}, 'HASH');
ok($hash->{$0}{data});

# read self to compare.
seek(DATA,0,0);
my $data = join '', <DATA>;
is($hash->{$0}{data}, $data, "Check file contents...");

my $size = $obj->get_size(tag => 'test');
ok(($size >= 2 * (-s $0)) and ($size <= 2 * (1024 + -s $0))) or
    diag("Size: $size, expected about " . (2*-s $0));

my @tags = $obj->list_tags();
ok(@tags);
ok(@tags == 2);

1;
__DATA__
This is here to allow seek(DATA,0,0) to work.
