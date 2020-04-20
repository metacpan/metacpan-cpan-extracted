# NAME

tmclean - cleanup TimeMachine

# SYNOPSIS

    % tmclean [--dry-run] [--days=300/--before=2018/01/01]

## Options

- --dry-run
- --days

    Delete backups that before the specified number of days (default: 366)

- --before

    Delete backups before the specified date

# DESCRIPTION

tmclean is command line utility for cleanup TimeMachine.

# INSTALLATION

    % cpanm App::tmclean

## Homebrew

    % brew install Songmu/tap/tmclean

## Single Packed Executable

    % curl -L https://raw.githubusercontent.com/Songmu/App-tmclean/master/tmclean > /usr/local/bin/tmclean; chmod +x /usr/local/bin/tmclean

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
