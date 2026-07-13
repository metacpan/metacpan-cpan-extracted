# Search

Chandra::Markdown includes full-text search powered by `Search::Trigram` — a
trigram inverted index with Dice coefficient scoring.

## Adding search to your app

```perl
my $nav    = $md->render_dir('docs', base_route => '/docs', recursive => 1);
my $search = $md->search_widget(placeholder => 'Search docs...');

$app->layout(sub {
    my ($body) = @_;
    return qq{
        <aside>$nav $search</aside>
        <main id="chandra-content">$body</main>
    };
});
```

`render_dir` builds the index as a side effect of scanning files.
`search_widget` registers the `__chandra_md_search` invoke handler and
returns the `<input>` HTML with its debounce script.

## How results are scored

Each result has a **score** between 0 and 1 — the Dice coefficient between
the query trigrams and the document trigrams. Results are sorted
highest-score-first and displayed with a percentage badge.

## Options

| Option        | Default       | Description                        |
|---------------|---------------|------------------------------------|
| `placeholder` | `Search...`   | Input placeholder text             |
| `limit`       | `10`          | Maximum results to return          |
| `min_length`  | `2`           | Minimum query length before search |
