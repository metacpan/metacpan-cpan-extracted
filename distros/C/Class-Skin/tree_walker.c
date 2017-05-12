#include "tree_walker.h"

/**************************
 * walk_the_tree
 **************************/
void walk_the_tree(SV * self, 
		   SV * buffer,
		   struct tnode * node, 
		   HV* vars) {
  char * label;
  SV** variable_ref;
  SV** sub_ref;
  SV* included_lines;
  SV* included_lines_ref;
  struct tnode * already_included_node;
  struct tnode * included_syntax_tree;
  int c;
  int ret;
  int count;
  int skip_includes;
  char log_message[256];
  dSP;

  /*
  printf("buffer::::::::::::::::::::::::::::::::::::::::\n");
  printf("%s", SvPV_nolen(buffer));
  printf("..............................................\n");

  show_tnode(node,2);
  printf("tttttttttttttttttttttttttttttttttttttttttttttt\n");
  */

  /* if the node or the node text are not defined, return empty string */
  if (!node || !(node->text)) {
    return; 
  }

  if (strcmp(node->text, "comment") == 0) {
    walk_the_tree(self, buffer, node->children[0], vars);
    return;
  }
  if (strcmp(node->text, "text") == 0) {
    sv_catpv(buffer, node->children[0]->text);

    walk_the_tree(self, buffer, node->children[1], vars);
    return;
  }
  if (strcmp(node->text, "variable") == 0) {
    label = node->children[0]->text; /* get the label of the variable */
    /* fetch the variable from vars */
    
    variable_ref = hv_fetch(vars, label, (U32)strlen(label), 0);
    /* if the variable is not available or not defined */
    if (variable_ref == 0 || !SvOK(*variable_ref) ) {
      sv_catpvf(buffer, "$%s", label); /* add to the buffer "$label" */
      walk_the_tree(self, buffer, node->children[1], vars);
      return;
    }
    /* get the variable as text */
    sv_catsv(buffer, *variable_ref);
    walk_the_tree(self, buffer, node->children[1], vars);
    return;
  }
  if (strcmp(node->text, "if") == 0 ||
      strcmp(node->text, "elsif") == 0) {
    label = node->children[0]->text; /* get the label of the condition */

    /* fetch the variable from vars */
    variable_ref = hv_fetch(vars, label, (U32)strlen(label), 0);
    /* if the variable is available and defined and gives true, 
       we walk in the block of the if */
    if (variable_ref != 0 && 
	SvOK(*variable_ref) &&
	SvTRUE(*variable_ref)) {
      walk_the_tree(self, buffer, node->children[1], vars);
    }
    /* if the condition above was not successful, we should check if there 
       is elsif or else for it */
    else if (node->children_number > 2 && 
	     (strcmp(node->children[2]->text, "elsif") == 0 ||
	      strcmp(node->children[2]->text, "else") == 0)) {
      walk_the_tree(self, buffer, node->children[2], vars);
    }
    /* in any case of "if" we walk the next node in the tree */
    if (strcmp(node->text, "if") == 0 &&
	node->children_number > 2) {
      walk_the_tree(self, buffer, node->children[node->children_number-1], 
		    vars);
    }
    return;
  }
  if (strcmp(node->text, "else") == 0) {
    walk_the_tree(self, buffer, node->children[0], vars);
    return;
  }
  if (strcmp(node->text, "include") == 0) {
    /* check if that node was already included */
    if (node->children_number > 2 &&
	node->children[node->children_number - 2]->text &&
	strcmp(node->children[node->children_number - 2]->text, 
	       "already_included") == 0) {
      walk_the_tree(self, buffer, 
		    node->children[node->children_number - 1], vars);
      return;
    }
    label = node->children[0]->text; /* get the file name of the include */
    /* check if we should skip */    
    /* fetch the SKIP_INCLUDES from self */    
    variable_ref = hv_fetch((HV*)SvRV(self), "SKIP_INCLUDES", 
			    (U32)strlen("SKIP_INCLUDES"), 0);
    /* if the variable is not available or not defined */
    if (variable_ref == 0 || !SvOK(*variable_ref) ) {
      skip_includes = 0;
    }
    else {
      skip_includes = SvIV(*variable_ref);
    }
    if (skip_includes) { /* skip all the includes because 
			    SKIP_INCLUDES is true */
      /* we should skip, so instead we write to the buffer the same include 
	 we had and then we just continue */
      if (node->children_number > 0 && 
	  node->children[1]->text != 0 &&
	  strcmp(node->children[1]->text, "skip") == 0 &&
	  node->children[1]->number > 0) {
	sv_catpvf(buffer, "<include src=\"%s\" skip=\"%d\">", label,
		  node->children[1]->number); 
      }
      else {
	sv_catpvf(buffer, "<include src=\"%s\">", label);
      }
      walk_the_tree(self, buffer, 
		    node->children[node->children_number - 1], vars);
      return;
    } 
    /* check about the skip attribute */
    else if (node->children_number > 0 &&
	     node->children[1]->text != 0 &&
	     strcmp(node->children[1]->text, "skip") == 0) {      
      if (node->children[1]->number > 0) {
	/* we should skip, so instead we write to the buffer an includ
	   with decremented skip value and then we just continue */
	sv_catpvf(buffer,  "<include src=\"%s\" skip=\"%d\">", label,
		  node->children[1]->number - 1); 
	walk_the_tree(self, buffer, 
		      node->children[node->children_number - 1], vars);
	return;
      }
    }

    /* if the included template file name is passed in a varibale, get it
       from the variable */
    if (label[0] == '$') {
      label = label + 1;
      /* fetch the variable from vars */
      variable_ref = hv_fetch(vars, label, (U32)strlen(label), 0);
      /* if the variable is not available or not defined */
      if (variable_ref == 0 || !SvOK(*variable_ref) ) {
	/* we just send a message to the log, and ignore the include */
        sprintf(log_message, "Include tag with undefined variable $%0.30s",
		label);
	write_log(self, log_message, 4);
	walk_the_tree(self, buffer, 
		      node->children[node->children_number - 1], vars);
	return;
      }
      /* get the variable as text and put it in label */
      label = SvPV_nolen(*variable_ref);
    }
    /* prepare the included lines variable and its reference */
    included_lines = newSVpvn("", 0); /* create empty string perl scalar */
    included_lines_ref = newRV_inc((SV*)included_lines);
    /* call read and read the template into lines */
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(sv_2mortal(newSVpvn(label, strlen(label))));
    XPUSHs(included_lines_ref);      
    PUTBACK;
    count = call_method("read", G_SCALAR);

    SPAGAIN;      
    if (count != 1) {
      /* a problem. must log it */
      sprintf(log_message, "Failed to call the read method");
      write_log(self, log_message, 4);
      return;
    }      
    ret = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    if (ret != 1) {
      /* a problem. must log it */
      sprintf(log_message, "The call read(\"%0.30s\") returned 0", label);
      write_log(self, log_message, 4);
      return;
    }

    /* call parse_skin to get the syntax tree */
    included_syntax_tree = parse_skin(SvPV_nolen(included_lines));

    /* add the included syntax tree to the include node */
    already_included_node = make_tnode("already_included", 0);
    add_tnode(already_included_node, included_syntax_tree);
    /*    add_tnode(already_included_node, 
	  node->children[node->children_number - 1]); */
    add_tnode(node, already_included_node);

    /* walk that new node */
    walk_the_tree(self, buffer, already_included_node, vars);
    /* walk the node that was after the include */
    walk_the_tree(self, buffer, node->children[2], vars);    
    return;
  }
  if (strcmp(node->text, "already_included") == 0) {
    /* first we walk the included tree */
    walk_the_tree(self, buffer, node->children[0], vars);
    /* and then the rest of the tree */
    /*    walk_the_tree(self, buffer, node->children[1], vars);*/
    return;
  }
  if (strcmp(node->text, "while") == 0) {
    /* get the reference to the callback function */
    label = node->children[0]->text; /* get the label of the condition */    
    /* fetch the reference to the subroutine from vars using label as a key */
    sub_ref = hv_fetch(vars, label, (U32)strlen(label), 0);
    /* if the variable is not available or not defined */
    if (sub_ref == 0 || !SvOK(*sub_ref) ) {
      /* call the log to tell that the callback is not available */
      sprintf(log_message, "Callback function %0.30s is unavailable", label);
      write_log(self, log_message, 4);
      return;
    }

    while (1) {
      /* call the callback function */
      SPAGAIN;
      ENTER;
      SAVETMPS;      
      PUSHMARK(SP);
      XPUSHs(newRV_noinc((SV*) vars));      
      PUTBACK;
      count = call_sv(*sub_ref, G_SCALAR);      
      SPAGAIN;      
      if (count != 1) {
	/* a problem. must log it */
	sprintf(log_message, "Failed to call the callback function %0.30s", 
		label);
	write_log(self, log_message, 4);
	return;
      }      
      ret = POPi;
      PUTBACK;
      FREETMPS;
      LEAVE;
      /* if the callback function returns 0 get out of the loop */
      if (!ret) {
	break;
      }

      /* walk the while block */
      walk_the_tree(self, buffer, node->children[1], vars);      
    }
    /* walk the rest of the tree */
    walk_the_tree(self, buffer, node->children[2], vars);
    return;
  }
} /* of walk_the_tree */

/***********************
 * write_log
 ***********************/
void write_log(SV* self, char* message, int level) {  
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(self);
  XPUSHs(sv_2mortal(newSVpv(message, 0)));
  XPUSHs(sv_2mortal(newSViv(level)));      
  PUTBACK;
  call_method("perl_write_log", G_DISCARD);
  FREETMPS;
  LEAVE;
} /* of write_log */


