MODULE = Chandra    PACKAGE = Chandra::Clipboard
PROTOTYPES: DISABLE

SV *
get_text(class)
    const char *class
CODE:
{
    char *text = chandra_clipboard_get_text(aTHX);
    if (text) {
        RETVAL = newSVpv(text, 0);
        SvUTF8_on(RETVAL);
        safefree(text);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

int
set_text(class, text_sv)
    const char *class
    SV *text_sv
CODE:
{
    STRLEN len;
    const char *text = SvPV(text_sv, len);
    RETVAL = chandra_clipboard_set_text(aTHX_ text, len);
}
OUTPUT:
    RETVAL

int
has_text(class)
    const char *class
CODE:
{
    RETVAL = chandra_clipboard_has_text(aTHX);
}
OUTPUT:
    RETVAL

SV *
get_html(class)
    const char *class
CODE:
{
    char *html = chandra_clipboard_get_html(aTHX);
    if (html) {
        RETVAL = newSVpv(html, 0);
        SvUTF8_on(RETVAL);
        safefree(html);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

int
set_html(class, html_sv)
    const char *class
    SV *html_sv
CODE:
{
    STRLEN len;
    const char *html = SvPV(html_sv, len);
    RETVAL = chandra_clipboard_set_html(aTHX_ html, len);
}
OUTPUT:
    RETVAL

int
has_html(class)
    const char *class
CODE:
{
    RETVAL = chandra_clipboard_has_html(aTHX);
}
OUTPUT:
    RETVAL

SV *
get_image(class)
    const char *class
CODE:
{
    RETVAL = chandra_clipboard_get_image(aTHX);
}
OUTPUT:
    RETVAL

int
set_image(class, path_sv)
    const char *class
    SV *path_sv
CODE:
{
    const char *path = SvPV_nolen(path_sv);
    RETVAL = chandra_clipboard_set_image(aTHX_ path);
}
OUTPUT:
    RETVAL

int
has_image(class)
    const char *class
CODE:
{
    RETVAL = chandra_clipboard_has_image(aTHX);
}
OUTPUT:
    RETVAL

void
clear(class)
    const char *class
CODE:
{
    chandra_clipboard_clear(aTHX);
}
