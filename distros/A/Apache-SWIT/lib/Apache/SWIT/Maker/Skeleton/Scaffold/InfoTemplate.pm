use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Scaffold::InfoTemplate;
use base qw(Apache::SWIT::Maker::Skeleton::HT::Template
		Apache::SWIT::Maker::Skeleton::Scaffold);

sub template { return <<'ENDS'; }
<html>
<body>
[% form %]<% FOREACH fields_v %>
<% title %>: [% <% field %> %] <br /><% END %>
</form>
<a href="../form/r?<% table_v %>_id=[% <% table_v %>_id %]">
Edit <% table_class_v %></a>
<a href="../list/r">List <% table_class_v %></a>
</body>
</html>
ENDS

1;
