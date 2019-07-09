; comment
macro M1 {
	inc hl
	dec de
}
	org 0x100
	M1
	ld a,1 : ld b,2 : call 0x200 : call 0x1234 ; comment
	M1
