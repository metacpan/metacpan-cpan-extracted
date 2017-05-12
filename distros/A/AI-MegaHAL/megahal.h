#ifndef MEGAHAL_H
#define MEGAHAL_H

void  megahal_setnoprompt ();
void  megahal_setnowrap ();
void  megahal_setnobanner ();
void  megahal_seterrorfile(char *filename);
void  megahal_setstatusfile(char *filename);
void  megahal_initialize();
char* megahal_initial_greeting();
int   megahal_command(char *input);
char* megahal_do_reply(char *input, int log);
void  megahal_learn(char *input, int log);
void  megahal_output(char *output);
char* megahal_input(char *prompt);
void  megahal_cleanup();

#endif
