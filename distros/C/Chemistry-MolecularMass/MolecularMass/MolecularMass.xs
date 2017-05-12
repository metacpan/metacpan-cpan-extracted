#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stddef.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/***********************************************/
/*                                             */
/*    Structures                               */
/*                                             */
/***********************************************/

typedef struct atom_count_struct *Atom_count_ptr;

typedef struct atom_count_struct {
   char *element_symbol;
   int count;
   Atom_count_ptr next;
} Atom_count;

typedef struct symbol_table_struct *Symtab_ptr;

typedef struct symbol_table_struct {
   Atom_count *start;
   Symtab_ptr next;
} Symtab;

typedef struct token_struct {
   /* 0 - left parenthesis
      1 - element name
      2 - int count number
      3 - right parenthesis
   */
   int type;
   char *element_symbol;
   int count;
} Token;

typedef struct stack_struct *Stack_ptr;

typedef struct stack_struct {
   Symtab *first_tab;
   Symtab *last_tab;
   Stack_ptr prev;
} Stack;

/***********************************************/
/*                                             */
/*      Functions declarations                 */
/*                                             */
/***********************************************/

int verify_brackets(char *);
int check_brackets(char *, char *);
int is_bracket(char);
int is_left_bracket(char);
char other_bracket(char);
int only_alnum(char *, char *);
int not_even(char *, char *);
char *matching_bracket(char *, char *);

Atom_count *parse_formula_c(char *formula);
void print_atom_count(Atom_count *i);
Atom_count *flatten(Symtab *n);
Atom_count *combine(Atom_count *n);
Atom_count *add_atom(Atom_count *i, Atom_count *j);
void free_symtab(Symtab *n);
int tokenize(Token *t, int *error, char **f);
char *make_str_copy(char *s);
void multiply(Atom_count *i, int n);
Atom_count *new_element(char *element_symbol);
Symtab *new_symtab(void);

/***********************************************/
/*                                             */
/*      Functions (for parsing)                */
/*                                             */
/***********************************************/

Atom_count *parse_formula_c(char *formula)
{
   Token tok;
   Token *t = &tok;
   int error = 0;
   Stack *temp_stack;
   Atom_count *ac;
   Symtab *st;
   Stack *stack = (Stack *) malloc(sizeof(Stack));
   stack->first_tab = NULL;
   stack->last_tab = NULL;
   stack->prev = NULL;

   t->type = 4; /* Wrong!!! */
   t->element_symbol = NULL;
   t->count = 0;

   while(tokenize(&tok, &error, &formula))
   {
      if(t->type == 0) /* left parenthesis */
      {
         temp_stack = (Stack *) malloc(sizeof(Stack));
	 temp_stack->first_tab = NULL;
	 temp_stack->last_tab = NULL;
	 temp_stack->prev = stack;
	 stack = temp_stack;
      }
      else if(t->type == 1) /* element name */
      {
         ac = new_element(t->element_symbol);
	 st = new_symtab();
	 st->start = ac;
	 if(stack->first_tab == NULL) stack->first_tab = st;
	 if(stack->last_tab != NULL) stack->last_tab->next = st;
	 stack->last_tab = st;
      }
      else if(t->type == 2) /* count */
      {
         multiply(stack->last_tab->start, t->count);
      }
      else if(t->type == 3) /* right parenthesis */
      {
         ac = combine(flatten(stack->first_tab));
	 free_symtab(stack->first_tab);
	 temp_stack = stack;
	 stack = stack->prev;
	 free(temp_stack);
	 st = new_symtab();
	 st->start = ac;
	 if(stack->first_tab == NULL) stack->first_tab = st;
	 if(stack->last_tab != NULL) stack->last_tab->next = st;
	 stack->last_tab = st;
      }
      else /* Error! */
      {
         return(NULL);
      }
   }
   if(error) return(NULL);
   ac = combine(flatten(stack->first_tab));
   free_symtab(stack->first_tab);
   free(stack);
   return(ac);
}

/************************************************/

int tokenize(Token *t, int *error, char **formula)
{
   char *formula_offset = *formula;
   char *i = formula_offset;
   char *j;
   char *k;

   if(*i == '(')
   {
      t->type = 0;
      ++formula_offset;
      *formula = formula_offset;
      return(1);
   }
   else if(*i == ')')
   {
      t->type = 3;
      ++formula_offset;
      *formula = formula_offset;
      return(1);
   }
   else if(isupper(*i))
   {
      t->type = 1;
      ++i;
      while(islower(*i))
      {
         ++i;
      }
      j = (char *) malloc(sizeof(char) * (i - formula_offset + 1));
      k = j;
      while(formula_offset != i)
      {
         *k = *formula_offset;
	 ++formula_offset;
	 ++k;
      }
      *k = '\0';
      free(t->element_symbol);
      t->element_symbol = j;
      *formula = formula_offset;
      return(1);
   }
   else if(isdigit(*i))
   {
      t->type = 2;
      ++i;
      while(isdigit(*i))
      {
         ++i;
      }
      j = (char *) malloc(sizeof(char) * (i - formula_offset + 1));
      k = j;
      while(formula_offset != i)
      {
         *k = *formula_offset;
	 ++formula_offset;
	 ++k;
      }
      *k = '\0';
      t->count = atoi(j);
      free(j);
      *formula = formula_offset;
      return(1);
   }
   else if(*i == '\0')
   {
      free(t->element_symbol);
      return(0);
   }
   else
   {
      free(t->element_symbol);
      *error = 1;
      return(0);
   }
}

/************************************************/

Atom_count *flatten(Symtab *n)
{
   Atom_count *i;
   Atom_count *j;

   if(n == NULL) return(NULL);

   i = n->start;
   j = i;

   n = n->next;
   while(n != NULL)
   {
      if(j == NULL)
      {
         j = n->start;
	 n = n->next;
	 continue;
      }

      while(j->next != NULL)
      {
         j = j->next;
      }
      j->next = n->start;
      n = n->next;
   }
   return i;
}

/***********************************************/

Atom_count *combine(Atom_count *n)
{
   Atom_count *i = NULL;
   return add_atom(i, n);
}

/************************************************/

Atom_count *add_atom(Atom_count *i, Atom_count *n)
{
   Atom_count *j;
   Atom_count *unchanged = i;
   if(n == NULL) return i;

   j = n;
   n = n->next;
   j->next = NULL;

   while(i != NULL)
   {
      if(strcmp(i->element_symbol, j->element_symbol) == 0)
      {
         i->count += j->count;
	 free(j);
	 return(add_atom(unchanged, n));
      }
      i = i->next;
   }

   j->next = unchanged;
   return(add_atom(j, n));
}

/***************************************************/

void free_symtab(Symtab *n)
{
   Symtab *i = n;

   while(n != NULL)
   {
      n = n->next;
      free(i);
      i = n;
   }
}

/**************************************************/

char *make_str_copy(char *s)
{
   char *t = (char *) malloc(sizeof(char)*(strlen(s)+1));
   t = strcpy(t, s);
   return(t);
}

/***************************************************/

void multiply(Atom_count *i, int n)
{
   while(i != NULL)
   {
      i->count *= n;
      i = i->next;
   }
   return;
}

/***************************************************/

Symtab *new_symtab(void)
{
   Symtab *s = (Symtab *) malloc(sizeof(Symtab));
   s->next = NULL;
   s->start = NULL;
   return(s);
}

/***************************************************/

Atom_count *new_element(char *element_symbol)
{
   Atom_count *ac = (Atom_count *) malloc(sizeof(Atom_count));
   ac->count = 1;
   ac->next = NULL;
   ac->element_symbol = make_str_copy(element_symbol);
   return(ac);
}

/***************************************************/

void print_atom_count(Atom_count *i)
{
   if(i == NULL)
   {
      printf("List is NULL\n");
      return;
   }

   while(i != NULL)
   {
      printf("Atom: %s     Count: %d\n", i->element_symbol, i->count);
      i = i->next;
   }
   printf("End\n");
   return;
}

/***********************************************************/
/*                                                         */
/*     Functions (for checking parentheses                 */
/*                                                         */
/***********************************************************/


/****************************************************/


int verify_brackets(char *begin)
{
   char *p;
   char *q;

   p = begin;
   q = begin;
   while (*q != '\0') ++q;

   if(check_brackets(p, q))
   {
      return(1);
   }
   return(0);
}

/*****************************************************/

int check_brackets(char *s, char *t)
{
   char *r;

   /********** base case one: no brackets ************/
   if (only_alnum(s, t)) return (1);

   
   /***** base case two: odd number of brackets ******/
   if (not_even(s, t)) return (0);


   /********** RECURSE !!!!! *************************/
   while ((is_left_bracket(*s)) != 1) ++s;
   r = matching_bracket(s, t);
   if (r == NULL) return (0);
   if ((check_brackets(s+1, r)) && (check_brackets(r+1, t)))
   {
      return (1);
   }
   return (0);
}

/******************************************************/

int only_alnum(char *s, char *t)
{
   int n = 1;
   while (s < t)
   {
      if (isalnum(*s) == 0)
         n = 0;
      ++s;
   }
   return (n);
}

/**********************************************************/

int not_even(char *s, char *t)
{
   int i = 0;
   int j = 0;
   int k = 0;
   int n = 0;
   while (s < t)
   {
      if (*s == '[') ++i;
      if (*s == ']') --i;

      if (*s == '{') ++j;
      if (*s == '}') --j;

      if (*s == '(') ++k;
      if (*s == ')') --k;

      if (*s == '<') ++n;
      if (*s == '>') --n;
      
      ++s;
   }

   if (i != 0 || j != 0 || k != 0 || n != 0) return (1);
   return (0);
}

/*******************************************************/

int is_left_bracket(char b)
{
   if ((b == '[') || (b == '{') || (b == '(') || (b == '<'))
   {
      return (1);
   }
   return (0);
}

/***********************************************************/

char *matching_bracket(char *s, char *t)
{
   char left;
   char right;
   int i = 1;

   left = *s;
   right = other_bracket(*s);
   ++s;

   while (s < t)
   {
      if (*s == right) --i;
      if (*s == left) ++i;
      if (i == 0) break;
      ++s;
   }
   if (i == 0) return (s);
   return (NULL);
}

/***********************************************************/

char other_bracket(char b)
{
   if (b == '[') return (']');
   if (b == '{') return ('}');
   if (b == '(') return (')');
   if (b == '<') return ('>');
   if (b == ']') return ('[');
   if (b == '}') return ('{');
   if (b == ')') return ('(');
   if (b == '>') return ('<');
   return ('\0');
}

/************************************************************/
/*                                                          */
/*      XSUB stuff                                          */
/*                                                          */
/************************************************************/

MODULE = Chemistry::MolecularMass            PACKAGE = Chemistry::MolecularMass

int
verify_parens(s)
	char *s;
	CODE:
		RETVAL = verify_brackets(s);
	OUTPUT:
		RETVAL

void
parse_formula(s)
	char *s;
	PREINIT:
		Atom_count *i;
	PPCODE:
		i = parse_formula_c(s);

		if(i == NULL)
		{
		   /* do push nothing on the stack --
		      an empty list is implicitly returned */
		}
		else
		{
		   while(i != NULL)
		   {
		      EXTEND(SP, 2);
		      PUSHs(newSVpv(i->element_symbol, 0));
		      PUSHs(newSViv(i->count));
		      i = i->next;
		   }
		}
