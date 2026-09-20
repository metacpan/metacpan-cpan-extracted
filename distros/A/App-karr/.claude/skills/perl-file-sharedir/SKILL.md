---
name: perl-file-sharedir
description: Use when packaging or reading non-code data files in a Perl distribution — File::ShareDir, the share/ layout, Dist::Zilla wiring, the development fallback.
user-invocable: true
---

# File::ShareDir — Distribution Share Files

Share files are non-code data files (templates, schemas, configs, word lists, skill definitions) shipped with a Perl distribution and accessible at runtime.

## Directory layout

```
my-dist/
  lib/
  share/           ← convention, configurable
    templates/
    schema.json
    kanban-issues-karr-cli/
  dist.ini
```

## Dist::Zilla setup

`[ShareDir]` is part of `@Basic`, which is included in `[@Author::GETTY]`. So **no extra config needed** — just put files in `share/` and they get packaged automatically.

To override the directory name (default is `share/`):

```ini
[ShareDir]
dir = data
```

## Runtime access

### After installation (production)

```perl
use File::ShareDir 'dist_dir';
use Path::Tiny;

my $share = path( dist_dir('My-Dist') );
my $template = $share->child('templates/main.html')->slurp_utf8;
```

Key functions:

| Function | Returns |
|----------|---------|
| `dist_dir('Dist-Name')` | Share directory path for a distribution |
| `dist_file('Dist-Name', 'file.txt')` | Full path to a specific file |
| `module_dir('Module::Name')` | Per-module share dir (rarely used) |
| `module_file('Module::Name', 'f.txt')` | Per-module file (rarely used) |

**Important:** Dist name uses hyphens (`App-karr`), not colons.

### Development fallback

`dist_dir()` only works after install. For development, fall back via `%INC`:

```perl
sub _find_share_dir {
  # Installed?
  eval {
    require File::ShareDir;
    my $dir = File::ShareDir::dist_dir('My-Dist');
    return path($dir) if path($dir)->is_dir;
  };

  # Development: navigate from module location to share/
  my $module_path = $INC{'My/Dist/Module.pm'};
  if ($module_path) {
    # parent() count = depth of module under lib/ + 1 for lib/ itself
    # e.g. lib/My/Dist/Module.pm → parent(4) = project root
    my $share = path($module_path)->parent(4)->child('share');
    return $share if $share->is_dir;
  }

  die "Could not find share directory. Is My-Dist properly installed?\n";
}
```

Parent count: count the path components in `lib/My/Dist/Module.pm` (that's 4).

### Alternative: File::ShareDir::ProjectDistDir

Zero-config development access (works without install):

```perl
use File::ShareDir::ProjectDistDir;
# Now dist_dir() works in development too
```

Trade-off: extra dependency, magic. The `%INC` fallback is more explicit.

## Testing share files

Use `Test::File::ShareDir` to set up share dirs in tests:

```perl
use Test::File::ShareDir -share => {
  -dist => { 'My-Dist' => 'share/' },
};
use File::ShareDir 'dist_dir';

# Now dist_dir('My-Dist') returns the local share/ path
my $dir = dist_dir('My-Dist');
```

## cpanfile dependency

```perl
requires 'File::ShareDir';

on test => sub {
    requires 'Test::File::ShareDir';  # if testing share access
};
```

## Common patterns

### Ship a config/template

```perl
sub default_config_path {
  return path(dist_dir('My-Dist'))->child('default-config.yml');
}
```

### Ship a Claude Code skill (like App::karr)

```
share/
  kanban-issues-karr-cli/
    SKILL.md
    references/*.md
```

```perl
# In init/install command: copy the directory, every file written in place --
# spew_utf8 renames a temp file over the target and would break a SKILL.md
# that is one link of a hardlink chain (manage-skills) out of that chain.
my $share = find_share_dir();  # with fallback
my $src   = $share->child('kanban-issues-karr-cli');
my $dst   = path('.claude/skills/kanban-issues-karr-cli');
$src->visit(sub {
  my ($p) = @_;
  return unless $p->is_file && $p->basename =~ /\.md\z/;
  my $target = $dst->child( $p->relative($src) );
  $target->parent->mkpath;
  $target->append_utf8( { truncate => 1 }, $p->slurp_utf8 );
}, { recurse => 1 });
```

### Ship JSON schemas (like OpenAPI-Modern)

```perl
my $share_dir = dist_dir('OpenAPI-Modern');
foreach my $file (path($share_dir)->children(qr/\.json$/)) {
  register_schema($file);
}
```

## Gotchas

1. **dist_dir() dies** if the dist isn't installed — always wrap in eval for dev fallback
2. **Dist name format:** `App-karr` not `App::karr` — hyphens, not colons
3. **[@Author::GETTY] includes `[ShareDir]` via `@Basic`** — no extra dist.ini config needed
4. **Files must exist at build time** — `dzil build` snapshots `share/` into the tarball
5. **No write access** — share dir may be in a system-owned path after install; never write to it
