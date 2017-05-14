# CORBA/IDLtree.pm   IDL to symbol tree translator
# This module is distributed under the same terms as Perl itself.
# Copyright/author:  (C) 1998-2003, Oliver M. Kellogg
# Contact:           okellogg@users.sourceforge.net
#
# -----------------------------------------------------------------------------
# Ver. |   Date   | History
# -----+----------+------------------------------------------------------------
#  1.4  2003/07/25  Implemented #elif in the emulated preprocessor and fixed
#                   the handling of preprocessor conditions.
#                   Changed the COMMENT element of the node structure to only
#                   contain the post-comment. Turned the former pre-comment
#                   into an independent node, REMARK. See documentation below.
#                   Added global switch $cache_trees.  It buys speed when
#                   submitting related IDL files to consecutive Parse_File
#                   calls by saving and reusing the trees built for #included
#                   files.  CAVEAT: The redefinition of #defined symbols
#                   is flagged as an error when using this switch.
#  1.3  2002/12/01  #include statements that appear at places other than
#                   the global scope are no longer made into INCFILE nodes;
#                   instead, the included file is parsed inline.
#                   The SCOPEREF of declarations immediately inside an INCFILE
#                   now point to the INCFILE. This change makes possible the
#                   reopening of modules.
#                   Support self-referential valuetype definition, i.e.
#                   state members that are of the type currently being defined.
#  1.2  2002/07/08  Added a further element to the node structure: COMMENT
#                   (see below for details.)
#                   Added user-level utilities is_a and root_type.
#                   Added PRAGMA for the general case of (unknown) pragmas.
#                   Relieved the constraint on the required perl version;
#                   perl versions after 5.002 should be fine.
#                   Privatized @predef_types. Apps should only use sub typeof.
#  1.1a 2002/06/27  Added sub is_valid_identifier. Added a test directory.
#  1.1  2002/06/24  Removed non-standard extensions.
#                   In the interest of IDL conformance, changed the scope
#                   separator used internally to "::". (This separator
#                   may appear at union CASE designators and in CONST
#                   and array dimension expressions.)
#                   Removed the LANG constants, and removed support for
#                   languages other than IDL in sub typeof.
#                   Corrected parsing of valuetype boxes.
#                   Repaired `const string' and implemented simple `const'
#                   used as a bounded-string bound expression.
#                   Added detection of unclosed comment at end of file.
#                   Added NATIVE.
#  1.0  2002/02/04  Turned all variables used as constants into subroutines.
#                   Attention, unfortunately this impacts all applications;
#                   e.g. the former $CORBA::IDLtree::BOOLEAN is now written
#                   &CORBA::IDLtree::BOOLEAN .
#                   Added "abstract" and OBV related keywords.
#                   Improved usage of gcc as a C preprocessor.
#                   However, there still are problems with using system
#                   preprocessors, due to variations in their options and
#                   behavior. The default is now to use preprocessor
#                   emulation. Removed sub emulate_cpp and added sub
#                   use_system_preprocessor to attempt usage of the system
#                   preprocessor.
#                   The builtin preprocessor now does simple substitutions
#                   (however, macro functions are still unimplemented.)
#  0.7b 1999/11/16  Added pragma ID.
#  0.7a 1999/11/16  Added sub emulate_cpp to force C preprocessor emulation.
#  0.7  1999/09/15  Added wchar and wstring to the elementary types.
#                   The SUBORDINATES of an INTERFACE node were erroneously
#                   a tuple (ancestor ref plus ref to array of contained nodes)
#                   The ref-to-contained-nodes was one level of indirection
#                   too many. Corrected that to be a flat array; element 0 is
#                   the ancestor ref, following elements are the contained
#                   nodes.
#                   Dump_Symbols now generates exact IDL syntax.
#  0.6b 1999/08/03  Improved C preprocessor emulation by Jacques Tremblay
#                   (jackt@gel.ulaval.ca)
#  0.6  1999/07/17  Use C preprocessor; added optional argument $cpp_args
#                   at Parse_File
#  0.5b 1999/05/17  Support IDL type "TypeCode"
#  0.5  1999/05/09  Support IDL type "fixed" and the extra long types
#  0.4a 1999/04/29  Added a node for interface forward declarations.
#                   First rough hack at the missing preprocessor directives
#                   #ifdef, #ifndef, #else, #endif, #define, #undef
#                   (no nested #ifdefs yet.) Perhaps this stuff shouldn't be
#                   done here at all and we should use the C preprocessor
#                   instead. Discussion welcome.
#  0.4  1999/04/20  Design change: added a back pointer to the enclosing
#                   scope to each node. The basic node now contains four
#                   elements: ($TYPE, $NAME, $SUBORDINATES, $SCOPE)
#                   Removed the %Prefixes hash that is thus obsolete.
#                   Replaced sub check_scope by sub curr_scope.
#  0.3  1999/04/11  Added a node for pragma prefix
#  0.2  1999/04/06  Minor cosmetic changes; tested subs traverse_tree
#                   and traverse (for usage example, see idl2ada.pl)
#                   Preprocessor directives other than #include were
#                   actually mistreated (fixed so they are just ignored.)
#  0.1  1998/07/06  Corrected the first parameter to the check_scope call
#                   in process_members.
#                   The two elements of @tuple in 'const' processing were
#                   the wrong way round, corrected that.
#                   Overhauled the explanation of the Symbol Tree which was
#                   buggy in itself.
#  0.0  1998/06/29  First public release, alpha stage
#                   Things known to need thought: forward declarations,
#                   generation of Typecode information. The symbol trees
#                   generated are pretty much nude'n'crude -- what you see in
#                   IDL is what you get in ST. What kind of decorative info do
#                   we need? Any ideas/discussion, please email to addr. above
#  -.-  Mar 1998    Start of development
#                   The first version of this worked as a simple one-pass
#                   text filter until I attempted implementing interface
#                   references. In order to generate a "Ref" for those (in
#                   Ada), it is necessary to distinguish them from other
#                   types (the Ada type name is different from the IDL type
#                   name.) This single requirement led to the abandonment
#                   of the direct text-to-text transformation approach.
#                   Instead, IDL source text is first translated into a
#                   target language independent intermediate representation
#                   (the symbol tree), and the target language text is
#                   then generated from that intermediate representation.
# -----------------------------------------------------------------------------
#


package CORBA::IDLtree;
require Exporter;
@ISA = ('Exporter');
@EXPORT = ();
@EXPORT_OK = ();  # &Parse_File, &Dump_Symbols, and all the constants subs

use vars qw(@include_path %defines $support_module_reopening $cache_trees
            $n_errors $enable_comments $enable_enum_comments);

use strict 'vars';

# -----------------------------------------------------------------------------
#
# Structure of the symbol tree:
#
# A "thing" in the symbol tree can be either a reference to a node, or a
# reference to an array of references to nodes.
#
# Each node is a five-element array with the elements
#   [0] => TYPE (MODULE|INTERFACE|STRUCT|UNION|ENUM|TYPEDEF|CHAR|...)
#   [1] => NAME
#   [2] => SUBORDINATES
#   [3] => COMMENT
#   [4] => SCOPEREF
#
# The TYPE element, instead of holding a type ID number (see the following
# list under SUBORDINATES), can also be a reference to the node defining the
# type. When the TYPE element can contain either a type ID or a reference to
# the defining node, we will call it a `type descriptor'.
# Which of the two alternatives is in effect can be determined via the
# isnode() function.
#
# The NAME element, unless specified otherwise, simply holds the name string
# of the respective IDL syntactic item.
#
# The SUBORDINATES element depends on the type ID:
#
#   MODULE or       Reference to an array of nodes (symbols) which are defined
#   INTERFACE       within the module or interface. In the case of INTERFACE,
#                   element [0] in this array will contain a reference to a
#                   further array which in turn contains references to the
#                   parent interface(s) if inheritance is used, or the null
#                   value if the current interface is not derived by
#                   inheritance. Element [1] is the "abstract" flag which is
#                   non-zero for interfaces declared abstract.
#
#   INTERFACE_FWD   Reference to the node of the full interface declaration.
#
#   STRUCT or       Reference to an array of node references representing the
#   EXCEPTION       member components of the struct or exception.
#                   Each member representative node is a quadruplet consisting
#                   of (TYPE, NAME, <dimref>, COMMENT).
#                   The <dimref> is a reference to a list of dimension numbers,
#                   or is 0 if no dimensions were given.
#
#   UNION           Similar to STRUCT/EXCEPTION, reference to an array of
#                   nodes. For union members, the member node has the same
#                   structure as for STRUCT/EXCEPTION.
#                   However, the first node contains a type descriptor for
#                   the discriminant type.
#                   The TYPE of a member node may also be CASE or DEFAULT.
#                   For CASE, the NAME is unused, and the SUBORDINATE contains
#                   a reference to a list of the case values for the following
#                   member node.
#                   For DEFAULT, both the NAME and the SUBORDINATE are unused.
#
#   ENUM            Reference to the array of enum value literals.
#                   If the global variable $enable_enum_comments is set then
#                   the elements in the array may be shaped differently:
#                   - If the enum literal is not followed by a comment then
#                     the element in the array is the enum literal as usual.
#                   - If the enum literal is followed by a comment then the
#                     element in the array is a reference to a tuple. In this
#                     tuple, the first element is the enum literal, and the
#                     second element is a reference to the comment list.
#                     Thus, when generating code for the literals, it is
#                     recommended to use the `ref' predicate to find out
#                     which of the two alternatives is in effect for each
#                     array element.
#
#   TYPEDEF         Reference to a two-element array: element 0 contains a
#                   reference to the type descriptor of the original type;
#                   element 1 contains a reference to an array of dimension
#                   numbers, or the null value if no dimensions are given.
#
#   SEQUENCE        As a special case, the NAME element of a SEQUENCE node
#                   does not contain a name (as sequences are anonymous
#                   types), but instead is used to hold the bound number.
#                   If the bound number is 0, then it is an unbounded
#                   sequence. The SUBORDINATES element contains the type
#                   descriptor of the base type of the sequence. This
#                   descriptor could itself be a reference to a SEQUENCE
#                   defining node (that is, a nested sequence definition.)
#                   Bounded strings are treated as a special case of sequence.
#                   They are represented as references to a node that has
#                   BOUNDED_STRING or BOUNDED_WSTRING as the type ID, the bound
#                   number in the NAME, and the SUBORDINATES element is unused.
#
#   CONST           Reference to a two-element array. Element 0 is a type
#                   descriptor of the const's type; element 1 is a reference
#                   to an array containing the RHS expression symbols.
#
#   FIXED           Reference to a two-element array. Element 0 contains the
#                   digit number and element 1 contains the scale factor.
#                   The NAME component in a FIXED node is unused.
#
#   VALUETYPE       [0] => $is_abstract (boolean)
#                   [1] => reference to a tuple (two-element list) containing
#                          inheritance related information:
#                          [0] => $is_truncatable (boolean)
#                          [1] => \@ancestors (reference to array containing
#                                 references to ancestor nodes)
#                   [2] => \@members: reference to array containing references
#                          to tuples (two-element lists) of the form:
#                          [0] => 0|PRIVATE|PUBLIC
#                                 A zero for this value means the element [1]
#                                 contains a reference to a METHOD or ATTRIBUTE.
#                                 In case of METHOD, the first element in the
#                                 method node subordinates (i.e., the return
#                                 type) may be FACTORY.
#                          [1] => reference to the defining node.
#                                 In case of PRIVATE or PUBLIC state member,
#                                 the defining node is the same as for STRUCT
#                                 subordinates, namely a quadruplet containing:
#                                  [0] => member type id
#                                  [1] => member name
#                                  [2] => dimref (reference to dimensions list)
#                                  [3] => COMMENT element
#
#   VALUETYPE_BOX   Reference to the defining type node.
#
#   VALUETYPE_FWD   Subordinates unused.
#
#   NATIVE          Subordinates unused.
#
#   ATTRIBUTE       Reference to a two-element array; element 0 is the read-
#                   only flag (0 for read/write attributes), element 1 is a
#                   type descriptor of the attribute's type.
#
#   METHOD          Reference to a variable length array; element 0 is a type
#                   descriptor for the return type. Elements 1 and following
#                   are references to parameter descriptor nodes with the
#                   following structure:
#                       elem. 0 => parameter type descriptor
#                       elem. 1 => parameter name
#                       elem. 2 => parameter mode (IN, OUT, or INOUT)
#                   The last element in the variable-length array is a
#                   reference to the "raises" list. This list contains
#                   references to the declaration nodes of exceptions raised,
#                   or is empty if there is no "raises" clause.
#
#   INCFILE         Reference to an array of nodes (symbols) which are defined
#                   within the include file. The Name element of this node
#                   contains the include file name.
#
#   PRAGMA_PREFIX   Subordinates unused.
#
#   PRAGMA_VERSION  Version string.
#
#   PRAGMA_ID       ID string.
#
#   PRAGMA          This is for the general case of pragmas that are none
#                   of the above, i.e. pragmas unknown to IDLtree.
#                   The NAME holds the pragma name, and SUBORDINATES
#                   holds a reference to all further text appearing after
#                   the pragma name, if any.
#
#   REMARK          The SUBORDINATES of the node is unused.
#                   The NAME component contains a reference to a list of
#                   comment lines. In the case of a single-line comment, the
#                   list will contain only one element; in case of multi-
#                   line comments, each line is represented by a list entry.
#                   The lines in this list are not newline terminated; empty
#                   entries represent empty comment lines.
#
#
# The COMMENT element holds the comment text that follows the IDL declaration
# on the same line. Usually this is just a single line. However, if a multi-
# line comment is started on the same line after a declaration, the multi-line
# comment may extend to further lines - therefore we use a list of lines.
# The lines in this list are not newline terminated. The COMMENT field is a
# reference to this list, or contains the value 0 if no comment is present
# at the IDL item.
#
# The SCOPEREF element is a reference back to the node of the module or
# interface enclosing the current node. If the current node is already
# at the global scope level, then the SCOPEREF is 0. All nodes have this
# element except for the parameter nodes of methods and the component nodes
# of structs/unions/exceptions.
#

# Visible subroutines #########################################################

sub Parse_File;
    # Parse_File() is the universal entry point (called by the main program.)
    # It takes an IDL file name as the input parameter and parses that file,
    # constructing one or more symbol trees for the outermost declaration(s)
    # encountered. It returns a reference to an array containing references
    # to those trees.
    # In case of errors during parsing , Parse_File returns 0.

# User definable auxiliary data for Parse_File:
@include_path = ();     # Paths where to look for included IDL files
%defines = ();          # Symbol definitions for preprocessor
$support_module_reopening = 0;  # By default, do not support module reopening
$cache_trees = 0;       # By default, do not cache trees of #included files
$enable_comments = 0;   # By default, do not generate REMARK nodes.
$enable_enum_comments = 0;  # By default, do not promote enum literal comments
                            # into the ENUM subordinates.
$n_errors = 0;          # Cumulative number of errors for a Parse_File call.

my %active_defines = ();


sub Dump_Symbols;
    # Symbol tree dumper (for debugging etc.)

sub Version ()
{
    for ('$Revision: 1.83 $') { #'){
        /: *(\S+)/ and return $1;
    }
    return "(undefined)";
}

# Visible constants ###########################################################

# Meanings of symbol node index
sub TYPE ()         { 0 }
sub NAME ()         { 1 }
sub SUBORDINATES () { 2 }
sub MODE ()         { 2 } # alias of SUBORDINATES (for method parameter nodes)
sub COMMENT ()      { 3 }
sub SCOPEREF ()     { 4 }

# Parameter modes
sub IN ()    { 1 }
sub OUT ()   { 2 }
sub INOUT () { 3 }

# Meanings of the TYPE entry in the symbol node.
# If these codes are changed, then @predef_types must be changed accordingly.
sub NONE ()            { 0 }   # error/illegality value
sub BOOLEAN ()         { 1 }
sub OCTET ()           { 2 }
sub CHAR ()            { 3 }
sub WCHAR ()           { 4 }
sub SHORT ()           { 5 }
sub LONG ()            { 6 }
sub LONGLONG ()        { 7 }
sub USHORT ()          { 8 }
sub ULONG ()           { 9 }
sub ULONGLONG ()       { 10 }
sub FLOAT ()           { 11 }
sub DOUBLE ()          { 12 }
sub LONGDOUBLE ()      { 13 }
sub STRING ()          { 14 }
sub WSTRING ()         { 15 }
sub OBJECT ()          { 16 }
sub TYPECODE ()        { 17 }
sub ANY ()             { 18 }
sub FIXED ()           { 19 }  # node
sub BOUNDED_STRING ()  { 20 }  # node
sub BOUNDED_WSTRING () { 21 }  # node
sub SEQUENCE ()        { 22 }  # node
sub ENUM ()            { 23 }  # node
sub TYPEDEF ()         { 24 }  # node
sub NATIVE ()          { 25 }  # node
sub STRUCT ()          { 26 }  # node
sub UNION ()           { 27 }  # node
sub CASE ()            { 28 }
sub DEFAULT ()         { 29 }
sub EXCEPTION ()       { 30 }  # node
sub CONST ()           { 31 }  # node
sub MODULE ()          { 32 }  # node
sub INTERFACE ()       { 33 }  # node
sub INTERFACE_FWD ()   { 34 }  # node
sub VALUETYPE ()       { 35 }  # node
sub VALUETYPE_FWD ()   { 36 }  # node
sub VALUETYPE_BOX ()   { 37 }  # node
sub ATTRIBUTE ()       { 38 }  # node
sub ONEWAY ()          { 39 }  # implies "void" as the return type
sub VOID ()            { 40 }
sub FACTORY ()         { 41 }  # treated as return type of METHOD;
                             #       can only occur inside valuetype
sub METHOD ()          { 42 }  # node
sub INCFILE ()         { 43 }  # node
sub PRAGMA_PREFIX ()   { 44 }  # node
sub PRAGMA_VERSION ()  { 45 }  # node
sub PRAGMA_ID ()       { 46 }  # node
sub PRAGMA ()          { 47 }  # node
sub REMARK ()          { 48 }  # node
sub NUMBER_OF_TYPES () { 49 }

# Valuetype flag values
sub ABSTRACT      { 1 }
sub TRUNCATABLE   { 2 }
sub CUSTOM        { 3 }
# valuetype member flags
sub PRIVATE       { 1 }
sub PUBLIC        { 2 }

# Visible subroutines #########################################################

sub is_elementary_type;
sub predef_type;
sub isnode;                   # Given a "thing", returns 1 if it is a
                              #  reference to a node, 0 otherwise.
sub is_scope;                 # Given a "thing", returns 1 if it's a ref
                              #  to a MODULE, INTERFACE, or INCFILE node.
sub find_node;                # Looks up a name in the symbol tree(s)
                              #  constructed so far.
                              #  Returns the node ref if found, else 0.
sub typeof;                   # Given a type descriptor, returns the type
                              #  as a string in IDL syntax.
sub use_system_preprocessor;  # Attempt to use the system preprocessor if
                              #  one is found.
                              #  Takes no arguments.
                              #  NOTE: Due to variations in preprocessor
                              #  options and behavior, this might not work
                              #  on your system.
                              #  If use_system_preprocessor is not called
                              #  then the IDLtree parser attempts to do the
                              #  preprocessing itself.
sub set_verbose;              # Parser tells us what it's doing.

sub is_a;                # Determine if typeid is of given type,
                         #  recursing through TYPEDEFs.
                         #  Not used internally.
sub root_type;           # Get the original type of a TYPEDEF, i.e.
                         #  recurse through all non-array TYPEDEFs until
                         #  the original type is reached.
                         #  Not used internally.
sub files_included;      # Returns an array with the names of files #included.
                         #  Not used internally.


# Internal subroutines (should not be visible)

sub get_items;
sub unget_items;
sub is_valid_identifier;
sub check_name;
sub curr_scope;
sub scope_names;
sub find_node_i;
sub parse_sequence;
sub parse_type;
sub parse_members;
sub error;
sub info;
sub abort;
sub cvt_expr;
sub require_end_of_stmt;
sub idlsplit;
sub get_files_included;
sub dump_symbols_internal;

# Auxiliary (non-visible) global stuff ########################################

# The @predef_types array must have the types in the same order as
# the numeric order of type identifying constants defined above.
my @predef_types = qw/ none boolean octet char wchar short long long_long
                       unsigned_short unsigned_long unsigned_long_long
                       float double long_double string wstring Object
                       TypeCode any fixed bounded_string bounded_wstring
                       sequence enum typedef native struct union case default
                       exception const module interface interface_fwd
                       valuetype valuetype_fwd valuetype_box
                       attribute oneway void factory method
                       include pragma_prefix pragma_version pragma_id pragma /;
my @infilename = ();    # infilename and line_number move in parallel.
my @line_number = ();
my @remark = ();        # Auxiliary to comment processing
my @post_comment = ();  # Auxiliary to comment processing
my @global_items = ();  # Auxiliary to sub unget_items
my %findnode_cache = (); # Auxiliary to find_node_i(): cache for lookups
my $in_valuetype = 0;   # Auxiliary to valuetype processing
my $abstract = 0;
my $currfile = -1;
my $emucpp = 1;         # use C preprocessor emulation
my $verbose = 0;        # report progress to stdout

sub locate_executable {
    # FIXME: this is probably another reinvention of the wheel.
    # Should look for builtin Perl solution or CPAN module that does this.
    my $executable = shift;
    # my $pathsep = $Config{'path_sep'};
    my $pathsep = ':';
    my $fully_qualified_name = "";
    my @dirs = split(/$pathsep/, $ENV{'PATH'});
    foreach (@dirs) {
        my $fqn = "$_/$executable";
        if (-e $fqn) {
            $fully_qualified_name = $fqn;
            last;
        }
    }
    $fully_qualified_name;
}


sub idlsplit {
    my $str = shift;
    my $in_string = 0;
    my $in_lit = 0;
    my $in_space = 0;
    my $i;
    my @out = ();
    my $ondx = -1;
    for ($i = 0; $i < length($str); $i++) {
        my $ch = substr($str, $i, 1);
        if ($in_string) {
            $out[$ondx] .= $ch;
            if ($ch eq '"' and substr($str, $i-1, 1) ne "\\") {
                $in_string = 0;
            }
        } elsif ($ch eq '"') {
            $in_string = 1;
            $out[++$ondx] = $ch;
        } elsif ($ch eq "'") {
            my $endx = index $str, "'", $i + 2;
            if ($endx < $i + 2) {
                error "cannot find closing apostrophe of char literal";
                return @out;
            }
            $out[++$ondx] = substr($str, $i, $endx - $i + 1);
            # print "idlsplit: $out[$ondx]\n";
            $i = $endx;
        } elsif ($ch =~ /[a-z_0-9\.]/i) {
            if (! $in_lit) {
                $in_lit = 1;
                $ondx++;
            }
            $out[$ondx] .= $ch;
        } elsif ($in_lit) {
            $in_lit = 0;
            # do preprocessor substitution
            if (exists $active_defines{$out[$ondx]}) {
                my $value = $active_defines{$out[$ondx]};
                if ("$value" ne "") {
                    my @addl = idlsplit($value);
                    push @out, @addl;
                    $ondx = $#out;
                }
            }
            if ($ch !~ /\s/) {
                $out[++$ondx] = $ch;
            }
        } elsif ($ch !~ /\s/) {
            $out[++$ondx] = $ch;
        }
    }
    # For simplification of further processing:
    # 1. Turn extra-long and unsigned types into single keyword
    #      long double => long_double
    #      unsigned short => unsigned_short
    # 2. Put scoped names back together, e.g. 'A' ':' ':' 'B' => 'A::B'
    #    Also, discard global-scope designators. (leading ::)
    # 3. Put the sign and value of negative numbers back together
    for ($i = 0; $i < $#out - 1; $i++) {
        if ($out[$i] eq 'long') {
            if ($out[$i+1] eq 'long' or $out[$i+1] eq 'double') {
                $out[$i] .= '_' . $out[$i + 1];
                splice @out, $i + 1, 1;
            }
        } elsif ($out[$i] eq 'unsigned') {
            if ($out[$i+1] eq 'short' or $out[$i+1] eq 'long') {
                $out[$i] .= '_' . $out[$i + 1];
                splice @out, $i + 1, 1;
                if ($out[$i+1] eq 'long') {
                    $out[$i] .= '_long';
                    splice @out, $i + 1, 1;
                }
            }
        } elsif ($out[$i] eq ':' and $out[$i+1] eq ':') {
            splice @out, $i, 2;
            if ($i > 0) {
                if ($out[$i - 1] eq 'CORBA') {
                    $out[$i - 1] = $out[$i];   # discard CORBA namespace
                } else {
                    $out[$i - 1] .= '::' . $out[$i];
                }
                splice @out, $i--, 1;
            }
        } elsif ($out[$i] eq '-' and $out[$i+1] =~ /^\d/) {
            $out[$i] .= $out[$i + 1];
            splice @out, $i + 1, 1;
        }
    }
    # Bounded strings are special-cased:
    # compress the notation "string<bound>" into one element
    for ($i = 0; $i < $#out - 1; $i++) {
        if ($out[$i] =~ /^w?string$/
            and $out[$i+1] eq '<' && $out[$i+3] eq '>') {
            my $bound = $out[$i+2];
            $out[$i] .= '<' . $bound . '>';
            splice @out, $i + 1, 3;
        }
    }
    @out;
}


sub is_elementary_type {
    # Returns the type index of an elementary type,
    # or 0 if the type is not elementary.
    my $tdesc = shift;                 # argument: a type descriptor
    my $recurse_into_typedef = 0;      # optional argument
    if (@_) {
        $recurse_into_typedef = shift;
    }
    my $rv = 0;
    if ($tdesc >= BOOLEAN && $tdesc <= ANY) {
        # For our purposes, sequences, bounded strings, enums, structs and
        # unions do not count as elementary types. They are represented as a
        # further node, i.e. the argument to is_elementary_type is not a
        # numeric constant, but instead contains a reference to the defining
        # node.
        $rv = $tdesc;
    } elsif ($recurse_into_typedef && isnode($tdesc) &&
             $$tdesc[TYPE] == TYPEDEF) {
        my @origtype_and_dim = @{$$tdesc[SUBORDINATES]};
        my $dimref = $origtype_and_dim[1];
        unless ($dimref && @{$dimref}) {
            $rv = is_elementary_type($origtype_and_dim[0], 1);
        }
    }
    $rv;
}


sub predef_type {
    my $idltype = shift;
    my $i;
    for ($i = 1; $i <= $#predef_types; $i++) {
        if ($idltype eq $predef_types[$i]) {
            return $i;
        }
    }
    if ($idltype =~ /^(w?string)\s*<(\d+)\s*>/) {
        my $type;
        $type = ($1 eq "wstring" ? BOUNDED_WSTRING : BOUNDED_STRING);
        my $string_bound = $2;
        return [ $type, $string_bound, 0, curr_scope ];
    }
    0;
}


sub is_valid_identifier {
    my $name = shift;
    if ($name !~ /^[a-z:]/i) {
        return 0;  # illegal first character
    }
    $name !~ /[^a-z0-9_:\.]/i
}

sub check_name {
    my $name = shift;
    my $msg = "name";
    if (@_) {
        $msg = shift;
    }
    unless (is_valid_identifier $name) {
        unless ($name =~ /^string<.*>$/) {
            error "illegal $msg";
        }
    }
    $name;
}


my @scopestack = ();
    # The scope stack. Elements in this stack are references to
    # MODULE or INTERFACE nodes.

sub curr_scope {
    ($#scopestack < 0 ? 0 : $scopestack[$#scopestack]);
}


sub comment {
    my $cmnt = 0;
    if (@post_comment) {
        $cmnt = [ @post_comment ];
    }
    $cmnt
}


sub parse_sequence {
    my ($argref, $symroot) = @_;
    if (shift @{$argref} ne '<') {
        error "expecting '<'";
        return 0;
    }
    my $nxtarg = shift @{$argref};
    my $type = predef_type $nxtarg;
    if (! $type) {
        $type = find_node_i($nxtarg, $symroot);
        if (! $type) {
            error "unknown sequence type";
            return 0;
        }
    } elsif ($type == SEQUENCE) {
        $type = parse_sequence($argref, $symroot);
    }
    my $bound = 0;
    $nxtarg = shift @{$argref};
    if ($nxtarg eq ',') {
        $bound = shift @{$argref};
        if ($bound =~ /\D/) {
            error "Sorry, non-numeric sequence bound is not implemented";
            return 0;
        }
        $nxtarg = shift @{$argref};
    }
    if ($nxtarg ne '>') {
        error "expecting '<'";
        return 0;
    }
    my @node = (SEQUENCE, $bound, $type, comment, curr_scope);
    \@node;
}


sub parse_type {
    my ($typename, $argref, $symtreeref) = @_;
    my $type;
    if ($typename eq 'fixed') {
        if (shift @{$argref} ne '<') {
            error "expecting '<' after 'fixed'";
            return 0;
        }
        my $digits = shift @{$argref};
        if ($digits =~ /\D/) {
            error "digit number in 'fixed' must be constant";
            return 0;
        }
        if (shift @{$argref} ne ',') {
            error "expecting comma in 'fixed'";
            return 0;
        }
        my $scale = shift @{$argref};
        if ($scale =~ /\D/) {
            error "scale number in 'fixed' must be constant";
            return 0;
        }
        if (shift @{$argref} ne '>') {
            error "expecting '>' at end of 'fixed'";
            return 0;
        }
        my @digits_and_scale = ($digits, $scale);
        $type = [ FIXED, "", \@digits_and_scale, comment, curr_scope ];
    } elsif ($typename =~ /^(w?string)<(\w+)>$/) {   # bounded string
        my $t;
        $t = ($1 eq "wstring" ? BOUNDED_WSTRING : BOUNDED_STRING);
        my $bound = $2;
        if ($bound !~ /^\d/) {
            my $boundtype = find_node_i($bound, $symtreeref);
            if (isnode $boundtype) {
                my @node = @{$boundtype};
                if ($node[TYPE] == CONST) {
                    my($basetype, $expr_ref) = @{$node[SUBORDINATES]};
                    my @expr = @{$expr_ref};
                    if (scalar(@expr) > 1 or $expr[0] !~ /^\d/) {
                        error("string bound expressions"
                              . " are not yet implemented");
                    }
                    $bound = $expr[0];
                } else {
                    error "illegal type for string bound";
                }
            } else {
                error "Cannot resolve string bound";
            }
        }
        $type = [ $t, $bound, 0, comment, curr_scope ];
    } elsif ($typename eq 'sequence') {
        $type = parse_sequence($argref, $symtreeref);
    } else {
        $type = find_node_i($typename, $symtreeref);
    }
    $type;
}


sub parse_members {
    # params:   \@symbols, \@arg, \@struct
    # returns:  -1 for error;
    #            0 for success with enclosing scope still open;
    #            1 for success with enclosing scope closed (i.e. seen '};')
    my $symtreeref = shift;
    my $argref = shift;
    my $structref = shift;
    my @arg = @{$argref};
    my %value_member_flags = ('private' => &PRIVATE, 'public' => &PUBLIC);
    while (@arg) {    # We're up here for a TYPE name
        my $first_thing = shift @arg;  # but it could also be '}'
        if ($first_thing eq '}') {
            return 1;   # return value signals closing of scope.
        }
        my $value_member_flag = 0;
        if ($in_valuetype) {
            if ($abstract) {
                error "data members not permitted in abstract valuetype";
                return -1;
            }
            unless (exists $value_member_flags{$first_thing}) {
                error "member in valuetype must be 'public' or 'private'";
                return -1;
            }
            $value_member_flag = $value_member_flags{$first_thing};
            $first_thing = shift @arg;
        }
        my $component_type = parse_type($first_thing, \@arg, $symtreeref);
        if (! $component_type) {
            error "unknown type $first_thing";
            return -1;  # return value signals error.
        }
        while (@arg) {    # We're here for VARIABLE name(s)
            my $component_name = shift @arg;
            last if ($component_name eq '}');
            check_name($component_name);
            my @dimensions = ();
            my $nxtarg = "";
            while (@arg) {    # We're here for a variable's DIMENSIONS
                $nxtarg = shift @arg;
                if ($nxtarg eq '[') {
                    my $dim = shift @arg;
                    if (shift @arg ne ']') {
                        error "expecting ']'";
                        return -1;
                    }
                    push @dimensions, $dim;
                } elsif ($nxtarg eq ',' || $nxtarg eq ';') {
                    last;
                } else {
                    error "component declaration syntax error";
                    return -1;
                }
            }
            my $node_ref = [ $component_type, $component_name,
                             [ @dimensions ] ];
            if ($in_valuetype) {
                $node_ref = [ $value_member_flag, $node_ref ];
            }
            push @{$structref}, $node_ref;
            last if ($nxtarg eq ';');
        }
    }
    0   # return value signals success with scope still open.
}


my @prev_symroots = ();
    # Stack of the roots of previously constructed symtrees.
    # Used by find_node_i() for identifying symbols.
    # Elements are added to/removed from the front of this,
    # i.e. using unshift/shift (as opposed to push/pop.)

my @fh = qw/ IN0 IN1 IN2 IN3 IN4 IN5 IN6 IN7 IN8 IN9/;
    # Input file handles (constants)

my %includetree = ();   # Roots of previously parsed includefiles
my $did_emucppmsg = 0;  # auxiliary to sub emucppmsg

my @struct = ();       # temporary storage for struct/union/exception
my @typestack = ();    # For struct/union/exception, typestack, namestack, and
my @namestack = ();    # cmntstack move in parallel.
                       # For valuetypes, only @typestack is used.
my @cmntstack = ();
    # The comment stack stores a trailing comment on the struct/union/exception
    # declaration line, e.g.
    #   struct mystruct {  // This comment is stored in @cmntstack.
    #     ...
    #   };
    # It is needed because the node is not constructed until the end of the
    # structure declaration, and members may have trailing comments which
    # would overwrite the single post_comment buffer.

sub set_verbose {
    if (@_) {
        $verbose = shift;
    } else {
        $verbose = 1;
    }
}

sub emucppmsg {
    if (! $did_emucppmsg && $verbose) {
        print "// using preprocessor emulation\n";
        $did_emucppmsg = 1;
    }
}

sub use_system_preprocessor {
    $emucpp = 0;
}

sub eval_preproc_expr {
    my @arg = @_;
    my $symbol = shift @arg;
    if ($symbol eq 'defined') {
        shift @arg;   # discard open-paren
        $symbol = shift @arg;
        if ($#arg > 0) {  # there's more than the closing-paren
            error "warning: #if not yet fully implemented\n";
        }
        return ($symbol =~ /^\d/);
    } elsif ($symbol =~ /^[A-z]/) {
        # NB: sub idlsplit has already done symbol substitution
        error "built-in preprocessor does not know how to interpret $symbol";
        return 0;
    } elsif ($symbol !~ /^\d+$/) {
        error "warning: #if expressions not yet implemented\n";
    }
    $symbol
}

sub skip_input {
    my $count = 0;
    my $in = $fh[$#infilename];
    while (<$in>) {
        next unless (/^\s*#/);
        my @arg = idlsplit($_);
        my $kw = shift @arg;
        # print (join ('|', @arg) . "\n");
        my $directive = shift @arg;
        if ($count == 0) {
            if ($directive eq 'else' || $directive eq 'endif') {
                return;
            }
            if ($directive eq 'elif') {
                if (eval_preproc_expr @arg) {
                    return;
                }
                next;
            }
        }
        if ($directive eq 'if' ||
            $directive eq 'ifdef' ||
            $directive eq 'ifndef') {
            $count++;
        } elsif ($directive eq 'endif') {
            $count--;
            if ($count <= 0) {
                return;
            }
        }
        # For #elif, the count remains the same.
    }
    error "skip_input: fell off end of file";
}


sub get_items {  # returns empty list for end-of-file or fatal error
    my $in = shift;
    my @items = ();
    if (@global_items) {
        @items = @global_items;
        @global_items = ();
        return @items;
    }
    my $first = 1;
    my $in_comment = 0;
    my $seen_token = 0;
    my $line = "";
    my $l;
    @remark = ();
    @post_comment = ();
    while (($l = <$in>)) {
        $line_number[$currfile]++;
        chomp $l;
        $l =~ s/\r//g;  # zap DOS line ending
        if ($l =~ /^\s*$/) {           # empty
            if ($in_comment) {
                if ($seen_token) {
                    push @post_comment, "";
                } else {
                    push @remark, "";
                }
            }
            next;
        }
        if ($l =~ /^\s*\/\/(.*)/) {        # single-line comment
            my $cmnt = $1;
            if ($seen_token) {
                push @post_comment, $cmnt;  # doesn't really happen (NYI)
            } else {
                push @remark, $cmnt;
            }
            next;
        }
        if ($in_comment) {
            if ($l =~ /\/\*/) {
                error "nested comments not supported!";
            }
            if ($l =~ /\*\//) {
                my $cmnt = $l;
                $cmnt =~ s/\s*\*\/.*$//;
                if ($cmnt) {
                    if ($seen_token) {
                        push @post_comment, $cmnt;
                    } else {
                        push @remark, $cmnt;
                    }
                }
                $in_comment = 0;     # end of multi-line comment
                $l =~ s/^.*\*\///;
                if ($seen_token) {
                    if ($l !~ /^\s*$/) {
                        error "unsupported comment/token combination";
                    }
                    last;
                }
                next if ($l =~ /^\s*$/);
            } else {
                if ($seen_token) {
                    push @post_comment, $l;
                } else {
                    push @remark, $l;
                }
                next;
            }
        } elsif ($l =~ /\/\*/) {       # start of multi-line comment
            my $cmntpos = pos $l;
            my $cmnt = $l;
            $cmnt =~ s/^.*\/\*//;  # remove comment start and stuff before
            $cmnt =~ s/\*\/.*$//;  # remove comment end and stuff after (if any)
            if ($l =~ /\*\//) {
                # remove comment
                $l =~ s/\/\*.*\*\///;
            } else {
                $in_comment = 1;
                # remove start of comment
                $l =~ s/\/\*.*$//;
            }
            if ($l =~ /^\s*$/) {       # If there is nothing else on the line
                push @remark, $cmnt;   # then it's a general comment
                next;
            } else {
                push @post_comment, $cmnt;  # else declare it a "post comment".
            }
        }
        if ($l =~ /\/\/(.*)$/) {
            my $cmnt = $1;
            unless ($cmnt =~ /^\s*$/) {
                push @post_comment, $cmnt;
            }
            $l =~ s/\/\/.*$//;         # discard trailing comment
        }
        $l =~ s/^\s+//;                # discard leading whitespace
        $l =~ s/\s+$//;                # discard trailing whitespace
        if ($first) {
            $first = 0;
        } else {
            $l = " $l";
        }
        $line .= $l;
        if (($line =~ /^#/)          # preprocessor directive
         or ($line =~ /[;,":\{]$/)) { #" characters declared to denote eol.
            $seen_token = 1;
            last unless $in_comment;
        }
    }
    if ($in_comment) {
        error "end of file reached while comment still open";
        $in_comment = 0;
    }
    if (! $line) {
        return ();
    }
    # sub idlsplit also does preprocessor symbol substitution.
    my @arg = idlsplit($line);
    my @tmp = @arg;
    if ($tmp[0] eq '#') {
        shift @tmp;  # discard '#'
        my $directive = shift @tmp;
        if ($directive eq 'if' || $directive eq 'elif') {
            emucppmsg;
            skip_input unless (eval_preproc_expr @tmp);
            @arg = get_items($in);
        } elsif ($directive eq 'ifdef') {
            my $symbol = shift @tmp;
            emucppmsg;
            skip_input unless ($symbol =~ /^\d/);
            @arg = get_items($in);
        } elsif ($directive eq 'ifndef') {
            my $symbol = shift @tmp;
            emucppmsg;
            skip_input if ($symbol =~ /^\d/);
            @arg = get_items($in);
        } elsif ($directive eq 'define') {
            my $symbol = shift @tmp;
            my $value = 1;
            emucppmsg;
            if (@tmp) {
                $value = join(' ', @tmp);
                print("// defining $symbol as $value\n") if ($verbose);
            }
            if (exists $active_defines{$symbol} and
                $value ne $active_defines{$symbol}) {
                if ($cache_trees) {
                    error("Redefinition of $symbol may lead to " .
                          "erroneous trees when cache_trees is used");
                } else {
                    info "info: redefining $symbol";
                }
            }
            $active_defines{$symbol} = $value;
            @arg = get_items($in);
        } elsif ($directive eq 'undef') {
            my $symbol = shift @tmp;
            emucppmsg;
            if (exists $active_defines{$symbol}) {
                if ($cache_trees) {
                    error("#undef of $symbol may lead to " .
                          "erroneous trees when cache_trees is used");
                }
                delete $active_defines{$symbol};
            }
            @arg = get_items($in);
        } elsif ($directive eq 'else') {
            # We only get to see the #else here if we were not skipping
            # the preceding #if or #elif.
            skip_input;
            @arg = get_items($in);
        } elsif ($directive eq 'endif') {
            @arg = get_items($in);
        }
    }
    @arg;
}

sub unget_items {
    @global_items = @_;
}


sub isname {
    my $txt = shift;
    $txt =~ /^[A-Za-z]/
}

sub check_union_case {
    my ($known_cases, $case) = @_;

    my $i = 0;
    if ($case->[0] == DEFAULT) {
        foreach (@$known_cases) {
            next if $i++ == 0;
            if ($_->[0] == DEFAULT) {
                error "duplicate default label";
                return 1;
            }
        }
    } else {
        my $type = root_type($known_cases->[0]);
        my $c;
        if (is_a($type, ENUM)) {
            # check if value is part of enumeration
            # (ignores scope for now...)
            foreach $c (@{$case->[2]}) {
                my $e = (split "::", $c)[-1];
                my $found = 0;
                foreach (@{$type->[SUBORDINATES]}) {
                    $found = 1, last if $_ eq $e;
                }
                unless ($found) {
                    error "invalid case value $c";
                    return 1;
                }
            }
        } elsif (is_a($type, BOOLEAN)) {
            foreach $c (@{$case->[2]}) {
                unless ($c eq "TRUE" || $c eq "FALSE") {
                    error "invalid case value $c";
                    return 1;
                }
            }
        } elsif (is_a($type, CHAR)) {
            foreach $c (@{$case->[2]}) {
                unless ($c =~ /^'.*'$/ || $c =~ /^\d+$/) {
                    error "invalid case value $c";
                    return 1;
                }
            }
        } else {
            # must be integer
            foreach $c (@{$case->[2]}) {
                unless ($c =~ /^[-+]?\d+$/) {
                    error "invalid case value $c";
                    return 1;
                }
            }
        }
        foreach (@$known_cases) {
            next if $i++ == 0;
            next unless $_->[0] == CASE;
            foreach (@{$_->[2]}) {
                foreach $c (@{$case->[2]}) {
                    if ($c eq $_) {
                        error "duplicate case label $c";
                        return 1;
                    }
                }
            }
        }
    }
    return 0;
}


sub Parse_File {
    @infilename = ();    # infilename and line_number move in parallel.
    @line_number = ();
    $n_errors = 0;       # auxiliary to sub error
    @remark = ();        # Auxiliary to comment processing
    @post_comment = ();  # Auxiliary to comment processing
    $in_valuetype = 0;   # Auxiliary to valuetype processing
    $abstract = 0;
    $currfile = -1;
    unless ($cache_trees) {
        %includetree = ();   # Roots of previously parsed includefiles
    }
    $did_emucppmsg = 0;  # auxiliary to sub emucppmsg
    @scopestack = ();
    @prev_symroots = ();
    %active_defines = %defines;
    Parse_File_i(@_);
}

sub Parse_File_i {
    my ($file, $input_filehandle, $symb) = @_;

#    my $file = shift;
#    my $input_filehandle = "";
#    if (@_) {
#        $input_filehandle = shift;   # internal use only
#    }

    my @vt_inheritance = (0, 0);
    my $in;
    my $custom = 0;
    $abstract = 0;
    if ($file) {        # Process a new file (or includefile if cpp emulated)
        -e "$file" or abort("Cannot find file $file");
        # remove "//" from filename to ensure correct filename match
        $file =~ s:/+:/:g;
        push @infilename, $file;
        push @line_number, 0;
        $currfile = $#infilename;
        $in = $fh[$currfile];
        my $cppcmd = "";
        unless ($emucpp) {
            # Try to find and run the C preprocessor.
            # Use `cpp' in preference of `cc -E' if the former can be found.
            # If no preprocessor can be found, we will try to emulate it.
            if (locate_executable 'cpp') {
                $cppcmd = 'cpp';
            } elsif (locate_executable 'gcc') {
                $cppcmd = 'gcc -E -x c++';
            } else {
                $emucpp = 1;
            }
        }
        if ($emucpp) {
            open($in, $file) or abort("Cannot open file $file");
        } else {
            my $cpp_args = "";
            foreach (keys %defines) {
                $cpp_args .= " -D$_=" . $defines{$_};
            }
            foreach (@include_path) {
                $cpp_args .= " -I$_";
            }
            open($in, "$cppcmd $cpp_args $file |")
                 or abort("Cannot open file $file");
        }
        print("// processing: $file\n") if ($verbose);
    } elsif ("$input_filehandle") {
        $in = $input_filehandle;  # Process a module or interface within file.
    }

    # symbol tree that will be constructed here
    my $symbols;
    if ($symb) {
        $symbols = $symb;
    } else {
        $symbols = [ ];
    }
    # @struct, @typestack, @namestack, @cmntstack use to be my() vars here.
    # They were moved to the global scope in order to support #include
    # statements at arbitrary locations.
    my @arg;
    while ((@arg = get_items($in))) {
        if ($verbose > 1) {
            my $line = join(' ', @arg);
            print "IDLtree: parsing $line\n";   # "super verbose mode"
        }
        if ($enable_comments && @remark) {
            my $remnode_ref = [ REMARK, [ @remark ], 0, 0, curr_scope ];
            if (@typestack) {
                if ($in_valuetype) {
                    push @struct, [ 0, $remnode_ref ];
                } else {
                    push @struct, $remnode_ref;
                }
            } else {
                push @$symbols, $remnode_ref;
            }
            @remark = ();
        }
        my $cmnt = comment;
        KEYWORD:
        my $kw = shift @arg;
        if ($kw eq '#') {
            my $directive = shift @arg;
            if ($directive eq 'pragma') {
                my @pragma_node;
                $directive = shift @arg;
                if ($directive eq 'prefix') {
                    my $prefix = shift @arg;
                    if (substr($prefix, 0, 1) ne '"') {
                        error "prefix should be given in double quotes";
                    } else {
                        $prefix = substr($prefix, 1);
                        if (substr($prefix, length($prefix) - 1) ne '"') {
                            error "missing closing quote";
                        } else {
                            $prefix = substr($prefix, 0, length($prefix) - 1);
                        }
                    }
                    @pragma_node = (PRAGMA_PREFIX, $prefix, 0, $cmnt,
                                    curr_scope);
                } elsif ($directive eq 'version') {
                    my $unitname = shift @arg;
                    my $vstring = shift @arg;
                    @pragma_node = (PRAGMA_VERSION, $unitname, $vstring, $cmnt,
                                    curr_scope);
                } elsif (uc($directive) eq 'ID') {
                    my $unitname = shift @arg;
                    my $idstring = shift @arg;
                    @pragma_node = (PRAGMA_ID, $unitname, $idstring, $cmnt,
                                    curr_scope);
                } else {
                    my $rest_of_line = join ' ', @arg;
                    @pragma_node = (PRAGMA, $directive, $rest_of_line, $cmnt,
                                    curr_scope);
                }
                push @$symbols, \@pragma_node;
            } elsif ($directive eq 'include') {
                my $filename = shift @arg;
                emucppmsg;
                if (substr($filename, 0, 1) ne '"') {
                    error "include file name should be given in double quotes";
                } else {
                    $filename = substr($filename, 1);
                    if (substr($filename, length($filename) - 1) ne '"') {
                        error "missing closing quote";
                    } else {
                        $filename = substr($filename, 0, length($filename) - 1);
                    }
                }
                $filename =~ s/\\/\//g;  # convert DOS path to Unix
                my $found = 1;
                if (not -e "$filename") {
                    $found = 0;
                    foreach (@include_path) {
                        if (-e "$_/$filename") {
                            $filename = "$_/$filename";
                            $found = 1;
                            last;
                        }
                    }
                }
                $found or abort ("Cannot find file $filename");
                my $in_global_scope = 1;
                if (@typestack || @scopestack) {
                    $in_global_scope = 0;
                }
                my $include_node = [ INCFILE, $filename, 0, $cmnt, curr_scope ];
                my $incfile_contents_ref;
                if (exists $includetree{$filename}) {
                    $incfile_contents_ref = $includetree{$filename};
                } else {
                    unshift @prev_symroots, $symbols;
                    if ($in_global_scope) {
                        push @scopestack, $include_node;
                    }
                    $incfile_contents_ref = Parse_File_i($filename, undef, []);
                    $incfile_contents_ref or abort("can't go on, sorry");
                    $includetree{$filename} = $incfile_contents_ref;
                    shift @prev_symroots;
                    if ($in_global_scope) {
                        pop @scopestack;
                    }
                }
                if ($in_global_scope) {
                    $$include_node[SUBORDINATES] = $incfile_contents_ref;
                    push @$symbols, $include_node;
                } else {
                    foreach (@$incfile_contents_ref) {
                        push @$symbols, $_;
                    }
                }
            } elsif ($directive =~ /^\d/) {
                # It's an output from the C preprocessor generated for
                # a "#include"
                my $linenum = $directive;
                $linenum =~ s/^(\d+)/$1/;
                my $filename = shift @arg;
                $filename = substr($filename, 1, length($filename) - 2);
                $filename =~ s@^./@@;
                $filename =~ s:/+:/:g;
                if ($filename eq $infilename[$currfile]) {
                    $line_number[$currfile] = $linenum;
                    next;
                }
                my $seen_file = 0;
                my $i;
                for ($i = 0; $i <= $#infilename; $i++) {
                    if ($filename eq $infilename[$i]) {
                        $currfile = $i;
                        $line_number[$currfile] = $linenum;
                        $seen_file = 1;
                        last;
                    }
                }
                last if ($seen_file);
                push @infilename, $filename;
                $currfile = $#infilename;
                $line_number[$currfile] = $linenum;
                unshift @prev_symroots, $symbols;
                my $incfile_contents_ref = Parse_File_i("", $in, []);
                $incfile_contents_ref or abort("can't go on, sorry");
                shift @prev_symroots;
                my @include_node = (INCFILE, $filename,
                                    $incfile_contents_ref, $cmnt, curr_scope);
                push @$symbols, \@include_node;
            } elsif ($directive eq 'if' ||
                     $directive eq 'ifdef' ||
                     $directive eq 'ifndef' ||
                     $directive eq 'elif' ||
                     $directive eq 'else' ||
                     $directive eq 'endif' ||
                     $directive eq 'define' ||
                     $directive eq 'undef') {
                # Sanity check only -
                # preprocessor conditions and definitions were already handled
                # in sub get_items and do not appear here.
                error "internal error - seen #$directive in Parse_File_i\n";
            } else {
                info "ignoring preprocessor directive \#$directive\n";
            }
            next;

        } elsif ($kw eq '}') {
            if (shift @arg ne ';') {
                error "missing ';'";
            }
            unless (@typestack) {  # must be closing of module or interface
                if (@scopestack) {
                    pop @scopestack;
                } else {
                    error('unexpected };');
                }
                return $symbols;
            }
            my $type = pop @typestack;
            if ($type == VALUETYPE) {
                # Treating of valuetypes is asymmetric to struct/union here
                # because the value node was pushed onto @$symbols early
                # in order to support recursive value type definitions.
                my @symarray = @$symbols;
                my $vnoderef = $symarray[$#symarray];
                my @obvsub = ($abstract, [ @vt_inheritance ], [ @struct ]);
                ${$vnoderef}[SUBORDINATES] = [ @obvsub ];
                $abstract = 0;
                $in_valuetype = 0;
                @vt_inheritance = (0, 0);
            } else {
                my $name = pop @namestack;
                my $cmnt = pop @cmntstack;
                if ($type == UNION && is_a($struct[0], ENUM)) {
                    # For the case of ENUM, check that all enum values
                    # are covered by CASEs.
                    my $maybe_dflt = $struct[$#struct - 1];
                    # No check possible if DEFAULT given.
                    unless ($$maybe_dflt[TYPE] == DEFAULT) {
                        my $enumtype = root_type($struct[0]);
                        my %lits_given = ();
                        my $umember;
                        foreach $umember (@struct) {
                            if ($$umember[TYPE] == CASE) {
                                foreach (@{$$umember[SUBORDINATES]}) {
                                    my $stripped_lit = $_;
                                    $stripped_lit =~ s/^.*:://;
                                    $lits_given{$stripped_lit} = 1;
                                }
                            }
                        }
                        foreach (@{$$enumtype[SUBORDINATES]}) {
                            unless (defined $lits_given{$_}) {
                                info("$name info: no case for enum value "
                                     . $_ . " given");
                            }
                        }
                    }
                }
                my @structnode = ($type, $name, 0, $cmnt, curr_scope);
                $structnode[SUBORDINATES] = [ @struct ];
                push @$symbols, \@structnode;
            }
            @struct = ();
            next;

        } elsif ($kw eq 'module') {
            my $name = check_name(shift @arg);
            error("expecting '{'") if (shift(@arg) ne '{');
            my $subord;
            my $fullname = $name;
            my @scope = scope_names();
            if (@scope) {
                $fullname = join('::', @scope) . "::$name";
            }
            my $module = 0;
            if ($support_module_reopening) {
                $module = find_node_i($fullname, $symbols, 1);
            }
            if ($module) {
                my @mnode = @$module;
                if ($mnode[TYPE] != MODULE) {
                    error "attempt to reopen something that is not a module";
                    next;
                }
                my $outer = $mnode[SCOPEREF];
                if ($outer && $$outer[TYPE] == INCFILE) {
                    my $osubord = $$outer[SUBORDINATES];
                    my $i;
                    for ($i = 0; $i < scalar(@$osubord); $i++) {
                        if ($$osubord[$i] == $module) {
                            splice @$osubord, $i, 1;
                            last;
                        }
                    }
                    push @$symbols, $module;
                }
                $subord = $mnode[SUBORDINATES];
            } else {
                $subord = [ ];
                $module = [ MODULE, $name, $subord, $cmnt, curr_scope ];
                push @$symbols, $module;
                unshift @prev_symroots, $symbols;
            }
            push @scopestack, $module;
            Parse_File_i("", $in, $subord) or abort("can't go on, sorry");
            unless ($module) {
                shift @prev_symroots;
            }
            next;

        } elsif ($kw eq 'interface') {
            my $name = check_name(shift @arg);
            my $subord = [ ];
            my @symnode = (INTERFACE, $name, $subord, $cmnt, curr_scope);
            my $lasttok = pop(@arg);
            if ($lasttok eq ';') {
                $symnode[TYPE] = INTERFACE_FWD;
                push @$symbols, \@symnode;
                next;
            } elsif ($lasttok ne '{') {
                error "expecting '{'";
                next;
            }
            my $fwd = find_node_i($name, $symbols);
            if ($fwd) {
                if ($$fwd[TYPE] != INTERFACE_FWD) {
                    error "type of interface fwd decl is not INTERFACE_FWD";
                    next;
                }
                $$fwd[SUBORDINATES] = \@symnode;
            }
            my @ancestor = ();
            if (@arg) {    # we have ancestors
                if (shift @arg ne ':') {
                    error "syntax error";
                    next;
                } elsif (! @arg) {
                    error "expecting ancestor(s)";
                    next;
                }
                my $i;  # "use strict" wants it.
                for ($i = 0; $i < @arg; $i++) {
                    my $name = check_name($arg[$i], "ancestor name");
                    my $ancestor_node = find_node_i($name, $symbols);
                    if (! $ancestor_node) {
                        error "could not find ancestor $name";
                        next;
                    }
                    push @ancestor, $ancestor_node;
                    if ($i < $#arg) {
                        if ($arg[++$i] ne ',') {
                            error "expecting comma separated list of ancestors";
                            last;
                        }
                    }
                }
            }
            push @$symbols, \@symnode;
            unshift @prev_symroots, $symbols;
            push @scopestack, \@symnode;
            Parse_File_i("", $in, $subord)
              or abort("can't go on, sorry");
            shift @prev_symroots;
            unshift @$subord, \@ancestor, $abstract;
#            my @iface_nodes = (\@ancestor, $abstract, @{$iface_contents_ref});
#            my $iface_ref = $symbols->[$#$symbols];
#            $$iface_ref[SUBORDINATES] = \@iface_nodes;
            $abstract = 0;
            next;

        } elsif ($kw eq 'abstract') {
            $abstract = 1;
            goto KEYWORD;

        } elsif ($kw eq 'custom') {
            $custom = 1;
            goto KEYWORD;

        } elsif ($kw eq 'valuetype') {
            my $name = check_name(shift @arg);
            my @symnode = (VALUETYPE, $name, 0, $cmnt, curr_scope);
            push @$symbols, \@symnode;
            my $nxttok = shift @arg;
            if ($nxttok eq ';') {
                $symnode[TYPE] = VALUETYPE_FWD;
                # Aliased to $symbols[$#symbols]
                next;
            }
            my @ancestors = ();  # do the inheritance jive
            my $seen_ancestors = 0;
            if ($nxttok eq ':') {
                if (($nxttok = shift @arg) eq 'truncatable') {
                    $vt_inheritance[0] = 1;
                    $nxttok = shift @arg;
                }
                while (isname($nxttok) and $nxttok ne 'supports') {
                    my $anc_type = find_node_i($nxttok, $symbols);
                    if (! isnode($anc_type)
                        || ($$anc_type[TYPE] != VALUETYPE &&
                            $$anc_type[TYPE] != VALUETYPE_BOX &&
                            $$anc_type[TYPE] != VALUETYPE_FWD)) {
                        error "ancestor $nxttok must be valuetype";
                    } else {
                        push @ancestors, $anc_type;
                    }
                    last unless (($nxttok = shift @arg) eq ',');
                    $nxttok = shift @arg;
                }
                $seen_ancestors = 1;
            }
            if ($nxttok eq 'supports') {
                while (isname($nxttok = shift @arg)) {
                    my $anc_type = find_node_i($nxttok, $symbols);
                    if (! $anc_type) {
                        error "unknown ancestor $nxttok";
                    } elsif (! isnode($anc_type)
                             || $$anc_type[TYPE] != INTERFACE
                             || $$anc_type[TYPE] != INTERFACE_FWD) {
                        error "ancestor $nxttok must be interface";
                    } else {
                        push @ancestors, $anc_type;
                    }
                    last unless (($nxttok = shift @arg) eq ',');
                    $nxttok = shift @arg;
                }
                $seen_ancestors = 1;
            }
            if ($seen_ancestors) {
                if ($nxttok ne '{') {
                    error "expecting '{' at valuetype declaration";
                }
                $vt_inheritance[1] = [ @ancestors ];
            } elsif (isname $nxttok) {
                # suspect a value box
                my $type = parse_type($nxttok, \@arg, $symbols);
                if ($type) {
                    $symnode[TYPE] = VALUETYPE_BOX;
                    $symnode[SUBORDINATES] = $type;
                    # Aliased to $symbols[$#symbols]
                } else {
                    error "value box: unknown type $nxttok";
                }
                next;
            } elsif ($nxttok ne '{') {
                error "expecting '{' at valuetype declaration";
            }
            my $fwd = find_node_i($name, $symbols);
            if ($fwd && $$fwd[TYPE] == VALUETYPE_FWD) {
                $$fwd[SUBORDINATES] = \@symnode;
            }

            push @typestack, VALUETYPE;
            # NB: @namestack and @cmntstack do not move in parallel here
            # (unnecessary because the value node was already pushed onto
            # @$symbols)
            if (@struct) {
                error "previous struct unfinished at valuetype (?)";
                @struct = ();
            }
            $in_valuetype = 1;
            if (@arg) {
                if ($arg[0] eq '}' or
                        parse_members($symbols, \@arg, \@struct) == 1) {
                    # end of type declaration was encountered
                    my @obvsub = ($abstract, [ @vt_inheritance ], [ @struct ]);
                    $symnode[SUBORDINATES] = \@obvsub;
                    # \@symnode is aliased to $symbols[$#symbols]
                    $abstract = 0;
                    @vt_inheritance = (0, 0);
                    pop @typestack;
                    @struct = ();
                    $in_valuetype = 0;
                }
            }
            next;

        } elsif ($kw eq 'struct' or $kw eq 'exception') {
            my $type;
            $type = ($kw eq 'struct' ? STRUCT : EXCEPTION);
            my $name = check_name(shift @arg);
            push @typestack, $type;
            push @namestack, $name;
            push @cmntstack, $cmnt;
            if (shift @arg ne '{') {
                error "expecting '{'";
                next;
            }
            @struct = ();
            if (@arg) {
                if ($arg[0] eq '}' or
                        parse_members($symbols, \@arg, \@struct) == 1) {
                    # end of type declaration was encountered
                    my @node = ($type, $name, [ @struct ], $cmnt, curr_scope);
                    push @$symbols, \@node;
                    pop @cmntstack;
                    pop @namestack;
                    pop @typestack;
                    @struct = ();
                }
            }
            next;

        } elsif ($kw eq 'union') {
            my $name = check_name(shift @arg, "type name");
            push @typestack, UNION;
            push @namestack, $name;
            push @cmntstack, $cmnt;
            if (shift(@arg) ne 'switch') {
                error "union: expecting keyword 'switch'";
                next;
            }
            if (shift @arg ne '(') {
                error "expecting '('";
                next;
            }
            my $switchtypename = shift @arg;
            my $switchtype = find_node_i($switchtypename, $symbols);
            if (! $switchtype) {
                error "unknown type of switch variable";
                next;
            } elsif (isnode $switchtype) {
                my $typ = ${$switchtype}[TYPE];
                if ($typ < BOOLEAN ||
                     ($typ > ULONG && $typ != ENUM && $typ != TYPEDEF)) {
                    error "illegal switch variable type (node; $typ)";
                    next;
                }
            } elsif ($switchtype < BOOLEAN || $switchtype > ULONGLONG) {
                error "illegal switch variable type ($switchtype)";
                next;
            }
            error("expecting ')'") if (shift @arg ne ')');
            error("expecting '{'") if (shift @arg ne '{');
            error("ignoring excess characters") if (@arg);
            @struct = ($switchtype);
            next;

        } elsif ($kw eq 'case' or $kw eq 'default') {
            my @node;
            my @casevals = ();
            if ($kw eq 'case') {
                while (@arg) {
                    push @casevals, shift @arg;
                    if (shift @arg ne ':') {
                        error "expecting ':'";
                        last;
                    }
                    last unless (@arg);
                    last unless ($arg[0] eq 'case');
                    shift @arg;
                }
                if (! @arg) {
                    # Peek ahead at following lines.  If they contain further
                    # CASEs then append them to @casevals.
                    while ((@arg = get_items($in))) {
                        $kw = shift @arg;
                        unless ($kw eq 'case') {
                            unshift @arg, $kw;
                            unget_items(@arg);
                            @arg = ();
                            last;
                        }
                        if ($arg[$#arg] eq ';') {
                            pop @arg;
                        }
                        while (@arg) {
                            push @casevals, shift @arg;
                            if (shift @arg ne ':') {
                                error "expecting ':'";
                                last;
                            }
                            last unless (@arg);
                            last unless ($arg[0] eq 'case');
                            shift @arg;
                        }
                        last if (@arg);
                    }
                }
                @node = (CASE, "", \@casevals);
            } else {
                if (shift @arg ne ':') {
                    error "expecting ':'";
                    next;
                }
                @node = (DEFAULT, "", 0);
            }
            check_union_case(\@struct, \@node);
            push @struct, \@node;
            if (@arg) {
                if (parse_members($symbols, \@arg, \@struct) == 1) {
                    # end of type declaration was encountered
                    if ($#typestack < 0) {
                        error "internal error 1";
                        next;
                    }
                    my $type = pop @typestack;
                    my $name = pop @namestack;
                    my $initial_cmnt = pop @cmntstack;
                    if ($initial_cmnt) {
                        if ($cmnt) {
                            unshift @$cmnt, @$initial_cmnt;
                        } else {
                            $cmnt = $initial_cmnt;
                        }
                    }
                    if ($type != UNION) {
                        error "internal error 2";
                        next;
                    }
                    my @unionnode = ($type, $name, [ @struct ], $cmnt,
                                     curr_scope);
                    push @$symbols, \@unionnode;
                    @struct = ();
                }
            }
            next;
        }

        if (! require_end_of_stmt(\@arg, $in)) {
            error "statement not terminated";
            next;
        }

        if ($kw eq 'native') {
            my $name = check_name(shift @arg, "type name");
            my @node = (NATIVE, $name, 0, $cmnt, curr_scope);
            push @$symbols, \@node;

        } elsif ($kw eq 'const') {
            my $type = shift @arg;
            my $name = shift @arg;
            if (shift(@arg) ne '=') {
                error "expecting '='";
                next;
            }
            my $typething = find_node_i($type, $symbols);
            unless ($typething) {
                error "unknown const type $type";
                next;
            }
            # Check basic validity of the RHS expression.
            foreach (@arg) {
                next if (/^\d/ or /^\.\d/ or /^-\d/);   # numeric constant
                next if (/^'.*'$/ or /^".*"$/);         # character or string
                next if is_valid_identifier $_;         # identifier
                # Check against predefined operands.
                my $arg = $_;
                my @operands = ( '+', '-', '*', '/', '%', '<<', '>>', '~',
                                 '^', '|', '&', '!', '||', '&&', '==', '!=',
                                 '<', '>', '<=', '>=' );
                my $is_operand = 0;
                foreach (@operands) {
                    if ($arg eq $_) {
                        $is_operand = 1;
                        last;
                    }
                }
                next if $is_operand;
                error "unknown token in CONST: $arg";
            }
            my @tuple = ($typething, [ @arg ]);
            if (isnode $typething) {
                my $id = ${$typething}[TYPE];
                if ($id < ENUM || $id > TYPEDEF) {
                    error "expecting type";
                    next;
                }
            }
            my @symnode = (CONST, $name, \@tuple, $cmnt, curr_scope);
            push @$symbols, \@symnode;

        } elsif ($kw eq 'typedef') {
            my $oldtype = check_name(shift @arg, "name of original type");
            # TO BE DONE: oldtype is STRUCT or UNION
            my $existing_typenode = parse_type($oldtype, \@arg, $symbols);
            if (! $existing_typenode) {
                error "unknown type $oldtype";
                next;
            }
            my $newtype = check_name(shift @arg, "name of newly defined type");
            my @dimensions = ();
            while (@arg) {
                if (shift(@arg) ne '[') {
                    error "expecting '['";
                    last;
                }
                my $dim = shift @arg;
                push @dimensions, $dim;
                if (shift(@arg) ne ']') {
                    error "expecting ']'";
                }
            }
            my @subord = ($existing_typenode, [ @dimensions ]);
            my @node = (TYPEDEF, $newtype, \@subord, $cmnt, curr_scope);
            push @$symbols, \@node;

        } elsif ($kw eq 'enum') {
            my $typename = check_name(shift @arg, "type name");
            if (shift @arg ne '{') {
                error("expecting '{'");
                next;
            }
            my @values = ();
            my $repres_given = grep(/=/, @arg);
            if ($repres_given) {
                info ("warning - $typename: enum representations " .
                              " are a non-standard extension\n");
            }
            my $natural_rep = 0;
            while (@arg) {
                my $lit = shift @arg;
                check_name $lit;
                if ($enable_enum_comments && @post_comment) {
                    my $tuple = [ $lit, [ @post_comment ] ];
                    push @values, $tuple;
                    @post_comment = ();
                } else {
                    push @values, $lit;
                }
                if (@arg) {
                    my $nxt = shift @arg;
                    if ($nxt eq '=') {
                        my $value = shift @arg;
                        $values[$#values] .= '=' . $value;
                        $natural_rep = $value;
                        last unless (@arg);
                        $nxt = shift @arg;
                    } elsif ($repres_given) {
                        $values[$#values] .= '=' . $natural_rep;
                        $natural_rep++;
                    }
                    last if ($nxt eq '}');
                    if ($nxt eq ',') {
                        unless (@arg) {
                            @arg = get_items($in);
                        }
                    } else {
                        error "expecting ','";
                        last;
                    }
                }
            }
            my @symnode = (ENUM, $typename, [ @values ], $cmnt, curr_scope);
            push @$symbols, [ @symnode ];

        } elsif ($kw eq 'readonly' or $kw eq 'attribute') {
            my $readonly = 0;
            if ($kw eq 'readonly') {
                if (shift(@arg) ne 'attribute') {
                    error "expecting keyword 'attribute'";
                    next;
                }
                $readonly = 1;
            }
            my $typename = shift @arg;
            my $type = parse_type($typename, \@arg, $symbols);
            if (! $type) {
                error "unknown type $typename";
                next;
            }
            my @subord = ($readonly, $type);
            my $name = check_name(shift @arg);
            my @node = (ATTRIBUTE, $name, \@subord, $cmnt, curr_scope);
            if ($in_valuetype) {
                my @value_member = (0, \@node);
                push @struct, \@value_member;
            } else {
                push @$symbols, \@node;
            }

        } elsif (grep /\(/, @arg) {   # Method declaration
            my $rettype;
            my @subord;
            if ($kw eq 'oneway') {
                if (shift(@arg) ne 'void') {
                    error "expecting keyword 'void' after oneway";
                    next;
                }
                $rettype = ONEWAY;
            } elsif ($kw eq 'void') {
                $rettype = VOID;
            } elsif ($in_valuetype and $kw eq 'factory') {
                $rettype = FACTORY;
            } else {
                $rettype = parse_type($kw, \@arg, $symbols);
                if (! $rettype) {
                    error "unknown return type $kw";
                    next;
                }
            }
            @subord = ($rettype);
            my $name = check_name(shift @arg, "method name");
            if (shift(@arg) ne '(') {
                error "expecting opening parenthesis";
                next;
            } elsif (pop(@arg) ne ')') {
                error "expecting closing parenthesis";
                next;
            }
            my @exception_list = ();
            my $expecting_exception_list = 0;
            while (@arg) {
                my $m = shift @arg;
                my $typename = shift @arg;
                my $pname = shift @arg;
                if ($m eq ')') {
                    if ($typename ne 'raises') {
                        error "expecting keyword 'raises'";
                    } elsif ($pname ne '(') {
                        error "expecting '(' after 'raises'";
                    } else {
                        $expecting_exception_list = 1;
                    }
                    last;
                }
                my $pmode;
                $pmode = ($m eq 'in' ? IN : $m eq 'out' ? OUT :
                             $m eq 'inout' ? INOUT : 0);
                if (! $pmode or $rettype == FACTORY && $pmode != IN) {
                    error("illegal mode of parameter $pname");
                    last;
                }
                my $ptype = find_node_i($typename, $symbols);
                if (! $ptype) {
                    error "unknown type of parameter $pname";
                    last;
                }
                my @param_node = ($ptype, $pname);
                push @param_node, $pmode;
                push @subord, \@param_node;
                if (@arg and $arg[0] eq ',') {
                    shift @arg;
                }
            }
            my @node = (METHOD, $name, \@subord, $cmnt, curr_scope);
            if ($in_valuetype) {
                my @value_member = (0, \@node);
                push @struct, \@value_member;
                next;
            }
            if ($expecting_exception_list) {
                while (@arg) {
                    my $exc_name = shift @arg;
                    my $exc_type = find_node_i($exc_name, $symbols);
                    if (! $exc_type) {
                        error "unknown exception $exc_name";
                        last;
                    } elsif (${$exc_type}[TYPE] != EXCEPTION) {
                        error "cannot raise $exc_name (not an exception)";
                        last;
                    }
                    push @exception_list, $exc_type;
                    if (@arg and shift @arg ne ',') {
                        error "expecting ',' in exception list";
                        last;
                    }
                }
            }
            push @{$node[SUBORDINATES]}, \@exception_list;
            push @$symbols, \@node;

        } else {                          # Data
            if ($#typestack < 0) {
                error "unexpected declaration";
                next;
            }
            unshift @arg, $kw;   # put type back into @arg
            if (parse_members($symbols, \@arg, \@struct) == 1) {
                # end of type declaration was encountered
                my $type = pop @typestack;
                if ($type == VALUETYPE) {
                    # Treating of valuetypes is asymmetric to struct/union here
                    # because the value node was pushed onto @$symbols early
                    # in order to support recursive value type definitions.
                    my @symarray = @$symbols;
                    my $vnoderef = $symarray[$#symarray];
                    my $obvsub = [ $abstract, [ @vt_inheritance ], [ @struct ] ];
                    ${$vnoderef}[SUBORDINATES] = $obvsub;
                    $abstract = 0;
                    $in_valuetype = 0;
                    @vt_inheritance = (0, 0);
                } else {
                    my $name = pop @namestack;
                    my $initial_cmnt = pop @cmntstack;
                    if ($initial_cmnt) {
                        if ($cmnt) {
                            unshift @$cmnt, @$initial_cmnt;
                        } else {
                            $cmnt = $initial_cmnt;
                        }
                    }
                    my @node = ($type, $name, [ @struct ], $cmnt, curr_scope);
                    push @$symbols, [ @node ];
                }
                @struct = ();
            }
        }
    }
    if ($verbose) {
        print "IDLtree: done with parsing $file\n";
    }
    if ($file) {
        close $in;
        pop @infilename;
        pop @line_number;
        $currfile--;
    }
    if ($n_errors) {
        return 0;
    }
    bless($symbols, "CORBA::IDLtree") unless $symb;
    return $symbols;
}


sub require_end_of_stmt {
    my ($argref, $file) = @_;
    if ($$argref[$#$argref] eq ';') {
        pop @{$argref};
        return 1;
    }
    my @new_items;
    while ($$argref[$#$argref] ne ';') {
        last if (! (@new_items = get_items($file)));
        push @{$argref}, @new_items;
    }
    if ($$argref[$#$argref] eq ';') {
        pop @{$argref};
        return 1;
    }
    0;
}


sub isnode {
    my $node_ref = shift;

    return ref($node_ref)
        && @$node_ref == 5
        && $$node_ref[TYPE] >= BOOLEAN
        && $$node_ref[TYPE] < NUMBER_OF_TYPES;

    # NB: The (@$node_ref == 5) means that component descriptors of
    # structs/unions/exceptions and parameter descriptors of methods
    # do not qualify as nodes.
}


sub is_scope {
    my $thing = shift;
    my $rv = 0;
    if (isnode $thing) {
        my $type = $$thing[TYPE];
        $rv = ($type == MODULE || $type == INTERFACE || $type == INCFILE);
    }
    return $rv;
}


sub find_node_i_recursive {   # auxiliary to find_node_i()
    my ($name, $root) = @_;
    my $sep = index $name, '::';
    if ($sep < 0) {
        while ($root) {
            if (isnode $root and $name eq $$root[NAME]) {
                return $root;
            }
            my @decls;
            if (is_scope($root)) {
                @decls = @{$root->[SUBORDINATES]};
                if ($$root[TYPE] == INTERFACE) {
                    shift @decls;    # discard ancestors
                    shift @decls;    # discard abstract flag
                }
            } else {
                @decls = @{$root};
            }
            foreach (@decls) {
                if (not isnode $_) {
                    error "find_node_i_recursive: internal error 1\n";
                    last;
                }
                my @n = @{$_};
                if ($n[NAME] eq $name) {
                    return $_;
                }
                if ($n[TYPE] == INCFILE) {
                    my $result = find_node_i_recursive($name, $n[SUBORDINATES]);
                    if ($result) {
                        return $result;
                    }
                }
            }
            last unless (is_scope $root);
            $root = $root->[SCOPEREF];
        }
        return 0;
    }
    my $this_prefix = substr($name, 0, $sep);
    $name = substr($name, $sep + 2);
    while ($root) {
        if (isnode $root and $$root[NAME] eq $this_prefix) {
            return find_node_i_recursive($name, $root);
        }
        my @decls;
        if (is_scope $root) {
            @decls = @{$$root[SUBORDINATES]};
            if ($$root[TYPE] == INTERFACE) {
                shift @decls;    # discard ancestors
                shift @decls;    # discard abstract flag
            }
        } else {
            @decls = @{$root};
        }
        foreach (@decls) {
            my $result = 0;
            my @n = @{$_};
            if (is_scope $_ and $n[NAME] eq $this_prefix) {
                $result = find_node_i_recursive($name, $_);
            } elsif ($n[TYPE] == INCFILE) {
                $result = find_node_i_recursive($this_prefix, $n[SUBORDINATES]);
                if ($result) {
                    $result = find_node_i_recursive($name, $result);
                }
            }
            if ($result) {
                return $result;
            }
        }
        last unless (is_scope $root);
        $root = $$root[SCOPEREF];
    }
    return 0;
}


# Return the names of the nodes in @scopestack as a list.
sub scope_names {
    my @names = ();
    my $noderef;  # "use strict" wants it.
    foreach $noderef (@scopestack) {
        unless ($$noderef[TYPE] == INCFILE) {
            push @names, $$noderef[NAME];
        }
    }
    @names;
}


sub find_node_i {
    # Returns a reference to the defining node, or a type id value
    # if the name given is a CORBA predefined type name.
    # Returns 0 if the name could not be identified.
    my $name = shift;
    if ("$name" eq "") {
        warn "IDLtree::find_node_i() called on empty name\n";
        return 0;
    }
    my $current_symtree_ref = shift;
    my $seek_module = 0;
    if (@_) {
        $seek_module = shift;
    }
    if ($name =~ /CORBA::/) {
        $name =~ s/CORBA:://;
    }
    my @namecomponents = split(/::/, $name);
    my $nseps = scalar(@namecomponents) - 1;
    if ($nseps) {
        unless ($seek_module) {
            # Discard same-scope prefix.
            my $given_prefix = $name;
            $given_prefix =~ s/::\w+$//;
            my @scopes = scope_names;
            if (scalar(@scopes) >= $nseps) {
                my $current_prefix = join("::", splice(@scopes, -$nseps));
                if ($given_prefix eq $current_prefix) {
                    $name =~ s/^.*:://;
                    @namecomponents = split(/::/, $name);
                    $nseps = scalar(@namecomponents) - 1;
                }
            }
        }
    } else {
        my $predef_type_id = predef_type($name);
        if ($predef_type_id) {
            return $predef_type_id;
        }
    }
    # References to names in foreign scopes are hashed because searching
    # for them may be expensive with large and complex IDL files.
    # Unqualified names are not hashed in order to be able to distinguish
    # same names in different scopes - such as
    #   module m1 {
    #     typedef boolean t;
    #   };
    #   module m2 {
    #     typedef float t;
    #     ....
    #   };
    # Here, if the cache is not cleared after parsing m1, then `t' refers to
    # m1::t even when parsing m2.
    # We keep away from that problem by not caching references to local names.
    if ($nseps and exists $findnode_cache{$name}) {
        return $findnode_cache{$name};
    }
    my $noderef = find_node_i_recursive($name, $current_symtree_ref);
    if ($noderef) {
        if ($nseps) {
            $findnode_cache{$name} = $noderef;
        }
        return $noderef;
    }
    foreach $noderef (@prev_symroots) {
        my $result_node_ref = find_node_i_recursive($name, $noderef);
        if ($result_node_ref) {
            if ($nseps) {
                $findnode_cache{$name} = $result_node_ref;
            }
            return $result_node_ref;
        }
    }
    0;
}



sub info {
    my $message = shift;
    warn ($infilename[$currfile]  . " line " . $line_number[$currfile]
                  . ": $message\n");
}

sub error {
    my $message = shift;
    warn ($infilename[$currfile]  . " line " . $line_number[$currfile]
                  . ": $message\n");
    $n_errors++;
}

sub abort {
    my $message = shift;
    my $f = "";
    if ($currfile >= 0) {
        $f = $infilename[$currfile]  . " line " . $line_number[$currfile]
          . ": ";
    }
    die ($f . $message . "\n");
}


# From here on, it's only Useful User Utilities
#  (not required for IDLtree internal purposes)

sub typeof {      # Returns the string of a "type descriptor" in IDL syntax
    my $type = shift;
    my $gen_scope = 0;       # generate scope-qualified name
    if (@_) {
        $gen_scope = shift;
    }
    my $rv = "";
    if (!ref($type) && ($type >= BOOLEAN && $type < NUMBER_OF_TYPES)) {
        $rv = $predef_types[$type];
        if ($type <= ANY) {
            $rv =~ s/_/ /g;
        }
        return $rv;
    } elsif (! isnode($type)) {
        warn "internal error: parameter to typeof is not a node ($type)\n";
        return "";
    }
    my @node = @{$type};
    my $name = $node[NAME];
    my $prefix = "";
    if ($gen_scope) {
        my @tmpnode = @node;
        my @scope;
        while ((@scope = @{$tmpnode[SCOPEREF]})) {
            $prefix = $scope[NAME] . "::" . $prefix;
            @tmpnode = @scope;
        }
        if (ref $gen_scope) {
            # @gen_scope contains the scope strings.
            # Now we can decide whether the scope prefix is needed.
            my $curr_scope = join("::", @{$gen_scope});
            if ($prefix eq "${curr_scope}::") {
                $prefix = "";
            }
        }
    }
    $rv = "$prefix$name";
    if ($node[TYPE] == FIXED) {
        my @digits_and_scale = @{$node[SUBORDINATES]};
        my $digits = $digits_and_scale[0];
        my $scale = $digits_and_scale[1];
        $rv = "fixed<$digits,$scale>";
    } elsif ($node[TYPE] == BOUNDED_STRING ||
             $node[TYPE] == BOUNDED_WSTRING) {
        my $wide = "";
        if ($node[TYPE] == BOUNDED_WSTRING) {
            $wide = "w";
        }
        $rv = "${wide}string<" . $name . ">";
    } elsif ($node[TYPE] == SEQUENCE) {
        my $bound = $name;   # NAME holds the bound
        my $eltype = typeof($node[SUBORDINATES], $gen_scope);
        $rv = 'sequence<' . $eltype;
        if ($bound) {
            $rv .= ", $bound";
        }
        $rv .= '>';
    }
    $rv;
}


sub is_a {
    # Determines whether node is of given type. Recurses through TYPEDEFs.
    my ($type, $typeid) = @_;

    unless ($type) {
        warn("CORBA::IDLtree::is_a: invalid input (comparing to "
             . typeof($typeid) . ")\n");
        return 0;
    }
    if (! isnode $type) {
        if ($typeid > 0) {
            return $type == $typeid;
        } else {
            return typeof($type) eq $typeid;
        }
    }

    # check the node
    if ($typeid > 0) {
        return 1 if $type->[TYPE] == $typeid;
    } else {
        return 1 if scoped_name($type) eq $typeid;
    }
    return 0 unless $type->[TYPE] == TYPEDEF;

    # we have a typedef

    my $origtype_and_dim = $type->[SUBORDINATES];

    # array ?
    my $dimref = $$origtype_and_dim[1];
    return 0 if $dimref && @{$dimref};

    # no, recursivly check basetype
    return is_a($$origtype_and_dim[0], $typeid);
}

sub root_type {
    # Returns the original type of a TYPEDEF, i.e. recurses through
    # all non-array TYPEDEFs until the original type is reached.
    my $type = shift;
    if (isnode $type and $$type[TYPE] == TYPEDEF) {
        my($origtype, $dimref) = @{$$type[SUBORDINATES]};
        unless ($dimref && @{$dimref}) {
            return root_type($origtype);
        }
    }
    $type
}

sub root_elem_type {
    # Returns the original type of a TYPEDEF, i.e. recurses through
    # all TYPEDEFs until the original type is reached.
    my $type = shift;
    if (isnode $type and $$type[TYPE] == TYPEDEF) {
        return root_elem_type($type->[SUBORDINATES][0]);
    }
    return $type;
}


sub files_included {
    keys %includetree
}


sub get_numeric {
    my $tree = shift;
    my ($value) = @_;

    if ($value =~ /^[-+]?\d/) {
        return $value; # + 0;  Try to do without...
    }
    if (isnode($value)) {
        # only const node allowed here
        return undef unless $value->[TYPE] == CONST;
        return $tree->get_numeric($value->[SUBORDINATES][1][0]);
    }
    my $node = $tree->find_node($value);
    if (!$node || !isnode($node)) {
        warn("unknown value: $value\n");
        return $value;
    }
    return $tree->get_numeric($node);
}

##################################################################
# return a numerical array dimension
# if a number is given, return that number
# if the number of CONST is given, return the value of the CONST
#     (recursively if necessary)
sub get_dim {
    my $tree = shift;
    my ($dim) = @_;

    if ($dim =~ /^\d+$/) {
        return $dim + 0;
    }
    if (isnode($dim)) {
        if ($$dim[TYPE] == CONST) {
            return $tree->get_dim($$dim[SUBORDINATES][1][0]);
        }
        warn("array dimension must be const: ".$$dim[NAME]."\n");
        return $$dim[NAME];
    }
    my $node = $tree->find_node($dim);
    if (!$node || !isnode($node)) {
        warn("unknown array dimension: $dim\n");
        return $dim;
    }
    return $tree->get_dim($node);
}


# Subs for finding stuff

sub find_in_current_scope {  # Auxiliary to find_scope() / find_node().
    my $name = shift;
    my $scoperef = shift;
    my $must_be_scope_node = 0;
    if (@_) {
        $must_be_scope_node = shift;
    }
    return undef unless defined $scoperef->[SUBORDINATES];

    my $decls = $scoperef->[SUBORDINATES];
    my $start = 0;
    my $end = $#$decls;
    if ($scoperef->[TYPE] == INTERFACE) {
        $start = 2;
    }
    my $i;
    for ($i = $start; $i <= $end; $i++) {
        my $node = $decls->[$i];
        if (@$node > 1 && $node->[NAME] eq $name) {
            if ($must_be_scope_node and not is_scope $node) {
                warn("warning: $name also used in " .
                     scoped_name($node) . "\n");
            } else {
                return $node;
            }
        }
    }
    undef;
}

sub find_scope_i;  # Auxiliary to find_scope().

sub find_scope_i {
    my ($scopelist_ref, $currscope, $global_symroot) = @_;
    my @scopes = @{$scopelist_ref};
    # $currscope sometimes is 0 instead of undef...

    $currscope = undef unless $currscope;
    unless (defined $currscope) {
        return undef unless defined $global_symroot;

        # Try find it somewhere in $global_symroot.
      GLOBAL_SCOPES:
        foreach (@$global_symroot) {
            if ($$_[TYPE] == INCFILE) {
                foreach (@{$$_[SUBORDINATES]}) {
                    if (is_scope $_) {
                        $currscope = find_scope_i(\@scopes, $_);
                        last GLOBAL_SCOPES if $currscope;
                    }
                }
            } elsif (is_scope($_) && $scopes[0] eq $$_[NAME]) {
                # It's in this scope.
                $currscope = $_;
                last;
            }
        }
        return undef unless defined $currscope;
    }

    if ($scopes[0] eq $$currscope[NAME]) {
        # It's in the current scope.
        shift @scopes;
        while (@scopes) {
            my $sought_name = shift @scopes;
            $currscope = find_in_current_scope($sought_name, $currscope, 1);
            last unless $currscope;
        }
        return $currscope;
    }
    # Not a direct match with current scope.
    # Try the scopes nested in the current scope.
    my $scope = find_in_current_scope($scopes[0], $currscope, 1);
    if ($scope) {
        shift @scopes;
        while (@scopes) {
            my $sought_name = shift @scopes;
            $scope = find_in_current_scope($sought_name, $scope, 1);
            last unless $scope;
        }
        return $scope;
    }
    # Still no match. Step outside and try again.
    find_scope_i($scopelist_ref, $$currscope[SCOPEREF], $global_symroot);
}

sub find_scope {
    my $global_symroot = shift;
    my ($scopelist_ref, $currscope) = @_;

    my $scoperef = undef;
    $scoperef = find_scope_i($scopelist_ref, $currscope)
      if defined $currscope;

    # undef as the second arg to find_scope_i means
    # try to find it anywhere in $global_symroot.
    $scoperef = find_scope_i($scopelist_ref, undef, $global_symroot)
      unless defined $scoperef;

    $scoperef;
}

# return a list of scope names leading to the given scope
# (including the scope itself)
sub get_scope {
    my ($scoperef) = @_;
    return () unless ref($scoperef);
    return () if ($scoperef->[TYPE] == INCFILE);
    return (get_scope($scoperef->[SCOPEREF]), $scoperef->[NAME]);
}

sub find_node {
    my $global_symroot = shift;
    my ($name, $scoperef, $recurse) = @_;

    my @components = split(/::/, $name);
    my $noderef = undef;
    if (scalar(@components) > 1) {
        $name = pop @components;
        $scoperef = $global_symroot->find_scope(\@components, $scoperef);
        if (defined $scoperef) {
            $noderef = find_in_current_scope($name, $scoperef);
        }
    } elsif (defined $scoperef) {
        my $scope = $scoperef;
        while ($scope) {
            $noderef = find_in_current_scope($name, $scope);
            last if $noderef;
            $scope = $$scope[SCOPEREF];
        }
        if ($recurse && !$noderef) {
            foreach (@{$scoperef->[SUBORDINATES]}) {
                if ($$_[TYPE] == INCFILE || $$_[TYPE] == MODULE) {
                    $noderef = $global_symroot->find_node($name, $_, 1);
                    last if $noderef;
                }
            }
        }
    } else {
        foreach (@$global_symroot) {
            if ($$_[NAME] eq $name) {
                return $_;
            }
        }
        # FIXME: This is not really correct:
        #  If no scope is given, search in all scopes, recursively
        foreach (@$global_symroot) {
            if ($$_[TYPE] == INCFILE || $$_[TYPE] == MODULE) {
                $noderef = $global_symroot->find_node($name, $_, 1);
                last if $noderef;
            }
        }
    }
    $noderef
}

sub scoped_name {
    my ($node) = @_;

    if (isnode($node)) {
        my $sc = $node->[SCOPEREF];
        my @scopes = ($node->[NAME]);
        while ($sc) {
            unshift @scopes, $sc->[NAME]
              unless $sc->[TYPE] == INCFILE;
            $sc = $sc->[SCOPEREF];
        }
        return join("::", @scopes);
    } else {
        return typeof($node);
    }
}


# Dump_Symbols and auxiliary subroutines

my $dsindentlevel = 0;

sub dsemit {
    print shift;
}

sub dsdent {
    dsemit(' ' x ($dsindentlevel * 3));
    if (@_) {
        dsemit shift;
    }
}

sub dump_comment {
    my $cmnt_ref = shift;
    if ($cmnt_ref) {
        my @cmnt = @{$cmnt_ref};
        if (scalar(@cmnt) > 1) {
            dsdent "/*\n";
            foreach (@cmnt) {
                dsdent "$_\n";
            }
            dsdent " */\n";
        } else {
            dsdent "// $cmnt[0]\n";
        }
    }
}

my @dscopes;   # List of scope strings; auxiliary to sub dstypeof

sub dstypeof {
    typeof(shift, \@dscopes);
}

my $dsymroot = 0;

sub dump_symbols_internal {
    my $sym_array_ref = shift;
    if (! $sym_array_ref) {
        warn "dump_symbols_internal: empty elem (returning)\n";
        return 0;
    }
    my $status = 1;
    if (not isnode $sym_array_ref) {
        foreach (@{$sym_array_ref}) {
            unless (dump_symbols_internal $_) {
                $status = 0;
            }
        }
        return $status;
    }
    my @node = @{$sym_array_ref};
    my $type = $node[TYPE];
    my $name = $node[NAME];
    my $subord = $node[SUBORDINATES];
    dump_comment $node[REMARK];
    my @arg = @{$subord};
    my $i;
    if ($type == INCFILE || $type == PRAGMA_PREFIX) {
        if ($type == INCFILE) {
            dsemit "\#include ";
            $name =~ s@^.*/@@;
        } else {
            dsemit "\#pragma prefix ";
        }
        dsemit "\"$name\"\n\n";
        return $status;
    }
    if ($type == ATTRIBUTE) {
        dsdent;
        dsemit("readonly ") if ($arg[0]);
        dsemit("attribute " . dstypeof($arg[1]) . " $name");
    } elsif ($type == METHOD) {
        my $t = shift @arg;
        my $rettype;
        if ($t == ONEWAY) {
            $rettype = 'oneway void';
        } elsif ($t == VOID) {
            $rettype = 'void';
        } else {
            $rettype = dstypeof($t);
        }
        my @exc_list = @{pop @arg};
        dsdent($rettype . " $name (");
        if (@arg) {
            unless ($#arg == 0) {
                dsemit "\n";
                $dsindentlevel += 5;
            }
            for ($i = 0; $i <= $#arg; $i++) {
                my $pnode = $arg[$i];
                my $ptype = dstypeof($$pnode[TYPE]);
                my $pname = $$pnode[NAME];
                my $m     = $$pnode[SUBORDINATES];
                my $pmode;
                $pmode = ($m == &IN ? 'in' : $m == &OUT ? 'out' : 'inout');
                dsdent unless ($#arg == 0);
                dsemit "$pmode $ptype $pname";
                dsemit(",\n") if ($i < $#arg);
            }
            unless ($#arg == 0) {
                $dsindentlevel -= 5;
            }
        }
        dsemit ")";
        if (@exc_list) {
            dsemit "\n";
            $dsindentlevel++;
            dsdent " raises (";
            for ($i = 0; $i <= $#exc_list; $i++) {
                dsemit(${$exc_list[$i]}[NAME]);
                dsemit(", ") if ($i < $#exc_list);
            }
            dsemit ")";
            $dsindentlevel--;
        }
    } elsif ($type == VALUETYPE) {
        dsdent;
        if ($arg[0]) {          # `abstract' flag
            dsemit "abstract ";
        }
        dsemit "valuetype $name ";
        if ($arg[1]) {          # ancestor info
            my($truncatable, $ancestors_ref) = @{$arg[1]};
            if ($truncatable) {
                dsemit "truncatable ";
            }
            if (@{$ancestors_ref}) {
                dsemit ": ";
                my $first = 1;
                foreach (@{$ancestors_ref}) {
                    if ($first) {
                        $first = 0;
                    } else {
                        dsemit ", ";
                    }
                    my @ancnode = @{$_};
                    dsemit $ancnode[NAME];
                }
                dsemit ' ';
            }
        }
        dsemit "{\n";
        $dsindentlevel++;
        my $memberinfo;  # "use strict" wants it
        foreach $memberinfo (@{$arg[2]}) {
            my ($memberkind, $member) = @{$memberinfo};
            my @member = @{$member};
            my $mtype = dstypeof($member[TYPE]);
            my $mname = $member[NAME];
            dump_comment $member[COMMENT];
            if ($memberkind == PRIVATE) {
                dsdent "private $mtype $mname;\n";
                next;
            } elsif ($memberkind == PUBLIC) {
                dsdent "public $mtype $mname;\n";
                next;
            }
            # $memberkind == 0 means it's a user method.
            my @subord = @{$member[SUBORDINATES]};
            if ($member[TYPE] == ATTRIBUTE) {
                my $readonly = $subord[0];
                my $rettype = dstypeof($subord[1]);
                dsdent;
                if ($readonly) {
                    dsemit "readonly ";
                }
                dsemit "attribute $rettype $mname;\n";
            } else {  # METHOD
                dsdent dstypeof(shift @subord);
                dsemit " $mname (";
                my $first = 1;
                my $param;  # "use strict" wants it
                foreach $param (@arg) {
                    my $m = $$param[MODE];
                    if ($first) {
                        $first = 0;
                    } else {
                        dsemit ", ";
                    }
                    dsemit(($m == &IN) ? "in" : ($m == &OUT) ? "out" : "inout");
                    dsemit(" " . dstypeof($$param[TYPE]) . " $$param[NAME]");
                }
                dsemit ");\n";
            }
        }
        $dsindentlevel--;
        dsdent "}";
    } elsif ($type == MODULE || $type == INTERFACE) {
        push @dscopes, $name;
        dsdent;
        if ($type == INTERFACE && $arg[1]) {
            dsemit "abstract ";
        }
        dsemit($predef_types[$type] . " ");
        dsemit "$name ";
        if ($type == INTERFACE) {
            my $ancref = shift @arg;
            my @ancestors = @{$ancref};
            shift @arg;  # discard the "abstract" flag
            if (@ancestors) {
                dsemit ": ";
                for ($i = 0; $i <= $#ancestors; $i++) {
                    my @ancnode = @{$ancestors[$i]};
                    dsemit $ancnode[NAME];
                    dsemit(", ") if ($i < $#ancestors);
                }
            }
        }
        dsemit " {\n\n";
        $dsindentlevel++;
        foreach (@arg) {
            unless (dump_symbols_internal $_) {
                $status = 0;
            }
        }
        $dsindentlevel--;
        dsdent "}";
        pop @dscopes;
    } elsif ($type == TYPEDEF) {
        my $origtype = $arg[0];
        my $dimref = $arg[1];
        dsdent("typedef " . dstypeof($origtype) . " $name");
        if ($dimref and @{$dimref}) {
            foreach (@{$dimref}) {
                dsemit "[$_]";
            }
        }
    } elsif ($type == CONST) {
        dsdent("const " . dstypeof($arg[0]) . " $name = ");
        dsemit join(' ', @{$arg[1]});
    } elsif ($type == ENUM) {
        dsdent "enum $name { ";
        if ($#arg > 4) {
            $dsindentlevel += 5;
            dsemit "\n";
        }
        for ($i = 0; $i <= $#arg; $i++) {
            dsdent if ($#arg > 4);
            dsemit $arg[$i];
            if ($i < $#arg) {
                dsemit(", ");
                dsemit("\n") if ($#arg > 4);
            }
        }
        if ($#arg > 4) {
            $dsindentlevel -= 5;
            dsemit "\n";
            dsdent "}";
        } else {
            dsemit " }";
        }
    } elsif ($type == STRUCT || $type == UNION || $type == EXCEPTION) {
        dsdent($predef_types[$type] . " $name");
        if ($type == UNION) {
            dsemit(" switch (" . dstypeof(shift @arg) . ")");
        }
        dsemit " {\n";
        $dsindentlevel++;
        my $had_case = 0;
        while (@arg) {
            my $node = shift @arg;
            my $type = $$node[TYPE];
            my $name = $$node[NAME];
            my $suboref = $$node[SUBORDINATES];
            dump_comment $$node[COMMENT];
            if ($type == CASE || $type == DEFAULT) {
                if ($had_case) {
                    $dsindentlevel--;
                } else {
                    $had_case = 1;
                }
                if ($type == CASE) {
                    foreach (@{$suboref}) {
                       dsdent "case $_:\n";
                    }
                } else {
                    dsdent "default:\n";
                }
                $dsindentlevel++;
            } else {
                foreach (@{$suboref}) {
                    $name .= '[' . $_ . ']';
                }
                dsdent(dstypeof($type) . " $name;\n");
            }
        }
        $dsindentlevel -= $had_case + 1;
        dsdent "}";
    } elsif ($type == INTERFACE_FWD) {
        dsdent "interface $name";
    } else {
        warn("Dump_Symbols: unknown type " . dstypeof($type) . "\n");
        $status = 0;
    }
    dsemit ";\n\n";
    $status
}


sub Dump_Symbols {
    my $sym_array_ref = shift;
    $dsymroot = $sym_array_ref;
    dump_symbols_internal $sym_array_ref
}

# End of Dump_Symbols stuff.


# traverse_tree stuff.

my $user_sub_ref = 0;
my $traverse_includefiles = 0;

sub traverse {
    my ($symroot, $scope, $inside_includefile) = @_;
    if (! $symroot) {
        warn "\ntraverse_tree: encountered empty elem (returning)\n";
        return;
    } elsif (is_elementary_type $symroot) {
        &{$user_sub_ref}($symroot, $scope, $inside_includefile);
        return;
    } elsif (not isnode $symroot) {
        foreach (@{$symroot}) {
            traverse($_, $scope, $inside_includefile);
        }
        return;
    }
    &{$user_sub_ref}($symroot, $scope, $inside_includefile);
    my @node = @{$symroot};
    my $type = $node[TYPE];
    my $name = $node[NAME];
    my $subord = $node[SUBORDINATES];
    my @arg = @{$subord};
    if ($type == INCFILE) {
        traverse($subord, $scope, 1) if ($traverse_includefiles);
    } elsif ($type == MODULE) {
        if ($scope) {
            $scope .= '::' . $name;
        } else {
            $scope = $name;
        }
        foreach (@arg) {
            traverse($_, $scope, $inside_includefile);
        }
    } elsif ($type == INTERFACE) {
        # my @ancestors = @{$arg[0]};
        # if (@ancestors) {
        #     foreach $elder (@ancestors) {
        #         &{$user_sub_ref}($elder, $scope, $inside_includefile);
        #     }
        # }
        shift @arg;   # discard ancestors
        shift @arg;   # discard abstract flag
        if ($scope) {
            $scope .= '::' . $name;
        } else {
            $scope = $name;
        }
        foreach (@arg) {
            traverse($_, $scope, $inside_includefile);
        }
    }
}

sub traverse_tree {
    my $sym_array_ref = shift;
    $user_sub_ref = shift;
    $traverse_includefiles = 0;
    if (@_) {
        $traverse_includefiles = shift;
    }
    traverse($sym_array_ref, "", 0);
}

# End of traverse_tree stuff.


1;

# Local Variables:
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
