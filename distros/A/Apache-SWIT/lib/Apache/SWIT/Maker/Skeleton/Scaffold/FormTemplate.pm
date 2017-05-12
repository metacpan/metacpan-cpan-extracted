use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Scaffold::FormTemplate;
use base qw(Apache::SWIT::Maker::Skeleton::HT::Template
		Apache::SWIT::Maker::Skeleton::Scaffold);

sub template { return <<'ENDS'; }
<html>
<body>
<h2>Add/Remove/Edit <% table_class_v %></h2>
[% form %]<% FOREACH fields_v %>
<% title %>: [% <% field %> %] <br /><% END %>
[% <% table_v %>_id %]
[% submit_button %]
[% delete_button %]
<br />
<a href="../list/r">List <% table_class_v %></a>
</form>
</body>
</html>
ENDS

1;
