

/* the tree structure */
struct tnode {
  char * text;
  int number;
  struct tnode *children[5];
  int children_number;
  struct tnode *root;
  int index;
};

struct tnode * first_node;

/* the main methods of the library */
struct tnode * parse_skin(char * text);
void clean_buffer();

/* functions that build the syntax tree */
struct tnode * block_node(struct tnode * parent,
			  struct tnode * child);
struct tnode * text_node(char * text);
struct tnode * variable_node(char * label);
struct tnode * comment_node(struct tnode * block);
struct tnode * if_node(char * condition, struct tnode * block);
struct tnode * else_node(char * pre_white_text, struct tnode * else_block);
struct tnode * elsif_node(char * pre_white_text,
			  char * condition, struct tnode * elsif_block);
struct tnode * chain_elsif_nodes(struct tnode * elsif_former_block,
				 struct tnode * new_elsif_block);
struct tnode * add_elsif_chain_to_if(struct tnode * if_part, 
				     char * pre_white_text,
				     struct tnode * elsif_part);
struct tnode * while_node(char * condition, struct tnode * block);
struct tnode * include_node(char * src, int skip);

/* functions to manage the tree */
struct tnode * make_tnode(char * text, int number);
struct tnode * add_tnode(struct tnode * parent, struct tnode * child);
struct tnode * root_tnode(struct tnode * node);
void show_tnode(struct tnode * node, int level);
void free_tnode(struct tnode * node);
void free_tnodes();


