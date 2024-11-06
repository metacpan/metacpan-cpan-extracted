
# CheerLights::API

**CheerLights::API** is a Perl module that provides an interface to the [CheerLights](https://cheerlights.com) API. It allows you to retrieve the current color, color history, and other useful functions related to CheerLights, a project that synchronizes connected lights globally based on social media interactions.

🌍 🎨 💡

## Features

- **Get the current CheerLights color** with its name and hex code.
- **Retrieve the history** of recent colors.
- **Convert color names to hex codes**.
- **Convert hex codes to RGB tuples**.
- **Check if a color name is valid** in the CheerLights context.

```
     .-=-.      .-=-.      .-=-.
   _(     )__ _(     )__ _(     )__
  (_________)(_________)(_________)
     |   |      |   |      |   |
     |   |      |   |      |   |
-----'   '------'   '------'   '-----
```

## Installation

1. Copy the `CheerLights/API.pm` file to your desired module directory (`lib/`).
2. Use the module in your Perl script by including `use CheerLights::API`.

## Usage

### Import the Module

```perl
use CheerLights::API qw(get_current_color get_current_hex get_color_history color_name_to_hex hex_to_rgb is_valid_color);
```

### Examples

**Get the Current Color**
```perl
my $current_color = get_current_color();
print "Current color: $current_color->{color}, Hex: $current_color->{hex}\n";
```

**Get the Current Hex Code**
```perl
my $hex = get_current_hex();
print "Current hex color: $hex\n";
```

**Get the Color History**
```perl
my $history = get_color_history(5);
foreach my $entry (@$history) {
    print "Color: $entry->{color}, Hex: $entry->{hex}, Timestamp: $entry->{timestamp}\n";
}
```

**Convert a Color Name to Hex**
```perl
my $hex_code = color_name_to_hex('red');
print "Hex code for red: $hex_code\n";
```

**Convert a Hex Code to RGB**
```perl
my @rgb = hex_to_rgb('#FF0000');
print "RGB values for #FF0000: @rgb\n";
```

**Check if a Color Name is Valid**
```perl
my $is_valid = is_valid_color('blue');
print "Is 'blue' a valid color? ", $is_valid ? 'Yes' : 'No', "\n";
```

## Functions

### `get_current_color()`
Returns the current CheerLights color as a hash reference with `color` and `hex` keys.

### `get_current_hex()`
Returns the current hex code of the CheerLights color.

### `get_current_color_name()`
Returns the current color name of the CheerLights.

### `get_color_history($count)`
Takes an integer `$count` (default is 10) and returns an array reference of the most recent color data, each containing `color`, `hex`, and `timestamp`.

### `color_name_to_hex($color_name)`
Converts a given color name to its corresponding hex code.

### `hex_to_rgb($hex_code)`
Converts a hex code to an RGB tuple.

### `is_valid_color($color_name)`
Checks if a color name is valid according to CheerLights' list.

## Requirements

- **Perl 5.10+**
- **Modules**:
  - `LWP::UserAgent`
  - `JSON`

Install required modules using CPAN:

```bash
cpan LWP::UserAgent JSON
```