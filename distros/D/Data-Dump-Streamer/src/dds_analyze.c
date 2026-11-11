#include "dds_engine.h"

/*
 * Breadth-first analysis
 *
 * Scalar slots and their referents have distinct catalogue roles. Queue depths
 * count both visits. Depth buckets choose canonical names at minimum depth
 * before depth-first emission chooses where to construct referents.
 *
 * Seed every root, drain the shallowest pending queue level, then reconcile
 * discovered closure roots. New roots or improved names restart analysis
 * before the catalogue is published.
 */

/* Record a scalar slot's canonical name, depth and alias properties when it
 * may be shared; forced roots are always catalogued.
 */
static void dds_register_slot(pTHX_ dds_ctx *ctx, SV *sv, UV depth, SV *name, UV count, bool force)
{
    dds_node *node;
    dds_role *role;

    if (!force && !dds_candidate(aTHX_ sv))
        return;

    node = dds_find(aTHX_ ctx, sv, TRUE);
    role = &node->slot;
    if (!role->present) {
        SV *clean = dds_clean_name(aTHX_ name);

        role->present = TRUE;
        role->name = newSVsv(clean);
        if (sv_cmp(clean, name))
            role->original = newSVsv(name);
        role->depth = depth;
        role->count = count;
        role->readonly = cBOOL(SvREADONLY(sv));
        role->weak = SvROK(sv) && SvWEAKREF(sv);
    } else {
        const char *old = DDS_PV(role->name), *new_name = DDS_PV(name);

        /* Prefer a direct slot name over an equally deep dereference. */
        if (role->depth == depth && old[0] == '$' &&
            (old[1] == '$' || (old[1] == '{' && old[2] == '$')) &&
            !(new_name[0] == '$' &&
              (new_name[1] == '$' || (new_name[1] == '{' && new_name[2] == '$'))))
            sv_setsv(role->name, name);
    }

    role->encounters++;
}

/* Queue a borrowed value at its traversal depth, owning a copy of its path and
 * retaining the value if callbacks have already been enabled.
 */
static void dds_enqueue(pTHX_ dds_ctx *ctx, SV *sv, UV depth, SV *name, bool direct)
{
    dds_queue_entry *entry;
    dds_queue_level *level;
    UV position = ctx->queue_count;
    bool empty = ctx->queue_head == ctx->queue_count;

    if (ctx->queue_count == ctx->queue_capacity) {
        ctx->queue_capacity = ctx->queue_capacity ? ctx->queue_capacity * 2 : 64;
        Renew(ctx->queue, ctx->queue_capacity, dds_queue_entry);
    }

    entry = &ctx->queue[ctx->queue_count++];
    entry->sv = sv;
    entry->depth = depth;
    entry->name = newSVsv(name);
    entry->direct = direct;
    entry->next = 0;

    if (depth >= ctx->queue_level_capacity) {
        UV old = ctx->queue_level_capacity, capacity = old ? old : 16;

        while (capacity <= depth)
            capacity *= 2;
        Renew(ctx->queue_levels, capacity, dds_queue_level);
        Zero(ctx->queue_levels + old, capacity - old, dds_queue_level);
        ctx->queue_level_capacity = capacity;
    }

    /* Glob slots add a different depth offset from ordinary children.
     * FIFO within each depth keeps first-name ties stable while ensuring
     * that no referent expands before a shorter queued route to it. */
    level = &ctx->queue_levels[depth];
    if (level->tail)
        ctx->queue[level->tail - 1].next = position + 1;
    else
        level->head = position + 1;
    level->tail = position + 1;

    if (empty || depth < ctx->queue_depth)
        ctx->queue_depth = depth;
    if (ctx->queue_count - ctx->queue_head > ctx->queue_peak)
        ctx->queue_peak = ctx->queue_count - ctx->queue_head;

    if (ctx->callbacks)
        av_push(ctx->keepalive, SvREFCNT_inc(sv));
}

/* Remove the next item from the shallowest nonempty depth bucket, preserving
 * FIFO order among paths at that depth.
 */
static UV dds_dequeue(dds_ctx *ctx)
{
    dds_queue_level *level;
    UV position;

    while (!ctx->queue_levels[ctx->queue_depth].head)
        ctx->queue_depth++;
    level = &ctx->queue_levels[ctx->queue_depth];
    position = level->head - 1;
    level->head = ctx->queue[position].next;
    if (!level->head)
        level->tail = 0;
    ctx->queue_head++;

    return position;
}

/* Return the borrowed scalar, hash, array, code or format slot selected from a
 * glob, without creating an absent slot.
 */
static SV *dds_glob_slot(pTHX_ GV *gv, UV slot)
{
    switch (slot) {
    case 0:
        return GvSV(gv);
    case 1:
        return (SV *)GvHV(gv);
    case 2:
        return (SV *)GvAV(gv);
    case 3:
        return (SV *)GvCV(gv);
    case 4:
        return (SV *)GvFORM(gv);
    }
    return NULL;
}

/* Schedule a reference or magical scalar for inspection, or schedule the
 * enabled slots of a directly encountered glob.
 */
static void dds_enqueue_value(pTHX_ dds_ctx *ctx, SV *sv, UV depth, SV *name)
{
    if (SvROK(sv) || SvGMAGICAL(sv))
        dds_enqueue(aTHX_ ctx, sv, depth, name, FALSE);
    else if (SvTYPE(sv) == SVt_PVGV && ctx->style.dumpglob) {
        UV i, limit = ctx->style.deparse && ctx->style.deparseglob ? 5 : 3;
        static const char *slots[] = {"SCALAR", "HASH", "ARRAY", "CODE", "FORMAT"};
        SV *glob_name = dds_glob_name(aTHX_(GV *) sv);

        if (strnEQ(DDS_PV(glob_name), "*Symbol::GEN", 12)) {
            SV *base = dds_underef(aTHX_ name);

            glob_name = dds_child_name(aTHX_ base ? base : name, '*', NULL, 0);
        }

        for (i = 0; i < limit; i++) {
            SV *value = dds_glob_slot(aTHX_(GV *) sv, i);
            SV *path;

            if (!value || (i == 0 && !SvOK(value)))
                continue;

            path = DDS_TEMP(newSVsv(glob_name));
            sv_catpvf(path, "{%s}", slots[i]);
            dds_enqueue(aTHX_ ctx, value, depth + 1, path, TRUE);
        }
    }
}

/* Register a child scalar slot and queue its value using the corresponding
 * path, with scratch values scoped to this visit.
 */
static void dds_analyze_child(pTHX_ dds_ctx *ctx, SV *sv, UV depth, SV *parent, char kind, SV *key,
                              IV child_index)
{
    SV *path;

    ENTER;
    SAVETMPS;
    path = dds_child_name(aTHX_ parent, kind, key, child_index);
    dds_register_slot(aTHX_ ctx, sv, depth + 1, path, SvREFCNT(sv) + dds_weak_count(aTHX_ sv),
                      FALSE);
    dds_enqueue_value(aTHX_ ctx, sv, depth + 2, path);
    FREETMPS;
    LEAVE;
}

#if defined(class_object_to_hash) && defined(PERL_MAGIC_class_storage)
/* Choose a private class-field variable name that does not collide with any
 * current root expression.
 */
static SV *dds_class_fields_name(pTHX_ dds_ctx *ctx)
{
    SV *name = DDS_TEMP(newSV(0));
    bool conflict;

    do {
        UV i;
        const char *identifier;

        conflict = FALSE;
        sv_setpvf(name, "$__DDS_class_fields_%" UVuf, ++ctx->class_serial);
        identifier = DDS_PV(name) + 1;

        for (i = 0; i < ctx->root_count; i++) {
            if (strstr(DDS_PV(ctx->roots[i].name), identifier)) {
                conflict = TRUE;
                break;
            }
        }
    } while (conflict);

    return name;
}

/* Snapshot XPerl class fields into owned metadata and queue that snapshot
 * separately from the object's ordinary payload.
 */
static void dds_analyze_class(pTHX_ dds_ctx *ctx, dds_node *node, SV *target, UV depth)
{
    MAGIC *storage;
    SV *rv;

    if (!SvOBJECT(target) || !SvMAGICAL(target))
        return;
    storage = mg_find(target, PERL_MAGIC_class_storage);
    if (!storage || !storage->mg_obj)
        return;

    /* The snapshot shares field slots with the object. Keep it separate
     * from the public payload so alias fixups finish before hydration. */
    rv = DDS_TEMP(newRV_inc(target));
    node->class_fields = class_object_to_hash(rv);
    (void)hv_delete((HV *)SvRV(node->class_fields), "$self", 5, G_DISCARD);
    node->class_fields_name = newSVsv(dds_class_fields_name(aTHX_ ctx));
    if (strchr("@%&", DDS_PV(node->ref.name)[0]))
        node->class_package = newSVsv(dds_class(aTHX_ target));

    if (ctx->class_tail)
        ctx->class_tail->class_next = node;
    else
        ctx->class_head = node;
    ctx->class_tail = node;

    dds_enqueue(aTHX_ ctx, node->class_fields, depth + 2, node->class_fields_name, FALSE);
}
#endif

/* Test object-address and class-name ignore policies before expanding a
 * referent.
 */
static bool dds_ignored(pTHX_ dds_ctx *ctx, SV *target)
{
    HV *style = dds_hash(aTHX_ ctx->object, "style", FALSE);
    HV *ignore = dds_hash(aTHX_ style, "ignore", FALSE);
    SV *address = DDS_TEMP(newSVpvf("#%" UVuf, PTR2UV(target)));
    SV *class_name = dds_class(aTHX_ target);

    if (SvTRUE(dds_hget_sv(aTHX_ ignore, address)))
        return TRUE;
    if (SvOK(class_name)) {
        SV *key = DDS_TEMP(newSVpvs("."));

        DDS_CAT(key, class_name);
        if (SvTRUE(dds_hget_sv(aTHX_ ignore, key)))
            return TRUE;
    }
    return FALSE;
}

/* Discover a closure's captured variables, choose distinct lexical names and
 * queue their values for graph analysis.
 */
static void dds_collect_lexicals(pTHX_ dds_ctx *ctx, SV *target, HV *lexrefs, HV *names, HV *used)
{
    SV *args[1], *result;
    HV *values;
    HE *he;

    args[0] = DDS_TEMP(newRV_inc(target));
    result = dds_call(aTHX_ ctx, "Data::Dump::Streamer::_get_lexicals", NULL, G_SCALAR, 1, args);
    if (!SvROK(result) || SvTYPE(SvRV(result)) != SVt_PVHV)
        return;

    values = (HV *)SvRV(result);
    hv_iterinit(values);
    while ((he = hv_iternext(values))) {
        SV *name = hv_iterkeysv(he), *rv = HeVAL(he), *address;
        STRLEN len, i;
        const char *p = SvPV(name, len);
        bool numeric = TRUE;

        if (!SvROK(rv))
            continue;

        for (i = 0; i < len; i++)
            if (!isDIGIT_A(p[i])) {
                numeric = FALSE;
                break;
            }
        if (numeric)
            continue;

        address = DDS_TEMP(newSVuv(PTR2UV(SvRV(rv))));
        if (hv_exists_ent(lexrefs, address, 0))
            continue;

        if (hv_exists_ent(used, name, 0)) {
            HV *style = dds_hash(aTHX_ ctx->object, "style", FALSE);
            SV *format = dds_hget(aTHX_ style, "eclipsename");
            SV *args2[3], *new_name;
            UV n = SvUV(dds_hget_sv(aTHX_ used, name)) + 1;

            hv_store_ent(used, name, newSVuv(n), 0);
            args2[0] = name;
            args2[1] = format;
            args2[2] = DDS_TEMP(newSVuv(n));
            new_name = dds_call(aTHX_ ctx, "Data::Dump::Streamer::_xs_eclipse_name", NULL, G_SCALAR,
                                3, args2);
            name = new_name;
        } else
            hv_store_ent(used, name, newSVuv(0), 0);

        hv_store_ent(lexrefs, address, newSVsv(rv), 0);
        hv_store_ent(names, address, newSVsv(name), 0);
        hv_store_ent(ctx->lexical_names, address, newSVsv(name), 0);
        dds_enqueue_value(aTHX_ ctx, rv, 2, name);
    }
}

/* Visit existing array slots, counting all visits but registering and
 * expanding only values that need graph analysis.
 */
static void dds_analyze_array(pTHX_ dds_ctx *ctx, SV *target, UV depth, SV *name)
{
    SSize_t k, last;

    if (SvTIED_mg(target, PERL_MAGIC_tied))
        dds_callback_guard(aTHX_ ctx);
    last = av_len((AV *)target);
    for (k = 0; k <= last; k++) {
        SV **value = av_fetch((AV *)target, k, 0);

        if (!value)
            continue;

        ctx->visits++;
        if (!dds_candidate(aTHX_ * value) && !SvROK(*value) && !SvGMAGICAL(*value) &&
            SvTYPE(*value) != SVt_PVGV)
            continue;
        dds_analyze_child(aTHX_ ctx, *value, depth, name, '[', NULL, k);
    }
}

/* Visit hash values in the selected key order, retaining any thaw action and
 * measuring key widths for later alignment.
 */
static void dds_analyze_hash(pTHX_ dds_ctx *ctx, dds_node *node, SV *target, UV depth, SV *name)
{
    SV *thaw = NULL;
    AV *keys = dds_keys(aTHX_ ctx, (HV *)target, 0, &thaw);
    SSize_t k;
    UV max = 0, sum = 0, count = 0;

    if (thaw) {
        if (!node)
            node = dds_find(aTHX_ ctx, target, TRUE);
        SvREFCNT_dec(node->thaw);
        node->thaw = newSVsv(thaw);
    }

    for (k = 0; k <= av_len(keys); k++) {
        SV **key = av_fetch(keys, k, 0);
        HE *he;
        SV *value;

        if (!key || !SvOK(*key))
            break;
        he = hv_fetch_ent((HV *)target, *key, 0, 0);
        value = he ? HeVAL(he) : &PL_sv_undef;
        ctx->visits++;

        if (ctx->style.indentkeys) {
            STRLEN width;

            ENTER;
            SAVETMPS;
            width = sv_len_utf8(dds_quote(aTHX_ * key, TRUE));
            sum += width;
            if (max < width)
                max = width;
            FREETMPS;
            LEAVE;
        }

        count++;
        if (!dds_candidate(aTHX_ value) && !SvROK(value) && !SvGMAGICAL(value) &&
            SvTYPE(value) != SVt_PVGV)
            continue;
        dds_analyze_child(aTHX_ ctx, value, depth, name, '{', *key, 0);
    }

    if (node) {
        NV avg = count ? (NV)sum / count : 0;

        node->key_width = max > 8 && (2.0 / 3.0 * max) > avg ? (UV)(0.5 + avg) : max;
        node->key_count = count;
    }
}

/* Analyze one queued value in its own temporary scope. Callback guards retain
 * live traversal work before Perl code can mutate the graph. */
static void dds_analyze_entry(pTHX_ dds_ctx *ctx, UV position, UV pass, HV *lexrefs, HV *lexnames,
                              HV *used_names)
{
    dds_queue_entry entry = ctx->queue[position];
    dds_active active;
    SV *target, *name = entry.name;
    UV depth = entry.depth;
    dds_node *node = NULL;
    bool replacement = FALSE;

    ENTER;
    SAVETMPS;

    /* Transfer this queue entry's name to the work-item scope.
     * Nodes and newly queued entries take their own copies. */
    ctx->queue[position].name = NULL;
    DDS_TEMP(name);
    Zero(&active, 1, dds_active);
    active.sv = entry.sv;
    ctx->active = &active;
    ctx->visits++;

    if (strnEQ(DDS_PV(name), "*DB::args", 9) && (DDS_PV(name)[9] == '\0' || DDS_PV(name)[9] == '{'))
        goto entry_done;

    if (SvGMAGICAL(entry.sv)) {
        av_push(ctx->keepalive, SvREFCNT_inc(entry.sv));
        dds_callback_guard(aTHX_ ctx);
        mg_get(entry.sv);
    }

    if (!entry.direct && !SvROK(entry.sv))
        goto entry_done;
    target = entry.direct ? entry.sv : SvRV(entry.sv);
    if (dds_ignored(aTHX_ ctx, target))
        goto entry_done;

    /* Resolve a freezer once per object, then analyze its proxy. */
    if (SvOBJECT(target)) {
        SV *args[1], *frozen;

        node = dds_find(aTHX_ ctx, target, TRUE);
        if (node->frozen)
            goto entry_done;
        node->frozen = TRUE;
        args[0] = entry.direct ? DDS_TEMP(newRV_inc(target)) : entry.sv;
        av_push(ctx->keepalive, SvREFCNT_inc(target));
        frozen = dds_freeze(aTHX_ ctx, args[0]);
        if (SvROK(frozen)) {
            AV *values = (AV *)SvRV(frozen);
            SV **proxy = av_fetch(values, 0, 0);
            SV **thaw = av_fetch(values, 1, 0);
            SV **postop = av_fetch(values, 2, 0);

            if (thaw && SvTRUE(*thaw))
                node->thaw = newSVsv(*thaw);
            if (postop && SvTRUE(*postop))
                node->postop = newSVsv(*postop);

            if (proxy && SvOK(*proxy) && !SvROK(*proxy) && !SvTRUE(*proxy)) {
                node->ignored = TRUE;
                goto entry_done;
            }

            if (proxy && SvOK(*proxy) && (!SvROK(*proxy) || SvRV(*proxy) != target)) {
                node->proxy = newSVsv(*proxy);
                if (!SvROK(*proxy))
                    goto entry_done;
                target = SvRV(*proxy);
                replacement = TRUE;
                node = NULL;
            }
        }
    }

    /* Only possible sharing needs a persistent catalogue entry.
     * A unique ordinary referent can expand without one. */
    if (!node) {
        /* One owned proxy RV can represent several occurrences
         * of the original object, even with referent count one. */
        bool force = replacement || entry.direct || strchr("@%&", DDS_PV(name)[0]) != NULL;

        if (!force && !entry.direct && dds_candidate(aTHX_ entry.sv)) {
            dds_node *slot = dds_find(aTHX_ ctx, entry.sv, FALSE);

            force = slot && slot->slot.original;
        }
        if (force || dds_candidate(aTHX_ target))
            node = dds_find(aTHX_ ctx, target, TRUE);
    }

    if (node) {
        dds_role *role = &node->ref;

        if (role->present) {
            role->encounters++;
            ctx->repeats++;
            goto entry_done;
        }

        role->present = TRUE;
        role->name = newSVsv(name);
        role->depth = depth;
        role->count = SvREFCNT(target) + dds_weak_count(aTHX_ target);
        role->encounters = 1;
        node->expanded = TRUE;
    }

#if defined(class_object_to_hash) && defined(PERL_MAGIC_class_storage)
    if (node)
        dds_analyze_class(aTHX_ ctx, node, target, depth);
#endif

    /* Child slots are one level deeper; their referents add another. */
    if (SvTYPE(target) == SVt_PVAV) {
        dds_analyze_array(aTHX_ ctx, target, depth, name);
    } else if (SvTYPE(target) == SVt_PVHV) {
        dds_analyze_hash(aTHX_ ctx, node, target, depth, name);
    } else if (SvTYPE(target) == SVt_PVCV) {
        if (!pass)
            dds_collect_lexicals(aTHX_ ctx, target, lexrefs, lexnames, used_names);
    } else if (SvTYPE(target) <= SVt_PVMG || SvTYPE(target) == SVt_PVGV) {
        dds_analyze_child(aTHX_ ctx, target, depth, name, '$', NULL, 0);
    }

entry_done:
    ctx->active = NULL;
    FREETMPS;
    LEAVE;
}

/* Match discovered closure values to roots, then prepend any missing
 * roots in lexical order. Return whether names or root membership changed. */
static bool dds_add_lexical_roots(pTHX_ dds_ctx *ctx, HV *lexrefs, HV *lexnames)
{
    AV *add = (AV *)DDS_TEMP((SV *)newAV());
    AV *unames = dds_array(aTHX_ ctx->object, "unames", TRUE);
    HE *he;
    UV i;
    bool again = FALSE;

    hv_iterinit(lexrefs);
    while ((he = hv_iternext(lexrefs))) {
        SV *address = hv_iterkeysv(he), *rv = HeVAL(he);
        SV *lexname = dds_hget_sv(aTHX_ lexnames, address);
        bool found = FALSE;

        hv_store_ent(ctx->lexical_names, address, newSVsv(lexname), 0);
        for (i = 0; i < ctx->root_count; i++) {
            if (ctx->roots[i].sv == SvRV(rv)) {
                SV **user = av_fetch(unames, i, 0);

                found = TRUE;
                if (!user || !SvTRUE(*user)) {
                    const char *p = DDS_PV(lexname);
                    SV *n = DDS_TEMP(newSVpvf("%s%s", p[0] == '$' ? "" : "*", p + 1));

                    av_store(unames, i, newSVsv(n));
                    again = TRUE;
                } else {
                    const char *p = DDS_PV(*user), *old = DDS_PV(lexname);
                    SV *renamed = DDS_TEMP(newSVpvf("%c%s", old[0], p[0] == '*' ? p + 1 : p));

                    hv_store_ent(lexnames, address, newSVsv(renamed), 0);
                }
                break;
            }
        }
        if (!found)
            av_push(add, newSVsv(lexname));
    }

    if (av_len(add) >= 0) {
        UV n = av_len(add) + 1, old_count = ctx->root_count;

        sortsv(AvARRAY(add), n, Perl_sv_cmp);
        Renew(ctx->roots, old_count + n, dds_root);
        Move(ctx->roots, ctx->roots + n, old_count, dds_root);
        Zero(ctx->roots, n, dds_root);
        av_unshift(unames, n);

        for (i = 0; i < n; i++) {
            SV *lexname = *av_fetch(add, i, 0), *rv = NULL;
            const char *p = DDS_PV(lexname);

            hv_iterinit(lexnames);
            while ((he = hv_iternext(lexnames))) {
                if (sv_cmp(HeVAL(he), lexname) == 0) {
                    rv = dds_hget(aTHX_ lexrefs, DDS_PV(hv_iterkeysv(he)));
                    break;
                }
            }

            if (!rv || !SvROK(rv))
                croak("Lost closure root");
            if (SvTYPE(SvRV(rv)) == SVt_PVAV || SvTYPE(SvRV(rv)) == SVt_PVHV ||
                SvTYPE(SvRV(rv)) == SVt_PVCV)
                ctx->roots[i].sv = newSVsv(rv);
            else
                ctx->roots[i].sv = SvREFCNT_inc(SvRV(rv));
            ctx->roots[i].count = SvREFCNT(ctx->roots[i].sv);
            ctx->roots[i].lexical = TRUE;
            av_store(unames, i, newSVpvf("%s%s", p[0] == '$' ? "" : "*", p + 1));
        }

        ctx->root_count = ctx->root_capacity = old_count + n;
        again = TRUE;
    }

    return again;
}

/* Build the breadth-first catalogue of identities, minimum depths and
 * canonical names, repeating when closure discovery adds or renames roots.
 */
void dds_analyze(pTHX_ dds_ctx *ctx)
{
    UV pass = 0, i;
    HV *lexrefs = (HV *)DDS_TEMP((SV *)newHV());
    HV *lexnames = (HV *)DDS_TEMP((SV *)newHV());
    HV *used_names = (HV *)DDS_TEMP((SV *)newHV());
    bool again;

    dds_load_style(aTHX_ ctx);

    do {
        again = FALSE;
        dds_clear_catalogue(aTHX_ ctx);

        /* Seed every root before expanding any referent. */
        for (i = 0; i < ctx->root_count; i++) {
            dds_root *root = &ctx->roots[i];
            SV *name = dds_name(aTHX_ ctx, root->sv, i);

            SvREFCNT_dec(root->name);
            root->name = newSVsv(name);
            root->analyzed_ref = SvROK(root->sv) ? SvRV(root->sv) : NULL;
            dds_register_slot(aTHX_ ctx, root->sv, 1, name, root->count, TRUE);
            dds_enqueue_value(aTHX_ ctx, root->sv, 2, name);
            if (root->lexical)
                hv_store_ent(ctx->lexical_added, name, newSViv(1), 0);
        }

        while (ctx->queue_head < ctx->queue_count)
            dds_analyze_entry(aTHX_ ctx, dds_dequeue(ctx), pass, lexrefs, lexnames, used_names);

        ctx->active = NULL;

        /* Closure discovery may add roots or improve their names. Rebuild
         * the catalogue so those roots participate in minimum-depth naming. */
        if (!pass && HvTOTALKEYS(lexrefs))
            again = dds_add_lexical_roots(aTHX_ ctx, lexrefs, lexnames);

        pass++;
    } while (again && pass < 3);

    /* Publish the closure names used by the Perl deparser facade. */
    {
        HE *he;
        HV *lexicals = dds_hash(aTHX_ ctx->object, "lexicals", TRUE);

        hv_iterinit(lexnames);
        while ((he = hv_iternext(lexnames)))
            hv_store_ent(ctx->lexical_names, hv_iterkeysv(he), newSVsv(HeVAL(he)), 0);
        hv_stores(lexicals, "a2n", newRV_inc((SV *)ctx->lexical_names));
        if (HvTOTALKEYS(ctx->lexical_added))
            hv_stores(lexicals, "added", newRV_inc((SV *)ctx->lexical_added));
    }

    ctx->cataloged = TRUE;
    hv_stores(ctx->object, "cataloged", newSViv(1));
}
