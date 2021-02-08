#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <string.h>
#include <strings.h>
#include <stdlib.h>
#include <ctype.h>

const char* start_ie_hack = "/*\\*/";
const char* end_ie_hack   = "/**/";

/* ****************************************************************************
 * CHARACTER CLASS METHODS
 * ****************************************************************************
 */
bool charIsSpace(char ch) {
    if (ch == ' ')  return 1;
    if (ch == '\t') return 1;
    return 0;
}
bool charIsEndspace(char ch) {
    if (ch == '\n') return 1;
    if (ch == '\r') return 1;
    if (ch == '\f') return 1;
    return 0;
}
bool charIsWhitespace(char ch) {
    return charIsSpace(ch) || charIsEndspace(ch);
}
bool charIsNumeric(char ch) {
    if ((ch >= '0') && (ch <= '9')) return 1;
    return 0;
}
bool charIsIdentifier(char ch) {
    if ((ch >= 'a') && (ch <= 'z')) return 1;
    if ((ch >= 'A') && (ch <= 'Z')) return 1;
    if ((ch >= '0') && (ch <= '9')) return 1;
    if (ch == '_')  return 1;
    if (ch == '.')  return 1;
    if (ch == '#')  return 1;
    if (ch == '@')  return 1;
    if (ch == '%')  return 1;
    return 0;
}
bool charIsInfix(char ch) {
    /* WS before+after these characters can be removed */
    if (ch == '{')  return 1;
    if (ch == '}')  return 1;
    if (ch == ';')  return 1;
    if (ch == ',')  return 1;
    if (ch == '~')  return 1;
    if (ch == '>')  return 1;
    return 0;
}
bool charIsPrefix(char ch) {
    /* WS after these characters can be removed */
    if (ch == '(')  return 1;   /* requires leading WS when used in @media */
    if (ch == ':')  return 1;   /* requires leading WS when used in pseudo-selector */
    return charIsInfix(ch);
}
bool charIsPostfix(char ch) {
    /* WS before these characters can be removed */
    if (ch == ')')  return 1;   /* requires trailing WS for MSIE */
    return charIsInfix(ch);
}

/* ****************************************************************************
 * TYPE DEFINITIONS
 * ****************************************************************************
 */
typedef enum {
    NODE_EMPTY,
    NODE_WHITESPACE,
    NODE_BLOCKCOMMENT,
    NODE_IDENTIFIER,
    NODE_LITERAL,
    NODE_SIGIL
} NodeType;

struct _Node;
typedef struct _Node Node;
struct _Node {
    /* linked list pointers */
    Node*       prev;
    Node*       next;
    /* node internals */
    const char* contents;
    size_t      length;
    NodeType    type;
    bool        can_prune;
};

#define NODE_SET_SIZE 50000

struct _NodeSet;
typedef struct _NodeSet NodeSet;
struct _NodeSet {
    /* link to next NodeSet */
    NodeSet*    next;
    /* Nodes in this Set */
    Node        nodes[NODE_SET_SIZE];
    size_t      next_node;
};

typedef struct {
    /* singly linked list of NodeSets */
    NodeSet*    head_set;
    NodeSet*    tail_set;
    /* doubly linked list of Nodes */
    Node*       head;
    Node*       tail;
    /* doc internals */
    const char* buffer;
    size_t      length;
    size_t      offset;
} CssDoc;

/* ****************************************************************************
 * NODE CHECKING MACROS/FUNCTIONS
 * ****************************************************************************
 */

/* checks to see if the node is the given string, case INSENSITIVELY */
bool nodeEquals(Node* node, const char* string) {
    /* not the same length? Not equal */
    size_t len = strlen(string);
    if (len != node->length)
        return 0;
    /* compare contents to see if they're equal */
    return (strncasecmp(node->contents, string, node->length) == 0);
}

/* checks to see if the node contains the given string, case INSENSITIVELY */
bool nodeContains(Node* node, const char* string) {
    const char* haystack = node->contents;
    const char* endofhay = haystack + node->length;
    size_t len = strlen(string);
    char ul_start[2] = { tolower(*string), toupper(*string) };

    /* if node is shorter we know we're not going to have a match */
    if (len > node->length)
        return 0;

    /* find the needle in the haystack */
    while (haystack && *haystack) {
        /* find first char of needle */
        haystack = strpbrk( haystack, ul_start );
        /* didn't find it? Oh well. */
        if (haystack == NULL)
            return 0;
        /* found it, but will the end be past the end of our node? */
        if ((haystack+len) > endofhay)
            return 0;
        /* see if it matches */
        if (strncasecmp(haystack, string, len) == 0)
            return 1;
        /* nope, move onto next character in the haystack */
        haystack ++;
    }

    /* no match */
    return 0;
}

/* checks to see if the node begins with the given string, case INSENSITIVELY.
 */
bool nodeBeginsWith(Node* node, const char* string) {
    /* If the string is longer than the node, it's not going to match */
    size_t len = strlen(string);
    if (len > node->length)
        return 0;
    /* check for match */
    return (strncasecmp(node->contents, string, len) == 0);
}

/* checks to see if the node ends with the given string, case INSENSITVELY. */
bool nodeEndsWith(Node* node, const char* string) {
    /* If the string is longer than the node, it's not going to match */
    size_t len = strlen(string);
    if (len > node->length)
        return 0;
    /* check for match */
    size_t off = node->length - len;
    return (strncasecmp(node->contents+off, string, len) == 0);
}

/* macros to help see what kind of node we've got */
#define nodeIsWHITESPACE(node)          ((node->type == NODE_WHITESPACE))
#define nodeIsBLOCKCOMMENT(node)        ((node->type == NODE_BLOCKCOMMENT))
#define nodeIsIDENTIFIER(node)          ((node->type == NODE_IDENTIFIER))
#define nodeIsLITERAL(node)             ((node->type == NODE_LITERAL))
#define nodeIsSIGIL(node)               ((node->type == NODE_SIGIL))

#define nodeIsEMPTY(node)               ((node->type == NODE_EMPTY) || ((node->length==0) || (node->contents==NULL)))
#define nodeIsMACIECOMMENTHACK(node)    (nodeIsBLOCKCOMMENT(node) && nodeEndsWith(node,"\\*/"))
#define nodeIsPREFIXSIGIL(node)         (nodeIsSIGIL(node) && charIsPrefix(node->contents[0]))
#define nodeIsPOSTFIXSIGIL(node)        (nodeIsSIGIL(node) && charIsPostfix(node->contents[0]))
#define nodeIsCHAR(node,ch)             ((node->contents[0]==ch) && (node->length==1))

/* checks if this node is the start of "!important" (with optional intravening
 * whitespace. */
bool nodeStartsBANGIMPORTANT(Node* node) {
    if (!node) return 0;

    /* Doesn't start with a "!", nope */
    if (!nodeIsCHAR(node,'!')) return 0;

    /* Skip any following whitespace */
    Node* next = node->next;
    while (next && nodeIsWHITESPACE(next)) {
        next = node->next;
    }
    if (!next) return 0;

    /* Next node _better be_ "important" */
    if (!nodeIsIDENTIFIER(next)) return 0;
    if (nodeEquals(next, "important")) return 1;
    return 0;
}

/* ****************************************************************************
 * NODE MANIPULATION FUNCTIONS
 * ****************************************************************************
 */
/* allocates a new node */
Node* CssAllocNode(CssDoc* doc) {
    Node* node;
    NodeSet* set = doc->tail_set;

    /* if our current NodeSet is full, allocate a new NodeSet */
    if (set->next_node >= NODE_SET_SIZE) {
        NodeSet* next_set;
        Newz(0, next_set, 1, NodeSet);
        set->next = next_set;
        doc->tail_set = next_set;
        set = next_set;
    }

    /* grab the next Node out of the NodeSet */
    node = set->nodes + set->next_node;
    set->next_node ++;

    /* initialize the node */
    node->prev = NULL;
    node->next = NULL;
    node->contents = NULL;
    node->length = 0;
    node->type = NODE_EMPTY;
    node->can_prune = 1;
    return node;
}

/* sets the contents of a node */
void CssSetNodeContents(Node* node, const char* string, size_t len) {
    node->contents = string;
    node->length   = len;
    return;
}

/* removes the node from the list and discards it entirely */
void CssDiscardNode(Node* node) {
    if (node->prev)
        node->prev->next = node->next;
    if (node->next)
        node->next->prev = node->prev;
}

/* appends the node to the given element */
void CssAppendNode(Node* element, Node* node) {
    if (element->next)
        element->next->prev = node;
    node->next = element->next;
    node->prev = element;
    element->next = node;
}

/* ****************************************************************************
 * TOKENIZING FUNCTIONS
 * ****************************************************************************
 */

/* extracts a quoted literal string */
void _CssExtractLiteral(CssDoc* doc, Node* node) {
    const char* buf = doc->buffer;
    size_t offset   = doc->offset;
    char delimiter  = buf[offset];
    /* skip start of literal */
    offset ++;
    /* search for end of literal */
    while (offset < doc->length) {
        if (buf[offset] == '\\') {
            /* escaped character; skip */
            offset ++;
        }
        else if (buf[offset] == delimiter) {
            const char* start = buf + doc->offset;
            size_t length     = offset - doc->offset + 1;
            CssSetNodeContents(node, start, length);
            node->type = NODE_LITERAL;
            return;
        }
        /* move onto next character */
        offset ++;
    }
    croak( "unterminated quoted string literal" );
}

/* extracts a block comment */
void _CssExtractBlockComment(CssDoc* doc, Node* node) {
    const char* buf = doc->buffer;
    size_t offset   = doc->offset;

    /* skip start of comment */
    offset ++;  /* skip "/" */
    offset ++;  /* skip "*" */

    /* search for end of comment block */
    while (offset < doc->length) {
        if (buf[offset] == '*') {
            if (buf[offset+1] == '/') {
                const char* start = buf + doc->offset;
                size_t length     = offset - doc->offset + 2;
                CssSetNodeContents(node, start, length);
                node->type = NODE_BLOCKCOMMENT;
                return;
            }
        }
        /* move onto next character */
        offset ++;
    }

    croak( "unterminated block comment" );
}

/* extracts a run of whitespace characters */
void _CssExtractWhitespace(CssDoc* doc, Node* node) {
    const char* buf = doc->buffer;
    size_t offset   = doc->offset;
    while ((offset < doc->length) && charIsWhitespace(buf[offset]))
        offset ++;
    CssSetNodeContents(node, doc->buffer+doc->offset, offset-doc->offset);
    node->type = NODE_WHITESPACE;
}

/* extracts an identifier */
void _CssExtractIdentifier(CssDoc* doc, Node* node) {
    const char* buf = doc->buffer;
    size_t offset   = doc->offset;
    while ((offset < doc->length) && charIsIdentifier(buf[offset]))
        offset++;
    CssSetNodeContents(node, doc->buffer+doc->offset, offset-doc->offset);
    node->type = NODE_IDENTIFIER;
}

/* extracts a -single- symbol/sigil */
void _CssExtractSigil(CssDoc* doc, Node* node) {
    CssSetNodeContents(node, doc->buffer+doc->offset, 1);
    node->type = NODE_SIGIL;
}

/* tokenizes the given string and returns the list of nodes */
Node* CssTokenizeString(CssDoc* doc, const char* string) {
    /* parse the CSS */
    while ((doc->offset < doc->length) && (doc->buffer[doc->offset])) {
        /* allocate a new node */
        Node* node = CssAllocNode(doc);
        if (!doc->head)
            doc->head = node;
        if (!doc->tail)
            doc->tail = node;

        /* parse the next node out of the CSS */
        if ((doc->buffer[doc->offset] == '/') && (doc->buffer[doc->offset+1] == '*'))
            _CssExtractBlockComment(doc, node);
        else if ((doc->buffer[doc->offset] == '"') || (doc->buffer[doc->offset] == '\''))
            _CssExtractLiteral(doc, node);
        else if (charIsWhitespace(doc->buffer[doc->offset]))
            _CssExtractWhitespace(doc, node);
        else if (charIsIdentifier(doc->buffer[doc->offset]))
            _CssExtractIdentifier(doc, node);
        else
            _CssExtractSigil(doc, node);

        /* move ahead to the end of the parsed node */
        doc->offset += node->length;

        /* add the node to our list of nodes */
        if (node != doc->tail)
            CssAppendNode(doc->tail, node);
        doc->tail = node;
    }

    /* return the node list */
    return doc->head;
}

/* ****************************************************************************
 * MINIFICATION FUNCTIONS
 * ****************************************************************************
 */

/* Skips over any "zero value" found in the provided string, returning a
 * pointer to the next character after those zeros (which may be the same
 * as the pointer to ther original string, if no zeros were found).
 */
const char* CssSkipZeroValue(const char* str) {
    /* Skip leading zeros */
    while (*str == '0') { str ++; }
    const char* after_leading_zeros = str;

    /* Decimal point, followed by more zeros? */
    if (*str == '.') {
        str ++;
        while (*str == '0') { str ++; }
        if (charIsNumeric(*str)) {
            /* ends in digit; significant at the decimal point */
            return after_leading_zeros;
        }
        return str;
    }

    /* Done. */
    return after_leading_zeros;
}

/* checks to see if the string contains a known CSS unit */
bool CssIsKnownUnit(const char* str) {
    /* If it ends with a known Unit, its a Zero Unit */
    if (0 == strncmp(str, "em",   2)) { return 1; }
    if (0 == strncmp(str, "ex",   2)) { return 1; }
    if (0 == strncmp(str, "ch",   2)) { return 1; }
    if (0 == strncmp(str, "rem",  3)) { return 1; }
    if (0 == strncmp(str, "vw",   2)) { return 1; }
    if (0 == strncmp(str, "vh",   2)) { return 1; }
    if (0 == strncmp(str, "vmin", 3)) { return 1; }
    if (0 == strncmp(str, "vmax", 3)) { return 1; }
    if (0 == strncmp(str, "cm",   2)) { return 1; }
    if (0 == strncmp(str, "mm",   2)) { return 1; }
    if (0 == strncmp(str, "in",   2)) { return 1; }
    if (0 == strncmp(str, "px",   2)) { return 1; }
    if (0 == strncmp(str, "pt",   2)) { return 1; }
    if (0 == strncmp(str, "pc",   2)) { return 1; }
    if (0 == strncmp(str, "%",    1)) { return 1; }

    /* Nope */
    return 0;
}

/* collapses all of the nodes to their shortest possible representation */
void CssCollapseNodes(Node* curr) {
    bool inMacIeCommentHack = 0;
    bool inFunction = 0;
    while (curr) {
        Node* next = curr->next;
        switch (curr->type) {
            case NODE_WHITESPACE:
                /* collapse to a single whitespace character */
                curr->length = 1;
                break;
            case NODE_BLOCKCOMMENT:
                if (!inMacIeCommentHack && nodeIsMACIECOMMENTHACK(curr)) {
                    /* START of mac/ie hack */
                    CssSetNodeContents(curr, start_ie_hack, strlen(start_ie_hack));
                    curr->can_prune = 0;
                    inMacIeCommentHack = 1;
                }
                else if (inMacIeCommentHack && !nodeIsMACIECOMMENTHACK(curr)) {
                    /* END of mac/ie hack */
                    CssSetNodeContents(curr, end_ie_hack, strlen(end_ie_hack));
                    curr->can_prune = 0;
                    inMacIeCommentHack = 0;
                }
                break;
            case NODE_IDENTIFIER:
            {
                /* if the node doesn't begin with a "zero", nothing to collapse */
                const char* ptr = curr->contents;
                if ( (*ptr != '0') && (*ptr != '.' )) {
                    /* not "0" and not "point-something" */
                    break;
                }
                if ( (*ptr == '.') && (*(ptr+1) != '0') ) {
                    /* "point-something", but not "point-zero" */
                    break;
                }

                /* skip all leading zeros */
                ptr = CssSkipZeroValue(curr->contents);

                /* if we didn't skip anything, no Zeros to collapse */
                if (ptr == curr->contents) {
                    break;
                }

                /* did we skip the entire thing, and thus the Node is "all zeros"? */
                size_t skipped = ptr - curr->contents;
                if (skipped == curr->length) {
                    /* nothing but zeros, so truncate to "0" */
                    CssSetNodeContents(curr, "0", 1);
                    break;
                }

                /* was it a zero percentage? */
                if (*ptr == '%') {
                    /* a zero percentage; truncate to "0%" */
                    CssSetNodeContents(curr, "0%", 2);
                    break;
                }

                /* if all we're left with is a known CSS unit, and we're NOT in
                 * a function (where we have to preserve units), just truncate
                 * to "0"
                 */
                if (!inFunction && CssIsKnownUnit(ptr)) {
                    /* not in a function, and is a zero unit; truncate to "0" */
                    CssSetNodeContents(curr, "0", 1);
                    break;
                }

                /* otherwise, just skip leading zeros, and preserve any unit */
                /* ... do we need to back up one char to find a significant zero? */
                if (*ptr != '.') { ptr --; }
                /* ... if that's not the start of the buffer ... */
                if (ptr != curr->contents) {
                    /* set the buffer to "0 + units", blowing away the earlier bits */
                    size_t len = curr->length - (ptr - curr->contents);
                    CssSetNodeContents(curr, ptr, len);
                }
                break;
            }
            case NODE_SIGIL:
                if (nodeIsCHAR(curr,'(')) { inFunction = 1; }
                if (nodeIsCHAR(curr,')')) { inFunction = 0; }
                break;
            default:
                break;
        }
        curr = next;
    }
}

/* checks to see whether we can prune the given node from the list.
 *
 * THIS is the function that controls the bulk of the minification process.
 */
enum {
    PRUNE_NO,
    PRUNE_PREVIOUS,
    PRUNE_CURRENT,
    PRUNE_NEXT
};
int CssCanPrune(Node* node) {
    Node* prev = node->prev;
    Node* next = node->next;

    /* only if node is prunable */
    if (!node->can_prune)
        return PRUNE_NO;

    switch (node->type) {
        case NODE_EMPTY:
            /* prune empty nodes */
            return PRUNE_CURRENT;
        case NODE_WHITESPACE:
            /* remove whitespace before comment blocks */
            if (next && nodeIsBLOCKCOMMENT(next))
                return PRUNE_CURRENT;
            /* remove whitespace after comment blocks */
            if (prev && nodeIsBLOCKCOMMENT(prev))
                return PRUNE_CURRENT;
            /* remove whitespace before "!important" */
            if (next && nodeStartsBANGIMPORTANT(next)) {
                return PRUNE_CURRENT;
            }
            /* leading whitespace gets pruned */
            if (!prev)
                return PRUNE_CURRENT;
            /* trailing whitespace gets pruned */
            if (!next)
                return PRUNE_CURRENT;
            /* keep all other whitespace */
            return PRUNE_NO;
        case NODE_BLOCKCOMMENT:
            /* keep comments that contain the word "copyright" */
            if (nodeContains(node,"copyright"))
                return PRUNE_NO;
            /* remove comment blocks */
            return PRUNE_CURRENT;
        case NODE_IDENTIFIER:
            /* keep all identifiers */
            return PRUNE_NO;
        case NODE_LITERAL:
            /* keep all literals */
            return PRUNE_NO;
        case NODE_SIGIL:
            /* remove whitespace after "prefix" sigils */
            if (nodeIsPREFIXSIGIL(node) && next && nodeIsWHITESPACE(next))
                return PRUNE_NEXT;
            /* remove whitespace before "postfix" sigils */
            if (nodeIsPOSTFIXSIGIL(node) && prev && nodeIsWHITESPACE(prev))
                return PRUNE_PREVIOUS;
            /* remove ";" characters at end of selector groups */
            if (nodeIsCHAR(node,';') && next && nodeIsSIGIL(next) && nodeIsCHAR(next,'}'))
                return PRUNE_CURRENT;
            /* keep all other sigils */
            return PRUNE_NO;
    }
    /* keep anything else */
    return PRUNE_NO;
}

/* prune nodes from the list */
Node* CssPruneNodes(Node *head) {
    Node* curr = head;
    while (curr) {
        /* see if/how we can prune this node */
        int prune = CssCanPrune(curr);
        /* prune.  each block is responsible for moving onto the next node */
        Node* prev = curr->prev;
        Node* next = curr->next;
        switch (prune) {
            case PRUNE_PREVIOUS:
                /* discard previous node */
                CssDiscardNode(prev);
                /* reset "head" if that's what got pruned */
                if (prev == head)
                    head = curr;
                break;
            case PRUNE_CURRENT:
                /* discard current node */
                CssDiscardNode(curr);
                /* reset "head" if that's what got pruned */
                if (curr == head)
                    head = prev ? prev : next;
                /* backup and try again if possible */
                curr = prev ? prev : next;
                break;
            case PRUNE_NEXT:
                /* discard next node */
                CssDiscardNode(next);
                /* stay on current node, and try again */
                break;
            default:
                /* move ahead to next node */
                curr = next;
                break;
        }
    }

    /* return the (possibly new) head node back to the caller */
    return head;
}

/* ****************************************************************************
 * Minifies the given CSS, returning a newly allocated string back to the
 * caller (YOU'RE responsible for freeing its memory).
 * ****************************************************************************
 */
char* CssMinify(const char* string) {
    char* results;
    CssDoc doc;

    /* initialize our CSS document object */
    doc.head = NULL;
    doc.tail = NULL;
    doc.buffer = string;
    doc.length = strlen(string);
    doc.offset = 0;
    Newz(0, doc.head_set, 1, NodeSet);
    doc.tail_set = doc.head_set;

    /* PASS 1: tokenize CSS into a list of nodes */
    Node* head = CssTokenizeString(&doc, string);
    if (!head) return NULL;
    /* PASS 2: collapse nodes */
    CssCollapseNodes(head);
    /* PASS 3: prune nodes */
    head = CssPruneNodes(head);
    if (!head) return NULL;
    /* PASS 4: re-assemble CSS into single string */
    {
        Node* curr;
        char* ptr;
        /* allocate the result buffer to the same size as the original CSS; in
         * a worst case scenario that's how much memory we'll need for it.
         */
        Newz(0, results, (strlen(string)+1), char);
        ptr = results;
        /* copy node contents into result buffer */
        curr = head;
        while (curr) {
            memcpy(ptr, curr->contents, curr->length);
            ptr += curr->length;
            curr = curr->next;
        }
        *ptr = 0;
    }
    /* free memory used by the NodeSets */
    {
        NodeSet* curr = doc.head_set;
        while (curr) {
            NodeSet* next = curr->next;
            Safefree(curr);
            curr = next;
        }
    }
    /* return resulting minified CSS back to caller */
    return results;
}



MODULE = CSS::Minifier::XS              PACKAGE = CSS::Minifier::XS

PROTOTYPES: disable

SV*
minify(string)
    SV* string
    INIT:
        char* buffer = NULL;
        RETVAL = &PL_sv_undef;
    CODE:
        /* minify the CSS */
        buffer = CssMinify( SvPVX(string) );
        /* hand back the minified CSS (if we had any) */
        if (buffer != NULL) {
            RETVAL = newSVpv(buffer, 0);
            Safefree( buffer );
        }
    OUTPUT:
        RETVAL
