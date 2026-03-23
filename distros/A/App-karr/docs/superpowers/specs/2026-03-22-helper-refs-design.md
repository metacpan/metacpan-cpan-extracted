# karr Helper Refs Design

Date: 2026-03-22

## Goal

Add two new CLI commands, `set-refs` and `get-refs`, that let users store and
retrieve arbitrary helper payloads in Git refs without touching the protected
`refs/karr/*` board namespace or central Git namespaces such as branches and
tags.

## Scope

This feature is intentionally separate from the task board data model. It
exists as a general-purpose helper channel for agent workflows, for example to
store planning documents or transient coordination state in refs such as
`refs/superpowers/spec/1234.md`.

The same change set also:

- sharpens the Perl POD wording so it reads more like end-user CPAN
  documentation,
- keeps local Perl usage first while still documenting Docker as an equally
  valid execution mode,
- mentions AI/agent workflows more explicitly,
- adds `irc = #ai` to `dist.ini`.

## CLI Behaviour

### `karr set-refs <ref> <content...>`

- Accepts either a bare ref suffix such as `superpowers/spec/1234.md` or a full
  ref name such as `refs/superpowers/spec/1234.md`.
- Normalizes bare values to `refs/...`.
- Joins all remaining positional arguments into the stored payload separated by
  single spaces.
- Writes status information to `stderr`.
- Writes nothing to `stdout` on success.
- Pushes exactly the updated ref to the configured remote.

### `karr get-refs <ref>`

- Accepts the same normalized ref syntax as `set-refs`.
- Fetches exactly the requested ref from the remote before reading.
- Writes status information to `stderr`.
- Writes only the ref payload to `stdout`.

## Validation

Requested refs must pass both structural validation and namespace validation.

### Blocked namespaces

The following namespaces are denied:

- `refs/heads/`
- `refs/tags/`
- `refs/remotes/`
- `refs/bisect/`
- `refs/replace/`
- `refs/stash`
- `refs/karr/`

### Structural rules

The implementation rejects ref names with:

- empty path segments,
- leading or duplicate slashes,
- `..`,
- `@{`,
- control characters,
- spaces,
- Git-special characters such as `~ ^ : ? * [ \`,
- `.lock` suffixes,
- trailing dots.

Errors must distinguish between invalid ref syntax and blocked namespaces.

## Architecture

`App::karr::Git` remains the low-level Git boundary. The new feature extends it
with helper methods for:

- ref normalization,
- helper-ref validation,
- single-ref fetch,
- single-ref push.

The existing `write_ref` and `read_ref` methods remain the storage format
implementation and continue to wrap content in a blob/tree/commit structure.

Two new command modules, `App::karr::Cmd::SetRefs` and
`App::karr::Cmd::GetRefs`, provide the end-user interface.

## Documentation

- `App::karr` gets a short section describing helper refs and the AI/agent use
  case.
- The new command modules receive full POD.
- Existing command and main-module POD should mention Docker as a peer runtime
  option after the Perl-first examples.
- `README.md` already covers Docker prominently, so the Perl POD only needs a
  concise nod to it rather than duplicating the full README.

## Verification

- Add focused tests for ref normalization, validation, and blocked namespaces.
- Add an integration test that pushes and fetches a helper ref across two Git
  repositories.
- Extend the load test to include the new command modules.
- Run `prove -l t`.
- Run `podchecker` across the modified modules.
