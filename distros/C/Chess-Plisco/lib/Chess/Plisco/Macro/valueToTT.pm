#! /bin/false

# Copyright (C) 2021-2026 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This is a macro that is not intended to run standalone.

## no critic (TestingAndDebugging::RequireUseStrict)

(do {
	(($v >= VALUE_TB_WIN_IN_MAX_PLY) ? $v + $p : ($v <= VALUE_TB_LOSS_IN_MAX_PLY) ? $v - $p : $v);
})
