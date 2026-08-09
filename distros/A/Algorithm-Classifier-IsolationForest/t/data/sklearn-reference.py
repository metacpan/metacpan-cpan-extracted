#!/usr/bin/env python3
"""Regenerate the *.sklearn reference score files in this directory.

Run from the distribution root:

    python3 t/data/sklearn-reference.py

Needs scikit-learn; nothing in the test suite does.  The reference files
are checked in so t/81-sklearn-real-data.t can compare against sklearn on
machines with no Python at all, and are only regenerated when a dataset
is added or the reference parameters below change.

The parameters are chosen to match the Perl side's defaults: 100 trees, a
256-point sub-sample per tree.  random_state pins sklearn's RNG so the
file is reproducible; it does NOT make the two implementations produce
identical scores, since they draw from different generators.  What the
test checks is that the two agree on the ORDERING of the points.
"""

import csv
import hashlib
import os
import sys

import sklearn
from sklearn.ensemble import IsolationForest

HERE = os.path.dirname(os.path.abspath(__file__))
SETS = ["glass", "ionosphere", "seeds", "wdbc"]

N_ESTIMATORS = 100
MAX_SAMPLES = 256
RANDOM_STATE = 42

for name in SETS:
    path = os.path.join(HERE, name + ".csv")
    with open(path, newline="") as fh:
        rows = list(csv.reader(fh))
    header, data = rows[0], [[float(c) for c in r] for r in rows[1:]]

    with open(path, "rb") as fh:
        csv_sha = hashlib.sha256(fh.read()).hexdigest()

    model = IsolationForest(
        n_estimators=N_ESTIMATORS,
        max_samples=MAX_SAMPLES,
        random_state=RANDOM_STATE,
        contamination="auto",
    ).fit(data)

    # score_samples is the NEGATED anomaly score: lower means more
    # anomalous.  Stored raw, exactly as sklearn returns it; the test
    # negates it to line the direction up with the Perl side.
    scores = model.score_samples(data)

    out = os.path.join(HERE, name + ".sklearn")
    with open(out, "w") as fh:
        fh.write("# sklearn IsolationForest.score_samples reference scores\n")
        fh.write("# lower = more anomalous (this is sklearn's sign convention)\n")
        fh.write("# dataset: %s.csv (sha256 %s)\n" % (name, csv_sha))
        fh.write("# rows: %d, features: %d\n" % (len(data), len(header)))
        fh.write("# sklearn %s, python %s\n" % (sklearn.__version__,
                                                sys.version.split()[0]))
        fh.write("# n_estimators=%d max_samples=%d random_state=%d "
                 "contamination=auto\n"
                 % (N_ESTIMATORS, MAX_SAMPLES, RANDOM_STATE))
        for s in scores:
            fh.write("%.17g\n" % s)

    print("%-12s %4d rows -> %s" % (name, len(data), os.path.basename(out)))
