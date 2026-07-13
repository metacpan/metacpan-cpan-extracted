# search_widget

```perl
my $html = $md->search_widget(%opts);
```

Registers the `__chandra_md_search` invoke handler and returns HTML for
embedding a search input in your layout.

## Options

| Option        | Default     | Description                              |
|---------------|-------------|------------------------------------------|
| `placeholder` | `Search...` | Input placeholder text                   |
| `limit`       | `10`        | Maximum results returned per query       |
| `min_length`  | `2`         | Minimum query chars before search fires  |

## Returned HTML

```html
<div class="chandra-search-wrap">
  <input type="search" id="chandra-md-search" placeholder="Search...">
</div>
<script>/* 300ms debounce → window.chandra.invoke */</script>
```

Place the returned string in your layout alongside the nav:

```perl
$app->layout(sub {
    my ($body) = @_;
    qq{<aside>$nav $search</aside>
       <main id="chandra-content">$body</main>};
});
```

## Behaviour

- Typing triggers a 300ms debounced call to `__chandra_md_search`.
- Queries shorter than `min_length` navigate back to `/`.
- Results are rendered into `#chandra-content` via `dispatch_eval`.
- Results are sorted by Dice score descending with a `%` badge each.

## Prerequisites

Call `render_dir` before `search_widget` — `render_dir` builds the
trigram index that `search_widget` queries.
