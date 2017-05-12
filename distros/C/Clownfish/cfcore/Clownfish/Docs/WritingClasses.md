# Writing Apache Clownfish classes

## Parcels

Every Clownfish class belongs to a Clownfish parcel. Parcels are used for
namespacing and versioning. Information about parcels is stored in `.cfp`
files which contain a JSON hash with the following keys:

* __name:__ The parcel's name. It must contain only letters.

* __nickname:__ A short nickname. It must contain only letters. This nickname,
    followed by an underscore, is used to prefix generated C symbols and
    macros. Depending on the kind of symbol, a lowercase or uppercase prefix
    will be used.

* __version:__ A version specifier of the following form (without whitespace):

      version-specifier = "v" version-number
      version-number = digit+ | digit+ "." version-number

* __prerequisites:__ A hash containing the prerequisite parcels. The hash keys
    are the parcel names. The values contain the minimum required version.

An example `.cfp` file might look like:

    {
        "name": "Pathfinder",
        "nickname": "Pfind",
        "version": "v2.3.8",
        "prerequisites": {
            "Clownfish": "v0.6.1"
        }
    }

A parcel specifier of the following form is used in Clownfish header files:

    parcel-specifier = "parcel" parcel-name ";"
    parcel-name = identifier

For example:

    parcel Pathfinder;

Every `.cfh` file starts with a parcel specifier containing the name of
the parcel for all classes in the header file.

### Initialization

Every Clownfish parcel must be initialized before it is used. The
initialization function is named `{parcel_nick}_bootstrap_parcel` and takes
no arguments.

Example call:

    pfind_bootstrap_parcel();

The generated host language bindings call the bootstrap function
automatically. C projects must call the function manually.

### Short names

If a macro with the uppercase name `{PARCEL_NICK}_USE_SHORT_NAMES` is
defined before including a generated C header, additional macros without the
parcel prefix will be defined for most symbols.

Example:

    #define PFIND_USE_SHORT_NAMES
    #include <Pathfinder/Graph.h>
    #include <Pathfinder/Path.h>

    /* Prefixes can be omitted. */
    Path *path = Graph_Find_Shortest_Path(graph);

    /* Without PFIND_USE_SHORT_NAMES, one would have to write: */
    pfind_Path *path = PFIND_Graph_Find_Shortest_Path(graph);

For object types in Clownfish header files, prefixes of class structs can
also be omitted unless multiple parcels declare classes with the same last
component of the class name.

### The "Clownfish" parcel

The Clownfish runtime classes live in a parcel named `Clownfish` with
nickname `Cfish`. Consequently, the short name macro is named
`CFISH_USE_SHORT_NAMES`.

## Declaring classes

Classes are declared in Clownfish header files using a declaration of the
following form:

    class-declaration = class-exposure-specifier?
                        class-modifier*
                        "class" class-name
                        ("nickname" class-nickname)?
                        ("inherits" class-name)?
                        "{" class-contents "}"
    class-exposure-specifier = "public"
    class-modifier = "inert" | "final"
    class-name = identifier | identifier "::" class-name
    class-nickname = identifier
    class-contents = (variable-declaration | function-declaration)*

Class name components must start with an uppercase letter and must not contain
underscores. The last component must contain at least one lowercase letter and
must be unique for every class in a parcel.

For every class, a type with the name `{parcel_nick}_{Class_Last_Comp}`
is defined in the generated C header. This is an opaque typedef used to
ensure type safety.

For every class, a global variable with the uppercase name
`{PARCEL_NICK}_{CLASS_LAST_COMP}` is defined. This variable is a pointer to
a Clownfish::Class object which is initialized when bootstrapping the parcel.

Non-inert classes inherit from Clownfish::Obj by default.

Example of a class declaration:

    parcel Pathfinder;

    public class Pathfinder::Graph::VisibilityGraph nickname VisGraph
        extends Clownfish::Obj {
        /* Variables and functions */
    }

This will generate:

    typedef struct pfind_VisibilityGraph pfind_VisibilityGraph;
    extern cfish_Class *PFIND_VISIBILITYGRAPH;

### Class exposure

API documentation will only be generated for classes with `public` exposure.

### Inert classes

Inert classes must contain only inert variables or inert functions, that is,
neither instance variables nor methods. They must not inherit from another
class nor be inherited from. They're essentially nothing more than a
namespace for functions and global variables.

### Final classes

For final classes, every method is made final, regardless of the method
modifier. Final classes must not be inherited from.

## Variables

Variables are declared with a declaration of the following form:

    variable-declaration = variable-modifier*
                           type variable-name ";"
    variable-modifier = "inert"
    variable-name = identifier

### Inert variables

Inert variables are global class variables of which only a single copy
exists. They are declared in the generated C header with the name
`{parcel_nick}_{Class_Nick}_{Variable_Name}` and must be defined in a C
source file.

Example:

    public class Pathfinder::Path {
        public inert int max_path_length;
    }

This will generate:

    extern int pfind_Path_max_path_length;

The C source file defining the variable will typically use short names. So the
definition will look like:

    int Path_max_path_length = 5000;

### Instance variables

Non-inert variables are instance variables and added to the class's ivars
struct.

Example:

    public class Pathfinder::Path {
        int num_nodes;

        public int
        Get_Num_Nodes(Path *self);
    }

This will add a `num_nodes` member to the ivars struct of `Path`.

### The ivars struct

To access instance variables, the macro `C_{PARCEL_NICK}_{CLASS_LAST_COMP}`
must be defined before including the generated header file. This will make
a struct named `{parcel_nick}_{Class_Name}IVARS` with a corresponding
typedef and short name available that contains all instance variables
of the class and all superclasses from the same parcel. Instance
variables defined in other parcels are not accessible. This is by
design to guarantee ABI stability if the instance variable layout
of a superclass from another parcel changes in a different version.
If you need to access an instance variable from another parcel,
add accessor methods.

A pointer to the ivars struct can be obtained by calling an inline
function named `{parcel_nick}_{Class_Name}_IVARS`. This function
takes the object of the class (typically `self`) as argument.

Example using short names:

    #define C_PFIND_PATH
    #define PFIND_USE_SHORT_NAMES
    #include "Pathfinder/Path.h"

    int
    Path_get_num_nodes(Path *self) {
        PathIVARS *ivars = Path_IVARS(self);
        return ivars->num_nodes;
    }

## Functions

    function-declaration = function-exposure-specifier?
                           function-modifier*
                           return-type function-name
                           "(" param-list? ")" ";"
    function-exposure-specifier = "public"
    function-modifier = "inert" | "inline" | "abstract" | "final"
    return-type = return-type-qualifier* type
    return-type-qualifier = "incremented" | "nullable"
    function-name = identifier
    param-list = param | param "," param-list
    param = param-qualifier* type param-name ("=" scalar-constant)?
    param-name = identifier
    param-qualifier = "decremented"

### Function exposure

API documentation will only be generated for functions with `public` exposure.

### Inert functions

Inert functions are dispatched statically. They are declared in the generated
C header with the name `{parcel_nick}_{Class_Nick}_{Function_Name}`
and must be defined in a C source file. They must be neither abstract nor
final.

Example:

    public class Pathfinder::Graph::VisibilityGraph nickname VisGraph
        extends Clownfish::Obj {

        public inert incremented VisibilityGraph*
        new(int node_capacity);
    }

This will generate:

    pfind_VisibilityGraph*
    pfind_VisGraph_new(int node_capacity);

The C source file implementing the inert function will typically use short
names. So the implementation will look like:

    #define PFIND_USE_SHORT_NAMES
    #include "Pathfinder/Graph/VisibilityGraph.h"

    VisibilityGraph*
    VisGraph_new(int node_capacity) {
        /* Implementation */
    }

### Inline functions

Inert functions can be inline. They should be defined as static inline
functions in a C block in the Clownfish header file. The macro `CFISH_INLINE`
expands to the C compiler's inline keyword and should be used for portability.

### Methods

Non-inert functions are dynamically dispatched methods. Their name must start
with an uppercase letter and every underscore must be followed by an uppercase
letter. Methods must not be declared inline.

The first parameter of a method must be a pointer to an object of the method's
class which receives the object on which the method was invoked. By convention,
this parameter is named `self`.

For every method, an inline wrapper for dynamic dispatch is defined in
the generated C header with the name
`{PARCEL_NICK}_{Class_Nick}_{Method_Name}`. Additionally, an
implementing function is declared with the name
`{PARCEL_NICK}_{Class_Nick}_{Method_Name}_IMP`. The Clownfish compiler also
generates a typedef for the method's function pointer type named
`{PARCEL_NICK}_{Class_Nick}_{Method_Name}_t`. Wrappers and typedefs are
created for all subclasses whether they override a method or not.

Example:

    public class Pathfinder::Graph::VisibilityGraph nickname VisGraph
        extends Clownfish::Obj {

        public void
        Add_Node(VisibilityGraph *self, decremented Node *node);
    }

This will generate:

    /* Wrapper for dynamic dispatch */
    static inline void
    PFIND_VisGraph_Add_Node(pfind_VisibilityGraph *self, pfind_Node *node) {
        /* Inline code for wrapper */
    }

    /* Declaration of implementing function */
    void
    PFIND_VisGraph_Add_Node_IMP(pfind_VisibilityGraph *self,
                                pfind_Node *node);

    /* Declaration of function pointer type */
    typedef void
    (*PFIND_VisGraph_Add_Node_t)(pfind_VisibilityGraph *self,
                                 pfind_Node *node);

The implementing function of non-abstract methods must be defined in a C source
file. This file will typically define the short names macro. So the
implementation will look like:

    #define PFIND_USE_SHORT_NAMES
    #include "Pathfinder/Graph/VisibilityGraph.h"

    void
    VisGraph_Add_Node_IMP(VisibilityGraph *self, Node *node) {
        /* Implementation */
    }

### Looking up methods

Clownfish defines a macro named `CFISH_METHOD_PTR` that looks up the pointer
to the implementing function of a method. The first parameter of the macro is
a pointer to the Clownfish::Class object of the method's class, the second is
the unshortened name of the method wrapper. If short names for the Clownfish
parcel are used, the macro is also available under the name `METHOD_PTR`.

To lookup methods from a superclass, there's a macro `CFISH_SUPER_METHOD_PTR`
with the same parameters.

Example using short names:

    // Note that the name of the method wrapper must not be shortened.
    VisGraph_Add_Node_t add_node
        = METHOD_PTR(VISIBILITYGRAPH, Pfind_VisGraph_Add_Node);

    VisGraph_Add_Node_t super_add_node
        = SUPER_METHOD_PTR(VISIBILITYGRAPH, Pfind_VisGraph_Add_Node);

### Abstract methods

For abstract methods, the Clownfish compiler generates an implementing function
which throws an error. They should be overridden in a subclass.

### Final methods

Final methods must not be overridden. They must not be abstract.

### Nullable return type

If a function has a nullable return type, it must return a pointer.
Non-nullable functions must never return the NULL pointer.

### Incremented return type

Incremented return types must be pointers to Clownfish objects. The function
will either return a new object with an initial reference count of 1 or
increment the reference count. The caller must decrement the reference count of
the returned object when it's no longer used.

For returned objects with non-incremented return type, usually no additional
handling of reference counts is required. Only if an object is returned from an
accessor or a container object and the caller wants to use the object longer
than the returning object retains a reference, it must increment the reference
count itself and decrement when the object is no longer used.

### Decremented parameters

Decremented parameters must be pointers to Clownfish objects. The function
will either decrement the reference count of the passed-in object or retain a
reference without incrementing the reference count. If the caller wants to use
the passed-in object afterwards, it usually must increment its reference count
before the call and decrement it when it's no longer used. If the caller does
not make further use of the passed-in object, it must not decrement its
reference count after the call.

This is typically used in container classes like Vector:

    String *string = String_newf("Hello");
    Vec_Push(array, (Obj*)string);
    // No need to DECREF the string.

### Default parameter values

Default parameter values can be given as integer, float, or string literals.
The values `true`, `false`, and `NULL` are also supported. The default
values are only used by certain host language bindings. They're not supported
when calling a function from C.

## C blocks

Clownfish headers can contain C blocks which start with a line containing the
string `__C__` and end on a line containing the string `__END_C__`. The
contents of a C block are copied verbatim to the generated C header.

Example:

    __C__

    struct pfind_AuxiliaryStruct {
        int a;
        int b;
    };

    __END_C__

## Object life cycle

### Object creation

Objects are allocated by invoking the `Make_Obj` method on a class's
Clownfish::Class object.

Any inert function can be used to construct objects from C. But to support
inheritance and object creation from the host language, Clownfish classes
need a separate function to initialize objects. The initializer must take a
pointer to an object as first argument and return a pointer to the same
object. If the parent class has an initializer, it should be called first by
the subclass's initializer.

By convention, the standard constructor is named `new` and the standard
initializer `init`.

Example:

    /* Clownfish header */

    class Vehicle {
        double max_speed;

        inert Vehicle*
        init(Vehicle *self, double max_speed);
    }

    class Train inherits Vehicle {
        double track_gauge;

        inert incremented Train*
        new(double max_speed, double track_gauge);

        inert Train*
        init(Train *self, double max_speed, double track_gauge);
    }

    /* Implementation */

    Train*
    Train_new(double max_speed, double track_gauge) {
        Train *self = (Train*)Class_Make_Obj(TRAIN);
        return Train_init(self, max_speed, track_gauge);
    }

    Train*
    Train_init(Train *self, double max_speed, double track_gauge) {
        Vehicle_init((Vehicle*)self, max_speed);
        self->track_gauge = track_gauge;
        return self;
    }

### Reference counting

Clownfish uses reference counting for memory management. Objects are created
with a reference count of 1. There are two macros `CFISH_INCREF` and
`CFISH_DECREF` to increment and decrement reference counts. If short names
for the Clownfish parcel are enabled, the macros can be abbreviated to
`INCREF` and `DECREF`. Both macros take a pointer to an object as argument.
NULL pointers are allowed. `CFISH_INCREF` returns a pointer to the object.
This value might differ from the passed-in pointer in some cases. So if a
reference is retained, the pointer returned from `CFISH_INCREF` should be
used. `CFISH_DECREF` returns the modified reference count.

Examples:

    self->value = INCREF(arg);

    DECREF(object);

### Object destruction

If an object's reference count reaches 0, its `Destroy` method is called.
This public method takes no arguments besides `self` and has no return value.
It should release the resources held by the object and finally call the
`Destroy` method of the superclass via the `CFISH_SUPER_DESTROY` macro with
short name `SUPER_DESTROY`. This macro takes the `self` pointer as first
argument and a pointer to the object's Clownfish::Class as second argument.
The `Destroy` method of the Clownfish::Obj class will eventually free the
object struct.

Example:

    /* Clownfish header */

    class Path {
        Vector *nodes;

        public void
        Destroy(Path *self);
    }

    /* Implementation */

    void
    Path_Destroy_IMP(Path *self) {
        DECREF(self->nodes);
        SUPER_DESTROY(self, PATH);
    }

## Documentation

The Clownfish compiler creates documentation in the host language's preferred
format from so-called DocuComments found in the `.cfh` files. DocuComments use
Markdown ([CommonMark](http://commonmark.org/) flavor) for formatting.
DocuComments are multi-line C-style comments that start with `/**`. They
immediately precede the documented class, inert function, or method.
A left border consisting of whitespace and asterisks is stripped.

The DocuComment for a class should start with a short description (everything
up until the first period `.`) which may appear in the name section of a
man page, for example.

DocuComments for functions and methods may end with a series of `@param` and
`@return` directives which document the parameters and return values.

Example:

    /** Class describing a train.
     *
     * The Train class describes a train. It extends the Vehicle class and
     * adds some useful properties specific to trains.
     */
    public class Train inherits Vehicle {
        /** Create a new Train object.
         *
         * @param max_speed The maximum speed in km/h.
         * @param track_gauge The track gauge in mm.
         */
        public inert incremented Train*
        new(double max_speed, double track_gauge);

        /** Accessor for maximum speed.
         *
         * @return the maximum speed in km/h.
         */
        public double
        Get_Max_Speed(Train *self);
    }

The Clownfish compiler also looks for standalone Markdown `.md` files in the
source directories which will be included in the documentation.

