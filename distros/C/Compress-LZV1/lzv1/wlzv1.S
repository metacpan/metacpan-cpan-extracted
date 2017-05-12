/*	
 *	LZV compression written in assembly.
 *
 *	Written by Antoine de Maricourt (dumesnil@etca.fr)
 *	                21 Mar 1995
 *
 *	NOTE: The use of this algorithm may be restricted by some
 *	      patent. Please check if this is the case in your 
 *	      country before using it.
 *
 *	Interface :
 *	-----------
 *
 *	   int wLZV1 (char *ib, char *ob, int il, int ol);
 *
 *              ib = input buffer (uncompressed data)
 *              ob = output buffer (compressed data)
 *		il = number of bytes in the input buffer
 *		ol = maximum number of bytes for compressed data
 *
 *	The routine may read more (i.e., 3) bytes than the specified
 *	size for the input buffer. It may also write more (i.e., 264)
 *	bytes than the specified size for the output buffer before it
 *	realizes it must stop. The caller should be ready for that.
 *	Returned value is the size in byte of the compressed data, or
 *	0 if the data can not be compressed into less bytes than ol.
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
#include "lzv1.h"

#if 0
#define HTAB	SYMBOL_NAME(ext2_lzv1_htab)
#else
#define HTAB	40(%esp)
#endif

#define A0	32
#define A1	36
#if 0
#define A2	40
#define A3	44
#else
#define A2	44
#define A3	48
#endif
#define L0

	/* for i386 */
#define bswap rol $16,

#define OutputLiteral(_b)	\
	movb _b, (%edi);	\
	incl %edi;		\
	andl $255, %ecx;	\
	subl %ecx, %esi;	\
	rep; movsb

#define UpdateHashKey(_b)	\
	shll $HSHIFT, %ebx;	\
	xorb _b, %bl

#define UpdateHashTable(_w)	\
	andl $HMASK, %ebx;	\
	movw _w, (%ebp,%ebx,2)

#if 0
.comm HTAB, 4				# hash table
#endif

	.text

ENTRY(ext2_LZV1_compress)
	pushl %ebp
	pushl %edi
	pushl %esi
	pushl %ebx			# be safe
	pushl %ecx
	pushl %edx
	subl $4, %esp

	movl A0(%esp), %esi		# esi = input buffer
	movl A1(%esp), %edi		# edi = output buffer
	movl A2(%esp), %ecx
	addl %esi, %ecx
	movl %ecx, A2(%esp)		# input limit
	subl $3, %ecx
	movl %ecx, L0(%esp)
	addl %edi, A3(%esp)		# output limit

	movl HTAB, %ebp			# get pointer to hash table
	xorl %ecx, %ecx			# clear literal len
	xorl %edx, %edx			# clear input position
	cld

	movzbl (%esi), %ebx		# initialize hash key
	UpdateHashKey (1(%esi))

	/*
	 *	eax = 
	 *	ebx = hash key (bx)
	 *	ecx = literal len (cl) + tmp data (ch)
	 *	edx = 
	 *	esi = source pointer
	 *	edi = destination pointer
	 *	ebp = hash table address
	 */

L10:	cmpl A2(%esp), %esi		# check for input overflow
	jae L40

	UpdateHashKey (2(%esi))		# update hash key

	/*
	 *	Test for potential match
	 */

	andl $HMASK, %ebx
	movl %edx, %eax
	movw (%ebp,%ebx,2), %ax		# eax = Hi(ip)|Lo(m_pos)
	movw %dx, (%ebp,%ebx,2)		# edx = ip
	cmpl %edx, %eax
	jb L11
	cmpl $0x10000, %eax
	jb L30
	subl $0x10000, %eax

L11:	subl %edx, %eax			# eax = m_pos - ip [= -m_off - 1 < 0]
	cmpl $-MOFF, %eax
	jb L30
	cmpl L0(%esp), %esi
	jae L30

	movb (%esi), %ch		# compare first byte
	cmpb %ch, (%esi,%eax)
	jne L30

	movb 1(%esi), %ch		# compare second byte
	cmpb %ch, 1(%esi,%eax)
	jne L30

	movb 2(%esi), %ch		# compare third byte
	cmpb %ch, 2(%esi,%eax)
	jne L30

	/*
	 *	Flush pending literal on output first,
	 *	so that we do not need anymore its len.
	 */

	testb %cl, %cl
	je L12
	movb %cl, %ch
	decb %ch
	shlb $3, %ch
	OutputLiteral (%ch)

	/*
	 *	Find length of current match
	 */

L12:	lea 2(%esi), %esi

	movl A2(%esp), %ecx		# find maximum match len
	subl %esi, %ecx
	cmpl $MML, %ecx
	jbe L13
	movl $MML, %ecx

L13:	bswap %ebx			# save hash key
	movw %cx, %bx			# save max match len

	xchg %eax, %edi			# save edi
	lea (%esi,%edi), %edi		# get pointer to potential match

	repe; cmpsb
	jz L14
	incl %ecx
	decl %esi
	decl %edi

L14:	subw %cx, %bx			# match len

	xchg %eax, %edi			# restore edi
	subl %esi, %eax			# restore the offset

	/*
	 *	Output offset and length of match.
	 */

	notl %eax
	movzwl %bx, %ecx

	cmpw $7, %bx
	jae L17

	shlb $3, %ah			# output 2 bytes (len < 7)
	orb %bl, %ah
	movb %ah, (%edi)
	jmp L18

L17:	shlb $3, %ah			# output 3 bytes (len >= 7)
	orb $7, %ah
	movb %ah, (%edi)
	subw $7, %bx
	incl %edi
	movb %bl, (%edi)

L18:	movb %al, 1(%edi)
	lea 2(%edi), %edi

	/*
	 *	Update hash table
	 */

	bswap %ebx
	subl %ecx, %esi

L16:	incl %edx
	incl %esi
	UpdateHashKey ((%esi))
	UpdateHashTable (%dx)
	decl %ecx
	jne L16

	incl %edx
	UpdateHashKey (1(%esi))
	UpdateHashTable (%dx)
	incl %edx

	xorl %ecx, %ecx			# reset literal len

	cmpl A3(%esp), %edi		# check for output overflow
	jbe L10				# and continue
	jmp L40
	
	/*
	 *	Not a match.
	 */

	ALIGN

L30:	incl %edx; incl %esi
	incb %cl			# update literal len

	cmpb $MLL, %cl			# flush pending literal
	jb L32				# if needed
	OutputLiteral ($0xf8)
	xorb %cl, %cl

L32:	cmpl A3(%esp), %edi		# check for output overflow
	jbe L10				# and continue
	
	/*
	 *	The end.
	 */

L40:	testb %cl, %cl			# flush pending literal
	je L41				# if needed
	movb %cl, %ch
	decb %ch
	shlb $3, %ch
	OutputLiteral (%ch)

L41:	xorl %eax, %eax			# return 0 if output overflow
	cmpl A3(%esp), %edi
	jae L42 
	movl %edi, %eax
	subl A1(%esp),%eax

L42:	addl $4, %esp
	popl %edx
	popl %ecx	
	popl %ebx	
	popl %esi
	popl %edi
	popl %ebp
	ret
