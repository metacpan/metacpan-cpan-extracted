"App::Prove::Plugin::Metrics" Version 0.0.3

Abstract:
---------
This package provides a mechanism to emit pass-rate metrics from Perl unit tests executed with the `prove` testing tool.

What's new in version 0.0.3:
----------------------------
* "No tests run for subtest" emit as failures
* Subtest names also bubble up as labels by default
* Unlabeled assertions are handled properly

Copyright & License:
--------------------
This package is Copyright (c) 2025--2035 by MediaAlpha.  All rights reserved.

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
https://github.com/MediaAlpha/perl-app-prove-plugin-metrics
