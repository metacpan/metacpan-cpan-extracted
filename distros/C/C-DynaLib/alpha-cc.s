	.verstamp 3 11
	.set noreorder
	.set volatile
	.set noat
	.file	1 "alpha-cc.c"
gcc2_compiled.:
__gnu_compiled_c:
.text
	.align 3
	.globl dynalib_alpha_excuse_for_asm
	.ent dynalib_alpha_excuse_for_asm
dynalib_alpha_excuse_for_asm:
	ldgp $29,0($27)
dynalib_alpha_excuse_for_asm..ng:
	lda $30,-64($30)
	.frame $15,64,$26,0
	stq $26,0($30)
	stq $15,8($30)
	.mask 0x4008000,-64
	bis $30,$30,$15
	.prologue 1
	stq $17,24($15)
	stq $18,32($15)
	stq $19,40($15)
	stq $20,48($15)
	stq $21,56($15)
	ldq $3,72($15)
	stq $16,16($15)
	ldq $5,80($15)
	ble $3,$34
	s8addq $3,0,$1
	lda $2,-4096($30)
	subq $30,$1,$4
	cmpult $4,$2,$1
	beq $1,$36
$35:
	stq $31,0($2)
	lda $2,-8192($2)
	cmpule $2,$4,$1
	beq $1,$35
	stq $31,0($4)
$36:
	bis $4,$4,$30
	bis $30,$30,$2
	ble $3,$34
	.align 5
$39:
	ldt $f1,0($5)
	subq $3,1,$3
	addq $5,8,$5
	cmple $3,0,$1
	stt $f1,0($2)
	addq $2,8,$2
	beq $1,$39
$34:
	ldq $16,16($15)
	ldq $17,24($15)
	ldq $18,32($15)
	ldq $19,40($15)
	ldq $20,48($15)
	ldq $21,56($15)
	ldt $f16, 16($15)
	ldq $27,64($15)
	ldt $f17, 24($15)
	ldt $f18, 32($15)
	ldt $f19, 40($15)
	ldt $f20, 48($15)
	ldt $f21, 56($15)
	jsr $26,($27),0
	ldgp $29,0($26)
	bis $15,$15,$30
	ldq $26,0($30)
	ldq $15,8($30)
	addq $30,64,$30
	ret $31,($26),1
	.end dynalib_alpha_excuse_for_asm
