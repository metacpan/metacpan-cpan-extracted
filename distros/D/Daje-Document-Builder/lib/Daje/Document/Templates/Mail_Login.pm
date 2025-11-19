package Daje::Document::Templates::Mail_Login;
use strict;
use warnings FATAL => 'all';

__DATA__
@@ login

[% title %]
===================


Languages
----------------
[% FOREACH name IN languages %]
* [% name %]
[% END %]


People
----------------
[% FOREACH person IN people %]
* [% person.name %] [% IF person.email %]mail: [% person.email %][% END -%]
[% END %]


__END__
1;