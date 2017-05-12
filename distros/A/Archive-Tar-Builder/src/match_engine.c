/*-
 * Copyright (c) 2003-2007 Tim Kientzle
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Copyright (c) 2012, cPanel, Inc.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 *
 * Modified for use in Archive::Tar::Builder.
 */

#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "match_line_reader.h"
#include "match_engine.h"
#include "match_path.h"

struct match {
    struct match * next;
    int            matches;
    char           pattern[1];
};

struct lafe_matching {
    struct match * exclusions;
    int            exclusions_count;
    struct match * inclusions;
    int            inclusions_count;
    int            inclusions_unmatched_count;
};

static int                     add_pattern(struct match **list, const char *pattern);
static struct lafe_matching ** initialize_matching(struct lafe_matching **);
static int                     match_exclusion(struct match *, const char *pathname);
static int                     match_inclusion(struct match *, const char *pathname);

/*
 * The matching logic here needs to be re-thought.  I started out to
 * try to mimic gtar's matching logic, but it's not entirely
 * consistent.  In particular 'tar -t' and 'tar -x' interpret patterns
 * on the command line as anchored, but --exclude doesn't.
 */

/*
 * Utility functions to manage exclusion/inclusion patterns
 */

int
lafe_exclude(struct lafe_matching **matching, const char *pattern)
{

    if (*matching == NULL) {
        initialize_matching(matching);
    }

    if (add_pattern(&((*matching)->exclusions), pattern) < 0) {
        return -1;
    }

    (*matching)->exclusions_count++;

    return 0;
}

int
lafe_exclude_from_file(struct lafe_matching **matching, const char *pathname)
{
    struct lafe_line_reader *lr;
    const char *p;
    int ret = 0;

    if ((lr = lafe_line_reader(pathname, 0)) == NULL) {
        return -1;
    }

    while (lafe_line_reader_next(lr, &p) == 0) {
        if (p == NULL) {
            break;
        }

        if (lafe_exclude(matching, p) != 0) {
            ret = -1;
        }
    }

    lafe_line_reader_free(lr);

    return ret;
}

int
lafe_include(struct lafe_matching **matching, const char *pattern)
{

    if (*matching == NULL) {
        initialize_matching(matching);
    }

    if (add_pattern(&((*matching)->inclusions), pattern) < 0) {
        return -1;
    }

    (*matching)->inclusions_count++;
    (*matching)->inclusions_unmatched_count++;

    return 0;
}

int
lafe_include_from_file(struct lafe_matching **matching, const char *pathname,
    int nullSeparator)
{
    struct lafe_line_reader *lr;
    const char *p;
    int ret = 0;

    if ((lr = lafe_line_reader(pathname, nullSeparator)) == NULL) {
        return -1;
    }

    while (lafe_line_reader_next(lr, &p) == 0) {
        if (p == NULL) {
            break;
        }

        if (lafe_include(matching, p) != 0) {
            ret = -1;
        }
    }

    lafe_line_reader_free(lr);

    return ret;
}

static int
add_pattern(struct match **list, const char *pattern)
{
    struct match *match;
    size_t len;

    len   = strlen(pattern);
    match = malloc(sizeof(*match) + len + 1);

    if (match == NULL) {
        return -1;
    }

    strcpy(match->pattern, pattern);

    /* Both "foo/" and "foo" should match "foo/bar". */
    if (len && match->pattern[len - 1] == '/') {
        match->pattern[len - 1] = '\0';
    }

    match->next = *list;
    *list = match;
    match->matches = 0;

    return 0;
}

int
lafe_excluded(struct lafe_matching *matching, const char *pathname)
{
    struct match *match;
    struct match *matched;

    if (matching == NULL) {
        return 0;
    }

    /* Mark off any unmatched inclusions. */
    /* In particular, if a filename does appear in the archive and
     * is explicitly included and excluded, then we don't report
     * it as missing even though we don't extract it.
     */
    matched = NULL;

    for (match = matching->inclusions; match != NULL; match = match->next) {
        if (match->matches == 0 && match_inclusion(match, pathname)) {
            matching->inclusions_unmatched_count--;
            match->matches++;
            matched = match;
        }
    }

    /* Exclusions take priority */
    for (match = matching->exclusions; match != NULL; match = match->next){
        if (match_exclusion(match, pathname)) {
            return 1;
        }
    }

    /* It's not excluded and we found an inclusion above, so it's included. */
    if (matched != NULL) {
        return 0;
    }


    /* We didn't find an unmatched inclusion, check the remaining ones. */
    for (match = matching->inclusions; match != NULL; match = match->next){
        /* We looked at previously-unmatched inclusions already. */
        if (match->matches > 0 && match_inclusion(match, pathname)) {
            match->matches++;

            return 0;
        }
    }

    /* If there were inclusions, default is to exclude. */
    if (matching->inclusions != NULL) {
        return 1;
    }

    /* No explicit inclusions, default is to match. */
    return 0;
}

/*
 * This is a little odd, but it matches the default behavior of
 * gtar.  In particular, 'a*b' will match 'foo/a1111/222b/bar'
 *
 */
static int
match_exclusion(struct match *match, const char *pathname)
{
    return lafe_pathmatch(match->pattern, pathname,
        PATHMATCH_NO_ANCHOR_START | PATHMATCH_NO_ANCHOR_END
    );
}

/*
 * Again, mimic gtar:  inclusions are always anchored (have to match
 * the beginning of the path) even though exclusions are not anchored.
 */
static int
match_inclusion(struct match *match, const char *pathname)
{
    return lafe_pathmatch(match->pattern, pathname, PATHMATCH_NO_ANCHOR_END);
}

void
lafe_cleanup_exclusions(struct lafe_matching **matching)
{
    struct match *p, *q;

    if (*matching == NULL) {
        return;
    }

    for (p = (*matching)->inclusions; p != NULL; ) {
        q = p;
        p = p->next;

        free(q);
    }

    for (p = (*matching)->exclusions; p != NULL; ) {
        q = p;
        p = p->next;

        free(q);
    }

    free(*matching);
    *matching = NULL;
}

static struct lafe_matching **
initialize_matching(struct lafe_matching **matching)
{
    if ((*matching = calloc(sizeof(**matching), 1)) == NULL) {
        return NULL;
    }

    return matching;
}

int
lafe_unmatched_inclusions(struct lafe_matching *matching)
{

    if (matching == NULL) {
        return 0;
    }

    return matching->inclusions_unmatched_count;
}
