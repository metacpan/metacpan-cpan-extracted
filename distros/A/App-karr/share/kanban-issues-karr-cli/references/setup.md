# Setup: init, skill files, shell completion, Docker

## init

```bash
karr init [--name NAME] [--statuses s1,s2,s3] [--claude-skill] [--new-board]
```

Creates the board refs in the current Git repository (`--dir PATH` starts the
repository search elsewhere). `--claude-skill` installs this skill as
`.claude/skills/kanban-issues-karr-cli/` in the repository root.

Before writing, init asks the remote whether a board already exists there:
`git clone` does not fetch `refs/karr/*`, so a fresh clone looks like a
repository that never had one. A remote advertising `refs/karr/*` makes init
refuse and point at `karr sync`. No remote, an unreachable one, or no answer
inside the probe budget lets init through — it has to work offline.
`--new-board` starts an independent board beside the remote's on purpose; the
two will never sync with each other.

## skill

```bash
karr skill install                        # for the agent dirs found in the current directory (all three if none)
karr skill install --agent claude-code    # claude-code, codex, cursor (comma-separated)
karr skill install --global               # under $HOME instead
karr skill install --force                # overwrite an existing install
karr skill check                          # exit 1 when an install differs from the bundled files
karr skill update                         # refresh outdated installs in place
karr skill show                           # print the bundled SKILL.md
```

Installs `SKILL.md` and `references/*.md` under `.claude/skills/`,
`.agents/skills/` or `.cursor/skills/` (`--global`: `~/.claude/skills`,
`~/.codex/skills`, `~/.cursor/skills`). The target is the current directory —
`skill` takes no `--dir`; `cd` there. Files are written in place, so a
hardlinked skill shared across projects (manage-skills) stays linked.

## completion

```bash
karr completion bash                          # print a bash completion script
karr completion zsh > "${fpath[1]}/_karr"
karr completion fish | source
```

The script is static: it embeds command and option names and never calls
`karr` at completion time. Board-specific values (statuses, tags, ids) are not
completed.

## Docker

Perl is the primary installation path. For a repository that vendors karr
instead, an alias around `raudssus/karr:latest` (or `raudssus/karr:user`)
mounting the project at `/work` with `HOME=/home/karr` runs the same commands
and can drop privileges to the workspace owner without losing Git config or
agent skill directories.
