use common::sense;
use Test::More;
use File::Temp ();
use File::Path ();
use AnyEvent::MCP::Config ();
use IPC::Open3 ();
use Symbol ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
File::Path::mkpath (["$dir/home", "$dir/config"], 0, 0700);
local $ENV{HOME} = "$dir/home";
local $ENV{XDG_CONFIG_HOME} = "$dir/config";

sub run_vim {
   my @argv = @_;
   my $error = Symbol::gensym;
   my $pid = IPC::Open3::open3 (my $input, my $output, $error,
      $^X, "-Ilib", "bin/mcp-vim", @argv);
   close $input;
   local $/;
   my $out = <$output> // "";
   my $err = <$error> // "";
   waitpid $pid, 0;
   ($? >> 8, $out, $err)
}

my ($status, $url, $err) = run_vim ("--print-url");
is $status, 0, "print-url exits successfully";
like $url, qr{\Ahttp://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_-]{43}/\n\z},
   "print-url emits a cookie-bearing URL prefix";
is $err, "", "print-url has no diagnostics on success";

my $file = "$dir/config/anyevent-mcp/global.ini";
ok -f $file && !((stat $file)[2] & 077), "global master secret saved privately";
my $config = AnyEvent::MCP::Config->new (file => $file);
my ($default_port, $cookie);
{
   local $0 = "mcp-vim";
   $default_port = $config->server_port ("default");
   $cookie = $config->credential ("token", "default");
}
like $url, qr{\Ahttp://127\.0\.0\.1:$default_port/},
   "default port is derived from the service name";
# token is derived in the broker program domain above.
like $url, qr{\Q/$cookie/\E\n\z}, "cookie derives from global master secret";

my ($again_status, $again_url) = run_vim ("--print-url");
is $again_status, 0, "second invocation exits successfully";
is $again_url, $url, "cookie and URL are stable across processes";
($status, $url) = run_vim ("--print-url", "--token", "cli-first", "--token", "cli-second");
is $status, 0, "repeated --token options accepted";
like $url, qr{/cli-first/\n\z}, "first CLI token is advertised";
ok !-e "$dir/home/.xpcse-broker", "startup no longer generates old cookie config";

open my $legacy, ">>", $file or die $!;
print {$legacy} "\n[instance default]\nbind = 127.0.0.1:31749\n";
close $legacy or die $!;
($status, $url, $err) = run_vim ("--print-url");
is $status, 0, "named bind setting accepted";
is $url, "http://127.0.0.1:31749/$cookie/\n",
   "named bind overrides derived port";

open my $fh, ">>", $file or die $!;
print {$fh} "tokens = explicit-cookie,secondary-token\n";
close $fh or die $!;
($status, $url) = run_vim ("--print-url");
is $status, 0, "explicit configured tokens accepted";
like $url, qr{\Ahttp://[^:/\s]+:31749/explicit-cookie/\n\z},
   "first configured token overrides derived default";

($status, $url) = run_vim ("--print-url", "--bind", "127.0.0.1:41859");
is $status, 0, "bind switch accepted";
is $url, "http://127.0.0.1:41859/explicit-cookie/\n",
   "explicit bind overrides named setting";

($status, $url) = run_vim ("--print-url", "--bind", "[::1]:41859");
is $status, 0, "IPv6 bind accepted";
is $url, "http://[::1]:41859/explicit-cookie/\n",
   "IPv6 URL host is bracketed";

($status, $url) = run_vim ("--print-url", "--bind", "[::]");
is $status, 0, "IPv6 wildcard accepted";
like $url, qr{\Ahttp://[^:/\s]+:31749/explicit-cookie/\n\z},
   "wildcard bind advertises concrete hostname";

($status, undef, $err) = run_vim ("--print-url", "--bind", ":0");
ok $status != 0 && $err =~ /port is not known/,
   "zero port rejected because a printable fixed URL is required";
($status, undef, $err) = run_vim ("--print-url", "--bind", ":65536");
ok $status != 0 && $err =~ /Invalid MCP bind/,
   "out-of-range port rejected";
($status, undef, $err) = run_vim ("--print-url", "--bind", "");
ok $status != 0 && $err =~ /Invalid MCP bind/,
   "empty host rejected";

{
   local $ENV{XDG_CONFIG_HOME} = "/proc/self/mcp-vim-no-persistent-secret-$$";
   ($status, $url, $err) = run_vim ("--print-url");
   ok $status != 0 && !length $url,
      "cannot print a URL backed only by unsaved, process-local entropy";
   like $err, qr/master secret is not persistently stored/,
      "unstable master secret is diagnosed explicitly";
}

($status, my $help) = run_vim ("--help");
is $status, 0, "help exits successfully";
like $help, qr/print-url/, "help explains URL switch";
($status, undef, $err) = run_vim ("--not-a-switch");
ok $status != 0, "unknown option rejected";
# exercise message capture and error propagation in Vim itself, when available.
SKIP: {
   skip "extended real Vim tests (PERL_ANYEVENT_MCP_TESTS=1)", 2
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   my ($vim) = grep -x $_ && !-d _, map "$_/vim", split /:/, $ENV{PATH};
   skip "vim not available", 2 unless $vim;

   my $script = "$dir/ex-test.vim";
   open my $fh, ">", $script or die "$script: $!";
   print {$fh} <<'VIM';
if !exists ('*getscriptinfo') || !exists ('*assert_equal') || !exists ('*bufadd') || !exists ('*bufload') || !exists ('*execute')
  call writefile (['SKIP: Vim lacks required scripting functions'], argv (0))
  qa!
endif
source vim/plugin/mcp-vim.vim
let sid = filter (getscriptinfo (), 'v:val.name =~# "mcp-vim\\.vim$"')[0].sid
let Rpc = function ('<SNR>' . sid . '_rpc_call_ex')
call assert_equal ("\nhello\nworld", Rpc ("echo 'hello' | echo 'world'").output)
call assert_equal ('', Rpc ("let g:mcp_ex_test = 42").output)
call assert_equal (42, g:mcp_ex_test)
call Rpc ("call setline (1, 'changed')\nlet g:mcp_ex_second = 1")
call assert_equal ('changed', getline (1))
call assert_equal (1, g:mcp_ex_second)
let error = ''
try
  call Rpc ("let g:mcp_ex_partial = 1 | throw 'deliberate failure'")
catch
  let error = v:exception
endtry
call assert_equal ('deliberate failure', error)
call assert_equal (1, g:mcp_ex_partial)
let error = ''
try
  call Rpc ('NoSuchExCommand')
catch
  let error = v:exception
endtry
call assert_match ('E492:', error)
call assert_equal ("\nafter error", Rpc ("echo 'after error'").output)

let original = bufnr ('%')
let file = tempname ()
call writefile (['original'], file)
let target = bufadd (file)
call bufload (target)
call setbufline (target, 1, 'saved by update')
let tick = getbufvar (target, 'changedtick')
call Rpc ('update', target, tick)
call assert_equal (target, bufnr ('%'))
call assert_equal (['saved by update'], readfile (file))
call assert_equal (0, &modified)
call Rpc ("call setline (1, 'newer contents')", target)
let error = ''
try
  call Rpc ('let g:mcp_stale_ex_ran = 1', target, tick)
catch
  let error = v:exception
endtry
call assert_match ('rpc/stale_buffer:', error)
call assert_equal (0, exists ('g:mcp_stale_ex_ran'))
call assert_equal (['saved by update'], readfile (file))
let error = ''
try
  call Rpc ('let g:mcp_stale_ex_ran = 1', v:null, b:changedtick)
catch
  let error = v:exception
endtry
call assert_match ('requires_buffer', error)
call assert_equal (0, exists ('g:mcp_stale_ex_ran'))

" Entering a buffer can run autocommands; check the tick afterwards.
execute 'hide buffer ' . original
execute 'autocmd BufEnter <buffer=' . target . '> call setline (1, "changed on entry")'
let tick = getbufvar (target, 'changedtick')
let error = ''
try
  call Rpc ('let g:mcp_stale_ex_ran = 1', target, tick)
catch
  let error = v:exception
endtry
call assert_match ('rpc/stale_buffer:', error)
call assert_equal (0, exists ('g:mcp_stale_ex_ran'))

" A hidden buffer has its own history; undo must not affect the current one.
let Undo = function ('<SNR>' . sid . '_rpc_call_undo')
let Redo = function ('<SNR>' . sid . '_rpc_call_redo')
let Substitute = function ('<SNR>' . sid . '_rpc_call_substitute')
let caller = bufnr ('%')
let caller_lines = getline (1, '$')
let caller_view = winsaveview ()
let undo_file = tempname ()
call writefile (['base'], undo_file)
let undo_buf = bufadd (undo_file)
call bufload (undo_buf)
call Substitute (undo_buf, '%', 'base', 'one', '', getbufvar (undo_buf, 'changedtick'))
let one = getbufvar (undo_buf, 'changedtick')
call Substitute (undo_buf, '%', 'one', 'two', '', one)
let two = getbufvar (undo_buf, 'changedtick')
let result = Undo (undo_buf, two)
call assert_equal (['one'], getbufline (undo_buf, 1, '$'))
call assert_equal (undo_buf, result.buffer)
call assert_equal (1, result.changed)
call assert_equal (1, result.modified)
call assert_equal (1, result.seq_cur)
call assert_equal (2, result.seq_last)
call assert_equal (getbufvar (undo_buf, 'changedtick'), result.changedtick)
call assert_equal (caller, bufnr ('%'))
call assert_equal (caller_lines, getline (1, '$'))
call assert_equal (caller_view, winsaveview ())
call assert_equal (['base'], readfile (undo_file))

let error = ''
try
  call Redo (undo_buf, two)
catch
  let error = v:exception
endtry
call assert_match ('rpc/stale_buffer:', error)
call assert_equal (['one'], getbufline (undo_buf, 1, '$'))
let result = Redo (undo_buf, result.changedtick)
call assert_equal (['two'], getbufline (undo_buf, 1, '$'))
call assert_equal (2, result.seq_cur)
call assert_equal (1, result.changed)
let result = Redo (undo_buf, result.changedtick)
call assert_equal (0, result.changed)
call assert_equal (2, result.seq_cur)

let result = Undo (undo_buf, result.changedtick)
let result = Undo (undo_buf, result.changedtick)
call assert_equal (['base'], getbufline (undo_buf, 1, '$'))
call assert_equal (0, result.seq_cur)
call assert_equal (0, result.modified)
let result = Undo (undo_buf, result.changedtick)
call assert_equal (0, result.changed)
call assert_equal (0, result.seq_cur)

" A new edit after undo selects a new branch; redo cannot resurrect the old one.
let result = Redo (undo_buf, result.changedtick)
call Substitute (undo_buf, '%', 'one', 'branch', '', result.changedtick)
let tick = getbufvar (undo_buf, 'changedtick')
let result = Redo (undo_buf, tick)
call assert_equal (['branch'], getbufline (undo_buf, 1, '$'))
call assert_equal (0, result.changed)
call assert_equal (3, result.seq_cur)
call assert_equal (3, result.seq_last)

call setbufvar (undo_buf, '&modifiable', 0)
let error = ''
try
  call Undo (undo_buf, result.changedtick)
catch
  let error = v:exception
endtry
call assert_match ('rpc/not_modifiable', error)
call setbufvar (undo_buf, '&modifiable', 1)
call assert_equal (['base'], readfile (undo_file))
call assert_equal (caller, bufnr ('%'))

" The current-buffer case keeps Vim's normal cursor adjustment and history.
execute 'noautocmd hide buffer ' . undo_buf
let result = Undo (undo_buf, getbufvar (undo_buf, 'changedtick'))
call assert_equal (undo_buf, bufnr ('%'))
call assert_equal (['one'], getline (1, '$'))
call assert_equal (1, result.seq_cur)
let result = Redo (undo_buf, result.changedtick)
call assert_equal (['branch'], getline (1, '$'))
call assert_equal (3, result.seq_cur)

let Update = function ('<SNR>' . sid . '_rpc_call_update')
let caller = bufnr ('%')
let caller_lines = getline (1, '$')
let caller_view = winsaveview ()
let update_file = tempname ()
call writefile (['saved'], update_file)
let update_buf = bufadd (update_file)
call bufload (update_buf)
call setbufline (update_buf, 1, 'edited')
let old_tick = getbufvar (update_buf, 'changedtick')
let result = Update (update_buf, old_tick)
call assert_equal (['edited'], readfile (update_file))
call assert_equal (0, result.modified)
call assert_equal (update_buf, result.buffer)
call assert_equal (update_file, result.filename)
call assert_equal (getbufvar (update_buf, 'changedtick'), result.changedtick)
call assert_equal (caller, bufnr ('%'))
call assert_equal (caller_lines, getline (1, '$'))
call assert_equal (caller_view, winsaveview ())

let g:update_writes = 0
execute 'autocmd BufWritePre <buffer=' . update_buf . '> let g:update_writes += 1'
let result = Update (update_buf, result.changedtick)
call assert_equal (0, g:update_writes)
call assert_equal (0, result.modified)
call setbufline (update_buf, 1, 'newer')
let error = ''
try
  call Update (update_buf, old_tick)
catch
  let error = v:exception
endtry
call assert_match ('rpc/stale_buffer:', error)
call assert_equal (['edited'], readfile (update_file))
call assert_equal (0, g:update_writes)

" Write autocommands run normally; the result describes the buffer afterwards.
execute 'autocmd BufWritePre <buffer=' . update_buf . '> call setline (1, "prewrite")'
execute 'autocmd BufWritePost <buffer=' . update_buf . '> call setline (1, "postwrite")'
let result = Update (update_buf, getbufvar (update_buf, 'changedtick'))
call assert_equal (1, g:update_writes)
call assert_equal (['prewrite'], readfile (update_file))
call assert_equal (['postwrite'], getbufline (update_buf, 1, '$'))
call assert_equal (getbufvar (update_buf, '&modified'), result.modified)
call assert_equal (getbufvar (update_buf, 'changedtick'), result.changedtick)
execute 'autocmd! BufWritePre <buffer=' . update_buf . '>'
execute 'autocmd! BufWritePost <buffer=' . update_buf . '>'

call setbufvar (update_buf, '&modified', 1)
execute 'autocmd BufWritePre <buffer=' . update_buf . '> throw "deliberate write failure"'
let error = ''
try
  call Update (update_buf, result.changedtick)
catch
  let error = v:exception
endtry
call assert_equal ('deliberate write failure', error)
call assert_equal (['prewrite'], readfile (update_file))
call assert_equal (1, getbufvar (update_buf, '&modified'))
call assert_equal (caller, bufnr ('%'))
execute 'autocmd! BufWritePre <buffer=' . update_buf . '>'

call setbufvar (update_buf, '&readonly', 1)
let error = ''
try
  call Update (update_buf, getbufvar (update_buf, 'changedtick'))
catch
  let error = v:exception
endtry
call assert_match ('E45:', error)
call assert_equal (['prewrite'], readfile (update_file))
call setbufvar (update_buf, '&readonly', 0)
let result = Update (update_buf, getbufvar (update_buf, 'changedtick'))
call assert_equal (['postwrite'], readfile (update_file))
call assert_equal (0, result.modified)

" A write autocommand may change the current buffer; report the saved target.
execute 'autocmd BufWritePost <buffer=' . update_buf . '> execute "noautocmd hide buffer " . ' . caller
call setbufline (update_buf, 1, 'switched')
let result = Update (update_buf, getbufvar (update_buf, 'changedtick'))
call assert_equal (update_buf, result.buffer)
call assert_equal (update_file, result.filename)
call assert_equal (getbufvar (update_buf, 'changedtick'), result.changedtick)
call assert_equal (['switched'], readfile (update_file))
call assert_equal (caller, bufnr ('%'))
execute 'autocmd! BufWritePost <buffer=' . update_buf . '>'

let unnamed = bufadd ('')
call bufload (unnamed)
call setbufline (unnamed, 1, 'unsaved')
let error = ''
try
  call Update (unnamed, getbufvar (unnamed, 'changedtick'))
catch
  let error = v:exception
endtry
call assert_match ('E32:', error)
call assert_equal (1, getbufvar (unnamed, '&modified'))
call assert_equal (caller, bufnr ('%'))
" Opening files loads a listed buffer without changing the current view.
let Open = function ('<SNR>' . sid . '_rpc_call_open')
let open_dir = tempname ()
call mkdir (open_dir)
let old_cwd = getcwd ()
execute 'lcd ' . fnameescape (open_dir)
let caller = bufnr ('%')
let caller_lines = getline (1, '$')
let caller_view = winsaveview ()
let literal_name = "literal # % | [*] $HOME 'quote'.txt"
call writefile (['disk one', 'disk two'], literal_name)
let opened = Open (literal_name)
call assert_equal (open_dir . '/' . literal_name, opened.filename)
call assert_equal (['disk one', 'disk two'], getbufline (opened.buffer, 1, '$'))
call assert_equal (1, buflisted (opened.buffer))
call assert_equal (2, opened.line_count)
call assert_equal (0, opened.modified)
call assert_equal (getbufvar (opened.buffer, 'changedtick'), opened.changedtick)
call assert_equal (caller, bufnr ('%'))
call assert_equal (caller_lines, getline (1, '$'))
call assert_equal (caller_view, winsaveview ())

call setbufline (opened.buffer, 1, 'unsaved edit')
call writefile (['external disk edit'], literal_name)
let reopened = Open (open_dir . '/' . literal_name)
call assert_equal (opened.buffer, reopened.buffer)
call assert_equal (['unsaved edit', 'disk two'], getbufline (reopened.buffer, 1, '$'))
call assert_equal (1, reopened.modified)
call assert_equal (getbufvar (reopened.buffer, 'changedtick'), reopened.changedtick)

call writefile (['unloaded'], 'unloaded.txt')
let unloaded = bufadd ('unloaded.txt')
call assert_equal (0, bufloaded (unloaded))
let loaded = Open ('unloaded.txt')
call assert_equal (unloaded, loaded.buffer)
call assert_equal (1, bufloaded (loaded.buffer))
call assert_equal (1, buflisted (loaded.buffer))
call assert_equal (['unloaded'], getbufline (loaded.buffer, 1, '$'))

let missing = Open ('missing.txt')
call assert_equal ([''], getbufline (missing.buffer, 1, '$'))
call assert_equal (1, missing.line_count)
call assert_equal (0, missing.modified)
call assert_equal (0, filereadable ('missing.txt'))

let g:open_event_file = open_dir . '/events.txt'
call writefile (['disk'], g:open_event_file)
augroup MCP_TEST_OPEN
  autocmd!
  autocmd BufReadPost * if expand ('<afile>:p') ==# g:open_event_file | call setline (1, 'autocommand edit') | endif
augroup END
let event_buffer = Open (g:open_event_file)
call assert_equal (['autocommand edit'], getbufline (event_buffer.buffer, 1, '$'))
call assert_equal (getbufvar (event_buffer.buffer, 'changedtick'), event_buffer.changedtick)
call assert_equal (getbufvar (event_buffer.buffer, '&modified'), event_buffer.modified)
call assert_equal (caller, bufnr ('%'))

set modeline modelines=5
call writefile (['text', 'vim: set ts=7:'], 'modeline.txt')
let modeline_buffer = Open ('modeline.txt')
call assert_equal (7, getbufvar (modeline_buffer.buffer, '&tabstop'))

let g:open_event_file = open_dir . '/failure.txt'
call writefile (['disk'], g:open_event_file)
augroup MCP_TEST_OPEN
  autocmd!
  autocmd BufReadPost * if expand ('<afile>:p') ==# g:open_event_file | throw 'deliberate open failure' | endif
augroup END
let error = ''
try
  call Open (g:open_event_file)
catch
  let error = v:exception
endtry
call assert_match ('deliberate open failure', error)
call assert_equal (caller, bufnr ('%'))
augroup MCP_TEST_OPEN
  autocmd!
augroup END
execute 'lcd ' . fnameescape (old_cwd)
call delete (open_dir, 'rf')
call delete (update_file)
call delete (undo_file)
call delete (file)
call writefile (v:errors, argv (0))
qa!
VIM
   close $fh or die "$script: $!";
   my $errors = "$dir/vim-errors";
   my $error = Symbol::gensym;
   my $pid = IPC::Open3::open3 (my $input, my $output, $error,
      $vim, "-Nu", "NONE", "-i", "NONE", "-n", "-es", "-S", $script, "--", $errors);
   close $input;
   local $/;
   my $stdout = <$output>;
   my $stderr = <$error>;
   waitpid $pid, 0;
   my $status = $?;
   open $fh, "<", $errors or die "$errors: $!";
   my $messages = <$fh> // "";
   close $fh;

   skip $messages, 2 if !$status && $messages =~ /\ASKIP:/;
   is $status, 0, "real Vim loads the plugin and exercises unrestricted Ex RPC";
   diag $stdout, $stderr if $status;
   is $messages, "", "real Vim captures messages, changes state, propagates errors and retains partial effects";
}

done_testing;
