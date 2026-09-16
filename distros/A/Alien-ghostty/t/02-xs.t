use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::ghostty;

alien_ok 'Alien::ghostty';

xs_ok do { local $/; <DATA> }, with_subtest {
    my ($module) = @_;
    is($module->render("hello\r\n\e[1mworld\e[0m", 20, 5), "hello\nworld",
       'terminal parses VT input and formats plain text');
    my $version = $module->version;
    like($version, qr/^\d+\.\d+\.\d+/, "library reports version $version");
    is($version, Alien::ghostty->version, 'library version matches Alien::ghostty->version')
        if Alien::ghostty->install_type eq 'share';
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>
#include <ghostty/vt.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

SV *
render(klass, input, cols, rows)
    const char *klass
    SV *input
    int cols
    int rows
  PREINIT:
    GhosttyTerminal term = NULL;
    GhosttyFormatter fmt = NULL;
    GhosttyFormatterTerminalOptions opts;
    uint8_t *buf = NULL;
    size_t len = 0;
    STRLEN in_len;
    const char *in;
  CODE:
    PERL_UNUSED_VAR(klass);
    in = SvPVbyte(input, in_len);
    if (ghostty_terminal_new(NULL, &term, (uint16_t)cols, (uint16_t)rows) != GHOSTTY_SUCCESS)
        croak("ghostty_terminal_new failed");
    ghostty_terminal_vt_write(term, (const uint8_t *)in, in_len);
    memset(&opts, 0, sizeof opts);
    opts.size = sizeof opts;
    opts.emit = GHOSTTY_FORMATTER_FORMAT_PLAIN;
    opts.trim = true;
    if (ghostty_formatter_terminal_new(NULL, &fmt, term, opts) != GHOSTTY_SUCCESS
        || ghostty_formatter_format_alloc(fmt, NULL, &buf, &len) != GHOSTTY_SUCCESS) {
        if (fmt) ghostty_formatter_free(fmt);
        ghostty_terminal_free(term);
        croak("formatting failed");
    }
    RETVAL = newSVpvn((const char *)buf, len);
    ghostty_free(NULL, buf, len);
    ghostty_formatter_free(fmt);
    ghostty_terminal_free(term);
  OUTPUT:
    RETVAL

SV *
version(klass)
    const char *klass
  PREINIT:
    GhosttyString v;
  CODE:
    PERL_UNUSED_VAR(klass);
    if (ghostty_build_info(GHOSTTY_BUILD_INFO_VERSION_STRING, &v) != GHOSTTY_SUCCESS)
        croak("ghostty_build_info failed");
    RETVAL = newSVpvn((const char *)v.ptr, v.len);
  OUTPUT:
    RETVAL
