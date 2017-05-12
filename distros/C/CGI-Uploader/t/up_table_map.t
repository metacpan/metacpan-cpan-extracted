use Test::More;
Test::More->builder->no_ending(1);
use lib 'lib';
use strict;
use HTTP::Request::Common;
use lib 't/lib';
use CGI::Uploader::Test; # provides setup() and read_file()
use Config;

use CGI::Uploader;
use DBI;
use CGI;
use Test::DatabaseRow;

$| = 1;

if (! $Config{d_fork} ) {
    plan skip_all => "fork not available on this platform";
}
else {
    plan tests => 19;
}

# skip default table create to do it ourselves later.
my ($DBH,$drv) = setup(skip_create_uploader_table => 1);

my $req = &HTTP::Request::Common::POST(
    '/dummy_location',
    Content_Type => 'form-data',
    Content      => [
        test_file => ["t/test_file.txt"],
    ]
);

# Useful in simulating an upload.
$ENV{REQUEST_METHOD} = 'POST';
$ENV{CONTENT_TYPE}   = 'multipart/form-data';
$ENV{CONTENT_LENGTH} = $req->content_length;
if ( open( CHILD, "|-" ) ) {
    print CHILD $req->content;
    close CHILD;
    exit 0;
}


my $q = new CGI;

ok(open(IN, "<create_uploader_table.".$drv.".sql"), 'opening SQL create file');
my $sql = join "\n", (<IN>);

# We alter the table to test our mapping
$sql =~ s/upload_id /upload_id_b /g;
$sql =~ s/mime_type/mime_type_b/;
$sql =~ s/extension/extension_b/;
$sql =~ s/width/width_b/;
$sql =~ s/height/height_b/;
$sql =~ s/gen_from_id/gen_from_id_b/;


my $created_up_table = $DBH->do($sql);
ok($created_up_table, 'creating uploads table');

     $DBH->do("ALTER TABLE uploads ADD COLUMN custom char(64)");

     my %imgs = (
        'test_file' => {
            gen_files => {
                'test_file_gen' => {
                    transform_method => \&test_gen_transform,
                }
            },
        },
     );

     my $u =    CGI::Uploader->new(
        updir_path=>'t/uploads',
        updir_url=>'http://localhost/test',
        dbh => $DBH,
        query => $q,
        spec => \%imgs,
        up_table_map => {
            upload_id => 'upload_id_b',
            mime_type => 'mime_type_b',
            extension => 'extension_b',
            width     => 'width_b',
            height    => 'height_b',
            gen_from_id => 'gen_from_id_b',
            custom    => undef,
        }
     );
     ok($u, 'Uploader object creation');

     my $form_data = $q->Vars;

     my ($entity);
     eval {
        ($entity) = $u->store_uploads($form_data);

     };
     is($@,'', 'calling store_uploads');

     my @pres = $u->spec_names;
     ok(eq_set([grep {m/_id$/} keys %$entity ],[map { $_.'_id'} @pres]),
        'store_uploads entity additions work');

    ok(not(grep {m/^(test_file)$/} keys %$entity),
           'store_uploads entity removals work');

    my @files = <t/uploads/*>;
    ok(scalar @files == 2, 'expected number of files created');

    $Test::DatabaseRow::dbh = $DBH;
    row_ok( sql   => "SELECT * FROM uploads  ORDER BY upload_id_b LIMIT 1",
                tests => {
                    'eq' => {
                        mime_type_b => 'text/plain',
                        extension_b => '.txt',
                    },
                    '=~' => {
                        upload_id_b => qr/^\d+/,
                    },
                } ,
                label => "reality checking a database row");

    my $row_cnt = $DBH->selectrow_array("SELECT count(*) FROM uploads ");
    is($row_cnt,2, 'number of rows in database');

{
   ok($DBH->do(qq!INSERT INTO cgi_uploader_test (item_id,test_file_id,test_file_gen_id) VALUES (1,1,2)!),
    'test data insert');
    my $tmpl_vars_ref = $u->fk_meta(
        table   => 'cgi_uploader_test',
        where   => {item_id => 1},
        prefixes => [qw/test_file test_file_gen/]);

    use Data::Dumper;
    ok (eq_set(
            [qw/
                test_file_url
                test_file_id
                test_file_gen_url
                test_file_gen_id
            /],
            [keys %$tmpl_vars_ref],
        ), 'fk_meta keys returned') || diag Dumper($tmpl_vars_ref);

    like($tmpl_vars_ref->{test_file_url}, qr/1\.txt/, "fk_meta URLs look correct");
}

     $q->param('test_file_id',1);
     $q->param('test_file_delete',1);
     my @deleted_field_ids = $u->delete_checked_uploads;


    my @cmp_array = (\@deleted_field_ids,['test_file_id', 'test_file_gen_id']);
     ok(eq_set(@cmp_array),
         'delete_checked_uploads returned field ids') || diag Dumper (@cmp_array);

     @files = <t/uploads/*>;

    is((scalar @files),0, 'expected number of files removed');

    $row_cnt = $DBH->selectrow_array("SELECT count(*) FROM uploads ");
    is($row_cnt,0, 'number of rows removed');

    #  my $all = $DBH->selectall_arrayref("SELECT * from uploads",{ Slice => {}});
    #  use Data::Dumper;
    #  warn Dumper ($all);


