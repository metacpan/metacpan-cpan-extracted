%{

#include "y.tab.h"
#include <string.h>

#define BUFFER_INITIAL_SIZE        256
#define INITIAL_GROW_BUFFER_BY     BUFFER_INITIAL_SIZE / 2 
#define BUFFER_SIZE_LIMIT          BUFFER_INITIAL_SIZE * 2
#define UNDEF           0

#undef YY_INPUT
#define YY_INPUT(B, R, MS) (R = my_yyinput(B, MS))
#define min(A, B) ((A) < (B) ? (A) : (B))

#undef DEBUG

#ifdef DEBUG
#define debug(WHERE) printf("%s  yytext=%s\n", WHERE, yytext)
  void show_current_command();
#else
#define debug(WHERE) 
#endif

  char * myinput = 0;
  char * myinputptr = 0;
  char * myinputlim = 0;
  int my_yyinput(char* buf, int max_size);

  extern int lineno;

  int grow_buffer_by = INITIAL_GROW_BUFFER_BY;
  int wait_for_condition = 0;
  int wait_for_src = 0;
  int wait_for_skip = 0;
  int is_in_comment = 0;
  int wait_for_label = 0;
  int current_buffer_size = 0;
  int position_in_buffer = 0;
  char * buffer = 0;
  int is_buffer_white = 1;

  int current_command = UNDEF;
  int return_text();
  int got_dollar();
  int open_skin_commands();
  int got_condition();
  int got_src();
  int got_skip();
  int any_text();  
  int end_of_file();
  int terminating_skin_command();

  int get_command_from_string(char * string,
			      int is_closing_command);
  void token_ended(char * token_name);
  char * add_text_to_buffer(char * text);
  void refresh_buffer();


%}

skin_command          \<\/?[ \t\n]*([iI][fF]|[eE][lL][sS][iI][fF]|[eE][lL][sS][eE]|[wW][hH][iI][lL][eE]|[iI][nN][cC][lL][uU][dD][eE]|[cC][oO][mM][mM][eE][nN][tT])
condition             [cC][oO][nN][dD][iI][tT][iI][oO][nN][ \t\n]*=[ \t\n]*\"[^\"]+\"
src                   [sS][rR][cC][ \t\n]*=[ \t\n]*\"[^\"]+\"
skip                  [sS][kK][iI][pP][ \t\n]*=[ \t\n]*\"[^\"]+\"
dollar                \$
label                 \([a-zA-Z_][a-zA-Z_0-9]*\)|[a-zA-Z_][a-zA-Z_0-9]*

%%

{dollar}              { return got_dollar(); } 
{label}               { return got_label(); } 
{condition}           { return got_condition(); }
{src}                 { return got_src(); }
{skip}                { return got_skip(); }
{skin_command}        { return open_skin_commands(); }
\>                    { return terminating_skin_command(); }
.                     { return any_text(); }
\n                    { lineno++; return any_text(); }
<<EOF>>               { return end_of_file(); }

%%

/****************************
 * got_dollar
 ****************************/
int got_dollar() {
  /* if we do not get a label immediately after the dollar, we stop to 
     wait for the label, and we push the dollar to the buffer (because
     we didn't push it when we got it). here we push the previous dollar
     before we start to wait again to the label. */ 
  if (wait_for_label) {    
    add_text_to_buffer("$"); 
  }
  else {
    wait_for_label = 1;
  }
  debug("got_dollar");
  return return_text();
} /* of got_dollar */

/****************************
 * open_skin_commands
 ****************************/
int open_skin_commands() {
  int is_closing_command = 0;
  debug("open_skin_commands");

  /* first check if it is opening command or closing command */
  if (yytext[1] == '/') {
    is_closing_command = 1;
  }
  /* get the command */
  current_command = get_command_from_string(yytext + 1 + is_closing_command,
					    is_closing_command);
#ifdef DEBUG 
  show_current_command();
#endif
  if (is_in_comment == 1 && !(current_command == CLOSE_COMMENT)) {
    any_text();
  }
  switch (current_command) {
  case OPEN_IF:
  case OPEN_ELSIF:
  case OPEN_WHILE:
    wait_for_condition = 1;
    break;
  case INCLUDE:
    wait_for_src = 1;
    wait_for_skip = 1;
    break;
  case OPEN_COMMENT:
    is_in_comment = 1;
    break;
  case CLOSE_COMMENT:
    is_in_comment = 0;
  }    
  return return_text();
} /* of open_skin_commands */

/****************************
 * return_text
 ****************************/
int return_text() {
  int return_value;
  if (buffer) {
    yylval.string = (char *)strdup(buffer); 
  }  
  if (is_buffer_white) {    
    if (current_command == OPEN_ELSE) {
      return_value = PRE_ELSE_WHITE_TEXT;    
      debug("return_text: PRE_ELSE_WHITE_TEXT");
    }
    else if (current_command == OPEN_ELSIF) {
      return_value = PRE_ELSIF_WHITE_TEXT;
      debug("return_text: PRE_ELSIF_WHITE_TEXT");
    }
    else {
      return_value = WHITE_TEXT;
      debug("return_text: WHITE_TEXT");
    }
  }
  else {
    return_value = TEXT;
    debug("return_text: TEXT");
  }
  refresh_buffer();
  return return_value;
} /* of return_text */

/****************************
 * get_command_from_string
 ****************************/
int get_command_from_string(char * string,
			    int is_closing_command) {
  if (strcasecmp(string, "if") == 0) {
    return is_closing_command ? CLOSE_IF : OPEN_IF;
  }
  else if (strcasecmp(string, "elsif") == 0) {
    return is_closing_command ? CLOSE_ELSIF : OPEN_ELSIF;
  }
  else if (strcasecmp(string, "else") == 0) {
    return is_closing_command ? CLOSE_ELSE : OPEN_ELSE;
  }
  else if (strcasecmp(string, "while") == 0) {
    return is_closing_command ? CLOSE_WHILE : OPEN_WHILE;
  }
  else if (strcasecmp(string, "include") == 0) {
    return INCLUDE;
  }
  else if (strcasecmp(string, "comment") == 0) {
    return is_closing_command ? CLOSE_COMMENT : OPEN_COMMENT;  
  }
  else {
    return UNDEF;
  }
} /* of get_command_from_string */

/****************************
 * any_text
 ****************************/
int any_text() {
  /* if we do not get a label immediately after the dollar, we stop to 
     wait for the label, and we push the dollar to the buffer (because
     we didn't push it when we got it) */ 
  if (wait_for_label) {    
    add_text_to_buffer("$"); 
  }
  wait_for_label = 0; 
  add_text_to_buffer(yytext);
  /* if the buffer is too big, it means that we have too many recursive
     calls to yylex (see below). 
     in order to avoid overflow of the stack, we return_text in any case 
     when the buffer is too big. this usually should not be a problem. it 
     can be a problem if we do it within a command, but if we take the 
     BUFFER_SIZE_LIMIT big enough, this will not happen, as the 
     commands suppose to be quite small. */
  if (current_buffer_size > BUFFER_SIZE_LIMIT) {
    debug("any_text - buffer too big");
    return return_text();
  }
  else {
    debug("any_text");
    return yylex();
  }
} /* of any_text */

/****************************
 * end_of_file
 ****************************/
int end_of_file() {
  if (buffer && *buffer) { 
    debug("end_of_file ==> return_text");
    return return_text(); 
  } 
  else {
    debug("end_of_file ==> EOF");
    return EOF; 
  } 
} /* of end_of_file */

/****************************
 * is_string_white
 ****************************/
int is_string_white(char * string) {
  int i;
  for (i = 0; i < strlen(string); i++) {
    if (!isspace(string[i])) {
      return 0;
    }
  }
  return 1;
} /* of is_string_white */

/****************************
 * add_text_to_buffer
 ****************************/
char * add_text_to_buffer(char * text) {
  char * tmp_buffer;
  /*  printf("current_buffer_size = %d\ttext = %s", current_buffer_size, text);*/
  if (strlen(text) + position_in_buffer >= current_buffer_size) {
    current_buffer_size = current_buffer_size + strlen(text) + grow_buffer_by;
    grow_buffer_by *= 2;
    tmp_buffer = (char* )malloc(current_buffer_size);
    *tmp_buffer = 0;
    if (position_in_buffer) {
      strcpy(tmp_buffer, buffer);      
      free(buffer);
    }
    buffer = tmp_buffer;
  }
  position_in_buffer += strlen(text);
  strcat(buffer, text);
  is_buffer_white = is_buffer_white ? is_string_white(text) : 0;
  /*  printf("   ...\n");  */
  return buffer;
} /* of add_text_to_buffer */

/****************************
 * refresh_buffer
 ****************************/
void refresh_buffer() {
  if (buffer) {
    free(buffer);
  }  
  is_buffer_white = 1;
  current_buffer_size = BUFFER_INITIAL_SIZE;
  grow_buffer_by = INITIAL_GROW_BUFFER_BY;
  position_in_buffer = 0;
  buffer = (char* )malloc(current_buffer_size);
  *buffer = 0;
} /* of refresh_buffer */

/****************************
 * clean_buffer
 ****************************/
void clean_buffer() {
  if (buffer) {
    free(buffer);
    buffer = 0;
  }  
  is_buffer_white = 1;
  position_in_buffer = 0;
} /* of clean_buffer */

/****************************
 * got_label
 ****************************/
int got_label() {
  if (wait_for_label) {
    wait_for_label = 0;    
    if (yytext[0] == '(' && yytext[strlen(yytext) - 1] == ')') {
      yylval.string = strdup(yytext + 1);
      yylval.string[strlen(yylval.string) - 1] = '\0';      
    }
    else {
      yylval.string = strdup(yytext);	   
    }
    debug("got_label ===> VARIABLE");
    return VARIABLE;
  }
  else {
    debug("got_label ===> any_text");
    return any_text();
  }
} /* of got_label */

/****************************
 * got_condition
 ****************************/
int got_condition() {
  char * condition;
  char * ptr;
  if (wait_for_condition) {
    wait_for_condition = 0;
    ptr = strchr(yytext, '\"');
    ptr = ptr ? ptr + 1 : yytext;
    condition = (char *)strdup(ptr);
    ptr = strchr(condition, '\"');
    if (ptr) {
      *ptr = 0;
    }
    yylval.string = condition; 
    switch (current_command) {
    case OPEN_IF:
      debug("got_condition ==> IF_CONDITION");
      return IF_CONDITION;
    case OPEN_ELSIF:
      debug("got_condition ==> ELSIF_CONDITION");
      return ELSIF_CONDITION;
    case OPEN_WHILE:
      debug("got_condition ==> WHILE_CONDITION");
      return WHILE_CONDITION;
    }
  }
  else {
    debug("got_condition ==> any_text");
    return any_text();
  }
} /* of got_condition */

/****************************
 * got_src
 ****************************/
int got_src() {
  char * src;
  char * ptr;
  if (wait_for_src) {
    wait_for_src = 0;
    ptr = strchr(yytext, '\"');
    ptr = ptr ? ptr + 1 : yytext;
    src = (char *)strdup(ptr);
    ptr = strchr(src, '\"');
    if (ptr) {
      *ptr = 0;
    }
    yylval.string = src; 
    debug("got_src ==> SRC");
    return SRC;
  }
  else {
    yyless(3); /* if we were not waiting for src, we push back the src. 
		  this promises that we do not loose any other tokens 
		  withing the src token we found. */
    debug("got_src ==> any_text");
    return any_text();
  }
} /* of got_src */

/****************************
 * got_skip
 ****************************/
int got_skip() {
  char * skip;
  char * ptr;
  if (wait_for_skip) {
    wait_for_skip = 0;
    ptr = strchr(yytext, '\"');
    ptr = ptr ? ptr + 1 : yytext;
    skip = (char *)strdup(ptr);
    ptr = strchr(skip, '\"');
    if (ptr) {
      *ptr = 0;
    }
    yylval.number = atoi(skip);
    free(skip);
    debug("got_skip ==> SKIP");
    return SKIP;
  }
  else {
    debug("got_skip ==> any_text");
    return any_text();
  }
} /* of got_skip */

/****************************
 * terminating_skin_command
 ****************************/    
int terminating_skin_command() {
  int command;
  if (current_command != UNDEF &&
      !wait_for_condition && 
      !wait_for_src) {
    wait_for_skip = 0;
    command = current_command;
    current_command = UNDEF;
    refresh_buffer(); /* we do not want to take any text from within the 
			 command tag */
    debug("terminating_skin_command ==> command");
    return command;
  }
  else {
    debug("terminating_skin_command ==> any_text");
    return any_text();
  }
} /* of terminating_skin_command */

/****************************
 * yyerror
 ****************************/
yyerror (const char *msg) {
  fprintf (stderr, "%d: %s at '%s'\n", lineno, msg, yytext);
} /* of yyerror */

/*********************
 * my_yyinput
 ********************/
int my_yyinput(char* buf, int max_size) {
  int n = min(max_size, myinputlim - myinputptr);
  
  if (n > 0) {
    memcpy(buf, myinputptr, n);
    myinputptr += n;
  }
  return n;
} /* of my_yyinput */


#ifdef DEBUG 

/***************************
 * show_current_command
 ***************************/
void show_current_command() {
  switch (current_command) {
  case OPEN_IF:
    printf("===> OPEN_IF\n");
    return;
  case CLOSE_IF:
    printf("===> CLOSE_IF\n");
    return;
  case OPEN_ELSIF:
    printf("===> OPEN_ELSIF\n");
    return;
  case CLOSE_ELSIF:
    printf("===> CLOSE_ELSIF\n");
    return;
  case OPEN_ELSE:
    printf("===> OPEN_ELSE\n");
    return;
  case CLOSE_ELSE:
    printf("===> CLOSE_ELSE\n");
    return;
  case OPEN_WHILE:
    printf("===> OPEN_WHILE\n");
    return;
  case CLOSE_WHILE:
    printf("===> CLOSE_WHILE\n");
    return;
  case INCLUDE:
    printf("===> INCLUDE\n");
    return;
  case OPEN_COMMENT:
    printf("===> OPEN_COMMENT\n");
    return;
  case CLOSE_COMMENT:
    printf("===> OPEN_COMMENT\n");
    return;    
  }    
  printf("===> ??????????\n");
  return;
}

#endif
