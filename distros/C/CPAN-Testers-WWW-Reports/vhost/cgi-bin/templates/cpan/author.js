[% comma = 0 -%]
var results = {
[% FOREACH d = builder.distributions -%]
[% IF comma == 1 %],
[% END %][% comma = 1 -%]

"[% d.dist %]": [
[% inner = 0 -%]
[% FOREACH report = d.reports -%]
[% IF inner == 1 %],
[% END %][% inner = 1 -%]
  {status:"[% report.status | html %]",guid:"[% report.guid %]",id:"[% report.id %]",perl:"[% report.perl | html %]",osname:"[% report.osname | lower | html %]",ostext:"[% report.ostext | html %]",osvers:"[% report.osvers | html %]",archname:"[% report.archname || report.platform | trim | html %]",perlmat:"[% report.cssperl %]"}[% END -%]

][% END -%]

};

[% comma = 0 -%]
var distros = {
[% FOREACH d = builder.distributions -%]
[% IF comma == 1 %],
[% END %][% comma = 1 -%]
  "[% d.dist %]": [ {oncpan:"[% d.csscurrent %]", distmat:"[% d.cssrelease %]"} ][% END -%]

};

[% comma = 0 -%]
var versions = [
[% FOREACH d = builder.distributions -%]
[% IF comma == 1 %],
[% END %][% comma = 1 -%]
"[% d.dist %]"[% END -%]

];