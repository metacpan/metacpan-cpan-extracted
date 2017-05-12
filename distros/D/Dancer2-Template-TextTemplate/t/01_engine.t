use Test::More tests => 18;
use Test::API;
use Test::Fatal;
use File::Temp ();
use autodie ':all';

### Checking module interface

my $module;

BEGIN {
    $module = 'Dancer2::Template::TextTemplate::FakeEngine';
    use_ok $module;
}

class_api_ok $module, qw{
    new
    caching expires cache_stringrefs
    delimiters
    prepend
    safe safe_opcodes safe_disposable
    process
};

my $e = new_ok $module;

### Checking default values

is $e->caching, 1,    'caching is enabled by default';
is $e->expires, 3600, 'cached instances expire after 3600 sec by default';
is_deeply $e->delimiters, [ '{', '}' ], 'delimiters are { and } by default';

### Real-life example

is(
    exception {
        $e->caching(0);
        $e->expires(0);
        $e->delimiters( [qw/ `[+ +]´ /] );
    },
    undef,
    'successfully modified attributes'
);

# Creates a $template_file and a $template_string from an untouched
# $reference_file, so that we can safely change the content of $template_file
# without modifying versioned test-suite files.
my $reference_file  = 't/test.template';
my $template_string = do {
    open my $fh, '<', $reference_file or BAIL_OUT "Can't read $reference_file";
    local $/;
    <$fh>;
};
my $tmp_fh = File::Temp->new( UNLINK => 0 );
my $template_file = $tmp_fh->filename;
print {$tmp_fh} $template_string;
close $tmp_fh;
my $template_args = { totoro => { fly => 2 } };
my $expected_string = "41 42 43\n";

is $e->process( $template_file, $template_args ), $expected_string,
  'template files are correctly computed';

is $e->process( \$template_string, $template_args ), $expected_string,
  'template strings are correctly computed';

{
    my $tmp_str = "1 2 3";
    is( exception { $e->process( \$tmp_str ) },
        undef, 'omiting args hashref (when the template uses no arg) lives' );
    is $e->process( \$tmp_str ), $tmp_str,
      'omiting args hashref (when the template uses no arg) works';
}

# Now we change the content of $template_file. The process() result must have
# changed alike, as we have disabled caching.

open $tmp_fh, '>', $template_file;
print {$tmp_fh} <<'EOF';
1 `[+ 2 +]´ 3
EOF
close $tmp_fh;

is $e->caching, 0, 'caching appears to be disabled when requested';
is $e->process( $template_file, $template_args ), "1 2 3\n",
  'caching is actually disabled when requested';

# Now try again with caching on (forever, since expires=0)

$e->caching(1);
is $e->caching, 1, 'caching appears to be enabled when requested';
is $e->expires, 0, 'expires is still set to 0';
is $e->process( $template_file, $template_args ), "1 2 3\n",
  'enabling caching does not change the result of process() yet ...';

# Now we change back the content of $template_file. The process() result must
# not have changed, since it is supposed to be cached forever.
open $tmp_fh, '>', $template_file;
print {$tmp_fh} $template_string;
close $tmp_fh;
is $e->process( $template_file, $template_args ), "1 2 3\n",
  'because of caching, process() result is outdated';

my $tmp_fh2 = File::Temp->new;
my $template_file2 = $tmp_fh2->filename;
print {$tmp_fh2} $template_string;
close $tmp_fh2;
is $e->process( $template_file2, $template_args ), $expected_string,
  'a fresh filename does not suffer from outdated Text::Template instances';

$tmp_fh->unlink_on_destroy(1);

1;
