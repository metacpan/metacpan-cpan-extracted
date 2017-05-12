# -*- perl -*-
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use ok 'Catalyst::Test', 'IntApp';

ok request('/')->is_success, '/ is callable.';
is get('/'), 'index works', '/ result is correct';

# calling a wrapped template
ok request('/simple_template')->is_success, '/simple_template is callable.';
like get('/simple_template'), qr{\s*<body>\s*<div\s+class="bad-class-name"\s+id="main">\s*Perl\s+rocks\s*</div>\s*</body>\s*}xms, '/simple_template result is correct';

# calling a wrapped template with extra args - this test group failed in 0.10
# after calling render() from inside process()
ok request('/simple_template/foo/bar')->is_success, '/simple_template/foo/bar is callable.';
like get('/simple_template/foo/bar'), qr{\s*<body>\s*<div\s+class="bad-class-name"\s+id="main">\s*Perl\s+rocks\s*</div>\s*</body>\s*}xms, '/simple_template/foo/bar result is correct';


done_testing();