---
name: crypt-age-core
description: "Load before editing Crypt::Age — the pure-Perl age implementation: header layout and the read/write split in what the MAC covers, X25519 stanzas, Bech32 keys, STREAM chunking, and the upstream test kit that stands in for a missing age binary."
---

# Crypt::Age — core

Pure-Perl implementation of the age file encryption format, byte-compatible with the Go
reference implementation (`filippo.io/age`) and Rust `rage`. Interop is the whole
product: every constant here exists because the spec says so, not because it was chosen.

**The specification is normative and short — read it rather than guessing:**
<https://github.com/C2SP/C2SP/blob/main/age.md> (`c2sp.org/age`). Where this skill and
the spec disagree, the spec wins and this file is the bug.

## Module map

| Module | Owns |
|---|---|
| `Crypt::Age` | public API — `generate_keypair`, `encrypt`/`decrypt`, `encrypt_file`/`decrypt_file`, `encrypt_filehandle`/`decrypt_filehandle`. Class methods, never instantiated |
| `Crypt::Age::Header` | the text header — `create`, `parse`, `parse_from_fh`, `to_string`, `verify_mac`, `unwrap_file_key`, and the `_bytes` attribute the MAC is taken over |
| `Crypt::Age::Stanza` | stanza base class — `to_string`, the 64-column body wrap, `encode_base64_no_padding` / `decode_base64_no_padding` |
| `Crypt::Age::Stanza::X25519` | `wrap` / `unwrap` for `-> X25519` stanzas (the only recipient type implemented) |
| `Crypt::Age::Keys` | Bech32 (BIP-173) encode/decode, `age` / `age-secret-key-` HRPs, `public_key_from_secret` |
| `Crypt::Age::Primitives` | X25519, ChaCha20-Poly1305, HKDF-SHA256, HMAC-SHA256, STREAM chunking, `_make_nonce` |

Everything is `Moo` + `namespace::clean`. `Crypt::Age` itself declares no attributes —
it is a `Moo` class used purely as a namespace for class methods. Don't "fix" that into
an instance API without a reason; callers depend on the class-method form.

## The file

```
age-encryption.org/v1\n          <- version line
-> X25519 <b64 ephemeral share>\n <- one stanza per recipient
<b64 wrapped file key>\n
--- <b64 mac>\n                   <- header ends here
<16-byte nonce><encrypted chunks> <- binary payload, no separator
```

## Wire constants — all specified, none chosen

| Thing | Value | Where |
|---|---|---|
| file key | **16 bytes** CSPRNG, never reused | `Primitives::generate_file_key` |
| X25519 wrap key | `HKDF-SHA256(ikm=shared_secret, salt=ephemeral_share‖recipient, info="age-encryption.org/v1/X25519")`, 32 bytes | `derive_wrap_key` |
| stanza body | `ChaCha20-Poly1305(wrap_key, file_key)` with a **12-byte all-zero nonce** → 32 bytes (16 ct + 16 tag) | `wrap_file_key` |
| header MAC key | `HKDF-SHA256(ikm=file_key, salt="", info="header")` | `compute_header_mac` |
| header MAC | HMAC-SHA256 over the header **up to and including `---`**, excluding the space after it and with **no trailing newline** | `Header::_bytes` |
| payload nonce | 16 bytes CSPRNG, sits immediately after the header's newline | `generate_payload_nonce` |
| payload key | `HKDF-SHA256(ikm=file_key, salt=nonce, info="payload")` | `derive_payload_key` |
| chunking | 64 KiB, ChaCha20-Poly1305, nonce = 11-byte big-endian counter ‖ `0x01` final / `0x00` otherwise | `encrypt_payload`, `_make_nonce` |
| base64 | RFC 4648 §4, **unpadded**, everywhere in the header | `Stanza` |

## The invariant that decides whether interop holds

**Read and write use different sources for the MAC input, and that asymmetry is
deliberate.** `parse_from_fh` captures the literal header bytes as it reads them and
stores them on the object as `_bytes`; `verify_mac` MACs *those*. `create` has no bytes
to capture, so the lazy builder `_build__bytes` re-serializes the stanzas through
`Stanza::to_string`.

That split fixed the old failure mode — a header written by `age`, valid per the spec
but formatted differently from ours, used to fail its own MAC here — but it does not
demote `Stanza::to_string` to formatting:

> Any change to how a stanza is serialized — argument spacing, the 64-column wrap, the
> base64 encoding, the order of stanzas — is still a **wire change** on the write side.
> It decides the bytes `age` has to accept and the MAC we compute over our own header.

So a "cosmetic" edit in `Stanza::to_string` is never cosmetic. Round-tripping
Perl→Perl keeps passing, because our writer and our reader change together. What
catches it is the real binary — or, on a machine without one, the test kit's
`success` vectors, which were written by the reference implementation.

## Known spec gaps — all closed, 2026-08-19

Every gap this section used to list is fixed and has a regression test. Do not
"discover" them again, and do not reintroduce one by reverting a check that looks
over-strict — each is dictated by `c2sp.org/age`:

| Was | Now | Commit |
|---|---|---|
| all-zero X25519 shared secret accepted | `x25519_shared_secret` croaks (low-order point check) | `eb143d9` |
| stanza body flush at 64 columns emitted no final line | `to_string` loops on `>= 64` | `4237e07` |
| base64 decoder repaired padding and non-canonical input | `decode_base64_no_padding` rejects both, plus bad alphabet and impossible length | `4237e07` |
| X25519 stanza arguments unvalidated | `Stanza::X25519::BUILD` checks arg count, 32-byte argument, 32-byte body — at parse time, so a malformed stanza is a header failure, not a soft "no match" | `fa48954` |
| empty payload decrypted to `""` | `decrypt_payload_fh` raises | PR #3 |
| `verify_mac` used `eq` | `Crypt::Misc::slow_eq` | `93fad42` |
| `_make_nonce` computed its nonce twice | dead line removed | `eb143d9` |
| stanza arguments accepted any non-whitespace byte | `[\x21-\x7e]` per `argument = 1*VCHAR` — checked before the type dispatch, so it applies to stanzas of unknown type too | `9ef9ce6` |
| STREAM finality decided by `eof()` | a chunk is final because it authenticates under the final-flag nonce; data after the final chunk is rejected | `bf0550e` |

The last two were found by the test kit on the day it was wired in, not by review —
which is the argument for running it.

Two things worth carrying forward:

- **A partial release is part of the contract.** `decrypt_payload_fh` streams, so
  plaintext already written stays in the output handle when it dies. Each released
  chunk is individually authentic; the *message* is not, and that is exactly what the
  error reports. Do not "fix" this by buffering — the test kit asserts on the partial
  release (`stream_no_final_full` expects 64 KiB out, then the error).
- **CryptX ≥ 0.067 refuses low-order peer keys inside `shared_secret()` itself.** Our
  own check is a backstop, and the reason `t/05-primitives.t` stubs the backend to
  reach it. The cpanfile pins that floor.

Still absent by design, not defects: scrypt / passphrase recipients, the ssh and
`mlkem768x25519` / tagged types, and ASCII armor.

The file and filehandle API **streams**: `encrypt_file` / `decrypt_file` open handles and
go through `_encrypt_fh` / `_decrypt_fh`, which chunk via `encrypt_payload_fh` /
`decrypt_payload_fh`; `encrypt_filehandle` / `decrypt_filehandle` expose the same path to
a caller's own handles. Only the string API `encrypt` / `decrypt` holds the whole message
in memory, which is what a string API means. Do not "add streaming" that is already here.

## Keys

Bech32 per BIP-173, **without** the 90-character length limit (the spec removes it).
HRP `age` for recipients (lowercase output), `age-secret-key-` for identities
(**uppercased** on output — `encode_secret_key` wraps the whole string in `uc`).
The checksum is always computed over the lowercase form, which is why `bech32_decode`
lowercases the HRP before verifying.

`bech32_decode` rejects a string that mixes cases (`Invalid bech32: mixed case`), per
BIP-173's "Decoders MUST NOT accept strings where some characters are uppercase and
some are lowercase" — checked first, before the separator. All-upper and all-lower both
decode, and to the same bytes.

The binaries differ on the case they accept for a *key type*, which is a separate
question from the mixed-case rule and deliberately not mirrored here: `age` 1.2.1
dispatches on the literal prefix, so it rejects an all-upper `AGE1...` recipient
("unknown recipient type") and an all-lower identity ("unknown identity type"); `rage`
0.12.1 accepts both. Both binaries reject mixed case outright.

This distribution follows `rage`, and it does so on **both** paths — say which path when
you make a claim here, because the two used to disagree and that is what hid the bug in
`Header::create`:

| Path | Dispatch | Decode |
|---|---|---|
| encrypt | `Header::create`, `/^age1/i` | `Keys::decode_public_key`, HRP compared with `lc` |
| decrypt | `Header::unwrap_file_key`, `/^AGE-SECRET-KEY-1/i` | `Keys::decode_secret_key`, HRP compared with `lc` |

So an all-upper `AGE1...` recipient encrypts and an all-lower `age-secret-key-1...`
identity decrypts, both the way `rage` takes them; a mixed-case string of either kind
passes the prefix test and then dies in `bech32_decode` with `Invalid bech32: mixed
case`. Until ticket #19 the recipient dispatch alone was case-sensitive, so
`decode_public_key(uc $pub)` returned the right bytes while `encrypt` died with
`Unsupported recipient format` — do not re-narrow either regex to "match the binary",
and note that `age`'s refusal is strictness beyond the spec, not our standard.

None of this reaches the wire. The recipient string is decoded to raw bytes in
`Stanza::X25519::wrap` and the stanza carries the *ephemeral* public key, so a file
encrypted to `AGE1...` is byte-identical to the same file encrypted to `age1...`, and
`age` 1.2.1 reads both — even though it would not have accepted `AGE1...` as its own
`-r` argument. Generated keys stay canonical: `encode_public_key` is lowercase,
`encode_secret_key` uppercase.

## Proof — a green suite is not one

```bash
prove -lr t/                    # everything; note -r, plain -l t/ is not recursive
prove -lv t/07-testkit.t        # the 143 upstream vectors — runs without a binary
prove -lv t/04-interop.t        # the real binary, when there is one
```

**Never assume whether a binary is present — check, with `which age rage`.** Machines
differ and this skill ships inside the tarball, so any claim here about what is installed
would be wrong somewhere. `t/04-interop.t` collects every CLI it finds — `age` and `rage`
— and runs the whole block once per CLI, prefixing each description with `[age]` /
`[rage]`; it `plan skip_all`s only when neither exists. Consequences:

- With no binary the file asserts **nothing**, and a green suite is not evidence for a
  format-touching change on its own.
- With both installed the count is **120** (60 per CLI); with one, 60. A run reporting 60
  covered a single implementation, and the `Using CLI:` diag lines at the top name which.
  No `PATH` surgery is needed to reach the Rust side any more.
- The two differ observably: given a 0-byte plaintext and `-o`, `age` writes a 0-byte
  file, `rage` writes no file at all. The chunk-boundary block handles both.

Say which of the three commands you ran, and against which binaries and versions.

`t/07-testkit.t` is what fills that hole: the C2SP/CCTV vectors, vendored under
`t/testkit/`, 68 of 143 runnable against this implementation and 75 skipped with a
printed per-reason tally (armor, scrypt, hybrid — none implemented). They were produced
by the reference implementation, so they prove the read side against real bytes. They
cannot prove the write side end to end: there is no reproducible way to inject our
randomness, so nothing here shows that `age` accepts what we emit. Only the binary does
that.

Never weaken an assertion to make a test pass, and never edit a vector or the runner's
expectations to get to green — a test kit you adjust proves nothing. Keys, identities
and plaintext never appear in errors, diagnostics, commit messages or ticket bodies.
