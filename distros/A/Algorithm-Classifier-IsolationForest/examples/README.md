# Examples for Algorithm::Classifier::IsolationForest

Runnable scripts demonstrating the module. From the distribution root, run any
of them with the local `lib/` on the path:

```sh
perl -Ilib examples/basic-anomaly-detection.pl
```

If the module is already installed, drop the `-Ilib`:

```sh
perl examples/basic-anomaly-detection.pl
```

Each script seeds the RNG so its output is reproducible.

| Script                       | Shows                                                                                                                                                                                          |
|------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `basic-anomaly-detection.pl` | The core workflow: `fit` → `score_samples` → `predict` on a Gaussian blob with known ring outliers, reported as a precision/recall summary and a ranked top-10.                                |
| `axis-vs-extended.pl`        | `mode => 'axis'` vs `mode => 'extended'` on correlated (diagonal) data, illustrating how Extended Isolation Forest reduces the axis-aligned bias and better flags off-diagonal anomalies.      |
| `contamination-threshold.pl` | Letting `contamination` auto-learn a cutoff at `fit` time, reading it back with `decision_threshold`, and how `predict` uses it by default vs a naive fixed 0.5.                               |
| `save-and-load.pl`           | Persisting a trained model with `save`/`to_json` and restoring it with `load`/`from_json`, confirming a reloaded model scores bit-for-bit identically.                                         |
| `server-metrics.pl`          | An applied take: ranking server requests `[latency_ms, response_bytes]` by anomaly score, using `path_lengths` alongside `score_samples`, and writing the scored data to `request_scores.csv`. |
| `online-streaming.pl`        | Online Isolation Forest (`::Online`) on a drifting stream: prequential `score_learn`, and how the sliding window makes the old regime anomalous and the new one normal after a drift.          |


## Quick reference

```perl
use Algorithm::Classifier::IsolationForest;

my $if = Algorithm::Classifier::IsolationForest->new(
    n_trees       => 100,      # ensemble size
    sample_size   => 256,      # sub-sample per tree (psi)
    mode          => 'axis',   # or 'extended'
    contamination => undef,    # e.g. 0.05 to learn a threshold
    seed          => 42,       # for reproducibility
);

$if->fit(\@data);                       # @data = ([f1, f2, ...], ...)
my $scores = $if->score_samples(\@data); # arrayref, each in (0, 1]
my $labels = $if->predict(\@data);       # arrayref of 0/1
my $depths = $if->path_lengths(\@data);  # arrayref, mean isolation depth

$if->save('model.json');
my $reloaded = Algorithm::Classifier::IsolationForest->load('model.json');
```

Scores near 1 are strong anomalies (isolated after only a few splits); scores
well below 0.5 are normal; ~0.5 means the point is hard to tell apart.
