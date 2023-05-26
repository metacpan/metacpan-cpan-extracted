;------------------------------------------------------------------------------
; CPU::Z80::Disassembler control file
;------------------------------------------------------------------------------

0000 :F t/data/zx81.rom

	:<; ===========================================================
	:<; An Assembly Listing of the Operating System of the ZX81 ROM
	:<; ===========================================================
	:<; -------------------------
	:<; Last updated: 13-DEC-2004
	:<; -------------------------
	:<;
	:<; Work in progress.
	:<; This file will cross-assemble an original version of the "Improved"
	:<; ZX81 ROM.  The file can be modified to change the behaviour of the ROM
	:<; when used in emulators although there is no spare space available.
	:<;
	:<; The documentation is incomplete and if you can find a copy
	:<; of "The Complete Spectrum ROM Disassembly" then many routines
	:<; such as POINTERS and most of the mathematical routines are
	:<; similar and often identical.
	:<;
	:<; I've used the labels from the above book in this file and also
	:<; some from the more elusive Complete ZX81 ROM Disassembly
	:<; by the same publishers, Melbourne House.
	:<
	:<

#include zx81_sysvars.ctl


0000:C
	:#
	:#
	:#;*****************************************
	:#;** Part 1. RESTART ROUTINES AND TABLES **
	:#;*****************************************
	:#
	:#; -----------
	:#; THE 'START'
	:#; -----------
	:#; All Z80 chips start at location zero.
	:#; At start-up the Interrupt Mode is 0, ZX computers use Interrupt Mode 1.
	:#; Interrupts are disabled .
	:#
	:#;; START
0000 D3FD       out ($FD), a	:C START
	:; Turn off the NMI generator if this ROM is 
	:; running in ZX81 hardware. This does nothing 
	:; if this ROM is running within an upgraded
	:; ZX80.

0002:C
0002 01FF7F     ld bc, $7FFF	:C
	:; Set BC to the top of possible RAM.
	:; The higher unpopulated addresses are used for
	:; video generation.

0005:C
0005 C3CB03     jp $03CB	:C
	:; Jump forward to RAM-CHECK.
	:;

0008:C
	:#; -------------------
	:#; THE 'ERROR' RESTART
	:#; -------------------
	:#; The error restart deals immediately with an error. ZX computers execute the 
	:#; same code in runtime as when checking syntax. If the error occurred while 
	:#; running a program then a brief report is produced. If the error occurred
	:#; while entering a BASIC line or in input etc., then the error marker indicates
	:#; the exact point at which the error lies.
	:#
	:#;; ERROR-1
0008 2A1640     ld hl, ($4016)	:C ERROR_1
	:; fetch character address from CH_ADD.

000B:C
000B 221840     ld ($4018), hl	:C
	:; and set the error pointer X_PTR.

000E:C
000E 1846       jr $0056	:C
	:; forward to continue at ERROR-2.
	:;

0010:C
	:#; -------------------------------
	:#; THE 'PRINT A CHARACTER' RESTART
	:#; -------------------------------
	:#; This restart prints the character in the accumulator using the alternate
	:#; register set so there is no requirement to save the main registers.
	:#; There is sufficient room available to separate a space (zero) from other
	:#; characters as leading spaces need not be considered with a space.
	:#
	:#;; PRINT-A
0010 A7         and a	:C PRINT_A
	:; test for zero - space.

0011:C
0011 C2F107     jp nz, $07F1	:C
	:; jump forward if not to PRINT-CH.
	:;

0014:C
0014 C3F507     jp $07F5	:C
	:; jump forward to PRINT-SP.
	:;
	:; ---
	:;

0017:B
0017-0017 FF	:B
	:; unused location.
	:;

0018:C
	:#; ---------------------------------
	:#; THE 'COLLECT A CHARACTER' RESTART
	:#; ---------------------------------
	:#; The character addressed by the system variable CH_ADD is fetched and if it
	:#; is a non-space, non-cursor character it is returned else CH_ADD is 
	:#; incremented and the new addressed character tested until it is not a space.
	:#
	:#;; GET-CHAR
0018 2A1640     ld hl, ($4016)	:C GET_CHAR
	:; set HL to character address CH_ADD.

001B:C
001B 7E         ld a, (hl)	:C
	:; fetch addressed character to A.
	:;

001C:C
	:#;; TEST-SP
001C A7         and a	:C TEST_SP
	:; test for space.

001D:C
001D C0         ret nz	:C
	:; return if not a space
	:;

001E:C
001E 00         nop	:C
	:; else trickle through

001F:C
001F 00         nop	:C
	:; to the next routine.
	:;

0020:C
	:#; ------------------------------------
	:#; THE 'COLLECT NEXT CHARACTER' RESTART
	:#; ------------------------------------
	:#; The character address in incremented and the new addressed character is 
	:#; returned if not a space, or cursor, else the process is repeated.
	:#
	:#;; NEXT-CHAR
0020 CD4900     call $0049	:C NEXT_CHAR
	:; routine CH-ADD+1 gets next immediate
	:; character.

0023:C
0023 18F7       jr $001C	:C
	:; back to TEST-SP.
	:;

0025:B
	:#; ---
	:#
0025-0027 FFFFFF	:B
	:; unused locations.
	:;

0028:C
	:#; ---------------------------------------
	:#; THE 'FLOATING POINT CALCULATOR' RESTART
	:#; ---------------------------------------
	:#; this restart jumps to the recursive floating-point calculator.
	:#; the ZX81's internal, FORTH-like, stack-based language.
	:#;
	:#; In the five remaining bytes there is, appropriately, enough room for the
	:#; end-calc literal - the instruction which exits the calculator.
	:#
	:#;; FP-CALC
0028 C39D19     jp $199D	:C FP_CALC
	:; jump immediately to the CALCULATE routine.
	:;

002B:C
	:#; ---
	:#
	:#;; end-calc
002B F1         pop af	:C end_calc
	:; drop the calculator return address RE-ENTRY

002C:C
002C D9         exx	:C
	:; switch to the other set.
	:;

002D:C
002D E3         ex (sp), hl	:C
	:; transfer H'L' to machine stack for the
	:; return address.
	:; when exiting recursion then the previous
	:; pointer is transferred to H'L'.
	:;

002E:C
002E D9         exx	:C
	:; back to main set.

002F:C
002F C9         ret	:C
	:; return.
	:;
	:;

0030:C
	:#; -----------------------------
	:#; THE 'MAKE BC SPACES'  RESTART
	:#; -----------------------------
	:#; This restart is used eight times to create, in workspace, the number of
	:#; spaces passed in the BC register.
	:#
	:#;; BC-SPACES
0030 C5         push bc	:C BC_SPACES
	:; push number of spaces on stack.

0031:C
0031 2A1440     ld hl, ($4014)	:C
	:; fetch edit line location from E_LINE.

0034:C
0034 E5         push hl	:C
	:; save this value on stack.

0035:C
0035 C38814     jp $1488	:C
	:; jump forward to continue at RESERVE.
	:;

0038:C
	:#; -----------------------
	:#; THE 'INTERRUPT' RESTART
	:#; -----------------------
	:#;   The Mode 1 Interrupt routine is concerned solely with generating the central
	:#;   television picture.
	:#;   On the ZX81 interrupts are enabled only during the interrupt routine, 
	:#;   although the interrupt 
	:#;   This Interrupt Service Routine automatically disables interrupts at the 
	:#;   outset and the last interrupt in a cascade exits before the interrupts are
	:#;   enabled.
	:#;   There is no DI instruction in the ZX81 ROM.
	:#;   An maskable interrupt is triggered when bit 6 of the Z80's Refresh register
	:#;   changes from set to reset.
	:#;   The Z80 will always be executing a HALT (NEWLINE) when the interrupt occurs.
	:#;   A HALT instruction repeatedly executes NOPS but the seven lower bits
	:#;   of the Refresh register are incremented each time as they are when any 
	:#;   simple instruction is executed. (The lower 7 bits are incremented twice for
	:#;   a prefixed instruction)
	:#;   This is controlled by the Sinclair Computer Logic Chip - manufactured from 
	:#;   a Ferranti Uncommitted Logic Array.
	:#;
	:#;   When a Mode 1 Interrupt occurs the Program Counter, which is the address in
	:#;   the upper echo display following the NEWLINE/HALT instruction, goes on the 
	:#;   machine stack.  193 interrupts are required to generate the last part of
	:#;   the 56th border line and then the 192 lines of the central TV picture and, 
	:#;   although each interrupt interrupts the previous one, there are no stack 
	:#;   problems as the 'return address' is discarded each time.
	:#;
	:#;   The scan line counter in C counts down from 8 to 1 within the generation of
	:#;   each text line. For the first interrupt in a cascade the initial value of 
	:#;   C is set to 1 for the last border line.
	:#;   Timing is of the utmost importance as the RH border, horizontal retrace
	:#;   and LH border are mostly generated in the 58 clock cycles this routine 
	:#;   takes .
	:#
	:#;; INTERRUPT
0038 0D         dec c	:C INTERRUPT
	:; (4)  decrement C - the scan line counter.

0039:C
0039 C24500     jp nz, $0045	:C
	:; (10/10) JUMP forward if not zero to SCAN-LINE
	:;

003C:C
003C E1         pop hl	:C
	:; (10) point to start of next row in display 
	:;      file.
	:;

003D:C
003D 05         dec b	:C
	:; (4)  decrement the row counter. (4)

003E:C
003E C8         ret z	:C
	:; (11/5) return when picture complete to L028B
	:;      with interrupts disabled.
	:;

003F:C
003F CBD9       set 3, c	:C
	:; (8)  Load the scan line counter with eight.  
	:;      Note. LD C,$08 is 7 clock cycles which 
	:;      is way too fast.
	:;

0041:C
	:#; ->
	:#
	:#;; WAIT-INT
0041 ED4F       ld r, a	:C WAIT_INT
	:; (9) Load R with initial rising value $DD.
	:;

0043:C
0043 FB         ei	:C
	:; (4) Enable Interrupts.  [ R is now $DE ].
	:;

0044:C
0044 E9         jp (hl)	:C
	:; (4) jump to the echo display file in upper
	:;     memory and execute characters $00 - $3F 
	:;     as NOP instructions.  The video hardware 
	:;     is able to read these characters and, 
	:;     with the I register is able to convert 
	:;     the character bitmaps in this ROM into a 
	:;     line of bytes. Eventually the NEWLINE/HALT
	:;     will be encountered before R reaches $FF. 
	:;     It is however the transition from $FF to 
	:;     $80 that triggers the next interrupt.
	:;     [ The Refresh register is now $DF ]
	:;

0045:C
	:#; ---
	:#
	:#;; SCAN-LINE
0045 D1         pop de	:C SCAN_LINE
	:; (10) discard the address after NEWLINE as the 
	:;      same text line has to be done again
	:;      eight times. 
	:;

0046:C
0046 C8         ret z	:C
	:; (5)  Harmless Nonsensical Timing.
	:;      (condition never met)
	:;

0047:C
0047 18F8       jr $0041	:C
	:; (12) back to WAIT-INT
	:;

0049:C
	:#;   Note. that a computer with less than 4K or RAM will have a collapsed
	:#;   display file and the above mechanism deals with both types of display.
	:#;
	:#;   With a full display, the 32 characters in the line are treated as NOPS
	:#;   and the Refresh register rises from $E0 to $FF and, at the next instruction 
	:#;   - HALT, the interrupt occurs.
	:#;   With a collapsed display and an initial NEWLINE/HALT, it is the NOPs 
	:#;   generated by the HALT that cause the Refresh value to rise from $E0 to $FF,
	:#;   triggering an Interrupt on the next transition.
	:#;   This works happily for all display lines between these extremes and the 
	:#;   generation of the 32 character, 1 pixel high, line will always take 128 
	:#;   clock cycles.
	:#
	:#; ---------------------------------
	:#; THE 'INCREMENT CH-ADD' SUBROUTINE
	:#; ---------------------------------
	:#; This is the subroutine that increments the character address system variable
	:#; and returns if it is not the cursor character. The ZX81 has an actual 
	:#; character at the cursor position rather than a pointer system variable
	:#; as is the case with prior and subsequent ZX computers.
	:#
	:#;; CH-ADD+1
0049 2A1640     ld hl, ($4016)	:C CH_ADD_1
	:; fetch character address to CH_ADD.
	:;

004C:C
	:#;; TEMP-PTR1
004C 23         inc hl	:C TEMP_PTR1
	:; address next immediate location.
	:;

004D:C
	:#;; TEMP-PTR2
004D 221640     ld ($4016), hl	:C TEMP_PTR2
	:; update system variable CH_ADD.
	:;

0050:C
0050 7E         ld a, (hl)	:C
	:; fetch the character.

0051:C
0051 FE7F       cp $7F	:C
	:; compare to cursor character.

0053:C
0053 C0         ret nz	:C
	:; return if not the cursor.
	:;

0054:C
0054 18F6       jr $004C	:C
	:; back for next character to TEMP-PTR1.
	:;

0056:C
	:#; --------------------
	:#; THE 'ERROR-2' BRANCH
	:#; --------------------
	:#; This is a continuation of the error restart.
	:#; If the error occurred in runtime then the error stack pointer will probably
	:#; lead to an error report being printed unless it occurred during input.
	:#; If the error occurred when checking syntax then the error stack pointer
	:#; will be an editing routine and the position of the error will be shown
	:#; when the lower screen is reprinted.
	:#
	:#;; ERROR-2
0056 E1         pop hl	:C ERROR_2
	:; pop the return address which points to the
	:; DEFB, error code, after the RST 08.

0057:C
0057 6E         ld l, (hl)	:C
	:; load L with the error code. HL is not needed
	:; anymore.
	:;

0058:C
	:#;; ERROR-3
0058 FD7500     ld (iy), l	:C ERROR_3
	:; place error code in system variable ERR_NR

005B:C
005B ED7B0240   ld sp, ($4002)	:C
	:; set the stack pointer from ERR_SP

005F:C
005F CD0702     call $0207	:C
	:; routine SLOW/FAST selects slow mode.

0062:C
0062 C3BC14     jp $14BC	:C
	:; exit to address on stack via routine SET-MIN.
	:;

0065:B
	:#; ---
	:#
0065-0065 FF	:B
	:; unused.
	:;

0066:C
	:#; ------------------------------------
	:#; THE 'NON MASKABLE INTERRUPT' ROUTINE
	:#; ------------------------------------
	:#;   Jim Westwood's technical dodge using Non-Maskable Interrupts solved the
	:#;   flicker problem of the ZX80 and gave the ZX81 a multi-tasking SLOW mode 
	:#;   with a steady display.  Note that the AF' register is reserved for this 
	:#;   function and its interaction with the display routines.  When counting 
	:#;   TV lines, the NMI makes no use of the main registers.
	:#;   The circuitry for the NMI generator is contained within the SCL (Sinclair 
	:#;   Computer Logic) chip. 
	:#;   ( It takes 32 clock cycles while incrementing towards zero ). 
	:#
	:#;; NMI
0066 08         ex af, af'	:C NMI
	:; (4) switch in the NMI's copy of the 
	:;     accumulator.

0067:C
0067 3C         inc a	:C
	:; (4) increment.

0068:C
0068 FA6D00     jp m, $006D	:C
	:; (10/10) jump, if minus, to NMI-RET as this is
	:;     part of a test to see if the NMI 
	:;     generation is working or an intermediate 
	:;     value for the ascending negated blank 
	:;     line counter.
	:;

006B:C
006B 2802       jr z, $006F	:C
	:; (12) forward to NMI-CONT
	:;      when line count has incremented to zero.
	:;

006D:C
	:#; Note. the synchronizing NMI when A increments from zero to one takes this
	:#; 7 clock cycle route making 39 clock cycles in all.
	:#
	:#;; NMI-RET
006D 08         ex af, af'	:C NMI_RET
	:; (4)  switch out the incremented line counter
	:;      or test result $80

006E:C
006E C9         ret	:C
	:; (10) return to User application for a while.
	:;

006F:C
	:#; ---
	:#
	:#;   This branch is taken when the 55 (or 31) lines have been drawn.
	:#
	:#;; NMI-CONT
006F 08         ex af, af'	:C NMI_CONT
	:; (4) restore the main accumulator.
	:;

0070:C
0070 F5         push af	:C
	:; (11) *             Save Main Registers

0071:C
0071 C5         push bc	:C
	:; (11) **

0072:C
0072 D5         push de	:C
	:; (11) ***

0073:C
0073 E5         push hl	:C
	:; (11) ****
	:;

0074:C
	:#;   the next set-up procedure is only really applicable when the top set of 
	:#;   blank lines have been generated.
	:#
0074 2A0C40     ld hl, ($400C)	:C
	:; (16) fetch start of Display File from D_FILE
	:;      points to the HALT at beginning.

0077:C
0077 CBFC       set 7, h	:C
	:; (8) point to upper 32K 'echo display file'
	:;

0079:C
0079 76         halt	:C
	:; (1) HALT synchronizes with NMI.  
	:; Used with special hardware connected to the
	:; Z80 HALT and WAIT lines to take 1 clock cycle.
	:;

007A:C
	:#; ----------------------------------------------------------------------------
	:#;   the NMI has been generated - start counting. The cathode ray is at the RH 
	:#;   side of the TV.
	:#;   First the NMI servicing, similar to CALL            =  17 clock cycles.
	:#;   Then the time taken by the NMI for zero-to-one path =  39 cycles
	:#;   The HALT above                                      =  01 cycles.
	:#;   The two instructions below                          =  19 cycles.
	:#;   The code at L0281 up to and including the CALL      =  43 cycles.
	:#;   The Called routine at L02B5                         =  24 cycles.
	:#;   --------------------------------------                ---
	:#;   Total Z80 instructions                              = 143 cycles.
	:#;
	:#;   Meanwhile in TV world,
	:#;   Horizontal retrace                                  =  15 cycles.
	:#;   Left blanking border 8 character positions          =  32 cycles
	:#;   Generation of 75% scanline from the first NEWLINE   =  96 cycles
	:#;   ---------------------------------------               ---
	:#;                                                         143 cycles
	:#;
	:#;   Since at the time the first JP (HL) is encountered to execute the echo
	:#;   display another 8 character positions have to be put out, then the
	:#;   Refresh register need to hold $F8. Working back and counteracting 
	:#;   the fact that every instruction increments the Refresh register then
	:#;   the value that is loaded into R needs to be $F5.      :-)
	:#;
	:#;
007A D3FD       out ($FD), a	:C
	:; (11) Stop the NMI generator.
	:;

007C:C
007C DDE9       jp (ix)	:C
	:; (8) forward to L0281 (after top) or L028F
	:;

007E:B
	:#; ****************
	:#; ** KEY TABLES **
	:#; ****************
	:#
	:#; -------------------------------
	:#; THE 'UNSHIFTED' CHARACTER CODES
	:#; -------------------------------
	:#
	:#;; K-UNSHIFT
007E-007E 3F	:B K_UNSHIFT
	:; Z

007F:B
007F-007F 3D	:B
	:; X

0080:B
0080-0080 28	:B
	:; C

0081:B
0081-0081 3B	:B
	:; V

0082:B
0082-0082 26	:B
	:; A

0083:B
0083-0083 38	:B
	:; S

0084:B
0084-0084 29	:B
	:; D

0085:B
0085-0085 2B	:B
	:; F

0086:B
0086-0086 2C	:B
	:; G

0087:B
0087-0087 36	:B
	:; Q

0088:B
0088-0088 3C	:B
	:; W

0089:B
0089-0089 2A	:B
	:; E

008A:B
008A-008A 37	:B
	:; R

008B:B
008B-008B 39	:B
	:; T

008C:B
008C-008C 1D	:B
	:; 1

008D:B
008D-008D 1E	:B
	:; 2

008E:B
008E-008E 1F	:B
	:; 3

008F:B
008F-008F 20	:B
	:; 4

0090:B
0090-0090 21	:B
	:; 5

0091:B
0091-0091 1C	:B
	:; 0

0092:B
0092-0092 25	:B
	:; 9

0093:B
0093-0093 24	:B
	:; 8

0094:B
0094-0094 23	:B
	:; 7

0095:B
0095-0095 22	:B
	:; 6

0096:B
0096-0096 35	:B
	:; P

0097:B
0097-0097 34	:B
	:; O

0098:B
0098-0098 2E	:B
	:; I

0099:B
0099-0099 3A	:B
	:; U

009A:B
009A-009A 3E	:B
	:; Y

009B:B
009B-009B 76	:B
	:; NEWLINE

009C:B
009C-009C 31	:B
	:; L

009D:B
009D-009D 30	:B
	:; K

009E:B
009E-009E 2F	:B
	:; J

009F:B
009F-009F 2D	:B
	:; H

00A0:B
00A0-00A0 00	:B
	:; SPACE

00A1:B
00A1-00A1 1B	:B
	:; .

00A2:B
00A2-00A2 32	:B
	:; M

00A3:B
00A3-00A3 33	:B
	:; N

00A4:B
00A4-00A4 27	:B
	:; B
	:;

00A5:B
	:#; -----------------------------
	:#; THE 'SHIFTED' CHARACTER CODES
	:#; -----------------------------
	:#
	:#
	:#;; K-SHIFT
00A5-00A5 0E	:B K_SHIFT
	:; :

00A6:B
00A6-00A6 19	:B
	:; ;

00A7:B
00A7-00A7 0F	:B
	:; ?

00A8:B
00A8-00A8 18	:B
	:; /

00A9:B
00A9-00A9 E3	:B
	:; STOP

00AA:B
00AA-00AA E1	:B
	:; LPRINT

00AB:B
00AB-00AB E4	:B
	:; SLOW

00AC:B
00AC-00AC E5	:B
	:; FAST

00AD:B
00AD-00AD E2	:B
	:; LLIST

00AE:B
00AE-00AE C0	:B
	:; ""

00AF:B
00AF-00AF D9	:B
	:; OR

00B0:B
00B0-00B0 E0	:B
	:; STEP

00B1:B
00B1-00B1 DB	:B
	:; <=

00B2:B
00B2-00B2 DD	:B
	:; <>

00B3:B
00B3-00B3 75	:B
	:; EDIT

00B4:B
00B4-00B4 DA	:B
	:; AND

00B5:B
00B5-00B5 DE	:B
	:; THEN

00B6:B
00B6-00B6 DF	:B
	:; TO

00B7:B
00B7-00B7 72	:B
	:; cursor-left

00B8:B
00B8-00B8 77	:B
	:; RUBOUT

00B9:B
00B9-00B9 74	:B
	:; GRAPHICS

00BA:B
00BA-00BA 73	:B
	:; cursor-right

00BB:B
00BB-00BB 70	:B
	:; cursor-up

00BC:B
00BC-00BC 71	:B
	:; cursor-down

00BD:B
00BD-00BD 0B	:B
	:; "

00BE:B
00BE-00BE 11	:B
	:; )

00BF:B
00BF-00BF 10	:B
	:; (

00C0:B
00C0-00C0 0D	:B
	:; $

00C1:B
00C1-00C1 DC	:B
	:; >=

00C2:B
00C2-00C2 79	:B
	:; FUNCTION

00C3:B
00C3-00C3 14	:B
	:; =

00C4:B
00C4-00C4 15	:B
	:; +

00C5:B
00C5-00C5 16	:B
	:; -

00C6:B
00C6-00C6 D8	:B
	:; **

00C7:B
00C7-00C7 0C	:B
	:; ukp

00C8:B
00C8-00C8 1A	:B
	:; ,

00C9:B
00C9-00C9 12	:B
	:; >

00CA:B
00CA-00CA 13	:B
	:; <

00CB:B
00CB-00CB 17	:B
	:; *
	:;

00CC:B
	:#; ------------------------------
	:#; THE 'FUNCTION' CHARACTER CODES
	:#; ------------------------------
	:#
	:#
	:#;; K-FUNCT
00CC-00CC CD	:B K_FUNCT
	:; LN

00CD:B
00CD-00CD CE	:B
	:; EXP

00CE:B
00CE-00CE C1	:B
	:; AT

00CF:B
00CF-00CF 78	:B
	:; KL

00D0:B
00D0-00D0 CA	:B
	:; ASN

00D1:B
00D1-00D1 CB	:B
	:; ACS

00D2:B
00D2-00D2 CC	:B
	:; ATN

00D3:B
00D3-00D3 D1	:B
	:; SGN

00D4:B
00D4-00D4 D2	:B
	:; ABS

00D5:B
00D5-00D5 C7	:B
	:; SIN

00D6:B
00D6-00D6 C8	:B
	:; COS

00D7:B
00D7-00D7 C9	:B
	:; TAN

00D8:B
00D8-00D8 CF	:B
	:; INT

00D9:B
00D9-00D9 40	:B
	:; RND

00DA:B
00DA-00DA 78	:B
	:; KL

00DB:B
00DB-00DB 78	:B
	:; KL

00DC:B
00DC-00DC 78	:B
	:; KL

00DD:B
00DD-00DD 78	:B
	:; KL

00DE:B
00DE-00DE 78	:B
	:; KL

00DF:B
00DF-00DF 78	:B
	:; KL

00E0:B
00E0-00E0 78	:B
	:; KL

00E1:B
00E1-00E1 78	:B
	:; KL

00E2:B
00E2-00E2 78	:B
	:; KL

00E3:B
00E3-00E3 78	:B
	:; KL

00E4:B
00E4-00E4 C2	:B
	:; TAB

00E5:B
00E5-00E5 D3	:B
	:; PEEK

00E6:B
00E6-00E6 C4	:B
	:; CODE

00E7:B
00E7-00E7 D6	:B
	:; CHR$

00E8:B
00E8-00E8 D5	:B
	:; STR$

00E9:B
00E9-00E9 78	:B
	:; KL

00EA:B
00EA-00EA D4	:B
	:; USR

00EB:B
00EB-00EB C6	:B
	:; LEN

00EC:B
00EC-00EC C5	:B
	:; VAL

00ED:B
00ED-00ED D0	:B
	:; SQR

00EE:B
00EE-00EE 78	:B
	:; KL

00EF:B
00EF-00EF 78	:B
	:; KL

00F0:B
00F0-00F0 42	:B
	:; PI

00F1:B
00F1-00F1 D7	:B
	:; NOT

00F2:B
00F2-00F2 41	:B
	:; INKEY$
	:;

00F3:B
	:#; -----------------------------
	:#; THE 'GRAPHIC' CHARACTER CODES
	:#; -----------------------------
	:#
	:#
	:#;; K-GRAPH
00F3-00F3 08	:B K_GRAPH
	:; graphic

00F4:B
00F4-00F4 0A	:B
	:; graphic

00F5:B
00F5-00F5 09	:B
	:; graphic

00F6:B
00F6-00F6 8A	:B
	:; graphic

00F7:B
00F7-00F7 89	:B
	:; graphic

00F8:B
00F8-00F8 81	:B
	:; graphic

00F9:B
00F9-00F9 82	:B
	:; graphic

00FA:B
00FA-00FA 07	:B
	:; graphic

00FB:B
00FB-00FB 84	:B
	:; graphic

00FC:B
00FC-00FC 06	:B
	:; graphic

00FD:B
00FD-00FD 01	:B
	:; graphic

00FE:B
00FE-00FE 02	:B
	:; graphic

00FF:B
00FF-00FF 87	:B
	:; graphic

0100:B
0100-0100 04	:B
	:; graphic

0101:B
0101-0101 05	:B
	:; graphic

0102:B
0102-0102 77	:B
	:; RUBOUT

0103:B
0103-0103 78	:B
	:; KL

0104:B
0104-0104 85	:B
	:; graphic

0105:B
0105-0105 03	:B
	:; graphic

0106:B
0106-0106 83	:B
	:; graphic

0107:B
0107-0107 8B	:B
	:; graphic

0108:B
0108-0108 91	:B
	:; inverse )

0109:B
0109-0109 90	:B
	:; inverse (

010A:B
010A-010A 8D	:B
	:; inverse $

010B:B
010B-010B 86	:B
	:; graphic

010C:B
010C-010C 78	:B
	:; KL

010D:B
010D-010D 92	:B
	:; inverse >

010E:B
010E-010E 95	:B
	:; inverse +

010F:B
010F-010F 96	:B
	:; inverse -

0110:B
0110-0110 88	:B
	:; graphic
	:;

0111:B
	:#; ------------------
	:#; THE 'TOKEN' TABLES
	:#; ------------------
	:#
	:#
	:#;; TOKENS_TAB
0111-0111 8F	:B TOKENS_TAB
	:; '?'+$80

0112:B
0112-0113 0B8B	:B
	:; ""

0114:B
0114-0115 26B9	:B
	:; AT

0116:B
0116-0118 3926A7	:B
	:; TAB

0119:B
0119-0119 8F	:B
	:; '?'+$80

011A:B
011A-011D 283429AA	:B
	:; CODE

011E:B
011E-0120 3B26B1	:B
	:; VAL

0121:B
0121-0123 312AB3	:B
	:; LEN

0124:B
0124-0126 382EB3	:B
	:; SIN

0127:B
0127-0129 2834B8	:B
	:; COS

012A:B
012A-012C 3926B3	:B
	:; TAN

012D:B
012D-012F 2638B3	:B
	:; ASN

0130:B
0130-0132 2628B8	:B
	:; ACS

0133:B
0133-0135 2639B3	:B
	:; ATN

0136:B
0136-0137 31B3	:B
	:; LN

0138:B
0138-013A 2A3DB5	:B
	:; EXP

013B:B
013B-013D 2E33B9	:B
	:; INT

013E:B
013E-0140 3836B7	:B
	:; SQR

0141:B
0141-0143 382CB3	:B
	:; SGN

0144:B
0144-0146 2627B8	:B
	:; ABS

0147:B
0147-014A 352A2AB0	:B
	:; PEEK

014B:B
014B-014D 3A38B7	:B
	:; USR

014E:B
014E-0151 3839378D	:B
	:; STR$

0152:B
0152-0155 282D378D	:B
	:; CHR$

0156:B
0156-0158 3334B9	:B
	:; NOT

0159:B
0159-015A 1797	:B
	:; **

015B:B
015B-015C 34B7	:B
	:; OR

015D:B
015D-015F 2633A9	:B
	:; AND

0160:B
0160-0161 1394	:B
	:; <=

0162:B
0162-0163 1294	:B
	:; >=

0164:B
0164-0165 1392	:B
	:; <>

0166:B
0166-0169 392D2AB3	:B
	:; THEN

016A:B
016A-016B 39B4	:B
	:; TO

016C:B
016C-016F 38392AB5	:B
	:; STEP

0170:B
0170-0175 3135372E33B9	:B
	:; LPRINT

0176:B
0176-017A 31312E38B9	:B
	:; LLIST

017B:B
017B-017E 383934B5	:B
	:; STOP

017F:B
017F-0182 383134BC	:B
	:; SLOW

0183:B
0183-0186 2B2638B9	:B
	:; FAST

0187:B
0187-0189 332ABC	:B
	:; NEW

018A:B
018A-018F 3828373431B1	:B
	:; SCROLL

0190:B
0190-0193 283433B9	:B
	:; CONT

0194:B
0194-0196 292EB2	:B
	:; DIM

0197:B
0197-0199 372AB2	:B
	:; REM

019A:B
019A-019C 2B34B7	:B
	:; FOR

019D:B
019D-01A0 2C3439B4	:B
	:; GOTO

01A1:B
01A1-01A5 2C34383AA7	:B
	:; GOSUB

01A6:B
01A6-01AA 2E33353AB9	:B
	:; INPUT

01AB:B
01AB-01AE 313426A9	:B
	:; LOAD

01AF:B
01AF-01B2 312E38B9	:B
	:; LIST

01B3:B
01B3-01B5 312AB9	:B
	:; LET

01B6:B
01B6-01BA 35263A38AA	:B
	:; PAUSE

01BB:B
01BB-01BE 332A3DB9	:B
	:; NEXT

01BF:B
01BF-01C2 353430AA	:B
	:; POKE

01C3:B
01C3-01C7 35372E33B9	:B
	:; PRINT

01C8:B
01C8-01CB 353134B9	:B
	:; PLOT

01CC:B
01CC-01CE 373AB3	:B
	:; RUN

01CF:B
01CF-01D2 38263BAA	:B
	:; SAVE

01D3:B
01D3-01D6 372633A9	:B
	:; RAND

01D7:B
01D7-01D8 2EAB	:B
	:; IF

01D9:B
01D9-01DB 2831B8	:B
	:; CLS

01DC:B
01DC-01E1 3A33353134B9	:B
	:; UNPLOT

01E2:B
01E2-01E6 28312A26B7	:B
	:; CLEAR

01E7:B
01E7-01EC 372A393A37B3	:B
	:; RETURN

01ED:B
01ED-01F0 283435BE	:B
	:; COPY

01F1:B
01F1-01F3 3733A9	:B
	:; RND

01F4:B
01F4-01F9 2E33302A3E8D	:B
	:; INKEY$

01FA:B
01FA-01FB 35AE	:B
	:; PI
	:;
	:;

01FC:C
	:#; ------------------------------
	:#; THE 'LOAD-SAVE UPDATE' ROUTINE
	:#; ------------------------------
	:#;
	:#;
	:#
	:#;; LOAD/SAVE
01FC 23         inc hl	:C LOAD_SAVE
	:;

01FD:C
01FD EB         ex de, hl	:C
	:;

01FE:C
01FE 2A1440     ld hl, ($4014)	:C
	:; system variable edit line E_LINE.

0201:C
0201 37         scf	:C
	:; set carry flag

0202:C
0202 ED52       sbc hl, de	:C
	:;

0204:C
0204 EB         ex de, hl	:C
	:;

0205:C
0205 D0         ret nc	:C
	:; return if more bytes to load/save.
	:;

0206:C
0206 E1         pop hl	:C
	:; else drop return address
	:;

0207:C
	:#; ----------------------
	:#; THE 'DISPLAY' ROUTINES
	:#; ----------------------
	:#;
	:#;
	:#
	:#;; SLOW/FAST
0207 213B40     ld hl, $403B	:C SLOW_FAST
	:; Address the system variable CDFLAG.

020A:C
020A 7E         ld a, (hl)	:C
	:; Load value to the accumulator.

020B:C
020B 17         rla	:C
	:; rotate bit 6 to position 7.

020C:C
020C AE         xor (hl)	:C
	:; exclusive or with original bit 7.

020D:C
020D 17         rla	:C
	:; rotate result out to carry.

020E:C
020E D0         ret nc	:C
	:; return if both bits were the same.
	:;

020F:C
	:#;   Now test if this really is a ZX81 or a ZX80 running the upgraded ROM.
	:#;   The standard ZX80 did not have an NMI generator.
	:#
020F 3E7F       ld a, $7F	:C
	:; Load accumulator with %011111111

0211:C
0211 08         ex af, af'	:C
	:; save in AF'
	:;

0212:C
0212 0611       ld b, $11	:C
	:; A counter within which an NMI should occur
	:; if this is a ZX81.

0214:C
0214 D3FE       out ($FE), a	:C
	:; start the NMI generator.
	:;

0216:C
	:#;  Note that if this is a ZX81 then the NMI will increment AF'.
	:#
	:#;; LOOP-11
0216 10FE       djnz $0216	:C LOOP_11
	:; self loop to give the NMI a chance to kick in.
	:; = 16*13 clock cycles + 8 = 216 clock cycles.
	:;

0218:C
0218 D3FD       out ($FD), a	:C
	:; Turn off the NMI generator.

021A:C
021A 08         ex af, af'	:C
	:; bring back the AF' value.

021B:C
021B 17         rla	:C
	:; test bit 7.

021C:C
021C 3008       jr nc, $0226	:C
	:; forward, if bit 7 is still reset, to NO-SLOW.
	:;

021E:C
	:#;   If the AF' was incremented then the NMI generator works and SLOW mode can
	:#;   be set.
	:#
021E CBFE       set 7, (hl)	:C
	:; Indicate SLOW mode - Compute and Display.
	:;

0220:C
0220 F5         push af	:C
	:; *             Save Main Registers

0221:C
0221 C5         push bc	:C
	:; **

0222:C
0222 D5         push de	:C
	:; ***

0223:C
0223 E5         push hl	:C
	:; ****
	:;

0224:C
0224 1803       jr $0229	:C
	:; skip forward - to DISPLAY-1.
	:;

0226:C
	:#; ---
	:#
	:#;; NO-SLOW
0226 CBB6       res 6, (hl)	:C NO_SLOW
	:; reset bit 6 of CDFLAG.

0228:C
0228 C9         ret	:C
	:; return.
	:;

0229:C
	:#; -----------------------
	:#; THE 'MAIN DISPLAY' LOOP
	:#; -----------------------
	:#; This routine is executed once for every frame displayed.
	:#
	:#;; DISPLAY-1
0229 2A3440     ld hl, ($4034)	:C DISPLAY_1
	:; fetch two-byte system variable FRAMES.

022C:C
022C 2B         dec hl	:C
	:; decrement frames counter.
	:;

022D:C
	:#;; DISPLAY-P
022D 3E7F       ld a, $7F	:C DISPLAY_P
	:; prepare a mask

022F:C
022F A4         and h	:C
	:; pick up bits 6-0 of H.

0230:C
0230 B5         or l	:C
	:; and any bits of L.

0231:C
0231 7C         ld a, h	:C
	:; reload A with all bits of H for PAUSE test.
	:;

0232:C
	:#;   Note both branches must take the same time.
	:#
0232 2003       jr nz, $0237	:C
	:; (12/7) forward if bits 14-0 are not zero 
	:; to ANOTHER
	:;

0234:C
0234 17         rla	:C
	:; (4) test bit 15 of FRAMES.

0235:C
0235 1802       jr $0239	:C
	:; (12) forward with result to OVER-NC
	:;

0237:C
	:#; ---
	:#
	:#;; ANOTHER
0237 46         ld b, (hl)	:C ANOTHER
	:; (7) Note. Harmless Nonsensical Timing weight.

0238:C
0238 37         scf	:C
	:; (4) Set Carry Flag.
	:;

0239:C
	:#; Note. the branch to here takes either (12)(7)(4) cyles or (7)(4)(12) cycles.
	:#
	:#;; OVER-NC
0239 67         ld h, a	:C OVER_NC
	:; (4)  set H to zero

023A:C
023A 223440     ld ($4034), hl	:C
	:; (16) update system variable FRAMES 

023D:C
023D D0         ret nc	:C
	:; (11/5) return if FRAMES is in use by PAUSE 
	:; command.
	:;

023E:C
	:#;; DISPLAY-2
023E CDBB02     call $02BB	:C DISPLAY_2
	:; routine KEYBOARD gets the key row in H and 
	:; the column in L. Reading the ports also starts
	:; the TV frame synchronization pulse. (VSYNC)
	:;

0241:C
0241 ED4B2540   ld bc, ($4025)	:C
	:; fetch the last key values read from LAST_K

0245:C
0245 222540     ld ($4025), hl	:C
	:; update LAST_K with new values.
	:;

0248:C
0248 78         ld a, b	:C
	:; load A with previous column - will be $FF if
	:; there was no key.

0249:C
0249 C602       add a, $02	:C
	:; adding two will set carry if no previous key.
	:;

024B:C
024B ED42       sbc hl, bc	:C
	:; subtract with the carry the two key values.
	:;

024D:C
	:#; If the same key value has been returned twice then HL will be zero.
	:#
024D 3A2740     ld a, ($4027)	:C
	:; fetch system variable DEBOUNCE

0250:C
0250 B4         or h	:C
	:; and OR with both bytes of the difference

0251:C
0251 B5         or l	:C
	:; setting the zero flag for the upcoming branch.
	:;

0252:C
0252 58         ld e, b	:C
	:; transfer the column value to E

0253:C
0253 060B       ld b, $0B	:C
	:; and load B with eleven 
	:;

0255:C
0255 213B40     ld hl, $403B	:C
	:; address system variable CDFLAG

0258:C
0258 CB86       res 0, (hl)	:C
	:; reset the rightmost bit of CDFLAG

025A:C
025A 2008       jr nz, $0264	:C
	:; skip forward if debounce/diff >0 to NO-KEY
	:;

025C:C
025C CB7E       bit 7, (hl)	:C
	:; test compute and display bit of CDFLAG

025E:C
025E CBC6       set 0, (hl)	:C
	:; set the rightmost bit of CDFLAG.

0260:C
0260 C8         ret z	:C
	:; return if bit 7 indicated fast mode.
	:;

0261:C
0261 05         dec b	:C
	:; (4) decrement the counter.

0262:C
0262 00         nop	:C
	:; (4) Timing - 4 clock cycles. ??

0263:C
0263 37         scf	:C
	:; (4) Set Carry Flag
	:;

0264:C
	:#;; NO-KEY
0264 212740     ld hl, $4027	:C NO_KEY
	:; sv DEBOUNCE

0267:C
0267 3F         ccf	:C
	:; Complement Carry Flag

0268:C
0268 CB10       rl b	:C
	:; rotate left B picking up carry
	:;  C<-76543210<-C
	:;

026A:C
	:#;; LOOP-B
026A 10FE       djnz $026A	:C LOOP_B
	:; self-loop while B>0 to LOOP-B
	:;

026C:C
026C 46         ld b, (hl)	:C
	:; fetch value of DEBOUNCE to B

026D:C
026D 7B         ld a, e	:C
	:; transfer column value

026E:C
026E FEFE       cp $FE	:C
	:;

0270:C
0270 9F         sbc a, a	:C
	:;

0271:C
0271 061F       ld b, $1F	:C
	:;

0273:C
0273 B6         or (hl)	:C
	:;

0274:C
0274 A0         and b	:C
	:;

0275:C
0275 1F         rra	:C
	:;

0276:C
0276 77         ld (hl), a	:C
	:;
	:;

0277:C
0277 D3FF       out ($FF), a	:C
	:; end the TV frame synchronization pulse.
	:;

0279:C
0279 2A0C40     ld hl, ($400C)	:C
	:; (12) set HL to the Display File from D_FILE

027C:C
027C CBFC       set 7, h	:C
	:; (8) set bit 15 to address the echo display.
	:;

027E:C
027E CD9202     call $0292	:C
	:; (17) routine DISPLAY-3 displays the top set 
	:; of blank lines.
	:;

0281:C
	:#; ---------------------
	:#; THE 'VIDEO-1' ROUTINE
	:#; ---------------------
	:#
	:#;; R-IX-1
0281 ED5F       ld a, r	:C R_IX_1
	:; (9)  Harmless Nonsensical Timing or something
	:;      very clever?

0283:C
0283 010119     ld bc, $1901	:C
	:; (10) 25 lines, 1 scanline in first.

0286:C
0286 3EF5       ld a, $F5	:C
	:; (7)  This value will be loaded into R and 
	:; ensures that the cycle starts at the right 
	:; part of the display  - after 32nd character 
	:; position.
	:;

0288:C
0288 CDB502     call $02B5	:C
	:; (17) routine DISPLAY-5 completes the current 
	:; blank line and then generates the display of 
	:; the live picture using INT interrupts
	:; The final interrupt returns to the next 
	:; address.
	:;

028B:C
028B 2B         dec hl	:C
	:; point HL to the last NEWLINE/HALT.
	:;

028C:C
028C CD9202     call $0292	:C
	:; routine DISPLAY-3 displays the bottom set of
	:; blank lines.
	:;

028F:C
	:#; ---
	:#
	:#;; R-IX-2
028F C32902     jp $0229	:C R_IX_2
	:; JUMP back to DISPLAY-1
	:;

0292:C
	:#; ---------------------------------
	:#; THE 'DISPLAY BLANK LINES' ROUTINE 
	:#; ---------------------------------
	:#;   This subroutine is called twice (see above) to generate first the blank 
	:#;   lines at the top of the television display and then the blank lines at the
	:#;   bottom of the display. 
	:#
	:#;; DISPLAY-3
0292 DDE1       pop ix	:C DISPLAY_3
	:; pop the return address to IX register.
	:; will be either L0281 or L028F - see above.
	:;

0294:C
0294 FD4E28     ld c, (iy+$28)	:C
	:; load C with value of system constant MARGIN.

0297:C
0297 FDCB3B7E   bit 7, (iy+$3B)	:C
	:; test CDFLAG for compute and display.

029B:C
029B 280C       jr z, $02A9	:C
	:; forward, with FAST mode, to DISPLAY-4
	:;

029D:C
029D 79         ld a, c	:C
	:; move MARGIN to A  - 31d or 55d.

029E:C
029E ED44       neg	:C
	:; Negate

02A0:C
02A0 3C         inc a	:C
	:;

02A1:C
02A1 08         ex af, af'	:C
	:; place negative count of blank lines in A'
	:;

02A2:C
02A2 D3FE       out ($FE), a	:C
	:; enable the NMI generator.
	:;

02A4:C
02A4 E1         pop hl	:C
	:; ****

02A5:C
02A5 D1         pop de	:C
	:; ***

02A6:C
02A6 C1         pop bc	:C
	:; **

02A7:C
02A7 F1         pop af	:C
	:; *             Restore Main Registers
	:;

02A8:C
02A8 C9         ret	:C
	:; return - end of interrupt.  Return is to 
	:; user's program - BASIC or machine code.
	:; which will be interrupted by every NMI.
	:;

02A9:C
	:#; ------------------------
	:#; THE 'FAST MODE' ROUTINES
	:#; ------------------------
	:#
	:#;; DISPLAY-4
02A9 3EFC       ld a, $FC	:C DISPLAY_4
	:; (7)  load A with first R delay value

02AB:C
02AB 0601       ld b, $01	:C
	:; (7)  one row only.
	:;

02AD:C
02AD CDB502     call $02B5	:C
	:; (17) routine DISPLAY-5
	:;

02B0:C
02B0 2B         dec hl	:C
	:; (6)  point back to the HALT.

02B1:C
02B1 E3         ex (sp), hl	:C
	:; (19) Harmless Nonsensical Timing if paired.

02B2:C
02B2 E3         ex (sp), hl	:C
	:; (19) Harmless Nonsensical Timing.

02B3:C
02B3 DDE9       jp (ix)	:C
	:; (8)  to L0281 or L028F
	:;

02B5:C
	:#; --------------------------
	:#; THE 'DISPLAY-5' SUBROUTINE
	:#; --------------------------
	:#;   This subroutine is called from SLOW mode and FAST mode to generate the 
	:#;   central TV picture. With SLOW mode the R register is incremented, with
	:#;   each instruction, to $F7 by the time it completes.  With fast mode, the 
	:#;   final R value will be $FF and an interrupt will occur as soon as the 
	:#;   Program Counter reaches the HALT.  (24 clock cycles)
	:#
	:#;; DISPLAY-5
02B5 ED4F       ld r, a	:C DISPLAY_5
	:; (9) Load R from A.    R = slow: $F5 fast: $FC

02B7:C
02B7 3EDD       ld a, $DD	:C
	:; (7) load future R value.        $F6       $FD
	:;

02B9:C
02B9 FB         ei	:C
	:; (4) Enable Interrupts           $F7       $FE
	:;

02BA:C
02BA E9         jp (hl)	:C
	:; (4) jump to the echo display.   $F8       $FF
	:;

02BB:C
	:#; ----------------------------------
	:#; THE 'KEYBOARD SCANNING' SUBROUTINE
	:#; ----------------------------------
	:#; The keyboard is read during the vertical sync interval while no video is 
	:#; being displayed.  Reading a port with address bit 0 low i.e. $FE starts the 
	:#; vertical sync pulse.
	:#
	:#;; KEYBOARD
02BB 21FFFF     ld hl, $FFFF	:C KEYBOARD
	:; (16) prepare a buffer to take key.

02BE:C
02BE 01FEFE     ld bc, $FEFE	:C
	:; (20) set BC to port $FEFE. The B register, 
	:;      with its single reset bit also acts as 
	:;      an 8-counter.

02C1:C
02C1 ED78       in a, (c)	:C
	:; (11) read the port - all 16 bits are put on 
	:;      the address bus.  Start VSYNC pulse.

02C3:C
02C3 F601       or $01	:C
	:; (7)  set the rightmost bit so as to ignore 
	:;      the SHIFT key.
	:;

02C5:C
	:#;; EACH-LINE
02C5 F6E0       or $E0	:C EACH_LINE
	:; [7] OR %11100000

02C7:C
02C7 57         ld d, a	:C
	:; [4] transfer to D.

02C8:C
02C8 2F         cpl	:C
	:; [4] complement - only bits 4-0 meaningful now.

02C9:C
02C9 FE01       cp $01	:C
	:; [7] sets carry if A is zero.

02CB:C
02CB 9F         sbc a, a	:C
	:; [4] $FF if $00 else zero.

02CC:C
02CC B0         or b	:C
	:; [7] $FF or port FE,FD,FB....

02CD:C
02CD A5         and l	:C
	:; [4] unless more than one key, L will still be 
	:;     $FF. if more than one key is pressed then A is 
	:;     now invalid.

02CE:C
02CE 6F         ld l, a	:C
	:; [4] transfer to L.
	:;

02CF:C
	:#; now consider the column identifier.
	:#
02CF 7C         ld a, h	:C
	:; [4] will be $FF if no previous keys.

02D0:C
02D0 A2         and d	:C
	:; [4] 111xxxxx

02D1:C
02D1 67         ld h, a	:C
	:; [4] transfer A to H
	:;

02D2:C
	:#; since only one key may be pressed, H will, if valid, be one of
	:#; 11111110, 11111101, 11111011, 11110111, 11101111
	:#; reading from the outer column, say Q, to the inner column, say T.
	:#
02D2 CB00       rlc b	:C
	:; [8]  rotate the 8-counter/port address.
	:;      sets carry if more to do.

02D4:C
02D4 ED78       in a, (c)	:C
	:; [10] read another half-row.
	:;      all five bits this time.
	:;

02D6:C
02D6 38ED       jr c, $02C5	:C
	:; [12](7) loop back, until done, to EACH-LINE
	:;

02D8:C
	:#;   The last row read is SHIFT,Z,X,C,V  for the second time.
	:#
02D8 1F         rra	:C
	:; (4) test the shift key - carry will be reset
	:;     if the key is pressed.

02D9:C
02D9 CB14       rl h	:C
	:; (8) rotate left H picking up the carry giving
	:;     column values -
	:;        $FD, $FB, $F7, $EF, $DF.
	:;     or $FC, $FA, $F6, $EE, $DE if shifted.
	:;

02DB:C
	:#;   We now have H identifying the column and L identifying the row in the
	:#;   keyboard matrix.
	:#
	:#;   This is a good time to test if this is an American or British machine.
	:#;   The US machine has an extra diode that causes bit 6 of a byte read from
	:#;   a port to be reset.
	:#
02DB 17         rla	:C
	:; (4) compensate for the shift test.

02DC:C
02DC 17         rla	:C
	:; (4) rotate bit 7 out.

02DD:C
02DD 17         rla	:C
	:; (4) test bit 6.
	:;

02DE:C
02DE 9F         sbc a, a	:C
	:; (4)           $FF or $00 {USA}

02DF:C
02DF E618       and $18	:C
	:; (7)           $18 or $00

02E1:C
02E1 C61F       add a, $1F	:C
	:; (7)           $37 or $1F
	:;

02E3:C
	:#;   result is either 31 (USA) or 55 (UK) blank lines above and below the TV 
	:#;   picture.
	:#
02E3 322840     ld ($4028), a	:C
	:; (13) update system variable MARGIN
	:;

02E6:C
02E6 C9         ret	:C
	:; (10) return
	:;

02E7:C
	:#; ------------------------------
	:#; THE 'SET FAST MODE' SUBROUTINE
	:#; ------------------------------
	:#;
	:#;
	:#
	:#;; SET-FAST
02E7 FDCB3B7E   bit 7, (iy+$3B)	:C SET_FAST
	:; sv CDFLAG

02EB:C
02EB C8         ret z	:C
	:;
	:;

02EC:C
02EC 76         halt	:C
	:; Wait for Interrupt

02ED:C
02ED D3FD       out ($FD), a	:C
	:;

02EF:C
02EF FDCB3BBE   res 7, (iy+$3B)	:C
	:; sv CDFLAG

02F3:C
02F3 C9         ret	:C
	:; return.
	:;
	:;

02F4:C
	:#; --------------
	:#; THE 'REPORT-F'
	:#; --------------
	:#
	:#;; REPORT-F
02F4 CF         rst $08	:C REPORT_F
	:; ERROR-1

02F5:B
02F5-02F5 0E	:B
	:; Error Report: No Program Name supplied.
	:;

02F6:C
	:#; --------------------------
	:#; THE 'SAVE COMMAND' ROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; SAVE
02F6 CDA803     call $03A8	:C SAVE
	:; routine NAME

02F9:C
02F9 38F9       jr c, $02F4	:C
	:; back with null name to REPORT-F above.
	:;

02FB:C
02FB EB         ex de, hl	:C
	:;

02FC:C
02FC 11CB12     ld de, $12CB	:C
	:; five seconds timing value
	:;

02FF:C
	:#;; HEADER
02FF CD460F     call $0F46	:C HEADER
	:; routine BREAK-1

0302:C
0302 302E       jr nc, $0332	:C
	:; to BREAK-2
	:;

0304:C
	:#;; DELAY-1
0304 10FE       djnz $0304	:C DELAY_1
	:; to DELAY-1
	:;

0306:C
0306 1B         dec de	:C
	:;

0307:C
0307 7A         ld a, d	:C
	:;

0308:C
0308 B3         or e	:C
	:;

0309:C
0309 20F4       jr nz, $02FF	:C
	:; back for delay to HEADER
	:;

030B:C
	:#;; OUT-NAME
030B CD1E03     call $031E	:C OUT_NAME
	:; routine OUT-BYTE

030E:C
030E CB7E       bit 7, (hl)	:C
	:; test for inverted bit.

0310:C
0310 23         inc hl	:C
	:; address next character of name.

0311:C
0311 28F8       jr z, $030B	:C
	:; back if not inverted to OUT-NAME
	:;

0313:C
	:#; now start saving the system variables onwards.
	:#
0313 210940     ld hl, $4009	:C
	:; set start of area to VERSN thereby
	:; preserving RAMTOP etc.
	:;

0316:C
	:#;; OUT-PROG
0316 CD1E03     call $031E	:C OUT_PROG
	:; routine OUT-BYTE
	:;

0319:C
0319 CDFC01     call $01FC	:C
	:; routine LOAD/SAVE                     >>

031C:C
031C 18F8       jr $0316	:C
	:; loop back to OUT-PROG
	:;

031E:C
	:#; -------------------------
	:#; THE 'OUT-BYTE' SUBROUTINE
	:#; -------------------------
	:#; This subroutine outputs a byte a bit at a time to a domestic tape recorder.
	:#
	:#;; OUT-BYTE
031E 5E         ld e, (hl)	:C OUT_BYTE
	:; fetch byte to be saved.

031F:C
031F 37         scf	:C
	:; set carry flag - as a marker.
	:;

0320:C
	:#;; EACH-BIT
0320 CB13       rl e	:C EACH_BIT
	:;  C < 76543210 < C

0322:C
0322 C8         ret z	:C
	:; return when the marker bit has passed 
	:; right through.                        >>
	:;

0323:C
0323 9F         sbc a, a	:C
	:; $FF if set bit or $00 with no carry.

0324:C
0324 E605       and $05	:C
	:; $05               $00

0326:C
0326 C604       add a, $04	:C
	:; $09               $04

0328:C
0328 4F         ld c, a	:C
	:; transfer timer to C. a set bit has a longer
	:; pulse than a reset bit.
	:;

0329:C
	:#;; PULSES
0329 D3FF       out ($FF), a	:C PULSES
	:; pulse to cassette.

032B:C
032B 0623       ld b, $23	:C
	:; set timing constant
	:;

032D:C
	:#;; DELAY-2
032D 10FE       djnz $032D	:C DELAY_2
	:; self-loop to DELAY-2
	:;

032F:C
032F CD460F     call $0F46	:C
	:; routine BREAK-1 test for BREAK key.
	:;

0332:C
	:#;; BREAK-2
0332 3072       jr nc, $03A6	:C BREAK_2
	:; forward with break to REPORT-D
	:;

0334:C
0334 061E       ld b, $1E	:C
	:; set timing value.
	:;

0336:C
	:#;; DELAY-3
0336 10FE       djnz $0336	:C DELAY_3
	:; self-loop to DELAY-3
	:;

0338:C
0338 0D         dec c	:C
	:; decrement counter

0339:C
0339 20EE       jr nz, $0329	:C
	:; loop back to PULSES
	:;

033B:C
	:#;; DELAY-4
033B A7         and a	:C DELAY_4
	:; clear carry for next bit test.

033C:C
033C 10FD       djnz $033B	:C
	:; self loop to DELAY-4 (B is zero - 256)
	:;

033E:C
033E 18E0       jr $0320	:C
	:; loop back to EACH-BIT
	:;

0340:C
	:#; --------------------------
	:#; THE 'LOAD COMMAND' ROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; LOAD
0340 CDA803     call $03A8	:C LOAD
	:; routine NAME
	:;

0343:C
	:#; DE points to start of name in RAM.
	:#
0343 CB12       rl d	:C
	:; pick up carry 

0345:C
0345 CB0A       rrc d	:C
	:; carry now in bit 7.
	:;

0347:C
	:#;; NEXT-PROG
0347 CD4C03     call $034C	:C NEXT_PROG
	:; routine IN-BYTE

034A:C
034A 18FB       jr $0347	:C
	:; loop to NEXT-PROG
	:;

034C:C
	:#; ------------------------
	:#; THE 'IN-BYTE' SUBROUTINE
	:#; ------------------------
	:#
	:#;; IN-BYTE
034C 0E01       ld c, $01	:C IN_BYTE
	:; prepare an eight counter 00000001.
	:;

034E:C
	:#;; NEXT-BIT
034E 0600       ld b, $00	:C NEXT_BIT
	:; set counter to 256
	:;

0350:C
	:#;; BREAK-3
0350 3E7F       ld a, $7F	:C BREAK_3
	:; read the keyboard row 

0352:C
0352 DBFE       in a, ($FE)	:C
	:; with the SPACE key.
	:;

0354:C
0354 D3FF       out ($FF), a	:C
	:; output signal to screen.
	:;

0356:C
0356 1F         rra	:C
	:; test for SPACE pressed.

0357:C
0357 3049       jr nc, $03A2	:C
	:; forward if so to BREAK-4
	:;

0359:C
0359 17         rla	:C
	:; reverse above rotation

035A:C
035A 17         rla	:C
	:; test tape bit.

035B:C
035B 3828       jr c, $0385	:C
	:; forward if set to GET-BIT
	:;

035D:C
035D 10F1       djnz $0350	:C
	:; loop back to BREAK-3
	:;

035F:C
035F F1         pop af	:C
	:; drop the return address.

0360:C
0360 BA         cp d	:C
	:; ugh.
	:;

0361:C
	:#;; RESTART
0361 D2E503     jp nc, $03E5	:C RESTART
	:; jump forward to INITIAL if D is zero 
	:; to reset the system
	:; if the tape signal has timed out for example
	:; if the tape is stopped. Not just a simple 
	:; report as some system variables will have
	:; been overwritten.
	:;

0364:C
0364 62         ld h, d	:C
	:; else transfer the start of name

0365:C
0365 6B         ld l, e	:C
	:; to the HL register
	:;

0366:C
	:#;; IN-NAME
0366 CD4C03     call $034C	:C IN_NAME
	:; routine IN-BYTE is sort of recursion for name
	:; part. received byte in C.

0369:C
0369 CB7A       bit 7, d	:C
	:; is name the null string ?

036B:C
036B 79         ld a, c	:C
	:; transfer byte to A.

036C:C
036C 2003       jr nz, $0371	:C
	:; forward with null string to MATCHING
	:;

036E:C
036E BE         cp (hl)	:C
	:; else compare with string in memory.

036F:C
036F 20D6       jr nz, $0347	:C
	:; back with mis-match to NEXT-PROG
	:; (seemingly out of subroutine but return 
	:; address has been dropped).
	:;
	:;

0371:C
	:#;; MATCHING
0371 23         inc hl	:C MATCHING
	:; address next character of name

0372:C
0372 17         rla	:C
	:; test for inverted bit.

0373:C
0373 30F1       jr nc, $0366	:C
	:; back if not to IN-NAME
	:;

0375:C
	:#; the name has been matched in full. 
	:#; proceed to load the data but first increment the high byte of E_LINE, which
	:#; is one of the system variables to be loaded in. Since the low byte is loaded
	:#; before the high byte, it is possible that, at the in-between stage, a false
	:#; value could cause the load to end prematurely - see  LOAD/SAVE check.
	:#
0375 FD3415     inc (iy+$15)	:C
	:; increment system variable E_LINE_hi.

0378:C
0378 210940     ld hl, $4009	:C
	:; start loading at system variable VERSN.
	:;

037B:C
	:#;; IN-PROG
037B 50         ld d, b	:C IN_PROG
	:; set D to zero as indicator.

037C:C
037C CD4C03     call $034C	:C
	:; routine IN-BYTE loads a byte

037F:C
037F 71         ld (hl), c	:C
	:; insert assembled byte in memory.

0380:C
0380 CDFC01     call $01FC	:C
	:; routine LOAD/SAVE                     >>

0383:C
0383 18F6       jr $037B	:C
	:; loop back to IN-PROG
	:;

0385:C
	:#; ---
	:#
	:#; this branch assembles a full byte before exiting normally
	:#; from the IN-BYTE subroutine.
	:#
	:#;; GET-BIT
0385 D5         push de	:C GET_BIT
	:; save the 

0386:C
0386 1E94       ld e, $94	:C
	:; timing value.
	:;

0388:C
	:#;; TRAILER
0388 061A       ld b, $1A	:C TRAILER
	:; counter to twenty six.
	:;

038A:C
	:#;; COUNTER
038A 1D         dec e	:C COUNTER
	:; decrement the measuring timer.

038B:C
038B DBFE       in a, ($FE)	:C
	:; read the

038D:C
038D 17         rla	:C
	:;

038E:C
038E CB7B       bit 7, e	:C
	:;

0390:C
0390 7B         ld a, e	:C
	:;

0391:C
0391 38F5       jr c, $0388	:C
	:; loop back with carry to TRAILER
	:;

0393:C
0393 10F5       djnz $038A	:C
	:; to COUNTER
	:;

0395:C
0395 D1         pop de	:C
	:;

0396:C
0396 2004       jr nz, $039C	:C
	:; to BIT-DONE
	:;

0398:C
0398 FE56       cp $56	:C
	:;

039A:C
039A 30B2       jr nc, $034E	:C
	:; to NEXT-BIT
	:;

039C:C
	:#;; BIT-DONE
039C 3F         ccf	:C BIT_DONE
	:; complement carry flag

039D:C
039D CB11       rl c	:C
	:;

039F:C
039F 30AD       jr nc, $034E	:C
	:; to NEXT-BIT
	:;

03A1:C
03A1 C9         ret	:C
	:; return with full byte.
	:;

03A2:C
	:#; ---
	:#
	:#; if break is pressed while loading data then perform a reset.
	:#; if break pressed while waiting for program on tape then OK to break.
	:#
	:#;; BREAK-4
03A2 7A         ld a, d	:C BREAK_4
	:; transfer indicator to A.

03A3:C
03A3 A7         and a	:C
	:; test for zero.

03A4:C
03A4 28BB       jr z, $0361	:C
	:; back if so to RESTART
	:;
	:;

03A6:C
	:#;; REPORT-D
03A6 CF         rst $08	:C REPORT_D
	:; ERROR-1

03A7:B
03A7-03A7 0C	:B
	:; Error Report: BREAK - CONT repeats
	:;

03A8:C
	:#; -----------------------------
	:#; THE 'PROGRAM NAME' SUBROUTINE
	:#; -----------------------------
	:#;
	:#;
	:#
	:#;; NAME
03A8 CD550F     call $0F55	:C NAME
	:; routine SCANNING

03AB:C
03AB 3A0140     ld a, ($4001)	:C
	:; sv FLAGS

03AE:C
03AE 87         add a, a	:C
	:;

03AF:C
03AF FA9A0D     jp m, $0D9A	:C
	:; to REPORT-C
	:;

03B2:C
03B2 E1         pop hl	:C
	:;

03B3:C
03B3 D0         ret nc	:C
	:;
	:;

03B4:C
03B4 E5         push hl	:C
	:;

03B5:C
03B5 CDE702     call $02E7	:C
	:; routine SET-FAST

03B8:C
03B8 CDF813     call $13F8	:C
	:; routine STK-FETCH

03BB:C
03BB 62         ld h, d	:C
	:;

03BC:C
03BC 6B         ld l, e	:C
	:;

03BD:C
03BD 0D         dec c	:C
	:;

03BE:C
03BE F8         ret m	:C
	:;
	:;

03BF:C
03BF 09         add hl, bc	:C
	:;

03C0:C
03C0 CBFE       set 7, (hl)	:C
	:;

03C2:C
03C2 C9         ret	:C
	:;
	:;

03C3:C
	:#; -------------------------
	:#; THE 'NEW' COMMAND ROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; NEW
03C3 CDE702     call $02E7	:C NEW
	:; routine SET-FAST

03C6:C
03C6 ED4B0440   ld bc, ($4004)	:C
	:; fetch value of system variable RAMTOP

03CA:C
03CA 0B         dec bc	:C
	:; point to last system byte.
	:;

03CB:C
	:#; -----------------------
	:#; THE 'RAM CHECK' ROUTINE
	:#; -----------------------
	:#;
	:#;
	:#
	:#;; RAM-CHECK
03CB 60         ld h, b	:C RAM_CHECK
	:;

03CC:C
03CC 69         ld l, c	:C
	:;

03CD:C
03CD 3E3F       ld a, $3F	:C
	:;
	:;

03CF:C
	:#;; RAM-FILL
03CF 3602       ld (hl), $02	:C RAM_FILL
	:;

03D1:C
03D1 2B         dec hl	:C
	:;

03D2:C
03D2 BC         cp h	:C
	:;

03D3:C
03D3 20FA       jr nz, $03CF	:C
	:; to RAM-FILL
	:;

03D5:C
	:#;; RAM-READ
03D5 A7         and a	:C RAM_READ
	:;

03D6:C
03D6 ED42       sbc hl, bc	:C
	:;

03D8:C
03D8 09         add hl, bc	:C
	:;

03D9:C
03D9 23         inc hl	:C
	:;

03DA:C
03DA 3006       jr nc, $03E2	:C
	:; to SET-TOP
	:;

03DC:C
03DC 35         dec (hl)	:C
	:;

03DD:C
03DD 2803       jr z, $03E2	:C
	:; to SET-TOP
	:;

03DF:C
03DF 35         dec (hl)	:C
	:;

03E0:C
03E0 28F3       jr z, $03D5	:C
	:; to RAM-READ
	:;

03E2:C
	:#;; SET-TOP
03E2 220440     ld ($4004), hl	:C SET_TOP
	:; set system variable RAMTOP to first byte 
	:; above the BASIC system area.
	:;

03E5:C
	:#; ----------------------------
	:#; THE 'INITIALIZATION' ROUTINE
	:#; ----------------------------
	:#;
	:#;
	:#
	:#;; INITIAL
03E5 2A0440     ld hl, ($4004)	:C INITIAL
	:; fetch system variable RAMTOP.

03E8:C
03E8 2B         dec hl	:C
	:; point to last system byte.

03E9:C
03E9 363E       ld (hl), $3E	:C
	:; make GO SUB end-marker $3E - too high for
	:; high order byte of line number.
	:; (was $3F on ZX80)

03EB:C
03EB 2B         dec hl	:C
	:; point to unimportant low-order byte.

03EC:C
03EC F9         ld sp, hl	:C
	:; and initialize the stack-pointer to this
	:; location.

03ED:C
03ED 2B         dec hl	:C
	:; point to first location on the machine stack

03EE:C
03EE 2B         dec hl	:C
	:; which will be filled by next CALL/PUSH.

03EF:C
03EF 220240     ld ($4002), hl	:C
	:; set the error stack pointer ERR_SP to
	:; the base of the now empty machine stack.
	:;

03F2:C
	:#; Now set the I register so that the video hardware knows where to find the
	:#; character set. This ROM only uses the character set when printing to 
	:#; the ZX Printer. The TV picture is formed by the external video hardware. 
	:#; Consider also, that this 8K ROM can be retro-fitted to the ZX80 instead of 
	:#; its original 4K ROM so the video hardware could be on the ZX80.
	:#
03F2 3E1E       ld a, $1E	:C
	:; address for this ROM is $1E00.

03F4:C
03F4 ED47       ld i, a	:C
	:; set I register from A.

03F6:C
03F6 ED56       im 1	:C
	:; select Z80 Interrupt Mode 1.
	:;

03F8:C
03F8 FD210040   ld iy, $4000	:C
	:; set IY to the start of RAM so that the 
	:; system variables can be indexed.

03FC:C
03FC FD363B40   ld (iy+$3B), $40	:C
	:; set CDFLAG 0100 0000. Bit 6 indicates 
	:; Compute nad Display required.
	:;

0400:C
0400 217D40     ld hl, $407D	:C
	:; The first location after System Variables -
	:; 16509 decimal.

0403:C
0403 220C40     ld ($400C), hl	:C
	:; set system variable D_FILE to this value.

0406:C
0406 0619       ld b, $19	:C
	:; prepare minimal screen of 24 NEWLINEs
	:; following an initial NEWLINE.
	:;

0408:C
	:#;; LINE
0408 3676       ld (hl), $76	:C LINE
	:; insert NEWLINE (HALT instruction)

040A:C
040A 23         inc hl	:C
	:; point to next location.

040B:C
040B 10FB       djnz $0408	:C
	:; loop back for all twenty five to LINE
	:;

040D:C
040D 221040     ld ($4010), hl	:C
	:; set system variable VARS to next location
	:;

0410:C
0410 CD9A14     call $149A	:C
	:; routine CLEAR sets $80 end-marker and the 
	:; dynamic memory pointers E_LINE, STKBOT and
	:; STKEND.
	:;

0413:C
	:#;; N/L-ONLY
0413 CDAD14     call $14AD	:C N_L_ONLY
	:; routine CURSOR-IN inserts the cursor and 
	:; end-marker in the Edit Line also setting
	:; size of lower display to two lines.
	:;

0416:C
0416 CD0702     call $0207	:C
	:; routine SLOW/FAST selects COMPUTE and DISPLAY
	:;

0419:C
	:#; ---------------------------
	:#; THE 'BASIC LISTING' SECTION
	:#; ---------------------------
	:#;
	:#;
	:#
	:#;; UPPER
0419 CD2A0A     call $0A2A	:C UPPER
	:; routine CLS

041C:C
041C 2A0A40     ld hl, ($400A)	:C
	:; sv E_PPC_lo

041F:C
041F ED5B2340   ld de, ($4023)	:C
	:; sv S_TOP_lo

0423:C
0423 A7         and a	:C
	:;

0424:C
0424 ED52       sbc hl, de	:C
	:;

0426:C
0426 EB         ex de, hl	:C
	:;

0427:C
0427 3004       jr nc, $042D	:C
	:; to ADDR-TOP
	:;

0429:C
0429 19         add hl, de	:C
	:;

042A:C
042A 222340     ld ($4023), hl	:C
	:; sv S_TOP_lo
	:;

042D:C
	:#;; ADDR-TOP
042D CDD809     call $09D8	:C ADDR_TOP
	:; routine LINE-ADDR

0430:C
0430 2801       jr z, $0433	:C
	:; to LIST-TOP
	:;

0432:C
0432 EB         ex de, hl	:C
	:;
	:;

0433:C
	:#;; LIST-TOP
0433 CD3E07     call $073E	:C LIST_TOP
	:; routine LIST-PROG

0436:C
0436 FD351E     dec (iy+$1E)	:C
	:; sv BERG

0439:C
0439 2037       jr nz, $0472	:C
	:; to LOWER
	:;

043B:C
043B 2A0A40     ld hl, ($400A)	:C
	:; sv E_PPC_lo

043E:C
043E CDD809     call $09D8	:C
	:; routine LINE-ADDR

0441:C
0441 2A1640     ld hl, ($4016)	:C
	:; sv CH_ADD_lo

0444:C
0444 37         scf	:C
	:; Set Carry Flag

0445:C
0445 ED52       sbc hl, de	:C
	:;

0447:C
0447 212340     ld hl, $4023	:C
	:; sv S_TOP_lo

044A:C
044A 300B       jr nc, $0457	:C
	:; to INC-LINE
	:;

044C:C
044C EB         ex de, hl	:C
	:;

044D:C
044D 7E         ld a, (hl)	:C
	:;

044E:C
044E 23         inc hl	:C
	:;

044F:C
044F EDA0       ldi	:C
	:;

0451:C
0451 12         ld (de), a	:C
	:;

0452:C
0452 18C5       jr $0419	:C
	:; to UPPER
	:;

0454:C
	:#; ---
	:#
	:#;; DOWN-KEY
0454 210A40     ld hl, $400A	:C DOWN_KEY
	:; sv E_PPC_lo
	:;

0457:C
	:#;; INC-LINE
0457 5E         ld e, (hl)	:C INC_LINE
	:;

0458:C
0458 23         inc hl	:C
	:;

0459:C
0459 56         ld d, (hl)	:C
	:;

045A:C
045A E5         push hl	:C
	:;

045B:C
045B EB         ex de, hl	:C
	:;

045C:C
045C 23         inc hl	:C
	:;

045D:C
045D CDD809     call $09D8	:C
	:; routine LINE-ADDR

0460:C
0460 CDBB05     call $05BB	:C
	:; routine LINE-NO

0463:C
0463 E1         pop hl	:C
	:;
	:;

0464:C
	:#;; KEY-INPUT
0464 FDCB2D6E   bit 5, (iy+$2D)	:C KEY_INPUT
	:; sv FLAGX

0468:C
0468 2008       jr nz, $0472	:C
	:; forward to LOWER
	:;

046A:C
046A 72         ld (hl), d	:C
	:;

046B:C
046B 2B         dec hl	:C
	:;

046C:C
046C 73         ld (hl), e	:C
	:;

046D:C
046D 18AA       jr $0419	:C
	:; to UPPER
	:;

046F:C
	:#; ----------------------------
	:#; THE 'EDIT LINE COPY' SECTION
	:#; ----------------------------
	:#; This routine sets the edit line to just the cursor when
	:#; 1) There is not enough memory to edit a BASIC line.
	:#; 2) The edit key is used during input.
	:#; The entry point LOWER
	:#
	:#
	:#;; EDIT-INP
046F CDAD14     call $14AD	:C EDIT_INP
	:; routine CURSOR-IN sets cursor only edit line.
	:;

0472:C
	:#; ->
	:#
	:#;; LOWER
0472 2A1440     ld hl, ($4014)	:C LOWER
	:; fetch edit line start from E_LINE.
	:;

0475:C
	:#;; EACH-CHAR
0475 7E         ld a, (hl)	:C EACH_CHAR
	:; fetch a character from edit line.

0476:C
0476 FE7E       cp $7E	:C
	:; compare to the number marker.

0478:C
0478 2008       jr nz, $0482	:C
	:; forward if not to END-LINE
	:;

047A:C
047A 010600     ld bc, $0006	:C
	:; else six invisible bytes to be removed.

047D:C
047D CD600A     call $0A60	:C
	:; routine RECLAIM-2

0480:C
0480 18F3       jr $0475	:C
	:; back to EACH-CHAR
	:;

0482:C
	:#; ---
	:#
	:#;; END-LINE
0482 FE76       cp $76	:C END_LINE
	:;

0484:C
0484 23         inc hl	:C
	:;

0485:C
0485 20EE       jr nz, $0475	:C
	:; to EACH-CHAR
	:;

0487:C
	:#;; EDIT-LINE
0487 CD3705     call $0537	:C EDIT_LINE
	:; routine CURSOR sets cursor K or L.
	:;

048A:C
	:#;; EDIT-ROOM
048A CD1F0A     call $0A1F	:C EDIT_ROOM
	:; routine LINE-ENDS

048D:C
048D 2A1440     ld hl, ($4014)	:C
	:; sv E_LINE_lo

0490:C
0490 FD3600FF   ld (iy), $FF	:C
	:; sv ERR_NR

0494:C
0494 CD6607     call $0766	:C
	:; routine COPY-LINE

0497:C
0497 FDCB007E   bit 7, (iy)	:C
	:; sv ERR_NR

049B:C
049B 2024       jr nz, $04C1	:C
	:; to DISPLAY-6
	:;

049D:C
049D 3A2240     ld a, ($4022)	:C
	:; sv DF_SZ

04A0:C
04A0 FE18       cp $18	:C
	:;

04A2:C
04A2 301D       jr nc, $04C1	:C
	:; to DISPLAY-6
	:;

04A4:C
04A4 3C         inc a	:C
	:;

04A5:C
04A5 322240     ld ($4022), a	:C
	:; sv DF_SZ

04A8:C
04A8 47         ld b, a	:C
	:;

04A9:C
04A9 0E01       ld c, $01	:C
	:;

04AB:C
04AB CD1809     call $0918	:C
	:; routine LOC-ADDR

04AE:C
04AE 54         ld d, h	:C
	:;

04AF:C
04AF 5D         ld e, l	:C
	:;

04B0:C
04B0 7E         ld a, (hl)	:C
	:;
	:;

04B1:C
	:#;; FREE-LINE
04B1 2B         dec hl	:C FREE_LINE
	:;

04B2:C
04B2 BE         cp (hl)	:C
	:;

04B3:C
04B3 20FC       jr nz, $04B1	:C
	:; to FREE-LINE
	:;

04B5:C
04B5 23         inc hl	:C
	:;

04B6:C
04B6 EB         ex de, hl	:C
	:;

04B7:C
04B7 3A0540     ld a, ($4005)	:C
	:; sv RAMTOP_hi

04BA:C
04BA FE4D       cp $4D	:C
	:;

04BC:C
04BC DC5D0A     call c, $0A5D	:C
	:; routine RECLAIM-1

04BF:C
04BF 18C9       jr $048A	:C
	:; to EDIT-ROOM
	:;

04C1:C
	:#; --------------------------
	:#; THE 'WAIT FOR KEY' SECTION
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; DISPLAY-6
04C1 210000     ld hl, $0000	:C DISPLAY_6
	:;

04C4:C
04C4 221840     ld ($4018), hl	:C
	:; sv X_PTR_lo
	:;

04C7:C
04C7 213B40     ld hl, $403B	:C
	:; system variable CDFLAG

04CA:C
04CA CB7E       bit 7, (hl)	:C
	:;
	:;

04CC:C
04CC CC2902     call z, $0229	:C
	:; routine DISPLAY-1
	:;

04CF:C
	:#;; SLOW-DISP
04CF CB46       bit 0, (hl)	:C SLOW_DISP
	:;

04D1:C
04D1 28FC       jr z, $04CF	:C
	:; to SLOW-DISP
	:;

04D3:C
04D3 ED4B2540   ld bc, ($4025)	:C
	:; sv LAST_K

04D7:C
04D7 CD4B0F     call $0F4B	:C
	:; routine DEBOUNCE

04DA:C
04DA CDBD07     call $07BD	:C
	:; routine DECODE
	:;

04DD:C
04DD 3093       jr nc, $0472	:C
	:; back to LOWER
	:;

04DF:C
	:#; -------------------------------
	:#; THE 'KEYBOARD DECODING' SECTION
	:#; -------------------------------
	:#;   The decoded key value is in E and HL points to the position in the 
	:#;   key table. D contains zero.
	:#
	:#;; K-DECODE 
04DF 3A0640     ld a, ($4006)	:C K_DECODE
	:; Fetch value of system variable MODE

04E2:C
04E2 3D         dec a	:C
	:; test the three values together
	:;

04E3:C
04E3 FA0805     jp m, $0508	:C
	:; forward, if was zero, to FETCH-2
	:;

04E6:C
04E6 200F       jr nz, $04F7	:C
	:; forward, if was 2, to FETCH-1
	:;

04E8:C
	:#;   The original value was one and is now zero.
	:#
04E8 320640     ld ($4006), a	:C
	:; update the system variable MODE
	:;

04EB:C
04EB 1D         dec e	:C
	:; reduce E to range $00 - $7F

04EC:C
04EC 7B         ld a, e	:C
	:; place in A

04ED:C
04ED D627       sub $27	:C
	:; subtract 39 setting carry if range 00 - 38

04EF:C
04EF 3801       jr c, $04F2	:C
	:; forward, if so, to FUNC-BASE
	:;

04F1:C
04F1 5F         ld e, a	:C
	:; else set E to reduced value
	:;

04F2:C
	:#;; FUNC-BASE
04F2 21CC00     ld hl, $00CC	:C FUNC_BASE
	:; address of K-FUNCT table for function keys.

04F5:C
04F5 180E       jr $0505	:C
	:; forward to TABLE-ADD
	:;

04F7:C
	:#; ---
	:#
	:#;; FETCH-1
04F7 7E         ld a, (hl)	:C FETCH_1
	:;

04F8:C
04F8 FE76       cp $76	:C
	:;

04FA:C
04FA 282F       jr z, $052B	:C
	:; to K/L-KEY
	:;

04FC:C
04FC FE40       cp $40	:C
	:;

04FE:C
04FE CBFF       set 7, a	:C
	:;

0500:C
0500 3819       jr c, $051B	:C
	:; to ENTER
	:;

0502:C
0502 21C700     ld hl, $00C7	:C
	:; (expr reqd)
	:;

0505:C
	:#;; TABLE-ADD
0505 19         add hl, de	:C TABLE_ADD
	:;

0506:C
0506 180D       jr $0515	:C
	:; to FETCH-3
	:;

0508:C
	:#; ---
	:#
	:#;; FETCH-2
0508 7E         ld a, (hl)	:C FETCH_2
	:;

0509:C
0509 FDCB0156   bit 2, (iy+$01)	:C
	:; sv FLAGS  - K or L mode ?

050D:C
050D 2007       jr nz, $0516	:C
	:; to TEST-CURS
	:;

050F:C
050F C6C0       add a, $C0	:C
	:;

0511:C
0511 FEE6       cp $E6	:C
	:;

0513:C
0513 3001       jr nc, $0516	:C
	:; to TEST-CURS
	:;

0515:C
	:#;; FETCH-3
0515 7E         ld a, (hl)	:C FETCH_3
	:;
	:;

0516:C
	:#;; TEST-CURS
0516 FEF0       cp $F0	:C TEST_CURS
	:;

0518:C
0518 EA2D05     jp pe, $052D	:C
	:; to KEY-SORT
	:;

051B:C
	:#;; ENTER
051B 5F         ld e, a	:C ENTER
	:;

051C:C
051C CD3705     call $0537	:C
	:; routine CURSOR
	:;

051F:C
051F 7B         ld a, e	:C
	:;

0520:C
0520 CD2605     call $0526	:C
	:; routine ADD-CHAR
	:;

0523:C
	:#;; BACK-NEXT
0523 C37204     jp $0472	:C BACK_NEXT
	:; back to LOWER
	:;

0526:C
	:#; ------------------------------
	:#; THE 'ADD CHARACTER' SUBROUTINE
	:#; ------------------------------
	:#;
	:#;
	:#
	:#;; ADD-CHAR
0526 CD9B09     call $099B	:C ADD_CHAR
	:; routine ONE-SPACE

0529:C
0529 12         ld (de), a	:C
	:;

052A:C
052A C9         ret	:C
	:;
	:;

052B:C
	:#; -------------------------
	:#; THE 'CURSOR KEYS' ROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; K/L-KEY
052B 3E78       ld a, $78	:C K_L_KEY
	:;
	:;

052D:C
	:#;; KEY-SORT
052D 5F         ld e, a	:C KEY_SORT
	:;

052E:C
052E 218204     ld hl, $0482	:C
	:; base address of ED-KEYS (exp reqd)

0531:C
0531 19         add hl, de	:C
	:;

0532:C
0532 19         add hl, de	:C
	:;

0533:C
0533 4E         ld c, (hl)	:C
	:;

0534:C
0534 23         inc hl	:C
	:;

0535:C
0535 46         ld b, (hl)	:C
	:;

0536:C
0536 C5         push bc	:C
	:;
	:;

0537:C
	:#;; CURSOR
0537 2A1440     ld hl, ($4014)	:C CURSOR
	:; sv E_LINE_lo

053A:C
053A FDCB2D6E   bit 5, (iy+$2D)	:C
	:; sv FLAGX

053E:C
053E 2016       jr nz, $0556	:C
	:; to L-MODE
	:;

0540:C
	:#;; K-MODE
0540 FDCB0196   res 2, (iy+$01)	:C K_MODE
	:; sv FLAGS  - Signal use K mode
	:;

0544:C
	:#;; TEST-CHAR
0544 7E         ld a, (hl)	:C TEST_CHAR
	:;

0545:C
0545 FE7F       cp $7F	:C
	:;

0547:C
0547 C8         ret z	:C
	:; return
	:;

0548:C
0548 23         inc hl	:C
	:;

0549:C
0549 CDB407     call $07B4	:C
	:; routine NUMBER

054C:C
054C 28F6       jr z, $0544	:C
	:; to TEST-CHAR
	:;

054E:C
054E FE26       cp $26	:C
	:;

0550:C
0550 38F2       jr c, $0544	:C
	:; to TEST-CHAR
	:;

0552:C
0552 FEDE       cp $DE	:C
	:;

0554:C
0554 28EA       jr z, $0540	:C
	:; to K-MODE
	:;

0556:C
	:#;; L-MODE
0556 FDCB01D6   set 2, (iy+$01)	:C L_MODE
	:; sv FLAGS  - Signal use L mode

055A:C
055A 18E8       jr $0544	:C
	:; to TEST-CHAR
	:;

055C:C
	:#; --------------------------
	:#; THE 'CLEAR-ONE' SUBROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; CLEAR-ONE
055C 010100     ld bc, $0001	:C CLEAR_ONE
	:;

055F:C
055F C3600A     jp $0A60	:C
	:; to RECLAIM-2
	:;
	:;
	:;

0562:W
	:#; ------------------------
	:#; THE 'EDITING KEYS' TABLE
	:#; ------------------------
	:#;
	:#;
	:#
	:#;; ED-KEYS
0562-0563 9F05	:W ED_KEYS
	:; Address: $059F; Address: UP-KEY

0564:W
0564-0565 5404	:W
	:; Address: $0454; Address: DOWN-KEY

0566:W
0566-0567 7605	:W
	:; Address: $0576; Address: LEFT-KEY

0568:W
0568-0569 7F05	:W
	:; Address: $057F; Address: RIGHT-KEY

056A:W
056A-056B AF05	:W
	:; Address: $05AF; Address: FUNCTION

056C:W
056C-056D C405	:W
	:; Address: $05C4; Address: EDIT-KEY

056E:W
056E-056F 0C06	:W
	:; Address: $060C; Address: N/L-KEY

0570:W
0570-0571 8B05	:W
	:; Address: $058B; Address: RUBOUT

0572:W
0572-0573 AF05	:W
	:; Address: $05AF; Address: FUNCTION

0574:W
0574-0575 AF05	:W
	:; Address: $05AF; Address: FUNCTION
	:;
	:;

0576:C
	:#; -------------------------
	:#; THE 'CURSOR LEFT' ROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; LEFT-KEY
0576 CD9305     call $0593	:C LEFT_KEY
	:; routine LEFT-EDGE

0579:C
0579 7E         ld a, (hl)	:C
	:;

057A:C
057A 367F       ld (hl), $7F	:C
	:;

057C:C
057C 23         inc hl	:C
	:;

057D:C
057D 1809       jr $0588	:C
	:; to GET-CODE
	:;

057F:C
	:#; --------------------------
	:#; THE 'CURSOR RIGHT' ROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; RIGHT-KEY
057F 23         inc hl	:C RIGHT_KEY
	:;

0580:C
0580 7E         ld a, (hl)	:C
	:;

0581:C
0581 FE76       cp $76	:C
	:;

0583:C
0583 2818       jr z, $059D	:C
	:; to ENDED-2
	:;

0585:C
0585 367F       ld (hl), $7F	:C
	:;

0587:C
0587 2B         dec hl	:C
	:;
	:;

0588:C
	:#;; GET-CODE
0588 77         ld (hl), a	:C GET_CODE
	:;
	:;

0589:C
	:#;; ENDED-1
0589 1898       jr $0523	:C ENDED_1
	:; to BACK-NEXT
	:;

058B:C
	:#; --------------------
	:#; THE 'RUBOUT' ROUTINE
	:#; --------------------
	:#;
	:#;
	:#
	:#;; RUBOUT
058B CD9305     call $0593	:C RUBOUT
	:; routine LEFT-EDGE

058E:C
058E CD5C05     call $055C	:C
	:; routine CLEAR-ONE

0591:C
0591 18F6       jr $0589	:C
	:; to ENDED-1
	:;

0593:C
	:#; ------------------------
	:#; THE 'ED-EDGE' SUBROUTINE
	:#; ------------------------
	:#;
	:#;
	:#
	:#;; LEFT-EDGE
0593 2B         dec hl	:C LEFT_EDGE
	:;

0594:C
0594 ED5B1440   ld de, ($4014)	:C
	:; sv E_LINE_lo

0598:C
0598 1A         ld a, (de)	:C
	:;

0599:C
0599 FE7F       cp $7F	:C
	:;

059B:C
059B C0         ret nz	:C
	:;
	:;

059C:C
059C D1         pop de	:C
	:;
	:;

059D:C
	:#;; ENDED-2
059D 18EA       jr $0589	:C ENDED_2
	:; to ENDED-1
	:;

059F:C
	:#; -----------------------
	:#; THE 'CURSOR UP' ROUTINE
	:#; -----------------------
	:#;
	:#;
	:#
	:#;; UP-KEY
059F 2A0A40     ld hl, ($400A)	:C UP_KEY
	:; sv E_PPC_lo

05A2:C
05A2 CDD809     call $09D8	:C
	:; routine LINE-ADDR

05A5:C
05A5 EB         ex de, hl	:C
	:;

05A6:C
05A6 CDBB05     call $05BB	:C
	:; routine LINE-NO

05A9:C
05A9 210B40     ld hl, $400B	:C
	:; point to system variable E_PPC_hi

05AC:C
05AC C36404     jp $0464	:C
	:; jump back to KEY-INPUT
	:;

05AF:C
	:#; --------------------------
	:#; THE 'FUNCTION KEY' ROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; FUNCTION
05AF 7B         ld a, e	:C FUNCTION
	:;

05B0:C
05B0 E607       and $07	:C
	:;

05B2:C
05B2 320640     ld ($4006), a	:C
	:; sv MODE

05B5:C
05B5 18E6       jr $059D	:C
	:; back to ENDED-2
	:;

05B7:C
	:#; ------------------------------------
	:#; THE 'COLLECT LINE NUMBER' SUBROUTINE
	:#; ------------------------------------
	:#;
	:#;
	:#
	:#;; ZERO-DE
05B7 EB         ex de, hl	:C ZERO_DE
	:;

05B8:C
05B8 11C204     ld de, $04C2	:C
	:; $04C2 - a location addressing two zeros.
	:;

05BB:C
	:#; ->
	:#
	:#;; LINE-NO
05BB 7E         ld a, (hl)	:C LINE_NO
	:;

05BC:C
05BC E6C0       and $C0	:C
	:;

05BE:C
05BE 20F7       jr nz, $05B7	:C
	:; to ZERO-DE
	:;

05C0:C
05C0 56         ld d, (hl)	:C
	:;

05C1:C
05C1 23         inc hl	:C
	:;

05C2:C
05C2 5E         ld e, (hl)	:C
	:;

05C3:C
05C3 C9         ret	:C
	:;
	:;

05C4:C
	:#; ----------------------
	:#; THE 'EDIT KEY' ROUTINE
	:#; ----------------------
	:#;
	:#;
	:#
	:#;; EDIT-KEY
05C4 CD1F0A     call $0A1F	:C EDIT_KEY
	:; routine LINE-ENDS clears lower display.
	:;

05C7:C
05C7 216F04     ld hl, $046F	:C
	:; Address: EDIT-INP

05CA:C
05CA E5         push hl	:C
	:; ** is pushed as an error looping address.
	:;

05CB:C
05CB FDCB2D6E   bit 5, (iy+$2D)	:C
	:; test FLAGX

05CF:C
05CF C0         ret nz	:C
	:; indirect jump if in input mode
	:; to L046F, EDIT-INP (begin again).
	:;

05D0:C
	:#;
	:#
05D0 2A1440     ld hl, ($4014)	:C
	:; fetch E_LINE

05D3:C
05D3 220E40     ld ($400E), hl	:C
	:; and use to update the screen cursor DF_CC
	:;

05D6:C
	:#; so now RST $10 will print the line numbers to the edit line instead of screen.
	:#; first make sure that no newline/out of screen can occur while sprinting the
	:#; line numbers to the edit line.
	:#
05D6 212118     ld hl, $1821	:C
	:; prepare line 0, column 0.

05D9:C
05D9 223940     ld ($4039), hl	:C
	:; update S_POSN with these dummy values.
	:;

05DC:C
05DC 2A0A40     ld hl, ($400A)	:C
	:; fetch current line from E_PPC may be a 
	:; non-existent line e.g. last line deleted.

05DF:C
05DF CDD809     call $09D8	:C
	:; routine LINE-ADDR gets address or that of
	:; the following line.

05E2:C
05E2 CDBB05     call $05BB	:C
	:; routine LINE-NO gets line number if any in DE
	:; leaving HL pointing at second low byte.
	:;

05E5:C
05E5 7A         ld a, d	:C
	:; test the line number for zero.

05E6:C
05E6 B3         or e	:C
	:;

05E7:C
05E7 C8         ret z	:C
	:; return if no line number - no program to edit.
	:;

05E8:C
05E8 2B         dec hl	:C
	:; point to high byte.

05E9:C
05E9 CDA50A     call $0AA5	:C
	:; routine OUT-NO writes number to edit line.
	:;

05EC:C
05EC 23         inc hl	:C
	:; point to length bytes.

05ED:C
05ED 4E         ld c, (hl)	:C
	:; low byte to C.

05EE:C
05EE 23         inc hl	:C
	:;

05EF:C
05EF 46         ld b, (hl)	:C
	:; high byte to B.
	:;

05F0:C
05F0 23         inc hl	:C
	:; point to first character in line.

05F1:C
05F1 ED5B0E40   ld de, ($400E)	:C
	:; fetch display file cursor DF_CC
	:;

05F5:C
05F5 3E7F       ld a, $7F	:C
	:; prepare the cursor character.

05F7:C
05F7 12         ld (de), a	:C
	:; and insert in edit line.

05F8:C
05F8 13         inc de	:C
	:; increment intended destination.
	:;

05F9:C
05F9 E5         push hl	:C
	:; * save start of BASIC.
	:;

05FA:C
05FA 211D00     ld hl, $001D	:C
	:; set an overhead of 29 bytes.

05FD:C
05FD 19         add hl, de	:C
	:; add in the address of cursor.

05FE:C
05FE 09         add hl, bc	:C
	:; add the length of the line.

05FF:C
05FF ED72       sbc hl, sp	:C
	:; subtract the stack pointer.
	:;

0601:C
0601 E1         pop hl	:C
	:; * restore pointer to start of BASIC.
	:;

0602:C
0602 D0         ret nc	:C
	:; return if not enough room to L046F EDIT-INP.
	:; the edit key appears not to work.
	:;

0603:C
0603 EDB0       ldir	:C
	:; else copy bytes from program to edit line.
	:; Note. hidden floating point forms are also
	:; copied to edit line.
	:;

0605:C
0605 EB         ex de, hl	:C
	:; transfer free location pointer to HL
	:;

0606:C
0606 D1         pop de	:C
	:; ** remove address EDIT-INP from stack.
	:;

0607:C
0607 CDA614     call $14A6	:C
	:; routine SET-STK-B sets STKEND from HL.
	:;

060A:C
060A 1891       jr $059D	:C
	:; back to ENDED-2 and after 3 more jumps
	:; to L0472, LOWER.
	:; Note. The LOWER routine removes the hidden 
	:; floating-point numbers from the edit line.
	:;

060C:C
	:#; -------------------------
	:#; THE 'NEWLINE KEY' ROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; N/L-KEY
060C CD1F0A     call $0A1F	:C N_L_KEY
	:; routine LINE-ENDS
	:;

060F:C
060F 217204     ld hl, $0472	:C
	:; prepare address: LOWER
	:;

0612:C
0612 FDCB2D6E   bit 5, (iy+$2D)	:C
	:; sv FLAGX

0616:C
0616 2011       jr nz, $0629	:C
	:; to NOW-SCAN
	:;

0618:C
0618 2A1440     ld hl, ($4014)	:C
	:; sv E_LINE_lo

061B:C
061B 7E         ld a, (hl)	:C
	:;

061C:C
061C FEFF       cp $FF	:C
	:;

061E:C
061E 2806       jr z, $0626	:C
	:; to STK-UPPER
	:;

0620:C
0620 CDE208     call $08E2	:C
	:; routine CLEAR-PRB

0623:C
0623 CD2A0A     call $0A2A	:C
	:; routine CLS
	:;

0626:C
	:#;; STK-UPPER
0626 211904     ld hl, $0419	:C STK_UPPER
	:; Address: UPPER
	:;

0629:C
	:#;; NOW-SCAN
0629 E5         push hl	:C NOW_SCAN
	:; push routine address (LOWER or UPPER).

062A:C
062A CDBA0C     call $0CBA	:C
	:; routine LINE-SCAN

062D:C
062D E1         pop hl	:C
	:;

062E:C
062E CD3705     call $0537	:C
	:; routine CURSOR

0631:C
0631 CD5C05     call $055C	:C
	:; routine CLEAR-ONE

0634:C
0634 CD730A     call $0A73	:C
	:; routine E-LINE-NO

0637:C
0637 2015       jr nz, $064E	:C
	:; to N/L-INP
	:;

0639:C
0639 78         ld a, b	:C
	:;

063A:C
063A B1         or c	:C
	:;

063B:C
063B C2E006     jp nz, $06E0	:C
	:; to N/L-LINE
	:;

063E:C
063E 0B         dec bc	:C
	:;

063F:C
063F 0B         dec bc	:C
	:;

0640:C
0640 ED430740   ld ($4007), bc	:C
	:; sv PPC_lo

0644:C
0644 FD362202   ld (iy+$22), $02	:C
	:; sv DF_SZ

0648:C
0648 ED5B0C40   ld de, ($400C)	:C
	:; sv D_FILE_lo
	:;

064C:C
064C 1813       jr $0661	:C
	:; forward to TEST-NULL
	:;

064E:C
	:#; ---
	:#
	:#;; N/L-INP
064E FE76       cp $76	:C N_L_INP
	:;

0650:C
0650 2812       jr z, $0664	:C
	:; to N/L-NULL
	:;

0652:C
0652 ED4B3040   ld bc, ($4030)	:C
	:; sv T_ADDR_lo

0656:C
0656 CD1809     call $0918	:C
	:; routine LOC-ADDR

0659:C
0659 ED5B2940   ld de, ($4029)	:C
	:; sv NXTLIN_lo

065D:C
065D FD362202   ld (iy+$22), $02	:C
	:; sv DF_SZ
	:;

0661:C
	:#;; TEST-NULL
0661 DF         rst $18	:C TEST_NULL
	:; GET-CHAR

0662:C
0662 FE76       cp $76	:C
	:;
	:;

0664:C
	:#;; N/L-NULL
0664 CA1304     jp z, $0413	:C N_L_NULL
	:; to N/L-ONLY
	:;

0667:C
0667 FD360180   ld (iy+$01), $80	:C
	:; sv FLAGS

066B:C
066B EB         ex de, hl	:C
	:;
	:;

066C:C
	:#;; NEXT-LINE
066C 222940     ld ($4029), hl	:C NEXT_LINE
	:; sv NXTLIN_lo

066F:C
066F EB         ex de, hl	:C
	:;

0670:C
0670 CD4D00     call $004D	:C
	:; routine TEMP-PTR-2

0673:C
0673 CDC10C     call $0CC1	:C
	:; routine LINE-RUN

0676:C
0676 FDCB018E   res 1, (iy+$01)	:C
	:; sv FLAGS  - Signal printer not in use

067A:C
067A 3EC0       ld a, $C0	:C
	:;

067C:C
067C FD7719     ld (iy+$19), a	:C
	:; sv X_PTR_lo

067F:C
067F CDA314     call $14A3	:C
	:; routine X-TEMP

0682:C
0682 FDCB2DAE   res 5, (iy+$2D)	:C
	:; sv FLAGX

0686:C
0686 FDCB007E   bit 7, (iy)	:C
	:; sv ERR_NR

068A:C
068A 2822       jr z, $06AE	:C
	:; to STOP-LINE
	:;

068C:C
068C 2A2940     ld hl, ($4029)	:C
	:; sv NXTLIN_lo

068F:C
068F A6         and (hl)	:C
	:;

0690:C
0690 201C       jr nz, $06AE	:C
	:; to STOP-LINE
	:;

0692:C
0692 56         ld d, (hl)	:C
	:;

0693:C
0693 23         inc hl	:C
	:;

0694:C
0694 5E         ld e, (hl)	:C
	:;

0695:C
0695 ED530740   ld ($4007), de	:C
	:; sv PPC_lo

0699:C
0699 23         inc hl	:C
	:;

069A:C
069A 5E         ld e, (hl)	:C
	:;

069B:C
069B 23         inc hl	:C
	:;

069C:C
069C 56         ld d, (hl)	:C
	:;

069D:C
069D 23         inc hl	:C
	:;

069E:C
069E EB         ex de, hl	:C
	:;

069F:C
069F 19         add hl, de	:C
	:;

06A0:C
06A0 CD460F     call $0F46	:C
	:; routine BREAK-1

06A3:C
06A3 38C7       jr c, $066C	:C
	:; to NEXT-LINE
	:;

06A5:C
06A5 210040     ld hl, $4000	:C
	:; sv ERR_NR

06A8:C
06A8 CB7E       bit 7, (hl)	:C
	:;

06AA:C
06AA 2802       jr z, $06AE	:C
	:; to STOP-LINE
	:;

06AC:C
06AC 360C       ld (hl), $0C	:C
	:;
	:;

06AE:C
	:#;; STOP-LINE
06AE FDCB387E   bit 7, (iy+$38)	:C STOP_LINE
	:; sv PR_CC

06B2:C
06B2 CC7108     call z, $0871	:C
	:; routine COPY-BUFF

06B5:C
06B5 012101     ld bc, $0121	:C
	:;

06B8:C
06B8 CD1809     call $0918	:C
	:; routine LOC-ADDR

06BB:C
06BB 3A0040     ld a, ($4000)	:C
	:; sv ERR_NR

06BE:C
06BE ED4B0740   ld bc, ($4007)	:C
	:; sv PPC_lo

06C2:C
06C2 3C         inc a	:C
	:;

06C3:C
06C3 280C       jr z, $06D1	:C
	:; to REPORT
	:;

06C5:C
06C5 FE09       cp $09	:C
	:;

06C7:C
06C7 2001       jr nz, $06CA	:C
	:; to CONTINUE
	:;

06C9:C
06C9 03         inc bc	:C
	:;
	:;

06CA:C
	:#;; CONTINUE
06CA ED432B40   ld ($402B), bc	:C CONTINUE
	:; sv OLDPPC_lo

06CE:C
06CE 2001       jr nz, $06D1	:C
	:; to REPORT
	:;

06D0:C
06D0 0B         dec bc	:C
	:;
	:;

06D1:C
	:#;; REPORT
06D1 CDEB07     call $07EB	:C REPORT
	:; routine OUT-CODE

06D4:C
06D4 3E18       ld a, $18	:C
	:;
	:;

06D6:C
06D6 D7         rst $10	:C
	:; PRINT-A

06D7:C
06D7 CD980A     call $0A98	:C
	:; routine OUT-NUM

06DA:C
06DA CDAD14     call $14AD	:C
	:; routine CURSOR-IN

06DD:C
06DD C3C104     jp $04C1	:C
	:; to DISPLAY-6
	:;

06E0:C
	:#; ---
	:#
	:#;; N/L-LINE
06E0 ED430A40   ld ($400A), bc	:C N_L_LINE
	:; sv E_PPC_lo

06E4:C
06E4 2A1640     ld hl, ($4016)	:C
	:; sv CH_ADD_lo

06E7:C
06E7 EB         ex de, hl	:C
	:;

06E8:C
06E8 211304     ld hl, $0413	:C
	:; Address: N/L-ONLY

06EB:C
06EB E5         push hl	:C
	:;

06EC:C
06EC 2A1A40     ld hl, ($401A)	:C
	:; sv STKBOT_lo

06EF:C
06EF ED52       sbc hl, de	:C
	:;

06F1:C
06F1 E5         push hl	:C
	:;

06F2:C
06F2 C5         push bc	:C
	:;

06F3:C
06F3 CDE702     call $02E7	:C
	:; routine SET-FAST

06F6:C
06F6 CD2A0A     call $0A2A	:C
	:; routine CLS

06F9:C
06F9 E1         pop hl	:C
	:;

06FA:C
06FA CDD809     call $09D8	:C
	:; routine LINE-ADDR

06FD:C
06FD 2006       jr nz, $0705	:C
	:; to COPY-OVER
	:;

06FF:C
06FF CDF209     call $09F2	:C
	:; routine NEXT-ONE

0702:C
0702 CD600A     call $0A60	:C
	:; routine RECLAIM-2
	:;

0705:C
	:#;; COPY-OVER
0705 C1         pop bc	:C COPY_OVER
	:;

0706:C
0706 79         ld a, c	:C
	:;

0707:C
0707 3D         dec a	:C
	:;

0708:C
0708 B0         or b	:C
	:;

0709:C
0709 C8         ret z	:C
	:;
	:;

070A:C
070A C5         push bc	:C
	:;

070B:C
070B 03         inc bc	:C
	:;

070C:C
070C 03         inc bc	:C
	:;

070D:C
070D 03         inc bc	:C
	:;

070E:C
070E 03         inc bc	:C
	:;

070F:C
070F 2B         dec hl	:C
	:;

0710:C
0710 CD9E09     call $099E	:C
	:; routine MAKE-ROOM

0713:C
0713 CD0702     call $0207	:C
	:; routine SLOW/FAST

0716:C
0716 C1         pop bc	:C
	:;

0717:C
0717 C5         push bc	:C
	:;

0718:C
0718 13         inc de	:C
	:;

0719:C
0719 2A1A40     ld hl, ($401A)	:C
	:; sv STKBOT_lo

071C:C
071C 2B         dec hl	:C
	:;

071D:C
071D EDB8       lddr	:C
	:; copy bytes

071F:C
071F 2A0A40     ld hl, ($400A)	:C
	:; sv E_PPC_lo

0722:C
0722 EB         ex de, hl	:C
	:;

0723:C
0723 C1         pop bc	:C
	:;

0724:C
0724 70         ld (hl), b	:C
	:;

0725:C
0725 2B         dec hl	:C
	:;

0726:C
0726 71         ld (hl), c	:C
	:;

0727:C
0727 2B         dec hl	:C
	:;

0728:C
0728 73         ld (hl), e	:C
	:;

0729:C
0729 2B         dec hl	:C
	:;

072A:C
072A 72         ld (hl), d	:C
	:;
	:;

072B:C
072B C9         ret	:C
	:; return.
	:;

072C:C
	:#; ---------------------------------------
	:#; THE 'LIST' AND 'LLIST' COMMAND ROUTINES
	:#; ---------------------------------------
	:#;
	:#;
	:#
	:#;; LLIST
072C FDCB01CE   set 1, (iy+$01)	:C LLIST
	:; sv FLAGS  - signal printer in use
	:;

0730:C
	:#;; LIST
0730 CDA70E     call $0EA7	:C LIST
	:; routine FIND-INT
	:;

0733:C
0733 78         ld a, b	:C
	:; fetch high byte of user-supplied line number.

0734:C
0734 E63F       and $3F	:C
	:; and crudely limit to range 1-16383.
	:;

0736:C
0736 67         ld h, a	:C
	:;

0737:C
0737 69         ld l, c	:C
	:;

0738:C
0738 220A40     ld ($400A), hl	:C
	:; sv E_PPC_lo

073B:C
073B CDD809     call $09D8	:C
	:; routine LINE-ADDR
	:;

073E:C
	:#;; LIST-PROG
073E 1E00       ld e, $00	:C LIST_PROG
	:;
	:;

0740:C
	:#;; UNTIL-END
0740 CD4507     call $0745	:C UNTIL_END
	:; routine OUT-LINE lists one line of BASIC
	:; making an early return when the screen is
	:; full or the end of program is reached.    >>

0743:C
0743 18FB       jr $0740	:C
	:; loop back to UNTIL-END
	:;

0745:C
	:#; -----------------------------------
	:#; THE 'PRINT A BASIC LINE' SUBROUTINE
	:#; -----------------------------------
	:#;
	:#;
	:#
	:#;; OUT-LINE
0745 ED4B0A40   ld bc, ($400A)	:C OUT_LINE
	:; sv E_PPC_lo

0749:C
0749 CDEA09     call $09EA	:C
	:; routine CP-LINES

074C:C
074C 1692       ld d, $92	:C
	:;

074E:C
074E 2805       jr z, $0755	:C
	:; to TEST-END
	:;

0750:C
0750 110000     ld de, $0000	:C
	:;

0753:C
0753 CB13       rl e	:C
	:;
	:;

0755:C
	:#;; TEST-END
0755 FD731E     ld (iy+$1E), e	:C TEST_END
	:; sv BERG

0758:C
0758 7E         ld a, (hl)	:C
	:;

0759:C
0759 FE40       cp $40	:C
	:;

075B:C
075B C1         pop bc	:C
	:;

075C:C
075C D0         ret nc	:C
	:;
	:;

075D:C
075D C5         push bc	:C
	:;

075E:C
075E CDA50A     call $0AA5	:C
	:; routine OUT-NO

0761:C
0761 23         inc hl	:C
	:;

0762:C
0762 7A         ld a, d	:C
	:;
	:;

0763:C
0763 D7         rst $10	:C
	:; PRINT-A

0764:C
0764 23         inc hl	:C
	:;

0765:C
0765 23         inc hl	:C
	:;
	:;

0766:C
	:#;; COPY-LINE
0766 221640     ld ($4016), hl	:C COPY_LINE
	:; sv CH_ADD_lo

0769:C
0769 FDCB01C6   set 0, (iy+$01)	:C
	:; sv FLAGS  - Suppress leading space
	:;

076D:C
	:#;; MORE-LINE
076D ED4B1840   ld bc, ($4018)	:C MORE_LINE
	:; sv X_PTR_lo

0771:C
0771 2A1640     ld hl, ($4016)	:C
	:; sv CH_ADD_lo

0774:C
0774 A7         and a	:C
	:;

0775:C
0775 ED42       sbc hl, bc	:C
	:;

0777:C
0777 2003       jr nz, $077C	:C
	:; to TEST-NUM
	:;

0779:C
0779 3EB8       ld a, $B8	:C
	:;
	:;

077B:C
077B D7         rst $10	:C
	:; PRINT-A
	:;

077C:C
	:#;; TEST-NUM
077C 2A1640     ld hl, ($4016)	:C TEST_NUM
	:; sv CH_ADD_lo

077F:C
077F 7E         ld a, (hl)	:C
	:;

0780:C
0780 23         inc hl	:C
	:;

0781:C
0781 CDB407     call $07B4	:C
	:; routine NUMBER

0784:C
0784 221640     ld ($4016), hl	:C
	:; sv CH_ADD_lo

0787:C
0787 28E4       jr z, $076D	:C
	:; to MORE-LINE
	:;

0789:C
0789 FE7F       cp $7F	:C
	:;

078B:C
078B 2810       jr z, $079D	:C
	:; to OUT-CURS
	:;

078D:C
078D FE76       cp $76	:C
	:;

078F:C
078F 285D       jr z, $07EE	:C
	:; to OUT-CH
	:;

0791:C
0791 CB77       bit 6, a	:C
	:;

0793:C
0793 2805       jr z, $079A	:C
	:; to NOT-TOKEN
	:;

0795:C
0795 CD4B09     call $094B	:C
	:; routine TOKENS

0798:C
0798 18D3       jr $076D	:C
	:; to MORE-LINE
	:;

079A:C
	:#; ---
	:#
	:#
	:#;; NOT-TOKEN
079A D7         rst $10	:C NOT_TOKEN
	:; PRINT-A

079B:C
079B 18D0       jr $076D	:C
	:; to MORE-LINE
	:;

079D:C
	:#; ---
	:#
	:#;; OUT-CURS
079D 3A0640     ld a, ($4006)	:C OUT_CURS
	:; Fetch value of system variable MODE

07A0:C
07A0 06AB       ld b, $AB	:C
	:; Prepare an inverse [F] for function cursor.
	:;

07A2:C
07A2 A7         and a	:C
	:; Test for zero -

07A3:C
07A3 2005       jr nz, $07AA	:C
	:; forward if not to FLAGS-2
	:;

07A5:C
07A5 3A0140     ld a, ($4001)	:C
	:; Fetch system variable FLAGS.

07A8:C
07A8 06B0       ld b, $B0	:C
	:; Prepare an inverse [K] for keyword cursor.
	:;

07AA:C
	:#;; FLAGS-2
07AA 1F         rra	:C FLAGS_2
	:; 00000?00 -> 000000?0

07AB:C
07AB 1F         rra	:C
	:; 000000?0 -> 0000000?

07AC:C
07AC E601       and $01	:C
	:; 0000000?    0000000x
	:;

07AE:C
07AE 80         add a, b	:C
	:; Possibly [F] -> [G]  or  [K] -> [L]
	:;

07AF:C
07AF CDF507     call $07F5	:C
	:; routine PRINT-SP prints character 

07B2:C
07B2 18B9       jr $076D	:C
	:; back to MORE-LINE
	:;

07B4:C
	:#; -----------------------
	:#; THE 'NUMBER' SUBROUTINE
	:#; -----------------------
	:#;
	:#;
	:#
	:#;; NUMBER
07B4 FE7E       cp $7E	:C NUMBER
	:;

07B6:C
07B6 C0         ret nz	:C
	:;
	:;

07B7:C
07B7 23         inc hl	:C
	:;

07B8:C
07B8 23         inc hl	:C
	:;

07B9:C
07B9 23         inc hl	:C
	:;

07BA:C
07BA 23         inc hl	:C
	:;

07BB:C
07BB 23         inc hl	:C
	:;

07BC:C
07BC C9         ret	:C
	:;
	:;

07BD:C
	:#; --------------------------------
	:#; THE 'KEYBOARD DECODE' SUBROUTINE
	:#; --------------------------------
	:#;
	:#;
	:#
	:#;; DECODE
07BD 1600       ld d, $00	:C DECODE
	:;

07BF:C
07BF CB28       sra b	:C
	:;

07C1:C
07C1 9F         sbc a, a	:C
	:;

07C2:C
07C2 F626       or $26	:C
	:;

07C4:C
07C4 2E05       ld l, $05	:C
	:;

07C6:C
07C6 95         sub l	:C
	:;
	:;

07C7:C
	:#;; KEY-LINE
07C7 85         add a, l	:C KEY_LINE
	:;

07C8:C
07C8 37         scf	:C
	:; Set Carry Flag

07C9:C
07C9 CB19       rr c	:C
	:;

07CB:C
07CB 38FA       jr c, $07C7	:C
	:; to KEY-LINE
	:;

07CD:C
07CD 0C         inc c	:C
	:;

07CE:C
07CE C0         ret nz	:C
	:;
	:;

07CF:C
07CF 48         ld c, b	:C
	:;

07D0:C
07D0 2D         dec l	:C
	:;

07D1:C
07D1 2E01       ld l, $01	:C
	:;

07D3:C
07D3 20F2       jr nz, $07C7	:C
	:; to KEY-LINE
	:;

07D5:C
07D5 217D00     ld hl, $007D	:C
	:; (expr reqd)

07D8:C
07D8 5F         ld e, a	:C
	:;

07D9:C
07D9 19         add hl, de	:C
	:;

07DA:C
07DA 37         scf	:C
	:; Set Carry Flag

07DB:C
07DB C9         ret	:C
	:;
	:;

07DC:C
	:#; -------------------------
	:#; THE 'PRINTING' SUBROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; LEAD-SP
07DC 7B         ld a, e	:C LEAD_SP
	:;

07DD:C
07DD A7         and a	:C
	:;

07DE:C
07DE F8         ret m	:C
	:;
	:;

07DF:C
07DF 1810       jr $07F1	:C
	:; to PRINT-CH
	:;

07E1:C
	:#; ---
	:#
	:#;; OUT-DIGIT
07E1 AF         xor a	:C OUT_DIGIT
	:;
	:;

07E2:C
	:#;; DIGIT-INC
07E2 09         add hl, bc	:C DIGIT_INC
	:;

07E3:C
07E3 3C         inc a	:C
	:;

07E4:C
07E4 38FC       jr c, $07E2	:C
	:; to DIGIT-INC
	:;

07E6:C
07E6 ED42       sbc hl, bc	:C
	:;

07E8:C
07E8 3D         dec a	:C
	:;

07E9:C
07E9 28F1       jr z, $07DC	:C
	:; to LEAD-SP
	:;

07EB:C
	:#;; OUT-CODE
07EB 1E1C       ld e, $1C	:C OUT_CODE
	:;

07ED:C
07ED 83         add a, e	:C
	:;
	:;

07EE:C
	:#;; OUT-CH
07EE A7         and a	:C OUT_CH
	:;

07EF:C
07EF 2804       jr z, $07F5	:C
	:; to PRINT-SP
	:;

07F1:C
	:#;; PRINT-CH
07F1 FDCB0186   res 0, (iy+$01)	:C PRINT_CH
	:; update FLAGS - signal leading space permitted
	:;

07F5:C
	:#;; PRINT-SP
07F5 D9         exx	:C PRINT_SP
	:;

07F6:C
07F6 E5         push hl	:C
	:;

07F7:C
07F7 FDCB014E   bit 1, (iy+$01)	:C
	:; test FLAGS - is printer in use ?

07FB:C
07FB 2005       jr nz, $0802	:C
	:; to LPRINT-A
	:;

07FD:C
07FD CD0808     call $0808	:C
	:; routine ENTER-CH

0800:C
0800 1803       jr $0805	:C
	:; to PRINT-EXX
	:;

0802:C
	:#; ---
	:#
	:#;; LPRINT-A
0802 CD5108     call $0851	:C LPRINT_A
	:; routine LPRINT-CH
	:;

0805:C
	:#;; PRINT-EXX
0805 E1         pop hl	:C PRINT_EXX
	:;

0806:C
0806 D9         exx	:C
	:;

0807:C
0807 C9         ret	:C
	:;
	:;

0808:C
	:#; ---
	:#
	:#;; ENTER-CH
0808 57         ld d, a	:C ENTER_CH
	:;

0809:C
0809 ED4B3940   ld bc, ($4039)	:C
	:; sv S_POSN_x

080D:C
080D 79         ld a, c	:C
	:;

080E:C
080E FE21       cp $21	:C
	:;

0810:C
0810 281A       jr z, $082C	:C
	:; to TEST-LOW
	:;

0812:C
	:#;; TEST-N/L
0812 3E76       ld a, $76	:C TEST_N_L
	:;

0814:C
0814 BA         cp d	:C
	:;

0815:C
0815 2830       jr z, $0847	:C
	:; to WRITE-N/L
	:;

0817:C
0817 2A0E40     ld hl, ($400E)	:C
	:; sv DF_CC_lo

081A:C
081A BE         cp (hl)	:C
	:;

081B:C
081B 7A         ld a, d	:C
	:;

081C:C
081C 2020       jr nz, $083E	:C
	:; to WRITE-CH
	:;

081E:C
081E 0D         dec c	:C
	:;

081F:C
081F 2019       jr nz, $083A	:C
	:; to EXPAND-1
	:;

0821:C
0821 23         inc hl	:C
	:;

0822:C
0822 220E40     ld ($400E), hl	:C
	:; sv DF_CC_lo

0825:C
0825 0E21       ld c, $21	:C
	:;

0827:C
0827 05         dec b	:C
	:;

0828:C
0828 ED433940   ld ($4039), bc	:C
	:; sv S_POSN_x
	:;

082C:C
	:#;; TEST-LOW
082C 78         ld a, b	:C TEST_LOW
	:;

082D:C
082D FDBE22     cp (iy+$22)	:C
	:; sv DF_SZ

0830:C
0830 2803       jr z, $0835	:C
	:; to REPORT-5
	:;

0832:C
0832 A7         and a	:C
	:;

0833:C
0833 20DD       jr nz, $0812	:C
	:; to TEST-N/L
	:;

0835:C
	:#;; REPORT-5
0835 2E04       ld l, $04	:C REPORT_5
	:; 'No more room on screen'

0837:C
0837 C35800     jp $0058	:C
	:; to ERROR-3
	:;

083A:C
	:#; ---
	:#
	:#;; EXPAND-1
083A CD9B09     call $099B	:C EXPAND_1
	:; routine ONE-SPACE

083D:C
083D EB         ex de, hl	:C
	:;
	:;

083E:C
	:#;; WRITE-CH
083E 77         ld (hl), a	:C WRITE_CH
	:;

083F:C
083F 23         inc hl	:C
	:;

0840:C
0840 220E40     ld ($400E), hl	:C
	:; sv DF_CC_lo

0843:C
0843 FD3539     dec (iy+$39)	:C
	:; sv S_POSN_x

0846:C
0846 C9         ret	:C
	:;
	:;

0847:C
	:#; ---
	:#
	:#;; WRITE-N/L
0847 0E21       ld c, $21	:C WRITE_N_L
	:;

0849:C
0849 05         dec b	:C
	:;

084A:C
084A FDCB01C6   set 0, (iy+$01)	:C
	:; sv FLAGS  - Suppress leading space

084E:C
084E C31809     jp $0918	:C
	:; to LOC-ADDR
	:;

0851:C
	:#; --------------------------
	:#; THE 'LPRINT-CH' SUBROUTINE
	:#; --------------------------
	:#; This routine sends a character to the ZX-Printer placing the code for the
	:#; character in the Printer Buffer.
	:#; Note. PR-CC contains the low byte of the buffer address. The high order byte 
	:#; is always constant. 
	:#
	:#
	:#;; LPRINT-CH
0851 FE76       cp $76	:C LPRINT_CH
	:; compare to NEWLINE.

0853:C
0853 281C       jr z, $0871	:C
	:; forward if so to COPY-BUFF
	:;

0855:C
0855 4F         ld c, a	:C
	:; take a copy of the character in C.

0856:C
0856 3A3840     ld a, ($4038)	:C
	:; fetch print location from PR_CC

0859:C
0859 E67F       and $7F	:C
	:; ignore bit 7 to form true position.

085B:C
085B FE5C       cp $5C	:C
	:; compare to 33rd location
	:;

085D:C
085D 6F         ld l, a	:C
	:; form low-order byte.

085E:C
085E 2640       ld h, $40	:C
	:; the high-order byte is fixed.
	:;

0860:C
0860 CC7108     call z, $0871	:C
	:; routine COPY-BUFF to send full buffer to 
	:; the printer if first 32 bytes full.
	:; (this will reset HL to start.)
	:;

0863:C
0863 71         ld (hl), c	:C
	:; place character at location.

0864:C
0864 2C         inc l	:C
	:; increment - will not cross a 256 boundary.

0865:C
0865 FD7538     ld (iy+$38), l	:C
	:; update system variable PR_CC
	:; automatically resetting bit 7 to show that
	:; the buffer is not empty.

0868:C
0868 C9         ret	:C
	:; return.
	:;

0869:C
	:#; --------------------------
	:#; THE 'COPY' COMMAND ROUTINE
	:#; --------------------------
	:#; The full character-mapped screen is copied to the ZX-Printer.
	:#; All twenty-four text/graphic lines are printed.
	:#
	:#;; COPY
0869 1616       ld d, $16	:C COPY
	:; prepare to copy twenty four text lines.

086B:C
086B 2A0C40     ld hl, ($400C)	:C
	:; set HL to start of display file from D_FILE.

086E:C
086E 23         inc hl	:C
	:; 

086F:C
086F 1805       jr $0876	:C
	:; forward to COPY*D
	:;

0871:C
	:#; ---
	:#
	:#; A single character-mapped printer buffer is copied to the ZX-Printer.
	:#
	:#;; COPY-BUFF
0871 1601       ld d, $01	:C COPY_BUFF
	:; prepare to copy a single text line.

0873:C
0873 213C40     ld hl, $403C	:C
	:; set HL to start of printer buffer PRBUFF.
	:;

0876:C
	:#; both paths converge here.
	:#
	:#;; COPY*D
0876 CDE702     call $02E7	:C COPY_D
	:; routine SET-FAST
	:;

0879:C
0879 C5         push bc	:C
	:; *** preserve BC throughout.
	:; a pending character may be present 
	:; in C from LPRINT-CH
	:;

087A:C
	:#;; COPY-LOOP
087A E5         push hl	:C COPY_LOOP
	:; save first character of line pointer. (*)

087B:C
087B AF         xor a	:C
	:; clear accumulator.

087C:C
087C 5F         ld e, a	:C
	:; set pixel line count, range 0-7, to zero.
	:;

087D:C
	:#; this inner loop deals with each horizontal pixel line.
	:#
	:#;; COPY-TIME
087D D3FB       out ($FB), a	:C COPY_TIME
	:; bit 2 reset starts the printer motor
	:; with an inactive stylus - bit 7 reset.

087F:C
087F E1         pop hl	:C
	:; pick up first character of line pointer (*)
	:; on inner loop.
	:;

0880:C
	:#;; COPY-BRK
0880 CD460F     call $0F46	:C COPY_BRK
	:; routine BREAK-1

0883:C
0883 3805       jr c, $088A	:C
	:; forward with no keypress to COPY-CONT
	:;

0885:C
	:#; else A will hold 11111111 0
	:#
0885 1F         rra	:C
	:; 0111 1111

0886:C
0886 D3FB       out ($FB), a	:C
	:; stop ZX printer motor, de-activate stylus.
	:;

0888:C
	:#;; REPORT-D2
0888 CF         rst $08	:C REPORT_D2
	:; ERROR-1

0889:B
0889-0889 0C	:B
	:; Error Report: BREAK - CONT repeats
	:;

088A:C
	:#; ---
	:#
	:#;; COPY-CONT
088A DBFB       in a, ($FB)	:C COPY_CONT
	:; read from printer port.

088C:C
088C 87         add a, a	:C
	:; test bit 6 and 7

088D:C
088D FADE08     jp m, $08DE	:C
	:; jump forward with no printer to COPY-END
	:;

0890:C
0890 30EE       jr nc, $0880	:C
	:; back if stylus not in position to COPY-BRK
	:;

0892:C
0892 E5         push hl	:C
	:; save first character of line pointer (*)

0893:C
0893 D5         push de	:C
	:; ** preserve character line and pixel line.
	:;

0894:C
0894 7A         ld a, d	:C
	:; text line count to A?

0895:C
0895 FE02       cp $02	:C
	:; sets carry if last line.

0897:C
0897 9F         sbc a, a	:C
	:; now $FF if last line else zero.
	:;

0898:C
	:#; now cleverly prepare a printer control mask setting bit 2 (later moved to 1)
	:#; of D to slow printer for the last two pixel lines ( E = 6 and 7)
	:#
0898 A3         and e	:C
	:; and with pixel line offset 0-7

0899:C
0899 07         rlca	:C
	:; shift to left.

089A:C
089A A3         and e	:C
	:; and again.

089B:C
089B 57         ld d, a	:C
	:; store control mask in D.
	:;

089C:C
	:#;; COPY-NEXT
089C 4E         ld c, (hl)	:C COPY_NEXT
	:; load character from screen or buffer.

089D:C
089D 79         ld a, c	:C
	:; save a copy in C for later inverse test.

089E:C
089E 23         inc hl	:C
	:; update pointer for next time.

089F:C
089F FE76       cp $76	:C
	:; is character a NEWLINE ?

08A1:C
08A1 2824       jr z, $08C7	:C
	:; forward, if so, to COPY-N/L
	:;

08A3:C
08A3 E5         push hl	:C
	:; * else preserve the character pointer.
	:;

08A4:C
08A4 CB27       sla a	:C
	:; (?) multiply by two

08A6:C
08A6 87         add a, a	:C
	:; multiply by four

08A7:C
08A7 87         add a, a	:C
	:; multiply by eight
	:;

08A8:C
08A8 260F       ld h, $0F	:C
	:; load H with half the address of character set.

08AA:C
08AA CB14       rl h	:C
	:; now $1E or $1F (with carry)

08AC:C
08AC 83         add a, e	:C
	:; add byte offset 0-7

08AD:C
08AD 6F         ld l, a	:C
	:; now HL addresses character source byte
	:;

08AE:C
08AE CB11       rl c	:C
	:; test character, setting carry if inverse.

08B0:C
08B0 9F         sbc a, a	:C
	:; accumulator now $00 if normal, $FF if inverse.
	:;

08B1:C
08B1 AE         xor (hl)	:C
	:; combine with bit pattern at end or ROM.

08B2:C
08B2 4F         ld c, a	:C
	:; transfer the byte to C.

08B3:C
08B3 0608       ld b, $08	:C
	:; count eight bits to output.
	:;

08B5:C
	:#;; COPY-BITS
08B5 7A         ld a, d	:C COPY_BITS
	:; fetch speed control mask from D.

08B6:C
08B6 CB01       rlc c	:C
	:; rotate a bit from output byte to carry.

08B8:C
08B8 1F         rra	:C
	:; pick up in bit 7, speed bit to bit 1

08B9:C
08B9 67         ld h, a	:C
	:; store aligned mask in H register.
	:;

08BA:C
	:#;; COPY-WAIT
08BA DBFB       in a, ($FB)	:C COPY_WAIT
	:; read the printer port

08BC:C
08BC 1F         rra	:C
	:; test for alignment signal from encoder.

08BD:C
08BD 30FB       jr nc, $08BA	:C
	:; loop if not present to COPY-WAIT
	:;

08BF:C
08BF 7C         ld a, h	:C
	:; control byte to A.

08C0:C
08C0 D3FB       out ($FB), a	:C
	:; and output to printer port.

08C2:C
08C2 10F1       djnz $08B5	:C
	:; loop for all eight bits to COPY-BITS
	:;

08C4:C
08C4 E1         pop hl	:C
	:; * restore character pointer.

08C5:C
08C5 18D5       jr $089C	:C
	:; back for adjacent character line to COPY-NEXT
	:;

08C7:C
	:#; ---
	:#
	:#; A NEWLINE has been encountered either following a text line or as the 
	:#; first character of the screen or printer line.
	:#
	:#;; COPY-N/L
08C7 DBFB       in a, ($FB)	:C COPY_N_L
	:; read printer port.

08C9:C
08C9 1F         rra	:C
	:; wait for encoder signal.

08CA:C
08CA 30FB       jr nc, $08C7	:C
	:; loop back if not to COPY-N/L
	:;

08CC:C
08CC 7A         ld a, d	:C
	:; transfer speed mask to A.

08CD:C
08CD 0F         rrca	:C
	:; rotate speed bit to bit 1. 
	:; bit 7, stylus control is reset.

08CE:C
08CE D3FB       out ($FB), a	:C
	:; set the printer speed.
	:;

08D0:C
08D0 D1         pop de	:C
	:; ** restore character line and pixel line.

08D1:C
08D1 1C         inc e	:C
	:; increment pixel line 0-7.

08D2:C
08D2 CB5B       bit 3, e	:C
	:; test if value eight reached.

08D4:C
08D4 28A7       jr z, $087D	:C
	:; back if not to COPY-TIME
	:;

08D6:C
	:#; eight pixel lines, a text line have been completed.
	:#
08D6 C1         pop bc	:C
	:; lose the now redundant first character 
	:; pointer

08D7:C
08D7 15         dec d	:C
	:; decrease text line count.

08D8:C
08D8 20A0       jr nz, $087A	:C
	:; back if not zero to COPY-LOOP
	:;

08DA:C
08DA 3E04       ld a, $04	:C
	:; stop the already slowed printer motor.

08DC:C
08DC D3FB       out ($FB), a	:C
	:; output to printer port.
	:;

08DE:C
	:#;; COPY-END
08DE CD0702     call $0207	:C COPY_END
	:; routine SLOW/FAST

08E1:C
08E1 C1         pop bc	:C
	:; *** restore preserved BC.
	:;

08E2:C
	:#; -------------------------------------
	:#; THE 'CLEAR PRINTER BUFFER' SUBROUTINE
	:#; -------------------------------------
	:#; This subroutine sets 32 bytes of the printer buffer to zero (space) and
	:#; the 33rd character is set to a NEWLINE.
	:#; This occurs after the printer buffer is sent to the printer but in addition
	:#; after the 24 lines of the screen are sent to the printer. 
	:#; Note. This is a logic error as the last operation does not involve the 
	:#; buffer at all. Logically one should be able to use 
	:#; 10 LPRINT "HELLO ";
	:#; 20 COPY
	:#; 30 LPRINT ; "WORLD"
	:#; and expect to see the entire greeting emerge from the printer.
	:#; Surprisingly this logic error was never discovered and although one can argue
	:#; if the above is a bug, the repetition of this error on the Spectrum was most
	:#; definitely a bug.
	:#; Since the printer buffer is fixed at the end of the system variables, and
	:#; the print position is in the range $3C - $5C, then bit 7 of the system
	:#; variable is set to show the buffer is empty and automatically reset when
	:#; the variable is updated with any print position - neat.
	:#
	:#;; CLEAR-PRB
08E2 215C40     ld hl, $405C	:C CLEAR_PRB
	:; address fixed end of PRBUFF

08E5:C
08E5 3676       ld (hl), $76	:C
	:; place a newline at last position.

08E7:C
08E7 0620       ld b, $20	:C
	:; prepare to blank 32 preceding characters. 
	:;

08E9:C
	:#;; PRB-BYTES
08E9 2B         dec hl	:C PRB_BYTES
	:; decrement address - could be DEC L.

08EA:C
08EA 3600       ld (hl), $00	:C
	:; place a zero byte.

08EC:C
08EC 10FB       djnz $08E9	:C
	:; loop for all thirty-two to PRB-BYTES
	:;

08EE:C
08EE 7D         ld a, l	:C
	:; fetch character print position.

08EF:C
08EF CBFF       set 7, a	:C
	:; signal the printer buffer is clear.

08F1:C
08F1 323840     ld ($4038), a	:C
	:; update one-byte system variable PR_CC

08F4:C
08F4 C9         ret	:C
	:; return.
	:;

08F5:C
	:#; -------------------------
	:#; THE 'PRINT AT' SUBROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; PRINT-AT
08F5 3E17       ld a, $17	:C PRINT_AT
	:;

08F7:C
08F7 90         sub b	:C
	:;

08F8:C
08F8 380B       jr c, $0905	:C
	:; to WRONG-VAL
	:;

08FA:C
	:#;; TEST-VAL
08FA FDBE22     cp (iy+$22)	:C TEST_VAL
	:; sv DF_SZ

08FD:C
08FD DA3508     jp c, $0835	:C
	:; to REPORT-5
	:;

0900:C
0900 3C         inc a	:C
	:;

0901:C
0901 47         ld b, a	:C
	:;

0902:C
0902 3E1F       ld a, $1F	:C
	:;

0904:C
0904 91         sub c	:C
	:;
	:;

0905:C
	:#;; WRONG-VAL
0905 DAAD0E     jp c, $0EAD	:C WRONG_VAL
	:; to REPORT-B
	:;

0908:C
0908 C602       add a, $02	:C
	:;

090A:C
090A 4F         ld c, a	:C
	:;
	:;

090B:C
	:#;; SET-FIELD
090B FDCB014E   bit 1, (iy+$01)	:C SET_FIELD
	:; sv FLAGS  - Is printer in use

090F:C
090F 2807       jr z, $0918	:C
	:; to LOC-ADDR
	:;

0911:C
0911 3E5D       ld a, $5D	:C
	:;

0913:C
0913 91         sub c	:C
	:;

0914:C
0914 323840     ld ($4038), a	:C
	:; sv PR_CC

0917:C
0917 C9         ret	:C
	:;
	:;

0918:C
	:#; ----------------------------
	:#; THE 'LOCATE ADDRESS' ROUTINE
	:#; ----------------------------
	:#;
	:#;
	:#
	:#;; LOC-ADDR
0918 ED433940   ld ($4039), bc	:C LOC_ADDR
	:; sv S_POSN_x

091C:C
091C 2A1040     ld hl, ($4010)	:C
	:; sv VARS_lo

091F:C
091F 51         ld d, c	:C
	:;

0920:C
0920 3E22       ld a, $22	:C
	:;

0922:C
0922 91         sub c	:C
	:;

0923:C
0923 4F         ld c, a	:C
	:;

0924:C
0924 3E76       ld a, $76	:C
	:;

0926:C
0926 04         inc b	:C
	:;
	:;

0927:C
	:#;; LOOK-BACK
0927 2B         dec hl	:C LOOK_BACK
	:;

0928:C
0928 BE         cp (hl)	:C
	:;

0929:C
0929 20FC       jr nz, $0927	:C
	:; to LOOK-BACK
	:;

092B:C
092B 10FA       djnz $0927	:C
	:; to LOOK-BACK
	:;

092D:C
092D 23         inc hl	:C
	:;

092E:C
092E EDB1       cpir	:C
	:;

0930:C
0930 2B         dec hl	:C
	:;

0931:C
0931 220E40     ld ($400E), hl	:C
	:; sv DF_CC_lo

0934:C
0934 37         scf	:C
	:; Set Carry Flag

0935:C
0935 E0         ret po	:C
	:;
	:;

0936:C
0936 15         dec d	:C
	:;

0937:C
0937 C8         ret z	:C
	:;
	:;

0938:C
0938 C5         push bc	:C
	:;

0939:C
0939 CD9E09     call $099E	:C
	:; routine MAKE-ROOM

093C:C
093C C1         pop bc	:C
	:;

093D:C
093D 41         ld b, c	:C
	:;

093E:C
093E 62         ld h, d	:C
	:;

093F:C
093F 6B         ld l, e	:C
	:;
	:;

0940:C
	:#;; EXPAND-2
0940 3600       ld (hl), $00	:C EXPAND_2
	:;

0942:C
0942 2B         dec hl	:C
	:;

0943:C
0943 10FB       djnz $0940	:C
	:; to EXPAND-2
	:;

0945:C
0945 EB         ex de, hl	:C
	:;

0946:C
0946 23         inc hl	:C
	:;

0947:C
0947 220E40     ld ($400E), hl	:C
	:; sv DF_CC_lo

094A:C
094A C9         ret	:C
	:;
	:;

094B:C
	:#; ------------------------------
	:#; THE 'EXPAND TOKENS' SUBROUTINE
	:#; ------------------------------
	:#;
	:#;
	:#
	:#;; TOKENS
094B F5         push af	:C TOKENS
	:;

094C:C
094C CD7509     call $0975	:C
	:; routine TOKEN-ADD

094F:C
094F 3008       jr nc, $0959	:C
	:; to ALL-CHARS
	:;

0951:C
0951 FDCB0146   bit 0, (iy+$01)	:C
	:; sv FLAGS  - Leading space if set

0955:C
0955 2002       jr nz, $0959	:C
	:; to ALL-CHARS
	:;

0957:C
0957 AF         xor a	:C
	:;
	:;

0958:C
0958 D7         rst $10	:C
	:; PRINT-A
	:;

0959:C
	:#;; ALL-CHARS
0959 0A         ld a, (bc)	:C ALL_CHARS
	:;

095A:C
095A E63F       and $3F	:C
	:;
	:;

095C:C
095C D7         rst $10	:C
	:; PRINT-A

095D:C
095D 0A         ld a, (bc)	:C
	:;

095E:C
095E 03         inc bc	:C
	:;

095F:C
095F 87         add a, a	:C
	:;

0960:C
0960 30F7       jr nc, $0959	:C
	:; to ALL-CHARS
	:;

0962:C
0962 C1         pop bc	:C
	:;

0963:C
0963 CB78       bit 7, b	:C
	:;

0965:C
0965 C8         ret z	:C
	:;
	:;

0966:C
0966 FE1A       cp $1A	:C
	:;

0968:C
0968 2803       jr z, $096D	:C
	:; to TRAIL-SP
	:;

096A:C
096A FE38       cp $38	:C
	:;

096C:C
096C D8         ret c	:C
	:;
	:;

096D:C
	:#;; TRAIL-SP
096D AF         xor a	:C TRAIL_SP
	:;

096E:C
096E FDCB01C6   set 0, (iy+$01)	:C
	:; sv FLAGS  - Suppress leading space

0972:C
0972 C3F507     jp $07F5	:C
	:; to PRINT-SP
	:;

0975:C
	:#; ---
	:#
	:#;; TOKEN-ADD
0975 E5         push hl	:C TOKEN_ADD
	:;

0976:C
0976 211101     ld hl, $0111	:C
	:; Address of TOKENS

0979:C
0979 CB7F       bit 7, a	:C
	:;

097B:C
097B 2802       jr z, $097F	:C
	:; to TEST-HIGH
	:;

097D:C
097D E63F       and $3F	:C
	:;
	:;

097F:C
	:#;; TEST-HIGH
097F FE43       cp $43	:C TEST_HIGH
	:;

0981:C
0981 3010       jr nc, $0993	:C
	:; to FOUND
	:;

0983:C
0983 47         ld b, a	:C
	:;

0984:C
0984 04         inc b	:C
	:;
	:;

0985:C
	:#;; WORDS
0985 CB7E       bit 7, (hl)	:C WORDS
	:;

0987:C
0987 23         inc hl	:C
	:;

0988:C
0988 28FB       jr z, $0985	:C
	:; to WORDS
	:;

098A:C
098A 10F9       djnz $0985	:C
	:; to WORDS
	:;

098C:C
098C CB77       bit 6, a	:C
	:;

098E:C
098E 2002       jr nz, $0992	:C
	:; to COMP-FLAG
	:;

0990:C
0990 FE18       cp $18	:C
	:;
	:;

0992:C
	:#;; COMP-FLAG
0992 3F         ccf	:C COMP_FLAG
	:; Complement Carry Flag
	:;

0993:C
	:#;; FOUND
0993 44         ld b, h	:C FOUND
	:;

0994:C
0994 4D         ld c, l	:C
	:;

0995:C
0995 E1         pop hl	:C
	:;

0996:C
0996 D0         ret nc	:C
	:;
	:;

0997:C
0997 0A         ld a, (bc)	:C
	:;

0998:C
0998 C6E4       add a, $E4	:C
	:;

099A:C
099A C9         ret	:C
	:;
	:;

099B:C
	:#; --------------------------
	:#; THE 'ONE SPACE' SUBROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; ONE-SPACE
099B 010100     ld bc, $0001	:C ONE_SPACE
	:;
	:;

099E:C
	:#; --------------------------
	:#; THE 'MAKE ROOM' SUBROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; MAKE-ROOM
099E E5         push hl	:C MAKE_ROOM
	:;

099F:C
099F CDC50E     call $0EC5	:C
	:; routine TEST-ROOM

09A2:C
09A2 E1         pop hl	:C
	:;

09A3:C
09A3 CDAD09     call $09AD	:C
	:; routine POINTERS

09A6:C
09A6 2A1C40     ld hl, ($401C)	:C
	:; sv STKEND_lo

09A9:C
09A9 EB         ex de, hl	:C
	:;

09AA:C
09AA EDB8       lddr	:C
	:; Copy Bytes

09AC:C
09AC C9         ret	:C
	:;
	:;

09AD:C
	:#; -------------------------
	:#; THE 'POINTERS' SUBROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; POINTERS
09AD F5         push af	:C POINTERS
	:;

09AE:C
09AE E5         push hl	:C
	:;

09AF:C
09AF 210C40     ld hl, $400C	:C
	:; sv D_FILE_lo

09B2:C
09B2 3E09       ld a, $09	:C
	:;
	:;

09B4:C
	:#;; NEXT-PTR
09B4 5E         ld e, (hl)	:C NEXT_PTR
	:;

09B5:C
09B5 23         inc hl	:C
	:;

09B6:C
09B6 56         ld d, (hl)	:C
	:;

09B7:C
09B7 E3         ex (sp), hl	:C
	:;

09B8:C
09B8 A7         and a	:C
	:;

09B9:C
09B9 ED52       sbc hl, de	:C
	:;

09BB:C
09BB 19         add hl, de	:C
	:;

09BC:C
09BC E3         ex (sp), hl	:C
	:;

09BD:C
09BD 3009       jr nc, $09C8	:C
	:; to PTR-DONE
	:;

09BF:C
09BF D5         push de	:C
	:;

09C0:C
09C0 EB         ex de, hl	:C
	:;

09C1:C
09C1 09         add hl, bc	:C
	:;

09C2:C
09C2 EB         ex de, hl	:C
	:;

09C3:C
09C3 72         ld (hl), d	:C
	:;

09C4:C
09C4 2B         dec hl	:C
	:;

09C5:C
09C5 73         ld (hl), e	:C
	:;

09C6:C
09C6 23         inc hl	:C
	:;

09C7:C
09C7 D1         pop de	:C
	:;
	:;

09C8:C
	:#;; PTR-DONE
09C8 23         inc hl	:C PTR_DONE
	:;

09C9:C
09C9 3D         dec a	:C
	:;

09CA:C
09CA 20E8       jr nz, $09B4	:C
	:; to NEXT-PTR
	:;

09CC:C
09CC EB         ex de, hl	:C
	:;

09CD:C
09CD D1         pop de	:C
	:;

09CE:C
09CE F1         pop af	:C
	:;

09CF:C
09CF A7         and a	:C
	:;

09D0:C
09D0 ED52       sbc hl, de	:C
	:;

09D2:C
09D2 44         ld b, h	:C
	:;

09D3:C
09D3 4D         ld c, l	:C
	:;

09D4:C
09D4 03         inc bc	:C
	:;

09D5:C
09D5 19         add hl, de	:C
	:;

09D6:C
09D6 EB         ex de, hl	:C
	:;

09D7:C
09D7 C9         ret	:C
	:;
	:;

09D8:C
	:#; -----------------------------
	:#; THE 'LINE ADDRESS' SUBROUTINE
	:#; -----------------------------
	:#;
	:#;
	:#
	:#;; LINE-ADDR
09D8 E5         push hl	:C LINE_ADDR
	:;

09D9:C
09D9 217D40     ld hl, $407D	:C
	:;

09DC:C
09DC 54         ld d, h	:C
	:;

09DD:C
09DD 5D         ld e, l	:C
	:;
	:;

09DE:C
	:#;; NEXT-TEST
09DE C1         pop bc	:C NEXT_TEST
	:;

09DF:C
09DF CDEA09     call $09EA	:C
	:; routine CP-LINES

09E2:C
09E2 D0         ret nc	:C
	:;
	:;

09E3:C
09E3 C5         push bc	:C
	:;

09E4:C
09E4 CDF209     call $09F2	:C
	:; routine NEXT-ONE

09E7:C
09E7 EB         ex de, hl	:C
	:;

09E8:C
09E8 18F4       jr $09DE	:C
	:; to NEXT-TEST
	:;

09EA:C
	:#; -------------------------------------
	:#; THE 'COMPARE LINE NUMBERS' SUBROUTINE
	:#; -------------------------------------
	:#;
	:#;
	:#
	:#;; CP-LINES
09EA 7E         ld a, (hl)	:C CP_LINES
	:;

09EB:C
09EB B8         cp b	:C
	:;

09EC:C
09EC C0         ret nz	:C
	:;
	:;

09ED:C
09ED 23         inc hl	:C
	:;

09EE:C
09EE 7E         ld a, (hl)	:C
	:;

09EF:C
09EF 2B         dec hl	:C
	:;

09F0:C
09F0 B9         cp c	:C
	:;

09F1:C
09F1 C9         ret	:C
	:;
	:;

09F2:C
	:#; --------------------------------------
	:#; THE 'NEXT LINE OR VARIABLE' SUBROUTINE
	:#; --------------------------------------
	:#;
	:#;
	:#
	:#;; NEXT-ONE
09F2 E5         push hl	:C NEXT_ONE
	:;

09F3:C
09F3 7E         ld a, (hl)	:C
	:;

09F4:C
09F4 FE40       cp $40	:C
	:;

09F6:C
09F6 3817       jr c, $0A0F	:C
	:; to LINES
	:;

09F8:C
09F8 CB6F       bit 5, a	:C
	:;

09FA:C
09FA 2814       jr z, $0A10	:C
	:; forward to NEXT-O-4
	:;

09FC:C
09FC 87         add a, a	:C
	:;

09FD:C
09FD FA010A     jp m, $0A01	:C
	:; to NEXT+FIVE
	:;

0A00:C
0A00 3F         ccf	:C
	:; Complement Carry Flag
	:;

0A01:C
	:#;; NEXT+FIVE
0A01 010500     ld bc, $0005	:C NEXT_FIVE
	:;

0A04:C
0A04 3002       jr nc, $0A08	:C
	:; to NEXT-LETT
	:;

0A06:C
0A06 0E11       ld c, $11	:C
	:;
	:;

0A08:C
	:#;; NEXT-LETT
0A08 17         rla	:C NEXT_LETT
	:;

0A09:C
0A09 23         inc hl	:C
	:;

0A0A:C
0A0A 7E         ld a, (hl)	:C
	:;

0A0B:C
0A0B 30FB       jr nc, $0A08	:C
	:; to NEXT-LETT
	:;

0A0D:C
0A0D 1806       jr $0A15	:C
	:; to NEXT-ADD
	:;

0A0F:C
	:#; ---
	:#
	:#;; LINES
0A0F 23         inc hl	:C LINES
	:;
	:;

0A10:C
	:#;; NEXT-O-4
0A10 23         inc hl	:C NEXT_O_4
	:;

0A11:C
0A11 4E         ld c, (hl)	:C
	:;

0A12:C
0A12 23         inc hl	:C
	:;

0A13:C
0A13 46         ld b, (hl)	:C
	:;

0A14:C
0A14 23         inc hl	:C
	:;
	:;

0A15:C
	:#;; NEXT-ADD
0A15 09         add hl, bc	:C NEXT_ADD
	:;

0A16:C
0A16 D1         pop de	:C
	:;
	:;

0A17:C
	:#; ---------------------------
	:#; THE 'DIFFERENCE' SUBROUTINE
	:#; ---------------------------
	:#;
	:#;
	:#
	:#;; DIFFER
0A17 A7         and a	:C DIFFER
	:;

0A18:C
0A18 ED52       sbc hl, de	:C
	:;

0A1A:C
0A1A 44         ld b, h	:C
	:;

0A1B:C
0A1B 4D         ld c, l	:C
	:;

0A1C:C
0A1C 19         add hl, de	:C
	:;

0A1D:C
0A1D EB         ex de, hl	:C
	:;

0A1E:C
0A1E C9         ret	:C
	:;
	:;

0A1F:C
	:#; --------------------------
	:#; THE 'LINE-ENDS' SUBROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; LINE-ENDS
0A1F FD4622     ld b, (iy+$22)	:C LINE_ENDS
	:; sv DF_SZ

0A22:C
0A22 C5         push bc	:C
	:;

0A23:C
0A23 CD2C0A     call $0A2C	:C
	:; routine B-LINES

0A26:C
0A26 C1         pop bc	:C
	:;

0A27:C
0A27 05         dec b	:C
	:;

0A28:C
0A28 1802       jr $0A2C	:C
	:; to B-LINES
	:;

0A2A:C
	:#; -------------------------
	:#; THE 'CLS' COMMAND ROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; CLS
0A2A 0618       ld b, $18	:C CLS
	:;
	:;

0A2C:C
	:#;; B-LINES
0A2C FDCB018E   res 1, (iy+$01)	:C B_LINES
	:; sv FLAGS  - Signal printer not in use

0A30:C
0A30 0E21       ld c, $21	:C
	:;

0A32:C
0A32 C5         push bc	:C
	:;

0A33:C
0A33 CD1809     call $0918	:C
	:; routine LOC-ADDR

0A36:C
0A36 C1         pop bc	:C
	:;

0A37:C
0A37 3A0540     ld a, ($4005)	:C
	:; sv RAMTOP_hi

0A3A:C
0A3A FE4D       cp $4D	:C
	:;

0A3C:C
0A3C 3814       jr c, $0A52	:C
	:; to COLLAPSED
	:;

0A3E:C
0A3E FDCB3AFE   set 7, (iy+$3A)	:C
	:; sv S_POSN_y
	:;

0A42:C
	:#;; CLEAR-LOC
0A42 AF         xor a	:C CLEAR_LOC
	:; prepare a space

0A43:C
0A43 CDF507     call $07F5	:C
	:; routine PRINT-SP prints a space

0A46:C
0A46 2A3940     ld hl, ($4039)	:C
	:; sv S_POSN_x

0A49:C
0A49 7D         ld a, l	:C
	:;

0A4A:C
0A4A B4         or h	:C
	:;

0A4B:C
0A4B E67E       and $7E	:C
	:;

0A4D:C
0A4D 20F3       jr nz, $0A42	:C
	:; to CLEAR-LOC
	:;

0A4F:C
0A4F C31809     jp $0918	:C
	:; to LOC-ADDR
	:;

0A52:C
	:#; ---
	:#
	:#;; COLLAPSED
0A52 54         ld d, h	:C COLLAPSED
	:;

0A53:C
0A53 5D         ld e, l	:C
	:;

0A54:C
0A54 2B         dec hl	:C
	:;

0A55:C
0A55 48         ld c, b	:C
	:;

0A56:C
0A56 0600       ld b, $00	:C
	:;

0A58:C
0A58 EDB0       ldir	:C
	:; Copy Bytes

0A5A:C
0A5A 2A1040     ld hl, ($4010)	:C
	:; sv VARS_lo
	:;

0A5D:C
	:#; ----------------------------
	:#; THE 'RECLAIMING' SUBROUTINES
	:#; ----------------------------
	:#;
	:#;
	:#
	:#;; RECLAIM-1
0A5D CD170A     call $0A17	:C RECLAIM_1
	:; routine DIFFER
	:;

0A60:C
	:#;; RECLAIM-2
0A60 C5         push bc	:C RECLAIM_2
	:;

0A61:C
0A61 78         ld a, b	:C
	:;

0A62:C
0A62 2F         cpl	:C
	:;

0A63:C
0A63 47         ld b, a	:C
	:;

0A64:C
0A64 79         ld a, c	:C
	:;

0A65:C
0A65 2F         cpl	:C
	:;

0A66:C
0A66 4F         ld c, a	:C
	:;

0A67:C
0A67 03         inc bc	:C
	:;

0A68:C
0A68 CDAD09     call $09AD	:C
	:; routine POINTERS

0A6B:C
0A6B EB         ex de, hl	:C
	:;

0A6C:C
0A6C E1         pop hl	:C
	:;

0A6D:C
0A6D 19         add hl, de	:C
	:;

0A6E:C
0A6E D5         push de	:C
	:;

0A6F:C
0A6F EDB0       ldir	:C
	:; Copy Bytes

0A71:C
0A71 E1         pop hl	:C
	:;

0A72:C
0A72 C9         ret	:C
	:;
	:;

0A73:C
	:#; ------------------------------
	:#; THE 'E-LINE NUMBER' SUBROUTINE
	:#; ------------------------------
	:#;
	:#;
	:#
	:#;; E-LINE-NO
0A73 2A1440     ld hl, ($4014)	:C E_LINE_NO
	:; sv E_LINE_lo

0A76:C
0A76 CD4D00     call $004D	:C
	:; routine TEMP-PTR-2
	:;

0A79:C
0A79 DF         rst $18	:C
	:; GET-CHAR

0A7A:C
0A7A FDCB2D6E   bit 5, (iy+$2D)	:C
	:; sv FLAGX

0A7E:C
0A7E C0         ret nz	:C
	:;
	:;

0A7F:C
0A7F 215D40     ld hl, $405D	:C
	:; sv MEM-0-1st

0A82:C
0A82 221C40     ld ($401C), hl	:C
	:; sv STKEND_lo

0A85:C
0A85 CD4815     call $1548	:C
	:; routine INT-TO-FP

0A88:C
0A88 CD8A15     call $158A	:C
	:; routine FP-TO-BC

0A8B:C
0A8B 3804       jr c, $0A91	:C
	:; to NO-NUMBER
	:;

0A8D:C
0A8D 21F0D8     ld hl, $D8F0	:C
	:; value '-10000'

0A90:C
0A90 09         add hl, bc	:C
	:;
	:;

0A91:C
	:#;; NO-NUMBER
0A91 DA9A0D     jp c, $0D9A	:C NO_NUMBER
	:; to REPORT-C
	:;

0A94:C
0A94 BF         cp a	:C
	:;

0A95:C
0A95 C3BC14     jp $14BC	:C
	:; routine SET-MIN
	:;

0A98:C
	:#; -------------------------------------------------
	:#; THE 'REPORT AND LINE NUMBER' PRINTING SUBROUTINES
	:#; -------------------------------------------------
	:#;
	:#;
	:#
	:#;; OUT-NUM
0A98 D5         push de	:C OUT_NUM
	:;

0A99:C
0A99 E5         push hl	:C
	:;

0A9A:C
0A9A AF         xor a	:C
	:;

0A9B:C
0A9B CB78       bit 7, b	:C
	:;

0A9D:C
0A9D 2020       jr nz, $0ABF	:C
	:; to UNITS
	:;

0A9F:C
0A9F 60         ld h, b	:C
	:;

0AA0:C
0AA0 69         ld l, c	:C
	:;

0AA1:C
0AA1 1EFF       ld e, $FF	:C
	:;

0AA3:C
0AA3 1808       jr $0AAD	:C
	:; to THOUSAND
	:;

0AA5:C
	:#; ---
	:#
	:#;; OUT-NO
0AA5 D5         push de	:C OUT_NO
	:;

0AA6:C
0AA6 56         ld d, (hl)	:C
	:;

0AA7:C
0AA7 23         inc hl	:C
	:;

0AA8:C
0AA8 5E         ld e, (hl)	:C
	:;

0AA9:C
0AA9 E5         push hl	:C
	:;

0AAA:C
0AAA EB         ex de, hl	:C
	:;

0AAB:C
0AAB 1E00       ld e, $00	:C
	:; set E to leading space.
	:;

0AAD:C
	:#;; THOUSAND
0AAD 0118FC     ld bc, $FC18	:C THOUSAND
	:;

0AB0:C
0AB0 CDE107     call $07E1	:C
	:; routine OUT-DIGIT

0AB3:C
0AB3 019CFF     ld bc, $FF9C	:C
	:;

0AB6:C
0AB6 CDE107     call $07E1	:C
	:; routine OUT-DIGIT

0AB9:C
0AB9 0EF6       ld c, $F6	:C
	:;

0ABB:C
0ABB CDE107     call $07E1	:C
	:; routine OUT-DIGIT

0ABE:C
0ABE 7D         ld a, l	:C
	:;
	:;

0ABF:C
	:#;; UNITS
0ABF CDEB07     call $07EB	:C UNITS
	:; routine OUT-CODE

0AC2:C
0AC2 E1         pop hl	:C
	:;

0AC3:C
0AC3 D1         pop de	:C
	:;

0AC4:C
0AC4 C9         ret	:C
	:;
	:;

0AC5:C
	:#; --------------------------
	:#; THE 'UNSTACK-Z' SUBROUTINE
	:#; --------------------------
	:#; This subroutine is used to return early from a routine when checking syntax.
	:#; On the ZX81 the same routines that execute commands also check the syntax
	:#; on line entry. This enables precise placement of the error marker in a line
	:#; that fails syntax.
	:#; The sequence CALL SYNTAX-Z ; RET Z can be replaced by a call to this routine
	:#; although it has not replaced every occurrence of the above two instructions.
	:#; Even on the ZX-80 this routine was not fully utilized.
	:#
	:#;; UNSTACK-Z
0AC5 CDA60D     call $0DA6	:C UNSTACK_Z
	:; routine SYNTAX-Z resets the ZERO flag if
	:; checking syntax.

0AC8:C
0AC8 E1         pop hl	:C
	:; drop the return address.

0AC9:C
0AC9 C8         ret z	:C
	:; return to previous calling routine if 
	:; checking syntax.
	:;

0ACA:C
0ACA E9         jp (hl)	:C
	:; else jump to the continuation address in
	:; the calling routine as RET would have done.
	:;

0ACB:C
	:#; ----------------------------
	:#; THE 'LPRINT' COMMAND ROUTINE
	:#; ----------------------------
	:#;
	:#;
	:#
	:#;; LPRINT
0ACB FDCB01CE   set 1, (iy+$01)	:C LPRINT
	:; sv FLAGS  - Signal printer in use
	:;

0ACF:C
	:#; ---------------------------
	:#; THE 'PRINT' COMMAND ROUTINE
	:#; ---------------------------
	:#;
	:#;
	:#
	:#;; PRINT
0ACF 7E         ld a, (hl)	:C PRINT
	:;

0AD0:C
0AD0 FE76       cp $76	:C
	:;

0AD2:C
0AD2 CA840B     jp z, $0B84	:C
	:; to PRINT-END
	:;

0AD5:C
	:#;; PRINT-1
0AD5 D61A       sub $1A	:C PRINT_1
	:;

0AD7:C
0AD7 CE00       adc a, $00	:C
	:;

0AD9:C
0AD9 2869       jr z, $0B44	:C
	:; to SPACING
	:;

0ADB:C
0ADB FEA7       cp $A7	:C
	:;

0ADD:C
0ADD 201B       jr nz, $0AFA	:C
	:; to NOT-AT
	:;
	:;

0ADF:C
0ADF E7         rst $20	:C
	:; NEXT-CHAR

0AE0:C
0AE0 CD920D     call $0D92	:C
	:; routine CLASS-6

0AE3:C
0AE3 FE1A       cp $1A	:C
	:;

0AE5:C
0AE5 C29A0D     jp nz, $0D9A	:C
	:; to REPORT-C
	:;
	:;

0AE8:C
0AE8 E7         rst $20	:C
	:; NEXT-CHAR

0AE9:C
0AE9 CD920D     call $0D92	:C
	:; routine CLASS-6

0AEC:C
0AEC CD4E0B     call $0B4E	:C
	:; routine SYNTAX-ON
	:;

0AEF:C
0AEF EF         rst $28	:C
	:;; FP-CALC

0AF0:B
0AF0-0AF0 01	:B
	:;;exchange

0AF1:B
0AF1-0AF1 34	:B
	:;;end-calc
	:;

0AF2:C
0AF2 CDF50B     call $0BF5	:C
	:; routine STK-TO-BC

0AF5:C
0AF5 CDF508     call $08F5	:C
	:; routine PRINT-AT

0AF8:C
0AF8 183D       jr $0B37	:C
	:; to PRINT-ON
	:;

0AFA:C
	:#; ---
	:#
	:#;; NOT-AT
0AFA FEA8       cp $A8	:C NOT_AT
	:;

0AFC:C
0AFC 2033       jr nz, $0B31	:C
	:; to NOT-TAB
	:;
	:;

0AFE:C
0AFE E7         rst $20	:C
	:; NEXT-CHAR

0AFF:C
0AFF CD920D     call $0D92	:C
	:; routine CLASS-6

0B02:C
0B02 CD4E0B     call $0B4E	:C
	:; routine SYNTAX-ON

0B05:C
0B05 CD020C     call $0C02	:C
	:; routine STK-TO-A

0B08:C
0B08 C2AD0E     jp nz, $0EAD	:C
	:; to REPORT-B
	:;

0B0B:C
0B0B E61F       and $1F	:C
	:;

0B0D:C
0B0D 4F         ld c, a	:C
	:;

0B0E:C
0B0E FDCB014E   bit 1, (iy+$01)	:C
	:; sv FLAGS  - Is printer in use

0B12:C
0B12 280A       jr z, $0B1E	:C
	:; to TAB-TEST
	:;

0B14:C
0B14 FD9638     sub (iy+$38)	:C
	:; sv PR_CC

0B17:C
0B17 CBFF       set 7, a	:C
	:;

0B19:C
0B19 C63C       add a, $3C	:C
	:;

0B1B:C
0B1B D47108     call nc, $0871	:C
	:; routine COPY-BUFF
	:;

0B1E:C
	:#;; TAB-TEST
0B1E FD8639     add a, (iy+$39)	:C TAB_TEST
	:; sv S_POSN_x

0B21:C
0B21 FE21       cp $21	:C
	:;

0B23:C
0B23 3A3A40     ld a, ($403A)	:C
	:; sv S_POSN_y

0B26:C
0B26 DE01       sbc a, $01	:C
	:;

0B28:C
0B28 CDFA08     call $08FA	:C
	:; routine TEST-VAL

0B2B:C
0B2B FDCB01C6   set 0, (iy+$01)	:C
	:; sv FLAGS  - Suppress leading space

0B2F:C
0B2F 1806       jr $0B37	:C
	:; to PRINT-ON
	:;

0B31:C
	:#; ---
	:#
	:#;; NOT-TAB
0B31 CD550F     call $0F55	:C NOT_TAB
	:; routine SCANNING

0B34:C
0B34 CD550B     call $0B55	:C
	:; routine PRINT-STK
	:;

0B37:C
	:#;; PRINT-ON
0B37 DF         rst $18	:C PRINT_ON
	:; GET-CHAR

0B38:C
0B38 D61A       sub $1A	:C
	:;

0B3A:C
0B3A CE00       adc a, $00	:C
	:;

0B3C:C
0B3C 2806       jr z, $0B44	:C
	:; to SPACING
	:;

0B3E:C
0B3E CD1D0D     call $0D1D	:C
	:; routine CHECK-END

0B41:C
0B41 C3840B     jp $0B84	:C
	:;;; to PRINT-END
	:;

0B44:C
	:#; ---
	:#
	:#;; SPACING
0B44 D48B0B     call nc, $0B8B	:C SPACING
	:; routine FIELD
	:;

0B47:C
0B47 E7         rst $20	:C
	:; NEXT-CHAR

0B48:C
0B48 FE76       cp $76	:C
	:;

0B4A:C
0B4A C8         ret z	:C
	:;
	:;

0B4B:C
0B4B C3D50A     jp $0AD5	:C
	:;;; to PRINT-1
	:;

0B4E:C
	:#; ---
	:#
	:#;; SYNTAX-ON
0B4E CDA60D     call $0DA6	:C SYNTAX_ON
	:; routine SYNTAX-Z

0B51:C
0B51 C0         ret nz	:C
	:;
	:;

0B52:C
0B52 E1         pop hl	:C
	:;

0B53:C
0B53 18E2       jr $0B37	:C
	:; to PRINT-ON
	:;

0B55:C
	:#; ---
	:#
	:#;; PRINT-STK
0B55 CDC50A     call $0AC5	:C PRINT_STK
	:; routine UNSTACK-Z

0B58:C
0B58 FDCB0176   bit 6, (iy+$01)	:C
	:; sv FLAGS  - Numeric or string result?

0B5C:C
0B5C CCF813     call z, $13F8	:C
	:; routine STK-FETCH

0B5F:C
0B5F 280A       jr z, $0B6B	:C
	:; to PR-STR-4
	:;

0B61:C
0B61 C3DB15     jp $15DB	:C
	:; jump forward to PRINT-FP
	:;

0B64:C
	:#; ---
	:#
	:#;; PR-STR-1
0B64 3E0B       ld a, $0B	:C PR_STR_1
	:;
	:;

0B66:C
	:#;; PR-STR-2
0B66 D7         rst $10	:C PR_STR_2
	:; PRINT-A
	:;

0B67:C
	:#;; PR-STR-3
0B67 ED5B1840   ld de, ($4018)	:C PR_STR_3
	:; sv X_PTR_lo
	:;

0B6B:C
	:#;; PR-STR-4
0B6B 78         ld a, b	:C PR_STR_4
	:;

0B6C:C
0B6C B1         or c	:C
	:;

0B6D:C
0B6D 0B         dec bc	:C
	:;

0B6E:C
0B6E C8         ret z	:C
	:;
	:;

0B6F:C
0B6F 1A         ld a, (de)	:C
	:;

0B70:C
0B70 13         inc de	:C
	:;

0B71:C
0B71 ED531840   ld ($4018), de	:C
	:; sv X_PTR_lo

0B75:C
0B75 CB77       bit 6, a	:C
	:;

0B77:C
0B77 28ED       jr z, $0B66	:C
	:; to PR-STR-2
	:;

0B79:C
0B79 FEC0       cp $C0	:C
	:;

0B7B:C
0B7B 28E7       jr z, $0B64	:C
	:; to PR-STR-1
	:;

0B7D:C
0B7D C5         push bc	:C
	:;

0B7E:C
0B7E CD4B09     call $094B	:C
	:; routine TOKENS

0B81:C
0B81 C1         pop bc	:C
	:;

0B82:C
0B82 18E3       jr $0B67	:C
	:; to PR-STR-3
	:;

0B84:C
	:#; ---
	:#
	:#;; PRINT-END
0B84 CDC50A     call $0AC5	:C PRINT_END
	:; routine UNSTACK-Z

0B87:C
0B87 3E76       ld a, $76	:C
	:;
	:;

0B89:C
0B89 D7         rst $10	:C
	:; PRINT-A

0B8A:C
0B8A C9         ret	:C
	:;
	:;

0B8B:C
	:#; ---
	:#
	:#;; FIELD
0B8B CDC50A     call $0AC5	:C FIELD
	:; routine UNSTACK-Z

0B8E:C
0B8E FDCB01C6   set 0, (iy+$01)	:C
	:; sv FLAGS  - Suppress leading space

0B92:C
0B92 AF         xor a	:C
	:;
	:;

0B93:C
0B93 D7         rst $10	:C
	:; PRINT-A

0B94:C
0B94 ED4B3940   ld bc, ($4039)	:C
	:; sv S_POSN_x

0B98:C
0B98 79         ld a, c	:C
	:;

0B99:C
0B99 FDCB014E   bit 1, (iy+$01)	:C
	:; sv FLAGS  - Is printer in use

0B9D:C
0B9D 2805       jr z, $0BA4	:C
	:; to CENTRE
	:;

0B9F:C
0B9F 3E5D       ld a, $5D	:C
	:;

0BA1:C
0BA1 FD9638     sub (iy+$38)	:C
	:; sv PR_CC
	:;

0BA4:C
	:#;; CENTRE
0BA4 0E11       ld c, $11	:C CENTRE
	:;

0BA6:C
0BA6 B9         cp c	:C
	:;

0BA7:C
0BA7 3002       jr nc, $0BAB	:C
	:; to RIGHT
	:;

0BA9:C
0BA9 0E01       ld c, $01	:C
	:;
	:;

0BAB:C
	:#;; RIGHT
0BAB CD0B09     call $090B	:C RIGHT
	:; routine SET-FIELD

0BAE:C
0BAE C9         ret	:C
	:;
	:;

0BAF:C
	:#; --------------------------------------
	:#; THE 'PLOT AND UNPLOT' COMMAND ROUTINES
	:#; --------------------------------------
	:#;
	:#;
	:#
	:#;; PLOT/UNP
0BAF CDF50B     call $0BF5	:C PLOT_UNP
	:; routine STK-TO-BC

0BB2:C
0BB2 ED433640   ld ($4036), bc	:C
	:; sv COORDS_x

0BB6:C
0BB6 3E2B       ld a, $2B	:C
	:;

0BB8:C
0BB8 90         sub b	:C
	:;

0BB9:C
0BB9 DAAD0E     jp c, $0EAD	:C
	:; to REPORT-B
	:;

0BBC:C
0BBC 47         ld b, a	:C
	:;

0BBD:C
0BBD 3E01       ld a, $01	:C
	:;

0BBF:C
0BBF CB28       sra b	:C
	:;

0BC1:C
0BC1 3002       jr nc, $0BC5	:C
	:; to COLUMNS
	:;

0BC3:C
0BC3 3E04       ld a, $04	:C
	:;
	:;

0BC5:C
	:#;; COLUMNS
0BC5 CB29       sra c	:C COLUMNS
	:;

0BC7:C
0BC7 3001       jr nc, $0BCA	:C
	:; to FIND-ADDR
	:;

0BC9:C
0BC9 07         rlca	:C
	:;
	:;

0BCA:C
	:#;; FIND-ADDR
0BCA F5         push af	:C FIND_ADDR
	:;

0BCB:C
0BCB CDF508     call $08F5	:C
	:; routine PRINT-AT

0BCE:C
0BCE 7E         ld a, (hl)	:C
	:;

0BCF:C
0BCF 07         rlca	:C
	:;

0BD0:C
0BD0 FE10       cp $10	:C
	:;

0BD2:C
0BD2 3006       jr nc, $0BDA	:C
	:; to TABLE-PTR
	:;

0BD4:C
0BD4 0F         rrca	:C
	:;

0BD5:C
0BD5 3002       jr nc, $0BD9	:C
	:; to SQ-SAVED
	:;

0BD7:C
0BD7 EE8F       xor $8F	:C
	:;
	:;

0BD9:C
	:#;; SQ-SAVED
0BD9 47         ld b, a	:C SQ_SAVED
	:;
	:;

0BDA:C
	:#;; TABLE-PTR
0BDA 119E0C     ld de, $0C9E	:C TABLE_PTR
	:; Address: P-UNPLOT

0BDD:C
0BDD 3A3040     ld a, ($4030)	:C
	:; sv T_ADDR_lo

0BE0:C
0BE0 93         sub e	:C
	:;

0BE1:C
0BE1 FAE90B     jp m, $0BE9	:C
	:; to PLOT
	:;

0BE4:C
0BE4 F1         pop af	:C
	:;

0BE5:C
0BE5 2F         cpl	:C
	:;

0BE6:C
0BE6 A0         and b	:C
	:;

0BE7:C
0BE7 1802       jr $0BEB	:C
	:; to UNPLOT
	:;

0BE9:C
	:#; ---
	:#
	:#;; PLOT
0BE9 F1         pop af	:C PLOT
	:;

0BEA:C
0BEA B0         or b	:C
	:;
	:;

0BEB:C
	:#;; UNPLOT
0BEB FE08       cp $08	:C UNPLOT
	:;

0BED:C
0BED 3802       jr c, $0BF1	:C
	:; to PLOT-END
	:;

0BEF:C
0BEF EE8F       xor $8F	:C
	:;
	:;

0BF1:C
	:#;; PLOT-END
0BF1 D9         exx	:C PLOT_END
	:;
	:;

0BF2:C
0BF2 D7         rst $10	:C
	:; PRINT-A

0BF3:C
0BF3 D9         exx	:C
	:;

0BF4:C
0BF4 C9         ret	:C
	:;
	:;

0BF5:C
	:#; ----------------------------
	:#; THE 'STACK-TO-BC' SUBROUTINE
	:#; ----------------------------
	:#;
	:#;
	:#
	:#;; STK-TO-BC
0BF5 CD020C     call $0C02	:C STK_TO_BC
	:; routine STK-TO-A

0BF8:C
0BF8 47         ld b, a	:C
	:;

0BF9:C
0BF9 C5         push bc	:C
	:;

0BFA:C
0BFA CD020C     call $0C02	:C
	:; routine STK-TO-A

0BFD:C
0BFD 59         ld e, c	:C
	:;

0BFE:C
0BFE C1         pop bc	:C
	:;

0BFF:C
0BFF 51         ld d, c	:C
	:;

0C00:C
0C00 4F         ld c, a	:C
	:;

0C01:C
0C01 C9         ret	:C
	:;
	:;

0C02:C
	:#; ---------------------------
	:#; THE 'STACK-TO-A' SUBROUTINE
	:#; ---------------------------
	:#;
	:#;
	:#
	:#;; STK-TO-A
0C02 CDCD15     call $15CD	:C STK_TO_A
	:; routine FP-TO-A

0C05:C
0C05 DAAD0E     jp c, $0EAD	:C
	:; to REPORT-B
	:;

0C08:C
0C08 0E01       ld c, $01	:C
	:;

0C0A:C
0C0A C8         ret z	:C
	:;
	:;

0C0B:C
0C0B 0EFF       ld c, $FF	:C
	:;

0C0D:C
0C0D C9         ret	:C
	:;
	:;

0C0E:C
	:#; -----------------------
	:#; THE 'SCROLL' SUBROUTINE
	:#; -----------------------
	:#;
	:#;
	:#
	:#;; SCROLL
0C0E FD4622     ld b, (iy+$22)	:C SCROLL
	:; sv DF_SZ

0C11:C
0C11 0E21       ld c, $21	:C
	:;

0C13:C
0C13 CD1809     call $0918	:C
	:; routine LOC-ADDR

0C16:C
0C16 CD9B09     call $099B	:C
	:; routine ONE-SPACE

0C19:C
0C19 7E         ld a, (hl)	:C
	:;

0C1A:C
0C1A 12         ld (de), a	:C
	:;

0C1B:C
0C1B FD343A     inc (iy+$3A)	:C
	:; sv S_POSN_y

0C1E:C
0C1E 2A0C40     ld hl, ($400C)	:C
	:; sv D_FILE_lo

0C21:C
0C21 23         inc hl	:C
	:;

0C22:C
0C22 54         ld d, h	:C
	:;

0C23:C
0C23 5D         ld e, l	:C
	:;

0C24:C
0C24 EDB1       cpir	:C
	:;

0C26:C
0C26 C35D0A     jp $0A5D	:C
	:; to RECLAIM-1
	:;

0C29:B
	:#; -------------------
	:#; THE 'SYNTAX' TABLES
	:#; -------------------
	:#
	:#; i) The Offset table
	:#
	:#;; offset-t
0C29-0C29 8B	:B offset_t
	:; 8B offset to; Address: P-LPRINT

0C2A:B
0C2A-0C2A 8D	:B
	:; 8D offset to; Address: P-LLIST

0C2B:B
0C2B-0C2B 2D	:B
	:; 2D offset to; Address: P-STOP

0C2C:B
0C2C-0C2C 7F	:B
	:; 7F offset to; Address: P-SLOW

0C2D:B
0C2D-0C2D 81	:B
	:; 81 offset to; Address: P-FAST

0C2E:B
0C2E-0C2E 49	:B
	:; 49 offset to; Address: P-NEW

0C2F:B
0C2F-0C2F 75	:B
	:; 75 offset to; Address: P-SCROLL

0C30:B
0C30-0C30 5F	:B
	:; 5F offset to; Address: P-CONT

0C31:B
0C31-0C31 40	:B
	:; 40 offset to; Address: P-DIM

0C32:B
0C32-0C32 42	:B
	:; 42 offset to; Address: P-REM

0C33:B
0C33-0C33 2B	:B
	:; 2B offset to; Address: P-FOR

0C34:B
0C34-0C34 17	:B
	:; 17 offset to; Address: P-GOTO

0C35:B
0C35-0C35 1F	:B
	:; 1F offset to; Address: P-GOSUB

0C36:B
0C36-0C36 37	:B
	:; 37 offset to; Address: P-INPUT

0C37:B
0C37-0C37 52	:B
	:; 52 offset to; Address: P-LOAD

0C38:B
0C38-0C38 45	:B
	:; 45 offset to; Address: P-LIST

0C39:B
0C39-0C39 0F	:B
	:; 0F offset to; Address: P-LET

0C3A:B
0C3A-0C3A 6D	:B
	:; 6D offset to; Address: P-PAUSE

0C3B:B
0C3B-0C3B 2B	:B
	:; 2B offset to; Address: P-NEXT

0C3C:B
0C3C-0C3C 44	:B
	:; 44 offset to; Address: P-POKE

0C3D:B
0C3D-0C3D 2D	:B
	:; 2D offset to; Address: P-PRINT

0C3E:B
0C3E-0C3E 5A	:B
	:; 5A offset to; Address: P-PLOT

0C3F:B
0C3F-0C3F 3B	:B
	:; 3B offset to; Address: P-RUN

0C40:B
0C40-0C40 4C	:B
	:; 4C offset to; Address: P-SAVE

0C41:B
0C41-0C41 45	:B
	:; 45 offset to; Address: P-RAND

0C42:B
0C42-0C42 0D	:B
	:; 0D offset to; Address: P-IF

0C43:B
0C43-0C43 52	:B
	:; 52 offset to; Address: P-CLS

0C44:B
0C44-0C44 5A	:B
	:; 5A offset to; Address: P-UNPLOT

0C45:B
0C45-0C45 4D	:B
	:; 4D offset to; Address: P-CLEAR

0C46:B
0C46-0C46 15	:B
	:; 15 offset to; Address: P-RETURN

0C47:B
0C47-0C47 6A	:B
	:; 6A offset to; Address: P-COPY
	:;

0C48:B
	:#; ii) The parameter table.
	:#
	:#
	:#;; P-LET
0C48-0C48 01	:B P_LET
	:; Class-01 - A variable is required.

0C49:B
0C49-0C49 14	:B
	:; Separator:  '='

0C4A:B
0C4A-0C4A 02	:B
	:; Class-02 - An expression, numeric or string,
	:; must follow.
	:;

0C4B:B
	:#;; P-GOTO
0C4B-0C4B 06	:B P_GOTO
	:; Class-06 - A numeric expression must follow.

0C4C:B
0C4C-0C4C 00	:B
	:; Class-00 - No further operands.

0C4D:W
0C4D-0C4E 810E	:W
	:; Address: $0E81; Address: GOTO
	:;

0C4F:B
	:#;; P-IF
0C4F-0C4F 06	:B P_IF
	:; Class-06 - A numeric expression must follow.

0C50:B
0C50-0C50 DE	:B
	:; Separator:  'THEN'

0C51:B
0C51-0C51 05	:B
	:; Class-05 - Variable syntax checked entirely
	:; by routine.

0C52:W
0C52-0C53 AB0D	:W
	:; Address: $0DAB; Address: IF
	:;

0C54:B
	:#;; P-GOSUB
0C54-0C54 06	:B P_GOSUB
	:; Class-06 - A numeric expression must follow.

0C55:B
0C55-0C55 00	:B
	:; Class-00 - No further operands.

0C56:W
0C56-0C57 B50E	:W
	:; Address: $0EB5; Address: GOSUB
	:;

0C58:B
	:#;; P-STOP
0C58-0C58 00	:B P_STOP
	:; Class-00 - No further operands.

0C59:W
0C59-0C5A DC0C	:W
	:; Address: $0CDC; Address: STOP
	:;

0C5B:B
	:#;; P-RETURN
0C5B-0C5B 00	:B P_RETURN
	:; Class-00 - No further operands.

0C5C:W
0C5C-0C5D D80E	:W
	:; Address: $0ED8; Address: RETURN
	:;

0C5E:B
	:#;; P-FOR
0C5E-0C5E 04	:B P_FOR
	:; Class-04 - A single character variable must
	:; follow.

0C5F:B
0C5F-0C5F 14	:B
	:; Separator:  '='

0C60:B
0C60-0C60 06	:B
	:; Class-06 - A numeric expression must follow.

0C61:B
0C61-0C61 DF	:B
	:; Separator:  'TO'

0C62:B
0C62-0C62 06	:B
	:; Class-06 - A numeric expression must follow.

0C63:B
0C63-0C63 05	:B
	:; Class-05 - Variable syntax checked entirely
	:; by routine.

0C64:W
0C64-0C65 B90D	:W
	:; Address: $0DB9; Address: FOR
	:;

0C66:B
	:#;; P-NEXT
0C66-0C66 04	:B P_NEXT
	:; Class-04 - A single character variable must
	:; follow.

0C67:B
0C67-0C67 00	:B
	:; Class-00 - No further operands.

0C68:W
0C68-0C69 2E0E	:W
	:; Address: $0E2E; Address: NEXT
	:;

0C6A:B
	:#;; P-PRINT
0C6A-0C6A 05	:B P_PRINT
	:; Class-05 - Variable syntax checked entirely
	:; by routine.

0C6B:W
0C6B-0C6C CF0A	:W
	:; Address: $0ACF; Address: PRINT
	:;

0C6D:B
	:#;; P-INPUT
0C6D-0C6D 01	:B P_INPUT
	:; Class-01 - A variable is required.

0C6E:B
0C6E-0C6E 00	:B
	:; Class-00 - No further operands.

0C6F:W
0C6F-0C70 E90E	:W
	:; Address: $0EE9; Address: INPUT
	:;

0C71:B
	:#;; P-DIM
0C71-0C71 05	:B P_DIM
	:; Class-05 - Variable syntax checked entirely
	:; by routine.

0C72:W
0C72-0C73 0914	:W
	:; Address: $1409; Address: DIM
	:;

0C74:B
	:#;; P-REM
0C74-0C74 05	:B P_REM
	:; Class-05 - Variable syntax checked entirely
	:; by routine.

0C75:W
0C75-0C76 6A0D	:W
	:; Address: $0D6A; Address: REM
	:;

0C77:B
	:#;; P-NEW
0C77-0C77 00	:B P_NEW
	:; Class-00 - No further operands.

0C78:W
0C78-0C79 C303	:W
	:; Address: $03C3; Address: NEW
	:;

0C7A:B
	:#;; P-RUN
0C7A-0C7A 03	:B P_RUN
	:; Class-03 - A numeric expression may follow
	:; else default to zero.

0C7B:W
0C7B-0C7C AF0E	:W
	:; Address: $0EAF; Address: RUN
	:;

0C7D:B
	:#;; P-LIST
0C7D-0C7D 03	:B P_LIST
	:; Class-03 - A numeric expression may follow
	:; else default to zero.

0C7E:W
0C7E-0C7F 3007	:W
	:; Address: $0730; Address: LIST
	:;

0C80:B
	:#;; P-POKE
0C80-0C80 06	:B P_POKE
	:; Class-06 - A numeric expression must follow.

0C81:B
0C81-0C81 1A	:B
	:; Separator:  ','

0C82:B
0C82-0C82 06	:B
	:; Class-06 - A numeric expression must follow.

0C83:B
0C83-0C83 00	:B
	:; Class-00 - No further operands.

0C84:W
0C84-0C85 920E	:W
	:; Address: $0E92; Address: POKE
	:;

0C86:B
	:#;; P-RAND
0C86-0C86 03	:B P_RAND
	:; Class-03 - A numeric expression may follow
	:; else default to zero.

0C87:W
0C87-0C88 6C0E	:W
	:; Address: $0E6C; Address: RAND
	:;

0C89:B
	:#;; P-LOAD
0C89-0C89 05	:B P_LOAD
	:; Class-05 - Variable syntax checked entirely
	:; by routine.

0C8A:W
0C8A-0C8B 4003	:W
	:; Address: $0340; Address: LOAD
	:;

0C8C:B
	:#;; P-SAVE
0C8C-0C8C 05	:B P_SAVE
	:; Class-05 - Variable syntax checked entirely
	:; by routine.

0C8D:W
0C8D-0C8E F602	:W
	:; Address: $02F6; Address: SAVE
	:;

0C8F:B
	:#;; P-CONT
0C8F-0C8F 00	:B P_CONT
	:; Class-00 - No further operands.

0C90:W
0C90-0C91 7C0E	:W
	:; Address: $0E7C; Address: CONT
	:;

0C92:B
	:#;; P-CLEAR
0C92-0C92 00	:B P_CLEAR
	:; Class-00 - No further operands.

0C93:W
0C93-0C94 9A14	:W
	:; Address: $149A; Address: CLEAR
	:;

0C95:B
	:#;; P-CLS
0C95-0C95 00	:B P_CLS
	:; Class-00 - No further operands.

0C96:W
0C96-0C97 2A0A	:W
	:; Address: $0A2A; Address: CLS
	:;

0C98:B
	:#;; P-PLOT
0C98-0C98 06	:B P_PLOT
	:; Class-06 - A numeric expression must follow.

0C99:B
0C99-0C99 1A	:B
	:; Separator:  ','

0C9A:B
0C9A-0C9A 06	:B
	:; Class-06 - A numeric expression must follow.

0C9B:B
0C9B-0C9B 00	:B
	:; Class-00 - No further operands.

0C9C:W
0C9C-0C9D AF0B	:W
	:; Address: $0BAF; Address: PLOT/UNP
	:;

0C9E:B
	:#;; P-UNPLOT
0C9E-0C9E 06	:B P_UNPLOT
	:; Class-06 - A numeric expression must follow.

0C9F:B
0C9F-0C9F 1A	:B
	:; Separator:  ','

0CA0:B
0CA0-0CA0 06	:B
	:; Class-06 - A numeric expression must follow.

0CA1:B
0CA1-0CA1 00	:B
	:; Class-00 - No further operands.

0CA2:W
0CA2-0CA3 AF0B	:W
	:; Address: $0BAF; Address: PLOT/UNP
	:;

0CA4:B
	:#;; P-SCROLL
0CA4-0CA4 00	:B P_SCROLL
	:; Class-00 - No further operands.

0CA5:W
0CA5-0CA6 0E0C	:W
	:; Address: $0C0E; Address: SCROLL
	:;

0CA7:B
	:#;; P-PAUSE
0CA7-0CA7 06	:B P_PAUSE
	:; Class-06 - A numeric expression must follow.

0CA8:B
0CA8-0CA8 00	:B
	:; Class-00 - No further operands.

0CA9:W
0CA9-0CAA 320F	:W
	:; Address: $0F32; Address: PAUSE
	:;

0CAB:B
	:#;; P-SLOW
0CAB-0CAB 00	:B P_SLOW
	:; Class-00 - No further operands.

0CAC:W
0CAC-0CAD 2B0F	:W
	:; Address: $0F2B; Address: SLOW
	:;

0CAE:B
	:#;; P-FAST
0CAE-0CAE 00	:B P_FAST
	:; Class-00 - No further operands.

0CAF:W
0CAF-0CB0 230F	:W
	:; Address: $0F23; Address: FAST
	:;

0CB1:B
	:#;; P-COPY
0CB1-0CB1 00	:B P_COPY
	:; Class-00 - No further operands.

0CB2:W
0CB2-0CB3 6908	:W
	:; Address: $0869; Address: COPY
	:;

0CB4:B
	:#;; P-LPRINT
0CB4-0CB4 05	:B P_LPRINT
	:; Class-05 - Variable syntax checked entirely
	:; by routine.

0CB5:W
0CB5-0CB6 CB0A	:W
	:; Address: $0ACB; Address: LPRINT
	:;

0CB7:B
	:#;; P-LLIST
0CB7-0CB7 03	:B P_LLIST
	:; Class-03 - A numeric expression may follow
	:; else default to zero.

0CB8:W
0CB8-0CB9 2C07	:W
	:; Address: $072C; Address: LLIST
	:;
	:;

0CBA:C
	:#; ---------------------------
	:#; THE 'LINE SCANNING' ROUTINE
	:#; ---------------------------
	:#;
	:#;
	:#
	:#;; LINE-SCAN
0CBA FD360101   ld (iy+$01), $01	:C LINE_SCAN
	:; sv FLAGS

0CBE:C
0CBE CD730A     call $0A73	:C
	:; routine E-LINE-NO
	:;

0CC1:C
	:#;; LINE-RUN
0CC1 CDBC14     call $14BC	:C LINE_RUN
	:; routine SET-MIN

0CC4:C
0CC4 210040     ld hl, $4000	:C
	:; sv ERR_NR

0CC7:C
0CC7 36FF       ld (hl), $FF	:C
	:;

0CC9:C
0CC9 212D40     ld hl, $402D	:C
	:; sv FLAGX

0CCC:C
0CCC CB6E       bit 5, (hl)	:C
	:;

0CCE:C
0CCE 280E       jr z, $0CDE	:C
	:; to LINE-NULL
	:;

0CD0:C
0CD0 FEE3       cp $E3	:C
	:; 'STOP' ?

0CD2:C
0CD2 7E         ld a, (hl)	:C
	:;

0CD3:C
0CD3 C26F0D     jp nz, $0D6F	:C
	:; to INPUT-REP
	:;

0CD6:C
0CD6 CDA60D     call $0DA6	:C
	:; routine SYNTAX-Z

0CD9:C
0CD9 C8         ret z	:C
	:;
	:;
	:;

0CDA:C
0CDA CF         rst $08	:C
	:; ERROR-1

0CDB:B
0CDB-0CDB 0C	:B
	:; Error Report: BREAK - CONT repeats
	:;
	:;

0CDC:C
	:#; --------------------------
	:#; THE 'STOP1' COMMAND ROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; STOP1
0CDC CF         rst $08	:C STOP1
	:; ERROR-1

0CDD:B
0CDD-0CDD 08	:B
	:; Error Report: STOP statement
	:;

0CDE:C
	:#; ---
	:#
	:#; the interpretation of a line continues with a check for just spaces
	:#; followed by a carriage return.
	:#; The IF command also branches here with a true value to execute the
	:#; statement after the THEN but the statement can be null so
	:#; 10 IF 1 = 1 THEN
	:#; passes syntax (on all ZX computers).
	:#
	:#;; LINE-NULL
0CDE DF         rst $18	:C LINE_NULL
	:; GET-CHAR

0CDF:C
0CDF 0600       ld b, $00	:C
	:; prepare to index - early.

0CE1:C
0CE1 FE76       cp $76	:C
	:; compare to NEWLINE.

0CE3:C
0CE3 C8         ret z	:C
	:; return if so.
	:;

0CE4:C
0CE4 4F         ld c, a	:C
	:; transfer character to C.
	:;

0CE5:C
0CE5 E7         rst $20	:C
	:; NEXT-CHAR advances.

0CE6:C
0CE6 79         ld a, c	:C
	:; character to A

0CE7:C
0CE7 D6E1       sub $E1	:C
	:; subtract 'LPRINT' - lowest command.

0CE9:C
0CE9 383B       jr c, $0D26	:C
	:; forward if less to REPORT-C2
	:;

0CEB:C
0CEB 4F         ld c, a	:C
	:; reduced token to C

0CEC:C
0CEC 21290C     ld hl, $0C29	:C
	:; set HL to address of offset table.

0CEF:C
0CEF 09         add hl, bc	:C
	:; index into offset table.

0CF0:C
0CF0 4E         ld c, (hl)	:C
	:; fetch offset

0CF1:C
0CF1 09         add hl, bc	:C
	:; index into parameter table.

0CF2:C
0CF2 1803       jr $0CF7	:C
	:; to GET-PARAM
	:;

0CF4:C
	:#; ---
	:#
	:#;; SCAN-LOOP
0CF4 2A3040     ld hl, ($4030)	:C SCAN_LOOP
	:; sv T_ADDR_lo
	:;

0CF7:C
	:#; -> Entry Point to Scanning Loop
	:#
	:#;; GET-PARAM
0CF7 7E         ld a, (hl)	:C GET_PARAM
	:;

0CF8:C
0CF8 23         inc hl	:C
	:;

0CF9:C
0CF9 223040     ld ($4030), hl	:C
	:; sv T_ADDR_lo
	:;

0CFC:C
0CFC 01F40C     ld bc, $0CF4	:C
	:; Address: SCAN-LOOP

0CFF:C
0CFF C5         push bc	:C
	:; is pushed on machine stack.
	:;

0D00:C
0D00 4F         ld c, a	:C
	:;

0D01:C
0D01 FE0B       cp $0B	:C
	:;

0D03:C
0D03 300B       jr nc, $0D10	:C
	:; to SEPARATOR
	:;

0D05:C
0D05 21160D     ld hl, $0D16	:C
	:; class-tbl - the address of the class table.

0D08:C
0D08 0600       ld b, $00	:C
	:;

0D0A:C
0D0A 09         add hl, bc	:C
	:;

0D0B:C
0D0B 4E         ld c, (hl)	:C
	:;

0D0C:C
0D0C 09         add hl, bc	:C
	:;

0D0D:C
0D0D E5         push hl	:C
	:;
	:;

0D0E:C
0D0E DF         rst $18	:C
	:; GET-CHAR

0D0F:C
0D0F C9         ret	:C
	:; indirect jump to class routine and
	:; by subsequent RET to SCAN-LOOP.
	:;

0D10:C
	:#; -----------------------
	:#; THE 'SEPARATOR' ROUTINE
	:#; -----------------------
	:#
	:#;; SEPARATOR
0D10 DF         rst $18	:C SEPARATOR
	:; GET-CHAR

0D11:C
0D11 B9         cp c	:C
	:;

0D12:C
0D12 2012       jr nz, $0D26	:C
	:; to REPORT-C2
	:; 'Nonsense in BASIC'
	:;

0D14:C
0D14 E7         rst $20	:C
	:; NEXT-CHAR

0D15:C
0D15 C9         ret	:C
	:; return
	:;
	:;

0D16:B
	:#; -------------------------
	:#; THE 'COMMAND CLASS' TABLE
	:#; -------------------------
	:#;
	:#
	:#;; class-tbl
0D16-0D16 17	:B class_tbl
	:; 17 offset to; Address: CLASS-0

0D17:B
0D17-0D17 25	:B
	:; 25 offset to; Address: CLASS-1

0D18:B
0D18-0D18 53	:B
	:; 53 offset to; Address: CLASS-2

0D19:B
0D19-0D19 0F	:B
	:; 0F offset to; Address: CLASS-3

0D1A:B
0D1A-0D1A 6B	:B
	:; 6B offset to; Address: CLASS-4

0D1B:B
0D1B-0D1B 13	:B
	:; 13 offset to; Address: CLASS-5

0D1C:B
0D1C-0D1C 76	:B
	:; 76 offset to; Address: CLASS-6
	:;
	:;

0D1D:C
	:#; --------------------------
	:#; THE 'CHECK END' SUBROUTINE
	:#; --------------------------
	:#; Check for end of statement and that no spurious characters occur after
	:#; a correctly parsed statement. Since only one statement is allowed on each
	:#; line, the only character that may follow a statement is a NEWLINE.
	:#;
	:#
	:#;; CHECK-END
0D1D CDA60D     call $0DA6	:C CHECK_END
	:; routine SYNTAX-Z

0D20:C
0D20 C0         ret nz	:C
	:; return in runtime.
	:;

0D21:C
0D21 C1         pop bc	:C
	:; else drop return address.
	:;

0D22:C
	:#;; CHECK-2
0D22 7E         ld a, (hl)	:C CHECK_2
	:; fetch character.

0D23:C
0D23 FE76       cp $76	:C
	:; compare to NEWLINE.

0D25:C
0D25 C8         ret z	:C
	:; return if so.
	:;

0D26:C
	:#;; REPORT-C2
0D26 1872       jr $0D9A	:C REPORT_C2
	:; to REPORT-C
	:; 'Nonsense in BASIC'
	:;

0D28:C
	:#; --------------------------
	:#; COMMAND CLASSES 03, 00, 05
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; CLASS-3
0D28 FE76       cp $76	:C CLASS_3
	:;

0D2A:C
0D2A CD9C0D     call $0D9C	:C
	:; routine NO-TO-STK
	:;

0D2D:C
	:#;; CLASS-0
0D2D BF         cp a	:C CLASS_0
	:;
	:;

0D2E:C
	:#;; CLASS-5
0D2E C1         pop bc	:C CLASS_5
	:;

0D2F:C
0D2F CC1D0D     call z, $0D1D	:C
	:; routine CHECK-END

0D32:C
0D32 EB         ex de, hl	:C
	:;

0D33:C
0D33 2A3040     ld hl, ($4030)	:C
	:; sv T_ADDR_lo

0D36:C
0D36 4E         ld c, (hl)	:C
	:;

0D37:C
0D37 23         inc hl	:C
	:;

0D38:C
0D38 46         ld b, (hl)	:C
	:;

0D39:C
0D39 EB         ex de, hl	:C
	:;
	:;

0D3A:C
	:#;; CLASS-END
0D3A C5         push bc	:C CLASS_END
	:;

0D3B:C
0D3B C9         ret	:C
	:;
	:;

0D3C:C
	:#; ------------------------------
	:#; COMMAND CLASSES 01, 02, 04, 06
	:#; ------------------------------
	:#;
	:#;
	:#
	:#;; CLASS-1
0D3C CD1C11     call $111C	:C CLASS_1
	:; routine LOOK-VARS
	:;

0D3F:C
	:#;; CLASS-4-2
0D3F FD362D00   ld (iy+$2D), $00	:C CLASS_4_2
	:; sv FLAGX

0D43:C
0D43 3008       jr nc, $0D4D	:C
	:; to SET-STK
	:;

0D45:C
0D45 FDCB2DCE   set 1, (iy+$2D)	:C
	:; sv FLAGX

0D49:C
0D49 2018       jr nz, $0D63	:C
	:; to SET-STRLN
	:;
	:;

0D4B:C
	:#;; REPORT-2
0D4B CF         rst $08	:C REPORT_2
	:; ERROR-1

0D4C:B
0D4C-0D4C 01	:B
	:; Error Report: Variable not found
	:;

0D4D:C
	:#; ---
	:#
	:#;; SET-STK
0D4D CCA711     call z, $11A7	:C SET_STK
	:; routine STK-VAR

0D50:C
0D50 FDCB0176   bit 6, (iy+$01)	:C
	:; sv FLAGS  - Numeric or string result?

0D54:C
0D54 200D       jr nz, $0D63	:C
	:; to SET-STRLN
	:;

0D56:C
0D56 AF         xor a	:C
	:;

0D57:C
0D57 CDA60D     call $0DA6	:C
	:; routine SYNTAX-Z

0D5A:C
0D5A C4F813     call nz, $13F8	:C
	:; routine STK-FETCH

0D5D:C
0D5D 212D40     ld hl, $402D	:C
	:; sv FLAGX

0D60:C
0D60 B6         or (hl)	:C
	:;

0D61:C
0D61 77         ld (hl), a	:C
	:;

0D62:C
0D62 EB         ex de, hl	:C
	:;
	:;

0D63:C
	:#;; SET-STRLN
0D63 ED432E40   ld ($402E), bc	:C SET_STRLN
	:; sv STRLEN_lo

0D67:C
0D67 221240     ld ($4012), hl	:C
	:; sv DEST-lo
	:;

0D6A:C
	:#; THE 'REM' COMMAND ROUTINE
	:#
	:#;; REM
0D6A C9         ret	:C REM
	:;
	:;

0D6B:C
	:#; ---
	:#
	:#;; CLASS-2
0D6B C1         pop bc	:C CLASS_2
	:;

0D6C:C
0D6C 3A0140     ld a, ($4001)	:C
	:; sv FLAGS
	:;

0D6F:C
	:#;; INPUT-REP
0D6F F5         push af	:C INPUT_REP
	:;

0D70:C
0D70 CD550F     call $0F55	:C
	:; routine SCANNING

0D73:C
0D73 F1         pop af	:C
	:;

0D74:C
0D74 012113     ld bc, $1321	:C
	:; Address: LET

0D77:C
0D77 FD5601     ld d, (iy+$01)	:C
	:; sv FLAGS

0D7A:C
0D7A AA         xor d	:C
	:;

0D7B:C
0D7B E640       and $40	:C
	:;

0D7D:C
0D7D 201B       jr nz, $0D9A	:C
	:; to REPORT-C
	:;

0D7F:C
0D7F CB7A       bit 7, d	:C
	:;

0D81:C
0D81 20B7       jr nz, $0D3A	:C
	:; to CLASS-END
	:;

0D83:C
0D83 189D       jr $0D22	:C
	:; to CHECK-2
	:;

0D85:C
	:#; ---
	:#
	:#;; CLASS-4
0D85 CD1C11     call $111C	:C CLASS_4
	:; routine LOOK-VARS

0D88:C
0D88 F5         push af	:C
	:;

0D89:C
0D89 79         ld a, c	:C
	:;

0D8A:C
0D8A F69F       or $9F	:C
	:;

0D8C:C
0D8C 3C         inc a	:C
	:;

0D8D:C
0D8D 200B       jr nz, $0D9A	:C
	:; to REPORT-C
	:;

0D8F:C
0D8F F1         pop af	:C
	:;

0D90:C
0D90 18AD       jr $0D3F	:C
	:; to CLASS-4-2
	:;

0D92:C
	:#; ---
	:#
	:#;; CLASS-6
0D92 CD550F     call $0F55	:C CLASS_6
	:; routine SCANNING

0D95:C
0D95 FDCB0176   bit 6, (iy+$01)	:C
	:; sv FLAGS  - Numeric or string result?

0D99:C
0D99 C0         ret nz	:C
	:;
	:;
	:;

0D9A:C
	:#;; REPORT-C
0D9A CF         rst $08	:C REPORT_C
	:; ERROR-1

0D9B:B
0D9B-0D9B 0B	:B
	:; Error Report: Nonsense in BASIC
	:;

0D9C:C
	:#; --------------------------------
	:#; THE 'NUMBER TO STACK' SUBROUTINE
	:#; --------------------------------
	:#;
	:#;
	:#
	:#;; NO-TO-STK
0D9C 20F4       jr nz, $0D92	:C NO_TO_STK
	:; back to CLASS-6 with a non-zero number.
	:;

0D9E:C
0D9E CDA60D     call $0DA6	:C
	:; routine SYNTAX-Z

0DA1:C
0DA1 C8         ret z	:C
	:; return if checking syntax.
	:;

0DA2:C
	:#; in runtime a zero default is placed on the calculator stack.
	:#
0DA2 EF         rst $28	:C
	:;; FP-CALC

0DA3:B
0DA3-0DA3 A0	:B
	:;;stk-zero

0DA4:B
0DA4-0DA4 34	:B
	:;;end-calc
	:;

0DA5:C
0DA5 C9         ret	:C
	:; return.
	:;

0DA6:C
	:#; -------------------------
	:#; THE 'SYNTAX-Z' SUBROUTINE
	:#; -------------------------
	:#; This routine returns with zero flag set if checking syntax.
	:#; Calling this routine uses three instruction bytes compared to four if the
	:#; bit test is implemented inline.
	:#
	:#;; SYNTAX-Z
0DA6 FDCB017E   bit 7, (iy+$01)	:C SYNTAX_Z
	:; test FLAGS  - checking syntax only?

0DAA:C
0DAA C9         ret	:C
	:; return.
	:;

0DAB:C
	:#; ------------------------
	:#; THE 'IF' COMMAND ROUTINE
	:#; ------------------------
	:#; In runtime, the class routines have evaluated the test expression and
	:#; the result, true or false, is on the stack.
	:#
	:#;; IF
0DAB CDA60D     call $0DA6	:C IF
	:; routine SYNTAX-Z

0DAE:C
0DAE 2806       jr z, $0DB6	:C
	:; forward if checking syntax to IF-END
	:;

0DB0:C
	:#; else delete the Boolean value on the calculator stack.
	:#
0DB0 EF         rst $28	:C
	:;; FP-CALC

0DB1:B
0DB1-0DB1 02	:B
	:;;delete

0DB2:B
0DB2-0DB2 34	:B
	:;;end-calc
	:;

0DB3:C
	:#; register DE points to exponent of floating point value.
	:#
0DB3 1A         ld a, (de)	:C
	:; fetch exponent.

0DB4:C
0DB4 A7         and a	:C
	:; test for zero - FALSE.

0DB5:C
0DB5 C8         ret z	:C
	:; return if so.
	:;

0DB6:C
	:#;; IF-END
0DB6 C3DE0C     jp $0CDE	:C IF_END
	:; jump back to LINE-NULL
	:;

0DB9:C
	:#; -------------------------
	:#; THE 'FOR' COMMAND ROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; FOR
0DB9 FEE0       cp $E0	:C FOR
	:; is current character 'STEP' ?

0DBB:C
0DBB 2009       jr nz, $0DC6	:C
	:; forward if not to F-USE-ONE
	:;
	:;

0DBD:C
0DBD E7         rst $20	:C
	:; NEXT-CHAR

0DBE:C
0DBE CD920D     call $0D92	:C
	:; routine CLASS-6 stacks the number

0DC1:C
0DC1 CD1D0D     call $0D1D	:C
	:; routine CHECK-END

0DC4:C
0DC4 1806       jr $0DCC	:C
	:; forward to F-REORDER
	:;

0DC6:C
	:#; ---
	:#
	:#;; F-USE-ONE
0DC6 CD1D0D     call $0D1D	:C F_USE_ONE
	:; routine CHECK-END
	:;

0DC9:C
0DC9 EF         rst $28	:C
	:;; FP-CALC

0DCA:B
0DCA-0DCA A1	:B
	:;;stk-one

0DCB:B
0DCB-0DCB 34	:B
	:;;end-calc
	:;
	:;
	:;

0DCC:C
	:#;; F-REORDER
0DCC EF         rst $28	:C F_REORDER
	:;; FP-CALC      v, l, s.

0DCD:B
0DCD-0DCD C0	:B
	:;;st-mem-0      v, l, s.

0DCE:B
0DCE-0DCE 02	:B
	:;;delete        v, l.

0DCF:B
0DCF-0DCF 01	:B
	:;;exchange      l, v.

0DD0:B
0DD0-0DD0 E0	:B
	:;;get-mem-0     l, v, s.

0DD1:B
0DD1-0DD1 01	:B
	:;;exchange      l, s, v.

0DD2:B
0DD2-0DD2 34	:B
	:;;end-calc      l, s, v.
	:;

0DD3:C
0DD3 CD2113     call $1321	:C
	:; routine LET
	:;

0DD6:C
0DD6 221F40     ld ($401F), hl	:C
	:; set MEM to address variable.

0DD9:C
0DD9 2B         dec hl	:C
	:; point to letter.

0DDA:C
0DDA 7E         ld a, (hl)	:C
	:;

0DDB:C
0DDB CBFE       set 7, (hl)	:C
	:;

0DDD:C
0DDD 010600     ld bc, $0006	:C
	:;

0DE0:C
0DE0 09         add hl, bc	:C
	:;

0DE1:C
0DE1 07         rlca	:C
	:;

0DE2:C
0DE2 3806       jr c, $0DEA	:C
	:; to F-LMT-STP
	:;

0DE4:C
0DE4 CB21       sla c	:C
	:;

0DE6:C
0DE6 CD9E09     call $099E	:C
	:; routine MAKE-ROOM

0DE9:C
0DE9 23         inc hl	:C
	:;
	:;

0DEA:C
	:#;; F-LMT-STP
0DEA E5         push hl	:C F_LMT_STP
	:;
	:;

0DEB:C
0DEB EF         rst $28	:C
	:;; FP-CALC

0DEC:B
0DEC-0DEC 02	:B
	:;;delete

0DED:B
0DED-0DED 02	:B
	:;;delete

0DEE:B
0DEE-0DEE 34	:B
	:;;end-calc
	:;

0DEF:C
0DEF E1         pop hl	:C
	:;

0DF0:C
0DF0 EB         ex de, hl	:C
	:;
	:;

0DF1:C
0DF1 0E0A       ld c, $0A	:C
	:; ten bytes to be moved.

0DF3:C
0DF3 EDB0       ldir	:C
	:; copy bytes
	:;

0DF5:C
0DF5 2A0740     ld hl, ($4007)	:C
	:; set HL to system variable PPC current line.

0DF8:C
0DF8 EB         ex de, hl	:C
	:; transfer to DE, variable pointer to HL.

0DF9:C
0DF9 13         inc de	:C
	:; loop start will be this line + 1 at least.

0DFA:C
0DFA 73         ld (hl), e	:C
	:;

0DFB:C
0DFB 23         inc hl	:C
	:;

0DFC:C
0DFC 72         ld (hl), d	:C
	:;

0DFD:C
0DFD CD5A0E     call $0E5A	:C
	:; routine NEXT-LOOP considers an initial pass.

0E00:C
0E00 D0         ret nc	:C
	:; return if possible.
	:;

0E01:C
	:#; else program continues from point following matching NEXT.
	:#
0E01 FDCB087E   bit 7, (iy+$08)	:C
	:; test PPC_hi

0E05:C
0E05 C0         ret nz	:C
	:; return if over 32767 ???
	:;

0E06:C
0E06 FD462E     ld b, (iy+$2E)	:C
	:; fetch variable name from STRLEN_lo

0E09:C
0E09 CBB0       res 6, b	:C
	:; make a true letter.

0E0B:C
0E0B 2A2940     ld hl, ($4029)	:C
	:; set HL from NXTLIN
	:;

0E0E:C
	:#; now enter a loop to look for matching next.
	:#
	:#;; NXTLIN-NO
0E0E 7E         ld a, (hl)	:C NXTLIN_NO
	:; fetch high byte of line number.

0E0F:C
0E0F E6C0       and $C0	:C
	:; mask off low bits $3F

0E11:C
0E11 2017       jr nz, $0E2A	:C
	:; forward at end of program to FOR-END
	:;

0E13:C
0E13 C5         push bc	:C
	:; save letter

0E14:C
0E14 CDF209     call $09F2	:C
	:; routine NEXT-ONE finds next line.

0E17:C
0E17 C1         pop bc	:C
	:; restore letter
	:;

0E18:C
0E18 23         inc hl	:C
	:; step past low byte

0E19:C
0E19 23         inc hl	:C
	:; past the

0E1A:C
0E1A 23         inc hl	:C
	:; line length.

0E1B:C
0E1B CD4C00     call $004C	:C
	:; routine TEMP-PTR1 sets CH_ADD
	:;

0E1E:C
0E1E DF         rst $18	:C
	:; GET-CHAR

0E1F:C
0E1F FEF3       cp $F3	:C
	:; compare to 'NEXT'.

0E21:C
0E21 EB         ex de, hl	:C
	:; next line to HL.

0E22:C
0E22 20EA       jr nz, $0E0E	:C
	:; back with no match to NXTLIN-NO
	:;

0E24:C
	:#;
	:#
0E24 EB         ex de, hl	:C
	:; restore pointer.
	:;

0E25:C
0E25 E7         rst $20	:C
	:; NEXT-CHAR advances and gets letter in A.

0E26:C
0E26 EB         ex de, hl	:C
	:; save pointer

0E27:C
0E27 B8         cp b	:C
	:; compare to variable name.

0E28:C
0E28 20E4       jr nz, $0E0E	:C
	:; back with mismatch to NXTLIN-NO
	:;

0E2A:C
	:#;; FOR-END
0E2A 222940     ld ($4029), hl	:C FOR_END
	:; update system variable NXTLIN

0E2D:C
0E2D C9         ret	:C
	:; return.
	:;

0E2E:C
	:#; --------------------------
	:#; THE 'NEXT' COMMAND ROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; NEXT
0E2E FDCB2D4E   bit 1, (iy+$2D)	:C NEXT
	:; sv FLAGX

0E32:C
0E32 C24B0D     jp nz, $0D4B	:C
	:; to REPORT-2
	:;

0E35:C
0E35 2A1240     ld hl, ($4012)	:C
	:; DEST

0E38:C
0E38 CB7E       bit 7, (hl)	:C
	:;

0E3A:C
0E3A 281C       jr z, $0E58	:C
	:; to REPORT-1
	:;

0E3C:C
0E3C 23         inc hl	:C
	:;

0E3D:C
0E3D 221F40     ld ($401F), hl	:C
	:; sv MEM_lo
	:;

0E40:C
0E40 EF         rst $28	:C
	:;; FP-CALC

0E41:B
0E41-0E41 E0	:B
	:;;get-mem-0

0E42:B
0E42-0E42 E2	:B
	:;;get-mem-2

0E43:B
0E43-0E43 0F	:B
	:;;addition

0E44:B
0E44-0E44 C0	:B
	:;;st-mem-0

0E45:B
0E45-0E45 02	:B
	:;;delete

0E46:B
0E46-0E46 34	:B
	:;;end-calc
	:;

0E47:C
0E47 CD5A0E     call $0E5A	:C
	:; routine NEXT-LOOP

0E4A:C
0E4A D8         ret c	:C
	:;
	:;

0E4B:C
0E4B 2A1F40     ld hl, ($401F)	:C
	:; sv MEM_lo

0E4E:C
0E4E 110F00     ld de, $000F	:C
	:;

0E51:C
0E51 19         add hl, de	:C
	:;

0E52:C
0E52 5E         ld e, (hl)	:C
	:;

0E53:C
0E53 23         inc hl	:C
	:;

0E54:C
0E54 56         ld d, (hl)	:C
	:;

0E55:C
0E55 EB         ex de, hl	:C
	:;

0E56:C
0E56 182E       jr $0E86	:C
	:; to GOTO-2
	:;

0E58:C
	:#; ---
	:#
	:#
	:#;; REPORT-1
0E58 CF         rst $08	:C REPORT_1
	:; ERROR-1

0E59:B
0E59-0E59 00	:B
	:; Error Report: NEXT without FOR
	:;
	:;

0E5A:C
	:#; --------------------------
	:#; THE 'NEXT-LOOP' SUBROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; NEXT-LOOP
0E5A EF         rst $28	:C NEXT_LOOP
	:;; FP-CALC

0E5B:B
0E5B-0E5B E1	:B
	:;;get-mem-1

0E5C:B
0E5C-0E5C E0	:B
	:;;get-mem-0

0E5D:B
0E5D-0E5D E2	:B
	:;;get-mem-2

0E5E:B
0E5E-0E5E 32	:B
	:;;less-0

0E5F:B
0E5F-0E5F 00	:B
	:;;jump-true

0E60:B
0E60-0E60 02	:B
	:;;to L0E62, LMT-V-VAL
	:;

0E61:B
0E61-0E61 01	:B
	:;;exchange
	:;

0E62:B
	:#;; LMT-V-VAL
0E62-0E62 03	:B LMT_V_VAL
	:;;subtract

0E63:B
0E63-0E63 33	:B
	:;;greater-0

0E64:B
0E64-0E64 00	:B
	:;;jump-true

0E65:B
0E65-0E65 04	:B
	:;;to L0E69, IMPOSS
	:;

0E66:B
0E66-0E66 34	:B
	:;;end-calc
	:;

0E67:C
0E67 A7         and a	:C
	:; clear carry flag

0E68:C
0E68 C9         ret	:C
	:; return.
	:;

0E69:B
	:#; ---
	:#
	:#
	:#;; IMPOSS
0E69-0E69 34	:B IMPOSS
	:;;end-calc
	:;

0E6A:C
0E6A 37         scf	:C
	:; set carry flag

0E6B:C
0E6B C9         ret	:C
	:; return.
	:;

0E6C:C
	:#; --------------------------
	:#; THE 'RAND' COMMAND ROUTINE
	:#; --------------------------
	:#; The keyword was 'RANDOMISE' on the ZX80, is 'RAND' here on the ZX81 and
	:#; becomes 'RANDOMIZE' on the ZX Spectrum.
	:#; In all invocations the procedure is the same - to set the SEED system variable
	:#; with a supplied integer value or to use a time-based value if no number, or
	:#; zero, is supplied.
	:#
	:#;; RAND
0E6C CDA70E     call $0EA7	:C RAND
	:; routine FIND-INT

0E6F:C
0E6F 78         ld a, b	:C
	:; test value

0E70:C
0E70 B1         or c	:C
	:; for zero

0E71:C
0E71 2004       jr nz, $0E77	:C
	:; forward if not zero to SET-SEED
	:;

0E73:C
0E73 ED4B3440   ld bc, ($4034)	:C
	:; fetch value of FRAMES system variable.
	:;

0E77:C
	:#;; SET-SEED
0E77 ED433240   ld ($4032), bc	:C SET_SEED
	:; update the SEED system variable.

0E7B:C
0E7B C9         ret	:C
	:; return.
	:;

0E7C:C
	:#; --------------------------
	:#; THE 'CONT' COMMAND ROUTINE
	:#; --------------------------
	:#; Another abbreviated command. ROM space was really tight.
	:#; CONTINUE at the line number that was set when break was pressed.
	:#; Sometimes the current line, sometimes the next line.
	:#
	:#;; CONT
0E7C 2A2B40     ld hl, ($402B)	:C CONT
	:; set HL from system variable OLDPPC

0E7F:C
0E7F 1805       jr $0E86	:C
	:; forward to GOTO-2
	:;

0E81:C
	:#; --------------------------
	:#; THE 'GOTO' COMMAND ROUTINE
	:#; --------------------------
	:#; This token also suffered from the shortage of room and there is no space
	:#; getween GO and TO as there is on the ZX80 and ZX Spectrum. The same also 
	:#; applies to the GOSUB keyword.
	:#
	:#;; GOTO
0E81 CDA70E     call $0EA7	:C GOTO
	:; routine FIND-INT

0E84:C
0E84 60         ld h, b	:C
	:;

0E85:C
0E85 69         ld l, c	:C
	:;
	:;

0E86:C
	:#;; GOTO-2
0E86 7C         ld a, h	:C GOTO_2
	:;

0E87:C
0E87 FEF0       cp $F0	:C
	:;

0E89:C
0E89 3022       jr nc, $0EAD	:C
	:; to REPORT-B
	:;

0E8B:C
0E8B CDD809     call $09D8	:C
	:; routine LINE-ADDR

0E8E:C
0E8E 222940     ld ($4029), hl	:C
	:; sv NXTLIN_lo

0E91:C
0E91 C9         ret	:C
	:;
	:;

0E92:C
	:#; --------------------------
	:#; THE 'POKE' COMMAND ROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; POKE
0E92 CDCD15     call $15CD	:C POKE
	:; routine FP-TO-A

0E95:C
0E95 3816       jr c, $0EAD	:C
	:; forward, with overflow, to REPORT-B
	:;

0E97:C
0E97 2802       jr z, $0E9B	:C
	:; forward, if positive, to POKE-SAVE
	:;

0E99:C
0E99 ED44       neg	:C
	:; negate
	:;

0E9B:C
	:#;; POKE-SAVE
0E9B F5         push af	:C POKE_SAVE
	:; preserve value.

0E9C:C
0E9C CDA70E     call $0EA7	:C
	:; routine FIND-INT gets address in BC
	:; invoking the error routine with overflow
	:; or a negative number.

0E9F:C
0E9F F1         pop af	:C
	:; restore value.
	:;

0EA0:C
	:#; Note. the next two instructions are legacy code from the ZX80 and
	:#; inappropriate here.
	:#
0EA0 FDCB007E   bit 7, (iy)	:C
	:; test ERR_NR - is it still $FF ?

0EA4:C
0EA4 C8         ret z	:C
	:; return with error.
	:;

0EA5:C
0EA5 02         ld (bc), a	:C
	:; update the address contents.

0EA6:C
0EA6 C9         ret	:C
	:; return.
	:;

0EA7:C
	:#; -----------------------------
	:#; THE 'FIND INTEGER' SUBROUTINE
	:#; -----------------------------
	:#;
	:#;
	:#
	:#;; FIND-INT
0EA7 CD8A15     call $158A	:C FIND_INT
	:; routine FP-TO-BC

0EAA:C
0EAA 3801       jr c, $0EAD	:C
	:; forward with overflow to REPORT-B
	:;

0EAC:C
0EAC C8         ret z	:C
	:; return if positive (0-65535).
	:;
	:;

0EAD:C
	:#;; REPORT-B
0EAD CF         rst $08	:C REPORT_B
	:; ERROR-1

0EAE:B
0EAE-0EAE 0A	:B
	:; Error Report: Integer out of range
	:;

0EAF:C
	:#; -------------------------
	:#; THE 'RUN' COMMAND ROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; RUN
0EAF CD810E     call $0E81	:C RUN
	:; routine GOTO

0EB2:C
0EB2 C39A14     jp $149A	:C
	:; to CLEAR
	:;

0EB5:C
	:#; ---------------------------
	:#; THE 'GOSUB' COMMAND ROUTINE
	:#; ---------------------------
	:#;
	:#;
	:#
	:#;; GOSUB
0EB5 2A0740     ld hl, ($4007)	:C GOSUB
	:; sv PPC_lo

0EB8:C
0EB8 23         inc hl	:C
	:;

0EB9:C
0EB9 E3         ex (sp), hl	:C
	:;

0EBA:C
0EBA E5         push hl	:C
	:;

0EBB:C
0EBB ED730240   ld ($4002), sp	:C
	:; set the error stack pointer - ERR_SP

0EBF:C
0EBF CD810E     call $0E81	:C
	:; routine GOTO

0EC2:C
0EC2 010600     ld bc, $0006	:C
	:;
	:;

0EC5:C
	:#; --------------------------
	:#; THE 'TEST ROOM' SUBROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; TEST-ROOM
0EC5 2A1C40     ld hl, ($401C)	:C TEST_ROOM
	:; sv STKEND_lo

0EC8:C
0EC8 09         add hl, bc	:C
	:;

0EC9:C
0EC9 3808       jr c, $0ED3	:C
	:; to REPORT-4
	:;

0ECB:C
0ECB EB         ex de, hl	:C
	:;

0ECC:C
0ECC 212400     ld hl, $0024	:C
	:;

0ECF:C
0ECF 19         add hl, de	:C
	:;

0ED0:C
0ED0 ED72       sbc hl, sp	:C
	:;

0ED2:C
0ED2 D8         ret c	:C
	:;
	:;

0ED3:C
	:#;; REPORT-4
0ED3 2E03       ld l, $03	:C REPORT_4
	:;

0ED5:C
0ED5 C35800     jp $0058	:C
	:; to ERROR-3
	:;

0ED8:C
	:#; ----------------------------
	:#; THE 'RETURN' COMMAND ROUTINE
	:#; ----------------------------
	:#;
	:#;
	:#
	:#;; RETURN
0ED8 E1         pop hl	:C RETURN
	:;

0ED9:C
0ED9 E3         ex (sp), hl	:C
	:;

0EDA:C
0EDA 7C         ld a, h	:C
	:;

0EDB:C
0EDB FE3E       cp $3E	:C
	:;

0EDD:C
0EDD 2806       jr z, $0EE5	:C
	:; to REPORT-7
	:;

0EDF:C
0EDF ED730240   ld ($4002), sp	:C
	:; sv ERR_SP_lo

0EE3:C
0EE3 18A1       jr $0E86	:C
	:; back to GOTO-2
	:;

0EE5:C
	:#; ---
	:#
	:#;; REPORT-7
0EE5 E3         ex (sp), hl	:C REPORT_7
	:;

0EE6:C
0EE6 E5         push hl	:C
	:;
	:;

0EE7:C
0EE7 CF         rst $08	:C
	:; ERROR-1

0EE8:B
0EE8-0EE8 06	:B
	:; Error Report: RETURN without GOSUB
	:;

0EE9:C
	:#; ---------------------------
	:#; THE 'INPUT' COMMAND ROUTINE
	:#; ---------------------------
	:#;
	:#;
	:#
	:#;; INPUT
0EE9 FDCB087E   bit 7, (iy+$08)	:C INPUT
	:; sv PPC_hi

0EED:C
0EED 2032       jr nz, $0F21	:C
	:; to REPORT-8
	:;

0EEF:C
0EEF CDA314     call $14A3	:C
	:; routine X-TEMP

0EF2:C
0EF2 212D40     ld hl, $402D	:C
	:; sv FLAGX

0EF5:C
0EF5 CBEE       set 5, (hl)	:C
	:;

0EF7:C
0EF7 CBB6       res 6, (hl)	:C
	:;

0EF9:C
0EF9 3A0140     ld a, ($4001)	:C
	:; sv FLAGS

0EFC:C
0EFC E640       and $40	:C
	:;

0EFE:C
0EFE 010200     ld bc, $0002	:C
	:;

0F01:C
0F01 2002       jr nz, $0F05	:C
	:; to PROMPT
	:;

0F03:C
0F03 0E04       ld c, $04	:C
	:;
	:;

0F05:C
	:#;; PROMPT
0F05 B6         or (hl)	:C PROMPT
	:;

0F06:C
0F06 77         ld (hl), a	:C
	:;
	:;

0F07:C
0F07 F7         rst $30	:C
	:; BC-SPACES

0F08:C
0F08 3676       ld (hl), $76	:C
	:;

0F0A:C
0F0A 79         ld a, c	:C
	:;

0F0B:C
0F0B 0F         rrca	:C
	:;

0F0C:C
0F0C 0F         rrca	:C
	:;

0F0D:C
0F0D 3805       jr c, $0F14	:C
	:; to ENTER-CUR
	:;

0F0F:C
0F0F 3E0B       ld a, $0B	:C
	:;

0F11:C
0F11 12         ld (de), a	:C
	:;

0F12:C
0F12 2B         dec hl	:C
	:;

0F13:C
0F13 77         ld (hl), a	:C
	:;
	:;

0F14:C
	:#;; ENTER-CUR
0F14 2B         dec hl	:C ENTER_CUR
	:;

0F15:C
0F15 367F       ld (hl), $7F	:C
	:;

0F17:C
0F17 2A3940     ld hl, ($4039)	:C
	:; sv S_POSN_x

0F1A:C
0F1A 223040     ld ($4030), hl	:C
	:; sv T_ADDR_lo

0F1D:C
0F1D E1         pop hl	:C
	:;

0F1E:C
0F1E C37204     jp $0472	:C
	:; to LOWER
	:;

0F21:C
	:#; ---
	:#
	:#;; REPORT-8
0F21 CF         rst $08	:C REPORT_8
	:; ERROR-1

0F22:B
0F22-0F22 07	:B
	:; Error Report: End of file
	:;

0F23:C
	:#; ---------------------------
	:#; THE 'PAUSE' COMMAND ROUTINE
	:#; ---------------------------
	:#;
	:#;
	:#
	:#;; FAST
0F23 CDE702     call $02E7	:C FAST
	:; routine SET-FAST

0F26:C
0F26 FDCB3BB6   res 6, (iy+$3B)	:C
	:; sv CDFLAG

0F2A:C
0F2A C9         ret	:C
	:; return.
	:;

0F2B:C
	:#; --------------------------
	:#; THE 'SLOW' COMMAND ROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; SLOW
0F2B FDCB3BF6   set 6, (iy+$3B)	:C SLOW
	:; sv CDFLAG

0F2F:C
0F2F C30702     jp $0207	:C
	:; to SLOW/FAST
	:;

0F32:C
	:#; ---------------------------
	:#; THE 'PAUSE' COMMAND ROUTINE
	:#; ---------------------------
	:#
	:#;; PAUSE
0F32 CDA70E     call $0EA7	:C PAUSE
	:; routine FIND-INT

0F35:C
0F35 CDE702     call $02E7	:C
	:; routine SET-FAST

0F38:C
0F38 60         ld h, b	:C
	:;

0F39:C
0F39 69         ld l, c	:C
	:;

0F3A:C
0F3A CD2D02     call $022D	:C
	:; routine DISPLAY-P
	:;

0F3D:C
0F3D FD3635FF   ld (iy+$35), $FF	:C
	:; sv FRAMES_hi
	:;

0F41:C
0F41 CD0702     call $0207	:C
	:; routine SLOW/FAST

0F44:C
0F44 1805       jr $0F4B	:C
	:; routine DEBOUNCE
	:;

0F46:C
	:#; ----------------------
	:#; THE 'BREAK' SUBROUTINE
	:#; ----------------------
	:#;
	:#;
	:#
	:#;; BREAK-1
0F46 3E7F       ld a, $7F	:C BREAK_1
	:; read port $7FFE - keys B,N,M,.,SPACE.

0F48:C
0F48 DBFE       in a, ($FE)	:C
	:;

0F4A:C
0F4A 1F         rra	:C
	:; carry will be set if space not pressed.
	:;

0F4B:C
	:#; -------------------------
	:#; THE 'DEBOUNCE' SUBROUTINE
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; DEBOUNCE
0F4B FDCB3B86   res 0, (iy+$3B)	:C DEBOUNCE
	:; update system variable CDFLAG

0F4F:C
0F4F 3EFF       ld a, $FF	:C
	:;

0F51:C
0F51 322740     ld ($4027), a	:C
	:; update system variable DEBOUNCE

0F54:C
0F54 C9         ret	:C
	:; return.
	:;
	:;

0F55:C
	:#; -------------------------
	:#; THE 'SCANNING' SUBROUTINE
	:#; -------------------------
	:#; This recursive routine is where the ZX81 gets its power. Provided there is
	:#; enough memory it can evaluate an expression of unlimited complexity.
	:#; Note. there is no unary plus so, as on the ZX80, PRINT +1 gives a syntax error.
	:#; PRINT +1 works on the Spectrum but so too does PRINT + "STRING".
	:#
	:#;; SCANNING
0F55 DF         rst $18	:C SCANNING
	:; GET-CHAR

0F56:C
0F56 0600       ld b, $00	:C
	:; set B register to zero.

0F58:C
0F58 C5         push bc	:C
	:; stack zero as a priority end-marker.
	:;

0F59:C
	:#;; S-LOOP-1
0F59 FE40       cp $40	:C S_LOOP_1
	:; compare to the 'RND' character

0F5B:C
0F5B 202F       jr nz, $0F8C	:C
	:; forward, if not, to S-TEST-PI
	:;

0F5D:C
	:#; ------------------
	:#; THE 'RND' FUNCTION
	:#; ------------------
	:#
0F5D CDA60D     call $0DA6	:C
	:; routine SYNTAX-Z

0F60:C
0F60 2828       jr z, $0F8A	:C
	:; forward if checking syntax to S-JPI-END
	:;

0F62:C
0F62 ED4B3240   ld bc, ($4032)	:C
	:; sv SEED_lo

0F66:C
0F66 CD2015     call $1520	:C
	:; routine STACK-BC
	:;

0F69:C
0F69 EF         rst $28	:C
	:;; FP-CALC

0F6A:B
0F6A-0F6A A1	:B
	:;;stk-one

0F6B:B
0F6B-0F6B 0F	:B
	:;;addition

0F6C:B
0F6C-0F6C 30	:B
	:;;stk-data

0F6D:B
0F6D-0F6D 37	:B
	:;;Exponent: $87, Bytes: 1

0F6E:B
0F6E-0F6E 16	:B
	:;;(+00,+00,+00)

0F6F:B
0F6F-0F6F 04	:B
	:;;multiply

0F70:B
0F70-0F70 30	:B
	:;;stk-data

0F71:B
0F71-0F71 80	:B
	:;;Bytes: 3

0F72:B
0F72-0F72 41	:B
	:;;Exponent $91

0F73:B
0F73-0F75 000080	:B
	:;;(+00)

0F76:B
0F76-0F76 2E	:B
	:;;n-mod-m

0F77:B
0F77-0F77 02	:B
	:;;delete

0F78:B
0F78-0F78 A1	:B
	:;;stk-one

0F79:B
0F79-0F79 03	:B
	:;;subtract

0F7A:B
0F7A-0F7A 2D	:B
	:;;duplicate

0F7B:B
0F7B-0F7B 34	:B
	:;;end-calc
	:;

0F7C:C
0F7C CD8A15     call $158A	:C
	:; routine FP-TO-BC

0F7F:C
0F7F ED433240   ld ($4032), bc	:C
	:; update the SEED system variable.

0F83:C
0F83 7E         ld a, (hl)	:C
	:; HL addresses the exponent of the last value.

0F84:C
0F84 A7         and a	:C
	:; test for zero

0F85:C
0F85 2803       jr z, $0F8A	:C
	:; forward, if so, to S-JPI-END
	:;

0F87:C
0F87 D610       sub $10	:C
	:; else reduce exponent by sixteen

0F89:C
0F89 77         ld (hl), a	:C
	:; thus dividing by 65536 for last value.
	:;

0F8A:C
	:#;; S-JPI-END
0F8A 180D       jr $0F99	:C S_JPI_END
	:; forward to S-PI-END
	:;

0F8C:C
	:#; ---
	:#
	:#;; S-TEST-PI
0F8C FE42       cp $42	:C S_TEST_PI
	:; the 'PI' character

0F8E:C
0F8E 200D       jr nz, $0F9D	:C
	:; forward, if not, to S-TST-INK
	:;

0F90:C
	:#; -------------------
	:#; THE 'PI' EVALUATION
	:#; -------------------
	:#
0F90 CDA60D     call $0DA6	:C
	:; routine SYNTAX-Z

0F93:C
0F93 2804       jr z, $0F99	:C
	:; forward if checking syntax to S-PI-END
	:;
	:;

0F95:C
0F95 EF         rst $28	:C
	:;; FP-CALC

0F96:B
0F96-0F96 A3	:B
	:;;stk-pi/2

0F97:B
0F97-0F97 34	:B
	:;;end-calc
	:;

0F98:C
0F98 34         inc (hl)	:C
	:; double the exponent giving PI on the stack.
	:;

0F99:C
	:#;; S-PI-END
0F99 E7         rst $20	:C S_PI_END
	:; NEXT-CHAR advances character pointer.
	:;

0F9A:C
0F9A C38310     jp $1083	:C
	:; jump forward to S-NUMERIC to set the flag
	:; to signal numeric result before advancing.
	:;

0F9D:C
	:#; ---
	:#
	:#;; S-TST-INK
0F9D FE41       cp $41	:C S_TST_INK
	:; compare to character 'INKEY$'

0F9F:C
0F9F 2011       jr nz, $0FB2	:C
	:; forward, if not, to S-ALPHANUM
	:;

0FA1:C
	:#; -----------------------
	:#; THE 'INKEY$' EVALUATION
	:#; -----------------------
	:#
0FA1 CDBB02     call $02BB	:C
	:; routine KEYBOARD

0FA4:C
0FA4 44         ld b, h	:C
	:;

0FA5:C
0FA5 4D         ld c, l	:C
	:;

0FA6:C
0FA6 51         ld d, c	:C
	:;

0FA7:C
0FA7 14         inc d	:C
	:;

0FA8:C
0FA8 C4BD07     call nz, $07BD	:C
	:; routine DECODE

0FAB:C
0FAB 7A         ld a, d	:C
	:;

0FAC:C
0FAC 8A         adc a, d	:C
	:;

0FAD:C
0FAD 42         ld b, d	:C
	:;

0FAE:C
0FAE 4F         ld c, a	:C
	:;

0FAF:C
0FAF EB         ex de, hl	:C
	:;

0FB0:C
0FB0 183B       jr $0FED	:C
	:; forward to S-STRING
	:;

0FB2:C
	:#; ---
	:#
	:#;; S-ALPHANUM
0FB2 CDD214     call $14D2	:C S_ALPHANUM
	:; routine ALPHANUM

0FB5:C
0FB5 386E       jr c, $1025	:C
	:; forward, if alphanumeric to S-LTR-DGT
	:;

0FB7:C
0FB7 FE1B       cp $1B	:C
	:; is character a '.' ?

0FB9:C
0FB9 CA4710     jp z, $1047	:C
	:; jump forward if so to S-DECIMAL
	:;

0FBC:C
0FBC 01D809     ld bc, $09D8	:C
	:; prepare priority 09, operation 'subtract'

0FBF:C
0FBF FE16       cp $16	:C
	:; is character unary minus '-' ?

0FC1:C
0FC1 285D       jr z, $1020	:C
	:; forward, if so, to S-PUSH-PO
	:;

0FC3:C
0FC3 FE10       cp $10	:C
	:; is character a '(' ?

0FC5:C
0FC5 200F       jr nz, $0FD6	:C
	:; forward if not to S-QUOTE
	:;

0FC7:C
0FC7 CD4900     call $0049	:C
	:; routine CH-ADD+1 advances character pointer.
	:;

0FCA:C
0FCA CD550F     call $0F55	:C
	:; recursively call routine SCANNING to
	:; evaluate the sub-expression.
	:;

0FCD:C
0FCD FE11       cp $11	:C
	:; is subsequent character a ')' ?

0FCF:C
0FCF 202E       jr nz, $0FFF	:C
	:; forward if not to S-RPT-C
	:;
	:;

0FD1:C
0FD1 CD4900     call $0049	:C
	:; routine CH-ADD+1  advances.

0FD4:C
0FD4 1822       jr $0FF8	:C
	:; relative jump to S-JP-CONT3 and then S-CONT3
	:;

0FD6:C
	:#; ---
	:#
	:#; consider a quoted string e.g. PRINT "Hooray!"
	:#; Note. quotes are not allowed within a string.
	:#
	:#;; S-QUOTE
0FD6 FE0B       cp $0B	:C S_QUOTE
	:; is character a quote (") ?

0FD8:C
0FD8 2028       jr nz, $1002	:C
	:; forward, if not, to S-FUNCTION
	:;

0FDA:C
0FDA CD4900     call $0049	:C
	:; routine CH-ADD+1 advances

0FDD:C
0FDD E5         push hl	:C
	:; * save start of string.

0FDE:C
0FDE 1803       jr $0FE3	:C
	:; forward to S-QUOTE-S
	:;

0FE0:C
	:#; ---
	:#
	:#
	:#;; S-Q-AGAIN
0FE0 CD4900     call $0049	:C S_Q_AGAIN
	:; routine CH-ADD+1
	:;

0FE3:C
	:#;; S-QUOTE-S
0FE3 FE0B       cp $0B	:C S_QUOTE_S
	:; is character a '"' ?

0FE5:C
0FE5 2014       jr nz, $0FFB	:C
	:; forward if not to S-Q-NL
	:;

0FE7:C
0FE7 D1         pop de	:C
	:; * retrieve start of string

0FE8:C
0FE8 A7         and a	:C
	:; prepare to subtract.

0FE9:C
0FE9 ED52       sbc hl, de	:C
	:; subtract start from current position.

0FEB:C
0FEB 44         ld b, h	:C
	:; transfer this length

0FEC:C
0FEC 4D         ld c, l	:C
	:; to the BC register pair.
	:;

0FED:C
	:#;; S-STRING
0FED 210140     ld hl, $4001	:C S_STRING
	:; address system variable FLAGS

0FF0:C
0FF0 CBB6       res 6, (hl)	:C
	:; signal string result

0FF2:C
0FF2 CB7E       bit 7, (hl)	:C
	:; test if checking syntax.
	:;

0FF4:C
0FF4 C4C312     call nz, $12C3	:C
	:; in run-time routine STK-STO-$ stacks the
	:; string descriptor - start DE, length BC.
	:;

0FF7:C
0FF7 E7         rst $20	:C
	:; NEXT-CHAR advances pointer.
	:;

0FF8:C
	:#;; S-J-CONT-3
0FF8 C38810     jp $1088	:C S_J_CONT_3
	:; jump to S-CONT-3
	:;

0FFB:C
	:#; ---
	:#
	:#; A string with no terminating quote has to be considered.
	:#
	:#;; S-Q-NL
0FFB FE76       cp $76	:C S_Q_NL
	:; compare to NEWLINE

0FFD:C
0FFD 20E1       jr nz, $0FE0	:C
	:; loop back if not to S-Q-AGAIN
	:;

0FFF:C
	:#;; S-RPT-C
0FFF C39A0D     jp $0D9A	:C S_RPT_C
	:; to REPORT-C
	:;

1002:C
	:#; ---
	:#
	:#;; S-FUNCTION
1002 D6C4       sub $C4	:C S_FUNCTION
	:; subtract 'CODE' reducing codes
	:; CODE thru '<>' to range $00 - $XX

1004:C
1004 38F9       jr c, $0FFF	:C
	:; back, if less, to S-RPT-C
	:;

1006:C
	:#; test for NOT the last function in character set.
	:#
1006 01EC04     ld bc, $04EC	:C
	:; prepare priority $04, operation 'not'

1009:C
1009 FE13       cp $13	:C
	:; compare to 'NOT'  ( - CODE)

100B:C
100B 2813       jr z, $1020	:C
	:; forward, if so, to S-PUSH-PO
	:;

100D:C
100D 30F0       jr nc, $0FFF	:C
	:; back with anything higher to S-RPT-C
	:;

100F:C
	:#; else is a function 'CODE' thru 'CHR$'
	:#
100F 0610       ld b, $10	:C
	:; priority sixteen binds all functions to
	:; arguments removing the need for brackets.
	:;

1011:C
1011 C6D9       add a, $D9	:C
	:; add $D9 to give range $D9 thru $EB
	:; bit 6 is set to show numeric argument.
	:; bit 7 is set to show numeric result.
	:;

1013:C
	:#; now adjust these default argument/result indicators.
	:#
1013 4F         ld c, a	:C
	:; save code in C
	:;

1014:C
1014 FEDC       cp $DC	:C
	:; separate 'CODE', 'VAL', 'LEN'

1016:C
1016 3002       jr nc, $101A	:C
	:; skip forward if string operand to S-NO-TO-$
	:;

1018:C
1018 CBB1       res 6, c	:C
	:; signal string operand.
	:;

101A:C
	:#;; S-NO-TO-$
101A FEEA       cp $EA	:C S_NO_TO__
	:; isolate top of range 'STR$' and 'CHR$'

101C:C
101C 3802       jr c, $1020	:C
	:; skip forward with others to S-PUSH-PO
	:;

101E:C
101E CBB9       res 7, c	:C
	:; signal string result.
	:;

1020:C
	:#;; S-PUSH-PO
1020 C5         push bc	:C S_PUSH_PO
	:; push the priority/operation
	:;

1021:C
1021 E7         rst $20	:C
	:; NEXT-CHAR

1022:C
1022 C3590F     jp $0F59	:C
	:; jump back to S-LOOP-1
	:;

1025:C
	:#; ---
	:#
	:#;; S-LTR-DGT
1025 FE26       cp $26	:C S_LTR_DGT
	:; compare to 'A'.

1027:C
1027 381E       jr c, $1047	:C
	:; forward if less to S-DECIMAL
	:;

1029:C
1029 CD1C11     call $111C	:C
	:; routine LOOK-VARS

102C:C
102C DA4B0D     jp c, $0D4B	:C
	:; back if not found to REPORT-2
	:; a variable is always 'found' when checking
	:; syntax.
	:;

102F:C
102F CCA711     call z, $11A7	:C
	:; routine STK-VAR stacks string parameters or
	:; returns cell location if numeric.
	:;

1032:C
1032 3A0140     ld a, ($4001)	:C
	:; fetch FLAGS

1035:C
1035 FEC0       cp $C0	:C
	:; compare to numeric result/numeric operand

1037:C
1037 384E       jr c, $1087	:C
	:; forward if not numeric to S-CONT-2
	:;

1039:C
1039 23         inc hl	:C
	:; address numeric contents of variable.

103A:C
103A ED5B1C40   ld de, ($401C)	:C
	:; set destination to STKEND

103E:C
103E CDF619     call $19F6	:C
	:; routine MOVE-FP stacks the five bytes

1041:C
1041 EB         ex de, hl	:C
	:; transfer new free location from DE to HL.

1042:C
1042 221C40     ld ($401C), hl	:C
	:; update STKEND system variable.

1045:C
1045 1840       jr $1087	:C
	:; forward to S-CONT-2
	:;

1047:C
	:#; ---
	:#
	:#; The Scanning Decimal routine is invoked when a decimal point or digit is
	:#; found in the expression.
	:#; When checking syntax, then the 'hidden floating point' form is placed
	:#; after the number in the BASIC line.
	:#; In run-time, the digits are skipped and the floating point number is picked
	:#; up.
	:#
	:#;; S-DECIMAL
1047 CDA60D     call $0DA6	:C S_DECIMAL
	:; routine SYNTAX-Z

104A:C
104A 2023       jr nz, $106F	:C
	:; forward in run-time to S-STK-DEC
	:;

104C:C
104C CDD914     call $14D9	:C
	:; routine DEC-TO-FP
	:;

104F:C
104F DF         rst $18	:C
	:; GET-CHAR advances HL past digits

1050:C
1050 010600     ld bc, $0006	:C
	:; six locations are required.

1053:C
1053 CD9E09     call $099E	:C
	:; routine MAKE-ROOM

1056:C
1056 23         inc hl	:C
	:; point to first new location

1057:C
1057 367E       ld (hl), $7E	:C
	:; insert the number marker 126 decimal.

1059:C
1059 23         inc hl	:C
	:; increment

105A:C
105A EB         ex de, hl	:C
	:; transfer destination to DE.

105B:C
105B 2A1C40     ld hl, ($401C)	:C
	:; set HL from STKEND which points to the
	:; first location after the 'last value'

105E:C
105E 0E05       ld c, $05	:C
	:; five bytes to move.

1060:C
1060 A7         and a	:C
	:; clear carry.

1061:C
1061 ED42       sbc hl, bc	:C
	:; subtract five pointing to 'last value'.

1063:C
1063 221C40     ld ($401C), hl	:C
	:; update STKEND thereby 'deleting the value.
	:;

1066:C
1066 EDB0       ldir	:C
	:; copy the five value bytes.
	:;

1068:C
1068 EB         ex de, hl	:C
	:; basic pointer to HL which may be white-space
	:; following the number.

1069:C
1069 2B         dec hl	:C
	:; now points to last of five bytes.

106A:C
106A CD4C00     call $004C	:C
	:; routine TEMP-PTR1 advances the character
	:; address skipping any white-space.

106D:C
106D 1814       jr $1083	:C
	:; forward to S-NUMERIC
	:; to signal a numeric result.
	:;

106F:C
	:#; ---
	:#
	:#; In run-time the branch is here when a digit or point is encountered.
	:#
	:#;; S-STK-DEC
106F E7         rst $20	:C S_STK_DEC
	:; NEXT-CHAR

1070:C
1070 FE7E       cp $7E	:C
	:; compare to 'number marker'

1072:C
1072 20FB       jr nz, $106F	:C
	:; loop back until found to S-STK-DEC
	:; skipping all the digits.
	:;

1074:C
1074 23         inc hl	:C
	:; point to first of five hidden bytes.

1075:C
1075 ED5B1C40   ld de, ($401C)	:C
	:; set destination from STKEND system variable

1079:C
1079 CDF619     call $19F6	:C
	:; routine MOVE-FP stacks the number.

107C:C
107C ED531C40   ld ($401C), de	:C
	:; update system variable STKEND.

1080:C
1080 221640     ld ($4016), hl	:C
	:; update system variable CH_ADD.
	:;

1083:C
	:#;; S-NUMERIC
1083 FDCB01F6   set 6, (iy+$01)	:C S_NUMERIC
	:; update FLAGS  - Signal numeric result
	:;

1087:C
	:#;; S-CONT-2
1087 DF         rst $18	:C S_CONT_2
	:; GET-CHAR
	:;

1088:C
	:#;; S-CONT-3
1088 FE10       cp $10	:C S_CONT_3
	:; compare to opening bracket '('

108A:C
108A 200C       jr nz, $1098	:C
	:; forward if not to S-OPERTR
	:;

108C:C
108C FDCB0176   bit 6, (iy+$01)	:C
	:; test FLAGS  - Numeric or string result?

1090:C
1090 202A       jr nz, $10BC	:C
	:; forward if numeric to S-LOOP
	:;

1092:C
	:#; else is a string
	:#
1092 CD6312     call $1263	:C
	:; routine SLICING
	:;

1095:C
1095 E7         rst $20	:C
	:; NEXT-CHAR

1096:C
1096 18F0       jr $1088	:C
	:; back to S-CONT-3
	:;

1098:C
	:#; ---
	:#
	:#; the character is now manipulated to form an equivalent in the table of
	:#; calculator literals. This is quite cumbersome and in the ZX Spectrum a
	:#; simple look-up table was introduced at this point.
	:#
	:#;; S-OPERTR
1098 01C300     ld bc, $00C3	:C S_OPERTR
	:; prepare operator 'subtract' as default.
	:; also set B to zero for later indexing.
	:;

109B:C
109B FE12       cp $12	:C
	:; is character '>' ?

109D:C
109D 381D       jr c, $10BC	:C
	:; forward if less to S-LOOP as
	:; we have reached end of meaningful expression
	:;

109F:C
109F D616       sub $16	:C
	:; is character '-' ?

10A1:C
10A1 3004       jr nc, $10A7	:C
	:; forward with - * / and '**' '<>' to SUBMLTDIV
	:;

10A3:C
10A3 C60D       add a, $0D	:C
	:; increase others by thirteen
	:; $09 '>' thru $0C '+'

10A5:C
10A5 180E       jr $10B5	:C
	:; forward to GET-PRIO
	:;

10A7:C
	:#; ---
	:#
	:#;; SUBMLTDIV
10A7 FE03       cp $03	:C SUBMLTDIV
	:; isolate $00 '-', $01 '*', $02 '/'

10A9:C
10A9 380A       jr c, $10B5	:C
	:; forward if so to GET-PRIO
	:;

10AB:C
	:#; else possibly originally $D8 '**' thru $DD '<>' already reduced by $16
	:#
10AB D6C2       sub $C2	:C
	:; giving range $00 to $05

10AD:C
10AD 380D       jr c, $10BC	:C
	:; forward if less to S-LOOP
	:;

10AF:C
10AF FE06       cp $06	:C
	:; test the upper limit for nonsense also

10B1:C
10B1 3009       jr nc, $10BC	:C
	:; forward if so to S-LOOP
	:;

10B3:C
10B3 C603       add a, $03	:C
	:; increase by 3 to give combined operators of
	:;
	:; $00 '-'
	:; $01 '*'
	:; $02 '/'
	:;
	:; $03 '**'
	:; $04 'OR'
	:; $05 'AND'
	:; $06 '<='
	:; $07 '>='
	:; $08 '<>'
	:;
	:; $09 '>'
	:; $0A '<'
	:; $0B '='
	:; $0C '+'
	:;

10B5:C
	:#;; GET-PRIO
10B5 81         add a, c	:C GET_PRIO
	:; add to default operation 'sub' ($C3)

10B6:C
10B6 4F         ld c, a	:C
	:; and place in operator byte - C.
	:;

10B7:C
10B7 214C10     ld hl, $104C	:C
	:; theoretical base of the priorities table.

10BA:C
10BA 09         add hl, bc	:C
	:; add C ( B is zero)

10BB:C
10BB 46         ld b, (hl)	:C
	:; pick up the priority in B
	:;

10BC:C
	:#;; S-LOOP
10BC D1         pop de	:C S_LOOP
	:; restore previous

10BD:C
10BD 7A         ld a, d	:C
	:; load A with priority.

10BE:C
10BE B8         cp b	:C
	:; is present priority higher

10BF:C
10BF 382C       jr c, $10ED	:C
	:; forward if so to S-TIGHTER
	:;

10C1:C
10C1 A7         and a	:C
	:; are both priorities zero

10C2:C
10C2 CA1800     jp z, $0018	:C
	:; exit if zero via GET-CHAR
	:;

10C5:C
10C5 C5         push bc	:C
	:; stack present values

10C6:C
10C6 D5         push de	:C
	:; stack last values

10C7:C
10C7 CDA60D     call $0DA6	:C
	:; routine SYNTAX-Z

10CA:C
10CA 2809       jr z, $10D5	:C
	:; forward is checking syntax to S-SYNTEST
	:;

10CC:C
10CC 7B         ld a, e	:C
	:; fetch last operation

10CD:C
10CD E63F       and $3F	:C
	:; mask off the indicator bits to give true
	:; calculator literal.

10CF:C
10CF 47         ld b, a	:C
	:; place in the B register for BREG
	:;

10D0:C
	:#; perform the single operation
	:#
10D0 EF         rst $28	:C
	:;; FP-CALC

10D1:B
10D1-10D1 37	:B
	:;;fp-calc-2

10D2:B
10D2-10D2 34	:B
	:;;end-calc
	:;

10D3:C
10D3 1809       jr $10DE	:C
	:; forward to S-RUNTEST
	:;

10D5:C
	:#; ---
	:#
	:#;; S-SYNTEST
10D5 7B         ld a, e	:C S_SYNTEST
	:; transfer masked operator to A

10D6:C
10D6 FDAE01     xor (iy+$01)	:C
	:; XOR with FLAGS like results will reset bit 6

10D9:C
10D9 E640       and $40	:C
	:; test bit 6
	:;

10DB:C
	:#;; S-RPORT-C
10DB C29A0D     jp nz, $0D9A	:C S_RPORT_C
	:; back to REPORT-C if results do not agree.
	:;

10DE:C
	:#; ---
	:#
	:#; in run-time impose bit 7 of the operator onto bit 6 of the FLAGS
	:#
	:#;; S-RUNTEST
10DE D1         pop de	:C S_RUNTEST
	:; restore last operation.

10DF:C
10DF 210140     ld hl, $4001	:C
	:; address system variable FLAGS

10E2:C
10E2 CBF6       set 6, (hl)	:C
	:; presume a numeric result

10E4:C
10E4 CB7B       bit 7, e	:C
	:; test expected result in operation

10E6:C
10E6 2002       jr nz, $10EA	:C
	:; forward if numeric to S-LOOPEND
	:;

10E8:C
10E8 CBB6       res 6, (hl)	:C
	:; reset to signal string result
	:;

10EA:C
	:#;; S-LOOPEND
10EA C1         pop bc	:C S_LOOPEND
	:; restore present values

10EB:C
10EB 18CF       jr $10BC	:C
	:; back to S-LOOP
	:;

10ED:C
	:#; ---
	:#
	:#;; S-TIGHTER
10ED D5         push de	:C S_TIGHTER
	:; push last values and consider these
	:;

10EE:C
10EE 79         ld a, c	:C
	:; get the present operator.

10EF:C
10EF FDCB0176   bit 6, (iy+$01)	:C
	:; test FLAGS  - Numeric or string result?

10F3:C
10F3 2015       jr nz, $110A	:C
	:; forward if numeric to S-NEXT
	:;

10F5:C
10F5 E63F       and $3F	:C
	:; strip indicator bits to give clear literal.

10F7:C
10F7 C608       add a, $08	:C
	:; add eight - augmenting numeric to equivalent
	:; string literals.

10F9:C
10F9 4F         ld c, a	:C
	:; place plain literal back in C.

10FA:C
10FA FE10       cp $10	:C
	:; compare to 'AND'

10FC:C
10FC 2004       jr nz, $1102	:C
	:; forward if not to S-NOT-AND
	:;

10FE:C
10FE CBF1       set 6, c	:C
	:; set the numeric operand required for 'AND'

1100:C
1100 1808       jr $110A	:C
	:; forward to S-NEXT
	:;

1102:C
	:#; ---
	:#
	:#;; S-NOT-AND
1102 38D7       jr c, $10DB	:C S_NOT_AND
	:; back if less than 'AND' to S-RPORT-C
	:; Nonsense if '-', '*' etc.
	:;

1104:C
1104 FE17       cp $17	:C
	:; compare to 'strs-add' literal

1106:C
1106 2802       jr z, $110A	:C
	:; forward if so signaling string result
	:;

1108:C
1108 CBF9       set 7, c	:C
	:; set bit to numeric (Boolean) for others.
	:;

110A:C
	:#;; S-NEXT
110A C5         push bc	:C S_NEXT
	:; stack 'present' values
	:;

110B:C
110B E7         rst $20	:C
	:; NEXT-CHAR

110C:C
110C C3590F     jp $0F59	:C
	:; jump back to S-LOOP-1
	:;
	:;
	:;

110F:B
	:#; -------------------------
	:#; THE 'TABLE OF PRIORITIES'
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; tbl-pri
110F-110F 06	:B tbl_pri
	:;       '-'

1110:B
1110-1110 08	:B
	:;       '*'

1111:B
1111-1111 08	:B
	:;       '/'

1112:B
1112-1112 0A	:B
	:;       '**'

1113:B
1113-1113 02	:B
	:;       'OR'

1114:B
1114-1114 03	:B
	:;       'AND'

1115:B
1115-1115 05	:B
	:;       '<='

1116:B
1116-1116 05	:B
	:;       '>='

1117:B
1117-1117 05	:B
	:;       '<>'

1118:B
1118-1118 05	:B
	:;       '>'

1119:B
1119-1119 05	:B
	:;       '<'

111A:B
111A-111A 05	:B
	:;       '='

111B:B
111B-111B 06	:B
	:;       '+'
	:;
	:;

111C:C
	:#; --------------------------
	:#; THE 'LOOK-VARS' SUBROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; LOOK-VARS
111C FDCB01F6   set 6, (iy+$01)	:C LOOK_VARS
	:; sv FLAGS  - Signal numeric result
	:;

1120:C
1120 DF         rst $18	:C
	:; GET-CHAR

1121:C
1121 CDCE14     call $14CE	:C
	:; routine ALPHA

1124:C
1124 D29A0D     jp nc, $0D9A	:C
	:; to REPORT-C
	:;

1127:C
1127 E5         push hl	:C
	:;

1128:C
1128 4F         ld c, a	:C
	:;
	:;

1129:C
1129 E7         rst $20	:C
	:; NEXT-CHAR

112A:C
112A E5         push hl	:C
	:;

112B:C
112B CBA9       res 5, c	:C
	:;

112D:C
112D FE10       cp $10	:C
	:;

112F:C
112F 2817       jr z, $1148	:C
	:; to V-SYN/RUN
	:;

1131:C
1131 CBF1       set 6, c	:C
	:;

1133:C
1133 FE0D       cp $0D	:C
	:;

1135:C
1135 280C       jr z, $1143	:C
	:; forward to V-STR-VAR
	:;

1137:C
1137 CBE9       set 5, c	:C
	:;
	:;

1139:C
	:#;; V-CHAR
1139 CDD214     call $14D2	:C V_CHAR
	:; routine ALPHANUM

113C:C
113C 300A       jr nc, $1148	:C
	:; forward when not to V-RUN/SYN
	:;

113E:C
113E CBB1       res 6, c	:C
	:;
	:;

1140:C
1140 E7         rst $20	:C
	:; NEXT-CHAR

1141:C
1141 18F6       jr $1139	:C
	:; loop back to V-CHAR
	:;

1143:C
	:#; ---
	:#
	:#;; V-STR-VAR
1143 E7         rst $20	:C V_STR_VAR
	:; NEXT-CHAR

1144:C
1144 FDCB01B6   res 6, (iy+$01)	:C
	:; sv FLAGS  - Signal string result
	:;

1148:C
	:#;; V-RUN/SYN
1148 41         ld b, c	:C V_RUN_SYN
	:;

1149:C
1149 CDA60D     call $0DA6	:C
	:; routine SYNTAX-Z

114C:C
114C 2008       jr nz, $1156	:C
	:; forward to V-RUN
	:;

114E:C
114E 79         ld a, c	:C
	:;

114F:C
114F E6E0       and $E0	:C
	:;

1151:C
1151 CBFF       set 7, a	:C
	:;

1153:C
1153 4F         ld c, a	:C
	:;

1154:C
1154 1834       jr $118A	:C
	:; forward to V-SYNTAX
	:;

1156:C
	:#; ---
	:#
	:#;; V-RUN
1156 2A1040     ld hl, ($4010)	:C V_RUN
	:; sv VARS
	:;

1159:C
	:#;; V-EACH
1159 7E         ld a, (hl)	:C V_EACH
	:;

115A:C
115A E67F       and $7F	:C
	:;

115C:C
115C 282A       jr z, $1188	:C
	:; to V-80-BYTE
	:;

115E:C
115E B9         cp c	:C
	:;

115F:C
115F 201F       jr nz, $1180	:C
	:; to V-NEXT
	:;

1161:C
1161 17         rla	:C
	:;

1162:C
1162 87         add a, a	:C
	:;

1163:C
1163 F29511     jp p, $1195	:C
	:; to V-FOUND-2
	:;

1166:C
1166 382D       jr c, $1195	:C
	:; to V-FOUND-2
	:;

1168:C
1168 D1         pop de	:C
	:;

1169:C
1169 D5         push de	:C
	:;

116A:C
116A E5         push hl	:C
	:;
	:;

116B:C
	:#;; V-MATCHES
116B 23         inc hl	:C V_MATCHES
	:;
	:;

116C:C
	:#;; V-SPACES
116C 1A         ld a, (de)	:C V_SPACES
	:;

116D:C
116D 13         inc de	:C
	:;

116E:C
116E A7         and a	:C
	:;

116F:C
116F 28FB       jr z, $116C	:C
	:; back to V-SPACES
	:;

1171:C
1171 BE         cp (hl)	:C
	:;

1172:C
1172 28F7       jr z, $116B	:C
	:; back to V-MATCHES
	:;

1174:C
1174 F680       or $80	:C
	:;

1176:C
1176 BE         cp (hl)	:C
	:;

1177:C
1177 2006       jr nz, $117F	:C
	:; forward to V-GET-PTR
	:;

1179:C
1179 1A         ld a, (de)	:C
	:;

117A:C
117A CDD214     call $14D2	:C
	:; routine ALPHANUM

117D:C
117D 3015       jr nc, $1194	:C
	:; forward to V-FOUND-1
	:;

117F:C
	:#;; V-GET-PTR
117F E1         pop hl	:C V_GET_PTR
	:;
	:;

1180:C
	:#;; V-NEXT
1180 C5         push bc	:C V_NEXT
	:;

1181:C
1181 CDF209     call $09F2	:C
	:; routine NEXT-ONE

1184:C
1184 EB         ex de, hl	:C
	:;

1185:C
1185 C1         pop bc	:C
	:;

1186:C
1186 18D1       jr $1159	:C
	:; back to V-EACH
	:;

1188:C
	:#; ---
	:#
	:#;; V-80-BYTE
1188 CBF8       set 7, b	:C V_80_BYTE
	:;
	:;

118A:C
	:#;; V-SYNTAX
118A D1         pop de	:C V_SYNTAX
	:;
	:;

118B:C
118B DF         rst $18	:C
	:; GET-CHAR

118C:C
118C FE10       cp $10	:C
	:;

118E:C
118E 2809       jr z, $1199	:C
	:; forward to V-PASS
	:;

1190:C
1190 CBE8       set 5, b	:C
	:;

1192:C
1192 180D       jr $11A1	:C
	:; forward to V-END
	:;

1194:C
	:#; ---
	:#
	:#;; V-FOUND-1
1194 D1         pop de	:C V_FOUND_1
	:;
	:;

1195:C
	:#;; V-FOUND-2
1195 D1         pop de	:C V_FOUND_2
	:;

1196:C
1196 D1         pop de	:C
	:;

1197:C
1197 E5         push hl	:C
	:;
	:;

1198:C
1198 DF         rst $18	:C
	:; GET-CHAR
	:;

1199:C
	:#;; V-PASS
1199 CDD214     call $14D2	:C V_PASS
	:; routine ALPHANUM

119C:C
119C 3003       jr nc, $11A1	:C
	:; forward if not alphanumeric to V-END
	:;
	:;

119E:C
119E E7         rst $20	:C
	:; NEXT-CHAR

119F:C
119F 18F8       jr $1199	:C
	:; back to V-PASS
	:;

11A1:C
	:#; ---
	:#
	:#;; V-END
11A1 E1         pop hl	:C V_END
	:;

11A2:C
11A2 CB10       rl b	:C
	:;

11A4:C
11A4 CB70       bit 6, b	:C
	:;

11A6:C
11A6 C9         ret	:C
	:;
	:;

11A7:C
	:#; ------------------------
	:#; THE 'STK-VAR' SUBROUTINE
	:#; ------------------------
	:#;
	:#;
	:#
	:#;; STK-VAR
11A7 AF         xor a	:C STK_VAR
	:;

11A8:C
11A8 47         ld b, a	:C
	:;

11A9:C
11A9 CB79       bit 7, c	:C
	:;

11AB:C
11AB 204B       jr nz, $11F8	:C
	:; forward to SV-COUNT
	:;

11AD:C
11AD CB7E       bit 7, (hl)	:C
	:;

11AF:C
11AF 200E       jr nz, $11BF	:C
	:; forward to SV-ARRAYS
	:;

11B1:C
11B1 3C         inc a	:C
	:;
	:;

11B2:C
	:#;; SV-SIMPLE$
11B2 23         inc hl	:C SV_SIMPLE_
	:;

11B3:C
11B3 4E         ld c, (hl)	:C
	:;

11B4:C
11B4 23         inc hl	:C
	:;

11B5:C
11B5 46         ld b, (hl)	:C
	:;

11B6:C
11B6 23         inc hl	:C
	:;

11B7:C
11B7 EB         ex de, hl	:C
	:;

11B8:C
11B8 CDC312     call $12C3	:C
	:; routine STK-STO-$
	:;

11BB:C
11BB DF         rst $18	:C
	:; GET-CHAR

11BC:C
11BC C35A12     jp $125A	:C
	:; jump forward to SV-SLICE?
	:;

11BF:C
	:#; ---
	:#
	:#;; SV-ARRAYS
11BF 23         inc hl	:C SV_ARRAYS
	:;

11C0:C
11C0 23         inc hl	:C
	:;

11C1:C
11C1 23         inc hl	:C
	:;

11C2:C
11C2 46         ld b, (hl)	:C
	:;

11C3:C
11C3 CB71       bit 6, c	:C
	:;

11C5:C
11C5 280A       jr z, $11D1	:C
	:; forward to SV-PTR
	:;

11C7:C
11C7 05         dec b	:C
	:;

11C8:C
11C8 28E8       jr z, $11B2	:C
	:; forward to SV-SIMPLE$
	:;

11CA:C
11CA EB         ex de, hl	:C
	:;
	:;

11CB:C
11CB DF         rst $18	:C
	:; GET-CHAR

11CC:C
11CC FE10       cp $10	:C
	:;

11CE:C
11CE 2061       jr nz, $1231	:C
	:; forward to REPORT-3
	:;

11D0:C
11D0 EB         ex de, hl	:C
	:;
	:;

11D1:C
	:#;; SV-PTR
11D1 EB         ex de, hl	:C SV_PTR
	:;

11D2:C
11D2 1824       jr $11F8	:C
	:; forward to SV-COUNT
	:;

11D4:C
	:#; ---
	:#
	:#;; SV-COMMA
11D4 E5         push hl	:C SV_COMMA
	:;
	:;

11D5:C
11D5 DF         rst $18	:C
	:; GET-CHAR

11D6:C
11D6 E1         pop hl	:C
	:;

11D7:C
11D7 FE1A       cp $1A	:C
	:;

11D9:C
11D9 2820       jr z, $11FB	:C
	:; forward to SV-LOOP
	:;

11DB:C
11DB CB79       bit 7, c	:C
	:;

11DD:C
11DD 2852       jr z, $1231	:C
	:; forward to REPORT-3
	:;

11DF:C
11DF CB71       bit 6, c	:C
	:;

11E1:C
11E1 2006       jr nz, $11E9	:C
	:; forward to SV-CLOSE
	:;

11E3:C
11E3 FE11       cp $11	:C
	:;

11E5:C
11E5 203C       jr nz, $1223	:C
	:; forward to SV-RPT-C
	:;
	:;

11E7:C
11E7 E7         rst $20	:C
	:; NEXT-CHAR

11E8:C
11E8 C9         ret	:C
	:;
	:;

11E9:C
	:#; ---
	:#
	:#;; SV-CLOSE
11E9 FE11       cp $11	:C SV_CLOSE
	:;

11EB:C
11EB 286C       jr z, $1259	:C
	:; forward to SV-DIM
	:;

11ED:C
11ED FEDF       cp $DF	:C
	:;

11EF:C
11EF 2032       jr nz, $1223	:C
	:; forward to SV-RPT-C
	:;
	:;

11F1:C
	:#;; SV-CH-ADD
11F1 DF         rst $18	:C SV_CH_ADD
	:; GET-CHAR

11F2:C
11F2 2B         dec hl	:C
	:;

11F3:C
11F3 221640     ld ($4016), hl	:C
	:; sv CH_ADD

11F6:C
11F6 185E       jr $1256	:C
	:; forward to SV-SLICE
	:;

11F8:C
	:#; ---
	:#
	:#;; SV-COUNT
11F8 210000     ld hl, $0000	:C SV_COUNT
	:;
	:;

11FB:C
	:#;; SV-LOOP
11FB E5         push hl	:C SV_LOOP
	:;
	:;

11FC:C
11FC E7         rst $20	:C
	:; NEXT-CHAR

11FD:C
11FD E1         pop hl	:C
	:;

11FE:C
11FE 79         ld a, c	:C
	:;

11FF:C
11FF FEC0       cp $C0	:C
	:;

1201:C
1201 2009       jr nz, $120C	:C
	:; forward to SV-MULT
	:;
	:;

1203:C
1203 DF         rst $18	:C
	:; GET-CHAR

1204:C
1204 FE11       cp $11	:C
	:;

1206:C
1206 2851       jr z, $1259	:C
	:; forward to SV-DIM
	:;

1208:C
1208 FEDF       cp $DF	:C
	:;

120A:C
120A 28E5       jr z, $11F1	:C
	:; back to SV-CH-ADD
	:;

120C:C
	:#;; SV-MULT
120C C5         push bc	:C SV_MULT
	:;

120D:C
120D E5         push hl	:C
	:;

120E:C
120E CDFF12     call $12FF	:C
	:; routine DE,(DE+1)

1211:C
1211 E3         ex (sp), hl	:C
	:;

1212:C
1212 EB         ex de, hl	:C
	:;

1213:C
1213 CDDD12     call $12DD	:C
	:; routine INT-EXP1

1216:C
1216 3819       jr c, $1231	:C
	:; forward to REPORT-3
	:;

1218:C
1218 0B         dec bc	:C
	:;

1219:C
1219 CD0513     call $1305	:C
	:; routine GET-HL*DE

121C:C
121C 09         add hl, bc	:C
	:;

121D:C
121D D1         pop de	:C
	:;

121E:C
121E C1         pop bc	:C
	:;

121F:C
121F 10B3       djnz $11D4	:C
	:; loop back to SV-COMMA
	:;

1221:C
1221 CB79       bit 7, c	:C
	:;
	:;

1223:C
	:#;; SV-RPT-C
1223 2066       jr nz, $128B	:C SV_RPT_C
	:; relative jump to SL-RPT-C
	:;

1225:C
1225 E5         push hl	:C
	:;

1226:C
1226 CB71       bit 6, c	:C
	:;

1228:C
1228 2013       jr nz, $123D	:C
	:; forward to SV-ELEM$
	:;

122A:C
122A 42         ld b, d	:C
	:;

122B:C
122B 4B         ld c, e	:C
	:;
	:;

122C:C
122C DF         rst $18	:C
	:; GET-CHAR

122D:C
122D FE11       cp $11	:C
	:; is character a ')' ?

122F:C
122F 2802       jr z, $1233	:C
	:; skip forward to SV-NUMBER
	:;
	:;

1231:C
	:#;; REPORT-3
1231 CF         rst $08	:C REPORT_3
	:; ERROR-1

1232:B
1232-1232 02	:B
	:; Error Report: Subscript wrong
	:;
	:;

1233:C
	:#;; SV-NUMBER
1233 E7         rst $20	:C SV_NUMBER
	:; NEXT-CHAR

1234:C
1234 E1         pop hl	:C
	:;

1235:C
1235 110500     ld de, $0005	:C
	:;

1238:C
1238 CD0513     call $1305	:C
	:; routine GET-HL*DE

123B:C
123B 09         add hl, bc	:C
	:;

123C:C
123C C9         ret	:C
	:; return                            >>
	:;

123D:C
	:#; ---
	:#
	:#;; SV-ELEM$
123D CDFF12     call $12FF	:C SV_ELEM_
	:; routine DE,(DE+1)

1240:C
1240 E3         ex (sp), hl	:C
	:;

1241:C
1241 CD0513     call $1305	:C
	:; routine GET-HL*DE

1244:C
1244 C1         pop bc	:C
	:;

1245:C
1245 09         add hl, bc	:C
	:;

1246:C
1246 23         inc hl	:C
	:;

1247:C
1247 42         ld b, d	:C
	:;

1248:C
1248 4B         ld c, e	:C
	:;

1249:C
1249 EB         ex de, hl	:C
	:;

124A:C
124A CDC212     call $12C2	:C
	:; routine STK-ST-0
	:;

124D:C
124D DF         rst $18	:C
	:; GET-CHAR

124E:C
124E FE11       cp $11	:C
	:; is it ')' ?

1250:C
1250 2807       jr z, $1259	:C
	:; forward if so to SV-DIM
	:;

1252:C
1252 FE1A       cp $1A	:C
	:; is it ',' ?

1254:C
1254 20DB       jr nz, $1231	:C
	:; back if not to REPORT-3
	:;

1256:C
	:#;; SV-SLICE
1256 CD6312     call $1263	:C SV_SLICE
	:; routine SLICING
	:;

1259:C
	:#;; SV-DIM
1259 E7         rst $20	:C SV_DIM
	:; NEXT-CHAR
	:;

125A:C
	:#;; SV-SLICE?
125A FE10       cp $10	:C SV_SLICE_
	:;

125C:C
125C 28F8       jr z, $1256	:C
	:; back to SV-SLICE
	:;

125E:C
125E FDCB01B6   res 6, (iy+$01)	:C
	:; sv FLAGS  - Signal string result

1262:C
1262 C9         ret	:C
	:; return.
	:;

1263:C
	:#; ------------------------
	:#; THE 'SLICING' SUBROUTINE
	:#; ------------------------
	:#;
	:#;
	:#
	:#;; SLICING
1263 CDA60D     call $0DA6	:C SLICING
	:; routine SYNTAX-Z

1266:C
1266 C4F813     call nz, $13F8	:C
	:; routine STK-FETCH
	:;

1269:C
1269 E7         rst $20	:C
	:; NEXT-CHAR

126A:C
126A FE11       cp $11	:C
	:; is it ')' ?

126C:C
126C 2850       jr z, $12BE	:C
	:; forward if so to SL-STORE
	:;

126E:C
126E D5         push de	:C
	:;

126F:C
126F AF         xor a	:C
	:;

1270:C
1270 F5         push af	:C
	:;

1271:C
1271 C5         push bc	:C
	:;

1272:C
1272 110100     ld de, $0001	:C
	:;
	:;

1275:C
1275 DF         rst $18	:C
	:; GET-CHAR

1276:C
1276 E1         pop hl	:C
	:;

1277:C
1277 FEDF       cp $DF	:C
	:; is it 'TO' ?

1279:C
1279 2817       jr z, $1292	:C
	:; forward if so to SL-SECOND
	:;

127B:C
127B F1         pop af	:C
	:;

127C:C
127C CDDE12     call $12DE	:C
	:; routine INT-EXP2

127F:C
127F F5         push af	:C
	:;

1280:C
1280 50         ld d, b	:C
	:;

1281:C
1281 59         ld e, c	:C
	:;

1282:C
1282 E5         push hl	:C
	:;
	:;

1283:C
1283 DF         rst $18	:C
	:; GET-CHAR

1284:C
1284 E1         pop hl	:C
	:;

1285:C
1285 FEDF       cp $DF	:C
	:; is it 'TO' ?

1287:C
1287 2809       jr z, $1292	:C
	:; forward if so to SL-SECOND
	:;

1289:C
1289 FE11       cp $11	:C
	:;
	:;

128B:C
	:#;; SL-RPT-C
128B C29A0D     jp nz, $0D9A	:C SL_RPT_C
	:; to REPORT-C
	:;

128E:C
128E 62         ld h, d	:C
	:;

128F:C
128F 6B         ld l, e	:C
	:;

1290:C
1290 1813       jr $12A5	:C
	:; forward to SL-DEFINE
	:;

1292:C
	:#; ---
	:#
	:#;; SL-SECOND
1292 E5         push hl	:C SL_SECOND
	:;
	:;

1293:C
1293 E7         rst $20	:C
	:; NEXT-CHAR

1294:C
1294 E1         pop hl	:C
	:;

1295:C
1295 FE11       cp $11	:C
	:; is it ')' ?

1297:C
1297 280C       jr z, $12A5	:C
	:; forward if so to SL-DEFINE
	:;

1299:C
1299 F1         pop af	:C
	:;

129A:C
129A CDDE12     call $12DE	:C
	:; routine INT-EXP2

129D:C
129D F5         push af	:C
	:;
	:;

129E:C
129E DF         rst $18	:C
	:; GET-CHAR

129F:C
129F 60         ld h, b	:C
	:;

12A0:C
12A0 69         ld l, c	:C
	:;

12A1:C
12A1 FE11       cp $11	:C
	:; is it ')' ?

12A3:C
12A3 20E6       jr nz, $128B	:C
	:; back if not to SL-RPT-C
	:;

12A5:C
	:#;; SL-DEFINE
12A5 F1         pop af	:C SL_DEFINE
	:;

12A6:C
12A6 E3         ex (sp), hl	:C
	:;

12A7:C
12A7 19         add hl, de	:C
	:;

12A8:C
12A8 2B         dec hl	:C
	:;

12A9:C
12A9 E3         ex (sp), hl	:C
	:;

12AA:C
12AA A7         and a	:C
	:;

12AB:C
12AB ED52       sbc hl, de	:C
	:;

12AD:C
12AD 010000     ld bc, $0000	:C
	:;

12B0:C
12B0 3807       jr c, $12B9	:C
	:; forward to SL-OVER
	:;

12B2:C
12B2 23         inc hl	:C
	:;

12B3:C
12B3 A7         and a	:C
	:;

12B4:C
12B4 FA3112     jp m, $1231	:C
	:; jump back to REPORT-3
	:;

12B7:C
12B7 44         ld b, h	:C
	:;

12B8:C
12B8 4D         ld c, l	:C
	:;
	:;

12B9:C
	:#;; SL-OVER
12B9 D1         pop de	:C SL_OVER
	:;

12BA:C
12BA FDCB01B6   res 6, (iy+$01)	:C
	:; sv FLAGS  - Signal string result
	:;

12BE:C
	:#;; SL-STORE
12BE CDA60D     call $0DA6	:C SL_STORE
	:; routine SYNTAX-Z

12C1:C
12C1 C8         ret z	:C
	:; return if checking syntax.
	:;

12C2:C
	:#; --------------------------
	:#; THE 'STK-STORE' SUBROUTINE
	:#; --------------------------
	:#;
	:#;
	:#
	:#;; STK-ST-0
12C2 AF         xor a	:C STK_ST_0
	:;
	:;

12C3:C
	:#;; STK-STO-$
12C3 C5         push bc	:C STK_STO__
	:;

12C4:C
12C4 CDEB19     call $19EB	:C
	:; routine TEST-5-SP

12C7:C
12C7 C1         pop bc	:C
	:;

12C8:C
12C8 2A1C40     ld hl, ($401C)	:C
	:; sv STKEND

12CB:C
12CB 77         ld (hl), a	:C
	:;

12CC:C
12CC 23         inc hl	:C
	:;

12CD:C
12CD 73         ld (hl), e	:C
	:;

12CE:C
12CE 23         inc hl	:C
	:;

12CF:C
12CF 72         ld (hl), d	:C
	:;

12D0:C
12D0 23         inc hl	:C
	:;

12D1:C
12D1 71         ld (hl), c	:C
	:;

12D2:C
12D2 23         inc hl	:C
	:;

12D3:C
12D3 70         ld (hl), b	:C
	:;

12D4:C
12D4 23         inc hl	:C
	:;

12D5:C
12D5 221C40     ld ($401C), hl	:C
	:; sv STKEND

12D8:C
12D8 FDCB01B6   res 6, (iy+$01)	:C
	:; update FLAGS - signal string result

12DC:C
12DC C9         ret	:C
	:; return.
	:;

12DD:C
	:#; -------------------------
	:#; THE 'INT EXP' SUBROUTINES
	:#; -------------------------
	:#;
	:#;
	:#
	:#;; INT-EXP1
12DD AF         xor a	:C INT_EXP1
	:;
	:;

12DE:C
	:#;; INT-EXP2
12DE D5         push de	:C INT_EXP2
	:;

12DF:C
12DF E5         push hl	:C
	:;

12E0:C
12E0 F5         push af	:C
	:;

12E1:C
12E1 CD920D     call $0D92	:C
	:; routine CLASS-6

12E4:C
12E4 F1         pop af	:C
	:;

12E5:C
12E5 CDA60D     call $0DA6	:C
	:; routine SYNTAX-Z

12E8:C
12E8 2812       jr z, $12FC	:C
	:; forward if checking syntax to I-RESTORE
	:;

12EA:C
12EA F5         push af	:C
	:;

12EB:C
12EB CDA70E     call $0EA7	:C
	:; routine FIND-INT

12EE:C
12EE D1         pop de	:C
	:;

12EF:C
12EF 78         ld a, b	:C
	:;

12F0:C
12F0 B1         or c	:C
	:;

12F1:C
12F1 37         scf	:C
	:; Set Carry Flag

12F2:C
12F2 2805       jr z, $12F9	:C
	:; forward to I-CARRY
	:;

12F4:C
12F4 E1         pop hl	:C
	:;

12F5:C
12F5 E5         push hl	:C
	:;

12F6:C
12F6 A7         and a	:C
	:;

12F7:C
12F7 ED42       sbc hl, bc	:C
	:;
	:;

12F9:C
	:#;; I-CARRY
12F9 7A         ld a, d	:C I_CARRY
	:;

12FA:C
12FA DE00       sbc a, $00	:C
	:;
	:;

12FC:C
	:#;; I-RESTORE
12FC E1         pop hl	:C I_RESTORE
	:;

12FD:C
12FD D1         pop de	:C
	:;

12FE:C
12FE C9         ret	:C
	:;
	:;

12FF:C
	:#; --------------------------
	:#; THE 'DE,(DE+1)' SUBROUTINE
	:#; --------------------------
	:#; INDEX and LOAD Z80 subroutine. 
	:#; This emulates the 6800 processor instruction LDX 1,X which loads a two-byte
	:#; value from memory into the register indexing it. Often these are hardly worth
	:#; the bother of writing as subroutines and this one doesn't save any time or 
	:#; memory. The timing and space overheads have to be offset against the ease of
	:#; writing and the greater program readability from using such toolkit routines.
	:#
	:#;; DE,(DE+1)
12FF EB         ex de, hl	:C DE__DE_1_
	:; move index address into HL.

1300:C
1300 23         inc hl	:C
	:; increment to address word.

1301:C
1301 5E         ld e, (hl)	:C
	:; pick up word low-order byte.

1302:C
1302 23         inc hl	:C
	:; index high-order byte and 

1303:C
1303 56         ld d, (hl)	:C
	:; pick it up.

1304:C
1304 C9         ret	:C
	:; return with DE = word.
	:;

1305:C
	:#; --------------------------
	:#; THE 'GET-HL*DE' SUBROUTINE
	:#; --------------------------
	:#;
	:#
	:#;; GET-HL*DE
1305 CDA60D     call $0DA6	:C GET_HL_DE
	:; routine SYNTAX-Z

1308:C
1308 C8         ret z	:C
	:;
	:;

1309:C
1309 C5         push bc	:C
	:;

130A:C
130A 0610       ld b, $10	:C
	:;

130C:C
130C 7C         ld a, h	:C
	:;

130D:C
130D 4D         ld c, l	:C
	:;

130E:C
130E 210000     ld hl, $0000	:C
	:;
	:;

1311:C
	:#;; HL-LOOP
1311 29         add hl, hl	:C HL_LOOP
	:;

1312:C
1312 3806       jr c, $131A	:C
	:; forward with carry to HL-END
	:;

1314:C
1314 CB11       rl c	:C
	:;

1316:C
1316 17         rla	:C
	:;

1317:C
1317 3004       jr nc, $131D	:C
	:; forward with no carry to HL-AGAIN
	:;

1319:C
1319 19         add hl, de	:C
	:;
	:;

131A:C
	:#;; HL-END
131A DAD30E     jp c, $0ED3	:C HL_END
	:; to REPORT-4
	:;

131D:C
	:#;; HL-AGAIN
131D 10F2       djnz $1311	:C HL_AGAIN
	:; loop back to HL-LOOP
	:;

131F:C
131F C1         pop bc	:C
	:;

1320:C
1320 C9         ret	:C
	:; return.
	:;

1321:C
	:#; --------------------
	:#; THE 'LET' SUBROUTINE
	:#; --------------------
	:#;
	:#;
	:#
	:#;; LET
1321 2A1240     ld hl, ($4012)	:C LET
	:; sv DEST-lo

1324:C
1324 FDCB2D4E   bit 1, (iy+$2D)	:C
	:; sv FLAGX

1328:C
1328 2844       jr z, $136E	:C
	:; forward to L-EXISTS
	:;

132A:C
132A 010500     ld bc, $0005	:C
	:;
	:;

132D:C
	:#;; L-EACH-CH
132D 03         inc bc	:C L_EACH_CH
	:;
	:;

132E:C
	:#; check
	:#
	:#;; L-NO-SP
132E 23         inc hl	:C L_NO_SP
	:;

132F:C
132F 7E         ld a, (hl)	:C
	:;

1330:C
1330 A7         and a	:C
	:;

1331:C
1331 28FB       jr z, $132E	:C
	:; back to L-NO-SP
	:;

1333:C
1333 CDD214     call $14D2	:C
	:; routine ALPHANUM

1336:C
1336 38F5       jr c, $132D	:C
	:; back to L-EACH-CH
	:;

1338:C
1338 FE0D       cp $0D	:C
	:; is it '$' ?

133A:C
133A CAC813     jp z, $13C8	:C
	:; forward if so to L-NEW$
	:;
	:;

133D:C
133D F7         rst $30	:C
	:; BC-SPACES

133E:C
133E D5         push de	:C
	:;

133F:C
133F 2A1240     ld hl, ($4012)	:C
	:; sv DEST

1342:C
1342 1B         dec de	:C
	:;

1343:C
1343 79         ld a, c	:C
	:;

1344:C
1344 D606       sub $06	:C
	:;

1346:C
1346 47         ld b, a	:C
	:;

1347:C
1347 3E40       ld a, $40	:C
	:;

1349:C
1349 280E       jr z, $1359	:C
	:; forward to L-SINGLE
	:;

134B:C
	:#;; L-CHAR
134B 23         inc hl	:C L_CHAR
	:;

134C:C
134C 7E         ld a, (hl)	:C
	:;

134D:C
134D A7         and a	:C
	:; is it a space ?

134E:C
134E 28FB       jr z, $134B	:C
	:; back to L-CHAR
	:;

1350:C
1350 13         inc de	:C
	:;

1351:C
1351 12         ld (de), a	:C
	:;

1352:C
1352 10F7       djnz $134B	:C
	:; loop back to L-CHAR
	:;

1354:C
1354 F680       or $80	:C
	:;

1356:C
1356 12         ld (de), a	:C
	:;

1357:C
1357 3E80       ld a, $80	:C
	:;
	:;

1359:C
	:#;; L-SINGLE
1359 2A1240     ld hl, ($4012)	:C L_SINGLE
	:; sv DEST-lo

135C:C
135C AE         xor (hl)	:C
	:;

135D:C
135D E1         pop hl	:C
	:;

135E:C
135E CDE713     call $13E7	:C
	:; routine L-FIRST
	:;

1361:C
	:#;; L-NUMERIC
1361 E5         push hl	:C L_NUMERIC
	:;
	:;

1362:C
1362 EF         rst $28	:C
	:;; FP-CALC

1363:B
1363-1363 02	:B
	:;;delete

1364:B
1364-1364 34	:B
	:;;end-calc
	:;

1365:C
1365 E1         pop hl	:C
	:;

1366:C
1366 010500     ld bc, $0005	:C
	:;

1369:C
1369 A7         and a	:C
	:;

136A:C
136A ED42       sbc hl, bc	:C
	:;

136C:C
136C 1840       jr $13AE	:C
	:; forward to L-ENTER
	:;

136E:C
	:#; ---
	:#
	:#;; L-EXISTS
136E FDCB0176   bit 6, (iy+$01)	:C L_EXISTS
	:; sv FLAGS  - Numeric or string result?

1372:C
1372 2806       jr z, $137A	:C
	:; forward to L-DELETE$
	:;

1374:C
1374 110600     ld de, $0006	:C
	:;

1377:C
1377 19         add hl, de	:C
	:;

1378:C
1378 18E7       jr $1361	:C
	:; back to L-NUMERIC
	:;

137A:C
	:#; ---
	:#
	:#;; L-DELETE$
137A 2A1240     ld hl, ($4012)	:C L_DELETE_
	:; sv DEST-lo

137D:C
137D ED4B2E40   ld bc, ($402E)	:C
	:; sv STRLEN_lo

1381:C
1381 FDCB2D46   bit 0, (iy+$2D)	:C
	:; sv FLAGX

1385:C
1385 2030       jr nz, $13B7	:C
	:; forward to L-ADD$
	:;

1387:C
1387 78         ld a, b	:C
	:;

1388:C
1388 B1         or c	:C
	:;

1389:C
1389 C8         ret z	:C
	:;
	:;

138A:C
138A E5         push hl	:C
	:;
	:;

138B:C
138B F7         rst $30	:C
	:; BC-SPACES

138C:C
138C D5         push de	:C
	:;

138D:C
138D C5         push bc	:C
	:;

138E:C
138E 54         ld d, h	:C
	:;

138F:C
138F 5D         ld e, l	:C
	:;

1390:C
1390 23         inc hl	:C
	:;

1391:C
1391 3600       ld (hl), $00	:C
	:;

1393:C
1393 EDB8       lddr	:C
	:; Copy Bytes

1395:C
1395 E5         push hl	:C
	:;

1396:C
1396 CDF813     call $13F8	:C
	:; routine STK-FETCH

1399:C
1399 E1         pop hl	:C
	:;

139A:C
139A E3         ex (sp), hl	:C
	:;

139B:C
139B A7         and a	:C
	:;

139C:C
139C ED42       sbc hl, bc	:C
	:;

139E:C
139E 09         add hl, bc	:C
	:;

139F:C
139F 3002       jr nc, $13A3	:C
	:; forward to L-LENGTH
	:;

13A1:C
13A1 44         ld b, h	:C
	:;

13A2:C
13A2 4D         ld c, l	:C
	:;
	:;

13A3:C
	:#;; L-LENGTH
13A3 E3         ex (sp), hl	:C L_LENGTH
	:;

13A4:C
13A4 EB         ex de, hl	:C
	:;

13A5:C
13A5 78         ld a, b	:C
	:;

13A6:C
13A6 B1         or c	:C
	:;

13A7:C
13A7 2802       jr z, $13AB	:C
	:; forward if zero to L-IN-W/S
	:;

13A9:C
13A9 EDB0       ldir	:C
	:; Copy Bytes
	:;

13AB:C
	:#;; L-IN-W/S
13AB C1         pop bc	:C L_IN_W_S
	:;

13AC:C
13AC D1         pop de	:C
	:;

13AD:C
13AD E1         pop hl	:C
	:;
	:;

13AE:C
	:#; ------------------------
	:#; THE 'L-ENTER' SUBROUTINE
	:#; ------------------------
	:#;
	:#
	:#;; L-ENTER
13AE EB         ex de, hl	:C L_ENTER
	:;

13AF:C
13AF 78         ld a, b	:C
	:;

13B0:C
13B0 B1         or c	:C
	:;

13B1:C
13B1 C8         ret z	:C
	:;
	:;

13B2:C
13B2 D5         push de	:C
	:;

13B3:C
13B3 EDB0       ldir	:C
	:; Copy Bytes

13B5:C
13B5 E1         pop hl	:C
	:;

13B6:C
13B6 C9         ret	:C
	:; return.
	:;

13B7:C
	:#; ---
	:#
	:#;; L-ADD$
13B7 2B         dec hl	:C L_ADD_
	:;

13B8:C
13B8 2B         dec hl	:C
	:;

13B9:C
13B9 2B         dec hl	:C
	:;

13BA:C
13BA 7E         ld a, (hl)	:C
	:;

13BB:C
13BB E5         push hl	:C
	:;

13BC:C
13BC C5         push bc	:C
	:;
	:;

13BD:C
13BD CDCE13     call $13CE	:C
	:; routine L-STRING
	:;

13C0:C
13C0 C1         pop bc	:C
	:;

13C1:C
13C1 E1         pop hl	:C
	:;

13C2:C
13C2 03         inc bc	:C
	:;

13C3:C
13C3 03         inc bc	:C
	:;

13C4:C
13C4 03         inc bc	:C
	:;

13C5:C
13C5 C3600A     jp $0A60	:C
	:; jump back to exit via RECLAIM-2
	:;

13C8:C
	:#; ---
	:#
	:#;; L-NEW$
13C8 3E60       ld a, $60	:C L_NEW_
	:; prepare mask %01100000

13CA:C
13CA 2A1240     ld hl, ($4012)	:C
	:; sv DEST-lo

13CD:C
13CD AE         xor (hl)	:C
	:;
	:;

13CE:C
	:#; -------------------------
	:#; THE 'L-STRING' SUBROUTINE
	:#; -------------------------
	:#;
	:#
	:#;; L-STRING
13CE F5         push af	:C L_STRING
	:;

13CF:C
13CF CDF813     call $13F8	:C
	:; routine STK-FETCH

13D2:C
13D2 EB         ex de, hl	:C
	:;

13D3:C
13D3 09         add hl, bc	:C
	:;

13D4:C
13D4 E5         push hl	:C
	:;

13D5:C
13D5 03         inc bc	:C
	:;

13D6:C
13D6 03         inc bc	:C
	:;

13D7:C
13D7 03         inc bc	:C
	:;
	:;

13D8:C
13D8 F7         rst $30	:C
	:; BC-SPACES

13D9:C
13D9 EB         ex de, hl	:C
	:;

13DA:C
13DA E1         pop hl	:C
	:;

13DB:C
13DB 0B         dec bc	:C
	:;

13DC:C
13DC 0B         dec bc	:C
	:;

13DD:C
13DD C5         push bc	:C
	:;

13DE:C
13DE EDB8       lddr	:C
	:; Copy Bytes

13E0:C
13E0 EB         ex de, hl	:C
	:;

13E1:C
13E1 C1         pop bc	:C
	:;

13E2:C
13E2 0B         dec bc	:C
	:;

13E3:C
13E3 70         ld (hl), b	:C
	:;

13E4:C
13E4 2B         dec hl	:C
	:;

13E5:C
13E5 71         ld (hl), c	:C
	:;

13E6:C
13E6 F1         pop af	:C
	:;
	:;

13E7:C
	:#;; L-FIRST
13E7 F5         push af	:C L_FIRST
	:;

13E8:C
13E8 CDC714     call $14C7	:C
	:; routine REC-V80

13EB:C
13EB F1         pop af	:C
	:;

13EC:C
13EC 2B         dec hl	:C
	:;

13ED:C
13ED 77         ld (hl), a	:C
	:;

13EE:C
13EE 2A1A40     ld hl, ($401A)	:C
	:; sv STKBOT_lo

13F1:C
13F1 221440     ld ($4014), hl	:C
	:; sv E_LINE_lo

13F4:C
13F4 2B         dec hl	:C
	:;

13F5:C
13F5 3680       ld (hl), $80	:C
	:;

13F7:C
13F7 C9         ret	:C
	:;
	:;

13F8:C
	:#; --------------------------
	:#; THE 'STK-FETCH' SUBROUTINE
	:#; --------------------------
	:#; This routine fetches a five-byte value from the calculator stack
	:#; reducing the pointer to the end of the stack by five.
	:#; For a floating-point number the exponent is in A and the mantissa
	:#; is the thirty-two bits EDCB.
	:#; For strings, the start of the string is in DE and the length in BC.
	:#; A is unused.
	:#
	:#;; STK-FETCH
13F8 2A1C40     ld hl, ($401C)	:C STK_FETCH
	:; load HL from system variable STKEND
	:;

13FB:C
13FB 2B         dec hl	:C
	:;

13FC:C
13FC 46         ld b, (hl)	:C
	:;

13FD:C
13FD 2B         dec hl	:C
	:;

13FE:C
13FE 4E         ld c, (hl)	:C
	:;

13FF:C
13FF 2B         dec hl	:C
	:;

1400:C
1400 56         ld d, (hl)	:C
	:;

1401:C
1401 2B         dec hl	:C
	:;

1402:C
1402 5E         ld e, (hl)	:C
	:;

1403:C
1403 2B         dec hl	:C
	:;

1404:C
1404 7E         ld a, (hl)	:C
	:;
	:;

1405:C
1405 221C40     ld ($401C), hl	:C
	:; set system variable STKEND to lower value.

1408:C
1408 C9         ret	:C
	:; return.
	:;

1409:C
	:#; -------------------------
	:#; THE 'DIM' COMMAND ROUTINE
	:#; -------------------------
	:#; An array is created and initialized to zeros which is also the space
	:#; character on the ZX81.
	:#
	:#;; DIM
1409 CD1C11     call $111C	:C DIM
	:; routine LOOK-VARS
	:;

140C:C
	:#;; D-RPORT-C
140C C29A0D     jp nz, $0D9A	:C D_RPORT_C
	:; to REPORT-C
	:;

140F:C
140F CDA60D     call $0DA6	:C
	:; routine SYNTAX-Z

1412:C
1412 2008       jr nz, $141C	:C
	:; forward to D-RUN
	:;

1414:C
1414 CBB1       res 6, c	:C
	:;

1416:C
1416 CDA711     call $11A7	:C
	:; routine STK-VAR

1419:C
1419 CD1D0D     call $0D1D	:C
	:; routine CHECK-END
	:;

141C:C
	:#;; D-RUN
141C 3808       jr c, $1426	:C D_RUN
	:; forward to D-LETTER
	:;

141E:C
141E C5         push bc	:C
	:;

141F:C
141F CDF209     call $09F2	:C
	:; routine NEXT-ONE

1422:C
1422 CD600A     call $0A60	:C
	:; routine RECLAIM-2

1425:C
1425 C1         pop bc	:C
	:;
	:;

1426:C
	:#;; D-LETTER
1426 CBF9       set 7, c	:C D_LETTER
	:;

1428:C
1428 0600       ld b, $00	:C
	:;

142A:C
142A C5         push bc	:C
	:;

142B:C
142B 210100     ld hl, $0001	:C
	:;

142E:C
142E CB71       bit 6, c	:C
	:;

1430:C
1430 2002       jr nz, $1434	:C
	:; forward to D-SIZE
	:;

1432:C
1432 2E05       ld l, $05	:C
	:;
	:;

1434:C
	:#;; D-SIZE
1434 EB         ex de, hl	:C D_SIZE
	:;
	:;

1435:C
	:#;; D-NO-LOOP
1435 E7         rst $20	:C D_NO_LOOP
	:; NEXT-CHAR

1436:C
1436 2640       ld h, $40	:C
	:;

1438:C
1438 CDDD12     call $12DD	:C
	:; routine INT-EXP1

143B:C
143B DA3112     jp c, $1231	:C
	:; jump back to REPORT-3
	:;

143E:C
143E E1         pop hl	:C
	:;

143F:C
143F C5         push bc	:C
	:;

1440:C
1440 24         inc h	:C
	:;

1441:C
1441 E5         push hl	:C
	:;

1442:C
1442 60         ld h, b	:C
	:;

1443:C
1443 69         ld l, c	:C
	:;

1444:C
1444 CD0513     call $1305	:C
	:; routine GET-HL*DE

1447:C
1447 EB         ex de, hl	:C
	:;
	:;

1448:C
1448 DF         rst $18	:C
	:; GET-CHAR

1449:C
1449 FE1A       cp $1A	:C
	:;

144B:C
144B 28E8       jr z, $1435	:C
	:; back to D-NO-LOOP
	:;

144D:C
144D FE11       cp $11	:C
	:; is it ')' ?

144F:C
144F 20BB       jr nz, $140C	:C
	:; back if not to D-RPORT-C
	:;
	:;

1451:C
1451 E7         rst $20	:C
	:; NEXT-CHAR

1452:C
1452 C1         pop bc	:C
	:;

1453:C
1453 79         ld a, c	:C
	:;

1454:C
1454 68         ld l, b	:C
	:;

1455:C
1455 2600       ld h, $00	:C
	:;

1457:C
1457 23         inc hl	:C
	:;

1458:C
1458 23         inc hl	:C
	:;

1459:C
1459 29         add hl, hl	:C
	:;

145A:C
145A 19         add hl, de	:C
	:;

145B:C
145B DAD30E     jp c, $0ED3	:C
	:; jump to REPORT-4
	:;

145E:C
145E D5         push de	:C
	:;

145F:C
145F C5         push bc	:C
	:;

1460:C
1460 E5         push hl	:C
	:;

1461:C
1461 44         ld b, h	:C
	:;

1462:C
1462 4D         ld c, l	:C
	:;

1463:C
1463 2A1440     ld hl, ($4014)	:C
	:; sv E_LINE_lo

1466:C
1466 2B         dec hl	:C
	:;

1467:C
1467 CD9E09     call $099E	:C
	:; routine MAKE-ROOM

146A:C
146A 23         inc hl	:C
	:;

146B:C
146B 77         ld (hl), a	:C
	:;

146C:C
146C C1         pop bc	:C
	:;

146D:C
146D 0B         dec bc	:C
	:;

146E:C
146E 0B         dec bc	:C
	:;

146F:C
146F 0B         dec bc	:C
	:;

1470:C
1470 23         inc hl	:C
	:;

1471:C
1471 71         ld (hl), c	:C
	:;

1472:C
1472 23         inc hl	:C
	:;

1473:C
1473 70         ld (hl), b	:C
	:;

1474:C
1474 F1         pop af	:C
	:;

1475:C
1475 23         inc hl	:C
	:;

1476:C
1476 77         ld (hl), a	:C
	:;

1477:C
1477 62         ld h, d	:C
	:;

1478:C
1478 6B         ld l, e	:C
	:;

1479:C
1479 1B         dec de	:C
	:;

147A:C
147A 3600       ld (hl), $00	:C
	:;

147C:C
147C C1         pop bc	:C
	:;

147D:C
147D EDB8       lddr	:C
	:; Copy Bytes
	:;

147F:C
	:#;; DIM-SIZES
147F C1         pop bc	:C DIM_SIZES
	:;

1480:C
1480 70         ld (hl), b	:C
	:;

1481:C
1481 2B         dec hl	:C
	:;

1482:C
1482 71         ld (hl), c	:C
	:;

1483:C
1483 2B         dec hl	:C
	:;

1484:C
1484 3D         dec a	:C
	:;

1485:C
1485 20F8       jr nz, $147F	:C
	:; back to DIM-SIZES
	:;

1487:C
1487 C9         ret	:C
	:; return.
	:;

1488:C
	:#; ---------------------
	:#; THE 'RESERVE' ROUTINE
	:#; ---------------------
	:#;
	:#;
	:#
	:#;; RESERVE
1488 2A1A40     ld hl, ($401A)	:C RESERVE
	:; address STKBOT

148B:C
148B 2B         dec hl	:C
	:; now last byte of workspace

148C:C
148C CD9E09     call $099E	:C
	:; routine MAKE-ROOM

148F:C
148F 23         inc hl	:C
	:;

1490:C
1490 23         inc hl	:C
	:;

1491:C
1491 C1         pop bc	:C
	:;

1492:C
1492 ED431440   ld ($4014), bc	:C
	:; sv E_LINE_lo

1496:C
1496 C1         pop bc	:C
	:;

1497:C
1497 EB         ex de, hl	:C
	:;

1498:C
1498 23         inc hl	:C
	:;

1499:C
1499 C9         ret	:C
	:;
	:;

149A:C
	:#; ---------------------------
	:#; THE 'CLEAR' COMMAND ROUTINE
	:#; ---------------------------
	:#;
	:#;
	:#
	:#;; CLEAR
149A 2A1040     ld hl, ($4010)	:C CLEAR
	:; sv VARS_lo

149D:C
149D 3680       ld (hl), $80	:C
	:;

149F:C
149F 23         inc hl	:C
	:;

14A0:C
14A0 221440     ld ($4014), hl	:C
	:; sv E_LINE_lo
	:;

14A3:C
	:#; -----------------------
	:#; THE 'X-TEMP' SUBROUTINE
	:#; -----------------------
	:#;
	:#;
	:#
	:#;; X-TEMP
14A3 2A1440     ld hl, ($4014)	:C X_TEMP
	:; sv E_LINE_lo
	:;

14A6:C
	:#; ----------------------
	:#; THE 'SET-STK' ROUTINES
	:#; ----------------------
	:#;
	:#;
	:#
	:#;; SET-STK-B
14A6 221A40     ld ($401A), hl	:C SET_STK_B
	:; sv STKBOT
	:;

14A9:C
	:#;
	:#
	:#;; SET-STK-E
14A9 221C40     ld ($401C), hl	:C SET_STK_E
	:; sv STKEND

14AC:C
14AC C9         ret	:C
	:;
	:;

14AD:C
	:#; -----------------------
	:#; THE 'CURSOR-IN' ROUTINE
	:#; -----------------------
	:#; This routine is called to set the edit line to the minimum cursor/newline
	:#; and to set STKEND, the start of free space, at the next position.
	:#
	:#;; CURSOR-IN
14AD 2A1440     ld hl, ($4014)	:C CURSOR_IN
	:; fetch start of edit line from E_LINE

14B0:C
14B0 367F       ld (hl), $7F	:C
	:; insert cursor character
	:;

14B2:C
14B2 23         inc hl	:C
	:; point to next location.

14B3:C
14B3 3676       ld (hl), $76	:C
	:; insert NEWLINE character

14B5:C
14B5 23         inc hl	:C
	:; point to next free location.
	:;

14B6:C
14B6 FD362202   ld (iy+$22), $02	:C
	:; set lower screen display file size DF_SZ
	:;

14BA:C
14BA 18EA       jr $14A6	:C
	:; exit via SET-STK-B above
	:;

14BC:C
	:#; ------------------------
	:#; THE 'SET-MIN' SUBROUTINE
	:#; ------------------------
	:#;
	:#;
	:#
	:#;; SET-MIN
14BC 215D40     ld hl, $405D	:C SET_MIN
	:; normal location of calculator's memory area

14BF:C
14BF 221F40     ld ($401F), hl	:C
	:; update system variable MEM

14C2:C
14C2 2A1A40     ld hl, ($401A)	:C
	:; fetch STKBOT

14C5:C
14C5 18E2       jr $14A9	:C
	:; back to SET-STK-E
	:;
	:;

14C7:C
	:#; ------------------------------------
	:#; THE 'RECLAIM THE END-MARKER' ROUTINE
	:#; ------------------------------------
	:#
	:#;; REC-V80
14C7 ED5B1440   ld de, ($4014)	:C REC_V80
	:; sv E_LINE_lo

14CB:C
14CB C35D0A     jp $0A5D	:C
	:; to RECLAIM-1
	:;

14CE:C
	:#; ----------------------
	:#; THE 'ALPHA' SUBROUTINE
	:#; ----------------------
	:#
	:#;; ALPHA
14CE FE26       cp $26	:C ALPHA
	:;

14D0:C
14D0 1802       jr $14D4	:C
	:; skip forward to ALPHA-2
	:;
	:;

14D2:C
	:#; -------------------------
	:#; THE 'ALPHANUM' SUBROUTINE
	:#; -------------------------
	:#
	:#;; ALPHANUM
14D2 FE1C       cp $1C	:C ALPHANUM
	:;
	:;
	:;

14D4:C
	:#;; ALPHA-2
14D4 3F         ccf	:C ALPHA_2
	:; Complement Carry Flag

14D5:C
14D5 D0         ret nc	:C
	:;
	:;

14D6:C
14D6 FE40       cp $40	:C
	:;

14D8:C
14D8 C9         ret	:C
	:;
	:;
	:;

14D9:C
	:#; ------------------------------------------
	:#; THE 'DECIMAL TO FLOATING POINT' SUBROUTINE
	:#; ------------------------------------------
	:#;
	:#
	:#;; DEC-TO-FP
14D9 CD4815     call $1548	:C DEC_TO_FP
	:; routine INT-TO-FP gets first part

14DC:C
14DC FE1B       cp $1B	:C
	:; is character a '.' ?

14DE:C
14DE 2015       jr nz, $14F5	:C
	:; forward if not to E-FORMAT
	:;
	:;

14E0:C
14E0 EF         rst $28	:C
	:;; FP-CALC

14E1:B
14E1-14E1 A1	:B
	:;;stk-one

14E2:B
14E2-14E2 C0	:B
	:;;st-mem-0

14E3:B
14E3-14E3 02	:B
	:;;delete

14E4:B
14E4-14E4 34	:B
	:;;end-calc
	:;
	:;

14E5:C
	:#;; NXT-DGT-1
14E5 E7         rst $20	:C NXT_DGT_1
	:; NEXT-CHAR

14E6:C
14E6 CD1415     call $1514	:C
	:; routine STK-DIGIT

14E9:C
14E9 380A       jr c, $14F5	:C
	:; forward to E-FORMAT
	:;
	:;

14EB:C
14EB EF         rst $28	:C
	:;; FP-CALC

14EC:B
14EC-14EC E0	:B
	:;;get-mem-0

14ED:B
14ED-14ED A4	:B
	:;;stk-ten

14EE:B
14EE-14EE 05	:B
	:;;division

14EF:B
14EF-14EF C0	:B
	:;;st-mem-0

14F0:B
14F0-14F0 04	:B
	:;;multiply

14F1:B
14F1-14F1 0F	:B
	:;;addition

14F2:B
14F2-14F2 34	:B
	:;;end-calc
	:;

14F3:C
14F3 18F0       jr $14E5	:C
	:; loop back till exhausted to NXT-DGT-1
	:;

14F5:C
	:#; ---
	:#
	:#;; E-FORMAT
14F5 FE2A       cp $2A	:C E_FORMAT
	:; is character 'E' ?

14F7:C
14F7 C0         ret nz	:C
	:; return if not
	:;

14F8:C
14F8 FD365DFF   ld (iy+$5D), $FF	:C
	:; initialize sv MEM-0-1st to $FF TRUE
	:;

14FC:C
14FC E7         rst $20	:C
	:; NEXT-CHAR

14FD:C
14FD FE15       cp $15	:C
	:; is character a '+' ?

14FF:C
14FF 2807       jr z, $1508	:C
	:; forward if so to SIGN-DONE
	:;

1501:C
1501 FE16       cp $16	:C
	:; is it a '-' ?

1503:C
1503 2004       jr nz, $1509	:C
	:; forward if not to ST-E-PART
	:;

1505:C
1505 FD345D     inc (iy+$5D)	:C
	:; sv MEM-0-1st change to FALSE
	:;

1508:C
	:#;; SIGN-DONE
1508 E7         rst $20	:C SIGN_DONE
	:; NEXT-CHAR
	:;

1509:C
	:#;; ST-E-PART
1509 CD4815     call $1548	:C ST_E_PART
	:; routine INT-TO-FP
	:;

150C:C
150C EF         rst $28	:C
	:;; FP-CALC              m, e.

150D:B
150D-150D E0	:B
	:;;get-mem-0             m, e, (1/0) TRUE/FALSE

150E:B
150E-150E 00	:B
	:;;jump-true

150F:B
150F-150F 02	:B
	:;;to L1511, E-POSTVE

1510:B
1510-1510 18	:B
	:;;neg                   m, -e
	:;

1511:B
	:#;; E-POSTVE
1511-1511 38	:B E_POSTVE
	:;;e-to-fp               x.

1512:B
1512-1512 34	:B
	:;;end-calc              x.
	:;

1513:C
1513 C9         ret	:C
	:; return.
	:;
	:;

1514:C
	:#; --------------------------
	:#; THE 'STK-DIGIT' SUBROUTINE
	:#; --------------------------
	:#;
	:#
	:#;; STK-DIGIT
1514 FE1C       cp $1C	:C STK_DIGIT
	:;

1516:C
1516 D8         ret c	:C
	:;
	:;

1517:C
1517 FE26       cp $26	:C
	:;

1519:C
1519 3F         ccf	:C
	:; Complement Carry Flag

151A:C
151A D8         ret c	:C
	:;
	:;

151B:C
151B D61C       sub $1C	:C
	:;
	:;

151D:C
	:#; ------------------------
	:#; THE 'STACK-A' SUBROUTINE
	:#; ------------------------
	:#;
	:#
	:#
	:#;; STACK-A
151D 4F         ld c, a	:C STACK_A
	:;

151E:C
151E 0600       ld b, $00	:C
	:;
	:;

1520:C
	:#; -------------------------
	:#; THE 'STACK-BC' SUBROUTINE
	:#; -------------------------
	:#; The ZX81 does not have an integer number format so the BC register contents
	:#; must be converted to their full floating-point form.
	:#
	:#;; STACK-BC
1520 FD210040   ld iy, $4000	:C STACK_BC
	:; re-initialize the system variables pointer.

1524:C
1524 C5         push bc	:C
	:; save the integer value.
	:;

1525:C
	:#; now stack zero, five zero bytes as a starting point.
	:#
1525 EF         rst $28	:C
	:;; FP-CALC

1526:B
1526-1526 A0	:B
	:;;stk-zero                      0.

1527:B
1527-1527 34	:B
	:;;end-calc
	:;

1528:C
1528 C1         pop bc	:C
	:; restore integer value.
	:;

1529:C
1529 3691       ld (hl), $91	:C
	:; place $91 in exponent         65536.
	:; this is the maximum possible value
	:;

152B:C
152B 78         ld a, b	:C
	:; fetch hi-byte.

152C:C
152C A7         and a	:C
	:; test for zero.

152D:C
152D 2007       jr nz, $1536	:C
	:; forward if not zero to STK-BC-2
	:;

152F:C
152F 77         ld (hl), a	:C
	:; else make exponent zero again

1530:C
1530 B1         or c	:C
	:; test lo-byte

1531:C
1531 C8         ret z	:C
	:; return if BC was zero - done.
	:;

1532:C
	:#; else  there has to be a set bit if only the value one.
	:#
1532 41         ld b, c	:C
	:; save C in B.

1533:C
1533 4E         ld c, (hl)	:C
	:; fetch zero to C

1534:C
1534 3689       ld (hl), $89	:C
	:; make exponent $89             256.
	:;

1536:C
	:#;; STK-BC-2
1536 35         dec (hl)	:C STK_BC_2
	:; decrement exponent - halving number

1537:C
1537 CB21       sla c	:C
	:;  C<-76543210<-0

1539:C
1539 CB10       rl b	:C
	:;  C<-76543210<-C

153B:C
153B 30F9       jr nc, $1536	:C
	:; loop back if no carry to STK-BC-2
	:;

153D:C
153D CB38       srl b	:C
	:;  0->76543210->C

153F:C
153F CB19       rr c	:C
	:;  C->76543210->C
	:;

1541:C
1541 23         inc hl	:C
	:; address first byte of mantissa

1542:C
1542 70         ld (hl), b	:C
	:; insert B

1543:C
1543 23         inc hl	:C
	:; address second byte of mantissa

1544:C
1544 71         ld (hl), c	:C
	:; insert C
	:;

1545:C
1545 2B         dec hl	:C
	:; point to the

1546:C
1546 2B         dec hl	:C
	:; exponent again

1547:C
1547 C9         ret	:C
	:; return.
	:;

1548:C
	:#; ------------------------------------------
	:#; THE 'INTEGER TO FLOATING POINT' SUBROUTINE
	:#; ------------------------------------------
	:#;
	:#;
	:#
	:#;; INT-TO-FP
1548 F5         push af	:C INT_TO_FP
	:;
	:;

1549:C
1549 EF         rst $28	:C
	:;; FP-CALC

154A:B
154A-154A A0	:B
	:;;stk-zero

154B:B
154B-154B 34	:B
	:;;end-calc
	:;

154C:C
154C F1         pop af	:C
	:;
	:;

154D:C
	:#;; NXT-DGT-2
154D CD1415     call $1514	:C NXT_DGT_2
	:; routine STK-DIGIT

1550:C
1550 D8         ret c	:C
	:;
	:;
	:;

1551:C
1551 EF         rst $28	:C
	:;; FP-CALC

1552:B
1552-1552 01	:B
	:;;exchange

1553:B
1553-1553 A4	:B
	:;;stk-ten

1554:B
1554-1554 04	:B
	:;;multiply

1555:B
1555-1555 0F	:B
	:;;addition

1556:B
1556-1556 34	:B
	:;;end-calc
	:;
	:;

1557:C
1557 E7         rst $20	:C
	:; NEXT-CHAR

1558:C
1558 18F3       jr $154D	:C
	:; to NXT-DGT-2
	:;
	:;

155A:C
	:#; -------------------------------------------
	:#; THE 'E-FORMAT TO FLOATING POINT' SUBROUTINE
	:#; -------------------------------------------
	:#; (Offset $38: 'e-to-fp')
	:#; invoked from DEC-TO-FP and PRINT-FP.
	:#; e.g. 2.3E4 is 23000.
	:#; This subroutine evaluates xEm where m is a positive or negative integer.
	:#; At a simple level x is multiplied by ten for every unit of m.
	:#; If the decimal exponent m is negative then x is divided by ten for each unit.
	:#; A short-cut is taken if the exponent is greater than seven and in this
	:#; case the exponent is reduced by seven and the value is multiplied or divided
	:#; by ten million.
	:#; Note. for the ZX Spectrum an even cleverer method was adopted which involved
	:#; shifting the bits out of the exponent so the result was achieved with six
	:#; shifts at most. The routine below had to be completely re-written mostly
	:#; in Z80 machine code.
	:#; Although no longer operable, the calculator literal was retained for old
	:#; times sake, the routine being invoked directly from a machine code CALL.
	:#;
	:#; On entry in the ZX81, m, the exponent, is the 'last value', and the
	:#; floating-point decimal mantissa is beneath it.
	:#
	:#
	:#;; e-to-fp
155A EF         rst $28	:C e_to_fp
	:;; FP-CALC              x, m.

155B:B
155B-155B 2D	:B
	:;;duplicate             x, m, m.

155C:B
155C-155C 32	:B
	:;;less-0                x, m, (1/0).

155D:B
155D-155D C0	:B
	:;;st-mem-0              x, m, (1/0).

155E:B
155E-155E 02	:B
	:;;delete                x, m.

155F:B
155F-155F 27	:B
	:;;abs                   x, +m.
	:;

1560:B
	:#;; E-LOOP
1560-1560 A1	:B E_LOOP
	:;;stk-one               x, m,1.

1561:B
1561-1561 03	:B
	:;;subtract              x, m-1.

1562:B
1562-1562 2D	:B
	:;;duplicate             x, m-1,m-1.

1563:B
1563-1563 32	:B
	:;;less-0                x, m-1, (1/0).

1564:B
1564-1564 00	:B
	:;;jump-true             x, m-1.

1565:B
1565-1565 22	:B
	:;;to L1587, E-END       x, m-1.
	:;

1566:B
1566-1566 2D	:B
	:;;duplicate             x, m-1, m-1.

1567:B
1567-1567 30	:B
	:;;stk-data

1568:B
1568-1568 33	:B
	:;;Exponent: $83, Bytes: 1
	:;

1569:B
1569-1569 40	:B
	:;;(+00,+00,+00)         x, m-1, m-1, 6.

156A:B
156A-156A 03	:B
	:;;subtract              x, m-1, m-7.

156B:B
156B-156B 2D	:B
	:;;duplicate             x, m-1, m-7, m-7.

156C:B
156C-156C 32	:B
	:;;less-0                x, m-1, m-7, (1/0).

156D:B
156D-156D 00	:B
	:;;jump-true             x, m-1, m-7.

156E:B
156E-156E 0C	:B
	:;;to L157A, E-LOW
	:;

156F:B
	:#; but if exponent m is higher than 7 do a bigger chunk.
	:#; multiplying (or dividing if negative) by 10 million - 1e7.
	:#
156F-156F 01	:B
	:;;exchange              x, m-7, m-1.

1570:B
1570-1570 02	:B
	:;;delete                x, m-7.

1571:B
1571-1571 01	:B
	:;;exchange              m-7, x.

1572:B
1572-1572 30	:B
	:;;stk-data

1573:B
1573-1573 80	:B
	:;;Bytes: 3

1574:B
1574-1574 48	:B
	:;;Exponent $98

1575:B
1575-1577 189680	:B
	:;;(+00)                 m-7, x, 10,000,000 (=f)

1578:B
1578-1578 2F	:B
	:;;jump

1579:B
1579-1579 04	:B
	:;;to L157D, E-CHUNK
	:;

157A:B
	:#; ---
	:#
	:#;; E-LOW
157A-157A 02	:B E_LOW
	:;;delete                x, m-1.

157B:B
157B-157B 01	:B
	:;;exchange              m-1, x.

157C:B
157C-157C A4	:B
	:;;stk-ten               m-1, x, 10 (=f).
	:;

157D:B
	:#;; E-CHUNK
157D-157D E0	:B E_CHUNK
	:;;get-mem-0             m-1, x, f, (1/0)

157E:B
157E-157E 00	:B
	:;;jump-true             m-1, x, f

157F:B
157F-157F 04	:B
	:;;to L1583, E-DIVSN
	:;

1580:B
1580-1580 04	:B
	:;;multiply              m-1, x*f.

1581:B
1581-1581 2F	:B
	:;;jump

1582:B
1582-1582 02	:B
	:;;to L1584, E-SWAP
	:;

1583:B
	:#; ---
	:#
	:#;; E-DIVSN
1583-1583 05	:B E_DIVSN
	:;;division              m-1, x/f (= new x).
	:;

1584:B
	:#;; E-SWAP
1584-1584 01	:B E_SWAP
	:;;exchange              x, m-1 (= new m).

1585:B
1585-1585 2F	:B
	:;;jump                  x, m.

1586:B
1586-1586 DA	:B
	:;;to L1560, E-LOOP
	:;

1587:B
	:#; ---
	:#
	:#;; E-END
1587-1587 02	:B E_END
	:;;delete                x. (-1)

1588:B
1588-1588 34	:B
	:;;end-calc              x.
	:;

1589:C
1589 C9         ret	:C
	:; return.
	:;

158A:C
	:#; -------------------------------------
	:#; THE 'FLOATING-POINT TO BC' SUBROUTINE
	:#; -------------------------------------
	:#; The floating-point form on the calculator stack is compressed directly into
	:#; the BC register rounding up if necessary.
	:#; Valid range is 0 to 65535.4999
	:#
	:#;; FP-TO-BC
158A CDF813     call $13F8	:C FP_TO_BC
	:; routine STK-FETCH - exponent to A
	:; mantissa to EDCB.

158D:C
158D A7         and a	:C
	:; test for value zero.

158E:C
158E 2005       jr nz, $1595	:C
	:; forward if not to FPBC-NZRO
	:;

1590:C
	:#; else value is zero
	:#
1590 47         ld b, a	:C
	:; zero to B

1591:C
1591 4F         ld c, a	:C
	:; also to C

1592:C
1592 F5         push af	:C
	:; save the flags on machine stack

1593:C
1593 1831       jr $15C6	:C
	:; forward to FPBC-END
	:;

1595:C
	:#; ---
	:#
	:#; EDCB  =>  BCE
	:#
	:#;; FPBC-NZRO
1595 43         ld b, e	:C FPBC_NZRO
	:; transfer the mantissa from EDCB

1596:C
1596 59         ld e, c	:C
	:; to BCE. Bit 7 of E is the 17th bit which

1597:C
1597 4A         ld c, d	:C
	:; will be significant for rounding if the
	:; number is already normalized.
	:;

1598:C
1598 D691       sub $91	:C
	:; subtract 65536

159A:C
159A 3F         ccf	:C
	:; complement carry flag

159B:C
159B CB78       bit 7, b	:C
	:; test sign bit

159D:C
159D F5         push af	:C
	:; push the result
	:;

159E:C
159E CBF8       set 7, b	:C
	:; set the implied bit

15A0:C
15A0 3824       jr c, $15C6	:C
	:; forward with carry from SUB/CCF to FPBC-END
	:; number is too big.
	:;

15A2:C
15A2 3C         inc a	:C
	:; increment the exponent and

15A3:C
15A3 ED44       neg	:C
	:; negate to make range $00 - $0F
	:;

15A5:C
15A5 FE08       cp $08	:C
	:; test if one or two bytes

15A7:C
15A7 3806       jr c, $15AF	:C
	:; forward with two to BIG-INT
	:;

15A9:C
15A9 59         ld e, c	:C
	:; shift mantissa

15AA:C
15AA 48         ld c, b	:C
	:; 8 places right

15AB:C
15AB 0600       ld b, $00	:C
	:; insert a zero in B

15AD:C
15AD D608       sub $08	:C
	:; reduce exponent by eight
	:;

15AF:C
	:#;; BIG-INT
15AF A7         and a	:C BIG_INT
	:; test the exponent

15B0:C
15B0 57         ld d, a	:C
	:; save exponent in D.
	:;

15B1:C
15B1 7B         ld a, e	:C
	:; fractional bits to A

15B2:C
15B2 07         rlca	:C
	:; rotate most significant bit to carry for
	:; rounding of an already normal number.
	:;

15B3:C
15B3 2807       jr z, $15BC	:C
	:; forward if exponent zero to EXP-ZERO
	:; the number is normalized
	:;

15B5:C
	:#;; FPBC-NORM
15B5 CB38       srl b	:C FPBC_NORM
	:;   0->76543210->C

15B7:C
15B7 CB19       rr c	:C
	:;   C->76543210->C
	:;

15B9:C
15B9 15         dec d	:C
	:; decrement exponent
	:;

15BA:C
15BA 20F9       jr nz, $15B5	:C
	:; loop back till zero to FPBC-NORM
	:;

15BC:C
	:#;; EXP-ZERO
15BC 3008       jr nc, $15C6	:C EXP_ZERO
	:; forward without carry to NO-ROUND
	:;

15BE:C
15BE 03         inc bc	:C
	:; round up.

15BF:C
15BF 78         ld a, b	:C
	:; test result

15C0:C
15C0 B1         or c	:C
	:; for zero

15C1:C
15C1 2003       jr nz, $15C6	:C
	:; forward if not to GRE-ZERO
	:;

15C3:C
15C3 F1         pop af	:C
	:; restore sign flag

15C4:C
15C4 37         scf	:C
	:; set carry flag to indicate overflow

15C5:C
15C5 F5         push af	:C
	:; save combined flags again
	:;

15C6:C
	:#;; FPBC-END
15C6 C5         push bc	:C FPBC_END
	:; save BC value
	:;

15C7:C
	:#; set HL and DE to calculator stack pointers.
	:#
15C7 EF         rst $28	:C
	:;; FP-CALC

15C8:B
15C8-15C8 34	:B
	:;;end-calc
	:;
	:;

15C9:C
15C9 C1         pop bc	:C
	:; restore BC value

15CA:C
15CA F1         pop af	:C
	:; restore flags

15CB:C
15CB 79         ld a, c	:C
	:; copy low byte to A also.

15CC:C
15CC C9         ret	:C
	:; return
	:;

15CD:C
	:#; ------------------------------------
	:#; THE 'FLOATING-POINT TO A' SUBROUTINE
	:#; ------------------------------------
	:#;
	:#;
	:#
	:#;; FP-TO-A
15CD CD8A15     call $158A	:C FP_TO_A
	:; routine FP-TO-BC

15D0:C
15D0 D8         ret c	:C
	:;
	:;

15D1:C
15D1 F5         push af	:C
	:;

15D2:C
15D2 05         dec b	:C
	:;

15D3:C
15D3 04         inc b	:C
	:;

15D4:C
15D4 2803       jr z, $15D9	:C
	:; forward if in range to FP-A-END
	:;

15D6:C
15D6 F1         pop af	:C
	:; fetch result

15D7:C
15D7 37         scf	:C
	:; set carry flag signaling overflow

15D8:C
15D8 C9         ret	:C
	:; return
	:;

15D9:C
	:#;; FP-A-END
15D9 F1         pop af	:C FP_A_END
	:;

15DA:C
15DA C9         ret	:C
	:;
	:;
	:;

15DB:C
	:#; ----------------------------------------------
	:#; THE 'PRINT A FLOATING-POINT NUMBER' SUBROUTINE
	:#; ----------------------------------------------
	:#; prints 'last value' x on calculator stack.
	:#; There are a wide variety of formats see Chapter 4.
	:#; e.g. 
	:#; PI            prints as       3.1415927
	:#; .123          prints as       0.123
	:#; .0123         prints as       .0123
	:#; 999999999999  prints as       1000000000000
	:#; 9876543210123 prints as       9876543200000
	:#
	:#; Begin by isolating zero and just printing the '0' character
	:#; for that case. For negative numbers print a leading '-' and
	:#; then form the absolute value of x.
	:#
	:#;; PRINT-FP
15DB EF         rst $28	:C PRINT_FP
	:;; FP-CALC              x.

15DC:B
15DC-15DC 2D	:B
	:;;duplicate             x, x.

15DD:B
15DD-15DD 32	:B
	:;;less-0                x, (1/0).

15DE:B
15DE-15DE 00	:B
	:;;jump-true

15DF:B
15DF-15DF 0B	:B
	:;;to L15EA, PF-NGTVE    x.
	:;

15E0:B
15E0-15E0 2D	:B
	:;;duplicate             x, x

15E1:B
15E1-15E1 33	:B
	:;;greater-0             x, (1/0).

15E2:B
15E2-15E2 00	:B
	:;;jump-true

15E3:B
15E3-15E3 0D	:B
	:;;to L15F0, PF-POSTVE   x.
	:;

15E4:B
15E4-15E4 02	:B
	:;;delete                .

15E5:B
15E5-15E5 34	:B
	:;;end-calc              .
	:;

15E6:C
15E6 3E1C       ld a, $1C	:C
	:; load accumulator with character '0'
	:;

15E8:C
15E8 D7         rst $10	:C
	:; PRINT-A

15E9:C
15E9 C9         ret	:C
	:; return.                               >>
	:;

15EA:B
	:#; ---
	:#
	:#;; PF-NEGTVE
15EA-15EA 27	:B PF_NEGTVE
	:; abs                   +x.

15EB:B
15EB-15EB 34	:B
	:;;end-calc              x.
	:;

15EC:C
15EC 3E16       ld a, $16	:C
	:; load accumulator with '-'
	:;

15EE:C
15EE D7         rst $10	:C
	:; PRINT-A
	:;

15EF:C
15EF EF         rst $28	:C
	:;; FP-CALC              x.
	:;

15F0:B
	:#;; PF-POSTVE
15F0-15F0 34	:B PF_POSTVE
	:;;end-calc              x.
	:;

15F1:C
	:#; register HL addresses the exponent of the floating-point value.
	:#; if positive, and point floats to left, then bit 7 is set.
	:#
15F1 7E         ld a, (hl)	:C
	:; pick up the exponent byte

15F2:C
15F2 CD1D15     call $151D	:C
	:; routine STACK-A places on calculator stack.
	:;

15F5:C
	:#; now calculate roughly the number of digits, n, before the decimal point by
	:#; subtracting a half from true exponent and multiplying by log to 
	:#; the base 10 of 2. 
	:#; The true number could be one higher than n, the integer result.
	:#
15F5 EF         rst $28	:C
	:;; FP-CALC              x, e.

15F6:B
15F6-15F6 30	:B
	:;;stk-data

15F7:B
15F7-15F7 78	:B
	:;;Exponent: $88, Bytes: 2

15F8:B
15F8-15F9 0080	:B
	:;;(+00,+00)             x, e, 128.5.

15FA:B
15FA-15FA 03	:B
	:;;subtract              x, e -.5.

15FB:B
15FB-15FB 30	:B
	:;;stk-data

15FC:B
15FC-15FC EF	:B
	:;;Exponent: $7F, Bytes: 4

15FD:B
15FD-1600 1A209A85	:B
	:;;                      .30103 (log10 2)

1601:B
1601-1601 04	:B
	:;;multiply              x,

1602:B
1602-1602 24	:B
	:;;int

1603:B
1603-1603 C1	:B
	:;;st-mem-1              x, n.
	:;
	:;

1604:B
1604-1604 30	:B
	:;;stk-data

1605:B
1605-1605 34	:B
	:;;Exponent: $84, Bytes: 1

1606:B
1606-1606 00	:B
	:;;(+00,+00,+00)         x, n, 8.
	:;

1607:B
1607-1607 03	:B
	:;;subtract              x, n-8.

1608:B
1608-1608 18	:B
	:;;neg                   x, 8-n.

1609:B
1609-1609 38	:B
	:;;e-to-fp               x * (10^n)
	:;

160A:B
	:#; finally the 8 or 9 digit decimal is rounded.
	:#; a ten-digit integer can arise in the case of, say, 999999999.5
	:#; which gives 1000000000.
	:#
160A-160A A2	:B
	:;;stk-half

160B:B
160B-160B 0F	:B
	:;;addition

160C:B
160C-160C 24	:B
	:;;int                   i.

160D:B
160D-160D 34	:B
	:;;end-calc
	:;

160E:C
	:#; If there were 8 digits then final rounding will take place on the calculator 
	:#; stack above and the next two instructions insert a masked zero so that
	:#; no further rounding occurs. If the result is a 9 digit integer then
	:#; rounding takes place within the buffer.
	:#
160E 216B40     ld hl, $406B	:C
	:; address system variable MEM-2-5th
	:; which could be the 'ninth' digit.

1611:C
1611 3690       ld (hl), $90	:C
	:; insert the value $90  10010000
	:;

1613:C
	:#; now starting from lowest digit lay down the 8, 9 or 10 digit integer
	:#; which represents the significant portion of the number
	:#; e.g. PI will be the nine-digit integer 314159265
	:#
1613 060A       ld b, $0A	:C
	:; count is ten digits.
	:;

1615:C
	:#;; PF-LOOP
1615 23         inc hl	:C PF_LOOP
	:; increase pointer
	:;

1616:C
1616 E5         push hl	:C
	:; preserve buffer address.

1617:C
1617 C5         push bc	:C
	:; preserve counter.
	:;

1618:C
1618 EF         rst $28	:C
	:;; FP-CALC              i.

1619:B
1619-1619 A4	:B
	:;;stk-ten               i, 10.

161A:B
161A-161A 2E	:B
	:;;n-mod-m               i mod 10, i/10

161B:B
161B-161B 01	:B
	:;;exchange              i/10, remainder.

161C:B
161C-161C 34	:B
	:;;end-calc
	:;

161D:C
161D CDCD15     call $15CD	:C
	:; routine FP-TO-A  $00-$09
	:;

1620:C
1620 F690       or $90	:C
	:; make left hand nibble 9 
	:;

1622:C
1622 C1         pop bc	:C
	:; restore counter

1623:C
1623 E1         pop hl	:C
	:; restore buffer address.
	:;

1624:C
1624 77         ld (hl), a	:C
	:; insert masked digit in buffer.

1625:C
1625 10EE       djnz $1615	:C
	:; loop back for all ten to PF-LOOP
	:;

1627:C
	:#; the most significant digit will be last but if the number is exhausted then
	:#; the last one or two positions will contain zero ($90).
	:#
	:#; e.g. for 'one' we have zero as estimate of leading digits.
	:#; 1*10^8 100000000 as integer value
	:#; 90 90 90 90 90   90 90 90 91 90 as buffer mem3/mem4 contents.
	:#
	:#
1627 23         inc hl	:C
	:; advance pointer to one past buffer 

1628:C
1628 010800     ld bc, $0008	:C
	:; set C to 8 ( B is already zero )

162B:C
162B E5         push hl	:C
	:; save pointer.
	:;

162C:C
	:#;; PF-NULL
162C 2B         dec hl	:C PF_NULL
	:; decrease pointer

162D:C
162D 7E         ld a, (hl)	:C
	:; fetch masked digit

162E:C
162E FE90       cp $90	:C
	:; is it a leading zero ?

1630:C
1630 28FA       jr z, $162C	:C
	:; loop back if so to PF-NULL
	:;

1632:C
	:#; at this point a significant digit has been found. carry is reset.
	:#
1632 ED42       sbc hl, bc	:C
	:; subtract eight from the address.

1634:C
1634 E5         push hl	:C
	:; ** save this pointer too

1635:C
1635 7E         ld a, (hl)	:C
	:; fetch addressed byte

1636:C
1636 C66B       add a, $6B	:C
	:; add $6B - forcing a round up ripple
	:; if  $95 or over.

1638:C
1638 F5         push af	:C
	:; save the carry result.
	:;

1639:C
	:#; now enter a loop to round the number. After rounding has been considered
	:#; a zero that has arisen from rounding or that was present at that position
	:#; originally is changed from $90 to $80.
	:#
	:#;; PF-RND-LP
1639 F1         pop af	:C PF_RND_LP
	:; retrieve carry from machine stack.

163A:C
163A 23         inc hl	:C
	:; increment address

163B:C
163B 7E         ld a, (hl)	:C
	:; fetch new byte

163C:C
163C CE00       adc a, $00	:C
	:; add in any carry
	:;

163E:C
163E 27         daa	:C
	:; decimal adjust accumulator
	:; carry will ripple through the '9'
	:;

163F:C
163F F5         push af	:C
	:; save carry on machine stack.

1640:C
1640 E60F       and $0F	:C
	:; isolate character 0 - 9 AND set zero flag
	:; if zero.

1642:C
1642 77         ld (hl), a	:C
	:; place back in location.

1643:C
1643 CBFE       set 7, (hl)	:C
	:; set bit 7 to show printable.
	:; but not if trailing zero after decimal point.

1645:C
1645 28F2       jr z, $1639	:C
	:; back if a zero to PF-RND-LP
	:; to consider further rounding and/or trailing
	:; zero identification.
	:;

1647:C
1647 F1         pop af	:C
	:; balance stack

1648:C
1648 E1         pop hl	:C
	:; ** retrieve lower pointer
	:;

1649:C
	:#; now insert 6 trailing zeros which are printed if before the decimal point
	:#; but mark the end of printing if after decimal point.
	:#; e.g. 9876543210123 is printed as 9876543200000
	:#; 123.456001 is printed as 123.456
	:#
1649 0606       ld b, $06	:C
	:; the count is six.
	:;

164B:C
	:#;; PF-ZERO-6
164B 3680       ld (hl), $80	:C PF_ZERO_6
	:; insert a masked zero

164D:C
164D 2B         dec hl	:C
	:; decrease pointer.

164E:C
164E 10FB       djnz $164B	:C
	:; loop back for all six to PF-ZERO-6
	:;

1650:C
	:#; n-mod-m reduced the number to zero and this is now deleted from the calculator
	:#; stack before fetching the original estimate of leading digits.
	:#
	:#
1650 EF         rst $28	:C
	:;; FP-CALC              0.

1651:B
1651-1651 02	:B
	:;;delete                .

1652:B
1652-1652 E1	:B
	:;;get-mem-1             n.

1653:B
1653-1653 34	:B
	:;;end-calc              n.
	:;

1654:C
1654 CDCD15     call $15CD	:C
	:; routine FP-TO-A

1657:C
1657 2802       jr z, $165B	:C
	:; skip forward if positive to PF-POS
	:;

1659:C
1659 ED44       neg	:C
	:; negate makes positive
	:;

165B:C
	:#;; PF-POS
165B 5F         ld e, a	:C PF_POS
	:; transfer count of digits to E

165C:C
165C 1C         inc e	:C
	:; increment twice 

165D:C
165D 1C         inc e	:C
	:; 

165E:C
165E E1         pop hl	:C
	:; * retrieve pointer to one past buffer.
	:;

165F:C
	:#;; GET-FIRST
165F 2B         dec hl	:C GET_FIRST
	:; decrement address.

1660:C
1660 1D         dec e	:C
	:; decrement digit counter.

1661:C
1661 7E         ld a, (hl)	:C
	:; fetch masked byte.

1662:C
1662 E60F       and $0F	:C
	:; isolate right-hand nibble.

1664:C
1664 28F9       jr z, $165F	:C
	:; back with leading zero to GET-FIRST
	:;

1666:C
	:#; now determine if E-format printing is needed
	:#
1666 7B         ld a, e	:C
	:; transfer now accurate number count to A.

1667:C
1667 D605       sub $05	:C
	:; subtract five

1669:C
1669 FE08       cp $08	:C
	:; compare with 8 as maximum digits is 13.

166B:C
166B F28216     jp p, $1682	:C
	:; forward if positive to PF-E-FMT
	:;

166E:C
166E FEF6       cp $F6	:C
	:; test for more than four zeros after point.

1670:C
1670 FA8216     jp m, $1682	:C
	:; forward if so to PF-E-FMT
	:;

1673:C
1673 C606       add a, $06	:C
	:; test for zero leading digits, e.g. 0.5

1675:C
1675 2848       jr z, $16BF	:C
	:; forward if so to PF-ZERO-1 
	:;

1677:C
1677 FAB216     jp m, $16B2	:C
	:; forward if more than one zero to PF-ZEROS
	:;

167A:C
	:#; else digits before the decimal point are to be printed
	:#
167A 47         ld b, a	:C
	:; count of leading characters to B.
	:;

167B:C
	:#;; PF-NIB-LP
167B CDD016     call $16D0	:C PF_NIB_LP
	:; routine PF-NIBBLE

167E:C
167E 10FB       djnz $167B	:C
	:; loop back for counted numbers to PF-NIB-LP
	:;

1680:C
1680 1840       jr $16C2	:C
	:; forward to consider decimal part to PF-DC-OUT
	:;

1682:C
	:#; ---
	:#
	:#;; PF-E-FMT
1682 43         ld b, e	:C PF_E_FMT
	:; count to B

1683:C
1683 CDD016     call $16D0	:C
	:; routine PF-NIBBLE prints one digit.

1686:C
1686 CDC216     call $16C2	:C
	:; routine PF-DC-OUT considers fractional part.
	:;

1689:C
1689 3E2A       ld a, $2A	:C
	:; prepare character 'E'

168B:C
168B D7         rst $10	:C
	:; PRINT-A
	:;

168C:C
168C 78         ld a, b	:C
	:; transfer exponent to A

168D:C
168D A7         and a	:C
	:; test the sign.

168E:C
168E F29816     jp p, $1698	:C
	:; forward if positive to PF-E-POS
	:;

1691:C
1691 ED44       neg	:C
	:; negate the negative exponent.

1693:C
1693 47         ld b, a	:C
	:; save positive exponent in B.
	:;

1694:C
1694 3E16       ld a, $16	:C
	:; prepare character '-'

1696:C
1696 1802       jr $169A	:C
	:; skip forward to PF-E-SIGN
	:;

1698:C
	:#; ---
	:#
	:#;; PF-E-POS
1698 3E15       ld a, $15	:C PF_E_POS
	:; prepare character '+'
	:;

169A:C
	:#;; PF-E-SIGN
169A D7         rst $10	:C PF_E_SIGN
	:; PRINT-A
	:;

169B:C
	:#; now convert the integer exponent in B to two characters.
	:#; it will be less than 99.
	:#
169B 78         ld a, b	:C
	:; fetch positive exponent.

169C:C
169C 06FF       ld b, $FF	:C
	:; initialize left hand digit to minus one.
	:;

169E:C
	:#;; PF-E-TENS
169E 04         inc b	:C PF_E_TENS
	:; increment ten count

169F:C
169F D60A       sub $0A	:C
	:; subtract ten from exponent

16A1:C
16A1 30FB       jr nc, $169E	:C
	:; loop back if greater than ten to PF-E-TENS
	:;

16A3:C
16A3 C60A       add a, $0A	:C
	:; reverse last subtraction

16A5:C
16A5 4F         ld c, a	:C
	:; transfer remainder to C
	:;

16A6:C
16A6 78         ld a, b	:C
	:; transfer ten value to A.

16A7:C
16A7 A7         and a	:C
	:; test for zero.

16A8:C
16A8 2803       jr z, $16AD	:C
	:; skip forward if so to PF-E-LOW
	:;

16AA:C
16AA CDEB07     call $07EB	:C
	:; routine OUT-CODE prints as digit '1' - '9'
	:;

16AD:C
	:#;; PF-E-LOW
16AD 79         ld a, c	:C PF_E_LOW
	:; low byte to A

16AE:C
16AE CDEB07     call $07EB	:C
	:; routine OUT-CODE prints final digit of the
	:; exponent.

16B1:C
16B1 C9         ret	:C
	:; return.                               >>
	:;

16B2:C
	:#; ---
	:#
	:#; this branch deals with zeros after decimal point.
	:#; e.g.      .01 or .0000999
	:#
	:#;; PF-ZEROS
16B2 ED44       neg	:C PF_ZEROS
	:; negate makes number positive 1 to 4.

16B4:C
16B4 47         ld b, a	:C
	:; zero count to B.
	:;

16B5:C
16B5 3E1B       ld a, $1B	:C
	:; prepare character '.'

16B7:C
16B7 D7         rst $10	:C
	:; PRINT-A
	:;

16B8:C
16B8 3E1C       ld a, $1C	:C
	:; prepare a '0'
	:;

16BA:C
	:#;; PF-ZRO-LP
16BA D7         rst $10	:C PF_ZRO_LP
	:; PRINT-A

16BB:C
16BB 10FD       djnz $16BA	:C
	:; loop back to PF-ZRO-LP
	:;

16BD:C
16BD 1809       jr $16C8	:C
	:; forward to PF-FRAC-LP
	:;

16BF:C
	:#; ---
	:#
	:#; there is  a need to print a leading zero e.g. 0.1 but not with .01
	:#
	:#;; PF-ZERO-1
16BF 3E1C       ld a, $1C	:C PF_ZERO_1
	:; prepare character '0'.

16C1:C
16C1 D7         rst $10	:C
	:; PRINT-A
	:;

16C2:C
	:#; this subroutine considers the decimal point and any trailing digits.
	:#; if the next character is a marked zero, $80, then nothing more to print.
	:#
	:#;; PF-DC-OUT
16C2 35         dec (hl)	:C PF_DC_OUT
	:; decrement addressed character

16C3:C
16C3 34         inc (hl)	:C
	:; increment it again

16C4:C
16C4 E8         ret pe	:C
	:; return with overflow  (was 128) >>
	:; as no fractional part
	:;

16C5:C
	:#; else there is a fractional part so print the decimal point.
	:#
16C5 3E1B       ld a, $1B	:C
	:; prepare character '.'

16C7:C
16C7 D7         rst $10	:C
	:; PRINT-A
	:;

16C8:C
	:#; now enter a loop to print trailing digits
	:#
	:#;; PF-FRAC-LP
16C8 35         dec (hl)	:C PF_FRAC_LP
	:; test for a marked zero.

16C9:C
16C9 34         inc (hl)	:C
	:;

16CA:C
16CA E8         ret pe	:C
	:; return when digits exhausted          >>
	:;

16CB:C
16CB CDD016     call $16D0	:C
	:; routine PF-NIBBLE

16CE:C
16CE 18F8       jr $16C8	:C
	:; back for all fractional digits to PF-FRAC-LP.
	:;

16D0:C
	:#; ---
	:#
	:#; subroutine to print right-hand nibble
	:#
	:#;; PF-NIBBLE
16D0 7E         ld a, (hl)	:C PF_NIBBLE
	:; fetch addressed byte

16D1:C
16D1 E60F       and $0F	:C
	:; mask off lower 4 bits

16D3:C
16D3 CDEB07     call $07EB	:C
	:; routine OUT-CODE

16D6:C
16D6 2B         dec hl	:C
	:; decrement pointer.

16D7:C
16D7 C9         ret	:C
	:; return.
	:;
	:;

16D8:C
	:#; -------------------------------
	:#; THE 'PREPARE TO ADD' SUBROUTINE
	:#; -------------------------------
	:#; This routine is called twice to prepare each floating point number for
	:#; addition, in situ, on the calculator stack.
	:#; The exponent is picked up from the first byte which is then cleared to act
	:#; as a sign byte and accept any overflow.
	:#; If the exponent is zero then the number is zero and an early return is made.
	:#; The now redundant sign bit of the mantissa is set and if the number is 
	:#; negative then all five bytes of the number are twos-complemented to prepare 
	:#; the number for addition.
	:#; On the second invocation the exponent of the first number is in B.
	:#
	:#
	:#;; PREP-ADD
16D8 7E         ld a, (hl)	:C PREP_ADD
	:; fetch exponent.

16D9:C
16D9 3600       ld (hl), $00	:C
	:; make this byte zero to take any overflow and
	:; default to positive.

16DB:C
16DB A7         and a	:C
	:; test stored exponent for zero.

16DC:C
16DC C8         ret z	:C
	:; return with zero flag set if number is zero.
	:;

16DD:C
16DD 23         inc hl	:C
	:; point to first byte of mantissa.

16DE:C
16DE CB7E       bit 7, (hl)	:C
	:; test the sign bit.

16E0:C
16E0 CBFE       set 7, (hl)	:C
	:; set it to its implied state.

16E2:C
16E2 2B         dec hl	:C
	:; set pointer to first byte again.

16E3:C
16E3 C8         ret z	:C
	:; return if bit indicated number is positive.>>
	:;

16E4:C
	:#; if negative then all five bytes are twos complemented starting at LSB.
	:#
16E4 C5         push bc	:C
	:; save B register contents.

16E5:C
16E5 010500     ld bc, $0005	:C
	:; set BC to five.

16E8:C
16E8 09         add hl, bc	:C
	:; point to location after 5th byte.

16E9:C
16E9 41         ld b, c	:C
	:; set the B counter to five.

16EA:C
16EA 4F         ld c, a	:C
	:; store original exponent in C.

16EB:C
16EB 37         scf	:C
	:; set carry flag so that one is added.
	:;

16EC:C
	:#; now enter a loop to twos-complement the number.
	:#; The first of the five bytes becomes $FF to denote a negative number.
	:#
	:#;; NEG-BYTE
16EC 2B         dec hl	:C NEG_BYTE
	:; point to first or more significant byte.

16ED:C
16ED 7E         ld a, (hl)	:C
	:; fetch to accumulator.

16EE:C
16EE 2F         cpl	:C
	:; complement.

16EF:C
16EF CE00       adc a, $00	:C
	:; add in initial carry or any subsequent carry.

16F1:C
16F1 77         ld (hl), a	:C
	:; place number back.

16F2:C
16F2 10F8       djnz $16EC	:C
	:; loop back five times to NEG-BYTE
	:;

16F4:C
16F4 79         ld a, c	:C
	:; restore the exponent to accumulator.

16F5:C
16F5 C1         pop bc	:C
	:; restore B register contents.
	:;

16F6:C
16F6 C9         ret	:C
	:; return.
	:;

16F7:C
	:#; ----------------------------------
	:#; THE 'FETCH TWO NUMBERS' SUBROUTINE
	:#; ----------------------------------
	:#; This routine is used by addition, multiplication and division to fetch
	:#; the two five-byte numbers addressed by HL and DE from the calculator stack
	:#; into the Z80 registers.
	:#; The HL register may no longer point to the first of the two numbers.
	:#; Since the 32-bit addition operation is accomplished using two Z80 16-bit
	:#; instructions, it is important that the lower two bytes of each mantissa are
	:#; in one set of registers and the other bytes all in the alternate set.
	:#;
	:#; In: HL = highest number, DE= lowest number
	:#;
	:#;         : alt':   :
	:#; Out:    :H,B-C:C,B: num1
	:#;         :L,D-E:D-E: num2
	:#
	:#;; FETCH-TWO
16F7 E5         push hl	:C FETCH_TWO
	:; save HL 

16F8:C
16F8 F5         push af	:C
	:; save A - result sign when used from division.
	:;

16F9:C
16F9 4E         ld c, (hl)	:C
	:;

16FA:C
16FA 23         inc hl	:C
	:;

16FB:C
16FB 46         ld b, (hl)	:C
	:;

16FC:C
16FC 77         ld (hl), a	:C
	:; insert sign when used from multiplication.

16FD:C
16FD 23         inc hl	:C
	:;

16FE:C
16FE 79         ld a, c	:C
	:; m1

16FF:C
16FF 4E         ld c, (hl)	:C
	:;

1700:C
1700 C5         push bc	:C
	:; PUSH m2 m3
	:;

1701:C
1701 23         inc hl	:C
	:;

1702:C
1702 4E         ld c, (hl)	:C
	:; m4

1703:C
1703 23         inc hl	:C
	:;

1704:C
1704 46         ld b, (hl)	:C
	:; m5  BC holds m5 m4
	:;

1705:C
1705 EB         ex de, hl	:C
	:; make HL point to start of second number.
	:;

1706:C
1706 57         ld d, a	:C
	:; m1

1707:C
1707 5E         ld e, (hl)	:C
	:;

1708:C
1708 D5         push de	:C
	:; PUSH m1 n1
	:;

1709:C
1709 23         inc hl	:C
	:;

170A:C
170A 56         ld d, (hl)	:C
	:;

170B:C
170B 23         inc hl	:C
	:;

170C:C
170C 5E         ld e, (hl)	:C
	:;

170D:C
170D D5         push de	:C
	:; PUSH n2 n3
	:;

170E:C
170E D9         exx	:C
	:; - - - - - - -
	:;

170F:C
170F D1         pop de	:C
	:; POP n2 n3

1710:C
1710 E1         pop hl	:C
	:; POP m1 n1

1711:C
1711 C1         pop bc	:C
	:; POP m2 m3
	:;

1712:C
1712 D9         exx	:C
	:; - - - - - - -
	:;

1713:C
1713 23         inc hl	:C
	:;

1714:C
1714 56         ld d, (hl)	:C
	:;

1715:C
1715 23         inc hl	:C
	:;

1716:C
1716 5E         ld e, (hl)	:C
	:; DE holds n4 n5
	:;

1717:C
1717 F1         pop af	:C
	:; restore saved

1718:C
1718 E1         pop hl	:C
	:; registers.

1719:C
1719 C9         ret	:C
	:; return.
	:;

171A:C
	:#; -----------------------------
	:#; THE 'SHIFT ADDEND' SUBROUTINE
	:#; -----------------------------
	:#; The accumulator A contains the difference between the two exponents.
	:#; This is the lowest of the two numbers to be added 
	:#
	:#;; SHIFT-FP
171A A7         and a	:C SHIFT_FP
	:; test difference between exponents.

171B:C
171B C8         ret z	:C
	:; return if zero. both normal.
	:;

171C:C
171C FE21       cp $21	:C
	:; compare with 33 bits.

171E:C
171E 3016       jr nc, $1736	:C
	:; forward if greater than 32 to ADDEND-0
	:;

1720:C
1720 C5         push bc	:C
	:; preserve BC - part 

1721:C
1721 47         ld b, a	:C
	:; shift counter to B.
	:;

1722:C
	:#; Now perform B right shifts on the addend  L'D'E'D E
	:#; to bring it into line with the augend     H'B'C'C B
	:#
	:#;; ONE-SHIFT
1722 D9         exx	:C ONE_SHIFT
	:; - - -

1723:C
1723 CB2D       sra l	:C
	:;    76543210->C    bit 7 unchanged.

1725:C
1725 CB1A       rr d	:C
	:; C->76543210->C

1727:C
1727 CB1B       rr e	:C
	:; C->76543210->C

1729:C
1729 D9         exx	:C
	:; - - - 

172A:C
172A CB1A       rr d	:C
	:; C->76543210->C

172C:C
172C CB1B       rr e	:C
	:; C->76543210->C

172E:C
172E 10F2       djnz $1722	:C
	:; loop back B times to ONE-SHIFT
	:;

1730:C
1730 C1         pop bc	:C
	:; restore BC

1731:C
1731 D0         ret nc	:C
	:; return if last shift produced no carry.   >>
	:;

1732:C
	:#; if carry flag was set then accuracy is being lost so round up the addend.
	:#
1732 CD4117     call $1741	:C
	:; routine ADD-BACK

1735:C
1735 C0         ret nz	:C
	:; return if not FF 00 00 00 00
	:;

1736:C
	:#; this branch makes all five bytes of the addend zero and is made during
	:#; addition when the exponents are too far apart for the addend bits to 
	:#; affect the result.
	:#
	:#;; ADDEND-0
1736 D9         exx	:C ADDEND_0
	:; select alternate set for more significant 
	:; bytes.

1737:C
1737 AF         xor a	:C
	:; clear accumulator.
	:;
	:;

1738:C
	:#; this entry point (from multiplication) sets four of the bytes to zero or if 
	:#; continuing from above, during addition, then all five bytes are set to zero.
	:#
	:#;; ZEROS-4/5
1738 2E00       ld l, $00	:C ZEROS_4_5
	:; set byte 1 to zero.

173A:C
173A 57         ld d, a	:C
	:; set byte 2 to A.

173B:C
173B 5D         ld e, l	:C
	:; set byte 3 to zero.

173C:C
173C D9         exx	:C
	:; select main set 

173D:C
173D 110000     ld de, $0000	:C
	:; set lower bytes 4 and 5 to zero.

1740:C
1740 C9         ret	:C
	:; return.
	:;

1741:C
	:#; -------------------------
	:#; THE 'ADD-BACK' SUBROUTINE
	:#; -------------------------
	:#; Called from SHIFT-FP above during addition and after normalization from
	:#; multiplication.
	:#; This is really a 32-bit increment routine which sets the zero flag according
	:#; to the 32-bit result.
	:#; During addition, only negative numbers like FF FF FF FF FF,
	:#; the twos-complement version of xx 80 00 00 01 say 
	:#; will result in a full ripple FF 00 00 00 00.
	:#; FF FF FF FF FF when shifted right is unchanged by SHIFT-FP but sets the 
	:#; carry invoking this routine.
	:#
	:#;; ADD-BACK
1741 1C         inc e	:C ADD_BACK
	:;

1742:C
1742 C0         ret nz	:C
	:;
	:;

1743:C
1743 14         inc d	:C
	:;

1744:C
1744 C0         ret nz	:C
	:;
	:;

1745:C
1745 D9         exx	:C
	:;

1746:C
1746 1C         inc e	:C
	:;

1747:C
1747 2001       jr nz, $174A	:C
	:; forward if no overflow to ALL-ADDED
	:;

1749:C
1749 14         inc d	:C
	:;
	:;

174A:C
	:#;; ALL-ADDED
174A D9         exx	:C ALL_ADDED
	:;

174B:C
174B C9         ret	:C
	:; return with zero flag set for zero mantissa.
	:;
	:;

174C:C
	:#; ---------------------------
	:#; THE 'SUBTRACTION' OPERATION
	:#; ---------------------------
	:#; just switch the sign of subtrahend and do an add.
	:#
	:#;; subtract
174C 1A         ld a, (de)	:C subtract
	:; fetch exponent byte of second number the
	:; subtrahend. 

174D:C
174D A7         and a	:C
	:; test for zero

174E:C
174E C8         ret z	:C
	:; return if zero - first number is result.
	:;

174F:C
174F 13         inc de	:C
	:; address the first mantissa byte.

1750:C
1750 1A         ld a, (de)	:C
	:; fetch to accumulator.

1751:C
1751 EE80       xor $80	:C
	:; toggle the sign bit.

1753:C
1753 12         ld (de), a	:C
	:; place back on calculator stack.

1754:C
1754 1B         dec de	:C
	:; point to exponent byte.
	:; continue into addition routine.
	:;

1755:C
	:#; ------------------------
	:#; THE 'ADDITION' OPERATION
	:#; ------------------------
	:#; The addition operation pulls out all the stops and uses most of the Z80's
	:#; registers to add two floating-point numbers.
	:#; This is a binary operation and on entry, HL points to the first number
	:#; and DE to the second.
	:#
	:#;; addition
1755 D9         exx	:C addition
	:; - - -

1756:C
1756 E5         push hl	:C
	:; save the pointer to the next literal.

1757:C
1757 D9         exx	:C
	:; - - -
	:;

1758:C
1758 D5         push de	:C
	:; save pointer to second number

1759:C
1759 E5         push hl	:C
	:; save pointer to first number - will be the
	:; result pointer on calculator stack.
	:;

175A:C
175A CDD816     call $16D8	:C
	:; routine PREP-ADD

175D:C
175D 47         ld b, a	:C
	:; save first exponent byte in B.

175E:C
175E EB         ex de, hl	:C
	:; switch number pointers.

175F:C
175F CDD816     call $16D8	:C
	:; routine PREP-ADD

1762:C
1762 4F         ld c, a	:C
	:; save second exponent byte in C.

1763:C
1763 B8         cp b	:C
	:; compare the exponent bytes.

1764:C
1764 3003       jr nc, $1769	:C
	:; forward if second higher to SHIFT-LEN
	:;

1766:C
1766 78         ld a, b	:C
	:; else higher exponent to A

1767:C
1767 41         ld b, c	:C
	:; lower exponent to B

1768:C
1768 EB         ex de, hl	:C
	:; switch the number pointers.
	:;

1769:C
	:#;; SHIFT-LEN
1769 F5         push af	:C SHIFT_LEN
	:; save higher exponent

176A:C
176A 90         sub b	:C
	:; subtract lower exponent
	:;

176B:C
176B CDF716     call $16F7	:C
	:; routine FETCH-TWO

176E:C
176E CD1A17     call $171A	:C
	:; routine SHIFT-FP
	:;

1771:C
1771 F1         pop af	:C
	:; restore higher exponent.

1772:C
1772 E1         pop hl	:C
	:; restore result pointer.

1773:C
1773 77         ld (hl), a	:C
	:; insert exponent byte.

1774:C
1774 E5         push hl	:C
	:; save result pointer again.
	:;

1775:C
	:#; now perform the 32-bit addition using two 16-bit Z80 add instructions.
	:#
1775 68         ld l, b	:C
	:; transfer low bytes of mantissa individually

1776:C
1776 61         ld h, c	:C
	:; to HL register
	:;

1777:C
1777 19         add hl, de	:C
	:; the actual binary addition of lower bytes
	:;

1778:C
	:#; now the two higher byte pairs that are in the alternate register sets.
	:#
1778 D9         exx	:C
	:; switch in set 

1779:C
1779 EB         ex de, hl	:C
	:; transfer high mantissa bytes to HL register.
	:;

177A:C
177A ED4A       adc hl, bc	:C
	:; the actual addition of higher bytes with
	:; any carry from first stage.
	:;

177C:C
177C EB         ex de, hl	:C
	:; result in DE, sign bytes ($FF or $00) to HL
	:;

177D:C
	:#; now consider the two sign bytes
	:#
177D 7C         ld a, h	:C
	:; fetch sign byte of num1
	:;

177E:C
177E 8D         adc a, l	:C
	:; add including any carry from mantissa 
	:; addition. 00 or 01 or FE or FF
	:;

177F:C
177F 6F         ld l, a	:C
	:; result in L.
	:;

1780:C
	:#; possible outcomes of signs and overflow from mantissa are
	:#;
	:#;  H +  L + carry =  L    RRA  XOR L  RRA
	:#; ------------------------------------------------------------
	:#; 00 + 00         = 00    00   00
	:#; 00 + 00 + carry = 01    00   01     carry
	:#; FF + FF         = FE C  FF   01     carry
	:#; FF + FF + carry = FF C  FF   00
	:#; FF + 00         = FF    FF   00
	:#; FF + 00 + carry = 00 C  80   80
	:#
1780 1F         rra	:C
	:; C->76543210->C

1781:C
1781 AD         xor l	:C
	:; set bit 0 if shifting required.
	:;

1782:C
1782 D9         exx	:C
	:; switch back to main set

1783:C
1783 EB         ex de, hl	:C
	:; full mantissa result now in D'E'D E registers.

1784:C
1784 E1         pop hl	:C
	:; restore pointer to result exponent on 
	:; the calculator stack.
	:;

1785:C
1785 1F         rra	:C
	:; has overflow occurred ?

1786:C
1786 3008       jr nc, $1790	:C
	:; skip forward if not to TEST-NEG
	:;

1788:C
	:#; if the addition of two positive mantissas produced overflow or if the
	:#; addition of two negative mantissas did not then the result exponent has to
	:#; be incremented and the mantissa shifted one place to the right.
	:#
1788 3E01       ld a, $01	:C
	:; one shift required.

178A:C
178A CD1A17     call $171A	:C
	:; routine SHIFT-FP performs a single shift 
	:; rounding any lost bit

178D:C
178D 34         inc (hl)	:C
	:; increment the exponent.

178E:C
178E 2823       jr z, $17B3	:C
	:; forward to ADD-REP-6 if the exponent
	:; wraps round from FF to zero as number is too
	:; big for the system.
	:;

1790:C
	:#; at this stage the exponent on the calculator stack is correct.
	:#
	:#;; TEST-NEG
1790 D9         exx	:C TEST_NEG
	:; switch in the alternate set.

1791:C
1791 7D         ld a, l	:C
	:; load result sign to accumulator.

1792:C
1792 E680       and $80	:C
	:; isolate bit 7 from sign byte setting zero
	:; flag if positive.

1794:C
1794 D9         exx	:C
	:; back to main set.
	:;

1795:C
1795 23         inc hl	:C
	:; point to first byte of mantissa

1796:C
1796 77         ld (hl), a	:C
	:; insert $00 positive or $80 negative at 
	:; position on calculator stack.
	:;

1797:C
1797 2B         dec hl	:C
	:; point to exponent again.

1798:C
1798 281F       jr z, $17B9	:C
	:; forward if positive to GO-NC-MLT
	:;

179A:C
	:#; a negative number has to be twos-complemented before being placed on stack.
	:#
179A 7B         ld a, e	:C
	:; fetch lowest (rightmost) mantissa byte.

179B:C
179B ED44       neg	:C
	:; Negate

179D:C
179D 3F         ccf	:C
	:; Complement Carry Flag

179E:C
179E 5F         ld e, a	:C
	:; place back in register
	:;

179F:C
179F 7A         ld a, d	:C
	:; ditto

17A0:C
17A0 2F         cpl	:C
	:;

17A1:C
17A1 CE00       adc a, $00	:C
	:;

17A3:C
17A3 57         ld d, a	:C
	:;
	:;

17A4:C
17A4 D9         exx	:C
	:; switch to higher (leftmost) 16 bits.
	:;

17A5:C
17A5 7B         ld a, e	:C
	:; ditto

17A6:C
17A6 2F         cpl	:C
	:;

17A7:C
17A7 CE00       adc a, $00	:C
	:;

17A9:C
17A9 5F         ld e, a	:C
	:;
	:;

17AA:C
17AA 7A         ld a, d	:C
	:; ditto

17AB:C
17AB 2F         cpl	:C
	:;

17AC:C
17AC CE00       adc a, $00	:C
	:;

17AE:C
17AE 3007       jr nc, $17B7	:C
	:; forward without overflow to END-COMPL
	:;

17B0:C
	:#; else entire mantissa is now zero.  00 00 00 00
	:#
17B0 1F         rra	:C
	:; set mantissa to 80 00 00 00

17B1:C
17B1 D9         exx	:C
	:; switch.

17B2:C
17B2 34         inc (hl)	:C
	:; increment the exponent.
	:;

17B3:C
	:#;; ADD-REP-6
17B3 CA8018     jp z, $1880	:C ADD_REP_6
	:; jump forward if exponent now zero to REPORT-6
	:; 'Number too big'
	:;

17B6:C
17B6 D9         exx	:C
	:; switch back to alternate set.
	:;

17B7:C
	:#;; END-COMPL
17B7 57         ld d, a	:C END_COMPL
	:; put first byte of mantissa back in DE.

17B8:C
17B8 D9         exx	:C
	:; switch to main set.
	:;

17B9:C
	:#;; GO-NC-MLT
17B9 AF         xor a	:C GO_NC_MLT
	:; clear carry flag and
	:; clear accumulator so no extra bits carried
	:; forward as occurs in multiplication.
	:;

17BA:C
17BA 186C       jr $1828	:C
	:; forward to common code at TEST-NORM 
	:; but should go straight to NORMALIZE.
	:;
	:;

17BC:C
	:#; ----------------------------------------------
	:#; THE 'PREPARE TO MULTIPLY OR DIVIDE' SUBROUTINE
	:#; ----------------------------------------------
	:#; this routine is called twice from multiplication and twice from division
	:#; to prepare each of the two numbers for the operation.
	:#; Initially the accumulator holds zero and after the second invocation bit 7
	:#; of the accumulator will be the sign bit of the result.
	:#
	:#;; PREP-M/D
17BC 37         scf	:C PREP_M_D
	:; set carry flag to signal number is zero.

17BD:C
17BD 35         dec (hl)	:C
	:; test exponent

17BE:C
17BE 34         inc (hl)	:C
	:; for zero.

17BF:C
17BF C8         ret z	:C
	:; return if zero with carry flag set.
	:;

17C0:C
17C0 23         inc hl	:C
	:; address first mantissa byte.

17C1:C
17C1 AE         xor (hl)	:C
	:; exclusive or the running sign bit.

17C2:C
17C2 CBFE       set 7, (hl)	:C
	:; set the implied bit.

17C4:C
17C4 2B         dec hl	:C
	:; point to exponent byte.

17C5:C
17C5 C9         ret	:C
	:; return.
	:;

17C6:C
	:#; ------------------------------
	:#; THE 'MULTIPLICATION' OPERATION
	:#; ------------------------------
	:#;
	:#;
	:#
	:#;; multiply
17C6 AF         xor a	:C multiply
	:; reset bit 7 of running sign flag.

17C7:C
17C7 CDBC17     call $17BC	:C
	:; routine PREP-M/D

17CA:C
17CA D8         ret c	:C
	:; return if number is zero.
	:; zero * anything = zero.
	:;

17CB:C
17CB D9         exx	:C
	:; - - -

17CC:C
17CC E5         push hl	:C
	:; save pointer to 'next literal'

17CD:C
17CD D9         exx	:C
	:; - - -
	:;

17CE:C
17CE D5         push de	:C
	:; save pointer to second number 
	:;

17CF:C
17CF EB         ex de, hl	:C
	:; make HL address second number.
	:;

17D0:C
17D0 CDBC17     call $17BC	:C
	:; routine PREP-M/D
	:;

17D3:C
17D3 EB         ex de, hl	:C
	:; HL first number, DE - second number

17D4:C
17D4 385A       jr c, $1830	:C
	:; forward with carry to ZERO-RSLT
	:; anything * zero = zero.
	:;

17D6:C
17D6 E5         push hl	:C
	:; save pointer to first number.
	:;

17D7:C
17D7 CDF716     call $16F7	:C
	:; routine FETCH-TWO fetches two mantissas from
	:; calc stack to B'C'C,B  D'E'D E
	:; (HL will be overwritten but the result sign
	:; in A is inserted on the calculator stack)
	:;

17DA:C
17DA 78         ld a, b	:C
	:; transfer low mantissa byte of first number

17DB:C
17DB A7         and a	:C
	:; clear carry.

17DC:C
17DC ED62       sbc hl, hl	:C
	:; a short form of LD HL,$0000 to take lower
	:; two bytes of result. (2 program bytes)

17DE:C
17DE D9         exx	:C
	:; switch in alternate set

17DF:C
17DF E5         push hl	:C
	:; preserve HL

17E0:C
17E0 ED62       sbc hl, hl	:C
	:; set HL to zero also to take higher two bytes
	:; of the result and clear carry.

17E2:C
17E2 D9         exx	:C
	:; switch back.
	:;

17E3:C
17E3 0621       ld b, $21	:C
	:; register B can now be used to count thirty 
	:; three shifts.

17E5:C
17E5 1811       jr $17F8	:C
	:; forward to loop entry point STRT-MLT
	:;

17E7:C
	:#; ---
	:#
	:#; The multiplication loop is entered at  STRT-LOOP.
	:#
	:#;; MLT-LOOP
17E7 3005       jr nc, $17EE	:C MLT_LOOP
	:; forward if no carry to NO-ADD
	:;
	:; else add in the multiplicand.
	:;

17E9:C
17E9 19         add hl, de	:C
	:; add the two low bytes to result

17EA:C
17EA D9         exx	:C
	:; switch to more significant bytes.

17EB:C
17EB ED5A       adc hl, de	:C
	:; add high bytes of multiplicand and any carry.

17ED:C
17ED D9         exx	:C
	:; switch to main set.
	:;

17EE:C
	:#; in either case shift result right into B'C'C A
	:#
	:#;; NO-ADD
17EE D9         exx	:C NO_ADD
	:; switch to alternate set

17EF:C
17EF CB1C       rr h	:C
	:; C > 76543210 > C

17F1:C
17F1 CB1D       rr l	:C
	:; C > 76543210 > C

17F3:C
17F3 D9         exx	:C
	:;

17F4:C
17F4 CB1C       rr h	:C
	:; C > 76543210 > C

17F6:C
17F6 CB1D       rr l	:C
	:; C > 76543210 > C
	:;

17F8:C
	:#;; STRT-MLT
17F8 D9         exx	:C STRT_MLT
	:; switch in alternate set.

17F9:C
17F9 CB18       rr b	:C
	:; C > 76543210 > C

17FB:C
17FB CB19       rr c	:C
	:; C > 76543210 > C

17FD:C
17FD D9         exx	:C
	:; now main set

17FE:C
17FE CB19       rr c	:C
	:; C > 76543210 > C

1800:C
1800 1F         rra	:C
	:; C > 76543210 > C

1801:C
1801 10E4       djnz $17E7	:C
	:; loop back 33 times to MLT-LOOP
	:;

1803:C
	:#;
	:#
1803 EB         ex de, hl	:C
	:;

1804:C
1804 D9         exx	:C
	:;

1805:C
1805 EB         ex de, hl	:C
	:;

1806:C
1806 D9         exx	:C
	:;

1807:C
1807 C1         pop bc	:C
	:;

1808:C
1808 E1         pop hl	:C
	:;

1809:C
1809 78         ld a, b	:C
	:;

180A:C
180A 81         add a, c	:C
	:;

180B:C
180B 2001       jr nz, $180E	:C
	:; forward to MAKE-EXPT
	:;

180D:C
180D A7         and a	:C
	:;
	:;

180E:C
	:#;; MAKE-EXPT
180E 3D         dec a	:C MAKE_EXPT
	:;

180F:C
180F 3F         ccf	:C
	:; Complement Carry Flag
	:;

1810:C
	:#;; DIVN-EXPT
1810 17         rla	:C DIVN_EXPT
	:;

1811:C
1811 3F         ccf	:C
	:; Complement Carry Flag

1812:C
1812 1F         rra	:C
	:;

1813:C
1813 F21918     jp p, $1819	:C
	:; forward to OFLW1-CLR
	:;

1816:C
1816 3068       jr nc, $1880	:C
	:; forward to REPORT-6
	:;

1818:C
1818 A7         and a	:C
	:;
	:;

1819:C
	:#;; OFLW1-CLR
1819 3C         inc a	:C OFLW1_CLR
	:;

181A:C
181A 2008       jr nz, $1824	:C
	:; forward to OFLW2-CLR
	:;

181C:C
181C 3806       jr c, $1824	:C
	:; forward to OFLW2-CLR
	:;

181E:C
181E D9         exx	:C
	:;

181F:C
181F CB7A       bit 7, d	:C
	:;

1821:C
1821 D9         exx	:C
	:;

1822:C
1822 205C       jr nz, $1880	:C
	:; forward to REPORT-6
	:;

1824:C
	:#;; OFLW2-CLR
1824 77         ld (hl), a	:C OFLW2_CLR
	:;

1825:C
1825 D9         exx	:C
	:;

1826:C
1826 78         ld a, b	:C
	:;

1827:C
1827 D9         exx	:C
	:;
	:;

1828:C
	:#; addition joins here with carry flag clear.
	:#
	:#;; TEST-NORM
1828 3015       jr nc, $183F	:C TEST_NORM
	:; forward to NORMALIZE
	:;

182A:C
182A 7E         ld a, (hl)	:C
	:;

182B:C
182B A7         and a	:C
	:;
	:;

182C:C
	:#;; NEAR-ZERO
182C 3E80       ld a, $80	:C NEAR_ZERO
	:; prepare to rescue the most significant bit 
	:; of the mantissa if it is set.

182E:C
182E 2801       jr z, $1831	:C
	:; skip forward to SKIP-ZERO
	:;

1830:C
	:#;; ZERO-RSLT
1830 AF         xor a	:C ZERO_RSLT
	:; make mask byte zero signaling set five
	:; bytes to zero.
	:;

1831:C
	:#;; SKIP-ZERO
1831 D9         exx	:C SKIP_ZERO
	:; switch in alternate set

1832:C
1832 A2         and d	:C
	:; isolate most significant bit (if A is $80).
	:;

1833:C
1833 CD3817     call $1738	:C
	:; routine ZEROS-4/5 sets mantissa without 
	:; affecting any flags.
	:;

1836:C
1836 07         rlca	:C
	:; test if MSB set. bit 7 goes to bit 0.
	:; either $00 -> $00 or $80 -> $01

1837:C
1837 77         ld (hl), a	:C
	:; make exponent $01 (lowest) or $00 zero

1838:C
1838 382E       jr c, $1868	:C
	:; forward if first case to OFLOW-CLR
	:;

183A:C
183A 23         inc hl	:C
	:; address first mantissa byte on the
	:; calculator stack.

183B:C
183B 77         ld (hl), a	:C
	:; insert a zero for the sign bit.

183C:C
183C 2B         dec hl	:C
	:; point to zero exponent

183D:C
183D 1829       jr $1868	:C
	:; forward to OFLOW-CLR
	:;

183F:C
	:#; ---
	:#
	:#; this branch is common to addition and multiplication with the mantissa
	:#; result still in registers D'E'D E .
	:#
	:#;; NORMALIZE
183F 0620       ld b, $20	:C NORMALIZE
	:; a maximum of thirty-two left shifts will be 
	:; needed.
	:;

1841:C
	:#;; SHIFT-ONE
1841 D9         exx	:C SHIFT_ONE
	:; address higher 16 bits.

1842:C
1842 CB7A       bit 7, d	:C
	:; test the leftmost bit

1844:C
1844 D9         exx	:C
	:; address lower 16 bits.
	:;

1845:C
1845 2012       jr nz, $1859	:C
	:; forward if leftmost bit was set to NORML-NOW
	:;

1847:C
1847 07         rlca	:C
	:; this holds zero from addition, 33rd bit 
	:; from multiplication.
	:;

1848:C
1848 CB13       rl e	:C
	:; C < 76543210 < C

184A:C
184A CB12       rl d	:C
	:; C < 76543210 < C
	:;

184C:C
184C D9         exx	:C
	:; address higher 16 bits.
	:;

184D:C
184D CB13       rl e	:C
	:; C < 76543210 < C

184F:C
184F CB12       rl d	:C
	:; C < 76543210 < C
	:;

1851:C
1851 D9         exx	:C
	:; switch to main set.
	:;

1852:C
1852 35         dec (hl)	:C
	:; decrement the exponent byte on the calculator
	:; stack.
	:;

1853:C
1853 28D7       jr z, $182C	:C
	:; back if exponent becomes zero to NEAR-ZERO
	:; it's just possible that the last rotation
	:; set bit 7 of D. We shall see.
	:;

1855:C
1855 10EA       djnz $1841	:C
	:; loop back to SHIFT-ONE
	:;

1857:C
	:#; if thirty-two left shifts were performed without setting the most significant 
	:#; bit then the result is zero.
	:#
1857 18D7       jr $1830	:C
	:; back to ZERO-RSLT
	:;

1859:C
	:#; ---
	:#
	:#;; NORML-NOW
1859 17         rla	:C NORML_NOW
	:; for the addition path, A is always zero.
	:; for the mult path, ...
	:;

185A:C
185A 300C       jr nc, $1868	:C
	:; forward to OFLOW-CLR
	:;

185C:C
	:#; this branch is taken only with multiplication.
	:#
185C CD4117     call $1741	:C
	:; routine ADD-BACK
	:;

185F:C
185F 2007       jr nz, $1868	:C
	:; forward to OFLOW-CLR
	:;

1861:C
1861 D9         exx	:C
	:;

1862:C
1862 1680       ld d, $80	:C
	:;

1864:C
1864 D9         exx	:C
	:;

1865:C
1865 34         inc (hl)	:C
	:;

1866:C
1866 2818       jr z, $1880	:C
	:; forward to REPORT-6
	:;

1868:C
	:#; now transfer the mantissa from the register sets to the calculator stack
	:#; incorporating the sign bit already there.
	:#
	:#;; OFLOW-CLR
1868 E5         push hl	:C OFLOW_CLR
	:; save pointer to exponent on stack.

1869:C
1869 23         inc hl	:C
	:; address first byte of mantissa which was 
	:; previously loaded with sign bit $00 or $80.
	:;

186A:C
186A D9         exx	:C
	:; - - -

186B:C
186B D5         push de	:C
	:; push the most significant two bytes.

186C:C
186C D9         exx	:C
	:; - - -
	:;

186D:C
186D C1         pop bc	:C
	:; pop - true mantissa is now BCDE.
	:;

186E:C
	:#; now pick up the sign bit.
	:#
186E 78         ld a, b	:C
	:; first mantissa byte to A 

186F:C
186F 17         rla	:C
	:; rotate out bit 7 which is set

1870:C
1870 CB16       rl (hl)	:C
	:; rotate sign bit on stack into carry.

1872:C
1872 1F         rra	:C
	:; rotate sign bit into bit 7 of mantissa.
	:;

1873:C
	:#; and transfer mantissa from main registers to calculator stack.
	:#
1873 77         ld (hl), a	:C
	:;

1874:C
1874 23         inc hl	:C
	:;

1875:C
1875 71         ld (hl), c	:C
	:;

1876:C
1876 23         inc hl	:C
	:;

1877:C
1877 72         ld (hl), d	:C
	:;

1878:C
1878 23         inc hl	:C
	:;

1879:C
1879 73         ld (hl), e	:C
	:;
	:;

187A:C
187A E1         pop hl	:C
	:; restore pointer to num1 now result.

187B:C
187B D1         pop de	:C
	:; restore pointer to num2 now STKEND.
	:;

187C:C
187C D9         exx	:C
	:; - - -

187D:C
187D E1         pop hl	:C
	:; restore pointer to next calculator literal.

187E:C
187E D9         exx	:C
	:; - - -
	:;

187F:C
187F C9         ret	:C
	:; return.
	:;

1880:C
	:#; ---
	:#
	:#;; REPORT-6
1880 CF         rst $08	:C REPORT_6
	:; ERROR-1

1881:B
1881-1881 05	:B
	:; Error Report: Arithmetic overflow.
	:;

1882:C
	:#; ------------------------
	:#; THE 'DIVISION' OPERATION
	:#; ------------------------
	:#;   "Of all the arithmetic subroutines, division is the most complicated and
	:#;   the least understood.  It is particularly interesting to note that the 
	:#;   Sinclair programmer himself has made a mistake in his programming ( or has
	:#;   copied over someone else's mistake!) for
	:#;   PRINT PEEK 6352 [ $18D0 ] ('unimproved' ROM, 6351 [ $18CF ] )
	:#;   should give 218 not 225."
	:#;   - Dr. Ian Logan, Syntax magazine Jul/Aug 1982.
	:#;   [  i.e. the jump should be made to div-34th ]
	:#
	:#;   First check for division by zero.
	:#
	:#;; division
1882 EB         ex de, hl	:C division
	:; consider the second number first. 

1883:C
1883 AF         xor a	:C
	:; set the running sign flag.

1884:C
1884 CDBC17     call $17BC	:C
	:; routine PREP-M/D

1887:C
1887 38F7       jr c, $1880	:C
	:; back if zero to REPORT-6
	:; 'Arithmetic overflow'
	:;

1889:C
1889 EB         ex de, hl	:C
	:; now prepare first number and check for zero.

188A:C
188A CDBC17     call $17BC	:C
	:; routine PREP-M/D

188D:C
188D D8         ret c	:C
	:; return if zero, 0/anything is zero.
	:;

188E:C
188E D9         exx	:C
	:; - - -

188F:C
188F E5         push hl	:C
	:; save pointer to the next calculator literal.

1890:C
1890 D9         exx	:C
	:; - - -
	:;

1891:C
1891 D5         push de	:C
	:; save pointer to divisor - will be STKEND.

1892:C
1892 E5         push hl	:C
	:; save pointer to dividend - will be result.
	:;

1893:C
1893 CDF716     call $16F7	:C
	:; routine FETCH-TWO fetches the two numbers
	:; into the registers H'B'C'C B
	:;                    L'D'E'D E

1896:C
1896 D9         exx	:C
	:; - - -

1897:C
1897 E5         push hl	:C
	:; save the two exponents.
	:;

1898:C
1898 60         ld h, b	:C
	:; transfer the dividend to H'L'H L

1899:C
1899 69         ld l, c	:C
	:; 

189A:C
189A D9         exx	:C
	:;

189B:C
189B 61         ld h, c	:C
	:;

189C:C
189C 68         ld l, b	:C
	:; 
	:;

189D:C
189D AF         xor a	:C
	:; clear carry bit and accumulator.

189E:C
189E 06DF       ld b, $DF	:C
	:; count upwards from -33 decimal

18A0:C
18A0 1810       jr $18B2	:C
	:; forward to mid-loop entry point DIV-START
	:;

18A2:C
	:#; ---
	:#
	:#;; DIV-LOOP
18A2 17         rla	:C DIV_LOOP
	:; multiply partial quotient by two

18A3:C
18A3 CB11       rl c	:C
	:; setting result bit from carry.

18A5:C
18A5 D9         exx	:C
	:;

18A6:C
18A6 CB11       rl c	:C
	:;

18A8:C
18A8 CB10       rl b	:C
	:;

18AA:C
18AA D9         exx	:C
	:;
	:;

18AB:C
	:#;; div-34th
18AB 29         add hl, hl	:C div_34th
	:;

18AC:C
18AC D9         exx	:C
	:;

18AD:C
18AD ED6A       adc hl, hl	:C
	:;

18AF:C
18AF D9         exx	:C
	:;

18B0:C
18B0 3810       jr c, $18C2	:C
	:; forward to SUBN-ONLY
	:;

18B2:C
	:#;; DIV-START
18B2 ED52       sbc hl, de	:C DIV_START
	:; subtract divisor part.

18B4:C
18B4 D9         exx	:C
	:;

18B5:C
18B5 ED52       sbc hl, de	:C
	:;

18B7:C
18B7 D9         exx	:C
	:;

18B8:C
18B8 300F       jr nc, $18C9	:C
	:; forward if subtraction goes to NO-RSTORE
	:;

18BA:C
18BA 19         add hl, de	:C
	:; else restore     

18BB:C
18BB D9         exx	:C
	:;

18BC:C
18BC ED5A       adc hl, de	:C
	:;

18BE:C
18BE D9         exx	:C
	:;

18BF:C
18BF A7         and a	:C
	:; clear carry

18C0:C
18C0 1808       jr $18CA	:C
	:; forward to COUNT-ONE
	:;

18C2:C
	:#; ---
	:#
	:#;; SUBN-ONLY
18C2 A7         and a	:C SUBN_ONLY
	:;

18C3:C
18C3 ED52       sbc hl, de	:C
	:;

18C5:C
18C5 D9         exx	:C
	:;

18C6:C
18C6 ED52       sbc hl, de	:C
	:;

18C8:C
18C8 D9         exx	:C
	:;
	:;

18C9:C
	:#;; NO-RSTORE
18C9 37         scf	:C NO_RSTORE
	:; set carry flag
	:;

18CA:C
	:#;; COUNT-ONE
18CA 04         inc b	:C COUNT_ONE
	:; increment the counter

18CB:C
18CB FAA218     jp m, $18A2	:C
	:; back while still minus to DIV-LOOP
	:;

18CE:C
18CE F5         push af	:C
	:;

18CF:C
18CF 28E1       jr z, $18B2	:C
	:; back to DIV-START
	:;

18D1:C
	:#; "This jump is made to the wrong place. No 34th bit will ever be obtained
	:#; without first shifting the dividend. Hence important results like 1/10 and
	:#; 1/1000 are not rounded up as they should be. Rounding up never occurs when
	:#; it depends on the 34th bit. The jump should be made to div-34th above."
	:#; - Dr. Frank O'Hara, "The Complete Spectrum ROM Disassembly", 1983,
	:#; published by Melbourne House.
	:#; (Note. on the ZX81 this would be JR Z,L18AB)
	:#;
	:#; However if you make this change, then while (1/2=.5) will now evaluate as
	:#; true, (.25=1/4), which did evaluate as true, no longer does.
	:#
18D1 5F         ld e, a	:C
	:;

18D2:C
18D2 51         ld d, c	:C
	:;

18D3:C
18D3 D9         exx	:C
	:;

18D4:C
18D4 59         ld e, c	:C
	:;

18D5:C
18D5 50         ld d, b	:C
	:;
	:;

18D6:C
18D6 F1         pop af	:C
	:;

18D7:C
18D7 CB18       rr b	:C
	:;

18D9:C
18D9 F1         pop af	:C
	:;

18DA:C
18DA CB18       rr b	:C
	:;
	:;

18DC:C
18DC D9         exx	:C
	:;

18DD:C
18DD C1         pop bc	:C
	:;

18DE:C
18DE E1         pop hl	:C
	:;

18DF:C
18DF 78         ld a, b	:C
	:;

18E0:C
18E0 91         sub c	:C
	:;

18E1:C
18E1 C31018     jp $1810	:C
	:; jump back to DIVN-EXPT
	:;

18E4:C
	:#; ------------------------------------------------
	:#; THE 'INTEGER TRUNCATION TOWARDS ZERO' SUBROUTINE
	:#; ------------------------------------------------
	:#;
	:#
	:#;; truncate
18E4 7E         ld a, (hl)	:C truncate
	:; fetch exponent

18E5:C
18E5 FE81       cp $81	:C
	:; compare to +1  

18E7:C
18E7 3006       jr nc, $18EF	:C
	:; forward, if 1 or more, to T-GR-ZERO
	:;

18E9:C
	:#; else the number is smaller than plus or minus 1 and can be made zero.
	:#
18E9 3600       ld (hl), $00	:C
	:; make exponent zero.

18EB:C
18EB 3E20       ld a, $20	:C
	:; prepare to set 32 bits of mantissa to zero.

18ED:C
18ED 1805       jr $18F4	:C
	:; forward to NIL-BYTES
	:;

18EF:C
	:#; ---
	:#
	:#;; T-GR-ZERO
18EF D6A0       sub $A0	:C T_GR_ZERO
	:; subtract +32 from exponent

18F1:C
18F1 F0         ret p	:C
	:; return if result is positive as all 32 bits 
	:; of the mantissa relate to the integer part.
	:; The floating point is somewhere to the right 
	:; of the mantissa
	:;

18F2:C
18F2 ED44       neg	:C
	:; else negate to form number of rightmost bits 
	:; to be blanked.
	:;

18F4:C
	:#; for instance, disregarding the sign bit, the number 3.5 is held as 
	:#; exponent $82 mantissa .11100000 00000000 00000000 00000000
	:#; we need to set $82 - $A0 = $E2 NEG = $1E (thirty) bits to zero to form the 
	:#; integer.
	:#; The sign of the number is never considered as the first bit of the mantissa
	:#; must be part of the integer.
	:#
	:#;; NIL-BYTES
18F4 D5         push de	:C NIL_BYTES
	:; save pointer to STKEND

18F5:C
18F5 EB         ex de, hl	:C
	:; HL points at STKEND

18F6:C
18F6 2B         dec hl	:C
	:; now at last byte of mantissa.

18F7:C
18F7 47         ld b, a	:C
	:; Transfer bit count to B register.

18F8:C
18F8 CB38       srl b	:C
	:; divide by 

18FA:C
18FA CB38       srl b	:C
	:; eight

18FC:C
18FC CB38       srl b	:C
	:;

18FE:C
18FE 2805       jr z, $1905	:C
	:; forward if zero to BITS-ZERO
	:;

1900:C
	:#; else the original count was eight or more and whole bytes can be blanked.
	:#
	:#;; BYTE-ZERO
1900 3600       ld (hl), $00	:C BYTE_ZERO
	:; set eight bits to zero.

1902:C
1902 2B         dec hl	:C
	:; point to more significant byte of mantissa.

1903:C
1903 10FB       djnz $1900	:C
	:; loop back to BYTE-ZERO
	:;

1905:C
	:#; now consider any residual bits.
	:#
	:#;; BITS-ZERO
1905 E607       and $07	:C BITS_ZERO
	:; isolate the remaining bits

1907:C
1907 2809       jr z, $1912	:C
	:; forward if none to IX-END
	:;

1909:C
1909 47         ld b, a	:C
	:; transfer bit count to B counter.

190A:C
190A 3EFF       ld a, $FF	:C
	:; form a mask 11111111
	:;

190C:C
	:#;; LESS-MASK
190C CB27       sla a	:C LESS_MASK
	:; 1 <- 76543210 <- o     slide mask leftwards.

190E:C
190E 10FC       djnz $190C	:C
	:; loop back for bit count to LESS-MASK
	:;

1910:C
1910 A6         and (hl)	:C
	:; lose the unwanted rightmost bits

1911:C
1911 77         ld (hl), a	:C
	:; and place in mantissa byte.
	:;

1912:C
	:#;; IX-END
1912 EB         ex de, hl	:C IX_END
	:; restore result pointer from DE. 

1913:C
1913 D1         pop de	:C
	:; restore STKEND from stack.

1914:C
1914 C9         ret	:C
	:; return.
	:;
	:;

1915:B
	:#;********************************
	:#;**  FLOATING-POINT CALCULATOR **
	:#;********************************
	:#
	:#; As a general rule the calculator avoids using the IY register.
	:#; Exceptions are val and str$.
	:#; So an assembly language programmer who has disabled interrupts to use IY
	:#; for other purposes can still use the calculator for mathematical
	:#; purposes.
	:#
	:#
	:#; ------------------------
	:#; THE 'TABLE OF CONSTANTS'
	:#; ------------------------
	:#; The ZX81 has only floating-point number representation.
	:#; Both the ZX80 and the ZX Spectrum have integer numbers in some form.
	:#
	:#;; stk-zero                                                 00 00 00 00 00
1915-1915 00	:B stk_zero
	:;;Bytes: 1

1916:B
1916-1916 B0	:B
	:;;Exponent $00

1917:B
1917-1917 00	:B
	:;;(+00,+00,+00)
	:;

1918:B
	:#;; stk-one                                                  81 00 00 00 00
1918-1918 31	:B stk_one
	:;;Exponent $81, Bytes: 1

1919:B
1919-1919 00	:B
	:;;(+00,+00,+00)
	:;
	:;

191A:B
	:#;; stk-half                                                 80 00 00 00 00
191A-191A 30	:B stk_half
	:;;Exponent: $80, Bytes: 1

191B:B
191B-191B 00	:B
	:;;(+00,+00,+00)
	:;
	:;

191C:B
	:#;; stk-pi/2                                                 81 49 0F DA A2
191C-191C F1	:B stk_pi_2
	:;;Exponent: $81, Bytes: 4

191D:B
191D-1920 490FDAA2	:B
	:;;
	:;

1921:B
	:#;; stk-ten                                                  84 20 00 00 00
1921-1921 34	:B stk_ten
	:;;Exponent: $84, Bytes: 1

1922:B
1922-1922 20	:B
	:;;(+00,+00,+00)
	:;
	:;

1923:W
	:#; ------------------------
	:#; THE 'TABLE OF ADDRESSES'
	:#; ------------------------
	:#;
	:#; starts with binary operations which have two operands and one result.
	:#; three pseudo binary operations first.
	:#
	:#;; tbl-addrs
1923-1924 2F1C	:W tbl_addrs
	:; $00 Address: $1C2F - jump-true

1925:W
1925-1926 721A	:W
	:; $01 Address: $1A72 - exchange

1927:W
1927-1928 E319	:W
	:; $02 Address: $19E3 - delete
	:;

1929:W
	:#; true binary operations.
	:#
1929-192A 4C17	:W
	:; $03 Address: $174C - subtract

192B:W
192B-192C C617	:W
	:; $04 Address: $176C - multiply

192D:W
192D-192E 8218	:W
	:; $05 Address: $1882 - division

192F:W
192F-1930 E21D	:W
	:; $06 Address: $1DE2 - to-power

1931:W
1931-1932 ED1A	:W
	:; $07 Address: $1AED - or
	:;

1933:W
1933-1934 F31A	:W
	:; $08 Address: $1B03 - no-&-no

1935:W
1935-1936 031B	:W
	:; $09 Address: $1B03 - no-l-eql

1937:W
1937-1938 031B	:W
	:; $0A Address: $1B03 - no-gr-eql

1939:W
1939-193A 031B	:W
	:; $0B Address: $1B03 - nos-neql

193B:W
193B-193C 031B	:W
	:; $0C Address: $1B03 - no-grtr

193D:W
193D-193E 031B	:W
	:; $0D Address: $1B03 - no-less

193F:W
193F-1940 031B	:W
	:; $0E Address: $1B03 - nos-eql

1941:W
1941-1942 5517	:W
	:; $0F Address: $1755 - addition
	:;

1943:W
1943-1944 F81A	:W
	:; $10 Address: $1AF8 - str-&-no

1945:W
1945-1946 031B	:W
	:; $11 Address: $1B03 - str-l-eql

1947:W
1947-1948 031B	:W
	:; $12 Address: $1B03 - str-gr-eql

1949:W
1949-194A 031B	:W
	:; $13 Address: $1B03 - strs-neql

194B:W
194B-194C 031B	:W
	:; $14 Address: $1B03 - str-grtr

194D:W
194D-194E 031B	:W
	:; $15 Address: $1B03 - str-less

194F:W
194F-1950 031B	:W
	:; $16 Address: $1B03 - strs-eql

1951:W
1951-1952 621B	:W
	:; $17 Address: $1B62 - strs-add
	:;

1953:W
	:#; unary follow
	:#
1953-1954 A01A	:W
	:; $18 Address: $1AA0 - neg
	:;

1955:W
1955-1956 061C	:W
	:; $19 Address: $1C06 - code

1957:W
1957-1958 A41B	:W
	:; $1A Address: $1BA4 - val

1959:W
1959-195A 111C	:W
	:; $1B Address: $1C11 - len

195B:W
195B-195C 491D	:W
	:; $1C Address: $1D49 - sin

195D:W
195D-195E 3E1D	:W
	:; $1D Address: $1D3E - cos

195F:W
195F-1960 6E1D	:W
	:; $1E Address: $1D6E - tan

1961:W
1961-1962 C41D	:W
	:; $1F Address: $1DC4 - asn

1963:W
1963-1964 D41D	:W
	:; $20 Address: $1DD4 - acs

1965:W
1965-1966 761D	:W
	:; $21 Address: $1D76 - atn

1967:W
1967-1968 A91C	:W
	:; $22 Address: $1CA9 - ln

1969:W
1969-196A 5B1C	:W
	:; $23 Address: $1C5B - exp

196B:W
196B-196C 461C	:W
	:; $24 Address: $1C46 - int

196D:W
196D-196E DB1D	:W
	:; $25 Address: $1DDB - sqr

196F:W
196F-1970 AF1A	:W
	:; $26 Address: $1AAF - sgn

1971:W
1971-1972 AA1A	:W
	:; $27 Address: $1AAA - abs

1973:W
1973-1974 BE1A	:W
	:; $28 Address: $1A1B - peek

1975:W
1975-1976 C51A	:W
	:; $29 Address: $1AC5 - usr-no

1977:W
1977-1978 D51B	:W
	:; $2A Address: $1BD5 - str$

1979:W
1979-197A 8F1B	:W
	:; $2B Address: $1B8F - chrs

197B:W
197B-197C D51A	:W
	:; $2C Address: $1AD5 - not
	:;

197D:W
	:#; end of true unary
	:#
197D-197E F619	:W
	:; $2D Address: $19F6 - duplicate

197F:W
197F-1980 371C	:W
	:; $2E Address: $1C37 - n-mod-m
	:;

1981:W
1981-1982 231C	:W
	:; $2F Address: $1C23 - jump

1983:W
1983-1984 FC19	:W
	:; $30 Address: $19FC - stk-data
	:;

1985:W
1985-1986 171C	:W
	:; $31 Address: $1C17 - dec-jr-nz

1987:W
1987-1988 DB1A	:W
	:; $32 Address: $1ADB - less-0

1989:W
1989-198A CE1A	:W
	:; $33 Address: $1ACE - greater-0

198B:W
198B-198C 2B00	:W
	:; $34 Address: $002B - end-calc

198D:W
198D-198E 181D	:W
	:; $35 Address: $1D18 - get-argt

198F:W
198F-1990 E418	:W
	:; $36 Address: $18E4 - truncate

1991:W
1991-1992 E419	:W
	:; $37 Address: $19E4 - fp-calc-2

1993:W
1993-1994 5A15	:W
	:; $38 Address: $155A - e-to-fp
	:;

1995:W
	:#; the following are just the next available slots for the 128 compound literals
	:#; which are in range $80 - $FF.
	:#
1995-1996 7F1A	:W
	:; $39 Address: $1A7F - series-xx    $80 - $9F.

1997:W
1997-1998 511A	:W
	:; $3A Address: $1A51 - stk-const-xx $A0 - $BF.

1999:W
1999-199A 631A	:W
	:; $3B Address: $1A63 - st-mem-xx    $C0 - $DF.

199B:W
199B-199C 451A	:W
	:; $3C Address: $1A45 - get-mem-xx   $E0 - $FF.
	:;

199D:C
	:#; Aside: 3D - 7F are therefore unused calculator literals.
	:#;        39 - 7B would be available for expansion.
	:#
	:#; -------------------------------
	:#; THE 'FLOATING POINT CALCULATOR'
	:#; -------------------------------
	:#;
	:#;
	:#
	:#;; CALCULATE
199D CD851B     call $1B85	:C CALCULATE
	:; routine STK-PNTRS is called to set up the
	:; calculator stack pointers for a default
	:; unary operation. HL = last value on stack.
	:; DE = STKEND first location after stack.
	:;

19A0:C
	:#; the calculate routine is called at this point by the series generator...
	:#
	:#;; GEN-ENT-1
19A0 78         ld a, b	:C GEN_ENT_1
	:; fetch the Z80 B register to A

19A1:C
19A1 321E40     ld ($401E), a	:C
	:; and store value in system variable BREG.
	:; this will be the counter for dec-jr-nz
	:; or if used from fp-calc2 the calculator
	:; instruction.
	:;

19A4:C
	:#; ... and again later at this point
	:#
	:#;; GEN-ENT-2
19A4 D9         exx	:C GEN_ENT_2
	:; switch sets

19A5:C
19A5 E3         ex (sp), hl	:C
	:; and store the address of next instruction,
	:; the return address, in H'L'.
	:; If this is a recursive call then the H'L'
	:; of the previous invocation goes on stack.
	:; c.f. end-calc.

19A6:C
19A6 D9         exx	:C
	:; switch back to main set.
	:;

19A7:C
	:#; this is the re-entry looping point when handling a string of literals.
	:#
	:#;; RE-ENTRY
19A7 ED531C40   ld ($401C), de	:C RE_ENTRY
	:; save end of stack in system variable STKEND

19AB:C
19AB D9         exx	:C
	:; switch to alt

19AC:C
19AC 7E         ld a, (hl)	:C
	:; get next literal

19AD:C
19AD 23         inc hl	:C
	:; increase pointer'
	:;

19AE:C
	:#; single operation jumps back to here
	:#
	:#;; SCAN-ENT
19AE E5         push hl	:C SCAN_ENT
	:; save pointer on stack   *

19AF:C
19AF A7         and a	:C
	:; now test the literal

19B0:C
19B0 F2C219     jp p, $19C2	:C
	:; forward to FIRST-3D if in range $00 - $3D
	:; anything with bit 7 set will be one of
	:; 128 compound literals.
	:;

19B3:C
	:#; compound literals have the following format.
	:#; bit 7 set indicates compound.
	:#; bits 6-5 the subgroup 0-3.
	:#; bits 4-0 the embedded parameter $00 - $1F.
	:#; The subgroup 0-3 needs to be manipulated to form the next available four
	:#; address places after the simple literals in the address table.
	:#
19B3 57         ld d, a	:C
	:; save literal in D

19B4:C
19B4 E660       and $60	:C
	:; and with 01100000 to isolate subgroup

19B6:C
19B6 0F         rrca	:C
	:; rotate bits

19B7:C
19B7 0F         rrca	:C
	:; 4 places to right

19B8:C
19B8 0F         rrca	:C
	:; not five as we need offset * 2

19B9:C
19B9 0F         rrca	:C
	:; 00000xx0

19BA:C
19BA C672       add a, $72	:C
	:; add ($39 * 2) to give correct offset.
	:; alter above if you add more literals.

19BC:C
19BC 6F         ld l, a	:C
	:; store in L for later indexing.

19BD:C
19BD 7A         ld a, d	:C
	:; bring back compound literal

19BE:C
19BE E61F       and $1F	:C
	:; use mask to isolate parameter bits

19C0:C
19C0 180E       jr $19D0	:C
	:; forward to ENT-TABLE
	:;

19C2:C
	:#; ---
	:#
	:#; the branch was here with simple literals.
	:#
	:#;; FIRST-3D
19C2 FE18       cp $18	:C FIRST_3D
	:; compare with first unary operations.

19C4:C
19C4 3008       jr nc, $19CE	:C
	:; to DOUBLE-A with unary operations
	:;

19C6:C
	:#; it is binary so adjust pointers.
	:#
19C6 D9         exx	:C
	:;

19C7:C
19C7 01FBFF     ld bc, $FFFB	:C
	:; the value -5

19CA:C
19CA 54         ld d, h	:C
	:; transfer HL, the last value, to DE.

19CB:C
19CB 5D         ld e, l	:C
	:;

19CC:C
19CC 09         add hl, bc	:C
	:; subtract 5 making HL point to second
	:; value.

19CD:C
19CD D9         exx	:C
	:;
	:;

19CE:C
	:#;; DOUBLE-A
19CE 07         rlca	:C DOUBLE_A
	:; double the literal

19CF:C
19CF 6F         ld l, a	:C
	:; and store in L for indexing
	:;

19D0:C
	:#;; ENT-TABLE
19D0 112319     ld de, $1923	:C ENT_TABLE
	:; Address: tbl-addrs

19D3:C
19D3 2600       ld h, $00	:C
	:; prepare to index

19D5:C
19D5 19         add hl, de	:C
	:; add to get address of routine

19D6:C
19D6 5E         ld e, (hl)	:C
	:; low byte to E

19D7:C
19D7 23         inc hl	:C
	:;

19D8:C
19D8 56         ld d, (hl)	:C
	:; high byte to D
	:;

19D9:C
19D9 21A719     ld hl, $19A7	:C
	:; Address: RE-ENTRY

19DC:C
19DC E3         ex (sp), hl	:C
	:; goes on machine stack
	:; address of next literal goes to HL. *
	:;
	:;

19DD:C
19DD D5         push de	:C
	:; now the address of routine is stacked.

19DE:C
19DE D9         exx	:C
	:; back to main set
	:; avoid using IY register.

19DF:C
19DF ED4B1D40   ld bc, ($401D)	:C
	:; STKEND_hi
	:; nothing much goes to C but BREG to B
	:; and continue into next ret instruction
	:; which has a dual identity
	:;
	:;

19E3:C
	:#; -----------------------
	:#; THE 'DELETE' SUBROUTINE
	:#; -----------------------
	:#; offset $02: 'delete'
	:#; A simple return but when used as a calculator literal this
	:#; deletes the last value from the calculator stack.
	:#; On entry, as always with binary operations,
	:#; HL=first number, DE=second number
	:#; On exit, HL=result, DE=stkend.
	:#; So nothing to do
	:#
	:#;; delete
19E3 C9         ret	:C delete
	:; return - indirect jump if from above.
	:;

19E4:C
	:#; ---------------------------------
	:#; THE 'SINGLE OPERATION' SUBROUTINE
	:#; ---------------------------------
	:#; offset $37: 'fp-calc-2'
	:#; this single operation is used, in the first instance, to evaluate most
	:#; of the mathematical and string functions found in BASIC expressions.
	:#
	:#;; fp-calc-2
19E4 F1         pop af	:C fp_calc_2
	:; drop return address.

19E5:C
19E5 3A1E40     ld a, ($401E)	:C
	:; load accumulator from system variable BREG
	:; value will be literal eg. 'tan'

19E8:C
19E8 D9         exx	:C
	:; switch to alt

19E9:C
19E9 18C3       jr $19AE	:C
	:; back to SCAN-ENT
	:; next literal will be end-calc in scanning
	:;

19EB:C
	:#; ------------------------------
	:#; THE 'TEST 5 SPACES' SUBROUTINE
	:#; ------------------------------
	:#; This routine is called from MOVE-FP, STK-CONST and STK-STORE to
	:#; test that there is enough space between the calculator stack and the
	:#; machine stack for another five-byte value. It returns with BC holding
	:#; the value 5 ready for any subsequent LDIR.
	:#
	:#;; TEST-5-SP
19EB D5         push de	:C TEST_5_SP
	:; save

19EC:C
19EC E5         push hl	:C
	:; registers

19ED:C
19ED 010500     ld bc, $0005	:C
	:; an overhead of five bytes

19F0:C
19F0 CDC50E     call $0EC5	:C
	:; routine TEST-ROOM tests free RAM raising
	:; an error if not.

19F3:C
19F3 E1         pop hl	:C
	:; else restore

19F4:C
19F4 D1         pop de	:C
	:; registers.

19F5:C
19F5 C9         ret	:C
	:; return with BC set at 5.
	:;
	:;

19F6:C
	:#; ---------------------------------------------
	:#; THE 'MOVE A FLOATING POINT NUMBER' SUBROUTINE
	:#; ---------------------------------------------
	:#; offset $2D: 'duplicate'
	:#; This simple routine is a 5-byte LDIR instruction
	:#; that incorporates a memory check.
	:#; When used as a calculator literal it duplicates the last value on the
	:#; calculator stack.
	:#; Unary so on entry HL points to last value, DE to stkend
	:#
	:#;; duplicate
	:#;; MOVE-FP
19F6 CDEB19     call $19EB	:C MOVE_FP
	:; routine TEST-5-SP test free memory
	:; and sets BC to 5.

19F9:C
19F9 EDB0       ldir	:C
	:; copy the five bytes.

19FB:C
19FB C9         ret	:C
	:; return with DE addressing new STKEND
	:; and HL addressing new last value.
	:;

19FC:C
	:#; -------------------------------
	:#; THE 'STACK LITERALS' SUBROUTINE
	:#; -------------------------------
	:#; offset $30: 'stk-data'
	:#; When a calculator subroutine needs to put a value on the calculator
	:#; stack that is not a regular constant this routine is called with a
	:#; variable number of following data bytes that convey to the routine
	:#; the floating point form as succinctly as is possible.
	:#
	:#;; stk-data
19FC 62         ld h, d	:C stk_data
	:; transfer STKEND

19FD:C
19FD 6B         ld l, e	:C
	:; to HL for result.
	:;

19FE:C
	:#;; STK-CONST
19FE CDEB19     call $19EB	:C STK_CONST
	:; routine TEST-5-SP tests that room exists
	:; and sets BC to $05.
	:;

1A01:C
1A01 D9         exx	:C
	:; switch to alternate set

1A02:C
1A02 E5         push hl	:C
	:; save the pointer to next literal on stack

1A03:C
1A03 D9         exx	:C
	:; switch back to main set
	:;

1A04:C
1A04 E3         ex (sp), hl	:C
	:; pointer to HL, destination to stack.
	:;

1A05:C
1A05 C5         push bc	:C
	:; save BC - value 5 from test room ??.
	:;

1A06:C
1A06 7E         ld a, (hl)	:C
	:; fetch the byte following 'stk-data'

1A07:C
1A07 E6C0       and $C0	:C
	:; isolate bits 7 and 6

1A09:C
1A09 07         rlca	:C
	:; rotate

1A0A:C
1A0A 07         rlca	:C
	:; to bits 1 and 0  range $00 - $03.

1A0B:C
1A0B 4F         ld c, a	:C
	:; transfer to C

1A0C:C
1A0C 0C         inc c	:C
	:; and increment to give number of bytes
	:; to read. $01 - $04

1A0D:C
1A0D 7E         ld a, (hl)	:C
	:; reload the first byte

1A0E:C
1A0E E63F       and $3F	:C
	:; mask off to give possible exponent.

1A10:C
1A10 2002       jr nz, $1A14	:C
	:; forward to FORM-EXP if it was possible to
	:; include the exponent.
	:;

1A12:C
	:#; else byte is just a byte count and exponent comes next.
	:#
1A12 23         inc hl	:C
	:; address next byte and

1A13:C
1A13 7E         ld a, (hl)	:C
	:; pick up the exponent ( - $50).
	:;

1A14:C
	:#;; FORM-EXP
1A14 C650       add a, $50	:C FORM_EXP
	:; now add $50 to form actual exponent

1A16:C
1A16 12         ld (de), a	:C
	:; and load into first destination byte.

1A17:C
1A17 3E05       ld a, $05	:C
	:; load accumulator with $05 and

1A19:C
1A19 91         sub c	:C
	:; subtract C to give count of trailing
	:; zeros plus one.

1A1A:C
1A1A 23         inc hl	:C
	:; increment source

1A1B:C
1A1B 13         inc de	:C
	:; increment destination

1A1C:C
1A1C 0600       ld b, $00	:C
	:; prepare to copy

1A1E:C
1A1E EDB0       ldir	:C
	:; copy C bytes
	:;

1A20:C
1A20 C1         pop bc	:C
	:; restore 5 counter to BC ??.
	:;

1A21:C
1A21 E3         ex (sp), hl	:C
	:; put HL on stack as next literal pointer
	:; and the stack value - result pointer -
	:; to HL.
	:;

1A22:C
1A22 D9         exx	:C
	:; switch to alternate set.

1A23:C
1A23 E1         pop hl	:C
	:; restore next literal pointer from stack
	:; to H'L'.

1A24:C
1A24 D9         exx	:C
	:; switch back to main set.
	:;

1A25:C
1A25 47         ld b, a	:C
	:; zero count to B

1A26:C
1A26 AF         xor a	:C
	:; clear accumulator
	:;

1A27:C
	:#;; STK-ZEROS
1A27 05         dec b	:C STK_ZEROS
	:; decrement B counter

1A28:C
1A28 C8         ret z	:C
	:; return if zero.          >>
	:; DE points to new STKEND
	:; HL to new number.
	:;

1A29:C
1A29 12         ld (de), a	:C
	:; else load zero to destination

1A2A:C
1A2A 13         inc de	:C
	:; increase destination

1A2B:C
1A2B 18FA       jr $1A27	:C
	:; loop back to STK-ZEROS until done.
	:;

1A2D:C
	:#; -------------------------------
	:#; THE 'SKIP CONSTANTS' SUBROUTINE
	:#; -------------------------------
	:#; This routine traverses variable-length entries in the table of constants,
	:#; stacking intermediate, unwanted constants onto a dummy calculator stack,
	:#; in the first five bytes of the ZX81 ROM.
	:#
	:#;; SKIP-CONS
1A2D A7         and a	:C SKIP_CONS
	:; test if initially zero.
	:;

1A2E:C
	:#;; SKIP-NEXT
1A2E C8         ret z	:C SKIP_NEXT
	:; return if zero.          >>
	:;

1A2F:C
1A2F F5         push af	:C
	:; save count.

1A30:C
1A30 D5         push de	:C
	:; and normal STKEND
	:;

1A31:C
1A31 110000     ld de, $0000	:C
	:; dummy value for STKEND at start of ROM
	:; Note. not a fault but this has to be
	:; moved elsewhere when running in RAM.
	:;

1A34:C
1A34 CDFE19     call $19FE	:C
	:; routine STK-CONST works through variable
	:; length records.
	:;

1A37:C
1A37 D1         pop de	:C
	:; restore real STKEND

1A38:C
1A38 F1         pop af	:C
	:; restore count

1A39:C
1A39 3D         dec a	:C
	:; decrease

1A3A:C
1A3A 18F2       jr $1A2E	:C
	:; loop back to SKIP-NEXT
	:;

1A3C:C
	:#; --------------------------------
	:#; THE 'MEMORY LOCATION' SUBROUTINE
	:#; --------------------------------
	:#; This routine, when supplied with a base address in HL and an index in A,
	:#; will calculate the address of the A'th entry, where each entry occupies
	:#; five bytes. It is used for addressing floating-point numbers in the
	:#; calculator's memory area.
	:#
	:#;; LOC-MEM
1A3C 4F         ld c, a	:C LOC_MEM
	:; store the original number $00-$1F.

1A3D:C
1A3D 07         rlca	:C
	:; double.

1A3E:C
1A3E 07         rlca	:C
	:; quadruple.

1A3F:C
1A3F 81         add a, c	:C
	:; now add original value to multiply by five.
	:;

1A40:C
1A40 4F         ld c, a	:C
	:; place the result in C.

1A41:C
1A41 0600       ld b, $00	:C
	:; set B to 0.

1A43:C
1A43 09         add hl, bc	:C
	:; add to form address of start of number in HL.
	:;

1A44:C
1A44 C9         ret	:C
	:; return.
	:;

1A45:C
	:#; -------------------------------------
	:#; THE 'GET FROM MEMORY AREA' SUBROUTINE
	:#; -------------------------------------
	:#; offsets $E0 to $FF: 'get-mem-0', 'get-mem-1' etc.
	:#; A holds $00-$1F offset.
	:#; The calculator stack increases by 5 bytes.
	:#
	:#;; get-mem-xx
1A45 D5         push de	:C get_mem_xx
	:; save STKEND

1A46:C
1A46 2A1F40     ld hl, ($401F)	:C
	:; MEM is base address of the memory cells.

1A49:C
1A49 CD3C1A     call $1A3C	:C
	:; routine LOC-MEM so that HL = first byte

1A4C:C
1A4C CDF619     call $19F6	:C
	:; routine MOVE-FP moves 5 bytes with memory
	:; check.
	:; DE now points to new STKEND.

1A4F:C
1A4F E1         pop hl	:C
	:; the original STKEND is now RESULT pointer.

1A50:C
1A50 C9         ret	:C
	:; return.
	:;

1A51:C
	:#; ---------------------------------
	:#; THE 'STACK A CONSTANT' SUBROUTINE
	:#; ---------------------------------
	:#; offset $A0: 'stk-zero'
	:#; offset $A1: 'stk-one'
	:#; offset $A2: 'stk-half'
	:#; offset $A3: 'stk-pi/2'
	:#; offset $A4: 'stk-ten'
	:#; This routine allows a one-byte instruction to stack up to 32 constants
	:#; held in short form in a table of constants. In fact only 5 constants are
	:#; required. On entry the A register holds the literal ANDed with $1F.
	:#; It isn't very efficient and it would have been better to hold the
	:#; numbers in full, five byte form and stack them in a similar manner
	:#; to that which would be used later for semi-tone table values.
	:#
	:#;; stk-const-xx
1A51 62         ld h, d	:C stk_const_xx
	:; save STKEND - required for result

1A52:C
1A52 6B         ld l, e	:C
	:;

1A53:C
1A53 D9         exx	:C
	:; swap

1A54:C
1A54 E5         push hl	:C
	:; save pointer to next literal

1A55:C
1A55 211519     ld hl, $1915	:C
	:; Address: stk-zero - start of table of
	:; constants

1A58:C
1A58 D9         exx	:C
	:;

1A59:C
1A59 CD2D1A     call $1A2D	:C
	:; routine SKIP-CONS

1A5C:C
1A5C CDFE19     call $19FE	:C
	:; routine STK-CONST

1A5F:C
1A5F D9         exx	:C
	:;

1A60:C
1A60 E1         pop hl	:C
	:; restore pointer to next literal.

1A61:C
1A61 D9         exx	:C
	:;

1A62:C
1A62 C9         ret	:C
	:; return.
	:;

1A63:C
	:#; ---------------------------------------
	:#; THE 'STORE IN A MEMORY AREA' SUBROUTINE
	:#; ---------------------------------------
	:#; Offsets $C0 to $DF: 'st-mem-0', 'st-mem-1' etc.
	:#; Although 32 memory storage locations can be addressed, only six
	:#; $C0 to $C5 are required by the ROM and only the thirty bytes (6*5)
	:#; required for these are allocated. ZX81 programmers who wish to
	:#; use the floating point routines from assembly language may wish to
	:#; alter the system variable MEM to point to 160 bytes of RAM to have
	:#; use the full range available.
	:#; A holds derived offset $00-$1F.
	:#; Unary so on entry HL points to last value, DE to STKEND.
	:#
	:#;; st-mem-xx
1A63 E5         push hl	:C st_mem_xx
	:; save the result pointer.

1A64:C
1A64 EB         ex de, hl	:C
	:; transfer to DE.

1A65:C
1A65 2A1F40     ld hl, ($401F)	:C
	:; fetch MEM the base of memory area.

1A68:C
1A68 CD3C1A     call $1A3C	:C
	:; routine LOC-MEM sets HL to the destination.

1A6B:C
1A6B EB         ex de, hl	:C
	:; swap - HL is start, DE is destination.

1A6C:C
1A6C CDF619     call $19F6	:C
	:; routine MOVE-FP.
	:; note. a short ld bc,5; ldir
	:; the embedded memory check is not required
	:; so these instructions would be faster!

1A6F:C
1A6F EB         ex de, hl	:C
	:; DE = STKEND

1A70:C
1A70 E1         pop hl	:C
	:; restore original result pointer

1A71:C
1A71 C9         ret	:C
	:; return.
	:;

1A72:C
	:#; -------------------------
	:#; THE 'EXCHANGE' SUBROUTINE
	:#; -------------------------
	:#; offset $01: 'exchange'
	:#; This routine exchanges the last two values on the calculator stack
	:#; On entry, as always with binary operations,
	:#; HL=first number, DE=second number
	:#; On exit, HL=result, DE=stkend.
	:#
	:#;; exchange
1A72 0605       ld b, $05	:C exchange
	:; there are five bytes to be swapped
	:;

1A74:C
	:#; start of loop.
	:#
	:#;; SWAP-BYTE
1A74 1A         ld a, (de)	:C SWAP_BYTE
	:; each byte of second

1A75:C
1A75 4E         ld c, (hl)	:C
	:; each byte of first

1A76:C
1A76 EB         ex de, hl	:C
	:; swap pointers

1A77:C
1A77 12         ld (de), a	:C
	:; store each byte of first

1A78:C
1A78 71         ld (hl), c	:C
	:; store each byte of second

1A79:C
1A79 23         inc hl	:C
	:; advance both

1A7A:C
1A7A 13         inc de	:C
	:; pointers.

1A7B:C
1A7B 10F7       djnz $1A74	:C
	:; loop back to SWAP-BYTE until all 5 done.
	:;

1A7D:C
1A7D EB         ex de, hl	:C
	:; even up the exchanges
	:; so that DE addresses STKEND.

1A7E:C
1A7E C9         ret	:C
	:; return.
	:;

1A7F:C
	:#; ---------------------------------
	:#; THE 'SERIES GENERATOR' SUBROUTINE
	:#; ---------------------------------
	:#; offset $86: 'series-06'
	:#; offset $88: 'series-08'
	:#; offset $8C: 'series-0C'
	:#; The ZX81 uses Chebyshev polynomials to generate approximations for
	:#; SIN, ATN, LN and EXP. These are named after the Russian mathematician
	:#; Pafnuty Chebyshev, born in 1821, who did much pioneering work on numerical
	:#; series. As far as calculators are concerned, Chebyshev polynomials have an
	:#; advantage over other series, for example the Taylor series, as they can
	:#; reach an approximation in just six iterations for SIN, eight for EXP and
	:#; twelve for LN and ATN. The mechanics of the routine are interesting but
	:#; for full treatment of how these are generated with demonstrations in
	:#; Sinclair BASIC see "The Complete Spectrum ROM Disassembly" by Dr Ian Logan
	:#; and Dr Frank O'Hara, published 1983 by Melbourne House.
	:#
	:#;; series-xx
1A7F 47         ld b, a	:C series_xx
	:; parameter $00 - $1F to B counter

1A80:C
1A80 CDA019     call $19A0	:C
	:; routine GEN-ENT-1 is called.
	:; A recursive call to a special entry point
	:; in the calculator that puts the B register
	:; in the system variable BREG. The return
	:; address is the next location and where
	:; the calculator will expect its first
	:; instruction - now pointed to by HL'.
	:; The previous pointer to the series of
	:; five-byte numbers goes on the machine stack.
	:;

1A83:B
	:#; The initialization phase.
	:#
1A83-1A83 2D	:B
	:;;duplicate       x,x

1A84:B
1A84-1A84 0F	:B
	:;;addition        x+x

1A85:B
1A85-1A85 C0	:B
	:;;st-mem-0        x+x

1A86:B
1A86-1A86 02	:B
	:;;delete          .

1A87:B
1A87-1A87 A0	:B
	:;;stk-zero        0

1A88:B
1A88-1A88 C2	:B
	:;;st-mem-2        0
	:;

1A89:B
	:#; a loop is now entered to perform the algebraic calculation for each of
	:#; the numbers in the series
	:#
	:#;; G-LOOP
1A89-1A89 2D	:B G_LOOP
	:;;duplicate       v,v.

1A8A:B
1A8A-1A8A E0	:B
	:;;get-mem-0       v,v,x+2

1A8B:B
1A8B-1A8B 04	:B
	:;;multiply        v,v*x+2

1A8C:B
1A8C-1A8C E2	:B
	:;;get-mem-2       v,v*x+2,v

1A8D:B
1A8D-1A8D C1	:B
	:;;st-mem-1

1A8E:B
1A8E-1A8E 03	:B
	:;;subtract

1A8F:B
1A8F-1A8F 34	:B
	:;;end-calc
	:;

1A90:C
	:#; the previous pointer is fetched from the machine stack to H'L' where it
	:#; addresses one of the numbers of the series following the series literal.
	:#
1A90 CDFC19     call $19FC	:C
	:; routine STK-DATA is called directly to
	:; push a value and advance H'L'.

1A93:C
1A93 CDA419     call $19A4	:C
	:; routine GEN-ENT-2 recursively re-enters
	:; the calculator without disturbing
	:; system variable BREG
	:; H'L' value goes on the machine stack and is
	:; then loaded as usual with the next address.
	:;

1A96:B
1A96-1A96 0F	:B
	:;;addition

1A97:B
1A97-1A97 01	:B
	:;;exchange

1A98:B
1A98-1A98 C2	:B
	:;;st-mem-2

1A99:B
1A99-1A99 02	:B
	:;;delete
	:;

1A9A:B
1A9A-1A9A 31	:B
	:;;dec-jr-nz

1A9B:B
1A9B-1A9B EE	:B
	:;;back to L1A89, G-LOOP
	:;

1A9C:B
	:#; when the counted loop is complete the final subtraction yields the result
	:#; for example SIN X.
	:#
1A9C-1A9C E1	:B
	:;;get-mem-1

1A9D:B
1A9D-1A9D 03	:B
	:;;subtract

1A9E:B
1A9E-1A9E 34	:B
	:;;end-calc
	:;

1A9F:C
1A9F C9         ret	:C
	:; return with H'L' pointing to location
	:; after last number in series.
	:;

1AA0:C
	:#; -----------------------
	:#; Handle unary minus (18)
	:#; -----------------------
	:#; Unary so on entry HL points to last value, DE to STKEND.
	:#
	:#;; NEGATE
	:#;; negate
1AA0 7E         ld a, (hl)	:C negate
	:; fetch exponent of last value on the
	:; calculator stack.

1AA1:C
1AA1 A7         and a	:C
	:; test it.

1AA2:C
1AA2 C8         ret z	:C
	:; return if zero.
	:;

1AA3:C
1AA3 23         inc hl	:C
	:; address the byte with the sign bit.

1AA4:C
1AA4 7E         ld a, (hl)	:C
	:; fetch to accumulator.

1AA5:C
1AA5 EE80       xor $80	:C
	:; toggle the sign bit.

1AA7:C
1AA7 77         ld (hl), a	:C
	:; put it back.

1AA8:C
1AA8 2B         dec hl	:C
	:; point to last value again.

1AA9:C
1AA9 C9         ret	:C
	:; return.
	:;

1AAA:C
	:#; -----------------------
	:#; Absolute magnitude (27)
	:#; -----------------------
	:#; This calculator literal finds the absolute value of the last value,
	:#; floating point, on calculator stack.
	:#
	:#;; abs
1AAA 23         inc hl	:C abs
	:; point to byte with sign bit.

1AAB:C
1AAB CBBE       res 7, (hl)	:C
	:; make the sign positive.

1AAD:C
1AAD 2B         dec hl	:C
	:; point to last value again.

1AAE:C
1AAE C9         ret	:C
	:; return.
	:;

1AAF:C
	:#; -----------
	:#; Signum (26)
	:#; -----------
	:#; This routine replaces the last value on the calculator stack,
	:#; which is in floating point form, with one if positive and with -minus one
	:#; if negative. If it is zero then it is left as such.
	:#
	:#;; sgn
1AAF 23         inc hl	:C sgn
	:; point to first byte of 4-byte mantissa.

1AB0:C
1AB0 7E         ld a, (hl)	:C
	:; pick up the byte with the sign bit.

1AB1:C
1AB1 2B         dec hl	:C
	:; point to exponent.

1AB2:C
1AB2 35         dec (hl)	:C
	:; test the exponent for

1AB3:C
1AB3 34         inc (hl)	:C
	:; the value zero.
	:;

1AB4:C
1AB4 37         scf	:C
	:; set the carry flag.

1AB5:C
1AB5 C4E01A     call nz, $1AE0	:C
	:; routine FP-0/1  replaces last value with one
	:; if exponent indicates the value is non-zero.
	:; in either case mantissa is now four zeros.
	:;

1AB8:C
1AB8 23         inc hl	:C
	:; point to first byte of 4-byte mantissa.

1AB9:C
1AB9 07         rlca	:C
	:; rotate original sign bit to carry.

1ABA:C
1ABA CB1E       rr (hl)	:C
	:; rotate the carry into sign.

1ABC:C
1ABC 2B         dec hl	:C
	:; point to last value.

1ABD:C
1ABD C9         ret	:C
	:; return.
	:;
	:;

1ABE:C
	:#; -------------------------
	:#; Handle PEEK function (28)
	:#; -------------------------
	:#; This function returns the contents of a memory address.
	:#; The entire address space can be peeked including the ROM.
	:#
	:#;; peek
1ABE CDA70E     call $0EA7	:C peek
	:; routine FIND-INT puts address in BC.

1AC1:C
1AC1 0A         ld a, (bc)	:C
	:; load contents into A register.
	:;

1AC2:C
	:#;; IN-PK-STK
1AC2 C31D15     jp $151D	:C IN_PK_STK
	:; exit via STACK-A to put value on the
	:; calculator stack.
	:;

1AC5:C
	:#; ---------------
	:#; USR number (29)
	:#; ---------------
	:#; The USR function followed by a number 0-65535 is the method by which
	:#; the ZX81 invokes machine code programs. This function returns the
	:#; contents of the BC register pair.
	:#; Note. that STACK-BC re-initializes the IY register to $4000 if a user-written
	:#; program has altered it.
	:#
	:#;; usr-no
1AC5 CDA70E     call $0EA7	:C usr_no
	:; routine FIND-INT to fetch the
	:; supplied address into BC.
	:;

1AC8:C
1AC8 212015     ld hl, $1520	:C
	:; address: STACK-BC is

1ACB:C
1ACB E5         push hl	:C
	:; pushed onto the machine stack.

1ACC:C
1ACC C5         push bc	:C
	:; then the address of the machine code
	:; routine.
	:;

1ACD:C
1ACD C9         ret	:C
	:; make an indirect jump to the routine
	:; and, hopefully, to STACK-BC also.
	:;
	:;

1ACE:C
	:#; -----------------------
	:#; Greater than zero ($33)
	:#; -----------------------
	:#; Test if the last value on the calculator stack is greater than zero.
	:#; This routine is also called directly from the end-tests of the comparison
	:#; routine.
	:#
	:#;; GREATER-0
	:#;; greater-0
1ACE 7E         ld a, (hl)	:C greater_0
	:; fetch exponent.

1ACF:C
1ACF A7         and a	:C
	:; test it for zero.

1AD0:C
1AD0 C8         ret z	:C
	:; return if so.
	:;
	:;

1AD1:C
1AD1 3EFF       ld a, $FF	:C
	:; prepare XOR mask for sign bit

1AD3:C
1AD3 1807       jr $1ADC	:C
	:; forward to SIGN-TO-C
	:; to put sign in carry
	:; (carry will become set if sign is positive)
	:; and then overwrite location with 1 or 0
	:; as appropriate.
	:;

1AD5:C
	:#; ------------------------
	:#; Handle NOT operator ($2C)
	:#; ------------------------
	:#; This overwrites the last value with 1 if it was zero else with zero
	:#; if it was any other value.
	:#;
	:#; e.g. NOT 0 returns 1, NOT 1 returns 0, NOT -3 returns 0.
	:#;
	:#; The subroutine is also called directly from the end-tests of the comparison
	:#; operator.
	:#
	:#;; NOT
	:#;; not
1AD5 7E         ld a, (hl)	:C not
	:; get exponent byte.

1AD6:C
1AD6 ED44       neg	:C
	:; negate - sets carry if non-zero.

1AD8:C
1AD8 3F         ccf	:C
	:; complement so carry set if zero, else reset.

1AD9:C
1AD9 1805       jr $1AE0	:C
	:; forward to FP-0/1.
	:;

1ADB:C
	:#; -------------------
	:#; Less than zero (32)
	:#; -------------------
	:#; Destructively test if last value on calculator stack is less than zero.
	:#; Bit 7 of second byte will be set if so.
	:#
	:#;; less-0
1ADB AF         xor a	:C less_0
	:; set xor mask to zero
	:; (carry will become set if sign is negative).
	:;

1ADC:C
	:#; transfer sign of mantissa to Carry Flag.
	:#
	:#;; SIGN-TO-C
1ADC 23         inc hl	:C SIGN_TO_C
	:; address 2nd byte.

1ADD:C
1ADD AE         xor (hl)	:C
	:; bit 7 of HL will be set if number is negative.

1ADE:C
1ADE 2B         dec hl	:C
	:; address 1st byte again.

1ADF:C
1ADF 07         rlca	:C
	:; rotate bit 7 of A to carry.
	:;

1AE0:C
	:#; -----------
	:#; Zero or one
	:#; -----------
	:#; This routine places an integer value zero or one at the addressed location
	:#; of calculator stack or MEM area. The value one is written if carry is set on
	:#; entry else zero.
	:#
	:#;; FP-0/1
1AE0 E5         push hl	:C FP_0_1
	:; save pointer to the first byte

1AE1:C
1AE1 0605       ld b, $05	:C
	:; five bytes to do.
	:;

1AE3:C
	:#;; FP-loop
1AE3 3600       ld (hl), $00	:C FP_loop
	:; insert a zero.

1AE5:C
1AE5 23         inc hl	:C
	:;

1AE6:C
1AE6 10FB       djnz $1AE3	:C
	:; repeat.
	:;

1AE8:C
1AE8 E1         pop hl	:C
	:;

1AE9:C
1AE9 D0         ret nc	:C
	:;
	:;

1AEA:C
1AEA 3681       ld (hl), $81	:C
	:; make value 1

1AEC:C
1AEC C9         ret	:C
	:; return.
	:;
	:;

1AED:C
	:#; -----------------------
	:#; Handle OR operator (07)
	:#; -----------------------
	:#; The Boolean OR operator. eg. X OR Y
	:#; The result is zero if both values are zero else a non-zero value.
	:#;
	:#; e.g.    0 OR 0  returns 0.
	:#;        -3 OR 0  returns -3.
	:#;         0 OR -3 returns 1.
	:#;        -3 OR 2  returns 1.
	:#;
	:#; A binary operation.
	:#; On entry HL points to first operand (X) and DE to second operand (Y).
	:#
	:#;; or1
1AED 1A         ld a, (de)	:C or1
	:; fetch exponent of second number

1AEE:C
1AEE A7         and a	:C
	:; test it.

1AEF:C
1AEF C8         ret z	:C
	:; return if zero.
	:;

1AF0:C
1AF0 37         scf	:C
	:; set carry flag

1AF1:C
1AF1 18ED       jr $1AE0	:C
	:; back to FP-0/1 to overwrite the first operand
	:; with the value 1.
	:;
	:;

1AF3:C
	:#; -----------------------------
	:#; Handle number AND number (08)
	:#; -----------------------------
	:#; The Boolean AND operator.
	:#;
	:#; e.g.    -3 AND 2  returns -3.
	:#;         -3 AND 0  returns 0.
	:#;          0 and -2 returns 0.
	:#;          0 and 0  returns 0.
	:#;
	:#; Compare with OR routine above.
	:#
	:#;; no-&-no
1AF3 1A         ld a, (de)	:C no___no
	:; fetch exponent of second number.

1AF4:C
1AF4 A7         and a	:C
	:; test it.

1AF5:C
1AF5 C0         ret nz	:C
	:; return if not zero.
	:;

1AF6:C
1AF6 18E8       jr $1AE0	:C
	:; back to FP-0/1 to overwrite the first operand
	:; with zero for return value.
	:;

1AF8:C
	:#; -----------------------------
	:#; Handle string AND number (10)
	:#; -----------------------------
	:#; e.g. "YOU WIN" AND SCORE>99 will return the string if condition is true
	:#; or the null string if false.
	:#
	:#;; str-&-no
1AF8 1A         ld a, (de)	:C str___no
	:; fetch exponent of second number.

1AF9:C
1AF9 A7         and a	:C
	:; test it.

1AFA:C
1AFA C0         ret nz	:C
	:; return if number was not zero - the string
	:; is the result.
	:;

1AFB:C
	:#; if the number was zero (false) then the null string must be returned by
	:#; altering the length of the string on the calculator stack to zero.
	:#
1AFB D5         push de	:C
	:; save pointer to the now obsolete number
	:; (which will become the new STKEND)
	:;

1AFC:C
1AFC 1B         dec de	:C
	:; point to the 5th byte of string descriptor.

1AFD:C
1AFD AF         xor a	:C
	:; clear the accumulator.

1AFE:C
1AFE 12         ld (de), a	:C
	:; place zero in high byte of length.

1AFF:C
1AFF 1B         dec de	:C
	:; address low byte of length.

1B00:C
1B00 12         ld (de), a	:C
	:; place zero there - now the null string.
	:;

1B01:C
1B01 D1         pop de	:C
	:; restore pointer - new STKEND.

1B02:C
1B02 C9         ret	:C
	:; return.
	:;

1B03:C
	:#; -----------------------------------
	:#; Perform comparison ($09-$0E, $11-$16)
	:#; -----------------------------------
	:#; True binary operations.
	:#;
	:#; A single entry point is used to evaluate six numeric and six string
	:#; comparisons. On entry, the calculator literal is in the B register and
	:#; the two numeric values, or the two string parameters, are on the
	:#; calculator stack.
	:#; The individual bits of the literal are manipulated to group similar
	:#; operations although the SUB 8 instruction does nothing useful and merely
	:#; alters the string test bit.
	:#; Numbers are compared by subtracting one from the other, strings are
	:#; compared by comparing every character until a mismatch, or the end of one
	:#; or both, is reached.
	:#;
	:#; Numeric Comparisons.
	:#; --------------------
	:#; The 'x>y' example is the easiest as it employs straight-thru logic.
	:#; Number y is subtracted from x and the result tested for greater-0 yielding
	:#; a final value 1 (true) or 0 (false).
	:#; For 'x<y' the same logic is used but the two values are first swapped on the
	:#; calculator stack.
	:#; For 'x=y' NOT is applied to the subtraction result yielding true if the
	:#; difference was zero and false with anything else.
	:#; The first three numeric comparisons are just the opposite of the last three
	:#; so the same processing steps are used and then a final NOT is applied.
	:#;
	:#; literal    Test   No  sub 8       ExOrNot  1st RRCA  exch sub  ?   End-Tests
	:#; =========  ====   == ======== === ======== ========  ==== ===  =  === === ===
	:#; no-l-eql   x<=y   09 00000001 dec 00000000 00000000  ---- x-y  ?  --- >0? NOT
	:#; no-gr-eql  x>=y   0A 00000010 dec 00000001 10000000c swap y-x  ?  --- >0? NOT
	:#; nos-neql   x<>y   0B 00000011 dec 00000010 00000001  ---- x-y  ?  NOT --- NOT
	:#; no-grtr    x>y    0C 00000100  -  00000100 00000010  ---- x-y  ?  --- >0? ---
	:#; no-less    x<y    0D 00000101  -  00000101 10000010c swap y-x  ?  --- >0? ---
	:#; nos-eql    x=y    0E 00000110  -  00000110 00000011  ---- x-y  ?  NOT --- ---
	:#;
	:#;                                                           comp -> C/F
	:#;                                                           ====    ===
	:#; str-l-eql  x$<=y$ 11 00001001 dec 00001000 00000100  ---- x$y$ 0  !or >0? NOT
	:#; str-gr-eql x$>=y$ 12 00001010 dec 00001001 10000100c swap y$x$ 0  !or >0? NOT
	:#; strs-neql  x$<>y$ 13 00001011 dec 00001010 00000101  ---- x$y$ 0  !or >0? NOT
	:#; str-grtr   x$>y$  14 00001100  -  00001100 00000110  ---- x$y$ 0  !or >0? ---
	:#; str-less   x$<y$  15 00001101  -  00001101 10000110c swap y$x$ 0  !or >0? ---
	:#; strs-eql   x$=y$  16 00001110  -  00001110 00000111  ---- x$y$ 0  !or >0? ---
	:#;
	:#; String comparisons are a little different in that the eql/neql carry flag
	:#; from the 2nd RRCA is, as before, fed into the first of the end tests but
	:#; along the way it gets modified by the comparison process. The result on the
	:#; stack always starts off as zero and the carry fed in determines if NOT is
	:#; applied to it. So the only time the greater-0 test is applied is if the
	:#; stack holds zero which is not very efficient as the test will always yield
	:#; zero. The most likely explanation is that there were once separate end tests
	:#; for numbers and strings.
	:#
	:#;; no-l-eql,etc.
1B03 78         ld a, b	:C no_l_eql_etc_
	:; transfer literal to accumulator.

1B04:C
1B04 D608       sub $08	:C
	:; subtract eight - which is not useful.
	:;

1B06:C
1B06 CB57       bit 2, a	:C
	:; isolate '>', '<', '='.
	:;

1B08:C
1B08 2001       jr nz, $1B0B	:C
	:; skip to EX-OR-NOT with these.
	:;

1B0A:C
1B0A 3D         dec a	:C
	:; else make $00-$02, $08-$0A to match bits 0-2.
	:;

1B0B:C
	:#;; EX-OR-NOT
1B0B 0F         rrca	:C EX_OR_NOT
	:; the first RRCA sets carry for a swap.

1B0C:C
1B0C 3008       jr nc, $1B16	:C
	:; forward to NU-OR-STR with other 8 cases
	:;

1B0E:C
	:#; for the other 4 cases the two values on the calculator stack are exchanged.
	:#
1B0E F5         push af	:C
	:; save A and carry.

1B0F:C
1B0F E5         push hl	:C
	:; save HL - pointer to first operand.
	:; (DE points to second operand).
	:;

1B10:C
1B10 CD721A     call $1A72	:C
	:; routine exchange swaps the two values.
	:; (HL = second operand, DE = STKEND)
	:;

1B13:C
1B13 D1         pop de	:C
	:; DE = first operand

1B14:C
1B14 EB         ex de, hl	:C
	:; as we were.

1B15:C
1B15 F1         pop af	:C
	:; restore A and carry.
	:;

1B16:C
	:#; Note. it would be better if the 2nd RRCA preceded the string test.
	:#; It would save two duplicate bytes and if we also got rid of that sub 8
	:#; at the beginning we wouldn't have to alter which bit we test.
	:#
	:#;; NU-OR-STR
1B16 CB57       bit 2, a	:C NU_OR_STR
	:; test if a string comparison.

1B18:C
1B18 2007       jr nz, $1B21	:C
	:; forward to STRINGS if so.
	:;

1B1A:C
	:#; continue with numeric comparisons.
	:#
1B1A 0F         rrca	:C
	:; 2nd RRCA causes eql/neql to set carry.

1B1B:C
1B1B F5         push af	:C
	:; save A and carry
	:;

1B1C:C
1B1C CD4C17     call $174C	:C
	:; routine subtract leaves result on stack.

1B1F:C
1B1F 1833       jr $1B54	:C
	:; forward to END-TESTS
	:;

1B21:C
	:#; ---
	:#
	:#;; STRINGS
1B21 0F         rrca	:C STRINGS
	:; 2nd RRCA causes eql/neql to set carry.

1B22:C
1B22 F5         push af	:C
	:; save A and carry.
	:;

1B23:C
1B23 CDF813     call $13F8	:C
	:; routine STK-FETCH gets 2nd string params

1B26:C
1B26 D5         push de	:C
	:; save start2 *.

1B27:C
1B27 C5         push bc	:C
	:; and the length.
	:;

1B28:C
1B28 CDF813     call $13F8	:C
	:; routine STK-FETCH gets 1st string
	:; parameters - start in DE, length in BC.

1B2B:C
1B2B E1         pop hl	:C
	:; restore length of second to HL.
	:;

1B2C:C
	:#; A loop is now entered to compare, by subtraction, each corresponding character
	:#; of the strings. For each successful match, the pointers are incremented and
	:#; the lengths decreased and the branch taken back to here. If both string
	:#; remainders become null at the same time, then an exact match exists.
	:#
	:#;; BYTE-COMP
1B2C 7C         ld a, h	:C BYTE_COMP
	:; test if the second string

1B2D:C
1B2D B5         or l	:C
	:; is the null string and hold flags.
	:;

1B2E:C
1B2E E3         ex (sp), hl	:C
	:; put length2 on stack, bring start2 to HL *.

1B2F:C
1B2F 78         ld a, b	:C
	:; hi byte of length1 to A
	:;

1B30:C
1B30 200B       jr nz, $1B3D	:C
	:; forward to SEC-PLUS if second not null.
	:;

1B32:C
1B32 B1         or c	:C
	:; test length of first string.
	:;

1B33:C
	:#;; SECND-LOW
1B33 C1         pop bc	:C SECND_LOW
	:; pop the second length off stack.

1B34:C
1B34 2804       jr z, $1B3A	:C
	:; forward to BOTH-NULL if first string is also
	:; of zero length.
	:;

1B36:C
	:#; the true condition - first is longer than second (SECND-LESS)
	:#
1B36 F1         pop af	:C
	:; restore carry (set if eql/neql)

1B37:C
1B37 3F         ccf	:C
	:; complement carry flag.
	:; Note. equality becomes false.
	:; Inequality is true. By swapping or applying
	:; a terminal 'not', all comparisons have been
	:; manipulated so that this is success path.

1B38:C
1B38 1816       jr $1B50	:C
	:; forward to leave via STR-TEST
	:;

1B3A:C
	:#; ---
	:#; the branch was here with a match
	:#
	:#;; BOTH-NULL
1B3A F1         pop af	:C BOTH_NULL
	:; restore carry - set for eql/neql

1B3B:C
1B3B 1813       jr $1B50	:C
	:; forward to STR-TEST
	:;

1B3D:C
	:#; ---
	:#; the branch was here when 2nd string not null and low byte of first is yet
	:#; to be tested.
	:#
	:#
	:#;; SEC-PLUS
1B3D B1         or c	:C SEC_PLUS
	:; test the length of first string.

1B3E:C
1B3E 280D       jr z, $1B4D	:C
	:; forward to FRST-LESS if length is zero.
	:;

1B40:C
	:#; both strings have at least one character left.
	:#
1B40 1A         ld a, (de)	:C
	:; fetch character of first string.

1B41:C
1B41 96         sub (hl)	:C
	:; subtract with that of 2nd string.

1B42:C
1B42 3809       jr c, $1B4D	:C
	:; forward to FRST-LESS if carry set
	:;

1B44:C
1B44 20ED       jr nz, $1B33	:C
	:; back to SECND-LOW and then STR-TEST
	:; if not exact match.
	:;

1B46:C
1B46 0B         dec bc	:C
	:; decrease length of 1st string.

1B47:C
1B47 13         inc de	:C
	:; increment 1st string pointer.
	:;

1B48:C
1B48 23         inc hl	:C
	:; increment 2nd string pointer.

1B49:C
1B49 E3         ex (sp), hl	:C
	:; swap with length on stack

1B4A:C
1B4A 2B         dec hl	:C
	:; decrement 2nd string length

1B4B:C
1B4B 18DF       jr $1B2C	:C
	:; back to BYTE-COMP
	:;

1B4D:C
	:#; ---
	:#;   the false condition.
	:#
	:#;; FRST-LESS
1B4D C1         pop bc	:C FRST_LESS
	:; discard length

1B4E:C
1B4E F1         pop af	:C
	:; pop A

1B4F:C
1B4F A7         and a	:C
	:; clear the carry for false result.
	:;

1B50:C
	:#; ---
	:#;   exact match and x$>y$ rejoin here
	:#
	:#;; STR-TEST
1B50 F5         push af	:C STR_TEST
	:; save A and carry
	:;

1B51:C
1B51 EF         rst $28	:C
	:;; FP-CALC

1B52:B
1B52-1B52 A0	:B
	:;;stk-zero      an initial false value.

1B53:B
1B53-1B53 34	:B
	:;;end-calc
	:;

1B54:C
	:#;   both numeric and string paths converge here.
	:#
	:#;; END-TESTS
1B54 F1         pop af	:C END_TESTS
	:; pop carry  - will be set if eql/neql

1B55:C
1B55 F5         push af	:C
	:; save it again.
	:;

1B56:C
1B56 DCD51A     call c, $1AD5	:C
	:; routine NOT sets true(1) if equal(0)
	:; or, for strings, applies true result.

1B59:C
1B59 CDCE1A     call $1ACE	:C
	:; greater-0  ??????????
	:;
	:;

1B5C:C
1B5C F1         pop af	:C
	:; pop A

1B5D:C
1B5D 0F         rrca	:C
	:; the third RRCA - test for '<=', '>=' or '<>'.

1B5E:C
1B5E D4D51A     call nc, $1AD5	:C
	:; apply a terminal NOT if so.

1B61:C
1B61 C9         ret	:C
	:; return.
	:;

1B62:C
	:#; -------------------------
	:#; String concatenation ($17)
	:#; -------------------------
	:#;   This literal combines two strings into one e.g. LET A$ = B$ + C$
	:#;   The two parameters of the two strings to be combined are on the stack.
	:#
	:#;; strs-add
1B62 CDF813     call $13F8	:C strs_add
	:; routine STK-FETCH fetches string parameters
	:; and deletes calculator stack entry.

1B65:C
1B65 D5         push de	:C
	:; save start address.

1B66:C
1B66 C5         push bc	:C
	:; and length.
	:;

1B67:C
1B67 CDF813     call $13F8	:C
	:; routine STK-FETCH for first string

1B6A:C
1B6A E1         pop hl	:C
	:; re-fetch first length

1B6B:C
1B6B E5         push hl	:C
	:; and save again

1B6C:C
1B6C D5         push de	:C
	:; save start of second string

1B6D:C
1B6D C5         push bc	:C
	:; and its length.
	:;

1B6E:C
1B6E 09         add hl, bc	:C
	:; add the two lengths.

1B6F:C
1B6F 44         ld b, h	:C
	:; transfer to BC

1B70:C
1B70 4D         ld c, l	:C
	:; and create

1B71:C
1B71 F7         rst $30	:C
	:; BC-SPACES in workspace.
	:; DE points to start of space.
	:;

1B72:C
1B72 CDC312     call $12C3	:C
	:; routine STK-STO-$ stores parameters
	:; of new string updating STKEND.
	:;

1B75:C
1B75 C1         pop bc	:C
	:; length of first

1B76:C
1B76 E1         pop hl	:C
	:; address of start

1B77:C
1B77 78         ld a, b	:C
	:; test for

1B78:C
1B78 B1         or c	:C
	:; zero length.

1B79:C
1B79 2802       jr z, $1B7D	:C
	:; to OTHER-STR if null string
	:;

1B7B:C
1B7B EDB0       ldir	:C
	:; copy string to workspace.
	:;

1B7D:C
	:#;; OTHER-STR
1B7D C1         pop bc	:C OTHER_STR
	:; now second length

1B7E:C
1B7E E1         pop hl	:C
	:; and start of string

1B7F:C
1B7F 78         ld a, b	:C
	:; test this one

1B80:C
1B80 B1         or c	:C
	:; for zero length

1B81:C
1B81 2802       jr z, $1B85	:C
	:; skip forward to STK-PNTRS if so as complete.
	:;

1B83:C
1B83 EDB0       ldir	:C
	:; else copy the bytes.
	:; and continue into next routine which
	:; sets the calculator stack pointers.
	:;

1B85:C
	:#; --------------------
	:#; Check stack pointers
	:#; --------------------
	:#;   Register DE is set to STKEND and HL, the result pointer, is set to five
	:#;   locations below this.
	:#;   This routine is used when it is inconvenient to save these values at the
	:#;   time the calculator stack is manipulated due to other activity on the
	:#;   machine stack.
	:#;   This routine is also used to terminate the VAL routine for
	:#;   the same reason and to initialize the calculator stack at the start of
	:#;   the CALCULATE routine.
	:#
	:#;; STK-PNTRS
1B85 2A1C40     ld hl, ($401C)	:C STK_PNTRS
	:; fetch STKEND value from system variable.

1B88:C
1B88 11FBFF     ld de, $FFFB	:C
	:; the value -5

1B8B:C
1B8B E5         push hl	:C
	:; push STKEND value.
	:;

1B8C:C
1B8C 19         add hl, de	:C
	:; subtract 5 from HL.
	:;

1B8D:C
1B8D D1         pop de	:C
	:; pop STKEND to DE.

1B8E:C
1B8E C9         ret	:C
	:; return.
	:;

1B8F:C
	:#; ----------------
	:#; Handle CHR$ (2B)
	:#; ----------------
	:#;   This function returns a single character string that is a result of
	:#;   converting a number in the range 0-255 to a string e.g. CHR$ 38 = "A".
	:#;   Note. the ZX81 does not have an ASCII character set.
	:#
	:#;; chrs
1B8F CDCD15     call $15CD	:C chrs
	:; routine FP-TO-A puts the number in A.
	:;

1B92:C
1B92 380E       jr c, $1BA2	:C
	:; forward to REPORT-Bd if overflow

1B94:C
1B94 200C       jr nz, $1BA2	:C
	:; forward to REPORT-Bd if negative
	:;

1B96:C
1B96 F5         push af	:C
	:; save the argument.
	:;

1B97:C
1B97 010100     ld bc, $0001	:C
	:; one space required.

1B9A:C
1B9A F7         rst $30	:C
	:; BC-SPACES makes DE point to start
	:;

1B9B:C
1B9B F1         pop af	:C
	:; restore the number.
	:;

1B9C:C
1B9C 12         ld (de), a	:C
	:; and store in workspace
	:;

1B9D:C
1B9D CDC312     call $12C3	:C
	:; routine STK-STO-$ stacks descriptor.
	:;

1BA0:C
1BA0 EB         ex de, hl	:C
	:; make HL point to result and DE to STKEND.

1BA1:C
1BA1 C9         ret	:C
	:; return.
	:;

1BA2:C
	:#; ---
	:#
	:#;; REPORT-Bd
1BA2 CF         rst $08	:C REPORT_Bd
	:; ERROR-1

1BA3:B
1BA3-1BA3 0A	:B
	:; Error Report: Integer out of range
	:;

1BA4:C
	:#; ----------------------------
	:#; Handle VAL ($1A)
	:#; ----------------------------
	:#;   VAL treats the characters in a string as a numeric expression.
	:#;       e.g. VAL "2.3" = 2.3, VAL "2+4" = 6, VAL ("2" + "4") = 24.
	:#
	:#;; val
1BA4 2A1640     ld hl, ($4016)	:C val
	:; fetch value of system variable CH_ADD

1BA7:C
1BA7 E5         push hl	:C
	:; and save on the machine stack.
	:;

1BA8:C
1BA8 CDF813     call $13F8	:C
	:; routine STK-FETCH fetches the string operand
	:; from calculator stack.
	:;

1BAB:C
1BAB D5         push de	:C
	:; save the address of the start of the string.

1BAC:C
1BAC 03         inc bc	:C
	:; increment the length for a carriage return.
	:;

1BAD:C
1BAD F7         rst $30	:C
	:; BC-SPACES creates the space in workspace.

1BAE:C
1BAE E1         pop hl	:C
	:; restore start of string to HL.

1BAF:C
1BAF ED531640   ld ($4016), de	:C
	:; load CH_ADD with start DE in workspace.
	:;

1BB3:C
1BB3 D5         push de	:C
	:; save the start in workspace

1BB4:C
1BB4 EDB0       ldir	:C
	:; copy string from program or variables or
	:; workspace to the workspace area.

1BB6:C
1BB6 EB         ex de, hl	:C
	:; end of string + 1 to HL

1BB7:C
1BB7 2B         dec hl	:C
	:; decrement HL to point to end of new area.

1BB8:C
1BB8 3676       ld (hl), $76	:C
	:; insert a carriage return at end.
	:; ZX81 has a non-ASCII character set

1BBA:C
1BBA FDCB01BE   res 7, (iy+$01)	:C
	:; update FLAGS  - signal checking syntax.

1BBE:C
1BBE CD920D     call $0D92	:C
	:; routine CLASS-06 - SCANNING evaluates string
	:; expression and checks for integer result.
	:;

1BC1:C
1BC1 CD220D     call $0D22	:C
	:; routine CHECK-2 checks for carriage return.
	:;
	:;

1BC4:C
1BC4 E1         pop hl	:C
	:; restore start of string in workspace.
	:;

1BC5:C
1BC5 221640     ld ($4016), hl	:C
	:; set CH_ADD to the start of the string again.

1BC8:C
1BC8 FDCB01FE   set 7, (iy+$01)	:C
	:; update FLAGS  - signal running program.

1BCC:C
1BCC CD550F     call $0F55	:C
	:; routine SCANNING evaluates the string
	:; in full leaving result on calculator stack.
	:;

1BCF:C
1BCF E1         pop hl	:C
	:; restore saved character address in program.

1BD0:C
1BD0 221640     ld ($4016), hl	:C
	:; and reset the system variable CH_ADD.
	:;

1BD3:C
1BD3 18B0       jr $1B85	:C
	:; back to exit via STK-PNTRS.
	:; resetting the calculator stack pointers
	:; HL and DE from STKEND as it wasn't possible
	:; to preserve them during this routine.
	:;

1BD5:C
	:#; ----------------
	:#; Handle STR$ (2A)
	:#; ----------------
	:#;   This function returns a string representation of a numeric argument.
	:#;   The method used is to trick the PRINT-FP routine into thinking it
	:#;   is writing to a collapsed display file when in fact it is writing to
	:#;   string workspace.
	:#;   If there is already a newline at the intended print position and the
	:#;   column count has not been reduced to zero then the print routine
	:#;   assumes that there is only 1K of RAM and the screen memory, like the rest
	:#;   of dynamic memory, expands as necessary using calls to the ONE-SPACE
	:#;   routine. The screen is character-mapped not bit-mapped.
	:#
	:#;; str$
1BD5 010100     ld bc, $0001	:C str_
	:; create an initial byte in workspace

1BD8:C
1BD8 F7         rst $30	:C
	:; using BC-SPACES restart.
	:;

1BD9:C
1BD9 3676       ld (hl), $76	:C
	:; place a carriage return there.
	:;

1BDB:C
1BDB 2A3940     ld hl, ($4039)	:C
	:; fetch value of S_POSN column/line

1BDE:C
1BDE E5         push hl	:C
	:; and preserve on stack.
	:;

1BDF:C
1BDF 2EFF       ld l, $FF	:C
	:; make column value high to create a
	:; contrived buffer of length 254.

1BE1:C
1BE1 223940     ld ($4039), hl	:C
	:; and store in system variable S_POSN.
	:;

1BE4:C
1BE4 2A0E40     ld hl, ($400E)	:C
	:; fetch value of DF_CC

1BE7:C
1BE7 E5         push hl	:C
	:; and preserve on stack also.
	:;

1BE8:C
1BE8 ED530E40   ld ($400E), de	:C
	:; now set DF_CC which normally addresses
	:; somewhere in the display file to the start
	:; of workspace.

1BEC:C
1BEC D5         push de	:C
	:; save the start of new string.
	:;

1BED:C
1BED CDDB15     call $15DB	:C
	:; routine PRINT-FP.
	:;

1BF0:C
1BF0 D1         pop de	:C
	:; retrieve start of string.
	:;

1BF1:C
1BF1 2A0E40     ld hl, ($400E)	:C
	:; fetch end of string from DF_CC.

1BF4:C
1BF4 A7         and a	:C
	:; prepare for true subtraction.

1BF5:C
1BF5 ED52       sbc hl, de	:C
	:; subtract to give length.
	:;

1BF7:C
1BF7 44         ld b, h	:C
	:; and transfer to the BC

1BF8:C
1BF8 4D         ld c, l	:C
	:; register.
	:;

1BF9:C
1BF9 E1         pop hl	:C
	:; restore original

1BFA:C
1BFA 220E40     ld ($400E), hl	:C
	:; DF_CC value
	:;

1BFD:C
1BFD E1         pop hl	:C
	:; restore original

1BFE:C
1BFE 223940     ld ($4039), hl	:C
	:; S_POSN values.
	:;

1C01:C
1C01 CDC312     call $12C3	:C
	:; routine STK-STO-$ stores the string
	:; descriptor on the calculator stack.
	:;

1C04:C
1C04 EB         ex de, hl	:C
	:; HL = last value, DE = STKEND.

1C05:C
1C05 C9         ret	:C
	:; return.
	:;
	:;

1C06:C
	:#; -------------------
	:#; THE 'CODE' FUNCTION
	:#; -------------------
	:#; (offset $19: 'code')
	:#;   Returns the code of a character or first character of a string
	:#;   e.g. CODE "AARDVARK" = 38  (not 65 as the ZX81 does not have an ASCII
	:#;   character set).
	:#
	:#
	:#;; code
1C06 CDF813     call $13F8	:C code
	:; routine STK-FETCH to fetch and delete the
	:; string parameters.
	:; DE points to the start, BC holds the length.

1C09:C
1C09 78         ld a, b	:C
	:; test length

1C0A:C
1C0A B1         or c	:C
	:; of the string.

1C0B:C
1C0B 2801       jr z, $1C0E	:C
	:; skip to STK-CODE with zero if the null string.
	:;

1C0D:C
1C0D 1A         ld a, (de)	:C
	:; else fetch the first character.
	:;

1C0E:C
	:#;; STK-CODE
1C0E C31D15     jp $151D	:C STK_CODE
	:; jump back to STACK-A (with memory check)
	:;

1C11:C
	:#; --------------------
	:#; THE 'LEN' SUBROUTINE
	:#; --------------------
	:#; (offset $1b: 'len')
	:#;   Returns the length of a string.
	:#;   In Sinclair BASIC strings can be more than twenty thousand characters long
	:#;   so a sixteen-bit register is required to store the length
	:#
	:#;; len
1C11 CDF813     call $13F8	:C len
	:; routine STK-FETCH to fetch and delete the
	:; string parameters from the calculator stack.
	:; register BC now holds the length of string.
	:;

1C14:C
1C14 C32015     jp $1520	:C
	:; jump back to STACK-BC to save result on the
	:; calculator stack (with memory check).
	:;

1C17:C
	:#; -------------------------------------
	:#; THE 'DECREASE THE COUNTER' SUBROUTINE
	:#; -------------------------------------
	:#; (offset $31: 'dec-jr-nz')
	:#;   The calculator has an instruction that decrements a single-byte
	:#;   pseudo-register and makes consequential relative jumps just like
	:#;   the Z80's DJNZ instruction.
	:#
	:#;; dec-jr-nz
1C17 D9         exx	:C dec_jr_nz
	:; switch in set that addresses code
	:;

1C18:C
1C18 E5         push hl	:C
	:; save pointer to offset byte

1C19:C
1C19 211E40     ld hl, $401E	:C
	:; address BREG in system variables

1C1C:C
1C1C 35         dec (hl)	:C
	:; decrement it

1C1D:C
1C1D E1         pop hl	:C
	:; restore pointer
	:;

1C1E:C
1C1E 2004       jr nz, $1C24	:C
	:; to JUMP-2 if not zero
	:;

1C20:C
1C20 23         inc hl	:C
	:; step past the jump length.

1C21:C
1C21 D9         exx	:C
	:; switch in the main set.

1C22:C
1C22 C9         ret	:C
	:; return.
	:;

1C23:C
	:#;   Note. as a general rule the calculator avoids using the IY register
	:#;   otherwise the cumbersome 4 instructions in the middle could be replaced by
	:#;   dec (iy+$xx) - using three instruction bytes instead of six.
	:#
	:#
	:#; ---------------------
	:#; THE 'JUMP' SUBROUTINE
	:#; ---------------------
	:#; (Offset $2F; 'jump')
	:#;   This enables the calculator to perform relative jumps just like
	:#;   the Z80 chip's JR instruction.
	:#;   This is one of the few routines to be polished for the ZX Spectrum.
	:#;   See, without looking at the ZX Spectrum ROM, if you can get rid of the
	:#;   relative jump.
	:#
	:#;; jump
	:#;; JUMP
1C23 D9         exx	:C JUMP
	:;switch in pointer set
	:;

1C24:C
	:#;; JUMP-2
1C24 5E         ld e, (hl)	:C JUMP_2
	:; the jump byte 0-127 forward, 128-255 back.

1C25:C
1C25 AF         xor a	:C
	:; clear accumulator.

1C26:C
1C26 CB7B       bit 7, e	:C
	:; test if negative jump

1C28:C
1C28 2801       jr z, $1C2B	:C
	:; skip, if positive, to JUMP-3.
	:;

1C2A:C
1C2A 2F         cpl	:C
	:; else change to $FF.
	:;

1C2B:C
	:#;; JUMP-3
1C2B 57         ld d, a	:C JUMP_3
	:; transfer to high byte.

1C2C:C
1C2C 19         add hl, de	:C
	:; advance calculator pointer forward or back.
	:;

1C2D:C
1C2D D9         exx	:C
	:; switch out pointer set.

1C2E:C
1C2E C9         ret	:C
	:; return.
	:;

1C2F:C
	:#; -----------------------------
	:#; THE 'JUMP ON TRUE' SUBROUTINE
	:#; -----------------------------
	:#; (Offset $00; 'jump-true')
	:#;   This enables the calculator to perform conditional relative jumps
	:#;   dependent on whether the last test gave a true result
	:#;   On the ZX81, the exponent will be zero for zero or else $81 for one.
	:#
	:#;; jump-true
1C2F 1A         ld a, (de)	:C jump_true
	:; collect exponent byte
	:;

1C30:C
1C30 A7         and a	:C
	:; is result 0 or 1 ?

1C31:C
1C31 20F0       jr nz, $1C23	:C
	:; back to JUMP if true (1).
	:;

1C33:C
1C33 D9         exx	:C
	:; else switch in the pointer set.

1C34:C
1C34 23         inc hl	:C
	:; step past the jump length.

1C35:C
1C35 D9         exx	:C
	:; switch in the main set.

1C36:C
1C36 C9         ret	:C
	:; return.
	:;
	:;

1C37:C
	:#; ------------------------
	:#; THE 'MODULUS' SUBROUTINE
	:#; ------------------------
	:#; ( Offset $2E: 'n-mod-m' )
	:#; ( i1, i2 -- i3, i4 )
	:#;   The subroutine calculate N mod M where M is the positive integer, the
	:#;   'last value' on the calculator stack and N is the integer beneath.
	:#;   The subroutine returns the integer quotient as the last value and the
	:#;   remainder as the value beneath.
	:#;   e.g.    17 MOD 3 = 5 remainder 2
	:#;   It is invoked during the calculation of a random number and also by
	:#;   the PRINT-FP routine.
	:#
	:#;; n-mod-m
1C37 EF         rst $28	:C n_mod_m
	:;; FP-CALC          17, 3.

1C38:B
1C38-1C38 C0	:B
	:;;st-mem-0          17, 3.

1C39:B
1C39-1C39 02	:B
	:;;delete            17.

1C3A:B
1C3A-1C3A 2D	:B
	:;;duplicate         17, 17.

1C3B:B
1C3B-1C3B E0	:B
	:;;get-mem-0         17, 17, 3.

1C3C:B
1C3C-1C3C 05	:B
	:;;division          17, 17/3.

1C3D:B
1C3D-1C3D 24	:B
	:;;int               17, 5.

1C3E:B
1C3E-1C3E E0	:B
	:;;get-mem-0         17, 5, 3.

1C3F:B
1C3F-1C3F 01	:B
	:;;exchange          17, 3, 5.

1C40:B
1C40-1C40 C0	:B
	:;;st-mem-0          17, 3, 5.

1C41:B
1C41-1C41 04	:B
	:;;multiply          17, 15.

1C42:B
1C42-1C42 03	:B
	:;;subtract          2.

1C43:B
1C43-1C43 E0	:B
	:;;get-mem-0         2, 5.

1C44:B
1C44-1C44 34	:B
	:;;end-calc          2, 5.
	:;

1C45:C
1C45 C9         ret	:C
	:; return.
	:;
	:;

1C46:C
	:#; ----------------------
	:#; THE 'INTEGER' FUNCTION
	:#; ----------------------
	:#; (offset $24: 'int')
	:#;   This function returns the integer of x, which is just the same as truncate
	:#;   for positive numbers. The truncate literal truncates negative numbers
	:#;   upwards so that -3.4 gives -3 whereas the BASIC INT function has to
	:#;   truncate negative numbers down so that INT -3.4 is 4.
	:#;   It is best to work through using, say, plus or minus 3.4 as examples.
	:#
	:#;; int
1C46 EF         rst $28	:C int
	:;; FP-CALC              x.    (= 3.4 or -3.4).

1C47:B
1C47-1C47 2D	:B
	:;;duplicate             x, x.

1C48:B
1C48-1C48 32	:B
	:;;less-0                x, (1/0)

1C49:B
1C49-1C49 00	:B
	:;;jump-true             x, (1/0)

1C4A:B
1C4A-1C4A 04	:B
	:;;to L1C46, X-NEG
	:;

1C4B:B
1C4B-1C4B 36	:B
	:;;truncate              trunc 3.4 = 3.

1C4C:B
1C4C-1C4C 34	:B
	:;;end-calc              3.
	:;

1C4D:C
1C4D C9         ret	:C
	:; return with + int x on stack.
	:;
	:;

1C4E:B
	:#;; X-NEG
1C4E-1C4E 2D	:B X_NEG
	:;;duplicate             -3.4, -3.4.

1C4F:B
1C4F-1C4F 36	:B
	:;;truncate              -3.4, -3.

1C50:B
1C50-1C50 C0	:B
	:;;st-mem-0              -3.4, -3.

1C51:B
1C51-1C51 03	:B
	:;;subtract              -.4

1C52:B
1C52-1C52 E0	:B
	:;;get-mem-0             -.4, -3.

1C53:B
1C53-1C53 01	:B
	:;;exchange              -3, -.4.

1C54:B
1C54-1C54 2C	:B
	:;;not                   -3, (0).

1C55:B
1C55-1C55 00	:B
	:;;jump-true             -3.

1C56:B
1C56-1C56 03	:B
	:;;to L1C59, EXIT        -3.
	:;

1C57:B
1C57-1C57 A1	:B
	:;;stk-one               -3, 1.

1C58:B
1C58-1C58 03	:B
	:;;subtract              -4.
	:;

1C59:B
	:#;; EXIT
1C59-1C59 34	:B EXIT
	:;;end-calc              -4.
	:;

1C5A:C
1C5A C9         ret	:C
	:; return.
	:;
	:;

1C5B:C
	:#; ----------------
	:#; Exponential (23)
	:#; ----------------
	:#;
	:#;
	:#
	:#;; EXP
	:#;; exp
1C5B EF         rst $28	:C exp
	:;; FP-CALC

1C5C:B
1C5C-1C5C 30	:B
	:;;stk-data

1C5D:B
1C5D-1C5D F1	:B
	:;;Exponent: $81, Bytes: 4

1C5E:B
1C5E-1C61 38AA3B29	:B
	:;;

1C62:B
1C62-1C62 04	:B
	:;;multiply

1C63:B
1C63-1C63 2D	:B
	:;;duplicate

1C64:B
1C64-1C64 24	:B
	:;;int

1C65:B
1C65-1C65 C3	:B
	:;;st-mem-3

1C66:B
1C66-1C66 03	:B
	:;;subtract

1C67:B
1C67-1C67 2D	:B
	:;;duplicate

1C68:B
1C68-1C68 0F	:B
	:;;addition

1C69:B
1C69-1C69 A1	:B
	:;;stk-one

1C6A:B
1C6A-1C6A 03	:B
	:;;subtract

1C6B:B
1C6B-1C6B 88	:B
	:;;series-08

1C6C:B
1C6C-1C6C 13	:B
	:;;Exponent: $63, Bytes: 1

1C6D:B
1C6D-1C6D 36	:B
	:;;(+00,+00,+00)

1C6E:B
1C6E-1C6E 58	:B
	:;;Exponent: $68, Bytes: 2

1C6F:B
1C6F-1C70 6566	:B
	:;;(+00,+00)

1C71:B
1C71-1C71 9D	:B
	:;;Exponent: $6D, Bytes: 3

1C72:B
1C72-1C74 786540	:B
	:;;(+00)

1C75:B
1C75-1C75 A2	:B
	:;;Exponent: $72, Bytes: 3

1C76:B
1C76-1C78 6032C9	:B
	:;;(+00)

1C79:B
1C79-1C79 E7	:B
	:;;Exponent: $77, Bytes: 4

1C7A:B
1C7A-1C7D 21F7AF24	:B
	:;;

1C7E:B
1C7E-1C7E EB	:B
	:;;Exponent: $7B, Bytes: 4

1C7F:B
1C7F-1C82 2FB0B014	:B
	:;;

1C83:B
1C83-1C83 EE	:B
	:;;Exponent: $7E, Bytes: 4

1C84:B
1C84-1C87 7EBB9458	:B
	:;;

1C88:B
1C88-1C88 F1	:B
	:;;Exponent: $81, Bytes: 4

1C89:B
1C89-1C8C 3A7EF8CF	:B
	:;;

1C8D:B
1C8D-1C8D E3	:B
	:;;get-mem-3

1C8E:B
1C8E-1C8E 34	:B
	:;;end-calc
	:;

1C8F:C
1C8F CDCD15     call $15CD	:C
	:; routine FP-TO-A

1C92:C
1C92 2007       jr nz, $1C9B	:C
	:; to N-NEGTV
	:;

1C94:C
1C94 3803       jr c, $1C99	:C
	:; to REPORT-6b
	:;

1C96:C
1C96 86         add a, (hl)	:C
	:;

1C97:C
1C97 3009       jr nc, $1CA2	:C
	:; to RESULT-OK
	:;
	:;

1C99:C
	:#;; REPORT-6b
1C99 CF         rst $08	:C REPORT_6b
	:; ERROR-1

1C9A:B
1C9A-1C9A 05	:B
	:; Error Report: Number too big
	:;

1C9B:C
	:#;; N-NEGTV
1C9B 3807       jr c, $1CA4	:C N_NEGTV
	:; to RSLT-ZERO
	:;

1C9D:C
1C9D 96         sub (hl)	:C
	:;

1C9E:C
1C9E 3004       jr nc, $1CA4	:C
	:; to RSLT-ZERO
	:;

1CA0:C
1CA0 ED44       neg	:C
	:; Negate
	:;

1CA2:C
	:#;; RESULT-OK
1CA2 77         ld (hl), a	:C RESULT_OK
	:;

1CA3:C
1CA3 C9         ret	:C
	:; return.
	:;
	:;

1CA4:C
	:#;; RSLT-ZERO
1CA4 EF         rst $28	:C RSLT_ZERO
	:;; FP-CALC

1CA5:B
1CA5-1CA5 02	:B
	:;;delete

1CA6:B
1CA6-1CA6 A0	:B
	:;;stk-zero

1CA7:B
1CA7-1CA7 34	:B
	:;;end-calc
	:;

1CA8:C
1CA8 C9         ret	:C
	:; return.
	:;
	:;

1CA9:C
	:#; --------------------------------
	:#; THE 'NATURAL LOGARITHM' FUNCTION
	:#; --------------------------------
	:#; (offset $22: 'ln')
	:#;   Like the ZX81 itself, 'natural' logarithms came from Scotland.
	:#;   They were devised in 1614 by well-traveled Scotsman John Napier who noted
	:#;   "Nothing doth more molest and hinder calculators than the multiplications,
	:#;    divisions, square and cubical extractions of great numbers".
	:#;
	:#;   Napier's logarithms enabled the above operations to be accomplished by 
	:#;   simple addition and subtraction simplifying the navigational and 
	:#;   astronomical calculations which beset his age.
	:#;   Napier's logarithms were quickly overtaken by logarithms to the base 10
	:#;   devised, in conjunction with Napier, by Henry Briggs a Cambridge-educated 
	:#;   professor of Geometry at Oxford University. These simplified the layout
	:#;   of the tables enabling humans to easily scale calculations.
	:#;
	:#;   It is only recently with the introduction of pocket calculators and
	:#;   computers like the ZX81 that natural logarithms are once more at the fore,
	:#;   although some computers retain logarithms to the base ten.
	:#;   'Natural' logarithms are powers to the base 'e', which like 'pi' is a 
	:#;   naturally occurring number in branches of mathematics.
	:#;   Like 'pi' also, 'e' is an irrational number and starts 2.718281828...
	:#;
	:#;   The tabular use of logarithms was that to multiply two numbers one looked
	:#;   up their two logarithms in the tables, added them together and then looked 
	:#;   for the result in a table of antilogarithms to give the desired product.
	:#;
	:#;   The EXP function is the BASIC equivalent of a calculator's 'antiln' function 
	:#;   and by picking any two numbers, 1.72 and 6.89 say,
	:#;     10 PRINT EXP ( LN 1.72 + LN 6.89 ) 
	:#;   will give just the same result as
	:#;     20 PRINT 1.72 * 6.89.
	:#;   Division is accomplished by subtracting the two logs.
	:#;
	:#;   Napier also mentioned "square and cubicle extractions". 
	:#;   To raise a number to the power 3, find its 'ln', multiply by 3 and find the 
	:#;   'antiln'.  e.g. PRINT EXP( LN 4 * 3 )  gives 64.
	:#;   Similarly to find the n'th root divide the logarithm by 'n'.
	:#;   The ZX81 ROM used PRINT EXP ( LN 9 / 2 ) to find the square root of the 
	:#;   number 9. The Napieran square root function is just a special case of 
	:#;   the 'to_power' function. A cube root or indeed any root/power would be just
	:#;   as simple.
	:#
	:#;   First test that the argument to LN is a positive, non-zero number.
	:#
	:#;; ln
1CA9 EF         rst $28	:C ln
	:;; FP-CALC

1CAA:B
1CAA-1CAA 2D	:B
	:;;duplicate

1CAB:B
1CAB-1CAB 33	:B
	:;;greater-0

1CAC:B
1CAC-1CAC 00	:B
	:;;jump-true

1CAD:B
1CAD-1CAD 04	:B
	:;;to L1CB1, VALID
	:;

1CAE:B
1CAE-1CAE 34	:B
	:;;end-calc
	:;
	:;

1CAF:C
	:#;; REPORT-Ab
1CAF CF         rst $08	:C REPORT_Ab
	:; ERROR-1

1CB0:B
1CB0-1CB0 09	:B
	:; Error Report: Invalid argument
	:;

1CB1:B
	:#;; VALID
1CB1-1CB1 A0	:B VALID
	:;;stk-zero              Note. not 

1CB2:B
1CB2-1CB2 02	:B
	:;;delete                necessary.

1CB3:B
1CB3-1CB3 34	:B
	:;;end-calc

1CB4:C
1CB4 7E         ld a, (hl)	:C
	:;
	:;

1CB5:C
1CB5 3680       ld (hl), $80	:C
	:;

1CB7:C
1CB7 CD1D15     call $151D	:C
	:; routine STACK-A
	:;

1CBA:C
1CBA EF         rst $28	:C
	:;; FP-CALC

1CBB:B
1CBB-1CBB 30	:B
	:;;stk-data

1CBC:B
1CBC-1CBC 38	:B
	:;;Exponent: $88, Bytes: 1

1CBD:B
1CBD-1CBD 00	:B
	:;;(+00,+00,+00)

1CBE:B
1CBE-1CBE 03	:B
	:;;subtract

1CBF:B
1CBF-1CBF 01	:B
	:;;exchange

1CC0:B
1CC0-1CC0 2D	:B
	:;;duplicate

1CC1:B
1CC1-1CC1 30	:B
	:;;stk-data

1CC2:B
1CC2-1CC2 F0	:B
	:;;Exponent: $80, Bytes: 4

1CC3:B
1CC3-1CC6 4CCCCCCD	:B
	:;;

1CC7:B
1CC7-1CC7 03	:B
	:;;subtract

1CC8:B
1CC8-1CC8 33	:B
	:;;greater-0

1CC9:B
1CC9-1CC9 00	:B
	:;;jump-true

1CCA:B
1CCA-1CCA 08	:B
	:;;to L1CD2, GRE.8
	:;

1CCB:B
1CCB-1CCB 01	:B
	:;;exchange

1CCC:B
1CCC-1CCC A1	:B
	:;;stk-one

1CCD:B
1CCD-1CCD 03	:B
	:;;subtract

1CCE:B
1CCE-1CCE 01	:B
	:;;exchange

1CCF:B
1CCF-1CCF 34	:B
	:;;end-calc
	:;

1CD0:C
1CD0 34         inc (hl)	:C
	:;
	:;

1CD1:C
1CD1 EF         rst $28	:C
	:;; FP-CALC
	:;

1CD2:B
	:#;; GRE.8
1CD2-1CD2 01	:B GRE_8
	:;;exchange

1CD3:B
1CD3-1CD3 30	:B
	:;;stk-data

1CD4:B
1CD4-1CD4 F0	:B
	:;;Exponent: $80, Bytes: 4

1CD5:B
1CD5-1CD8 317217F8	:B
	:;;

1CD9:B
1CD9-1CD9 04	:B
	:;;multiply

1CDA:B
1CDA-1CDA 01	:B
	:;;exchange

1CDB:B
1CDB-1CDB A2	:B
	:;;stk-half

1CDC:B
1CDC-1CDC 03	:B
	:;;subtract

1CDD:B
1CDD-1CDD A2	:B
	:;;stk-half

1CDE:B
1CDE-1CDE 03	:B
	:;;subtract

1CDF:B
1CDF-1CDF 2D	:B
	:;;duplicate

1CE0:B
1CE0-1CE0 30	:B
	:;;stk-data

1CE1:B
1CE1-1CE1 32	:B
	:;;Exponent: $82, Bytes: 1

1CE2:B
1CE2-1CE2 20	:B
	:;;(+00,+00,+00)

1CE3:B
1CE3-1CE3 04	:B
	:;;multiply

1CE4:B
1CE4-1CE4 A2	:B
	:;;stk-half

1CE5:B
1CE5-1CE5 03	:B
	:;;subtract

1CE6:B
1CE6-1CE6 8C	:B
	:;;series-0C

1CE7:B
1CE7-1CE7 11	:B
	:;;Exponent: $61, Bytes: 1

1CE8:B
1CE8-1CE8 AC	:B
	:;;(+00,+00,+00)

1CE9:B
1CE9-1CE9 14	:B
	:;;Exponent: $64, Bytes: 1

1CEA:B
1CEA-1CEA 09	:B
	:;;(+00,+00,+00)

1CEB:B
1CEB-1CEB 56	:B
	:;;Exponent: $66, Bytes: 2

1CEC:B
1CEC-1CED DAA5	:B
	:;;(+00,+00)

1CEE:B
1CEE-1CEE 59	:B
	:;;Exponent: $69, Bytes: 2

1CEF:B
1CEF-1CF0 30C5	:B
	:;;(+00,+00)

1CF1:B
1CF1-1CF1 5C	:B
	:;;Exponent: $6C, Bytes: 2

1CF2:B
1CF2-1CF3 90AA	:B
	:;;(+00,+00)

1CF4:B
1CF4-1CF4 9E	:B
	:;;Exponent: $6E, Bytes: 3

1CF5:B
1CF5-1CF7 706F61	:B
	:;;(+00)

1CF8:B
1CF8-1CF8 A1	:B
	:;;Exponent: $71, Bytes: 3

1CF9:B
1CF9-1CFB CBDA96	:B
	:;;(+00)

1CFC:B
1CFC-1CFC A4	:B
	:;;Exponent: $74, Bytes: 3

1CFD:B
1CFD-1CFF 319FB4	:B
	:;;(+00)

1D00:B
1D00-1D00 E7	:B
	:;;Exponent: $77, Bytes: 4

1D01:B
1D01-1D04 A0FE5CFC	:B
	:;;

1D05:B
1D05-1D05 EA	:B
	:;;Exponent: $7A, Bytes: 4

1D06:B
1D06-1D09 1B43CA36	:B
	:;;

1D0A:B
1D0A-1D0A ED	:B
	:;;Exponent: $7D, Bytes: 4

1D0B:B
1D0B-1D0E A79C7E5E	:B
	:;;

1D0F:B
1D0F-1D0F F0	:B
	:;;Exponent: $80, Bytes: 4

1D10:B
1D10-1D13 6E238093	:B
	:;;

1D14:B
1D14-1D14 04	:B
	:;;multiply

1D15:B
1D15-1D15 0F	:B
	:;;addition

1D16:B
1D16-1D16 34	:B
	:;;end-calc
	:;

1D17:C
1D17 C9         ret	:C
	:; return.
	:;

1D18:C
	:#; -----------------------------
	:#; THE 'TRIGONOMETRIC' FUNCTIONS
	:#; -----------------------------
	:#;   Trigonometry is rocket science. It is also used by carpenters and pyramid
	:#;   builders. 
	:#;   Some uses can be quite abstract but the principles can be seen in simple
	:#;   right-angled triangles. Triangles have some special properties -
	:#;
	:#;   1) The sum of the three angles is always PI radians (180 degrees).
	:#;      Very helpful if you know two angles and wish to find the third.
	:#;   2) In any right-angled triangle the sum of the squares of the two shorter
	:#;      sides is equal to the square of the longest side opposite the right-angle.
	:#;      Very useful if you know the length of two sides and wish to know the
	:#;      length of the third side.
	:#;   3) Functions sine, cosine and tangent enable one to calculate the length 
	:#;      of an unknown side when the length of one other side and an angle is 
	:#;      known.
	:#;   4) Functions arcsin, arccosine and arctan enable one to calculate an unknown
	:#;      angle when the length of two of the sides is known.
	:#
	:#; --------------------------------
	:#; THE 'REDUCE ARGUMENT' SUBROUTINE
	:#; --------------------------------
	:#; (offset $35: 'get-argt')
	:#;
	:#;   This routine performs two functions on the angle, in radians, that forms
	:#;   the argument to the sine and cosine functions.
	:#;   First it ensures that the angle 'wraps round'. That if a ship turns through 
	:#;   an angle of, say, 3*PI radians (540 degrees) then the net effect is to turn 
	:#;   through an angle of PI radians (180 degrees).
	:#;   Secondly it converts the angle in radians to a fraction of a right angle,
	:#;   depending within which quadrant the angle lies, with the periodicity 
	:#;   resembling that of the desired sine value.
	:#;   The result lies in the range -1 to +1.              
	:#;
	:#;                       90 deg.
	:#; 
	:#;                       (pi/2)
	:#;                II       +1        I
	:#;                         |
	:#;          sin+      |\   |   /|    sin+
	:#;          cos-      | \  |  / |    cos+
	:#;          tan-      |  \ | /  |    tan+
	:#;                    |   \|/)  |           
	:#;   180 deg. (pi) 0 -|----+----|-- 0  (0)   0 degrees
	:#;                    |   /|\   |
	:#;          sin-      |  / | \  |    sin-
	:#;          cos-      | /  |  \ |    cos+
	:#;          tan+      |/   |   \|    tan-
	:#;                         |
	:#;                III      -1       IV
	:#;                       (3pi/2)
	:#;
	:#;                       270 deg.
	:#
	:#
	:#;; get-argt
1D18 EF         rst $28	:C get_argt
	:;; FP-CALC         X.

1D19:B
1D19-1D19 30	:B
	:;;stk-data

1D1A:B
1D1A-1D1A EE	:B
	:;;Exponent: $7E, 
	:;;Bytes: 4

1D1B:B
1D1B-1D1E 22F9836E	:B
	:;;                 X, 1/(2*PI)             

1D1F:B
1D1F-1D1F 04	:B
	:;;multiply         X/(2*PI) = fraction
	:;

1D20:B
1D20-1D20 2D	:B
	:;;duplicate             

1D21:B
1D21-1D21 A2	:B
	:;;stk-half

1D22:B
1D22-1D22 0F	:B
	:;;addition

1D23:B
1D23-1D23 24	:B
	:;;int
	:;

1D24:B
1D24-1D24 03	:B
	:;;subtract         now range -.5 to .5
	:;

1D25:B
1D25-1D25 2D	:B
	:;;duplicate

1D26:B
1D26-1D26 0F	:B
	:;;addition         now range -1 to 1.

1D27:B
1D27-1D27 2D	:B
	:;;duplicate

1D28:B
1D28-1D28 0F	:B
	:;;addition         now range -2 to 2.
	:;

1D29:B
	:#;   quadrant I (0 to +1) and quadrant IV (-1 to 0) are now correct.
	:#;   quadrant II ranges +1 to +2.
	:#;   quadrant III ranges -2 to -1.
	:#
1D29-1D29 2D	:B
	:;;duplicate        Y, Y.

1D2A:B
1D2A-1D2A 27	:B
	:;;abs              Y, abs(Y).    range 1 to 2

1D2B:B
1D2B-1D2B A1	:B
	:;;stk-one          Y, abs(Y), 1.

1D2C:B
1D2C-1D2C 03	:B
	:;;subtract         Y, abs(Y)-1.  range 0 to 1

1D2D:B
1D2D-1D2D 2D	:B
	:;;duplicate        Y, Z, Z.

1D2E:B
1D2E-1D2E 33	:B
	:;;greater-0        Y, Z, (1/0).
	:;

1D2F:B
1D2F-1D2F C0	:B
	:;;st-mem-0         store as possible sign 
	:;;                 for cosine function.
	:;

1D30:B
1D30-1D30 00	:B
	:;;jump-true

1D31:B
1D31-1D31 04	:B
	:;;to L1D35, ZPLUS  with quadrants II and III
	:;

1D32:B
	:#;   else the angle lies in quadrant I or IV and value Y is already correct.
	:#
1D32-1D32 02	:B
	:;;delete          Y    delete test value.

1D33:B
1D33-1D33 34	:B
	:;;end-calc        Y.
	:;

1D34:C
1D34 C9         ret	:C
	:; return.         with Q1 and Q4 >>>
	:;

1D35:B
	:#;   The branch was here with quadrants II (0 to 1) and III (1 to 0).
	:#;   Y will hold -2 to -1 if this is quadrant III.
	:#
	:#;; ZPLUS
1D35-1D35 A1	:B ZPLUS
	:;;stk-one         Y, Z, 1

1D36:B
1D36-1D36 03	:B
	:;;subtract        Y, Z-1.       Q3 = 0 to -1

1D37:B
1D37-1D37 01	:B
	:;;exchange        Z-1, Y.

1D38:B
1D38-1D38 32	:B
	:;;less-0          Z-1, (1/0).

1D39:B
1D39-1D39 00	:B
	:;;jump-true       Z-1.

1D3A:B
1D3A-1D3A 02	:B
	:;;to L1D3C, YNEG
	:;;if angle in quadrant III
	:;

1D3B:B
	:#;   else angle is within quadrant II (-1 to 0)
	:#
1D3B-1D3B 18	:B
	:;;negate          range +1 to 0
	:;
	:;

1D3C:B
	:#;; YNEG
1D3C-1D3C 34	:B YNEG
	:;;end-calc        quadrants II and III correct.
	:;

1D3D:C
1D3D C9         ret	:C
	:; return.
	:;
	:;

1D3E:C
	:#; ---------------------
	:#; THE 'COSINE' FUNCTION
	:#; ---------------------
	:#; (offset $1D: 'cos')
	:#;   Cosines are calculated as the sine of the opposite angle rectifying the 
	:#;   sign depending on the quadrant rules. 
	:#;
	:#;
	:#;             /|
	:#;          h /y|
	:#;           /  |o
	:#;          /x  |
	:#;         /----|    
	:#;           a
	:#;
	:#;   The cosine of angle x is the adjacent side (a) divided by the hypotenuse 1.
	:#;   However if we examine angle y then a/h is the sine of that angle.
	:#;   Since angle x plus angle y equals a right-angle, we can find angle y by 
	:#;   subtracting angle x from pi/2.
	:#;   However it's just as easy to reduce the argument first and subtract the
	:#;   reduced argument from the value 1 (a reduced right-angle).
	:#;   It's even easier to subtract 1 from the angle and rectify the sign.
	:#;   In fact, after reducing the argument, the absolute value of the argument
	:#;   is used and rectified using the test result stored in mem-0 by 'get-argt'
	:#;   for that purpose.
	:#
	:#;; cos
1D3E EF         rst $28	:C cos
	:;; FP-CALC              angle in radians.

1D3F:B
1D3F-1D3F 35	:B
	:;;get-argt              X       reduce -1 to +1
	:;

1D40:B
1D40-1D40 27	:B
	:;;abs                   ABS X   0 to 1

1D41:B
1D41-1D41 A1	:B
	:;;stk-one               ABS X, 1.

1D42:B
1D42-1D42 03	:B
	:;;subtract              now opposite angle 
	:;;                      though negative sign.

1D43:B
1D43-1D43 E0	:B
	:;;get-mem-0             fetch sign indicator.

1D44:B
1D44-1D44 00	:B
	:;;jump-true

1D45:B
1D45-1D45 06	:B
	:;;fwd to L1D4B, C-ENT
	:;;forward to common code if in QII or QIII 
	:;
	:;

1D46:B
1D46-1D46 18	:B
	:;;negate                else make positive.

1D47:B
1D47-1D47 2F	:B
	:;;jump

1D48:B
1D48-1D48 03	:B
	:;;fwd to L1D4B, C-ENT
	:;;with quadrants QI and QIV 
	:;

1D49:C
	:#; -------------------
	:#; THE 'SINE' FUNCTION
	:#; -------------------
	:#; (offset $1C: 'sin')
	:#;   This is a fundamental transcendental function from which others such as cos
	:#;   and tan are directly, or indirectly, derived.
	:#;   It uses the series generator to produce Chebyshev polynomials.
	:#;
	:#;
	:#;             /|
	:#;          1 / |
	:#;           /  |x
	:#;          /a  |
	:#;         /----|    
	:#;           y
	:#;
	:#;   The 'get-argt' function is designed to modify the angle and its sign 
	:#;   in line with the desired sine value and afterwards it can launch straight
	:#;   into common code.
	:#
	:#;; sin
1D49 EF         rst $28	:C sin
	:;; FP-CALC      angle in radians

1D4A:B
1D4A-1D4A 35	:B
	:;;get-argt      reduce - sign now correct.
	:;

1D4B:B
	:#;; C-ENT
1D4B-1D4B 2D	:B C_ENT
	:;;duplicate

1D4C:B
1D4C-1D4C 2D	:B
	:;;duplicate

1D4D:B
1D4D-1D4D 04	:B
	:;;multiply

1D4E:B
1D4E-1D4E 2D	:B
	:;;duplicate

1D4F:B
1D4F-1D4F 0F	:B
	:;;addition

1D50:B
1D50-1D50 A1	:B
	:;;stk-one

1D51:B
1D51-1D51 03	:B
	:;;subtract
	:;

1D52:B
1D52-1D52 86	:B
	:;;series-06

1D53:B
1D53-1D53 14	:B
	:;;Exponent: $64, Bytes: 1

1D54:B
1D54-1D54 E6	:B
	:;;(+00,+00,+00)

1D55:B
1D55-1D55 5C	:B
	:;;Exponent: $6C, Bytes: 2

1D56:B
1D56-1D57 1F0B	:B
	:;;(+00,+00)

1D58:B
1D58-1D58 A3	:B
	:;;Exponent: $73, Bytes: 3

1D59:B
1D59-1D5B 8F38EE	:B
	:;;(+00)

1D5C:B
1D5C-1D5C E9	:B
	:;;Exponent: $79, Bytes: 4

1D5D:B
1D5D-1D60 1563BB23	:B
	:;;

1D61:B
1D61-1D61 EE	:B
	:;;Exponent: $7E, Bytes: 4

1D62:B
1D62-1D65 920DCDED	:B
	:;;

1D66:B
1D66-1D66 F1	:B
	:;;Exponent: $81, Bytes: 4

1D67:B
1D67-1D6A 235D1BEA	:B
	:;;
	:;

1D6B:B
1D6B-1D6B 04	:B
	:;;multiply

1D6C:B
1D6C-1D6C 34	:B
	:;;end-calc
	:;

1D6D:C
1D6D C9         ret	:C
	:; return.
	:;
	:;

1D6E:C
	:#; ----------------------
	:#; THE 'TANGENT' FUNCTION
	:#; ----------------------
	:#; (offset $1E: 'tan')
	:#;
	:#;   Evaluates tangent x as    sin(x) / cos(x).
	:#;
	:#;
	:#;             /|
	:#;          h / |
	:#;           /  |o
	:#;          /x  |
	:#;         /----|    
	:#;           a
	:#;
	:#;   The tangent of angle x is the ratio of the length of the opposite side 
	:#;   divided by the length of the adjacent side. As the opposite length can 
	:#;   be calculates using sin(x) and the adjacent length using cos(x) then 
	:#;   the tangent can be defined in terms of the previous two functions.
	:#
	:#;   Error 6 if the argument, in radians, is too close to one like pi/2
	:#;   which has an infinite tangent. e.g. PRINT TAN (PI/2)  evaluates as 1/0.
	:#;   Similarly PRINT TAN (3*PI/2), TAN (5*PI/2) etc.
	:#
	:#;; tan
1D6E EF         rst $28	:C tan
	:;; FP-CALC          x.

1D6F:B
1D6F-1D6F 2D	:B
	:;;duplicate         x, x.

1D70:B
1D70-1D70 1C	:B
	:;;sin               x, sin x.

1D71:B
1D71-1D71 01	:B
	:;;exchange          sin x, x.

1D72:B
1D72-1D72 1D	:B
	:;;cos               sin x, cos x.

1D73:B
1D73-1D73 05	:B
	:;;division          sin x/cos x (= tan x).

1D74:B
1D74-1D74 34	:B
	:;;end-calc          tan x.
	:;

1D75:C
1D75 C9         ret	:C
	:; return.
	:;

1D76:C
	:#; ---------------------
	:#; THE 'ARCTAN' FUNCTION
	:#; ---------------------
	:#; (Offset $21: 'atn')
	:#;   The inverse tangent function with the result in radians.
	:#;   This is a fundamental transcendental function from which others such as
	:#;   asn and acs are directly, or indirectly, derived.
	:#;   It uses the series generator to produce Chebyshev polynomials.
	:#
	:#;; atn
1D76 7E         ld a, (hl)	:C atn
	:; fetch exponent

1D77:C
1D77 FE81       cp $81	:C
	:; compare to that for 'one'

1D79:C
1D79 380E       jr c, $1D89	:C
	:; forward, if less, to SMALL
	:;

1D7B:C
1D7B EF         rst $28	:C
	:;; FP-CALC      X.

1D7C:B
1D7C-1D7C A1	:B
	:;;stk-one

1D7D:B
1D7D-1D7D 18	:B
	:;;negate

1D7E:B
1D7E-1D7E 01	:B
	:;;exchange

1D7F:B
1D7F-1D7F 05	:B
	:;;division

1D80:B
1D80-1D80 2D	:B
	:;;duplicate

1D81:B
1D81-1D81 32	:B
	:;;less-0

1D82:B
1D82-1D82 A3	:B
	:;;stk-pi/2

1D83:B
1D83-1D83 01	:B
	:;;exchange

1D84:B
1D84-1D84 00	:B
	:;;jump-true

1D85:B
1D85-1D85 06	:B
	:;;to L1D8B, CASES
	:;

1D86:B
1D86-1D86 18	:B
	:;;negate

1D87:B
1D87-1D87 2F	:B
	:;;jump

1D88:B
1D88-1D88 03	:B
	:;;to L1D8B, CASES
	:;

1D89:C
	:#; ---
	:#
	:#;; SMALL
1D89 EF         rst $28	:C SMALL
	:;; FP-CALC

1D8A:B
1D8A-1D8A A0	:B
	:;;stk-zero
	:;

1D8B:B
	:#;; CASES
1D8B-1D8B 01	:B CASES
	:;;exchange

1D8C:B
1D8C-1D8C 2D	:B
	:;;duplicate

1D8D:B
1D8D-1D8D 2D	:B
	:;;duplicate

1D8E:B
1D8E-1D8E 04	:B
	:;;multiply

1D8F:B
1D8F-1D8F 2D	:B
	:;;duplicate

1D90:B
1D90-1D90 0F	:B
	:;;addition

1D91:B
1D91-1D91 A1	:B
	:;;stk-one

1D92:B
1D92-1D92 03	:B
	:;;subtract
	:;

1D93:B
1D93-1D93 8C	:B
	:;;series-0C

1D94:B
1D94-1D94 10	:B
	:;;Exponent: $60, Bytes: 1

1D95:B
1D95-1D95 B2	:B
	:;;(+00,+00,+00)

1D96:B
1D96-1D96 13	:B
	:;;Exponent: $63, Bytes: 1

1D97:B
1D97-1D97 0E	:B
	:;;(+00,+00,+00)

1D98:B
1D98-1D98 55	:B
	:;;Exponent: $65, Bytes: 2

1D99:B
1D99-1D9A E48D	:B
	:;;(+00,+00)

1D9B:B
1D9B-1D9B 58	:B
	:;;Exponent: $68, Bytes: 2

1D9C:B
1D9C-1D9D 39BC	:B
	:;;(+00,+00)

1D9E:B
1D9E-1D9E 5B	:B
	:;;Exponent: $6B, Bytes: 2

1D9F:B
1D9F-1DA0 98FD	:B
	:;;(+00,+00)

1DA1:B
1DA1-1DA1 9E	:B
	:;;Exponent: $6E, Bytes: 3

1DA2:B
1DA2-1DA4 003675	:B
	:;;(+00)

1DA5:B
1DA5-1DA5 A0	:B
	:;;Exponent: $70, Bytes: 3

1DA6:B
1DA6-1DA8 DBE8B4	:B
	:;;(+00)

1DA9:B
1DA9-1DA9 63	:B
	:;;Exponent: $73, Bytes: 2

1DAA:B
1DAA-1DAB 42C4	:B
	:;;(+00,+00)

1DAC:B
1DAC-1DAC E6	:B
	:;;Exponent: $76, Bytes: 4

1DAD:B
1DAD-1DB0 B50936BE	:B
	:;;

1DB1:B
1DB1-1DB1 E9	:B
	:;;Exponent: $79, Bytes: 4

1DB2:B
1DB2-1DB5 36731B5D	:B
	:;;

1DB6:B
1DB6-1DB6 EC	:B
	:;;Exponent: $7C, Bytes: 4

1DB7:B
1DB7-1DBA D8DE63BE	:B
	:;;

1DBB:B
1DBB-1DBB F0	:B
	:;;Exponent: $80, Bytes: 4

1DBC:B
1DBC-1DBF 61A1B30C	:B
	:;;
	:;

1DC0:B
1DC0-1DC0 04	:B
	:;;multiply

1DC1:B
1DC1-1DC1 0F	:B
	:;;addition

1DC2:B
1DC2-1DC2 34	:B
	:;;end-calc
	:;

1DC3:C
1DC3 C9         ret	:C
	:; return.
	:;
	:;

1DC4:C
	:#; ---------------------
	:#; THE 'ARCSIN' FUNCTION
	:#; ---------------------
	:#; (Offset $1F: 'asn')
	:#;   The inverse sine function with result in radians.
	:#;   Derived from arctan function above.
	:#;   Error A unless the argument is between -1 and +1 inclusive.
	:#;   Uses an adaptation of the formula asn(x) = atn(x/sqr(1-x*x))
	:#;
	:#;
	:#;                 /|
	:#;                / |
	:#;              1/  |x
	:#;              /a  |
	:#;             /----|    
	:#;               y
	:#;
	:#;   e.g. We know the opposite side (x) and hypotenuse (1) 
	:#;   and we wish to find angle a in radians.
	:#;   We can derive length y by Pythagoras and then use ATN instead. 
	:#;   Since y*y + x*x = 1*1 (Pythagoras Theorem) then
	:#;   y=sqr(1-x*x)                         - no need to multiply 1 by itself.
	:#;   So, asn(a) = atn(x/y)
	:#;   or more fully,
	:#;   asn(a) = atn(x/sqr(1-x*x))
	:#
	:#;   Close but no cigar.
	:#
	:#;   While PRINT ATN (x/SQR (1-x*x)) gives the same results as PRINT ASN x,
	:#;   it leads to division by zero when x is 1 or -1.
	:#;   To overcome this, 1 is added to y giving half the required angle and the 
	:#;   result is then doubled. 
	:#;   That is, PRINT ATN (x/(SQR (1-x*x) +1)) *2
	:#;
	:#;
	:#;               . /|
	:#;            .  c/ |
	:#;         .     /1 |x
	:#;      . c   b /a  |
	:#;    ---------/----|    
	:#;      1      y
	:#;
	:#;   By creating an isosceles triangle with two equal sides of 1, angles c and 
	:#;   c are also equal. If b+c+d = 180 degrees and b+a = 180 degrees then c=a/2.
	:#;
	:#;   A value higher than 1 gives the required error as attempting to find  the
	:#;   square root of a negative number generates an error in Sinclair BASIC.
	:#
	:#;; asn
1DC4 EF         rst $28	:C asn
	:;; FP-CALC      x.

1DC5:B
1DC5-1DC5 2D	:B
	:;;duplicate     x, x.

1DC6:B
1DC6-1DC6 2D	:B
	:;;duplicate     x, x, x.

1DC7:B
1DC7-1DC7 04	:B
	:;;multiply      x, x*x.

1DC8:B
1DC8-1DC8 A1	:B
	:;;stk-one       x, x*x, 1.

1DC9:B
1DC9-1DC9 03	:B
	:;;subtract      x, x*x-1.

1DCA:B
1DCA-1DCA 18	:B
	:;;negate        x, 1-x*x.

1DCB:B
1DCB-1DCB 25	:B
	:;;sqr           x, sqr(1-x*x) = y.

1DCC:B
1DCC-1DCC A1	:B
	:;;stk-one       x, y, 1.

1DCD:B
1DCD-1DCD 0F	:B
	:;;addition      x, y+1.

1DCE:B
1DCE-1DCE 05	:B
	:;;division      x/y+1.

1DCF:B
1DCF-1DCF 21	:B
	:;;atn           a/2     (half the angle)

1DD0:B
1DD0-1DD0 2D	:B
	:;;duplicate     a/2, a/2.

1DD1:B
1DD1-1DD1 0F	:B
	:;;addition      a.

1DD2:B
1DD2-1DD2 34	:B
	:;;end-calc      a.
	:;

1DD3:C
1DD3 C9         ret	:C
	:; return.
	:;
	:;

1DD4:C
	:#; ------------------------
	:#; THE 'ARCCOS' FUNCTION
	:#; ------------------------
	:#; (Offset $20: 'acs')
	:#;   The inverse cosine function with the result in radians.
	:#;   Error A unless the argument is between -1 and +1.
	:#;   Result in range 0 to pi.
	:#;   Derived from asn above which is in turn derived from the preceding atn. It 
	:#;   could have been derived directly from atn using acs(x) = atn(sqr(1-x*x)/x).
	:#;   However, as sine and cosine are horizontal translations of each other,
	:#;   uses acs(x) = pi/2 - asn(x)
	:#
	:#;   e.g. the arccosine of a known x value will give the required angle b in 
	:#;   radians.
	:#;   We know, from above, how to calculate the angle a using asn(x). 
	:#;   Since the three angles of any triangle add up to 180 degrees, or pi radians,
	:#;   and the largest angle in this case is a right-angle (pi/2 radians), then
	:#;   we can calculate angle b as pi/2 (both angles) minus asn(x) (angle a).
	:#; 
	:#;
	:#;            /|
	:#;         1 /b|
	:#;          /  |x
	:#;         /a  |
	:#;        /----|    
	:#;          y
	:#
	:#;; acs
1DD4 EF         rst $28	:C acs
	:;; FP-CALC      x.

1DD5:B
1DD5-1DD5 1F	:B
	:;;asn           asn(x).

1DD6:B
1DD6-1DD6 A3	:B
	:;;stk-pi/2      asn(x), pi/2.

1DD7:B
1DD7-1DD7 03	:B
	:;;subtract      asn(x) - pi/2.

1DD8:B
1DD8-1DD8 18	:B
	:;;negate        pi/2 - asn(x) = acs(x).

1DD9:B
1DD9-1DD9 34	:B
	:;;end-calc      acs(x)
	:;

1DDA:C
1DDA C9         ret	:C
	:; return.
	:;
	:;

1DDB:C
	:#; --------------------------
	:#; THE 'SQUARE ROOT' FUNCTION
	:#; --------------------------
	:#; (Offset $25: 'sqr')
	:#;   Error A if argument is negative.
	:#;   This routine is remarkable for its brevity - 7 bytes.
	:#;   The ZX81 code was originally 9K and various techniques had to be
	:#;   used to shoe-horn it into an 8K Rom chip.
	:#
	:#
	:#;; sqr
1DDB EF         rst $28	:C sqr
	:;; FP-CALC              x.

1DDC:B
1DDC-1DDC 2D	:B
	:;;duplicate             x, x.

1DDD:B
1DDD-1DDD 2C	:B
	:;;not                   x, 1/0

1DDE:B
1DDE-1DDE 00	:B
	:;;jump-true             x, (1/0).

1DDF:B
1DDF-1DDF 1E	:B
	:;;to L1DFD, LAST        exit if argument zero
	:;;                      with zero result.
	:;

1DE0:B
	:#;   else continue to calculate as x ** .5
	:#
1DE0-1DE0 A2	:B
	:;;stk-half              x, .5.

1DE1:B
1DE1-1DE1 34	:B
	:;;end-calc              x, .5.
	:;
	:;

1DE2:C
	:#; ------------------------------
	:#; THE 'EXPONENTIATION' OPERATION
	:#; ------------------------------
	:#; (Offset $06: 'to-power')
	:#;   This raises the first number X to the power of the second number Y.
	:#;   As with the ZX80,
	:#;   0 ** 0 = 1
	:#;   0 ** +n = 0
	:#;   0 ** -n = arithmetic overflow.
	:#
	:#;; to-power
1DE2 EF         rst $28	:C to_power
	:;; FP-CALC              X,Y.

1DE3:B
1DE3-1DE3 01	:B
	:;;exchange              Y,X.

1DE4:B
1DE4-1DE4 2D	:B
	:;;duplicate             Y,X,X.

1DE5:B
1DE5-1DE5 2C	:B
	:;;not                   Y,X,(1/0).

1DE6:B
1DE6-1DE6 00	:B
	:;;jump-true

1DE7:B
1DE7-1DE7 07	:B
	:;;forward to L1DEE, XISO if X is zero.
	:;

1DE8:B
	:#;   else X is non-zero. function 'ln' will catch a negative value of X.
	:#
1DE8-1DE8 22	:B
	:;;ln                    Y, LN X.

1DE9:B
1DE9-1DE9 04	:B
	:;;multiply              Y * LN X

1DEA:B
1DEA-1DEA 34	:B
	:;;end-calc
	:;

1DEB:C
1DEB C35B1C     jp $1C5B	:C
	:; jump back to EXP routine.  ->
	:;

1DEE:B
	:#; ---
	:#
	:#;   These routines form the three simple results when the number is zero.
	:#;   begin by deleting the known zero to leave Y the power factor.
	:#
	:#;; XISO
1DEE-1DEE 02	:B XISO
	:;;delete                Y.

1DEF:B
1DEF-1DEF 2D	:B
	:;;duplicate             Y, Y.

1DF0:B
1DF0-1DF0 2C	:B
	:;;not                   Y, (1/0).

1DF1:B
1DF1-1DF1 00	:B
	:;;jump-true     

1DF2:B
1DF2-1DF2 09	:B
	:;;forward to L1DFB, ONE if Y is zero.
	:;

1DF3:B
	:#;   the power factor is not zero. If negative then an error exists.
	:#
1DF3-1DF3 A0	:B
	:;;stk-zero              Y, 0.

1DF4:B
1DF4-1DF4 01	:B
	:;;exchange              0, Y.

1DF5:B
1DF5-1DF5 33	:B
	:;;greater-0             0, (1/0).

1DF6:B
1DF6-1DF6 00	:B
	:;;jump-true             0

1DF7:B
1DF7-1DF7 06	:B
	:;;to L1DFD, LAST        if Y was any positive 
	:;;                      number.
	:;

1DF8:B
	:#;   else force division by zero thereby raising an Arithmetic overflow error.
	:#;   There are some one and two-byte alternatives but perhaps the most formal
	:#;   might have been to use end-calc; rst 08; defb 05.
	:#
1DF8-1DF8 A1	:B
	:;;stk-one               0, 1.

1DF9:B
1DF9-1DF9 01	:B
	:;;exchange              1, 0.

1DFA:B
1DFA-1DFA 05	:B
	:;;division              1/0    >> error 
	:;

1DFB:B
	:#; ---
	:#
	:#;; ONE
1DFB-1DFB 02	:B ONE
	:;;delete                .

1DFC:B
1DFC-1DFC A1	:B
	:;;stk-one               1.
	:;

1DFD:B
	:#;; LAST
1DFD-1DFD 34	:B LAST
	:;;end-calc              last value 1 or 0.
	:;

1DFE:C
1DFE C9         ret	:C
	:; return.
	:;

1DFF:B
	:#; ---------------------
	:#; THE 'SPARE LOCATIONS'
	:#; ---------------------
	:#
	:#;; SPARE
1DFF-1DFF FF	:B SPARE
	:; That's all folks.
	:;
	:;
	:;

1E00:B
	:#; ------------------------
	:#; THE 'ZX81 CHARACTER SET'
	:#; ------------------------
	:#
	:#;; char-set - begins with space character.
	:#
	:#; $00 - Character: ' '          CHR$(0)
	:#
1E00-1E00 00	:B

1E01:B
1E01-1E01 00	:B

1E02:B
1E02-1E02 00	:B

1E03:B
1E03-1E03 00	:B

1E04:B
1E04-1E04 00	:B

1E05:B
1E05-1E05 00	:B

1E06:B
1E06-1E06 00	:B

1E07:B
1E07-1E07 00	:B
	:;

1E08:B
	:#; $01 - Character: mosaic       CHR$(1)
	:#
1E08-1E08 F0	:B

1E09:B
1E09-1E09 F0	:B

1E0A:B
1E0A-1E0A F0	:B

1E0B:B
1E0B-1E0B F0	:B

1E0C:B
1E0C-1E0C 00	:B

1E0D:B
1E0D-1E0D 00	:B

1E0E:B
1E0E-1E0E 00	:B

1E0F:B
1E0F-1E0F 00	:B
	:;
	:;

1E10:B
	:#; $02 - Character: mosaic       CHR$(2)
	:#
1E10-1E10 0F	:B

1E11:B
1E11-1E11 0F	:B

1E12:B
1E12-1E12 0F	:B

1E13:B
1E13-1E13 0F	:B

1E14:B
1E14-1E14 00	:B

1E15:B
1E15-1E15 00	:B

1E16:B
1E16-1E16 00	:B

1E17:B
1E17-1E17 00	:B
	:;
	:;

1E18:B
	:#; $03 - Character: mosaic       CHR$(3)
	:#
1E18-1E18 FF	:B

1E19:B
1E19-1E19 FF	:B

1E1A:B
1E1A-1E1A FF	:B

1E1B:B
1E1B-1E1B FF	:B

1E1C:B
1E1C-1E1C 00	:B

1E1D:B
1E1D-1E1D 00	:B

1E1E:B
1E1E-1E1E 00	:B

1E1F:B
1E1F-1E1F 00	:B
	:;

1E20:B
	:#; $04 - Character: mosaic       CHR$(4)
	:#
1E20-1E20 00	:B

1E21:B
1E21-1E21 00	:B

1E22:B
1E22-1E22 00	:B

1E23:B
1E23-1E23 00	:B

1E24:B
1E24-1E24 F0	:B

1E25:B
1E25-1E25 F0	:B

1E26:B
1E26-1E26 F0	:B

1E27:B
1E27-1E27 F0	:B
	:;

1E28:B
	:#; $05 - Character: mosaic       CHR$(5)
	:#
1E28-1E28 F0	:B

1E29:B
1E29-1E29 F0	:B

1E2A:B
1E2A-1E2A F0	:B

1E2B:B
1E2B-1E2B F0	:B

1E2C:B
1E2C-1E2C F0	:B

1E2D:B
1E2D-1E2D F0	:B

1E2E:B
1E2E-1E2E F0	:B

1E2F:B
1E2F-1E2F F0	:B
	:;

1E30:B
	:#; $06 - Character: mosaic       CHR$(6)
	:#
1E30-1E30 0F	:B

1E31:B
1E31-1E31 0F	:B

1E32:B
1E32-1E32 0F	:B

1E33:B
1E33-1E33 0F	:B

1E34:B
1E34-1E34 F0	:B

1E35:B
1E35-1E35 F0	:B

1E36:B
1E36-1E36 F0	:B

1E37:B
1E37-1E37 F0	:B
	:;

1E38:B
	:#; $07 - Character: mosaic       CHR$(7)
	:#
1E38-1E38 FF	:B

1E39:B
1E39-1E39 FF	:B

1E3A:B
1E3A-1E3A FF	:B

1E3B:B
1E3B-1E3B FF	:B

1E3C:B
1E3C-1E3C F0	:B

1E3D:B
1E3D-1E3D F0	:B

1E3E:B
1E3E-1E3E F0	:B

1E3F:B
1E3F-1E3F F0	:B
	:;

1E40:B
	:#; $08 - Character: mosaic       CHR$(8)
	:#
1E40-1E40 AA	:B

1E41:B
1E41-1E41 55	:B

1E42:B
1E42-1E42 AA	:B

1E43:B
1E43-1E43 55	:B

1E44:B
1E44-1E44 AA	:B

1E45:B
1E45-1E45 55	:B

1E46:B
1E46-1E46 AA	:B

1E47:B
1E47-1E47 55	:B
	:;

1E48:B
	:#; $09 - Character: mosaic       CHR$(9)
	:#
1E48-1E48 00	:B

1E49:B
1E49-1E49 00	:B

1E4A:B
1E4A-1E4A 00	:B

1E4B:B
1E4B-1E4B 00	:B

1E4C:B
1E4C-1E4C AA	:B

1E4D:B
1E4D-1E4D 55	:B

1E4E:B
1E4E-1E4E AA	:B

1E4F:B
1E4F-1E4F 55	:B
	:;

1E50:B
	:#; $0A - Character: mosaic       CHR$(10)
	:#
1E50-1E50 AA	:B

1E51:B
1E51-1E51 55	:B

1E52:B
1E52-1E52 AA	:B

1E53:B
1E53-1E53 55	:B

1E54:B
1E54-1E54 00	:B

1E55:B
1E55-1E55 00	:B

1E56:B
1E56-1E56 00	:B

1E57:B
1E57-1E57 00	:B
	:;

1E58:B
	:#; $0B - Character: '"'          CHR$(11)
	:#
1E58-1E58 00	:B

1E59:B
1E59-1E59 24	:B

1E5A:B
1E5A-1E5A 24	:B

1E5B:B
1E5B-1E5B 00	:B

1E5C:B
1E5C-1E5C 00	:B

1E5D:B
1E5D-1E5D 00	:B

1E5E:B
1E5E-1E5E 00	:B

1E5F:B
1E5F-1E5F 00	:B
	:;

1E60:B
	:#; $0B - Character: ukp          CHR$(12)
	:#
1E60-1E60 00	:B

1E61:B
1E61-1E61 1C	:B

1E62:B
1E62-1E62 22	:B

1E63:B
1E63-1E63 78	:B

1E64:B
1E64-1E64 20	:B

1E65:B
1E65-1E65 20	:B

1E66:B
1E66-1E66 7E	:B

1E67:B
1E67-1E67 00	:B
	:;

1E68:B
	:#; $0B - Character: '$'          CHR$(13)
	:#
1E68-1E68 00	:B

1E69:B
1E69-1E69 08	:B

1E6A:B
1E6A-1E6A 3E	:B

1E6B:B
1E6B-1E6B 28	:B

1E6C:B
1E6C-1E6C 3E	:B

1E6D:B
1E6D-1E6D 0A	:B

1E6E:B
1E6E-1E6E 3E	:B

1E6F:B
1E6F-1E6F 08	:B
	:;

1E70:B
	:#; $0B - Character: ':'          CHR$(14)
	:#
1E70-1E70 00	:B

1E71:B
1E71-1E71 00	:B

1E72:B
1E72-1E72 00	:B

1E73:B
1E73-1E73 10	:B

1E74:B
1E74-1E74 00	:B

1E75:B
1E75-1E75 00	:B

1E76:B
1E76-1E76 10	:B

1E77:B
1E77-1E77 00	:B
	:;

1E78:B
	:#; $0B - Character: '?'          CHR$(15)
	:#
1E78-1E78 00	:B

1E79:B
1E79-1E79 3C	:B

1E7A:B
1E7A-1E7A 42	:B

1E7B:B
1E7B-1E7B 04	:B

1E7C:B
1E7C-1E7C 08	:B

1E7D:B
1E7D-1E7D 00	:B

1E7E:B
1E7E-1E7E 08	:B

1E7F:B
1E7F-1E7F 00	:B
	:;

1E80:B
	:#; $10 - Character: '('          CHR$(16)
	:#
1E80-1E80 00	:B

1E81:B
1E81-1E81 04	:B

1E82:B
1E82-1E82 08	:B

1E83:B
1E83-1E83 08	:B

1E84:B
1E84-1E84 08	:B

1E85:B
1E85-1E85 08	:B

1E86:B
1E86-1E86 04	:B

1E87:B
1E87-1E87 00	:B
	:;

1E88:B
	:#; $11 - Character: ')'          CHR$(17)
	:#
1E88-1E88 00	:B

1E89:B
1E89-1E89 20	:B

1E8A:B
1E8A-1E8A 10	:B

1E8B:B
1E8B-1E8B 10	:B

1E8C:B
1E8C-1E8C 10	:B

1E8D:B
1E8D-1E8D 10	:B

1E8E:B
1E8E-1E8E 20	:B

1E8F:B
1E8F-1E8F 00	:B
	:;

1E90:B
	:#; $12 - Character: '>'          CHR$(18)
	:#
1E90-1E90 00	:B

1E91:B
1E91-1E91 00	:B

1E92:B
1E92-1E92 10	:B

1E93:B
1E93-1E93 08	:B

1E94:B
1E94-1E94 04	:B

1E95:B
1E95-1E95 08	:B

1E96:B
1E96-1E96 10	:B

1E97:B
1E97-1E97 00	:B
	:;

1E98:B
	:#; $13 - Character: '<'          CHR$(19)
	:#
1E98-1E98 00	:B

1E99:B
1E99-1E99 00	:B

1E9A:B
1E9A-1E9A 04	:B

1E9B:B
1E9B-1E9B 08	:B

1E9C:B
1E9C-1E9C 10	:B

1E9D:B
1E9D-1E9D 08	:B

1E9E:B
1E9E-1E9E 04	:B

1E9F:B
1E9F-1E9F 00	:B
	:;

1EA0:B
	:#; $14 - Character: '='          CHR$(20)
	:#
1EA0-1EA0 00	:B

1EA1:B
1EA1-1EA1 00	:B

1EA2:B
1EA2-1EA2 00	:B

1EA3:B
1EA3-1EA3 3E	:B

1EA4:B
1EA4-1EA4 00	:B

1EA5:B
1EA5-1EA5 3E	:B

1EA6:B
1EA6-1EA6 00	:B

1EA7:B
1EA7-1EA7 00	:B
	:;

1EA8:B
	:#; $15 - Character: '+'          CHR$(21)
	:#
1EA8-1EA8 00	:B

1EA9:B
1EA9-1EA9 00	:B

1EAA:B
1EAA-1EAA 08	:B

1EAB:B
1EAB-1EAB 08	:B

1EAC:B
1EAC-1EAC 3E	:B

1EAD:B
1EAD-1EAD 08	:B

1EAE:B
1EAE-1EAE 08	:B

1EAF:B
1EAF-1EAF 00	:B
	:;

1EB0:B
	:#; $16 - Character: '-'          CHR$(22)
	:#
1EB0-1EB0 00	:B

1EB1:B
1EB1-1EB1 00	:B

1EB2:B
1EB2-1EB2 00	:B

1EB3:B
1EB3-1EB3 00	:B

1EB4:B
1EB4-1EB4 3E	:B

1EB5:B
1EB5-1EB5 00	:B

1EB6:B
1EB6-1EB6 00	:B

1EB7:B
1EB7-1EB7 00	:B
	:;

1EB8:B
	:#; $17 - Character: '*'          CHR$(23)
	:#
1EB8-1EB8 00	:B

1EB9:B
1EB9-1EB9 00	:B

1EBA:B
1EBA-1EBA 14	:B

1EBB:B
1EBB-1EBB 08	:B

1EBC:B
1EBC-1EBC 3E	:B

1EBD:B
1EBD-1EBD 08	:B

1EBE:B
1EBE-1EBE 14	:B

1EBF:B
1EBF-1EBF 00	:B
	:;

1EC0:B
	:#; $18 - Character: '/'          CHR$(24)
	:#
1EC0-1EC0 00	:B

1EC1:B
1EC1-1EC1 00	:B

1EC2:B
1EC2-1EC2 02	:B

1EC3:B
1EC3-1EC3 04	:B

1EC4:B
1EC4-1EC4 08	:B

1EC5:B
1EC5-1EC5 10	:B

1EC6:B
1EC6-1EC6 20	:B

1EC7:B
1EC7-1EC7 00	:B
	:;

1EC8:B
	:#; $19 - Character: ';'          CHR$(25)
	:#
1EC8-1EC8 00	:B

1EC9:B
1EC9-1EC9 00	:B

1ECA:B
1ECA-1ECA 10	:B

1ECB:B
1ECB-1ECB 00	:B

1ECC:B
1ECC-1ECC 00	:B

1ECD:B
1ECD-1ECD 10	:B

1ECE:B
1ECE-1ECE 10	:B

1ECF:B
1ECF-1ECF 20	:B
	:;

1ED0:B
	:#; $1A - Character: ','          CHR$(26)
	:#
1ED0-1ED0 00	:B

1ED1:B
1ED1-1ED1 00	:B

1ED2:B
1ED2-1ED2 00	:B

1ED3:B
1ED3-1ED3 00	:B

1ED4:B
1ED4-1ED4 00	:B

1ED5:B
1ED5-1ED5 08	:B

1ED6:B
1ED6-1ED6 08	:B

1ED7:B
1ED7-1ED7 10	:B
	:;

1ED8:B
	:#; $1B - Character: '.'          CHR$(27)
	:#
1ED8-1ED8 00	:B

1ED9:B
1ED9-1ED9 00	:B

1EDA:B
1EDA-1EDA 00	:B

1EDB:B
1EDB-1EDB 00	:B

1EDC:B
1EDC-1EDC 00	:B

1EDD:B
1EDD-1EDD 18	:B

1EDE:B
1EDE-1EDE 18	:B

1EDF:B
1EDF-1EDF 00	:B
	:;

1EE0:B
	:#; $1C - Character: '0'          CHR$(28)
	:#
1EE0-1EE0 00	:B

1EE1:B
1EE1-1EE1 3C	:B

1EE2:B
1EE2-1EE2 46	:B

1EE3:B
1EE3-1EE3 4A	:B

1EE4:B
1EE4-1EE4 52	:B

1EE5:B
1EE5-1EE5 62	:B

1EE6:B
1EE6-1EE6 3C	:B

1EE7:B
1EE7-1EE7 00	:B
	:;

1EE8:B
	:#; $1D - Character: '1'          CHR$(29)
	:#
1EE8-1EE8 00	:B

1EE9:B
1EE9-1EE9 18	:B

1EEA:B
1EEA-1EEA 28	:B

1EEB:B
1EEB-1EEB 08	:B

1EEC:B
1EEC-1EEC 08	:B

1EED:B
1EED-1EED 08	:B

1EEE:B
1EEE-1EEE 3E	:B

1EEF:B
1EEF-1EEF 00	:B
	:;

1EF0:B
	:#; $1E - Character: '2'          CHR$(30)
	:#
1EF0-1EF0 00	:B

1EF1:B
1EF1-1EF1 3C	:B

1EF2:B
1EF2-1EF2 42	:B

1EF3:B
1EF3-1EF3 02	:B

1EF4:B
1EF4-1EF4 3C	:B

1EF5:B
1EF5-1EF5 40	:B

1EF6:B
1EF6-1EF6 7E	:B

1EF7:B
1EF7-1EF7 00	:B
	:;

1EF8:B
	:#; $1F - Character: '3'          CHR$(31)
	:#
1EF8-1EF8 00	:B

1EF9:B
1EF9-1EF9 3C	:B

1EFA:B
1EFA-1EFA 42	:B

1EFB:B
1EFB-1EFB 0C	:B

1EFC:B
1EFC-1EFC 02	:B

1EFD:B
1EFD-1EFD 42	:B

1EFE:B
1EFE-1EFE 3C	:B

1EFF:B
1EFF-1EFF 00	:B
	:;

1F00:B
	:#; $20 - Character: '4'          CHR$(32)
	:#
1F00-1F00 00	:B

1F01:B
1F01-1F01 08	:B

1F02:B
1F02-1F02 18	:B

1F03:B
1F03-1F03 28	:B

1F04:B
1F04-1F04 48	:B

1F05:B
1F05-1F05 7E	:B

1F06:B
1F06-1F06 08	:B

1F07:B
1F07-1F07 00	:B
	:;

1F08:B
	:#; $21 - Character: '5'          CHR$(33)
	:#
1F08-1F08 00	:B

1F09:B
1F09-1F09 7E	:B

1F0A:B
1F0A-1F0A 40	:B

1F0B:B
1F0B-1F0B 7C	:B

1F0C:B
1F0C-1F0C 02	:B

1F0D:B
1F0D-1F0D 42	:B

1F0E:B
1F0E-1F0E 3C	:B

1F0F:B
1F0F-1F0F 00	:B
	:;

1F10:B
	:#; $22 - Character: '6'          CHR$(34)
	:#
1F10-1F10 00	:B

1F11:B
1F11-1F11 3C	:B

1F12:B
1F12-1F12 40	:B

1F13:B
1F13-1F13 7C	:B

1F14:B
1F14-1F14 42	:B

1F15:B
1F15-1F15 42	:B

1F16:B
1F16-1F16 3C	:B

1F17:B
1F17-1F17 00	:B
	:;

1F18:B
	:#; $23 - Character: '7'          CHR$(35)
	:#
1F18-1F18 00	:B

1F19:B
1F19-1F19 7E	:B

1F1A:B
1F1A-1F1A 02	:B

1F1B:B
1F1B-1F1B 04	:B

1F1C:B
1F1C-1F1C 08	:B

1F1D:B
1F1D-1F1D 10	:B

1F1E:B
1F1E-1F1E 10	:B

1F1F:B
1F1F-1F1F 00	:B
	:;

1F20:B
	:#; $24 - Character: '8'          CHR$(36)
	:#
1F20-1F20 00	:B

1F21:B
1F21-1F21 3C	:B

1F22:B
1F22-1F22 42	:B

1F23:B
1F23-1F23 3C	:B

1F24:B
1F24-1F24 42	:B

1F25:B
1F25-1F25 42	:B

1F26:B
1F26-1F26 3C	:B

1F27:B
1F27-1F27 00	:B
	:;

1F28:B
	:#; $25 - Character: '9'          CHR$(37)
	:#
1F28-1F28 00	:B

1F29:B
1F29-1F29 3C	:B

1F2A:B
1F2A-1F2A 42	:B

1F2B:B
1F2B-1F2B 42	:B

1F2C:B
1F2C-1F2C 3E	:B

1F2D:B
1F2D-1F2D 02	:B

1F2E:B
1F2E-1F2E 3C	:B

1F2F:B
1F2F-1F2F 00	:B
	:;

1F30:B
	:#; $26 - Character: 'A'          CHR$(38)
	:#
1F30-1F30 00	:B

1F31:B
1F31-1F31 3C	:B

1F32:B
1F32-1F32 42	:B

1F33:B
1F33-1F33 42	:B

1F34:B
1F34-1F34 7E	:B

1F35:B
1F35-1F35 42	:B

1F36:B
1F36-1F36 42	:B

1F37:B
1F37-1F37 00	:B
	:;

1F38:B
	:#; $27 - Character: 'B'          CHR$(39)
	:#
1F38-1F38 00	:B

1F39:B
1F39-1F39 7C	:B

1F3A:B
1F3A-1F3A 42	:B

1F3B:B
1F3B-1F3B 7C	:B

1F3C:B
1F3C-1F3C 42	:B

1F3D:B
1F3D-1F3D 42	:B

1F3E:B
1F3E-1F3E 7C	:B

1F3F:B
1F3F-1F3F 00	:B
	:;

1F40:B
	:#; $28 - Character: 'C'          CHR$(40)
	:#
1F40-1F40 00	:B

1F41:B
1F41-1F41 3C	:B

1F42:B
1F42-1F42 42	:B

1F43:B
1F43-1F43 40	:B

1F44:B
1F44-1F44 40	:B

1F45:B
1F45-1F45 42	:B

1F46:B
1F46-1F46 3C	:B

1F47:B
1F47-1F47 00	:B
	:;

1F48:B
	:#; $29 - Character: 'D'          CHR$(41)
	:#
1F48-1F48 00	:B

1F49:B
1F49-1F49 78	:B

1F4A:B
1F4A-1F4A 44	:B

1F4B:B
1F4B-1F4B 42	:B

1F4C:B
1F4C-1F4C 42	:B

1F4D:B
1F4D-1F4D 44	:B

1F4E:B
1F4E-1F4E 78	:B

1F4F:B
1F4F-1F4F 00	:B
	:;

1F50:B
	:#; $2A - Character: 'E'          CHR$(42)
	:#
1F50-1F50 00	:B

1F51:B
1F51-1F51 7E	:B

1F52:B
1F52-1F52 40	:B

1F53:B
1F53-1F53 7C	:B

1F54:B
1F54-1F54 40	:B

1F55:B
1F55-1F55 40	:B

1F56:B
1F56-1F56 7E	:B

1F57:B
1F57-1F57 00	:B
	:;

1F58:B
	:#; $2B - Character: 'F'          CHR$(43)
	:#
1F58-1F58 00	:B

1F59:B
1F59-1F59 7E	:B

1F5A:B
1F5A-1F5A 40	:B

1F5B:B
1F5B-1F5B 7C	:B

1F5C:B
1F5C-1F5C 40	:B

1F5D:B
1F5D-1F5D 40	:B

1F5E:B
1F5E-1F5E 40	:B

1F5F:B
1F5F-1F5F 00	:B
	:;

1F60:B
	:#; $2C - Character: 'G'          CHR$(44)
	:#
1F60-1F60 00	:B

1F61:B
1F61-1F61 3C	:B

1F62:B
1F62-1F62 42	:B

1F63:B
1F63-1F63 40	:B

1F64:B
1F64-1F64 4E	:B

1F65:B
1F65-1F65 42	:B

1F66:B
1F66-1F66 3C	:B

1F67:B
1F67-1F67 00	:B
	:;

1F68:B
	:#; $2D - Character: 'H'          CHR$(45)
	:#
1F68-1F68 00	:B

1F69:B
1F69-1F69 42	:B

1F6A:B
1F6A-1F6A 42	:B

1F6B:B
1F6B-1F6B 7E	:B

1F6C:B
1F6C-1F6C 42	:B

1F6D:B
1F6D-1F6D 42	:B

1F6E:B
1F6E-1F6E 42	:B

1F6F:B
1F6F-1F6F 00	:B
	:;

1F70:B
	:#; $2E - Character: 'I'          CHR$(46)
	:#
1F70-1F70 00	:B

1F71:B
1F71-1F71 3E	:B

1F72:B
1F72-1F72 08	:B

1F73:B
1F73-1F73 08	:B

1F74:B
1F74-1F74 08	:B

1F75:B
1F75-1F75 08	:B

1F76:B
1F76-1F76 3E	:B

1F77:B
1F77-1F77 00	:B
	:;

1F78:B
	:#; $2F - Character: 'J'          CHR$(47)
	:#
1F78-1F78 00	:B

1F79:B
1F79-1F79 02	:B

1F7A:B
1F7A-1F7A 02	:B

1F7B:B
1F7B-1F7B 02	:B

1F7C:B
1F7C-1F7C 42	:B

1F7D:B
1F7D-1F7D 42	:B

1F7E:B
1F7E-1F7E 3C	:B

1F7F:B
1F7F-1F7F 00	:B
	:;

1F80:B
	:#; $30 - Character: 'K'          CHR$(48)
	:#
1F80-1F80 00	:B

1F81:B
1F81-1F81 44	:B

1F82:B
1F82-1F82 48	:B

1F83:B
1F83-1F83 70	:B

1F84:B
1F84-1F84 48	:B

1F85:B
1F85-1F85 44	:B

1F86:B
1F86-1F86 42	:B

1F87:B
1F87-1F87 00	:B
	:;

1F88:B
	:#; $31 - Character: 'L'          CHR$(49)
	:#
1F88-1F88 00	:B

1F89:B
1F89-1F89 40	:B

1F8A:B
1F8A-1F8A 40	:B

1F8B:B
1F8B-1F8B 40	:B

1F8C:B
1F8C-1F8C 40	:B

1F8D:B
1F8D-1F8D 40	:B

1F8E:B
1F8E-1F8E 7E	:B

1F8F:B
1F8F-1F8F 00	:B
	:;

1F90:B
	:#; $32 - Character: 'M'          CHR$(50)
	:#
1F90-1F90 00	:B

1F91:B
1F91-1F91 42	:B

1F92:B
1F92-1F92 66	:B

1F93:B
1F93-1F93 5A	:B

1F94:B
1F94-1F94 42	:B

1F95:B
1F95-1F95 42	:B

1F96:B
1F96-1F96 42	:B

1F97:B
1F97-1F97 00	:B
	:;

1F98:B
	:#; $33 - Character: 'N'          CHR$(51)
	:#
1F98-1F98 00	:B

1F99:B
1F99-1F99 42	:B

1F9A:B
1F9A-1F9A 62	:B

1F9B:B
1F9B-1F9B 52	:B

1F9C:B
1F9C-1F9C 4A	:B

1F9D:B
1F9D-1F9D 46	:B

1F9E:B
1F9E-1F9E 42	:B

1F9F:B
1F9F-1F9F 00	:B
	:;

1FA0:B
	:#; $34 - Character: 'O'          CHR$(52)
	:#
1FA0-1FA0 00	:B

1FA1:B
1FA1-1FA1 3C	:B

1FA2:B
1FA2-1FA2 42	:B

1FA3:B
1FA3-1FA3 42	:B

1FA4:B
1FA4-1FA4 42	:B

1FA5:B
1FA5-1FA5 42	:B

1FA6:B
1FA6-1FA6 3C	:B

1FA7:B
1FA7-1FA7 00	:B
	:;

1FA8:B
	:#; $35 - Character: 'P'          CHR$(53)
	:#
1FA8-1FA8 00	:B

1FA9:B
1FA9-1FA9 7C	:B

1FAA:B
1FAA-1FAA 42	:B

1FAB:B
1FAB-1FAB 42	:B

1FAC:B
1FAC-1FAC 7C	:B

1FAD:B
1FAD-1FAD 40	:B

1FAE:B
1FAE-1FAE 40	:B

1FAF:B
1FAF-1FAF 00	:B
	:;

1FB0:B
	:#; $36 - Character: 'Q'          CHR$(54)
	:#
1FB0-1FB0 00	:B

1FB1:B
1FB1-1FB1 3C	:B

1FB2:B
1FB2-1FB2 42	:B

1FB3:B
1FB3-1FB3 42	:B

1FB4:B
1FB4-1FB4 52	:B

1FB5:B
1FB5-1FB5 4A	:B

1FB6:B
1FB6-1FB6 3C	:B

1FB7:B
1FB7-1FB7 00	:B
	:;

1FB8:B
	:#; $37 - Character: 'R'          CHR$(55)
	:#
1FB8-1FB8 00	:B

1FB9:B
1FB9-1FB9 7C	:B

1FBA:B
1FBA-1FBA 42	:B

1FBB:B
1FBB-1FBB 42	:B

1FBC:B
1FBC-1FBC 7C	:B

1FBD:B
1FBD-1FBD 44	:B

1FBE:B
1FBE-1FBE 42	:B

1FBF:B
1FBF-1FBF 00	:B
	:;

1FC0:B
	:#; $38 - Character: 'S'          CHR$(56)
	:#
1FC0-1FC0 00	:B

1FC1:B
1FC1-1FC1 3C	:B

1FC2:B
1FC2-1FC2 40	:B

1FC3:B
1FC3-1FC3 3C	:B

1FC4:B
1FC4-1FC4 02	:B

1FC5:B
1FC5-1FC5 42	:B

1FC6:B
1FC6-1FC6 3C	:B

1FC7:B
1FC7-1FC7 00	:B
	:;

1FC8:B
	:#; $39 - Character: 'T'          CHR$(57)
	:#
1FC8-1FC8 00	:B

1FC9:B
1FC9-1FC9 FE	:B

1FCA:B
1FCA-1FCA 10	:B

1FCB:B
1FCB-1FCB 10	:B

1FCC:B
1FCC-1FCC 10	:B

1FCD:B
1FCD-1FCD 10	:B

1FCE:B
1FCE-1FCE 10	:B

1FCF:B
1FCF-1FCF 00	:B
	:;

1FD0:B
	:#; $3A - Character: 'U'          CHR$(58)
	:#
1FD0-1FD0 00	:B

1FD1:B
1FD1-1FD1 42	:B

1FD2:B
1FD2-1FD2 42	:B

1FD3:B
1FD3-1FD3 42	:B

1FD4:B
1FD4-1FD4 42	:B

1FD5:B
1FD5-1FD5 42	:B

1FD6:B
1FD6-1FD6 3C	:B

1FD7:B
1FD7-1FD7 00	:B
	:;

1FD8:B
	:#; $3B - Character: 'V'          CHR$(59)
	:#
1FD8-1FD8 00	:B

1FD9:B
1FD9-1FD9 42	:B

1FDA:B
1FDA-1FDA 42	:B

1FDB:B
1FDB-1FDB 42	:B

1FDC:B
1FDC-1FDC 42	:B

1FDD:B
1FDD-1FDD 24	:B

1FDE:B
1FDE-1FDE 18	:B

1FDF:B
1FDF-1FDF 00	:B
	:;

1FE0:B
	:#; $3C - Character: 'W'          CHR$(60)
	:#
1FE0-1FE0 00	:B

1FE1:B
1FE1-1FE1 42	:B

1FE2:B
1FE2-1FE2 42	:B

1FE3:B
1FE3-1FE3 42	:B

1FE4:B
1FE4-1FE4 42	:B

1FE5:B
1FE5-1FE5 5A	:B

1FE6:B
1FE6-1FE6 24	:B

1FE7:B
1FE7-1FE7 00	:B
	:;

1FE8:B
	:#; $3D - Character: 'X'          CHR$(61)
	:#
1FE8-1FE8 00	:B

1FE9:B
1FE9-1FE9 42	:B

1FEA:B
1FEA-1FEA 24	:B

1FEB:B
1FEB-1FEB 18	:B

1FEC:B
1FEC-1FEC 18	:B

1FED:B
1FED-1FED 24	:B

1FEE:B
1FEE-1FEE 42	:B

1FEF:B
1FEF-1FEF 00	:B
	:;

1FF0:B
	:#; $3E - Character: 'Y'          CHR$(62)
	:#
1FF0-1FF0 00	:B

1FF1:B
1FF1-1FF1 82	:B

1FF2:B
1FF2-1FF2 44	:B

1FF3:B
1FF3-1FF3 28	:B

1FF4:B
1FF4-1FF4 10	:B

1FF5:B
1FF5-1FF5 10	:B

1FF6:B
1FF6-1FF6 10	:B

1FF7:B
1FF7-1FF7 00	:B
	:;

1FF8:B
	:#; $3F - Character: 'Z'          CHR$(63)
	:#
1FF8-1FF8 00	:B

1FF9:B
1FF9-1FF9 7E	:B

1FFA:B
1FFA-1FFA 04	:B

1FFB:B
1FFB-1FFB 08	:B

1FFC:B
1FFC-1FFC 10	:B

1FFD:B
1FFD-1FFD 20	:B

1FFE:B
1FFE-1FFE 7E	:B

1FFF:B
1FFF-1FFF 00	:B
	:;
