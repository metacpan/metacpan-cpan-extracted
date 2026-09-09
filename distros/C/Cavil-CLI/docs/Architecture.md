# Cavil CLI Architecture

This document explains what the Cavil CLI does and, more importantly, *why* it is built the way it is. It is
meant to be read start to finish by someone new to the project, before they open the source. It talks about
concepts, not functions or line numbers.

## Why this exists

Cavil reviews the licensing of software on a server, as part of a formal legal workflow: a package is
submitted, unpacked, scanned, its licenses and risk are determined, and it is either auto-accepted or signed
off by a reviewer. That workflow is thorough, and it is the authoritative answer to "is this safe to ship".

Until now that workflow was driven only by bots wiring Cavil to a build service or a git forge. A developer
working on a project, or a CI pipeline gating a merge, had no easy way in. The CLI is that way in: it takes the
project in front of you, submits it for the standard review, and brings back the verdict. It does not invent a
second, lesser kind of analysis; it reuses the real one, so what a developer sees locally is what the legal
workflow sees.

## What it does, and what it does not

`check` uploads the working tree, waits for Cavil to review it, and reports the licensing risk, turning it into
a pass or fail for CI. It is the whole product; `whoami` and `config` only exist to make it usable.

It does not do its own license detection, and it does not clear or sign off anything. Acceptability is a
decision the review workflow owns; the CLI reports the risk the review found and gates on it, and leaves the
human judgement where it belongs.

Two things are deliberately out of scope for now. There is no lighter, backlog-free "just tell me about this
throwaway code" path yet; a submission today is a real review that enters the real queue, which is why it is
gated to high access (below). A separate sandbox namespace for ordinary users is planned for that, and the
client is shaped so it can grow one without changing how `check` looks.

## The commands

The work is one command. You run the check, you read the report, and in CI you look at the exit code. Keeping
it to a single command with a built-in gate is a deliberate reaction to the friction of provenance pipelines
where a scan produces a raw file that further tools must render and police before it means anything.

Two small helpers stand beside it. `whoami` asks the server who the token belongs to and times the round trip,
so a user can confirm the URL and token work and the instance is reachable before running a real check, and CI
can use it as a preflight. `config` saves the server URL and API token so they need not be passed every run;
the token is read from a hidden prompt (or piped in), never taken as a command-line flag where it would linger
in shell history and process listings, and it is stored under `~/.config/cavil-cli`. Credentials are resolved
from the environment (for CI) or that saved config, always as a pair from one source, never mixed: taking the
URL from one place and the token from another is how a token saved for one instance ends up sent to another.

## How a check works

A check is four steps: package the tree, upload it, wait for the review, and print the verdict.

### Packaging the working tree

The archive is the working tree *as it sits on disk*. This is the central design decision, and it is not the
obvious one. A first instinct is to honour `.gitignore`, but a full legal review must see the vendored
dependencies a project actually ships or builds against - the `node_modules`, `vendor` and bundled trees that
`.gitignore` almost always hides. A CI job that runs `npm install` and then `check` is exactly the case that
matters, and dropping the installed packages would review the one part nobody wrote and skip everything the
project pulled in. So the default is: include everything, dropping only `.git` and whatever the project lists
in a `.cavilignore` file or passes with `--exclude-path`. `--respect-gitignore` is offered for the leaner case,
and because a `.gitignore` says nothing tar can be trusted to interpret, that mode honours it through git
itself rather than approximating it.

The archive is a gzip tarball built by shelling out to `tar`, chosen over an in-process library because a
vendored tree can be hundreds of megabytes and should stream to disk rather than sit in memory. Its MD5 is
computed as it is written and sent with the upload, so a truncated transfer is rejected rather than reviewed as
incomplete sources.

Before uploading, the client checks the archive against the server's upload limit (the Cavil default, or
`CAVIL_MAX_UPLOAD_MB` for an instance configured to accept more) and refuses with guidance if it is over, so an
accidental large file fails fast rather than after a slow doomed upload. The server enforces the same limit, so
a client whose limit is set too high still gets a clear rejection rather than a raw error.

### Uploading and waiting

The archive is posted to Cavil, which starts the same unpack, index and analyze pipeline any other package
goes through. Submitting the same archive under the same name again is idempotent on the server, so a re-run of
an unchanged tree does not pile up duplicate reviews.

The review is not instant, so the client polls the report endpoint, which answers "not ready" until the
analysis finishes and then returns the report. Its "not ready" reply names the pipeline stage (queued,
unpacking, indexing, analyzing, finalizing), which the client shows on the progress line so the wait names what
is happening rather than sitting on a bare "Reviewing". The line is on standard error so it never pollutes the
report or a pipe, and only on a real terminal so CI logs stay clean. A timeout bounds the wait.

### The verdict

The report carries the maximum license risk Cavil found, on its one-to-nine scale, and the instance's own
acceptable-risk threshold. The client turns those into a headline, a short tally, the licenses found ordered by
risk, and a link to the full web report, in colour on a terminal and plain text otherwise. For CI there is a
flat JSON form with the same facts.

## The gate

In CI the report is a gate: the check fails when the risk is at or above a threshold, and passes otherwise.
The threshold defaults to the instance's own `acceptable_risk` plus one, so "would Cavil consider this
acceptable" and "does the CLI pass" line up by default and no project needs to configure a number to match its
Cavil. `--fail-on-risk` overrides it for a project with a stricter or looser bar.

Gating on risk rather than on the presence of any license is the point: every project has licenses, and most
are fine. Cavil's scale captures more than copyleft (obligations, non-commercial and unknown all have their
place on it), so a single threshold expresses a real policy. The exit code is conventional: zero when within
the threshold, one when the gate fails, two for a usage or configuration problem, and three for a server or
connection error, so any non-zero code is the simple signal CI acts on while the risk itself is in the report.

## Access, and why it is high for now

Submitting a package runs the full pipeline and puts a review in the legal backlog, so it is gated exactly like
Cavil's own web upload form: it needs a read-write API key whose user has admin (`infra`) access. That is a
high bar on purpose for a first version - it keeps random submissions out of the production queue while the
workflow is proven. The planned sandbox namespace is what will open ad-hoc checks to ordinary users without
that cost; until it exists, `check` is for admins and for CI configured with an appropriately privileged key.
The client preflights with `whoami` so a key that cannot submit is reported clearly before a large tree is
packaged, rather than as an opaque rejection afterwards.

## The service contract

The CLI depends on a small, stable contract with the Cavil server, deliberately narrow so it can be reasoned
about and mocked. An identity endpoint backs `whoami`. An upload endpoint takes the archive and its checksum
and starts a review, returning the new package's id. A report endpoint returns the report for that id, or "not
ready" while it builds, with the risk and acceptable-risk fields the gate needs. A documents endpoint serves
the generated SPDX SBOM and NOTICE files, likewise "not ready" until generated. That is all; the CLI needs no
knowledge of Cavil's internals beyond these questions and their answers.

The upload also carries an `ephemeral` flag, asking for a one-off report with no lasting side effects, no open
review left in the legal backlog. That is what a developer or CI check always wants, so it is always sent. It
is the forward edge of the planned sandbox mode: today's servers do not act on it (which is why submission is
still gated to high access), but a server that gains the ad-hoc mode can honour it without any client change,
and the access gate can then relax for ephemeral requests.

## Testing

The CLI is tested against a mock of the Cavil server, not a real one. Each scenario stands up a small
in-process web service that answers those endpoints with canned data and records what the CLI asked it. The
requests go through the real HTTP machinery, so the tests exercise the true wire behaviour, but there is no
database, no network, and no port to bind. A field problem becomes a test with almost no translation: the
responses that triggered it become the mock's answers, and the requests that led to it become the assertions.

The parts that never talk to the server - the archive builder, the report renderer, the risk gate and the exit
codes - are plain functions of their inputs and tested directly, with small throwaway directories and git
repositories as fixtures.

## Design choices and their reasons

A few decisions are worth stating on their own, because they are the ones a reader is most likely to question.

- **Reuse the real review, do not reinvent it.** The value is that the local answer is the authoritative one.
  A separate client-side approximation would drift from what the legal workflow decides, which is the one thing
  it must not do.
- **Include vendored code by default.** Honouring `.gitignore` would be the tidy choice and the wrong one: the
  installed dependencies are most of what a legal review is for. The default optimises for a correct review,
  and `--respect-gitignore` is there for the rare case that wants the lean tree.
- **Gate on risk, defaulted to the instance.** A copyleft yes-or-no is too coarse, and a hardcoded number would
  fight each instance's own policy. Defaulting the threshold to the instance's acceptable risk makes the common
  case need no configuration at all.
- **High access first, sandbox later.** Rather than invent a weaker analysis to make submission safe for
  everyone, the first version reuses the real pipeline behind the real access gate, and leaves room for a
  backlog-free sandbox to open it up properly.
