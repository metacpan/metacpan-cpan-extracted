" mcp-vim.vim - Vim client for the mcp-vim broker (protocol version 1.0).
"
" The broker exposes live Vim buffers to MCP clients and also supports
" browser-initiated editing sessions. Vim itself uses a private protocol
" to talk to the broker; it is not an MCP client.
" Its initial raw JSON line is ["mcp-vim", cookie, major, minor, target, instance_id].
" Subsequent messages use the normal Vim JSON channel envelope.
"
" Installation:
"   In the Perl source distribution: vim/plugin/mcp-vim.vim
"   Published URL: https://dist.schmorp.de/mcp-vim/1/mcp-vim.vim
"   Copy the file to ~/.vim/plugin/mcp-vim.vim to load it at startup,
"   or load it manually with :source /path/to/mcp-vim.vim.
"
" Usage:
"   :Mcp http://HOST:PORT/COOKIE/TARGET
"
" The broker supplies the connection URL, including its authentication
" cookie and the target name. To avoid typing the common prefix, set
" this in your vimrc:
"
"   let g:mcp_broker_url = 'http://HOST:PORT/COOKIE/'
"
" Then connect with :Mcp TARGET. Disconnected sessions are retried.
" McpHasTarget() reports whether a target URL has been configured.
"
" The /1/ in the distribution URL denotes the private Vim/broker
" protocol major version, not the MCP protocol version.
"
" Restart Vim after updating this file; re-sourcing does not reload it.

if exists ('g:loaded_mcp_vim')
  finish
endif
let g:loaded_mcp_vim = 1

let s:prot_major = 1
let s:prot_minor = 0

let s:instance_id = hostname () . ':' . getpid () . ':' . localtime ()
if has ('reltime')
  let s:instance_id .= ':' . reltimestr (reltime ())
endif

let s:channel     = v:null
let s:sessions    = {}
let s:popup       = 0
let s:url         = ''
let s:target      = ''
let s:retry_timer = -1
let s:incoming    = v:null

command! -nargs=1 Xpcse call s:connect (<f-args>)
command! -nargs=1 Mcp call s:connect (<f-args>)

function! McpHasTarget () abort
  return !empty (s:url)
endfunction

function! s:stop_retry () abort
  if s:retry_timer != -1
    call timer_stop (s:retry_timer)
    let s:retry_timer = -1
  endif
endfunction

function! s:retry (timer) abort
  if type (s:channel) != v:t_channel
    echom 'mcp-vim: reconnecting to ' . s:target
    call s:connect (s:url)
  endif
endfunction

function! s:quit () abort
  if type (s:channel) == v:t_channel
    if ch_status (s:channel) ==# 'open'
      call ch_sendexpr (s:channel, ['quit'])
    endif
    call ch_close (s:channel)
    let s:channel = v:null
  endif
endfunction

function! s:connect (url) abort
   let url = a:url

   if url !~# '^http://'
     let url = get (g:, 'mcp_broker_url', '') . url
   endif

  let s:url = url

  let m = matchlist (url, '^http://\([^:/]*\):\([0-9]\+\)/\([^/]\+\)/\(.*\)$')

  if empty (m)
    echoerr "Bad mcp-vim broker URL"
    return
  endif

  call s:quit ()

  let host   = m[1]
  let port   = m[2]
  let cookie = m[3]
  let id     = m[4]
  let s:target = id

  let s:channel = ch_open (host . ':' . port, {
    \ 'callback': function ('s:receive'),
    \ 'close_cb': function ('s:disconnected'),
    \ })

  if ch_status (s:channel) ==# 'open'
    call s:stop_retry ()

    call ch_sendraw (s:channel, json_encode (['mcp-vim', cookie, s:prot_major, s:prot_minor, id, s:instance_id]) . "\n")

    for session in values (s:sessions)
      call ch_sendexpr (s:channel, ['session', session.session, session.state])
    endfor

    call ch_sendexpr (s:channel, ['sessions-done'])
  else
    let s:channel = v:null
    echom 'mcp-vim: connection failed'
  endif
endfunction

function! s:disconnected (channel) abort
  echom 'mcp-vim: disconnected from ' . s:target
  let s:channel = v:null

  if s:retry_timer == -1
    let s:retry_timer = timer_start (1000, function ('s:retry'), { 'repeat': 60 })
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RPC support.
"
" broker -> vim: ['call',  id, method, args...]
" vim -> broker: ['reply', id, success, result]  " result is an exception string on failure
"
" Methods:
"   open (path)  " add/load a listed buffer without selecting it
"   state ()
"   read_lines (buffer, ranges)
"   grep (buffers, pattern, mode, max_results)
"   replace_lines (buffer, line, old_lines, new_lines, expected_changedtick)
"   apply_patch (buffer, patch, max_offsets, expected_changedtick)  " requires ordinary unified diff; MCP wrapper may relax @@ headers
"   substitute (buffer, range, pattern, replacement, flags, expected_changedtick)
"   undo (buffer, expected_changedtick)
"   redo (buffer, expected_changedtick)
"   update (buffer, expected_changedtick)  " save to current filename if modified
"   set_cursor (buffer, line, col [, expected_changedtick])
"   ex (command [, buffer, expected_changedtick])  " unrestricted; broker checks exec permission
"
" Explicit buffer ids are loaded on demand. In state, changedtick and line_count
" are v:null until a buffer has been loaded.

let s:rpc_sid = expand ('<SID>')

function! s:rpc_bufinfo (buf) abort
  let info = getbufinfo (a:buf)

  if empty (info)
    throw 'rpc/no_such_buffer: ' . a:buf
  endif

  if !info[0].loaded
    call bufload (a:buf)
    let info = getbufinfo (a:buf)

    if empty (info) || !info[0].loaded
      throw 'rpc/cannot_load_buffer: ' . a:buf
    endif
  endif

  return info[0]
endfunction

function! s:rpc_expect_tick (expected) abort
  if b:changedtick != a:expected
    throw printf ('rpc/stale_buffer: expected %d, got %d', a:expected, b:changedtick)
  endif
endfunction

function! s:rpc_break_undo () abort
  let &g:undolevels = &g:undolevels
endfunction

" Execute with {buf} current, while disturbing the user's window/buffer/cursor state as little as possible.
function! s:rpc_in_buffer (buf, fun, ...) abort
  let restoreview = !a:0 || a:1

  let info    = s:rpc_bufinfo (a:buf)
  let oldwin  = win_getid ()
  let oldbuf  = bufnr ('%')
  let oldview = winsaveview ()

  try
    if a:buf != oldbuf
      if !empty (info.windows)
        noautocmd call win_gotoid (info.windows[0])

        if win_getid () != info.windows[0]
          throw 'rpc/cannot_enter_window: ' . info.windows[0]
        endif
      else
        execute 'noautocmd keepalt keepjumps hide buffer ' . a:buf
      endif
    endif

    let targetwin  = win_getid ()
    let targetview = winsaveview ()

    try
      return call (a:fun, [])
    finally
      if restoreview
            \ && win_getid () == targetwin
            \ && bufnr ('%') == a:buf
        call winrestview (targetview)
      endif
    endtry
  finally
    noautocmd call win_gotoid (oldwin)

    if win_getid () != oldwin
      throw 'rpc/cannot_restore_window: ' . oldwin
    endif

    if bufnr ('%') != oldbuf
      execute 'noautocmd keepalt keepjumps hide buffer ' . oldbuf
    endif

    " Restore the caller's original view unless that is the buffer
    " we deliberately modified and want Vim's adjustment to survive.
    if restoreview || oldbuf != a:buf
      call winrestview (oldview)
    endif
  endtry
endfunction

" Validate a small Ex-range subset, then let Ex resolve it.
" A range-function gets the resolved addresses in a:firstline/a:lastline.
"
"   range   := % | address ([,;] address)?
"   address := base offset* | offset+
"   base    := . | $ | [1-9][0-9]* | /regexp/ | ?regexp?
"   offset  := [+-][0-9]*
"   regexp  := one or more non-delimiter characters; backslash escapes
"              the following character, including the delimiter
let s:rpc_range_result = v:null

function! s:rpc_capture_range () range abort
  let s:rpc_range_result = [a:firstline, a:lastline]
endfunction

function! s:rpc_validate_range (range) abort
  if a:range =~# '[\r\n]'
    throw 'rpc/bad_range: ' . a:range
  endif

  let fwd_char = '\%([^/\\]\|\\.\)'
  let bwd_char = '\%([^?\\]\|\\.\)'
  let fwd      = '/' . fwd_char . '\+/'
  let bwd      = '?' . bwd_char . '\+?'
  let base     = '\%([.$]\|[1-9][0-9]*\|' . fwd . '\|' . bwd . '\)'
  let offset   = '[+-][0-9]*'
  let address  = '\%(' . base . '\%(' . offset . '\)*\|\%(' . offset . '\)\+\)'
  let range    = '\%(%\|' . address . '\%([,;]' . address . '\)\?\)'

  if a:range !~# '^' . range . '$'
    throw 'rpc/bad_or_unsupported_range: ' . a:range
  endif
endfunction

function! s:rpc_range (range, line_count) abort
  call s:rpc_validate_range (a:range)

  let range = a:range
  let start = matchlist (range, '^\([1-9][0-9]*\)\([,;]\)')
  let end   = matchlist (range, '\([,;]\)\([1-9][0-9]*\)$')

  if !empty (start) && str2nr (start[1]) > a:line_count
    throw printf ('rpc/range_start_beyond_eof: %d > %d', str2nr (start[1]), a:line_count)
  endif

  if !empty (end) && str2nr (end[2]) > a:line_count
    let range = substitute (range, '\([,;]\)[1-9][0-9]*$', '\1' . a:line_count, '')
  elseif range =~# '^[1-9][0-9]*$' && str2nr (range) > a:line_count
    throw printf ('rpc/range_start_beyond_eof: %d > %d', str2nr (range), a:line_count)
  endif

  let pos = getpos ('.')
  let s:rpc_range_result = v:null

  try
    execute 'silent keepjumps keeppatterns ' . range . ' call ' . s:rpc_sid . 'rpc_capture_range ()'
  finally
    call setpos ('.', pos)
  endtry

  if type (s:rpc_range_result) != v:t_list
    throw 'rpc/bad_range: ' . a:range
  endif

  return s:rpc_range_result
endfunction

function! s:rpc_enter_buffer (buf, info) abort
  if a:buf != bufnr ('%')
    if !empty (a:info.windows)
      if !win_gotoid (a:info.windows[0])
        throw 'rpc/cannot_enter_window: ' . a:info.windows[0]
      endif
    else
      execute 'keepalt keepjumps hide buffer ' . a:buf
    endif
  endif

  if bufnr ('%') != a:buf
    throw 'rpc/cannot_enter_buffer: ' . a:buf
  endif
endfunction

" execute() captures messages without suppressing command errors.
" Commands retain their full authority, even when a starting buffer is given.
function! s:rpc_call_ex (command, ...) abort
  if a:0 && a:1 isnot v:null
    call s:rpc_enter_buffer (a:1, s:rpc_bufinfo (a:1))
  elseif a:0 > 1 && a:2 isnot v:null
    throw 'rpc/expected_changedtick_requires_buffer'
  endif

  if a:0 > 1 && a:2 isnot v:null
    call s:rpc_expect_tick (a:2)
  endif

  return {'output': execute (a:command)}
endfunction

function! s:rpc_call_state () abort
  let buffers = []

  for info in getbufinfo ()
    call add (buffers, {
          \ 'buffer':      info.bufnr,
          \ 'name':        info.name,
          \ 'listed':      info.listed ? v:true : v:false,
          \ 'modified':    info.changed ? v:true : v:false,
          \ 'changedtick': info.loaded ? info.changedtick : v:null,
          \ 'line_count':  info.loaded ? info.linecount : v:null,
          \ 'buftype':     getbufvar (info.bufnr, '&buftype'),
          \ 'filetype':    getbufvar (info.bufnr, '&filetype'),
          \ })
  endfor

  return {
        \ 'cwd':            getcwd (),
        \ 'current_buffer': bufnr ('%'),
        \ 'cursor':         {'line': line ('.'), 'column': col ('.')},
        \ 'buffers':        buffers,
        \ }
endfunction

function! s:rpc_call_open (path) abort
  let buf = bufadd (a:path)

  if !buf
    throw 'rpc/cannot_add_buffer'
  endif

  call setbufvar (buf, '&buflisted', 1)
  let info = s:rpc_bufinfo (buf)

  return {
        \ 'buffer':      buf,
        \ 'filename':    info.name,
        \ 'changedtick': info.changedtick,
        \ 'line_count':  info.linecount,
        \ 'modified':    info.changed,
        \ }
endfunction

function! s:rpc_call_apply_patch (buf, patch, max_offsets, expected_changedtick) abort
  return s:rpc_in_buffer (a:buf, {-> s:rpc_apply_patch (
        \ a:patch,
        \ a:max_offsets,
        \ a:expected_changedtick
        \ )}, v:false)
endfunction

function! s:rpc_apply_patch (patch, max_offsets, expected_changedtick) abort
  call s:rpc_expect_tick (a:expected_changedtick)

  if !&modifiable
    throw 'rpc/not_modifiable'
  endif

  let old_lines = getline (1, '$')
  let oldfile   = tempname ()
  let newfile   = tempname ()

  try
    " Patch complete logical lines, independently of the buffer's &endofline.
    " writefile(..., 'b') needs a final empty list item to write the last NL.
    if writefile (old_lines + [''], oldfile, 'b')
      throw 'rpc/patch_write_failed'
    endif

    " patch does all unified-diff parsing/matching.  It never modifies the
    " Vim buffer.  Keep rejects out of the filesystem.
    let cmd = 'LC_ALL=C patch --unified --batch --forward --get=0 --fuzz=0'
          \ . ' --reject-file=- --no-backup-if-mismatch'
          \ . ' -o ' . shellescape (newfile)
          \ . ' ' . shellescape (oldfile)
          \ . ' 2>&1'

    let output = system (cmd, a:patch)
    let status = v:shell_error

    if status
      throw printf (
            \ 'rpc/patch_failed: exit=%d %s',
            \ status,
            \ substitute (trim (output), "\n", ' | ', 'g')
            \ )
    endif

    " --fuzz=0 still permits relocating whole hunks.  The MCP wrapper rejects
    " ambiguous pure insertions and limits relocation by distinct old-side lines.
    for line in split (output, "\n")
      let match = matchlist (line, '^Hunk #\(\d\+\).*\<offset\s\+\([+-]\=\d\+\)\s\+lines\?\>')

      if !empty (match)
        let hunk   = str2nr (match[1])
        let offset = str2nr (match[2])

        if hunk < 1 || hunk > len (a:max_offsets)
          throw 'rpc/patch_bad_output: ' . substitute (trim (output), "\n", ' | ', 'g')
        endif

        if abs (offset) > a:max_offsets[hunk - 1]
          throw printf ('rpc/patch_needs_more_context: hunk=%d offset=%d max=%d %s',
                \ hunk, offset, a:max_offsets[hunk - 1],
                \ substitute (trim (output), "\n", ' | ', 'g'))
        endif
      endif
    endfor

    " Require complete lines in nonempty patch output.  A diff containing
    " a new-side no-EOL marker can otherwise remove the final NL.
    " Empty output represents Vim's single empty logical line.
    let new_lines = readfile (newfile, 'b')

    if !empty (new_lines)
      if new_lines[-1] !=# ''
        throw 'rpc/patch_missing_eol'
      endif
      call remove (new_lines, -1)
    endif

    " Vim always has at least one logical line.
    if empty (new_lines)
      let new_lines = ['']
    endif

    let hunks = diff (old_lines, new_lines, {'output': 'indices'})

    if empty (hunks)
      return {
            \ 'changedtick': b:changedtick,
            \ 'hunks':       0,
            \ 'noop':        v:true,
            \ }
    endif

    " Nothing has touched the buffer yet.  Recheck immediately before commit.
    call s:rpc_expect_tick (a:expected_changedtick)
    call s:rpc_break_undo ()

    " diff() indices refer to the original buffer.  Apply bottom-up so earlier
    " line numbers never move underneath later hunks.
    let changed = 0

    for hunk in reverse (copy (hunks))
      let first     = hunk.from_idx + 1
      let old_count = hunk.from_count
      let new_count = hunk.to_count
      let common    = min ([old_count, new_count])

      let replacement = new_count
            \ ? new_lines[hunk.to_idx : hunk.to_idx + new_count - 1]
            \ : []

      " Pure insertion: from_idx is the zero-based insertion position.
      if !old_count
        if changed
          undojoin
        endif

        if append (first - 1, replacement)
          throw 'rpc/append_failed'
        endif

        let changed = 1
        continue
      endif

      if common
        if changed
          undojoin
        endif

        if setline (first, replacement[:common - 1])
          throw 'rpc/setline_failed'
        endif

        let changed = 1
      endif

      if new_count < old_count
        if changed
          undojoin
        endif

        if deletebufline (
              \ bufnr ('%'),
              \ first + new_count,
              \ first + old_count - 1
              \ )
          throw 'rpc/deletebufline_failed'
        endif

        let changed = 1

      elseif new_count > old_count
        if changed
          undojoin
        endif

        if append (
              \ first + old_count - 1,
              \ replacement[old_count:]
              \ )
          throw 'rpc/append_failed'
        endif

        let changed = 1
      endif
    endfor

    return {
          \ 'changedtick': b:changedtick,
          \ 'hunks':       len (hunks),
          \ }

  finally
    call delete (oldfile)
    call delete (newfile)
  endtry
endfunction

function! s:rpc_read_ranges (buf, ranges) abort
  let result = []
  let line_count = s:rpc_bufinfo (a:buf).linecount

  for range in a:ranges
    let [first, last] = s:rpc_range (range, line_count)
    call add (result, {'range': range, 'start': first, 'end': last, 'lines': getline (first, last)})
  endfor

  return {'changedtick': b:changedtick, 'ranges': result}
endfunction

function! s:rpc_call_read_lines (buf, ranges) abort
  return s:rpc_in_buffer (a:buf, {-> s:rpc_read_ranges (a:buf, a:ranges)})
endfunction

" :global does the actual scan; this function merely collects matching lines.
let s:rpc_grep_result  = []
let s:rpc_grep_pattern = ''
let s:rpc_grep_max     = 0

function! s:rpc_grep_collect () abort
  if len (s:rpc_grep_result) >= s:rpc_grep_max
    return
  endif

  let text = getline ('.')

  call add (s:rpc_grep_result, {
        \ 'buffer':      bufnr ('%'),
        \ 'changedtick': b:changedtick,
        \ 'line':        line ('.'),
        \ 'column':      match (text, s:rpc_grep_pattern) + 1,
        \ 'text':        text,
        \ })
endfunction

function! s:rpc_grep_buffer () abort
  let save_search = @/

  try
    let @/ = s:rpc_grep_pattern
    execute 'silent keepjumps keeppatterns global//call ' . s:rpc_sid . 'rpc_grep_collect()'
  finally
    let @/ = save_search
  endtry
endfunction

function! s:rpc_call_grep (buffers, pattern, mode, max_results) abort
  if a:max_results <= 0
    throw 'rpc/bad_max_results: ' . a:max_results
  endif

  if a:mode ==# 'regex'
    let s:rpc_grep_pattern = a:pattern
  elseif a:mode ==# 'word'
    let s:rpc_grep_pattern = '\V\<' . escape (a:pattern, '\') . '\>'
  else
    throw 'rpc/bad_grep_mode: ' . a:mode
  endif

  let s:rpc_grep_result = []
  let s:rpc_grep_max    = a:max_results
  let buffers = empty (a:buffers) ? map (filter (getbufinfo (), 'v:val.loaded'), 'v:val.bufnr') : a:buffers

  for buf in buffers
    call s:rpc_in_buffer (buf, {-> s:rpc_grep_buffer ()})

    if len (s:rpc_grep_result) >= s:rpc_grep_max
      break
    endif
  endfor

  return {'matches': s:rpc_grep_result, 'truncated': len (s:rpc_grep_result) >= s:rpc_grep_max}
endfunction

" Quote / as an Ex :substitute delimiter without changing replacement backslash semantics.
" A / preceded by an even-length run of backslashes needs one more backslash;
" with an odd-length run it is already quoted for the command parser. An odd
" trailing run also needs one more backslash so it cannot quote the closing /.
function! s:rpc_quote_substitute_replacement (text) abort
  let result = ''
  let backslashes = 0

  for char in split (a:text, '\zs')
    if char ==# '\'
      let backslashes += 1
    else
      if char ==# '/' && backslashes % 2 == 0
        let result .= '\'
      endif

      let backslashes = 0
    endif

    let result .= char
  endfor

  if backslashes % 2
    let result .= '\'
  endif

  return result
endfunction

function! s:rpc_insert_lines (line, lines, expected_changedtick) abort
  if a:line < 0 || a:line > line ('$')
    throw printf ('rpc/bad_insert_line: %d', a:line)
  endif

  call s:rpc_expect_tick (a:expected_changedtick)
  call s:rpc_break_undo ()

  if append (a:line, a:lines)
    throw 'rpc/append_failed'
  endif

  return {
        \ 'changedtick': b:changedtick,
        \ 'start':       a:line + 1,
        \ 'end':         a:line + len (a:lines),
        \ }
endfunction

function! s:rpc_call_insert_lines (buf, line, lines, expected_changedtick) abort
  return s:rpc_in_buffer (a:buf, {-> s:rpc_insert_lines (
        \ a:line,
        \ a:lines,
        \ a:expected_changedtick
        \ )})
endfunction

function! s:rpc_substitute (range, pattern, replacement, flags, expected_changedtick) abort
  call s:rpc_expect_tick (a:expected_changedtick)
  call s:rpc_validate_range (a:range)

  if a:flags !~# '^[egiInp#lr]*$'
    throw 'rpc/bad_substitute_flags: ' . a:flags
  endif

  if strpart (a:replacement, 0, 2) ==# '\='
    throw 'rpc/expression_replacement_not_allowed'
  endif

  let save_search = @/
  let replacement = s:rpc_quote_substitute_replacement (a:replacement)

  call s:rpc_break_undo ()

  try
    let @/ = a:pattern
    execute 'silent keepjumps keeppatterns ' . a:range . 's//' . replacement . '/' . a:flags
  finally
    let @/ = save_search
  endtry

  return {'changedtick': b:changedtick, 'changed': b:changedtick != a:expected_changedtick}
endfunction

function! s:rpc_call_substitute (buf, range, pattern, replacement, flags, expected_changedtick) abort
  return s:rpc_in_buffer (a:buf, {-> s:rpc_substitute (a:range, a:pattern, a:replacement, a:flags, a:expected_changedtick)})
endfunction

function! s:rpc_update (expected_changedtick) abort
  call s:rpc_expect_tick (a:expected_changedtick)
  let buf = bufnr ('%')

  silent keepjumps update
  let info = getbufinfo (buf)

  if empty (info) || !info[0].loaded
    throw 'rpc/buffer_disappeared_during_update: ' . buf
  endif

  return {
        \ 'buffer':      buf,
        \ 'changedtick': info[0].changedtick,
        \ 'modified':    info[0].changed,
        \ 'filename':    bufname (buf),
        \ }
endfunction

function! s:rpc_call_update (buf, expected_changedtick) abort
  return s:rpc_in_buffer (a:buf, {-> s:rpc_update (a:expected_changedtick)})
endfunction

function! s:rpc_undo (command, expected_changedtick) abort
  call s:rpc_expect_tick (a:expected_changedtick)

  if !&modifiable
    throw 'rpc/not_modifiable'
  endif

  execute 'silent keepjumps ' . a:command
  let tree = undotree ()

  return {
        \ 'buffer':      bufnr ('%'),
        \ 'changedtick': b:changedtick,
        \ 'changed':     b:changedtick != a:expected_changedtick,
        \ 'seq_cur':     tree.seq_cur,
        \ 'seq_last':    tree.seq_last,
        \ 'modified':    &modified,
        \ }
endfunction

function! s:rpc_call_undo (buf, expected_changedtick) abort
  return s:rpc_in_buffer (a:buf, {-> s:rpc_undo ('undo', a:expected_changedtick)}, v:false)
endfunction

function! s:rpc_call_redo (buf, expected_changedtick) abort
  return s:rpc_in_buffer (a:buf, {-> s:rpc_undo ('redo', a:expected_changedtick)}, v:false)
endfunction

function! s:rpc_call_set_cursor (buf, line, col, ...) abort
  let info = s:rpc_bufinfo (a:buf)

  if a:0 && a:1 isnot v:null && info.changedtick != a:1
    throw printf ('rpc/stale_buffer: expected %d, got %d', a:1, info.changedtick)
  endif

  if a:line < 1 || a:line > info.linecount || a:col < 1
    throw printf ('rpc/bad_cursor: %d,%d', a:line, a:col)
  endif

  call s:rpc_enter_buffer (a:buf, info)

  call cursor (a:line, a:col)

  return {'buffer': bufnr ('%'), 'changedtick': b:changedtick, 'line': line ('.'), 'column': col ('.')}
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" command receiver

function! s:receive (channel, msg) abort
  if type (a:msg) != v:t_list || len (a:msg) == 0
    return
  endif

  let cmd = a:msg[0]

  if cmd ==# 'call'
    let id     = a:msg[1]
    let method = a:msg[2]
    let args   = a:msg[3:]

    try
      let result = call (function('s:rpc_call_' . method), args)
      call ch_sendexpr (s:channel, ['reply', id, 1, result])
    catch
      call ch_sendexpr (s:channel, ['reply', id, 0, v:exception]) " originallky also: v:throwpoint
    endtry

  elseif cmd ==# 'open'
    let session   = a:msg[1]
    let filename  = a:msg[2]
    let extension = a:msg[3]
    let state     = a:msg[4]

    let path = tempname() . '-' . filename . extension
    let s:incoming = { 'path': path, 'session': session, 'state': state }
    call writefile ([], path)

  elseif cmd ==# 'data'
    let data = base64_decode (a:msg[1])
    call ch_sendexpr (s:channel, ['ack', len (data)])
    call writefile (data, s:incoming.path, 'ab')

  elseif cmd ==# 'ack'
    " nop

  elseif cmd ==# 'eof'
    if a:msg[1]
      execute 'edit ' . fnameescape (s:incoming.path)
      let s:sessions[bufnr('%')] = { 'session': s:incoming.session, 'state': s:incoming.state, 'path': s:incoming.path }
    else
      call delete (s:incoming.path)
    endif

    let s:incoming = v:null

  elseif cmd ==# 'ex'
    execute a:msg[1]

  elseif cmd ==# 'echo'
    if s:popup
      call popup_close (s:popup)
    endif
    echom 'mcp-vim: ' . a:msg[1]

  elseif cmd ==# 'error'
    if s:popup
      call popup_close (s:popup)
    endif
    let s:popup = popup_create (split (a:msg[1], "\n", 1), { 'line': &lines - 2, 'col': 1, 'pos': 'botleft', 'maxheight': 10, 'maxwidth': &columns - 4, 'scrollbar': 1, 'padding': [0, 1, 0, 1] })

  elseif cmd ==# 'goto'
    for b in keys (s:sessions)
      if s:sessions[b].session ==# a:msg[1]
        execute 'buffer ' . b
        call cursor (a:msg[2], a:msg[3])
        break
      endif
    endfor

  else
    echom 'mcp-vim: unknown command ' . string (cmd)
  endif
endfunction

function! s:save (file) abort
  if type (s:channel) != v:t_channel
    return
  endif

  let b = bufnr ('%')

  if has_key (s:sessions, b) && a:file ==# s:sessions[b].path
    call ch_sendexpr (s:channel, ['save', s:sessions[b].session])

    let data = readblob (s:sessions[b].path)
    call ch_sendexpr (s:channel, ['data', base64_encode (data)])
    call ch_sendexpr (s:channel, ['eof', 1])

  endif
endfunction

function! s:close (buf) abort
  if has_key (s:sessions, a:buf)
    call delete (s:sessions[a:buf].path)
    if type (s:channel) == v:t_channel
      call ch_sendexpr (s:channel, ['close', s:sessions[a:buf].session])
    endif
    call remove (s:sessions, a:buf)
  endif
endfunction

augroup mcp_vim
  autocmd!

  autocmd BufWritePost * call s:save (expand ('<afile>:p'))
  autocmd BufUnload * call s:close (str2nr (expand ('<abuf>')))
  autocmd VimLeavePre * call s:quit ()
augroup END

