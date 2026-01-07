#! /bin/false

# Copyright (C) 2021-2026 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::Constants;
$Chess::Plisco::Engine::Constants::VERSION = 'v1.0.2';
use strict;
use integer;

use base qw(Exporter);

use constant DEPTH_QUIESCENCE => 0;
use constant DEPTH_UNSEARCHED => -2;
use constant DEPTH_ENTRY_OFFSET => -3;

use constant BOUND_NONE => 0;
use constant BOUND_UPPER => 1;
use constant BOUND_LOWER => 2;
use constant BOUND_EXACT => 3;

# For debugging output.
use constant BOUND_TYPES => ['None', 'Upper', 'Lower', 'Exact'];

use constant MATE => 32000;
use constant INF => MATE + 1;
use constant NONE => INF + 1;
use constant MAX_PLY => 246;
use constant DRAW => 0;

use constant MATE_IN_MAX_PLY => MATE - MAX_PLY;
use constant MATED_IN_MAX_PLY => -MATE_IN_MAX_PLY;

use constant VALUE_TB => MATE_IN_MAX_PLY - 1;
use constant VALUE_TB_WIN_IN_MAX_PLY => VALUE_TB - MAX_PLY;
use constant VALUE_TB_LOSS_IN_MAX_PLY => -VALUE_TB_WIN_IN_MAX_PLY;

# Node types for search.
use constant ROOT_NODE => 0;
use constant PV_NODE => 1;
use constant NON_PV_NODE => 2;

# For debugging output.
use constant NODE_TYPES => ['Root', 'PV', 'NonPV'];

# Indices into TT probe results.
#
# Boolean flag for a hit.
use constant TT_ENTRY_OCCUPIED => 0;
# The depth of the entry.
use constant TT_ENTRY_DEPTH => 1;
# The best move.
use constant TT_ENTRY_MOVE => 2;
# Value and static evaluation.
use constant TT_ENTRY_VALUE => 3;
use constant TT_ENTRY_EVAL => 4;
# Bound type.
use constant TT_ENTRY_BOUND_TYPE => 5;
# Flag for PV nodes.
use constant TT_ENTRY_PV => 6;
# The index into the TT array.
use constant TT_CLUSTER_INDEX => 7;
# The index of the bucket inside the cluster.
use constant TT_BUCKET_INDEX => 8;
# The current bucket.
use constant TT_BUCKET => 9;

our @EXPORT = qw(
	DEPTH_QUIESCENCE DEPTH_UNSEARCHED DEPTH_ENTRY_OFFSET
	BOUND_NONE BOUND_UPPER BOUND_LOWER BOUND_EXACT
	MATE INF MAX_PLY DRAW
	ROOT_NODE PV_NODE NON_PV_NODE NODE_TYPES
	MATE_IN_MAX_PLY MATED_IN_MAX_PLY
	VALUE_TB VALUE_TB_WIN_IN_MAX_PLY VALUE_TB_LOSS_IN_MAX_PLY
);

1;
