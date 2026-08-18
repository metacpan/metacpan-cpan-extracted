# aitextwatermarkremover-tools

Local command-line utilities for scanning and removing invisible Unicode characters from text files.

Inspired by [aitextwatermarkremover.com](https://aitextwatermarkremover.com/), this is an **independent third-party helper** and is not an official SDK or affiliated with that website.

## Features

- **Scan** – Detect invisible Unicode characters (zero-width spaces, joiners, soft hyphens, etc.) and report their positions.
- **Clean** – Remove detected invisible characters while preserving all visible text.
- **Markdown tidy** – Strip common Markdown paste artifacts such as escaped brackets, redundant backslashes, and stray line breaks.

## Non-features

This tool does **not**:

- Make network requests. Everything runs locally.
- Rewrite or paraphrase text.
- Guarantee bypass of any AI detection system.

## Install

```bash
npm install -g aitextwatermarkremover-tools
```

## Usage

```bash
atwr scan file.txt
atwr clean file.txt -o cleaned.txt
atwr tidy file.md
```

Pass `--help` for full option listing.

## License

MIT
