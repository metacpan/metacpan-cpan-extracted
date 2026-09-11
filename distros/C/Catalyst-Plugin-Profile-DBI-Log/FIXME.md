# Security & Bug Review Findings

Reviewed: 2026-09-10
Fixed: 2026-09-10 (branch: `bug_fixes_after_ai_review`)

## Security Vulnerabilities

### 1. XSS via JavaScript string injection (High) -- FIXED

**`ControlProfiling.pm:113`** -- The raw `$query` was interpolated directly into a
JavaScript string in an `onclick` attribute without any escaping.

**Fix:** Escape `\`, `"`, and newlines before interpolation; use double quotes
in the JS string with HTML entity encoding of the `"`.

### 2. XSS in `show` action -- query output (High) -- FIXED

**`ControlProfiling.pm:203`** -- Raw SQL query text was placed inside `<pre>`
without HTML encoding.

**Fix:** Wrap with `HTML::Entities::encode_entities()`.

### 3. XSS in `show` action -- clickable URL (High) -- FIXED

**`ControlProfiling.pm:163`** -- `$stats->{path_query}` was interpolated into both
the `href` attribute and link text with zero encoding.

**Fix:** HTML-encode before interpolation.

### 4. XSS in `index` action (Medium) -- FIXED

**`ControlProfiling.pm:80-88`** -- Multiple values from the JSON metadata were
interpolated into HTML without encoding.

**Fix:** HTML-encode all interpolated values.

### 5. XSS in `generate_stack_trace_html` (Medium) -- FIXED

**`ControlProfiling.pm:244-250`** -- `$frame->{file}` and `$frame->{sub}` were
interpolated into HTML without encoding.

**Fix:** HTML-encode all frame fields.

### 6. Path traversal in `show` action (Low-Medium) -- FIXED

**`ControlProfiling.pm:147-155`** -- The `$profile` parameter was used to construct
a file path with no validation.

**Fix:** Reject any profile name containing `..`, `/`, or `\`.

---

## Bugs

### 7. Race condition on shared global filehandle (Critical) -- NOT FIXED

**`Log.pm:80,90-100`** -- `$DBI::Log::opts{fh}` is a global. In a concurrent
server (e.g. prefork), requests can overwrite each other's filehandle.

**Note:** This is inherent to `DBI::Log`'s design and would require either
upstream changes to `DBI::Log` or a different approach (e.g. per-request
filehandle management outside of DBI::Log). Left for a future refactor.

### 8. Execution continues after failed file open (High) -- FIXED

**`Log.pm:65-66`** -- If `open` failed, the code continued with an invalid handle.

**Fix:** Use `do { ... return; }` to abort the hook and set a flag checked by
`finalize_body`.

### 9. File descriptor leak (Medium) -- FIXED

**`Log.pm:65-100`** -- The filehandle opened in `prepare_body` was never closed.

**Fix:** `close $DBI::Log::opts{fh}` in `finalize_body`.

### 10. `$dbilog_output_dir` duplicated and out of sync (Medium) -- FIXED

**`Log.pm:23` and `ControlProfiling.pm:20`** -- Both files declared their own
`$dbilog_output_dir` independently.

**Fix:** Replaced the controller's hardcoded variable with a `_dbilog_output_dir`
method that reads from the Catalyst app config, matching the plugin's logic.

### 11. `die` in controller action (Low) -- FIXED

**`ControlProfiling.pm:56`** -- `opendir` failure triggered `die`.

**Fix:** Return a 500 response with an error message.

---

## Code Quality

### 12. `DDP` imported but unused -- FIXED

**`Log.pm:12`** -- Removed `use DDP`.

### 13. External JS loaded without version pinning (Supply chain risk) -- FIXED

**`ControlProfiling.pm:168-169`** -- Pinned to jQuery 3.7.1 and sql-formatter
2.6.3.

### 14. Heredoc indentation broken -- NOT FIXED

**`ControlProfiling.pm:166`** -- Leading blank line in heredoc output. Cosmetic
issue, left for a future cleanup.

---

## Fix Order

1. ~~HTML-encode all interpolated values in the controller~~
2. ~~Fix the JS injection in `format_path` onclick~~
3. ~~Add `$profile` validation in `show` action~~
4. ~~Handle the failed `open` gracefully in `prepare_body`~~
5. ~~Close the filehandle in `finalize_body`~~
6. ~~Fix the duplicated `$dbilog_output_dir` variable~~
7. ~~Remove `use DDP`~~
8. ~~Pin or vendor the external JS dependencies~~
