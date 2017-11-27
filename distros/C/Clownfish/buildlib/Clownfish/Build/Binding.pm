# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
package Clownfish::Build::Binding;
use strict;
use warnings;

our $VERSION = '0.006002';
$VERSION = eval $VERSION;

sub bind_all {
    my $class = shift;
    $class->bind_clownfish;
    $class->bind_test;
    $class->bind_test_host;
    $class->bind_blob;
    $class->bind_boolean;
    $class->bind_bytebuf;
    $class->bind_charbuf;
    $class->bind_string;
    $class->bind_stringiterator;
    $class->bind_err;
    $class->bind_hash;
    $class->bind_hashiterator;
    $class->bind_float;
    $class->bind_integer;
    $class->bind_obj;
    $class->bind_vector;
    $class->bind_class;
}

sub bind_clownfish {
    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish    PACKAGE = Clownfish

SV*
to_clownfish(sv)
    SV *sv;
CODE:
{
    cfish_Obj *obj = XSBind_perl_to_cfish_nullable(aTHX_ sv, CFISH_OBJ);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(obj);
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Clownfish",
        class_name => "Clownfish",
    );
    $binding->append_xs($xs_code);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_test {
    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish::Test   PACKAGE = Clownfish::Test

SV*
create_test_suite()
CODE:
    cfish_TestSuite *suite = testcfish_Test_create_test_suite();
    RETVAL = CFISH_OBJ_TO_SV_NOINC(suite);
OUTPUT: RETVAL

void
invoke_to_string(obj)
    cfish_Obj *obj;
PPCODE:
    cfish_String *str = CFISH_Obj_To_String(obj);
    CFISH_DECREF(str);

int
refcount(obj)
    cfish_Obj *obj;
CODE:
    RETVAL = (int)CFISH_REFCOUNT_NN(obj);
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "TestClownfish",
        class_name => "Clownfish::Test",
    );
    $binding->append_xs($xs_code);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_test_host {
    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Test::TestHost",
    );
    $binding->bind_method(
        alias  => 'perl_alias',
        method => 'Aliased',
    );
    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_blob {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $blob = Clownfish::Blob->new($byte_string);
    my $byte_string = $blob->to_perl;
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
=head2 new

    my $blob = Clownfish::Blob->new($byte_string);

Create a Blob containing the passed-in bytes.
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( pod => $constructor );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish     PACKAGE = Clownfish::Blob

SV*
new(either_sv, sv)
    SV *either_sv;
    SV *sv;
CODE:
{
    STRLEN size;
    char *ptr = SvPV(sv, size);
    cfish_Blob *self
        = (cfish_Blob*)XSBind_new_blank_obj(aTHX_ either_sv);
    cfish_Blob_init(self, ptr, size);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(self);
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Blob",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->append_xs($xs_code);
    $binding->exclude_constructor;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_boolean {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    use Clownfish::Boolean qw( $true_singleton $false_singleton );

    my $bool = Clownfish::Boolean->singleton($truth_value);
    my $truth_value = $bool->get_value;

    if ($bool->equals($true_singleton)) {
        print "true\n";
    }
END_SYNOPSIS
    my $description = <<'END_DESCRIPTION';
There are only two singleton instances of this class: C<$true_singleton> and
C<$false_singleton> which are exported on demand.
END_DESCRIPTION
    my $constructor = <<'END_CONSTRUCTOR';
=head2 singleton

    my $bool = Clownfish::Boolean->singleton($truth_value);

Return either C<$true_singleton> or C<$false_singleton> depending on the
supplied value.
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->set_description($description);
    $pod_spec->add_constructor( pod => $constructor );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish   PACKAGE = Clownfish::Boolean

SV*
singleton(either_sv, value)
    SV      *either_sv;
    bool     value;
CODE:
{
    CFISH_UNUSED_VAR(either_sv);
    RETVAL = CFISH_OBJ_TO_SV_INC(cfish_Bool_singleton(value));
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Boolean",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->append_xs($xs_code);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_bytebuf {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $buf = Clownfish::ByteBuf->new($byte_string);
    my $byte_string = $buf->to_perl;
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
=head2 new

    my $buf = Clownfish::ByteBuf->new($byte_string);

Create a ByteBuf containing the passed-in bytes.
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( pod => $constructor );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish     PACKAGE = Clownfish::ByteBuf

SV*
new(either_sv, sv)
    SV *either_sv;
    SV *sv;
CODE:
{
    STRLEN size;
    char *ptr = SvPV(sv, size);
    cfish_ByteBuf *self
        = (cfish_ByteBuf*)XSBind_new_blank_obj(aTHX_ either_sv);
    cfish_BB_init_bytes(self, ptr, size);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(self);
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::ByteBuf",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->append_xs($xs_code);
    $binding->exclude_constructor;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_charbuf {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $buf = Clownfish::CharBuf->new;
    $buf->cat('abc');
    $buf->cat_char(ord("\n"));
    print $buf->to_string;
END_SYNOPSIS
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor();

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::CharBuf",
    );
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_string {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $string = Clownfish::String->new('abc');
    print $string->to_perl, "\n";
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
=head2 new

    my $string = Clownfish::String->new($perl_string);

Return a String containing the passed-in Perl string.
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( pod => $constructor );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish     PACKAGE = Clownfish::String

SV*
new(either_sv, sv)
    SV *either_sv;
    SV *sv;
CODE:
{
    STRLEN size;
    char *ptr = SvPVutf8(sv, size);
    cfish_String *self = (cfish_String*)XSBind_new_blank_obj(aTHX_ either_sv);
    cfish_Str_init_from_trusted_utf8(self, ptr, size);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(self);
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::String",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->append_xs($xs_code);
    $binding->exclude_constructor;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_stringiterator {
    my @hand_rolled = qw(
        Next
        Prev
    );

    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $iter = $string->top;
    while (my $code_point = $iter->next) {
        ...
    }
END_SYNOPSIS
    my $next_pod = <<'END_POD';
=head2 next

    my $code_point = $iter->next;

Return the code point after the current position and advance the
iterator. Returns undef at the end of the string. Returns zero
but true for U+0000.
END_POD
    my $prev_pod = <<'END_POD';
=head2 prev

    my $code_point = $iter->prev;

Return the code point before the current position and go one step back.
Returns undef at the start of the string. Returns zero but true for
U+0000.
END_POD
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_method(
        method => 'Next',
        alias  => 'next',
        pod    => $next_pod,
    );
    $pod_spec->add_method(
        method => 'Prev',
        alias  => 'prev',
        pod    => $prev_pod,
    );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish   PACKAGE = Clownfish::StringIterator

SV*
next(self)
    cfish_StringIterator *self;
CODE:
{
    int32_t cp = CFISH_StrIter_Next(self);

    if (cp == CFISH_STR_OOB) {
        RETVAL = &PL_sv_undef;
    }
    else if (cp == 0) {
        /* Zero but true. */
        RETVAL = newSVpvn("0e0", 3);
    }
    else {
        RETVAL = newSViv(cp);
    }
}
OUTPUT: RETVAL

SV*
prev(self)
    cfish_StringIterator *self;
CODE:
{
    int32_t cp = CFISH_StrIter_Prev(self);

    if (cp == CFISH_STR_OOB) {
        RETVAL = &PL_sv_undef;
    }
    else if (cp == 0) {
        /* Zero but true. */
        RETVAL = newSVpvn("0e0", 3);
    }
    else {
        RETVAL = newSViv(cp);
    }
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::StringIterator",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->exclude_method($_) for @hand_rolled;
    $binding->append_xs($xs_code);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_err {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    package MyErr;
    use base qw( Clownfish::Err );
    
    ...
    
    package main;
    use Scalar::Util qw( blessed );
    while (1) {
        eval {
            do_stuff() or MyErr->throw("retry");
        };
        if ( blessed($@) and $@->isa("MyErr") ) {
            warn "Retrying...\n";
        }
        else {
            # Re-throw.
            die "do_stuff() died: $@";
        }
    }
END_SYNOPSIS
    $pod_spec->set_synopsis($synopsis);

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish    PACKAGE = Clownfish::Err

SV*
trap(routine_sv, context_sv)
    SV *routine_sv;
    SV *context_sv;
CODE:
    cfish_Err *error = XSBind_trap(routine_sv, context_sv);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(error);
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Err",
    );
    $binding->bind_constructor( alias => '_new' );
    $binding->set_pod_spec($pod_spec);
    $binding->append_xs($xs_code);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_hash {
    my @hand_rolled = qw(
        Store
    );

    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $hash = Clownfish::Hash->new;
    $hash->store($key, $value);
    my $value = $hash->fetch($key);
END_SYNOPSIS
    my $store_pod = <<'END_POD';
=head2 store

    $hash->store($key, $value);

Store a key-value pair.
END_POD
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor();
    $pod_spec->add_method(
        method => 'Store',
        alias  => 'store',
        pod    => $store_pod,
    );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish    PACKAGE = Clownfish::Hash
SV*
fetch_raw(self, key)
    cfish_Hash *self;
    cfish_String *key;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_INC(CFISH_Hash_Fetch(self, key));
OUTPUT: RETVAL

void
store(self, key, value_sv);
    cfish_Hash         *self;
    cfish_String *key;
    SV           *value_sv;
PPCODE:
{
    cfish_Obj *value
        = (cfish_Obj*)XSBind_perl_to_cfish_nullable(aTHX_ value_sv, CFISH_OBJ);
    CFISH_Hash_Store(self, key, value);
}
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Hash",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->exclude_method($_) for @hand_rolled;
    $binding->append_xs($xs_code);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_hashiterator {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $iter = Clownfish::HashIterator->new($hash);
    while ($iter->next) {
        my $key   = $iter->get_key;
        my $value = $iter->get_value;
    }
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $iter = Clownfish::HashIterator->new($hash);
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( sample => $constructor );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish   PACKAGE = Clownfish::HashIterator

SV*
new(either_sv, hash)
    SV         *either_sv;
    cfish_Hash *hash;
CODE:
{
    cfish_HashIterator *self
        = (cfish_HashIterator*)XSBind_new_blank_obj(aTHX_ either_sv);
    cfish_HashIter_init(self, hash);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(self);
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::HashIterator",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->append_xs($xs_code);
    $binding->exclude_constructor;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_float {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $float = Clownfish::Float->new(2.5);
    my $value = $float->get_value;
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $float = Clownfish::Float->new($value);
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( sample => $constructor );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish   PACKAGE = Clownfish::Float

SV*
new(either_sv, value)
    SV     *either_sv;
    double  value;
CODE:
{
    cfish_Float *self
        = (cfish_Float*)XSBind_new_blank_obj(aTHX_ either_sv);
    cfish_Float_init(self, value);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(self);
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Float",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->append_xs($xs_code);
    $binding->exclude_constructor;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_integer {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $integer = Clownfish::Integer->new(7);
    my $value = $integer->get_value;
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $integer = Clownfish::Integer->new($value);
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( sample => $constructor );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish   PACKAGE = Clownfish::Integer

SV*
new(either_sv, value)
    SV      *either_sv;
    int64_t  value;
CODE:
{
    cfish_Integer *self
        = (cfish_Integer*)XSBind_new_blank_obj(aTHX_ either_sv);
    cfish_Int_init(self, value);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(self);
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Integer",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->append_xs($xs_code);
    $binding->exclude_constructor;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_obj {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    package MyObj;
    use base qw( Clownfish::Obj );
    
    # Inside-out member var.
    my %foo;
    
    sub new {
        my ( $class, %args ) = @_;
        my $foo = delete $args{foo};
        my $self = $class->SUPER::new(%args);
        $foo{$$self} = $foo;
        return $self;
    }
    
    sub get_foo {
        my $self = shift;
        return $foo{$$self};
    }
    
    sub DESTROY {
        my $self = shift;
        delete $foo{$$self};
        $self->SUPER::DESTROY;
    }
END_SYNOPSIS
    my $description = <<'END_DESCRIPTION';
Clownfish::Obj is the base class of the Clownfish object hierarchy.

From the standpoint of a Perl programmer, all classes are implemented as
blessed scalar references, with the scalar storing a pointer to a C struct.

=head2 Subclassing

The recommended way to subclass Clownfish::Obj and its descendants is
to use the inside-out design pattern.  (See L<Class::InsideOut> for an
introduction to inside-out techniques.)

Since the blessed scalar stores a C pointer value which is unique per-object,
C<$$self> can be used as an inside-out ID.

    # Accessor for 'foo' member variable.
    sub get_foo {
        my $self = shift;
        return $foo{$$self};
    }


Caveats:

=over

=item *

Inside-out aficionados will have noted that the "cached scalar id" stratagem
recommended above isn't compatible with ithreads.

=item *

Overridden methods must not return undef unless the API specifies that
returning undef is permissible.

=back

=head1 CONSTRUCTOR

=head2 new

    my $self = $class->SUPER::new;

Abstract constructor -- must be invoked via a subclass.  Attempting to
instantiate objects of class "Clownfish::Obj" directly causes an
error.

Takes no arguments; if any are supplied, an error will be reported.
END_DESCRIPTION
    my $to_perl_pod = <<'END_POD';
=head2 to_perl

    my $native = $obj->to_perl;

Tries to convert the object to its native Perl representation.
END_POD
    my $destroy_pod = <<'END_POD';
=head2 DESTROY

All Clownfish classes implement a DESTROY method; if you override it in a
subclass, you must call C<< $self->SUPER::DESTROY >> to avoid leaking memory.
END_POD
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->set_description($description);
    $pod_spec->add_method(
        alias  => 'to_perl',
        pod    => $to_perl_pod,
    );
    $pod_spec->add_method(
        method => 'Destroy',
        alias  => 'DESTROY',
        pod    => $destroy_pod,
    );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish     PACKAGE = Clownfish::Obj

SV*
get_class(self)
    cfish_Obj *self
CODE:
    cfish_Class *klass = cfish_Obj_get_class(self);
    RETVAL = (SV*)CFISH_Class_To_Host(klass, NULL);
OUTPUT: RETVAL

SV*
get_class_name(self)
    cfish_Obj *self
CODE:
    cfish_String *class_name = cfish_Obj_get_class_name(self);
    RETVAL = (SV*)CFISH_Str_To_Host(class_name, NULL);
OUTPUT: RETVAL

bool
is_a(self, class_name)
    cfish_Obj *self;
    cfish_String *class_name;
CODE:
{
    cfish_Class *target = cfish_Class_fetch_class(class_name);
    RETVAL = cfish_Obj_is_a(self, target);
}
OUTPUT: RETVAL

SV*
clone_raw(self)
    cfish_Obj *self;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_NOINC(CFISH_Obj_Clone(self));
OUTPUT: RETVAL

SV*
to_perl(self)
    cfish_Obj *self;
CODE:
    RETVAL = (SV*)CFISH_Obj_To_Host(self, NULL);
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Obj",
    );
    $binding->bind_method(
        alias  => 'DESTROY',
        method => 'Destroy',
    );
    $binding->append_xs($xs_code);
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_vector {
    my @hand_rolled = qw(
        Store
    );

    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $vector = Clownfish::Vector->new;
    $vector->store($tick, $value);
    my $value = $vector->fetch($tick);
END_SYNOPSIS
    my $store_pod = <<'END_POD';
=head2 store

    $vector->store($tick, $elem)

Store an element at index C<tick>, possibly displacing an existing element.
END_POD
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor();
    $pod_spec->add_method(
        method => 'Store',
        alias  => 'store',
        pod    => $store_pod,
    );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish   PACKAGE = Clownfish::Vector

SV*
pop_raw(self)
    cfish_Vector *self;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_NOINC(CFISH_Vec_Pop(self));
OUTPUT: RETVAL

SV*
delete_raw(self, tick)
    cfish_Vector *self;
    uint32_t    tick;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_NOINC(CFISH_Vec_Delete(self, tick));
OUTPUT: RETVAL

void
store(self, tick, value);
    cfish_Vector *self;
    uint32_t     tick;
    cfish_Obj    *value;
PPCODE:
{
    if (value) { CFISH_INCREF(value); }
    CFISH_Vec_Store(self, tick, value);
}

SV*
fetch_raw(self, tick)
    cfish_Vector *self;
    uint32_t     tick;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_INC(CFISH_Vec_Fetch(self, tick));
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Vector",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->exclude_method($_) for @hand_rolled;
    $binding->append_xs($xs_code);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_class {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $class = Clownfish::Class->fetch_class('Foo::Bar');
    my $subclass = Clownfish::Class->singleton('Foo::Bar::Jr', $class);
END_SYNOPSIS
    my $fetch_class_sample = <<'END_CONSTRUCTOR';
    my $class = Clownfish::Class->fetch_class($class_name);
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor(
        alias  => 'fetch_class',
        sample => $fetch_class_sample,
    );
    $pod_spec->add_constructor( alias  => 'singleton' );

    my $xs_code = <<'END_XS_CODE';
MODULE = Clownfish   PACKAGE = Clownfish::Class

SV*
fetch_class(unused_sv, class_name)
    SV *unused_sv;
    cfish_String *class_name;
CODE:
{
    cfish_Class *klass = cfish_Class_fetch_class(class_name);
    CFISH_UNUSED_VAR(unused_sv);
    RETVAL = klass ? (SV*)CFISH_Class_To_Host(klass, NULL) : &PL_sv_undef;
}
OUTPUT: RETVAL

SV*
singleton(unused_sv, ...)
    SV *unused_sv;
CODE:
{
    static const XSBind_ParamSpec param_specs[2] = {
        XSBIND_PARAM("class_name", true),
        XSBIND_PARAM("parent", false),
    };
    int32_t locations[2];
    cfish_String *class_name = NULL;
    cfish_Class  *parent     = NULL;
    cfish_Class  *singleton  = NULL;
    CFISH_UNUSED_VAR(unused_sv);
    XSBind_locate_args(aTHX_ &(ST(0)), 1, items, param_specs, locations, 2);
    class_name = (cfish_String*)XSBind_arg_to_cfish(
            aTHX_ ST(locations[0]), "class_name", CFISH_STRING,
            CFISH_ALLOCA_OBJ(CFISH_STRING));
    if (locations[1] < items) {
        parent = (cfish_Class*)XSBind_arg_to_cfish_nullable(
                aTHX_ ST(locations[1]), "parent", CFISH_CLASS, NULL);
    }
    singleton = cfish_Class_singleton(class_name, parent);
    RETVAL = (SV*)CFISH_Class_To_Host(singleton, NULL);
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        class_name => "Clownfish::Class",
    );
    $binding->set_pod_spec($pod_spec);
    $binding->append_xs($xs_code);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

1;
