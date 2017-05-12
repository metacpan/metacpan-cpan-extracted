use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;
use Catalyst::Test 'ESITest';

like get('/'),
qr{SubInclude test: will include /time_include using default plugin Catalyst::View::Component::SubInclude::Visit<br/>
Current time is: [\w\s:]+ --> \| foo = bar \|\s*
<br/>
Current time is: [\w\s:]+ --> Capture Arg: test\| baz = quux \|\s*
<br/>

<br/><br/>
Test subinclude using specific plugins:<br/>
Current time is: [\w\s:]+ --> \| plugin = SubRequest \|\s*
<br/>
Current time is: [\w\s:]+ --> \| plugin = Visit \|\s*
<br/>
<!--esi <esi:include src="/time\?plugin=ESI" /> --><br/>
<!--#include virtual="/time\?plugin=SSI" --><br/>

<br/><br/>


Test CaptureArgs and Args interaction \(SubRequest\):<br/><br/>

Current time is: [\w\s:]+ --> Capture Arg: capture_argtest \| query_arg = val \|  Action Arg: regular_arg\s*
<br/>
\(using: http://localhost/capture_argtest/time/regular_arg\?query_arg=val\)<br/>
<br/>

Current time is: [\w\s:]+ -->  \| query_arg = val \|  Action Arg: regular_arg\s*
<br/>
\(using: http://localhost/time/regular_arg\?query_arg=val\)<br/>

<br/><br/>

Test CaptureArgs and Args interaction \(Visit\):<br/><br/>

Current time is: [\w\s:]+ --> Capture Arg: capture_argtest \| query_arg = val \|  Action Arg: regular_arg\s*
<br/>
\(using: http://localhost/capture_argtest/time/regular_arg\?query_arg=val\)<br/>
<br/>

Current time is: [\w\s:]+ -->  \| query_arg = val \|  Action Arg: regular_arg\s*
<br/>
\(using: http://localhost/time/regular_arg\?query_arg=val\)<br/>

<br/><br/>

Test CaptureArgs and Args interaction \(ESI\):<br/><br/>

<!--esi <esi:include src="/capture_argtest/time/regular_arg\?query_arg=val" /> --><br/>
\(using: http://localhost/capture_argtest/time/regular_arg\?query_arg=val\)<br/>
<br/>

<!--esi <esi:include src="/time/regular_arg\?query_arg=val" /> --><br/>
\(using: http://localhost/time/regular_arg\?query_arg=val\)<br/>

<br/><br/>

Test CaptureArgs and Args interaction \(SSI\):<br/><br/>

<!--#include virtual="/capture_argtest/time/regular_arg\?query_arg=val" --><br/>
\(using: http://localhost/capture_argtest/time/regular_arg\?query_arg=val\)<br/>
<br/>

<!--#include virtual="/time/regular_arg\?query_arg=val" --><br/>
\(using: http://localhost/time/regular_arg\?query_arg=val\)<br/>

<br/><br/><br/>

Test Args when Chained is not being used:
Current time is: [\w\s:]+ -->  \| query_arg = val \|  No Chained Args: regular_arg1, regular_arg2
<br/>
\(using: http://localhost/time_args_no_chained/regular_arg1/regular_arg2\?query_arg=val\)<br/>
};

done_testing;
