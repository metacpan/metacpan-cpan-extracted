# Development Notes for App::optex::up

## Getopt::EX::Config Integration

### Processing Order in Getopt::EX::Module

When loading a module, Getopt::EX::Module processes in this order:

1. `use Module` - Perl code executes
2. `readrc` - `__DATA__` section is processed, macros and `$ENV{...}` are expanded
3. `initialize` is called
4. `finalize` is called

**Important**: Environment variables set in `initialize`/`finalize` will NOT be reflected in `__DATA__` macro expansion because it happens earlier.

### Solution: Use `$mod->setopt` in finalize

Instead of relying on `__DATA__` macros, use `$mod->setopt(default => ...)` in `finalize` to dynamically set the default option. This overrides any existing definition because `setopt` uses `unshift` and `getopt` uses `first`.

### Getopt::EX::Config Key Names

Option names with hyphens must match exactly:

```perl
my $config = Getopt::EX::Config->new(
    'pane-width' => 85,  # Use hyphen, not underscore
);

# Access with the same key
my $width = $config->{'pane-width'};
```

### Terminal Width Detection

Use `Term::ReadKey` with `/dev/tty` for reliable terminal width:

```perl
use Term::ReadKey;

sub term_width {
    my @size;
    if (open my $tty, ">", "/dev/tty") {
        @size = GetTerminalSize $tty, $tty;
    }
    $size[0];
}
```

### Short Options

`Getopt::EX::Config` 1.00+ no longer uses `-C` for `--config`, so modules can safely use `-C` for their own options.

## Testing

```bash
# Test with development version
perl -Ilib -S optex -Mdebug -Mup date

# Test with options
perl -Ilib -S optex -Mdebug -Mup -C2 -- date
perl -Ilib -S optex -Mdebug -Mup --pane-width=40 -- date
```

## Build and Release

This project uses `minil` for build and release.

### Before Committing

Always run `minil build` before committing to update `README.md`:

```bash
minil build
git add lib/App/optex/up.pm README.md
git commit -m "..."
```

### Release

```bash
minil release
```

## Dependencies

- Getopt::EX::Config >= 1.00
- Term::ReadKey
- App::ansicolumn
