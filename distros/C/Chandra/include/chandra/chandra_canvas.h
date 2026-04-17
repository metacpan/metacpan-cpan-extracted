/*
 * chandra_canvas.h — Canvas module static helpers
 * Included from Chandra.xs before the INCLUDE: xs/canvas.xs
 */

#ifndef CHANDRA_CANVAS_H
#define CHANDRA_CANVAS_H

/* Global canvas registry and counters */
static HV *_canvas_registry = NULL;
static int _canvas_id = 0;

/* ========================================================================
 * Command Buffer Opcodes
 * ======================================================================== */

#define CANVAS_OP_CLEAR           1
#define CANVAS_OP_FILL_STYLE      2
#define CANVAS_OP_STROKE_STYLE    3
#define CANVAS_OP_LINE_WIDTH      4
#define CANVAS_OP_FILL_RECT       5
#define CANVAS_OP_STROKE_RECT     6
#define CANVAS_OP_CLEAR_RECT      7
#define CANVAS_OP_BEGIN_PATH      8
#define CANVAS_OP_CLOSE_PATH      9
#define CANVAS_OP_MOVE_TO         10
#define CANVAS_OP_LINE_TO         11
#define CANVAS_OP_ARC             12
#define CANVAS_OP_FILL            13
#define CANVAS_OP_STROKE          14
#define CANVAS_OP_RECT            15
#define CANVAS_OP_SAVE            16
#define CANVAS_OP_RESTORE         17
#define CANVAS_OP_TRANSLATE       18
#define CANVAS_OP_ROTATE          19
#define CANVAS_OP_SCALE           20
#define CANVAS_OP_GLOBAL_ALPHA    21
#define CANVAS_OP_LINE_CAP        22
#define CANVAS_OP_LINE_JOIN       23
#define CANVAS_OP_FILL_CIRCLE     24
#define CANVAS_OP_STROKE_CIRCLE   25

/* Phase 2: Additional path and transform opcodes */
#define CANVAS_OP_ARC_TO                26
#define CANVAS_OP_BEZIER_CURVE_TO       27
#define CANVAS_OP_QUADRATIC_CURVE_TO    28
#define CANVAS_OP_CLIP                  29
#define CANVAS_OP_TRANSFORM             30
#define CANVAS_OP_SET_TRANSFORM         31
#define CANVAS_OP_RESET_TRANSFORM       32
#define CANVAS_OP_MITER_LIMIT           33
#define CANVAS_OP_GLOBAL_COMP_OP        34
#define CANVAS_OP_LINE                  35
#define CANVAS_OP_ROUNDED_RECT          36
#define CANVAS_OP_FILL_ROUNDED_RECT     37

/* ========================================================================
 * Command Buffer Helpers
 * ======================================================================== */

/* Get or create command buffer from self hashref */
static AV *
_canvas_get_buffer(pTHX_ HV *self)
{
    SV **buf_svp = hv_fetchs(self, "_buffer", 0);
    if (buf_svp && *buf_svp && SvROK(*buf_svp)) {
        return (AV *)SvRV(*buf_svp);
    }
    /* Should not happen if constructed properly */
    croak("Canvas command buffer not initialized");
    return NULL;
}

/* Clear the command buffer */
static void
_canvas_clear_buffer(pTHX_ HV *self)
{
    AV *buf = _canvas_get_buffer(aTHX_ self);
    av_clear(buf);
}

/* Push operation with no args */
static void
_canvas_push_op_0(pTHX_ AV *buf, int op)
{
    AV *cmd = newAV();
    av_push(cmd, newSViv(op));
    av_push(buf, newRV_noinc((SV *)cmd));
}

/* Push operation with 1 string arg */
static void
_canvas_push_op_1s(pTHX_ AV *buf, int op, const char *s)
{
    AV *cmd = newAV();
    av_push(cmd, newSViv(op));
    av_push(cmd, newSVpv(s, 0));
    av_push(buf, newRV_noinc((SV *)cmd));
}

/* Push operation with 1 NV arg */
static void
_canvas_push_op_1nv(pTHX_ AV *buf, int op, NV v)
{
    AV *cmd = newAV();
    av_push(cmd, newSViv(op));
    av_push(cmd, newSVnv(v));
    av_push(buf, newRV_noinc((SV *)cmd));
}

/* Push operation with 2 NV args */
static void
_canvas_push_op_2nv(pTHX_ AV *buf, int op, NV v1, NV v2)
{
    AV *cmd = newAV();
    av_push(cmd, newSViv(op));
    av_push(cmd, newSVnv(v1));
    av_push(cmd, newSVnv(v2));
    av_push(buf, newRV_noinc((SV *)cmd));
}

/* Push operation with 3 NV args */
static void
_canvas_push_op_3nv(pTHX_ AV *buf, int op, NV v1, NV v2, NV v3)
{
    AV *cmd = newAV();
    av_push(cmd, newSViv(op));
    av_push(cmd, newSVnv(v1));
    av_push(cmd, newSVnv(v2));
    av_push(cmd, newSVnv(v3));
    av_push(buf, newRV_noinc((SV *)cmd));
}

/* Push operation with 4 NV args */
static void
_canvas_push_op_4nv(pTHX_ AV *buf, int op, NV v1, NV v2, NV v3, NV v4)
{
    AV *cmd = newAV();
    av_push(cmd, newSViv(op));
    av_push(cmd, newSVnv(v1));
    av_push(cmd, newSVnv(v2));
    av_push(cmd, newSVnv(v3));
    av_push(cmd, newSVnv(v4));
    av_push(buf, newRV_noinc((SV *)cmd));
}

/* Push operation with 5 NV args (for arc_to, rounded_rect) */
static void
_canvas_push_op_5nv(pTHX_ AV *buf, int op, NV v1, NV v2, NV v3, NV v4, NV v5)
{
    AV *cmd = newAV();
    av_push(cmd, newSViv(op));
    av_push(cmd, newSVnv(v1));
    av_push(cmd, newSVnv(v2));
    av_push(cmd, newSVnv(v3));
    av_push(cmd, newSVnv(v4));
    av_push(cmd, newSVnv(v5));
    av_push(buf, newRV_noinc((SV *)cmd));
}

/* Push operation with 6 NV args (for arc) */
static void
_canvas_push_op_6nv(pTHX_ AV *buf, int op, NV v1, NV v2, NV v3, NV v4, NV v5, NV v6)
{
    AV *cmd = newAV();
    av_push(cmd, newSViv(op));
    av_push(cmd, newSVnv(v1));
    av_push(cmd, newSVnv(v2));
    av_push(cmd, newSVnv(v3));
    av_push(cmd, newSVnv(v4));
    av_push(cmd, newSVnv(v5));
    av_push(cmd, newSVnv(v6));
    av_push(buf, newRV_noinc((SV *)cmd));
}

/* ========================================================================
 * JavaScript Code Generation
 * ======================================================================== */

/* Generate JS for a single command */
static void
_canvas_cmd_to_js(pTHX_ SV *js, AV *cmd, const char *ctx)
{
    SV **op_svp = av_fetch(cmd, 0, 0);
    int op;
    SV **v1, **v2, **v3, **v4, **v5, **v6;

    if (!op_svp || !SvIOK(*op_svp)) return;
    op = SvIV(*op_svp);

    switch (op) {
        case CANVAS_OP_CLEAR:
            sv_catpvf(js, "%s.clearRect(0,0,%s.canvas.width,%s.canvas.height);",
                      ctx, ctx, ctx);
            break;

        case CANVAS_OP_FILL_STYLE:
            v1 = av_fetch(cmd, 1, 0);
            if (v1 && SvPOK(*v1))
                sv_catpvf(js, "%s.fillStyle='%s';", ctx, SvPV_nolen(*v1));
            break;

        case CANVAS_OP_STROKE_STYLE:
            v1 = av_fetch(cmd, 1, 0);
            if (v1 && SvPOK(*v1))
                sv_catpvf(js, "%s.strokeStyle='%s';", ctx, SvPV_nolen(*v1));
            break;

        case CANVAS_OP_LINE_WIDTH:
            v1 = av_fetch(cmd, 1, 0);
            if (v1)
                sv_catpvf(js, "%s.lineWidth=%g;", ctx, SvNV(*v1));
            break;

        case CANVAS_OP_GLOBAL_ALPHA:
            v1 = av_fetch(cmd, 1, 0);
            if (v1)
                sv_catpvf(js, "%s.globalAlpha=%g;", ctx, SvNV(*v1));
            break;

        case CANVAS_OP_LINE_CAP:
            v1 = av_fetch(cmd, 1, 0);
            if (v1 && SvPOK(*v1))
                sv_catpvf(js, "%s.lineCap='%s';", ctx, SvPV_nolen(*v1));
            break;

        case CANVAS_OP_LINE_JOIN:
            v1 = av_fetch(cmd, 1, 0);
            if (v1 && SvPOK(*v1))
                sv_catpvf(js, "%s.lineJoin='%s';", ctx, SvPV_nolen(*v1));
            break;

        case CANVAS_OP_FILL_RECT:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            if (v1 && v2 && v3 && v4)
                sv_catpvf(js, "%s.fillRect(%g,%g,%g,%g);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), SvNV(*v4));
            break;

        case CANVAS_OP_STROKE_RECT:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            if (v1 && v2 && v3 && v4)
                sv_catpvf(js, "%s.strokeRect(%g,%g,%g,%g);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), SvNV(*v4));
            break;

        case CANVAS_OP_CLEAR_RECT:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            if (v1 && v2 && v3 && v4)
                sv_catpvf(js, "%s.clearRect(%g,%g,%g,%g);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), SvNV(*v4));
            break;

        case CANVAS_OP_BEGIN_PATH:
            sv_catpvf(js, "%s.beginPath();", ctx);
            break;

        case CANVAS_OP_CLOSE_PATH:
            sv_catpvf(js, "%s.closePath();", ctx);
            break;

        case CANVAS_OP_MOVE_TO:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            if (v1 && v2)
                sv_catpvf(js, "%s.moveTo(%g,%g);", ctx, SvNV(*v1), SvNV(*v2));
            break;

        case CANVAS_OP_LINE_TO:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            if (v1 && v2)
                sv_catpvf(js, "%s.lineTo(%g,%g);", ctx, SvNV(*v1), SvNV(*v2));
            break;

        case CANVAS_OP_ARC:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            v5 = av_fetch(cmd, 5, 0);
            v6 = av_fetch(cmd, 6, 0);
            if (v1 && v2 && v3 && v4 && v5)
                sv_catpvf(js, "%s.arc(%g,%g,%g,%g,%g%s);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3),
                          SvNV(*v4), SvNV(*v5),
                          (v6 && SvTRUE(*v6)) ? ",true" : "");
            break;

        case CANVAS_OP_RECT:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            if (v1 && v2 && v3 && v4)
                sv_catpvf(js, "%s.rect(%g,%g,%g,%g);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), SvNV(*v4));
            break;

        case CANVAS_OP_FILL:
            sv_catpvf(js, "%s.fill();", ctx);
            break;

        case CANVAS_OP_STROKE:
            sv_catpvf(js, "%s.stroke();", ctx);
            break;

        case CANVAS_OP_SAVE:
            sv_catpvf(js, "%s.save();", ctx);
            break;

        case CANVAS_OP_RESTORE:
            sv_catpvf(js, "%s.restore();", ctx);
            break;

        case CANVAS_OP_TRANSLATE:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            if (v1 && v2)
                sv_catpvf(js, "%s.translate(%g,%g);", ctx, SvNV(*v1), SvNV(*v2));
            break;

        case CANVAS_OP_ROTATE:
            v1 = av_fetch(cmd, 1, 0);
            if (v1)
                sv_catpvf(js, "%s.rotate(%g);", ctx, SvNV(*v1));
            break;

        case CANVAS_OP_SCALE:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            if (v1 && v2)
                sv_catpvf(js, "%s.scale(%g,%g);", ctx, SvNV(*v1), SvNV(*v2));
            break;

        case CANVAS_OP_FILL_CIRCLE:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            if (v1 && v2 && v3)
                sv_catpvf(js, "%s.beginPath();%s.arc(%g,%g,%g,0,6.283185307);%s.fill();",
                          ctx, ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), ctx);
            break;

        case CANVAS_OP_STROKE_CIRCLE:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            if (v1 && v2 && v3)
                sv_catpvf(js, "%s.beginPath();%s.arc(%g,%g,%g,0,6.283185307);%s.stroke();",
                          ctx, ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), ctx);
            break;

        /* Phase 2: Additional path and transform operations */
        case CANVAS_OP_ARC_TO:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            v5 = av_fetch(cmd, 5, 0);
            if (v1 && v2 && v3 && v4 && v5)
                sv_catpvf(js, "%s.arcTo(%g,%g,%g,%g,%g);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), SvNV(*v4), SvNV(*v5));
            break;

        case CANVAS_OP_BEZIER_CURVE_TO:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            v5 = av_fetch(cmd, 5, 0);
            v6 = av_fetch(cmd, 6, 0);
            if (v1 && v2 && v3 && v4 && v5 && v6)
                sv_catpvf(js, "%s.bezierCurveTo(%g,%g,%g,%g,%g,%g);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3),
                          SvNV(*v4), SvNV(*v5), SvNV(*v6));
            break;

        case CANVAS_OP_QUADRATIC_CURVE_TO:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            if (v1 && v2 && v3 && v4)
                sv_catpvf(js, "%s.quadraticCurveTo(%g,%g,%g,%g);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), SvNV(*v4));
            break;

        case CANVAS_OP_CLIP:
            v1 = av_fetch(cmd, 1, 0);
            if (v1 && SvPOK(*v1))
                sv_catpvf(js, "%s.clip('%s');", ctx, SvPV_nolen(*v1));
            else
                sv_catpvf(js, "%s.clip();", ctx);
            break;

        case CANVAS_OP_TRANSFORM:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            v5 = av_fetch(cmd, 5, 0);
            v6 = av_fetch(cmd, 6, 0);
            if (v1 && v2 && v3 && v4 && v5 && v6)
                sv_catpvf(js, "%s.transform(%g,%g,%g,%g,%g,%g);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3),
                          SvNV(*v4), SvNV(*v5), SvNV(*v6));
            break;

        case CANVAS_OP_SET_TRANSFORM:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            v5 = av_fetch(cmd, 5, 0);
            v6 = av_fetch(cmd, 6, 0);
            if (v1 && v2 && v3 && v4 && v5 && v6)
                sv_catpvf(js, "%s.setTransform(%g,%g,%g,%g,%g,%g);",
                          ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3),
                          SvNV(*v4), SvNV(*v5), SvNV(*v6));
            break;

        case CANVAS_OP_RESET_TRANSFORM:
            sv_catpvf(js, "%s.resetTransform();", ctx);
            break;

        case CANVAS_OP_MITER_LIMIT:
            v1 = av_fetch(cmd, 1, 0);
            if (v1)
                sv_catpvf(js, "%s.miterLimit=%g;", ctx, SvNV(*v1));
            break;

        case CANVAS_OP_GLOBAL_COMP_OP:
            v1 = av_fetch(cmd, 1, 0);
            if (v1 && SvPOK(*v1))
                sv_catpvf(js, "%s.globalCompositeOperation='%s';", ctx, SvPV_nolen(*v1));
            break;

        case CANVAS_OP_LINE:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            if (v1 && v2 && v3 && v4)
                sv_catpvf(js, "%s.beginPath();%s.moveTo(%g,%g);%s.lineTo(%g,%g);%s.stroke();",
                          ctx, ctx, SvNV(*v1), SvNV(*v2), ctx, SvNV(*v3), SvNV(*v4), ctx);
            break;

        case CANVAS_OP_ROUNDED_RECT:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            v5 = av_fetch(cmd, 5, 0);
            if (v1 && v2 && v3 && v4 && v5)
                sv_catpvf(js, "%s.beginPath();%s.roundRect(%g,%g,%g,%g,%g);%s.stroke();",
                          ctx, ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), SvNV(*v4), SvNV(*v5), ctx);
            break;

        case CANVAS_OP_FILL_ROUNDED_RECT:
            v1 = av_fetch(cmd, 1, 0);
            v2 = av_fetch(cmd, 2, 0);
            v3 = av_fetch(cmd, 3, 0);
            v4 = av_fetch(cmd, 4, 0);
            v5 = av_fetch(cmd, 5, 0);
            if (v1 && v2 && v3 && v4 && v5)
                sv_catpvf(js, "%s.beginPath();%s.roundRect(%g,%g,%g,%g,%g);%s.fill();",
                          ctx, ctx, SvNV(*v1), SvNV(*v2), SvNV(*v3), SvNV(*v4), SvNV(*v5), ctx);
            break;
    }
}

/* Serialize entire buffer to JS string */
static SV *
_canvas_serialize_buffer(pTHX_ HV *self)
{
    AV *buf = _canvas_get_buffer(aTHX_ self);
    SV **id_svp = hv_fetchs(self, "id", 0);
    const char *canvas_id;
    char ctx_var[64];
    SV *js;
    SSize_t i, len;

    if (!id_svp || !SvPOK(*id_svp)) {
        croak("Canvas id not set");
        return &PL_sv_undef;
    }
    canvas_id = SvPV_nolen(*id_svp);

    /* Create context variable name */
    snprintf(ctx_var, sizeof(ctx_var), "_ctx_%s", canvas_id);

    /* Build JS */
    js = newSVpvs("");
    sv_catpvf(js, "(function(){var c=document.getElementById('%s');if(!c)return;var %s=c.getContext('2d');",
              canvas_id, ctx_var);

    len = av_len(buf) + 1;
    for (i = 0; i < len; i++) {
        SV **cmd_svp = av_fetch(buf, i, 0);
        if (cmd_svp && SvROK(*cmd_svp) && SvTYPE(SvRV(*cmd_svp)) == SVt_PVAV) {
            _canvas_cmd_to_js(aTHX_ js, (AV *)SvRV(*cmd_svp), ctx_var);
        }
    }

    sv_catpvs(js, "})();");
    return js;
}

/* Generate canvas element HTML */
static SV *
_canvas_gen_html(pTHX_ HV *self)
{
    SV **id_svp = hv_fetchs(self, "id", 0);
    SV **width_svp = hv_fetchs(self, "width", 0);
    SV **height_svp = hv_fetchs(self, "height", 0);
    SV **style_svp = hv_fetchs(self, "style", 0);
    SV **class_svp = hv_fetchs(self, "class", 0);
    SV *html = newSVpvs("<canvas");
    const char *id;
    int width, height;

    id = (id_svp && SvPOK(*id_svp)) ? SvPV_nolen(*id_svp) : "_canvas_1";
    width = (width_svp && SvIOK(*width_svp)) ? SvIV(*width_svp) : 800;
    height = (height_svp && SvIOK(*height_svp)) ? SvIV(*height_svp) : 600;

    sv_catpvf(html, " id=\"%s\" width=\"%d\" height=\"%d\"", id, width, height);

    if (style_svp && SvPOK(*style_svp))
        sv_catpvf(html, " style=\"%s\"", SvPV_nolen(*style_svp));

    if (class_svp && SvPOK(*class_svp))
        sv_catpvf(html, " class=\"%s\"", SvPV_nolen(*class_svp));

    sv_catpvs(html, "></canvas>");
    return html;
}

#endif /* CHANDRA_CANVAS_H */
