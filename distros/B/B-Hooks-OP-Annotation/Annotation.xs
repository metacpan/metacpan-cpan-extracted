#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "hook_op_annotation.h"

#define __PACKAGE__ "B::Hooks::OP::Annotation"
#include "optable.h"

#define OP_ANNOTATION_INITIAL_SIZE 2
#define OP_ANNOTATION_THRESHOLD 0.65

STATIC void op_annotation_free(pTHX_ OPAnnotation *annotation);

void op_annotate(OPAnnotationGroup table, OP * op, void *data, OPAnnotationDtor dtor) {
    (void)op_annotation_new(table, op, data, dtor);
}

/* the data and/or destructor can be assigned later */
OPAnnotation * op_annotation_new(OPAnnotationGroup table, OP * op, void *data, OPAnnotationDtor dtor) {
    OPAnnotation *annotation, *old;

    if (!table) {
        croak("B::Hooks::OP::Annotation: no annotation group supplied");
    }

    if (!op) {
        croak("B::Hooks::OP::Annotation: no OP supplied");
    }

    Newx(annotation, 1, OPAnnotation);

    if (!annotation) {
        croak("B::Hooks::OP::Annotation: can't allocate annotation");
    }

    annotation->data = data;
    annotation->dtor = dtor;
    annotation->op_ppaddr = op->op_ppaddr;

    old = OPTable_store(table, op, annotation);

    if (old) {
        op_annotation_free(aTHX_ old);
    }

    return annotation;
}

/* get the annotation for the current OP from the hash table */
OPAnnotation *op_annotation_get(OPAnnotationGroup table, OP *op) {
    OPAnnotation *annotation;

    if (!table) {
        croak("B::Hooks::OP::Annotation: no annotation group supplied");
    }

    if (!op) {
        croak("B::Hooks::OP::Annotation: no OP supplied");
    }

    annotation = OPTable_fetch(table, op);

    if (!annotation) {
         croak("can't retrieve annotation: OP not found");
    }

    return annotation;
}

void op_annotation_delete(pTHX_ OPAnnotationGroup table, OP *op) {
    OPAnnotation *annotation;

    if (!table) {
        croak("B::Hooks::OP::Annotation: no annotation group supplied");
    }

    annotation = OPTable_delete(table, op);

    if (!annotation) {
        croak("B::Hooks::OP::Annotation: can't delete annotation: OP not found");
    }

    op_annotation_free(aTHX_ annotation);
}

STATIC void op_annotation_free(pTHX_ OPAnnotation *annotation) {
    if (!annotation) {
        croak("B::Hooks::OP::Annotation: no annotation supplied");
    }

    if (annotation->data && annotation->dtor) {
        annotation->dtor(aTHX_ annotation->data);
    }

    Safefree(annotation);
}

OPAnnotationGroup op_annotation_group_new() {
    OPAnnotationGroup table;

    table = OPTable_new(OP_ANNOTATION_INITIAL_SIZE, OP_ANNOTATION_THRESHOLD);

    if (!table) {
        croak("B::Hooks::OP::Annotation: can't allocate annotation group");
    }

    return table;
}

void op_annotation_group_free(pTHX_ OPAnnotationGroup table) {
    if (!table) {
        croak("B::Hooks::OP::Annotation: no annotation group supplied");
    }

    OPTable_clear(aTHX_ table, op_annotation_free);
    OPTable_free(table);
}

MODULE = B::Hooks::OP::Annotation                PACKAGE = B::Hooks::OP::Annotation

PROTOTYPES: DISABLE
