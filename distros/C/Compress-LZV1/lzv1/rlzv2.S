/*	
 *	LZV decompression written in assembly.
 *
 *	Written by Antoine de Maricourt (dumesnil@etca.fr)
 *	                12 Apr 1995
 *
 *	NOTE: The use of this algorithm may be restricted by some
 *	      patent. Please check if this is the case in your 
 *	      country before using it.
 *
 *	Interface :
 *	-----------
 *
 *	   int rLZV2 (char *ib, char *ob, int il, int ol);
 *
 *              ib = input buffer (compressed data)
 *              ob = output buffer (uncompressed data)
 *		il = number of bytes in the input buffer
 *		ol = number of bytes to be uncompressed
 *
 *	The routine may write more (i.e., 65) bytes than requested
 *	(and could be modified in order to write exactly the requested
 *	number if this is really important). However, it will not write
 *	more than the original number of bytes in the uncompressed
 *	data. The returned value is the number of bytes written to
 *	output buffer.
 *
 *	The coding method is different from the original one. This
 *	allows matches that can be more distant. This also reduces
 *	the maximum match length from 264 to 65.
 *
 *	The algorithm and the coding method have been taken from
 *	file lzv.c originaly written by Hermann Vogt, and whose
 *	original copyright notice follows:
 *
 *	-------
 *	Copyright (c) 1994 Hermann Vogt. Redistribution of this file is
 *	permitted under the GNU Public Licence.
 *
 *	The method presented here is faster and compresses better
 *	than lzrw1 and lzrw1-a. I named it lzv for "Lev-Zimpel-Vogt".
 *	It uses ideas introduced by Ross Williams in his algorithm 
 *	lzrw1 [R. N. Williams (1991): "An Extremly Fast ZIV-Lempel Data
 *	Compression Algorithm", Proceedings IEEE Data Compression
 *	Conference, Snowbird, Utah, 362-371] and by Fiala and Green
 *	in their algorithm a1 [E. R. Fiala, D. H. Greene (1989): 
 *	"Data Compression with Finite Windows", Communications of the
 *	ACM, 4, 490-505]. Because lzv differs strongly from both,
 *	I hope there will be no	patent problems. The hashing-method 
 *	has been stolen from Jean-loup Gailly's (patent free) gzip.
 *	-------
 *	Copyright (c) 1995 Antoine de Maricourt. Redistribution
 *	of this file is permitted under the GNU Public License.
 */

#include <linux/linkage.h>

#define A0	28
#define A1	32
#define A2	36
#define A3	40

	.text
ENTRY(ext2_LZV2_decompress)
	pushl %ebp
	pushl %edi
	pushl %esi
	pushl %ebx			# be safe
	pushl %ecx
	pushl %edx

	movl A0(%esp), %esi		# esi = input buffer
	movl A1(%esp), %edi		# edi = output buffer
	movl %esi, %ebx
	addl A2(%esp), %ebx		# ebx = input limit
	movl %edi, %edx
	addl A3(%esp), %edx		# edx = output limit
	xorl %ecx, %ecx
	xorl %eax, %eax
	cld

	ALIGN

L10:	cmpl %esi, %ebx			# check for input overflow
	jna L13

	/*
	 *	Get the opcode
	 */

	movb (%esi), %al		# load opcode 
	testb $7, %al			# test 3 lower bits
	jne L11

	/*
	 *	This is a literal
	 */

	shrb $3, %al			# store its len into ecx
	incb %al			
	movb %al, %cl
	incl %esi
	rep; movsb
	cmpl %edx, %edi			# check for output overflow
	jb L10				# and continue
	jmp L13

	/*
	 *	This is a match
	 */

	ALIGN

L11:	movb %al, %cl
	andb $7, %cl			# store its len into ecx
	cmpb $7, %cl	
	je L12

	/*
	 *	This is a small match
	 */

	addl $2, %ecx
	shll $5, %eax
	movb 1(%esi), %al
	notl %eax
	lea 2(%esi), %ebp		# save next value of esi
	lea (%edi,%eax), %esi		# load pointer to match
	cmpl A1(%esp), %esi		# safety check
	jb L13
	rep; movsb			# copy the match
	xorl %eax, %eax
	movl %ebp, %esi			# restore esi
	cmpl %edx, %edi			# check for output overflow
	jb L10				# and continue
	jmp L13

	/*
	 *	This is a big match or a far match
	 */

	ALIGN

L12:	movb 1(%esi), %cl
	shll $7, %eax			# store the offset into eax
	movb %cl, %al
	andb $0xfc, %ah
	andb $0x03, %al
	orb %al, %ah
	movb 2(%esi), %al
	notl %eax
	shrb $2, %cl			# adjust match len
	addl $2, %ecx
	lea 3(%esi), %ebp		# save next value of esi
	lea (%edi,%eax), %esi		# load pointer to match
	cmpl A1(%esp), %esi		# safety check
	jb L13
	rep; movsb			# copy the match
	xorl %eax, %eax
	movl %ebp, %esi			# restore esi
	cmpl %edx, %edi			# check for output overflow
	jb L10				# and continue

	/*
	 *	The end.
	 */

L13:	movl %edi, %eax
	subl A1(%esp),%eax

	popl %edx
	popl %ecx
	popl %ebx
	popl %esi
	popl %edi
	popl %ebp
	ret

