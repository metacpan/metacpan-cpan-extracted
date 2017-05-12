use strict;
use warnings;
use utf8;
use BusyBird;

#### default "home" timeline.
timeline("home");

#### To create timeline, just call timeline("NAME") function.
## timeline("hoge");
## timeline("foobar");


#### Global config. This affects all timelines.
## busybird->set_config(time_zone => "UTC");

#### Per-Timeline config. This affects the individual timeline.
#### It overrides global config.
## timeline("hoge")->set_config(time_zone => "America/Chicago");

#### For complete list of config items, run 'perldoc BusyBird::Manual::Config'.

#### You must finish configuration with the 'end' function.
end;
