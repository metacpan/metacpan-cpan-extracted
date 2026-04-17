MODULE = Chandra    PACKAGE = Chandra::Canvas

PROTOTYPES: DISABLE

BOOT:
{
    _canvas_registry = newHV();
}

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *args = NULL;
    HV *self_hv;
    AV *cmd_buffer;
    HV *handlers;
    char cid_buf[32];
    int cid_len;
    SV **width_svp, **height_svp, **id_svp, **style_svp, **class_svp;
    int width = 800, height = 600;

    /* Parse args hashref */
    if (items > 1 && SvOK(ST(1)) && SvROK(ST(1)) &&
        SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
        args = (HV *)SvRV(ST(1));
    }

    self_hv = newHV();

    /* Generate canvas ID */
    cid_len = snprintf(cid_buf, sizeof(cid_buf), "_canvas_%d", ++_canvas_id);
    (void)hv_stores(self_hv, "_cid", newSVpvn(cid_buf, cid_len));

    /* id — use provided or auto-assign from _cid */
    id_svp = args ? hv_fetchs(args, "id", 0) : NULL;
    if (id_svp && *id_svp && SvOK(*id_svp)) {
        (void)hv_stores(self_hv, "id", newSVsv(*id_svp));
    } else {
        (void)hv_stores(self_hv, "id", newSVpvn(cid_buf, cid_len));
    }

    /* Dimensions */
    width_svp = args ? hv_fetchs(args, "width", 0) : NULL;
    if (width_svp && *width_svp && SvOK(*width_svp))
        width = SvIV(*width_svp);
    (void)hv_stores(self_hv, "width", newSViv(width));

    height_svp = args ? hv_fetchs(args, "height", 0) : NULL;
    if (height_svp && *height_svp && SvOK(*height_svp))
        height = SvIV(*height_svp);
    (void)hv_stores(self_hv, "height", newSViv(height));

    /* Optional style/class */
    style_svp = args ? hv_fetchs(args, "style", 0) : NULL;
    if (style_svp && *style_svp && SvOK(*style_svp))
        (void)hv_stores(self_hv, "style", newSVsv(*style_svp));

    class_svp = args ? hv_fetchs(args, "class", 0) : NULL;
    if (class_svp && *class_svp && SvOK(*class_svp))
        (void)hv_stores(self_hv, "class", newSVsv(*class_svp));

    /* Command buffer */
    cmd_buffer = newAV();
    (void)hv_stores(self_hv, "_buffer", newRV_noinc((SV *)cmd_buffer));

    /* Event handlers */
    handlers = newHV();
    (void)hv_stores(self_hv, "_handlers", newRV_noinc((SV *)handlers));

    /* Frame counter and loop state */
    (void)hv_stores(self_hv, "_frame", newSViv(0));
    (void)hv_stores(self_hv, "_running", newSViv(0));

    /* Register in global registry */
    (void)hv_store(_canvas_registry, cid_buf, cid_len,
                   newRV_inc((SV *)self_hv), 0);

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
                      gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

# ========================================================================
# Accessors
# ========================================================================

int
width(self, ...)
    SV *self
CODE:
{
    HV *self_hv = (HV *)SvRV(self);
    if (items > 1) {
        (void)hv_stores(self_hv, "width", newSViv(SvIV(ST(1))));
    }
    SV **svp = hv_fetchs(self_hv, "width", 0);
    RETVAL = (svp && SvIOK(*svp)) ? SvIV(*svp) : 800;
}
OUTPUT:
    RETVAL

int
height(self, ...)
    SV *self
CODE:
{
    HV *self_hv = (HV *)SvRV(self);
    if (items > 1) {
        (void)hv_stores(self_hv, "height", newSViv(SvIV(ST(1))));
    }
    SV **svp = hv_fetchs(self_hv, "height", 0);
    RETVAL = (svp && SvIOK(*svp)) ? SvIV(*svp) : 600;
}
OUTPUT:
    RETVAL

SV *
id(self)
    SV *self
CODE:
{
    HV *self_hv = (HV *)SvRV(self);
    SV **svp = hv_fetchs(self_hv, "id", 0);
    RETVAL = (svp && SvPOK(*svp)) ? newSVsv(*svp) : newSVpvs("");
}
OUTPUT:
    RETVAL

# ========================================================================
# Style Methods
# ========================================================================

void
fill_style(self, color)
    SV *self
    const char *color
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_1s(aTHX_ buf, CANVAS_OP_FILL_STYLE, color);
    XPUSHs(self);
}

void
stroke_style(self, color)
    SV *self
    const char *color
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_1s(aTHX_ buf, CANVAS_OP_STROKE_STYLE, color);
    XPUSHs(self);
}

void
line_width(self, width)
    SV *self
    NV width
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_1nv(aTHX_ buf, CANVAS_OP_LINE_WIDTH, width);
    XPUSHs(self);
}

void
global_alpha(self, alpha)
    SV *self
    NV alpha
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_1nv(aTHX_ buf, CANVAS_OP_GLOBAL_ALPHA, alpha);
    XPUSHs(self);
}

void
line_cap(self, cap)
    SV *self
    const char *cap
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_1s(aTHX_ buf, CANVAS_OP_LINE_CAP, cap);
    XPUSHs(self);
}

void
line_join(self, join)
    SV *self
    const char *join
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_1s(aTHX_ buf, CANVAS_OP_LINE_JOIN, join);
    XPUSHs(self);
}

# ========================================================================
# Drawing Methods
# ========================================================================

void
clear(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_CLEAR);
    XPUSHs(self);
}

void
fill_rect(self, x, y, w, h)
    SV *self
    NV x
    NV y
    NV w
    NV h
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_4nv(aTHX_ buf, CANVAS_OP_FILL_RECT, x, y, w, h);
    XPUSHs(self);
}

void
stroke_rect(self, x, y, w, h)
    SV *self
    NV x
    NV y
    NV w
    NV h
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_4nv(aTHX_ buf, CANVAS_OP_STROKE_RECT, x, y, w, h);
    XPUSHs(self);
}

void
clear_rect(self, x, y, w, h)
    SV *self
    NV x
    NV y
    NV w
    NV h
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_4nv(aTHX_ buf, CANVAS_OP_CLEAR_RECT, x, y, w, h);
    XPUSHs(self);
}

void
fill_circle(self, x, y, r)
    SV *self
    NV x
    NV y
    NV r
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_3nv(aTHX_ buf, CANVAS_OP_FILL_CIRCLE, x, y, r);
    XPUSHs(self);
}

void
stroke_circle(self, x, y, r)
    SV *self
    NV x
    NV y
    NV r
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_3nv(aTHX_ buf, CANVAS_OP_STROKE_CIRCLE, x, y, r);
    XPUSHs(self);
}

# ========================================================================
# Path Methods
# ========================================================================

void
begin_path(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_BEGIN_PATH);
    XPUSHs(self);
}

void
close_path(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_CLOSE_PATH);
    XPUSHs(self);
}

void
move_to(self, x, y)
    SV *self
    NV x
    NV y
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_2nv(aTHX_ buf, CANVAS_OP_MOVE_TO, x, y);
    XPUSHs(self);
}

void
line_to(self, x, y)
    SV *self
    NV x
    NV y
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_2nv(aTHX_ buf, CANVAS_OP_LINE_TO, x, y);
    XPUSHs(self);
}

void
arc(self, x, y, r, start_angle, end_angle, ...)
    SV *self
    NV x
    NV y
    NV r
    NV start_angle
    NV end_angle
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    NV ccw = (items > 6 && SvTRUE(ST(6))) ? 1 : 0;
    _canvas_push_op_6nv(aTHX_ buf, CANVAS_OP_ARC, x, y, r, start_angle, end_angle, ccw);
    XPUSHs(self);
}

void
rect(self, x, y, w, h)
    SV *self
    NV x
    NV y
    NV w
    NV h
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_4nv(aTHX_ buf, CANVAS_OP_RECT, x, y, w, h);
    XPUSHs(self);
}

void
fill(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_FILL);
    XPUSHs(self);
}

void
stroke(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_STROKE);
    XPUSHs(self);
}

# ========================================================================
# State Methods
# ========================================================================

void
save(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_SAVE);
    XPUSHs(self);
}

void
restore(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_RESTORE);
    XPUSHs(self);
}

# ========================================================================
# Transform Methods
# ========================================================================

void
translate(self, x, y)
    SV *self
    NV x
    NV y
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_2nv(aTHX_ buf, CANVAS_OP_TRANSLATE, x, y);
    XPUSHs(self);
}

void
rotate(self, angle)
    SV *self
    NV angle
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_1nv(aTHX_ buf, CANVAS_OP_ROTATE, angle);
    XPUSHs(self);
}

void
scale(self, x, y)
    SV *self
    NV x
    NV y
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_2nv(aTHX_ buf, CANVAS_OP_SCALE, x, y);
    XPUSHs(self);
}

# ========================================================================
# Phase 2: Advanced Path Methods
# ========================================================================

void
arc_to(self, x1, y1, x2, y2, radius)
    SV *self
    NV x1
    NV y1
    NV x2
    NV y2
    NV radius
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_5nv(aTHX_ buf, CANVAS_OP_ARC_TO, x1, y1, x2, y2, radius);
    XPUSHs(self);
}

void
bezier_curve_to(self, cp1x, cp1y, cp2x, cp2y, x, y)
    SV *self
    NV cp1x
    NV cp1y
    NV cp2x
    NV cp2y
    NV x
    NV y
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_6nv(aTHX_ buf, CANVAS_OP_BEZIER_CURVE_TO, cp1x, cp1y, cp2x, cp2y, x, y);
    XPUSHs(self);
}

void
quadratic_curve_to(self, cpx, cpy, x, y)
    SV *self
    NV cpx
    NV cpy
    NV x
    NV y
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_4nv(aTHX_ buf, CANVAS_OP_QUADRATIC_CURVE_TO, cpx, cpy, x, y);
    XPUSHs(self);
}

void
clip(self, ...)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    AV *cmd = newAV();
    av_push(cmd, newSViv(CANVAS_OP_CLIP));
    /* Optional fill rule: 'nonzero' (default) or 'evenodd' */
    if (items > 1 && SvOK(ST(1))) {
        av_push(cmd, newSVsv(ST(1)));
    }
    av_push(buf, newRV_noinc((SV *)cmd));
    XPUSHs(self);
}

# ========================================================================
# Phase 2: Advanced Transform Methods
# ========================================================================

void
transform(self, a, b, c, d, e, f)
    SV *self
    NV a
    NV b
    NV c
    NV d
    NV e
    NV f
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_6nv(aTHX_ buf, CANVAS_OP_TRANSFORM, a, b, c, d, e, f);
    XPUSHs(self);
}

void
set_transform(self, a, b, c, d, e, f)
    SV *self
    NV a
    NV b
    NV c
    NV d
    NV e
    NV f
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_6nv(aTHX_ buf, CANVAS_OP_SET_TRANSFORM, a, b, c, d, e, f);
    XPUSHs(self);
}

void
reset_transform(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_RESET_TRANSFORM);
    XPUSHs(self);
}

void
miter_limit(self, limit)
    SV *self
    NV limit
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_1nv(aTHX_ buf, CANVAS_OP_MITER_LIMIT, limit);
    XPUSHs(self);
}

void
global_composite_operation(self, op)
    SV *self
    const char *op
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_1s(aTHX_ buf, CANVAS_OP_GLOBAL_COMP_OP, op);
    XPUSHs(self);
}

# ========================================================================
# Phase 2: Convenience Shape Methods
# ========================================================================

void
line(self, x1, y1, x2, y2)
    SV *self
    NV x1
    NV y1
    NV x2
    NV y2
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_4nv(aTHX_ buf, CANVAS_OP_LINE, x1, y1, x2, y2);
    XPUSHs(self);
}

void
rounded_rect(self, x, y, w, h, radius)
    SV *self
    NV x
    NV y
    NV w
    NV h
    NV radius
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_5nv(aTHX_ buf, CANVAS_OP_ROUNDED_RECT, x, y, w, h, radius);
    XPUSHs(self);
}

void
fill_rounded_rect(self, x, y, w, h, radius)
    SV *self
    NV x
    NV y
    NV w
    NV h
    NV radius
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    _canvas_push_op_5nv(aTHX_ buf, CANVAS_OP_FILL_ROUNDED_RECT, x, y, w, h, radius);
    XPUSHs(self);
}

void
polygon(self, points_av)
    SV *self
    SV *points_av
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    AV *points;
    SSize_t len, i;

    if (!SvROK(points_av) || SvTYPE(SvRV(points_av)) != SVt_PVAV)
        croak("polygon requires arrayref of [x,y] pairs");

    points = (AV *)SvRV(points_av);
    len = av_len(points) + 1;

    if (len < 2)
        croak("polygon requires at least 2 points");

    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_BEGIN_PATH);

    for (i = 0; i < len; i++) {
        SV **pt_svp = av_fetch(points, i, 0);
        AV *pt;
        NV x, y;

        if (!pt_svp || !SvROK(*pt_svp) || SvTYPE(SvRV(*pt_svp)) != SVt_PVAV)
            croak("polygon point %ld must be [x,y] arrayref", (long)i);

        pt = (AV *)SvRV(*pt_svp);
        x = SvNV(*av_fetch(pt, 0, 0));
        y = SvNV(*av_fetch(pt, 1, 0));

        if (i == 0) {
            _canvas_push_op_2nv(aTHX_ buf, CANVAS_OP_MOVE_TO, x, y);
        } else {
            _canvas_push_op_2nv(aTHX_ buf, CANVAS_OP_LINE_TO, x, y);
        }
    }

    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_CLOSE_PATH);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_STROKE);
    XPUSHs(self);
}

void
fill_polygon(self, points_av)
    SV *self
    SV *points_av
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    AV *buf = _canvas_get_buffer(aTHX_ self_hv);
    AV *points;
    SSize_t len, i;

    if (!SvROK(points_av) || SvTYPE(SvRV(points_av)) != SVt_PVAV)
        croak("fill_polygon requires arrayref of [x,y] pairs");

    points = (AV *)SvRV(points_av);
    len = av_len(points) + 1;

    if (len < 2)
        croak("fill_polygon requires at least 2 points");

    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_BEGIN_PATH);

    for (i = 0; i < len; i++) {
        SV **pt_svp = av_fetch(points, i, 0);
        AV *pt;
        NV x, y;

        if (!pt_svp || !SvROK(*pt_svp) || SvTYPE(SvRV(*pt_svp)) != SVt_PVAV)
            croak("fill_polygon point %ld must be [x,y] arrayref", (long)i);

        pt = (AV *)SvRV(*pt_svp);
        x = SvNV(*av_fetch(pt, 0, 0));
        y = SvNV(*av_fetch(pt, 1, 0));

        if (i == 0) {
            _canvas_push_op_2nv(aTHX_ buf, CANVAS_OP_MOVE_TO, x, y);
        } else {
            _canvas_push_op_2nv(aTHX_ buf, CANVAS_OP_LINE_TO, x, y);
        }
    }

    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_CLOSE_PATH);
    _canvas_push_op_0(aTHX_ buf, CANVAS_OP_FILL);
    XPUSHs(self);
}

# ========================================================================
# Buffer / Render Methods
# ========================================================================

SV *
_serialize_buffer(self)
    SV *self
CODE:
{
    HV *self_hv = (HV *)SvRV(self);
    RETVAL = _canvas_serialize_buffer(aTHX_ self_hv);
}
OUTPUT:
    RETVAL

void
_clear_buffer(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    _canvas_clear_buffer(aTHX_ self_hv);
    XPUSHs(self);
}

SV *
render(self)
    SV *self
CODE:
{
    HV *self_hv = (HV *)SvRV(self);
    RETVAL = _canvas_gen_html(aTHX_ self_hv);
}
OUTPUT:
    RETVAL

void
flush(self)
    SV *self
PPCODE:
{
    HV *self_hv = (HV *)SvRV(self);
    SV *js = _canvas_serialize_buffer(aTHX_ self_hv);

    /* Call Chandra::eval_js if available */
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Chandra")));
    XPUSHs(sv_2mortal(js));
    PUTBACK;
    call_method("eval_js", G_DISCARD);
    FREETMPS;
    LEAVE;

    /* Clear the buffer */
    _canvas_clear_buffer(aTHX_ self_hv);
    XPUSHs(self);
}
