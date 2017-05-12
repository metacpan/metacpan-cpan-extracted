use strict;
use warnings FATAL => 'all';
use File::Temp;

use Test::More tests => 4;
BEGIN { require_ok('Config::AutoConf::INI') };

my $tmp = File::Temp->new(UNLINK => 1, SUFFIX => '.ini');
print $tmp <DATA>;
close($tmp) || warn "Failed to close $tmp";

my $c = new_ok('Config::AutoConf::INI');
ok($c->check($tmp->filename), 'Config::AutoConf::INI->new->check($filename) usage');
ok(Config::AutoConf::INI->check($tmp->filename), 'Config::AutoConf::INI->check($filename) usage');

1;
__DATA__

; --------------
; Compiler setup
; --------------
; Anything on the the left-hand side is used if the right-hand side is a true value.
;
[includes]
; Interface to push_includes
. = 1
/this/path = 1

[preprocess_flags]
; Interface to push_preprocess_flags
-DFLAG01 = 1

[compiler_flags]
; Interface to push_compiler_flags
-DFLAG02 = 1

[link_flags]
; Interface to push_link_flags
-lm = 1

; -----------------------
; Config::AutoConf checks
; -----------------------
; The check is done on the left-hand side when the right-hand side is a true value.
;
; If the right-hand side does not look like a number then a variable is explicitely
; created with that name in the config file.
;
[files]
; Interface to check_file
/etc/passwd = HAVE_ETC_PASSWD
/tmp/this = HAVE_THIS
/tmp/that = HAVE_THAT
C:\Windows\Temp\foo = HAVE_C_WINDOWS_TEMP_FOO

[progs]
; Interface to check_prog
cc = CC_NAME

[headers]
; Interface to check_header
stdio.h = 1
stddef.h = HAVE_STDDEF_H
unistd.h = 1
time.h = 1
sys/time.h = 1

[bundle]
; The bundle check on the left-hand side is done when the right-hand side is a true value.
;
; Interface to check_stdc_headers
stdc_headers = 1
; Interface to check_default_headers
default_headers = 1
; Interface to check_dirent_headers
dirent_headers = 1

[decls]
; Interface to check_decl
read = 1

[funcs]
; Interface to check_func
read = 1

[types]
; Interface to check_types
size_t = 1

[sizeof_types]
; Interface to check_sizeof_types
size_t = 1

[alignof_types]
; Interface to check_alignof_types
struct tm.tm_year = 1

[members]
; Interface to check_member
struct tm.tm_year = 1

[outputs]
; Anything on the the left-hand side is produced if the right-hand side is a true value.
config_autoconf.h = 1
config.h = 0
localpath/created/config_autoconf.h = 1
