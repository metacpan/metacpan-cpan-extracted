%{
#include <stdio.h>
#include <string.h>
  extern char * myinput;
  extern char * myinputptr;
  extern char * myinputlim;
  int lineno = 1;  
  int tnode_index = 0;
#include "skin.h"
  
%}
%union {
  char * string; /* string buffer */
  int number; /* number */
  struct tnode * node; /* tree node */
}

%token <string> TEXT WHITE_TEXT VARIABLE
%token <string> PRE_ELSE_WHITE_TEXT PRE_ELSIF_WHITE_TEXT
%token <string> WHILE_CONDITION IF_CONDITION ELSIF_CONDITION SRC 
%token <number> SKIP
%token OPEN_COMMENT CLOSE_COMMENT
%token OPEN_IF CLOSE_IF OPEN_ELSIF CLOSE_ELSIF OPEN_ELSE CLOSE_ELSE 
%token OPEN_WHILE CLOSE_WHILE INCLUDE  
%nonassoc IF_BLOCK
%nonassoc IF_ELSE_BLOCK IF_ELSIF_BLOCK
%nonassoc IF_ELSIF_ELSE_BLOCK

%%

block: block command_block { $<node>$ = block_node($<node>1, $<node>2); } |
       block text_block { $<node>$ = block_node($<node>1, text_node($<string>2)); } |
       command_block { $<node>$ = $<node>1; } |
       text_block { $<node>$ = text_node($<string>1); } 

command_block: condition_block { $<node>$ = $<node>1; } | 
               while_block { $<node>$ = $<node>1; } | 
               include { $<node>$ = $<node>1; } |
               variable { $<node>$ = $<node>1; } |
               comment_block { $<node>$ = $<node>1; } 

text_block: TEXT |
            WHITE_TEXT 

variable: VARIABLE { $<node>$ = variable_node($<string>1); }

comment_block: OPEN_COMMENT block CLOSE_COMMENT { $<node>$ = 
						    comment_node($<node>2); }

condition_block: if_block { $<node>$ = $<node>1; } |
                 if_else_block { $<node>$ = $<node>1; } |
                 if_elsif_block { $<node>$ = $<node>1; } |
                 if_elsif_else_block { $<node>$ = $<node>1; } 

if_block: IF_CONDITION OPEN_IF block CLOSE_IF { $<node>$ = if_node($<string>1,
								   $<node>3); }

if_else_block: IF_CONDITION OPEN_IF block CLOSE_IF PRE_ELSE_WHITE_TEXT 
                 OPEN_ELSE block CLOSE_ELSE 
                 { $<node>$ = add_elsif_chain_to_if(if_node($<string>1, 
							    $<node>3),
						    0,
						    else_node($<string>5, 
							      $<node>7)); } 
elsif_block: elsif_block 
             PRE_ELSIF_WHITE_TEXT 
             ELSIF_CONDITION OPEN_ELSIF block CLOSE_ELSIF 
             { $<node>$ = chain_elsif_nodes($<node>1, 
					    elsif_node($<string>2,
						       $<string>3, 
						       $<node>5)); } |
             ELSIF_CONDITION OPEN_ELSIF block CLOSE_ELSIF 
             { $<node>$ = elsif_node(0, $<string>1, $<node>3); } 
	     
elsif_else_block: elsif_block
                  PRE_ELSE_WHITE_TEXT 
                  OPEN_ELSE block CLOSE_ELSE
                  { $<node>$ = 
		      root_tnode(chain_elsif_nodes($<node>1, 
						   else_node($<string>2, 
							     $<node>4))); } 


if_elsif_block: IF_CONDITION OPEN_IF block CLOSE_IF 
                PRE_ELSIF_WHITE_TEXT elsif_block
                { $<node>$ = add_elsif_chain_to_if(if_node($<string>1, 
							   $<node>3),
						   $<string>5,
						   $<node>6); } 

if_elsif_else_block: IF_CONDITION OPEN_IF block CLOSE_IF 
                     PRE_ELSIF_WHITE_TEXT elsif_else_block
                     { $<node>$ = add_elsif_chain_to_if(if_node($<string>1, 
								$<node>3), 
							$<string>5,
							$<node>6); } 

while_block: WHILE_CONDITION OPEN_WHILE block CLOSE_WHILE
              { $<node>$ = while_node($<string>1, $<node>3); }

include: SRC INCLUDE { $<node>$ = include_node($<string>1, 0); } |
         SRC SKIP INCLUDE { $<node>$ = include_node($<string>1, $<number>2); } 

%%

/*********************
 * parse_skin 
 *********************/
struct tnode * parse_skin(char * text) {  
  first_node = 0;
  myinputptr = myinput = text;
  myinputlim = text + strlen(text);  
  refresh_buffer();
  yyparse();
  clean_buffer();
  return first_node;
} /* of parse_skin */

/**********************
 * block_node
 **********************/
struct tnode * block_node(struct tnode * parent,
			  struct tnode * child) {  
  add_tnode(parent, child);
  return child;  
} /* of block_node */

/*********************
 * text_node 
 *********************/
struct tnode * text_node(char * text) {
  struct tnode * text_node;
  struct tnode * data_node;
  text_node = make_tnode("text", 0);
  data_node = make_tnode(text, 0);
  add_tnode(text_node, data_node);
  free(text);
  return text_node;
} /* of text_node */

/***********************
 * variable_node
 ***********************/
struct tnode * variable_node(char * label) {
  struct tnode * variable_node;
  struct tnode * label_node;
  variable_node = make_tnode("variable", 0);
  label_node = make_tnode(label, 0);
  add_tnode(variable_node, label_node);
  free(label);
  return variable_node;  
} /* of variable_node */

/*********************
 * comment_node 
 *********************/
struct tnode * comment_node(struct tnode * block) {
  struct tnode * comment_node;
  comment_node = make_tnode("comment", 0);
  free_tnode(block); /* we do not need the comment block */
  return comment_node;
} /* of comment_node */

/*******************
 * if_node 
 *******************/
struct tnode * if_node(char * condition, struct tnode * block) {
  struct tnode * if_node;
  struct tnode * condition_node;
  if_node = make_tnode("if", 0);
  condition_node = make_tnode(condition, 0);
  add_tnode(if_node, condition_node);
  add_tnode(if_node, root_tnode(block));
  free(condition);
  return if_node;
} /* of if_node */

/*********************
 * else_node 
 *********************/
struct tnode * else_node(char * pre_white_text, struct tnode * else_block) {
  struct tnode * else_node;
  else_node = make_tnode("else", 0);
  add_tnode(else_node, root_tnode(else_block));
  free(pre_white_text); /* todo */
  return else_node;
} /* of else_node */

/***********************
 * elsif_node 
 ***********************/
struct tnode * elsif_node(char * pre_white_text,
			  char * condition, struct tnode * elsif_block) {
  struct tnode * elsif_node;
  struct tnode * condition_node;
  elsif_node = make_tnode("elsif", 0);
  condition_node = make_tnode(condition, 0);
  add_tnode(elsif_node, condition_node);
  add_tnode(elsif_node, root_tnode(elsif_block));
  free(condition);
  if (pre_white_text) {
    free(pre_white_text); /* todo */
  }
  return elsif_node;
} /* of elsif_node */

/***********************
 * chain_elsif_nodes
 ***********************/
struct tnode * chain_elsif_nodes(struct tnode * elsif_former_block,
				 struct tnode * new_elsif_block) {  
  add_tnode(elsif_former_block, root_tnode(new_elsif_block));
  return new_elsif_block;  
} /* of chain_elsif_nodes */

/**************************
 * add_elsif_chain_to_if 
 **************************/
struct tnode * add_elsif_chain_to_if(struct tnode * if_part, 
				     char * pre_white_text,
				     struct tnode * elsif_part) {
  add_tnode(if_part, root_tnode(elsif_part));
  if (pre_white_text) {
    free(pre_white_text); /* todo */
  }
  return if_part;
} /* of add_elsif_chain_to_if */

/*******************
 * while_node
 *******************/
struct tnode * while_node(char * condition, struct tnode * block) {
  struct tnode * while_node;
  struct tnode * condition_node;
  while_node = make_tnode("while", 0);
  condition_node = make_tnode(condition, 0);
  add_tnode(while_node, condition_node);
  add_tnode(while_node, root_tnode(block));
  free(condition);
  return while_node;
} /* of while_node */

/**********************
 * include_node
 **********************/
struct tnode * include_node(char * src, int skip) {
  struct tnode * include_node;
  struct tnode * src_node;
  struct tnode * skip_node;
  include_node = make_tnode("include", 0);
  src_node = make_tnode(src, 0);
  skip_node = make_tnode("skip", skip);
  add_tnode(include_node, src_node);
  add_tnode(include_node, skip_node);
  free(src);
  return include_node;
} /* of include_node */

/*******************************
 * make_tnode
 *******************************/
struct tnode * make_tnode(char * text, int number) {
  struct tnode * new_tnode = (struct tnode *)malloc(sizeof(struct tnode));
  if (text) {
    new_tnode->text = strdup(text);
  }
  else {
    new_tnode->text = 0;
  }
  new_tnode->number = number;
  new_tnode->children_number = 0;
  new_tnode->children[0] = 0;
  new_tnode->children[1] = 0;
  new_tnode->children[2] = 0;
  new_tnode->children[3] = 0;
  new_tnode->children[4] = 0;  
  new_tnode->root = 0; 
  new_tnode->index = tnode_index++;
#ifdef DEBUG 
  printf("<%d>  make tnode(%s, %d)\n",new_tnode->index, new_tnode->text, 
	 new_tnode->number);
#endif  
  if (!first_node) {
    first_node = new_tnode;
  }
  return new_tnode;
} /* of make_tnode */

/***********************
 * add_tnode
 ***********************/
struct tnode * add_tnode(struct tnode * parent, struct tnode * child) {
  parent->children[parent->children_number] = child;
  parent->children_number++;
  child->root = root_tnode(parent);
  return parent;
} /* of add_tnode */

/*******************
 * root_tnode 
 *******************/
struct tnode * root_tnode(struct tnode * node) {
  if (node) {
    if (node->root) {
      return node->root;
    }
    else {
      return node;
    }
  }
  else {
    return 0;
  }
} /* of root_tnode */ 

/**********************
 * show_tnode 
 **********************/
void show_tnode(struct tnode * node, int level) {
  int i;
  char * text;
  int number;
  if (!node) {
    return;
  }
  for (i = 0; i < level; i++) {
    printf(" ");
  }  
  text = node->text;
  number = node->number;
  printf("==%d== [%s] (%d) ", node->index, node->text, node->number);
  if (node->children_number) {
    printf("has %d children:", node->children_number);
  }
  printf("\n");
  for (i = 0; i < node->children_number; i++) {
    show_tnode((node->children)[i], level + 1);
  }
} /* of show_tnode */

/***************
 * free_tnode
 ***************/
void free_tnode(struct tnode * node) {
  int i;
  if (node) {
#ifdef DEBUG
    printf(">%d<  free tnode(%s, %d)\n",node->index, node->text, 
	   node->number);
#endif
    for (i = 0; i < node->children_number; i++) {
      free_tnode(node->children[i]);
      node->children[i] = 0;
    }
    
    if (node->text) {
      free(node->text);
    }
    free(node);
    node = 0;
  }
} /* of free_tnode */

/***************
 * free_tnodes
 ***************/
void free_tnodes() {
  free_tnode(root_tnode(first_node));
  first_node = 0;
} /* of free_tnodes */










