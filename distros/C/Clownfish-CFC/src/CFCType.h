/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/** Clownfish::CFC::Model::Type - A variable's type.
 */

#ifndef H_CFCTYPE
#define H_CFCTYPE

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCType CFCType;
struct CFCClass;
struct CFCParcel;

#define CFCTYPE_CONST         (1 << 0)
#define CFCTYPE_NULLABLE      (1 << 1)
#define CFCTYPE_VOID          (1 << 2)
#define CFCTYPE_INCREMENTED   (1 << 3)
#define CFCTYPE_DECREMENTED   (1 << 4)
#define CFCTYPE_OBJECT        (1 << 5)
#define CFCTYPE_PRIMITIVE     (1 << 6)
#define CFCTYPE_INTEGER       (1 << 7)
#define CFCTYPE_FLOATING      (1 << 8)
#define CFCTYPE_CFISH_OBJ     (1 << 9)
#define CFCTYPE_CFISH_STRING  (1 << 10)
#define CFCTYPE_CFISH_BLOB    (1 << 12)
#define CFCTYPE_CFISH_INTEGER (1 << 13)
#define CFCTYPE_CFISH_FLOAT   (1 << 14)
#define CFCTYPE_CFISH_BOOLEAN (1 << 15)
#define CFCTYPE_CFISH_VECTOR  (1 << 16)
#define CFCTYPE_CFISH_HASH    (1 << 17)
#define CFCTYPE_VA_LIST       (1 << 18)
#define CFCTYPE_ARBITRARY     (1 << 19)
#define CFCTYPE_COMPOSITE     (1 << 20)

/** Generic constructor.
 *
 * @param flags Flags which apply to the Type.  Supplying incompatible flags
 * will trigger an error.
 * @param parcel A Clownfish::CFC::Model::Parcel.
 * @param specifier The C name for the type, not including any indirection or
 * array subscripts.
 * @param indirection integer indicating level of indirection. Example: the C
 * type "float**" has a specifier of "float" and indirection 2.
 */
CFCType*
CFCType_new(int flags, struct CFCParcel *parcel, const char *specifier,
            int indirection);

CFCType*
CFCType_init(CFCType *self, int flags, struct CFCParcel *parcel,
             const char *specifier, int indirection);

/** Return a Type representing an integer primitive.
 *
 * Support is limited to a subset of the standard C integer types:
 *
 *     int8_t
 *     int16_t
 *     int32_t
 *     int64_t
 *     uint8_t
 *     uint16_t
 *     uint32_t
 *     uint64_t
 *     char
 *     short
 *     int
 *     long
 *     size_t
 *     bool
 *
 * Many others are not supported: "signed" or "unsigned" anything, "long
 * long", "ptrdiff_t", "off_t", etc.
 *
 * @param flags Allowed flags: CONST, INTEGER, PRIMITIVE.
 * @param specifier Must match one of the supported types.
 */
CFCType*
CFCType_new_integer(int flags, const char *specifier);

/** Return a Type representing a floating point primitive.
 *
 * @param flags Allowed flags: CONST, FLOATING, PRIMITIVE.
 * @param specifier Must be either 'float' or 'double'.
 */
CFCType*
CFCType_new_float(int flags, const char *specifier);

/** Create a Type representing an object.
 *
 * The supplied `specifier` must match the last component of the
 * class name -- i.e. for the class "Crustacean::Lobster" it must be
 * "Lobster".
 *
 * The Parcel's prefix will be prepended to the specifier by new_object().
 *
 * @param flags Allowed flags: OBJECT, CFISH_OBJ, CFISH_STRING, CFISH_BLOB,
 * CFISH_INTEGER, CFISH_FLOAT, CFISH_BOOLEAN, CFISH_VECTOR, CFISH_HASH, CONST,
 * NULLABLE, INCREMENTED, DECREMENTED.
 * @param parcel A Clownfish::CFC::Model::Parcel.
 * @param specifier Required.  Must follow the rules for
 * Clownfish::CFC::Model::Class class name components.
 * @param indirection Level of indirection.  Must be 1 if supplied.
 */
CFCType*
CFCType_new_object(int flags, struct CFCParcel *parcel, const char *specifier,
                   int indirection);

/** Constructor for a composite type which is made up of repetitions of a
 * single, uniform subtype.
 *
 * @param flags Allowed flags: COMPOSITE, NULLABLE
 * @param child The Clownfish::CFC::Model::Type which the composite is
 * comprised of.
 * @param indirection integer indicating level of indirection.  Example: the C
 * type "float**" has indirection 2.
 * @param array A string describing an array postfix.
 */
CFCType*
CFCType_new_composite(int flags, CFCType *child, int indirection,
                      const char *array);

/** Return a Clownfish::CFC::Model::Type representing a the 'void' keyword in
 * C.  It can be used either for a void return type, or in conjuction with
 * with new_composite() to support the `void*` opaque pointer type.
 *
 * @param is_const Should be true if the type is const.  (Useful in the
 * context of `const void*`).
 */
CFCType*
CFCType_new_void(int is_const);

/** Create a Type representing C's va_list, from stdarg.h.
 */
CFCType*
CFCType_new_va_list(void);

/** "Arbitrary" types are a hack that spares us from having to support C types
 * with complex declaration syntaxes -- such as unions, structs, enums, or
 * function pointers -- from within Clownfish itself.
 *
 * The only constraint is that the `specifier` must end in "_t".
 * This allows us to create complex types in a C header file...
 *
 *    typedef union { float f; int i; } floatint_t;
 *
 * ... pound-include the C header, then use the resulting typedef in a
 * Clownfish header file and have it parse as an "arbitrary" type.
 *
 *    floatint_t floatint;
 *
 * If `parcel` is supplied and `specifier` begins with a
 * capital letter, the Parcel's prefix will be prepended to the specifier:
 *
 *    foo_t         -> foo_t                # no prefix prepending
 *    Lobster_foo_t -> crust_Lobster_foo_t  # prefix prepended
 *
 * @param specifier The name of the type, which must end in "_t".
 * @param parcel A Clownfish::CFC::Model::Parcel.
 */
CFCType*
CFCType_new_arbitrary(struct CFCParcel *parcel, const char *specifier);

/** Find the actual class of an object variable without prefix.
 */
void
CFCType_resolve(CFCType *self);

void
CFCType_destroy(CFCType *self);

/** Returns true if two Clownfish::CFC::Model::Type objects are equivalent.
 */
int
CFCType_equals(CFCType *self, CFCType *other);

/** Weak checking of type which allows for covariant return types.  Calling
 * this method on anything other than an object type is an error.
 */
int
CFCType_similar(CFCType *self, CFCType *other);

void
CFCType_set_specifier(CFCType *self, const char *specifier);

const char*
CFCType_get_specifier(CFCType *self);

/** Return the name of the Class variable which corresponds to the object
 * type.  Returns NULL for non-object types.
 */
const char*
CFCType_get_class_var(CFCType *self);

int
CFCType_get_indirection(CFCType *self);

/* Return the parcel in which the Type is used. Note that for class types,
 * this is not neccessarily the parcel where class is defined.
 */
struct CFCParcel*
CFCType_get_parcel(CFCType *self);

/** Return the C representation of the type.
 */
const char*
CFCType_to_c(CFCType *self);

size_t
CFCType_get_width(CFCType *self);

const char*
CFCType_get_array(CFCType *self);

int
CFCType_const(CFCType *self);

void
CFCType_set_nullable(CFCType *self, int nullable);

int
CFCType_nullable(CFCType *self);

/** Returns true if the Type is incremented.  Only applicable to object Types.
 */
int
CFCType_incremented(CFCType *self);

/** Returns true if the Type is decremented.  Only applicable to object Types.
 */
int
CFCType_decremented(CFCType *self);

int
CFCType_is_void(CFCType *self);

int
CFCType_is_object(CFCType *self);

int
CFCType_is_primitive(CFCType *self);

int
CFCType_is_integer(CFCType *self);

int
CFCType_is_floating(CFCType *self);

/** Returns true if the type is Clownfish::Obj.
 */
int
CFCType_cfish_obj(CFCType *self);

/** Returns true if the type is Clownfish::String.
 */
int
CFCType_cfish_string(CFCType *self);

/** Returns true if the type is Clownfish::Blob.
 */
int
CFCType_cfish_blob(CFCType *self);

/** Returns true if the type is Clownfish::Integer.
 */
int
CFCType_cfish_integer(CFCType *self);

/** Returns true if the type is Clownfish::Float.
 */
int
CFCType_cfish_float(CFCType *self);

/** Returns true if the type is Clownfish::Boolean
 */
int
CFCType_cfish_boolean(CFCType *self);

/** Returns true if the type is Clownfish::Vector.
 */
int
CFCType_cfish_vector(CFCType *self);

/** Returns true if the type is Clownfish::Hash.
 */
int
CFCType_cfish_hash(CFCType *self);

int
CFCType_is_va_list(CFCType *self);

int
CFCType_is_arbitrary(CFCType *self);

int
CFCType_is_composite(CFCType *self);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCTYPE */

