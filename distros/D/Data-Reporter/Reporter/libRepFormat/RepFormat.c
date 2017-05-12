#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <math.h>
#include "RepFormat.h"

char *invalid(int size, char *output) {
	memset(output, '*', size);
	output[size] = '\0';
	return output;
}

char *str_picture(char *value, char *picture, char *output) {
	char *pch, *vch, *och;

	strcpy(output,"");
	pch = picture;
	vch = value;
	och = output;
	while (*pch != '\0') {
		switch (*pch) {
			case 'x':
			case 'X':
					if (*vch == '\0') {
						*och = ' ';
					} else {
						*och = *vch;
						vch++;
					}
					och++;
					break;
			case '~':
					vch++;
					break;
			case 'B':
			case 'b':
					*och = ' ';
					och++;
					break;
			default :
					*och = *pch;
					och++;
		}
		pch++;
	}
		
	*och = '\0';
	return output;
};

char *blank(int size, char *output) {
	memset(output, ' ', size);
	output[size] = '\0';
	return output;
}

int ndigits(float value) {
	int digits = 0;
	for (;fmod(value, 10) > 1;value /= 10, digits++);
	return digits;
};

char *rshift(int places, char *output) {
	char *aux;
	char *idx;
	int size = strlen(output);
	
	if (places > size)
		return output;
	aux = output+size-1;
	idx = aux-places;
	for (;idx != output;aux--,idx--) 
		*aux = *idx;
	*aux = *idx;
	aux--;
	for (;aux != output;aux--)
		*aux=' ';
	*aux=' ';
	
	return output;
}

char *lshift(int places, char *output) {
	char *aux = output;
	char *idx;
	if (places > strlen(output))
		return output;
	idx = aux+places;
	for (;*idx != '\0';aux++,idx++) 
		*aux = *idx;
	for (;*aux != '\0';aux++)
		*aux=' ';
	
	return output;
}

char *tonegative(char *output, char preC, char posC, int floatparen) {
	char *aux = output;	
	int size = strlen(output);

	if (*aux == ' ' && *(aux+1) == ' ')
		lshift(1, output);
	else if (*(aux+size-1) == ' ' && *(aux+size-2) == ' ' && preC != ' ')
		rshift(1, output);
	else {
		return invalid(strlen(output), output);
	}

	if (floatparen) {
		for(;*aux != '\0'; aux++) {
			if (*aux != ' ') {
				*(aux-1) = preC;
				break;
			}
		}
		aux = output+size-1;
		for(;aux != output; aux--) {
			if (*aux != ' ') {
				*(aux+1) = posC;
				break;
			}
		}
	} else {
		if (preC != ' ')
			*aux = preC;
		*(aux+size-1) = posC;
	}

	return output;
};

char *ltrim(char *output) {
	int places = 0;
	char *aux = output;
	for(;*aux == ' ';places++,aux++);
	if (places > 0)
		lshift(places, output);

	return output;
}

char *num_picture(double value, char *picture, char *output) {
	char *pch, *vch, *och, *tempval;
	char valpic[15];
	int ndig = 0, ndec = 0, isnegative = 0, size = 0, putdollar = 0;
	int has8 = 0, hasdoll = 0, hasdot = 0, hasB = 0;
	int implied = 0, floatparen = 0;
	char firstC = ' ';
	char prevC 	= ' ';
	char preC 	= ' ';
	char posC 	= ' ';

	pch = picture;
	for (;*pch != '\0';size++,pch++) {
		switch (toupper(*pch)) {
			case ',' :
						break;
			case '.' :	
						if (hasdot == 0) {
							hasdot = 1;
						} else {
							return invalid(strlen(picture), output);
						}
						break;
			case '$' : case '8' : case 'B' :
						if (*pch == '8') 
							has8 = 1;
						else if (*pch == '$')
							hasdoll = 1;
						else
							hasB = 1;
			case '0' : case '9' :
						if (hasdot == 0)
							ndig++;
						else
							ndec++;
						break;
			case 'P' : case 'M' :
						if (*(pch+2) == '\0') {
							firstC = toupper(*pch);
						} else {
							return invalid(strlen(picture), output);
						}
						break;
			case 'R' : case 'S' : case 'F' : case 'I' : 
						if (toupper(*pch) == 'I') {
							prevC = 'M';
							posC  = '-';
						} else {
							prevC = 'P';
							if (toupper(*pch) == 'R') {
								preC = '<';
								posC = '>';
							} else if (toupper(*pch) == 'S') {
								preC = '(';
								posC = ')';
							} else if (toupper(*pch) == 'F') {
								preC = '(';
								posC = ')';
								floatparen = 1;
							}
						}
						if (*(pch+1) == '\0' && firstC == prevC) {
							*(pch-1) = '\0';
							pch		-=2;
							break;
						} else {
							return invalid(strlen(picture), output);
						}
			case 'V' :
						if (hasdot == 0) {
							hasdot 	= 1;
							implied = 1;
						} else {
							return invalid(strlen(picture), output);
						}
						break;
			default	:	
						return invalid(strlen(picture), output);
		}
	}

	if (ndig < ndigits(value)) 
		return invalid(size, output);

	if (value == 0.0 && hasB == 1)
		return blank(size, output);	

	if (value < 0)
		isnegative = 1;
	
	if ((preC != ' ' || posC != ' ') && isnegative)
		value *= -1;

	memset(output, ' ', size);
	
	sprintf(valpic, "%%%d.%df", size, ndec);
	tempval = (char *) malloc(size+1);
	sprintf(tempval, valpic, value);
	
	vch = tempval;
	vch+=size-1;
	och = output;
	och+=size;
	*och = '\0';
	do {
		pch--;
		och--;
		switch(toupper(*pch)) {
			case 'B' :
			case '8' :
			case '9' :
						*och = *vch;
						vch--;
						break;
			case 'V' :
						vch--;
						och++;
						break;
			case '.' :
						*och = '.';
						vch--;
						break;
			case ',' :
						if (*vch != ' ') {
							*och = ',';
						} else {
							*och = ' ';
							vch--;
						}
						break;
			case '0' :
						if (*vch != ' ') 
							*och = *vch;
						else 
							*och = '0';
						vch--;
						break;
			case '$' :
						if (*vch != ' ') {
							*och = *vch;
						} else if (putdollar == 0){
							*och = '$';
							putdollar = 1;
						} else 
							*och = ' ';
						vch--;
						break;
		}
	} while(pch != picture);

	free(tempval);

	if (hasdoll && !putdollar)
		return invalid(size, output);

	if (isnegative && (preC != ' '  || posC != ' '))
		tonegative(output, preC, posC, floatparen);
	
	if (has8) 
		ltrim(output);
	
	return output;
};

char *RepFormat_ToPicture(char *value, char *picture) {
	static char ret[512];
	char *ach;
	int size = 0, isstr = 0, dig = 0, sign = 0, dot = 0;
	double numval = 0.0;

	strcpy(ret, "");	
	size = strlen(picture);
	if (size > 511)
		return invalid(511, ret);

	for(ach=picture; *ach!= '\0'; ach++) {
		if (toupper(*ach) == 'X') {
			isstr = 1;
			break;
		}
	}
	if (isstr) {
		str_picture(value, picture, ret);
	} else {
		for(ach=value; *ach != '\0'; ach++) {
			switch(*ach) {
				case '0': case '1': case '2': case '3': case '4': 
				case '5': case '6': case '7': case '8': case '9':
						dig=1;
						break;
				case '.':
						if (dot == 0)
							dot = 1;
						else
							return invalid(size, ret);
						break;
				case '+': case '-':
						if (sign == 0 && dig == 0)
							sign = 1;
						else
							return invalid(size, ret);
						break;
				default:
						return invalid(size, ret);
			}
		}
		numval = strtod(value, (char **) NULL);
		num_picture(numval, picture, ret);
	}
	return ret;
};

RepFormat *RepFormat_new(int cols, int rows) {
	int cont;
	RepFormat *self;

	self = (RepFormat *) malloc(sizeof(RepFormat));
	if (self == NULL) {
		return NULL;
	}
	self->NUMCOLS	= cols;
	self->NUMROWS	= rows;
	self->MAXROW	= 0;
	self->X			= 0;
	self->Y			= 0;
	self->bufflen	= self->NUMCOLS * self->NUMROWS;
	self->buffer 	= (char *) malloc(self->bufflen*sizeof(char));
	self->MATRIX 	= (char **) calloc(self->NUMROWS, sizeof(char *));

	for (cont=0; cont < self->NUMROWS; cont++) 
		self->MATRIX[cont] = (char *) self->buffer + (cont*self->NUMCOLS);

	RepFormat_Clear(self);
	return self;
}

void RepFormat_Clear(RepFormat *self) {
	memset(self->buffer, ' ', self->bufflen);
	self->X=0;
	self->Y=0;
	self->MAXROW=-1;
}

void RepFormat_Move(RepFormat *self, int col, int row) {
	if (col >= 0 && col < self->NUMCOLS)
		self->X = col;

	if (row >= 0 && row < self->NUMROWS)
		self->Y = row;

	if (self->Y > self->MAXROW)
		self->MAXROW = self->Y;

}

void RepFormat_Print(RepFormat *self, char *str) {
	char *dest;
	int size = strlen(str);

	if (self->MAXROW == -1)
		self->MAXROW = 0;

	if (size+self->X > self->NUMCOLS)
		size=self->NUMCOLS - self->X;
	
	dest = self->MATRIX[self->Y];
	dest += self->X;
	strncpy(dest, str, size);
	self->X+=size;
	
	if (self->X == self->NUMCOLS)
		self->X--; 
}

void RepFormat_MVPrint(RepFormat *self, int col, int row, char *str) {
	RepFormat_Move(self, col, row);
	RepFormat_Print(self, str);
}

void RepFormat_Printf(RepFormat *self, char *pformat, ...) {
	char aux[512];
	va_list ap;
	va_start(ap, pformat);
	strcpy(aux, "");
	vsprintf(aux, pformat, ap);
	va_end(ap);
	RepFormat_Print(self, aux);
}

void RepFormat_MVPrintf(RepFormat *self, int col, int row, char *pformat, ...) {
	char aux[512];
	va_list ap;
	
	va_start(ap, pformat);
	RepFormat_Move(self, col, row);
	strcpy(aux, "");
	vsprintf(aux, pformat, ap);
	va_end(ap);
	RepFormat_Print(self, aux);
}

void RepFormat_PrintP(RepFormat *self, char *value, char *picture) {
	RepFormat_Print(self, RepFormat_ToPicture(value, picture));
}

void RepFormat_MVPrintP(RepFormat *self, int col, int row, char *value, char *picture) {
	RepFormat_Move(self, col, row);
	RepFormat_PrintP(self, value, picture);
}

char *RepFormat_Center(RepFormat *self, char *value, int size) {
	static char ret[512];
	char *aux;
	int len_value;
	int ini;

	aux 		= ret;
	len_value	= strlen(value);
	
	if (size < 0)
		size = 0;
	
	if (size > 511)
		size = 511;
	
	if (len_value > 511)
		len_value = 511;

	if (len_value > size)
		len_value = size;
	
	memset(ret, ' ', size);
	ret[size] = '\0';

	ini = (size - len_value) / 2;
	aux+=ini;
	strncpy(aux, value, len_value);

	return ret;
}

void RepFormat_PrintC(RepFormat *self, char *value) {
	RepFormat_MVPrint(self, 0, self->Y, RepFormat_Center(self, value, self->NUMCOLS));
}

char *RepFormat_Getline(RepFormat *self, int row) {
	static char ret[512];
	char *aux;
	aux = ret;
	if (row < self->NUMROWS) {
		aux = self->MATRIX[row];
		strncpy(ret, aux, self->NUMCOLS);
		aux = ret;
		for(aux+=self->NUMCOLS-1; aux>=ret && *aux == ' ';aux--);
		aux++;
	}
	*aux = '\0';
	return ret;
}

int RepFormat_Nlines(RepFormat *self) {
	return self->MAXROW + 1;
}

int RepFormat_getX(RepFormat *self) {
	return self->X;
}

int RepFormat_getY(RepFormat *self) {
	return self->Y;
}

void RepFormat_Skip(RepFormat *self, int rows) {
	RepFormat_Move(self, 0, self->MAXROW + rows);
}

void RepFormat_Copy(RepFormat *self, RepFormat *other) {
	char *orig;
	int remain, size2cpy, newx, newy;
	
	size2cpy = other->NUMCOLS * RepFormat_Nlines(other);
	remain = (self->NUMROWS - (self->Y + 1)) * self->NUMCOLS;
	if (size2cpy > remain)
		size2cpy = remain;
	
	if (size2cpy > 0) {
		orig = self->MATRIX[self->Y+1];
		memcpy(orig, other->MATRIX[0], size2cpy);
		newy = (size2cpy / self->NUMCOLS) + self->Y;
		newx = size2cpy % self->NUMCOLS;
		if (newx == 0)
			newx = self->NUMCOLS -1 ;
		else
			newy++;
		RepFormat_Move(self, newx, newy);
	}
}

void RepFormat_Destroy(RepFormat *self) {
	free(self->buffer);
	free(self->MATRIX);
	free(self);
}
