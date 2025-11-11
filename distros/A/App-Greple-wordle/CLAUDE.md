# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

App::Greple::wordle is a Perl module that implements a Wordle game as a greple module. It's a CPAN-distributed package that provides an interactive command-line Wordle implementation with regex-based correctness checking.

## Development Commands

### Setup and Dependencies
```bash
cpanm --installdeps .          # Install dependencies from cpanfile
```

### Building
```bash
perl Build.PL                  # Generate Build script
./Build                        # Build the distribution
```

### Testing
```bash
prove -lvr t                   # Run all tests (same as CI)
./Build test                   # Alternative test runner
minil test                     # Run full test suite (mirrors CI)
```

### Running Locally
```bash
greple -Ilib -Mwordle         # Run the game using local code
greple -Ilib -Mwordle --series=0 --index=0  # Test with specific answer
```

### Release Process
```bash
minil test                     # Verify all tests pass
# Update $VERSION in lib/App/Greple/wordle.pm
# Update Changes file
minil release                  # Tag and release
```

## Architecture

### Module Structure

The codebase follows a clear separation of concerns:

- **lib/App/Greple/wordle.pm**: Main entry point and CLI orchestration
  - Handles option parsing via Getopt::EX::Hashed
  - Dynamically loads dataset modules based on --data option
  - Manages interactive game loop and user input
  - Integrates with greple's pattern matching system
  - Implements command parsing (hint, uniq, filtering)

- **lib/App/Greple/wordle/game.pm**: Game state and logic
  - Tracks attempts and answer
  - Generates regex patterns for hints
  - Produces colored output (keymap, hints, result squares)
  - Uses Mo for minimal object system

- **lib/App/Greple/wordle/util.pm**: Shared utilities
  - Currently contains `uniqword()` for filtering unique-character words

- **lib/App/Greple/wordle/ORIGINAL.pm**: Original Wordle dataset
  - Exports `@WORDS` (all valid words) and `@HIDDEN` (answer list)
  - Contains classic Wordle word list from original game
  - Uses Data::Section::Simple for data storage

- **lib/App/Greple/wordle/NYT.pm**: New York Times Wordle dataset
  - Exports `@WORDS` (all valid words) and `@HIDDEN` (answer list)
  - Contains NYT Wordle word list (updated through November 2025)
  - Uses Data::Section::Simple for data storage

- **lib/App/Greple/wordle/word_all.pm**: Legacy word dictionary (deprecated)
  - Kept for backward compatibility
  - Exports `@word_all` array and `%word_all` hash

- **lib/App/Greple/wordle/word_hidden.pm**: Legacy answer list (deprecated)
  - Kept for backward compatibility
  - Shuffled using series number as seed

### Integration with greple

The module leverages greple's pattern matching engine:
- Game colors (green/yellow/black) map to regex patterns passed to greple
- `--interactive` mode hooks into greple's processing pipeline via `--begin`, `--end`, `--epilogue`
- Uses greple's colormap system for terminal output
- Pattern generation in `patterns()` creates position-aware regex

### Option Handling

Uses Getopt::EX::Hashed for declarative option definitions:
- Options defined with `has` macro including specs, defaults, actions
- `--data` option selects dataset (default: ORIGINAL)
- Custom action for `--compat` that sets series to 0
- Supports environment variables (`WORDLE_ANSWER`, `WORDLE_INDEX`)
- Negative index values are relative to current day
- Dataset modules are dynamically loaded via `eval "use $pkg"`

### Color and Display

Three distinct color systems:
1. **Game colors**: Green (correct position), Yellow (wrong position), Black (not in word)
2. **Keymap display**: Shows tried letters with their status
3. **Result squares**: Unicode emoji squares for sharing results

## Key Technical Details

### Answer Selection
- Default index calculated from days since 2021-06-19
- Dataset selected via `--data` option (ORIGINAL or NYT)
- Series 0 matches original Wordle answers
- Non-zero series shuffles answers using seed for reproducibility
- Out-of-range index triggers random selection with warning
- Supports manual answer via `--answer` or `WORDLE_ANSWER` env var

### Command System
Commands can be chained with spaces:
- `hint` / `h`: Filter to possible words based on attempts
- `uniq` / `u`: Filter to words with unique characters
- `=chars`: Include only words containing all chars
- `!chars`: Exclude words containing any chars
- `!!`: Recall last command result
- Any regex: Custom filtering

### Hint Generation Algorithm (game.pm:_hint)
1. Tracks confirmed positions (green) and excluded chars per position
2. Builds lookahead assertions for required chars
3. Creates negative lookahead for excluded chars
4. Combines into single regex pattern for word filtering

## Technical Requirements

- **Perl version**: v5.18.2 minimum (declared in cpanfile)
- **Build system**: Module::Build::Tiny (via minil)
- **Key dependencies**:
  - App::Greple 8.58+
  - Getopt::EX 2.1.6+
  - Getopt::EX::Hashed 1.05+
  - Mo (minimal object system)
  - Data::Section::Simple (for dataset storage)
  - Date::Calc, Text::VisualWidth::PP

## Testing Notes

- CI tests against Perl 5.18, 5.28, 5.30, 5.36, 5.38, 5.40
- Test file naming: `NN_description.t` pattern in `t/` directory
- Currently only has compilation test (`00_compile.t`)
- Use `use lib 'lib';` in new tests to access in-tree modules

## Updating NYT Wordle Data

### Data Sources

1. **NYT Official Answers** (chronological list): https://wordfinder.yourdictionary.com/wordle/answers/
   - Contains all official Wordle answers from June 19, 2021 (CIGAR) to present
   - Updated daily with the latest answer

2. **Valid Word List**: https://github.com/alex1770/wordle
   - `wordlist_all` - Complete set of allowable guesses (~14,855 words)
   - `wordlist_hidden` - Extended answer list (~3,158 words)

### Extracting Latest NYT Answers

```bash
# Download the WordFinder page
curl -s "https://wordfinder.yourdictionary.com/wordle/answers/" > /tmp/wordle_page.html

# Extract all answers using Perl
cat > /tmp/extract_answers.pl << 'EOF'
#!/usr/bin/env perl
use strict;
use warnings;

my $html = do { local $/; <STDIN> };

# Extract todayData answer
if ($html =~ /todayData:\{[^}]*answer:"([A-Z]+)\s*"/) {
    print lc($1), "\n";
}

# Extract all pastData answers
while ($html =~ /answer:"([A-Z]+)\s*"/g) {
    print lc($1), "\n";
}
EOF

chmod +x /tmp/extract_answers.pl
cat /tmp/wordle_page.html | perl /tmp/extract_answers.pl > /tmp/all_answers.txt

# Remove duplicates while preserving order (newest first)
cat /tmp/all_answers.txt | awk '!seen[$0]++' > /tmp/nyt_answers_unique.txt

# Reverse to get chronological order (oldest first: cigar → latest)
tail -r /tmp/nyt_answers_unique.txt > /tmp/nyt_answers_final.txt

# Verify: should start with "cigar" and end with today's answer
head -1 /tmp/nyt_answers_final.txt  # Should be "cigar"
tail -1 /tmp/nyt_answers_final.txt  # Should be today's answer
wc -l /tmp/nyt_answers_final.txt    # Should match current puzzle number
```

### Downloading Valid Word List

```bash
# Download the complete valid word list from alex1770/wordle
curl -s https://raw.githubusercontent.com/alex1770/wordle/main/wordlist_all > /tmp/wordlist_all.txt

# Verify
wc -l /tmp/wordlist_all.txt  # Should be ~14,855 words
```

### Updating Word List Files

The repository contains two sets of word lists:

- **word_nyt_hidden.pm**: NYT official answers (chronological, cigar → present)
- **word_nyt_all.pm**: All valid guessable words

Update these files with the extracted data:

```bash
# Update word_nyt_hidden.pm
cat > lib/App/Greple/wordle/word_nyt_hidden.pm << 'EOF'
package App::Greple::wordle::word_nyt_hidden;

use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(@word_nyt_hidden);

our   @word_nyt_hidden = <DATA>;
chomp @word_nyt_hidden;

1;

__DATA__
EOF
cat /tmp/nyt_answers_final.txt >> lib/App/Greple/wordle/word_nyt_hidden.pm

# Update word_nyt_all.pm
cat > lib/App/Greple/wordle/word_nyt_all.pm << 'EOF'
package App::Greple::wordle::word_nyt_all;

use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(@word_nyt_all %word_nyt_all);

our   @word_nyt_all = <DATA>;
chomp @word_nyt_all;
our   %word_nyt_all = map { $_ => 1 } @word_nyt_all;

1;

__DATA__
EOF
cat /tmp/wordlist_all.txt >> lib/App/Greple/wordle/word_nyt_all.pm
```

### Important Notes

- The NYT answer list is in **chronological order** (oldest first), matching the original word_hidden.pm format
- Today's puzzle number = days since June 19, 2021 (puzzle #0 = "cigar")
- WordFinder.com updates daily, so this process can be repeated to get the latest data
- The answer list contains fewer words than the valid word list because many valid guesses are never used as answers
