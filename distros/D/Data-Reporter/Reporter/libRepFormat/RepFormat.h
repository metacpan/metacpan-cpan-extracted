#ifndef FORMAT_HEADER
#define FORMAT_HEADER
#include <stdarg.h>

typedef struct struct_format {
	int NUMCOLS;
	int NUMROWS;
	int X;
	int Y;
	int MAXROW;
	char **MATRIX;
	int bufflen;
	char *buffer;
} RepFormat;

char *RepFormat_ToPicture(char *value, char *picture);
RepFormat *RepFormat_new(int col, int row);
void RepFormat_Clear(RepFormat *self);
void RepFormat_Move(RepFormat *self, int col, int row);
void RepFormat_Print(RepFormat *self, char *str);
void RepFormat_MVPrint(RepFormat *self, int col, int row, char *str);
void RepFormat_Printf(RepFormat *self, char *pformat, ...);
void RepFormat_MVPrintf(RepFormat *self, int col, int row, char *pformat, ...);
void RepFormat_PrintP(RepFormat *self, char *value, char *picture);
void RepFormat_MVPrintP(RepFormat *self, int col, int row, char *value, char *picture);
char *RepFormat_Center(RepFormat *self, char *value, int size);
void RepFormat_PrintC(RepFormat *self, char *value);
char *RepFormat_Getline(RepFormat *self, int row);
int  RepFormat_Nlines(RepFormat *self);
void RepFormat_Skip(RepFormat *self, int rows);
void RepFormat_Copy(RepFormat *self, RepFormat *other); 
void RepFormat_Destroy(RepFormat *self);
int  RepFormat_getX(RepFormat *self);
int  RepFormat_getY(RepFormat *self);
#endif
