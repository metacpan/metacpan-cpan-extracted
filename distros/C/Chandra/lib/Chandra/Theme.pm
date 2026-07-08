package Chandra::Theme;

use strict;
use warnings;

our $VERSION = '0.28';

use Chandra;

# ── Built-in themes ───────────────────────────────────────

my %THEMES = (
    light => {
        primary    => '#2196F3',
        secondary  => '#4CAF50',
        danger     => '#f44336',
        warning    => '#ff9800',
        info       => '#2196F3',
        success    => '#4CAF50',
        bg         => '#ffffff',
        surface    => '#f5f5f5',
        text       => '#212121',
        text_muted => '#757575',
        border     => '#e0e0e0',
        input_bg   => '#ffffff',
        input_border => '#bdbdbd',
        hover      => '#f5f5f5',
        selected   => '#e3f2fd',
        shadow     => '0 2px 4px rgba(0,0,0,0.1)',
        font       => 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        font_mono  => 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace',
        radius     => '6px',
        font_size  => '14px',
        line_height => '1.5',
    },
    dark => {
        primary    => '#64B5F6',
        secondary  => '#81C784',
        danger     => '#ef5350',
        warning    => '#FFB74D',
        info       => '#64B5F6',
        success    => '#81C784',
        bg         => '#14181b',
        surface    => '#1e2225',
        text       => '#e0e0e0',
        text_muted => '#9e9e9e',
        border     => '#333333',
        input_bg   => '#282c2f',
        input_border => '#0a0e11',
        hover      => '#2c2c2c',
        selected   => '#3c4043',
        shadow     => '0 2px 4px rgba(0,0,0,0.3)',
        font       => 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        font_mono  => 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace',
        radius     => '6px',
        font_size  => '14px',
        line_height => '1.5',
    },
);

# ── Public API ────────────────────────────────────────────

sub apply {
    my ($class, $app, $theme) = @_;
    my $css;

    if ($theme eq 'auto') {
        my $light_vars = $class->_vars_css($THEMES{light});
        my $dark_vars  = $class->_vars_css($THEMES{dark});
        $css = ":root { $light_vars }\n"
             . "\@media (prefers-color-scheme: dark) { :root { $dark_vars } }\n"
             . $class->_base_css
             . $class->_component_css;
    } elsif (ref $theme eq 'HASH') {
        # Custom theme: merge with light as base
        my %merged = (%{$THEMES{light}}, %$theme);
        my $vars = $class->_vars_css(\%merged);
        $css = ":root { $vars }\n"
             . $class->_base_css
             . $class->_component_css;
    } elsif ($THEMES{$theme}) {
        my $vars = $class->_vars_css($THEMES{$theme});
        $css = ":root { $vars }\n"
             . $class->_base_css
             . $class->_component_css;
    } else {
        warn "Chandra::Theme: unknown theme '$theme', using light\n";
        return $class->apply($app, 'light');
    }

    $app->css($css);
    return $app;
}

sub themes { return keys %THEMES }

sub get {
    my ($class, $name) = @_;
    return $THEMES{$name} ? { %{$THEMES{$name}} } : undef;
}

# ── Internals ─────────────────────────────────────────────

sub _vars_css {
    my ($class, $tokens) = @_;
    my @vars;
    for my $key (sort keys %$tokens) {
        my $var = $key;
        $var =~ s/_/-/g;
        push @vars, "--chandra-$var: $tokens->{$key}";
    }
    return join('; ', @vars) . ';';
}

sub _base_css {
    return <<'CSS';

*, *::before, *::after { box-sizing: border-box; }

html {
    font-size: var(--chandra-font-size);
    line-height: var(--chandra-line-height);
}

body {
    margin: 0;
    padding: 0;
    font-family: var(--chandra-font);
    background: var(--chandra-bg);
    color: var(--chandra-text);
    -webkit-font-smoothing: antialiased;
}

a { color: var(--chandra-primary); text-decoration: none; }
a:hover { text-decoration: underline; }

code, pre, kbd {
    font-family: var(--chandra-font-mono);
    font-size: 0.9em;
}

pre {
    background: var(--chandra-surface);
    border: 1px solid var(--chandra-border);
    border-radius: var(--chandra-radius);
    padding: 12px 16px;
    overflow-x: auto;
}

code {
    background: var(--chandra-surface);
    padding: 2px 6px;
    border-radius: 3px;
}

pre code { background: none; padding: 0; }

hr {
    border: none;
    border-top: 1px solid var(--chandra-border);
    margin: 16px 0;
}

h1, h2, h3, h4, h5, h6 {
    margin: 24px 0 8px;
    line-height: 1.25;
}

h1 { font-size: 2em; }
h2 { font-size: 1.5em; }
h3 { font-size: 1.25em; }

CSS
}

sub _component_css {
    return <<'CSS';

/* ── Buttons ──────────────────────────────────────────── */

button, .chandra-btn {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 16px;
    border: 1px solid var(--chandra-border);
    border-radius: var(--chandra-radius);
    background: var(--chandra-surface);
    color: var(--chandra-text);
    font-family: inherit;
    font-size: inherit;
    cursor: pointer;
    transition: background 0.15s, border-color 0.15s;
}
button:hover, .chandra-btn:hover { background: var(--chandra-hover); }
button:disabled { opacity: 0.5; cursor: not-allowed; }

.chandra-btn-primary {
    background: var(--chandra-primary);
    color: #fff;
    border-color: var(--chandra-primary);
}
.chandra-btn-primary:hover { opacity: 0.9; }

.chandra-btn-danger {
    background: var(--chandra-danger);
    color: #fff;
    border-color: var(--chandra-danger);
}

.chandra-btn-secondary {
    background: transparent;
    border-color: var(--chandra-border);
}

/* ── Inputs ───────────────────────────────────────────── */

input[type="text"], input[type="email"], input[type="password"],
input[type="number"], input[type="search"], input[type="url"],
input[type="tel"], input[type="date"], input[type="time"],
textarea, select {
    padding: 6px 10px;
    border: 1px solid var(--chandra-input-border);
    border-radius: var(--chandra-radius);
    background: var(--chandra-input-bg);
    color: var(--chandra-text);
    font-family: inherit;
    font-size: inherit;
    transition: border-color 0.15s, box-shadow 0.15s;
}
input:focus, textarea:focus, select:focus {
    outline: none;
    border-color: var(--chandra-primary);
    box-shadow: 0 0 0 2px rgba(33, 150, 243, 0.2);
}

/* ── Form fields (Chandra::Form) ──────────────────────── */

.chandra-form { display: flex; flex-direction: column; gap: 12px; }
.chandra-field { display: flex; flex-direction: column; gap: 4px; }
.chandra-label { font-weight: 500; font-size: 0.9em; color: var(--chandra-text-muted); }
.chandra-submit {
    align-self: flex-start;
    padding: 8px 24px;
    background: var(--chandra-primary);
    color: #fff;
    border: none;
    border-radius: var(--chandra-radius);
    cursor: pointer;
    font-weight: 500;
}
.chandra-submit:hover { opacity: 0.9; }
.chandra-error { color: var(--chandra-danger); font-size: 0.85em; }
.chandra-group { border: 1px solid var(--chandra-border); border-radius: var(--chandra-radius); padding: 12px; }
.chandra-group legend { font-weight: 600; padding: 0 6px; }

/* ── Table (Chandra::Table) ───────────────────────────── */

.chandra-table-wrap { font-family: inherit; }
.chandra-table { width: 100%; border-collapse: collapse; }
.chandra-table th, .chandra-table td {
    padding: 8px 12px;
    text-align: left;
    border-bottom: 1px solid var(--chandra-border);
}
.chandra-table th {
    background: var(--chandra-surface);
    font-weight: 600;
    user-select: none;
}
.chandra-table-sortable { cursor: pointer; }
.chandra-table-sortable:hover { background: var(--chandra-hover); }
.chandra-table-stripe { background: var(--chandra-surface); }
.chandra-table-selected { background: var(--chandra-selected) !important; }
.chandra-table-select { width: 40px; text-align: center; }
.chandra-table-empty, .chandra-table-loading {
    text-align: center;
    padding: 24px;
    color: var(--chandra-text-muted);
}
.chandra-table-filters { padding: 8px 0; display: flex; gap: 8px; flex-wrap: wrap; }
.chandra-table-filter { font-size: 0.9em; }
.chandra-table-pagination {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    padding: 12px 0;
}
.chandra-table-page-btn {
    padding: 4px 10px;
    font-size: 0.85em;
}
.chandra-table-page-active {
    background: var(--chandra-primary) !important;
    color: #fff;
    border-color: var(--chandra-primary);
}
.chandra-table-info { margin-right: 12px; font-size: 0.85em; color: var(--chandra-text-muted); }

/* ── Context menu ─────────────────────────────────────── */

.chandra-context-menu {
    background: var(--chandra-bg);
    border: 1px solid var(--chandra-border);
    border-radius: var(--chandra-radius);
    box-shadow: var(--chandra-shadow);
    padding: 4px 0;
    min-width: 180px;
}
.chandra-context-menu-item {
    padding: 6px 16px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 8px;
}
.chandra-context-menu-item:hover { background: var(--chandra-hover); }

/* ── Scrollbar (webkit) ───────────────────────────────── */

::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb {
    background: var(--chandra-border);
    border-radius: 4px;
}
::-webkit-scrollbar-thumb:hover { background: var(--chandra-text-muted); }

CSS
}

1;

__END__

=head1 NAME

Chandra::Theme - CSS theme system for Chandra apps

=head1 SYNOPSIS

    use Chandra::App;
    use Chandra::Theme;

    my $app = Chandra::App->new(title => 'My App');

    # Built-in themes
    Chandra::Theme->apply($app, 'dark');
    Chandra::Theme->apply($app, 'light');

    # Auto-detect OS preference
    Chandra::Theme->apply($app, 'auto');

    # Custom theme (merged with light as base)
    Chandra::Theme->apply($app, {
        primary => '#6200ea',
        bg      => '#fafafa',
        surface => '#ffffff',
        radius  => '12px',
    });

    $app->run;

=head1 DESCRIPTION

C<Chandra::Theme> provides a CSS theme system using CSS custom properties.
It includes built-in light and dark themes, styles for all Chandra
components (Form, Table, ContextMenu), and base typography/reset styles.

=head1 CSS CUSTOM PROPERTIES

All tokens are available as C<--chandra-*> CSS variables:

    --chandra-primary, --chandra-secondary, --chandra-danger,
    --chandra-warning, --chandra-info, --chandra-success,
    --chandra-bg, --chandra-surface, --chandra-text,
    --chandra-text-muted, --chandra-border,
    --chandra-input-bg, --chandra-input-border,
    --chandra-hover, --chandra-selected, --chandra-shadow,
    --chandra-font, --chandra-font-mono,
    --chandra-radius, --chandra-font-size, --chandra-line-height

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Table>, L<Chandra::Form>

=cut
