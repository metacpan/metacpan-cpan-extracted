A comics aggregator in the style of Gotblah.

This one runs privately and generates a static comics page.
No web servers required.

USAGE

Unpack the sources somewhere in a convenient place, for example
$HOME/Comics .

Create a spool directory to contain the generated data files.
For example, $HOME/Comics/spool .

Install a cron job to run the collect script every hour or so:

00 * * * *  perl $HOME/Comics/script/comics.pl --spooldir=$HOME/Comics/spool

If everything goes well, point your browser at
$HOME/Comics/spool/index.html .

Feel free to fork and improve, especially add more plugins!

Plugin Comics/Plugin/Sigmund.pm is fully documented and can be used as
a starting point to develop your own plugins.

NOTES ABOUT THE PLUGINS

Several plugins have version numbers 0.xx. They use an obsolete but
still functional version of the plugin API. They will be upgraded to
the current API when changes to the plugin are required.

Many plugins are for compatibility with the original Gotblah
collection of comics. Some plugins are created/suggested by other
users. The collection of distributed plugins therefore does not
reflect my personal taste of humour.

LICENSE

Copyright (C) 2016,2019 Johan Vromans,

This module is free software. You can redistribute it and/or modify it
under the same terms as Perl.
