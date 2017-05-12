package B::Hooks::OP::Annotation;

use 5.008000;

use strict;
use warnings;

use base qw(DynaLoader);

our $VERSION = '0.44';

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;

__END__

=head1 NAME

B::Hooks::OP::Annotation - annotate and delegate hooked OPs

=head1 SYNOPSIS

    #include "hook_op_check.h"
    #include "hook_op_annotation.h"

    STATIC OPAnnotationGroup MYMODULE_ANNOTATIONS;

    STATIC void mymodule_mydata_free(pTHX_ void *mydata) {
        // ...
    }

    STATIC OP * mymodule_check_entersub(pTHX_ OP *op, void *unused) {
        MyData * mydata;

        mydata = mymodule_get_mydata(); /* metadata to be associated with this OP */
        op_annotate(MYMODULE_ANNOTATIONS, op, mydata, mymodule_mydata_free);
        op->op_ppaddr = mymodule_entersub;

        return op;
    }

    STATIC OP * mymodule_entersub(pTHX) {
        OPAnnotation * annotation;
        MyData * mydata;
        OP *op = PL_op;

        annotation = op_annotation_get(MYMODULE_ANNOTATIONS, op);
        mydata = (MyData *)annotation->data;

        // ...

        if (ok) {
            return NORMAL;
        } else if (mymodule_stop_hooking(op)) { /* restore the previous op_ppaddr */
            op->op_ppaddr = annotation->op_ppaddr;
            op_annotation_delete(MYMODULE_ANNOTATIONS, op);
            return op->op_ppaddr(aTHX);
        } else {
            return annotation->op_ppaddr(aTHX); /* delegate to the previous op_ppaddr */
        }
    }

    MODULE = mymodule PACKAGE = mymodule

    BOOT:
        MYMODULE_ANNOTATIONS = op_annotation_group_new();

    void
    END()
        CODE:
            op_annotation_group_free(aTHX_ MYMODULE_ANNOTATIONS);

    void
    setup()
        CODE:
            mymodule_hook_op_entersub_id = hook_op_check(
                OP_ENTERSUB,
                mymodule_check_entersub,
                NULL
            );

    void
    teardown()
        CODE:
            hook_op_check_remove(OP_ENTERSUB, mymodule_hook_op_entersub_id);

=head1 DESCRIPTION

This module provides a way for XS code that hijacks OP C<op_ppaddr> functions to delegate to (or restore) the previous
functions, whether assigned by perl or by another module. Typically this should be used in conjunction with
L<B::Hooks::OP::Check|B::Hooks::OP::Check>.

C<B::Hooks::OP::Annotation> makes its types and functions available to XS code by means of
L<ExtUtils::Depends|ExtUtils::Depends>. Modules that wish to use these exports in their XS code should
C<use B::OP::Hooks::Annotation> in the Perl module that loads the XS, and include something like the
following in their Makefile.PL:

    use ExtUtils::MakeMaker;
    use ExtUtils::Depends;

    our %XS_PREREQUISITES = (
        'B::Hooks::OP::Annotation' => '0.44',
        'B::Hooks::OP::Check'      => '0.15',
    );

    our %XS_DEPENDENCIES = ExtUtils::Depends->new(
        'Your::XS::Module',
         keys(%XS_PREREQUISITES)
    )->get_makefile_vars();

    WriteMakefile(
        NAME          => 'Your::XS::Module',
        VERSION_FROM  => 'lib/Your/XS/Module.pm',
        PREREQ_PM => {
            'B::Hooks::EndOfScope' => '0.07',
            %XS_PREREQUISITES
        },
        ($ExtUtils::MakeMaker::VERSION >= 6.46 ?
            (META_MERGE => {
                configure_requires => {
                    'ExtUtils::Depends' => '0.301',
                    %XS_PREREQUISITES
                }})
            : ()
        ),
        %XS_DEPENDENCIES,
        # ...
    );

=head2 TYPES

=head3 OPAnnotation

This struct contains the metadata associated with a particular OP i.e. the data itself, a destructor
for that data, and the C<op_ppaddr> function that was defined when the annotation was created
by L<"op_annotate"> or L<"op_annotation_new">.

=over

=item * C<op_ppaddr>, the OP's previous C<op_ppaddr> function (of type L<"OPAnnotationPPAddr">)

=item * C<data>, a C<void *> to metadata that should be associated with the OP

=item * C<dtor>, a function (of type L<"OPAnnotationDtor">) used to free the metadata

=back

The fields are all read/write and can be modified after the annotation has been created.

=head3 OPAnnotationGroup

Annotations are stored in groups. Multiple groups can be created, and each one manages
all of the annotations associated with it.

Annotations can be removed from the group and freed by calling L<"op_annotation_delete">,
and the group and all its members can be destroyed by calling L<"op_annotation_group_free">.

=head3 OPAnnotationPPAddr

This typedef corresponds to the type of perl's C<op_ppaddr> functions i.e.

    typedef  OP *(*OPAnnotationPPAddr)(pTHX);

=head3 OPAnnotationDtor

This is the typedef for the destructor used to free the metadata associated with the OP.

    typedef void (*OPAnnotationDtor)(pTHX_ void *data);

=head2 FUNCTIONS

=head3 op_annotation_new

This function creates and returns a new OP annotation.

It takes an L<"OPAnnotationGroup">, an OP, a pointer to the metadata to be associated with the OP,
and a destructor for that data. The data can be NULL and the destructor can be NULL if no cleanup is required.

If an annotation has already been assigned for the OP, then it is replaced by the new annotation, and the
old annotation is freed, triggering the destruction of its data (if supplied) by its
destructor (if supplied).

    OPAnnotation * op_annotation_new(
        OPAnnotationGroup group,
        OP *op,
        void *data,
        OPAnnotationDtor dtor
    );

=head3 op_annotate

This function is a void version of L<"op_annotation_new"> for cases where the new annotation is
not needed.

    void op_annotate(
        OPAnnotationGroup group,
        OP *op,
        void *data,
        OPAnnotationDtor dtor
    );

=head3 op_annotation_get

This retrieves the annotation associated with the supplied OP. If an annotation has not been
assigned for the OP, it raises a fatal exception.

    OPAnnotation * op_annotation_get(OPAnnotationGroup group, OP *op);

=head3 op_annotation_delete

This removes the specified annotation from the group and frees its memory. If a destructor was supplied,
it is called on the value in the C<data> field (if supplied).

    void op_annotation_delete(pTHX_ OPAnnotationGroup group, OP *op);

=head3 op_annotation_group_new

This function creates a new annotation group.

    OPAnnotationGroup op_annotation_group_new(void);

=head3 op_annotation_group_free

This function destroys the annotations in an annotation group and frees the memory allocated for the group.

    void op_annotation_group_free(pTHX_ OPAnnotationGroup group);

=head1 EXPORT

None by default.

=head1 VERSION

0.44

=head1 SEE ALSO

=over

=item * L<B::Hooks::OP::Check|B::Hooks::OP::Check>

=item * L<B::Hooks::OP::PPAddr|B::Hooks::OP::PPAddr>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2011 chocolateboy

This module is free software.

You may distribute this code under the same terms as Perl itself.

=cut
