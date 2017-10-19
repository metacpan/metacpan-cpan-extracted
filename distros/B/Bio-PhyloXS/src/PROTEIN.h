#ifndef PROTEIN_H
#define PROTEIN_H

typedef struct {
	unsigned int state : 5;
	unsigned int missing : 1;
	unsigned int gap : 1;
	unsigned int fundamental : 1;	
} ProteinState;

char[16] IUPAC_PROTEIN = { 
	'-',
	'A',
	'D',
	'C',
	'N',
	'F',
	'G',
	'H',
	'E',
	'K',
	'L',
	'M',
	'I',
	'P',
	'S',
	'R',
	'Q',
	'T',
	'U',
	'V',
	'W',
	'X',
	'B',
	'Y',
	'Z',
	'*'
};

//00000
#define AA_STATE_GAP 0

//00001
#define AA_STATE_A 1

//00010
#define AA_STATE_D 2

//00011
#define AA_STATE_C 3

//00100
#define AA_STATE_N 4

//00101
#define AA_STATE_F 5

//00110
#define AA_STATE_G 6

//00111
#define AA_STATE_H 7

//01000
#define AA_STATE_E 8

//01001
#define AA_STATE_K 9

//01010
#define AA_STATE_L 10

//01011
#define AA_STATE_M 11

//01100
#define AA_STATE_I 12

//01101
#define AA_STATE_P 13

//01110
#define AA_STATE_S 14

//01111
#define AA_STATE_R 15

//10000
#define AA_STATE_Q 16

//10001
#define AA_STATE_T 17

//10010
#define AA_STATE_U 18

//10011
#define AA_STATE_V 19

//10100
#define AA_STATE_W 20

//10101
#define AA_STATE_X 21

//10110
#define AA_STATE_B 22

//10111
#define AA_STATE_Y 23

//11000
#define AA_STATE_Z 24

//11001
#define AA_STATE_STAR 25

#endif