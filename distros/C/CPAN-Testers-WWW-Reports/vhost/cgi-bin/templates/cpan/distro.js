[% comma = 0 -%]
var results = {
[% FOREACH version = versions -%]
[% IF comma == 1 %],
[% END %][% comma = 1 -%]

"[% builder.distribution %]-[% version %]": [
[% inner = 0 -%]
[% FOREACH report = byversion.$version -%]
[% IF inner == 1 %],
[% END %][% inner = 1 -%]
  {status:"[% report.status | html %]",guid:"[% report.guid %]",id:"[% report.id %]",perl:"[% report.perl | html %]",osname:"[% report.osname | lower | html %]",ostext:"[% report.ostext | html %]",osvers:"[% report.osvers | html %]",archname:"[% report.archname || report.platform | trim | html %]",perlmat:"[% report.cssperl %]"}[% END -%]

][% END -%]

};

[% comma = 0 %]
var distros = {
[% FOREACH version = versions -%]
[% IF comma == 1 %],
[% END %][% comma = 1 -%]
  "[% builder.distribution %]-[% version %]": [ {oncpan:"[% release.$version.csscurrent %]", distmat:"[% release.$version.cssrelease %]", header:"[% release.$version.header %]"} ][% END -%]

};

[% comma = 0 %]
var versions = [
[% FOREACH version = versions -%]
[% IF comma == 1 %],
[% END %][% comma = 1 -%]
  "[% builder.distribution %]-[% version %]"[% END -%]

];


[% comma = 0 -%]
var stats = [
[% FOREACH p = builder.stats_perl -%]
[% IF comma == 1 %],
[% END %][% comma = 1 -%]
  {perl: "[% p %]", counts: [ [% inner = 0; FOREACH os IN builder.stats_oses; IF inner == 1 %], [% END; inner = 1 %]"[% builder.stats.$p.$os.version %]"[% END -%] ] }[% END -%]

];

