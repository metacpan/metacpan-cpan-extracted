# Algorithm::Classifier::IsolationForest

Isolation Forest (Liu, Fei Tony & Ting, Kai & Zhou, Zhi-Hua, 2008) detects anomalies by
random partitioning rather than by modelling normal points. Each tree repeatedly splits
the data. Points that get isolated after only a few splits are likely anomalies. The score
is the average isolation depth across many trees, normalised so values approach 1 for
anomalies and stay below 0.5 for normal points.

In extended mode the module implements the Extended Isolation Forest variant. Each split
is a random hyperplane instead of an axis-aligned cut, which removes the rectangular,
axis-aligned bias in the score field and tends to help on elongated or multi-modal data.

```perl
use Algorithm::Classifier::IsolationForest;

my @data = ([0.1, -0.2], [0.0, 0.1], [5.0, 6.0], ...);

# Classic, axis-parallel Isolation Forest
my $iforest = Algorithm::Classifier::IsolationForest->new(
    n_trees     => 100,
    sample_size => 256,
    seed        => 42,
);
$iforest->fit(\@data);

my $scores = $iforest->score_samples(\@data);  # arrayref, each in (0,1]
my $flags  = $iforest->predict(\@data, 0.6);    # arrayref of 0/1

# Save and reload
$iforest->save('model.json');
my $reloaded = Algorithm::Classifier::IsolationForest->load('model.json');

# Extended Isolation Forest (oblique hyperplane splits)
my $eif = IsolationForest->new(mode => 'extended', seed => 42);
$eif->fit(\@data);
```

# Install

## Source

```shell
perl Makefile.PL
make
make test
make install
```

## FreeBSD

```shell
pkg install p5-App-Cmd p5-File-Slurp p5-App-cpanminus
cpanm Algorithm::Classifier::IsolationForest
```

## Debian

```shell
pkg apt-get install libapp-cmd-perl libfile-slurp-perl cpanminus
cpanm Algorithm::Classifier::IsolationForest
```
