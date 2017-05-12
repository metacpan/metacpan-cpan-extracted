use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::HT::Template;
use base 'Apache::SWIT::Maker::Skeleton::Template';

sub template_options { return { START_TAG => '<%', END_TAG => '%>' }; }

sub template { return <<'ENDS' };
<html>
<body>
[% form %]
First: [% first %] <br />
<input type="submit" />
</form>
</body>
</html>
ENDS

1;
