# App-Ordo

**Official Command Line Interface for Ordo — Hierarchical Job Scheduler**

A terminal client for managing jobs, clusters, calendars, and servers in Ordo.

## Purpose

Ordo is a modern job scheduler designed for complex, hierarchical workloads (DAGs of jobs and clusters, Quartz-style calendars, real-time monitoring, multi-server execution).

The `ordo` CLI gives you full control from the terminal — with both one-shot commands and a rich interactive shell.

## Features

- Interactive shell with command history
- Hierarchical navigation (`ls`, `cd`)
- Full CRUD for jobs, clusters, calendars, and worker servers
- Real-time status, logs, and zombie detection (`sync`)
- Beautiful colored tables and output
- Built-in pager for long results
- Scriptable for automation

## Installation

### From CPAN (recommended)

```
cpanm App::Ordo
```

### From Git

```
git clone https://github.com/nathanielgraham/App-Ordo.git
cd App-Ordo
perl Makefile.PL
make install
```

## Quick Start

1. Run the CLI:

```
ordo
```

2. On first run it will prompt for your API token (get it from the Ordo web UI).

3. Common commands:

```
ls                     # list current path
job create ...         # create a new job
cluster run mycluster  # run a cluster
sync                   # resync servers & identify zombies
help                   # full command list
```

## Configuration

Config file: `~/.config/App-ordo/ordo_config.json`

```
{
  "api": "https://api.ordoscheduler.com",
  "token": "your-token-here"
}
```

## Advanced Tools

For low-level WebSocket debugging and scripting, see `wsshell.pl` in the GitHub repository.

## Links

- Project: [ordoscheduler.com](https://ordoscheduler.com) (coming soon)
- CPAN: https://metacpan.org/dist/App-Ordo

## License

Copyright © 2025 Nathaniel Graham.  
This software is free; you can redistribute and/or modify it under the same terms as Perl itself (Artistic License 2.0 or GPL).
