#ifndef RNA_H
#define RNA_H

typedef struct {
	unsigned int state : 4;
	unsigned int missing : 1;
	unsigned int gap : 1;
	unsigned int upper : 1;
	unsigned int fundamental : 1;	
} DNAState;

char[16] IUPAC_RNA = { 
	'-', // 0
	'A', // 1
	'C', // 2
	'M', // 3
	'G', // 4
	'R', // 5
	'S', // 6
	'V', // 7
	'U', // 8
	'W', // 9
	'Y', // 10
	'H', // 11
	'K', // 12
	'D', // 13
	'B', // 14
	'N'  // 15
};

//0000
#define RNA_STATE_GAP 0

//0001
#define RNA_STATE_A 1

//0010
#define RNA_STATE_C 2

//0011
#define RNA_STATE_M 3

//0100
#define RNA_STATE_G 4

//0101
#define RNA_STATE_R 5

//0110
#define RNA_STATE_S 6

//0111
#define RNA_STATE_V 7

//1000
#define RNA_STATE_U 8

//1001
#define RNA_STATE_W 9

//1010
#define RNA_STATE_Y 10

//1011
#define RNA_STATE_H 11

//1100
#define RNA_STATE_K 12

//1101
#define RNA_STATE_D 13

//1110
#define RNA_STATE_B 14

//1111
#define RNA_STATE_N 15

#endif