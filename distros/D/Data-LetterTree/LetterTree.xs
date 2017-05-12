#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "lettertree.h"

MODULE = Data::LetterTree		PACKAGE = Data::LetterTree

Node *
new(class)
	char * class
    CODE:
	RETVAL = new_tree();
    OUTPUT:
       RETVAL

MODULE = Data::LetterTree		PACKAGE = NodePtr

int
add_data(tree, word, data)
	Node * tree
	char * word
	SV * data

int
has_word(tree, word)
	Node * tree
	char * word

int
parse_tree(tree)
	Node * tree

void
get_data(tree, word)
	Node * tree
	char * word
    PREINIT:
	SV** data;
	int i = 0;
    PPCODE:
	data = get_data(tree, word);
	if (data) 
	    while (data[i]) 
		XPUSHs((SV*) data[i++]);

void
DESTROY(tree)
	Node * tree
    CODE:
	delete_tree(tree);
