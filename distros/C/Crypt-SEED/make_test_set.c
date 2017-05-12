/******************************************************************************* 
*	This program create a set of verification data for testing perl module
*	No copyright ^^ of course.
*
*******************************************************************************/


/******************************* Include files ********************************/

#include "SEED_KISA.h"
#include <stdlib.h>

/*******************************SEED test code ********************************/

int isSame( const BYTE*, BYTE* );
void printVerificationData(int, const BYTE*, const BYTE* );

int main() {
	int num;

	num = 0;
	printVerificationData( num++, "(6789Aesetof1234", "우리한글좋은글자" );
	printVerificationData( num++, "9ABCDEF&BCDEF&);", "영희야놀자.싫어!" );
	printVerificationData( num++, "0,0x02,0x0x0x00,", "키사시드멋져부러" );
	printVerificationData( num++, "00,0x00,00,0x01,", "Above_are_Korean" );
	printVerificationData( num++, "05,C,0x0D,0xinte", "Try_Chinese_here" );
	printVerificationData( num++, "%02ecrypt(X&ypti", "tsu_tsai_narima?" );
	printVerificationData( num++, "y[i;i<16;i])obee", "Fungyo,Ni_hao_ma" );
	printVerificationData( num++, "/inputpl,0x0B,0x", "Try_Japanese_too" );
	printVerificationData( num++, ".//(&01234Ine&SE", "O-gen-ki-desuka?" );
	printVerificationData( num++, "D56789ABCD234a[i", "DontUse_encoding" );
	printVerificationData( num++, "(&%(pdwRou02rive", "^_^; ASCII_ONLY!" );
	printVerificationData( num++, "/Thyright^isfver", "If_you_use_perl," );
	printVerificationData( num++, "eateasetduleNoco", "Were_all_friends" );
	printVerificationData( num++, "s/#incluain(){ou", "`~!@#$%^&*()-=_+" );
	printVerificationData( num++, "};i(&%02X&nttkey", "0123456789[]|\\{}" );
	printVerificationData( num++, "usersecr++)print", "\",./<>?;\':zxcvbn" );
	printVerificationData( num++, "laintext);for(i=", "asdfghjkASDFGHJK" );
	printVerificationData( num++, "CDEF&);outF&&);o", "qwertyuiQWERTYUI" );
	printVerificationData( num++, "789ABCDE6789ABCD", "poiuytrePOIUYTRE" );
	printVerificationData( num++, "789ABCDEF&ABBCDE", "lkjhgfdsLKJHGFDS" );
	printVerificationData( num++, "2345678912345678", "mnbvcxzaMNBVCXZA" );
	printVerificationData( num++, "BCD9ABCDEFEFABCD", "Eout(&&45678EF&)" );
	printVerificationData( num++, "1234567801234567", "8&,&012AF&,9;BCD" );
	printVerificationData( num++, "678456789A9A5678", "9EF&);D&01239ABC" );
	printVerificationData( num++, "ut(&0123out(&012", "3BCDEF&5ABC4D678" );
	printVerificationData( num++, "123cryptio45ut()", "{RoundRRound2];/" );
	printVerificationData( num++, "F&);voidkeysfore", "nnordeceDWOo/y[3" );
	printVerificationData( num++, "tioUsersecnB0x00", ",0,0x000,0x00,0x" );
	printVerificationData( num++, "Key[16]=0,0x00,/", "/retkey,0x0{00x0" );
	printVerificationData( num++, "serData,pdKentf(", "&SeedEnyptio#n&)" );
	printVerificationData( num++, "yptionprncrypt(p", "bwRound.#n~i;..." );
	printVerificationData( num++, ");/<16;i++/pciph", "et:&);xintf(erte" );
	printVerificationData( num++, ")printf(&&Crte(x", "iph&);,eounekrse" );
	printVerificationData( num++, "]);//Decn&);Seed", "DpbDataenprrncry" );
	printVerificationData( num++, "wRor(i=0;iunpted", "dlaint(ntexttf(&" );
	printVerificationData( num++, "rintdecrext:&);f", "o<16;i+patayPrin" );
	printVerificationData( num++, "rinKey:#n&tf;//P", "rntf(&rkeysadipr" );
	printVerificationData( num++, "bData[i]#n#nRoun", "d);for(rint)ioun" );
	printVerificationData( num++, "23456789AB566789", "AA789ABCDEEF&);o" );
	printVerificationData( num++, "&,&01234F&,&0123", "4CDEF&)1BCD59234" );
	printVerificationData( num++, "t(&0123456011234", "5567899EF&);0123" );
	printVerificationData( num++, "BCDEF&,&ABCDEF&,", "&789ABCu67804t(&" );
	printVerificationData( num++, "&);EF&,&01ouF&,&", "00123449ABCDout(" );
	printVerificationData( num++, "6789ABCD56789ABC", "D234567F123E&&);" );
	printVerificationData( num++, ";i<2d,1:%016,0:%", "0i]);pt1,pdwKey[" );
	printVerificationData( num++, "ntf(&K%2rintf(&K", "%8X#n&,o8X~d2und" );
	printVerificationData( num++, "&);EF&,&01ouF&,&", "00123449ABCDout(" );
	printVerificationData( num++, "6789AB5cryptedda", "tafor(i9AEF123E&" );
	printVerificationData( num++, "BCD9ABCDEFEFABCD", "Eout(&&45678EF&)" );
	printVerificationData( num++, "1234567801234567", "8&,&012AF&,9;BCD" );
	printVerificationData( num++, "678456789A9A5678", "9EF&);D&01239ABC" );
	printVerificationData( num++, "ut(&0123out(&012", "3BCDEF&5ABC4D678" );
	printVerificationData( num++, "123cryptio45ut()", "{RoundRRound2];/" );
	printVerificationData( num++, "F&);voidkeysfore", "nnordeceDWOo/y[3" );
	printVerificationData( num++, "tioUsersecnB0x00", ",0,0x000,0x00,0x" );
	printVerificationData( num++, "Key[16]=0,0x00,/", "/retkey,0x0{00x0" );
	printVerificationData( num++, "0,0x02,0x0x0x00,", "0]={0x,};BYTta[1" );
	printVerificationData( num++, "00,0x00,00,0x01,", "03,0x04px0006bDa" );
	printVerificationData( num++, "05,C,0x0D,0xinte", "x,0x0Abrypte,0x0" );
	printVerificationData( num++, "/inputpl,0x0B,0x", "00x0E,00ttoa9x08" );
	printVerificationData( num++, "};i(&%02X&nttkey", "p<16;itey:&)i=0;" );
	printVerificationData( num++, "usersecr++)print", "f,pbUsefrineior(" );
	printVerificationData( num++, "y[i;i<16;i])obee", "next:&printflain" );
	printVerificationData( num++, "laintext);for(i=", "0++)pri&crytt#nP" );
	printVerificationData( num++, "(&%(pdwRou02rive", "reySeedfromucret" );
	printVerificationData( num++, "[i]);//DdRoundKe", "yndKey,eounekrse" );
	return 0;
}

void printVerificationData(int ser, const BYTE* uKey, const BYTE* data)
{
	DWORD pdwRoundKey[32];	/* Round keys for encryption or decryption */
	BYTE pbUserKey[16]; 	/* User secret key                         */
	BYTE pbData[16];	/* input plaintext to be encrypted         */
	int i;
	
	for(i=0;i<16;i++) {
		pbUserKey[i] = uKey[i];
		pbData[i] = data[i];
	}
	
	printf("%d:UKEY=%s\tTEXT=%s\t", ser, uKey, data);

	/* Derive roundkeys from user secret key */
	SeedRoundKey(
		pdwRoundKey, 
		pbUserKey);
	
	printf ("RKEY=");
	for (i=0;i<16;i++) {
		printf("%08X", pdwRoundKey[2*i]);
		printf("%08X", pdwRoundKey[2*i+1]);
	}
	printf("\t");
	
	/* Encryption */
	SeedEncrypt(
		pbData, 
		pdwRoundKey);

	/* print encrypted data(ciphertext) */
	printf ("CIPH=");
	for (i=0;i<16;i++)	
		printf("%02X",pbData[i]);
	printf("\n");

	/* Decryption */
	SeedDecrypt(
		pbData, 
		pdwRoundKey);

	/* Print decrypted data(plaintext) */
	if( !isSame(data, pbData) ) {
		printf("Unmatched!!!\n");
		exit(-1);
	}
}

int isSame( const BYTE* a, BYTE* b ) {
	int i;
	for(i=0;i<16;i++) {
		if( a[i] != b[i] ) { return 0; }
	}
	return 1;
}

