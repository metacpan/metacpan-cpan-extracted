use strict;
use FindBin;
use Test::More;
use App::mookview;

my $app = App::mookview->new("$FindBin::Bin/../README.md");
isa_ok $app, 'App::mookview';

my $path = $app->local_or_share_path([qw/share/]);
ok $path;

my $not_found_response = $app->return_404();
ok $not_found_response;

my $css_response = $app->return_css('/css/screen.css');
ok $css_response;

my $code_block = $app->filter_markdown(<<'EOF');
```
my $foo = Foo->new();
$foo->bar();
```
EOF
is $code_block, <<'EOF'
    my $foo = Foo->new();
    $foo->bar();

EOF
;

my $markdown_response = $app->return_markdown();
ok $markdown_response;

done_testing;
