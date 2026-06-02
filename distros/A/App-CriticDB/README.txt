"App::CriticDB" Version 0.0.5

Abstract:
---------
This package provides a mechanism to store and retrieve Perl::Critic violations for a collection of files.

What's new in recent versions:
------------------------------
* Storable uses tempfile+rename
* Proper violation formatting/reporting
* Support perlcritic's --verbose option
* Support --quiet mode for collection only

Copyright & License:
--------------------
This package is Copyright (c) 2025--2035 by MediaAlpha.com.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

Installation:
-------------
perl ./Build.PL
Build build
Build install
Build test

Author:
---------------
Brian Blackmore <brian@mediaalpha.com>
https://github.com/MediaAlpha/perl-app-criticdb
