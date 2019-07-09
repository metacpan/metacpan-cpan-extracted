;************************************************************************
;** An Assembly File Listing to generate a 16K ROM for the ZX Spectrum **
;************************************************************************

; -------------------------
; Last updated: 13-DEC-2004
; -------------------------

; TASM cross-assembler directives. 
; ( comment out, perhaps, for other assemblers - see Notes at end.)

;#define DEFB .BYTE      
;#define DEFW .WORD
;#define DEFM .TEXT
;#define ORG  .ORG
;#define EQU  .EQU
;#define equ  .EQU

;   It is always a good idea to anchor, using ORGs, important sections such as 
;   the character bitmaps so that they don't move as code is added and removed.

;   Generally most approaches try to maintain main entry points as they are
;   often used by third-party software. 


KSTATE        equ $5C00         ; Used in reading the keyboard.
KSTATE1       equ $5C01         ; 
KSTATE2       equ $5C02         ; 
KSTATE3       equ $5C03         ; 
KSTATE4       equ $5C04         ; 
KSTATE5       equ $5C05         ; 
KSTATE6       equ $5C06         ; 
KSTATE7       equ $5C07         ; 
LAST_K        equ $5C08         ; Stores newly pressed key.
REPDEL        equ $5C09         ; Time (in 50ths of a second in 60ths of a second in
                                ; N. America) that a key must be held down before it
                                ; repeats. This starts off at 35, but you can POKE
                                ; in other values.
REPPER        equ $5C0A         ; Delay (in 50ths of a second in 60ths of a second in
                                ; N. America) between successive repeats of a key
                                ; held down: initially 5.
DEFADD        equ $5C0B         ; Address of arguments of user defined function if
                                ; one is being evaluated; otherwise 0.
K_DATA        equ $5C0D         ; Stores 2nd byte of colour controls entered
                                ; from keyboard .
TVDATA        equ $5C0E         ; Stores bytes of coiour, AT and TAB controls going
                                ; to television.
STRMS         equ $5C10         ; Addresses of channels attached to streams.
CHARS         equ $5C36         ; 256 less than address of character set (which
                                ; starts with space and carries on to the copyright
                                ; symbol). Normally in ROM, but you can set up your
                                ; own in RAM and make CHARS point to it.
RASP          equ $5C38         ; Length of warning buzz.
PIP           equ $5C39         ; Length of keyboard click.
ERR_NR        equ $5C3A         ; 1 less than the report code. Starts off at 255 (for 1)
                                ; so PEEK 23610 gives 255.
FLAGS         equ $5C3B         ; Various flags to control the BASIC system.
TV_FLAG       equ $5C3C         ; Flags associated with the television.
ERR_SP        equ $5C3D         ; Address of item on machine stack to be used as
                                ; error return.
LIST_SP       equ $5C3F         ; Address of return address from automatic listing.
MODE          equ $5C41         ; Specifies K, L, C. E or G cursor.
NEWPPC        equ $5C42         ; Line to be jumped to.
NSPPC         equ $5C44         ; Statement number in line to be jumped to. Poking
                                ; first NEWPPC and then NSPPC forces a jump to
                                ; a specified statement in a line.
PPC           equ $5C45         ; Line number of statement currently being executed.
SUBPPC        equ $5C47         ; Number within line of statement being executed.
BORDCR        equ $5C48         ; Border colour * 8; also contains the attributes
                                ; normally used for the lower half of the screen.
E_PPC         equ $5C49         ; Number of current line (with program cursor).
VARS          equ $5C4B         ; Address of variables.
DEST          equ $5C4D         ; Address of variable in assignment.
CHANS         equ $5C4F         ; Address of channel data.
CURCHL        equ $5C51         ; Address of information currently being used for
                                ; input and output.
PROG          equ $5C53         ; Address of BASIC program.
NXTLIN        equ $5C55         ; Address of next line in program.
DATADD        equ $5C57         ; Address of terminator of last DATA item.
E_LINE        equ $5C59         ; Address of command being typed in.
K_CUR         equ $5C5B         ; Address of cursor.
CH_ADD        equ $5C5D         ; Address of the next character to be interpreted:
                                ; the character after the argument of PEEK, or
                                ; the NEWLINE at the end of a POKE statement.
X_PTR         equ $5C5F         ; Address of the character after the ? marker.
WORKSP        equ $5C61         ; Address of temporary work space.
STKBOT        equ $5C63         ; Address of bottom of calculator stack.
STKEND        equ $5C65         ; Address of start of spare space.
BREG          equ $5C67         ; Calculator's b register.
MEM           equ $5C68         ; Address of area used for calculator's memory.
                                ; (Usually MEMBOT, but not always.)
FLAGS2        equ $5C6A         ; More flags.
DF_SZ         equ $5C6B         ; The number of lines (including one blank line)
                                ; in the lower part of the screen.
S_TOP         equ $5C6C         ; The number of the top program line in automatic
                                ; listings.
OLDPPC        equ $5C6E         ; Line number to which CONTINUE jumps.
OSPCC         equ $5C70         ; Number within line of statement to which
                                ; CONTINUE jumps.
FLAGX         equ $5C71         ; Various flags.
STRLEN        equ $5C72         ; Length of string type destination in assignment.
T_ADDR        equ $5C74         ; Address of next item in syntax table (very unlikely
                                ; to be useful).
SEED          equ $5C76         ; The seed for RND. This is the variable that is set
                                ; by RANDOMIZE.
FRAMES        equ $5C78         ; 3 byte (least significant first), frame counter.
                                ; Incremented every 20ms. See Chapter 18.
FRAMES3       equ $5C7A         ; 3rd byte of FRAMES
UDG           equ $5C7B         ; Address of 1st user defined graphic You can change
                                ; this for instance to save space by having fewer
                                ; user defined graphics.
COORDS        equ $5C7D         ; x-coordinate of last point plotted.
COORDS_hi     equ $5C7E         ; y-coordinate of last point plotted.
P_POSN        equ $5C7F         ; 33 column number of printer position
PR_CC         equ $5C80         ; Full address of next position for LPRINT to print at
                                ; (in ZX printer buffer). Legal values 5B00 - 5B1F.
                                ; [Not used in 128K mode or when certain peripherals
                                ; are attached]
ECHO_E        equ $5C82         ; 33 column number and 24 line number (in lower half)
                                ; of end of input buffer.
DF_CC         equ $5C84         ; Address in display file of PRINT position.
DFCCL         equ $5C86         ; Like DF CC for lower part of screen.
S_POSN        equ $5C88         ; 33 column number for PRINT position
S_POSN_hi     equ $5C89         ; 24 line number for PRINT position.
SPOSNL        equ $5C8A         ; Like S POSN for lower part
SCR_CT        equ $5C8C         ; Counts scrolls: it is always 1 more than the number
                                ; of scrolls that will be done before stopping with
                                ; scroll? If you keep poking this with a number
                                ; bigger than 1 (say 255), the screen will scroll
                                ; on and on without asking you.
ATTR_P        equ $5C8D         ; Permanent current colours, etc (as set up by colour
                                ; statements).
MASK_P        equ $5C8E         ; Used for transparent colours, etc. Any bit that
                                ; is 1 shows that the corresponding attribute bit
                                ; is taken not from ATTR P, but from what is already
                                ; on the screen.
ATTR_T        equ $5C8F         ; Temporary current colours, etc (as set up by
                                ; colour items).
MASK_T        equ $5C90         ; Like MASK P, but temporary.
P_FLAG        equ $5C91         ; More flags.
MEMBOT        equ $5C92         ; Calculator's memory area; used to store numbers
                                ; that cannot conveniently be put on
                                ; the calculator stack.
NMIADD        equ $5CB0         ; This is the address of a user supplied NMI address
                                ; which is read by the standard ROM when a peripheral
                                ; activates the NMI. Probably intentionally disabled
                                ; so that the effect is to perform a reset if both
                                ; locations hold zero, but do nothing if the locations
                                ; hold a non-zero value. Interface 1's with serial
                                ; number greater than 87315 will initialize these
                                ; locations to 0 and 80 to allow the RS232 "T" channel
                                ; to use a variable line width. 23728 is the current
                                ; print position and 23729 the width - default 80.
RAMTOP        equ $5CB2         ; Address of last byte of BASIC system area.
P_RAMT        equ $5CB4         ; Address of last byte of physical RAM.

IY0           equ ERR_NR

        org $0000

;*****************************************
;** Part 1. RESTART ROUTINES AND TABLES **
;*****************************************

; -----------
; THE 'START'
; -----------
;   At switch on, the Z80 chip is in Interrupt Mode 0.
;   The Spectrum uses Interrupt Mode 1.
;   This location can also be 'called' to reset the machine.
;   Typically with PRINT USR 0.

;; START

START:
        di                      ; Disable Interrupts.
        xor a                   ; Signal coming from START.
        ld de, $FFFF            ; Set pointer to top of possible physical RAM.
        jp START_NEW            ; Jump forward to common code at START-NEW.


; -------------------
; THE 'ERROR' RESTART
; -------------------
;   The error pointer is made to point to the position of the error to enable
;   the editor to highlight the error position if it occurred during syntax 
;   checking.  It is used at 37 places in the program.  An instruction fetch 
;   on address $0008 may page in a peripheral ROM such as the Sinclair 
;   Interface 1 or Disciple Disk Interface.  This was not an original design 
;   concept and not all errors pass through here.

;; ERROR-1

ERROR_1:
        ld hl, (CH_ADD)         ; Fetch the character address from CH_ADD.
        ld (X_PTR), hl          ; Copy it to the error pointer X_PTR.
        jr ERROR_2              ; Forward to continue at ERROR-2.


; -----------------------------
; THE 'PRINT CHARACTER' RESTART
; -----------------------------
;   The A register holds the code of the character that is to be sent to
;   the output stream of the current channel.  The alternate register set is 
;   used to output a character in the A register so there is no need to 
;   preserve any of the current main registers (HL, DE, BC).  
;   This restart is used 21 times.

;; PRINT-A

PRINT_A:
        jp PRINT_A_2            ; Jump forward to continue at PRINT-A-2.


; ---

        defb $FF, $FF, $FF, $FF, $FF
                                ; Five unused locations.

; -------------------------------
; THE 'COLLECT CHARACTER' RESTART
; -------------------------------
;   The contents of the location currently addressed by CH_ADD are fetched.
;   A return is made if the value represents a character that has
;   relevance to the BASIC parser. Otherwise CH_ADD is incremented and the
;   tests repeated. CH_ADD will be addressing somewhere -
;   1) in the BASIC program area during line execution.
;   2) in workspace if evaluating, for example, a string expression.
;   3) in the edit buffer if parsing a direct command or a new BASIC line.
;   4) in workspace if accepting input but not that from INPUT LINE.

;; GET-CHAR

GET_CHAR:
        ld hl, (CH_ADD)         ; fetch the address from CH_ADD.
        ld a, (hl)              ; use it to pick up current character.

;; TEST-CHAR

TEST_CHAR:
        call SKIP_OVER          ; routine SKIP-OVER tests if the character is
                                ; relevant.
        ret nc                  ; Return if it is significant.

; ------------------------------------
; THE 'COLLECT NEXT CHARACTER' RESTART
; ------------------------------------
;   As the BASIC commands and expressions are interpreted, this routine is
;   called repeatedly to step along the line.  It is used 83 times.

;; NEXT-CHAR

NEXT_CHAR:
        call CH_ADD_1           ; routine CH-ADD+1 fetches the next immediate
                                ; character.
        jr TEST_CHAR            ; jump back to TEST-CHAR until a valid
                                ; character is found.


; ---

        defb $FF, $FF, $FF      ; unused

; -----------------------
; THE 'CALCULATE' RESTART
; -----------------------
;   This restart enters the Spectrum's internal, floating-point, stack-based, 
;   FORTH-like language.
;   It is further used recursively from within the calculator.
;   It is used on 77 occasions.

;; FP-CALC

FP_CALC:
        jp CALCULATE            ; jump forward to the CALCULATE routine.


; ---

        defb $FF, $FF, $FF, $FF, $FF
                                ; spare - note that on the ZX81, space being a
                                ; little cramped, these same locations were
                                ; used for the five-byte end-calc literal.

; ------------------------------
; THE 'CREATE BC SPACES' RESTART
; ------------------------------
;   This restart is used on only 12 occasions to create BC spaces
;   between workspace and the calculator stack.

;; BC-SPACES

BC_SPACES:
        push bc                 ; Save number of spaces.
        ld hl, (WORKSP)         ; Fetch WORKSP.
        push hl                 ; Save address of workspace.
        jp RESERVE              ; Jump forward to continuation code RESERVE.


; --------------------------------
; THE 'MASKABLE INTERRUPT' ROUTINE
; --------------------------------
;   This routine increments the Spectrum's three-byte FRAMES counter fifty 
;   times a second (sixty times a second in the USA ).
;   Both this routine and the called KEYBOARD subroutine use the IY register 
;   to access system variables and flags so a user-written program must 
;   disable interrupts to make use of the IY register.

;; MASK-INT

MASK_INT:
        push af                 ; Save the registers that will be used but not
        push hl                 ; the IY register unfortunately.
        ld hl, (FRAMES)         ; Fetch the first two bytes at FRAMES1.
        inc hl                  ; Increment lowest two bytes of counter.
        ld (FRAMES), hl         ; Place back in FRAMES1.
        ld a, h                 ; Test if the result was zero.
        or l
        jr nz, KEY_INT          ; Forward, if not, to KEY-INT

        inc (iy+FRAMES3-IY0)    ; otherwise increment FRAMES3 the third byte.

;   Now save the rest of the main registers and read and decode the keyboard.

;; KEY-INT

KEY_INT:
        push bc                 ; Save the other main registers.
        push de

        call KEYBOARD           ; Routine KEYBOARD executes a stage in the
                                ; process of reading a key-press.
        pop de
        pop bc                  ; Restore registers.

        pop hl
        pop af

        ei                      ; Enable Interrupts.
        ret                     ; Return.


; ---------------------
; THE 'ERROR-2' ROUTINE
; ---------------------
;   A continuation of the code at 0008.
;   The error code is stored and after clearing down stacks, an indirect jump 
;   is made to MAIN-4, etc. to handle the error.

;; ERROR-2

ERROR_2:
        pop hl                  ; drop the return address - the location
                                ; after the RST 08H instruction.
        ld l, (hl)              ; fetch the error code that follows.
                                ; (nice to see this instruction used.)

;   Note. this entry point is used when out of memory at REPORT-4.
;   The L register has been loaded with the report code but X-PTR is not
;   updated.

;; ERROR-3

ERROR_3:
        ld (iy+ERR_NR-IY0), l   ; Store it in the system variable ERR_NR.
        ld sp, (ERR_SP)         ; ERR_SP points to an error handler on the
                                ; machine stack. There may be a hierarchy
                                ; of routines.
                                ; To MAIN-4 initially at base.
                                ; or REPORT-G on line entry.
                                ; or  ED-ERROR when editing.
                                ; or   ED-FULL during ed-enter.
                                ; or  IN-VAR-1 during runtime input etc.

        jp SET_STK              ; Jump to SET-STK to clear the calculator stack
                                ; and reset MEM to usual place in the systems
                                ; variables area and then indirectly to MAIN-4,
                                ; etc.


; ---

        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF
                                ; Unused locations
                                ; before the fixed-position
                                ; NMI routine.

; ------------------------------------
; THE 'NON-MASKABLE INTERRUPT' ROUTINE
; ------------------------------------
;   
;   There is no NMI switch on the standard Spectrum or its peripherals.
;   When the NMI line is held low, then no matter what the Z80 was doing at 
;   the time, it will now execute the code at 66 Hex.
;   This Interrupt Service Routine will jump to location zero if the contents 
;   of the system variable NMIADD are zero or return if the location holds a
;   non-zero address.   So attaching a simple switch to the NMI as in the book 
;   "Spectrum Hardware Manual" causes a reset.  The logic was obviously 
;   intended to work the other way.  Sinclair Research said that, since they
;   had never advertised the NMI, they had no plans to fix the error "until 
;   the opportunity arose".
;   
;   Note. The location NMIADD was, in fact, later used by Sinclair Research 
;   to enhance the text channel on the ZX Interface 1.
;   On later Amstrad-made Spectrums, and the Brazilian Spectrum, the logic of 
;   this routine was indeed reversed but not as at first intended.
;
;   It can be deduced by looking elsewhere in this ROM that the NMIADD system
;   variable pointed to L121C and that this enabled a Warm Restart to be 
;   performed at any time, even while playing machine code games, or while 
;   another Spectrum has been allowed to gain control of this one. 
;
;   Software houses would have been able to protect their games from attack by
;   placing two zeros in the NMIADD system variable.

;; RESET

RESET:
        push af                 ; save the
        push hl                 ; registers.
        ld hl, (NMIADD)         ; fetch the system variable NMIADD.
        ld a, h                 ; test address
        or l                    ; for zero.

        jr nz, NO_RESET         ; skip to NO-RESET if NOT ZERO

        jp (hl)                 ; jump to routine ( i.e. L0000 )


;; NO-RESET

NO_RESET:
        pop hl                  ; restore the
        pop af                  ; registers.
        retn                    ; return to previous interrupt state.


; ---------------------------
; THE 'CH ADD + 1' SUBROUTINE
; ---------------------------
;   This subroutine is called from RST 20, and three times from elsewhere
;   to fetch the next immediate character following the current valid character
;   address and update the associated system variable.
;   The entry point TEMP-PTR1 is used from the SCANNING routine.
;   Both TEMP-PTR1 and TEMP-PTR2 are used by the READ command routine.

;; CH-ADD+1

CH_ADD_1:
        ld hl, (CH_ADD)         ; fetch address from CH_ADD.

;; TEMP-PTR1

TEMP_PTR1:
        inc hl                  ; increase the character address by one.

;; TEMP-PTR2

TEMP_PTR2:
        ld (CH_ADD), hl         ; update CH_ADD with character address.


X007B:
        ld a, (hl)              ; load character to A from HL.
        ret                     ; and return.


; --------------------------
; THE 'SKIP OVER' SUBROUTINE
; --------------------------
;   This subroutine is called once from RST 18 to skip over white-space and
;   other characters irrelevant to the parsing of a BASIC line etc. .
;   Initially the A register holds the character to be considered
;   and HL holds its address which will not be within quoted text
;   when a BASIC line is parsed.
;   Although the 'tab' and 'at' characters will not appear in a BASIC line,
;   they could be present in a string expression, and in other situations.
;   Note. although white-space is usually placed in a program to indent loops
;   and make it more readable, it can also be used for the opposite effect and
;   spaces may appear in variable names although the parser never sees them.
;   It is this routine that helps make the variables 'Anum bEr5 3BUS' and
;   'a number 53 bus' appear the same to the parser.

;; SKIP-OVER

SKIP_OVER:
        cp $21                  ; test if higher than space.
        ret nc                  ; return with carry clear if so.

        cp $0D                  ; carriage return ?
        ret z                   ; return also with carry clear if so.

                                ; all other characters have no relevance
                                ; to the parser and must be returned with
                                ; carry set.

        cp $10                  ; test if 0-15d
        ret c                   ; return, if so, with carry set.

        cp $18                  ; test if 24-32d
        ccf                     ; complement carry flag.
        ret c                   ; return with carry set if so.

                                ; now leaves 16d-23d

        inc hl                  ; all above have at least one extra character
                                ; to be stepped over.

        cp $16                  ; controls 22d ('at') and 23d ('tab') have two.
        jr c, SKIPS             ; forward to SKIPS with ink, paper, flash,
                                ; bright, inverse or over controls.
                                ; Note. the high byte of tab is for RS232 only.
                                ; it has no relevance on this machine.

        inc hl                  ; step over the second character of 'at'/'tab'.

;; SKIPS

SKIPS:
        scf                     ; set the carry flag
        ld (CH_ADD), hl         ; update the CH_ADD system variable.
        ret                     ; return with carry set.



; ------------------
; THE 'TOKEN' TABLES
; ------------------
;   The tokenized characters 134d (RND) to 255d (COPY) are expanded using
;   this table. The last byte of a token is inverted to denote the end of
;   the word. The first is an inverted step-over byte.

;; TKN-TABLE

TKN_TABLE:
        defm7 "?"
        defm7 "RND"
        defm7 "INKEY$"
        defm7 "PI"
        defm7 "FN"
        defm7 "POINT"
        defm7 "SCREEN$"
        defm7 "ATTR"
        defm7 "AT"
        defm7 "TAB"
        defm7 "VAL$"
        defm7 "CODE"
        defm7 "VAL"
        defm7 "LEN"
        defm7 "SIN"
        defm7 "COS"
        defm7 "TAN"
        defm7 "ASN"
        defm7 "ACS"
        defm7 "ATN"
        defm7 "LN"
        defm7 "EXP"
        defm7 "INT"
        defm7 "SQR"
        defm7 "SGN"
        defm7 "ABS"
        defm7 "PEEK"
        defm7 "IN"
        defm7 "USR"
        defm7 "STR$"
        defm7 "CHR$"
        defm7 "NOT"
        defm7 "BIN"

;   The previous 32 function-type words are printed without a leading space
;   The following have a leading space if they begin with a letter

        defm7 "OR"
        defm7 "AND"
        defm7 "<="              ; <=
        defm7 ">="              ; >=
        defm7 "<>"              ; <>
        defm7 "LINE"
        defm7 "THEN"
        defm7 "TO"
        defm7 "STEP"
        defm7 "DEF FN"
        defm7 "CAT"
        defm7 "FORMAT"
        defm7 "MOVE"
        defm7 "ERASE"
        defm7 "OPEN #"
        defm7 "CLOSE #"
        defm7 "MERGE"
        defm7 "VERIFY"
        defm7 "BEEP"
        defm7 "CIRCLE"
        defm7 "INK"
        defm7 "PAPER"
        defm7 "FLASH"
        defm7 "BRIGHT"
        defm7 "INVERSE"
        defm7 "OVER"
        defm7 "OUT"
        defm7 "LPRINT"
        defm7 "LLIST"
        defm7 "STOP"
        defm7 "READ"
        defm7 "DATA"
        defm7 "RESTORE"
        defm7 "NEW"
        defm7 "BORDER"
        defm7 "CONTINUE"
        defm7 "DIM"
        defm7 "REM"
        defm7 "FOR"
        defm7 "GO TO"
        defm7 "GO SUB"
        defm7 "INPUT"
        defm7 "LOAD"
        defm7 "LIST"
        defm7 "LET"
        defm7 "PAUSE"
        defm7 "NEXT"
        defm7 "POKE"
        defm7 "PRINT"
        defm7 "PLOT"
        defm7 "RUN"
        defm7 "SAVE"
        defm7 "RANDOMIZE"
        defm7 "IF"
        defm7 "CLS"
        defm7 "DRAW"
        defm7 "CLEAR"
        defm7 "RETURN"
        defm7 "COPY"

; ----------------
; THE 'KEY' TABLES
; ----------------
;   These six look-up tables are used by the keyboard reading routine
;   to decode the key values.
;
;   The first table contains the maps for the 39 keys of the standard
;   40-key Spectrum keyboard. The remaining key [SHIFT $27] is read directly.
;   The keys consist of the 26 upper-case alphabetic characters, the 10 digit
;   keys and the space, ENTER and symbol shift key.
;   Unshifted alphabetic keys have $20 added to the value.
;   The keywords for the main alphabetic keys are obtained by adding $A5 to
;   the values obtained from this table.

;; MAIN-KEYS

MAIN_KEYS:
        defm "B"                ; B
        defm "H"                ; H
        defm "Y"                ; Y
        defm "6"                ; 6
        defm "5"                ; 5
        defm "T"                ; T
        defm "G"                ; G
        defm "V"                ; V
        defm "N"                ; N
        defm "J"                ; J
        defm "U"                ; U
        defm "7"                ; 7
        defm "4"                ; 4
        defm "R"                ; R
        defm "F"                ; F
        defm "C"                ; C
        defm "M"                ; M
        defm "K"                ; K
        defm "I"                ; I
        defm "8"                ; 8
        defm "3"                ; 3
        defm "E"                ; E
        defm "D"                ; D
        defm "X"                ; X
        defb $0E                ; SYMBOL SHIFT
        defm "L"                ; L
        defm "O"                ; O
        defm "9"                ; 9
        defm "2"                ; 2
        defm "W"                ; W
        defm "S"                ; S
        defm "Z"                ; Z
        defm " "                ; SPACE
        defb $0D                ; ENTER
        defm "P"                ; P
        defm "0"                ; 0
        defm "1"                ; 1
        defm "Q"                ; Q
        defm "A"                ; A


;; E-UNSHIFT
;  The 26 unshifted extended mode keys for the alphabetic characters.
;  The green keywords on the original keyboard.

E_UNSHIFT:
        defb $E3                ; READ
        defb $C4                ; BIN
        defb $E0                ; LPRINT
        defb $E4                ; DATA
        defb $B4                ; TAN
        defb $BC                ; SGN
        defb $BD                ; ABS
        defb $BB                ; SQR
        defb $AF                ; CODE
        defb $B0                ; VAL
        defb $B1                ; LEN
        defb $C0                ; USR
        defb $A7                ; PI
        defb $A6                ; INKEY$
        defb $BE                ; PEEK
        defb $AD                ; TAB
        defb $B2                ; SIN
        defb $BA                ; INT
        defb $E5                ; RESTORE
        defb $A5                ; RND
        defb $C2                ; CHR$
        defb $E1                ; LLIST
        defb $B3                ; COS
        defb $B9                ; EXP
        defb $C1                ; STR$
        defb $B8                ; LN


;; EXT-SHIFT
;  The 26 shifted extended mode keys for the alphabetic characters.
;  The red keywords below keys on the original keyboard.

EXT_SHIFT:
        defm "~"                ; ~
        defb $DC                ; BRIGHT
        defb $DA                ; PAPER
        defm "\\"               ; \ ;
        defb $B7                ; ATN
        defm "{"                ; {
        defm "}"                ; }
        defb $D8                ; CIRCLE
        defb $BF                ; IN
        defb $AE                ; VAL$
        defb $AA                ; SCREEN$
        defb $AB                ; ATTR
        defb $DD                ; INVERSE
        defb $DE                ; OVER
        defb $DF                ; OUT
        defb $7F                ; (Copyright character)
        defb $B5                ; ASN
        defb $D6                ; VERIFY
        defm "|"                ; |
        defb $D5                ; MERGE
        defm "]"                ; ]
        defb $DB                ; FLASH
        defb $B6                ; ACS
        defb $D9                ; INK
        defm "["                ; [
        defb $D7                ; BEEP


;; CTL-CODES
;  The ten control codes assigned to the top line of digits when the shift 
;  key is pressed.

CTL_CODES:
        defb $0C                ; DELETE
        defb $07                ; EDIT
        defb $06                ; CAPS LOCK
        defb $04                ; TRUE VIDEO
        defb $05                ; INVERSE VIDEO
        defb $08                ; CURSOR LEFT
        defb $0A                ; CURSOR DOWN
        defb $0B                ; CURSOR UP
        defb $09                ; CURSOR RIGHT
        defb $0F                ; GRAPHICS


;; SYM-CODES
;  The 26 red symbols assigned to the alphabetic characters of the keyboard.
;  The ten single-character digit symbols are converted without the aid of
;  a table using subtraction and minor manipulation. 

SYM_CODES:
        defb $E2                ; STOP
        defm "*"                ; *
        defm "?"                ; ?
        defb $CD                ; STEP
        defb $C8                ; >=
        defb $CC                ; TO
        defb $CB                ; THEN
        defm "^"                ; ^
        defb $AC                ; AT
        defm "-"                ; -
        defm "+"                ; +
        defm "="                ; =
        defm "."                ; .
        defm ","                ; ,
        defm ";"                ; ;
        defm "\""               ; "
        defb $C7                ; <=
        defm "<"                ; <
        defb $C3                ; NOT
        defm ">"                ; >
        defb $C5                ; OR
        defm "/"                ; /
        defb $C9                ; <>
        defb $60                ; pound
        defb $C6                ; AND
        defm ":"                ; :

;; E-DIGITS
;  The ten keywords assigned to the digits in extended mode.
;  The remaining red keywords below the keys.

E_DIGITS:
        defb $D0                ; FORMAT
        defb $CE                ; DEF FN
        defb $A8                ; FN
        defb $CA                ; LINE
        defb $D3                ; OPEN #
        defb $D4                ; CLOSE #
        defb $D1                ; MOVE
        defb $D2                ; ERASE
        defb $A9                ; POINT
        defb $CF                ; CAT


;*******************************
;** Part 2. KEYBOARD ROUTINES **
;*******************************

;   Using shift keys and a combination of modes the Spectrum 40-key keyboard
;   can be mapped to 256 input characters

; ---------------------------------------------------------------------------
;
;         0     1     2     3     4 -Bits-  4     3     2     1     0
; PORT                                                                    PORT
;
; F7FE  [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ]  |  [ 6 ] [ 7 ] [ 8 ] [ 9 ] [ 0 ]   EFFE
;  ^                                   |                                   v
; FBFE  [ Q ] [ W ] [ E ] [ R ] [ T ]  |  [ Y ] [ U ] [ I ] [ O ] [ P ]   DFFE
;  ^                                   |                                   v
; FDFE  [ A ] [ S ] [ D ] [ F ] [ G ]  |  [ H ] [ J ] [ K ] [ L ] [ ENT ] BFFE
;  ^                                   |                                   v
; FEFE  [SHI] [ Z ] [ X ] [ C ] [ V ]  |  [ B ] [ N ] [ M ] [sym] [ SPC ] 7FFE
;  ^     $27                                                 $18           v
; Start                                                                   End
;        00100111                                            00011000
;
; ---------------------------------------------------------------------------
;   The above map may help in reading.
;   The neat arrangement of ports means that the B register need only be
;   rotated left to work up the left hand side and then down the right
;   hand side of the keyboard. When the reset bit drops into the carry
;   then all 8 half-rows have been read. Shift is the first key to be
;   read. The lower six bits of the shifts are unambiguous.

; -------------------------------
; THE 'KEYBOARD SCANNING' ROUTINE
; -------------------------------
;   From keyboard and s-inkey$
;   Returns 1 or 2 keys in DE, most significant shift first if any
;   key values 0-39 else 255

;; KEY-SCAN

KEY_SCAN:
        ld l, $2F               ; initial key value
                                ; valid values are obtained by subtracting
                                ; eight five times.
        ld de, $FFFF            ; a buffer to receive 2 keys.

        ld bc, $FEFE            ; the commencing port address
                                ; B holds 11111110 initially and is also
                                ; used to count the 8 half-rows
                                ; ; KEY-LINE

KEY_LINE:
        in a, (c)               ; read the port to A - bits will be reset
                                ; if a key is pressed else set.
        cpl                     ; complement - pressed key-bits are now set
        and $1F                 ; apply 00011111 mask to pick up the
                                ; relevant set bits.

        jr z, KEY_DONE          ; forward to KEY-DONE if zero and therefore
                                ; no keys pressed in row at all.

        ld h, a                 ; transfer row bits to H
        ld a, l                 ; load the initial key value to A

;; KEY-3KEYS

KEY_3KEYS:
        inc d                   ; now test the key buffer
        ret nz                  ; if we have collected 2 keys already
                                ; then too many so quit.

;; KEY-BITS

KEY_BITS:
        sub $08                 ; subtract 8 from the key value
                                ; cycling through key values (top = $27)
                                ; e.g. 2F>   27>1F>17>0F>07
                                ;      2E>   26>1E>16>0E>06
        srl h                   ; shift key bits right into carry.
        jr nc, KEY_BITS         ; back to KEY-BITS if not pressed
                                ; but if pressed we have a value (0-39d)

        ld d, e                 ; transfer a possible previous key to D
        ld e, a                 ; transfer the new key to E
        jr nz, KEY_3KEYS        ; back to KEY-3KEYS if there were more
                                ; set bits - H was not yet zero.

;; KEY-DONE

KEY_DONE:
        dec l                   ; cycles 2F>2E>2D>2C>2B>2A>29>28 for
                                ; each half-row.
        rlc b                   ; form next port address e.g. FEFE > FDFE
        jr c, KEY_LINE          ; back to KEY-LINE if still more rows to do.

        ld a, d                 ; now test if D is still FF ?
        inc a                   ; if it is zero we have at most 1 key
                                ; range now $01-$28  (1-40d)
        ret z                   ; return if one key or no key.

        cp $28                  ; is it capsshift (was $27) ?
        ret z                   ; return if so.

        cp $19                  ; is it symbol shift (was $18) ?
        ret z                   ; return also

        ld a, e                 ; now test E
        ld e, d                 ; but first switch
        ld d, a                 ; the two keys.
        cp $18                  ; is it symbol shift ?
        ret                     ; return (with zero set if it was).
                                ; but with symbol shift now in D


; ----------------------
; THE 'KEYBOARD' ROUTINE
; ----------------------
;   Called from the interrupt 50 times a second.
;

;; KEYBOARD

KEYBOARD:
        call KEY_SCAN           ; routine KEY-SCAN
        ret nz                  ; return if invalid combinations

;   then decrease the counters within the two key-state maps
;   as this could cause one to become free.
;   if the keyboard has not been pressed during the last five interrupts
;   then both sets will be free.


        ld hl, KSTATE           ; point to KSTATE-0

;; K-ST-LOOP

K_ST_LOOP:
        bit 7, (hl)             ; is it free ?  (i.e. $FF)
        jr nz, K_CH_SET         ; forward to K-CH-SET if so

        inc hl                  ; address the 5-counter
        dec (hl)                ; decrease the counter
        dec hl                  ; step back

        jr nz, K_CH_SET         ; forward to K-CH-SET if not at end of count

        ld (hl), $FF            ; else mark this particular map free.

;; K-CH-SET

K_CH_SET:
        ld a, l                 ; make a copy of the low address byte.
        ld hl, KSTATE4          ; point to KSTATE-4
                                ; (ld l,$04 would do)
        cp l                    ; have both sets been considered ?
        jr nz, K_ST_LOOP        ; back to K-ST-LOOP to consider this 2nd set

;   now the raw key (0-38d) is converted to a main key (uppercase).

        call K_TEST             ; routine K-TEST to get main key in A

        ret nc                  ; return if just a single shift

        ld hl, KSTATE           ; point to KSTATE-0
        cp (hl)                 ; does the main key code match ?
        jr z, K_REPEAT          ; forward to K-REPEAT if so

;   if not consider the second key map.

        ex de, hl               ; save kstate-0 in de
        ld hl, KSTATE4          ; point to KSTATE-4
        cp (hl)                 ; does the main key code match ?
        jr z, K_REPEAT          ; forward to K-REPEAT if so

;   having excluded a repeating key we can now consider a new key.
;   the second set is always examined before the first.

        bit 7, (hl)             ; is the key map free ?
        jr nz, K_NEW            ; forward to K-NEW if so.

        ex de, hl               ; bring back KSTATE-0
        bit 7, (hl)             ; is it free ?
        ret z                   ; return if not.
                                ; as we have a key but nowhere to put it yet.

;   continue or jump to here if one of the buffers was free.

;; K-NEW

K_NEW:
        ld e, a                 ; store key in E
        ldi (hl), a             ; place in free location
                                ; advance to the interrupt counter
        ldi (hl), $05           ; and initialize counter to 5
                                ; advance to the delay
        ld a, (REPDEL)          ; pick up the system variable REPDEL
        ldi (hl), a             ; and insert that for first repeat delay.
                                ; advance to last location of state map.

        ld c, (iy+MODE-IY0)     ; pick up MODE  (3 bytes)
        ld d, (iy+FLAGS-IY0)    ; pick up FLAGS (3 bytes)
        push hl                 ; save state map location
                                ; Note. could now have used, to avoid IY,
                                ; ld l,$41; ld c,(hl); ld l,$3B; ld d,(hl).
                                ; six and two threes of course.

        call K_DECODE           ; routine K-DECODE

        pop hl                  ; restore map pointer
        ld (hl), a              ; put the decoded key in last location of map.

;; K-END

K_END:
        ld (LAST_K), a          ; update LASTK system variable.
        set 5, (iy+FLAGS-IY0)   ; update FLAGS  - signal a new key.
        ret                     ; return to interrupt routine.


; -----------------------
; THE 'REPEAT KEY' BRANCH
; -----------------------
;   A possible repeat has been identified. HL addresses the raw key.
;   The last location of the key map holds the decoded key from the first 
;   context.  This could be a keyword and, with the exception of NOT a repeat 
;   is syntactically incorrect and not really desirable.

;; K-REPEAT

K_REPEAT:
        inc hl                  ; increment the map pointer to second location.
        ldi (hl), $05           ; maintain interrupt counter at 5.
                                ; now point to third location.
        dec (hl)                ; decrease the REPDEL value which is used to
                                ; time the delay of a repeat key.

        ret nz                  ; return if not yet zero.

        ld a, (REPPER)          ; fetch the system variable value REPPER.
        ldi (hl), a             ; for subsequent repeats REPPER will be used.
                                ; advance

        ld a, (hl)              ; pick up the key decoded possibly in another
                                ; context.
                                ; Note. should compare with $A5 (RND) and make
                                ; a simple return if this is a keyword.
                                ; e.g. cp $a5; ret nc; (3 extra bytes)
        jr K_END                ; back to K-END


; ----------------------
; THE 'KEY-TEST' ROUTINE
; ----------------------
;   also called from s-inkey$
;   begin by testing for a shift with no other.

;; K-TEST

K_TEST:
        ld b, d                 ; load most significant key to B
                                ; will be $FF if not shift.
        ld d, $00               ; and reset D to index into main table
        ld a, e                 ; load least significant key from E
        cp $27                  ; is it higher than 39d   i.e. FF
        ret nc                  ; return with just a shift (in B now)

        cp $18                  ; is it symbol shift ?
        jr nz, K_MAIN           ; forward to K-MAIN if not

;   but we could have just symbol shift and no other

        bit 7, b                ; is other key $FF (ie not shift)
        ret nz                  ; return with solitary symbol shift


;; K-MAIN

K_MAIN:
        ld hl, MAIN_KEYS        ; address: MAIN-KEYS
        add hl, de              ; add offset 0-38
        ld a, (hl)              ; pick up main key value
        scf                     ; set carry flag
        ret                     ; return    (B has other key still)


; ----------------------------------
; THE 'KEYBOARD DECODING' SUBROUTINE
; ----------------------------------
;   also called from s-inkey$

;; K-DECODE

K_DECODE:
        ld a, e                 ; pick up the stored main key
        cp $3A                  ; an arbitrary point between digits and letters
        jr c, K_DIGIT           ; forward to K-DIGIT with digits, space, enter.

        dec c                   ; decrease MODE ( 0='KLC', 1='E', 2='G')

        jp m, K_KLC_LET         ; to K-KLC-LET if was zero

        jr z, K_E_LET           ; to K-E-LET if was 1 for extended letters.

;   proceed with graphic codes.
;   Note. should selectively drop return address if code > 'U' ($55).
;   i.e. abort the KEYBOARD call.
;   e.g. cp 'V'; jr c,addit; pop af ;pop af ;;addit etc. (6 extra bytes).
;   (s-inkey$ never gets into graphics mode.)
  
;; addit
        add a, $4F              ; add offset to augment 'A' to graphics A say.
        ret                     ; return.
                                ; Note. ( but [GRAPH] V gives RND, etc ).


; ---

;   the jump was to here with extended mode with uppercase A-Z.

;; K-E-LET

K_E_LET:
        ld hl, E_UNSHIFT-$41    ; base address of E-UNSHIFT L022c.
                                ; ( $01EB in standard ROM ).
        inc b                   ; test B is it empty i.e. not a shift.
        jr z, K_LOOK_UP         ; forward to K-LOOK-UP if neither shift.

        ld hl, EXT_SHIFT-$41    ; Address: $0205 L0246-$41 EXT-SHIFT base

;; K-LOOK-UP

K_LOOK_UP:
        ld d, $00               ; prepare to index.
        add hl, de              ; add the main key value.
        ld a, (hl)              ; pick up other mode value.
        ret                     ; return.


; ---

;   the jump was here with mode = 0

;; K-KLC-LET

K_KLC_LET:
        ld hl, SYM_CODES-$41    ; prepare base of sym-codes
        bit 0, b                ; shift=$27 sym-shift=$18
        jr z, K_LOOK_UP         ; back to K-LOOK-UP with symbol-shift

        bit 3, d                ; test FLAGS is it 'K' mode (from OUT-CURS)
        jr z, K_TOKENS          ; skip to K-TOKENS if so

        bit 3, (iy+FLAGS2-IY0)  ; test FLAGS2 - consider CAPS LOCK ?
        ret nz                  ; return if so with main code.

        inc b                   ; is shift being pressed ?
                                ; result zero if not
        ret nz                  ; return if shift pressed.

        add a, $20              ; else convert the code to lower case.
        ret                     ; return.


; ---

;   the jump was here for tokens

;; K-TOKENS

K_TOKENS:
        add a, $A5              ; add offset to main code so that 'A'
                                ; becomes 'NEW' etc.

        ret                     ; return.


; ---

;   the jump was here with digits, space, enter and symbol shift (< $xx)

;; K-DIGIT

K_DIGIT:
        cp $30                  ; is it '0' or higher ?
        ret c                   ; return with space, enter and symbol-shift

        dec c                   ; test MODE (was 0='KLC', 1='E', 2='G')
        jp m, K_KLC_DGT         ; jump to K-KLC-DGT if was 0.

        jr nz, K_GRA_DGT        ; forward to K-GRA-DGT if mode was 2.

;   continue with extended digits 0-9.

        ld hl, E_DIGITS-$30     ; $0254 - base of E-DIGITS
        bit 5, b                ; test - shift=$27 sym-shift=$18
        jr z, K_LOOK_UP         ; to K-LOOK-UP if sym-shift

        cp $38                  ; is character '8' ?
        jr nc, K_8___9          ; to K-8-&-9 if greater than '7'

        sub $20                 ; reduce to ink range $10-$17
        inc b                   ; shift ?
        ret z                   ; return if not.

        add a, $08              ; add 8 to give paper range $18 - $1F
        ret                     ; return


; ---

;   89

;; K-8-&-9

K_8___9:
        sub $36                 ; reduce to 02 and 03  bright codes
        inc b                   ; test if shift pressed.
        ret z                   ; return if not.

        add a, $FE              ; subtract 2 setting carry
        ret                     ; to give 0 and 1    flash codes.


; ---

;   graphics mode with digits

;; K-GRA-DGT

K_GRA_DGT:
        ld hl, CTL_CODES-$30    ; $0230 base address of CTL-CODES

        cp $39                  ; is key '9' ?
        jr z, K_LOOK_UP         ; back to K-LOOK-UP - changed to $0F, GRAPHICS.

        cp $30                  ; is key '0' ?
        jr z, K_LOOK_UP         ; back to K-LOOK-UP - changed to $0C, delete.

;   for keys '0' - '7' we assign a mosaic character depending on shift.

        and $07                 ; convert character to number. 0 - 7.
        add a, $80              ; add offset - they start at $80

        inc b                   ; destructively test for shift
        ret z                   ; and return if not pressed.

        xor $0F                 ; toggle bits becomes range $88-$8F
        ret                     ; return.


; ---

;   now digits in 'KLC' mode

;; K-KLC-DGT

K_KLC_DGT:
        inc b                   ; return with digit codes if neither
        ret z                   ; shift key pressed.

        bit 5, b                ; test for caps shift.

        ld hl, CTL_CODES-$30    ; prepare base of table CTL-CODES.
        jr nz, K_LOOK_UP        ; back to K-LOOK-UP if shift pressed.

;   must have been symbol shift

        sub $10                 ; for ASCII most will now be correct
                                ; on a standard typewriter.

        cp $22                  ; but '@' is not - see below.
        jr z, K___CHAR          ; forward to K-@-CHAR if so

        cp $20                  ; '_' is the other one that fails
        ret nz                  ; return if not.

        ld a, $5F               ; substitute ASCII '_'
        ret                     ; return.


; ---

;; K-@-CHAR

K___CHAR:
        ld a, $40               ; substitute ASCII '@'
        ret                     ; return.



; ------------------------------------------------------------------------
;   The Spectrum Input character keys. One or two are abbreviated.
;   From $00 Flash 0 to $FF COPY. The routine above has decoded all these.

;  | 00 Fl0| 01 Fl1| 02 Br0| 03 Br1| 04 In0| 05 In1| 06 CAP| 07 EDT|
;  | 08 LFT| 09 RIG| 0A DWN| 0B UP | 0C DEL| 0D ENT| 0E SYM| 0F GRA|
;  | 10 Ik0| 11 Ik1| 12 Ik2| 13 Ik3| 14 Ik4| 15 Ik5| 16 Ik6| 17 Ik7|
;  | 18 Pa0| 19 Pa1| 1A Pa2| 1B Pa3| 1C Pa4| 1D Pa5| 1E Pa6| 1F Pa7|
;  | 20 SP | 21  ! | 22  " | 23  # | 24  $ | 25  % | 26  & | 27  ' |
;  | 28  ( | 29  ) | 2A  * | 2B  + | 2C  , | 2D  - | 2E  . | 2F  / |
;  | 30  0 | 31  1 | 32  2 | 33  3 | 34  4 | 35  5 | 36  6 | 37  7 |
;  | 38  8 | 39  9 | 3A  : | 3B  ; | 3C  < | 3D  = | 3E  > | 3F  ? |
;  | 40  @ | 41  A | 42  B | 43  C | 44  D | 45  E | 46  F | 47  G |
;  | 48  H | 49  I | 4A  J | 4B  K | 4C  L | 4D  M | 4E  N | 4F  O |
;  | 50  P | 51  Q | 52  R | 53  S | 54  T | 55  U | 56  V | 57  W |
;  | 58  X | 59  Y | 5A  Z | 5B  [ | 5C  \ | 5D  ] | 5E  ^ | 5F  _ |
;  | 60  £ | 61  a | 62  b | 63  c | 64  d | 65  e | 66  f | 67  g |
;  | 68  h | 69  i | 6A  j | 6B  k | 6C  l | 6D  m | 6E  n | 6F  o |
;  | 70  p | 71  q | 72  r | 73  s | 74  t | 75  u | 76  v | 77  w |
;  | 78  x | 79  y | 7A  z | 7B  { | 7C  | | 7D  } | 7E  ~ | 7F  © |
;  | 80 128| 81 129| 82 130| 83 131| 84 132| 85 133| 86 134| 87 135|
;  | 88 136| 89 137| 8A 138| 8B 139| 8C 140| 8D 141| 8E 142| 8F 143|
;  | 90 [A]| 91 [B]| 92 [C]| 93 [D]| 94 [E]| 95 [F]| 96 [G]| 97 [H]|
;  | 98 [I]| 99 [J]| 9A [K]| 9B [L]| 9C [M]| 9D [N]| 9E [O]| 9F [P]|
;  | A0 [Q]| A1 [R]| A2 [S]| A3 [T]| A4 [U]| A5 RND| A6 IK$| A7 PI |
;  | A8 FN | A9 PNT| AA SC$| AB ATT| AC AT | AD TAB| AE VL$| AF COD|
;  | B0 VAL| B1 LEN| B2 SIN| B3 COS| B4 TAN| B5 ASN| B6 ACS| B7 ATN|
;  | B8 LN | B9 EXP| BA INT| BB SQR| BC SGN| BD ABS| BE PEK| BF IN |
;  | C0 USR| C1 ST$| C2 CH$| C3 NOT| C4 BIN| C5 OR | C6 AND| C7 <= |
;  | C8 >= | C9 <> | CA LIN| CB THN| CC TO | CD STP| CE DEF| CF CAT|
;  | D0 FMT| D1 MOV| D2 ERS| D3 OPN| D4 CLO| D5 MRG| D6 VFY| D7 BEP|
;  | D8 CIR| D9 INK| DA PAP| DB FLA| DC BRI| DD INV| DE OVR| DF OUT|
;  | E0 LPR| E1 LLI| E2 STP| E3 REA| E4 DAT| E5 RES| E6 NEW| E7 BDR|
;  | E8 CON| E9 DIM| EA REM| EB FOR| EC GTO| ED GSB| EE INP| EF LOA|
;  | F0 LIS| F1 LET| F2 PAU| F3 NXT| F4 POK| F5 PRI| F6 PLO| F7 RUN|
;  | F8 SAV| F9 RAN| FA IF | FB CLS| FC DRW| FD CLR| FE RET| FF CPY|

;   Note that for simplicity, Sinclair have located all the control codes
;   below the space character.
;   ASCII DEL, $7F, has been made a copyright symbol.
;   Also $60, '`', not used in BASIC but used in other languages, has been
;   allocated the local currency symbol for the relevant country -
;    £  in most Spectrums.

; ------------------------------------------------------------------------


;**********************************
;** Part 3. LOUDSPEAKER ROUTINES **
;**********************************

; Documented by Alvin Albrecht.

; ------------------------------
; Routine to control loudspeaker
; ------------------------------
; Outputs a square wave of given duration and frequency
; to the loudspeaker.
;   Enter with: DE = #cycles - 1
;               HL = tone period as described next
;
; The tone period is measured in T states and consists of
; three parts: a coarse part (H register), a medium part
; (bits 7..2 of L) and a fine part (bits 1..0 of L) which
; contribute to the waveform timing as follows:
;
;                          coarse    medium       fine
; duration of low  = 118 + 1024*H + 16*(L>>2) + 4*(L&0x3)
; duration of hi   = 118 + 1024*H + 16*(L>>2) + 4*(L&0x3)
; Tp = tone period = 236 + 2048*H + 32*(L>>2) + 8*(L&0x3)
;                  = 236 + 2048*H + 8*L = 236 + 8*HL
;
; As an example, to output five seconds of middle C (261.624 Hz):
;   (a) Tone period = 1/261.624 = 3.822ms
;   (b) Tone period in T-States = 3.822ms*fCPU = 13378
;         where fCPU = clock frequency of the CPU = 3.5MHz
;    ©  Find H and L for desired tone period:
;         HL = (Tp - 236) / 8 = (13378 - 236) / 8 = 1643 = 0x066B
;   (d) Tone duration in cycles = 5s/3.822ms = 1308 cycles
;         DE = 1308 - 1 = 0x051B
;
; The resulting waveform has a duty ratio of exactly 50%.
;
;
;; BEEPER

BEEPER:
        di                      ; Disable Interrupts so they don't disturb timing
        ld a, l
        srl l
        srl l                   ; L = medium part of tone period
        cpl
        and $03                 ; A = 3 - fine part of tone period
        ld c, a
        ld b, $00
        ld ix, BE_IX_3          ; Address: BE-IX+3
        add ix, bc              ;   IX holds address of entry into the loop
                                ;   the loop will contain 0-3 NOPs, implementing
                                ;   the fine part of the tone period.
        ld a, (BORDCR)          ; BORDCR
        and $38                 ; bits 5..3 contain border colour
        rrca                    ; border colour bits moved to 2..0
        rrca                    ;   to match border bits on port #FE
        rrca
        or $08                  ; bit 3 set (tape output bit on port #FE)
                                ;   for loud sound output
                                ; ; BE-IX+3

BE_IX_3:
        nop                     ; (4)   ; optionally executed NOPs for small
                                ;   adjustments to tone period
                                ; ; BE-IX+2

BE_IX_2:
        nop                     ; (4)   ;

;; BE-IX+1

BE_IX_1:
        nop                     ; (4)   ;

;; BE-IX+0

BE_IX_0:
        inc b                   ; (4)   ;
        inc c                   ; (4)   ;

;; BE-H&L-LP

BE_H_L_LP:
        dec c                   ; (4)   ; timing loop for duration of
        jr nz, BE_H_L_LP        ; (12/7);   high or low pulse of waveform

        ld c, $3F               ; (7)   ;
        dec b                   ; (4)   ;
        jp nz, BE_H_L_LP        ; (10)  ; to BE-H&L-LP

        xor $10                 ; (7)   ; toggle output beep bit
        out ($FE), a            ; (11)  ; output pulse
        ld b, h                 ; (4)   ; B = coarse part of tone period
        ld c, a                 ; (4)   ; save port #FE output byte
        bit 4, a                ; (8)   ; if new output bit is high, go
        jr nz, BE_AGAIN         ; (12/7);   to BE-AGAIN

        ld a, d                 ; (4)   ; one cycle of waveform has completed
        or e                    ; (4)   ;   (low->low). if cycle countdown = 0
        jr z, BE_END            ; (12/7);   go to BE-END

        ld a, c                 ; (4)   ; restore output byte for port #FE
        ld c, l                 ; (4)   ; C = medium part of tone period
        dec de                  ; (6)   ; decrement cycle count
        jp (ix)                 ; (8)   ; do another cycle


;; BE-AGAIN                     ; halfway through cycle

BE_AGAIN:
        ld c, l                 ; (4)   ; C = medium part of tone period
        inc c                   ; (4)   ; adds 16 cycles to make duration of high = duration of low
        jp (ix)                 ; (8)   ; do high pulse of tone


;; BE-END

BE_END:
        ei                      ; Enable Interrupts
        ret



; ------------------
; THE 'BEEP' COMMAND
; ------------------
; BASIC interface to BEEPER subroutine.
; Invoked in BASIC with:
;   BEEP dur, pitch
;   where dur   = duration in seconds
;         pitch = # of semitones above/below middle C
;
; Enter with: pitch on top of calculator stack
;             duration next on calculator stack
;
;; beep

beep:
        rst $28                 ; ; FP-CALC
        defb $31                ; ;duplicate                  ; duplicate pitch
        defb $27                ; ;int                        ; convert to integer
        defb $C0                ; ;st-mem-0                   ; store integer pitch to memory 0
        defb $03                ; ;subtract                   ; calculate fractional part of pitch = fp_pitch - int_pitch
        defb $34                ; ;stk-data                   ; push constant
        defb $EC                ; ;Exponent: $7C, Bytes: 4    ; constant = 0.05762265
        defb $6C, $98, $1F, $F5 ; ;($6C,$98,$1F,$F5)
        defb $04                ; ;multiply                   ; compute:
        defb $A1                ; ;stk-one                    ; 1 + 0.05762265 * fraction_part(pitch)
        defb $0F                ; ;addition
        defb $38                ; ;end-calc                   ; leave on calc stack

        ld hl, MEMBOT           ; MEM-0: number stored here is in 16 bit integer format (pitch)
                                ;   0, 0/FF (pos/neg), LSB, MSB, 0
                                ;   LSB/MSB is stored in two's complement
                                ; In the following, the pitch is checked if it is in the range -128<=p<=127
        ld a, (hl)              ; First byte must be zero, otherwise
        and a                   ;   error in integer conversion
        jr nz, REPORT_B         ; to REPORT-B

        inc hl
        ldi c, (hl)             ; C = pos/neg flag = 0/FF
        ld b, (hl)              ; B = LSB, two's complement
        ld a, b
        rla
        sbc a, a                ; A = 0/FF if B is pos/neg
        cp c                    ; must be the same as C if the pitch is -128<=p<=127
        jr nz, REPORT_B         ; if no, error REPORT-B

        inc hl                  ; if -128<=p<=127, MSB will be 0/FF if B is pos/neg
        cp (hl)                 ; verify this
        jr nz, REPORT_B         ; if no, error REPORT-B
                                ; now we know -128<=p<=127
        ld a, b                 ; A = pitch + 60
        add a, $3C              ; if -60<=pitch<=67,
        jp p, BE_I_OK           ;   goto BE-i-OK

        jp po, REPORT_B         ; if pitch <= 67 goto REPORT-B
                                ;   lower bound of pitch set at -60

;; BE-I-OK                      ; here, -60<=pitch<=127
                                ; and A=pitch+60 -> 0<=A<=187


BE_I_OK:
        ld b, $FA               ; 6 octaves below middle C

;; BE-OCTAVE                    ; A=# semitones above 5 octaves below middle C

BE_OCTAVE:
        inc b                   ; increment octave
        sub $0C                 ; 12 semitones = one octave
        jr nc, BE_OCTAVE        ; to BE-OCTAVE

        add a, $0C              ; A = # semitones above C (0-11)
        push bc                 ; B = octave displacement from middle C, 2's complement: -5<=B<=10
        ld hl, semi_tone        ; Address: semi-tone
        call LOC_MEM            ; routine LOC-MEM
                                ;   HL = 5*A + $046E
        call STACK_NUM          ; routine STACK-NUM
                                ;   read FP value (freq) from semitone table (HL) and push onto calc stack

        rst $28                 ; ; FP-CALC
        defb $04                ; ;multiply   mult freq by 1 + 0.0576 * fraction_part(pitch) stacked earlier
                                ; ;             thus taking into account fractional part of pitch.
                                ; ;           the number 0.0576*frequency is the distance in Hz to the next
                                ; ;             note (verify with the frequencies recorded in the semitone
                                ; ;             table below) so that the fraction_part of the pitch does
                                ; ;             indeed represent a fractional distance to the next note.
        defb $38                ; ;end-calc   HL points to first byte of fp num on stack = middle frequency to generate

        pop af                  ; A = octave displacement from middle C, 2's complement: -5<=A<=10
        add a, (hl)             ; increase exponent by A (equivalent to multiplying by 2^A)
        ld (hl), a

        rst $28                 ; ; FP-CALC
        defb $C0                ; ;st-mem-0          ; store frequency in memory 0
        defb $02                ; ;delete            ; remove from calc stack
        defb $31                ; ;duplicate         ; duplicate duration (seconds)
        defb $38                ; ;end-calc

        call FIND_INT1          ; routine FIND-INT1 ; FP duration to A
        cp $0B                  ; if dur > 10 seconds,
        jr nc, REPORT_B         ;   goto REPORT-B

        ;;; The following calculation finds the tone period for HL and the cycle count
        ;;; for DE expected in the BEEPER subroutine.  From the example in the BEEPER comments,
        ;;;
        ;;; HL = ((fCPU / f) - 236) / 8 = fCPU/8/f - 236/8 = 437500/f -29.5
        ;;; DE = duration * frequency - 1
        ;;;
        ;;; Note the different constant (30.125) used in the calculation of HL
        ;;; below.  This is probably an error.

        rst $28                 ; ; FP-CALC
        defb $E0                ; ;get-mem-0                 ; push frequency
        defb $04                ; ;multiply                  ; result1: #cycles = duration * frequency
        defb $E0                ; ;get-mem-0                 ; push frequency
        defb $34                ; ;stk-data                  ; push constant
        defb $80                ; ;Exponent $93, Bytes: 3    ; constant = 437500
        defb $43, $55, $9F, $80 ; ;($55,$9F,$80,$00)
        defb $01                ; ;exchange                  ; frequency on top
        defb $05                ; ;division                  ; 437500 / frequency
        defb $34                ; ;stk-data                  ; push constant
        defb $35                ; ;Exponent: $85, Bytes: 1   ; constant = 30.125
        defb $71                ; ;($71,$00,$00,$00)
        defb $03                ; ;subtract                  ; result2: tone_period(HL) = 437500 / freq - 30.125
        defb $38                ; ;end-calc

        call FIND_INT2          ; routine FIND-INT2
        push bc                 ;   BC = tone_period(HL)
        call FIND_INT2          ; routine FIND-INT2, BC = #cycles to generate
        pop hl                  ; HL = tone period
        ld de, bc               ; DE = #cycles
        ld a, d
        or e
        ret z                   ; if duration = 0, skip BEEP and avoid 65536 cycle
                                ;   boondoggle that would occur next
        dec de                  ; DE = #cycles - 1
        jp BEEPER               ; to BEEPER


; ---


;; REPORT-B

REPORT_B:
        rst $08                 ; ERROR-1
        defb $0A                ; Error Report: Integer out of range



; ---------------------
; THE 'SEMI-TONE' TABLE
; ---------------------
;
;   Holds frequencies corresponding to semitones in middle octave.
;   To move n octaves higher or lower, frequencies are multiplied by 2^n.

;; semi-tone         five byte fp         decimal freq     note (middle)

semi_tone:
        defb $89, $02, $D0, $12, $86
                                ;  261.625565290         C
        defb $89, $0A, $97, $60, $75
                                ;  277.182631135         C#
        defb $89, $12, $D5, $17, $1F
                                ;  293.664768100         D
        defb $89, $1B, $90, $41, $02
                                ;  311.126983881         D#
        defb $89, $24, $D0, $53, $CA
                                ;  329.627557039         E
        defb $89, $2E, $9D, $36, $B1
                                ;  349.228231549         F
        defb $89, $38, $FF, $49, $3E
                                ;  369.994422674         F#
        defb $89, $43, $FF, $6A, $73
                                ;  391.995436072         G
        defb $89, $4F, $A7, $00, $54
                                ;  415.304697513         G#
        defb $89, $5C, $00, $00, $00
                                ;  440.000000000         A
        defb $89, $69, $14, $F6, $24
                                ;  466.163761616         A#
        defb $89, $76, $F1, $10, $05
                                ;  493.883301378         B


;   "Music is the hidden mathematical endeavour of a soul unconscious it 
;    is calculating" - Gottfried Wilhelm Liebnitz 1646 - 1716


;****************************************
;** Part 4. CASSETTE HANDLING ROUTINES **
;****************************************

;   These routines begin with the service routines followed by a single
;   command entry point.
;   The first of these service routines is a curiosity.

; -----------------------
; THE 'ZX81 NAME' ROUTINE
; -----------------------
;   This routine fetches a filename in ZX81 format and is not used by the 
;   cassette handling routines in this ROM.

;; zx81-name

zx81_name:
        call SCANNING           ; routine SCANNING to evaluate expression.
        ld a, (FLAGS)           ; fetch system variable FLAGS.
        add a, a                ; test bit 7 - syntax, bit 6 - result type.
        jp m, REPORT_C          ; to REPORT-C if not string result
                                ; 'Nonsense in BASIC'.

        pop hl                  ; drop return address.
        ret nc                  ; return early if checking syntax.

        push hl                 ; re-save return address.
        call STK_FETCH          ; routine STK-FETCH fetches string parameters.
        ld hl, de               ; transfer start of filename
                                ; to the HL register.
        dec c                   ; adjust to point to last character and
        ret m                   ; return if the null string.
                                ; or multiple of 256!

        add hl, bc              ; find last character of the filename.
                                ; and also clear carry.
        set 7, (hl)             ; invert it.
        ret                     ; return.


; =========================================
;
; PORT 254 ($FE)
;
;                      spk mic { border  }  
;          ___ ___ ___ ___ ___ ___ ___ ___ 
; PORT    |   |   |   |   |   |   |   |   |
; 254     |   |   |   |   |   |   |   |   |
; $FE     |___|___|___|___|___|___|___|___|
;           7   6   5   4   3   2   1   0
;

; ----------------------------------
; Save header and program/data bytes
; ----------------------------------
;   This routine saves a section of data. It is called from SA-CTRL to save the
;   seventeen bytes of header data. It is also the exit route from that routine
;   when it is set up to save the actual data.
;   On entry -
;   HL points to start of data.
;   IX points to descriptor.
;   The accumulator is set to  $00 for a header, $FF for data.

;; SA-BYTES

SA_BYTES:
        ld hl, SA_LD_RET        ; address: SA/LD-RET
        push hl                 ; is pushed as common exit route.
                                ; however there is only one non-terminal exit
                                ; point.

        ld hl, $1F80            ; a timing constant H=$1F, L=$80
                                ; inner and outer loop counters
                                ; a five second lead-in is used for a header.

        bit 7, a                ; test one bit of accumulator.
                                ; (AND A ?)
        jr z, SA_FLAG           ; skip to SA-FLAG if a header is being saved.

;   else is data bytes and a shorter lead-in is used.

        ld hl, $0C98            ; another timing value H=$0C, L=$98.
                                ; a two second lead-in is used for the data.


;; SA-FLAG

SA_FLAG:
        ex af, af'              ; save flag
        inc de                  ; increase length by one.
        dec ix                  ; decrease start.

        di                      ; disable interrupts

        ld a, $02               ; select red for border, microphone bit on.
        ld b, a                 ; also does as an initial slight counter value.

;; SA-LEADER

SA_LEADER:
        djnz SA_LEADER          ; self loop to SA-LEADER for delay.
                                ; after initial loop, count is $A4 (or $A3)

        out ($FE), a            ; output byte $02/$0D to tape port.

        xor $0F                 ; switch from RED (mic on) to CYAN (mic off).

        ld b, $A4               ; hold count. also timed instruction.

        dec l                   ; originally $80 or $98.
                                ; but subsequently cycles 256 times.
        jr nz, SA_LEADER        ; back to SA-LEADER until L is zero.

;   the outer loop is counted by H

        dec b                   ; decrement count
        dec h                   ; originally  twelve or thirty-one.
        jp p, SA_LEADER         ; back to SA-LEADER until H becomes $FF

;   now send a sync pulse. At this stage mic is off and A holds value
;   for mic on.
;   A sync pulse is much shorter than the steady pulses of the lead-in.

        ld b, $2F               ; another short timed delay.

;; SA-SYNC-1

SA_SYNC_1:
        djnz SA_SYNC_1          ; self loop to SA-SYNC-1

        out ($FE), a            ; switch to mic on and red.
        ld a, $0D               ; prepare mic off - cyan
        ld b, $37               ; another short timed delay.

;; SA-SYNC-2

SA_SYNC_2:
        djnz SA_SYNC_2          ; self loop to SA-SYNC-2

        out ($FE), a            ; output mic off, cyan border.
        ld bc, $3B0E            ; B=$3B time(*), C=$0E, YELLOW, MIC OFF.

; 

        ex af, af'              ; restore saved flag
                                ; which is 1st byte to be saved.

        ld l, a                 ; and transfer to L.
                                ; the initial parity is A, $FF or $00.
        jp SA_START             ; JUMP forward to SA-START     ->
                                ; the mid entry point of loop.


; -------------------------
;   During the save loop a parity byte is maintained in H.
;   the save loop begins by testing if reduced length is zero and if so
;   the final parity byte is saved reducing count to $FFFF.

;; SA-LOOP

SA_LOOP:
        ld a, d                 ; fetch high byte
        or e                    ; test against low byte.
        jr z, SA_PARITY         ; forward to SA-PARITY if zero.

        ld l, (ix)              ; load currently addressed byte to L.

;; SA-LOOP-P

SA_LOOP_P:
        ld a, h                 ; fetch parity byte.
        xor l                   ; exclusive or with new byte.

; -> the mid entry point of loop.

;; SA-START

SA_START:
        ld h, a                 ; put parity byte in H.
        ld a, $01               ; prepare blue, mic=on.
        scf                     ; set carry flag ready to rotate in.
        jp SA_8_BITS            ; JUMP forward to SA-8-BITS            -8->


; ---

;; SA-PARITY

SA_PARITY:
        ld l, h                 ; transfer the running parity byte to L and
        jr SA_LOOP_P            ; back to SA-LOOP-P
                                ; to output that byte before quitting normally.


; ---

;   The entry point to save yellow part of bit.
;   A bit consists of a period with mic on and blue border followed by 
;   a period of mic off with yellow border. 
;   Note. since the DJNZ instruction does not affect flags, the zero flag is 
;   used to indicate which of the two passes is in effect and the carry 
;   maintains the state of the bit to be saved.

;; SA-BIT-2

SA_BIT_2:
        ld a, c                 ; fetch 'mic on and yellow' which is
                                ; held permanently in C.
        bit 7, b                ; set the zero flag. B holds $3E.

;   The entry point to save 1 entire bit. For first bit B holds $3B(*).
;   Carry is set if saved bit is 1. zero is reset NZ on entry.

;; SA-BIT-1

SA_BIT_1:
        djnz SA_BIT_1           ; self loop for delay to SA-BIT-1

        jr nc, SA_OUT           ; forward to SA-OUT if bit is 0.

;   but if bit is 1 then the mic state is held for longer.

        ld b, $42               ; set timed delay. (66 decimal)

;; SA-SET

SA_SET:
        djnz SA_SET             ; self loop to SA-SET
                                ; (roughly an extra 66*13 clock cycles)

;; SA-OUT

SA_OUT:
        out ($FE), a            ; blue and mic on OR  yellow and mic off.

        ld b, $3E               ; set up delay
        jr nz, SA_BIT_2         ; back to SA-BIT-2 if zero reset NZ (first pass)

;   proceed when the blue and yellow bands have been output.

        dec b                   ; change value $3E to $3D.
        xor a                   ; clear carry flag (ready to rotate in).
        inc a                   ; reset zero flag i.e. NZ.

; -8-> 

;; SA-8-BITS

SA_8_BITS:
        rl l                    ; rotate left through carry
                                ; C<76543210<C
        jp nz, SA_BIT_1         ; JUMP back to SA-BIT-1
                                ; until all 8 bits done.

;   when the initial set carry is passed out again then a byte is complete.

        dec de                  ; decrease length
        inc ix                  ; increase byte pointer
        ld b, $31               ; set up timing.

        ld a, $7F               ; test the space key and
        in a, ($FE)             ; return to common exit (to restore border)
        rra                     ; if a space is pressed
        ret nc                  ; return to SA/LD-RET.   - - >

;   now test if byte counter has reached $FFFF.

        ld a, d                 ; fetch high byte
        inc a                   ; increment.
        jp nz, SA_LOOP          ; JUMP to SA-LOOP if more bytes.

        ld b, $3B               ; a final delay.

;; SA-DELAY

SA_DELAY:
        djnz SA_DELAY           ; self loop to SA-DELAY

        ret                     ; return - - >


; ------------------------------
; THE 'SAVE/LOAD RETURN' ROUTINE
; ------------------------------
;   The address of this routine is pushed on the stack prior to any load/save
;   operation and it handles normal completion with the restoration of the
;   border and also abnormal termination when the break key, or to be more
;   precise the space key is pressed during a tape operation.
;
; - - >

;; SA/LD-RET

SA_LD_RET:
        push af                 ; preserve accumulator throughout.
        ld a, (BORDCR)          ; fetch border colour from BORDCR.
        and $38                 ; mask off paper bits.
        rrca                    ; rotate
        rrca                    ; to the
        rrca                    ; range 0-7.

        out ($FE), a            ; change the border colour.

        ld a, $7F               ; read from port address $7FFE the
        in a, ($FE)             ; row with the space key at outside.
 
        rra                     ; test for space key pressed.
        ei                      ; enable interrupts
        jr c, SA_LD_END         ; forward to SA/LD-END if not


;; REPORT-Da

REPORT_Da:
        rst $08                 ; ERROR-1
        defb $0C                ; Error Report: BREAK - CONT repeats

; ---

;; SA/LD-END

SA_LD_END:
        pop af                  ; restore the accumulator.
        ret                     ; return.


; ------------------------------------
; Load header or block of information
; ------------------------------------
;   This routine is used to load bytes and on entry A is set to $00 for a 
;   header or to $FF for data.  IX points to the start of receiving location 
;   and DE holds the length of bytes to be loaded. If, on entry the carry flag 
;   is set then data is loaded, if reset then it is verified.

;; LD-BYTES

LD_BYTES:
        inc d                   ; reset the zero flag without disturbing carry.
        ex af, af'              ; preserve entry flags.
        dec d                   ; restore high byte of length.

        di                      ; disable interrupts

        ld a, $0F               ; make the border white and mic off.
        out ($FE), a            ; output to port.

        ld hl, SA_LD_RET        ; Address: SA/LD-RET
        push hl                 ; is saved on stack as terminating routine.

;   the reading of the EAR bit (D6) will always be preceded by a test of the 
;   space key (D0), so store the initial post-test state.

        in a, ($FE)             ; read the ear state - bit 6.
        rra                     ; rotate to bit 5.
        and $20                 ; isolate this bit.
        or $02                  ; combine with red border colour.
        ld c, a                 ; and store initial state long-term in C.
        cp a                    ; set the zero flag.

; 

;; LD-BREAK

LD_BREAK:
        ret nz                  ; return if at any time space is pressed.

;; LD-START

LD_START:
        call LD_EDGE_1          ; routine LD-EDGE-1
        jr nc, LD_BREAK         ; back to LD-BREAK with time out and no
                                ; edge present on tape.

;   but continue when a transition is found on tape.

        ld hl, $0415            ; set up 16-bit outer loop counter for
                                ; approx 1 second delay.

;; LD-WAIT

LD_WAIT:
        djnz LD_WAIT            ; self loop to LD-WAIT (for 256 times)

        dec hl                  ; decrease outer loop counter.
        ld a, h                 ; test for
        or l                    ; zero.
        jr nz, LD_WAIT          ; back to LD-WAIT, if not zero, with zero in B.

;   continue after delay with H holding zero and B also.
;   sample 256 edges to check that we are in the middle of a lead-in section. 

        call LD_EDGE_2          ; routine LD-EDGE-2
        jr nc, LD_BREAK         ; back to LD-BREAK
                                ; if no edges at all.

;; LD-LEADER

LD_LEADER:
        ld b, $9C               ; set timing value.
        call LD_EDGE_2          ; routine LD-EDGE-2
        jr nc, LD_BREAK         ; back to LD-BREAK if time-out

        ld a, $C6               ; two edges must be spaced apart.
        cp b                    ; compare
        jr nc, LD_START         ; back to LD-START if too close together for a
                                ; lead-in.

        inc h                   ; proceed to test 256 edged sample.
        jr nz, LD_LEADER        ; back to LD-LEADER while more to do.

;   sample indicates we are in the middle of a two or five second lead-in.
;   Now test every edge looking for the terminal sync signal.

;; LD-SYNC

LD_SYNC:
        ld b, $C9               ; initial timing value in B.
        call LD_EDGE_1          ; routine LD-EDGE-1
        jr nc, LD_BREAK         ; back to LD-BREAK with time-out.

        ld a, b                 ; fetch augmented timing value from B.
        cp $D4                  ; compare
        jr nc, LD_SYNC          ; back to LD-SYNC if gap too big, that is,
                                ; a normal lead-in edge gap.

;   but a short gap will be the sync pulse.
;   in which case another edge should appear before B rises to $FF

        call LD_EDGE_1          ; routine LD-EDGE-1
        ret nc                  ; return with time-out.

; proceed when the sync at the end of the lead-in is found.
; We are about to load data so change the border colours.

        ld a, c                 ; fetch long-term mask from C
        xor $03                 ; and make blue/yellow.

        ld c, a                 ; store the new long-term byte.

        ld h, $00               ; set up parity byte as zero.
        ld b, $B0               ; timing.
        jr LD_MARKER            ; forward to LD-MARKER
                                ; the loop mid entry point with the alternate
                                ; zero flag reset to indicate first byte
                                ; is discarded.


; --------------
;   the loading loop loads each byte and is entered at the mid point.

;; LD-LOOP

LD_LOOP:
        ex af, af'              ; restore entry flags and type in A.
        jr nz, LD_FLAG          ; forward to LD-FLAG if awaiting initial flag
                                ; which is to be discarded.

        jr nc, LD_VERIFY        ; forward to LD-VERIFY if not to be loaded.

        ld (ix), l              ; place loaded byte at memory location.
        jr LD_NEXT              ; forward to LD-NEXT


; ---

;; LD-FLAG

LD_FLAG:
        rl c                    ; preserve carry (verify) flag in long-term
                                ; state byte. Bit 7 can be lost.

        xor l                   ; compare type in A with first byte in L.
        ret nz                  ; return if no match e.g. CODE vs. DATA.

;   continue when data type matches.

        ld a, c                 ; fetch byte with stored carry
        rra                     ; rotate it to carry flag again
        ld c, a                 ; restore long-term port state.

        inc de                  ; increment length ??
        jr LD_DEC               ; forward to LD-DEC.
                                ; but why not to location after ?


; ---
;   for verification the byte read from tape is compared with that in memory.

;; LD-VERIFY

LD_VERIFY:
        ld a, (ix)              ; fetch byte from memory.
        xor l                   ; compare with that on tape
        ret nz                  ; return if not zero.

;; LD-NEXT

LD_NEXT:
        inc ix                  ; increment byte pointer.

;; LD-DEC

LD_DEC:
        dec de                  ; decrement length.
        ex af, af'              ; store the flags.
        ld b, $B2               ; timing.

;   when starting to read 8 bits the receiving byte is marked with bit at right.
;   when this is rotated out again then 8 bits have been read.

;; LD-MARKER

LD_MARKER:
        ld l, $01               ; initialize as %00000001

;; LD-8-BITS

LD_8_BITS:
        call LD_EDGE_2          ; routine LD-EDGE-2 increments B relative to
                                ; gap between 2 edges.
        ret nc                  ; return with time-out.

        ld a, $CB               ; the comparison byte.
        cp b                    ; compare to incremented value of B.
                                ; if B is higher then bit on tape was set.
                                ; if <= then bit on tape is reset.

        rl l                    ; rotate the carry bit into L.

        ld b, $B0               ; reset the B timer byte.
        jp nc, LD_8_BITS        ; JUMP back to LD-8-BITS

;   when carry set then marker bit has been passed out and byte is complete.

        ld a, h                 ; fetch the running parity byte.
        xor l                   ; include the new byte.
        ld h, a                 ; and store back in parity register.

        ld a, d                 ; check length of
        or e                    ; expected bytes.
        jr nz, LD_LOOP          ; back to LD-LOOP
                                ; while there are more.

;   when all bytes loaded then parity byte should be zero.

        ld a, h                 ; fetch parity byte.
        cp $01                  ; set carry if zero.
        ret                     ; return
                                ; in no carry then error as checksum disagrees.


; -------------------------
; Check signal being loaded
; -------------------------
;   An edge is a transition from one mic state to another.
;   More specifically a change in bit 6 of value input from port $FE.
;   Graphically it is a change of border colour, say, blue to yellow.
;   The first entry point looks for two adjacent edges. The second entry point
;   is used to find a single edge.
;   The B register holds a count, up to 256, within which the edge (or edges) 
;   must be found. The gap between two edges will be more for a '1' than a '0'
;   so the value of B denotes the state of the bit (two edges) read from tape.

; ->

;; LD-EDGE-2

LD_EDGE_2:
        call LD_EDGE_1          ; call routine LD-EDGE-1 below.
        ret nc                  ; return if space pressed or time-out.
                                ; else continue and look for another adjacent
                                ; edge which together represent a bit on the
                                ; tape.

; -> 
;   this entry point is used to find a single edge from above but also 
;   when detecting a read-in signal on the tape.

;; LD-EDGE-1

LD_EDGE_1:
        ld a, $16               ; a delay value of twenty two.

;; LD-DELAY

LD_DELAY:
        dec a                   ; decrement counter
        jr nz, LD_DELAY         ; loop back to LD-DELAY 22 times.

        and a                   ; clear carry.

;; LD-SAMPLE

LD_SAMPLE:
        inc b                   ; increment the time-out counter.
        ret z                   ; return with failure when $FF passed.

        ld a, $7F               ; prepare to read keyboard and EAR port
        in a, ($FE)             ; row $7FFE. bit 6 is EAR, bit 0 is SPACE key.
        rra                     ; test outer key the space. (bit 6 moves to 5)
        ret nc                  ; return if space pressed.  >>>

        xor c                   ; compare with initial long-term state.
        and $20                 ; isolate bit 5
        jr z, LD_SAMPLE         ; back to LD-SAMPLE if no edge.

;   but an edge, a transition of the EAR bit, has been found so switch the
;   long-term comparison byte containing both border colour and EAR bit. 

        ld a, c                 ; fetch comparison value.
        cpl                     ; switch the bits
        ld c, a                 ; and put back in C for long-term.

        and $07                 ; isolate new colour bits.
        or $08                  ; set bit 3 - MIC off.
        out ($FE), a            ; send to port to effect the change of colour.

        scf                     ; set carry flag signaling edge found within
                                ; time allowed.
        ret                     ; return.


; ---------------------------------
; Entry point for all tape commands
; ---------------------------------
;   This is the single entry point for the four tape commands.
;   The routine first determines in what context it has been called by examining
;   the low byte of the Syntax table entry which was stored in T_ADDR.
;   Subtracting $EO (the present arrangement) gives a value of
;   $00 - SAVE
;   $01 - LOAD
;   $02 - VERIFY
;   $03 - MERGE
;   As with all commands the address STMT-RET is on the stack.

;; SAVE-ETC

SAVE_ETC:
        pop af                  ; discard address STMT-RET.
        ld a, (T_ADDR)          ; fetch T_ADDR

;   Now reduce the low byte of the Syntax table entry to give command.
;   Note. For ZASM use SUB $E0 as next instruction.


L0609:
        sub +(P_SAVE + 1) % 256 ; subtract the known offset.
                                ; ( is SUB $E0 in standard ROM )

        ld (T_ADDR), a          ; and put back in T_ADDR as 0,1,2, or 3
                                ; for future reference.

        call EXPT_EXP           ; routine EXPT-EXP checks that a string
                                ; expression follows and stacks the
                                ; parameters in run-time.

        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, SA_DATA           ; forward to SA-DATA if checking syntax.

        ld bc, $0011            ; presume seventeen bytes for a header.
        ld a, (T_ADDR)          ; fetch command from T_ADDR.
        and a                   ; test for zero - SAVE.
        jr z, SA_SPACE          ; forward to SA-SPACE if so.

        ld c, $22               ; else double length to thirty four.

;; SA-SPACE

SA_SPACE:
        rst $30                 ; BC-SPACES creates 17/34 bytes in workspace.

        push de                 ; transfer the start of new space to
        pop ix                  ; the available index register.

;   ten spaces are required for the default filename but it is simpler to
;   overwrite the first file-type indicator byte as well.

        ld b, $0B               ; set counter to eleven.
        ld a, $20               ; prepare a space.

;; SA-BLANK

SA_BLANK:
        ldi (de), a             ; set workspace location to space.
                                ; next location.
        djnz SA_BLANK           ; loop back to SA-BLANK till all eleven done.

        ld (ix+$01), $FF        ; set first byte of ten character filename
                                ; to $FF as a default to signal null string.

        call STK_FETCH          ; routine STK-FETCH fetches the filename
                                ; parameters from the calculator stack.
                                ; length of string in BC.
                                ; start of string in DE.

        ld hl, $FFF6            ; prepare the value minus ten.
        dec bc                  ; decrement length.
                                ; ten becomes nine, zero becomes $FFFF.
        add hl, bc              ; trial addition.
        inc bc                  ; restore true length.
        jr nc, SA_NAME          ; forward to SA-NAME if length is one to ten.

;   the filename is more than ten characters in length or the null string.

        ld a, (T_ADDR)          ; fetch command from T_ADDR.
        and a                   ; test for zero - SAVE.
        jr nz, SA_NULL          ; forward to SA-NULL if not the SAVE command.

;   but no more than ten characters are allowed for SAVE.
;   The first ten characters of any other command parameter are acceptable.
;   Weird, but necessary, if saving to sectors.
;   Note. the golden rule that there are no restriction on anything is broken.

;; REPORT-Fa

REPORT_Fa:
        rst $08                 ; ERROR-1
        defb $0E                ; Error Report: Invalid file name

;   continue with LOAD, MERGE, VERIFY and also SAVE within ten character limit.

;; SA-NULL

SA_NULL:
        ld a, b                 ; test length of filename
        or c                    ; for zero.
        jr z, SA_DATA           ; forward to SA-DATA if so using the 255
                                ; indicator followed by spaces.

        ld bc, $000A            ; else trim length to ten.

;   other paths rejoin here with BC holding length in range 1 - 10.

;; SA-NAME

SA_NAME:
        ld hl, ix               ; push start of file descriptor.
                                ; and pop into HL.

        inc hl                  ; HL now addresses first byte of filename.
        ex de, hl               ; transfer destination address to DE, start
                                ; of string in command to HL.
        ldir                    ; copy up to ten bytes
                                ; if less than ten then trailing spaces follow.

;   the case for the null string rejoins here.

;; SA-DATA

SA_DATA:
        rst $18                 ; GET-CHAR
        cp $E4                  ; is character after filename the token 'DATA' ?
        jr nz, SA_SCR_          ; forward to SA-SCR$ to consider SCREEN$ if
                                ; not.

;   continue to consider DATA.

        ld a, (T_ADDR)          ; fetch command from T_ADDR
        cp $03                  ; is it 'VERIFY' ?
        jp z, REPORT_C          ; jump forward to REPORT-C if so.
                                ; 'Nonsense in BASIC'
                                ; VERIFY "d" DATA is not allowed.

;   continue with SAVE, LOAD, MERGE of DATA.

        rst $20                 ; NEXT-CHAR
        call LOOK_VARS          ; routine LOOK-VARS searches variables area
                                ; returning with carry reset if found or
                                ; checking syntax.
        set 7, c                ; this converts a simple string to a
                                ; string array. The test for an array or string
                                ; comes later.
        jr nc, SA_V_OLD         ; forward to SA-V-OLD if variable found.

        ld hl, $0000            ; set destination to zero as not fixed.
        ld a, (T_ADDR)          ; fetch command from T_ADDR
        dec a                   ; test for 1 - LOAD
        jr z, SA_V_NEW          ; forward to SA-V-NEW with LOAD DATA.
                                ; to load a new array.

;   otherwise the variable was not found in run-time with SAVE/MERGE.

;; REPORT-2a

REPORT_2a:
        rst $08                 ; ERROR-1
        defb $01                ; Error Report: Variable not found

;   continue with SAVE/LOAD  DATA

;; SA-V-OLD

SA_V_OLD:
        jp nz, REPORT_C         ; to REPORT-C if not an array variable.
                                ; or erroneously a simple string.
                                ; 'Nonsense in BASIC'


        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, SA_DATA_1         ; forward to SA-DATA-1 if checking syntax.

        inc hl                  ; step past single character variable name.
        ld a, (hl)              ; fetch low byte of length.
        ld (ix+$0B), a          ; place in descriptor.
        inc hl                  ; point to high byte.
        ld a, (hl)              ; and transfer that
        ld (ix+$0C), a          ; to descriptor.
        inc hl                  ; increase pointer within variable.

;; SA-V-NEW

SA_V_NEW:
        ld (ix+$0E), c          ; place character array name in  header.
        ld a, $01               ; default to type numeric.
        bit 6, c                ; test result from look-vars.
        jr z, SA_V_TYPE         ; forward to SA-V-TYPE if numeric.

        inc a                   ; set type to 2 - string array.

;; SA-V-TYPE

SA_V_TYPE:
        ld (ix), a              ; place type 0, 1 or 2 in descriptor.

;; SA-DATA-1

SA_DATA_1:
        ex de, hl               ; save var pointer in DE

        rst $20                 ; NEXT-CHAR
        cp $29                  ; is character ')' ?
        jr nz, SA_V_OLD         ; back if not to SA-V-OLD to report
                                ; 'Nonsense in BASIC'

        rst $20                 ; NEXT-CHAR advances character address.
        call CHECK_END          ; routine CHECK-END errors if not end of
                                ; the statement.

        ex de, hl               ; bring back variables data pointer.
        jp SA_ALL               ; jump forward to SA-ALL


; ---
;   the branch was here to consider a 'SCREEN$', the display file.

;; SA-SCR$

SA_SCR_:
        cp $AA                  ; is character the token 'SCREEN$' ?
        jr nz, SA_CODE          ; forward to SA-CODE if not.

        ld a, (T_ADDR)          ; fetch command from T_ADDR
        cp $03                  ; is it MERGE ?
        jp z, REPORT_C          ; jump to REPORT-C if so.
                                ; 'Nonsense in BASIC'

;   continue with SAVE/LOAD/VERIFY SCREEN$.

        rst $20                 ; NEXT-CHAR
        call CHECK_END          ; routine CHECK-END errors if not at end of
                                ; statement.

;   continue in runtime.

        ld (ix+$0B), $00        ; set descriptor length
        ld (ix+$0C), $1B        ; to $1b00 to include bitmaps and attributes.

        ld hl, $4000            ; set start to display file start.
        ld (ix+$0D), hl         ; place start in
                                ; the descriptor.
        jr SA_TYPE_3            ; forward to SA-TYPE-3


; ---
;   the branch was here to consider CODE.

;; SA-CODE

SA_CODE:
        cp $AF                  ; is character the token 'CODE' ?
        jr nz, SA_LINE          ; forward if not to SA-LINE to consider an
                                ; auto-started BASIC program.

        ld a, (T_ADDR)          ; fetch command from T_ADDR
        cp $03                  ; is it MERGE ?
        jp z, REPORT_C          ; jump forward to REPORT-C if so.
                                ; 'Nonsense in BASIC'


        rst $20                 ; NEXT-CHAR advances character address.
        call PR_ST_END          ; routine PR-ST-END checks if a carriage
                                ; return or ':' follows.
        jr nz, SA_CODE_1        ; forward to SA-CODE-1 if there are parameters.

        ld a, (T_ADDR)          ; else fetch the command from T_ADDR.
        and a                   ; test for zero - SAVE without a specification.
        jp z, REPORT_C          ; jump to REPORT-C if so.
                                ; 'Nonsense in BASIC'

;   for LOAD/VERIFY put zero on stack to signify handle at location saved from.

        call USE_ZERO           ; routine USE-ZERO
        jr SA_CODE_2            ; forward to SA-CODE-2


; ---

;   if there are more characters after CODE expect start and possibly length.

;; SA-CODE-1

SA_CODE_1:
        call EXPT_1NUM          ; routine EXPT-1NUM checks for numeric
                                ; expression and stacks it in run-time.

        rst $18                 ; GET-CHAR
        cp $2C                  ; does a comma follow ?
        jr z, SA_CODE_3         ; forward if so to SA-CODE-3

;   else allow saved code to be loaded to a specified address.

        ld a, (T_ADDR)          ; fetch command from T_ADDR.
        and a                   ; is the command SAVE which requires length ?
        jp z, REPORT_C          ; jump to REPORT-C if so.
                                ; 'Nonsense in BASIC'

;   the command LOAD code may rejoin here with zero stacked as start.

;; SA-CODE-2

SA_CODE_2:
        call USE_ZERO           ; routine USE-ZERO stacks zero for length.
        jr SA_CODE_4            ; forward to SA-CODE-4


; ---
;   the branch was here with SAVE CODE start, 

;; SA-CODE-3

SA_CODE_3:
        rst $20                 ; NEXT-CHAR advances character address.
        call EXPT_1NUM          ; routine EXPT-1NUM checks for expression
                                ; and stacks in run-time.

;   paths converge here and nothing must follow.

;; SA-CODE-4

SA_CODE_4:
        call CHECK_END          ; routine CHECK-END errors with extraneous
                                ; characters and quits if checking syntax.

;   in run-time there are two 16-bit parameters on the calculator stack.

        call FIND_INT2          ; routine FIND-INT2 gets length.
        ld (ix+$0B), bc         ; place length
                                ; in descriptor.
        call FIND_INT2          ; routine FIND-INT2 gets start.
        ld (ix+$0D), bc         ; place start
                                ; in descriptor.
        ld hl, bc               ; transfer the
                                ; start to HL also.

;; SA-TYPE-3

SA_TYPE_3:
        ld (ix), $03            ; place type 3 - code in descriptor.
        jr SA_ALL               ; forward to SA-ALL.


; ---
;   the branch was here with BASIC to consider an optional auto-start line
;   number.

;; SA-LINE

SA_LINE:
        cp $CA                  ; is character the token 'LINE' ?
        jr z, SA_LINE_1         ; forward to SA-LINE-1 if so.

;   else all possibilities have been considered and nothing must follow.

        call CHECK_END          ; routine CHECK-END

;   continue in run-time to save BASIC without auto-start.

        ld (ix+$0E), $80        ; place high line number in descriptor to
                                ; disable auto-start.
        jr SA_TYPE_0            ; forward to SA-TYPE-0 to save program.


; ---
;   the branch was here to consider auto-start.

;; SA-LINE-1

SA_LINE_1:
        ld a, (T_ADDR)          ; fetch command from T_ADDR
        and a                   ; test for SAVE.
        jp nz, REPORT_C         ; jump forward to REPORT-C with anything else.
                                ; 'Nonsense in BASIC'

; 

        rst $20                 ; NEXT-CHAR
        call EXPT_1NUM          ; routine EXPT-1NUM checks for numeric
                                ; expression and stacks in run-time.
        call CHECK_END          ; routine CHECK-END quits if syntax path.
        call FIND_INT2          ; routine FIND-INT2 fetches the numeric
                                ; expression.
        ld (ix+$0D), bc         ; place the auto-start
                                ; line number in the descriptor.

;   Note. this isn't checked, but is subsequently handled by the system.
;   If the user typed 40000 instead of 4000 then it won't auto-start
;   at line 4000, or indeed, at all.

;   continue to save program and any variables.

;; SA-TYPE-0

SA_TYPE_0:
        ld (ix), $00            ; place type zero - program in descriptor.
        ld hl, (E_LINE)         ; fetch E_LINE to HL.
        ld de, (PROG)           ; fetch PROG to DE.
        scf                     ; set carry flag to calculate from end of
                                ; variables E_LINE -1.
        sbc hl, de              ; subtract to give total length.

        ld (ix+$0B), hl         ; place total length
                                ; in descriptor.
        ld hl, (VARS)           ; load HL from system variable VARS
        sbc hl, de              ; subtract to give program length.
        ld (ix+$0F), hl         ; place length of program
                                ; in the descriptor.
        ex de, hl               ; start to HL, length to DE.

;; SA-ALL

SA_ALL:
        ld a, (T_ADDR)          ; fetch command from T_ADDR
        and a                   ; test for zero - SAVE.
        jp z, SA_CONTRL         ; jump forward to SA-CONTRL with SAVE  ->

; ---
;   continue with LOAD, MERGE and VERIFY.

        push hl                 ; save start.
        ld bc, $0011            ; prepare to add seventeen
        add ix, bc              ; to point IX at second descriptor.

;; LD-LOOK-H

LD_LOOK_H:
        push ix                 ; save IX
        ld de, $0011            ; seventeen bytes
        xor a                   ; reset zero flag
        scf                     ; set carry flag
        call LD_BYTES           ; routine LD-BYTES loads a header from tape
                                ; to second descriptor.
        pop ix                  ; restore IX.
        jr nc, LD_LOOK_H        ; loop back to LD-LOOK-H until header found.

        ld a, $FE               ; select system channel 'S'
        call CHAN_OPEN          ; routine CHAN-OPEN opens it.

        ld (iy+SCR_CT-IY0), $03 ; set SCR_CT to 3 lines.

        ld c, $80               ; C has bit 7 set to indicate type mismatch as
                                ; a default startpoint.

        ld a, (ix)              ; fetch loaded header type to A
        cp (ix-$11)             ; compare with expected type.
        jr nz, LD_TYPE          ; forward to LD-TYPE with mis-match.

        ld c, $F6               ; set C to minus ten - will count characters
                                ; up to zero.

;; LD-TYPE

LD_TYPE:
        cp $04                  ; check if type in acceptable range 0 - 3.
        jr nc, LD_LOOK_H        ; back to LD-LOOK-H with 4 and over.

;   else A indicates type 0-3.

        ld de, tape_msgs_2-$01  ; address base of last 4 tape messages
        push bc                 ; save BC
        call PO_MSG             ; routine PO-MSG outputs relevant message.
                                ; Note. all messages have a leading newline.
        pop bc                  ; restore BC

        push ix                 ; transfer IX,
        pop de                  ; the 2nd descriptor, to DE.
        ld hl, $FFF0            ; prepare minus seventeen.
        add hl, de              ; add to point HL to 1st descriptor.
        ld b, $0A               ; the count will be ten characters for the
                                ; filename.

        ld a, (hl)              ; fetch first character and test for
        inc a                   ; value 255.
        jr nz, LD_NAME          ; forward to LD-NAME if not the wildcard.

;   but if it is the wildcard, then add ten to C which is minus ten for a type
;   match or -128 for a type mismatch. Although characters have to be counted
;   bit 7 of C will not alter from state set here.

        ld a, c                 ; transfer $F6 or $80 to A
        add a, b                ; add $0A
        ld c, a                 ; place result, zero or -118, in C.

;   At this point we have either a type mismatch, a wildcard match or ten
;   characters to be counted. The characters must be shown on the screen.

;; LD-NAME

LD_NAME:
        inc de                  ; address next input character
        ld a, (de)              ; fetch character
        cp (hl)                 ; compare to expected
        inc hl                  ; address next expected character
        jr nz, LD_CH_PR         ; forward to LD-CH-PR with mismatch

        inc c                   ; increment matched character count

;; LD-CH-PR

LD_CH_PR:
        rst $10                 ; PRINT-A prints character
        djnz LD_NAME            ; loop back to LD-NAME for ten characters.

;   if ten characters matched and the types previously matched then C will 
;   now hold zero.

        bit 7, c                ; test if all matched
        jr nz, LD_LOOK_H        ; back to LD-LOOK-H if not

;   else print a terminal carriage return.

        ld a, $0D               ; prepare carriage return.
        rst $10                 ; PRINT-A outputs it.

;   The various control routines for LOAD, VERIFY and MERGE are executed 
;   during the one-second gap following the header on tape.

        pop hl                  ; restore xx
        ld a, (ix)              ; fetch incoming type
        cp $03                  ; compare with CODE
        jr z, VR_CONTRL         ; forward to VR-CONTRL if it is CODE.

;  type is a program or an array.

        ld a, (T_ADDR)          ; fetch command from T_ADDR
        dec a                   ; was it LOAD ?
        jp z, LD_CONTRL         ; JUMP forward to LD-CONTRL if so to
                                ; load BASIC or variables.

        cp $02                  ; was command MERGE ?
        jp z, ME_CONTRL         ; jump forward to ME-CONTRL if so.

;   else continue into VERIFY control routine to verify.

; ----------------------------
; THE 'VERIFY CONTROL' ROUTINE
; ----------------------------
;   There are two branches to this routine.
;   1) From above to verify a program or array
;   2) from earlier with no carry to load or verify code.

;; VR-CONTRL

VR_CONTRL:
        push hl                 ; save pointer to data.
        ld hl, (ix-$06)         ; fetch length of old data
                                ; to HL.
        ld de, (ix+$0B)         ; fetch length of new data
                                ; to DE.
        ld a, h                 ; check length of old
        or l                    ; for zero.
        jr z, VR_CONT_1         ; forward to VR-CONT-1 if length unspecified
                                ; e.g. LOAD "x" CODE

;   as opposed to, say, LOAD 'x' CODE 32768,300.

        sbc hl, de              ; subtract the two lengths.
        jr c, REPORT_R          ; forward to REPORT-R if the length on tape is
                                ; larger than that specified in command.
                                ; 'Tape loading error'

        jr z, VR_CONT_1         ; forward to VR-CONT-1 if lengths match.

;   a length on tape shorter than expected is not allowed for CODE

        ld a, (ix)              ; else fetch type from tape.
        cp $03                  ; is it CODE ?
        jr nz, REPORT_R         ; forward to REPORT-R if so
                                ; 'Tape loading error'

;; VR-CONT-1

VR_CONT_1:
        pop hl                  ; pop pointer to data
        ld a, h                 ; test for zero
        or l                    ; e.g. LOAD 'x' CODE
        jr nz, VR_CONT_2        ; forward to VR-CONT-2 if destination specified.

        ld hl, (ix+$0D)         ; else use the destination in the header
                                ; and load code at address saved from.

;; VR-CONT-2

VR_CONT_2:
        ld ix, hl               ; push pointer to start of data block.
                                ; transfer to IX.
        ld a, (T_ADDR)          ; fetch reduced command from T_ADDR
        cp $02                  ; is it VERIFY ?
        scf                     ; prepare a set carry flag
        jr nz, VR_CONT_3        ; skip to VR-CONT-3 if not

        and a                   ; clear carry flag for VERIFY so that
                                ; data is not loaded.

;; VR-CONT-3

VR_CONT_3:
        ld a, $FF               ; signal data block to be loaded

; -----------------
; Load a data block
; -----------------
;   This routine is called from 3 places other than above to load a data block.
;   In all cases the accumulator is first set to $FF so the routine could be 
;   called at the previous instruction.

;; LD-BLOCK

LD_BLOCK:
        call LD_BYTES           ; routine LD-BYTES
        ret c                   ; return if successful.


;; REPORT-R

REPORT_R:
        rst $08                 ; ERROR-1
        defb $1A                ; Error Report: Tape loading error

; --------------------------
; THE 'LOAD CONTROL' ROUTINE
; --------------------------
;   This branch is taken when the command is LOAD with type 0, 1 or 2. 

;; LD-CONTRL

LD_CONTRL:
        ld de, (ix+$0B)         ; fetch length of found data block
                                ; from 2nd descriptor.
        push hl                 ; save destination
        ld a, h                 ; test for zero
        or l
        jr nz, LD_CONT_1        ; forward if not to LD-CONT-1

        inc de                  ; increase length
        inc de                  ; for letter name
        inc de                  ; and 16-bit length
        ex de, hl               ; length to HL,
        jr LD_CONT_2            ; forward to LD-CONT-2


; ---

;; LD-CONT-1

LD_CONT_1:
        ld hl, (ix-$06)         ; fetch length from
                                ; the first header.
        ex de, hl
        scf                     ; set carry flag
        sbc hl, de
        jr c, LD_DATA           ; to LD-DATA

;; LD-CONT-2

LD_CONT_2:
        ld de, $0005            ; allow overhead of five bytes.
        add hl, de              ; add in the difference in data lengths.
        ld bc, hl               ; transfer to
                                ; the BC register pair
        call TEST_ROOM          ; routine TEST-ROOM fails if not enough room.

;; LD-DATA

LD_DATA:
        pop hl                  ; pop destination
        ld a, (ix)              ; fetch type 0, 1 or 2.
        and a                   ; test for program and variables.
        jr z, LD_PROG           ; forward if so to LD-PROG

;   the type is a numeric or string array.

        ld a, h                 ; test the destination for zero
        or l                    ; indicating variable does not already exist.
        jr z, LD_DATA_1         ; forward if so to LD-DATA-1

;   else the destination is the first dimension within the array structure

        dec hl                  ; address high byte of total length
        ldd b, (hl)             ; transfer to B.
                                ; address low byte of total length.
        ldd c, (hl)             ; transfer to C.
                                ; point to letter of variable.
        inc bc                  ; adjust length to
        inc bc                  ; include these
        inc bc                  ; three bytes also.
        ld (X_PTR), ix          ; save header pointer in X_PTR.
        call RECLAIM_2          ; routine RECLAIM-2 reclaims the old variable
                                ; sliding workspace including the two headers
                                ; downwards.
        ld ix, (X_PTR)          ; reload IX from X_PTR which will have been
                                ; adjusted down by POINTERS routine.

;; LD-DATA-1

LD_DATA_1:
        ld hl, (E_LINE)         ; address E_LINE
        dec hl                  ; now point to the $80 variables end-marker.
        ld bc, (ix+$0B)         ; fetch new data length
                                ; from 2nd header.
        push bc                 ; * save it.
        inc bc                  ; adjust the
        inc bc                  ; length to include
        inc bc                  ; letter name and total length.
        ld a, (ix-$03)          ; fetch letter name from old header.
        push af                 ; preserve accumulator though not corrupted.

        call MAKE_ROOM          ; routine MAKE-ROOM creates space for variable
                                ; sliding workspace up. IX no longer addresses
                                ; anywhere meaningful.
        inc hl                  ; point to first new location.

        pop af                  ; fetch back the letter name.
        ld (hl), a              ; place in first new location.
        pop de                  ; * pop the data length.
        inc hl                  ; address 2nd location
        ldi (hl), de            ; store low byte of length.
                                ; address next.
                                ; store high byte.
                                ; address start of data.
        ld ix, hl               ; transfer address
                                ; to IX register pair.
        scf                     ; set carry flag indicating load not verify.
        ld a, $FF               ; signal data not header.
        jp LD_BLOCK             ; JUMP back to LD-BLOCK


; -----------------
;   the branch is here when a program as opposed to an array is to be loaded.

;; LD-PROG

LD_PROG:
        ex de, hl               ; transfer dest to DE.
        ld hl, (E_LINE)         ; address E_LINE
        dec hl                  ; now variables end-marker.
        ld (X_PTR), ix          ; place the IX header pointer in X_PTR
        ld bc, (ix+$0B)         ; get new length
                                ; from 2nd header
        push bc                 ; and save it.

        call RECLAIM_1          ; routine RECLAIM-1 reclaims program and vars.
                                ; adjusting X-PTR.

        pop bc                  ; restore new length.
        push hl                 ; * save start
        push bc                 ; ** and length.

        call MAKE_ROOM          ; routine MAKE-ROOM creates the space.

        ld ix, (X_PTR)          ; reload IX from adjusted X_PTR
        inc hl                  ; point to start of new area.
        ld bc, (ix+$0F)         ; fetch length of BASIC on tape
                                ; from 2nd descriptor
        add hl, bc              ; add to address the start of variables.
        ld (VARS), hl           ; set system variable VARS

        ld h, (ix+$0E)          ; fetch high byte of autostart line number.
        ld a, h                 ; transfer to A
        and $C0                 ; test if greater than $3F.
        jr nz, LD_PROG_1        ; forward to LD-PROG-1 if so with no autostart.

        ld l, (ix+$0D)          ; else fetch the low byte.
        ld (NEWPPC), hl         ; set system variable to line number NEWPPC
        ld (iy+NSPPC-IY0), $00  ; set statement NSPPC to zero.

;; LD-PROG-1

LD_PROG_1:
        pop de                  ; ** pop the length
        pop ix                  ; * and start.
        scf                     ; set carry flag
        ld a, $FF               ; signal data as opposed to a header.
        jp LD_BLOCK             ; jump back to LD-BLOCK


; ---------------------------
; THE 'MERGE CONTROL' ROUTINE
; ---------------------------
;   the branch was here to merge a program and its variables or an array.
;

;; ME-CONTRL

ME_CONTRL:
        ld bc, (ix+$0B)         ; fetch length
                                ; of data block on tape.
        push bc                 ; save it.
        inc bc                  ; one for the pot.

        rst $30                 ; BC-SPACES creates room in workspace.
                                ; HL addresses last new location.
        ld (hl), $80            ; place end-marker at end.
        ex de, hl               ; transfer first location to HL.
        pop de                  ; restore length to DE.
        push hl                 ; save start.

        ld ix, hl               ; and transfer it
                                ; to IX register.
        scf                     ; set carry flag to load data on tape.
        ld a, $FF               ; signal data not a header.
        call LD_BLOCK           ; routine LD-BLOCK loads to workspace.
        pop hl                  ; restore first location in workspace to HL.

X08CE:
        ld de, (PROG)           ; set DE from system variable PROG.

;   now enter a loop to merge the data block in workspace with the program and 
;   variables. 

;; ME-NEW-LP

ME_NEW_LP:
        ld a, (hl)              ; fetch next byte from workspace.
        and $C0                 ; compare with $3F.
        jr nz, ME_VAR_LP        ; forward to ME-VAR-LP if a variable or
                                ; end-marker.

;   continue when HL addresses a BASIC line number.

;; ME-OLD-LP

ME_OLD_LP:
        ldi a, (de)             ; fetch high byte from program area.
                                ; bump prog address.
        cp (hl)                 ; compare with that in workspace.
        inc hl                  ; bump workspace address.
        jr nz, ME_OLD_L1        ; forward to ME-OLD-L1 if high bytes don't match

        ld a, (de)              ; fetch the low byte of program line number.
        cp (hl)                 ; compare with that in workspace.

;; ME-OLD-L1

ME_OLD_L1:
        dec de                  ; point to start of
        dec hl                  ; respective lines again.
        jr nc, ME_NEW_L2        ; forward to ME-NEW-L2 if line number in
                                ; workspace is less than or equal to current
                                ; program line as has to be added to program.

        push hl                 ; else save workspace pointer.
        ex de, hl               ; transfer prog pointer to HL
        call NEXT_ONE           ; routine NEXT-ONE finds next line in DE.
        pop hl                  ; restore workspace pointer
        jr ME_OLD_LP            ; back to ME-OLD-LP until destination position
                                ; in program area found.


; ---
;   the branch was here with an insertion or replacement point.

;; ME-NEW-L2

ME_NEW_L2:
        call ME_ENTER           ; routine ME-ENTER enters the line
        jr ME_NEW_LP            ; loop back to ME-NEW-LP.


; ---
;   the branch was here when the location in workspace held a variable.

;; ME-VAR-LP

ME_VAR_LP:
        ld a, (hl)              ; fetch first byte of workspace variable.
        ld c, a                 ; copy to C also.
        cp $80                  ; is it the end-marker ?
        ret z                   ; return if so as complete.  >>>>>

        push hl                 ; save workspace area pointer.
        ld hl, (VARS)           ; load HL with VARS - start of variables area.

;; ME-OLD-VP

ME_OLD_VP:
        ld a, (hl)              ; fetch first byte.
        cp $80                  ; is it the end-marker ?
        jr z, ME_VAR_L2         ; forward if so to ME-VAR-L2 to add
                                ; variable at end of variables area.

        cp c                    ; compare with variable in workspace area.
        jr z, ME_OLD_V2         ; forward to ME-OLD-V2 if a match to replace.

;   else entire variables area has to be searched.

;; ME-OLD-V1

ME_OLD_V1:
        push bc                 ; save character in C.
        call NEXT_ONE           ; routine NEXT-ONE gets following variable
                                ; address in DE.
        pop bc                  ; restore character in C
        ex de, hl               ; transfer next address to HL.
        jr ME_OLD_VP            ; loop back to ME-OLD-VP


; --- 
;   the branch was here when first characters of name matched. 

;; ME-OLD-V2

ME_OLD_V2:
        and $E0                 ; keep bits 11100000
        cp $A0                  ; compare   10100000 - a long-named variable.

        jr nz, ME_VAR_L1        ; forward to ME-VAR-L1 if just one-character.

;   but long-named variables have to be matched character by character.

        pop de                  ; fetch workspace 1st character pointer
        push de                 ; and save it on the stack again.
        push hl                 ; save variables area pointer on stack.

;; ME-OLD-V3

ME_OLD_V3:
        inc hl                  ; address next character in vars area.
        inc de                  ; address next character in workspace area.
        ld a, (de)              ; fetch workspace character.
        cp (hl)                 ; compare to variables character.
        jr nz, ME_OLD_V4        ; forward to ME-OLD-V4 with a mismatch.

        rla                     ; test if the terminal inverted character.
        jr nc, ME_OLD_V3        ; loop back to ME-OLD-V3 if more to test.

;   otherwise the long name matches in its entirety.

        pop hl                  ; restore pointer to first character of variable
        jr ME_VAR_L1            ; forward to ME-VAR-L1


; ---
;   the branch is here when two characters don't match

;; ME-OLD-V4

ME_OLD_V4:
        pop hl                  ; restore the prog/vars pointer.
        jr ME_OLD_V1            ; back to ME-OLD-V1 to resume search.


; ---
;   branch here when variable is to replace an existing one

;; ME-VAR-L1

ME_VAR_L1:
        ld a, $FF               ; indicate a replacement.

;   this entry point is when A holds $80 indicating a new variable.

;; ME-VAR-L2

ME_VAR_L2:
        pop de                  ; pop workspace pointer.
        ex de, hl               ; now make HL workspace pointer, DE vars pointer
        inc a                   ; zero flag set if replacement.
        scf                     ; set carry flag indicating a variable not a
                                ; program line.
        call ME_ENTER           ; routine ME-ENTER copies variable in.
        jr ME_VAR_LP            ; loop back to ME-VAR-LP


; ------------------------
; Merge a Line or Variable
; ------------------------
;   A BASIC line or variable is inserted at the current point. If the line 
;   number or variable names match (zero flag set) then a replacement takes 
;   place.

;; ME-ENTER

ME_ENTER:
        jr nz, ME_ENT_1         ; forward to ME-ENT-1 for insertion only.

;   but the program line or variable matches so old one is reclaimed.

        ex af, af'              ; save flag??
        ld (X_PTR), hl          ; preserve workspace pointer in dynamic X_PTR
        ex de, hl               ; transfer program dest pointer to HL.
        call NEXT_ONE           ; routine NEXT-ONE finds following location
                                ; in program or variables area.
        call RECLAIM_2          ; routine RECLAIM-2 reclaims the space between.
        ex de, hl               ; transfer program dest pointer back to DE.
        ld hl, (X_PTR)          ; fetch adjusted workspace pointer from X_PTR
        ex af, af'              ; restore flags.

;   now the new line or variable is entered.

;; ME-ENT-1

ME_ENT_1:
        ex af, af'              ; save or re-save flags.
        push de                 ; save dest pointer in prog/vars area.
        call NEXT_ONE           ; routine NEXT-ONE finds next in workspace.
                                ; gets next in DE, difference in BC.
                                ; prev addr in HL
        ld (X_PTR), hl          ; store pointer in X_PTR
        ld hl, (PROG)           ; load HL from system variable PROG
        ex (sp), hl             ; swap with prog/vars pointer on stack.
        push bc                 ; ** save length of new program line/variable.
        ex af, af'              ; fetch flags back.
        jr c, ME_ENT_2          ; skip to ME-ENT-2 if variable

        dec hl                  ; address location before pointer
        call MAKE_ROOM          ; routine MAKE-ROOM creates room for BASIC line
        inc hl                  ; address next.
        jr ME_ENT_3             ; forward to ME-ENT-3


; ---

;; ME-ENT-2

ME_ENT_2:
        call MAKE_ROOM          ; routine MAKE-ROOM creates room for variable.

;; ME-ENT-3

ME_ENT_3:
        inc hl                  ; address next?

        pop bc                  ; ** pop length
        pop de                  ; * pop value for PROG which may have been
                                ; altered by POINTERS if first line.
        ld (PROG), de           ; set PROG to original value.
        ld de, (X_PTR)          ; fetch adjusted workspace pointer from X_PTR
        push bc                 ; save length
        push de                 ; and workspace pointer
        ex de, hl               ; make workspace pointer source, prog/vars
                                ; pointer the destination
        ldir                    ; copy bytes of line or variable into new area.
        pop hl                  ; restore workspace pointer.
        pop bc                  ; restore length.
        push de                 ; save new prog/vars pointer.
        call RECLAIM_2          ; routine RECLAIM-2 reclaims the space used
                                ; by the line or variable in workspace block
                                ; as no longer required and space could be
                                ; useful for adding more lines.
        pop de                  ; restore the prog/vars pointer
        ret                     ; return.


; --------------------------
; THE 'SAVE CONTROL' ROUTINE
; --------------------------
;   A branch from the main SAVE-ETC routine at SAVE-ALL.
;   First the header data is saved. Then after a wait of 1 second
;   the data itself is saved.
;   HL points to start of data.
;   IX points to start of descriptor.

;; SA-CONTRL

SA_CONTRL:
        push hl                 ; save start of data

        ld a, $FD               ; select system channel 'S'
        call CHAN_OPEN          ; routine CHAN-OPEN

        xor a                   ; clear to address table directly
        ld de, tape_msgs        ; address: tape-msgs
        call PO_MSG             ; routine PO-MSG -
                                ; 'Start tape then press any key.'

        set 5, (iy+TV_FLAG-IY0) ; TV_FLAG  - Signal lower screen requires
                                ; clearing
        call WAIT_KEY           ; routine WAIT-KEY

        push ix                 ; save pointer to descriptor.
        ld de, $0011            ; there are seventeen bytes.
        xor a                   ; signal a header.
        call SA_BYTES           ; routine SA-BYTES

        pop ix                  ; restore descriptor pointer.

        ld b, $32               ; wait for a second - 50 interrupts.

;; SA-1-SEC

SA_1_SEC:
        halt                    ; wait for interrupt
        djnz SA_1_SEC           ; back to SA-1-SEC until pause complete.

        ld de, (ix+$0B)         ; fetch length of bytes from the
                                ; descriptor.

        ld a, $FF               ; signal data bytes.

        pop ix                  ; retrieve pointer to start
        jp SA_BYTES             ; jump back to SA-BYTES



;   Arrangement of two headers in workspace.
;   Originally IX addresses first location and only one header is required
;   when saving.
;
;   OLD     NEW         PROG   DATA  DATA  CODE 
;   HEADER  HEADER             num   chr          NOTES.
;   ------  ------      ----   ----  ----  ----   -----------------------------
;   IX-$11  IX+$00      0      1     2     3      Type.
;   IX-$10  IX+$01      x      x     x     x      F  ($FF if filename is null).
;   IX-$0F  IX+$02      x      x     x     x      i
;   IX-$0E  IX+$03      x      x     x     x      l
;   IX-$0D  IX+$04      x      x     x     x      e
;   IX-$0C  IX+$05      x      x     x     x      n
;   IX-$0B  IX+$06      x      x     x     x      a
;   IX-$0A  IX+$07      x      x     x     x      m
;   IX-$09  IX+$08      x      x     x     x      e
;   IX-$08  IX+$09      x      x     x     x      .
;   IX-$07  IX+$0A      x      x     x     x      (terminal spaces).
;   IX-$06  IX+$0B      lo     lo    lo    lo     Total  
;   IX-$05  IX+$0C      hi     hi    hi    hi     Length of datablock.
;   IX-$04  IX+$0D      Auto   -     -     Start  Various
;   IX-$03  IX+$0E      Start  a-z   a-z   addr   ($80 if no autostart).
;   IX-$02  IX+$0F      lo     -     -     -      Length of Program 
;   IX-$01  IX+$10      hi     -     -     -      only i.e. without variables.
;


; ------------------------
; Canned cassette messages
; ------------------------
;   The last-character-inverted Cassette messages.
;   Starts with normal initial step-over byte.

;; tape-msgs

tape_msgs:
        defb $80
        defm7 "Start tape, then press any key."

tape_msgs_2:
        defb $0D
        defm7 "Program: "
        defb $0D
        defm7 "Number array: "
        defb $0D
        defm7 "Character array: "
        defb $0D
        defm7 "Bytes: "


;**************************************************
;** Part 5. SCREEN AND PRINTER HANDLING ROUTINES **
;**************************************************

; --------------------------
; THE 'PRINT OUTPUT' ROUTINE
; --------------------------
;   This is the routine most often used by the RST 10 restart although the
;   subroutine is on two occasions called directly when it is known that
;   output will definitely be to the lower screen.

;; PRINT-OUT

PRINT_OUT:
        call PO_FETCH           ; routine PO-FETCH fetches print position
                                ; to HL register pair.
        cp $20                  ; is character a space or higher ?
        jp nc, PO_ABLE          ; jump forward to PO-ABLE if so.

        cp $06                  ; is character in range 00-05 ?
        jr c, PO_QUEST          ; to PO-QUEST to print '?' if so.

        cp $18                  ; is character in range 24d - 31d ?
        jr nc, PO_QUEST         ; to PO-QUEST to also print '?' if so.

        ld hl, ctlchrtab-$06    ; address 0A0B - the base address of control
                                ; character table - where zero would be.
        ld e, a                 ; control character 06 - 23d
        ld d, $00               ; is transferred to DE.

        add hl, de              ; index into table.

        ld e, (hl)              ; fetch the offset to routine.
        add hl, de              ; add to make HL the address.
        push hl                 ; push the address.

        jp PO_FETCH             ; Jump forward to PO-FETCH,
                                ; as the screen/printer position has been
                                ; disturbed, and then indirectly to the PO-STORE
                                ; routine on stack.


; -----------------------------
; THE 'CONTROL CHARACTER' TABLE
; -----------------------------
;   For control characters in the range 6 - 23d the following table
;   is indexed to provide an offset to the handling routine that
;   follows the table.

;; ctlchrtab

ctlchrtab:
        defb PO_COMMA - $       ; 06d offset $4E to Address: PO-COMMA
        defb PO_QUEST - $       ; 07d offset $57 to Address: PO-QUEST
        defb PO_BACK_1 - $      ; 08d offset $10 to Address: PO-BACK-1
        defb PO_RIGHT - $       ; 09d offset $29 to Address: PO-RIGHT
        defb PO_QUEST - $       ; 10d offset $54 to Address: PO-QUEST
        defb PO_QUEST - $       ; 11d offset $53 to Address: PO-QUEST
        defb PO_QUEST - $       ; 12d offset $52 to Address: PO-QUEST
        defb PO_ENTER - $       ; 13d offset $37 to Address: PO-ENTER
        defb PO_QUEST - $       ; 14d offset $50 to Address: PO-QUEST
        defb PO_QUEST - $       ; 15d offset $4F to Address: PO-QUEST
        defb PO_1_OPER - $      ; 16d offset $5F to Address: PO-1-OPER
        defb PO_1_OPER - $      ; 17d offset $5E to Address: PO-1-OPER
        defb PO_1_OPER - $      ; 18d offset $5D to Address: PO-1-OPER
        defb PO_1_OPER - $      ; 19d offset $5C to Address: PO-1-OPER
        defb PO_1_OPER - $      ; 20d offset $5B to Address: PO-1-OPER
        defb PO_1_OPER - $      ; 21d offset $5A to Address: PO-1-OPER
        defb PO_2_OPER - $      ; 22d offset $54 to Address: PO-2-OPER
        defb PO_2_OPER - $      ; 23d offset $53 to Address: PO-2-OPER


; -------------------------
; THE 'CURSOR LEFT' ROUTINE
; -------------------------
;   Backspace and up a line if that action is from the left of screen.
;   For ZX printer backspace up to first column but not beyond.

;; PO-BACK-1

PO_BACK_1:
        inc c                   ; move left one column.
        ld a, $22               ; value $21 is leftmost column.
        cp c                    ; have we passed ?
        jr nz, PO_BACK_3        ; to PO-BACK-3 if not and store new position.

        bit 1, (iy+FLAGS-IY0)   ; test FLAGS  - is printer in use ?
        jr nz, PO_BACK_2        ; to PO-BACK-2 if so, as we are unable to
                                ; backspace from the leftmost position.


        inc b                   ; move up one screen line
        ld c, $02               ; the rightmost column position.
        ld a, $18               ; Note. This should be $19
                                ; credit. Dr. Frank O'Hara, 1982

        cp b                    ; has position moved past top of screen ?
        jr nz, PO_BACK_3        ; to PO-BACK-3 if not and store new position.

        dec b                   ; else back to $18.

;; PO-BACK-2

PO_BACK_2:
        ld c, $21               ; the leftmost column position.

;; PO-BACK-3

PO_BACK_3:
        jp CL_SET               ; to CL-SET and PO-STORE to save new
                                ; position in system variables.


; --------------------------
; THE 'CURSOR RIGHT' ROUTINE
; --------------------------
;   This moves the print position to the right leaving a trail in the
;   current background colour.
;   "However the programmer has failed to store the new print position
;   so CHR$ 9 will only work if the next print position is at a newly
;   defined place.
;   e.g. PRINT PAPER 2; CHR$ 9; AT 4,0;
;   does work but is not very helpful"
;   - Dr. Ian Logan, Understanding Your Spectrum, 1982.

;; PO-RIGHT

PO_RIGHT:
        ld a, (P_FLAG)          ; fetch P_FLAG value
        push af                 ; and save it on stack.

        ld (iy+P_FLAG-IY0), $01 ; temporarily set P_FLAG 'OVER 1'.
        ld a, $20               ; prepare a space.
        call PO_CHAR            ; routine PO-CHAR to print it.
                                ; Note. could be PO-ABLE which would update
                                ; the column position.

        pop af                  ; restore the permanent flag.
        ld (P_FLAG), a          ; and restore system variable P_FLAG

        ret                     ; return without updating column position


; -----------------------
; Perform carriage return
; -----------------------
; A carriage return is 'printed' to screen or printer buffer.

;; PO-ENTER

PO_ENTER:
        bit 1, (iy+FLAGS-IY0)   ; test FLAGS  - is printer in use ?
        jp nz, COPY_BUFF        ; to COPY-BUFF if so, to flush buffer and reset
                                ; the print position.

        ld c, $21               ; the leftmost column position.
        call PO_SCR             ; routine PO-SCR handles any scrolling required.
        dec b                   ; to next screen line.
        jp CL_SET               ; jump forward to CL-SET to store new position.


; -----------
; Print comma
; -----------
; The comma control character. The 32 column screen has two 16 character
; tabstops.  The routine is only reached via the control character table.

;; PO-COMMA

PO_COMMA:
        call PO_FETCH           ; routine PO-FETCH - seems unnecessary.

        ld a, c                 ; the column position. $21-$01
        dec a                   ; move right. $20-$00
        dec a                   ; and again   $1F-$00 or $FF if trailing
        and $10                 ; will be $00 or $10.
        jr PO_FILL              ; forward to PO-FILL


; -------------------
; Print question mark
; -------------------
; This routine prints a question mark which is commonly
; used to print an unassigned control character in range 0-31d.
; there are a surprising number yet to be assigned.

;; PO-QUEST

PO_QUEST:
        ld a, $3F               ; prepare the character '?'.
        jr PO_ABLE              ; forward to PO-ABLE.


; --------------------------------
; Control characters with operands
; --------------------------------
; Certain control characters are followed by 1 or 2 operands.
; The entry points from control character table are PO-2-OPER and PO-1-OPER.
; The routines alter the output address of the current channel so that
; subsequent RST $10 instructions take the appropriate action
; before finally resetting the output address back to PRINT-OUT.

;; PO-TV-2

PO_TV_2:
        ld de, PO_CONT          ; address: PO-CONT will be next output routine
        ld ($5C0F), a           ; store first operand in TVDATA-hi
        jr PO_CHANGE            ; forward to PO-CHANGE >>


; ---

; -> This initial entry point deals with two operands - AT or TAB.

;; PO-2-OPER

PO_2_OPER:
        ld de, PO_TV_2          ; address: PO-TV-2 will be next output routine
        jr PO_TV_1              ; forward to PO-TV-1


; ---

; -> This initial entry point deals with one operand INK to OVER.

;; PO-1-OPER

PO_1_OPER:
        ld de, PO_CONT          ; address: PO-CONT will be next output routine

;; PO-TV-1

PO_TV_1:
        ld (TVDATA), a          ; store control code in TVDATA-lo

;; PO-CHANGE

PO_CHANGE:
        ld hl, (CURCHL)         ; use CURCHL to find current output channel.
        ldi (hl), e             ; make it
                                ; the supplied
        ld (hl), d              ; address from DE.
        ret                     ; return.


; ---

;; PO-CONT

PO_CONT:
        ld de, PRINT_OUT        ; Address: PRINT-OUT
        call PO_CHANGE          ; routine PO-CHANGE to restore normal channel.
        ld hl, (TVDATA)         ; TVDATA gives control code and possible
                                ; subsequent character
        ld d, a                 ; save current character
        ld a, l                 ; the stored control code
        cp $16                  ; was it INK to OVER (1 operand) ?
        jp c, CO_TEMP_5         ; to CO-TEMP-5

        jr nz, PO_TAB           ; to PO-TAB if not 22d i.e. 23d TAB.

                                ; else must have been 22d AT.
        ld b, h                 ; line to H   (0-23d)
        ld c, d                 ; column to C (0-31d)
        ld a, $1F               ; the value 31d
        sub c                   ; reverse the column number.
        jr c, PO_AT_ERR         ; to PO-AT-ERR if C was greater than 31d.

        add a, $02              ; transform to system range $02-$21
        ld c, a                 ; and place in column register.

        bit 1, (iy+FLAGS-IY0)   ; test FLAGS  - is printer in use ?
        jr nz, PO_AT_SET        ; to PO-AT-SET as line can be ignored.

        ld a, $16               ; 22 decimal
        sub b                   ; subtract line number to reverse
                                ; 0 - 22 becomes 22 - 0.

;; PO-AT-ERR

PO_AT_ERR:
        jp c, REPORT_Bb         ; to REPORT-B if higher than 22 decimal
                                ; Integer out of range.

        inc a                   ; adjust for system range $01-$17
        ld b, a                 ; place in line register
        inc b                   ; adjust to system range  $02-$18
        bit 0, (iy+TV_FLAG-IY0) ; TV_FLAG  - Lower screen in use ?
        jp nz, PO_SCR           ; exit to PO-SCR to test for scrolling

        cp (iy+DF_SZ-IY0)       ; Compare against DF_SZ
        jp c, REPORT_5          ; to REPORT-5 if too low
                                ; Out of screen.

;; PO-AT-SET

PO_AT_SET:
        jp CL_SET               ; print position is valid so exit via CL-SET


; ---

; Continue here when dealing with TAB.
; Note. In BASIC, TAB is followed by a 16-bit number and was initially
; designed to work with any output device.

;; PO-TAB

PO_TAB:
        ld a, h                 ; transfer parameter to A
                                ; Losing current character -
                                ; High byte of TAB parameter.


;; PO-FILL

PO_FILL:
        call PO_FETCH           ; routine PO-FETCH, HL-addr, BC=line/column.
                                ; column 1 (right), $21 (left)
        add a, c                ; add operand to current column
        dec a                   ; range 0 - 31+
        and $1F                 ; make range 0 - 31d
        ret z                   ; return if result zero

        ld d, a                 ; Counter to D
        set 0, (iy+FLAGS-IY0)   ; update FLAGS  - signal suppress leading space.

;; PO-SPACE

PO_SPACE:
        ld a, $20               ; space character.

        call PO_SAVE            ; routine PO-SAVE prints the character
                                ; using alternate set (normal output routine)

        dec d                   ; decrement counter.
        jr nz, PO_SPACE         ; to PO-SPACE until done

        ret                     ; return


; ----------------------
; Printable character(s)
; ----------------------
; This routine prints printable characters and continues into
; the position store routine

;; PO-ABLE

PO_ABLE:
        call PO_ANY             ; routine PO-ANY
                                ; and continue into position store routine.

; ----------------------------
; THE 'POSITION STORE' ROUTINE
; ----------------------------
;   This routine updates the system variables associated with the main screen, 
;   the lower screen/input buffer or the ZX printer.

;; PO-STORE

PO_STORE:
        bit 1, (iy+FLAGS-IY0)   ; Test FLAGS - is printer in use ?
        jr nz, PO_ST_PR         ; Forward, if so, to PO-ST-PR

        bit 0, (iy+TV_FLAG-IY0) ; Test TV_FLAG - is lower screen in use ?
        jr nz, PO_ST_E          ; Forward, if so, to PO-ST-E

;   This section deals with the upper screen.

        ld (S_POSN), bc         ; Update S_POSN - line/column upper screen
        ld (DF_CC), hl          ; Update DF_CC - upper display file address

        ret                     ; Return.


; ---

;   This section deals with the lower screen.

;; PO-ST-E

PO_ST_E:
        ld (SPOSNL), bc         ; Update SPOSNL line/column lower screen
        ld (ECHO_E), bc         ; Update ECHO_E line/column input buffer
        ld (DFCCL), hl          ; Update DFCCL  lower screen memory address
        ret                     ; Return.


; ---

;   This section deals with the ZX Printer.

;; PO-ST-PR

PO_ST_PR:
        ld (iy+P_POSN-IY0), c   ; Update P_POSN column position printer
        ld (PR_CC), hl          ; Update PR_CC - full printer buffer memory
                                ; address
        ret                     ; Return.


;   Note. that any values stored in location 23681 will be overwritten with 
;   the value 91 decimal. 
;   Credit April 1983, Dilwyn Jones. "Delving Deeper into your ZX Spectrum".

; ----------------------------
; THE 'POSITION FETCH' ROUTINE
; ----------------------------
;   This routine fetches the line/column and display file address of the upper 
;   and lower screen or, if the printer is in use, the column position and 
;   absolute memory address.
;   Note. that PR-CC-hi (23681) is used by this routine and if, in accordance 
;   with the manual (that says this is unused), the location has been used for 
;   other purposes, then subsequent output to the printer buffer could corrupt 
;   a 256-byte section of memory.

;; PO-FETCH

PO_FETCH:
        bit 1, (iy+FLAGS-IY0)   ; Test FLAGS - is printer in use ?
        jr nz, PO_F_PR          ; Forward, if so, to PO-F-PR

;   assume upper screen in use and thus optimize for path that requires speed.

        ld bc, (S_POSN)         ; Fetch line/column from S_POSN
        ld hl, (DF_CC)          ; Fetch DF_CC display file address

        bit 0, (iy+TV_FLAG-IY0) ; Test TV_FLAG - lower screen in use ?
        ret z                   ; Return if upper screen in use.

;   Overwrite registers with values for lower screen.

        ld bc, (SPOSNL)         ; Fetch line/column from SPOSNL
        ld hl, (DFCCL)          ; Fetch display file address from DFCCL
        ret                     ; Return.


; ---

;   This section deals with the ZX Printer.

;; PO-F-PR

PO_F_PR:
        ld c, (iy+P_POSN-IY0)   ; Fetch column from P_POSN.
        ld hl, (PR_CC)          ; Fetch printer buffer address from PR_CC.
        ret                     ; Return.


; ---------------------------------
; THE 'PRINT ANY CHARACTER' ROUTINE
; ---------------------------------
;   This routine is used to print any character in range 32d - 255d
;   It is only called from PO-ABLE which continues into PO-STORE

;; PO-ANY

PO_ANY:
        cp $80                  ; ASCII ?
        jr c, PO_CHAR           ; to PO-CHAR is so.

        cp $90                  ; test if a block graphic character.
        jr nc, PO_T_UDG         ; to PO-T&UDG to print tokens and UDGs

; The 16 2*2 mosaic characters 128-143 decimal are formed from
; bits 0-3 of the character.

        ld b, a                 ; save character
        call PO_GR_1            ; routine PO-GR-1 to construct top half
                                ; then bottom half.
        call PO_FETCH           ; routine PO-FETCH fetches print position.
        ld de, MEMBOT           ; MEM-0 is location of 8 bytes of character
        jr PR_ALL               ; to PR-ALL to print to screen or printer


; ---

;; PO-GR-1

PO_GR_1:
        ld hl, MEMBOT           ; address MEM-0 - a temporary buffer in
                                ; systems variables which is normally used
                                ; by the calculator.
        call PO_GR_2            ; routine PO-GR-2 to construct top half
                                ; and continue into routine to construct
                                ; bottom half.

;; PO-GR-2

PO_GR_2:
        rr b                    ; rotate bit 0/2 to carry
        sbc a, a                ; result $00 or $FF
        and $0F                 ; mask off right hand side
        ld c, a                 ; store part in C
        rr b                    ; rotate bit 1/3 of original chr to carry
        sbc a, a                ; result $00 or $FF
        and $F0                 ; mask off left hand side
        or c                    ; combine with stored pattern
        ld c, $04               ; four bytes for top/bottom half

;; PO-GR-3

PO_GR_3:
        ldi (hl), a             ; store bit patterns in temporary buffer
                                ; next address
        dec c                   ; jump back to
        jr nz, PO_GR_3          ; to PO-GR-3 until byte is stored 4 times

        ret                     ; return


; ---

; Tokens and User defined graphics are now separated.

;; PO-T&UDG

PO_T_UDG:
        sub $A5                 ; the 'RND' character
        jr nc, PO_T             ; to PO-T to print tokens

        add a, $15              ; add 21d to restore to 0 - 20
        push bc                 ; save current print position
        ld bc, (UDG)            ; fetch UDG to address bit patterns
        jr PO_CHAR_2            ; to PO-CHAR-2 - common code to lay down
                                ; a bit patterned character


; ---

;; PO-T

PO_T:
        call PO_TOKENS          ; routine PO-TOKENS prints tokens
        jp PO_FETCH             ; exit via a JUMP to PO-FETCH as this routine
                                ; must continue into PO-STORE.
                                ; A JR instruction could be used.


; This point is used to print ASCII characters  32d - 127d.

;; PO-CHAR

PO_CHAR:
        push bc                 ; save print position
        ld bc, (CHARS)          ; address CHARS

; This common code is used to transfer the character bytes to memory.

;; PO-CHAR-2

PO_CHAR_2:
        ex de, hl               ; transfer destination address to DE
        ld hl, FLAGS            ; point to FLAGS
        res 0, (hl)             ; allow for leading space
        cp $20                  ; is it a space ?
        jr nz, PO_CHAR_3        ; to PO-CHAR-3 if not

        set 0, (hl)             ; signal no leading space to FLAGS

;; PO-CHAR-3

PO_CHAR_3:
        ld h, $00               ; set high byte to 0
        ld l, a                 ; character to A
                                ; 0-21 UDG or 32-127 ASCII.
        add hl, hl              ; multiply
        add hl, hl              ; by
        add hl, hl              ; eight
        add hl, bc              ; HL now points to first byte of character
        pop bc                  ; the source address CHARS or UDG
        ex de, hl               ; character address to DE

; ----------------------------------
; THE 'PRINT ALL CHARACTERS' ROUTINE
; ----------------------------------
;   This entry point entered from above to print ASCII and UDGs but also from 
;   earlier to print mosaic characters.
;   HL=destination
;   DE=character source
;   BC=line/column

;; PR-ALL

PR_ALL:
        ld a, c                 ; column to A
        dec a                   ; move right
        ld a, $21               ; pre-load with leftmost position
        jr nz, PR_ALL_1         ; but if not zero to PR-ALL-1

        dec b                   ; down one line
        ld c, a                 ; load C with $21
        bit 1, (iy+FLAGS-IY0)   ; test FLAGS  - Is printer in use
        jr z, PR_ALL_1          ; to PR-ALL-1 if not

        push de                 ; save source address
        call COPY_BUFF          ; routine COPY-BUFF outputs line to printer
        pop de                  ; restore character source address
        ld a, c                 ; the new column number ($21) to C

;; PR-ALL-1

PR_ALL_1:
        cp c                    ; this test is really for screen - new line ?
        push de                 ; save source

        call z, PO_SCR          ; routine PO-SCR considers scrolling

        pop de                  ; restore source
        push bc                 ; save line/column
        push hl                 ; and destination
        ld a, (P_FLAG)          ; fetch P_FLAG to accumulator
        ld b, $FF               ; prepare OVER mask in B.
        rra                     ; bit 0 set if OVER 1
        jr c, PR_ALL_2          ; to PR-ALL-2

        inc b                   ; set OVER mask to 0

;; PR-ALL-2

PR_ALL_2:
        rra                     ; skip bit 1 of P_FLAG
        rra                     ; bit 2 is INVERSE
        sbc a, a                ; will be FF for INVERSE 1 else zero
        ld c, a                 ; transfer INVERSE mask to C
        ld a, $08               ; prepare to count 8 bytes
        and a                   ; clear carry to signal screen
        bit 1, (iy+FLAGS-IY0)   ; test FLAGS  - is printer in use ?
        jr z, PR_ALL_3          ; to PR-ALL-3 if screen

        set 1, (iy+FLAGS2-IY0)  ; update FLAGS2  - signal printer buffer has
                                ; been used.
        scf                     ; set carry flag to signal printer.

;; PR-ALL-3

PR_ALL_3:
        ex de, hl               ; now HL=source, DE=destination

;; PR-ALL-4

PR_ALL_4:
        ex af, af'              ; save printer/screen flag
        ld a, (de)              ; fetch existing destination byte
        and b                   ; consider OVER
        xor (hl)                ; now XOR with source
        xor c                   ; now with INVERSE MASK
        ld (de), a              ; update screen/printer
        ex af, af'              ; restore flag
        jr c, PR_ALL_6          ; to PR-ALL-6 - printer address update

        inc d                   ; gives next pixel line down screen

;; PR-ALL-5

PR_ALL_5:
        inc hl                  ; address next character byte
        dec a                   ; the byte count is decremented
        jr nz, PR_ALL_4         ; back to PR-ALL-4 for all 8 bytes

        ex de, hl               ; destination to HL
        dec h                   ; bring back to last updated screen position
        bit 1, (iy+FLAGS-IY0)   ; test FLAGS  - is printer in use ?
        call z, PO_ATTR         ; if not, call routine PO-ATTR to update
                                ; corresponding colour attribute.
        pop hl                  ; restore original screen/printer position
        pop bc                  ; and line column
        dec c                   ; move column to right
        inc hl                  ; increase screen/printer position
        ret                     ; return and continue into PO-STORE
                                ; within PO-ABLE


; ---

;   This branch is used to update the printer position by 32 places
;   Note. The high byte of the address D remains constant (which it should).

;; PR-ALL-6

PR_ALL_6:
        ex af, af'              ; save the flag
        ld a, $20               ; load A with 32 decimal
        add a, e                ; add this to E
        ld e, a                 ; and store result in E
        ex af, af'              ; fetch the flag
        jr PR_ALL_5             ; back to PR-ALL-5


; -----------------------------------
; THE 'GET ATTRIBUTE ADDRESS' ROUTINE
; -----------------------------------
;   This routine is entered with the HL register holding the last screen
;   address to be updated by PRINT or PLOT.
;   The Spectrum screen arrangement leads to the L register holding the correct
;   value for the attribute file and it is only necessary to manipulate H to 
;   form the correct colour attribute address.

;; PO-ATTR

PO_ATTR:
        ld a, h                 ; fetch high byte $40 - $57
        rrca                    ; shift
        rrca                    ; bits 3 and 4
        rrca                    ; to right.
        and $03                 ; range is now 0 - 2
        or $58                  ; form correct high byte for third of screen
        ld h, a                 ; HL is now correct
        ld de, (ATTR_T)         ; make D hold ATTR_T, E hold MASK-T
        ld a, (hl)              ; fetch existing attribute
        xor e                   ; apply masks
        and d
        xor e
        bit 6, (iy+P_FLAG-IY0)  ; test P_FLAG  - is this PAPER 9 ??
        jr z, PO_ATTR_1         ; skip to PO-ATTR-1 if not.

        and $C7                 ; set paper
        bit 2, a                ; to contrast with ink
        jr nz, PO_ATTR_1        ; skip to PO-ATTR-1

        xor $38

;; PO-ATTR-1

PO_ATTR_1:
        bit 4, (iy+P_FLAG-IY0)  ; test P_FLAG  - Is this INK 9 ??
        jr z, PO_ATTR_2         ; skip to PO-ATTR-2 if not

        and $F8                 ; make ink
        bit 5, a                ; contrast with paper.
        jr nz, PO_ATTR_2        ; to PO-ATTR-2

        xor $07

;; PO-ATTR-2

PO_ATTR_2:
        ld (hl), a              ; save the new attribute.
        ret                     ; return.


; ---------------------------------
; THE 'MESSAGE PRINTING' SUBROUTINE
; ---------------------------------
;   This entry point is used to print tape, boot-up, scroll? and error messages.
;   On entry the DE register points to an initial step-over byte or the 
;   inverted end-marker of the previous entry in the table.
;   Register A contains the message number, often zero to print first message.
;   (HL has nothing important usually P_FLAG)

;; PO-MSG

PO_MSG:
        push hl                 ; put hi-byte zero on stack to suppress
        ld h, $00               ; trailing spaces
        ex (sp), hl             ; ld h,0; push hl would have done ?.
        jr PO_TABLE             ; forward to PO-TABLE.


; ---

;   This entry point prints the BASIC keywords, '<>' etc. from alt set

;; PO-TOKENS

PO_TOKENS:
        ld de, TKN_TABLE        ; address: TKN-TABLE
        push af                 ; save the token number to control
                                ; trailing spaces - see later *

; ->

;; PO-TABLE

PO_TABLE:
        call PO_SEARCH          ; routine PO-SEARCH will set carry for
                                ; all messages and function words.

        jr c, PO_EACH           ; forward to PO-EACH if not a command, '<>' etc.

        ld a, $20               ; prepare leading space
        bit 0, (iy+FLAGS-IY0)   ; test FLAGS  - leading space if not set

        call z, PO_SAVE         ; routine PO-SAVE to print a space without
                                ; disturbing registers.

;; PO-EACH

PO_EACH:
        ld a, (de)              ; Fetch character from the table.
        and $7F                 ; Cancel any inverted bit.

        call PO_SAVE            ; Routine PO-SAVE to print using the alternate
                                ; set of registers.

        ldi a, (de)             ; Re-fetch character from table.
                                ; Address next character in the table.

        add a, a                ; Was character inverted ?
                                ; (this also doubles character)
        jr nc, PO_EACH          ; back to PO-EACH if not.

        pop de                  ; * re-fetch trailing space byte to D

        cp $48                  ; was the last character '$' ?
        jr z, PO_TR_SP          ; forward to PO-TR-SP to consider trailing
                                ; space if so.

        cp $82                  ; was it < 'A' i.e. '#','>','=' from tokens
                                ; or ' ','.' (from tape) or '?' from scroll

        ret c                   ; Return if so as no trailing space required.

;; PO-TR-SP

PO_TR_SP:
        ld a, d                 ; The trailing space flag (zero if an error msg)

        cp $03                  ; Test against RND, INKEY$ and PI which have no
                                ; parameters and therefore no trailing space.

        ret c                   ; Return if no trailing space.

        ld a, $20               ; Prepare the space character and continue to
                                ; print and make an indirect return.

; -----------------------------------
; THE 'RECURSIVE PRINTING' SUBROUTINE
; -----------------------------------
;   This routine which is part of PRINT-OUT allows RST $10 to be used 
;   recursively to print tokens and the spaces associated with them.
;   It is called on three occasions when the value of DE must be preserved.

;; PO-SAVE

PO_SAVE:
        push de                 ; Save DE value.
        exx                     ; Switch in main set

        rst $10                 ; PRINT-A prints using this alternate set.

        exx                     ; Switch back to this alternate set.
        pop de                  ; Restore the initial DE value.

        ret                     ; Return.


; ------------
; Table search
; ------------
; This subroutine searches a message or the token table for the
; message number held in A. DE holds the address of the table.

;; PO-SEARCH

PO_SEARCH:
        push af                 ; save the message/token number
        ex de, hl               ; transfer DE to HL
        inc a                   ; adjust for initial step-over byte

;; PO-STEP

PO_STEP:
        bit 7, (hl)             ; is character inverted ?
        inc hl                  ; address next
        jr z, PO_STEP           ; back to PO-STEP if not inverted.

        dec a                   ; decrease counter
        jr nz, PO_STEP          ; back to PO-STEP if not zero

        ex de, hl               ; transfer address to DE
        pop af                  ; restore message/token number
        cp $20                  ; return with carry set
        ret c                   ; for all messages and function tokens

        ld a, (de)              ; test first character of token
        sub $41                 ; and return with carry set
        ret                     ; if it is less that 'A'
                                ; i.e. '<>', '<=', '>='


; ---------------
; Test for scroll
; ---------------
; This test routine is called when printing carriage return, when considering
; PRINT AT and from the general PRINT ALL characters routine to test if
; scrolling is required, prompting the user if necessary.
; This is therefore using the alternate set.
; The B register holds the current line.

;; PO-SCR

PO_SCR:
        bit 1, (iy+FLAGS-IY0)   ; test FLAGS  - is printer in use ?
        ret nz                  ; return immediately if so.

        ld de, CL_SET           ; set DE to address: CL-SET
        push de                 ; and push for return address.

        ld a, b                 ; transfer the line to A.
        bit 0, (iy+TV_FLAG-IY0) ; test TV_FLAG - lower screen in use ?
        jp nz, PO_SCR_4         ; jump forward to PO-SCR-4 if so.

        cp (iy+DF_SZ-IY0)       ; greater than DF_SZ display file size ?
        jr c, REPORT_5          ; forward to REPORT-5 if less.
                                ; 'Out of screen'

        ret nz                  ; return (via CL-SET) if greater

        bit 4, (iy+TV_FLAG-IY0) ; test TV_FLAG  - Automatic listing ?
        jr z, PO_SCR_2          ; forward to PO-SCR-2 if not.

        ld e, (iy+BREG-IY0)     ; fetch BREG - the count of scroll lines to E.
        dec e                   ; decrease and jump
        jr z, PO_SCR_3          ; to PO-SCR-3 if zero and scrolling required.

        ld a, $00               ; explicit - select channel zero.
        call CHAN_OPEN          ; routine CHAN-OPEN opens it.

        ld sp, (LIST_SP)        ; set stack pointer to LIST_SP

        res 4, (iy+TV_FLAG-IY0) ; reset TV_FLAG  - signal auto listing finished.
        ret                     ; return ignoring pushed value, CL-SET
                                ; to MAIN or EDITOR without updating
                                ; print position                         >>


; ---


;; REPORT-5

REPORT_5:
        rst $08                 ; ERROR-1
        defb $04                ; Error Report: Out of screen

; continue here if not an automatic listing.

;; PO-SCR-2

PO_SCR_2:
        dec (iy+SCR_CT-IY0)     ; decrease SCR_CT
        jr nz, PO_SCR_3         ; forward to PO-SCR-3 to scroll display if
                                ; result not zero.

; now produce prompt.

        ld a, $18               ; reset
        sub b                   ; the
        ld (SCR_CT), a          ; SCR_CT scroll count
        ld hl, (ATTR_T)         ; L=ATTR_T, H=MASK_T
        push hl                 ; save on stack
        ld a, (P_FLAG)          ; P_FLAG
        push af                 ; save on stack to prevent lower screen
                                ; attributes (BORDCR etc.) being applied.
        ld a, $FD               ; select system channel 'K'
        call CHAN_OPEN          ; routine CHAN-OPEN opens it
        xor a                   ; clear to address message directly
        ld de, scrl_mssg        ; make DE address: scrl-mssg
        call PO_MSG             ; routine PO-MSG prints to lower screen
        set 5, (iy+TV_FLAG-IY0) ; set TV_FLAG  - signal lower screen requires
                                ; clearing
        ld hl, FLAGS            ; make HL address FLAGS
        set 3, (hl)             ; signal 'L' mode.
        res 5, (hl)             ; signal 'no new key'.
        exx                     ; switch to main set.
                                ; as calling chr input from alternative set.
        call WAIT_KEY           ; routine WAIT-KEY waits for new key
                                ; Note. this is the right routine but the
                                ; stream in use is unsatisfactory. From the
                                ; choices available, it is however the best.

        exx                     ; switch back to alternate set.
        cp $20                  ; space is considered as BREAK
        jr z, REPORT_D          ; forward to REPORT-D if so
                                ; 'BREAK - CONT repeats'

        cp $E2                  ; is character 'STOP' ?
        jr z, REPORT_D          ; forward to REPORT-D if so

        or $20                  ; convert to lower-case
        cp $6E                  ; is character 'n' ?
        jr z, REPORT_D          ; forward to REPORT-D if so else scroll.

        ld a, $FE               ; select system channel 'S'
        call CHAN_OPEN          ; routine CHAN-OPEN
        pop af                  ; restore original P_FLAG
        ld (P_FLAG), a          ; and save in P_FLAG.
        pop hl                  ; restore original ATTR_T, MASK_T
        ld (ATTR_T), hl         ; and reset ATTR_T, MASK-T as 'scroll?' has
                                ; been printed.

;; PO-SCR-3

PO_SCR_3:
        call CL_SC_ALL          ; routine CL-SC-ALL to scroll whole display
        ld b, (iy+DF_SZ-IY0)    ; fetch DF_SZ to B
        inc b                   ; increase to address last line of display
        ld c, $21               ; set C to $21 (was $21 from above routine)
        push bc                 ; save the line and column in BC.

        call CL_ADDR            ; routine CL-ADDR finds display address.

        ld a, h                 ; now find the corresponding attribute byte
        rrca                    ; (this code sequence is used twice
        rrca                    ; elsewhere and is a candidate for
        rrca                    ; a subroutine.)
        and $03
        or $58
        ld h, a

        ld de, $5AE0            ; start of last 'line' of attribute area
        ld a, (de)              ; get attribute for last line
        ld c, (hl)              ; transfer to base line of upper part
        ld b, $20               ; there are thirty two bytes
        ex de, hl               ; swap the pointers.

;; PO-SCR-3A

PO_SCR_3A:
        ld (de), a              ; transfer
        ld (hl), c              ; attributes.
        inc de                  ; address next.
        inc hl                  ; address next.
        djnz PO_SCR_3A          ; loop back to PO-SCR-3A for all adjacent
                                ; attribute lines.

        pop bc                  ; restore the line/column.
        ret                     ; return via CL-SET (was pushed on stack).


; ---

; The message 'scroll?' appears here with last byte inverted.

;; scrl-mssg

scrl_mssg:
        defb $80                ; initial step-over byte.
        defm7 "scroll?"

;; REPORT-D

REPORT_D:
        rst $08                 ; ERROR-1
        defb $0C                ; Error Report: BREAK - CONT repeats

; continue here if using lower display - A holds line number.

;; PO-SCR-4

PO_SCR_4:
        cp $02                  ; is line number less than 2 ?
        jr c, REPORT_5          ; to REPORT-5 if so
                                ; 'Out of Screen'.

        add a, (iy+DF_SZ-IY0)   ; add DF_SZ
        sub $19
        ret nc                  ; return if scrolling unnecessary

        neg                     ; Negate to give number of scrolls required.
        push bc                 ; save line/column
        ld b, a                 ; count to B
        ld hl, (ATTR_T)         ; fetch current ATTR_T, MASK_T to HL.
        push hl                 ; and save
        ld hl, (P_FLAG)         ; fetch P_FLAG
        push hl                 ; and save.
                                ; to prevent corruption by input AT

        call TEMPS              ; routine TEMPS sets to BORDCR etc
        ld a, b                 ; transfer scroll number to A.

;; PO-SCR-4A

PO_SCR_4A:
        push af                 ; save scroll number.
        ld hl, DF_SZ            ; address DF_SZ
        ld b, (hl)              ; fetch old value
        ld a, b                 ; transfer to A
        inc a                   ; and increment
        ld (hl), a              ; then put back.
        ld hl, S_POSN_hi        ; address S_POSN_hi - line
        cp (hl)                 ; compare
        jr c, PO_SCR_4B         ; forward to PO-SCR-4B if scrolling required

        inc (hl)                ; else increment S_POSN_hi
        ld b, $18               ; set count to whole display ??
                                ; Note. should be $17 and the top line will be
                                ; scrolled into the ROM which is harmless on
                                ; the standard set up.
                                ; credit P.Giblin 1984.

;; PO-SCR-4B

PO_SCR_4B:
        call CL_SCROLL          ; routine CL-SCROLL scrolls B lines
        pop af                  ; restore scroll counter.
        dec a                   ; decrease
        jr nz, PO_SCR_4A        ; back to PO-SCR-4A until done

        pop hl                  ; restore original P_FLAG.
        ld (iy+P_FLAG-IY0), l   ; and overwrite system variable P_FLAG.

        pop hl                  ; restore original ATTR_T/MASK_T.
        ld (ATTR_T), hl         ; and update system variables.

        ld bc, (S_POSN)         ; fetch S_POSN to BC.
        res 0, (iy+TV_FLAG-IY0) ; signal to TV_FLAG  - main screen in use.
        call CL_SET             ; call routine CL-SET for upper display.

        set 0, (iy+TV_FLAG-IY0) ; signal to TV_FLAG  - lower screen in use.
        pop bc                  ; restore line/column
        ret                     ; return via CL-SET for lower display.


; ----------------------
; Temporary colour items
; ----------------------
; This subroutine is called 11 times to copy the permanent colour items
; to the temporary ones.

;; TEMPS

TEMPS:
        xor a                   ; clear the accumulator
        ld hl, (ATTR_P)         ; fetch L=ATTR_P and H=MASK_P
        bit 0, (iy+TV_FLAG-IY0) ; test TV_FLAG  - is lower screen in use ?
        jr z, TEMPS_1           ; skip to TEMPS-1 if not

        ld h, a                 ; set H, MASK P, to 00000000.
        ld l, (iy+BORDCR-IY0)   ; fetch BORDCR to L which is used for lower
                                ; screen.

;; TEMPS-1

TEMPS_1:
        ld (ATTR_T), hl         ; transfer values to ATTR_T and MASK_T

; for the print flag the permanent values are odd bits, temporary even bits.

        ld hl, P_FLAG           ; address P_FLAG.
        jr nz, TEMPS_2          ; skip to TEMPS-2 if lower screen using A=0.

        ld a, (hl)              ; else pick up flag bits.
        rrca                    ; rotate permanent bits to temporary bits.

;; TEMPS-2

TEMPS_2:
        xor (hl)
        and $55                 ; BIN 01010101
        xor (hl)                ; permanent now as original
        ld (hl), a              ; apply permanent bits to temporary bits.
        ret                     ; and return.


; -----------------
; THE 'CLS' COMMAND 
; -----------------
;    This command clears the display.
;    The routine is also called during initialization and by the CLEAR command.
;    If it's difficult to write it should be difficult to read.

;; CLS

CLS:
        call CL_ALL             ; Routine CL-ALL clears the entire display and
                                ; sets the attributes to the permanent ones
                                ; from ATTR-P.

;   Having cleared all 24 lines of the display area, continue into the 
;   subroutine that clears the lower display area.  Note that at the moment 
;   the attributes for the lower lines are the same as upper ones and have 
;   to be changed to match the BORDER colour.

; --------------------------
; THE 'CLS-LOWER' SUBROUTINE 
; --------------------------
;   This routine is called from INPUT, and from the MAIN execution loop.
;   This is very much a housekeeping routine which clears between 2 and 23
;   lines of the display, setting attributes and correcting situations where
;   errors have occurred while the normal input and output routines have been
;   temporarily diverted to deal with, say colour control codes. 

;; CLS-LOWER

CLS_LOWER:
        ld hl, TV_FLAG          ; address System Variable TV_FLAG.
        res 5, (hl)             ; TV_FLAG - signal do not clear lower screen.
        set 0, (hl)             ; TV_FLAG - signal lower screen in use.

        call TEMPS              ; routine TEMPS applies permanent attributes,
                                ; in this case BORDCR to ATTR_T.
                                ; Note. this seems unnecessary and is repeated
                                ; within CL-LINE.

        ld b, (iy+DF_SZ-IY0)    ; fetch lower screen display file size DF_SZ

        call CL_LINE            ; routine CL-LINE clears lines to bottom of the
                                ; display and sets attributes from BORDCR while
                                ; preserving the B register.

        ld hl, $5AC0            ; set initial attribute address to the leftmost
                                ; cell of second line up.

        ld a, (ATTR_P)          ; fetch permanent attribute from ATTR_P.

        dec b                   ; decrement lower screen display file size.

        jr CLS_3                ; forward to enter the backfill loop at CLS-3
                                ; where B is decremented again.


; ---

;   The backfill loop is entered at midpoint and ensures, if more than 2
;   lines have been cleared, that any other lines take the permanent screen
;   attributes.

;; CLS-1

CLS_1:
        ld c, $20               ; set counter to 32 character cells per line

;; CLS-2

CLS_2:
        dec hl                  ; decrease attribute address.
        ld (hl), a              ; and place attributes in next line up.
        dec c                   ; decrease the 32 counter.
        jr nz, CLS_2            ; loop back to CLS-2 until all 32 cells done.

;; CLS-3

CLS_3:
        djnz CLS_1              ; decrease B counter and back to CLS-1
                                ; if not zero.

        ld (iy+DF_SZ-IY0), $02  ; now set DF_SZ lower screen to 2

; This entry point is also called from CL-ALL below to
; reset the system channel input and output addresses to normal.

;; CL-CHAN

CL_CHAN:
        ld a, $FD               ; select system channel 'K'

        call CHAN_OPEN          ; routine CHAN-OPEN opens it.

        ld hl, (CURCHL)         ; fetch CURCHL to HL to address current channel
        ld de, PRINT_OUT        ; set address to PRINT-OUT for first pass.
        and a                   ; clear carry for first pass.

;; CL-CHAN-A

CL_CHAN_A:
        ldi (hl), de            ; Insert the output address on the first pass
                                ; or the input address on the second pass.

        ld de, KEY_INPUT        ; fetch address KEY-INPUT for second pass
        ccf                     ; complement carry flag - will set on pass 1.

        jr c, CL_CHAN_A         ; back to CL-CHAN-A if first pass else done.

        ld bc, $1721            ; line 23 for lower screen
        jr CL_SET               ; exit via CL-SET to set column
                                ; for lower display


; ---------------------------
; Clearing whole display area
; ---------------------------
; This subroutine called from CLS, AUTO-LIST and MAIN-3
; clears 24 lines of the display and resets the relevant system variables.
; This routine also recovers from an error situation where, for instance, an 
; invalid colour or position control code has left the output routine addressing
; PO-TV-2 or PO-CONT.

;; CL-ALL

CL_ALL:
        ld hl, $0000            ; Initialize plot coordinates.
        ld (COORDS), hl         ; Set system variable COORDS to 0,0.

        res 0, (iy+FLAGS2-IY0)  ; update FLAGS2  - signal main screen is clear.

        call CL_CHAN            ; routine CL-CHAN makes channel 'K' 'normal'.

        ld a, $FE               ; select system channel 'S'
        call CHAN_OPEN          ; routine CHAN-OPEN opens it.

        call TEMPS              ; routine TEMPS applies permanent attributes,
                                ; in this case ATTR_P, to ATTR_T.
                                ; Note. this seems unnecessary.

        ld b, $18               ; There are 24 lines.

        call CL_LINE            ; routine CL-LINE clears 24 text lines and sets
                                ; attributes from ATTR-P.
                                ; This routine preserves B and sets C to $21.

        ld hl, (CURCHL)         ; fetch CURCHL make HL address output routine.

        ld de, PRINT_OUT        ; address: PRINT-OUT
        ldi (hl), e             ; is made
                                ; the normal
        ld (hl), d              ; output address.

        ld (iy+SCR_CT-IY0), $01 ; set SCR_CT - scroll count - to default.

;   Note. BC already contains $1821.

        ld bc, $1821            ; reset column and line to 0,0
                                ; and continue into CL-SET, below, exiting
                                ; via PO-STORE (for the upper screen).

; --------------------
; THE 'CL-SET' ROUTINE
; --------------------
; This important subroutine is used to calculate the character output
; address for screens or printer based on the line/column for screens
; or the column for printer.

;; CL-SET

CL_SET:
        ld hl, $5B00            ; the base address of printer buffer
        bit 1, (iy+FLAGS-IY0)   ; test FLAGS  - is printer in use ?
        jr nz, CL_SET_2         ; forward to CL-SET-2 if so.

        ld a, b                 ; transfer line to A.
        bit 0, (iy+TV_FLAG-IY0) ; test TV_FLAG  - lower screen in use ?
        jr z, CL_SET_1          ; skip to CL-SET-1 if handling upper part

        add a, (iy+DF_SZ-IY0)   ; add DF_SZ for lower screen
        sub $18                 ; and adjust.

;; CL-SET-1

CL_SET_1:
        push bc                 ; save the line/column.
        ld b, a                 ; transfer line to B
                                ; (adjusted if lower screen)

        call CL_ADDR            ; routine CL-ADDR calculates address at left
                                ; of screen.
        pop bc                  ; restore the line/column.

;; CL-SET-2

CL_SET_2:
        ld a, $21               ; the column $01-$21 is reversed
        sub c                   ; to range $00 - $20
        ld e, a                 ; now transfer to DE
        ld d, $00               ; prepare for addition
        add hl, de              ; and add to base address

        jp PO_STORE             ; exit via PO-STORE to update the relevant
                                ; system variables.
                                ; ----------------
                                ; Handle scrolling
                                ; ----------------
                                ; The routine CL-SC-ALL is called once from PO to scroll all the display
                                ; and from the routine CL-SCROLL, once, to scroll part of the display.


;; CL-SC-ALL

CL_SC_ALL:
        ld b, $17               ; scroll 23 lines, after 'scroll?'.

;; CL-SCROLL

CL_SCROLL:
        call CL_ADDR            ; routine CL-ADDR gets screen address in HL.
        ld c, $08               ; there are 8 pixel lines to scroll.

;; CL-SCR-1

CL_SCR_1:
        push bc                 ; save counters.
        push hl                 ; and initial address.
        ld a, b                 ; get line count.
        and $07                 ; will set zero if all third to be scrolled.
        ld a, b                 ; re-fetch the line count.
        jr nz, CL_SCR_3         ; forward to CL-SCR-3 if partial scroll.

; HL points to top line of third and must be copied to bottom of previous 3rd.
; ( so HL = $4800 or $5000 ) ( but also sometimes $4000 )

;; CL-SCR-2

CL_SCR_2:
        ex de, hl               ; copy HL to DE.
        ld hl, $F8E0            ; subtract $08 from H and add $E0 to L -
        add hl, de              ; to make destination bottom line of previous
                                ; third.
        ex de, hl               ; restore the source and destination.
        ld bc, 32               ; thirty-two bytes are to be copied.
        dec a                   ; decrement the line count.
        ldir                    ; copy a pixel line to previous third.

;; CL-SCR-3

CL_SCR_3:
        ex de, hl               ; save source in DE.
        ld hl, $FFE0            ; load the value -32.
        add hl, de              ; add to form destination in HL.
        ex de, hl               ; switch source and destination
        ld b, a                 ; save the count in B.
        and $07                 ; mask to find count applicable to current
        rrca                    ; third and
        rrca                    ; multiply by
        rrca                    ; thirty two (same as 5 RLCAs)

        ld c, a                 ; transfer byte count to C ($E0 at most)
        ld a, b                 ; store line count to A
        ld b, $00               ; make B zero
        ldir                    ; copy bytes (BC=0, H incremented, L=0)
        ld b, $07               ; set B to 7, C is zero.
        add hl, bc              ; add 7 to H to address next third.
        and $F8                 ; has last third been done ?
        jr nz, CL_SCR_2         ; back to CL-SCR-2 if not.

        pop hl                  ; restore topmost address.
        inc h                   ; next pixel line down.
        pop bc                  ; restore counts.
        dec c                   ; reduce pixel line count.
        jr nz, CL_SCR_1         ; back to CL-SCR-1 if all eight not done.

        call CL_ATTR            ; routine CL-ATTR gets address in attributes
                                ; from current 'ninth line', count in BC.

        ld hl, $FFE0            ; set HL to the 16-bit value -32.
        add hl, de              ; and add to form destination address.
        ex de, hl               ; swap source and destination addresses.
        ldir                    ; copy bytes scrolling the linear attributes.
        ld b, $01               ; continue to clear the bottom line.

; ------------------------------
; THE 'CLEAR TEXT LINES' ROUTINE
; ------------------------------
; This subroutine, called from CL-ALL, CLS-LOWER and AUTO-LIST and above,
; clears text lines at bottom of display.
; The B register holds on entry the number of lines to be cleared 1-24.

;; CL-LINE

CL_LINE:
        push bc                 ; save line count
        call CL_ADDR            ; routine CL-ADDR gets top address
        ld c, $08               ; there are eight screen lines to a text line.

;; CL-LINE-1

CL_LINE_1:
        push bc                 ; save pixel line count
        push hl                 ; and save the address
        ld a, b                 ; transfer the line to A (1-24).

;; CL-LINE-2

CL_LINE_2:
        and $07                 ; mask 0-7 to consider thirds at a time
        rrca                    ; multiply
        rrca                    ; by 32  (same as five RLCA instructions)
        rrca                    ; now 32 - 256(0)
        ld c, a                 ; store result in C
        ld a, b                 ; save line in A (1-24)
        ld b, $00               ; set high byte to 0, prepare for ldir.
        dec c                   ; decrement count 31-255.
        ld de, hl               ; copy HL
                                ; to DE.
        ld (hl), $00            ; blank the first byte.
        inc de                  ; make DE point to next byte.
        ldir                    ; ldir will clear lines.
        ld de, $0701            ; now address next third adjusting
        add hl, de              ; register E to address left hand side
        dec a                   ; decrease the line count.
        and $F8                 ; will be 16, 8 or 0  (AND $18 will do).
        ld b, a                 ; transfer count to B.
        jr nz, CL_LINE_2        ; back to CL-LINE-2 if 16 or 8 to do
                                ; the next third.

        pop hl                  ; restore start address.
        inc h                   ; address next line down.
        pop bc                  ; fetch counts.
        dec c                   ; decrement pixel line count
        jr nz, CL_LINE_1        ; back to CL-LINE-1 till all done.

        call CL_ATTR            ; routine CL-ATTR gets attribute address
                                ; in DE and B * 32 in BC.

        ld hl, de               ; transfer the address
                                ; to HL.

        inc de                  ; make DE point to next location.

        ld a, (ATTR_P)          ; fetch ATTR_P - permanent attributes
        bit 0, (iy+TV_FLAG-IY0) ; test TV_FLAG  - lower screen in use ?
        jr z, CL_LINE_3         ; skip to CL-LINE-3 if not.

        ld a, (BORDCR)          ; else lower screen uses BORDCR as attribute.

;; CL-LINE-3

CL_LINE_3:
        ld (hl), a              ; put attribute in first byte.
        dec bc                  ; decrement the counter.
        ldir                    ; copy bytes to set all attributes.
        pop bc                  ; restore the line $01-$24.
        ld c, $21               ; make column $21. (No use is made of this)
        ret                     ; return to the calling routine.


; ------------------
; Attribute handling
; ------------------
; This subroutine is called from CL-LINE or CL-SCROLL with the HL register
; pointing to the 'ninth' line and H needs to be decremented before or after
; the division. Had it been done first then either present code or that used
; at the start of PO-ATTR could have been used.
; The Spectrum screen arrangement leads to the L register already holding 
; the correct value for the attribute file and it is only necessary
; to manipulate H to form the correct colour attribute address.

;; CL-ATTR

CL_ATTR:
        ld a, h                 ; fetch H to A - $48, $50, or $58.
        rrca                    ; divide by
        rrca                    ; eight.
        rrca                    ; $09, $0A or $0B.
        dec a                   ; $08, $09 or $0A.
        or $50                  ; $58, $59 or $5A.
        ld h, a                 ; save high byte of attributes.

        ex de, hl               ; transfer attribute address to DE
        ld h, c                 ; set H to zero - from last LDIR.
        ld l, b                 ; load L with the line from B.
        add hl, hl              ; multiply
        add hl, hl              ; by
        add hl, hl              ; thirty two
        add hl, hl              ; to give count of attribute
        add hl, hl              ; cells to the end of display.

        ld bc, hl               ; transfer the result
                                ; to register BC.

        ret                     ; return.


; -------------------------------
; Handle display with line number
; -------------------------------
; This subroutine is called from four places to calculate the address
; of the start of a screen character line which is supplied in B.

;; CL-ADDR

CL_ADDR:
        ld a, $18               ; reverse the line number
        sub b                   ; to range $00 - $17.
        ld d, a                 ; save line in D for later.
        rrca                    ; multiply
        rrca                    ; by
        rrca                    ; thirty-two.

        and $E0                 ; mask off low bits to make
        ld l, a                 ; L a multiple of 32.

        ld a, d                 ; bring back the line to A.

        and $18                 ; now $00, $08 or $10.

        or $40                  ; add the base address of screen.

        ld h, a                 ; HL now has the correct address.
        ret                     ; return.


; -------------------
; Handle COPY command
; -------------------
; This command copies the top 176 lines to the ZX Printer
; It is popular to call this from machine code at point
; L0EAF with B holding 192 (and interrupts disabled) for a full-screen
; copy. This particularly applies to 16K Spectrums as time-critical
; machine code routines cannot be written in the first 16K of RAM as
; it is shared with the ULA which has precedence over the Z80 chip.

;; COPY

COPY:
        di                      ; disable interrupts as this is time-critical.

        ld b, $B0               ; top 176 lines.

L0EAF:
        ld hl, $4000            ; address start of the display file.

; now enter a loop to handle each pixel line.

;; COPY-1

COPY_1:
        push hl                 ; save the screen address.
        push bc                 ; and the line counter.

        call COPY_LINE          ; routine COPY-LINE outputs one line.

        pop bc                  ; restore the line counter.
        pop hl                  ; and display address.
        inc h                   ; next line down screen within 'thirds'.
        ld a, h                 ; high byte to A.
        and $07                 ; result will be zero if we have left third.
        jr nz, COPY_2           ; forward to COPY-2 if not to continue loop.

        ld a, l                 ; consider low byte first.
        add a, $20              ; increase by 32 - sets carry if back to zero.
        ld l, a                 ; will be next group of 8.
        ccf                     ; complement - carry set if more lines in
                                ; the previous third.
        sbc a, a                ; will be FF, if more, else 00.
        and $F8                 ; will be F8 (-8) or 00.
        add a, h                ; that is subtract 8, if more to do in third.
        ld h, a                 ; and reset address.

;; COPY-2

COPY_2:
        djnz COPY_1             ; back to COPY-1 for all lines.

        jr COPY_END             ; forward to COPY-END to switch off the printer
                                ; motor and enable interrupts.
                                ; Note. Nothing else is required.


; ------------------------------
; Pass printer buffer to printer
; ------------------------------
; This routine is used to copy 8 text lines from the printer buffer
; to the ZX Printer. These text lines are mapped linearly so HL does
; not need to be adjusted at the end of each line.

;; COPY-BUFF

COPY_BUFF:
        di                      ; disable interrupts
        ld hl, $5B00            ; the base address of the Printer Buffer.
        ld b, $08               ; set count to 8 lines of 32 bytes.

;; COPY-3

COPY_3:
        push bc                 ; save counter.

        call COPY_LINE          ; routine COPY-LINE outputs 32 bytes

        pop bc                  ; restore counter.
        djnz COPY_3             ; loop back to COPY-3 for all 8 lines.
                                ; then stop motor and clear buffer.

; Note. the COPY command rejoins here, essentially to execute the next
; three instructions.

;; COPY-END

COPY_END:
        ld a, $04               ; output value 4 to port
        out ($FB), a            ; to stop the slowed printer motor.
        ei                      ; enable interrupts.

; --------------------
; Clear Printer Buffer
; --------------------
; This routine clears an arbitrary 256 bytes of memory.
; Note. The routine seems designed to clear a buffer that follows the
; system variables.
; The routine should check a flag or HL address and simply return if COPY
; is in use.
; As a consequence of this omission the buffer will needlessly
; be cleared when COPY is used and the screen/printer position may be set to
; the start of the buffer and the line number to 0 (B)
; giving an 'Out of Screen' error.
; There seems to have been an unsuccessful attempt to circumvent the use
; of PR_CC_hi.

;; CLEAR-PRB

CLEAR_PRB:
        ld hl, $5B00            ; the location of the buffer.
        ld (iy+PR_CC-IY0), l    ; update PR_CC_lo - set to zero - superfluous.
        xor a                   ; clear the accumulator.
        ld b, a                 ; set count to 256 bytes.

;; PRB-BYTES

PRB_BYTES:
        ldi (hl), a             ; set addressed location to zero.
                                ; address next byte - Note. not INC L.
        djnz PRB_BYTES          ; back to PRB-BYTES. repeat for 256 bytes.

        res 1, (iy+FLAGS2-IY0)  ; set FLAGS2 - signal printer buffer is clear.
        ld c, $21               ; set the column position .
        jp CL_SET               ; exit via CL-SET and then PO-STORE.


; -----------------
; Copy line routine
; -----------------
; This routine is called from COPY and COPY-BUFF to output a line of
; 32 bytes to the ZX Printer.
; Output to port $FB -
; bit 7 set - activate stylus.
; bit 7 low - deactivate stylus.
; bit 2 set - stops printer.
; bit 2 reset - starts printer
; bit 1 set - slows printer.
; bit 1 reset - normal speed.

;; COPY-LINE

COPY_LINE:
        ld a, b                 ; fetch the counter 1-8 or 1-176
        cp $03                  ; is it 01 or 02 ?.
        sbc a, a                ; result is $FF if so else $00.
        and $02                 ; result is 02 now else 00.
                                ; bit 1 set slows the printer.
        out ($FB), a            ; slow the printer for the
                                ; last two lines.
        ld d, a                 ; save the mask to control the printer later.

;; COPY-L-1

COPY_L_1:
        call BREAK_KEY          ; call BREAK-KEY to read keyboard immediately.
        jr c, COPY_L_2          ; forward to COPY-L-2 if 'break' not pressed.

        ld a, $04               ; else stop the
        out ($FB), a            ; printer motor.
        ei                      ; enable interrupts.
        call CLEAR_PRB          ; call routine CLEAR-PRB.
                                ; Note. should not be cleared if COPY in use.

;; REPORT-Dc

REPORT_Dc:
        rst $08                 ; ERROR-1
        defb $0C                ; Error Report: BREAK - CONT repeats

;; COPY-L-2

COPY_L_2:
        in a, ($FB)             ; test now to see if
        add a, a                ; a printer is attached.
        ret m                   ; return if not - but continue with parent
                                ; command.

        jr nc, COPY_L_1         ; back to COPY-L-1 if stylus of printer not
                                ; in position.

        ld c, $20               ; set count to 32 bytes.

;; COPY-L-3

COPY_L_3:
        ldi e, (hl)             ; fetch a byte from line.
                                ; address next location. Note. not INC L.
        ld b, $08               ; count the bits.

;; COPY-L-4

COPY_L_4:
        rl d                    ; prepare mask to receive bit.
        rl e                    ; rotate leftmost print bit to carry
        rr d                    ; and back to bit 7 of D restoring bit 1

;; COPY-L-5

COPY_L_5:
        in a, ($FB)             ; read the port.
        rra                     ; bit 0 to carry.
        jr nc, COPY_L_5         ; back to COPY-L-5 if stylus not in position.

        ld a, d                 ; transfer command bits to A.
        out ($FB), a            ; and output to port.
        djnz COPY_L_4           ; loop back to COPY-L-4 for all 8 bits.

        dec c                   ; decrease the byte count.
        jr nz, COPY_L_3         ; back to COPY-L-3 until 256 bits done.

        ret                     ; return to calling routine COPY/COPY-BUFF.



; ----------------------------------
; Editor routine for BASIC and INPUT
; ----------------------------------
; The editor is called to prepare or edit a BASIC line.
; It is also called from INPUT to input a numeric or string expression.
; The behaviour and options are quite different in the various modes
; and distinguished by bit 5 of FLAGX.
;
; This is a compact and highly versatile routine.

;; EDITOR

EDITOR:
        ld hl, (ERR_SP)         ; fetch ERR_SP
        push hl                 ; save on stack

;; ED-AGAIN

ED_AGAIN:
        ld hl, ED_ERROR         ; address: ED-ERROR
        push hl                 ; save address on stack and
        ld (ERR_SP), sp         ; make ERR_SP point to it.

; Note. While in editing/input mode should an error occur then RST 08 will
; update X_PTR to the location reached by CH_ADD and jump to ED-ERROR
; where the error will be cancelled and the loop begin again from ED-AGAIN
; above. The position of the error will be apparent when the lower screen is
; reprinted. If no error then the re-iteration is to ED-LOOP below when
; input is arriving from the keyboard.

;; ED-LOOP

ED_LOOP:
        call WAIT_KEY           ; routine WAIT-KEY gets key possibly
                                ; changing the mode.
        push af                 ; save key.
        ld d, $00               ; and give a short click based
        ld e, (iy+PIP-IY0)      ; on PIP value for duration.
        ld hl, $00C8            ; and pitch.
        call BEEPER             ; routine BEEPER gives click - effective
                                ; with rubber keyboard.
        pop af                  ; get saved key value.
        ld hl, ED_LOOP          ; address: ED-LOOP is loaded to HL.
        push hl                 ; and pushed onto stack.

; At this point there is a looping return address on the stack, an error
; handler and an input stream set up to supply characters.
; The character that has been received can now be processed.

        cp $18                  ; range 24 to 255 ?
        jr nc, ADD_CHAR         ; forward to ADD-CHAR if so.

        cp $07                  ; lower than 7 ?
        jr c, ADD_CHAR          ; forward to ADD-CHAR also.
                                ; Note. This is a 'bug' and chr$ 6, the comma
                                ; control character, should have had an
                                ; entry in the ED-KEYS table.
                                ; Steven Vickers, 1984, Pitman.

        cp $10                  ; less than 16 ?
        jr c, ED_KEYS           ; forward to ED-KEYS if editing control
                                ; range 7 to 15 dealt with by a table

        ld bc, $0002            ; prepare for ink/paper etc.
        ld d, a                 ; save character in D
        cp $16                  ; is it ink/paper/bright etc. ?
        jr c, ED_CONTR          ; forward to ED-CONTR if so

                                ; leaves 22d AT and 23d TAB
                                ; which can't be entered via KEY-INPUT.
                                ; so this code is never normally executed
                                ; when the keyboard is used for input.

        inc bc                  ; if it was AT/TAB - 3 locations required
        bit 7, (iy+FLAGX-IY0)   ; test FLAGX  - Is this INPUT LINE ?
        jp z, ED_IGNORE         ; jump to ED-IGNORE if not, else

        call WAIT_KEY           ; routine WAIT-KEY - input address is KEY-NEXT
                                ; but is reset to KEY-INPUT
        ld e, a                 ; save first in E

;; ED-CONTR

ED_CONTR:
        call WAIT_KEY           ; routine WAIT-KEY for control.
                                ; input address will be key-next.

        push de                 ; saved code/parameters
        ld hl, (K_CUR)          ; fetch address of keyboard cursor from K_CUR
        res 0, (iy+MODE-IY0)    ; set MODE to 'L'

        call MAKE_ROOM          ; routine MAKE-ROOM makes 2/3 spaces at cursor

        pop bc                  ; restore code/parameters
        inc hl                  ; address first location
        ldi (hl), b             ; place code (ink etc.)
                                ; address next
        ld (hl), c              ; place possible parameter. If only one
                                ; then DE points to this location also.
        jr ADD_CH_1             ; forward to ADD-CH-1


; ------------------------
; Add code to current line
; ------------------------
; this is the branch used to add normal non-control characters
; with ED-LOOP as the stacked return address.
; it is also the OUTPUT service routine for system channel 'R'.

;; ADD-CHAR

ADD_CHAR:
        res 0, (iy+MODE-IY0)    ; set MODE to 'L'


X0F85:
        ld hl, (K_CUR)          ; fetch address of keyboard cursor from K_CUR

        call ONE_SPACE          ; routine ONE-SPACE creates one space.

; either a continuation of above or from ED-CONTR with ED-LOOP on stack.

;; ADD-CH-1

ADD_CH_1:
        ldi (de), a             ; load current character to last new location.
                                ; address next
        ld (K_CUR), de          ; and update K_CUR system variable.
        ret                     ; return - either a simple return
                                ; from ADD-CHAR or to ED-LOOP on stack.


; ---

; a branch of the editing loop to deal with control characters
; using a look-up table.

;; ED-KEYS

ED_KEYS:
        ld e, a                 ; character to E.
        ld d, $00               ; prepare to add.
        ld hl, ed_keys_t-$07    ; base address of editing keys table. $0F99
        add hl, de              ; add E
        ld e, (hl)              ; fetch offset to E
        add hl, de              ; add offset for address of handling routine.
        push hl                 ; push the address on machine stack.
        ld hl, (K_CUR)          ; load address of cursor from K_CUR.
        ret                     ; Make an indirect jump forward to routine.


; ------------------
; Editing keys table
; ------------------
; For each code in the range $07 to $0F this table contains a
; single offset byte to the routine that services that code.
; Note. for what was intended there should also have been an
; entry for chr$ 6 with offset to ed-symbol.

;; ed-keys-t

ed_keys_t:
        defb ED_EDIT - $        ; 07d offset $09 to Address: ED-EDIT
        defb ED_LEFT - $        ; 08d offset $66 to Address: ED-LEFT
        defb ED_RIGHT - $       ; 09d offset $6A to Address: ED-RIGHT
        defb ED_DOWN - $        ; 10d offset $50 to Address: ED-DOWN
        defb ED_UP - $          ; 11d offset $B5 to Address: ED-UP
        defb ED_DELETE - $      ; 12d offset $70 to Address: ED-DELETE
        defb ED_ENTER - $       ; 13d offset $7E to Address: ED-ENTER
        defb ED_SYMBOL - $      ; 14d offset $CF to Address: ED-SYMBOL
        defb ED_GRAPH - $       ; 15d offset $D4 to Address: ED-GRAPH

; ---------------
; Handle EDIT key
; ---------------
; The user has pressed SHIFT 1 to bring edit line down to bottom of screen.
; Alternatively the user wishes to clear the input buffer and start again.
; Alternatively ...

;; ED-EDIT

ED_EDIT:
        ld hl, (E_PPC)          ; fetch E_PPC the last line number entered.
                                ; Note. may not exist and may follow program.
        bit 5, (iy+FLAGX-IY0)   ; test FLAGX  - input mode ?
        jp nz, CLEAR_SP         ; jump forward to CLEAR-SP if not in editor.

        call LINE_ADDR          ; routine LINE-ADDR to find address of line
                                ; or following line if it doesn't exist.
        call LINE_NO            ; routine LINE-NO will get line number from
                                ; address or previous line if at end-marker.
        ld a, d                 ; if there is no program then DE will
        or e                    ; contain zero so test for this.
        jp z, CLEAR_SP          ; jump to CLEAR-SP if so.

; Note. at this point we have a validated line number, not just an
; approximation and it would be best to update E_PPC with the true
; cursor line value which would enable the line cursor to be suppressed
; in all situations - see shortly.

        push hl                 ; save address of line.
        inc hl                  ; address low byte of length.
        ldi c, (hl)             ; transfer to C
                                ; next to high byte
        ld b, (hl)              ; transfer to B.
        ld hl, $000A            ; an overhead of ten bytes
        add hl, bc              ; is added to length.
        ld bc, hl               ; transfer adjusted value
                                ; to BC register.
        call TEST_ROOM          ; routine TEST-ROOM checks free memory.
        call CLEAR_SP           ; routine CLEAR-SP clears editing area.
        ld hl, (CURCHL)         ; address CURCHL
        ex (sp), hl             ; swap with line address on stack
        push hl                 ; save line address underneath

        ld a, $FF               ; select system channel 'R'
        call CHAN_OPEN          ; routine CHAN-OPEN opens it

        pop hl                  ; drop line address
        dec hl                  ; make it point to first byte of line num.
        dec (iy+E_PPC-IY0)      ; decrease E_PPC_lo to suppress line cursor.
                                ; Note. ineffective when E_PPC is one
                                ; greater than last line of program perhaps
                                ; as a result of a delete.
                                ; credit. Paul Harrison 1982.

        call OUT_LINE           ; routine OUT-LINE outputs the BASIC line
                                ; to the editing area.
        inc (iy+E_PPC-IY0)      ; restore E_PPC_lo to the previous value.
        ld hl, (E_LINE)         ; address E_LINE in editing area.
        inc hl                  ; advance
        inc hl                  ; past space
        inc hl                  ; and digit characters
        inc hl                  ; of line number.

        ld (K_CUR), hl          ; update K_CUR to address start of BASIC.
        pop hl                  ; restore the address of CURCHL.
        call CHAN_FLAG          ; routine CHAN-FLAG sets flags for it.

        ret                     ; RETURN to ED-LOOP.


; -------------------
; Cursor down editing
; -------------------
;   The BASIC lines are displayed at the top of the screen and the user
;   wishes to move the cursor down one line in edit mode.
;   With INPUT LINE, this key must be used instead of entering STOP.

;; ED-DOWN

ED_DOWN:
        bit 5, (iy+FLAGX-IY0)   ; test FLAGX  - Input Mode ?
        jr nz, ED_STOP          ; skip to ED-STOP if so

        ld hl, E_PPC            ; address E_PPC - 'current line'
        call LN_FETCH           ; routine LN-FETCH fetches number of next
                                ; line or same if at end of program.
        jr ED_LIST              ; forward to ED-LIST to produce an
                                ; automatic listing.


; ---

;; ED-STOP

ED_STOP:
        ld (iy+ERR_NR-IY0), $10 ; set ERR_NR to 'STOP in INPUT' code
        jr ED_ENTER             ; forward to ED-ENTER to produce error.


; -------------------
; Cursor left editing
; -------------------
; This acts on the cursor in the lower section of the screen in both
; editing and input mode.

;; ED-LEFT

ED_LEFT:
        call ED_EDGE            ; routine ED-EDGE moves left if possible
        jr ED_CUR               ; forward to ED-CUR to update K-CUR
                                ; and return to ED-LOOP.


; --------------------
; Cursor right editing
; --------------------
; This acts on the cursor in the lower screen in both editing and input
; mode and moves it to the right.

;; ED-RIGHT

ED_RIGHT:
        ld a, (hl)              ; fetch addressed character.
        cp $0D                  ; is it carriage return ?
        ret z                   ; return if so to ED-LOOP

        inc hl                  ; address next character

;; ED-CUR

ED_CUR:
        ld (K_CUR), hl          ; update K_CUR system variable
        ret                     ; return to ED-LOOP


; --------------
; DELETE editing
; --------------
; This acts on the lower screen and deletes the character to left of
; cursor. If control characters are present these are deleted first
; leaving the naked parameter (0-7) which appears as a '?' except in the
; case of chr$ 6 which is the comma control character. It is not mandatory
; to delete these second characters.

;; ED-DELETE

ED_DELETE:
        call ED_EDGE            ; routine ED-EDGE moves cursor to left.
        ld bc, $0001            ; of character to be deleted.
        jp RECLAIM_2            ; to RECLAIM-2 reclaim the character.


; ------------------------------------------
; Ignore next 2 codes from key-input routine
; ------------------------------------------
; Since AT and TAB cannot be entered this point is never reached
; from the keyboard. If inputting from a tape device or network then
; the control and two following characters are ignored and processing
; continues as if a carriage return had been received.
; Here, perhaps, another Spectrum has said print #15; AT 0,0; "This is yellow"
; and this one is interpreting input #15; a$.

;; ED-IGNORE

ED_IGNORE:
        call WAIT_KEY           ; routine WAIT-KEY to ignore keystroke.
        call WAIT_KEY           ; routine WAIT-KEY to ignore next key.

; -------------
; Enter/newline
; -------------
; The enter key has been pressed to have BASIC line or input accepted.

;; ED-ENTER

ED_ENTER:
        pop hl                  ; discard address ED-LOOP
        pop hl                  ; drop address ED-ERROR

;; ED-END

ED_END:
        pop hl                  ; the previous value of ERR_SP
        ld (ERR_SP), hl         ; is restored to ERR_SP system variable
        bit 7, (iy+ERR_NR-IY0)  ; is ERR_NR $FF (= 'OK') ?
        ret nz                  ; return if so

        ld sp, hl               ; else put error routine on stack
        ret                     ; and make an indirect jump to it.


; -----------------------------
; Move cursor left when editing
; -----------------------------
; This routine moves the cursor left. The complication is that it must
; not position the cursor between control codes and their parameters.
; It is further complicated in that it deals with TAB and AT characters
; which are never present from the keyboard.
; The method is to advance from the beginning of the line each time,
; jumping one, two, or three characters as necessary saving the original
; position at each jump in DE. Once it arrives at the cursor then the next
; legitimate leftmost position is in DE.

;; ED-EDGE

ED_EDGE:
        scf                     ; carry flag must be set to call the nested
        call SET_DE             ; subroutine SET-DE.
                                ; if input   then DE=WORKSP
                                ; if editing then DE=E_LINE
        sbc hl, de              ; subtract address from start of line
        add hl, de              ; and add back.
        inc hl                  ; adjust for carry.
        pop bc                  ; drop return address
        ret c                   ; return to ED-LOOP if already at left
                                ; of line.

        push bc                 ; resave return address - ED-LOOP.
        ld bc, hl               ; transfer HL - cursor address
                                ; to BC register pair.
                                ; at this point DE addresses start of line.

;; ED-EDGE-1

ED_EDGE_1:
        ld hl, de               ; transfer DE - leftmost pointer
                                ; to HL
        inc hl                  ; address next leftmost character to
                                ; advance position each time.
        ld a, (de)              ; pick up previous in A
        and $F0                 ; lose the low bits
        cp $10                  ; is it INK to TAB $10-$1F ?
                                ; that is, is it followed by a parameter ?
        jr nz, ED_EDGE_2        ; to ED-EDGE-2 if not
                                ; HL has been incremented once

        inc hl                  ; address next as at least one parameter.

; in fact since 'tab' and 'at' cannot be entered the next section seems
; superfluous.
; The test will always fail and the jump to ED-EDGE-2 will be taken.

        ld a, (de)              ; reload leftmost character
        sub $17                 ; decimal 23 ('tab')
        adc a, $00              ; will be 0 for 'tab' and 'at'.
        jr nz, ED_EDGE_2        ; forward to ED-EDGE-2 if not
                                ; HL has been incremented twice

        inc hl                  ; increment a third time for 'at'/'tab'

;; ED-EDGE-2

ED_EDGE_2:
        and a                   ; prepare for true subtraction
        sbc hl, bc              ; subtract cursor address from pointer
        add hl, bc              ; and add back
                                ; Note when HL matches the cursor position BC,
                                ; there is no carry and the previous
                                ; position is in DE.
        ex de, hl               ; transfer result to DE if looping again.
                                ; transfer DE to HL to be used as K-CUR
                                ; if exiting loop.
        jr c, ED_EDGE_1         ; back to ED-EDGE-1 if cursor not matched.

        ret                     ; return.


; -----------------
; Cursor up editing
; -----------------
; The main screen displays part of the BASIC program and the user wishes
; to move up one line scrolling if necessary.
; This has no alternative use in input mode.

;; ED-UP

ED_UP:
        bit 5, (iy+FLAGX-IY0)   ; test FLAGX  - input mode ?
        ret nz                  ; return if not in editor - to ED-LOOP.

        ld hl, (E_PPC)          ; get current line from E_PPC
        call LINE_ADDR          ; routine LINE-ADDR gets address
        ex de, hl               ; and previous in DE
        call LINE_NO            ; routine LINE-NO gets prev line number
        ld hl, $5C4A            ; set HL to E_PPC_hi as next routine stores
                                ; top first.
        call LN_STORE           ; routine LN-STORE loads DE value to HL
                                ; high byte first - E_PPC_lo takes E

; this branch is also taken from ed-down.

;; ED-LIST

ED_LIST:
        call AUTO_LIST          ; routine AUTO-LIST lists to upper screen
                                ; including adjusted current line.
        ld a, $00               ; select lower screen again
        jp CHAN_OPEN            ; exit via CHAN-OPEN to ED-LOOP


; --------------------------------
; Use of symbol and graphics codes
; --------------------------------
; These will not be encountered with the keyboard but would be handled
; otherwise as follows.
; As noted earlier, Vickers says there should have been an entry in
; the KEYS table for chr$ 6 which also pointed here.
; If, for simplicity, two Spectrums were both using #15 as a bi-directional
; channel connected to each other:-
; then when the other Spectrum has said PRINT #15; x, y
; input #15; i ; j  would treat the comma control as a newline and the
; control would skip to input j.
; You can get round the missing chr$ 6 handler by sending multiple print
; items separated by a newline '.

; chr$14 would have the same functionality.

; This is chr$ 14.
;; ED-SYMBOL

ED_SYMBOL:
        bit 7, (iy+FLAGX-IY0)   ; test FLAGX - is this INPUT LINE ?
        jr z, ED_ENTER          ; back to ED-ENTER if not to treat as if
                                ; enter had been pressed.
                                ; else continue and add code to buffer.

; Next is chr$ 15
; Note that ADD-CHAR precedes the table so we can't offset to it directly.

;; ED-GRAPH

ED_GRAPH:
        jp ADD_CHAR             ; jump back to ADD-CHAR


; --------------------
; Editor error routine
; --------------------
; If an error occurs while editing, or inputting, then ERR_SP
; points to the stack location holding address ED_ERROR.

;; ED-ERROR

ED_ERROR:
        bit 4, (iy+FLAGS2-IY0)  ; test FLAGS2  - is K channel in use ?
        jr z, ED_END            ; back to ED-END if not.

; but as long as we're editing lines or inputting from the keyboard, then
; we've run out of memory so give a short rasp.

        ld (iy+ERR_NR-IY0), $FF ; reset ERR_NR to 'OK'.
        ld d, $00               ; prepare for beeper.
        ld e, (iy+RASP-IY0)     ; use RASP value.
        ld hl, $1A90            ; set the pitch - or tone period.
        call BEEPER             ; routine BEEPER emits a warning rasp.
        jp ED_AGAIN             ; to ED-AGAIN to re-stack address of
                                ; this routine and make ERR_SP point to it.


; ---------------------
; Clear edit/work space
; ---------------------
; The editing area or workspace is cleared depending on context.
; This is called from ED-EDIT to clear workspace if edit key is
; used during input, to clear editing area if no program exists
; and to clear editing area prior to copying the edit line to it.
; It is also used by the error routine to clear the respective
; area depending on FLAGX.

;; CLEAR-SP

CLEAR_SP:
        push hl                 ; preserve HL
        call SET_HL             ; routine SET-HL
                                ; if in edit   HL = WORKSP-1, DE = E_LINE
                                ; if in input  HL = STKBOT,   DE = WORKSP
        dec hl                  ; adjust
        call RECLAIM_1          ; routine RECLAIM-1 reclaims space
        ld (K_CUR), hl          ; set K_CUR to start of empty area
        ld (iy+MODE-IY0), $00   ; set MODE to 'KLC'
        pop hl                  ; restore HL.
        ret                     ; return.


; ----------------------------
; THE 'KEYBOARD INPUT' ROUTINE
; ----------------------------
; This is the service routine for the input stream of the keyboard channel 'K'.

;; KEY-INPUT

KEY_INPUT:
        bit 3, (iy+TV_FLAG-IY0) ; test TV_FLAG  - has a key been pressed in
                                ; editor ?

        call nz, ED_COPY        ; routine ED-COPY, if so, to reprint the lower
                                ; screen at every keystroke/mode change.

        and a                   ; clear carry flag - required exit condition.

        bit 5, (iy+FLAGS-IY0)   ; test FLAGS  - has a new key been pressed ?
        ret z                   ; return if not.                        >>

        ld a, (LAST_K)          ; system variable LASTK will hold last key -
                                ; from the interrupt routine.

        res 5, (iy+FLAGS-IY0)   ; update FLAGS  - reset the new key flag.
        push af                 ; save the input character.

        bit 5, (iy+TV_FLAG-IY0) ; test TV_FLAG  - clear lower screen ?

        call nz, CLS_LOWER      ; routine CLS-LOWER if so.

        pop af                  ; restore the character code.

        cp $20                  ; if space or higher then
        jr nc, KEY_DONE2        ; forward to KEY-DONE2 and return with carry
                                ; set to signal key-found.

        cp $10                  ; with 16d INK and higher skip
        jr nc, KEY_CONTR        ; forward to KEY-CONTR.

        cp $06                  ; for 6 - 15d
        jr nc, KEY_M_CL         ; skip forward to KEY-M-CL to handle Modes
                                ; and CapsLock.

; that only leaves 0-5, the flash bright inverse switches.

        ld b, a                 ; save character in B
        and $01                 ; isolate the embedded parameter (0/1).
        ld c, a                 ; and store in C
        ld a, b                 ; re-fetch copy (0-5)
        rra                     ; halve it 0, 1 or 2.
        add a, $12              ; add 18d gives 'flash', 'bright'
                                ; and 'inverse'.
        jr KEY_DATA             ; forward to KEY-DATA with the
                                ; parameter (0/1) in C.


; ---

; Now separate capslock 06 from modes 7-15.

;; KEY-M-CL

KEY_M_CL:
        jr nz, KEY_MODE         ; forward to KEY-MODE if not 06 (capslock)

        ld hl, FLAGS2           ; point to FLAGS2
        ld a, $08               ; value 00001000
        xor (hl)                ; toggle BIT 3 of FLAGS2 the capslock bit
        ld (hl), a              ; and store result in FLAGS2 again.
        jr KEY_FLAG             ; forward to KEY-FLAG to signal no-key.


; ---

;; KEY-MODE

KEY_MODE:
        cp $0E                  ; compare with chr 14d
        ret c                   ; return with carry set "key found" for
                                ; codes 7 - 13d leaving 14d and 15d
                                ; which are converted to mode codes.

        sub $0D                 ; subtract 13d leaving 1 and 2
                                ; 1 is 'E' mode, 2 is 'G' mode.
        ld hl, MODE             ; address the MODE system variable.
        cp (hl)                 ; compare with existing value before
        ld (hl), a              ; inserting the new value.
        jr nz, KEY_FLAG         ; forward to KEY-FLAG if it has changed.

        ld (hl), $00            ; else make MODE zero - KLC mode
                                ; Note. while in Extended/Graphics mode,
                                ; the Extended Mode/Graphics key is pressed
                                ; again to get out.

;; KEY-FLAG

KEY_FLAG:
        set 3, (iy+TV_FLAG-IY0) ; update TV_FLAG  - show key state has changed
        cp a                    ; clear carry and reset zero flags -
                                ; no actual key returned.
        ret                     ; make the return.


; ---

; now deal with colour controls - 16-23 ink, 24-31 paper

;; KEY-CONTR

KEY_CONTR:
        ld b, a                 ; make a copy of character.
        and $07                 ; mask to leave bits 0-7
        ld c, a                 ; and store in C.
        ld a, $10               ; initialize to 16d - INK.
        bit 3, b                ; was it paper ?
        jr nz, KEY_DATA         ; forward to KEY-DATA with INK 16d and
                                ; colour in C.

        inc a                   ; else change from INK to PAPER (17d) if so.

;; KEY-DATA

KEY_DATA:
        ld (iy+K_DATA-IY0), c   ; put the colour (0-7)/state(0/1) in KDATA
        ld de, KEY_NEXT         ; address: KEY-NEXT will be next input stream
        jr KEY_CHAN             ; forward to KEY-CHAN to change it ...


; ---

; ... so that INPUT_AD directs control to here at next call to WAIT-KEY

;; KEY-NEXT

KEY_NEXT:
        ld a, (K_DATA)          ; pick up the parameter stored in KDATA.
        ld de, KEY_INPUT        ; address: KEY-INPUT will be next input stream
                                ; continue to restore default channel and
                                ; make a return with the control code.

;; KEY-CHAN

KEY_CHAN:
        ld hl, (CHANS)          ; address start of CHANNELS area using CHANS
                                ; system variable.
                                ; Note. One might have expected CURCHL to
                                ; have been used.
        inc hl                  ; step over the
        inc hl                  ; output address
        ldi (hl), e             ; and update the input
                                ; routine address for
        ld (hl), d              ; the next call to WAIT-KEY.

;; KEY-DONE2

KEY_DONE2:
        scf                     ; set carry flag to show a key has been found
        ret                     ; and return.


; --------------------
; Lower screen copying
; --------------------
; This subroutine is called whenever the line in the editing area or
; input workspace is required to be printed to the lower screen.
; It is by calling this routine after any change that the cursor, for
; instance, appears to move to the left.
; Remember the edit line will contain characters and tokens
; e.g. "1000 LET a=1" is 8 characters.

;; ED-COPY

ED_COPY:
        call TEMPS              ; routine TEMPS sets temporary attributes.
        res 3, (iy+TV_FLAG-IY0) ; update TV_FLAG  - signal no change in mode
        res 5, (iy+TV_FLAG-IY0) ; update TV_FLAG  - signal don't clear lower
                                ; screen.
        ld hl, (SPOSNL)         ; fetch SPOSNL
        push hl                 ; and save on stack.

        ld hl, (ERR_SP)         ; fetch ERR_SP
        push hl                 ; and save also
        ld hl, ED_FULL          ; address: ED-FULL
        push hl                 ; is pushed as the error routine
        ld (ERR_SP), sp         ; and ERR_SP made to point to it.

        ld hl, (ECHO_E)         ; fetch ECHO_E
        push hl                 ; and push also

        scf                     ; set carry flag to control SET-DE
        call SET_DE             ; call routine SET-DE
                                ; if in input DE = WORKSP
                                ; if in edit  DE = E_LINE
        ex de, hl               ; start address to HL

        call OUT_LINE2          ; routine OUT-LINE2 outputs entire line up to
                                ; carriage return including initial
                                ; characterized line number when present.
        ex de, hl               ; transfer new address to DE
        call OUT_CURS           ; routine OUT-CURS considers a
                                ; terminating cursor.

        ld hl, (SPOSNL)         ; fetch updated SPOSNL
        ex (sp), hl             ; exchange with ECHO_E on stack
        ex de, hl               ; transfer ECHO_E to DE
        call TEMPS              ; routine TEMPS to re-set attributes
                                ; if altered.

; the lower screen was not cleared, at the outset, so if deleting then old
; text from a previous print may follow this line and requires blanking.

;; ED-BLANK

ED_BLANK:
        ld a, ($5C8B)           ; fetch SPOSNL_hi is current line
        sub d                   ; compare with old
        jr c, ED_C_DONE         ; forward to ED-C-DONE if no blanking

        jr nz, ED_SPACES        ; forward to ED-SPACES if line has changed

        ld a, e                 ; old column to A
        sub (iy+SPOSNL-IY0)     ; subtract new in SPOSNL_lo
        jr nc, ED_C_DONE        ; forward to ED-C-DONE if no backfilling.

;; ED-SPACES

ED_SPACES:
        ld a, $20               ; prepare a space.
        push de                 ; save old line/column.
        call PRINT_OUT          ; routine PRINT-OUT prints a space over
                                ; any text from previous print.
                                ; Note. Since the blanking only occurs when
                                ; using $09F4 to print to the lower screen,
                                ; there is no need to vector via a RST 10
                                ; and we can use this alternate set.
        pop de                  ; restore the old line column.
        jr ED_BLANK             ; back to ED-BLANK until all old text blanked.


; -------------------------------
; THE 'EDITOR-FULL' ERROR ROUTINE
; -------------------------------
;   This is the error routine addressed by ERR_SP.  This is not for the out of
;   memory situation as we're just printing.  The pitch and duration are exactly
;   the same as used by ED-ERROR from which this has been augmented.  The
;   situation is that the lower screen is full and a rasp is given to suggest
;   that this is perhaps not the best idea you've had that day.

;; ED-FULL

ED_FULL:
        ld d, $00               ; prepare to moan.
        ld e, (iy+RASP-IY0)     ; fetch RASP value.
        ld hl, $1A90            ; set pitch or tone period.

        call BEEPER             ; routine BEEPER.

        ld (iy+ERR_NR-IY0), $FF ; clear ERR_NR.
        ld de, (SPOSNL)         ; fetch SPOSNL.
        jr ED_C_END             ; forward to ED-C-END


; -------

; the exit point from line printing continues here.

;; ED-C-DONE

ED_C_DONE:
        pop de                  ; fetch new line/column.
        pop hl                  ; fetch the error address.

; the error path rejoins here.

;; ED-C-END

ED_C_END:
        pop hl                  ; restore the old value of ERR_SP.
        ld (ERR_SP), hl         ; update the system variable ERR_SP

        pop bc                  ; old value of SPOSN_L
        push de                 ; save new value

        call CL_SET             ; routine CL-SET and PO-STORE
                                ; update ECHO_E and SPOSN_L from BC

        pop hl                  ; restore new value
        ld (ECHO_E), hl         ; and overwrite ECHO_E

        ld (iy+$26), $00        ; make error pointer X_PTR_hi out of bounds

        ret                     ; return


; -----------------------------------------------
; Point to first and last locations of work space
; -----------------------------------------------
;   These two nested routines ensure that the appropriate pointers are
;   selected for the editing area or workspace. The routines that call
;   these routines are designed to work on either area.

; this routine is called once

;; SET-HL

SET_HL:
        ld hl, (WORKSP)         ; fetch WORKSP to HL.
        dec hl                  ; point to last location of editing area.
        and a                   ; clear carry to limit exit points to first
                                ; or last.

; this routine is called with carry set and exits at a conditional return.

;; SET-DE

SET_DE:
        ld de, (E_LINE)         ; fetch E_LINE to DE
        bit 5, (iy+FLAGX-IY0)   ; test FLAGX  - Input Mode ?
        ret z                   ; return now if in editing mode

        ld de, (WORKSP)         ; fetch WORKSP to DE
        ret c                   ; return if carry set ( entry = set-de)

        ld hl, (STKBOT)         ; fetch STKBOT to HL as well
        ret                     ; and return  (entry = set-hl (in input))


; -----------------------------------
; THE 'REMOVE FLOATING POINT' ROUTINE
; -----------------------------------
;   When a BASIC LINE or the INPUT BUFFER is parsed any numbers will have
;   an invisible chr 14d inserted after them and the 5-byte integer or
;   floating point form inserted after that.  Similar invisible value holders
;   are also created after the numeric and string variables in a DEF FN list.
;   This routine removes these 'compiled' numbers from the edit line or
;   input workspace.

;; REMOVE-FP

REMOVE_FP:
        ld a, (hl)              ; fetch character
        cp $0E                  ; is it the CHR$ 14 number marker ?
        ld bc, $0006            ; prepare to strip six bytes

        call z, RECLAIM_2       ; routine RECLAIM-2 reclaims bytes if CHR$ 14.

        ldi a, (hl)             ; reload next (or same) character
                                ; and advance address
        cp $0D                  ; end of line or input buffer ?
        jr nz, REMOVE_FP        ; back to REMOVE-FP until entire line done.

        ret                     ; return.



; *********************************
; ** Part 6. EXECUTIVE ROUTINES  **
; *********************************


; The memory.
;
; +---------+-----------+------------+--------------+-------------+--
; | BASIC   |  Display  | Attributes | ZX Printer   |    System   | 
; |  ROM    |   File    |    File    |   Buffer     |  Variables  | 
; +---------+-----------+------------+--------------+-------------+--
; ^         ^           ^            ^              ^             ^
; $0000   $4000       $5800        $5B00          $5C00         $5CB6 = CHANS 
;
;
;  --+----------+---+---------+-----------+---+------------+--+---+--
;    | Channel  |$80|  BASIC  | Variables |$80| Edit Line  |NL|$80|
;    |   Info   |   | Program |   Area    |   | or Command |  |   |
;  --+----------+---+---------+-----------+---+------------+--+---+--
;    ^              ^         ^               ^                   ^
;  CHANS           PROG      VARS           E_LINE              WORKSP
;
;
;                             ---5-->         <---2---  <--3---
;  --+-------+--+------------+-------+-------+---------+-------+-+---+------+
;    | INPUT |NL| Temporary  | Calc. | Spare | Machine | GOSUB |?|$3E| UDGs |
;    | data  |  | Work Space | Stack |       |  Stack  | Stack | |   |      |
;  --+-------+--+------------+-------+-------+---------+-------+-+---+------+
;    ^                       ^       ^       ^                   ^   ^      ^
;  WORKSP                  STKBOT  STKEND   sp               RAMTOP UDG  P_RAMT
;                                                                         

; -----------------
; THE 'NEW' COMMAND
; -----------------
;   The NEW command is about to set all RAM below RAMTOP to zero and then
;   re-initialize the system.  All RAM above RAMTOP should, and will be,
;   preserved.
;   There is nowhere to store values in RAM or on the stack which becomes
;   inoperable. Similarly PUSH and CALL instructions cannot be used to store
;   values or section common code. The alternate register set is the only place
;   available to store 3 persistent 16-bit system variables.

;; NEW

NEW:
        di                      ; Disable Interrupts - machine stack will be
                                ; cleared.
        ld a, $FF               ; Flag coming from NEW.
        ld de, (RAMTOP)         ; Fetch RAMTOP as top value.
        exx                     ; Switch in alternate set.
        ld bc, (P_RAMT)         ; Fetch P-RAMT differs on 16K/48K machines.
        ld de, (RASP)           ; Fetch RASP/PIP.
        ld hl, (UDG)            ; Fetch UDG    differs on 16K/48K machines.
        exx                     ; Switch back to main set and continue into...

; ----------------------
; THE 'START-NEW' BRANCH     
; ----------------------
;   This branch is taken from above and from RST 00h.
;   The common code tests RAM and sets it to zero re-initializing all the 
;   non-zero system variables and channel information.  The A register flags 
;   if coming from START or NEW.

;; START-NEW

START_NEW:
        ld b, a                 ; Save the flag to control later branching.

        ld a, $07               ; Select a white border
        out ($FE), a            ; and set it now by writing to a port.

        ld a, $3F               ; Load the accumulator with last page in ROM.
        ld i, a                 ; Set the I register - this remains constant
                                ; and can't be in the range $40 - $7F as 'snow'
                                ; appears on the screen.

        nop                     ; These seem unnecessary.
        nop
        nop
        nop
        nop
        nop

; -----------------------
; THE 'RAM CHECK' SECTION
; -----------------------
;   Typically, a Spectrum will have 16K or 48K of RAM and this code will test
;   it all till it finds an unpopulated location or, less likely, a faulty 
;   location.  Usually it stops when it reaches the top $FFFF, or in the case 
;   of NEW the supplied top value.  The entire screen turns black with 
;   sometimes red stripes on black paper just visible.

;; ram-check

ram_check:
        ld hl, de               ; Transfer the top value to the HL register
                                ; pair.

;; RAM-FILL

RAM_FILL:
        ldd (hl), $02           ; Load memory with $02 - red ink on black paper.
                                ; Decrement memory address.
        cp h                    ; Have we reached ROM - $3F ?
        jr nz, RAM_FILL         ; Back to RAM-FILL if not.

;; RAM-READ

RAM_READ:
        and a                   ; Clear carry - prepare to subtract.
        sbc hl, de              ; subtract and add back setting
        add hl, de              ; carry when back at start.
        inc hl                  ; and increment for next iteration.
        jr nc, RAM_DONE         ; forward to RAM-DONE if we've got back to
                                ; starting point with no errors.

        dec (hl)                ; decrement to 1.
        jr z, RAM_DONE          ; forward to RAM-DONE if faulty.

        dec (hl)                ; decrement to zero.
        jr z, RAM_READ          ; back to RAM-READ if zero flag was set.

;; RAM-DONE

RAM_DONE:
        dec hl                  ; step back to last valid location.
        exx                     ; regardless of state, set up possibly
                                ; stored system variables in case from NEW.
        ld (P_RAMT), bc         ; insert P-RAMT.
        ld (RASP), de           ; insert RASP/PIP.
        ld (UDG), hl            ; insert UDG.
        exx                     ; switch in main set.
        inc b                   ; now test if we arrived here from NEW.
        jr z, RAM_SET           ; forward to RAM-SET if we did.

;   This section applies to START only.

        ld (P_RAMT), hl         ; set P-RAMT to the highest working RAM
                                ; address.
        ld de, $3EAF            ; address of last byte of 'U' bitmap in ROM.
        ld bc, $00A8            ; there are 21 user defined graphics.
        ex de, hl               ; switch pointers and make the UDGs a
        lddr                    ; copy of the standard characters A - U.
        ex de, hl               ; switch the pointer to HL.
        inc hl                  ; update to start of 'A' in RAM.
        ld (UDG), hl            ; make UDG system variable address the first
                                ; bitmap.
        dec hl                  ; point at RAMTOP again.

        ld bc, $0040            ; set the values of
        ld (RASP), bc           ; the PIP and RASP system variables.

;   The NEW command path rejoins here.

;; RAM-SET

RAM_SET:
        ld (RAMTOP), hl         ; set system variable RAMTOP to HL.

;   
;   Note. this entry point is a disabled Warm Restart that was almost certainly
;   once pointed to by the System Variable NMIADD.  It would be essential that
;   any NMI Handler would perform the tasks from here to the EI instruction 
;   below.

;; NMI_VECT

NMI_VECT:
        ld hl, $3C00            ; a strange place to set the pointer to the
        ld (CHARS), hl          ; character set, CHARS - as no printing yet.

        ld hl, (RAMTOP)         ; fetch RAMTOP to HL again as we've lost it.

        ldd (hl), $3E           ; top of user ram holds GOSUB end marker
                                ; an impossible line number - see RETURN.
                                ; no significance in the number $3E. It has
                                ; been traditional since the ZX80.
                                ; followed by empty byte (not important).

        ld sp, hl               ; set up the machine stack pointer.
        dec hl
        dec hl
        ld (ERR_SP), hl         ; ERR_SP is where the error pointer is
                                ; at moment empty - will take address MAIN-4
                                ; at the call preceding that address,
                                ; although interrupts and calls will make use
                                ; of this location in meantime.

        im 1                    ; select interrupt mode 1.

        ld iy, ERR_NR           ; set IY to ERR_NR. IY can reach all standard
                                ; system variables but shadow ROM system
                                ; variables will be mostly out of range.

        ei                      ; enable interrupts now that we have a stack.

;   If, as suggested above, the NMI service routine pointed to this section of
;   code then a decision would have to be made at this point to jump forward, 
;   in a Warm Restart scenario, to produce a report code, leaving any program 
;   intact.

        ld hl, $5CB6            ; The address of the channels - initially
                                ; following system variables.
        ld (CHANS), hl          ; Set the CHANS system variable.

        ld de, init_chan        ; Address: init-chan in ROM.
        ld bc, $0015            ; There are 21 bytes of initial data in ROM.
        ex de, hl               ; swap the pointers.
        ldir                    ; Copy the bytes to RAM.

        ex de, hl               ; Swap pointers. HL points to program area.
        dec hl                  ; Decrement address.
        ld (DATADD), hl         ; Set DATADD to location before program area.
        inc hl                  ; Increment again.

        ld (PROG), hl           ; Set PROG the location where BASIC starts.
        ld (VARS), hl           ; Set VARS to same location with a
        ldi (hl), $80           ; variables end-marker.
                                ; Advance address.
        ld (E_LINE), hl         ; Set E_LINE, where the edit line
                                ; will be created.
                                ; Note. it is not strictly necessary to
                                ; execute the next fifteen bytes of code
                                ; as this will be done by the call to SET-MIN.
                                ; --
        ldi (hl), $0D           ; initially just has a carriage return
                                ; followed by
        ldi (hl), $80           ; an end-marker.
                                ; address the next location.
        ld (WORKSP), hl         ; set WORKSP - empty workspace.
        ld (STKBOT), hl         ; set STKBOT - bottom of the empty stack.
        ld (STKEND), hl         ; set STKEND to the end of the empty stack.
                                ; --
        ld a, $38               ; the colour system is set to white paper,
                                ; black ink, no flash or bright.
        ld (ATTR_P), a          ; set ATTR_P permanent colour attributes.
        ld (ATTR_T), a          ; set ATTR_T temporary colour attributes.
        ld (BORDCR), a          ; set BORDCR the border colour/lower screen
                                ; attributes.

        ld hl, $0523            ; The keyboard repeat and delay values are
        ld (REPDEL), hl         ; loaded to REPDEL and REPPER.

        dec (iy+KSTATE-IY0)     ; set KSTATE-0 to $FF - keyboard map available.
        dec (iy+KSTATE4-IY0)    ; set KSTATE-4 to $FF - keyboard map available.

        ld hl, init_strm        ; set source to ROM Address: init-strm
        ld de, STRMS            ; set destination to system variable STRMS-FD
        ld bc, $000E            ; copy the 14 bytes of initial 7 streams data
        ldir                    ; from ROM to RAM.

        set 1, (iy+FLAGS-IY0)   ; update FLAGS  - signal printer in use.
        call CLEAR_PRB          ; call routine CLEAR-PRB to initialize system
                                ; variables associated with printer.
                                ; The buffer is clear.

        ld (iy+DF_SZ-IY0), $02  ; set DF_SZ the lower screen display size to
                                ; two lines
        call CLS                ; call routine CLS to set up system
                                ; variables associated with screen and clear
                                ; the screen and set attributes.
        xor a                   ; clear accumulator so that we can address
        ld de, copyright-$01    ; the message table directly.
        call PO_MSG             ; routine PO-MSG puts
                                ; ' ©  1982 Sinclair Research Ltd'
                                ; at bottom of display.
        set 5, (iy+TV_FLAG-IY0) ; update TV_FLAG  - signal lower screen will
                                ; require clearing.

        jr MAIN_1               ; forward to MAIN-1


; -------------------------
; THE 'MAIN EXECUTION LOOP'
; -------------------------
;
;

;; MAIN-EXEC

MAIN_EXEC:
        ld (iy+DF_SZ-IY0), $02  ; set DF_SZ lower screen display file size to
                                ; two lines.
        call AUTO_LIST          ; routine AUTO-LIST

;; MAIN-1

MAIN_1:
        call SET_MIN            ; routine SET-MIN clears work areas.

;; MAIN-2

MAIN_2:
        ld a, $00               ; select channel 'K' the keyboard

        call CHAN_OPEN          ; routine CHAN-OPEN opens it

        call EDITOR             ; routine EDITOR is called.
                                ; Note the above routine is where the Spectrum
                                ; waits for user-interaction. Perhaps the
                                ; most common input at this stage
                                ; is LOAD "".

        call LINE_SCAN          ; routine LINE-SCAN scans the input.

        bit 7, (iy+ERR_NR-IY0)  ; test ERR_NR - will be $FF if syntax is OK.
        jr nz, MAIN_3           ; forward, if correct, to MAIN-3.

; 

        bit 4, (iy+FLAGS2-IY0)  ; test FLAGS2 - K channel in use ?
        jr z, MAIN_4            ; forward to MAIN-4 if not.

;

        ld hl, (E_LINE)         ; an editing error so address E_LINE.
        call REMOVE_FP          ; routine REMOVE-FP removes the hidden
                                ; floating-point forms.
        ld (iy+ERR_NR-IY0), $FF ; system variable ERR_NR is reset to 'OK'.
        jr MAIN_2               ; back to MAIN-2 to allow user to correct.


; ---

; the branch was here if syntax has passed test.

;; MAIN-3

MAIN_3:
        ld hl, (E_LINE)         ; fetch the edit line address from E_LINE.

        ld (CH_ADD), hl         ; system variable CH_ADD is set to first
                                ; character of edit line.
                                ; Note. the above two instructions are a little
                                ; inadequate.
                                ; They are repeated with a subtle difference
                                ; at the start of the next subroutine and are
                                ; therefore not required above.

        call E_LINE_NO          ; routine E-LINE-NO will fetch any line
                                ; number to BC if this is a program line.

        ld a, b                 ; test if the number of
        or c                    ; the line is non-zero.
        jp nz, MAIN_ADD         ; jump forward to MAIN-ADD if so to add the
                                ; line to the BASIC program.

; Has the user just pressed the ENTER key ?

        rst $18                 ; GET-CHAR gets character addressed by CH_ADD.
        cp $0D                  ; is it a carriage return ?
        jr z, MAIN_EXEC         ; back to MAIN-EXEC if so for an automatic
                                ; listing.

; this must be a direct command.

        bit 0, (iy+FLAGS2-IY0)  ; test FLAGS2 - clear the main screen ?

        call nz, CL_ALL         ; routine CL-ALL, if so, e.g. after listing.

        call CLS_LOWER          ; routine CLS-LOWER anyway.

        ld a, $19               ; compute scroll count as 25 minus
        sub (iy+S_POSN_hi-IY0)  ; value of S_POSN_hi.
        ld (SCR_CT), a          ; update SCR_CT system variable.
        set 7, (iy+FLAGS-IY0)   ; update FLAGS - signal running program.
        ld (iy+ERR_NR-IY0), $FF ; set ERR_NR to 'OK'.
        ld (iy+NSPPC-IY0), $01  ; set NSPPC to one for first statement.
        call LINE_RUN           ; call routine LINE-RUN to run the line.
                                ; sysvar ERR_SP therefore addresses MAIN-4

; Examples of direct commands are RUN, CLS, LOAD "", PRINT USR 40000,
; LPRINT "A"; etc..
; If a user written machine-code program disables interrupts then it
; must enable them to pass the next step. We also jumped to here if the
; keyboard was not being used.

;; MAIN-4

MAIN_4:
        halt                    ; wait for interrupt the only routine that can
                                ; set bit 5 of FLAGS.

        res 5, (iy+FLAGS-IY0)   ; update bit 5 of FLAGS - signal no new key.

        bit 1, (iy+FLAGS2-IY0)  ; test FLAGS2 - is printer buffer clear ?
        call nz, COPY_BUFF      ; call routine COPY-BUFF if not.
                                ; Note. the programmer has neglected
                                ; to set bit 1 of FLAGS first.

        ld a, (ERR_NR)          ; fetch ERR_NR
        inc a                   ; increment to give true code.

; Now deal with a runtime error as opposed to an editing error.
; However if the error code is now zero then the OK message will be printed.

;; MAIN-G

MAIN_G:
        push af                 ; save the error number.

        ld hl, $0000            ; prepare to clear some system variables.
        ld (iy+FLAGX-IY0), h    ; clear all the bits of FLAGX.
        ld (iy+$26), h          ; blank X_PTR_hi to suppress error marker.
        ld (DEFADD), hl         ; blank DEFADD to signal that no defined
                                ; function is currently being evaluated.

        ld hl, $0001            ; explicit - inc hl would do.
        ld ($5C16), hl          ; ensure STRMS-00 is keyboard.

        call SET_MIN            ; routine SET-MIN clears workspace etc.
        res 5, (iy+FLAGX-IY0)   ; update FLAGX - signal in EDIT not INPUT mode.
                                ; Note. all the bits were reset earlier.

        call CLS_LOWER          ; call routine CLS-LOWER.

        set 5, (iy+TV_FLAG-IY0) ; update TV_FLAG - signal lower screen
                                ; requires clearing.

        pop af                  ; bring back the true error number
        ld b, a                 ; and make a copy in B.
        cp $0A                  ; is it a print-ready digit ?
        jr c, MAIN_5            ; forward to MAIN-5 if so.

        add a, $07              ; add ASCII offset to letters.

;; MAIN-5

MAIN_5:
        call OUT_CODE           ; call routine OUT-CODE to print the code.

        ld a, $20               ; followed by a space.
        rst $10                 ; PRINT-A

        ld a, b                 ; fetch stored report code.
        ld de, rpt_mesgs        ; address: rpt-mesgs.

        call PO_MSG             ; call routine PO-MSG to print the message.


X1349:
        xor a                   ; clear accumulator to directly
        ld de, comma_sp-$01     ; address the comma and space message.

        call PO_MSG             ; routine PO-MSG prints ', ' although it would
                                ; be more succinct to use RST $10.

        ld bc, (PPC)            ; fetch PPC the current line number.
        call OUT_NUM_1          ; routine OUT-NUM-1 will print that

        ld a, $3A               ; then a ':' character.
        rst $10                 ; PRINT-A

        ld c, (iy+SUBPPC-IY0)   ; then SUBPPC for statement
        ld b, $00               ; limited to 127
        call OUT_NUM_1          ; routine OUT-NUM-1 prints BC.

        call CLEAR_SP           ; routine CLEAR-SP clears editing area which
                                ; probably contained 'RUN'.

        ld a, (ERR_NR)          ; fetch ERR_NR again
        inc a                   ; test for no error originally $FF.
        jr z, MAIN_9            ; forward to MAIN-9 if no error.

        cp $09                  ; is code Report 9 STOP ?
        jr z, MAIN_6            ; forward to MAIN-6 if so

        cp $15                  ; is code Report L Break ?
        jr nz, MAIN_7           ; forward to MAIN-7 if not

; Stop or Break was encountered so consider CONTINUE.

;; MAIN-6

MAIN_6:
        inc (iy+SUBPPC-IY0)     ; increment SUBPPC to next statement.

;; MAIN-7

MAIN_7:
        ld bc, $0003            ; prepare to copy 3 system variables to
        ld de, OSPCC            ; address OSPPC - statement for CONTINUE.
                                ; also updating OLDPPC line number below.

        ld hl, NSPPC            ; set source top to NSPPC next statement.
        bit 7, (hl)             ; did BREAK occur before the jump ?
                                ; e.g. between GO TO and next statement.
        jr z, MAIN_8            ; skip forward to MAIN-8, if not, as set-up
                                ; is correct.

        add hl, bc              ; set source to SUBPPC number of current
                                ; statement/line which will be repeated.

;; MAIN-8

MAIN_8:
        lddr                    ; copy PPC to OLDPPC and SUBPPC to OSPCC
                                ; or NSPPC to OLDPPC and NEWPPC to OSPCC

;; MAIN-9

MAIN_9:
        ld (iy+NSPPC-IY0), $FF  ; update NSPPC - signal 'no jump'.
        res 3, (iy+FLAGS-IY0)   ; update FLAGS - signal use 'K' mode for
                                ; the first character in the editor and

        jp MAIN_2               ; jump back to MAIN-2.



; ----------------------
; Canned report messages
; ----------------------
; The Error reports with the last byte inverted. The first entry
; is a dummy entry. The last, which begins with $7F, the Spectrum
; character for copyright symbol, is placed here for convenience
; as is the preceding comma and space.
; The report line must accommodate a 4-digit line number and a 3-digit
; statement number which limits the length of the message text to twenty 
; characters.
; e.g.  "B Integer out of range, 1000:127"

;; rpt-mesgs

rpt_mesgs:
        defb $80
        defm7 "OK"              ; 0
        defm7 "NEXT without FOR"
                                ; 1
        defm7 "Variable not found"
                                ; 2
        defm7 "Subscript wrong" ; 3
        defm7 "Out of memory"   ; 4
        defm7 "Out of screen"   ; 5
        defm7 "Number too big"  ; 6
        defm7 "RETURN without GOSUB"
                                ; 7
        defm7 "End of file"     ; 8
        defm7 "STOP statement"  ; 9
        defm7 "Invalid argument"
                                ; A
        defm7 "Integer out of range"
                                ; B
        defm7 "Nonsense in BASIC"
                                ; C
        defm7 "BREAK - CONT repeats"
                                ; D
        defm7 "Out of DATA"     ; E
        defm7 "Invalid file name"
                                ; F
        defm7 "No room for line"
                                ; G
        defm7 "STOP in INPUT"   ; H
        defm7 "FOR without NEXT"
                                ; I
        defm7 "Invalid I/O device"
                                ; J
        defm7 "Invalid colour"  ; K
        defm7 "BREAK into program"
                                ; L
        defm7 "RAMTOP no good"  ; M
        defm7 "Statement lost"  ; N
        defm7 "Invalid stream"  ; O
        defm7 "FN without DEF"  ; P
        defm7 "Parameter error" ; Q
        defm7 "Tape loading error"
                                ; R
                                ; ; comma-sp

comma_sp:
        defm7 ", "              ; used in report line.
                                ; ; copyright

copyright:
        defb $7F                ; copyright
        defm7 " 1982 Sinclair Research Ltd"


; -------------
; REPORT-G
; -------------
; Note ERR_SP points here during line entry which allows the
; normal 'Out of Memory' report to be augmented to the more
; precise 'No Room for line' report.

;; REPORT-G
; No Room for line

REPORT_G:
        ld a, $10               ; i.e. 'G' -$30 -$07
        ld bc, $0000            ; this seems unnecessary.
        jp MAIN_G               ; jump back to MAIN-G


; -----------------------------
; Handle addition of BASIC line
; -----------------------------
; Note this is not a subroutine but a branch of the main execution loop.
; System variable ERR_SP still points to editing error handler.
; A new line is added to the BASIC program at the appropriate place.
; An existing line with same number is deleted first.
; Entering an existing line number deletes that line.
; Entering a non-existent line allows the subsequent line to be edited next.

;; MAIN-ADD

MAIN_ADD:
        ld (E_PPC), bc          ; set E_PPC to extracted line number.
        ld hl, (CH_ADD)         ; fetch CH_ADD - points to location after the
                                ; initial digits (set in E_LINE_NO).
        ex de, hl               ; save start of BASIC in DE.

        ld hl, REPORT_G         ; Address: REPORT-G
        push hl                 ; is pushed on stack and addressed by ERR_SP.
                                ; the only error that can occur is
                                ; 'Out of memory'.

        ld hl, (WORKSP)         ; fetch WORKSP - end of line.
        scf                     ; prepare for true subtraction.
        sbc hl, de              ; find length of BASIC and
        push hl                 ; save it on stack.
        ld hl, bc               ; transfer line number
                                ; to HL register.
        call LINE_ADDR          ; routine LINE-ADDR will see if
                                ; a line with the same number exists.
        jr nz, MAIN_ADD1        ; forward if no existing line to MAIN-ADD1.

        call NEXT_ONE           ; routine NEXT-ONE finds the existing line.
        call RECLAIM_2          ; routine RECLAIM-2 reclaims it.

;; MAIN-ADD1

MAIN_ADD1:
        pop bc                  ; retrieve the length of the new line.
        ld a, c                 ; and test if carriage return only
        dec a                   ; i.e. one byte long.
        or b                    ; result would be zero.
        jr z, MAIN_ADD2         ; forward to MAIN-ADD2 is so.

        push bc                 ; save the length again.
        inc bc                  ; adjust for inclusion
        inc bc                  ; of line number (two bytes)
        inc bc                  ; and line length
        inc bc                  ; (two bytes).
        dec hl                  ; HL points to location before the destination

        ld de, (PROG)           ; fetch the address of PROG
        push de                 ; and save it on the stack
        call MAKE_ROOM          ; routine MAKE-ROOM creates BC spaces in
                                ; program area and updates pointers.
        pop hl                  ; restore old program pointer.
        ld (PROG), hl           ; and put back in PROG as it may have been
                                ; altered by the POINTERS routine.

        pop bc                  ; retrieve BASIC length
        push bc                 ; and save again.

        inc de                  ; points to end of new area.
        ld hl, (WORKSP)         ; set HL to WORKSP - location after edit line.
        dec hl                  ; decrement to address end marker.
        dec hl                  ; decrement to address carriage return.
        lddr                    ; copy the BASIC line back to initial command.

        ld hl, (E_PPC)          ; fetch E_PPC - line number.
        ex de, hl               ; swap it to DE, HL points to last of
                                ; four locations.
        pop bc                  ; retrieve length of line.
        ldd (hl), b             ; high byte last.
        ldd (hl), c             ; then low byte of length.
        ldd (hl), e             ; then low byte of line number.
        ld (hl), d              ; then high byte range $0 - $27 (1-9999).

;; MAIN-ADD2

MAIN_ADD2:
        pop af                  ; drop the address of Report G
        jp MAIN_EXEC            ; and back to MAIN-EXEC producing a listing
                                ; and to reset ERR_SP in EDITOR.



; ---------------------------------
; THE 'INITIAL CHANNEL' INFORMATION
; ---------------------------------
;   This initial channel information is copied from ROM to RAM, during 
;   initialization.  It's new location is after the system variables and is 
;   addressed by the system variable CHANS which means that it can slide up and
;   down in memory.  The table is never searched, by this ROM, and the last 
;   character, which could be anything other than a comma, provides a 
;   convenient resting place for DATADD.

;; init-chan

init_chan:
        defw PRINT_OUT          ; PRINT-OUT
        defw KEY_INPUT          ; KEY-INPUT
        defb $4B                ; 'K'
        defw PRINT_OUT          ; PRINT-OUT
        defw REPORT_J           ; REPORT-J
        defb $53                ; 'S'
        defw ADD_CHAR           ; ADD-CHAR
        defw REPORT_J           ; REPORT-J
        defb $52                ; 'R'
        defw PRINT_OUT          ; PRINT-OUT
        defw REPORT_J           ; REPORT-J
        defb $50                ; 'P'

        defb $80                ; End Marker

;; REPORT-J

REPORT_J:
        rst $08                 ; ERROR-1
        defb $12                ; Error Report: Invalid I/O device


; -------------------------
; THE 'INITIAL STREAM' DATA
; -------------------------
;   This is the initial stream data for the seven streams $FD - $03 that is
;   copied from ROM to the STRMS system variables area during initialization.
;   There are reserved locations there for another 12 streams.  Each location 
;   contains an offset to the second byte of a channel.  The first byte of a 
;   channel can't be used as that would result in an offset of zero for some 
;   and zero is used to denote that a stream is closed.

;; init-strm

init_strm:
        defb $01, $00           ; stream $FD offset to channel 'K'
        defb $06, $00           ; stream $FE offset to channel 'S'
        defb $0B, $00           ; stream $FF offset to channel 'R'

        defb $01, $00           ; stream $00 offset to channel 'K'
        defb $01, $00           ; stream $01 offset to channel 'K'
        defb $06, $00           ; stream $02 offset to channel 'S'
        defb $10, $00           ; stream $03 offset to channel 'P'

; ------------------------------
; THE 'INPUT CONTROL' SUBROUTINE
; ------------------------------
;

;; WAIT-KEY

WAIT_KEY:
        bit 5, (iy+TV_FLAG-IY0) ; test TV_FLAG - clear lower screen ?
        jr nz, WAIT_KEY1        ; forward to WAIT-KEY1 if so.

        set 3, (iy+TV_FLAG-IY0) ; update TV_FLAG - signal reprint the edit
                                ; line to the lower screen.

;; WAIT-KEY1

WAIT_KEY1:
        call INPUT_AD           ; routine INPUT-AD is called.

        ret c                   ; return with acceptable keys.

        jr z, WAIT_KEY1         ; back to WAIT-KEY1 if no key is pressed
                                ; or it has been handled within INPUT-AD.

;   Note. When inputting from the keyboard all characters are returned with
;   above conditions so this path is never taken.

;; REPORT-8

REPORT_8:
        rst $08                 ; ERROR-1
        defb $07                ; Error Report: End of file

; ---------------------------
; THE 'INPUT ADDRESS' ROUTINE
; ---------------------------
;   This routine fetches the address of the input stream from the current 
;   channel area using the system variable CURCHL.

;; INPUT-AD

INPUT_AD:
        exx                     ; switch in alternate set.
        push hl                 ; save HL register
        ld hl, (CURCHL)         ; fetch address of CURCHL - current channel.
        inc hl                  ; step over output routine
        inc hl                  ; to point to low byte of input routine.
        jr CALL_SUB             ; forward to CALL-SUB.


; -------------------------
; THE 'CODE OUTPUT' ROUTINE
; -------------------------
;   This routine is called on five occasions to print the ASCII equivalent of 
;   a value 0-9.

;; OUT-CODE

OUT_CODE:
        ld e, $30               ; add 48 decimal to give the ASCII character
        add a, e                ; '0' to '9' and continue into the main output
                                ; routine.

; -------------------------
; THE 'MAIN OUTPUT' ROUTINE
; -------------------------
;   PRINT-A-2 is a continuation of the RST 10 restart that prints any character.
;   The routine prints to the current channel and the printing of control codes
;   may alter that channel to divert subsequent RST 10 instructions to temporary
;   routines. The normal channel is $09F4.

;; PRINT-A-2

PRINT_A_2:
        exx                     ; switch in alternate set
        push hl                 ; save HL register
        ld hl, (CURCHL)         ; fetch CURCHL the current channel.

; input-ad rejoins here also.

;; CALL-SUB

CALL_SUB:
        ldi e, (hl)             ; put the low byte in E.
                                ; advance address.
        ld d, (hl)              ; put the high byte to D.
        ex de, hl               ; transfer the stream to HL.
        call CALL_JUMP          ; use routine CALL-JUMP.
                                ; in effect CALL (HL).

        pop hl                  ; restore saved HL register.
        exx                     ; switch back to the main set and
        ret                     ; return.


; --------------------------
; THE 'OPEN CHANNEL' ROUTINE
; --------------------------
;   This subroutine is used by the ROM to open a channel 'K', 'S', 'R' or 'P'.
;   This is either for its own use or in response to a user's request, for
;   example, when '#' is encountered with output - PRINT, LIST etc.
;   or with input - INPUT, INKEY$ etc.
;   It is entered with a system stream $FD - $FF, or a user stream $00 - $0F
;   in the accumulator.

;; CHAN-OPEN

CHAN_OPEN:
        add a, a                ; double the stream ($FF will become $FE etc.)
        add a, $16              ; add the offset to stream 0 from $5C00
        ld l, a                 ; result to L
        ld h, $5C               ; now form the address in STRMS area.
        ldi e, (hl)             ; fetch low byte of CHANS offset
                                ; address next
        ld d, (hl)              ; fetch high byte of offset
        ld a, d                 ; test that the stream is open.
        or e                    ; zero if closed.
        jr nz, CHAN_OP_1        ; forward to CHAN-OP-1 if open.

;; REPORT-Oa

REPORT_Oa:
        rst $08                 ; ERROR-1
        defb $17                ; Error Report: Invalid stream

; continue here if stream was open. Note that the offset is from CHANS
; to the second byte of the channel.

;; CHAN-OP-1

CHAN_OP_1:
        dec de                  ; reduce offset so it points to the channel.
        ld hl, (CHANS)          ; fetch CHANS the location of the base of
                                ; the channel information area
        add hl, de              ; and add the offset to address the channel.
                                ; and continue to set flags.

; -----------------
; Set channel flags
; -----------------
; This subroutine is used from ED-EDIT, str$ and read-in to reset the
; current channel when it has been temporarily altered.

;; CHAN-FLAG

CHAN_FLAG:
        ld (CURCHL), hl         ; set CURCHL system variable to the
                                ; address in HL
        res 4, (iy+FLAGS2-IY0)  ; update FLAGS2  - signal K channel not in use.
                                ; Note. provide a default for channel 'R'.
        inc hl                  ; advance past
        inc hl                  ; output routine.
        inc hl                  ; advance past
        inc hl                  ; input routine.
        ld c, (hl)              ; pick up the letter.
        ld hl, chn_cd_lu        ; address: chn-cd-lu
        call INDEXER            ; routine INDEXER finds offset to a
                                ; flag-setting routine.

        ret nc                  ; but if the letter wasn't found in the
                                ; table just return now. - channel 'R'.

        ld d, $00               ; prepare to add
        ld e, (hl)              ; offset to E
        add hl, de              ; add offset to location of offset to form
                                ; address of routine

;; CALL-JUMP

CALL_JUMP:
        jp (hl)                 ; jump to the routine


; Footnote. calling any location that holds JP (HL) is the equivalent to
; a pseudo Z80 instruction CALL (HL). The ROM uses the instruction above.

; --------------------------
; Channel code look-up table
; --------------------------
; This table is used by the routine above to find one of the three
; flag setting routines below it.
; A zero end-marker is required as channel 'R' is not present.

;; chn-cd-lu

chn_cd_lu:
        defm "K"                ; offset $06 to CHAN-K
        defb CHAN_K - $
        defm "S"                ; offset $12 to CHAN-S
        defb CHAN_S - $
        defm "P"                ; offset $1B to CHAN-P
        defb CHAN_P - $

        defb $00                ; end marker.

; --------------
; Channel K flag
; --------------
; routine to set flags for lower screen/keyboard channel.

;; CHAN-K

CHAN_K:
        set 0, (iy+TV_FLAG-IY0) ; update TV_FLAG  - signal lower screen in use
        res 5, (iy+FLAGS-IY0)   ; update FLAGS    - signal no new key
        set 4, (iy+FLAGS2-IY0)  ; update FLAGS2   - signal K channel in use
        jr CHAN_S_1             ; forward to CHAN-S-1 for indirect exit


; --------------
; Channel S flag
; --------------
; routine to set flags for upper screen channel.

;; CHAN-S

CHAN_S:
        res 0, (iy+TV_FLAG-IY0) ; TV_FLAG  - signal main screen in use

;; CHAN-S-1

CHAN_S_1:
        res 1, (iy+FLAGS-IY0)   ; update FLAGS  - signal printer not in use
        jp TEMPS                ; jump back to TEMPS and exit via that
                                ; routine after setting temporary attributes.
                                ; --------------
                                ; Channel P flag
                                ; --------------
                                ; This routine sets a flag so that subsequent print related commands
                                ; print to printer or update the relevant system variables.
                                ; This status remains in force until reset by the routine above.


;; CHAN-P

CHAN_P:
        set 1, (iy+FLAGS-IY0)   ; update FLAGS  - signal printer in use
        ret                     ; return


; --------------------------
; THE 'ONE SPACE' SUBROUTINE
; --------------------------
; This routine is called once only to create a single space
; in workspace by ADD-CHAR. 

;; ONE-SPACE

ONE_SPACE:
        ld bc, $0001            ; create space for a single character.

; ---------
; Make Room
; ---------
; This entry point is used to create BC spaces in various areas such as
; program area, variables area, workspace etc..
; The entire free RAM is available to each BASIC statement.
; On entry, HL addresses where the first location is to be created.
; Afterwards, HL will point to the location before this.

;; MAKE-ROOM

MAKE_ROOM:
        push hl                 ; save the address pointer.
        call TEST_ROOM          ; routine TEST-ROOM checks if room
                                ; exists and generates an error if not.
        pop hl                  ; restore the address pointer.
        call POINTERS           ; routine POINTERS updates the
                                ; dynamic memory location pointers.
                                ; DE now holds the old value of STKEND.
        ld hl, (STKEND)         ; fetch new STKEND the top destination.

        ex de, hl               ; HL now addresses the top of the area to
                                ; be moved up - old STKEND.
        lddr                    ; the program, variables, etc are moved up.
        ret                     ; return with new area ready to be populated.
                                ; HL points to location before new area,
                                ; and DE to last of new locations.


; -----------------------------------------------
; Adjust pointers before making or reclaiming room
; -----------------------------------------------
; This routine is called by MAKE-ROOM to adjust upwards and by RECLAIM to
; adjust downwards the pointers within dynamic memory.
; The fourteen pointers to dynamic memory, starting with VARS and ending 
; with STKEND, are updated adding BC if they are higher than the position
; in HL.  
; The system variables are in no particular order except that STKEND, the first
; free location after dynamic memory must be the last encountered.

;; POINTERS

POINTERS:
        push af                 ; preserve accumulator.
        push hl                 ; put pos pointer on stack.
        ld hl, VARS             ; address VARS the first of the
        ld a, $0E               ; fourteen variables to consider.

;; PTR-NEXT

PTR_NEXT:
        ldi e, (hl)             ; fetch the low byte of the system variable.
                                ; advance address.
        ld d, (hl)              ; fetch high byte of the system variable.
        ex (sp), hl             ; swap pointer on stack with the variable
                                ; pointer.
        and a                   ; prepare to subtract.
        sbc hl, de              ; subtract variable address
        add hl, de              ; and add back
        ex (sp), hl             ; swap pos with system variable pointer
        jr nc, PTR_DONE         ; forward to PTR-DONE if var before pos

        push de                 ; save system variable address.
        ex de, hl               ; transfer to HL
        add hl, bc              ; add the offset
        ex de, hl               ; back to DE
        ldd (hl), d             ; load high byte
                                ; move back
        ldi (hl), e             ; load low byte
                                ; advance to high byte
        pop de                  ; restore old system variable address.

;; PTR-DONE

PTR_DONE:
        inc hl                  ; address next system variable.
        dec a                   ; decrease counter.
        jr nz, PTR_NEXT         ; back to PTR-NEXT if more.
        ex de, hl               ; transfer old value of STKEND to HL.
                                ; Note. this has always been updated.
        pop de                  ; pop the address of the position.

        pop af                  ; pop preserved accumulator.
        and a                   ; clear carry flag preparing to subtract.

        sbc hl, de              ; subtract position from old stkend
        ld bc, hl               ; to give number of data bytes
                                ; to be moved.
        inc bc                  ; increment as we also copy byte at old STKEND.
        add hl, de              ; recompute old stkend.
        ex de, hl               ; transfer to DE.
        ret                     ; return.




; -------------------
; Collect line number
; -------------------
; This routine extracts a line number, at an address that has previously
; been found using LINE-ADDR, and it is entered at LINE-NO. If it encounters
; the program 'end-marker' then the previous line is used and if that
; should also be unacceptable then zero is used as it must be a direct
; command. The program end-marker is the variables end-marker $80, or
; if variables exist, then the first character of any variable name.

;; LINE-ZERO

LINE_ZERO:
        defb $00, $00           ; dummy line number used for direct commands


;; LINE-NO-A

LINE_NO_A:
        ex de, hl               ; fetch the previous line to HL and set
        ld de, LINE_ZERO        ; DE to LINE-ZERO should HL also fail.

; -> The Entry Point.

;; LINE-NO

LINE_NO:
        ld a, (hl)              ; fetch the high byte - max $2F
        and $C0                 ; mask off the invalid bits.
        jr nz, LINE_NO_A        ; to LINE-NO-A if an end-marker.

        ldi d, (hl)             ; reload the high byte.
                                ; advance address.
        ld e, (hl)              ; pick up the low byte.
        ret                     ; return from here.


; -------------------
; Handle reserve room
; -------------------
; This is a continuation of the restart BC-SPACES

;; RESERVE

RESERVE:
        ld hl, (STKBOT)         ; STKBOT first location of calculator stack
        dec hl                  ; make one less than new location
        call MAKE_ROOM          ; routine MAKE-ROOM creates the room.
        inc hl                  ; address the first new location
        inc hl                  ; advance to second
        pop bc                  ; restore old WORKSP
        ld (WORKSP), bc         ; system variable WORKSP was perhaps
                                ; changed by POINTERS routine.
        pop bc                  ; restore count for return value.
        ex de, hl               ; switch. DE = location after first new space
        inc hl                  ; HL now location after new space
        ret                     ; return.


; ---------------------------
; Clear various editing areas
; ---------------------------
; This routine sets the editing area, workspace and calculator stack
; to their minimum configurations as at initialization and indeed this
; routine could have been relied on to perform that task.
; This routine uses HL only and returns with that register holding
; WORKSP/STKBOT/STKEND though no use is made of this. The routines also
; reset MEM to its usual place in the systems variable area should it
; have been relocated to a FOR-NEXT variable. The main entry point
; SET-MIN is called at the start of the MAIN-EXEC loop and prior to
; displaying an error.

;; SET-MIN

SET_MIN:
        ld hl, (E_LINE)         ; fetch E_LINE
        ld (hl), $0D            ; insert carriage return
        ld (K_CUR), hl          ; make K_CUR keyboard cursor point there.
        inc hl                  ; next location
        ldi (hl), $80           ; holds end-marker $80
                                ; next location becomes
        ld (WORKSP), hl         ; start of WORKSP

; This entry point is used prior to input and prior to the execution,
; or parsing, of each statement.

;; SET-WORK

SET_WORK:
        ld hl, (WORKSP)         ; fetch WORKSP value
        ld (STKBOT), hl         ; and place in STKBOT

; This entry point is used to move the stack back to its normal place
; after temporary relocation during line entry and also from ERROR-3

;; SET-STK

SET_STK:
        ld hl, (STKBOT)         ; fetch STKBOT value
        ld (STKEND), hl         ; and place in STKEND.

        push hl                 ; perhaps an obsolete entry point.
        ld hl, MEMBOT           ; normal location of MEM-0
        ld (MEM), hl            ; is restored to system variable MEM.
        pop hl                  ; saved value not required.
        ret                     ; return.


; ------------------
; Reclaim edit-line?
; ------------------
; This seems to be legacy code from the ZX80/ZX81 as it is 
; not used in this ROM.
; That task, in fact, is performed here by the dual-area routine CLEAR-SP.
; This routine is designed to deal with something that is known to be in the
; edit buffer and not workspace.
; On entry, HL must point to the end of the something to be deleted.

;; REC-EDIT

REC_EDIT:
        ld de, (E_LINE)         ; fetch start of edit line from E_LINE.
        jp RECLAIM_1            ; jump forward to RECLAIM-1.


; --------------------------
; The Table INDEXING routine
; --------------------------
; This routine is used to search two-byte hash tables for a character
; held in C, returning the address of the following offset byte.
; if it is known that the character is in the table e.g. for priorities,
; then the table requires no zero end-marker. If this is not known at the
; outset then a zero end-marker is required and carry is set to signal
; success.

;; INDEXER-1

INDEXER_1:
        inc hl                  ; address the next pair of values.

; -> The Entry Point.

;; INDEXER

INDEXER:
        ld a, (hl)              ; fetch the first byte of pair
        and a                   ; is it the end-marker ?
        ret z                   ; return with carry reset if so.

        cp c                    ; is it the required character ?
        inc hl                  ; address next location.
        jr nz, INDEXER_1        ; back to INDEXER-1 if no match.

        scf                     ; else set the carry flag.
        ret                     ; return with carry set


; --------------------------------
; The Channel and Streams Routines
; --------------------------------
; A channel is an input/output route to a hardware device
; and is identified to the system by a single letter e.g. 'K' for
; the keyboard. A channel can have an input and output route
; associated with it in which case it is bi-directional like
; the keyboard. Others like the upper screen 'S' are output
; only and the input routine usually points to a report message.
; Channels 'K' and 'S' are system channels and it would be inappropriate
; to close the associated streams so a mechanism is provided to
; re-attach them. When the re-attachment is no longer required, then
; closing these streams resets them as at initialization.
; Early adverts said that the network and RS232 were in this ROM. 
; Channels 'N' and 'B' are user channels and have been removed successfully 
; if, as seems possible, they existed.
; Ironically the tape streamer is not accessed through streams and
; channels.
; Early demonstrations of the Spectrum showed a single microdrive being
; controlled by the main ROM.

; ---------------------
; THE 'CLOSE #' COMMAND
; ---------------------
;   This command allows streams to be closed after use.
;   Any temporary memory areas used by the stream would be reclaimed and
;   finally flags set or reset if necessary.

;; CLOSE

CLOSE:
        call STR_DATA           ; routine STR-DATA fetches parameter
                                ; from calculator stack and gets the
                                ; existing STRMS data pointer address in HL
                                ; and stream offset from CHANS in BC.

                                ; Note. this offset could be zero if the
                                ; stream is already closed. A check for this
                                ; should occur now and an error should be
                                ; generated, for example,
                                ; Report S 'Stream status closed'.

        call CLOSE_2            ; routine CLOSE-2 would perform any actions
                                ; peculiar to that stream without disturbing
                                ; data pointer to STRMS entry in HL.

        ld bc, $0000            ; the stream is to be blanked.
        ld de, $A3E2            ; the number of bytes from stream 4, $5C1E,
                                ; to $10000
        ex de, hl               ; transfer offset to HL, STRMS data pointer
                                ; to DE.
        add hl, de              ; add the offset to the data pointer.
        jr c, CLOSE_1           ; forward to CLOSE-1 if a non-system stream.
                                ; i.e. higher than 3.

; proceed with a negative result.

        ld bc, init_strm+$0E    ; prepare the address of the byte after
                                ; the initial stream data in ROM. ($15D4)
        add hl, bc              ; index into the data table with negative value.
        ldi c, (hl)             ; low byte to C
                                ; address next.
        ld b, (hl)              ; high byte to B.

;   and for streams 0 - 3 just enter the initial data back into the STRMS entry
;   streams 0 - 2 can't be closed as they are shared by the operating system.
;   -> for streams 4 - 15 then blank the entry.

;; CLOSE-1

CLOSE_1:
        ex de, hl               ; address of stream to HL.
        ldi (hl), c             ; place zero (or low byte).
                                ; next address.
        ld (hl), b              ; place zero (or high byte).
        ret                     ; return.


; ------------------------
; THE 'CLOSE-2' SUBROUTINE
; ------------------------
;   There is not much point in coming here.
;   The purpose was once to find the offset to a special closing routine,
;   in this ROM and within 256 bytes of the close stream look up table that
;   would reclaim any buffers associated with a stream. At least one has been
;   removed.
;   Any attempt to CLOSE streams $00 to $04, without first opening the stream,
;   will lead to either a system restart or the production of a strange report.
;   credit: Martin Wren-Hilton 1982.

;; CLOSE-2

CLOSE_2:
        push hl                 ; * save address of stream data pointer
                                ; in STRMS on the machine stack.
        ld hl, (CHANS)          ; fetch CHANS address to HL
        add hl, bc              ; add the offset to address the second
                                ; byte of the output routine hopefully.
        inc hl                  ; step past
        inc hl                  ; the input routine.

;    Note. When the Sinclair Interface1 is fitted then an instruction fetch 
;    on the next address pages this ROM out and the shadow ROM in.

;; ROM_TRAP

ROM_TRAP:
        inc hl                  ; to address channel's letter
        ld c, (hl)              ; pick it up in C.
                                ; Note. but if stream is already closed we
                                ; get the value $10 (the byte preceding 'K').

        ex de, hl               ; save the pointer to the letter in DE.

;   Note. The string pointer is saved but not used!!

        ld hl, cl_str_lu        ; address: cl-str-lu in ROM.
        call INDEXER            ; routine INDEXER uses the code to get
                                ; the 8-bit offset from the current point to
                                ; the address of the closing routine in ROM.
                                ; Note. it won't find $10 there!

        ld c, (hl)              ; transfer the offset to C.
        ld b, $00               ; prepare to add.
        add hl, bc              ; add offset to point to the address of the
                                ; routine that closes the stream.
                                ; (and presumably removes any buffers that
                                ; are associated with it.)
        jp (hl)                 ; jump to that routine.


; --------------------------------
; THE 'CLOSE STREAM LOOK-UP' TABLE
; --------------------------------
;   This table contains an entry for a letter found in the CHANS area.
;   followed by an 8-bit displacement, from that byte's address in the
;   table to the routine that performs any ancillary actions associated
;   with closing the stream of that channel.
;   The table doesn't require a zero end-marker as the letter has been
;   picked up from a channel that has an open stream.

;; cl-str-lu

cl_str_lu:
        defm "K"                ; offset 5 to CLOSE-STR
        defb CLOSE_STR - $
        defm "S"                ; offset 3 to CLOSE-STR
        defb CLOSE_STR - $
        defm "P"                ; offset 1 to CLOSE-STR
        defb CLOSE_STR - $


; ------------------------------
; THE 'CLOSE STREAM' SUBROUTINES
; ------------------------------
; The close stream routines in fact have no ancillary actions to perform
; which is not surprising with regard to 'K' and 'S'.

;; CLOSE-STR                    

CLOSE_STR:
        pop hl                  ; * now just restore the stream data pointer
        ret                     ; in STRMS and return.


; -----------
; Stream data
; -----------
; This routine finds the data entry in the STRMS area for the specified
; stream which is passed on the calculator stack. It returns with HL
; pointing to this system variable and BC holding a displacement from
; the CHANS area to the second byte of the stream's channel. If BC holds
; zero, then that signifies that the stream is closed.

;; STR-DATA

STR_DATA:
        call FIND_INT1          ; routine FIND-INT1 fetches parameter to A
        cp $10                  ; is it less than 16d ?
        jr c, STR_DATA1         ; skip forward to STR-DATA1 if so.

;; REPORT-Ob

REPORT_Ob:
        rst $08                 ; ERROR-1
        defb $17                ; Error Report: Invalid stream

;; STR-DATA1

STR_DATA1:
        add a, $03              ; add the offset for 3 system streams.
                                ; range 00 - 15d becomes 3 - 18d.
        rlca                    ; double as there are two bytes per
                                ; stream - now 06 - 36d
        ld hl, STRMS            ; address STRMS - the start of the streams
                                ; data area in system variables.
        ld c, a                 ; transfer the low byte to A.
        ld b, $00               ; prepare to add offset.
        add hl, bc              ; add to address the data entry in STRMS.

; the data entry itself contains an offset from CHANS to the address of the
; stream

        ld bc, (hl)             ; low byte of displacement to C.
                                ; address next.
                                ; high byte of displacement to B.
                                ; step back to leave HL pointing to STRMS
                                ; data entry.
        ret                     ; return with CHANS displacement in BC
                                ; and address of stream data entry in HL.


; --------------------
; Handle OPEN# command
; --------------------
; Command syntax example: OPEN #5,"s"
; On entry the channel code entry is on the calculator stack with the next
; value containing the stream identifier. They have to swapped.

;; OPEN

OPEN:
        rst $28                 ; ; FP-CALC    ;s,c.
        defb $01                ; ;exchange    ;c,s.
        defb $38                ; ;end-calc

        call STR_DATA           ; routine STR-DATA fetches the stream off
                                ; the stack and returns with the CHANS
                                ; displacement in BC and HL addressing
                                ; the STRMS data entry.
        ld a, b                 ; test for zero which
        or c                    ; indicates the stream is closed.
        jr z, OPEN_1            ; skip forward to OPEN-1 if so.

; if it is a system channel then it can re-attached.

        ex de, hl               ; save STRMS address in DE.
        ld hl, (CHANS)          ; fetch CHANS.
        add hl, bc              ; add the offset to address the second
                                ; byte of the channel.
        inc hl                  ; skip over the
        inc hl                  ; input routine.
        inc hl                  ; and address the letter.
        ld a, (hl)              ; pick up the letter.
        ex de, hl               ; save letter pointer and bring back
                                ; the STRMS pointer.

        cp $4B                  ; is it 'K' ?
        jr z, OPEN_1            ; forward to OPEN-1 if so

        cp $53                  ; is it 'S' ?
        jr z, OPEN_1            ; forward to OPEN-1 if so

        cp $50                  ; is it 'P' ?
        jr nz, REPORT_Ob        ; back to REPORT-Ob if not.
                                ; to report 'Invalid stream'.

; continue if one of the upper-case letters was found.
; and rejoin here from above if stream was closed.

;; OPEN-1

OPEN_1:
        call OPEN_2             ; routine OPEN-2 opens the stream.

; it now remains to update the STRMS variable.

        ldi (hl), e             ; insert or overwrite the low byte.
                                ; address high byte in STRMS.
        ld (hl), d              ; insert or overwrite the high byte.
        ret                     ; return.


; -----------------
; OPEN-2 Subroutine
; -----------------
; There is some point in coming here as, as well as once creating buffers,
; this routine also sets flags.

;; OPEN-2

OPEN_2:
        push hl                 ; * save the STRMS data entry pointer.
        call STK_FETCH          ; routine STK-FETCH now fetches the
                                ; parameters of the channel string.
                                ; start in DE, length in BC.

        ld a, b                 ; test that it is not
        or c                    ; the null string.
        jr nz, OPEN_3           ; skip forward to OPEN-3 with 1 character
                                ; or more!

;; REPORT-Fb

REPORT_Fb:
        rst $08                 ; ERROR-1
        defb $0E                ; Error Report: Invalid file name

;; OPEN-3

OPEN_3:
        push bc                 ; save the length of the string.
        ld a, (de)              ; pick up the first character.
                                ; Note. There can be more than one character.
        and $DF                 ; make it upper-case.
        ld c, a                 ; place it in C.
        ld hl, op_str_lu        ; address: op-str-lu is loaded.
        call INDEXER            ; routine INDEXER will search for letter.
        jr nc, REPORT_Fb        ; back to REPORT-F if not found
                                ; 'Invalid filename'

        ld c, (hl)              ; fetch the displacement to opening routine.
        ld b, $00               ; prepare to add.
        add hl, bc              ; now form address of opening routine.
        pop bc                  ; restore the length of string.
        jp (hl)                 ; now jump forward to the relevant routine.


; -------------------------
; OPEN stream look-up table
; -------------------------
; The open stream look-up table consists of matched pairs.
; The channel letter is followed by an 8-bit displacement to the
; associated stream-opening routine in this ROM.
; The table requires a zero end-marker as the letter has been
; provided by the user and not the operating system.

;; op-str-lu

op_str_lu:
        defm "K"                ; $06 offset to OPEN-K
        defb OPEN_K - $
        defm "S"                ; $08 offset to OPEN-S
        defb OPEN_S - $
        defm "P"                ; $0A offset to OPEN-P
        defb OPEN_P - $

        defb $00                ; end-marker.

; ----------------------------
; The Stream Opening Routines.
; ----------------------------
; These routines would have opened any buffers associated with the stream
; before jumping forward to OPEN-END with the displacement value in E
; and perhaps a modified value in BC. The strange pathing does seem to
; provide for flexibility in this respect.
;
; There is no need to open the printer buffer as it is there already
; even if you are still saving up for a ZX Printer or have moved onto
; something bigger. In any case it would have to be created after
; the system variables but apart from that it is a simple task
; and all but one of the ROM routines can handle a buffer in that position.
; (PR-ALL-6 would require an extra 3 bytes of code).
; However it wouldn't be wise to have two streams attached to the ZX Printer
; as you can now, so one assumes that if PR_CC_hi was non-zero then
; the OPEN-P routine would have refused to attach a stream if another
; stream was attached.

; Something of significance is being passed to these ghost routines in the
; second character. Strings 'RB', 'RT' perhaps or a drive/station number.
; The routine would have to deal with that and exit to OPEN_END with BC
; containing $0001 or more likely there would be an exit within the routine.
; Anyway doesn't matter, these routines are long gone.

; -----------------
; OPEN-K Subroutine
; -----------------
; Open Keyboard stream.

;; OPEN-K

OPEN_K:
        ld e, $01               ; 01 is offset to second byte of channel 'K'.
        jr OPEN_END             ; forward to OPEN-END


; -----------------
; OPEN-S Subroutine
; -----------------
; Open Screen stream.

;; OPEN-S

OPEN_S:
        ld e, $06               ; 06 is offset to 2nd byte of channel 'S'
        jr OPEN_END             ; to OPEN-END


; -----------------
; OPEN-P Subroutine
; -----------------
; Open Printer stream.

;; OPEN-P

OPEN_P:
        ld e, $10               ; 16d is offset to 2nd byte of channel 'P'

;; OPEN-END

OPEN_END:
        dec bc                  ; the stored length of 'K','S','P' or
                                ; whatever is now tested. ??
        ld a, b                 ; test now if initial or residual length
        or c                    ; is one character.
        jr nz, REPORT_Fb        ; to REPORT-Fb 'Invalid file name' if not.

        ld d, a                 ; load D with zero to form the displacement
                                ; in the DE register.
        pop hl                  ; * restore the saved STRMS pointer.
        ret                     ; return to update STRMS entry thereby
                                ; signaling stream is open.


; ----------------------------------------
; Handle CAT, ERASE, FORMAT, MOVE commands
; ----------------------------------------
; These just generate an error report as the ROM is 'incomplete'.
;
; Luckily this provides a mechanism for extending these in a shadow ROM
; but without the powerful mechanisms set up in this ROM.
; An instruction fetch on $0008 may page in a peripheral ROM,
; e.g. the Sinclair Interface 1 ROM, to handle these commands.
; However that wasn't the plan.
; Development of this ROM continued for another three months until the cost
; of replacing it and the manual became unfeasible.
; The ultimate power of channels and streams died at birth.

;; CAT-ETC

CAT_ETC:
        jr REPORT_Ob            ; to REPORT-Ob


; -----------------
; Perform AUTO-LIST
; -----------------
; This produces an automatic listing in the upper screen.

;; AUTO-LIST

AUTO_LIST:
        ld (LIST_SP), sp        ; save stack pointer in LIST_SP
        ld (iy+TV_FLAG-IY0), $10
                                ; update TV_FLAG set bit 3
        call CL_ALL             ; routine CL-ALL.
        set 0, (iy+TV_FLAG-IY0) ; update TV_FLAG  - signal lower screen in use

        ld b, (iy+DF_SZ-IY0)    ; fetch DF_SZ to B.
        call CL_LINE            ; routine CL-LINE clears lower display
                                ; preserving B.
        res 0, (iy+TV_FLAG-IY0) ; update TV_FLAG  - signal main screen in use
        set 0, (iy+FLAGS2-IY0)  ; update FLAGS2 - signal will be necessary to
                                ; clear main screen.
        ld hl, (E_PPC)          ; fetch E_PPC current edit line to HL.
        ld de, (S_TOP)          ; fetch S_TOP to DE, the current top line
                                ; (initially zero)
        and a                   ; prepare for true subtraction.
        sbc hl, de              ; subtract and
        add hl, de              ; add back.
        jr c, AUTO_L_2          ; to AUTO-L-2 if S_TOP higher than E_PPC
                                ; to set S_TOP to E_PPC

        push de                 ; save the top line number.
        call LINE_ADDR          ; routine LINE-ADDR gets address of E_PPC.
        ld de, $02C0            ; prepare known number of characters in
                                ; the default upper screen.
        ex de, hl               ; offset to HL, program address to DE.
        sbc hl, de              ; subtract high value from low to obtain
                                ; negated result used in addition.
        ex (sp), hl             ; swap result with top line number on stack.
        call LINE_ADDR          ; routine LINE-ADDR  gets address of that
                                ; top line in HL and next line in DE.
        pop bc                  ; restore the result to balance stack.

;; AUTO-L-1

AUTO_L_1:
        push bc                 ; save the result.
        call NEXT_ONE           ; routine NEXT-ONE gets address in HL of
                                ; line after auto-line (in DE).
        pop bc                  ; restore result.
        add hl, bc              ; compute back.
        jr c, AUTO_L_3          ; to AUTO-L-3 if line 'should' appear

        ex de, hl               ; address of next line to HL.
        ldi d, (hl)             ; get line
                                ; number
        ldd e, (hl)             ; in DE.
                                ; adjust back to start.
        ld (S_TOP), de          ; update S_TOP.
        jr AUTO_L_1             ; to AUTO-L-1 until estimate reached.


; ---

; the jump was to here if S_TOP was greater than E_PPC

;; AUTO-L-2

AUTO_L_2:
        ld (S_TOP), hl          ; make S_TOP the same as E_PPC.

; continue here with valid starting point from above or good estimate
; from computation

;; AUTO-L-3

AUTO_L_3:
        ld hl, (S_TOP)          ; fetch S_TOP line number to HL.
        call LINE_ADDR          ; routine LINE-ADDR gets address in HL.
                                ; address of next in DE.
        jr z, AUTO_L_4          ; to AUTO-L-4 if line exists.

        ex de, hl               ; else use address of next line.

;; AUTO-L-4

AUTO_L_4:
        call LIST_ALL           ; routine LIST-ALL                >>>

; The return will be to here if no scrolling occurred

        res 4, (iy+TV_FLAG-IY0) ; update TV_FLAG  - signal no auto listing.
        ret                     ; return.


; ------------
; Handle LLIST
; ------------
; A short form of LIST #3. The listing goes to stream 3 - default printer.

;; LLIST

LLIST:
        ld a, $03               ; the usual stream for ZX Printer
        jr LIST_1               ; forward to LIST-1


; -----------
; Handle LIST
; -----------
; List to any stream.
; Note. While a starting line can be specified it is
; not possible to specify an end line.
; Just listing a line makes it the current edit line.

;; LIST

LIST:
        ld a, $02               ; default is stream 2 - the upper screen.

;; LIST-1

LIST_1:
        ld (iy+TV_FLAG-IY0), $00
                                ; the TV_FLAG is initialized with bit 0 reset
                                ; indicating upper screen in use.
        call SYNTAX_Z           ; routine SYNTAX-Z - checking syntax ?
        call nz, CHAN_OPEN      ; routine CHAN-OPEN if in run-time.

        rst $18                 ; GET-CHAR
        call STR_ALTER          ; routine STR-ALTER will alter if '#'.
        jr c, LIST_4            ; forward to LIST-4 not a '#' .


        rst $18                 ; GET-CHAR
        cp $3B                  ; is it ';' ?
        jr z, LIST_2            ; skip to LIST-2 if so.

        cp $2C                  ; is it ',' ?
        jr nz, LIST_3           ; forward to LIST-3 if neither separator.

; we have, say,  LIST #15, and a number must follow the separator.

;; LIST-2

LIST_2:
        rst $20                 ; NEXT-CHAR
        call EXPT_1NUM          ; routine EXPT-1NUM
        jr LIST_5               ; forward to LIST-5


; ---

; the branch was here with just LIST #3 etc.

;; LIST-3

LIST_3:
        call USE_ZERO           ; routine USE-ZERO
        jr LIST_5               ; forward to LIST-5


; ---

; the branch was here with LIST

;; LIST-4

LIST_4:
        call FETCH_NUM          ; routine FETCH-NUM checks if a number
                                ; follows else uses zero.

;; LIST-5

LIST_5:
        call CHECK_END          ; routine CHECK-END quits if syntax OK >>>

        call FIND_INT2          ; routine FIND-INT2 fetches the number
                                ; from the calculator stack in run-time.
        ld a, b                 ; fetch high byte of line number and
        and $3F                 ; make less than $40 so that NEXT-ONE
                                ; (from LINE-ADDR) doesn't lose context.
                                ; Note. this is not satisfactory and the typo
                                ; LIST 20000 will list an entirely different
                                ; section than LIST 2000. Such typos are not
                                ; available for checking if they are direct
                                ; commands.

        ld h, a                 ; transfer the modified
        ld l, c                 ; line number to HL.
        ld (E_PPC), hl          ; update E_PPC to new line number.
        call LINE_ADDR          ; routine LINE-ADDR gets the address of the
                                ; line.

; This routine is called from AUTO-LIST

;; LIST-ALL

LIST_ALL:
        ld e, $01               ; signal current line not yet printed

;; LIST-ALL-2

LIST_ALL_2:
        call OUT_LINE           ; routine OUT-LINE outputs a BASIC line
                                ; using PRINT-OUT and makes an early return
                                ; when no more lines to print. >>>

        rst $10                 ; PRINT-A prints the carriage return (in A)

        bit 4, (iy+TV_FLAG-IY0) ; test TV_FLAG  - automatic listing ?
        jr z, LIST_ALL_2        ; back to LIST-ALL-2 if not
                                ; (loop exit is via OUT-LINE)

; continue here if an automatic listing required.

        ld a, (DF_SZ)           ; fetch DF_SZ lower display file size.
        sub (iy+S_POSN_hi-IY0)  ; subtract S_POSN_hi ithe current line number.
        jr nz, LIST_ALL_2       ; back to LIST-ALL-2 if upper screen not full.

        xor e                   ; A contains zero, E contains one if the
                                ; current edit line has not been printed
                                ; or zero if it has (from OUT-LINE).
        ret z                   ; return if the screen is full and the line
                                ; has been printed.

; continue with automatic listings if the screen is full and the current
; edit line is missing. OUT-LINE will scroll automatically.

        push hl                 ; save the pointer address.
        push de                 ; save the E flag.
        ld hl, S_TOP            ; fetch S_TOP the rough estimate.
        call LN_FETCH           ; routine LN-FETCH updates S_TOP with
                                ; the number of the next line.
        pop de                  ; restore the E flag.
        pop hl                  ; restore the address of the next line.
        jr LIST_ALL_2           ; back to LIST-ALL-2.


; ------------------------
; Print a whole BASIC line
; ------------------------
; This routine prints a whole BASIC line and it is called
; from LIST-ALL to output the line to current channel
; and from ED-EDIT to 'sprint' the line to the edit buffer.

;; OUT-LINE

OUT_LINE:
        ld bc, (E_PPC)          ; fetch E_PPC the current line which may be
                                ; unchecked and not exist.
        call CP_LINES           ; routine CP-LINES finds match or line after.
        ld d, $3E               ; prepare cursor '>' in D.
        jr z, OUT_LINE1         ; to OUT-LINE1 if matched or line after.

        ld de, $0000            ; put zero in D, to suppress line cursor.
        rl e                    ; pick up carry in E if line before current
                                ; leave E zero if same or after.

;; OUT-LINE1

OUT_LINE1:
        ld (iy+BREG-IY0), e     ; save flag in BREG which is spare.
        ld a, (hl)              ; get high byte of line number.
        cp $40                  ; is it too high ($2F is maximum possible) ?
        pop bc                  ; drop the return address and
        ret nc                  ; make an early return if so >>>

        push bc                 ; save return address
        call OUT_NUM_2          ; routine OUT-NUM-2 to print addressed number
                                ; with leading space.
        inc hl                  ; skip low number byte.
        inc hl                  ; and the two
        inc hl                  ; length bytes.
        res 0, (iy+FLAGS-IY0)   ; update FLAGS - signal leading space required.
        ld a, d                 ; fetch the cursor.
        and a                   ; test for zero.
        jr z, OUT_LINE3         ; to OUT-LINE3 if zero.


        rst $10                 ; PRINT-A prints '>' the current line cursor.

; this entry point is called from ED-COPY

;; OUT-LINE2

OUT_LINE2:
        set 0, (iy+FLAGS-IY0)   ; update FLAGS - suppress leading space.

;; OUT-LINE3

OUT_LINE3:
        push de                 ; save flag E for a return value.
        ex de, hl               ; save HL address in DE.
        res 2, (iy+FLAGS2-IY0)  ; update FLAGS2 - signal NOT in QUOTES.

        ld hl, FLAGS            ; point to FLAGS.
        res 2, (hl)             ; signal 'K' mode. (starts before keyword)
        bit 5, (iy+FLAGX-IY0)   ; test FLAGX - input mode ?
        jr z, OUT_LINE4         ; forward to OUT-LINE4 if not.

        set 2, (hl)             ; signal 'L' mode. (used for input)

;; OUT-LINE4

OUT_LINE4:
        ld hl, (X_PTR)          ; fetch X_PTR - possibly the error pointer
                                ; address.
        and a                   ; clear the carry flag.
        sbc hl, de              ; test if an error address has been reached.
        jr nz, OUT_LINE5        ; forward to OUT-LINE5 if not.

        ld a, $3F               ; load A with '?' the error marker.
        call OUT_FLASH          ; routine OUT-FLASH to print flashing marker.

;; OUT-LINE5

OUT_LINE5:
        call OUT_CURS           ; routine OUT-CURS will print the cursor if
                                ; this is the right position.
        ex de, hl               ; restore address pointer to HL.
        ld a, (hl)              ; fetch the addressed character.
        call NUMBER             ; routine NUMBER skips a hidden floating
                                ; point number if present.
        inc hl                  ; now increment the pointer.
        cp $0D                  ; is character end-of-line ?
        jr z, OUT_LINE6         ; to OUT-LINE6, if so, as line is finished.

        ex de, hl               ; save the pointer in DE.
        call OUT_CHAR           ; routine OUT-CHAR to output character/token.

        jr OUT_LINE4            ; back to OUT-LINE4 until entire line is done.


; ---

;; OUT-LINE6

OUT_LINE6:
        pop de                  ; bring back the flag E, zero if current
                                ; line printed else 1 if still to print.
        ret                     ; return with A holding $0D


; -------------------------
; Check for a number marker
; -------------------------
; this subroutine is called from two processes. while outputting BASIC lines
; and while searching statements within a BASIC line.
; during both, this routine will pass over an invisible number indicator
; and the five bytes floating-point number that follows it.
; Note that this causes floating point numbers to be stripped from
; the BASIC line when it is fetched to the edit buffer by OUT_LINE.
; the number marker also appears after the arguments of a DEF FN statement
; and may mask old 5-byte string parameters.

;; NUMBER

NUMBER:
        cp $0E                  ; character fourteen ?
        ret nz                  ; return if not.

        inc hl                  ; skip the character
        inc hl                  ; and five bytes
        inc hl                  ; following.
        inc hl
        inc hl
        inc hl
        ld a, (hl)              ; fetch the following character
        ret                     ; for return value.


; --------------------------
; Print a flashing character
; --------------------------
; This subroutine is called from OUT-LINE to print a flashing error
; marker '?' or from the next routine to print a flashing cursor e.g. 'L'.
; However, this only gets called from OUT-LINE when printing the edit line
; or the input buffer to the lower screen so a direct call to $09F4 can
; be used, even though out-line outputs to other streams.
; In fact the alternate set is used for the whole routine.

;; OUT-FLASH

OUT_FLASH:
        exx                     ; switch in alternate set

        ld hl, (ATTR_T)         ; fetch L = ATTR_T, H = MASK-T
        push hl                 ; save masks.
        res 7, h                ; reset flash mask bit so active.
        set 7, l                ; make attribute FLASH.
        ld (ATTR_T), hl         ; resave ATTR_T and MASK-T

        ld hl, P_FLAG           ; address P_FLAG
        ld d, (hl)              ; fetch to D
        push de                 ; and save.
        ld (hl), $00            ; clear inverse, over, ink/paper 9

        call PRINT_OUT          ; routine PRINT-OUT outputs character
                                ; without the need to vector via RST 10.

        pop hl                  ; pop P_FLAG to H.
        ld (iy+P_FLAG-IY0), h   ; and restore system variable P_FLAG.
        pop hl                  ; restore temporary masks
        ld (ATTR_T), hl         ; and restore system variables ATTR_T/MASK_T

        exx                     ; switch back to main set
        ret                     ; return


; ----------------
; Print the cursor
; ----------------
; This routine is called before any character is output while outputting
; a BASIC line or the input buffer. This includes listing to a printer
; or screen, copying a BASIC line to the edit buffer and printing the
; input buffer or edit buffer to the lower screen. It is only in the
; latter two cases that it has any relevance and in the last case it
; performs another very important function also.

;; OUT-CURS

OUT_CURS:
        ld hl, (K_CUR)          ; fetch K_CUR the current cursor address
        and a                   ; prepare for true subtraction.
        sbc hl, de              ; test against pointer address in DE and
        ret nz                  ; return if not at exact position.

; the value of MODE, maintained by KEY-INPUT, is tested and if non-zero
; then this value 'E' or 'G' will take precedence.

        ld a, (MODE)            ; fetch MODE  0='KLC', 1='E', 2='G'.
        rlc a                   ; double the value and set flags.
        jr z, OUT_C_1           ; to OUT-C-1 if still zero ('KLC').

        add a, $43              ; add 'C' - will become 'E' if originally 1
                                ; or 'G' if originally 2.
        jr OUT_C_2              ; forward to OUT-C-2 to print.


; ---

; If mode was zero then, while printing a BASIC line, bit 2 of flags has been
; set if 'THEN' or ':' was encountered as a main character and reset otherwise.
; This is now used to determine if the 'K' cursor is to be printed but this
; transient state is also now transferred permanently to bit 3 of FLAGS
; to let the interrupt routine know how to decode the next key.

;; OUT-C-1

OUT_C_1:
        ld hl, FLAGS            ; Address FLAGS
        res 3, (hl)             ; signal 'K' mode initially.
        ld a, $4B               ; prepare letter 'K'.
        bit 2, (hl)             ; test FLAGS - was the
                                ; previous main character ':' or 'THEN' ?
        jr z, OUT_C_2           ; forward to OUT-C-2 if so to print.

        set 3, (hl)             ; signal 'L' mode to interrupt routine.
                                ; Note. transient bit has been made permanent.
        inc a                   ; augment from 'K' to 'L'.

        bit 3, (iy+FLAGS2-IY0)  ; test FLAGS2 - consider caps lock ?
                                ; which is maintained by KEY-INPUT.
        jr z, OUT_C_2           ; forward to OUT-C-2 if not set to print.

        ld a, $43               ; alter 'L' to 'C'.

;; OUT-C-2

OUT_C_2:
        push de                 ; save address pointer but OK as OUT-FLASH
                                ; uses alternate set without RST 10.

        call OUT_FLASH          ; routine OUT-FLASH to print.

        pop de                  ; restore and
        ret                     ; return.


; ----------------------------
; Get line number of next line
; ----------------------------
; These two subroutines are called while editing.
; This entry point is from ED-DOWN with HL addressing E_PPC
; to fetch the next line number.
; Also from AUTO-LIST with HL addressing S_TOP just to update S_TOP
; with the value of the next line number. It gets fetched but is discarded.
; These routines never get called while the editor is being used for input.

;; LN-FETCH

LN_FETCH:
        ldi e, (hl)             ; fetch low byte
                                ; address next
        ld d, (hl)              ; fetch high byte.
        push hl                 ; save system variable hi pointer.
        ex de, hl               ; line number to HL,
        inc hl                  ; increment as a starting point.
        call LINE_ADDR          ; routine LINE-ADDR gets address in HL.
        call LINE_NO            ; routine LINE-NO gets line number in DE.
        pop hl                  ; restore system variable hi pointer.

; This entry point is from the ED-UP with HL addressing E_PPC_hi

;; LN-STORE

LN_STORE:
        bit 5, (iy+FLAGX-IY0)   ; test FLAGX - input mode ?
        ret nz                  ; return if so.
                                ; Note. above already checked by ED-UP/ED-DOWN.

        ldd (hl), d             ; save high byte of line number.
                                ; address lower
        ld (hl), e              ; save low byte of line number.
        ret                     ; return.


; -----------------------------------------
; Outputting numbers at start of BASIC line
; -----------------------------------------
; This routine entered at OUT-SP-NO is used to compute then output the first
; three digits of a 4-digit BASIC line printing a space if necessary.
; The line number, or residual part, is held in HL and the BC register
; holds a subtraction value -1000, -100 or -10.
; Note. for example line number 200 -
; space(out_char), 2(out_code), 0(out_char) final number always out-code.

;; OUT-SP-2

OUT_SP_2:
        ld a, e                 ; will be space if OUT-CODE not yet called.
                                ; or $FF if spaces are suppressed.
                                ; else $30 ('0').
                                ; (from the first instruction at OUT-CODE)
                                ; this guy is just too clever.
        and a                   ; test bit 7 of A.
        ret m                   ; return if $FF, as leading spaces not
                                ; required. This is set when printing line
                                ; number and statement in MAIN-5.

        jr OUT_CHAR             ; forward to exit via OUT-CHAR.


; ---

; -> the single entry point.

;; OUT-SP-NO

OUT_SP_NO:
        xor a                   ; initialize digit to 0

;; OUT-SP-1

OUT_SP_1:
        add hl, bc              ; add negative number to HL.
        inc a                   ; increment digit
        jr c, OUT_SP_1          ; back to OUT-SP-1 until no carry from
                                ; the addition.

        sbc hl, bc              ; cancel the last addition
        dec a                   ; and decrement the digit.
        jr z, OUT_SP_2          ; back to OUT-SP-2 if it is zero.

        jp OUT_CODE             ; jump back to exit via OUT-CODE.    ->



; -------------------------------------
; Outputting characters in a BASIC line
; -------------------------------------
; This subroutine ...

;; OUT-CHAR

OUT_CHAR:
        call NUMERIC            ; routine NUMERIC tests if it is a digit ?
        jr nc, OUT_CH_3         ; to OUT-CH-3 to print digit without
                                ; changing mode. Will be 'K' mode if digits
                                ; are at beginning of edit line.

        cp $21                  ; less than quote character ?
        jr c, OUT_CH_3          ; to OUT-CH-3 to output controls and space.

        res 2, (iy+FLAGS-IY0)   ; initialize FLAGS to 'K' mode and leave
                                ; unchanged if this character would precede
                                ; a keyword.

        cp $CB                  ; is character 'THEN' token ?
        jr z, OUT_CH_3          ; to OUT-CH-3 to output if so.

        cp $3A                  ; is it ':' ?
        jr nz, OUT_CH_1         ; to OUT-CH-1 if not statement separator
                                ; to change mode back to 'L'.

        bit 5, (iy+FLAGX-IY0)   ; FLAGX  - Input Mode ??
        jr nz, OUT_CH_2         ; to OUT-CH-2 if in input as no statements.
                                ; Note. this check should seemingly be at
                                ; the start. Commands seem inappropriate in
                                ; INPUT mode and are rejected by the syntax
                                ; checker anyway.
                                ; unless INPUT LINE is being used.

        bit 2, (iy+FLAGS2-IY0)  ; test FLAGS2 - is the ':' within quotes ?
        jr z, OUT_CH_3          ; to OUT-CH-3 if ':' is outside quoted text.

        jr OUT_CH_2             ; to OUT-CH-2 as ':' is within quotes


; ---

;; OUT-CH-1

OUT_CH_1:
        cp $22                  ; is it quote character '"'  ?
        jr nz, OUT_CH_2         ; to OUT-CH-2 with others to set 'L' mode.

        push af                 ; save character.
        ld a, (FLAGS2)          ; fetch FLAGS2.
        xor $04                 ; toggle the quotes flag.
        ld (FLAGS2), a          ; update FLAGS2
        pop af                  ; and restore character.

;; OUT-CH-2

OUT_CH_2:
        set 2, (iy+FLAGS-IY0)   ; update FLAGS - signal L mode if the cursor
                                ; is next.

;; OUT-CH-3

OUT_CH_3:
        rst $10                 ; PRINT-A vectors the character to
                                ; channel 'S', 'K', 'R' or 'P'.
        ret                     ; return.


; -------------------------------------------
; Get starting address of line, or line after
; -------------------------------------------
; This routine is used often to get the address, in HL, of a BASIC line
; number supplied in HL, or failing that the address of the following line
; and the address of the previous line in DE.

;; LINE-ADDR

LINE_ADDR:
        push hl                 ; save line number in HL register
        ld hl, (PROG)           ; fetch start of program from PROG
        ld de, hl               ; transfer address to
                                ; the DE register pair.

;; LINE-AD-1

LINE_AD_1:
        pop bc                  ; restore the line number to BC
        call CP_LINES           ; routine CP-LINES compares with that
                                ; addressed by HL
        ret nc                  ; return if line has been passed or matched.
                                ; if NZ, address of previous is in DE

        push bc                 ; save the current line number
        call NEXT_ONE           ; routine NEXT-ONE finds address of next
                                ; line number in DE, previous in HL.
        ex de, hl               ; switch so next in HL
        jr LINE_AD_1            ; back to LINE-AD-1 for another comparison


; --------------------
; Compare line numbers
; --------------------
; This routine compares a line number supplied in BC with an addressed
; line number pointed to by HL.

;; CP-LINES

CP_LINES:
        ld a, (hl)              ; Load the high byte of line number and
        cp b                    ; compare with that of supplied line number.
        ret nz                  ; return if yet to match (carry will be set).

        inc hl                  ; address low byte of
        ldd a, (hl)             ; number and pick up in A.
                                ; step back to first position.
        cp c                    ; now compare.
        ret                     ; zero set if exact match.
                                ; carry set if yet to match.
                                ; no carry indicates a match or
                                ; next available BASIC line or
                                ; program end marker.


; -------------------
; Find each statement
; -------------------
; The single entry point EACH-STMT is used to
; 1) To find the D'th statement in a line.
; 2) To find a token in held E.

;; not-used

not_used:
        inc hl
        inc hl
        inc hl

; -> entry point.

;; EACH-STMT

EACH_STMT:
        ld (CH_ADD), hl         ; save HL in CH_ADD
        ld c, $00               ; initialize quotes flag

;; EACH-S-1

EACH_S_1:
        dec d                   ; decrease statement count
        ret z                   ; return if zero


        rst $20                 ; NEXT-CHAR
        cp e                    ; is it the search token ?
        jr nz, EACH_S_3         ; forward to EACH-S-3 if not

        and a                   ; clear carry
        ret                     ; return signalling success.


; ---

;; EACH-S-2

EACH_S_2:
        inc hl                  ; next address
        ld a, (hl)              ; next character

;; EACH-S-3

EACH_S_3:
        call NUMBER             ; routine NUMBER skips if number marker
        ld (CH_ADD), hl         ; save in CH_ADD
        cp $22                  ; is it quotes '"' ?
        jr nz, EACH_S_4         ; to EACH-S-4 if not

        dec c                   ; toggle bit 0 of C

;; EACH-S-4

EACH_S_4:
        cp $3A                  ; is it ':'
        jr z, EACH_S_5          ; to EACH-S-5

        cp $CB                  ; 'THEN'
        jr nz, EACH_S_6         ; to EACH-S-6

;; EACH-S-5

EACH_S_5:
        bit 0, c                ; is it in quotes
        jr z, EACH_S_1          ; to EACH-S-1 if not

;; EACH-S-6

EACH_S_6:
        cp $0D                  ; end of line ?
        jr nz, EACH_S_2         ; to EACH-S-2

        dec d                   ; decrease the statement counter
                                ; which should be zero else
                                ; 'Statement Lost'.
        scf                     ; set carry flag - not found
        ret                     ; return


; -----------------------------------------------------------------------
; Storage of variables. For full details - see chapter 24.
; ZX Spectrum BASIC Programming by Steven Vickers 1982.
; It is bits 7-5 of the first character of a variable that allow
; the six types to be distinguished. Bits 4-0 are the reduced letter.
; So any variable name is higher that $3F and can be distinguished
; also from the variables area end-marker $80.
;
; 76543210 meaning                               brief outline of format.
; -------- ------------------------              -----------------------
; 010      string variable.                      2 byte length + contents.
; 110      string array.                         2 byte length + contents.
; 100      array of numbers.                     2 byte length + contents.
; 011      simple numeric variable.              5 bytes.
; 101      variable length named numeric.        5 bytes.
; 111      for-next loop variable.               18 bytes.
; 10000000 the variables area end-marker.
;
; Note. any of the above seven will serve as a program end-marker.
;
; -----------------------------------------------------------------------

; ------------
; Get next one
; ------------
; This versatile routine is used to find the address of the next line
; in the program area or the next variable in the variables area.
; The reason one routine is made to handle two apparently unrelated tasks
; is that it can be called indiscriminately when merging a line or a
; variable.

;; NEXT-ONE

NEXT_ONE:
        push hl                 ; save the pointer address.
        ld a, (hl)              ; get first byte.
        cp $40                  ; compare with upper limit for line numbers.
        jr c, NEXT_O_3          ; forward to NEXT-O-3 if within BASIC area.

; the continuation here is for the next variable unless the supplied
; line number was erroneously over 16383. see RESTORE command.

        bit 5, a                ; is it a string or an array variable ?
        jr z, NEXT_O_4          ; forward to NEXT-O-4 to compute length.

        add a, a                ; test bit 6 for single-character variables.
        jp m, NEXT_O_1          ; forward to NEXT-O-1 if so

        ccf                     ; clear the carry for long-named variables.
                                ; it remains set for for-next loop variables.

;; NEXT-O-1

NEXT_O_1:
        ld bc, $0005            ; set BC to 5 for floating point number
        jr nc, NEXT_O_2         ; forward to NEXT-O-2 if not a for/next
                                ; variable.

        ld c, $12               ; set BC to eighteen locations.
                                ; value, limit, step, line and statement.

; now deal with long-named variables

;; NEXT-O-2

NEXT_O_2:
        rla                     ; test if character inverted. carry will also
                                ; be set for single character variables
        inc hl                  ; address next location.
        ld a, (hl)              ; and load character.
        jr nc, NEXT_O_2         ; back to NEXT-O-2 if not inverted bit.
                                ; forward immediately with single character
                                ; variable names.

        jr NEXT_O_5             ; forward to NEXT-O-5 to add length of
                                ; floating point number(s etc.).


; ---

; this branch is for line numbers.

;; NEXT-O-3

NEXT_O_3:
        inc hl                  ; increment pointer to low byte of line no.

; strings and arrays rejoin here

;; NEXT-O-4

NEXT_O_4:
        inc hl                  ; increment to address the length low byte.
        ldi bc, (hl)            ; transfer to C and
                                ; point to high byte of length.
                                ; transfer that to B
                                ; point to start of BASIC/variable contents.

; the three types of numeric variables rejoin here

;; NEXT-O-5

NEXT_O_5:
        add hl, bc              ; add the length to give address of next
                                ; line/variable in HL.
        pop de                  ; restore previous address to DE.

; ------------------
; Difference routine
; ------------------
; This routine terminates the above routine and is also called from the
; start of the next routine to calculate the length to reclaim.

;; DIFFER

DIFFER:
        and a                   ; prepare for true subtraction.
        sbc hl, de              ; subtract the two pointers.
        ld bc, hl               ; transfer result
                                ; to BC register pair.
        add hl, de              ; add back
        ex de, hl               ; and switch pointers
        ret                     ; return values are the length of area in BC,
                                ; low pointer (previous) in HL,
                                ; high pointer (next) in DE.


; -----------------------
; Handle reclaiming space
; -----------------------
;

;; RECLAIM-1

RECLAIM_1:
        call DIFFER             ; routine DIFFER immediately above

;; RECLAIM-2

RECLAIM_2:
        push bc

        ld a, b
        cpl
        ld b, a
        ld a, c
        cpl
        ld c, a
        inc bc

        call POINTERS           ; routine POINTERS
        ex de, hl
        pop hl

        add hl, de
        push de
        ldir                    ; copy bytes

        pop hl
        ret


; ----------------------------------------
; Read line number of line in editing area
; ----------------------------------------
; This routine reads a line number in the editing area returning the number
; in the BC register or zero if no digits exist before commands.
; It is called from LINE-SCAN to check the syntax of the digits.
; It is called from MAIN-3 to extract the line number in preparation for
; inclusion of the line in the BASIC program area.
;
; Interestingly the calculator stack is moved from its normal place at the
; end of dynamic memory to an adequate area within the system variables area.
; This ensures that in a low memory situation, that valid line numbers can
; be extracted without raising an error and that memory can be reclaimed
; by deleting lines. If the stack was in its normal place then a situation
; arises whereby the Spectrum becomes locked with no means of reclaiming space.

;; E-LINE-NO

E_LINE_NO:
        ld hl, (E_LINE)         ; load HL from system variable E_LINE.

        dec hl                  ; decrease so that NEXT_CHAR can be used
                                ; without skipping the first digit.

        ld (CH_ADD), hl         ; store in the system variable CH_ADD.

        rst $20                 ; NEXT-CHAR skips any noise and white-space
                                ; to point exactly at the first digit.

        ld hl, MEMBOT           ; use MEM-0 as a temporary calculator stack
                                ; an overhead of three locations are needed.
        ld (STKEND), hl         ; set new STKEND.

        call INT_TO_FP          ; routine INT-TO-FP will read digits till
                                ; a non-digit found.
        call FP_TO_BC           ; routine FP-TO-BC will retrieve number
                                ; from stack at membot.
        jr c, E_L_1             ; forward to E-L-1 if overflow i.e. > 65535.
                                ; 'Nonsense in BASIC'

        ld hl, $D8F0            ; load HL with value -9999
        add hl, bc              ; add to line number in BC

;; E-L-1

E_L_1:
        jp c, REPORT_C          ; to REPORT-C 'Nonsense in BASIC' if over.
                                ; Note. As ERR_SP points to ED_ERROR
                                ; the report is never produced although
                                ; the RST $08 will update X_PTR leading to
                                ; the error marker being displayed when
                                ; the ED_LOOP is reiterated.
                                ; in fact, since it is immediately
                                ; cancelled, any report will do.

; a line in the range 0 - 9999 has been entered.

        jp SET_STK              ; jump back to SET-STK to set the calculator
                                ; stack back to its normal place and exit
                                ; from there.


; ---------------------------------
; Report and line number outputting
; ---------------------------------
; Entry point OUT-NUM-1 is used by the Error Reporting code to print
; the line number and later the statement number held in BC.
; If the statement was part of a direct command then -2 is used as a
; dummy line number so that zero will be printed in the report.
; This routine is also used to print the exponent of E-format numbers.
;
; Entry point OUT-NUM-2 is used from OUT-LINE to output the line number
; addressed by HL with leading spaces if necessary.

;; OUT-NUM-1

OUT_NUM_1:
        push de                 ; save the
        push hl                 ; registers.
        xor a                   ; set A to zero.
        bit 7, b                ; is the line number minus two ?
        jr nz, OUT_NUM_4        ; forward to OUT-NUM-4 if so to print zero
                                ; for a direct command.

        ld hl, bc               ; transfer the
                                ; number to HL.
        ld e, $FF               ; signal 'no leading zeros'.
        jr OUT_NUM_3            ; forward to continue at OUT-NUM-3


; ---

; from OUT-LINE - HL addresses line number.

;; OUT-NUM-2

OUT_NUM_2:
        push de                 ; save flags
        ldi d, (hl)             ; high byte to D
                                ; address next
        ld e, (hl)              ; low byte to E
        push hl                 ; save pointer
        ex de, hl               ; transfer number to HL
        ld e, $20               ; signal 'output leading spaces'

;; OUT-NUM-3

OUT_NUM_3:
        ld bc, $FC18            ; value -1000
        call OUT_SP_NO          ; routine OUT-SP-NO outputs space or number
        ld bc, $FF9C            ; value -100
        call OUT_SP_NO          ; routine OUT-SP-NO
        ld c, $F6               ; value -10 ( B is still $FF )
        call OUT_SP_NO          ; routine OUT-SP-NO
        ld a, l                 ; remainder to A.

;; OUT-NUM-4

OUT_NUM_4:
        call OUT_CODE           ; routine OUT-CODE for final digit.
                                ; else report code zero wouldn't get
                                ; printed.
        pop hl                  ; restore the
        pop de                  ; registers and
        ret                     ; return.



;***************************************************
;** Part 7. BASIC LINE AND COMMAND INTERPRETATION **
;***************************************************

; ----------------
; The offset table
; ----------------
; The BASIC interpreter has found a command code $CE - $FF
; which is then reduced to range $00 - $31 and added to the base address
; of this table to give the address of an offset which, when added to
; the offset therein, gives the location in the following parameter table
; where a list of class codes, separators and addresses relevant to the
; command exists.

;; offst-tbl

offst_tbl:
        defb P_DEF_FN - $       ; B1 offset to Address: P-DEF-FN
        defb P_CAT - $          ; CB offset to Address: P-CAT
        defb P_FORMAT - $       ; BC offset to Address: P-FORMAT
        defb P_MOVE - $         ; BF offset to Address: P-MOVE
        defb P_ERASE - $        ; C4 offset to Address: P-ERASE
        defb P_OPEN - $         ; AF offset to Address: P-OPEN
        defb P_CLOSE - $        ; B4 offset to Address: P-CLOSE
        defb P_MERGE - $        ; 93 offset to Address: P-MERGE
        defb P_VERIFY - $       ; 91 offset to Address: P-VERIFY
        defb P_BEEP - $         ; 92 offset to Address: P-BEEP
        defb P_CIRCLE - $       ; 95 offset to Address: P-CIRCLE
        defb P_INK - $          ; 98 offset to Address: P-INK
        defb P_PAPER - $        ; 98 offset to Address: P-PAPER
        defb P_FLASH - $        ; 98 offset to Address: P-FLASH
        defb P_BRIGHT - $       ; 98 offset to Address: P-BRIGHT
        defb P_INVERSE - $      ; 98 offset to Address: P-INVERSE
        defb P_OVER - $         ; 98 offset to Address: P-OVER
        defb P_OUT - $          ; 98 offset to Address: P-OUT
        defb P_LPRINT - $       ; 7F offset to Address: P-LPRINT
        defb P_LLIST - $        ; 81 offset to Address: P-LLIST
        defb P_STOP - $         ; 2E offset to Address: P-STOP
        defb P_READ - $         ; 6C offset to Address: P-READ
        defb P_DATA - $         ; 6E offset to Address: P-DATA
        defb P_RESTORE - $      ; 70 offset to Address: P-RESTORE
        defb P_NEW - $          ; 48 offset to Address: P-NEW
        defb P_BORDER - $       ; 94 offset to Address: P-BORDER
        defb P_CONT - $         ; 56 offset to Address: P-CONT
        defb P_DIM - $          ; 3F offset to Address: P-DIM
        defb P_REM - $          ; 41 offset to Address: P-REM
        defb P_FOR - $          ; 2B offset to Address: P-FOR
        defb P_GO_TO - $        ; 17 offset to Address: P-GO-TO
        defb P_GO_SUB - $       ; 1F offset to Address: P-GO-SUB
        defb P_INPUT - $        ; 37 offset to Address: P-INPUT
        defb P_LOAD - $         ; 77 offset to Address: P-LOAD
        defb P_LIST - $         ; 44 offset to Address: P-LIST
        defb P_LET - $          ; 0F offset to Address: P-LET
        defb P_PAUSE - $        ; 59 offset to Address: P-PAUSE
        defb P_NEXT - $         ; 2B offset to Address: P-NEXT
        defb P_POKE - $         ; 43 offset to Address: P-POKE
        defb P_PRINT - $        ; 2D offset to Address: P-PRINT
        defb P_PLOT - $         ; 51 offset to Address: P-PLOT
        defb P_RUN - $          ; 3A offset to Address: P-RUN
        defb P_SAVE - $         ; 6D offset to Address: P-SAVE
        defb P_RANDOM - $       ; 42 offset to Address: P-RANDOM
        defb P_IF - $           ; 0D offset to Address: P-IF
        defb P_CLS - $          ; 49 offset to Address: P-CLS
        defb P_DRAW - $         ; 5C offset to Address: P-DRAW
        defb P_CLEAR - $        ; 44 offset to Address: P-CLEAR
        defb P_RETURN - $       ; 15 offset to Address: P-RETURN
        defb P_COPY - $         ; 5D offset to Address: P-COPY


; -------------------------------
; The parameter or "Syntax" table
; -------------------------------
; For each command there exists a variable list of parameters.
; If the character is greater than a space it is a required separator.
; If less, then it is a command class in the range 00 - 0B.
; Note that classes 00, 03 and 05 will fetch the addresses from this table.
; Some classes e.g. 07 and 0B have the same address in all invocations
; and the command is re-computed from the low-byte of the parameter address.
; Some e.g. 02 are only called once so a call to the command is made from
; within the class routine rather than holding the address within the table.
; Some class routines check syntax entirely and some leave this task for the
; command itself.
; Others for example CIRCLE (x,y,z) check the first part (x,y) using the
; class routine and the final part (,z) within the command.
; The last few commands appear to have been added in a rush but their syntax
; is rather simple e.g. MOVE "M1","M2"

;; P-LET

P_LET:
        defb $01                ; Class-01 - A variable is required.
        defb $3D                ; Separator:  '='
        defb $02                ; Class-02 - An expression, numeric or string,
                                ; must follow.

;; P-GO-TO

P_GO_TO:
        defb $06                ; Class-06 - A numeric expression must follow.
        defb $00                ; Class-00 - No further operands.
        defw GO_TO              ; Address: $1E67; Address: GO-TO

;; P-IF

P_IF:
        defb $06                ; Class-06 - A numeric expression must follow.
        defb $CB                ; Separator:  'THEN'
        defb $05                ; Class-05 - Variable syntax checked
                                ; by routine.
        defw IF                 ; Address: $1CF0; Address: IF

;; P-GO-SUB

P_GO_SUB:
        defb $06                ; Class-06 - A numeric expression must follow.
        defb $00                ; Class-00 - No further operands.
        defw GO_SUB             ; Address: $1EED; Address: GO-SUB

;; P-STOP

P_STOP:
        defb $00                ; Class-00 - No further operands.
        defw STOP_BAS           ; Address: $1CEE; Address: STOP

;; P-RETURN

P_RETURN:
        defb $00                ; Class-00 - No further operands.
        defw RETURN             ; Address: $1F23; Address: RETURN

;; P-FOR

P_FOR:
        defb $04                ; Class-04 - A single character variable must
                                ; follow.
        defb $3D                ; Separator:  '='
        defb $06                ; Class-06 - A numeric expression must follow.
        defb $CC                ; Separator:  'TO'
        defb $06                ; Class-06 - A numeric expression must follow.
        defb $05                ; Class-05 - Variable syntax checked
                                ; by routine.
        defw FOR                ; Address: $1D03; Address: FOR

;; P-NEXT

P_NEXT:
        defb $04                ; Class-04 - A single character variable must
                                ; follow.
        defb $00                ; Class-00 - No further operands.
        defw NEXT               ; Address: $1DAB; Address: NEXT

;; P-PRINT

P_PRINT:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw PRINT              ; Address: $1FCD; Address: PRINT

;; P-INPUT

P_INPUT:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw INPUT              ; Address: $2089; Address: INPUT

;; P-DIM

P_DIM:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw DIM                ; Address: $2C02; Address: DIM

;; P-REM

P_REM:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw REM                ; Address: $1BB2; Address: REM

;; P-NEW

P_NEW:
        defb $00                ; Class-00 - No further operands.
        defw NEW                ; Address: $11B7; Address: NEW

;; P-RUN

P_RUN:
        defb $03                ; Class-03 - A numeric expression may follow
                                ; else default to zero.
        defw RUN                ; Address: $1EA1; Address: RUN

;; P-LIST

P_LIST:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw LIST               ; Address: $17F9; Address: LIST

;; P-POKE

P_POKE:
        defb $08                ; Class-08 - Two comma-separated numeric
                                ; expressions required.
        defb $00                ; Class-00 - No further operands.
        defw POKE               ; Address: $1E80; Address: POKE

;; P-RANDOM

P_RANDOM:
        defb $03                ; Class-03 - A numeric expression may follow
                                ; else default to zero.
        defw RANDOMIZE          ; Address: $1E4F; Address: RANDOMIZE

;; P-CONT

P_CONT:
        defb $00                ; Class-00 - No further operands.
        defw CONTINUE           ; Address: $1E5F; Address: CONTINUE

;; P-CLEAR

P_CLEAR:
        defb $03                ; Class-03 - A numeric expression may follow
                                ; else default to zero.
        defw CLEAR              ; Address: $1EAC; Address: CLEAR

;; P-CLS

P_CLS:
        defb $00                ; Class-00 - No further operands.
        defw CLS                ; Address: $0D6B; Address: CLS

;; P-PLOT

P_PLOT:
        defb $09                ; Class-09 - Two comma-separated numeric
                                ; expressions required with optional colour
                                ; items.
        defb $00                ; Class-00 - No further operands.
        defw PLOT               ; Address: $22DC; Address: PLOT

;; P-PAUSE

P_PAUSE:
        defb $06                ; Class-06 - A numeric expression must follow.
        defb $00                ; Class-00 - No further operands.
        defw PAUSE              ; Address: $1F3A; Address: PAUSE

;; P-READ

P_READ:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw READ               ; Address: $1DED; Address: READ

;; P-DATA

P_DATA:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw DATA               ; Address: $1E27; Address: DATA

;; P-RESTORE

P_RESTORE:
        defb $03                ; Class-03 - A numeric expression may follow
                                ; else default to zero.
        defw RESTORE            ; Address: $1E42; Address: RESTORE

;; P-DRAW

P_DRAW:
        defb $09                ; Class-09 - Two comma-separated numeric
                                ; expressions required with optional colour
                                ; items.
        defb $05                ; Class-05 - Variable syntax checked
                                ; by routine.
        defw DRAW               ; Address: $2382; Address: DRAW

;; P-COPY

P_COPY:
        defb $00                ; Class-00 - No further operands.
        defw COPY               ; Address: $0EAC; Address: COPY

;; P-LPRINT

P_LPRINT:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw LPRINT             ; Address: $1FC9; Address: LPRINT

;; P-LLIST

P_LLIST:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw LLIST              ; Address: $17F5; Address: LLIST

;; P-SAVE

P_SAVE:
        defb $0B                ; Class-0B - Offset address converted to tape
                                ; command.

;; P-LOAD

P_LOAD:
        defb $0B                ; Class-0B - Offset address converted to tape
                                ; command.

;; P-VERIFY

P_VERIFY:
        defb $0B                ; Class-0B - Offset address converted to tape
                                ; command.

;; P-MERGE

P_MERGE:
        defb $0B                ; Class-0B - Offset address converted to tape
                                ; command.

;; P-BEEP

P_BEEP:
        defb $08                ; Class-08 - Two comma-separated numeric
                                ; expressions required.
        defb $00                ; Class-00 - No further operands.
        defw beep               ; Address: $03F8; Address: BEEP

;; P-CIRCLE

P_CIRCLE:
        defb $09                ; Class-09 - Two comma-separated numeric
                                ; expressions required with optional colour
                                ; items.
        defb $05                ; Class-05 - Variable syntax checked
                                ; by routine.
        defw CIRCLE             ; Address: $2320; Address: CIRCLE

;; P-INK

P_INK:
        defb $07                ; Class-07 - Offset address is converted to
                                ; colour code.

;; P-PAPER

P_PAPER:
        defb $07                ; Class-07 - Offset address is converted to
                                ; colour code.

;; P-FLASH

P_FLASH:
        defb $07                ; Class-07 - Offset address is converted to
                                ; colour code.

;; P-BRIGHT

P_BRIGHT:
        defb $07                ; Class-07 - Offset address is converted to
                                ; colour code.

;; P-INVERSE

P_INVERSE:
        defb $07                ; Class-07 - Offset address is converted to
                                ; colour code.

;; P-OVER

P_OVER:
        defb $07                ; Class-07 - Offset address is converted to
                                ; colour code.

;; P-OUT

P_OUT:
        defb $08                ; Class-08 - Two comma-separated numeric
                                ; expressions required.
        defb $00                ; Class-00 - No further operands.
        defw OUT_BAS            ; Address: $1E7A; Address: OUT

;; P-BORDER

P_BORDER:
        defb $06                ; Class-06 - A numeric expression must follow.
        defb $00                ; Class-00 - No further operands.
        defw BORDER             ; Address: $2294; Address: BORDER

;; P-DEF-FN

P_DEF_FN:
        defb $05                ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        defw DEF_FN             ; Address: $1F60; Address: DEF-FN

;; P-OPEN

P_OPEN:
        defb $06                ; Class-06 - A numeric expression must follow.
        defb $2C                ; Separator:  ','          see Footnote *
        defb $0A                ; Class-0A - A string expression must follow.
        defb $00                ; Class-00 - No further operands.
        defw OPEN               ; Address: $1736; Address: OPEN

;; P-CLOSE

P_CLOSE:
        defb $06                ; Class-06 - A numeric expression must follow.
        defb $00                ; Class-00 - No further operands.
        defw CLOSE              ; Address: $16E5; Address: CLOSE

;; P-FORMAT

P_FORMAT:
        defb $0A                ; Class-0A - A string expression must follow.
        defb $00                ; Class-00 - No further operands.
        defw CAT_ETC            ; Address: $1793; Address: CAT-ETC

;; P-MOVE

P_MOVE:
        defb $0A                ; Class-0A - A string expression must follow.
        defb $2C                ; Separator:  ','
        defb $0A                ; Class-0A - A string expression must follow.
        defb $00                ; Class-00 - No further operands.
        defw CAT_ETC            ; Address: $1793; Address: CAT-ETC

;; P-ERASE

P_ERASE:
        defb $0A                ; Class-0A - A string expression must follow.
        defb $00                ; Class-00 - No further operands.
        defw CAT_ETC            ; Address: $1793; Address: CAT-ETC

;; P-CAT

P_CAT:
        defb $00                ; Class-00 - No further operands.
        defw CAT_ETC            ; Address: $1793; Address: CAT-ETC

; * Note that a comma is required as a separator with the OPEN command
; but the Interface 1 programmers relaxed this allowing ';' as an
; alternative for their channels creating a confusing mixture of
; allowable syntax as it is this ROM which opens or re-opens the
; normal channels.

; -------------------------------
; Main parser (BASIC interpreter)
; -------------------------------
; This routine is called once from MAIN-2 when the BASIC line is to
; be entered or re-entered into the Program area and the syntax
; requires checking.

;; LINE-SCAN

LINE_SCAN:
        res 7, (iy+FLAGS-IY0)   ; update FLAGS - signal checking syntax
        call E_LINE_NO          ; routine E-LINE-NO              >>
                                ; fetches the line number if in range.

        xor a                   ; clear the accumulator.
        ld (SUBPPC), a          ; set statement number SUBPPC to zero.
        dec a                   ; set accumulator to $FF.
        ld (ERR_NR), a          ; set ERR_NR to 'OK' - 1.
        jr STMT_L_1             ; forward to continue at STMT-L-1.


; --------------
; Statement loop
; --------------
;
;

;; STMT-LOOP

STMT_LOOP:
        rst $20                 ; NEXT-CHAR

; -> the entry point from above or LINE-RUN
;; STMT-L-1

STMT_L_1:
        call SET_WORK           ; routine SET-WORK clears workspace etc.

        inc (iy+SUBPPC-IY0)     ; increment statement number SUBPPC
        jp m, REPORT_C          ; to REPORT-C to raise
                                ; 'Nonsense in BASIC' if over 127.

        rst $18                 ; GET-CHAR

        ld b, $00               ; set B to zero for later indexing.
                                ; early so any other reason ???

        cp $0D                  ; is character carriage return ?
                                ; i.e. an empty statement.
        jr z, LINE_END          ; forward to LINE-END if so.

        cp $3A                  ; is it statement end marker ':' ?
                                ; i.e. another type of empty statement.
        jr z, STMT_LOOP         ; back to STMT-LOOP if so.

        ld hl, STMT_RET         ; address: STMT-RET
        push hl                 ; is now pushed as a return address
        ld c, a                 ; transfer the current character to C.

; advance CH_ADD to a position after command and test if it is a command.

        rst $20                 ; NEXT-CHAR to advance pointer
        ld a, c                 ; restore current character
        sub $CE                 ; subtract 'DEF FN' - first command
        jp c, REPORT_C          ; jump to REPORT-C if less than a command
                                ; raising
                                ; 'Nonsense in BASIC'

        ld c, a                 ; put the valid command code back in C.
                                ; register B is zero.
        ld hl, offst_tbl        ; address: offst-tbl
        add hl, bc              ; index into table with one of 50 commands.
        ld c, (hl)              ; pick up displacement to syntax table entry.
        add hl, bc              ; add to address the relevant entry.
        jr GET_PARAM            ; forward to continue at GET-PARAM


; ----------------------
; The main scanning loop
; ----------------------
; not documented properly
;

;; SCAN-LOOP

SCAN_LOOP:
        ld hl, (T_ADDR)         ; fetch temporary address from T_ADDR
                                ; during subsequent loops.

; -> the initial entry point with HL addressing start of syntax table entry.

;; GET-PARAM

GET_PARAM:
        ldi a, (hl)             ; pick up the parameter.
                                ; address next one.
        ld (T_ADDR), hl         ; save pointer in system variable T_ADDR

        ld bc, SCAN_LOOP        ; address: SCAN-LOOP
        push bc                 ; is now pushed on stack as looping address.
        ld c, a                 ; store parameter in C.
        cp $20                  ; is it greater than ' '  ?
        jr nc, SEPARATOR        ; forward to SEPARATOR to check that correct
                                ; separator appears in statement if so.

        ld hl, class_tbl        ; address: class-tbl.
        ld b, $00               ; prepare to index into the class table.
        add hl, bc              ; index to find displacement to routine.
        ld c, (hl)              ; displacement to BC
        add hl, bc              ; add to address the CLASS routine.
        push hl                 ; push the address on the stack.

        rst $18                 ; GET-CHAR - HL points to place in statement.

        dec b                   ; reset the zero flag - the initial state
                                ; for all class routines.

        ret                     ; and make an indirect jump to routine
                                ; and then SCAN-LOOP (also on stack).


; Note. one of the class routines will eventually drop the return address
; off the stack breaking out of the above seemingly endless loop.

; -----------------------
; THE 'SEPARATOR' ROUTINE
; -----------------------
;   This routine is called once to verify that the mandatory separator
;   present in the parameter table is also present in the correct
;   location following the command.  For example, the 'THEN' token after
;   the 'IF' token and expression.

;; SEPARATOR

SEPARATOR:
        rst $18                 ; GET-CHAR
        cp c                    ; does it match the character in C ?
        jp nz, REPORT_C         ; jump forward to REPORT-C if not
                                ; 'Nonsense in BASIC'.

        rst $20                 ; NEXT-CHAR advance to next character
        ret                     ; return.


; ------------------------------
; Come here after interpretation
; ------------------------------
;
;

;; STMT-RET

STMT_RET:
        call BREAK_KEY          ; routine BREAK-KEY is tested after every
                                ; statement.
        jr c, STMT_R_1          ; step forward to STMT-R-1 if not pressed.

;; REPORT-L

REPORT_L:
        rst $08                 ; ERROR-1
        defb $14                ; Error Report: BREAK into program

;; STMT-R-1

STMT_R_1:
        bit 7, (iy+NSPPC-IY0)   ; test NSPPC - will be set if $FF -
                                ; no jump to be made.
        jr nz, STMT_NEXT        ; forward to STMT-NEXT if a program line.

        ld hl, (NEWPPC)         ; fetch line number from NEWPPC
        bit 7, h                ; will be set if minus two - direct command(s)
        jr z, LINE_NEW          ; forward to LINE-NEW if a jump is to be
                                ; made to a new program line/statement.

; --------------------
; Run a direct command
; --------------------
; A direct command is to be run or, if continuing from above,
; the next statement of a direct command is to be considered.

;; LINE-RUN

LINE_RUN:
        ld hl, $FFFE            ; The dummy value minus two
        ld (PPC), hl            ; is set/reset as line number in PPC.
        ld hl, (WORKSP)         ; point to end of line + 1 - WORKSP.
        dec hl                  ; now point to $80 end-marker.
        ld de, (E_LINE)         ; address the start of line E_LINE.
        dec de                  ; now location before - for GET-CHAR.
        ld a, (NSPPC)           ; load statement to A from NSPPC.
        jr NEXT_LINE            ; forward to NEXT-LINE.


; ------------------------------
; Find start address of new line
; ------------------------------
; The branch was to here if a jump is to made to a new line number
; and statement.
; That is the previous statement was a GO TO, GO SUB, RUN, RETURN, NEXT etc..

;; LINE-NEW

LINE_NEW:
        call LINE_ADDR          ; routine LINE-ADDR gets address of line
                                ; returning zero flag set if line found.
        ld a, (NSPPC)           ; fetch new statement from NSPPC
        jr z, LINE_USE          ; forward to LINE-USE if line matched.

; continue as must be a direct command.

        and a                   ; test statement which should be zero
        jr nz, REPORT_N         ; forward to REPORT-N if not.
                                ; 'Statement lost'

; 

        ld b, a                 ; save statement in B.??
        ld a, (hl)              ; fetch high byte of line number.
        and $C0                 ; test if using direct command
                                ; a program line is less than $3F
        ld a, b                 ; retrieve statement.
                                ; (we can assume it is zero).
        jr z, LINE_USE          ; forward to LINE-USE if was a program line

; Alternatively a direct statement has finished correctly.

;; REPORT-0

REPORT_0:
        rst $08                 ; ERROR-1
        defb $FF                ; Error Report: OK

; -----------------
; THE 'REM' COMMAND
; -----------------
; The REM command routine.
; The return address STMT-RET is dropped and the rest of line ignored.

;; REM

REM:
        pop bc                  ; drop return address STMT-RET and
                                ; continue ignoring rest of line.

; ------------
; End of line?
; ------------
;
;

;; LINE-END

LINE_END:
        call SYNTAX_Z           ; routine SYNTAX-Z  (UNSTACK-Z?)
        ret z                   ; return if checking syntax.

        ld hl, (NXTLIN)         ; fetch NXTLIN to HL.
        ld a, $C0               ; test against the
        and (hl)                ; system limit $3F.
        ret nz                  ; return if more as must be
                                ; end of program.
                                ; (or direct command)

        xor a                   ; set statement to zero.

; and continue to set up the next following line and then consider this new one.

; ---------------------
; General line checking
; ---------------------
; The branch was here from LINE-NEW if BASIC is branching.
; or a continuation from above if dealing with a new sequential line.
; First make statement zero number one leaving others unaffected.

;; LINE-USE

LINE_USE:
        cp $01                  ; will set carry if zero.
        adc a, $00              ; add in any carry.

        ldi d, (hl)             ; high byte of line number to D.
                                ; advance pointer.
        ld e, (hl)              ; low byte of line number to E.
        ld (PPC), de            ; set system variable PPC.

        inc hl                  ; advance pointer.
        ldi e, (hl)             ; low byte of line length to E.
                                ; advance pointer.
        ld d, (hl)              ; high byte of line length to D.

        ex de, hl               ; swap pointer to DE before
        add hl, de              ; adding to address the end of line.
        inc hl                  ; advance to start of next line.

; -----------------------------
; Update NEXT LINE but consider
; previous line or edit line.
; -----------------------------
; The pointer will be the next line if continuing from above or to
; edit line end-marker ($80) if from LINE-RUN.

;; NEXT-LINE

NEXT_LINE:
        ld (NXTLIN), hl         ; store pointer in system variable NXTLIN

        ex de, hl               ; bring back pointer to previous or edit line
        ld (CH_ADD), hl         ; and update CH_ADD with character address.

        ld d, a                 ; store statement in D.
        ld e, $00               ; set E to zero to suppress token searching
                                ; if EACH-STMT is to be called.
        ld (iy+NSPPC-IY0), $FF  ; set statement NSPPC to $FF signalling
                                ; no jump to be made.
        dec d                   ; decrement and test statement
        ld (iy+SUBPPC-IY0), d   ; set SUBPPC to decremented statement number.
        jp z, STMT_LOOP         ; to STMT-LOOP if result zero as statement is
                                ; at start of line and address is known.

        inc d                   ; else restore statement.
        call EACH_STMT          ; routine EACH-STMT finds the D'th statement
                                ; address as E does not contain a token.
        jr z, STMT_NEXT         ; forward to STMT-NEXT if address found.

;; REPORT-N

REPORT_N:
        rst $08                 ; ERROR-1
        defb $16                ; Error Report: Statement lost

; -----------------
; End of statement?
; -----------------
; This combination of routines is called from 20 places when
; the end of a statement should have been reached and all preceding
; syntax is in order.

;; CHECK-END

CHECK_END:
        call SYNTAX_Z           ; routine SYNTAX-Z
        ret nz                  ; return immediately in runtime

        pop bc                  ; drop address of calling routine.
        pop bc                  ; drop address STMT-RET.
                                ; and continue to find next statement.

; --------------------
; Go to next statement
; --------------------
; Acceptable characters at this point are carriage return and ':'.
; If so go to next statement which in the first case will be on next line.

;; STMT-NEXT

STMT_NEXT:
        rst $18                 ; GET-CHAR - ignoring white space etc.

        cp $0D                  ; is it carriage return ?
        jr z, LINE_END          ; back to LINE-END if so.

        cp $3A                  ; is it ':' ?
        jp z, STMT_LOOP         ; jump back to STMT-LOOP to consider
                                ; further statements

        jp REPORT_C             ; jump to REPORT-C with any other character
                                ; 'Nonsense in BASIC'.


; Note. the two-byte sequence 'rst 08; defb $0b' could replace the above jp.

; -------------------
; Command class table
; -------------------
;

;; class-tbl

class_tbl:
        defb CLASS_00 - $       ; 0F offset to Address: CLASS-00
        defb CLASS_01 - $       ; 1D offset to Address: CLASS-01
        defb CLASS_02 - $       ; 4B offset to Address: CLASS-02
        defb CLASS_03 - $       ; 09 offset to Address: CLASS-03
        defb CLASS_04 - $       ; 67 offset to Address: CLASS-04
        defb CLASS_05 - $       ; 0B offset to Address: CLASS-05
        defb EXPT_1NUM - $      ; 7B offset to Address: CLASS-06
        defb CLASS_07 - $       ; 8E offset to Address: CLASS-07
        defb EXPT_2NUM - $      ; 71 offset to Address: CLASS-08
        defb CLASS_09 - $       ; B4 offset to Address: CLASS-09
        defb EXPT_EXP - $       ; 81 offset to Address: CLASS-0A
        defb CLASS_0B - $       ; CF offset to Address: CLASS-0B


; --------------------------------
; Command classes---00, 03, and 05
; --------------------------------
; class-03 e.g. RUN or RUN 200   ;  optional operand
; class-00 e.g. CONTINUE         ;  no operand
; class-05 e.g. PRINT            ;  variable syntax checked by routine

;; CLASS-03

CLASS_03:
        call FETCH_NUM          ; routine FETCH-NUM

;; CLASS-00


CLASS_00:
        cp a                    ; reset zero flag.

; if entering here then all class routines are entered with zero reset.

;; CLASS-05

CLASS_05:
        pop bc                  ; drop address SCAN-LOOP.
        call z, CHECK_END       ; if zero set then call routine CHECK-END >>>
                                ; as should be no further characters.

        ex de, hl               ; save HL to DE.
        ld hl, (T_ADDR)         ; fetch T_ADDR
        ldi c, (hl)             ; fetch low byte of routine
                                ; address next.
        ld b, (hl)              ; fetch high byte of routine.
        ex de, hl               ; restore HL from DE
        push bc                 ; push the address
        ret                     ; and make an indirect jump to the command.


; --------------------------------
; Command classes---01, 02, and 04
; --------------------------------
; class-01  e.g. LET A = 2*3     ; a variable is reqd

; This class routine is also called from INPUT and READ to find the
; destination variable for an assignment.

;; CLASS-01

CLASS_01:
        call LOOK_VARS          ; routine LOOK-VARS returns carry set if not
                                ; found in runtime.

; ----------------------
; Variable in assignment
; ----------------------
;
;

;; VAR-A-1

VAR_A_1:
        ld (iy+FLAGX-IY0), $00  ; set FLAGX to zero
        jr nc, VAR_A_2          ; forward to VAR-A-2 if found or checking
                                ; syntax.

        set 1, (iy+FLAGX-IY0)   ; FLAGX  - Signal a new variable
        jr nz, VAR_A_3          ; to VAR-A-3 if not assigning to an array
                                ; e.g. LET a$(3,3) = "X"

;; REPORT-2

REPORT_2:
        rst $08                 ; ERROR-1
        defb $01                ; Error Report: Variable not found

;; VAR-A-2

VAR_A_2:
        call z, STK_VAR         ; routine STK-VAR considers a subscript/slice
        bit 6, (iy+FLAGS-IY0)   ; test FLAGS  - Numeric or string result ?
        jr nz, VAR_A_3          ; to VAR-A-3 if numeric

        xor a                   ; default to array/slice - to be retained.
        call SYNTAX_Z           ; routine SYNTAX-Z
        call nz, STK_FETCH      ; routine STK-FETCH is called in runtime
                                ; may overwrite A with 1.
        ld hl, FLAGX            ; address system variable FLAGX
        or (hl)                 ; set bit 0 if simple variable to be reclaimed
        ld (hl), a              ; update FLAGX
        ex de, hl               ; start of string/subscript to DE

;; VAR-A-3

VAR_A_3:
        ld (STRLEN), bc         ; update STRLEN
        ld (DEST), hl           ; and DEST of assigned string.
        ret                     ; return.


; -------------------------------------------------
; class-02 e.g. LET a = 1 + 1   ; an expression must follow

;; CLASS-02

CLASS_02:
        pop bc                  ; drop return address SCAN-LOOP
        call VAL_FET_1          ; routine VAL-FET-1 is called to check
                                ; expression and assign result in runtime
        call CHECK_END          ; routine CHECK-END checks nothing else
                                ; is present in statement.
        ret                     ; Return


; -------------
; Fetch a value
; -------------
;
;

;; VAL-FET-1

VAL_FET_1:
        ld a, (FLAGS)           ; initial FLAGS to A

;; VAL-FET-2

VAL_FET_2:
        push af                 ; save A briefly
        call SCANNING           ; routine SCANNING evaluates expression.
        pop af                  ; restore A
        ld d, (iy+FLAGS-IY0)    ; post-SCANNING FLAGS to D
        xor d                   ; xor the two sets of flags
        and $40                 ; pick up bit 6 of xored FLAGS should be zero
        jr nz, REPORT_C         ; forward to REPORT-C if not zero
                                ; 'Nonsense in BASIC' - results don't agree.

        bit 7, d                ; test FLAGS - is syntax being checked ?
        jp nz, LET              ; jump forward to LET to make the assignment
                                ; in runtime.

        ret                     ; but return from here if checking syntax.


; ------------------
; Command class---04
; ------------------
; class-04 e.g. FOR i            ; a single character variable must follow

;; CLASS-04

CLASS_04:
        call LOOK_VARS          ; routine LOOK-VARS
        push af                 ; preserve flags.
        ld a, c                 ; fetch type - should be 011xxxxx
        or $9F                  ; combine with 10011111.
        inc a                   ; test if now $FF by incrementing.
        jr nz, REPORT_C         ; forward to REPORT-C if result not zero.

        pop af                  ; else restore flags.
        jr VAR_A_1              ; back to VAR-A-1



; --------------------------------
; Expect numeric/string expression
; --------------------------------
; This routine is used to get the two coordinates of STRING$, ATTR and POINT.
; It is also called from PRINT-ITEM to get the two numeric expressions that
; follow the AT ( in PRINT AT, INPUT AT).

;; NEXT-2NUM

NEXT_2NUM:
        rst $20                 ; NEXT-CHAR advance past 'AT' or '('.

; --------
; class-08 e.g. POKE 65535,2     ; two numeric expressions separated by comma
;; CLASS-08
;; EXPT-2NUM

EXPT_2NUM:
        call EXPT_1NUM          ; routine EXPT-1NUM is called for first
                                ; numeric expression
        cp $2C                  ; is character ',' ?
        jr nz, REPORT_C         ; to REPORT-C if not required separator.
                                ; 'Nonsense in BASIC'.

        rst $20                 ; NEXT-CHAR

; ->
;  class-06  e.g. GOTO a*1000   ; a numeric expression must follow
;; CLASS-06
;; EXPT-1NUM

EXPT_1NUM:
        call SCANNING           ; routine SCANNING
        bit 6, (iy+FLAGS-IY0)   ; test FLAGS  - Numeric or string result ?
        ret nz                  ; return if result is numeric.

;; REPORT-C

REPORT_C:
        rst $08                 ; ERROR-1
        defb $0B                ; Error Report: Nonsense in BASIC

; ---------------------------------------------------------------
; class-0A e.g. ERASE "????"    ; a string expression must follow.
;                               ; these only occur in unimplemented commands
;                               ; although the routine expt-exp is called
;                               ; from SAVE-ETC

;; CLASS-0A
;; EXPT-EXP

EXPT_EXP:
        call SCANNING           ; routine SCANNING
        bit 6, (iy+FLAGS-IY0)   ; test FLAGS  - Numeric or string result ?
        ret z                   ; return if string result.

        jr REPORT_C             ; back to REPORT-C if numeric.


; ---------------------
; Set permanent colours
; class 07
; ---------------------
; class-07 e.g. PAPER 6          ; a single class for a collection of
;                               ; similar commands. Clever.
;
; Note. these commands should ensure that current channel is 'S'

;; CLASS-07

CLASS_07:
        bit 7, (iy+FLAGS-IY0)   ; test FLAGS - checking syntax only ?
                                ; Note. there is a subroutine to do this.
        res 0, (iy+TV_FLAG-IY0) ; update TV_FLAG - signal main screen in use
        call nz, TEMPS          ; routine TEMPS is called in runtime.
        pop af                  ; drop return address SCAN-LOOP
        ld a, (T_ADDR)          ; T_ADDR_lo to accumulator.
                                ; points to '$07' entry + 1
                                ; e.g. for INK points to $EC now

; Note if you move alter the syntax table next line may have to be altered.

; Note. For ZASM assembler replace following expression with SUB $13.


L1CA5:
        sub +(P_INK - $D8) % 256
                                ; convert $EB to $D8 ('INK') etc.
                                ; ( is SUB $13 in standard ROM )

        call CO_TEMP_4          ; routine CO-TEMP-4
        call CHECK_END          ; routine CHECK-END check that nothing else
                                ; in statement.

; return here in runtime.

        ld hl, (ATTR_T)         ; pick up ATTR_T and MASK_T
        ld (ATTR_P), hl         ; and store in ATTR_P and MASK_P
        ld hl, P_FLAG           ; point to P_FLAG.
        ld a, (hl)              ; pick up in A
        rlca                    ; rotate to left
        xor (hl)                ; combine with HL
        and $AA                 ; 10101010
        xor (hl)                ; only permanent bits affected
        ld (hl), a              ; reload into P_FLAG.
        ret                     ; return.


; ------------------
; Command class---09
; ------------------
; e.g. PLOT PAPER 0; 128,88     ; two coordinates preceded by optional
;                               ; embedded colour items.
;
; Note. this command should ensure that current channel is actually 'S'.

;; CLASS-09

CLASS_09:
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, CL_09_1           ; forward to CL-09-1 if checking syntax.

        res 0, (iy+TV_FLAG-IY0) ; update TV_FLAG - signal main screen in use
        call TEMPS              ; routine TEMPS is called.
        ld hl, MASK_T           ; point to MASK_T
        ld a, (hl)              ; fetch mask to accumulator.
        or $F8                  ; or with 11111000 paper/bright/flash 8
        ld (hl), a              ; mask back to MASK_T system variable.
        res 6, (iy+P_FLAG-IY0)  ; reset P_FLAG  - signal NOT PAPER 9 ?

        rst $18                 ; GET-CHAR

;; CL-09-1

CL_09_1:
        call CO_TEMP_2          ; routine CO-TEMP-2 deals with any embedded
                                ; colour items.
        jr EXPT_2NUM            ; exit via EXPT-2NUM to check for x,y.


; Note. if either of the numeric expressions contain STR$ then the flag setting 
; above will be undone when the channel flags are reset during STR$.
; e.g. 
; 10 BORDER 3 : PLOT VAL STR$ 128, VAL STR$ 100
; credit John Elliott.

; ------------------
; Command class---0B
; ------------------
; Again a single class for four commands.
; This command just jumps back to SAVE-ETC to handle the four tape commands.
; The routine itself works out which command has called it by examining the
; address in T_ADDR_lo. Note therefore that the syntax table has to be
; located where these and other sequential command addresses are not split
; over a page boundary.

;; CLASS-0B

CLASS_0B:
        jp SAVE_ETC             ; jump way back to SAVE-ETC


; --------------
; Fetch a number
; --------------
; This routine is called from CLASS-03 when a command may be followed by
; an optional numeric expression e.g. RUN. If the end of statement has
; been reached then zero is used as the default.
; Also called from LIST-4.

;; FETCH-NUM

FETCH_NUM:
        cp $0D                  ; is character a carriage return ?
        jr z, USE_ZERO          ; forward to USE-ZERO if so

        cp $3A                  ; is it ':' ?
        jr nz, EXPT_1NUM        ; forward to EXPT-1NUM if not.
                                ; else continue and use zero.

; ----------------
; Use zero routine
; ----------------
; This routine is called four times to place the value zero on the
; calculator stack as a default value in runtime.

;; USE-ZERO

USE_ZERO:
        call SYNTAX_Z           ; routine SYNTAX-Z  (UNSTACK-Z?)
        ret z

        rst $28                 ; ; FP-CALC
        defb $A0                ; ;stk-zero       ;0.
        defb $38                ; ;end-calc

        ret                     ; return.


; -------------------
; Handle STOP command
; -------------------
; Command Syntax: STOP
; One of the shortest and least used commands. As with 'OK' not an error.

;; REPORT-9
;; STOP

STOP_BAS:
        rst $08                 ; ERROR-1
        defb $08                ; Error Report: STOP statement

; -----------------
; Handle IF command
; -----------------
; e.g. IF score>100 THEN PRINT "You Win"
; The parser has already checked the expression the result of which is on
; the calculator stack. The presence of the 'THEN' separator has also been
; checked and CH-ADD points to the command after THEN.
;

;; IF

IF:
        pop bc                  ; drop return address - STMT-RET
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, IF_1              ; forward to IF-1 if checking syntax
                                ; to check syntax of PRINT "You Win"


        rst $28                 ; ; FP-CALC    score>100 (1=TRUE 0=FALSE)
        defb $02                ; ;delete      .
        defb $38                ; ;end-calc

        ex de, hl               ; make HL point to deleted value
        call TEST_ZERO          ; routine TEST-ZERO
        jp c, LINE_END          ; jump to LINE-END if FALSE (0)

;; IF-1

IF_1:
        jp STMT_L_1             ; to STMT-L-1, if true (1) to execute command
                                ; after 'THEN' token.


; ------------------
; Handle FOR command
; ------------------
; e.g. FOR i = 0 TO 1 STEP 0.1
; Using the syntax tables, the parser has already checked for a start and
; limit value and also for the intervening separator.
; the two values v,l are on the calculator stack.
; CLASS-04 has also checked the variable and the name is in STRLEN_lo.
; The routine begins by checking for an optional STEP.

;; FOR

FOR:
        cp $CD                  ; is there a 'STEP' ?
        jr nz, F_USE_1          ; to F-USE-1 if not to use 1 as default.

        rst $20                 ; NEXT-CHAR
        call EXPT_1NUM          ; routine EXPT-1NUM
        call CHECK_END          ; routine CHECK-END
        jr F_REORDER            ; to F-REORDER


; ---

;; F-USE-1

F_USE_1:
        call CHECK_END          ; routine CHECK-END

        rst $28                 ; ; FP-CALC      v,l.
        defb $A1                ; ;stk-one       v,l,1=s.
        defb $38                ; ;end-calc


;; F-REORDER

F_REORDER:
        rst $28                 ; ; FP-CALC       v,l,s.
        defb $C0                ; ;st-mem-0       v,l,s.
        defb $02                ; ;delete         v,l.
        defb $01                ; ;exchange       l,v.
        defb $E0                ; ;get-mem-0      l,v,s.
        defb $01                ; ;exchange       l,s,v.
        defb $38                ; ;end-calc

        call LET                ; routine LET assigns the initial value v to
                                ; the variable altering type if necessary.
        ld (MEM), hl            ; The system variable MEM is made to point to
                                ; the variable instead of its normal
                                ; location MEMBOT
        dec hl                  ; point to single-character name
        ld a, (hl)              ; fetch name
        set 7, (hl)             ; set bit 7 at location
        ld bc, $0006            ; add six to HL
        add hl, bc              ; to address where limit should be.
        rlca                    ; test bit 7 of original name.
        jr c, F_L_S             ; forward to F-L-S if already a FOR/NEXT
                                ; variable

        ld c, $0D               ; otherwise an additional 13 bytes are needed.
                                ; 5 for each value, two for line number and
                                ; 1 byte for looping statement.
        call MAKE_ROOM          ; routine MAKE-ROOM creates them.
        inc hl                  ; make HL address limit.

;; F-L-S

F_L_S:
        push hl                 ; save position.

        rst $28                 ; ; FP-CALC         l,s.
        defb $02                ; ;delete           l.
        defb $02                ; ;delete           .
        defb $38                ; ;end-calc
                                ; DE points to STKEND, l.

        pop hl                  ; restore variable position
        ex de, hl               ; swap pointers
        ld c, $0A               ; ten bytes to move
        ldir                    ; Copy 'deleted' values to variable.
        ld hl, (PPC)            ; Load with current line number from PPC
        ex de, hl               ; exchange pointers.
        ldi (hl), e             ; save the looping line
                                ; in the next
        ld (hl), d              ; two locations.
        ld d, (iy+SUBPPC-IY0)   ; fetch statement from SUBPPC system variable.
        inc d                   ; increment statement.
        inc hl                  ; and pointer
        ld (hl), d              ; and store the looping statement.
        call NEXT_LOOP          ; routine NEXT-LOOP considers an initial
        ret nc                  ; iteration. Return to STMT-RET if a loop is
                                ; possible to execute next statement.

; no loop is possible so execution continues after the matching 'NEXT'

        ld b, (iy+STRLEN-IY0)   ; get single-character name from STRLEN_lo
        ld hl, (PPC)            ; get the current line from PPC
        ld (NEWPPC), hl         ; and store it in NEWPPC
        ld a, (SUBPPC)          ; fetch current statement from SUBPPC
        neg                     ; Negate as counter decrements from zero
                                ; initially and we are in the middle of a
                                ; line.
        ld d, a                 ; Store result in D.
        ld hl, (CH_ADD)         ; get current address from CH_ADD
        ld e, $F3               ; search will be for token 'NEXT'

;; F-LOOP

F_LOOP:
        push bc                 ; save variable name.
        ld bc, (NXTLIN)         ; fetch NXTLIN
        call LOOK_PROG          ; routine LOOK-PROG searches for 'NEXT' token.
        ld (NXTLIN), bc         ; update NXTLIN
        pop bc                  ; and fetch the letter
        jr c, REPORT_I          ; forward to REPORT-I if the end of program
                                ; was reached by LOOK-PROG.
                                ; 'FOR without NEXT'

        rst $20                 ; NEXT-CHAR fetches character after NEXT
        or $20                  ; ensure it is upper-case.
        cp b                    ; compare with FOR variable name
        jr z, F_FOUND           ; forward to F-FOUND if it matches.

; but if no match i.e. nested FOR/NEXT loops then continue search.

        rst $20                 ; NEXT-CHAR
        jr F_LOOP               ; back to F-LOOP


; ---


;; F-FOUND

F_FOUND:
        rst $20                 ; NEXT-CHAR
        ld a, $01               ; subtract the negated counter from 1
        sub d                   ; to give the statement after the NEXT
        ld (NSPPC), a           ; set system variable NSPPC
        ret                     ; return to STMT-RET to branch to new
                                ; line and statement. ->
                                ; ---


;; REPORT-I

REPORT_I:
        rst $08                 ; ERROR-1
        defb $11                ; Error Report: FOR without NEXT

; ---------
; LOOK-PROG
; ---------
; Find DATA, DEF FN or NEXT.
; This routine searches the program area for one of the above three keywords.
; On entry, HL points to start of search area.
; The token is in E, and D holds a statement count, decremented from zero.

;; LOOK-PROG

LOOK_PROG:
        ld a, (hl)              ; fetch current character
        cp $3A                  ; is it ':' a statement separator ?
        jr z, LOOK_P_2          ; forward to LOOK-P-2 if so.

; The starting point was PROG - 1 or the end of a line.

;; LOOK-P-1

LOOK_P_1:
        inc hl                  ; increment pointer to address
        ld a, (hl)              ; the high byte of line number
        and $C0                 ; test for program end marker $80 or a
                                ; variable
        scf                     ; Set Carry Flag
        ret nz                  ; return with carry set if at end
                                ; of program.           ->

        ldi b, (hl)             ; high byte of line number to B
        ld c, (hl)              ; low byte to C.
        ld (NEWPPC), bc         ; set system variable NEWPPC.
        inc hl
        ldi c, (hl)             ; low byte of line length to C.
        ld b, (hl)              ; high byte to B.
        push hl                 ; save address
        add hl, bc              ; add length to position.
        ld bc, hl               ; and save result
                                ; in BC.
        pop hl                  ; restore address.
        ld d, $00               ; initialize statement counter to zero.

;; LOOK-P-2

LOOK_P_2:
        push bc                 ; save address of next line
        call EACH_STMT          ; routine EACH-STMT searches current line.
        pop bc                  ; restore address.
        ret nc                  ; return if match was found. ->

        jr LOOK_P_1             ; back to LOOK-P-1 for next line.


; -------------------
; Handle NEXT command
; -------------------
; e.g. NEXT i
; The parameter tables have already evaluated the presence of a variable

;; NEXT

NEXT:
        bit 1, (iy+FLAGX-IY0)   ; test FLAGX - handling a new variable ?
        jp nz, REPORT_2         ; jump back to REPORT-2 if so
                                ; 'Variable not found'

; now test if found variable is a simple variable uninitialized by a FOR.

        ld hl, (DEST)           ; load address of variable from DEST
        bit 7, (hl)             ; is it correct type ?
        jr z, REPORT_1          ; forward to REPORT-1 if not
                                ; 'NEXT without FOR'

        inc hl                  ; step past variable name
        ld (MEM), hl            ; and set MEM to point to three 5-byte values
                                ; value, limit, step.

        rst $28                 ; ; FP-CALC     add step and re-store
        defb $E0                ; ;get-mem-0    v.
        defb $E2                ; ;get-mem-2    v,s.
        defb $0F                ; ;addition     v+s.
        defb $C0                ; ;st-mem-0     v+s.
        defb $02                ; ;delete       .
        defb $38                ; ;end-calc

        call NEXT_LOOP          ; routine NEXT-LOOP tests against limit.
        ret c                   ; return if no more iterations possible.

        ld hl, (MEM)            ; find start of variable contents from MEM.
        ld de, $000F            ; add 3*5 to
        add hl, de              ; address the looping line number
        ldi de, (hl)            ; low byte to E
                                ; high byte to D
                                ; address looping statement
        ld h, (hl)              ; and store in H
        ex de, hl               ; swap registers
        jp GO_TO_2              ; exit via GO-TO-2 to execute another loop.


; ---

;; REPORT-1

REPORT_1:
        rst $08                 ; ERROR-1
        defb $00                ; Error Report: NEXT without FOR


; -----------------
; Perform NEXT loop
; -----------------
; This routine is called from the FOR command to test for an initial
; iteration and from the NEXT command to test for all subsequent iterations.
; the system variable MEM addresses the variable's contents which, in the
; latter case, have had the step, possibly negative, added to the value.

;; NEXT-LOOP

NEXT_LOOP:
        rst $28                 ; ; FP-CALC
        defb $E1                ; ;get-mem-1        l.
        defb $E0                ; ;get-mem-0        l,v.
        defb $E2                ; ;get-mem-2        l,v,s.
        defb $36                ; ;less-0           l,v,(1/0) negative step ?
        defb $00                ; ;jump-true        l,v.(1/0)

        defb $02                ; ;to L1DE2, NEXT-1 if step negative

        defb $01                ; ;exchange         v,l.

;; NEXT-1

NEXT_1:
        defb $03                ; ;subtract         l-v OR v-l.
        defb $37                ; ;greater-0        (1/0)
        defb $00                ; ;jump-true        .

        defb $04                ; ;to L1DE9, NEXT-2 if no more iterations.

        defb $38                ; ;end-calc         .

        and a                   ; clear carry flag signalling another loop.
        ret                     ; return


; ---

;; NEXT-2

NEXT_2:
        defb $38                ; ;end-calc         .

        scf                     ; set carry flag signalling looping exhausted.
        ret                     ; return



; -------------------
; Handle READ command
; -------------------
; e.g. READ a, b$, c$(1000 TO 3000)
; A list of comma-separated variables is assigned from a list of
; comma-separated expressions.
; As it moves along the first list, the character address CH_ADD is stored
; in X_PTR while CH_ADD is used to read the second list.

;; READ-3

READ_3:
        rst $20                 ; NEXT-CHAR

; -> Entry point.
;; READ

READ:
        call CLASS_01           ; routine CLASS-01 checks variable.
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, READ_2            ; forward to READ-2 if checking syntax


        rst $18                 ; GET-CHAR
        ld (X_PTR), hl          ; save character position in X_PTR.
        ld hl, (DATADD)         ; load HL with Data Address DATADD, which is
                                ; the start of the program or the address
                                ; after the last expression that was read or
                                ; the address of the line number of the
                                ; last RESTORE command.
        ld a, (hl)              ; fetch character
        cp $2C                  ; is it a comma ?
        jr z, READ_1            ; forward to READ-1 if so.

; else all data in this statement has been read so look for next DATA token

        ld e, $E4               ; token 'DATA'
        call LOOK_PROG          ; routine LOOK-PROG
        jr nc, READ_1           ; forward to READ-1 if DATA found

; else report the error.

;; REPORT-E

REPORT_E:
        rst $08                 ; ERROR-1
        defb $0D                ; Error Report: Out of DATA

;; READ-1

READ_1:
        call TEMP_PTR1          ; routine TEMP-PTR1 advances updating CH_ADD
                                ; with new DATADD position.
        call VAL_FET_1          ; routine VAL-FET-1 assigns value to variable
                                ; checking type match and adjusting CH_ADD.

        rst $18                 ; GET-CHAR fetches adjusted character position
        ld (DATADD), hl         ; store back in DATADD
        ld hl, (X_PTR)          ; fetch X_PTR  the original READ CH_ADD
        ld (iy+$26), $00        ; now nullify X_PTR_hi
        call TEMP_PTR2          ; routine TEMP-PTR2 restores READ CH_ADD

;; READ-2

READ_2:
        rst $18                 ; GET-CHAR
        cp $2C                  ; is it ',' indicating more variables to read ?
        jr z, READ_3            ; back to READ-3 if so

        call CHECK_END          ; routine CHECK-END
        ret                     ; return from here in runtime to STMT-RET.


; -------------------
; Handle DATA command
; -------------------
; In runtime this 'command' is passed by but the syntax is checked when such
; a statement is found while parsing a line.
; e.g. DATA 1, 2, "text", score-1, a$(location, room, object), FN r(49),
;         wages - tax, TRUE, The meaning of life

;; DATA

DATA:
        call SYNTAX_Z           ; routine SYNTAX-Z to check status
        jr nz, DATA_2           ; forward to DATA-2 if in runtime

;; DATA-1

DATA_1:
        call SCANNING           ; routine SCANNING to check syntax of
                                ; expression
        cp $2C                  ; is it a comma ?
        call nz, CHECK_END      ; routine CHECK-END checks that statement
                                ; is complete. Will make an early exit if
                                ; so. >>>
        rst $20                 ; NEXT-CHAR
        jr DATA_1               ; back to DATA-1


; ---

;; DATA-2

DATA_2:
        ld a, $E4               ; set token to 'DATA' and continue into
                                ; the PASS-BY routine.


; ----------------------------------
; Check statement for DATA or DEF FN
; ----------------------------------
; This routine is used to backtrack to a command token and then
; forward to the next statement in runtime.

;; PASS-BY

PASS_BY:
        ld b, a                 ; Give BC enough space to find token.
        cpdr                    ; Compare decrement and repeat. (Only use).
                                ; Work backwards till keyword is found which
                                ; is start of statement before any quotes.
                                ; HL points to location before keyword.
        ld de, $0200            ; count 1+1 statements, dummy value in E to
                                ; inhibit searching for a token.
        jp EACH_STMT            ; to EACH-STMT to find next statement


; -----------------------------------------------------------------------
; A General Note on Invalid Line Numbers.
; =======================================
; One of the revolutionary concepts of Sinclair BASIC was that it supported
; virtual line numbers. That is the destination of a GO TO, RESTORE etc. need
; not exist. It could be a point before or after an actual line number.
; Zero suffices for a before but the after should logically be infinity.
; Since the maximum actual line limit is 9999 then the system limit, 16383
; when variables kick in, would serve fine as a virtual end point.
; However, ironically, only the LOAD command gets it right. It will not
; autostart a program that has been saved with a line higher than 16383.
; All the other commands deal with the limit unsatisfactorily.
; LIST, RUN, GO TO, GO SUB and RESTORE have problems and the latter may
; crash the machine when supplied with an inappropriate virtual line number.
; This is puzzling as very careful consideration must have been given to
; this point when the new variable types were allocated their masks and also
; when the routine NEXT-ONE was successfully re-written to reflect this.
; An enigma.
; -------------------------------------------------------------------------

; ----------------------
; Handle RESTORE command
; ----------------------
; The restore command sets the system variable for the data address to
; point to the location before the supplied line number or first line
; thereafter.
; This alters the position where subsequent READ commands look for data.
; Note. If supplied with inappropriate high numbers the system may crash
; in the LINE-ADDR routine as it will pass the program/variables end-marker
; and then lose control of what it is looking for - variable or line number.
; - observation, Steven Vickers, 1984, Pitman.

;; RESTORE

RESTORE:
        call FIND_INT2          ; routine FIND-INT2 puts integer in BC.
                                ; Note. B should be checked against limit $3F
                                ; and an error generated if higher.

; this entry point is used from RUN command with BC holding zero

;; REST-RUN

REST_RUN:
        ld hl, bc               ; transfer the line
                                ; number to the HL register.
        call LINE_ADDR          ; routine LINE-ADDR to fetch the address.
        dec hl                  ; point to the location before the line.
        ld (DATADD), hl         ; update system variable DATADD.
        ret                     ; return to STMT-RET (or RUN)


; ------------------------
; Handle RANDOMIZE command
; ------------------------
; This command sets the SEED for the RND function to a fixed value.
; With the parameter zero, a random start point is used depending on
; how long the computer has been switched on.

;; RANDOMIZE

RANDOMIZE:
        call FIND_INT2          ; routine FIND-INT2 puts parameter in BC.
        ld a, b                 ; test this
        or c                    ; for zero.
        jr nz, RAND_1           ; forward to RAND-1 if not zero.

        ld bc, (FRAMES)         ; use the lower two bytes at FRAMES1.

;; RAND-1

RAND_1:
        ld (SEED), bc           ; place in SEED system variable.
        ret                     ; return to STMT-RET


; -----------------------
; Handle CONTINUE command
; -----------------------
; The CONTINUE command transfers the OLD (but incremented) values of
; line number and statement to the equivalent "NEW VALUE" system variables
; by using the last part of GO TO and exits indirectly to STMT-RET.

;; CONTINUE

CONTINUE:
        ld hl, (OLDPPC)         ; fetch OLDPPC line number.
        ld d, (iy+OSPCC-IY0)    ; fetch OSPPC statement.
        jr GO_TO_2              ; forward to GO-TO-2


; --------------------
; Handle GO TO command
; --------------------
; The GO TO command routine is also called by GO SUB and RUN routines
; to evaluate the parameters of both commands.
; It updates the system variables used to fetch the next line/statement.
; It is at STMT-RET that the actual change in control takes place.
; Unlike some BASICs the line number need not exist.
; Note. the high byte of the line number is incorrectly compared with $F0
; instead of $3F. This leads to commands with operands greater than 32767
; being considered as having been run from the editing area and the
; error report 'Statement Lost' is given instead of 'OK'.
; - Steven Vickers, 1984.

;; GO-TO

GO_TO:
        call FIND_INT2          ; routine FIND-INT2 puts operand in BC
        ld hl, bc               ; transfer line
                                ; number to HL.
        ld d, $00               ; set statement to 0 - first.
        ld a, h                 ; compare high byte only
        cp $F0                  ; to $F0 i.e. 61439 in full.
        jr nc, REPORT_Bb        ; forward to REPORT-B if above.

; This call entry point is used to update the system variables e.g. by RETURN.

;; GO-TO-2

GO_TO_2:
        ld (NEWPPC), hl         ; save line number in NEWPPC
        ld (iy+NSPPC-IY0), d    ; and statement in NSPPC
        ret                     ; to STMT-RET (or GO-SUB command)


; ------------------
; Handle OUT command
; ------------------
; Syntax has been checked and the two comma-separated values are on the
; calculator stack.

;; OUT

OUT_BAS:
        call TWO_PARAM          ; routine TWO-PARAM fetches values
                                ; to BC and A.
        out (c), a              ; perform the operation.
        ret                     ; return to STMT-RET.


; -------------------
; Handle POKE command
; -------------------
; This routine alters a single byte in the 64K address space.
; Happily no check is made as to whether ROM or RAM is addressed.
; Sinclair BASIC requires no poking of system variables.

;; POKE

POKE:
        call TWO_PARAM          ; routine TWO-PARAM fetches values
                                ; to BC and A.
        ld (bc), a              ; load memory location with A.
        ret                     ; return to STMT-RET.


; ------------------------------------
; Fetch two  parameters from calculator stack
; ------------------------------------
; This routine fetches a byte and word from the calculator stack
; producing an error if either is out of range.

;; TWO-PARAM

TWO_PARAM:
        call FP_TO_A            ; routine FP-TO-A
        jr c, REPORT_Bb         ; forward to REPORT-B if overflow occurred

        jr z, TWO_P_1           ; forward to TWO-P-1 if positive

        neg                     ; negative numbers are made positive

;; TWO-P-1

TWO_P_1:
        push af                 ; save the value
        call FIND_INT2          ; routine FIND-INT2 gets integer to BC
        pop af                  ; restore the value
        ret                     ; return


; -------------
; Find integers
; -------------
; The first of these routines fetches a 8-bit integer (range 0-255) from the
; calculator stack to the accumulator and is used for colours, streams,
; durations and coordinates.
; The second routine fetches 16-bit integers to the BC register pair 
; and is used to fetch command and function arguments involving line numbers
; or memory addresses and also array subscripts and tab arguments.
; ->

;; FIND-INT1

FIND_INT1:
        call FP_TO_A            ; routine FP-TO-A
        jr FIND_I_1             ; forward to FIND-I-1 for common exit routine.


; ---

; ->

;; FIND-INT2

FIND_INT2:
        call FP_TO_BC           ; routine FP-TO-BC

;; FIND-I-1

FIND_I_1:
        jr c, REPORT_Bb         ; to REPORT-Bb with overflow.

        ret z                   ; return if positive.


;; REPORT-Bb

REPORT_Bb:
        rst $08                 ; ERROR-1
        defb $0A                ; Error Report: Integer out of range

; ------------------
; Handle RUN command
; ------------------
; This command runs a program starting at an optional line.
; It performs a 'RESTORE 0' then CLEAR

;; RUN

RUN:
        call GO_TO              ; routine GO-TO puts line number in
                                ; system variables.
        ld bc, $0000            ; prepare to set DATADD to first line.
        call REST_RUN           ; routine REST-RUN does the 'restore'.
                                ; Note BC still holds zero.
        jr CLEAR_RUN            ; forward to CLEAR-RUN to clear variables
                                ; without disturbing RAMTOP and
                                ; exit indirectly to STMT-RET


; --------------------
; Handle CLEAR command
; --------------------
; This command reclaims the space used by the variables.
; It also clears the screen and the GO SUB stack.
; With an integer expression, it sets the uppermost memory
; address within the BASIC system.
; "Contrary to the manual, CLEAR doesn't execute a RESTORE" -
; Steven Vickers, Pitman Pocket Guide to the Spectrum, 1984.

;; CLEAR

CLEAR:
        call FIND_INT2          ; routine FIND-INT2 fetches to BC.

;; CLEAR-RUN

CLEAR_RUN:
        ld a, b                 ; test for
        or c                    ; zero.
        jr nz, CLEAR_1          ; skip to CLEAR-1 if not zero.

        ld bc, (RAMTOP)         ; use the existing value of RAMTOP if zero.

;; CLEAR-1

CLEAR_1:
        push bc                 ; save ramtop value.

        ld de, (VARS)           ; fetch VARS
        ld hl, (E_LINE)         ; fetch E_LINE
        dec hl                  ; adjust to point at variables end-marker.
        call RECLAIM_1          ; routine RECLAIM-1 reclaims the space used by
                                ; the variables.

        call CLS                ; routine CLS to clear screen.

        ld hl, (STKEND)         ; fetch STKEND the start of free memory.
        ld de, $0032            ; allow for another 50 bytes.
        add hl, de              ; add the overhead to HL.

        pop de                  ; restore the ramtop value.
        sbc hl, de              ; if HL is greater than the value then jump
        jr nc, REPORT_M         ; forward to REPORT-M
                                ; 'RAMTOP no good'

        ld hl, (P_RAMT)         ; now P-RAMT ($7FFF on 16K RAM machine)
        and a                   ; exact this time.
        sbc hl, de              ; new ramtop must be lower or the same.
        jr nc, CLEAR_2          ; skip to CLEAR-2 if in actual RAM.

;; REPORT-M

REPORT_M:
        rst $08                 ; ERROR-1
        defb $15                ; Error Report: RAMTOP no good

;; CLEAR-2

CLEAR_2:
        ex de, hl               ; transfer ramtop value to HL.
        ld (RAMTOP), hl         ; update system variable RAMTOP.
        pop de                  ; pop the return address STMT-RET.
        pop bc                  ; pop the Error Address.
        ldd (hl), $3E           ; now put the GO SUB end-marker at RAMTOP.
                                ; leave a location beneath it.
        ld sp, hl               ; initialize the machine stack pointer.
        push bc                 ; push the error address.
        ld (ERR_SP), sp         ; make ERR_SP point to location.
        ex de, hl               ; put STMT-RET in HL.
        jp (hl)                 ; and go there directly.


; ---------------------
; Handle GO SUB command
; ---------------------
; The GO SUB command diverts BASIC control to a new line number
; in a very similar manner to GO TO but
; the current line number and current statement + 1
; are placed on the GO SUB stack as a RETURN point.

;; GO-SUB

GO_SUB:
        pop de                  ; drop the address STMT-RET
        ld h, (iy+SUBPPC-IY0)   ; fetch statement from SUBPPC and
        inc h                   ; increment it
        ex (sp), hl             ; swap - error address to HL,
                                ; H (statement) at top of stack,
                                ; L (unimportant) beneath.
        inc sp                  ; adjust to overwrite unimportant byte
        ld bc, (PPC)            ; fetch the current line number from PPC
        push bc                 ; and PUSH onto GO SUB stack.
                                ; the empty machine-stack can be rebuilt
        push hl                 ; push the error address.
        ld (ERR_SP), sp         ; make system variable ERR_SP point to it.
        push de                 ; push the address STMT-RET.
        call GO_TO              ; call routine GO-TO to update the system
                                ; variables NEWPPC and NSPPC.
                                ; then make an indirect exit to STMT-RET via
        ld bc, $0014            ; a 20-byte overhead memory check.

; ----------------------
; Check available memory
; ----------------------
; This routine is used on many occasions when extending a dynamic area
; upwards or the GO SUB stack downwards.

;; TEST-ROOM

TEST_ROOM:
        ld hl, (STKEND)         ; fetch STKEND
        add hl, bc              ; add the supplied test value
        jr c, REPORT_4          ; forward to REPORT-4 if over $FFFF

        ex de, hl               ; was less so transfer to DE
        ld hl, $0050            ; test against another 80 bytes
        add hl, de              ; anyway
        jr c, REPORT_4          ; forward to REPORT-4 if this passes $FFFF

        sbc hl, sp              ; if less than the machine stack pointer
        ret c                   ; then return - OK.

;; REPORT-4

REPORT_4:
        ld l, $03               ; prepare 'Out of Memory'
        jp ERROR_3              ; jump back to ERROR-3 at $0055
                                ; Note. this error can't be trapped at $0008


; ------------------------------
; THE 'FREE MEMORY' USER ROUTINE
; ------------------------------
; This routine is not used by the ROM but allows users to evaluate
; approximate free memory with PRINT 65536 - USR 7962.

;; free-mem

free_mem:
        ld bc, $0000            ; allow no overhead.

        call TEST_ROOM          ; routine TEST-ROOM.

        ld bc, hl               ; transfer the result
                                ; to the BC register.
        ret                     ; the USR function returns value of BC.


; --------------------
; THE 'RETURN' COMMAND
; --------------------
; As with any command, there are two values on the machine stack at the time 
; it is invoked.  The machine stack is below the GOSUB stack.  Both grow 
; downwards, the machine stack by two bytes, the GOSUB stack by 3 bytes. 
; The highest location is a statement byte followed by a two-byte line number.

;; RETURN

RETURN:
        pop bc                  ; drop the address STMT-RET.
        pop hl                  ; now the error address.
        pop de                  ; now a possible BASIC return line.
        ld a, d                 ; the high byte $00 - $27 is
        cp $3E                  ; compared with the traditional end-marker $3E.
        jr z, REPORT_7          ; forward to REPORT-7 with a match.
                                ; 'RETURN without GOSUB'

; It was not the end-marker so a single statement byte remains at the base of 
; the calculator stack. It can't be popped off.

        dec sp                  ; adjust stack pointer to create room for two
                                ; bytes.
        ex (sp), hl             ; statement to H, error address to base of
                                ; new machine stack.
        ex de, hl               ; statement to D,  BASIC line number to HL.
        ld (ERR_SP), sp         ; adjust ERR_SP to point to new stack pointer
        push bc                 ; now re-stack the address STMT-RET
        jp GO_TO_2              ; to GO-TO-2 to update statement and line
                                ; system variables and exit indirectly to the
                                ; address just pushed on stack.


; ---

;; REPORT-7

REPORT_7:
        push de                 ; replace the end-marker.
        push hl                 ; now restore the error address
                                ; as will be required in a few clock cycles.

        rst $08                 ; ERROR-1
        defb $06                ; Error Report: RETURN without GOSUB

; --------------------
; Handle PAUSE command
; --------------------
; The pause command takes as its parameter the number of interrupts
; for which to wait. PAUSE 50 pauses for about a second.
; PAUSE 0 pauses indefinitely.
; Both forms can be finished by pressing a key.

;; PAUSE

PAUSE:
        call FIND_INT2          ; routine FIND-INT2 puts value in BC

;; PAUSE-1

PAUSE_1:
        halt                    ; wait for interrupt.
        dec bc                  ; decrease counter.
        ld a, b                 ; test if
        or c                    ; result is zero.
        jr z, PAUSE_END         ; forward to PAUSE-END if so.

        ld a, b                 ; test if
        and c                   ; now $FFFF
        inc a                   ; that is, initially zero.
        jr nz, PAUSE_2          ; skip forward to PAUSE-2 if not.

        inc bc                  ; restore counter to zero.

;; PAUSE-2

PAUSE_2:
        bit 5, (iy+FLAGS-IY0)   ; test FLAGS - has a new key been pressed ?
        jr z, PAUSE_1           ; back to PAUSE-1 if not.

;; PAUSE-END

PAUSE_END:
        res 5, (iy+FLAGS-IY0)   ; update FLAGS - signal no new key
        ret                     ; and return.


; -------------------
; Check for BREAK key
; -------------------
; This routine is called from COPY-LINE, when interrupts are disabled,
; to test if BREAK (SHIFT - SPACE) is being pressed.
; It is also called at STMT-RET after every statement.

;; BREAK-KEY

BREAK_KEY:
        ld a, $7F               ; Input address: $7FFE
        in a, ($FE)             ; read lower right keys
        rra                     ; rotate bit 0 - SPACE
        ret c                   ; return if not reset

        ld a, $FE               ; Input address: $FEFE
        in a, ($FE)             ; read lower left keys
        rra                     ; rotate bit 0 - SHIFT
        ret                     ; carry will be set if not pressed.
                                ; return with no carry if both keys
                                ; pressed.


; ---------------------
; Handle DEF FN command
; ---------------------
; e.g. DEF FN r$(a$,a) = a$(a TO )
; this 'command' is ignored in runtime but has its syntax checked
; during line-entry.

;; DEF-FN

DEF_FN:
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, DEF_FN_1          ; forward to DEF-FN-1 if parsing

        ld a, $CE               ; else load A with 'DEF FN' and
        jp PASS_BY              ; jump back to PASS-BY


; ---

; continue here if checking syntax.

;; DEF-FN-1

DEF_FN_1:
        set 6, (iy+FLAGS-IY0)   ; set FLAGS  - Assume numeric result
        call ALPHA              ; call routine ALPHA
        jr nc, DEF_FN_4         ; if not then to DEF-FN-4 to jump to
                                ; 'Nonsense in BASIC'


        rst $20                 ; NEXT-CHAR
        cp $24                  ; is it '$' ?
        jr nz, DEF_FN_2         ; to DEF-FN-2 if not as numeric.

        res 6, (iy+FLAGS-IY0)   ; set FLAGS  - Signal string result

        rst $20                 ; get NEXT-CHAR

;; DEF-FN-2

DEF_FN_2:
        cp $28                  ; is it '(' ?
        jr nz, DEF_FN_7         ; to DEF-FN-7 'Nonsense in BASIC'


        rst $20                 ; NEXT-CHAR
        cp $29                  ; is it ')' ?
        jr z, DEF_FN_6          ; to DEF-FN-6 if null argument

;; DEF-FN-3

DEF_FN_3:
        call ALPHA              ; routine ALPHA checks that it is the expected
                                ; alphabetic character.

;; DEF-FN-4

DEF_FN_4:
        jp nc, REPORT_C         ; to REPORT-C  if not
                                ; 'Nonsense in BASIC'.

        ex de, hl               ; save pointer in DE

        rst $20                 ; NEXT-CHAR re-initializes HL from CH_ADD
                                ; and advances.
        cp $24                  ; '$' ? is it a string argument.
        jr nz, DEF_FN_5         ; forward to DEF-FN-5 if not.

        ex de, hl               ; save pointer to '$' in DE

        rst $20                 ; NEXT-CHAR re-initializes HL and advances

;; DEF-FN-5

DEF_FN_5:
        ex de, hl               ; bring back pointer.
        ld bc, $0006            ; the function requires six hidden bytes for
                                ; each parameter passed.
                                ; The first byte will be $0E
                                ; then 5-byte numeric value
                                ; or 5-byte string pointer.

        call MAKE_ROOM          ; routine MAKE-ROOM creates space in program
                                ; area.

        inc hl                  ; adjust HL (set by LDDR)
        inc hl                  ; to point to first location.
        ld (hl), $0E            ; insert the 'hidden' marker.

; Note. these invisible storage locations hold nothing meaningful for the
; moment. They will be used every time the corresponding function is
; evaluated in runtime.
; Now consider the following character fetched earlier.

        cp $2C                  ; is it ',' ? (more than one parameter)
        jr nz, DEF_FN_6         ; to DEF-FN-6 if not


        rst $20                 ; else NEXT-CHAR
        jr DEF_FN_3             ; and back to DEF-FN-3


; ---

;; DEF-FN-6

DEF_FN_6:
        cp $29                  ; should close with a ')'
        jr nz, DEF_FN_7         ; to DEF-FN-7 if not
                                ; 'Nonsense in BASIC'


        rst $20                 ; get NEXT-CHAR
        cp $3D                  ; is it '=' ?
        jr nz, DEF_FN_7         ; to DEF-FN-7 if not 'Nonsense...'


        rst $20                 ; address NEXT-CHAR
        ld a, (FLAGS)           ; get FLAGS which has been set above
        push af                 ; and preserve

        call SCANNING           ; routine SCANNING checks syntax of expression
                                ; and also sets flags.

        pop af                  ; restore previous flags
        xor (iy+FLAGS-IY0)      ; xor with FLAGS - bit 6 should be same
                                ; therefore will be reset.
        and $40                 ; isolate bit 6.

;; DEF-FN-7

DEF_FN_7:
        jp nz, REPORT_C         ; jump back to REPORT-C if the expected result
                                ; is not the same type.
                                ; 'Nonsense in BASIC'

        call CHECK_END          ; routine CHECK-END will return early if
                                ; at end of statement and move onto next
                                ; else produce error report. >>>

                                ; There will be no return to here.

; -------------------------------
; Returning early from subroutine
; -------------------------------
; All routines are capable of being run in two modes - syntax checking mode
; and runtime mode.  This routine is called often to allow a routine to return 
; early if checking syntax.

;; UNSTACK-Z

UNSTACK_Z:
        call SYNTAX_Z           ; routine SYNTAX-Z sets zero flag if syntax
                                ; is being checked.

        pop hl                  ; drop the return address.
        ret z                   ; return to previous call in chain if checking
                                ; syntax.

        jp (hl)                 ; jump to return address as BASIC program is
                                ; actually running.


; ---------------------
; Handle LPRINT command
; ---------------------
; A simple form of 'PRINT #3' although it can output to 16 streams.
; Probably for compatibility with other BASICs particularly ZX81 BASIC.
; An extra UDG might have been better.

;; LPRINT

LPRINT:
        ld a, $03               ; the printer channel
        jr PRINT_1              ; forward to PRINT-1


; ---------------------
; Handle PRINT commands
; ---------------------
; The Spectrum's main stream output command.
; The default stream is stream 2 which is normally the upper screen
; of the computer. However the stream can be altered in range 0 - 15.

;; PRINT

PRINT:
        ld a, $02               ; the stream for the upper screen.

; The LPRINT command joins here.

;; PRINT-1

PRINT_1:
        call SYNTAX_Z           ; routine SYNTAX-Z checks if program running
        call nz, CHAN_OPEN      ; routine CHAN-OPEN if so
        call TEMPS              ; routine TEMPS sets temporary colours.
        call PRINT_2            ; routine PRINT-2 - the actual item
        call CHECK_END          ; routine CHECK-END gives error if not at end
                                ; of statement
        ret                     ; and return >>>


; ------------------------------------
; this subroutine is called from above
; and also from INPUT.

;; PRINT-2

PRINT_2:
        rst $18                 ; GET-CHAR gets printable character
        call PR_END_Z           ; routine PR-END-Z checks if more printing
        jr z, PRINT_4           ; to PRINT-4 if not     e.g. just 'PRINT :'

; This tight loop deals with combinations of positional controls and
; print items. An early return can be made from within the loop
; if the end of a print sequence is reached.

;; PRINT-3

PRINT_3:
        call PR_POSN_1          ; routine PR-POSN-1 returns zero if more
                                ; but returns early at this point if
                                ; at end of statement!
        jr z, PRINT_3           ; to PRINT-3 if consecutive positioners

        call PR_ITEM_1          ; routine PR-ITEM-1 deals with strings etc.
        call PR_POSN_1          ; routine PR-POSN-1 for more position codes
        jr z, PRINT_3           ; loop back to PRINT-3 if so

;; PRINT-4

PRINT_4:
        cp $29                  ; return now if this is ')' from input-item.
                                ; (see INPUT.)
        ret z                   ; or continue and print carriage return in
                                ; runtime

; ---------------------
; Print carriage return
; ---------------------
; This routine which continues from above prints a carriage return
; in run-time. It is also called once from PRINT-POSN.

;; PRINT-CR

PRINT_CR:
        call UNSTACK_Z          ; routine UNSTACK-Z

        ld a, $0D               ; prepare a carriage return

        rst $10                 ; PRINT-A
        ret                     ; return



; -----------
; Print items
; -----------
; This routine deals with print items as in
; PRINT AT 10,0;"The value of A is ";a
; It returns once a single item has been dealt with as it is part
; of a tight loop that considers sequences of positional and print items

;; PR-ITEM-1

PR_ITEM_1:
        rst $18                 ; GET-CHAR
        cp $AC                  ; is character 'AT' ?
        jr nz, PR_ITEM_2        ; forward to PR-ITEM-2 if not.

        call NEXT_2NUM          ; routine NEXT-2NUM  check for two comma
                                ; separated numbers placing them on the
                                ; calculator stack in runtime.
        call UNSTACK_Z          ; routine UNSTACK-Z quits if checking syntax.

        call STK_TO_BC          ; routine STK-TO-BC get the numbers in B and C.
        ld a, $16               ; prepare the 'at' control.
        jr PR_AT_TAB            ; forward to PR-AT-TAB to print the sequence.


; ---

;; PR-ITEM-2

PR_ITEM_2:
        cp $AD                  ; is character 'TAB' ?
        jr nz, PR_ITEM_3        ; to PR-ITEM-3 if not


        rst $20                 ; NEXT-CHAR to address next character
        call EXPT_1NUM          ; routine EXPT-1NUM
        call UNSTACK_Z          ; routine UNSTACK-Z quits if checking syntax.

        call FIND_INT2          ; routine FIND-INT2 puts integer in BC.
        ld a, $17               ; prepare the 'tab' control.

;; PR-AT-TAB

PR_AT_TAB:
        rst $10                 ; PRINT-A outputs the control

        ld a, c                 ; first value to A
        rst $10                 ; PRINT-A outputs it.

        ld a, b                 ; second value
        rst $10                 ; PRINT-A

        ret                     ; return - item finished >>>


; ---

; Now consider paper 2; #2; a$

;; PR-ITEM-3

PR_ITEM_3:
        call CO_TEMP_3          ; routine CO-TEMP-3 will print any colour
        ret nc                  ; items - return if success.

        call STR_ALTER          ; routine STR-ALTER considers new stream
        ret nc                  ; return if altered.

        call SCANNING           ; routine SCANNING now to evaluate expression
        call UNSTACK_Z          ; routine UNSTACK-Z if not runtime.

        bit 6, (iy+FLAGS-IY0)   ; test FLAGS  - Numeric or string result ?
        call z, STK_FETCH       ; routine STK-FETCH if string.
                                ; note no flags affected.
        jp nz, PRINT_FP         ; to PRINT-FP to print if numeric >>>

; It was a string expression - start in DE, length in BC
; Now enter a loop to print it

;; PR-STRING

PR_STRING:
        ld a, b                 ; this tests if the
        or c                    ; length is zero and sets flag accordingly.
        dec bc                  ; this doesn't but decrements counter.
        ret z                   ; return if zero.

        ldi a, (de)             ; fetch character.
                                ; address next location.

        rst $10                 ; PRINT-A.

        jr PR_STRING            ; loop back to PR-STRING.


; ---------------
; End of printing
; ---------------
; This subroutine returns zero if no further printing is required
; in the current statement.
; The first terminator is found in  escaped input items only,
; the others in print_items.

;; PR-END-Z

PR_END_Z:
        cp $29                  ; is character a ')' ?
        ret z                   ; return if so -        e.g. INPUT (p$); a$

;; PR-ST-END

PR_ST_END:
        cp $0D                  ; is it a carriage return ?
        ret z                   ; return also -         e.g. PRINT a

        cp $3A                  ; is character a ':' ?
        ret                     ; return - zero flag will be set if so.
                                ;                       e.g. PRINT a :


; --------------
; Print position
; --------------
; This routine considers a single positional character ';', ',', '''

;; PR-POSN-1

PR_POSN_1:
        rst $18                 ; GET-CHAR
        cp $3B                  ; is it ';' ?
                                ; i.e. print from last position.
        jr z, PR_POSN_3         ; forward to PR-POSN-3 if so.
                                ; i.e. do nothing.

        cp $2C                  ; is it ',' ?
                                ; i.e. print at next tabstop.
        jr nz, PR_POSN_2        ; forward to PR-POSN-2 if anything else.

        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, PR_POSN_3         ; forward to PR-POSN-3 if checking syntax.

        ld a, $06               ; prepare the 'comma' control character.

        rst $10                 ; PRINT-A  outputs to current channel in
                                ; run-time.

        jr PR_POSN_3            ; skip to PR-POSN-3.


; ---

; check for newline.

;; PR-POSN-2

PR_POSN_2:
        cp $27                  ; is character a "'" ? (newline)
        ret nz                  ; return if no match              >>>

        call PRINT_CR           ; routine PRINT-CR outputs a carriage return
                                ; in runtime only.

;; PR-POSN-3

PR_POSN_3:
        rst $20                 ; NEXT-CHAR to A.
        call PR_END_Z           ; routine PR-END-Z checks if at end.
        jr nz, PR_POSN_4        ; to PR-POSN-4 if not.

        pop bc                  ; drop return address if at end.

;; PR-POSN-4

PR_POSN_4:
        cp a                    ; reset the zero flag.
        ret                     ; and return to loop or quit.


; ------------
; Alter stream
; ------------
; This routine is called from PRINT ITEMS above, and also LIST as in
; LIST #15

;; STR-ALTER

STR_ALTER:
        cp $23                  ; is character '#' ?
        scf                     ; set carry flag.
        ret nz                  ; return if no match.


        rst $20                 ; NEXT-CHAR
        call EXPT_1NUM          ; routine EXPT-1NUM gets stream number
        and a                   ; prepare to exit early with carry reset
        call UNSTACK_Z          ; routine UNSTACK-Z exits early if parsing
        call FIND_INT1          ; routine FIND-INT1 gets number off stack
        cp $10                  ; must be range 0 - 15 decimal.
        jp nc, REPORT_Oa        ; jump back to REPORT-Oa if not
                                ; 'Invalid stream'.

        call CHAN_OPEN          ; routine CHAN-OPEN
        and a                   ; clear carry - signal item dealt with.
        ret                     ; return


; -------------------
; THE 'INPUT' COMMAND 
; -------------------
; This command is mysterious.
;

;; INPUT

INPUT:
        call SYNTAX_Z           ; routine SYNTAX-Z to check if in runtime.

        jr z, INPUT_1           ; forward to INPUT-1 if checking syntax.

        ld a, $01               ; select channel 'K' the keyboard for input.
        call CHAN_OPEN          ; routine CHAN-OPEN opens the channel and sets
                                ; bit 0 of TV_FLAG.

;   Note. As a consequence of clearing the lower screen channel 0 is made 
;   the current channel so the above two instructions are superfluous.

        call CLS_LOWER          ; routine CLS-LOWER clears the lower screen
                                ; and sets DF_SZ to two and TV_FLAG to $01.

;; INPUT-1

INPUT_1:
        ld (iy+TV_FLAG-IY0), $01
                                ; update TV_FLAG - signal lower screen in use
                                ; ensuring that the correct set of system
                                ; variables are updated and that the border
                                ; colour is used.

;   Note. The Complete Spectrum ROM Disassembly incorrectly names DF-SZ as the
;   system variable that is updated above and if, as some have done, you make 
;   this unnecessary alteration then there will be two blank lines between the
;   lower screen and the upper screen areas which will also scroll wrongly.

        call IN_ITEM_1          ; routine IN-ITEM-1 to handle the input.

        call CHECK_END          ; routine CHECK-END will make an early exit
                                ; if checking syntax. >>>

;   Keyboard input has been made and it remains to adjust the upper
;   screen in case the lower two lines have been extended upwards.

        ld bc, (S_POSN)         ; fetch S_POSN current line/column of
                                ; the upper screen.
        ld a, (DF_SZ)           ; fetch DF_SZ the display file size of
                                ; the lower screen.
        cp b                    ; test that lower screen does not overlap
        jr c, INPUT_2           ; forward to INPUT-2 if not.

; the two screens overlap so adjust upper screen.

        ld c, $21               ; set column of upper screen to leftmost.
        ld b, a                 ; and line to one above lower screen.
                                ; continue forward to update upper screen
                                ; print position.

;; INPUT-2

INPUT_2:
        ld (S_POSN), bc         ; set S_POSN update upper screen line/column.
        ld a, $19               ; subtract from twenty five
        sub b                   ; the new line number.
        ld (SCR_CT), a          ; and place result in SCR_CT - scroll count.
        res 0, (iy+TV_FLAG-IY0) ; update TV_FLAG - signal main screen in use.

        call CL_SET             ; routine CL-SET sets the print position
                                ; system variables for the upper screen.

        jp CLS_LOWER            ; jump back to CLS-LOWER and make
                                ; an indirect exit >>.


; ---------------------
; INPUT ITEM subroutine
; ---------------------
;   This subroutine deals with the input items and print items.
;   from  the current input channel.
;   It is only called from the above INPUT routine but was obviously
;   once called from somewhere else in another context.

;; IN-ITEM-1

IN_ITEM_1:
        call PR_POSN_1          ; routine PR-POSN-1 deals with a single
                                ; position item at each call.
        jr z, IN_ITEM_1         ; back to IN-ITEM-1 until no more in a
                                ; sequence.

        cp $28                  ; is character '(' ?
        jr nz, IN_ITEM_2        ; forward to IN-ITEM-2 if not.

;   any variables within braces will be treated as part, or all, of the prompt
;   instead of being used as destination variables.

        rst $20                 ; NEXT-CHAR
        call PRINT_2            ; routine PRINT-2 to output the dynamic
                                ; prompt.

        rst $18                 ; GET-CHAR
        cp $29                  ; is character a matching ')' ?
        jp nz, REPORT_C         ; jump back to REPORT-C if not.
                                ; 'Nonsense in BASIC'.

        rst $20                 ; NEXT-CHAR
        jp IN_NEXT_2            ; forward to IN-NEXT-2


; ---

;; IN-ITEM-2

IN_ITEM_2:
        cp $CA                  ; is the character the token 'LINE' ?
        jr nz, IN_ITEM_3        ; forward to IN-ITEM-3 if not.

        rst $20                 ; NEXT-CHAR - variable must come next.
        call CLASS_01           ; routine CLASS-01 returns destination
                                ; address of variable to be assigned.
                                ; or generates an error if no variable
                                ; at this position.

        set 7, (iy+FLAGX-IY0)   ; update FLAGX  - signal handling INPUT LINE
        bit 6, (iy+FLAGS-IY0)   ; test FLAGS  - numeric or string result ?
        jp nz, REPORT_C         ; jump back to REPORT-C if not string
                                ; 'Nonsense in BASIC'.

        jr IN_PROMPT            ; forward to IN-PROMPT to set up workspace.


; ---

;   the jump was here for other variables.

;; IN-ITEM-3

IN_ITEM_3:
        call ALPHA              ; routine ALPHA checks if character is
                                ; a suitable variable name.
        jp nc, IN_NEXT_1        ; forward to IN-NEXT-1 if not

        call CLASS_01           ; routine CLASS-01 returns destination
                                ; address of variable to be assigned.
        res 7, (iy+FLAGX-IY0)   ; update FLAGX  - signal not INPUT LINE.

;; IN-PROMPT

IN_PROMPT:
        call SYNTAX_Z           ; routine SYNTAX-Z
        jp z, IN_NEXT_2         ; forward to IN-NEXT-2 if checking syntax.

        call SET_WORK           ; routine SET-WORK clears workspace.
        ld hl, FLAGX            ; point to system variable FLAGX
        res 6, (hl)             ; signal string result.
        set 5, (hl)             ; signal in Input Mode for editor.
        ld bc, $0001            ; initialize space required to one for
                                ; the carriage return.
        bit 7, (hl)             ; test FLAGX - INPUT LINE in use ?
        jr nz, IN_PR_2          ; forward to IN-PR-2 if so as that is
                                ; all the space that is required.

        ld a, (FLAGS)           ; load accumulator from FLAGS
        and $40                 ; mask to test BIT 6 of FLAGS and clear
                                ; the other bits in A.
                                ; numeric result expected ?
        jr nz, IN_PR_1          ; forward to IN-PR-1 if so

        ld c, $03               ; increase space to three bytes for the
                                ; pair of surrounding quotes.

;; IN-PR-1

IN_PR_1:
        or (hl)                 ; if numeric result, set bit 6 of FLAGX.
        ld (hl), a              ; and update system variable

;; IN-PR-2

IN_PR_2:
        rst $30                 ; BC-SPACES opens 1 or 3 bytes in workspace
        ld (hl), $0D            ; insert carriage return at last new location.
        ld a, c                 ; fetch the length, one or three.
        rrca                    ; lose bit 0.
        rrca                    ; test if quotes required.
        jr nc, IN_PR_3          ; forward to IN-PR-3 if not.

        ld a, $22               ; load the '"' character
        ld (de), a              ; place quote in first new location at DE.
        dec hl                  ; decrease HL - from carriage return.
        ld (hl), a              ; and place a quote in second location.

;; IN-PR-3

IN_PR_3:
        ld (K_CUR), hl          ; set keyboard cursor K_CUR to HL
        bit 7, (iy+FLAGX-IY0)   ; test FLAGX  - is this INPUT LINE ??
        jr nz, IN_VAR_3         ; forward to IN-VAR-3 if so as input will
                                ; be accepted without checking its syntax.

        ld hl, (CH_ADD)         ; fetch CH_ADD
        push hl                 ; and save on stack.
        ld hl, (ERR_SP)         ; fetch ERR_SP
        push hl                 ; and save on stack

;; IN-VAR-1

IN_VAR_1:
        ld hl, IN_VAR_1         ; address: IN-VAR-1 - this address
        push hl                 ; is saved on stack to handle errors.
        bit 4, (iy+FLAGS2-IY0)  ; test FLAGS2  - is K channel in use ?
        jr z, IN_VAR_2          ; forward to IN-VAR-2 if not using the
                                ; keyboard for input. (??)

        ld (ERR_SP), sp         ; set ERR_SP to point to IN-VAR-1 on stack.

;; IN-VAR-2

IN_VAR_2:
        ld hl, (WORKSP)         ; set HL to WORKSP - start of workspace.
        call REMOVE_FP          ; routine REMOVE-FP removes floating point
                                ; forms when looping in error condition.
        ld (iy+ERR_NR-IY0), $FF ; set ERR_NR to 'OK' cancelling the error.
                                ; but X_PTR causes flashing error marker
                                ; to be displayed at each call to the editor.
        call EDITOR             ; routine EDITOR allows input to be entered
                                ; or corrected if this is second time around.

; if we pass to next then there are no system errors

        res 7, (iy+FLAGS-IY0)   ; update FLAGS  - signal checking syntax
        call IN_ASSIGN          ; routine IN-ASSIGN checks syntax using
                                ; the VAL-FET-2 and powerful SCANNING routines.
                                ; any syntax error and its back to IN-VAR-1.
                                ; but with the flashing error marker showing
                                ; where the error is.
                                ; Note. the syntax of string input has to be
                                ; checked as the user may have removed the
                                ; bounding quotes or escaped them as with
                                ; "hat" + "stand" for example.
                                ; proceed if syntax passed.

        jr IN_VAR_4             ; jump forward to IN-VAR-4


; ---

; the jump was to here when using INPUT LINE.

;; IN-VAR-3

IN_VAR_3:
        call EDITOR             ; routine EDITOR is called for input

; when ENTER received rejoin other route but with no syntax check.

; INPUT and INPUT LINE converge here.

;; IN-VAR-4

IN_VAR_4:
        ld (iy+$22), $00        ; set K_CUR_hi to a low value so that the cursor
                                ; no longer appears in the input line.

        call IN_CHAN_K          ; routine IN-CHAN-K tests if the keyboard
                                ; is being used for input.
        jr nz, IN_VAR_5         ; forward to IN-VAR-5 if using another input
                                ; channel.

; continue here if using the keyboard.

        call ED_COPY            ; routine ED-COPY overprints the edit line
                                ; to the lower screen. The only visible
                                ; affect is that the cursor disappears.
                                ; if you're inputting more than one item in
                                ; a statement then that becomes apparent.

        ld bc, (ECHO_E)         ; fetch line and column from ECHO_E
        call CL_SET             ; routine CL-SET sets S-POSNL to those
                                ; values.

; if using another input channel rejoin here.

;; IN-VAR-5

IN_VAR_5:
        ld hl, FLAGX            ; point HL to FLAGX
        res 5, (hl)             ; signal not in input mode
        bit 7, (hl)             ; is this INPUT LINE ?
        res 7, (hl)             ; cancel the bit anyway.
        jr nz, IN_VAR_6         ; forward to IN-VAR-6 if INPUT LINE.

        pop hl                  ; drop the looping address
        pop hl                  ; drop the address of previous
                                ; error handler.
        ld (ERR_SP), hl         ; set ERR_SP to point to it.
        pop hl                  ; drop original CH_ADD which points to
                                ; INPUT command in BASIC line.
        ld (X_PTR), hl          ; save in X_PTR while input is assigned.
        set 7, (iy+FLAGS-IY0)   ; update FLAGS - Signal running program
        call IN_ASSIGN          ; routine IN-ASSIGN is called again
                                ; this time the variable will be assigned
                                ; the input value without error.
                                ; Note. the previous example now
                                ; becomes "hatstand"

        ld hl, (X_PTR)          ; fetch stored CH_ADD value from X_PTR.
        ld (iy+$26), $00        ; set X_PTR_hi so that iy is no longer relevant.
        ld (CH_ADD), hl         ; put restored value back in CH_ADD
        jr IN_NEXT_2            ; forward to IN-NEXT-2 to see if anything
                                ; more in the INPUT list.


; ---

; the jump was to here with INPUT LINE only

;; IN-VAR-6

IN_VAR_6:
        ld hl, (STKBOT)         ; STKBOT points to the end of the input.
        ld de, (WORKSP)         ; WORKSP points to the beginning.
        scf                     ; prepare for true subtraction.
        sbc hl, de              ; subtract to get length
        ld bc, hl               ; transfer it to
                                ; the BC register pair.
        call STK_STO__          ; routine STK-STO-$ stores parameters on
                                ; the calculator stack.
        call LET                ; routine LET assigns it to destination.
        jr IN_NEXT_2            ; forward to IN-NEXT-2 as print items
                                ; not allowed with INPUT LINE.
                                ; Note. that "hat" + "stand" will, for
                                ; example, be unchanged as also would
                                ; 'PRINT "Iris was here"'.


; ---

; the jump was to here when ALPHA found more items while looking for
; a variable name.

;; IN-NEXT-1

IN_NEXT_1:
        call PR_ITEM_1          ; routine PR-ITEM-1 considers further items.

;; IN-NEXT-2

IN_NEXT_2:
        call PR_POSN_1          ; routine PR-POSN-1 handles a position item.
        jp z, IN_ITEM_1         ; jump back to IN-ITEM-1 if the zero flag
                                ; indicates more items are present.

        ret                     ; return.


; ---------------------------
; INPUT ASSIGNMENT Subroutine
; ---------------------------
; This subroutine is called twice from the INPUT command when normal
; keyboard input is assigned. On the first occasion syntax is checked
; using SCANNING. The final call with the syntax flag reset is to make
; the assignment.

;; IN-ASSIGN

IN_ASSIGN:
        ld hl, (WORKSP)         ; fetch WORKSP start of input
        ld (CH_ADD), hl         ; set CH_ADD to first character

        rst $18                 ; GET-CHAR ignoring leading white-space.
        cp $E2                  ; is it 'STOP'
        jr z, IN_STOP           ; forward to IN-STOP if so.

        ld a, (FLAGX)           ; load accumulator from FLAGX
        call VAL_FET_2          ; routine VAL-FET-2 makes assignment
                                ; or goes through the motions if checking
                                ; syntax. SCANNING is used.

        rst $18                 ; GET-CHAR
        cp $0D                  ; is it carriage return ?
        ret z                   ; return if so
                                ; either syntax is OK
                                ; or assignment has been made.

; if another character was found then raise an error.
; User doesn't see report but the flashing error marker
; appears in the lower screen.

;; REPORT-Cb

REPORT_Cb:
        rst $08                 ; ERROR-1
        defb $0B                ; Error Report: Nonsense in BASIC

;; IN-STOP

IN_STOP:
        call SYNTAX_Z           ; routine SYNTAX-Z (UNSTACK-Z?)
        ret z                   ; return if checking syntax
                                ; as user wouldn't see error report.
                                ; but generate visible error report
                                ; on second invocation.

;; REPORT-H

REPORT_H:
        rst $08                 ; ERROR-1
        defb $10                ; Error Report: STOP in INPUT

; -----------------------------------
; THE 'TEST FOR CHANNEL K' SUBROUTINE
; -----------------------------------
;   This subroutine is called once from the keyboard INPUT command to check if 
;   the input routine in use is the one for the keyboard.

;; IN-CHAN-K

IN_CHAN_K:
        ld hl, (CURCHL)         ; fetch address of current channel CURCHL
        inc hl
        inc hl                  ; advance past
        inc hl                  ; input and
        inc hl                  ; output streams
        ld a, (hl)              ; fetch the channel identifier.
        cp $4B                  ; test for 'K'
        ret                     ; return with zero set if keyboard is use.


; --------------------
; Colour Item Routines
; --------------------
;
; These routines have 3 entry points -
; 1) CO-TEMP-2 to handle a series of embedded Graphic colour items.
; 2) CO-TEMP-3 to handle a single embedded print colour item.
; 3) CO TEMP-4 to handle a colour command such as FLASH 1
;
; "Due to a bug, if you bring in a peripheral channel and later use a colour
;  statement, colour controls will be sent to it by mistake." - Steven Vickers
;  Pitman Pocket Guide, 1984.
;
; To be fair, this only applies if the last channel was other than 'K', 'S'
; or 'P', which are all that are supported by this ROM, but if that last
; channel was a microdrive file, network channel etc. then
; PAPER 6; CLS will not turn the screen yellow and
; CIRCLE INK 2; 128,88,50 will not draw a red circle.
;
; This bug does not apply to embedded PRINT items as it is quite permissible
; to mix stream altering commands and colour items.
; The fix therefore would be to ensure that CLASS-07 and CLASS-09 make
; channel 'S' the current channel when not checking syntax.
; -----------------------------------------------------------------

;; CO-TEMP-1

CO_TEMP_1:
        rst $20                 ; NEXT-CHAR

; -> Entry point from CLASS-09. Embedded Graphic colour items.
; e.g. PLOT INK 2; PAPER 8; 128,88
; Loops till all colour items output, finally addressing the coordinates.

;; CO-TEMP-2

CO_TEMP_2:
        call CO_TEMP_3          ; routine CO-TEMP-3 to output colour control.
        ret c                   ; return if nothing more to output. ->


        rst $18                 ; GET-CHAR
        cp $2C                  ; is it ',' separator ?
        jr z, CO_TEMP_1         ; back if so to CO-TEMP-1

        cp $3B                  ; is it ';' separator ?
        jr z, CO_TEMP_1         ; back to CO-TEMP-1 for more.

        jp REPORT_C             ; to REPORT-C (REPORT-Cb is within range)
                                ; 'Nonsense in BASIC'


; -------------------
; CO-TEMP-3
; -------------------
; -> this routine evaluates and outputs a colour control and parameter.
; It is called from above and also from PR-ITEM-3 to handle a single embedded
; print item e.g. PRINT PAPER 6; "Hi". In the latter case, the looping for
; multiple items is within the PR-ITEM routine.
; It is quite permissible to send these to any stream.

;; CO-TEMP-3

CO_TEMP_3:
        cp $D9                  ; is it 'INK' ?
        ret c                   ; return if less.

        cp $DF                  ; compare with 'OUT'
        ccf                     ; Complement Carry Flag
        ret c                   ; return if greater than 'OVER', $DE.

        push af                 ; save the colour token.

        rst $20                 ; address NEXT-CHAR
        pop af                  ; restore token and continue.

; -> this entry point used by CLASS-07. e.g. the command PAPER 6.

;; CO-TEMP-4

CO_TEMP_4:
        sub $C9                 ; reduce to control character $10 (INK)
                                ; thru $15 (OVER).
        push af                 ; save control.
        call EXPT_1NUM          ; routine EXPT-1NUM stacks addressed
                                ; parameter on calculator stack.
        pop af                  ; restore control.
        and a                   ; clear carry

        call UNSTACK_Z          ; routine UNSTACK-Z returns if checking syntax.

        push af                 ; save again
        call FIND_INT1          ; routine FIND-INT1 fetches parameter to A.
        ld d, a                 ; transfer now to D
        pop af                  ; restore control.

        rst $10                 ; PRINT-A outputs the control to current
                                ; channel.
        ld a, d                 ; transfer parameter to A.

        rst $10                 ; PRINT-A outputs parameter.
        ret                     ; return. ->


; -------------------------------------------------------------------------
;
;         {fl}{br}{   paper   }{  ink    }    The temporary colour attributes
;          ___ ___ ___ ___ ___ ___ ___ ___    system variable.
; ATTR_T  |   |   |   |   |   |   |   |   |
;         |   |   |   |   |   |   |   |   |
; 23695   |___|___|___|___|___|___|___|___|
;           7   6   5   4   3   2   1   0
;
;
;         {fl}{br}{   paper   }{  ink    }    The temporary mask used for
;          ___ ___ ___ ___ ___ ___ ___ ___    transparent colours. Any bit
; MASK_T  |   |   |   |   |   |   |   |   |   that is 1 shows that the
;         |   |   |   |   |   |   |   |   |   corresponding attribute is
; 23696   |___|___|___|___|___|___|___|___|   taken not from ATTR-T but from
;           7   6   5   4   3   2   1   0     what is already on the screen.
;
;
;         {paper9 }{ ink9 }{ inv1 }{ over1}   The print flags. Even bits are
;          ___ ___ ___ ___ ___ ___ ___ ___    temporary flags. The odd bits
; P_FLAG  |   |   |   |   |   |   |   |   |   are the permanent flags.
;         | p | t | p | t | p | t | p | t |
; 23697   |___|___|___|___|___|___|___|___|
;           7   6   5   4   3   2   1   0
;
; -----------------------------------------------------------------------

; ------------------------------------
;  The colour system variable handler.
; ------------------------------------
; This is an exit branch from PO-1-OPER, PO-2-OPER
; A holds control $10 (INK) to $15 (OVER)
; D holds parameter 0-9 for ink/paper 0,1 or 8 for bright/flash,
; 0 or 1 for over/inverse.

;; CO-TEMP-5

CO_TEMP_5:
        sub $11                 ; reduce range $FF-$04
        adc a, $00              ; add in carry if INK
        jr z, CO_TEMP_7         ; forward to CO-TEMP-7 with INK and PAPER.

        sub $02                 ; reduce range $FF-$02
        adc a, $00              ; add carry if FLASH
        jr z, CO_TEMP_C         ; forward to CO-TEMP-C with FLASH and BRIGHT.

        cp $01                  ; is it 'INVERSE' ?
        ld a, d                 ; fetch parameter for INVERSE/OVER
        ld b, $01               ; prepare OVER mask setting bit 0.
        jr nz, CO_TEMP_6        ; forward to CO-TEMP-6 if OVER

        rlca                    ; shift bit 0
        rlca                    ; to bit 2
        ld b, $04               ; set bit 2 of mask for inverse.

;; CO-TEMP-6

CO_TEMP_6:
        ld c, a                 ; save the A
        ld a, d                 ; re-fetch parameter
        cp $02                  ; is it less than 2
        jr nc, REPORT_K         ; to REPORT-K if not 0 or 1.
                                ; 'Invalid colour'.

        ld a, c                 ; restore A
        ld hl, P_FLAG           ; address system variable P_FLAG
        jr CO_CHANGE            ; forward to exit via routine CO-CHANGE


; ---

; the branch was here with INK/PAPER and carry set for INK.

;; CO-TEMP-7

CO_TEMP_7:
        ld a, d                 ; fetch parameter
        ld b, $07               ; set ink mask 00000111
        jr c, CO_TEMP_8         ; forward to CO-TEMP-8 with INK

        rlca                    ; shift bits 0-2
        rlca                    ; to
        rlca                    ; bits 3-5
        ld b, $38               ; set paper mask 00111000

; both paper and ink rejoin here

;; CO-TEMP-8

CO_TEMP_8:
        ld c, a                 ; value to C
        ld a, d                 ; fetch parameter
        cp $0A                  ; is it less than 10d ?
        jr c, CO_TEMP_9         ; forward to CO-TEMP-9 if so.

; ink 10 etc. is not allowed.

;; REPORT-K

REPORT_K:
        rst $08                 ; ERROR-1
        defb $13                ; Error Report: Invalid colour

;; CO-TEMP-9

CO_TEMP_9:
        ld hl, ATTR_T           ; address system variable ATTR_T initially.
        cp $08                  ; compare with 8
        jr c, CO_TEMP_B         ; forward to CO-TEMP-B with 0-7.

        ld a, (hl)              ; fetch temporary attribute as no change.
        jr z, CO_TEMP_A         ; forward to CO-TEMP-A with INK/PAPER 8

; it is either ink 9 or paper 9 (contrasting)

        or b                    ; or with mask to make white
        cpl                     ; make black and change other to dark
        and $24                 ; 00100100
        jr z, CO_TEMP_A         ; forward to CO-TEMP-A if black and
                                ; originally light.

        ld a, b                 ; else just use the mask (white)

;; CO-TEMP-A

CO_TEMP_A:
        ld c, a                 ; save A in C

;; CO-TEMP-B

CO_TEMP_B:
        ld a, c                 ; load colour to A
        call CO_CHANGE          ; routine CO-CHANGE addressing ATTR-T

        ld a, $07               ; put 7 in accumulator
        cp d                    ; compare with parameter
        sbc a, a                ; $00 if 0-7, $FF if 8
        call CO_CHANGE          ; routine CO-CHANGE addressing MASK-T
                                ; mask returned in A.

; now consider P-FLAG.

        rlca                    ; 01110000 or 00001110
        rlca                    ; 11100000 or 00011100
        and $50                 ; 01000000 or 00010000  (AND 01010000)
        ld b, a                 ; transfer to mask
        ld a, $08               ; load A with 8
        cp d                    ; compare with parameter
        sbc a, a                ; $FF if was 9,  $00 if 0-8
                                ; continue while addressing P-FLAG
                                ; setting bit 4 if ink 9
                                ; setting bit 6 if paper 9

; -----------------------
; Handle change of colour
; -----------------------
; This routine addresses a system variable ATTR_T, MASK_T or P-FLAG in HL.
; colour value in A, mask in B.

;; CO-CHANGE

CO_CHANGE:
        xor (hl)                ; impress bits specified
        and b                   ; by mask
        xor (hl)                ; on system variable.
        ldi (hl), a             ; update system variable.
                                ; address next location.
        ld a, b                 ; put current value of mask in A
        ret                     ; return.


; ---

; the branch was here with flash and bright

;; CO-TEMP-C

CO_TEMP_C:
        sbc a, a                ; set zero flag for bright.
        ld a, d                 ; fetch original parameter 0,1 or 8
        rrca                    ; rotate bit 0 to bit 7
        ld b, $80               ; mask for flash 10000000
        jr nz, CO_TEMP_D        ; forward to CO-TEMP-D if flash

        rrca                    ; rotate bit 7 to bit 6
        ld b, $40               ; mask for bright 01000000

;; CO-TEMP-D

CO_TEMP_D:
        ld c, a                 ; store value in C
        ld a, d                 ; fetch parameter
        cp $08                  ; compare with 8
        jr z, CO_TEMP_E         ; forward to CO-TEMP-E if 8

        cp $02                  ; test if 0 or 1
        jr nc, REPORT_K         ; back to REPORT-K if not
                                ; 'Invalid colour'

;; CO-TEMP-E

CO_TEMP_E:
        ld a, c                 ; value to A
        ld hl, ATTR_T           ; address ATTR_T
        call CO_CHANGE          ; routine CO-CHANGE addressing ATTR_T
        ld a, c                 ; fetch value
        rrca                    ; for flash8/bright8 complete
        rrca                    ; rotations to put set bit in
        rrca                    ; bit 7 (flash) bit 6 (bright)
        jr CO_CHANGE            ; back to CO-CHANGE addressing MASK_T
                                ; and indirect return.


; ---------------------
; Handle BORDER command
; ---------------------
; Command syntax example: BORDER 7
; This command routine sets the border to one of the eight colours.
; The colours used for the lower screen are based on this.

;; BORDER

BORDER:
        call FIND_INT1          ; routine FIND-INT1
        cp $08                  ; must be in range 0 (black) to 7 (white)
        jr nc, REPORT_K         ; back to REPORT-K if not
                                ; 'Invalid colour'.

        out ($FE), a            ; outputting to port effects an immediate
                                ; change.
        rlca                    ; shift the colour to
        rlca                    ; the paper bits setting the
        rlca                    ; ink colour black.
        bit 5, a                ; is the number light coloured ?
                                ; i.e. in the range green to white.
        jr nz, BORDER_1         ; skip to BORDER-1 if so

        xor $07                 ; make the ink white.

;; BORDER-1

BORDER_1:
        ld (BORDCR), a          ; update BORDCR with new paper/ink
        ret                     ; return.


; -----------------
; Get pixel address
; -----------------
;
;

;; PIXEL-ADD

PIXEL_ADD:
        ld a, $AF               ; load with 175 decimal.
        sub b                   ; subtract the y value.
        jp c, REPORT_Bc         ; jump forward to REPORT-Bc if greater.
                                ; 'Integer out of range'

; the high byte is derived from Y only.
; the first 3 bits are always 010
; the next 2 bits denote in which third of the screen the byte is.
; the last 3 bits denote in which of the 8 scan lines within a third
; the byte is located. There are 24 discrete values.


        ld b, a                 ; the line number from top of screen to B.
        and a                   ; clear carry (already clear)
        rra                     ;                     0xxxxxxx
        scf                     ; set carry flag
        rra                     ;                     10xxxxxx
        and a                   ; clear carry flag
        rra                     ;                     010xxxxx

        xor b
        and $F8                 ; keep the top 5 bits 11111000
        xor b                   ;                     010xxbbb
        ld h, a                 ; transfer high byte to H.

; the low byte is derived from both X and Y.

        ld a, c                 ; the x value 0-255.
        rlca
        rlca
        rlca
        xor b                   ; the y value
        and $C7                 ; apply mask             11000111
        xor b                   ; restore unmasked bits  xxyyyxxx
        rlca                    ; rotate to              xyyyxxxx
        rlca                    ; required position.     yyyxxxxx
        ld l, a                 ; low byte to L.

; finally form the pixel position in A.

        ld a, c                 ; x value to A
        and $07                 ; mod 8
        ret                     ; return


; ----------------
; Point Subroutine
; ----------------
; The point subroutine is called from s-point via the scanning functions
; table.

;; POINT-SUB

POINT_SUB:
        call STK_TO_BC          ; routine STK-TO-BC
        call PIXEL_ADD          ; routine PIXEL-ADD finds address of pixel.
        ld b, a                 ; pixel position to B, 0-7.
        inc b                   ; increment to give rotation count 1-8.
        ld a, (hl)              ; fetch byte from screen.

;; POINT-LP

POINT_LP:
        rlca                    ; rotate and loop back
        djnz POINT_LP           ; to POINT-LP until pixel at right.

        and $01                 ; test to give zero or one.
        jp STACK_A              ; jump forward to STACK-A to save result.


; -------------------
; Handle PLOT command
; -------------------
; Command Syntax example: PLOT 128,88
;

;; PLOT

PLOT:
        call STK_TO_BC          ; routine STK-TO-BC
        call PLOT_SUB           ; routine PLOT-SUB
        jp TEMPS                ; to TEMPS


; -------------------
; The Plot subroutine
; -------------------
; A screen byte holds 8 pixels so it is necessary to rotate a mask
; into the correct position to leave the other 7 pixels unaffected.
; However all 64 pixels in the character cell take any embedded colour
; items.
; A pixel can be reset (inverse 1), toggled (over 1), or set ( with inverse
; and over switches off). With both switches on, the byte is simply put
; back on the screen though the colours may change.

;; PLOT-SUB

PLOT_SUB:
        ld (COORDS), bc         ; store new x/y values in COORDS
        call PIXEL_ADD          ; routine PIXEL-ADD gets address in HL,
                                ; count from left 0-7 in B.
        ld b, a                 ; transfer count to B.
        inc b                   ; increase 1-8.
        ld a, $FE               ; 11111110 in A.

;; PLOT-LOOP

PLOT_LOOP:
        rrca                    ; rotate mask.
        djnz PLOT_LOOP          ; to PLOT-LOOP until B circular rotations.

        ld b, a                 ; load mask to B
        ld a, (hl)              ; fetch screen byte to A

        ld c, (iy+P_FLAG-IY0)   ; P_FLAG to C
        bit 0, c                ; is it to be OVER 1 ?
        jr nz, PL_TST_IN        ; forward to PL-TST-IN if so.

; was over 0

        and b                   ; combine with mask to blank pixel.

;; PL-TST-IN

PL_TST_IN:
        bit 2, c                ; is it inverse 1 ?
        jr nz, PLOT_END         ; to PLOT-END if so.

        xor b                   ; switch the pixel
        cpl                     ; restore other 7 bits

;; PLOT-END

PLOT_END:
        ld (hl), a              ; load byte to the screen.
        jp PO_ATTR              ; exit to PO-ATTR to set colours for cell.


; ------------------------------
; Put two numbers in BC register
; ------------------------------
;
;

;; STK-TO-BC

STK_TO_BC:
        call STK_TO_A           ; routine STK-TO-A
        ld b, a
        push bc
        call STK_TO_A           ; routine STK-TO-A
        ld e, c
        pop bc
        ld d, c
        ld c, a
        ret


; -----------------------
; Put stack in A register
; -----------------------
; This routine puts the last value on the calculator stack into the accumulator
; deleting the last value.

;; STK-TO-A

STK_TO_A:
        call FP_TO_A            ; routine FP-TO-A compresses last value into
                                ; accumulator. e.g. PI would become 3.
                                ; zero flag set if positive.
        jp c, REPORT_Bc         ; jump forward to REPORT-Bc if >= 255.5.

        ld c, $01               ; prepare a positive sign byte.
        ret z                   ; return if FP-TO-BC indicated positive.

        ld c, $FF               ; prepare negative sign byte and
        ret                     ; return.



; --------------------
; THE 'CIRCLE' COMMAND
; --------------------
;   "Goe not Thou about to Square eyther circle" -
;   - John Donne, Cambridge educated theologian, 1624
;
;   The CIRCLE command draws a circle as a series of straight lines.
;   In some ways it can be regarded as a polygon, but the first line is drawn 
;   as a tangent, taking the radius as its distance from the centre.
;
;   Both the CIRCLE algorithm and the ARC drawing algorithm make use of the
;   'ROTATION FORMULA' (see later).  It is only necessary to work out where 
;   the first line will be drawn and how long it is and then the rotation 
;   formula takes over and calculates all other rotated points.
;
;   All Spectrum circles consist of two vertical lines at each side and two 
;   horizontal lines at the top and bottom. The number of lines is calculated
;   from the radius of the circle and is always divisible by 4. For complete 
;   circles it will range from 4 for a square circle to 32 for a circle of 
;   radius 87. The Spectrum can attempt larger circles e.g. CIRCLE 0,14,255
;   but these will error as they go off-screen after four lines are drawn.
;   At the opposite end, CIRCLE 128,88,1.23 will draw a circle as a perfect 3x3
;   square using 4 straight lines although very small circles are just drawn as 
;   a dot on the screen.
;
;   The first chord drawn is the vertical chord on the right of the circle.
;   The starting point is at the base of this chord which is drawn upwards and
;   the circle continues in an anti-clockwise direction. As noted earlier the 
;   x-coordinate of this point measured from the centre of the circle is the 
;   radius. 
;
;   The CIRCLE command makes extensive use of the calculator and as part of
;   process of drawing a large circle, free memory is checked 1315 times.
;   When drawing a large arc, free memory is checked 928 times.
;   A single call to 'sin' involves 63 memory checks and so values of sine 
;   and cosine are pre-calculated and held in the mem locations. As a 
;   clever trick 'cos' is derived from 'sin' using simple arithmetic operations
;   instead of the more expensive 'cos' function.
;
;   Initially, the syntax has been partly checked using the class for the DRAW 
;   command which stacks the origin of the circle (X,Y).

;; CIRCLE

CIRCLE:
        rst $18                 ; GET-CHAR              x, y.
        cp $2C                  ; Is character the required comma ?
        jp nz, REPORT_C         ; Jump, if not, to REPORT-C
                                ; 'Nonsense in basic'

        rst $20                 ; NEXT-CHAR advances the parsed character address.
        call EXPT_1NUM          ; routine EXPT-1NUM stacks radius in runtime.
        call CHECK_END          ; routine CHECK-END will return here in runtime
                                ; if nothing follows the command.

;   Now make the radius positive and ensure that it is in floating point form 
;   so that the exponent byte can be accessed for quick testing.

        rst $28                 ; ; FP-CALC              x, y, r.
        defb $2A                ; ;abs                   x, y, r.
        defb $3D                ; ;re-stack              x, y, r.
        defb $38                ; ;end-calc              x, y, r.

        ld a, (hl)              ; Fetch first, floating-point, exponent byte.
        cp $81                  ; Compare to one.
        jr nc, C_R_GRE_1        ; Forward to C-R-GRE-1
                                ; if circle radius is greater than one.

;    The circle is no larger than a single pixel so delete the radius from the
;    calculator stack and plot a point at the centre.

        rst $28                 ; ; FP-CALC              x, y, r.
        defb $02                ; ;delete                x, y.
        defb $38                ; ;end-calc              x, y.

        jr PLOT                 ; back to PLOT routine to just plot x,y.


; ---

;   Continue when the circle's radius measures greater than one by forming 
;   the angle 2 * PI radians which is 360 degrees.

;; C-R-GRE-1

C_R_GRE_1:
        rst $28                 ; ; FP-CALC      x, y, r
        defb $A3                ; ;stk-pi/2      x, y, r, pi/2.
        defb $38                ; ;end-calc      x, y, r, pi/2.

;   Change the exponent of pi/2 from $81 to $83 giving 2*PI the central angle.
;   This is quicker than multiplying by four.

        ld (hl), $83            ;               x, y, r, 2*PI.

;   Now store this important constant in mem-5 and delete so that other 
;   parameters can be derived from it, by a routine shared with DRAW.

        rst $28                 ; ; FP-CALC      x, y, r, 2*PI.
        defb $C5                ; ;st-mem-5      store 2*PI in mem-5
        defb $02                ; ;delete        x, y, r.
        defb $38                ; ;end-calc      x, y, r.

;   The parameters derived from mem-5 (A) and from the radius are set up in 
;   four of the other mem locations by the CIRCLE DRAW PARAMETERS routine which 
;   also returns the number of straight lines in the B register.

        call CD_PRMS1           ; routine CD-PRMS1

                                ; mem-0 ; A/No of lines (=a)            unused  
                                ; mem-1 ; sin(a/2)  will be moving x    var
                                ; mem-2 ; -         will be moving y    var
                                ; mem-3 ; cos(a)                        const
                                ; mem-4 ; sin(a)                        const
                                ; mem-5 ; Angle of rotation (A) (2*PI)  const
                                ; B     ; Number of straight lines.

        push bc                 ; Preserve the number of lines in B.

;   Next calculate the length of half a chord by multiplying the sine of half 
;   the central angle by the radius of the circle.

        rst $28                 ; ; FP-CALC      x, y, r.
        defb $31                ; ;duplicate     x, y, r, r.
        defb $E1                ; ;get-mem-1     x, y, r, r, sin(a/2).
        defb $04                ; ;multiply      x, y, r, half-chord.
        defb $38                ; ;end-calc      x, y, r, half-chord.

        ld a, (hl)              ; fetch exponent  of the half arc to A.
        cp $80                  ; compare to a half pixel
        jr nc, C_ARC_GE1        ; forward, if greater than .5, to C-ARC-GE1

;   If the first line is less than .5 then 4 'lines' would be drawn on the same 
;   spot so tidy the calculator stack and machine stack and plot the centre.

        rst $28                 ; ; FP-CALC      x, y, r, hc.
        defb $02                ; ;delete        x, y, r.
        defb $02                ; ;delete        x, y.
        defb $38                ; ;end-calc      x, y.

        pop bc                  ; Balance machine stack by taking chord-count.

        jp PLOT                 ; JUMP to PLOT


; ---

;   The arc is greater than 0.5 so the circle can be drawn.

;; C-ARC-GE1

C_ARC_GE1:
        rst $28                 ; ; FP-CALC      x, y, r, hc.
        defb $C2                ; ;st-mem-2      x, y, r, half chord to mem-2.
        defb $01                ; ;exchange      x, y, hc, r.
        defb $C0                ; ;st-mem-0      x, y, hc, r.
        defb $02                ; ;delete        x, y, hc.

;   Subtract the length of the half-chord from the absolute y coordinate to
;   give the starting y coordinate sy. 
;   Note that for a circle this is also the end coordinate.

        defb $03                ; ;subtract      x, y-hc.  (The start y-coord)
        defb $01                ; ;exchange      sy, x.

;   Next simply add the radius to the x coordinate to give a fuzzy x-coordinate.
;   Strictly speaking, the radius should be multiplied by cos(a/2) first but
;   doing it this way makes the circle slightly larger.

        defb $E0                ; ;get-mem-0     sy, x, r.
        defb $0F                ; ;addition      sy, x+r.  (The start x-coord)

;   We now want three copies of this pair of values on the calculator stack.
;   The first pair remain on the stack throughout the circle routine and are 
;   the end points. The next pair will be the moving absolute values of x and y
;   that are updated after each line is drawn. The final pair will be loaded 
;   into the COORDS system variable so that the first vertical line starts at 
;   the right place.

        defb $C0                ; ;st-mem-0      sy, sx.
        defb $01                ; ;exchange      sx, sy.
        defb $31                ; ;duplicate     sx, sy, sy.
        defb $E0                ; ;get-mem-0     sx, sy, sy, sx.
        defb $01                ; ;exchange      sx, sy, sx, sy.
        defb $31                ; ;duplicate     sx, sy, sx, sy, sy.
        defb $E0                ; ;get-mem-0     sx, sy, sx, sy, sy, sx.

;   Locations mem-1 and mem-2 are the relative x and y values which are updated
;   after each line is drawn. Since we are drawing a vertical line then the rx
;   value in mem-1 is zero and the ry value in mem-2 is the full chord.

        defb $A0                ; ;stk-zero      sx, sy, sx, sy, sy, sx, 0.
        defb $C1                ; ;st-mem-1      sx, sy, sx, sy, sy, sx, 0.
        defb $02                ; ;delete        sx, sy, sx, sy, sy, sx.

;   Although the three pairs of x/y values are the same for a circle, they 
;   will be labelled terminating, absolute and start coordinates.

        defb $38                ; ;end-calc      tx, ty, ax, ay, sy, sx.

;   Use the exponent manipulating trick again to double the value of mem-2.

        inc (iy+$62)            ; Increment MEM-2-1st doubling half chord.

;   Note. this first vertical chord is drawn at the radius so circles are
;   slightly displaced to the right.
;   It is only necessary to place the values (sx) and (sy) in the system 
;   variable COORDS to ensure that drawing commences at the correct pixel.
;   Note. a couple of LD (COORDS),A instructions would have been quicker, and 
;   simpler, than using LD (COORDS),HL.

        call FIND_INT1          ; routine FIND-INT1 fetches sx from stack to A.

        ld l, a                 ; place X value in L.
        push hl                 ; save the holding register.

        call FIND_INT1          ; routine FIND-INT1 fetches sy to A

        pop hl                  ; restore the holding register.
        ld h, a                 ; and place y value in high byte.

        ld (COORDS), hl         ; Update the COORDS system variable.
                                ;               tx, ty, ax, ay.

        pop bc                  ; restore the chord count
                                ; values 4,8,12,16,20,24,28 or 32.

        jp DRW_STEPS            ; forward to DRW-STEPS
                                ;               tx, ty, ax, ay.


;   Note. the jump to DRW-STEPS is just to decrement B and jump into the 
;   middle of the arc-drawing loop. The arc count which includes the first 
;   vertical arc draws one less than the perceived number of arcs. 
;   The final arc offsets are obtained by subtracting the final COORDS value
;   from the initial sx and sy values which are kept at the base of the
;   calculator stack throughout the arc loop. 
;   This ensures that the final line finishes exactly at the starting pixel 
;   removing the possibility of any inaccuracy.
;   Since the initial sx and sy values are not required until the final arc
;   is drawn, they are not shown until then.
;   As the calculator stack is quite busy, only the active parts are shown in 
;   each section.


; ------------------
; THE 'DRAW' COMMAND
; ------------------
;   The Spectrum's DRAW command is overloaded and can take two parameters sets.
;
;   With two parameters, it simply draws an approximation to a straight line
;   at offset x,y using the LINE-DRAW routine.
;
;   With three parameters, an arc is drawn to the point at offset x,y turning 
;   through an angle, in radians, supplied by the third parameter.
;   The arc will consist of 4 to 252 straight lines each one of which is drawn 
;   by calls to the DRAW-LINE routine.

;; DRAW

DRAW:
        rst $18                 ; GET-CHAR
        cp $2C                  ; is it the comma character ?
        jr z, DR_3_PRMS         ; forward, if so, to DR-3-PRMS

;   There are two parameters e.g. DRAW 255,175

        call CHECK_END          ; routine CHECK-END

        jp LINE_DRAW            ; jump forward to LINE-DRAW


; ---

;    There are three parameters e.g. DRAW 255, 175, .5
;    The first two are relative coordinates and the third is the angle of 
;    rotation in radians (A).

;; DR-3-PRMS

DR_3_PRMS:
        rst $20                 ; NEXT-CHAR skips over the 'comma'.

        call EXPT_1NUM          ; routine EXPT-1NUM stacks the rotation angle.

        call CHECK_END          ; routine CHECK-END

;   Now enter the calculator and store the complete rotation angle in mem-5 

        rst $28                 ; ; FP-CALC      x, y, A.
        defb $C5                ; ;st-mem-5      x, y, A.

;   Test the angle for the special case of 360 degrees.

        defb $A2                ; ;stk-half      x, y, A, 1/2.
        defb $04                ; ;multiply      x, y, A/2.
        defb $1F                ; ;sin           x, y, sin(A/2).
        defb $31                ; ;duplicate     x, y, sin(A/2),sin(A/2)
        defb $30                ; ;not           x, y, sin(A/2), (0/1).
        defb $30                ; ;not           x, y, sin(A/2), (1/0).
        defb $00                ; ;jump-true     x, y, sin(A/2).

        defb $06                ; ;forward to L23A3, DR-SIN-NZ
                                ; if sin(r/2) is not zero.

;   The third parameter is 2*PI (or a multiple of 2*PI) so a 360 degrees turn
;   would just be a straight line.  Eliminating this case here prevents 
;   division by zero at later stage.

        defb $02                ; ;delete        x, y.
        defb $38                ; ;end-calc      x, y.

        jp LINE_DRAW            ; forward to LINE-DRAW


; ---

;   An arc can be drawn.

;; DR-SIN-NZ

DR_SIN_NZ:
        defb $C0                ; ;st-mem-0      x, y, sin(A/2).   store mem-0
        defb $02                ; ;delete        x, y.

;   The next step calculates (roughly) the diameter of the circle of which the 
;   arc will form part.  This value does not have to be too accurate as it is
;   only used to evaluate the number of straight lines and then discarded.
;   After all for a circle, the radius is used. Consequently, a circle of 
;   radius 50 will have 24 straight lines but an arc of radius 50 will have 20
;   straight lines - when drawn in any direction.
;   So that simple arithmetic can be used, the length of the chord can be 
;   calculated as X+Y rather than by Pythagoras Theorem and the sine of the
;   nearest angle within reach is used.

        defb $C1                ; ;st-mem-1      x, y.             store mem-1
        defb $02                ; ;delete        x.

        defb $31                ; ;duplicate     x, x.
        defb $2A                ; ;abs           x, x (+ve).
        defb $E1                ; ;get-mem-1     x, X, y.
        defb $01                ; ;exchange      x, y, X.
        defb $E1                ; ;get-mem-1     x, y, X, y.
        defb $2A                ; ;abs           x, y, X, Y (+ve).
        defb $0F                ; ;addition      x, y, X+Y.
        defb $E0                ; ;get-mem-0     x, y, X+Y, sin(A/2).
        defb $05                ; ;division      x, y, X+Y/sin(A/2).
        defb $2A                ; ;abs           x, y, X+Y/sin(A/2) = D.

;    Bring back sin(A/2) from mem-0 which will shortly get trashed.
;    Then bring D to the top of the stack again.

        defb $E0                ; ;get-mem-0     x, y, D, sin(A/2).
        defb $01                ; ;exchange      x, y, sin(A/2), D.

;   Note. that since the value at the top of the stack has arisen as a result
;   of division then it can no longer be in integer form and the next re-stack
;   is unnecessary. Only the Sinclair ZX80 had integer division.

        defb $3D                ; ;re-stack      (unnecessary)

        defb $38                ; ;end-calc      x, y, sin(A/2), D.

;   The next test avoids drawing 4 straight lines when the start and end pixels
;   are adjacent (or the same) but is probably best dispensed with.

        ld a, (hl)              ; fetch exponent byte of D.
        cp $81                  ; compare to 1
        jr nc, DR_PRMS          ; forward, if > 1,  to DR-PRMS

;   else delete the top two stack values and draw a simple straight line.

        rst $28                 ; ; FP-CALC
        defb $02                ; ;delete
        defb $02                ; ;delete
        defb $38                ; ;end-calc      x, y.

        jp LINE_DRAW            ; to LINE-DRAW


; ---

;   The ARC will consist of multiple straight lines so call the CIRCLE-DRAW
;   PARAMETERS ROUTINE to pre-calculate sine values from the angle (in mem-5)
;   and determine also the number of straight lines from that value and the
;   'diameter' which is at the top of the calculator stack.

;; DR-PRMS

DR_PRMS:
        call CD_PRMS1           ; routine CD-PRMS1

                                ; mem-0 ; (A)/No. of lines (=a) (step angle)
                                ; mem-1 ; sin(a/2) 
                                ; mem-2 ; -
                                ; mem-3 ; cos(a)                        const
                                ; mem-4 ; sin(a)                        const
                                ; mem-5 ; Angle of rotation (A)         in
                                ; B     ; Count of straight lines - max 252.

        push bc                 ; Save the line count on the machine stack.

;   Remove the now redundant diameter value D.

        rst $28                 ; ; FP-CALC      x, y, sin(A/2), D.
        defb $02                ; ;delete        x, y, sin(A/2).

;   Dividing the sine of the step angle by the sine of the total angle gives
;   the length of the initial chord on a unary circle. This factor f is used
;   to scale the coordinates of the first line which still points in the 
;   direction of the end point and may be larger.

        defb $E1                ; ;get-mem-1     x, y, sin(A/2), sin(a/2)
        defb $01                ; ;exchange      x, y, sin(a/2), sin(A/2)
        defb $05                ; ;division      x, y, sin(a/2)/sin(A/2)
        defb $C1                ; ;st-mem-1      x, y. f.
        defb $02                ; ;delete        x, y.

;   With the factor stored, scale the x coordinate first.

        defb $01                ; ;exchange      y, x.
        defb $31                ; ;duplicate     y, x, x.
        defb $E1                ; ;get-mem-1     y, x, x, f.
        defb $04                ; ;multiply      y, x, x*f    (=xx)
        defb $C2                ; ;st-mem-2      y, x, xx.
        defb $02                ; ;delete        y. x.

;   Now scale the y coordinate.

        defb $01                ; ;exchange      x, y.
        defb $31                ; ;duplicate     x, y, y.
        defb $E1                ; ;get-mem-1     x, y, y, f
        defb $04                ; ;multiply      x, y, y*f    (=yy)

;   Note. 'sin' and 'cos' trash locations mem-0 to mem-2 so fetch mem-2 to the 
;   calculator stack for safe keeping.

        defb $E2                ; ;get-mem-2     x, y, yy, xx.

;   Once we get the coordinates of the first straight line then the 'ROTATION
;   FORMULA' used in the arc loop will take care of all other points, but we
;   now use a variation of that formula to rotate the first arc through (A-a)/2
;   radians. 
;   
;       xRotated = y * sin(angle) + x * cos(angle)
;       yRotated = y * cos(angle) - x * sin(angle)
;
 
        defb $E5                ; ;get-mem-5     x, y, yy, xx, A.
        defb $E0                ; ;get-mem-0     x, y, yy, xx, A, a.
        defb $03                ; ;subtract      x, y, yy, xx, A-a.
        defb $A2                ; ;stk-half      x, y, yy, xx, A-a, 1/2.
        defb $04                ; ;multiply      x, y, yy, xx, (A-a)/2. (=angle)
        defb $31                ; ;duplicate     x, y, yy, xx, angle, angle.
        defb $1F                ; ;sin           x, y, yy, xx, angle, sin(angle)
        defb $C5                ; ;st-mem-5      x, y, yy, xx, angle, sin(angle)
        defb $02                ; ;delete        x, y, yy, xx, angle

        defb $20                ; ;cos           x, y, yy, xx, cos(angle).

;   Note. mem-0, mem-1 and mem-2 can be used again now...

        defb $C0                ; ;st-mem-0      x, y, yy, xx, cos(angle).
        defb $02                ; ;delete        x, y, yy, xx.

        defb $C2                ; ;st-mem-2      x, y, yy, xx.
        defb $02                ; ;delete        x, y, yy.

        defb $C1                ; ;st-mem-1      x, y, yy.
        defb $E5                ; ;get-mem-5     x, y, yy, sin(angle)
        defb $04                ; ;multiply      x, y, yy*sin(angle).
        defb $E0                ; ;get-mem-0     x, y, yy*sin(angle), cos(angle)
        defb $E2                ; ;get-mem-2     x, y, yy*sin(angle), cos(angle), xx.
        defb $04                ; ;multiply      x, y, yy*sin(angle), xx*cos(angle).
        defb $0F                ; ;addition      x, y, xRotated.
        defb $E1                ; ;get-mem-1     x, y, xRotated, yy.
        defb $01                ; ;exchange      x, y, yy, xRotated.
        defb $C1                ; ;st-mem-1      x, y, yy, xRotated.
        defb $02                ; ;delete        x, y, yy.

        defb $E0                ; ;get-mem-0     x, y, yy, cos(angle).
        defb $04                ; ;multiply      x, y, yy*cos(angle).
        defb $E2                ; ;get-mem-2     x, y, yy*cos(angle), xx.
        defb $E5                ; ;get-mem-5     x, y, yy*cos(angle), xx, sin(angle).
        defb $04                ; ;multiply      x, y, yy*cos(angle), xx*sin(angle).
        defb $03                ; ;subtract      x, y, yRotated.
        defb $C2                ; ;st-mem-2      x, y, yRotated.

;   Now the initial x and y coordinates are made positive and summed to see 
;   if they measure up to anything significant.

        defb $2A                ; ;abs           x, y, yRotated'.
        defb $E1                ; ;get-mem-1     x, y, yRotated', xRotated.
        defb $2A                ; ;abs           x, y, yRotated', xRotated'.
        defb $0F                ; ;addition      x, y, yRotated+xRotated.
        defb $02                ; ;delete        x, y.

        defb $38                ; ;end-calc      x, y.

;   Although the test value has been deleted it is still above the calculator
;   stack in memory and conveniently DE which points to the first free byte
;   addresses the exponent of the test value.

        ld a, (de)              ; Fetch exponent of the length indicator.
        cp $81                  ; Compare to that for 1

        pop bc                  ; Balance the machine stack

        jp c, LINE_DRAW         ; forward, if the coordinates of first line
                                ; don't add up to more than 1, to LINE-DRAW

;   Continue when the arc will have a discernable shape.

        push bc                 ; Restore line counter to the machine stack.

;   The parameters of the DRAW command were relative and they are now converted 
;   to absolute coordinates by adding to the coordinates of the last point 
;   plotted. The first two values on the stack are the terminal tx and ty 
;   coordinates.  The x-coordinate is converted first but first the last point 
;   plotted is saved as it will initialize the moving ax, value. 

        rst $28                 ; ; FP-CALC      x, y.
        defb $01                ; ;exchange      y, x.
        defb $38                ; ;end-calc      y, x.

        ld a, (COORDS)          ; Fetch System Variable COORDS-x
        call STACK_A            ; routine STACK-A

        rst $28                 ; ; FP-CALC      y, x, last-x.

;   Store the last point plotted to initialize the moving ax value.

        defb $C0                ; ;st-mem-0      y, x, last-x.
        defb $0F                ; ;addition      y, absolute x.
        defb $01                ; ;exchange      tx, y.
        defb $38                ; ;end-calc      tx, y.

        ld a, (COORDS_hi)       ; Fetch System Variable COORDS-y
        call STACK_A            ; routine STACK-A

        rst $28                 ; ; FP-CALC      tx, y, last-y.

;   Store the last point plotted to initialize the moving ay value.

        defb $C5                ; ;st-mem-5      tx, y, last-y.
        defb $0F                ; ;addition      tx, ty.

;   Fetch the moving ax and ay to the calculator stack.

        defb $E0                ; ;get-mem-0     tx, ty, ax.
        defb $E5                ; ;get-mem-5     tx, ty, ax, ay.
        defb $38                ; ;end-calc      tx, ty, ax, ay.

        pop bc                  ; Restore the straight line count.

; -----------------------------------
; THE 'CIRCLE/DRAW CONVERGENCE POINT'
; -----------------------------------
;   The CIRCLE and ARC-DRAW commands converge here. 
;
;   Note. for both the CIRCLE and ARC commands the minimum initial line count 
;   is 4 (as set up by the CD_PARAMS routine) and so the zero flag will never 
;   be set and the loop is always entered.  The first test is superfluous and
;   the jump will always be made to ARC-START.

;; DRW-STEPS

DRW_STEPS:
        dec b                   ; decrement the arc count (4,8,12,16...).

        jr z, ARC_END           ; forward, if zero (not possible), to ARC-END

        jr ARC_START            ; forward to ARC-START


; --------------
; THE 'ARC LOOP'
; --------------
;
;   The arc drawing loop will draw up to 31 straight lines for a circle and up 
;   251 straight lines for an arc between two points. In both cases the final
;   closing straight line is drawn at ARC_END, but it otherwise loops back to 
;   here to calculate the next coordinate using the ROTATION FORMULA where (a)
;   is the previously calculated, constant CENTRAL ANGLE of the arcs.
;
;       Xrotated = x * cos(a) - y * sin(a)
;       Yrotated = x * sin(a) + y * cos(a)
;
;   The values cos(a) and sin(a) are pre-calculated and held in mem-3 and mem-4 
;   for the duration of the routine.
;   Memory location mem-1 holds the last relative x value (rx) and mem-2 holds
;   the last relative y value (ry) used by DRAW.
;
;   Note. that this is a very clever twist on what is after all a very clever,
;   well-used formula.  Normally the rotation formula is used with the x and y
;   coordinates from the centre of the circle (or arc) and a supplied angle to 
;   produce two new x and y coordinates in an anticlockwise direction on the 
;   circumference of the circle.
;   What is being used here, instead, is the relative X and Y parameters from
;   the last point plotted that are required to get to the current point and 
;   the formula returns the next relative coordinates to use. 

;; ARC-LOOP

ARC_LOOP:
        rst $28                 ; ; FP-CALC
        defb $E1                ; ;get-mem-1     rx.
        defb $31                ; ;duplicate     rx, rx.
        defb $E3                ; ;get-mem-3     cos(a)
        defb $04                ; ;multiply      rx, rx*cos(a).
        defb $E2                ; ;get-mem-2     rx, rx*cos(a), ry.
        defb $E4                ; ;get-mem-4     rx, rx*cos(a), ry, sin(a).
        defb $04                ; ;multiply      rx, rx*cos(a), ry*sin(a).
        defb $03                ; ;subtract      rx, rx*cos(a) - ry*sin(a)
        defb $C1                ; ;st-mem-1      rx, new relative x rotated.
        defb $02                ; ;delete        rx.

        defb $E4                ; ;get-mem-4     rx, sin(a).
        defb $04                ; ;multiply      rx*sin(a)
        defb $E2                ; ;get-mem-2     rx*sin(a), ry.
        defb $E3                ; ;get-mem-3     rx*sin(a), ry, cos(a).
        defb $04                ; ;multiply      rx*sin(a), ry*cos(a).
        defb $0F                ; ;addition      rx*sin(a) + ry*cos(a).
        defb $C2                ; ;st-mem-2      new relative y rotated.
        defb $02                ; ;delete        .
        defb $38                ; ;end-calc      .

;   Note. the calculator stack actually holds   tx, ty, ax, ay
;   and the last absolute values of x and y 
;   are now brought into play.
;
;   Magically, the two new rotated coordinates rx and ry are all that we would
;   require to draw a circle or arc - on paper!
;   The Spectrum DRAW routine draws to the rounded x and y coordinate and so 
;   repetitions of values like 3.49 would mean that the fractional parts 
;   would be lost until eventually the draw coordinates might differ from the 
;   floating point values used above by several pixels.
;   For this reason the accurate offsets calculated above are added to the 
;   accurate, absolute coordinates maintained in ax and ay and these new 
;   coordinates have the integer coordinates of the last plot position 
;   ( from System Variable COORDS ) subtracted from them to give the relative 
;   coordinates required by the DRAW routine.

;   The mid entry point.

;; ARC-START

ARC_START:
        push bc                 ; Preserve the arc counter on the machine stack.

;   Store the absolute ay in temporary variable mem-0 for the moment.

        rst $28                 ; ; FP-CALC      ax, ay.
        defb $C0                ; ;st-mem-0      ax, ay.
        defb $02                ; ;delete        ax.

;   Now add the fractional relative x coordinate to the fractional absolute
;   x coordinate to obtain a new fractional x-coordinate.

        defb $E1                ; ;get-mem-1     ax, xr.
        defb $0F                ; ;addition      ax+xr (= new ax).
        defb $31                ; ;duplicate     ax, ax.
        defb $38                ; ;end-calc      ax, ax.

        ld a, (COORDS)          ; COORDS-x      last x    (integer ix 0-255)
        call STACK_A            ; routine STACK-A

        rst $28                 ; ; FP-CALC      ax, ax, ix.
        defb $03                ; ;subtract      ax, ax-ix  = relative DRAW Dx.

;   Having calculated the x value for DRAW do the same for the y value.

        defb $E0                ; ;get-mem-0     ax, Dx, ay.
        defb $E2                ; ;get-mem-2     ax, Dx, ay, ry.
        defb $0F                ; ;addition      ax, Dx, ay+ry (= new ay).
        defb $C0                ; ;st-mem-0      ax, Dx, ay.
        defb $01                ; ;exchange      ax, ay, Dx,
        defb $E0                ; ;get-mem-0     ax, ay, Dx, ay.
        defb $38                ; ;end-calc      ax, ay, Dx, ay.

        ld a, (COORDS_hi)       ; COORDS-y      last y (integer iy 0-175)
        call STACK_A            ; routine STACK-A

        rst $28                 ; ; FP-CALC      ax, ay, Dx, ay, iy.
        defb $03                ; ;subtract      ax, ay, Dx, ay-iy ( = Dy).
        defb $38                ; ;end-calc      ax, ay, Dx, Dy.

        call DRAW_LINE          ; Routine DRAW-LINE draws (Dx,Dy) relative to
                                ; the last pixel plotted leaving absolute x
                                ; and y on the calculator stack.
                                ;               ax, ay.

        pop bc                  ; Restore the arc counter from the machine stack.

        djnz ARC_LOOP           ; Decrement and loop while > 0 to ARC-LOOP

; -------------
; THE 'ARC END'
; -------------

;   To recap the full calculator stack is       tx, ty, ax, ay.

;   Just as one would do if drawing the curve on paper, the final line would
;   be drawn by joining the last point plotted to the initial start point 
;   in the case of a CIRCLE or to the calculated end point in the case of 
;   an ARC.
;   The moving absolute values of x and y are no longer required and they
;   can be deleted to expose the closing coordinates.

;; ARC-END

ARC_END:
        rst $28                 ; ; FP-CALC      tx, ty, ax, ay.
        defb $02                ; ;delete        tx, ty, ax.
        defb $02                ; ;delete        tx, ty.
        defb $01                ; ;exchange      ty, tx.
        defb $38                ; ;end-calc      ty, tx.

;   First calculate the relative x coordinate to the end-point.

        ld a, (COORDS)          ; COORDS-x
        call STACK_A            ; routine STACK-A

        rst $28                 ; ; FP-CALC      ty, tx, coords_x.
        defb $03                ; ;subtract      ty, rx.

;   Next calculate the relative y coordinate to the end-point.

        defb $01                ; ;exchange      rx, ty.
        defb $38                ; ;end-calc      rx, ty.

        ld a, (COORDS_hi)       ; COORDS-y
        call STACK_A            ; routine STACK-A

        rst $28                 ; ; FP-CALC      rx, ty, coords_y
        defb $03                ; ;subtract      rx, ry.
        defb $38                ; ;end-calc      rx, ry.

;   Finally draw the last straight line.

;; LINE-DRAW

LINE_DRAW:
        call DRAW_LINE          ; routine DRAW-LINE draws to the relative
                                ; coordinates (rx, ry).

        jp TEMPS                ; jump back and exit via TEMPS          >>>



; --------------------------------------------
; THE 'INITIAL CIRCLE/DRAW PARAMETERS' ROUTINE
; --------------------------------------------
;   Begin by calculating the number of chords which will be returned in B.
;   A rule of thumb is employed that uses a value z which for a circle is the
;   radius and for an arc is the diameter with, as it happens, a pinch more if 
;   the arc is on a slope.
;
;   NUMBER OF STRAIGHT LINES = ANGLE OF ROTATION * SQUARE ROOT ( Z ) / 2

;; CD-PRMS1

CD_PRMS1:
        rst $28                 ; ; FP-CALC      z.
        defb $31                ; ;duplicate     z, z.
        defb $28                ; ;sqr           z, sqr(z).
        defb $34                ; ;stk-data      z, sqr(z), 2.
        defb $32                ; ;Exponent: $82, Bytes: 1
        defb $00                ; ;(+00,+00,+00)
        defb $01                ; ;exchange      z, 2, sqr(z).
        defb $05                ; ;division      z, 2/sqr(z).
        defb $E5                ; ;get-mem-5     z, 2/sqr(z), ANGLE.
        defb $01                ; ;exchange      z, ANGLE, 2/sqr (z)
        defb $05                ; ;division      z, ANGLE*sqr(z)/2 (= No. of lines)
        defb $2A                ; ;abs           (for arc only)
        defb $38                ; ;end-calc      z, number of lines.

;    As an example for a circle of radius 87 the number of lines will be 29.

        call FP_TO_A            ; routine FP-TO-A

;    The value is compressed into A register, no carry with valid circle.

        jr c, USE_252           ; forward, if over 256, to USE-252

;    now make a multiple of 4 e.g. 29 becomes 28

        and $FC                 ; AND 252

;    Adding 4 could set carry for arc, for the circle example, 28 becomes 32.

        add a, $04              ; adding 4 could set carry if result is 256.
        
        jr nc, DRAW_SAVE        ; forward if less than 256 to DRAW-SAVE

;    For an arc, a limit of 252 is imposed.

;; USE-252

USE_252:
        ld a, $FC               ; Use a value of 252 (for arc).


;   For both arcs and circles, constants derived from the central angle are
;   stored in the 'mem' locations.  Some are not relevant for the circle.

;; DRAW-SAVE

DRAW_SAVE:
        push af                 ; Save the line count (A) on the machine stack.

        call STACK_A            ; Routine STACK-A stacks the modified count(A).

        rst $28                 ; ; FP-CALC      z, A.
        defb $E5                ; ;get-mem-5     z, A, ANGLE.
        defb $01                ; ;exchange      z, ANGLE, A.
        defb $05                ; ;division      z, ANGLE/A. (Angle/count = a)
        defb $31                ; ;duplicate     z, a, a.

;  Note. that cos (a) could be formed here directly using 'cos' and stored in 
;  mem-3 but that would spoil a good story and be slightly slower, as also 
;  would using square roots to form cos (a) from sin (a).

        defb $1F                ; ;sin           z, a, sin(a)
        defb $C4                ; ;st-mem-4      z, a, sin(a)
        defb $02                ; ;delete        z, a.
        defb $31                ; ;duplicate     z, a, a.
        defb $A2                ; ;stk-half      z, a, a, 1/2.
        defb $04                ; ;multiply      z, a, a/2.
        defb $1F                ; ;sin           z, a, sin(a/2).

;   Note. after second sin, mem-0 and mem-1 become free.

        defb $C1                ; ;st-mem-1      z, a, sin(a/2).
        defb $01                ; ;exchange      z, sin(a/2), a.
        defb $C0                ; ;st-mem-0      z, sin(a/2), a.  (for arc only)

;   Now form cos(a) from sin(a/2) using the 'DOUBLE ANGLE FORMULA'.

        defb $02                ; ;delete        z, sin(a/2).
        defb $31                ; ;duplicate     z, sin(a/2), sin(a/2).
        defb $04                ; ;multiply      z, sin(a/2)*sin(a/2).
        defb $31                ; ;duplicate     z, sin(a/2)*sin(a/2),
                                ; ;                           sin(a/2)*sin(a/2).
        defb $0F                ; ;addition      z, 2*sin(a/2)*sin(a/2).
        defb $A1                ; ;stk-one       z, 2*sin(a/2)*sin(a/2), 1.
        defb $03                ; ;subtract      z, 2*sin(a/2)*sin(a/2)-1.

        defb $1B                ; ;negate        z, 1-2*sin(a/2)*sin(a/2).

        defb $C3                ; ;st-mem-3      z, cos(a).
        defb $02                ; ;delete        z.
        defb $38                ; ;end-calc      z.

;   The radius/diameter is left on the calculator stack.

        pop bc                  ; Restore the line count to the B register.

        ret                     ; Return.


; --------------------------
; THE 'DOUBLE ANGLE FORMULA'
; --------------------------
;   This formula forms cos(a) from sin(a/2) using simple arithmetic.
;
;   THE GEOMETRIC PROOF OF FORMULA   cos (a) = 1 - 2 * sin(a/2) * sin(a/2)
;                                                                    
;                                                                   
;                                            A                     
;                                                                 
;                                         . /|\                      
;                                     .    / | \                     
;                                  .      /  |  \                    
;                               .        /   |a/2\                   
;                            .          /    |    \                  
;                         .          1 /     |     \                 
;                      .              /      |      \                
;                   .                /       |       \               
;                .                  /        |        \              
;             .  a/2             D / a      E|-+       \             
;          B ---------------------/----------+-+--------\ C
;            <-         1       -><-       1           ->           
;
;   cos a = 1 - 2 * sin(a/2) * sin(a/2)
;
;   The figure shows a right triangle that inscribes a circle of radius 1 with
;   centre, or origin, D.  Line BC is the diameter of length 2 and A is a point 
;   on the circle. The periphery angle BAC is therefore a right angle by the 
;   Rule of Thales.
;   Line AC is a chord touching two points on the circle and the angle at the 
;   centre is (a).
;   Since the vertex of the largest triangle B touches the circle, the 
;   inscribed angle (a/2) is half the central angle (a).
;   The cosine of (a) is the length DE as the hypotenuse is of length 1.
;   This can also be expressed as 1-length CE.  Examining the triangle at the
;   right, the top angle is also (a/2) as angle BAE and EBA add to give a right
;   angle as do BAE and EAC.
;   So cos (a) = 1 - AC * sin(a/2) 
;   Looking at the largest triangle, side AC can be expressed as 
;   AC = 2 * sin(a/2)   and so combining these we get 
;   cos (a) = 1 - 2 * sin(a/2) * sin(a/2).
;
;   "I will be sufficiently rewarded if when telling it to others, you will 
;    not claim the discovery as your own, but will say it is mine."
;   - Thales, 640 - 546 B.C.
;
; --------------------------
; THE 'LINE DRAWING' ROUTINE
; --------------------------
;
;

;; DRAW-LINE

DRAW_LINE:
        call STK_TO_BC          ; routine STK-TO-BC
        ld a, c
        cp b
        jr nc, DL_X_GE_Y        ; to DL-X-GE-Y

        ld l, c
        push de
        xor a
        ld e, a
        jr DL_LARGER            ; to DL-LARGER


; ---

;; DL-X-GE-Y

DL_X_GE_Y:
        or c
        ret z

        ld l, b
        ld b, c
        push de
        ld d, $00

;; DL-LARGER

DL_LARGER:
        ld h, b
        ld a, b
        rra

;; D-L-LOOP

D_L_LOOP:
        add a, l
        jr c, D_L_DIAG          ; to D-L-DIAG

        cp h
        jr c, D_L_HR_VT         ; to D-L-HR-VT

;; D-L-DIAG

D_L_DIAG:
        sub h
        ld c, a
        exx
        pop bc
        push bc
        jr D_L_STEP             ; to D-L-STEP


; ---

;; D-L-HR-VT

D_L_HR_VT:
        ld c, a
        push de
        exx
        pop bc

;; D-L-STEP

D_L_STEP:
        ld hl, (COORDS)         ; COORDS
        ld a, b
        add a, h
        ld b, a
        ld a, c
        inc a
        add a, l
        jr c, D_L_RANGE         ; to D-L-RANGE

        jr z, REPORT_Bc         ; to REPORT-Bc

;; D-L-PLOT

D_L_PLOT:
        dec a
        ld c, a
        call PLOT_SUB           ; routine PLOT-SUB
        exx
        ld a, c
        djnz D_L_LOOP           ; to D-L-LOOP

        pop de
        ret


; ---

;; D-L-RANGE

D_L_RANGE:
        jr z, D_L_PLOT          ; to D-L-PLOT


;; REPORT-Bc

REPORT_Bc:
        rst $08                 ; ERROR-1
        defb $0A                ; Error Report: Integer out of range



;***********************************
;** Part 8. EXPRESSION EVALUATION **
;***********************************
;
; It is a this stage of the ROM that the Spectrum ceases altogether to be
; just a colourful novelty. One remarkable feature is that in all previous
; commands when the Spectrum is expecting a number or a string then an
; expression of the same type can be substituted ad infinitum.
; This is the routine that evaluates that expression.
; This is what causes 2 + 2 to give the answer 4.
; That is quite easy to understand. However you don't have to make it much
; more complex to start a remarkable juggling act.
; e.g. PRINT 2 * (VAL "2+2" + TAN 3)
; In fact, provided there is enough free RAM, the Spectrum can evaluate
; an expression of unlimited complexity.
; Apart from a couple of minor glitches, which you can now correct, the
; system is remarkably robust.


; ---------------------------------
; Scan expression or sub-expression
; ---------------------------------
;
;

;; SCANNING

SCANNING:
        rst $18                 ; GET-CHAR
        ld b, $00               ; priority marker zero is pushed on stack
                                ; to signify end of expression when it is
                                ; popped off again.
        push bc                 ; put in on stack.
                                ; and proceed to consider the first character
                                ; of the expression.

;; S-LOOP-1

S_LOOP_1:
        ld c, a                 ; store the character while a look up is done.
        ld hl, scan_func        ; Address: scan-func
        call INDEXER            ; routine INDEXER is called to see if it is
                                ; part of a limited range '+', '(', 'ATTR' etc.

        ld a, c                 ; fetch the character back
        jp nc, S_ALPHNUM        ; jump forward to S-ALPHNUM if not in primary
                                ; operators and functions to consider in the
                                ; first instance a digit or a variable and
                                ; then anything else.                >>>

        ld b, $00               ; but here if it was found in table so
        ld c, (hl)              ; fetch offset from table and make B zero.
        add hl, bc              ; add the offset to position found
        jp (hl)                 ; and jump to the routine e.g. S-BIN
                                ; making an indirect exit from there.


; -------------------------------------------------------------------------
; The four service subroutines for routines in the scanning function table
; -------------------------------------------------------------------------

; PRINT """Hooray!"" he cried."

;; S-QUOTE-S

S_QUOTE_S:
        call CH_ADD_1           ; routine CH-ADD+1 points to next character
                                ; and fetches that character.
        inc bc                  ; increase length counter.
        cp $0D                  ; is it carriage return ?
                                ; inside a quote.
        jp z, REPORT_C          ; jump back to REPORT-C if so.
                                ; 'Nonsense in BASIC'.

        cp $22                  ; is it a quote '"' ?
        jr nz, S_QUOTE_S        ; back to S-QUOTE-S if not for more.

        call CH_ADD_1           ; routine CH-ADD+1
        cp $22                  ; compare with possible adjacent quote
        ret                     ; return. with zero set if two together.


; ---

; This subroutine is used to get two coordinate expressions for the three
; functions SCREEN$, ATTR and POINT that have two fixed parameters and
; therefore require surrounding braces.

;; S-2-COORD

S_2_COORD:
        rst $20                 ; NEXT-CHAR
        cp $28                  ; is it the opening '(' ?
        jr nz, S_RPORT_C        ; forward to S-RPORT-C if not
                                ; 'Nonsense in BASIC'.

        call NEXT_2NUM          ; routine NEXT-2NUM gets two comma-separated
                                ; numeric expressions. Note. this could cause
                                ; many more recursive calls to SCANNING but
                                ; the parent function will be evaluated fully
                                ; before rejoining the main juggling act.

        rst $18                 ; GET-CHAR
        cp $29                  ; is it the closing ')' ?

;; S-RPORT-C

S_RPORT_C:
        jp nz, REPORT_C         ; jump back to REPORT-C if not.
                                ; 'Nonsense in BASIC'.

; ------------
; Check syntax
; ------------
; This routine is called on a number of occasions to check if syntax is being
; checked or if the program is being run. To test the flag inline would use
; four bytes of code, but a call instruction only uses 3 bytes of code.

;; SYNTAX-Z

SYNTAX_Z:
        bit 7, (iy+FLAGS-IY0)   ; test FLAGS  - checking syntax only ?
        ret                     ; return.


; ----------------
; Scanning SCREEN$
; ----------------
; This function returns the code of a bit-mapped character at screen
; position at line C, column B. It is unable to detect the mosaic characters
; which are not bit-mapped but detects the ASCII 32 - 127 range.
; The bit-mapped UDGs are ignored which is curious as it requires only a
; few extra bytes of code. As usual, anything to do with CHARS is weird.
; If no match is found a null string is returned.
; No actual check on ranges is performed - that's up to the BASIC programmer.
; No real harm can come from SCREEN$(255,255) although the BASIC manual
; says that invalid values will be trapped.
; Interestingly, in the Pitman pocket guide, 1984, Vickers says that the
; range checking will be performed. 

;; S-SCRN$-S

S_SCRN__S:
        call STK_TO_BC          ; routine STK-TO-BC.
        ld hl, (CHARS)          ; fetch address of CHARS.
        ld de, $0100            ; fetch offset to chr$ 32
        add hl, de              ; and find start of bitmaps.
                                ; Note. not inc h. ??
        ld a, c                 ; transfer line to A.
        rrca                    ; multiply
        rrca                    ; by
        rrca                    ; thirty-two.
        and $E0                 ; and with 11100000
        xor b                   ; combine with column $00 - $1F
        ld e, a                 ; to give the low byte of top line
        ld a, c                 ; column to A range 00000000 to 00011111
        and $18                 ; and with 00011000
        xor $40                 ; xor with 01000000 (high byte screen start)
        ld d, a                 ; register DE now holds start address of cell.
        ld b, $60               ; there are 96 characters in ASCII set.

;; S-SCRN-LP

S_SCRN_LP:
        push bc                 ; save count
        push de                 ; save screen start address
        push hl                 ; save bitmap start
        ld a, (de)              ; first byte of screen to A
        xor (hl)                ; xor with corresponding character byte
        jr z, S_SC_MTCH         ; forward to S-SC-MTCH if they match
                                ; if inverse result would be $FF
                                ; if any other then mismatch

        inc a                   ; set to $00 if inverse
        jr nz, S_SCR_NXT        ; forward to S-SCR-NXT if a mismatch

        dec a                   ; restore $FF

; a match has been found so seven more to test.

;; S-SC-MTCH

S_SC_MTCH:
        ld c, a                 ; load C with inverse mask $00 or $FF
        ld b, $07               ; count seven more bytes

;; S-SC-ROWS

S_SC_ROWS:
        inc d                   ; increment screen address.
        inc hl                  ; increment bitmap address.
        ld a, (de)              ; byte to A
        xor (hl)                ; will give $00 or $FF (inverse)
        xor c                   ; xor with inverse mask
        jr nz, S_SCR_NXT        ; forward to S-SCR-NXT if no match.

        djnz S_SC_ROWS          ; back to S-SC-ROWS until all eight matched.

; continue if a match of all eight bytes was found

        pop bc                  ; discard the
        pop bc                  ; saved
        pop bc                  ; pointers
        ld a, $80               ; the endpoint of character set
        sub b                   ; subtract the counter
                                ; to give the code 32-127
        ld bc, $0001            ; make one space in workspace.

        rst $30                 ; BC-SPACES creates the space sliding
                                ; the calculator stack upwards.
        ld (de), a              ; start is addressed by DE, so insert code
        jr S_SCR_STO            ; forward to S-SCR-STO


; ---

; the jump was here if no match and more bitmaps to test.

;; S-SCR-NXT

S_SCR_NXT:
        pop hl                  ; restore the last bitmap start
        ld de, $0008            ; and prepare to add 8.
        add hl, de              ; now addresses next character bitmap.
        pop de                  ; restore screen address
        pop bc                  ; and character counter in B
        djnz S_SCRN_LP          ; back to S-SCRN-LP if more characters.

        ld c, b                 ; B is now zero, so BC now zero.

;; S-SCR-STO

S_SCR_STO:
        jp STK_STO__            ; to STK-STO-$ to store the string in
                                ; workspace or a string with zero length.
                                ; (value of DE doesn't matter in last case)


; Note. this exit seems correct but the general-purpose routine S-STRING
; that calls this one will also stack any of its string results so this
; leads to a double storing of the result in this case.
; The instruction at L257D should just be a RET.
; credit Stephen Kelly and others, 1982.

; -------------
; Scanning ATTR
; -------------
; This function subroutine returns the attributes of a screen location -
; a numeric result.
; Again it's up to the BASIC programmer to supply valid values of line/column.

;; S-ATTR-S

S_ATTR_S:
        call STK_TO_BC          ; routine STK-TO-BC fetches line to C,
                                ; and column to B.
        ld a, c                 ; line to A $00 - $17   (max 00010111)
        rrca                    ; rotate
        rrca                    ; bits
        rrca                    ; left.
        ld c, a                 ; store in C as an intermediate value.

        and $E0                 ; pick up bits 11100000 ( was 00011100 )
        xor b                   ; combine with column $00 - $1F
        ld l, a                 ; low byte now correct.

        ld a, c                 ; bring back intermediate result from C
        and $03                 ; mask to give correct third of
                                ; screen $00 - $02
        xor $58                 ; combine with base address.
        ld h, a                 ; high byte correct.
        ld a, (hl)              ; pick up the colour attribute.
        jp STACK_A              ; forward to STACK-A to store result
                                ; and make an indirect exit.


; -----------------------
; Scanning function table
; -----------------------
; This table is used by INDEXER routine to find the offsets to
; four operators and eight functions. e.g. $A8 is the token 'FN'.
; This table is used in the first instance for the first character of an
; expression or by a recursive call to SCANNING for the first character of
; any sub-expression. It eliminates functions that have no argument or
; functions that can have more than one argument and therefore require
; braces. By eliminating and dealing with these now it can later take a
; simplistic approach to all other functions and assume that they have
; one argument.
; Similarly by eliminating BIN and '.' now it is later able to assume that
; all numbers begin with a digit and that the presence of a number or
; variable can be detected by a call to ALPHANUM.
; By default all expressions are positive and the spurious '+' is eliminated
; now as in print +2. This should not be confused with the operator '+'.
; Note. this does allow a degree of nonsense to be accepted as in
; PRINT +"3 is the greatest.".
; An acquired programming skill is the ability to include brackets where
; they are not necessary.
; A bracket at the start of a sub-expression may be spurious or necessary
; to denote that the contained expression is to be evaluated as an entity.
; In either case this is dealt with by recursive calls to SCANNING.
; An expression that begins with a quote requires special treatment.

;; scan-func

scan_func:
        defb $22                ; $1C offset to S-QUOTE
        defb S_QUOTE - $
        defm "("                ; $4F offset to S-BRACKET
        defb S_BRACKET - $
        defm "."                ; $F2 offset to S-DECIMAL
        defb S_DECIMAL - $
        defm "+"                ; $12 offset to S-U-PLUS
        defb S_U_PLUS - $

        defb $A8                ; $56 offset to S-FN
        defb S_FN - $
        defb $A5                ; $57 offset to S-RND
        defb S_RND - $
        defb $A7                ; $84 offset to S-PI
        defb S_PI - $
        defb $A6                ; $8F offset to S-INKEY$
        defb S_INKEY_ - $
        defb $C4                ; $E6 offset to S-BIN
        defb S_DECIMAL - $
        defb $AA                ; $BF offset to S-SCREEN$
        defb S_SCREEN_ - $
        defb $AB                ; $C7 offset to S-ATTR
        defb S_ATTR - $
        defb $A9                ; $CE offset to S-POINT
        defb S_POINT - $

        defb $00                ; zero end marker

; --------------------------
; Scanning function routines
; --------------------------
; These are the 11 subroutines accessed by the above table.
; S-BIN and S-DECIMAL are the same
; The 1-byte offset limits their location to within 255 bytes of their
; entry in the table.

; ->
;; S-U-PLUS

S_U_PLUS:
        rst $20                 ; NEXT-CHAR just ignore
        jp S_LOOP_1             ; to S-LOOP-1


; ---

; ->
;; S-QUOTE

S_QUOTE:
        rst $18                 ; GET-CHAR
        inc hl                  ; address next character (first in quotes)
        push hl                 ; save start of quoted text.
        ld bc, $0000            ; initialize length of string to zero.
        call S_QUOTE_S          ; routine S-QUOTE-S
        jr nz, S_Q_PRMS         ; forward to S-Q-PRMS if

;; S-Q-AGAIN

S_Q_AGAIN:
        call S_QUOTE_S          ; routine S-QUOTE-S copies string until a
                                ; quote is encountered
        jr z, S_Q_AGAIN         ; back to S-Q-AGAIN if two quotes WERE
                                ; together.

; but if just an isolated quote then that terminates the string.

        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, S_Q_PRMS          ; forward to S-Q-PRMS if checking syntax.


        rst $30                 ; BC-SPACES creates the space for true
                                ; copy of string in workspace.
        pop hl                  ; re-fetch start of quoted text.
        push de                 ; save start in workspace.

;; S-Q-COPY

S_Q_COPY:
        ldi a, (hl)             ; fetch a character from source.
                                ; advance source address.
        ldi (de), a             ; place in destination.
                                ; advance destination address.
        cp $22                  ; was it a '"' just copied ?
        jr nz, S_Q_COPY         ; back to S-Q-COPY to copy more if not

        ldi a, (hl)             ; fetch adjacent character from source.
                                ; advance source address.
        cp $22                  ; is this '"' ? - i.e. two quotes together ?
        jr z, S_Q_COPY          ; to S-Q-COPY if so including just one of the
                                ; pair of quotes.

; proceed when terminating quote encountered.

;; S-Q-PRMS

S_Q_PRMS:
        dec bc                  ; decrease count by 1.
        pop de                  ; restore start of string in workspace.

;; S-STRING

S_STRING:
        ld hl, FLAGS            ; Address FLAGS system variable.
        res 6, (hl)             ; signal string result.
        bit 7, (hl)             ; is syntax being checked.
        call nz, STK_STO__      ; routine STK-STO-$ is called in runtime.
        jp S_CONT_2             ; jump forward to S-CONT-2          ===>


; ---

; ->
;; S-BRACKET

S_BRACKET:
        rst $20                 ; NEXT-CHAR
        call SCANNING           ; routine SCANNING is called recursively.
        cp $29                  ; is it the closing ')' ?
        jp nz, REPORT_C         ; jump back to REPORT-C if not
                                ; 'Nonsense in BASIC'

        rst $20                 ; NEXT-CHAR
        jp S_CONT_2             ; jump forward to S-CONT-2          ===>


; ---

; ->
;; S-FN

S_FN:
        jp S_FN_SBRN            ; jump forward to S-FN-SBRN.


; --------------------------------------------------------------------
;
;   RANDOM THEORY from the ZX81 manual by Steven Vickers
;
;   (same algorithm as the ZX Spectrum).
; 
;   Chapter 5. Exercise 6. (For mathematicians only.)
;
;   Let p be a [large] prime, & let a be a primitive root modulo p.
;   Then if b_i is the residue of a^i modulo p (1<=b_i<p-1), the 
;   sequence             
;   
;                           (b_i-1)/(p-1)
;               
;   is a cyclical sequence of p-1 distinct numbers in the range 0 to 1
;   (excluding 1). By choosing a suitably, these can be made to look 
;   fairly random.
;
;     65537 is a Mersenne prime 2^16-1. Note.
;
;   Use this, & Gauss' law of quadratic reciprocity, to show that 75 
;   is a primitive root modulo 65537.
;
;     The ZX81 uses p=65537 & a=75, & stores some b_i-1 in memory. 
;   The function RND involves replacing b_i-1 in memory by b_(i+1)-1, 
;   & yielding the result (b_(i+1)-1)/(p-1). RAND n (with 1<=n<=65535)
;   makes b_i equal to n+1.
;
; --------------------------------------------------------------------
;
; Steven Vickers writing in comp.sys.sinclair on 20-DEC-1993
; 
;   Note. (Of course, 65537 is 2^16 + 1, not -1.)
;
;   Consider arithmetic modulo a prime p. There are p residue classes, and the
;   non-zero ones are all invertible. Hence under multiplication they form a
;   group (Fp*, say) of order p-1; moreover (and not so obvious) Fp* is cyclic.
;   Its generators are the "primitive roots". The "quadratic residues modulo p"
;   are the squares in Fp*, and the "Legendre symbol" (d/p) is defined (when p
;   does not divide d) as +1 or -1, according as d is or is not a quadratic
;   residue mod p.
;
;   In the case when p = 65537, we can show that d is a primitive root if and
;   only if it's not a quadratic residue. For let w be a primitive root, d
;   congruent to w^r (mod p). If d is not primitive, then its order is a proper
;   factor of 65536: hence w^{32768*r} = 1 (mod p), so 65536 divides 32768*r,
;   and hence r is even and d is a square (mod p). Conversely, the squares in
;   Fp* form a subgroup of (Fp*)^2 of index 2, and so cannot be generators.
;
;   Hence to check whether 75 is primitive mod 65537, we want to calculate that
;   (75/65537) = -1. There is a multiplicative formula (ab/p) = (a/p)(b/p) (mod
;   p), so (75/65537) = (5/65537)^2 * (3/65537) = (3/65537). Now the law of
;   quadratic reciprocity says that if p and q are distinct odd primes, then
;
;    (p/q)(q/p) = (-1)^{(p-1)(q-1)/4}
;
;   Hence (3/65537) = (65537/3) * (-1)^{65536*2/4} = (65537/3)
;            = (2/3)  (because 65537 = 2 mod 3)
;            = -1
;
;   (I referred to Pierre Samuel's "Algebraic Theory of Numbers".)
;
; ->

;; S-RND

S_RND:
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, S_RND_END         ; forward to S-RND-END if checking syntax.

        ld bc, (SEED)           ; fetch system variable SEED
        call STACK_BC           ; routine STACK-BC places on calculator stack

        rst $28                 ; ; FP-CALC           ;s.
        defb $A1                ; ;stk-one            ;s,1.
        defb $0F                ; ;addition           ;s+1.
        defb $34                ; ;stk-data           ;
        defb $37                ; ;Exponent: $87,
                                ; ;Bytes: 1
        defb $16                ; ;(+00,+00,+00)      ;s+1,75.
        defb $04                ; ;multiply           ;(s+1)*75 = v
        defb $34                ; ;stk-data           ;v.
        defb $80                ; ;Bytes: 3
        defb $41, $00, $00, $80 ; ;Exponent $91
                                ; ;(+00)              ;v,65537.
        defb $32                ; ;n-mod-m            ;remainder, result.
        defb $02                ; ;delete             ;remainder.
        defb $A1                ; ;stk-one            ;remainder, 1.
        defb $03                ; ;subtract           ;remainder - 1. = rnd
        defb $31                ; ;duplicate          ;rnd,rnd.
        defb $38                ; ;end-calc

        call FP_TO_BC           ; routine FP-TO-BC
        ld (SEED), bc           ; store in SEED for next starting point.
        ld a, (hl)              ; fetch exponent
        and a                   ; is it zero ?
        jr z, S_RND_END         ; forward if so to S-RND-END

        sub $10                 ; reduce exponent by 2^16
        ld (hl), a              ; place back

;; S-RND-END

S_RND_END:
        jr S_PI_END             ; forward to S-PI-END


; ---

; the number PI 3.14159...

; ->
;; S-PI

S_PI:
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, S_PI_END          ; to S-PI-END if checking syntax.

        rst $28                 ; ; FP-CALC
        defb $A3                ; ;stk-pi/2                          pi/2.
        defb $38                ; ;end-calc

        inc (hl)                ; increment the exponent leaving pi
                                ; on the calculator stack.

;; S-PI-END

S_PI_END:
        rst $20                 ; NEXT-CHAR
        jp S_NUMERIC            ; jump forward to S-NUMERIC


; ---

; ->
;; S-INKEY$

S_INKEY_:
        ld bc, $105A            ; priority $10, operation code $1A ('read-in')
                                ; +$40 for string result, numeric operand.
                                ; set this up now in case we need to use the
                                ; calculator.
        rst $20                 ; NEXT-CHAR
        cp $23                  ; '#' ?
        jp z, S_PUSH_PO         ; to S-PUSH-PO if so to use the calculator
                                ; single operation
                                ; to read from network/RS232 etc. .

; else read a key from the keyboard.

        ld hl, FLAGS            ; fetch FLAGS
        res 6, (hl)             ; signal string result.
        bit 7, (hl)             ; checking syntax ?
        jr z, S_INK__EN         ; forward to S-INK$-EN if so

        call KEY_SCAN           ; routine KEY-SCAN key in E, shift in D.
        ld c, $00               ; the length of an empty string
        jr nz, S_IK__STK        ; to S-IK$-STK to store empty string if
                                ; no key returned.

        call K_TEST             ; routine K-TEST get main code in A
        jr nc, S_IK__STK        ; to S-IK$-STK to stack null string if
                                ; invalid

        dec d                   ; D is expected to be FLAGS so set bit 3 $FF
                                ; 'L' Mode so no keywords.
        ld e, a                 ; main key to A
                                ; C is MODE 0 'KLC' from above still.
        call K_DECODE           ; routine K-DECODE
        push af                 ; save the code
        ld bc, $0001            ; make room for one character

        rst $30                 ; BC-SPACES
        pop af                  ; bring the code back
        ld (de), a              ; put the key in workspace
        ld c, $01               ; set C length to one

;; S-IK$-STK

S_IK__STK:
        ld b, $00               ; set high byte of length to zero
        call STK_STO__          ; routine STK-STO-$

;; S-INK$-EN

S_INK__EN:
        jp S_CONT_2             ; to S-CONT-2            ===>


; ---

; ->
;; S-SCREEN$

S_SCREEN_:
        call S_2_COORD          ; routine S-2-COORD
        call nz, S_SCRN__S      ; routine S-SCRN$-S

        rst $20                 ; NEXT-CHAR
        jp S_STRING             ; forward to S-STRING to stack result


; ---

; ->
;; S-ATTR

S_ATTR:
        call S_2_COORD          ; routine S-2-COORD
        call nz, S_ATTR_S       ; routine S-ATTR-S

        rst $20                 ; NEXT-CHAR
        jr S_NUMERIC            ; forward to S-NUMERIC


; ---

; ->
;; S-POINT

S_POINT:
        call S_2_COORD          ; routine S-2-COORD
        call nz, POINT_SUB      ; routine POINT-SUB

        rst $20                 ; NEXT-CHAR
        jr S_NUMERIC            ; forward to S-NUMERIC


; -----------------------------

; ==> The branch was here if not in table.

;; S-ALPHNUM

S_ALPHNUM:
        call ALPHANUM           ; routine ALPHANUM checks if variable or
                                ; a digit.
        jr nc, S_NEGATE         ; forward to S-NEGATE if not to consider
                                ; a '-' character then functions.

        cp $41                  ; compare 'A'
        jr nc, S_LETTER         ; forward to S-LETTER if alpha       ->
                                ; else must have been numeric so continue
                                ; into that routine.

; This important routine is called during runtime and from LINE-SCAN
; when a BASIC line is checked for syntax. It is this routine that
; inserts, during syntax checking, the invisible floating point numbers
; after the numeric expression. During runtime it just picks these
; numbers up. It also handles BIN format numbers.

; ->
;; S-BIN
;; S-DECIMAL

S_DECIMAL:
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr nz, S_STK_DEC        ; to S-STK-DEC in runtime

; this route is taken when checking syntax.

        call DEC_TO_FP          ; routine DEC-TO-FP to evaluate number

        rst $18                 ; GET-CHAR to fetch HL
        ld bc, $0006            ; six locations required
        call MAKE_ROOM          ; routine MAKE-ROOM
        inc hl                  ; to first new location
        ldi (hl), $0E           ; insert number marker
                                ; address next
        ex de, hl               ; make DE destination.
        ld hl, (STKEND)         ; STKEND points to end of stack.
        ld c, $05               ; result is five locations lower
        and a                   ; prepare for true subtraction
        sbc hl, bc              ; point to start of value.
        ld (STKEND), hl         ; update STKEND as we are taking number.
        ldir                    ; Copy five bytes to program location
        ex de, hl               ; transfer pointer to HL
        dec hl                  ; adjust
        call TEMP_PTR1          ; routine TEMP-PTR1 sets CH-ADD
        jr S_NUMERIC            ; to S-NUMERIC to record nature of result


; ---

; branch here in runtime.

;; S-STK-DEC

S_STK_DEC:
        rst $18                 ; GET-CHAR positions HL at digit.

;; S-SD-SKIP

S_SD_SKIP:
        inc hl                  ; advance pointer
        ld a, (hl)              ; until we find
        cp $0E                  ; chr 14d - the number indicator
        jr nz, S_SD_SKIP        ; to S-SD-SKIP until a match
                                ; it has to be here.

        inc hl                  ; point to first byte of number
        call STACK_NUM          ; routine STACK-NUM stacks it
        ld (CH_ADD), hl         ; update system variable CH_ADD

;; S-NUMERIC

S_NUMERIC:
        set 6, (iy+FLAGS-IY0)   ; update FLAGS  - Signal numeric result
        jr S_CONT_1             ; forward to S-CONT-1               ===>
                                ; actually S-CONT-2 is destination but why
                                ; waste a byte on a jump when a JR will do.
                                ; Actually a JR L2712 can be used. Rats.


; end of functions accessed from scanning functions table.

; --------------------------
; Scanning variable routines
; --------------------------
;
;

;; S-LETTER

S_LETTER:
        call LOOK_VARS          ; routine LOOK-VARS

        jp c, REPORT_2          ; jump back to REPORT-2 if variable not found
                                ; 'Variable not found'
                                ; but a variable is always 'found' if syntax
                                ; is being checked.

        call z, STK_VAR         ; routine STK-VAR considers a subscript/slice
        ld a, (FLAGS)           ; fetch FLAGS value
        cp $C0                  ; compare 11000000
        jr c, S_CONT_1          ; step forward to S-CONT-1 if string  ===>

        inc hl                  ; advance pointer
        call STACK_NUM          ; routine STACK-NUM

;; S-CONT-1

S_CONT_1:
        jr S_CONT_2             ; forward to S-CONT-2                 ===>


; ----------------------------------------
; -> the scanning branch was here if not alphanumeric.
; All the remaining functions will be evaluated by a single call to the
; calculator. The correct priority for the operation has to be placed in
; the B register and the operation code, calculator literal in the C register.
; the operation code has bit 7 set if result is numeric and bit 6 is
; set if operand is numeric. so
; $C0 = numeric result, numeric operand.            e.g. 'sin'
; $80 = numeric result, string operand.             e.g. 'code'
; $40 = string result, numeric operand.             e.g. 'str$'
; $00 = string result, string operand.              e.g. 'val$'

;; S-NEGATE

S_NEGATE:
        ld bc, $09DB            ; prepare priority 09, operation code $C0 +
                                ; 'negate' ($1B) - bits 6 and 7 set for numeric
                                ; result and numeric operand.

        cp $2D                  ; is it '-' ?
        jr z, S_PUSH_PO         ; forward if so to S-PUSH-PO

        ld bc, $1018            ; prepare priority $10, operation code 'val$' -
                                ; bits 6 and 7 reset for string result and
                                ; string operand.
        
        cp $AE                  ; is it 'VAL$' ?
        jr z, S_PUSH_PO         ; forward if so to S-PUSH-PO

        sub $AF                 ; subtract token 'CODE' value to reduce
                                ; functions 'CODE' to 'NOT' although the
                                ; upper range is, as yet, unchecked.
                                ; valid range would be $00 - $14.

        jp c, REPORT_C          ; jump back to REPORT-C with anything else
                                ; 'Nonsense in BASIC'

        ld bc, $04F0            ; prepare priority $04, operation $C0 +
                                ; 'not' ($30)

        cp $14                  ; is it 'NOT'
        jr z, S_PUSH_PO         ; forward to S-PUSH-PO if so

        jp nc, REPORT_C         ; to REPORT-C if higher
                                ; 'Nonsense in BASIC'

        ld b, $10               ; priority $10 for all the rest
        add a, $DC              ; make range $DC - $EF
                                ; $C0 + 'code'($1C) thru 'chr$' ($2F)

        ld c, a                 ; transfer 'function' to C
        cp $DF                  ; is it 'sin' ?
        jr nc, S_NO_TO__        ; forward to S-NO-TO-$  with 'sin' through
                                ; 'chr$' as operand is numeric.

; all the rest 'cos' through 'chr$' give a numeric result except 'str$'
; and 'chr$'.

        res 6, c                ; signal string operand for 'code', 'val' and
                                ; 'len'.

;; S-NO-TO-$

S_NO_TO__:
        cp $EE                  ; compare 'str$'
        jr c, S_PUSH_PO         ; forward to S-PUSH-PO if lower as result
                                ; is numeric.

        res 7, c                ; reset bit 7 of op code for 'str$', 'chr$'
                                ; as result is string.

; >> This is where they were all headed for.

;; S-PUSH-PO

S_PUSH_PO:
        push bc                 ; push the priority and calculator operation
                                ; code.

        rst $20                 ; NEXT-CHAR
        jp S_LOOP_1             ; jump back to S-LOOP-1 to go round the loop
                                ; again with the next character.


; --------------------------------

; ===>  there were many branches forward to here

;   An important step after the evaluation of an expression is to test for
;   a string expression and allow it to be sliced.  If a numeric expression is 
;   followed by a '(' then the numeric expression is complete.
;   Since a string slice can itself be sliced then loop repeatedly 
;   e.g. (STR$ PI) (3 TO) (TO 2)    or "nonsense" (4 TO )

;; S-CONT-2

S_CONT_2:
        rst $18                 ; GET-CHAR

;; S-CONT-3

S_CONT_3:
        cp $28                  ; is it '(' ?
        jr nz, S_OPERTR         ; forward, if not, to S-OPERTR

        bit 6, (iy+FLAGS-IY0)   ; test FLAGS - numeric or string result ?
        jr nz, S_LOOP           ; forward, if numeric, to S-LOOP

;   if a string expression preceded the '(' then slice it.

        call SLICING            ; routine SLICING

        rst $20                 ; NEXT-CHAR
        jr S_CONT_3             ; loop back to S-CONT-3


; ---------------------------

;   the branch was here when possibility of a '(' has been excluded.

;; S-OPERTR

S_OPERTR:
        ld b, $00               ; prepare to add
        ld c, a                 ; possible operator to C
        ld hl, tbl_of_ops       ; Address: $2795 - tbl-of-ops
        call INDEXER            ; routine INDEXER
        jr nc, S_LOOP           ; forward to S-LOOP if not in table

;   but if found in table the priority has to be looked up.

        ld c, (hl)              ; operation code to C ( B is still zero )
        ld hl, tbl_priors-$C3   ; $26ED is base of table
        add hl, bc              ; index into table.
        ld b, (hl)              ; priority to B.

; ------------------
; Scanning main loop
; ------------------
; the juggling act

;; S-LOOP

S_LOOP:
        pop de                  ; fetch last priority and operation
        ld a, d                 ; priority to A
        cp b                    ; compare with this one
        jr c, S_TIGHTER         ; forward to S-TIGHTER to execute the
                                ; last operation before this one as it has
                                ; higher priority.

; the last priority was greater or equal this one.

        and a                   ; if it is zero then so is this
        jp z, GET_CHAR          ; jump to exit via get-char pointing at
                                ; next character.
                                ; This may be the character after the
                                ; expression or, if exiting a recursive call,
                                ; the next part of the expression to be
                                ; evaluated.

        push bc                 ; save current priority/operation
                                ; as it has lower precedence than the one
                                ; now in DE.

; the 'USR' function is special in that it is overloaded to give two types
; of result.

        ld hl, FLAGS            ; address FLAGS
        ld a, e                 ; new operation to A register
        cp $ED                  ; is it $C0 + 'usr-no' ($2D)  ?
        jr nz, S_STK_LST        ; forward to S-STK-LST if not

        bit 6, (hl)             ; string result expected ?
                                ; (from the lower priority operand we've
                                ; just pushed on stack )
        jr nz, S_STK_LST        ; forward to S-STK-LST if numeric
                                ; as operand bits match.

        ld e, $99               ; reset bit 6 and substitute $19 'usr-$'
                                ; for string operand.

;; S-STK-LST

S_STK_LST:
        push de                 ; now stack this priority/operation
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, S_SYNTEST         ; forward to S-SYNTEST if checking syntax.

        ld a, e                 ; fetch the operation code
        and $3F                 ; mask off the result/operand bits to leave
                                ; a calculator literal.
        ld b, a                 ; transfer to B register

; now use the calculator to perform the single operation - operand is on
; the calculator stack.
; Note. although the calculator is performing a single operation most
; functions e.g. TAN are written using other functions and literals and
; these in turn are written using further strings of calculator literals so
; another level of magical recursion joins the juggling act for a while
; as the calculator too is calling itself.

        rst $28                 ; ; FP-CALC
        defb $3B                ; ;fp-calc-2

L2758:
        defb $38                ; ;end-calc

        jr S_RUNTEST            ; forward to S-RUNTEST


; ---

; the branch was here if checking syntax only. 

;; S-SYNTEST

S_SYNTEST:
        ld a, e                 ; fetch the operation code to accumulator
        xor (iy+FLAGS-IY0)      ; compare with bits of FLAGS
        and $40                 ; bit 6 will be zero now if operand
                                ; matched expected result.

;; S-RPORT-C2

S_RPORT_C2:
        jp nz, REPORT_C         ; to REPORT-C if mismatch
                                ; 'Nonsense in BASIC'
                                ; else continue to set flags for next

; the branch is to here in runtime after a successful operation.

;; S-RUNTEST

S_RUNTEST:
        pop de                  ; fetch the last operation from stack
        ld hl, FLAGS            ; address FLAGS
        set 6, (hl)             ; set default to numeric result in FLAGS
        bit 7, e                ; test the operational result
        jr nz, S_LOOPEND        ; forward to S-LOOPEND if numeric

        res 6, (hl)             ; reset bit 6 of FLAGS to show string result.

;; S-LOOPEND

S_LOOPEND:
        pop bc                  ; fetch the previous priority/operation
        jr S_LOOP               ; back to S-LOOP to perform these


; ---

; the branch was here when a stacked priority/operator had higher priority
; than the current one.

;; S-TIGHTER

S_TIGHTER:
        push de                 ; save high priority op on stack again
        ld a, c                 ; fetch lower priority operation code
        bit 6, (iy+FLAGS-IY0)   ; test FLAGS - Numeric or string result ?
        jr nz, S_NEXT           ; forward to S-NEXT if numeric result

; if this is lower priority yet has string then must be a comparison.
; Since these can only be evaluated in context and were defaulted to
; numeric in operator look up they must be changed to string equivalents.

        and $3F                 ; mask to give true calculator literal
        add a, $08              ; augment numeric literals to string
                                ; equivalents.
                                ; 'no-&-no'  => 'str-&-no'
                                ; 'no-l-eql' => 'str-l-eql'
                                ; 'no-gr-eq' => 'str-gr-eq'
                                ; 'nos-neql' => 'strs-neql'
                                ; 'no-grtr'  => 'str-grtr'
                                ; 'no-less'  => 'str-less'
                                ; 'nos-eql'  => 'strs-eql'
                                ; 'addition' => 'strs-add'
        ld c, a                 ; put modified comparison operator back
        cp $10                  ; is it now 'str-&-no' ?
        jr nz, S_NOT_AND        ; forward to S-NOT-AND  if not.

        set 6, c                ; set numeric operand bit
        jr S_NEXT               ; forward to S-NEXT


; ---

;; S-NOT-AND

S_NOT_AND:
        jr c, S_RPORT_C2        ; back to S-RPORT-C2 if less
                                ; 'Nonsense in BASIC'.
                                ; e.g. a$ * b$

        cp $17                  ; is it 'strs-add' ?
        jr z, S_NEXT            ; forward to S-NEXT if so
                                ; (bit 6 and 7 are reset)

        set 7, c                ; set numeric (Boolean) result for all others

;; S-NEXT

S_NEXT:
        push bc                 ; now save this priority/operation on stack

        rst $20                 ; NEXT-CHAR
        jp S_LOOP_1             ; jump back to S-LOOP-1


; ------------------
; Table of operators
; ------------------
; This table is used to look up the calculator literals associated with
; the operator character. The thirteen calculator operations $03 - $0F
; have bits 6 and 7 set to signify a numeric result.
; Some of these codes and bits may be altered later if the context suggests
; a string comparison or operation.
; that is '+', '=', '>', '<', '<=', '>=' or '<>'.

;; tbl-of-ops

tbl_of_ops:
        defm "+"                ;        $C0 + 'addition'
        defb $CF
        defm "-"                ;        $C0 + 'subtract'
        defb $C3
        defm "*"                ;        $C0 + 'multiply'
        defb $C4
        defm "/"                ;        $C0 + 'division'
        defb $C5
        defm "^"                ;        $C0 + 'to-power'
        defb $C6
        defm "="                ;        $C0 + 'nos-eql'
        defb $CE
        defm ">"                ;        $C0 + 'no-grtr'
        defb $CC
        defm "<"                ;        $C0 + 'no-less'
        defb $CD

        defb $C7                ; '<='   $C0 + 'no-l-eql'
        defb $C9
        defb $C8                ; '>='   $C0 + 'no-gr-eql'
        defb $CA
        defb $C9                ; '<>'   $C0 + 'nos-neql'
        defb $CB
        defb $C5                ; 'OR'   $C0 + 'or'
        defb $C7
        defb $C6                ; 'AND'  $C0 + 'no-&-no'
        defb $C8

        defb $00                ; zero end-marker.


; -------------------
; Table of priorities
; -------------------
; This table is indexed with the operation code obtained from the above
; table $C3 - $CF to obtain the priority for the respective operation.

;; tbl-priors

tbl_priors:
        defb $06                ; '-'   opcode $C3
        defb $08                ; '*'   opcode $C4
        defb $08                ; '/'   opcode $C5
        defb $0A                ; '^'   opcode $C6
        defb $02                ; 'OR'  opcode $C7
        defb $03                ; 'AND' opcode $C8
        defb $05                ; '<='  opcode $C9
        defb $05                ; '>='  opcode $CA
        defb $05                ; '<>'  opcode $CB
        defb $05                ; '>'   opcode $CC
        defb $05                ; '<'   opcode $CD
        defb $05                ; '='   opcode $CE
        defb $06                ; '+'   opcode $CF

; ----------------------
; Scanning function (FN)
; ----------------------
; This routine deals with user-defined functions.
; The definition can be anywhere in the program area but these are best
; placed near the start of the program as we shall see.
; The evaluation process is quite complex as the Spectrum has to parse two
; statements at the same time. Syntax of both has been checked previously
; and hidden locations have been created immediately after each argument
; of the DEF FN statement. Each of the arguments of the FN function is
; evaluated by SCANNING and placed in the hidden locations. Then the
; expression to the right of the DEF FN '=' is evaluated by SCANNING and for
; any variables encountered, a search is made in the DEF FN variable list
; in the program area before searching in the normal variables area.
;
; Recursion is not allowed: i.e. the definition of a function should not use
; the same function, either directly or indirectly ( through another function).
; You'll normally get error 4, ('Out of memory'), although sometimes the system
; will crash. - Vickers, Pitman 1984.
;
; As the definition is just an expression, there would seem to be no means
; of breaking out of such recursion.
; However, by the clever use of string expressions and VAL, such recursion is
; possible.
; e.g. DEF FN a(n) = VAL "n+FN a(n-1)+0" ((n<1) * 10 + 1 TO )
; will evaluate the full 11-character expression for all values where n is
; greater than zero but just the 11th character, "0", when n drops to zero
; thereby ending the recursion producing the correct result.
; Recursive string functions are possible using VAL$ instead of VAL and the
; null string as the final addend.
; - from a turn of the century newsgroup discussion initiated by Mike Wynne.

;; S-FN-SBRN

S_FN_SBRN:
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr nz, SF_RUN           ; forward to SF-RUN in runtime


        rst $20                 ; NEXT-CHAR
        call ALPHA              ; routine ALPHA check for letters A-Z a-z
        jp nc, REPORT_C         ; jump back to REPORT-C if not
                                ; 'Nonsense in BASIC'


        rst $20                 ; NEXT-CHAR
        cp $24                  ; is it '$' ?
        push af                 ; save character and flags
        jr nz, SF_BRKT_1        ; forward to SF-BRKT-1 with numeric function


        rst $20                 ; NEXT-CHAR

;; SF-BRKT-1

SF_BRKT_1:
        cp $28                  ; is '(' ?
        jr nz, SF_RPRT_C        ; forward to SF-RPRT-C if not
                                ; 'Nonsense in BASIC'


        rst $20                 ; NEXT-CHAR
        cp $29                  ; is it ')' ?
        jr z, SF_FLAG_6         ; forward to SF-FLAG-6 if no arguments.

;; SF-ARGMTS

SF_ARGMTS:
        call SCANNING           ; routine SCANNING checks each argument
                                ; which may be an expression.

        rst $18                 ; GET-CHAR
        cp $2C                  ; is it a ',' ?
        jr nz, SF_BRKT_2        ; forward if not to SF-BRKT-2 to test bracket


        rst $20                 ; NEXT-CHAR if a comma was found
        jr SF_ARGMTS            ; back to SF-ARGMTS to parse all arguments.


; ---

;; SF-BRKT-2

SF_BRKT_2:
        cp $29                  ; is character the closing ')' ?

;; SF-RPRT-C

SF_RPRT_C:
        jp nz, REPORT_C         ; jump to REPORT-C
                                ; 'Nonsense in BASIC'

; at this point any optional arguments have had their syntax checked.

;; SF-FLAG-6

SF_FLAG_6:
        rst $20                 ; NEXT-CHAR
        ld hl, FLAGS            ; address system variable FLAGS
        res 6, (hl)             ; signal string result
        pop af                  ; restore test against '$'.
        jr z, SF_SYN_EN         ; forward to SF-SYN-EN if string function.

        set 6, (hl)             ; signal numeric result

;; SF-SYN-EN

SF_SYN_EN:
        jp S_CONT_2             ; jump back to S-CONT-2 to continue scanning.


; ---

; the branch was here in runtime.

;; SF-RUN

SF_RUN:
        rst $20                 ; NEXT-CHAR fetches name
        and $DF                 ; AND 11101111 - reset bit 5 - upper-case.
        ld b, a                 ; save in B

        rst $20                 ; NEXT-CHAR
        sub $24                 ; subtract '$'
        ld c, a                 ; save result in C
        jr nz, SF_ARGMT1        ; forward if not '$' to SF-ARGMT1

        rst $20                 ; NEXT-CHAR advances to bracket

;; SF-ARGMT1

SF_ARGMT1:
        rst $20                 ; NEXT-CHAR advances to start of argument
        push hl                 ; save address
        ld hl, (PROG)           ; fetch start of program area from PROG
        dec hl                  ; the search starting point is the previous
                                ; location.

;; SF-FND-DF

SF_FND_DF:
        ld de, $00CE            ; search is for token 'DEF FN' in E,
                                ; statement count in D.
        push bc                 ; save C the string test, and B the letter.
        call LOOK_PROG          ; routine LOOK-PROG will search for token.
        pop bc                  ; restore BC.
        jr nc, SF_CP_DEF        ; forward to SF-CP-DEF if a match was found.


;; REPORT-P

REPORT_P:
        rst $08                 ; ERROR-1
        defb $18                ; Error Report: FN without DEF

;; SF-CP-DEF

SF_CP_DEF:
        push hl                 ; save address of DEF FN
        call FN_SKPOVR          ; routine FN-SKPOVR skips over white-space etc.
                                ; without disturbing CH-ADD.
        and $DF                 ; make fetched character upper-case.
        cp b                    ; compare with FN name
        jr nz, SF_NOT_FD        ; forward to SF-NOT-FD if no match.

; the letters match so test the type.

        call FN_SKPOVR          ; routine FN-SKPOVR skips white-space
        sub $24                 ; subtract '$' from fetched character
        cp c                    ; compare with saved result of same operation
                                ; on FN name.
        jr z, SF_VALUES         ; forward to SF-VALUES with a match.

; the letters matched but one was string and the other numeric.

;; SF-NOT-FD

SF_NOT_FD:
        pop hl                  ; restore search point.
        dec hl                  ; make location before
        ld de, $0200            ; the search is to be for the end of the
                                ; current definition - 2 statements forward.
        push bc                 ; save the letter/type
        call EACH_STMT          ; routine EACH-STMT steps past rejected
                                ; definition.
        pop bc                  ; restore letter/type
        jr SF_FND_DF            ; back to SF-FND-DF to continue search


; ---

; Success!
; the branch was here with matching letter and numeric/string type.

;; SF-VALUES

SF_VALUES:
        and a                   ; test A ( will be zero if string '$' - '$' )

        call z, FN_SKPOVR       ; routine FN-SKPOVR advances HL past '$'.

        pop de                  ; discard pointer to 'DEF FN'.
        pop de                  ; restore pointer to first FN argument.
        ld (CH_ADD), de         ; save in CH_ADD

        call FN_SKPOVR          ; routine FN-SKPOVR advances HL past '('
        push hl                 ; save start address in DEF FN  ***
        cp $29                  ; is character a ')' ?
        jr z, SF_R_BR_2         ; forward to SF-R-BR-2 if no arguments.

;; SF-ARG-LP

SF_ARG_LP:
        inc hl                  ; point to next character.
        ld a, (hl)              ; fetch it.
        cp $0E                  ; is it the number marker
        ld d, $40               ; signal numeric in D.
        jr z, SF_ARG_VL         ; forward to SF-ARG-VL if numeric.

        dec hl                  ; back to letter
        call FN_SKPOVR          ; routine FN-SKPOVR skips any white-space
        inc hl                  ; advance past the expected '$' to
                                ; the 'hidden' marker.
        ld d, $00               ; signal string.

;; SF-ARG-VL

SF_ARG_VL:
        inc hl                  ; now address first of 5-byte location.
        push hl                 ; save address in DEF FN statement
        push de                 ; save D - result type

        call SCANNING           ; routine SCANNING evaluates expression in
                                ; the FN statement setting FLAGS and leaving
                                ; result as last value on calculator stack.

        pop af                  ; restore saved result type to A

        xor (iy+FLAGS-IY0)      ; xor with FLAGS
        and $40                 ; and with 01000000 to test bit 6
        jr nz, REPORT_Q         ; forward to REPORT-Q if type mismatch.
                                ; 'Parameter error'

        pop hl                  ; pop the start address in DEF FN statement
        ex de, hl               ; transfer to DE ?? pop straight into de ?

        ld hl, (STKEND)         ; set HL to STKEND location after value
        ld bc, $0005            ; five bytes to move
        sbc hl, bc              ; decrease HL by 5 to point to start.
        ld (STKEND), hl         ; set STKEND 'removing' value from stack.

        ldir                    ; copy value into DEF FN statement
        ex de, hl               ; set HL to location after value in DEF FN
        dec hl                  ; step back one
        call FN_SKPOVR          ; routine FN-SKPOVR gets next valid character
        cp $29                  ; is it ')' end of arguments ?
        jr z, SF_R_BR_2         ; forward to SF-R-BR-2 if so.

; a comma separator has been encountered in the DEF FN argument list.

        push hl                 ; save position in DEF FN statement

        rst $18                 ; GET-CHAR from FN statement
        cp $2C                  ; is it ',' ?
        jr nz, REPORT_Q         ; forward to REPORT-Q if not
                                ; 'Parameter error'

        rst $20                 ; NEXT-CHAR in FN statement advances to next
                                ; argument.

        pop hl                  ; restore DEF FN pointer
        call FN_SKPOVR          ; routine FN-SKPOVR advances to corresponding
                                ; argument.

        jr SF_ARG_LP            ; back to SF-ARG-LP looping until all
                                ; arguments are passed into the DEF FN
                                ; hidden locations.


; ---

; the branch was here when all arguments passed.

;; SF-R-BR-2

SF_R_BR_2:
        push hl                 ; save location of ')' in DEF FN

        rst $18                 ; GET-CHAR gets next character in FN
        cp $29                  ; is it a ')' also ?
        jr z, SF_VALUE          ; forward to SF-VALUE if so.


;; REPORT-Q

REPORT_Q:
        rst $08                 ; ERROR-1
        defb $19                ; Error Report: Parameter error

;; SF-VALUE

SF_VALUE:
        pop de                  ; location of ')' in DEF FN to DE.
        ex de, hl               ; now to HL, FN ')' pointer to DE.
        ld (CH_ADD), hl         ; initialize CH_ADD to this value.

; At this point the start of the DEF FN argument list is on the machine stack.
; We also have to consider that this defined function may form part of the
; definition of another defined function (though not itself).
; As this defined function may be part of a hierarchy of defined functions
; currently being evaluated by recursive calls to SCANNING, then we have to
; preserve the original value of DEFADD and not assume that it is zero.

        ld hl, (DEFADD)         ; get original DEFADD address
        ex (sp), hl             ; swap with DEF FN address on stack ***
        ld (DEFADD), hl         ; set DEFADD to point to this argument list
                                ; during scanning.

        push de                 ; save FN ')' pointer.

        rst $20                 ; NEXT-CHAR advances past ')' in define

        rst $20                 ; NEXT-CHAR advances past '=' to expression

        call SCANNING           ; routine SCANNING evaluates but searches
                                ; initially for variables at DEFADD

        pop hl                  ; pop the FN ')' pointer
        ld (CH_ADD), hl         ; set CH_ADD to this
        pop hl                  ; pop the original DEFADD value
        ld (DEFADD), hl         ; and re-insert into DEFADD system variable.

        rst $20                 ; NEXT-CHAR advances to character after ')'
        jp S_CONT_2             ; to S-CONT-2 - to continue current
                                ; invocation of scanning


; --------------------
; Used to parse DEF FN
; --------------------
; e.g. DEF FN     s $ ( x )     =  b     $ (  TO  x  ) : REM exaggerated
;
; This routine is used 10 times to advance along a DEF FN statement
; skipping spaces and colour control codes. It is similar to NEXT-CHAR
; which is, at the same time, used to skip along the corresponding FN function
; except the latter has to deal with AT and TAB characters in string
; expressions. These cannot occur in a program area so this routine is
; simpler as both colour controls and their parameters are less than space.

;; FN-SKPOVR

FN_SKPOVR:
        inc hl                  ; increase pointer
        ld a, (hl)              ; fetch addressed character
        cp $21                  ; compare with space + 1
        jr c, FN_SKPOVR         ; back to FN-SKPOVR if less

        ret                     ; return pointing to a valid character.


; ---------
; LOOK-VARS
; ---------
;
;

;; LOOK-VARS

LOOK_VARS:
        set 6, (iy+FLAGS-IY0)   ; update FLAGS - presume numeric result

        rst $18                 ; GET-CHAR
        call ALPHA              ; routine ALPHA tests for A-Za-z
        jp nc, REPORT_C         ; jump to REPORT-C if not.
                                ; 'Nonsense in BASIC'

        push hl                 ; save pointer to first letter       ^1
        and $1F                 ; mask lower bits, 1 - 26 decimal     000xxxxx
        ld c, a                 ; store in C.

        rst $20                 ; NEXT-CHAR
        push hl                 ; save pointer to second character   ^2
        cp $28                  ; is it '(' - an array ?
        jr z, V_RUN_SYN         ; forward to V-RUN/SYN if so.

        set 6, c                ; set 6 signaling string if solitary  010
        cp $24                  ; is character a '$' ?
        jr z, V_STR_VAR         ; forward to V-STR-VAR

        set 5, c                ; signal numeric                       011
        call ALPHANUM           ; routine ALPHANUM sets carry if second
                                ; character is alphanumeric.
        jr nc, V_TEST_FN        ; forward to V-TEST-FN if just one character

; It is more than one character but re-test current character so that 6 reset
; This loop renders the similar loop at V-PASS redundant.

;; V-CHAR

V_CHAR:
        call ALPHANUM           ; routine ALPHANUM
        jr nc, V_RUN_SYN        ; to V-RUN/SYN when no more

        res 6, c                ; make long named type                 001

        rst $20                 ; NEXT-CHAR
        jr V_CHAR               ; loop back to V-CHAR


; ---


;; V-STR-VAR

V_STR_VAR:
        rst $20                 ; NEXT-CHAR advances past '$'
        res 6, (iy+FLAGS-IY0)   ; update FLAGS - signal string result.

;; V-TEST-FN

V_TEST_FN:
        ld a, ($5C0C)           ; load A with DEFADD_hi
        and a                   ; and test for zero.
        jr z, V_RUN_SYN         ; forward to V-RUN/SYN if a defined function
                                ; is not being evaluated.

; Note.

        call SYNTAX_Z           ; routine SYNTAX-Z
        jp nz, STK_F_ARG        ; JUMP to STK-F-ARG in runtime and then
                                ; back to this point if no variable found.

;; V-RUN/SYN

V_RUN_SYN:
        ld b, c                 ; save flags in B
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr nz, V_RUN            ; to V-RUN to look for the variable in runtime

; if checking syntax the letter is not returned

        ld a, c                 ; copy letter/flags to A
        and $E0                 ; and with 11100000 to get rid of the letter
        set 7, a                ; use spare bit to signal checking syntax.
        ld c, a                 ; and transfer to C.
        jr V_SYNTAX             ; forward to V-SYNTAX


; ---

; but in runtime search for the variable.

;; V-RUN

V_RUN:
        ld hl, (VARS)           ; set HL to start of variables from VARS

;; V-EACH

V_EACH:
        ld a, (hl)              ; get first character
        and $7F                 ; and with 01111111
                                ; ignoring bit 7 which distinguishes
                                ; arrays or for/next variables.

        jr z, V_80_BYTE         ; to V-80-BYTE if zero as must be 10000000
                                ; the variables end-marker.

        cp c                    ; compare with supplied value.
        jr nz, V_NEXT           ; forward to V-NEXT if no match.

        rla                     ; destructively test
        add a, a                ; bits 5 and 6 of A
                                ; jumping if bit 5 reset or 6 set

        jp p, V_FOUND_2         ; to V-FOUND-2  strings and arrays

        jr c, V_FOUND_2         ; to V-FOUND-2  simple and for next

; leaving long name variables.

        pop de                  ; pop pointer to 2nd. char
        push de                 ; save it again
        push hl                 ; save variable first character pointer

;; V-MATCHES

V_MATCHES:
        inc hl                  ; address next character in vars area

;; V-SPACES

V_SPACES:
        ldi a, (de)             ; pick up letter from prog area
                                ; and advance address
        cp $20                  ; is it a space
        jr z, V_SPACES          ; back to V-SPACES until non-space

        or $20                  ; convert to range 1 - 26.
        cp (hl)                 ; compare with addressed variables character
        jr z, V_MATCHES         ; loop back to V-MATCHES if a match on an
                                ; intermediate letter.

        or $80                  ; now set bit 7 as last character of long
                                ; names are inverted.
        cp (hl)                 ; compare again
        jr nz, V_GET_PTR        ; forward to V-GET-PTR if no match

; but if they match check that this is also last letter in prog area

        ld a, (de)              ; fetch next character
        call ALPHANUM           ; routine ALPHANUM sets carry if not alphanum
        jr nc, V_FOUND_1        ; forward to V-FOUND-1 with a full match.

;; V-GET-PTR

V_GET_PTR:
        pop hl                  ; pop saved pointer to char 1

;; V-NEXT

V_NEXT:
        push bc                 ; save flags
        call NEXT_ONE           ; routine NEXT-ONE gets next variable in DE
        ex de, hl               ; transfer to HL.
        pop bc                  ; restore the flags
        jr V_EACH               ; loop back to V-EACH
                                ; to compare each variable


; ---

;; V-80-BYTE

V_80_BYTE:
        set 7, b                ; will signal not found

; the branch was here when checking syntax

;; V-SYNTAX

V_SYNTAX:
        pop de                  ; discard the pointer to 2nd. character  v2
                                ; in BASIC line/workspace.

        rst $18                 ; GET-CHAR gets character after variable name.
        cp $28                  ; is it '(' ?
        jr z, V_PASS            ; forward to V-PASS
                                ; Note. could go straight to V-END ?

        set 5, b                ; signal not an array
        jr V_END                ; forward to V-END


; ---------------------------

; the jump was here when a long name matched and HL pointing to last character
; in variables area.

;; V-FOUND-1

V_FOUND_1:
        pop de                  ; discard pointer to first var letter

; the jump was here with all other matches HL points to first var char.

;; V-FOUND-2

V_FOUND_2:
        pop de                  ; discard pointer to 2nd prog char       v2
        pop de                  ; drop pointer to 1st prog char          v1
        push hl                 ; save pointer to last char in vars

        rst $18                 ; GET-CHAR

;; V-PASS

V_PASS:
        call ALPHANUM           ; routine ALPHANUM
        jr nc, V_END            ; forward to V-END if not

; but it never will be as we advanced past long-named variables earlier.

        rst $20                 ; NEXT-CHAR
        jr V_PASS               ; back to V-PASS


; ---

;; V-END

V_END:
        pop hl                  ; pop the pointer to first character in
                                ; BASIC line/workspace.
        rl b                    ; rotate the B register left
                                ; bit 7 to carry
        bit 6, b                ; test the array indicator bit.
        ret                     ; return


; -----------------------
; Stack function argument
; -----------------------
; This branch is taken from LOOK-VARS when a defined function is currently
; being evaluated.
; Scanning is evaluating the expression after the '=' and the variable
; found could be in the argument list to the left of the '=' or in the
; normal place after the program. Preference will be given to the former.
; The variable name to be matched is in C.

;; STK-F-ARG

STK_F_ARG:
        ld hl, (DEFADD)         ; set HL to DEFADD
        ld a, (hl)              ; load the first character
        cp $29                  ; is it ')' ?
        jp z, V_RUN_SYN         ; JUMP back to V-RUN/SYN, if so, as there are
                                ; no arguments.

; but proceed to search argument list of defined function first if not empty.

;; SFA-LOOP

SFA_LOOP:
        ld a, (hl)              ; fetch character again.
        or $60                  ; or with 01100000 presume a simple variable.
        ld b, a                 ; save result in B.
        inc hl                  ; address next location.
        ld a, (hl)              ; pick up byte.
        cp $0E                  ; is it the number marker ?
        jr z, SFA_CP_VR         ; forward to SFA-CP-VR if so.

; it was a string. White-space may be present but syntax has been checked.

        dec hl                  ; point back to letter.
        call FN_SKPOVR          ; routine FN-SKPOVR skips to the '$'
        inc hl                  ; now address the hidden marker.
        res 5, b                ; signal a string variable.

;; SFA-CP-VR

SFA_CP_VR:
        ld a, b                 ; transfer found variable letter to A.
        cp c                    ; compare with expected.
        jr z, SFA_MATCH         ; forward to SFA-MATCH with a match.

        inc hl                  ; step
        inc hl                  ; past
        inc hl                  ; the
        inc hl                  ; five
        inc hl                  ; bytes.

        call FN_SKPOVR          ; routine FN-SKPOVR skips to next character
        cp $29                  ; is it ')' ?
        jp z, V_RUN_SYN         ; jump back if so to V-RUN/SYN to look in
                                ; normal variables area.

        call FN_SKPOVR          ; routine FN-SKPOVR skips past the ','
                                ; all syntax has been checked and these
                                ; things can be taken as read.
        jr SFA_LOOP             ; back to SFA-LOOP while there are more
                                ; arguments.


; ---

;; SFA-MATCH

SFA_MATCH:
        bit 5, c                ; test if numeric
        jr nz, SFA_END          ; to SFA-END if so as will be stacked
                                ; by scanning

        inc hl                  ; point to start of string descriptor
        ld de, (STKEND)         ; set DE to STKEND
        call MOVE_FP            ; routine MOVE-FP puts parameters on stack.
        ex de, hl               ; new free location to HL.
        ld (STKEND), hl         ; use it to set STKEND system variable.

;; SFA-END

SFA_END:
        pop de                  ; discard
        pop de                  ; pointers.
        xor a                   ; clear carry flag.
        inc a                   ; and zero flag.
        ret                     ; return.


; ------------------------
; Stack variable component
; ------------------------
; This is called to evaluate a complex structure that has been found, in
; runtime, by LOOK-VARS in the variables area.
; In this case HL points to the initial letter, bits 7-5
; of which indicate the type of variable.
; 010 - simple string, 110 - string array, 100 - array of numbers.
;
; It is called from CLASS-01 when assigning to a string or array including
; a slice.
; It is called from SCANNING to isolate the required part of the structure.
;
; An important part of the runtime process is to check that the number of
; dimensions of the variable match the number of subscripts supplied in the
; BASIC line.
;
; If checking syntax,
; the B register, which counts dimensions is set to zero (256) to allow
; the loop to continue till all subscripts are checked. While doing this it
; is reading dimension sizes from some arbitrary area of memory. Although
; these are meaningless it is of no concern as the limit is never checked by
; int-exp during syntax checking.
;
; The routine is also called from the syntax path of DIM command to check the
; syntax of both string and numeric arrays definitions except that bit 6 of C
; is reset so both are checked as numeric arrays. This ruse avoids a terminal
; slice being accepted as part of the DIM command.
; All that is being checked is that there are a valid set of comma-separated
; expressions before a terminal ')', although, as above, it will still go
; through the motions of checking dummy dimension sizes.

;; STK-VAR

STK_VAR:
        xor a                   ; clear A
        ld b, a                 ; and B, the syntax dimension counter (256)
        bit 7, c                ; checking syntax ?
        jr nz, SV_COUNT         ; forward to SV-COUNT if so.

; runtime evaluation.

        bit 7, (hl)             ; will be reset if a simple string.
        jr nz, SV_ARRAYS        ; forward to SV-ARRAYS otherwise

        inc a                   ; set A to 1, simple string.

;; SV-SIMPLE$

SV_SIMPLE_:
        inc hl                  ; address length low
        ldi bc, (hl)            ; place in C
                                ; address length high
                                ; place in B
                                ; address start of string
        ex de, hl               ; DE = start now.
        call STK_STO__          ; routine STK-STO-$ stacks string parameters
                                ; DE start in variables area,
                                ; BC length, A=1 simple string

; the only thing now is to consider if a slice is required.

        rst $18                 ; GET-CHAR puts character at CH_ADD in A
        jp SV_SLICE_            ; jump forward to SV-SLICE? to test for '('


; --------------------------------------------------------

; the branch was here with string and numeric arrays in runtime.

;; SV-ARRAYS

SV_ARRAYS:
        inc hl                  ; step past
        inc hl                  ; the total length
        inc hl                  ; to address Number of dimensions.
        ld b, (hl)              ; transfer to B overwriting zero.
        bit 6, c                ; a numeric array ?
        jr z, SV_PTR            ; forward to SV-PTR with numeric arrays

        dec b                   ; ignore the final element of a string array
                                ; the fixed string size.

        jr z, SV_SIMPLE_        ; back to SV-SIMPLE$ if result is zero as has
                                ; been created with DIM a$(10) for instance
                                ; and can be treated as a simple string.

; proceed with multi-dimensioned string arrays in runtime.

        ex de, hl               ; save pointer to dimensions in DE

        rst $18                 ; GET-CHAR looks at the BASIC line
        cp $28                  ; is character '(' ?
        jr nz, REPORT_3         ; to REPORT-3 if not
                                ; 'Subscript wrong'

        ex de, hl               ; dimensions pointer to HL to synchronize
                                ; with next instruction.

; runtime numeric arrays path rejoins here.

;; SV-PTR

SV_PTR:
        ex de, hl               ; save dimension pointer in DE
        jr SV_COUNT             ; forward to SV-COUNT with true no of dims
                                ; in B. As there is no initial comma the
                                ; loop is entered at the midpoint.


; ----------------------------------------------------------
; the dimension counting loop which is entered at mid-point.

;; SV-COMMA

SV_COMMA:
        push hl                 ; save counter

        rst $18                 ; GET-CHAR

        pop hl                  ; pop counter
        cp $2C                  ; is character ',' ?
        jr z, SV_LOOP           ; forward to SV-LOOP if so

; in runtime the variable definition indicates a comma should appear here

        bit 7, c                ; checking syntax ?
        jr z, REPORT_3          ; forward to REPORT-3 if not
                                ; 'Subscript error'

; proceed if checking syntax of an array?

        bit 6, c                ; array of strings
        jr nz, SV_CLOSE         ; forward to SV-CLOSE if so

; an array of numbers.

        cp $29                  ; is character ')' ?
        jr nz, SV_RPT_C         ; forward to SV-RPT-C if not
                                ; 'Nonsense in BASIC'

        rst $20                 ; NEXT-CHAR moves CH-ADD past the statement
        ret                     ; return ->


; ---

; the branch was here with an array of strings.

;; SV-CLOSE

SV_CLOSE:
        cp $29                  ; as above ')' could follow the expression
        jr z, SV_DIM            ; forward to SV-DIM if so

        cp $CC                  ; is it 'TO' ?
        jr nz, SV_RPT_C         ; to SV-RPT-C with anything else
                                ; 'Nonsense in BASIC'

; now backtrack CH_ADD to set up for slicing routine.
; Note. in a BASIC line we can safely backtrack to a colour parameter.

;; SV-CH-ADD

SV_CH_ADD:
        rst $18                 ; GET-CHAR
        dec hl                  ; backtrack HL
        ld (CH_ADD), hl         ; to set CH_ADD up for slicing routine
        jr SV_SLICE             ; forward to SV-SLICE and make a return
                                ; when all slicing complete.


; ----------------------------------------
; -> the mid-point entry point of the loop

;; SV-COUNT

SV_COUNT:
        ld hl, $0000            ; initialize data pointer to zero.

;; SV-LOOP

SV_LOOP:
        push hl                 ; save the data pointer.

        rst $20                 ; NEXT-CHAR in BASIC area points to an
                                ; expression.

        pop hl                  ; restore the data pointer.
        ld a, c                 ; transfer name/type to A.
        cp $C0                  ; is it 11000000 ?
                                ; Note. the letter component is absent if
                                ; syntax checking.
        jr nz, SV_MULT          ; forward to SV-MULT if not an array of
                                ; strings.

; proceed to check string arrays during syntax.

        rst $18                 ; GET-CHAR
        cp $29                  ; ')'  end of subscripts ?
        jr z, SV_DIM            ; forward to SV-DIM to consider further slice

        cp $CC                  ; is it 'TO' ?
        jr z, SV_CH_ADD         ; back to SV-CH-ADD to consider a slice.
                                ; (no need to repeat get-char at L29E0)

; if neither, then an expression is required so rejoin runtime loop ??
; registers HL and DE only point to somewhere meaningful in runtime so 
; comments apply to that situation.

;; SV-MULT

SV_MULT:
        push bc                 ; save dimension number.
        push hl                 ; push data pointer/rubbish.
                                ; DE points to current dimension.
        call DE__DE_1_          ; routine DE,(DE+1) gets next dimension in DE
                                ; and HL points to it.
        ex (sp), hl             ; dim pointer to stack, data pointer to HL (*)
        ex de, hl               ; data pointer to DE, dim size to HL.

        call INT_EXP1           ; routine INT-EXP1 checks integer expression
                                ; and gets result in BC in runtime.
        jr c, REPORT_3          ; to REPORT-3 if > HL
                                ; 'Subscript out of range'

        dec bc                  ; adjust returned result from 1-x to 0-x
        call GET_HL_DE          ; routine GET-HL*DE multiplies data pointer by
                                ; dimension size.
        add hl, bc              ; add the integer returned by expression.
        pop de                  ; pop the dimension pointer.                              ***
        pop bc                  ; pop dimension counter.
        djnz SV_COMMA           ; back to SV-COMMA if more dimensions
                                ; Note. during syntax checking, unless there
                                ; are more than 256 subscripts, the branch
                                ; back to SV-COMMA is always taken.

        bit 7, c                ; are we checking syntax ?
                                ; then we've got a joker here.

;; SV-RPT-C

SV_RPT_C:
        jr nz, SL_RPT_C         ; forward to SL-RPT-C if so
                                ; 'Nonsense in BASIC'
                                ; more than 256 subscripts in BASIC line.

; but in runtime the number of subscripts are at least the same as dims

        push hl                 ; save data pointer.
        bit 6, c                ; is it a string array ?
        jr nz, SV_ELEM_         ; forward to SV-ELEM$ if so.

; a runtime numeric array subscript.

        ld bc, de               ; register DE has advanced past all dimensions
                                ; and points to start of data in variable.
                                ; transfer it to BC.

        rst $18                 ; GET-CHAR checks BASIC line
        cp $29                  ; must be a ')' ?
        jr z, SV_NUMBER         ; skip to SV-NUMBER if so

; else more subscripts in BASIC line than the variable definition.

;; REPORT-3

REPORT_3:
        rst $08                 ; ERROR-1
        defb $02                ; Error Report: Subscript wrong

; continue if subscripts matched the numeric array.

;; SV-NUMBER

SV_NUMBER:
        rst $20                 ; NEXT-CHAR moves CH_ADD to next statement
                                ; - finished parsing.

        pop hl                  ; pop the data pointer.
        ld de, $0005            ; each numeric element is 5 bytes.
        call GET_HL_DE          ; routine GET-HL*DE multiplies.
        add hl, bc              ; now add to start of data in the variable.

        ret                     ; return with HL pointing at the numeric
                                ; array subscript.                       ->


; ---------------------------------------------------------------

; the branch was here for string subscripts when the number of subscripts
; in the BASIC line was one less than in variable definition.

;; SV-ELEM$

SV_ELEM_:
        call DE__DE_1_          ; routine DE,(DE+1) gets final dimension
                                ; the length of strings in this array.
        ex (sp), hl             ; start pointer to stack, data pointer to HL.
        call GET_HL_DE          ; routine GET-HL*DE multiplies by element
                                ; size.
        pop bc                  ; the start of data pointer is added
        add hl, bc              ; in - now points to location before.
        inc hl                  ; point to start of required string.
        ld bc, de               ; transfer the length (final dimension size)
                                ; from DE to BC.
        ex de, hl               ; put start in DE.
        call STK_ST_0           ; routine STK-ST-0 stores the string parameters
                                ; with A=0 - a slice or subscript.

; now check that there were no more subscripts in the BASIC line.

        rst $18                 ; GET-CHAR
        cp $29                  ; is it ')' ?
        jr z, SV_DIM            ; forward to SV-DIM to consider a separate
                                ; subscript or/and a slice.

        cp $2C                  ; a comma is allowed if the final subscript
                                ; is to be sliced e.g. a$(2,3,4 TO 6).
        jr nz, REPORT_3         ; to REPORT-3 with anything else
                                ; 'Subscript error'

;; SV-SLICE

SV_SLICE:
        call SLICING            ; routine SLICING slices the string.

; but a slice of a simple string can itself be sliced.

;; SV-DIM

SV_DIM:
        rst $20                 ; NEXT-CHAR

;; SV-SLICE?

SV_SLICE_:
        cp $28                  ; is character '(' ?
        jr z, SV_SLICE          ; loop back if so to SV-SLICE

        res 6, (iy+FLAGS-IY0)   ; update FLAGS  - Signal string result
        ret                     ; and return.


; ---

; The above section deals with the flexible syntax allowed.
; DIM a$(3,3,10) can be considered as two dimensional array of ten-character
; strings or a 3-dimensional array of characters.
; a$(1,1) will return a 10-character string as will a$(1,1,1 TO 10)
; a$(1,1,1) will return a single character.
; a$(1,1) (1 TO 6) is the same as a$(1,1,1 TO 6)
; A slice can itself be sliced ad infinitum
; b$ () () () () () () (2 TO 10) (2 TO 9) (3) is the same as b$(5)



; -------------------------
; Handle slicing of strings
; -------------------------
; The syntax of string slicing is very natural and it is as well to reflect
; on the permutations possible.
; a$() and a$( TO ) indicate the entire string although just a$ would do
; and would avoid coming here.
; h$(16) indicates the single character at position 16.
; a$( TO 32) indicates the first 32 characters.
; a$(257 TO) indicates all except the first 256 characters.
; a$(19000 TO 19999) indicates the thousand characters at position 19000.
; Also a$(9 TO 5) returns a null string not an error.
; This enables a$(2 TO) to return a null string if the passed string is
; of length zero or 1.
; A string expression in brackets can be sliced. e.g. (STR$ PI) (3 TO )
; We arrived here from SCANNING with CH-ADD pointing to the initial '('
; or from above.

;; SLICING

SLICING:
        call SYNTAX_Z           ; routine SYNTAX-Z
        call nz, STK_FETCH      ; routine STK-FETCH fetches parameters of
                                ; string at runtime, start in DE, length
                                ; in BC. This could be an array subscript.

        rst $20                 ; NEXT-CHAR
        cp $29                  ; is it ')' ?     e.g. a$()
        jr z, SL_STORE          ; forward to SL-STORE to store entire string.

        push de                 ; else save start address of string

        xor a                   ; clear accumulator to use as a running flag.
        push af                 ; and save on stack before any branching.

        push bc                 ; save length of string to be sliced.
        ld de, $0001            ; default the start point to position 1.

        rst $18                 ; GET-CHAR

        pop hl                  ; pop length to HL as default end point
                                ; and limit.

        cp $CC                  ; is it 'TO' ?    e.g. a$( TO 10000)
        jr z, SL_SECOND         ; to SL-SECOND to evaluate second parameter.

        pop af                  ; pop the running flag.

        call INT_EXP2           ; routine INT-EXP2 fetches first parameter.

        push af                 ; save flag (will be $FF if parameter>limit)

        ld de, bc               ; transfer the start
                                ; to DE overwriting 0001.
        push hl                 ; save original length.

        rst $18                 ; GET-CHAR
        pop hl                  ; pop the limit length.
        cp $CC                  ; is it 'TO' after a start ?
        jr z, SL_SECOND         ; to SL-SECOND to evaluate second parameter

        cp $29                  ; is it ')' ?       e.g. a$(365)

;; SL-RPT-C

SL_RPT_C:
        jp nz, REPORT_C         ; jump to REPORT-C with anything else
                                ; 'Nonsense in BASIC'

        ld hl, de               ; copy start
                                ; to end - just a one character slice.
        jr SL_DEFINE            ; forward to SL-DEFINE.


; ---------------------

;; SL-SECOND

SL_SECOND:
        push hl                 ; save limit length.

        rst $20                 ; NEXT-CHAR

        pop hl                  ; pop the length.

        cp $29                  ; is character ')' ?        e.g. a$(7 TO )
        jr z, SL_DEFINE         ; to SL-DEFINE using length as end point.

        pop af                  ; else restore flag.
        call INT_EXP2           ; routine INT-EXP2 gets second expression.

        push af                 ; save the running flag.

        rst $18                 ; GET-CHAR

        ld hl, bc               ; transfer second parameter
                                ; to HL.              e.g. a$(42 to 99)
        cp $29                  ; is character a ')' ?
        jr nz, SL_RPT_C         ; to SL-RPT-C if not
                                ; 'Nonsense in BASIC'

; we now have start in DE and an end in HL.

;; SL-DEFINE

SL_DEFINE:
        pop af                  ; pop the running flag.
        ex (sp), hl             ; put end point on stack, start address to HL
        add hl, de              ; add address of string to the start point.
        dec hl                  ; point to first character of slice.
        ex (sp), hl             ; start address to stack, end point to HL (*)
        and a                   ; prepare to subtract.
        sbc hl, de              ; subtract start point from end point.
        ld bc, $0000            ; default the length result to zero.
        jr c, SL_OVER           ; forward to SL-OVER if start > end.

        inc hl                  ; increment the length for inclusive byte.

        and a                   ; now test the running flag.
        jp m, REPORT_3          ; jump back to REPORT-3 if $FF.
                                ; 'Subscript out of range'

        ld bc, hl               ; transfer the length
                                ; to BC.

;; SL-OVER

SL_OVER:
        pop de                  ; restore start address from machine stack ***
        res 6, (iy+FLAGS-IY0)   ; update FLAGS - signal string result for
                                ; syntax.

;; SL-STORE

SL_STORE:
        call SYNTAX_Z           ; routine SYNTAX-Z  (UNSTACK-Z?)
        ret z                   ; return if checking syntax.
                                ; but continue to store the string in runtime.

; ------------------------------------
; other than from above, this routine is called from STK-VAR to stack
; a known string array element.
; ------------------------------------

;; STK-ST-0

STK_ST_0:
        xor a                   ; clear to signal a sliced string or element.

; -------------------------
; this routine is called from chr$, scrn$ etc. to store a simple string result.
; --------------------------

;; STK-STO-$

STK_STO__:
        res 6, (iy+FLAGS-IY0)   ; update FLAGS - signal string result.
                                ; and continue to store parameters of string.

; ---------------------------------------
; Pass five registers to calculator stack
; ---------------------------------------
; This subroutine puts five registers on the calculator stack.

;; STK-STORE

STK_STORE:
        push bc                 ; save two registers
        call TEST_5_SP          ; routine TEST-5-SP checks room and puts 5
                                ; in BC.
        pop bc                  ; fetch the saved registers.
        ld hl, (STKEND)         ; make HL point to first empty location STKEND
        ldi (hl), a             ; place the 5 registers.
        ldi (hl), de
        ldi (hl), bc
        ld (STKEND), hl         ; update system variable STKEND.
        ret                     ; and return.


; -------------------------------------------
; Return result of evaluating next expression
; -------------------------------------------
; This clever routine is used to check and evaluate an integer expression
; which is returned in BC, setting A to $FF, if greater than a limit supplied
; in HL. It is used to check array subscripts, parameters of a string slice
; and the arguments of the DIM command. In the latter case, the limit check
; is not required and H is set to $FF. When checking optional string slice
; parameters, it is entered at the second entry point so as not to disturb
; the running flag A, which may be $00 or $FF from a previous invocation.

;; INT-EXP1

INT_EXP1:
        xor a                   ; set result flag to zero.

; -> The entry point is here if A is used as a running flag.

;; INT-EXP2

INT_EXP2:
        push de                 ; preserve DE register throughout.
        push hl                 ; save the supplied limit.
        push af                 ; save the flag.

        call EXPT_1NUM          ; routine EXPT-1NUM evaluates expression
                                ; at CH_ADD returning if numeric result,
                                ; with value on calculator stack.

        pop af                  ; pop the flag.
        call SYNTAX_Z           ; routine SYNTAX-Z
        jr z, I_RESTORE         ; forward to I-RESTORE if checking syntax so
                                ; avoiding a comparison with supplied limit.

        push af                 ; save the flag.

        call FIND_INT2          ; routine FIND-INT2 fetches value from
                                ; calculator stack to BC producing an error
                                ; if too high.

        pop de                  ; pop the flag to D.
        ld a, b                 ; test value for zero and reject
        or c                    ; as arrays and strings begin at 1.
        scf                     ; set carry flag.
        jr z, I_CARRY           ; forward to I-CARRY if zero.

        pop hl                  ; restore the limit.
        push hl                 ; and save.
        and a                   ; prepare to subtract.
        sbc hl, bc              ; subtract value from limit.

;; I-CARRY

I_CARRY:
        ld a, d                 ; move flag to accumulator $00 or $FF.
        sbc a, $00              ; will set to $FF if carry set.

;; I-RESTORE

I_RESTORE:
        pop hl                  ; restore the limit.
        pop de                  ; and DE register.
        ret                     ; return.



; -----------------------
; LD DE,(DE+1) Subroutine
; -----------------------
; This routine just loads the DE register with the contents of the two
; locations following the location addressed by DE.
; It is used to step along the 16-bit dimension sizes in array definitions.
; Note. Such code is made into subroutines to make programs easier to
; write and it would use less space to include the five instructions in-line.
; However, there are so many exchanges going on at the places this is invoked
; that to implement it in-line would make the code hard to follow.
; It probably had a zippier label though as the intention is to simplify the
; program.

;; DE,(DE+1)

DE__DE_1_:
        ex de, hl
        inc hl
        ldi e, (hl)
        ld d, (hl)
        ret


; -------------------
; HL=HL*DE Subroutine
; -------------------
; This routine calls the mathematical routine to multiply HL by DE in runtime.
; It is called from STK-VAR and from DIM. In the latter case syntax is not
; being checked so the entry point could have been at the second CALL
; instruction to save a few clock-cycles.

;; GET-HL*DE

GET_HL_DE:
        call SYNTAX_Z           ; routine SYNTAX-Z.
        ret z                   ; return if checking syntax.

        call HL_HL_DE           ; routine HL-HL*DE.
        jp c, REPORT_4          ; jump back to REPORT-4 if over 65535.

        ret                     ; else return with 16-bit result in HL.


; -----------------
; THE 'LET' COMMAND
; -----------------
; Sinclair BASIC adheres to the ANSI-78 standard and a LET is required in
; assignments e.g. LET a = 1  :   LET h$ = "hat".
;
; Long names may contain spaces but not colour controls (when assigned).
; a substring can appear to the left of the equals sign.

; An earlier mathematician Lewis Carroll may have been pleased that
; 10 LET Babies cannot manage crocodiles = Babies are illogical AND
;    Nobody is despised who can manage a crocodile AND Illogical persons
;    are despised
; does not give the 'Nonsense..' error if the three variables exist.
; I digress.

;; LET

LET:
        ld hl, (DEST)           ; fetch system variable DEST to HL.
        bit 1, (iy+FLAGX-IY0)   ; test FLAGX - handling a new variable ?
        jr z, L_EXISTS          ; forward to L-EXISTS if not.

; continue for a new variable. DEST points to start in BASIC line.
; from the CLASS routines.

        ld bc, $0005            ; assume numeric and assign an initial 5 bytes

;; L-EACH-CH

L_EACH_CH:
        inc bc                  ; increase byte count for each relevant
                                ; character

;; L-NO-SP

L_NO_SP:
        inc hl                  ; increase pointer.
        ld a, (hl)              ; fetch character.
        cp $20                  ; is it a space ?
        jr z, L_NO_SP           ; back to L-NO-SP is so.

        jr nc, L_TEST_CH        ; forward to L-TEST-CH if higher.

        cp $10                  ; is it $00 - $0F ?
        jr c, L_SPACES          ; forward to L-SPACES if so.

        cp $16                  ; is it $16 - $1F ?
        jr nc, L_SPACES         ; forward to L-SPACES if so.

; it was $10 - $15  so step over a colour code.

        inc hl                  ; increase pointer.
        jr L_NO_SP              ; loop back to L-NO-SP.


; ---

; the branch was to here if higher than space.

;; L-TEST-CH

L_TEST_CH:
        call ALPHANUM           ; routine ALPHANUM sets carry if alphanumeric
        jr c, L_EACH_CH         ; loop back to L-EACH-CH for more if so.

        cp $24                  ; is it '$' ?
        jp z, L_NEW_            ; jump forward if so, to L-NEW$
                                ; with a new string.

;; L-SPACES

L_SPACES:
        ld a, c                 ; save length lo in A.
        ld hl, (E_LINE)         ; fetch E_LINE to HL.
        dec hl                  ; point to location before, the variables
                                ; end-marker.
        call MAKE_ROOM          ; routine MAKE-ROOM creates BC spaces
                                ; for name and numeric value.
        inc hl                  ; advance to first new location.
        inc hl                  ; then to second.
        ex de, hl               ; set DE to second location.
        push de                 ; save this pointer.
        ld hl, (DEST)           ; reload HL with DEST.
        dec de                  ; point to first.
        sub $06                 ; subtract six from length_lo.
        ld b, a                 ; save count in B.
        jr z, L_SINGLE          ; forward to L-SINGLE if it was just
                                ; one character.

; HL points to start of variable name after 'LET' in BASIC line.

;; L-CHAR

L_CHAR:
        inc hl                  ; increase pointer.
        ld a, (hl)              ; pick up character.
        cp $21                  ; is it space or higher ?
        jr c, L_CHAR            ; back to L-CHAR with space and less.

        or $20                  ; make variable lower-case.
        inc de                  ; increase destination pointer.
        ld (de), a              ; and load to edit line.
        djnz L_CHAR             ; loop back to L-CHAR until B is zero.

        or $80                  ; invert the last character.
        ld (de), a              ; and overwrite that in edit line.

; now consider first character which has bit 6 set

        ld a, $C0               ; set A 11000000 is xor mask for a long name.
                                ; %101      is xor/or  result

; single character numerics rejoin here with %00000000 in mask.
;                                            %011      will be xor/or result

;; L-SINGLE

L_SINGLE:
        ld hl, (DEST)           ; fetch DEST - HL addresses first character.
        xor (hl)                ; apply variable type indicator mask (above).
        or $20                  ; make lowercase - set bit 5.
        pop hl                  ; restore pointer to 2nd character.
        call L_FIRST            ; routine L-FIRST puts A in first character.
                                ; and returns with HL holding
                                ; new E_LINE-1  the $80 vars end-marker.

;; L-NUMERIC

L_NUMERIC:
        push hl                 ; save the pointer.

; the value of variable is deleted but remains after calculator stack.

        rst $28                 ; ; FP-CALC
        defb $02                ; ;delete      ; delete variable value
        defb $38                ; ;end-calc

; DE (STKEND) points to start of value.

        pop hl                  ; restore the pointer.
        ld bc, $0005            ; start of number is five bytes before.
        and a                   ; prepare for true subtraction.
        sbc hl, bc              ; HL points to start of value.
        jr L_ENTER              ; forward to L-ENTER  ==>


; ---


; the jump was to here if the variable already existed.

;; L-EXISTS

L_EXISTS:
        bit 6, (iy+FLAGS-IY0)   ; test FLAGS - numeric or string result ?
        jr z, L_DELETE_         ; skip forward to L-DELETE$   -*->
                                ; if string result.

; A numeric variable could be simple or an array element.
; They are treated the same and the old value is overwritten.

        ld de, $0006            ; six bytes forward points to loc past value.
        add hl, de              ; add to start of number.
        jr L_NUMERIC            ; back to L-NUMERIC to overwrite value.


; ---

; -*-> the branch was here if a string existed.

;; L-DELETE$

L_DELETE_:
        ld hl, (DEST)           ; fetch DEST to HL.
                                ; (still set from first instruction)
        ld bc, (STRLEN)         ; fetch STRLEN to BC.
        bit 0, (iy+FLAGX-IY0)   ; test FLAGX - handling a complete simple
                                ; string ?
        jr nz, L_ADD_           ; forward to L-ADD$ if so.

; must be a string array or a slice in workspace.
; Note. LET a$(3 TO 6) = h$   will assign "hat " if h$ = "hat"
;                                  and    "hats" if h$ = "hatstand".
;
; This is known as Procrustean lengthening and shortening after a
; character Procrustes in Greek legend who made travellers sleep in his bed,
; cutting off their feet or stretching them so they fitted the bed perfectly.
; The bloke was hatstand and slain by Theseus.

        ld a, b                 ; test if length
        or c                    ; is zero and
        ret z                   ; return if so.

        push hl                 ; save pointer to start.

        rst $30                 ; BC-SPACES creates room.
        push de                 ; save pointer to first new location.
        push bc                 ; and length            (*)
        ld de, hl               ; set DE to point to last location.
        inc hl                  ; set HL to next location.
        ld (hl), $20            ; place a space there.
        lddr                    ; copy bytes filling with spaces.

        push hl                 ; save pointer to start.
        call STK_FETCH          ; routine STK-FETCH start to DE,
                                ; length to BC.
        pop hl                  ; restore the pointer.
        ex (sp), hl             ; (*) length to HL, pointer to stack.
        and a                   ; prepare for true subtraction.
        sbc hl, bc              ; subtract old length from new.
        add hl, bc              ; and add back.
        jr nc, L_LENGTH         ; forward if it fits to L-LENGTH.

        ld bc, hl               ; otherwise set
                                ; length to old length.
                                ; "hatstand" becomes "hats"

;; L-LENGTH

L_LENGTH:
        ex (sp), hl             ; (*) length to stack, pointer to HL.
        ex de, hl               ; pointer to DE, start of string to HL.
        ld a, b                 ; is the length zero ?
        or c
        jr z, L_IN_W_S          ; forward to L-IN-W/S if so
                                ; leaving prepared spaces.

        ldir                    ; else copy bytes overwriting some spaces.

;; L-IN-W/S

L_IN_W_S:
        pop bc                  ; pop the new length.  (*)
        pop de                  ; pop pointer to new area.
        pop hl                  ; pop pointer to variable in assignment.
                                ; and continue copying from workspace
                                ; to variables area.

; ==> branch here from  L-NUMERIC

;; L-ENTER

L_ENTER:
        ex de, hl               ; exchange pointers HL=STKEND DE=end of vars.
        ld a, b                 ; test the length
        or c                    ; and make a
        ret z                   ; return if zero (strings only).

        push de                 ; save start of destination.
        ldir                    ; copy bytes.
        pop hl                  ; address the start.
        ret                     ; and return.


; ---

; the branch was here from L-DELETE$ if an existing simple string.
; register HL addresses start of string in variables area.

;; L-ADD$

L_ADD_:
        dec hl                  ; point to high byte of length.
        dec hl                  ; to low byte.
        dec hl                  ; to letter.
        ld a, (hl)              ; fetch masked letter to A.
        push hl                 ; save the pointer on stack.
        push bc                 ; save new length.
        call L_STRING           ; routine L-STRING adds new string at end
                                ; of variables area.
                                ; if no room we still have old one.
        pop bc                  ; restore length.
        pop hl                  ; restore start.
        inc bc                  ; increase
        inc bc                  ; length by three
        inc bc                  ; to include character and length bytes.
        jp RECLAIM_2            ; jump to indirect exit via RECLAIM-2
                                ; deleting old version and adjusting pointers.


; ---

; the jump was here with a new string variable.

;; L-NEW$

L_NEW_:
        ld a, $DF               ; indicator mask %11011111 for
                                ;                %010xxxxx will be result
        ld hl, (DEST)           ; address DEST first character.
        and (hl)                ; combine mask with character.

;; L-STRING

L_STRING:
        push af                 ; save first character and mask.
        call STK_FETCH          ; routine STK-FETCH fetches parameters of
                                ; the string.
        ex de, hl               ; transfer start to HL.
        add hl, bc              ; add to length.
        push bc                 ; save the length.
        dec hl                  ; point to end of string.
        ld (DEST), hl           ; save pointer in DEST.
                                ; (updated by POINTERS if in workspace)
        inc bc                  ; extra byte for letter.
        inc bc                  ; two bytes
        inc bc                  ; for the length of string.
        ld hl, (E_LINE)         ; address E_LINE.
        dec hl                  ; now end of VARS area.
        call MAKE_ROOM          ; routine MAKE-ROOM makes room for string.
                                ; updating pointers including DEST.
        ld hl, (DEST)           ; pick up pointer to end of string from DEST.
        pop bc                  ; restore length from stack.
        push bc                 ; and save again on stack.
        inc bc                  ; add a byte.
        lddr                    ; copy bytes from end to start.
        ex de, hl               ; HL addresses length low
        inc hl                  ; increase to address high byte
        pop bc                  ; restore length to BC
        ldd (hl), b             ; insert high byte
                                ; address low byte location
        ld (hl), c              ; insert that byte
        pop af                  ; restore character and mask

;; L-FIRST

L_FIRST:
        dec hl                  ; address variable name
        ld (hl), a              ; and insert character.
        ld hl, (E_LINE)         ; load HL with E_LINE.
        dec hl                  ; now end of VARS area.
        ret                     ; return


; ------------------------------------
; Get last value from calculator stack
; ------------------------------------
;
;

;; STK-FETCH

STK_FETCH:
        ld hl, (STKEND)         ; STKEND
        dec hl
        ldd b, (hl)
        ldd c, (hl)
        ldd d, (hl)
        ldd e, (hl)
        ld a, (hl)
        ld (STKEND), hl         ; STKEND
        ret


; ------------------
; Handle DIM command
; ------------------
; e.g. DIM a(2,3,4,7): DIM a$(32) : DIM b$(20,2,768) : DIM c$(20000)
; the only limit to dimensions is memory so, for example,
; DIM a(2,2,2,2,2,2,2,2,2,2,2,2,2) is possible and creates a multi-
; dimensional array of zeros. String arrays are initialized to spaces.
; It is not possible to erase an array, but it can be re-dimensioned to
; a minimal size of 1, after use, to free up memory.

;; DIM

DIM:
        call LOOK_VARS          ; routine LOOK-VARS

;; D-RPORT-C

D_RPORT_C:
        jp nz, REPORT_C         ; jump to REPORT-C if a long-name variable.
                                ; DIM lottery numbers(49) doesn't work.

        call SYNTAX_Z           ; routine SYNTAX-Z
        jr nz, D_RUN            ; forward to D-RUN in runtime.

        res 6, c                ; signal 'numeric' array even if string as
                                ; this simplifies the syntax checking.

        call STK_VAR            ; routine STK-VAR checks syntax.
        call CHECK_END          ; routine CHECK-END performs early exit ->

; the branch was here in runtime.

;; D-RUN

D_RUN:
        jr c, D_LETTER          ; skip to D-LETTER if variable did not exist.
                                ; else reclaim the old one.

        push bc                 ; save type in C.
        call NEXT_ONE           ; routine NEXT-ONE find following variable
                                ; or position of $80 end-marker.
        call RECLAIM_2          ; routine RECLAIM-2 reclaims the
                                ; space between.
        pop bc                  ; pop the type.

;; D-LETTER

D_LETTER:
        set 7, c                ; signal array.
        ld b, $00               ; initialize dimensions to zero and
        push bc                 ; save with the type.
        ld hl, $0001            ; make elements one character presuming string
        bit 6, c                ; is it a string ?
        jr nz, D_SIZE           ; forward to D-SIZE if so.

        ld l, $05               ; make elements 5 bytes as is numeric.

;; D-SIZE

D_SIZE:
        ex de, hl               ; save the element size in DE.

; now enter a loop to parse each of the integers in the list.

;; D-NO-LOOP

D_NO_LOOP:
        rst $20                 ; NEXT-CHAR
        ld h, $FF               ; disable limit check by setting HL high
        call INT_EXP1           ; routine INT-EXP1
        jp c, REPORT_3          ; to REPORT-3 if > 65280 and then some
                                ; 'Subscript out of range'

        pop hl                  ; pop dimension counter, array type
        push bc                 ; save dimension size                     ***
        inc h                   ; increment the dimension counter
        push hl                 ; save the dimension counter
        ld hl, bc               ; transfer size
                                ; to HL
        call GET_HL_DE          ; routine GET-HL*DE multiplies dimension by
                                ; running total of size required initially
                                ; 1 or 5.
        ex de, hl               ; save running total in DE

        rst $18                 ; GET-CHAR
        cp $2C                  ; is it ',' ?
        jr z, D_NO_LOOP         ; loop back to D-NO-LOOP until all dimensions
                                ; have been considered

; when loop complete continue.

        cp $29                  ; is it ')' ?
        jr nz, D_RPORT_C        ; to D-RPORT-C with anything else
                                ; 'Nonsense in BASIC'


        rst $20                 ; NEXT-CHAR advances to next statement/CR

        pop bc                  ; pop dimension counter/type
        ld a, c                 ; type to A

; now calculate space required for array variable

        ld l, b                 ; dimensions to L since these require 16 bits
                                ; then this value will be doubled
        ld h, $00               ; set high byte to zero

; another four bytes are required for letter(1), total length(2), number of
; dimensions(1) but since we have yet to double allow for two

        inc hl                  ; increment
        inc hl                  ; increment

        add hl, hl              ; now double giving 4 + dimensions * 2

        add hl, de              ; add to space required for array contents

        jp c, REPORT_4          ; to REPORT-4 if > 65535
                                ; 'Out of memory'

        push de                 ; save data space
        push bc                 ; save dimensions/type
        push hl                 ; save total space
        ld bc, hl               ; total space
                                ; to BC
        ld hl, (E_LINE)         ; address E_LINE - first location after
                                ; variables area
        dec hl                  ; point to location before - the $80 end-marker
        call MAKE_ROOM          ; routine MAKE-ROOM creates the space if
                                ; memory is available.

        inc hl                  ; point to first new location and
        ld (hl), a              ; store letter/type

        pop bc                  ; pop total space
        dec bc                  ; exclude name
        dec bc                  ; exclude the 16-bit
        dec bc                  ; counter itself
        inc hl                  ; point to next location the 16-bit counter
        ldi (hl), c             ; insert low byte
                                ; address next
        ld (hl), b              ; insert high byte

        pop bc                  ; pop the number of dimensions.
        ld a, b                 ; dimensions to A
        inc hl                  ; address next
        ld (hl), a              ; and insert "No. of dims"

        ld hl, de               ; transfer DE space + 1 from make-room
                                ; to HL
        dec de                  ; set DE to next location down.
        ld (hl), $00            ; presume numeric and insert a zero
        bit 6, c                ; test bit 6 of C. numeric or string ?
        jr z, DIM_CLEAR         ; skip to DIM-CLEAR if numeric

        ld (hl), $20            ; place a space character in HL

;; DIM-CLEAR

DIM_CLEAR:
        pop bc                  ; pop the data length

        lddr                    ; LDDR sets to zeros or spaces

; The number of dimensions is still in A.
; A loop is now entered to insert the size of each dimension that was pushed
; during the D-NO-LOOP working downwards from position before start of data.

;; DIM-SIZES

DIM_SIZES:
        pop bc                  ; pop a dimension size                    ***
        ldd (hl), b             ; insert high byte at position
                                ; next location down
        ldd (hl), c             ; insert low byte
                                ; next location down
        dec a                   ; decrement dimension counter
        jr nz, DIM_SIZES        ; back to DIM-SIZES until all done.

        ret                     ; return.


; -----------------------------
; Check whether digit or letter
; -----------------------------
; This routine checks that the character in A is alphanumeric
; returning with carry set if so.

;; ALPHANUM

ALPHANUM:
        call NUMERIC            ; routine NUMERIC will reset carry if so.
        ccf                     ; Complement Carry Flag
        ret c                   ; Return if numeric else continue into
                                ; next routine.

; This routine checks that the character in A is alphabetic

;; ALPHA

ALPHA:
        cp $41                  ; less than 'A' ?
        ccf                     ; Complement Carry Flag
        ret nc                  ; return if so

        cp $5B                  ; less than 'Z'+1 ?
        ret c                   ; is within first range

        cp $61                  ; less than 'a' ?
        ccf                     ; Complement Carry Flag
        ret nc                  ; return if so.

        cp $7B                  ; less than 'z'+1 ?
        ret                     ; carry set if within a-z.


; -------------------------
; Decimal to floating point
; -------------------------
; This routine finds the floating point number represented by an expression
; beginning with BIN, '.' or a digit.
; Note that BIN need not have any '0's or '1's after it.
; BIN is really just a notational symbol and not a function.

;; DEC-TO-FP

DEC_TO_FP:
        cp $C4                  ; 'BIN' token ?
        jr nz, NOT_BIN          ; to NOT-BIN if not

        ld de, $0000            ; initialize 16 bit buffer register.

;; BIN-DIGIT

BIN_DIGIT:
        rst $20                 ; NEXT-CHAR
        sub $31                 ; '1'
        adc a, $00              ; will be zero if '1' or '0'
                                ; carry will be set if was '0'
        jr nz, BIN_END          ; forward to BIN-END if result not zero

        ex de, hl               ; buffer to HL
        ccf                     ; Carry now set if originally '1'
        adc hl, hl              ; shift the carry into HL
        jp c, REPORT_6          ; to REPORT-6 if overflow - too many digits
                                ; after first '1'. There can be an unlimited
                                ; number of leading zeros.
                                ; 'Number too big' - raise an error

        ex de, hl               ; save the buffer
        jr BIN_DIGIT            ; back to BIN-DIGIT for more digits


; ---

;; BIN-END

BIN_END:
        ld bc, de               ; transfer 16 bit buffer
                                ; to BC register pair.
        jp STACK_BC             ; JUMP to STACK-BC to put on calculator stack


; ---

; continue here with .1,  42, 3.14, 5., 2.3 E -4

;; NOT-BIN

NOT_BIN:
        cp $2E                  ; '.' - leading decimal point ?
        jr z, DECIMAL           ; skip to DECIMAL if so.

        call INT_TO_FP          ; routine INT-TO-FP to evaluate all digits
                                ; This number 'x' is placed on stack.
        cp $2E                  ; '.' - mid decimal point ?

        jr nz, E_FORMAT         ; to E-FORMAT if not to consider that format

        rst $20                 ; NEXT-CHAR
        call NUMERIC            ; routine NUMERIC returns carry reset if 0-9

        jr c, E_FORMAT          ; to E-FORMAT if not a digit e.g. '1.'

        jr DEC_STO_1            ; to DEC-STO-1 to add the decimal part to 'x'


; ---

; a leading decimal point has been found in a number.

;; DECIMAL

DECIMAL:
        rst $20                 ; NEXT-CHAR
        call NUMERIC            ; routine NUMERIC will reset carry if digit

;; DEC-RPT-C

DEC_RPT_C:
        jp c, REPORT_C          ; to REPORT-C if just a '.'
                                ; raise 'Nonsense in BASIC'

; since there is no leading zero put one on the calculator stack.

        rst $28                 ; ; FP-CALC
        defb $A0                ; ;stk-zero  ; 0.
        defb $38                ; ;end-calc

; If rejoining from earlier there will be a value 'x' on stack.
; If continuing from above the value zero.
; Now store 1 in mem-0.
; Note. At each pass of the digit loop this will be divided by ten.

;; DEC-STO-1

DEC_STO_1:
        rst $28                 ; ; FP-CALC
        defb $A1                ; ;stk-one   ;x or 0,1.
        defb $C0                ; ;st-mem-0  ;x or 0,1.
        defb $02                ; ;delete    ;x or 0.
        defb $38                ; ;end-calc


;; NXT-DGT-1

NXT_DGT_1:
        rst $18                 ; GET-CHAR
        call STK_DIGIT          ; routine STK-DIGIT stacks single digit 'd'
        jr c, E_FORMAT          ; exit to E-FORMAT when digits exhausted  >


        rst $28                 ; ; FP-CALC   ;x or 0,d.           first pass.
        defb $E0                ; ;get-mem-0  ;x or 0,d,1.
        defb $A4                ; ;stk-ten    ;x or 0,d,1,10.
        defb $05                ; ;division   ;x or 0,d,1/10.
        defb $C0                ; ;st-mem-0   ;x or 0,d,1/10.
        defb $04                ; ;multiply   ;x or 0,d/10.
        defb $0F                ; ;addition   ;x or 0 + d/10.
        defb $38                ; ;end-calc   last value.

        rst $20                 ; NEXT-CHAR  moves to next character
        jr NXT_DGT_1            ; back to NXT-DGT-1


; ---

; although only the first pass is shown it can be seen that at each pass
; the new less significant digit is multiplied by an increasingly smaller
; factor (1/100, 1/1000, 1/10000 ... ) before being added to the previous
; last value to form a new last value.

; Finally see if an exponent has been input.

;; E-FORMAT

E_FORMAT:
        cp $45                  ; is character 'E' ?
        jr z, SIGN_FLAG         ; to SIGN-FLAG if so

        cp $65                  ; 'e' is acceptable as well.
        ret nz                  ; return as no exponent.

;; SIGN-FLAG

SIGN_FLAG:
        ld b, $FF               ; initialize temporary sign byte to $FF

        rst $20                 ; NEXT-CHAR
        cp $2B                  ; is character '+' ?
        jr z, SIGN_DONE         ; to SIGN-DONE

        cp $2D                  ; is character '-' ?
        jr nz, ST_E_PART        ; to ST-E-PART as no sign

        inc b                   ; set sign to zero

; now consider digits of exponent.
; Note. incidentally this is the only occasion in Spectrum BASIC when an
; expression may not be used when a number is expected.

;; SIGN-DONE

SIGN_DONE:
        rst $20                 ; NEXT-CHAR

;; ST-E-PART

ST_E_PART:
        call NUMERIC            ; routine NUMERIC
        jr c, DEC_RPT_C         ; to DEC-RPT-C if not
                                ; raise 'Nonsense in BASIC'.

        push bc                 ; save sign (in B)
        call INT_TO_FP          ; routine INT-TO-FP places exponent on stack
        call FP_TO_A            ; routine FP-TO-A  transfers it to A
        pop bc                  ; restore sign
        jp c, REPORT_6          ; to REPORT-6 if overflow (over 255)
                                ; raise 'Number too big'.

        and a                   ; set flags
        jp m, REPORT_6          ; to REPORT-6 if over '127'.
                                ; raise 'Number too big'.
                                ; 127 is still way too high and it is
                                ; impossible to enter an exponent greater
                                ; than 39 from the keyboard. The error gets
                                ; raised later in E-TO-FP so two different
                                ; error messages depending how high A is.

        inc b                   ; $FF to $00 or $00 to $01 - expendable now.
        jr z, E_FP_JUMP         ; forward to E-FP-JUMP if exponent positive

        neg                     ; Negate the exponent.

;; E-FP-JUMP

E_FP_JUMP:
        jp E_TO_FP              ; JUMP forward to E-TO-FP to assign to
                                ; last value x on stack x * 10 to power A
                                ; a relative jump would have done.


; ---------------------
; Check for valid digit
; ---------------------
; This routine checks that the ASCII character in A is numeric
; returning with carry reset if so.

;; NUMERIC

NUMERIC:
        cp $30                  ; '0'
        ret c                   ; return if less than zero character.

        cp $3A                  ; The upper test is '9'
        ccf                     ; Complement Carry Flag
        ret                     ; Return - carry clear if character '0' - '9'


; -----------
; Stack Digit
; -----------
; This subroutine is called from INT-TO-FP and DEC-TO-FP to stack a digit
; on the calculator stack.

;; STK-DIGIT

STK_DIGIT:
        call NUMERIC            ; routine NUMERIC
        ret c                   ; return if not numeric character

        sub $30                 ; convert from ASCII to digit

; -----------------
; Stack accumulator
; -----------------
;
;

;; STACK-A

STACK_A:
        ld c, a                 ; transfer to C
        ld b, $00               ; and make B zero

; ----------------------
; Stack BC register pair
; ----------------------
;

;; STACK-BC

STACK_BC:
        ld iy, ERR_NR           ; re-initialize ERR_NR

        xor a                   ; clear to signal small integer
        ld e, a                 ; place in E for sign
        ld d, c                 ; LSB to D
        ld c, b                 ; MSB to C
        ld b, a                 ; last byte not used
        call STK_STORE          ; routine STK-STORE

        rst $28                 ; ; FP-CALC
        defb $38                ; ;end-calc  make HL = STKEND-5

        and a                   ; clear carry
        ret                     ; before returning


; -------------------------
; Integer to floating point
; -------------------------
; This routine places one or more digits found in a BASIC line
; on the calculator stack multiplying the previous value by ten each time
; before adding in the new digit to form a last value on calculator stack.

;; INT-TO-FP

INT_TO_FP:
        push af                 ; save first character

        rst $28                 ; ; FP-CALC
        defb $A0                ; ;stk-zero    ; v=0. initial value
        defb $38                ; ;end-calc

        pop af                  ; fetch first character back.

;; NXT-DGT-2

NXT_DGT_2:
        call STK_DIGIT          ; routine STK-DIGIT puts 0-9 on stack
        ret c                   ; will return when character is not numeric >

        rst $28                 ; ; FP-CALC    ; v, d.
        defb $01                ; ;exchange    ; d, v.
        defb $A4                ; ;stk-ten     ; d, v, 10.
        defb $04                ; ;multiply    ; d, v*10.
        defb $0F                ; ;addition    ; d + v*10 = newvalue
        defb $38                ; ;end-calc    ; v.

        call CH_ADD_1           ; routine CH-ADD+1 get next character
        jr NXT_DGT_2            ; back to NXT-DGT-2 to process as a digit



;*********************************
;** Part 9. ARITHMETIC ROUTINES **
;*********************************

; --------------------------
; E-format to floating point
; --------------------------
; This subroutine is used by the PRINT-FP routine and the decimal to FP
; routines to stack a number expressed in exponent format.
; Note. Though not used by the ROM as such, it has also been set up as
; a unary calculator literal but this will not work as the accumulator
; is not available from within the calculator.

; on entry there is a value x on the calculator stack and an exponent of ten
; in A.    The required value is x + 10 ^ A

;; e-to-fp
;; E-TO-FP

E_TO_FP:
        rlca                    ; this will set the          x.
        rrca                    ; carry if bit 7 is set

        jr nc, E_SAVE           ; to E-SAVE  if positive.

        cpl                     ; make negative positive
        inc a                   ; without altering carry.

;; E-SAVE

E_SAVE:
        push af                 ; save positive exp and sign in carry

        ld hl, MEMBOT           ; address MEM-0

        call FP_0_1             ; routine FP-0/1
                                ; places an integer zero, if no carry,
                                ; else a one in mem-0 as a sign flag

        rst $28                 ; ; FP-CALC
        defb $A4                ; ;stk-ten                    x, 10.
        defb $38                ; ;end-calc

        pop af                  ; pop the exponent.

; now enter a loop

;; E-LOOP

E_LOOP:
        srl a                   ; 0>76543210>C

        jr nc, E_TST_END        ; forward to E-TST-END if no bit

        push af                 ; save shifted exponent.

        rst $28                 ; ; FP-CALC
        defb $C1                ; ;st-mem-1                   x, 10.
        defb $E0                ; ;get-mem-0                  x, 10, (0/1).
        defb $00                ; ;jump-true

        defb $04                ; ;to L2D6D, E-DIVSN

        defb $04                ; ;multiply                   x*10.
        defb $33                ; ;jump

        defb $02                ; ;to L2D6E, E-FETCH

;; E-DIVSN

E_DIVSN:
        defb $05                ; ;division                   x/10.

;; E-FETCH

E_FETCH:
        defb $E1                ; ;get-mem-1                  x/10 or x*10, 10.
        defb $38                ; ;end-calc                   new x, 10.

        pop af                  ; restore shifted exponent

; the loop branched to here with no carry

;; E-TST-END

E_TST_END:
        jr z, E_END             ; forward to E-END  if A emptied of bits

        push af                 ; re-save shifted exponent

        rst $28                 ; ; FP-CALC
        defb $31                ; ;duplicate                  new x, 10, 10.
        defb $04                ; ;multiply                   new x, 100.
        defb $38                ; ;end-calc

        pop af                  ; restore shifted exponent
        jr E_LOOP               ; back to E-LOOP  until all bits done.


; ---

; although only the first pass is shown it can be seen that for each set bit
; representing a power of two, x is multiplied or divided by the
; corresponding power of ten.

;; E-END

E_END:
        rst $28                 ; ; FP-CALC                   final x, factor.
        defb $02                ; ;delete                     final x.
        defb $38                ; ;end-calc                   x.

        ret                     ; return





; -------------
; Fetch integer
; -------------
; This routine is called by the mathematical routines - FP-TO-BC, PRINT-FP,
; mult, re-stack and negate to fetch an integer from address HL.
; HL points to the stack or a location in MEM and no deletion occurs.
; If the number is negative then a similar process to that used in INT-STORE
; is used to restore the twos complement number to normal in DE and a sign
; in C.

;; INT-FETCH

INT_FETCH:
        inc hl                  ; skip zero indicator.
        ldi c, (hl)             ; fetch sign to C
                                ; address low byte
        ld a, (hl)              ; fetch to A
        xor c                   ; two's complement
        sub c
        ld e, a                 ; place in E
        inc hl                  ; address high byte
        ld a, (hl)              ; fetch to A
        adc a, c                ; two's complement
        xor c
        ld d, a                 ; place in D
        ret                     ; return


; ------------------------
; Store a positive integer
; ------------------------
; This entry point is not used in this ROM but would
; store any integer as positive.

;; p-int-sto

p_int_sto:
        ld c, $00               ; make sign byte positive and continue

; -------------
; Store integer
; -------------
; this routine stores an integer in DE at address HL.
; It is called from mult, truncate, negate and sgn.
; The sign byte $00 +ve or $FF -ve is in C.
; If negative, the number is stored in 2's complement form so that it is
; ready to be added.

;; INT-STORE

INT_STORE:
        push hl                 ; preserve HL

        ldi (hl), $00           ; first byte zero shows integer not exponent
        ldi (hl), c             ; then store the sign byte
                                ; 
                                ; e.g.             +1             -1
        ld a, e                 ; fetch low byte   00000001       00000001
        xor c                   ; xor sign         00000000   or  11111111
                                ; gives            00000001   or  11111110
        sub c                   ; sub sign         00000000   or  11111111
                                ; gives            00000001>0 or  11111111>C
        ldi (hl), a             ; store 2's complement.
        ld a, d                 ; high byte        00000000       00000000
        adc a, c                ; sign             00000000<0     11111111<C
                                ; gives            00000000   or  00000000
        xor c                   ; xor sign         00000000       11111111
        ldi (hl), a             ; store 2's complement.
        ld (hl), $00            ; last byte always zero for integers.
                                ; is not used and need not be looked at when
                                ; testing for zero but comes into play should
                                ; an integer be converted to fp.
        pop hl                  ; restore HL
        ret                     ; return.



; -----------------------------
; Floating point to BC register
; -----------------------------
; This routine gets a floating point number e.g. 127.4 from the calculator
; stack to the BC register.

;; FP-TO-BC

FP_TO_BC:
        rst $28                 ; ; FP-CALC            set HL to
        defb $38                ; ;end-calc            point to last value.

        ld a, (hl)              ; get first of 5 bytes
        and a                   ; and test
        jr z, FP_DELETE         ; forward to FP-DELETE if an integer

; The value is first rounded up and then converted to integer.

        rst $28                 ; ; FP-CALC           x.
        defb $A2                ; ;stk-half           x. 1/2.
        defb $0F                ; ;addition           x + 1/2.
        defb $27                ; ;int                int(x + .5)
        defb $38                ; ;end-calc

; now delete but leave HL pointing at integer

;; FP-DELETE

FP_DELETE:
        rst $28                 ; ; FP-CALC
        defb $02                ; ;delete
        defb $38                ; ;end-calc

        push hl                 ; save pointer.
        push de                 ; and STKEND.
        ex de, hl               ; make HL point to exponent/zero indicator
        ld b, (hl)              ; indicator to B
        call INT_FETCH          ; routine INT-FETCH
                                ; gets int in DE sign byte to C
                                ; but meaningless values if a large integer

        xor a                   ; clear A
        sub b                   ; subtract indicator byte setting carry
                                ; if not a small integer.

        bit 7, c                ; test a bit of the sign byte setting zero
                                ; if positive.

        ld bc, de               ; transfer int
                                ; to BC
        ld a, e                 ; low byte to A as a useful return value.

        pop de                  ; pop STKEND
        pop hl                  ; and pointer to last value
        ret                     ; return
                                ; if carry is set then the number was too big.


; ------------
; LOG(2^A)
; ------------
; This routine is used when printing floating point numbers to calculate
; the number of digits before the decimal point.

; first convert a one-byte signed integer to its five byte form.

;; LOG(2^A)

LOG_2_A_:
        ld d, a                 ; store a copy of A in D.
        rla                     ; test sign bit of A.
        sbc a, a                ; now $FF if negative or $00
        ld e, a                 ; sign byte to E.
        ld c, a                 ; and to C
        xor a                   ; clear A
        ld b, a                 ; and B.
        call STK_STORE          ; routine STK-STORE stacks number AEDCB

;  so 00 00 XX 00 00 (positive) or 00 FF XX FF 00 (negative).
;  i.e. integer indicator, sign byte, low, high, unused.

; now multiply exponent by log to the base 10 of two.

        rst $28                 ; ; FP-CALC

        defb $34                ; ;stk-data                      .30103 (log 2)
        defb $EF                ; ;Exponent: $7F, Bytes: 4
        defb $1A, $20, $9A, $85 ; ;
        defb $04                ; ;multiply

        defb $27                ; ;int

        defb $38                ; ;end-calc

; -------------------
; Floating point to A
; -------------------
; this routine collects a floating point number from the stack into the
; accumulator returning carry set if not in range 0 - 255.
; Not all the calling routines raise an error with overflow so no attempt
; is made to produce an error report here.

;; FP-TO-A

FP_TO_A:
        call FP_TO_BC           ; routine FP-TO-BC returns with C in A also.
        ret c                   ; return with carry set if > 65535, overflow

        push af                 ; save the value and flags
        dec b                   ; and test that
        inc b                   ; the high byte is zero.
        jr z, FP_A_END          ; forward  FP-A-END if zero

; else there has been 8-bit overflow

        pop af                  ; retrieve the value
        scf                     ; set carry flag to show overflow
        ret                     ; and return.


; ---

;; FP-A-END

FP_A_END:
        pop af                  ; restore value and success flag and
        ret                     ; return.



; -----------------------------
; Print a floating point number
; -----------------------------
; Not a trivial task.
; Begin by considering whether to print a leading sign for negative numbers.

;; PRINT-FP

PRINT_FP:
        rst $28                 ; ; FP-CALC
        defb $31                ; ;duplicate
        defb $36                ; ;less-0
        defb $00                ; ;jump-true

        defb $0B                ; ;to L2DF2, PF-NEGTVE

        defb $31                ; ;duplicate
        defb $37                ; ;greater-0
        defb $00                ; ;jump-true

        defb $0D                ; ;to L2DF8, PF-POSTVE

; must be zero itself

        defb $02                ; ;delete
        defb $38                ; ;end-calc

        ld a, $30               ; prepare the character '0'

        rst $10                 ; PRINT-A
        ret                     ; return.                 ->
                                ; ---


;; PF-NEGTVE

PF_NEGTVE:
        defb $2A                ; ;abs
        defb $38                ; ;end-calc

        ld a, $2D               ; the character '-'

        rst $10                 ; PRINT-A

; and continue to print the now positive number.

        rst $28                 ; ; FP-CALC

;; PF-POSTVE

PF_POSTVE:
        defb $A0                ; ;stk-zero     x,0.     begin by
        defb $C3                ; ;st-mem-3     x,0.     clearing a temporary
        defb $C4                ; ;st-mem-4     x,0.     output buffer to
        defb $C5                ; ;st-mem-5     x,0.     fifteen zeros.
        defb $02                ; ;delete       x.
        defb $38                ; ;end-calc     x.

        exx                     ; in case called from 'str$' then save the
        push hl                 ; pointer to whatever comes after
        exx                     ; str$ as H'L' will be used.

; now enter a loop?

;; PF-LOOP

PF_LOOP:
        rst $28                 ; ; FP-CALC
        defb $31                ; ;duplicate    x,x.
        defb $27                ; ;int          x,int x.
        defb $C2                ; ;st-mem-2     x,int x.
        defb $03                ; ;subtract     x-int x.     fractional part.
        defb $E2                ; ;get-mem-2    x-int x, int x.
        defb $01                ; ;exchange     int x, x-int x.
        defb $C2                ; ;st-mem-2     int x, x-int x.
        defb $02                ; ;delete       int x.
        defb $38                ; ;end-calc     int x.
                                ; mem-2 holds the fractional part.

; HL points to last value int x

        ld a, (hl)              ; fetch exponent of int x.
        and a                   ; test
        jr nz, PF_LARGE         ; forward to PF-LARGE if a large integer
                                ; > 65535

; continue with small positive integer components in range 0 - 65535 
; if original number was say .999 then this integer component is zero. 

        call INT_FETCH          ; routine INT-FETCH gets x in DE
                                ; (but x is not deleted)

        ld b, $10               ; set B, bit counter, to 16d

        ld a, d                 ; test if
        and a                   ; high byte is zero
        jr nz, PF_SAVE          ; forward to PF-SAVE if 16-bit integer.

; and continue with integer in range 0 - 255.

        or e                    ; test the low byte for zero
                                ; i.e. originally just point something or other.
        jr z, PF_SMALL          ; forward if so to PF-SMALL

; 

        ld d, e                 ; transfer E to D
        ld b, $08               ; and reduce the bit counter to 8.

;; PF-SAVE

PF_SAVE:
        push de                 ; save the part before decimal point.
        exx
        pop de                  ; and pop in into D'E'
        exx
        jr PF_BITS              ; forward to PF-BITS


; ---------------------

; the branch was here when 'int x' was found to be zero as in say 0.5.
; The zero has been fetched from the calculator stack but not deleted and
; this should occur now. This omission leaves the stack unbalanced and while
; that causes no problems with a simple PRINT statement, it will if str$ is
; being used in an expression e.g. "2" + STR$ 0.5 gives the result "0.5"
; instead of the expected result "20.5".
; credit Tony Stratton, 1982.
; A DEFB 02 delete is required immediately on using the calculator.

;; PF-SMALL

PF_SMALL:
        rst $28                 ; ; FP-CALC       int x = 0.

L2E25:
        defb $E2                ; ;get-mem-2      int x = 0, x-int x.
        defb $38                ; ;end-calc

        ld a, (hl)              ; fetch exponent of positive fractional number
        sub $7E                 ; subtract

        call LOG_2_A_           ; routine LOG(2^A) calculates leading digits.

        ld d, a                 ; transfer count to D
        ld a, ($5CAC)           ; fetch total MEM-5-1
        sub d
        ld ($5CAC), a           ; MEM-5-1
        ld a, d
        call E_TO_FP            ; routine E-TO-FP

        rst $28                 ; ; FP-CALC
        defb $31                ; ;duplicate
        defb $27                ; ;int
        defb $C1                ; ;st-mem-1
        defb $03                ; ;subtract
        defb $E1                ; ;get-mem-1
        defb $38                ; ;end-calc

        call FP_TO_A            ; routine FP-TO-A

        push hl                 ; save HL
        ld ($5CA1), a           ; MEM-3-1
        dec a
        rla
        sbc a, a
        inc a

        ld hl, $5CAB            ; address MEM-5-1 leading digit counter
        ldi (hl), a             ; store counter
                                ; address MEM-5-2 total digits
        add a, (hl)             ; add counter to contents
        ld (hl), a              ; and store updated value
        pop hl                  ; restore HL

        jp PF_FRACTN            ; JUMP forward to PF-FRACTN


; ---

; Note. while it would be pedantic to comment on every occasion a JP
; instruction could be replaced with a JR instruction, this applies to the
; above, which is useful if you wish to correct the unbalanced stack error
; by inserting a 'DEFB 02 delete' at L2E25, and maintain main addresses.

; the branch was here with a large positive integer > 65535 e.g. 123456789
; the accumulator holds the exponent.

;; PF-LARGE

PF_LARGE:
        sub $80                 ; make exponent positive
        cp $1C                  ; compare to 28
        jr c, PF_MEDIUM         ; to PF-MEDIUM if integer <= 2^27

        call LOG_2_A_           ; routine LOG(2^A)
        sub $07
        ld b, a
        ld hl, $5CAC            ; address MEM-5-1 the leading digits counter.
        add a, (hl)             ; add A to contents
        ld (hl), a              ; store updated value.
        ld a, b
        neg                     ; negate
        call E_TO_FP            ; routine E-TO-FP
        jr PF_LOOP              ; back to PF-LOOP


; ----------------------------

;; PF-MEDIUM

PF_MEDIUM:
        ex de, hl
        call FETCH_TWO          ; routine FETCH-TWO
        exx
        set 7, d
        ld a, l
        exx
        sub $80
        ld b, a

; the branch was here to handle bits in DE with 8 or 16 in B  if small int
; and integer in D'E', 6 nibbles will accommodate 065535 but routine does
; 32-bit numbers as well from above

;; PF-BITS

PF_BITS:
        sla de                  ;  C<xxxxxxxx<0
                                ;  C<xxxxxxxx<C
        exx
        rl de                   ;  C<xxxxxxxx<C
                                ;  C<xxxxxxxx<C
        exx

        ld hl, $5CAA            ; set HL to mem-4-5th last byte of buffer
        ld c, $05               ; set byte count to 5 -  10 nibbles

;; PF-BYTES

PF_BYTES:
        ld a, (hl)              ; fetch 0 or prev value
        adc a, a                ; shift left add in carry    C<xxxxxxxx<C

        daa                     ; Decimal Adjust Accumulator.
                                ; if greater than 9 then the left hand
                                ; nibble is incremented. If greater than
                                ; 99 then adjusted and carry set.
                                ; so if we'd built up 7 and a carry came in
                                ;      0000 0111 < C
                                ;      0000 1111
                                ; daa     1 0101  which is 15 in BCD

        ldd (hl), a             ; put back
                                ; work down thru mem 4
        dec c                   ; decrease the 5 counter.
        jr nz, PF_BYTES         ; back to PF-BYTES until the ten nibbles rolled

        djnz PF_BITS            ; back to PF-BITS until 8 or 16 (or 32) done

; at most 9 digits for 32-bit number will have been loaded with digits
; each of the 9 nibbles in mem 4 is placed into ten bytes in mem-3 and mem 4
; unless the nibble is zero as the buffer is already zero.
; ( or in the case of mem-5 will become zero as a result of RLD instruction )

        xor a                   ; clear to accept
        ld hl, $5CA6            ; address MEM-4-0 byte destination.
        ld de, $5CA1            ; address MEM-3-0 nibble source.
        ld b, $09               ; the count is 9 (not ten) as the first
                                ; nibble is known to be blank.

        rld                     ; shift RH nibble to left in (HL)
                                ;    A           (HL)
                                ; 0000 0000 < 0000 3210
                                ; 0000 0000   3210 0000
                                ; A picks up the blank nibble


        ld c, $FF               ; set a flag to indicate when a significant
                                ; digit has been encountered.

;; PF-DIGITS

PF_DIGITS:
        rld                     ; pick up leftmost nibble from (HL)
                                ;    A           (HL)
                                ; 0000 0000 < 7654 3210
                                ; 0000 7654   3210 0000


        jr nz, PF_INSERT        ; to PF-INSERT if non-zero value picked up.

        dec c                   ; test
        inc c                   ; flag
        jr nz, PF_TEST_2        ; skip forward to PF-TEST-2 if flag still $FF
                                ; indicating this is a leading zero.

; but if the zero is a significant digit e.g. 10 then include in digit totals.
; the path for non-zero digits rejoins here.

;; PF-INSERT

PF_INSERT:
        ldi (de), a             ; insert digit at destination
                                ; increase the destination pointer
        inc (iy+$71)            ; increment MEM-5-1st  digit counter
        inc (iy+$72)            ; increment MEM-5-2nd  leading digit counter
        ld c, $00               ; set flag to zero indicating that any
                                ; subsequent zeros are significant and not
                                ; leading.

;; PF-TEST-2

PF_TEST_2:
        bit 0, b                ; test if the nibble count is even
        jr z, PF_ALL_9          ; skip to PF-ALL-9 if so to deal with the
                                ; other nibble in the same byte

        inc hl                  ; point to next source byte if not

;; PF-ALL-9

PF_ALL_9:
        djnz PF_DIGITS          ; decrement the nibble count, back to PF-DIGITS
                                ; if all nine not done.

; For 8-bit integers there will be at most 3 digits.
; For 16-bit integers there will be at most 5 digits. 
; but for larger integers there could be nine leading digits.
; if nine digits complete then the last one is rounded up as the number will
; be printed using E-format notation

        ld a, ($5CAB)           ; fetch digit count from MEM-5-1st
        sub $09                 ; subtract 9 - max possible
        jr c, PF_MORE           ; forward if less to PF-MORE

        dec (iy+$71)            ; decrement digit counter MEM-5-1st to 8
        ld a, $04               ; load A with the value 4.
        cp (iy+$6F)             ; compare with MEM-4-4th - the ninth digit
        jr PF_ROUND             ; forward to PF-ROUND
                                ; to consider rounding.


; ---------------------------------------
 
; now delete int x from calculator stack and fetch fractional part.

;; PF-MORE

PF_MORE:
        rst $28                 ; ; FP-CALC        int x.
        defb $02                ; ;delete          .
        defb $E2                ; ;get-mem-2       x - int x = f.
        defb $38                ; ;end-calc        f.

;; PF-FRACTN

PF_FRACTN:
        ex de, hl
        call FETCH_TWO          ; routine FETCH-TWO
        exx
        ld a, $80
        sub l
        ld l, $00
        set 7, d
        exx
        call SHIFT_FP           ; routine SHIFT-FP

;; PF-FRN-LP

PF_FRN_LP:
        ld a, (iy+$71)          ; MEM-5-1st
        cp $08
        jr c, PF_FR_DGT         ; to PF-FR-DGT

        exx
        rl d
        exx
        jr PF_ROUND             ; to PF-ROUND


; ---

;; PF-FR-DGT

PF_FR_DGT:
        ld bc, $0200

;; PF-FR-EXX

PF_FR_EXX:
        ld a, e
        call CA_10_A_C          ; routine CA-10*A+C
        ld e, a
        ld a, d
        call CA_10_A_C          ; routine CA-10*A+C
        ld d, a
        push bc
        exx
        pop bc
        djnz PF_FR_EXX          ; to PF-FR-EXX

        ld hl, $5CA1            ; MEM-3
        ld a, c
        ld c, (iy+$71)          ; MEM-5-1st
        add hl, bc
        ld (hl), a
        inc (iy+$71)            ; MEM-5-1st
        jr PF_FRN_LP            ; to PF-FRN-LP


; ----------------

; 1) with 9 digits but 8 in mem-5-1 and A holding 4, carry set if rounding up.
; e.g. 
;      999999999 is printed as 1E+9
;      100000001 is printed as 1E+8
;      100000009 is printed as 1.0000001E+8

;; PF-ROUND

PF_ROUND:
        push af                 ; save A and flags
        ld hl, $5CA1            ; address MEM-3 start of digits
        ld c, (iy+$71)          ; MEM-5-1st No. of digits to C
        ld b, $00               ; prepare to add
        add hl, bc              ; address last digit + 1
        ld b, c                 ; No. of digits to B counter
        pop af                  ; restore A and carry flag from comparison.

;; PF-RND-LP

PF_RND_LP:
        dec hl                  ; address digit at rounding position.
        ld a, (hl)              ; fetch it
        adc a, $00              ; add carry from the comparison
        ld (hl), a              ; put back result even if $0A.
        and a                   ; test A
        jr z, PF_R_BACK         ; skip to PF-R-BACK if ZERO?

        cp $0A                  ; compare to 'ten' - overflow
        ccf                     ; complement carry flag so that set if ten.
        jr nc, PF_COUNT         ; forward to PF-COUNT with 1 - 9.

;; PF-R-BACK

PF_R_BACK:
        djnz PF_RND_LP          ; loop back to PF-RND-LP

; if B counts down to zero then we've rounded right back as in 999999995.
; and the first 8 locations all hold $0A.


        ld (hl), $01            ; load first location with digit 1.
        inc b                   ; make B hold 1 also.
                                ; could save an instruction byte here.
        inc (iy+$72)            ; make MEM-5-2nd hold 1.
                                ; and proceed to initialize total digits to 1.

;; PF-COUNT

PF_COUNT:
        ld (iy+$71), b          ; MEM-5-1st

; now balance the calculator stack by deleting  it

        rst $28                 ; ; FP-CALC
        defb $02                ; ;delete
        defb $38                ; ;end-calc

; note if used from str$ then other values may be on the calculator stack.
; we can also restore the next literal pointer from its position on the
; machine stack.

        exx
        pop hl                  ; restore next literal pointer.
        exx

        ld bc, ($5CAB)          ; set C to MEM-5-1st digit counter.
                                ; set B to MEM-5-2nd leading digit counter.
        ld hl, $5CA1            ; set HL to start of digits at MEM-3-1
        ld a, b
        cp $09
        jr c, PF_NOT_E          ; to PF-NOT-E

        cp $FC
        jr c, PF_E_FRMT         ; to PF-E-FRMT

;; PF-NOT-E

PF_NOT_E:
        and a                   ; test for zero leading digits as in .123

        call z, OUT_CODE        ; routine OUT-CODE prints a zero e.g. 0.123

;; PF-E-SBRN

PF_E_SBRN:
        xor a
        sub b
        jp m, PF_OUT_LP         ; skip forward to PF-OUT-LP if originally +ve

        ld b, a                 ; else negative count now +ve
        jr PF_DC_OUT            ; forward to PF-DC-OUT       ->


; ---

;; PF-OUT-LP

PF_OUT_LP:
        ld a, c                 ; fetch total digit count
        and a                   ; test for zero
        jr z, PF_OUT_DT         ; forward to PF-OUT-DT if so

        ldi a, (hl)             ; fetch digit
                                ; address next digit
        dec c                   ; decrease total digit counter

;; PF-OUT-DT

PF_OUT_DT:
        call OUT_CODE           ; routine OUT-CODE outputs it.
        djnz PF_OUT_LP          ; loop back to PF-OUT-LP until B leading
                                ; digits output.

;; PF-DC-OUT

PF_DC_OUT:
        ld a, c                 ; fetch total digits and
        and a                   ; test if also zero
        ret z                   ; return if so              -->

; 

        inc b                   ; increment B
        ld a, $2E               ; prepare the character '.'

;; PF-DEC-0S

PF_DEC_0S:
        rst $10                 ; PRINT-A outputs the character '.' or '0'

        ld a, $30               ; prepare the character '0'
                                ; (for cases like .000012345678)
        djnz PF_DEC_0S          ; loop back to PF-DEC-0S for B times.

        ld b, c                 ; load B with now trailing digit counter.
        jr PF_OUT_LP            ; back to PF-OUT-LP


; ---------------------------------

; the branch was here for E-format printing e.g. 123456789 => 1.2345679e+8

;; PF-E-FRMT

PF_E_FRMT:
        ld d, b                 ; counter to D
        dec d                   ; decrement
        ld b, $01               ; load B with 1.

        call PF_E_SBRN          ; routine PF-E-SBRN above

        ld a, $45               ; prepare character 'e'
        rst $10                 ; PRINT-A

        ld c, d                 ; exponent to C
        ld a, c                 ; and to A
        and a                   ; test exponent
        jp p, PF_E_POS          ; to PF-E-POS if positive

        neg                     ; negate
        ld c, a                 ; positive exponent to C
        ld a, $2D               ; prepare character '-'
        jr PF_E_SIGN            ; skip to PF-E-SIGN


; ---

;; PF-E-POS

PF_E_POS:
        ld a, $2B               ; prepare character '+'

;; PF-E-SIGN

PF_E_SIGN:
        rst $10                 ; PRINT-A outputs the sign

        ld b, $00               ; make the high byte zero.
        jp OUT_NUM_1            ; exit via OUT-NUM-1 to print exponent in BC


; ------------------------------
; Handle printing floating point
; ------------------------------
; This subroutine is called twice from above when printing floating-point
; numbers. It returns 10*A +C in registers C and A

;; CA-10*A+C

CA_10_A_C:
        push de                 ; preserve DE.
        ld l, a                 ; transfer A to L
        ld h, $00               ; zero high byte.
        ld e, l                 ; copy HL
        ld d, h                 ; to DE.
        add hl, hl              ; double (*2)
        add hl, hl              ; double (*4)
        add hl, de              ; add DE (*5)
        add hl, hl              ; double (*10)
        ld e, c                 ; copy C to E    (D is 0)
        add hl, de              ; and add to give required result.
        ld c, h                 ; transfer to
        ld a, l                 ; destination registers.
        pop de                  ; restore DE
        ret                     ; return with result.


; --------------
; Prepare to add
; --------------
; This routine is called twice by addition to prepare the two numbers. The
; exponent is picked up in A and the location made zero. Then the sign bit
; is tested before being set to the implied state. Negative numbers are twos
; complemented.

;; PREP-ADD

PREP_ADD:
        ld a, (hl)              ; pick up exponent
        ld (hl), $00            ; make location zero
        and a                   ; test if number is zero
        ret z                   ; return if so

        inc hl                  ; address mantissa
        bit 7, (hl)             ; test the sign bit
        set 7, (hl)             ; set it to implied state
        dec hl                  ; point to exponent
        ret z                   ; return if positive number.

        push bc                 ; preserve BC
        ld bc, $0005            ; length of number
        add hl, bc              ; point HL past end
        ld b, c                 ; set B to 5 counter
        ld c, a                 ; store exponent in C
        scf                     ; set carry flag

;; NEG-BYTE

NEG_BYTE:
        dec hl                  ; work from LSB to MSB
        ld a, (hl)              ; fetch byte
        cpl                     ; complement
        adc a, $00              ; add in initial carry or from prev operation
        ld (hl), a              ; put back
        djnz NEG_BYTE           ; loop to NEG-BYTE till all 5 done

        ld a, c                 ; stored exponent to A
        pop bc                  ; restore original BC
        ret                     ; return


; -----------------
; Fetch two numbers
; -----------------
; This routine is called twice when printing floating point numbers and also
; to fetch two numbers by the addition, multiply and division routines.
; HL addresses the first number, DE addresses the second number.
; For arithmetic only, A holds the sign of the result which is stored in
; the second location. 

;; FETCH-TWO

FETCH_TWO:
        push hl                 ; save pointer to first number, result if math.
        push af                 ; save result sign.

        ldi c, (hl)

        ld b, (hl)
        ldi (hl), a             ; store the sign at correct location in
                                ; destination 5 bytes for arithmetic only.

        ld a, c
        ld c, (hl)
        push bc
        inc hl
        ldi c, (hl)
        ld b, (hl)
        ex de, hl
        ld d, a
        ld e, (hl)
        push de
        inc hl
        ldi d, (hl)
        ld e, (hl)
        push de
        exx
        pop de
        pop hl
        pop bc
        exx
        inc hl
        ldi d, (hl)
        ld e, (hl)

        pop af                  ; restore possible result sign.
        pop hl                  ; and pointer to possible result.
        ret                     ; return.


; ---------------------------------
; Shift floating point number right
; ---------------------------------
;
;

;; SHIFT-FP

SHIFT_FP:
        and a
        ret z

        cp $21
        jr nc, ADDEND_0         ; to ADDEND-0

        push bc
        ld b, a

;; ONE-SHIFT

ONE_SHIFT:
        exx
        sra l
        rr de
        exx
        rr de
        djnz ONE_SHIFT          ; to ONE-SHIFT

        pop bc
        ret nc

        call ADD_BACK           ; routine ADD-BACK
        ret nz

;; ADDEND-0

ADDEND_0:
        exx
        xor a

;; ZEROS-4/5

ZEROS_4_5:
        ld l, $00
        ld d, a
        ld e, l
        exx
        ld de, $0000
        ret


; ------------------
; Add back any carry
; ------------------
;
;

;; ADD-BACK

ADD_BACK:
        inc e
        ret nz

        inc d
        ret nz

        exx
        inc e
        jr nz, ALL_ADDED        ; to ALL-ADDED

        inc d

;; ALL-ADDED

ALL_ADDED:
        exx
        ret


; -----------------------
; Handle subtraction (03)
; -----------------------
; Subtraction is done by switching the sign byte/bit of the second number
; which may be integer of floating point and continuing into addition.

;; subtract

subtract:
        ex de, hl               ; address second number with HL

        call negate             ; routine NEGATE switches sign

        ex de, hl               ; address first number again
                                ; and continue.

; --------------------
; Handle addition (0F)
; --------------------
; HL points to first number, DE to second.
; If they are both integers, then go for the easy route.

;; addition

addition:
        ld a, (de)              ; fetch first byte of second
        or (hl)                 ; combine with first byte of first
        jr nz, FULL_ADDN        ; forward to FULL-ADDN if at least one was
                                ; in floating point form.

; continue if both were small integers.

        push de                 ; save pointer to lowest number for result.

        inc hl                  ; address sign byte and
        push hl                 ; push the pointer.

        inc hl                  ; address low byte
        ldi de, (hl)            ; to E
                                ; address high byte
                                ; to D
                                ; address unused byte

        inc hl                  ; address known zero indicator of 1st number
        inc hl                  ; address sign byte

        ldi a, (hl)             ; sign to A, $00 or $FF
                                ; address low byte

        ldi c, (hl)             ; to C
                                ; address high byte
        ld b, (hl)              ; to B

        pop hl                  ; pop result sign pointer
        ex de, hl               ; integer to HL

        add hl, bc              ; add to the other one in BC
                                ; setting carry if overflow.

        ex de, hl               ; save result in DE bringing back sign pointer

        adc a, (hl)             ; if pos/pos A=01 with overflow else 00
                                ; if neg/neg A=FF with overflow else FE
                                ; if mixture A=00 with overflow else FF

        rrca                    ; bit 0 to (C)

        adc a, $00              ; both acceptable signs now zero

        jr nz, ADDN_OFLW        ; forward to ADDN-OFLW if not

        sbc a, a                ; restore a negative result sign

        ldi (hl), a
        ld (hl), de
        dec hl
        dec hl

        pop de                  ; STKEND
        ret


; ---

;; ADDN-OFLW

ADDN_OFLW:
        dec hl
        pop de

;; FULL-ADDN

FULL_ADDN:
        call RE_ST_TWO          ; routine RE-ST-TWO
        exx
        push hl
        exx
        push de
        push hl
        call PREP_ADD           ; routine PREP-ADD
        ld b, a
        ex de, hl
        call PREP_ADD           ; routine PREP-ADD
        ld c, a
        cp b
        jr nc, SHIFT_LEN        ; to SHIFT-LEN

        ld a, b
        ld b, c
        ex de, hl

;; SHIFT-LEN

SHIFT_LEN:
        push af
        sub b
        call FETCH_TWO          ; routine FETCH-TWO
        call SHIFT_FP           ; routine SHIFT-FP
        pop af
        pop hl
        ld (hl), a
        push hl
        ld l, b
        ld h, c
        add hl, de
        exx
        ex de, hl
        adc hl, bc
        ex de, hl
        ld a, h
        adc a, l
        ld l, a
        rra
        xor l
        exx
        ex de, hl
        pop hl
        rra
        jr nc, TEST_NEG         ; to TEST-NEG

        ld a, $01
        call SHIFT_FP           ; routine SHIFT-FP
        inc (hl)
        jr z, ADD_REP_6         ; to ADD-REP-6

;; TEST-NEG

TEST_NEG:
        exx
        ld a, l
        and $80
        exx
        inc hl
        ldd (hl), a
        jr z, GO_NC_MLT         ; to GO-NC-MLT

        ld a, e
        neg                     ; Negate
        ccf                     ; Complement Carry Flag
        ld e, a
        ld a, d
        cpl
        adc a, $00
        ld d, a
        exx
        ld a, e
        cpl
        adc a, $00
        ld e, a
        ld a, d
        cpl
        adc a, $00
        jr nc, END_COMPL        ; to END-COMPL

        rra
        exx
        inc (hl)

;; ADD-REP-6

ADD_REP_6:
        jp z, REPORT_6          ; to REPORT-6

        exx

;; END-COMPL

END_COMPL:
        ld d, a
        exx

;; GO-NC-MLT

GO_NC_MLT:
        xor a
        jp TEST_NORM            ; to TEST-NORM


; -----------------------------
; Used in 16 bit multiplication
; -----------------------------
; This routine is used, in the first instance, by the multiply calculator
; literal to perform an integer multiplication in preference to
; 32-bit multiplication to which it will resort if this overflows.
;
; It is also used by STK-VAR to calculate array subscripts and by DIM to
; calculate the space required for multi-dimensional arrays.

;; HL-HL*DE

HL_HL_DE:
        push bc                 ; preserve BC throughout
        ld b, $10               ; set B to 16
        ld a, h                 ; save H in A high byte
        ld c, l                 ; save L in C low byte
        ld hl, $0000            ; initialize result to zero

; now enter a loop.

;; HL-LOOP

HL_LOOP:
        add hl, hl              ; double result
        jr c, HL_END            ; to HL-END if overflow

        rl c                    ; shift AC left into carry
        rla
        jr nc, HL_AGAIN         ; to HL-AGAIN to skip addition if no carry

        add hl, de              ; add in DE
        jr c, HL_END            ; to HL-END if overflow

;; HL-AGAIN

HL_AGAIN:
        djnz HL_LOOP            ; back to HL-LOOP for all 16 bits

;; HL-END

HL_END:
        pop bc                  ; restore preserved BC
        ret                     ; return with carry reset if successful
                                ; and result in HL.


; ----------------------------------------------
; THE 'PREPARE TO MULTIPLY OR DIVIDE' SUBROUTINE
; ----------------------------------------------
;   This routine is called in succession from multiply and divide to prepare
;   two mantissas by setting the leftmost bit that is used for the sign.
;   On the first call A holds zero and picks up the sign bit. On the second
;   call the two bits are XORed to form the result sign - minus * minus giving
;   plus etc. If either number is zero then this is flagged.
;   HL addresses the exponent.

;; PREP-M/D

PREP_M_D:
        call TEST_ZERO          ; routine TEST-ZERO  preserves accumulator.
        ret c                   ; return carry set if zero

        inc hl                  ; address first byte of mantissa
        xor (hl)                ; pick up the first or xor with first.
        set 7, (hl)             ; now set to give true 32-bit mantissa
        dec hl                  ; point to exponent
        ret                     ; return with carry reset


; ----------------------
; THE 'MULTIPLY' ROUTINE     
; ----------------------
; (offset: $04 'multiply')
;
;
;   "He said go forth and something about mathematics, I wasn't really 
;    listening" - overheard conversation between two unicorns.
;    [ The Odd Streak ].

;; multiply

multiply:
        ld a, (de)
        or (hl)
        jr nz, MULT_LONG        ; to MULT-LONG

        push de
        push hl
        push de
        call INT_FETCH          ; routine INT-FETCH
        ex de, hl
        ex (sp), hl
        ld b, c
        call INT_FETCH          ; routine INT-FETCH
        ld a, b
        xor c
        ld c, a
        pop hl
        call HL_HL_DE           ; routine HL-HL*DE
        ex de, hl
        pop hl
        jr c, MULT_OFLW         ; to MULT-OFLW

        ld a, d
        or e
        jr nz, MULT_RSLT        ; to MULT-RSLT

        ld c, a

;; MULT-RSLT

MULT_RSLT:
        call INT_STORE          ; routine INT-STORE
        pop de
        ret


; ---

;; MULT-OFLW

MULT_OFLW:
        pop de

;; MULT-LONG

MULT_LONG:
        call RE_ST_TWO          ; routine RE-ST-TWO
        xor a
        call PREP_M_D           ; routine PREP-M/D
        ret c

        exx
        push hl
        exx
        push de
        ex de, hl
        call PREP_M_D           ; routine PREP-M/D
        ex de, hl
        jr c, ZERO_RSLT         ; to ZERO-RSLT

        push hl
        call FETCH_TWO          ; routine FETCH-TWO
        ld a, b
        and a
        sbc hl, hl
        exx
        push hl
        sbc hl, hl
        exx
        ld b, $21
        jr STRT_MLT             ; to STRT-MLT


; ---

;; MLT-LOOP

MLT_LOOP:
        jr nc, NO_ADD           ; to NO-ADD

        add hl, de
        exx
        adc hl, de
        exx

;; NO-ADD

NO_ADD:
        exx
        rr hl
        exx
        rr hl

;; STRT-MLT

STRT_MLT:
        exx
        rr bc
        exx
        rr c
        rra
        djnz MLT_LOOP           ; to MLT-LOOP

        ex de, hl
        exx
        ex de, hl
        exx
        pop bc
        pop hl
        ld a, b
        add a, c
        jr nz, MAKE_EXPT        ; to MAKE-EXPT

        and a

;; MAKE-EXPT

MAKE_EXPT:
        dec a
        ccf                     ; Complement Carry Flag

;; DIVN-EXPT

DIVN_EXPT:
        rla
        ccf                     ; Complement Carry Flag
        rra
        jp p, OFLW1_CLR         ; to OFLW1-CLR

        jr nc, REPORT_6         ; to REPORT-6

        and a

;; OFLW1-CLR

OFLW1_CLR:
        inc a
        jr nz, OFLW2_CLR        ; to OFLW2-CLR

        jr c, OFLW2_CLR         ; to OFLW2-CLR

        exx
        bit 7, d
        exx
        jr nz, REPORT_6         ; to REPORT-6

;; OFLW2-CLR

OFLW2_CLR:
        ld (hl), a
        exx
        ld a, b
        exx

;; TEST-NORM

TEST_NORM:
        jr nc, NORMALISE        ; to NORMALISE

        ld a, (hl)
        and a

;; NEAR-ZERO

NEAR_ZERO:
        ld a, $80
        jr z, SKIP_ZERO         ; to SKIP-ZERO

;; ZERO-RSLT

ZERO_RSLT:
        xor a

;; SKIP-ZERO

SKIP_ZERO:
        exx
        and d
        call ZEROS_4_5          ; routine ZEROS-4/5
        rlca
        ld (hl), a
        jr c, OFLOW_CLR         ; to OFLOW-CLR

        inc hl
        ldd (hl), a
        jr OFLOW_CLR            ; to OFLOW-CLR


; ---

;; NORMALISE

NORMALISE:
        ld b, $20

;; SHIFT-ONE

SHIFT_ONE:
        exx
        bit 7, d
        exx
        jr nz, NORML_NOW        ; to NORML-NOW

        rlca
        rl de
        exx
        rl de
        exx
        dec (hl)
        jr z, NEAR_ZERO         ; to NEAR-ZERO

        djnz SHIFT_ONE          ; to SHIFT-ONE

        jr ZERO_RSLT            ; to ZERO-RSLT


; ---

;; NORML-NOW

NORML_NOW:
        rla
        jr nc, OFLOW_CLR        ; to OFLOW-CLR

        call ADD_BACK           ; routine ADD-BACK
        jr nz, OFLOW_CLR        ; to OFLOW-CLR

        exx
        ld d, $80
        exx
        inc (hl)
        jr z, REPORT_6          ; to REPORT-6

;; OFLOW-CLR

OFLOW_CLR:
        push hl
        inc hl
        exx
        push de
        exx
        pop bc
        ld a, b
        rla
        rl (hl)
        rra
        ldi (hl), a
        ldi (hl), c
        ldi (hl), d
        ld (hl), e
        pop hl
        pop de
        exx
        pop hl
        exx
        ret


; ---

;; REPORT-6

REPORT_6:
        rst $08                 ; ERROR-1
        defb $05                ; Error Report: Number too big

; ----------------------
; THE 'DIVISION' ROUTINE
; ----------------------
; (offset: $05 'division')
;
;   "He who can properly define and divide is to be considered a god"
;   - Plato,  429 - 347 B.C.

;; division

division:
        call RE_ST_TWO          ; routine RE-ST-TWO
        ex de, hl
        xor a
        call PREP_M_D           ; routine PREP-M/D
        jr c, REPORT_6          ; to REPORT-6

        ex de, hl
        call PREP_M_D           ; routine PREP-M/D
        ret c

        exx
        push hl
        exx
        push de
        push hl
        call FETCH_TWO          ; routine FETCH-TWO
        exx
        push hl
        ld hl, bc
        exx
        ld h, c
        ld l, b
        xor a
        ld b, $DF
        jr DIV_START            ; to DIV-START


; ---

;; DIV-LOOP

DIV_LOOP:
        rla
        rl c
        exx
        rl bc
        exx

;; div-34th

div_34th:
        add hl, hl
        exx
        adc hl, hl
        exx
        jr c, SUBN_ONLY         ; to SUBN-ONLY

;; DIV-START

DIV_START:
        sbc hl, de
        exx
        sbc hl, de
        exx
        jr nc, NO_RSTORE        ; to NO-RSTORE

        add hl, de
        exx
        adc hl, de
        exx
        and a
        jr COUNT_ONE            ; to COUNT-ONE


; ---

;; SUBN-ONLY

SUBN_ONLY:
        and a
        sbc hl, de
        exx
        sbc hl, de
        exx

;; NO-RSTORE

NO_RSTORE:
        scf                     ; Set Carry Flag

;; COUNT-ONE

COUNT_ONE:
        inc b
        jp m, DIV_LOOP          ; to DIV-LOOP

        push af
        jr z, DIV_START         ; to DIV-START

;
;
;
;

        ld e, a
        ld d, c
        exx
        ld e, c
        ld d, b
        pop af
        rr b
        pop af
        rr b
        exx
        pop bc
        pop hl
        ld a, b
        sub c
        jp DIVN_EXPT            ; jump back to DIVN-EXPT


; ------------------------------------
; Integer truncation towards zero ($3A)
; ------------------------------------
;
;

;; truncate

truncate:
        ld a, (hl)
        and a
        ret z

        cp $81
        jr nc, T_GR_ZERO        ; to T-GR-ZERO

        ld (hl), $00
        ld a, $20
        jr NIL_BYTES            ; to NIL-BYTES


; ---

;; T-GR-ZERO

T_GR_ZERO:
        cp $91
        jr nz, T_SMALL          ; to T-SMALL

        inc hl
        inc hl
        inc hl
        ld a, $80
        and (hl)
        dec hl
        or (hl)
        dec hl
        jr nz, T_FIRST          ; to T-FIRST

        ld a, $80
        xor (hl)

;; T-FIRST

T_FIRST:
        dec hl
        jr nz, T_EXPNENT        ; to T-EXPNENT

        ldi (hl), a
        ldd (hl), $FF
        ld a, $18
        jr NIL_BYTES            ; to NIL-BYTES


; ---

;; T-SMALL

T_SMALL:
        jr nc, X_LARGE          ; to X-LARGE

        push de
        cpl
        add a, $91
        inc hl
        ldi d, (hl)
        ldd e, (hl)
        dec hl
        ld c, $00
        bit 7, d
        jr z, T_NUMERIC         ; to T-NUMERIC

        dec c

;; T-NUMERIC

T_NUMERIC:
        set 7, d
        ld b, $08
        sub b
        add a, b
        jr c, T_TEST            ; to T-TEST

        ld e, d
        ld d, $00
        sub b

;; T-TEST

T_TEST:
        jr z, T_STORE           ; to T-STORE

        ld b, a

;; T-SHIFT

T_SHIFT:
        srl de
        djnz T_SHIFT            ; to T-SHIFT

;; T-STORE

T_STORE:
        call INT_STORE          ; routine INT-STORE
        pop de
        ret


; ---

;; T-EXPNENT

T_EXPNENT:
        ld a, (hl)

;; X-LARGE

X_LARGE:
        sub $A0
        ret p

        neg                     ; Negate

;; NIL-BYTES

NIL_BYTES:
        push de
        ex de, hl
        dec hl
        ld b, a
        srl b
        srl b
        srl b
        jr z, BITS_ZERO         ; to BITS-ZERO

;; BYTE-ZERO

BYTE_ZERO:
        ldd (hl), $00
        djnz BYTE_ZERO          ; to BYTE-ZERO

;; BITS-ZERO

BITS_ZERO:
        and $07
        jr z, IX_END            ; to IX-END

        ld b, a
        ld a, $FF

;; LESS-MASK

LESS_MASK:
        sla a
        djnz LESS_MASK          ; to LESS-MASK

        and (hl)
        ld (hl), a

;; IX-END

IX_END:
        ex de, hl
        pop de
        ret


; ----------------------------------
; Storage of numbers in 5 byte form.
; ==================================
; Both integers and floating-point numbers can be stored in five bytes.
; Zero is a special case stored as 5 zeros.
; For integers the form is
; Byte 1 - zero,
; Byte 2 - sign byte, $00 +ve, $FF -ve.
; Byte 3 - Low byte of integer.
; Byte 4 - High byte
; Byte 5 - unused but always zero.
;
; it seems unusual to store the low byte first but it is just as easy either
; way. Statistically it just increases the chances of trailing zeros which
; is an advantage elsewhere in saving ROM code.
;
;             zero     sign     low      high    unused
; So +1 is  00000000 00000000 00000001 00000000 00000000
;
; and -1 is 00000000 11111111 11111111 11111111 00000000
;
; much of the arithmetic found in BASIC lines can be done using numbers
; in this form using the Z80's 16 bit register operation ADD.
; (multiplication is done by a sequence of additions).
;
; Storing -ve integers in two's complement form, means that they are ready for
; addition and you might like to add the numbers above to prove that the
; answer is zero. If, as in this case, the carry is set then that denotes that
; the result is positive. This only applies when the signs don't match.
; With positive numbers a carry denotes the result is out of integer range.
; With negative numbers a carry denotes the result is within range.
; The exception to the last rule is when the result is -65536
;
; Floating point form is an alternative method of storing numbers which can
; be used for integers and larger (or fractional) numbers.
;
; In this form 1 is stored as
;           10000001 00000000 00000000 00000000 00000000
;
; When a small integer is converted to a floating point number the last two
; bytes are always blank so they are omitted in the following steps
;
; first make exponent +1 +16d  (bit 7 of the exponent is set if positive)

; 10010001 00000000 00000001
; 10010000 00000000 00000010 <-  now shift left and decrement exponent
; ...
; 10000010 01000000 00000000 <-  until a 1 abuts the imaginary point
; 10000001 10000000 00000000     to the left of the mantissa.
;
; however since the leftmost bit of the mantissa is always set then it can
; be used to denote the sign of the mantissa and put back when needed by the
; PREP routines which gives
;
; 10000001 00000000 00000000

; ----------------------------------------------
; THE 'RE-STACK TWO "SMALL" INTEGERS' SUBROUTINE
; ----------------------------------------------
;   This routine is called to re-stack two numbers in full floating point form
;   e.g. from mult when integer multiplication has overflowed.

;; RE-ST-TWO

RE_ST_TWO:
        call RESTK_SUB          ; routine RESTK-SUB  below and continue
                                ; into the routine to do the other one.

;; RESTK-SUB

RESTK_SUB:
        ex de, hl               ; swap pointers

; ---------------------------------------------
; THE 'RE-STACK ONE "SMALL" INTEGER' SUBROUTINE
; ---------------------------------------------
; (offset: $3D 're-stack')
;   This routine re-stacks an integer, usually on the calculator stack, in full 
;   floating point form.  HL points to first byte.

;; re-stack

re_stack:
        ld a, (hl)              ; Fetch Exponent byte to A
        and a                   ; test it
        ret nz                  ; return if not zero as already in full
                                ; floating-point form.

        push de                 ; preserve DE.
        call INT_FETCH          ; routine INT-FETCH
                                ; integer to DE, sign to C.

; HL points to 4th byte.

        xor a                   ; clear accumulator.
        inc hl                  ; point to 5th.
        ldd (hl), a             ; and blank.
                                ; point to 4th.
        ld (hl), a              ; and blank.

        ld b, $91               ; set exponent byte +ve $81
                                ; and imaginary dec point 16 bits to right
                                ; of first bit.

;   we could skip to normalize now but it's quicker to avoid normalizing 
;   through an empty D.

        ld a, d                 ; fetch the high byte D
        and a                   ; is it zero ?
        jr nz, RS_NRMLSE        ; skip to RS-NRMLSE if not.

        or e                    ; low byte E to A and test for zero
        ld b, d                 ; set B exponent to 0
        jr z, RS_STORE          ; forward to RS-STORE if value is zero.

        ld d, e                 ; transfer E to D
        ld e, b                 ; set E to 0
        ld b, $89               ; reduce the initial exponent by eight.


;; RS-NRMLSE

RS_NRMLSE:
        ex de, hl               ; integer to HL, addr of 4th byte to DE.

;; RSTK-LOOP

RSTK_LOOP:
        dec b                   ; decrease exponent
        add hl, hl              ; shift DE left
        jr nc, RSTK_LOOP        ; loop back to RSTK-LOOP
                                ; until a set bit pops into carry

        rrc c                   ; now rotate the sign byte $00 or $FF
                                ; into carry to give a sign bit

        rr hl                   ; rotate the sign bit to left of H
                                ; rotate any carry into L

        ex de, hl               ; address 4th byte, normalized int to DE

;; RS-STORE

RS_STORE:
        dec hl                  ; address 3rd byte
        ldd (hl), e             ; place E
                                ; address 2nd byte
        ldd (hl), d             ; place D
                                ; address 1st byte
        ld (hl), b              ; store the exponent

        pop de                  ; restore initial DE.
        ret                     ; return.


;****************************************
;** Part 10. FLOATING-POINT CALCULATOR **
;****************************************

; As a general rule the calculator avoids using the IY register.
; exceptions are val, val$ and str$.
; So an assembly language programmer who has disabled interrupts to use
; IY for other purposes can still use the calculator for mathematical
; purposes.


; ------------------------
; THE 'TABLE OF CONSTANTS'
; ------------------------
;
;

; used 11 times
;; stk-zero                                                 00 00 00 00 00

stk_zero:
        defb $00                ; ;Bytes: 1
        defb $B0, $00           ; ;Exponent $00
                                ; ;(+00,+00,+00)

; used 19 times
;; stk-one                                                  00 00 01 00 00

stk_one:
        defb $40                ; ;Bytes: 2
        defb $B0, $00, $01      ; ;Exponent $00
                                ; ;(+00,+00)

; used 9 times
;; stk-half                                                 80 00 00 00 00

stk_half:
        defb $30                ; ;Exponent: $80, Bytes: 1
        defb $00                ; ;(+00,+00,+00)

; used 4 times.
;; stk-pi/2                                                 81 49 0F DA A2

stk_pi_2:
        defb $F1                ; ;Exponent: $81, Bytes: 4
        defb $49, $0F, $DA, $A2 ; ;

; used 3 times.
;; stk-ten                                                  00 00 0A 00 00

stk_ten:
        defb $40                ; ;Bytes: 2
        defb $B0, $00, $0A      ; ;Exponent $00
                                ; ;(+00,+00)


; ------------------------
; THE 'TABLE OF ADDRESSES'
; ------------------------
;  "Each problem that I solved became a rule which served afterwards to solve 
;   other problems" - Rene Descartes 1596 - 1650.
;
;   Starts with binary operations which have two operands and one result.
;   Three pseudo binary operations first.

;; tbl-addrs

tbl_addrs:
        defw jump_true          ; $00 Address: $368F - jump-true
        defw exchange           ; $01 Address: $343C - exchange
        defw delete             ; $02 Address: $33A1 - delete

;   True binary operations.

        defw subtract           ; $03 Address: $300F - subtract
        defw multiply           ; $04 Address: $30CA - multiply
        defw division           ; $05 Address: $31AF - division
        defw to_power           ; $06 Address: $3851 - to-power
        defw or_func            ; $07 Address: $351B - or

        defw no___no            ; $08 Address: $3524 - no-&-no
        defw no_l_eql_etc_      ; $09 Address: $353B - no-l-eql
        defw no_l_eql_etc_      ; $0A Address: $353B - no-gr-eql
        defw no_l_eql_etc_      ; $0B Address: $353B - nos-neql
        defw no_l_eql_etc_      ; $0C Address: $353B - no-grtr
        defw no_l_eql_etc_      ; $0D Address: $353B - no-less
        defw no_l_eql_etc_      ; $0E Address: $353B - nos-eql
        defw addition           ; $0F Address: $3014 - addition

        defw str___no           ; $10 Address: $352D - str-&-no
        defw no_l_eql_etc_      ; $11 Address: $353B - str-l-eql
        defw no_l_eql_etc_      ; $12 Address: $353B - str-gr-eql
        defw no_l_eql_etc_      ; $13 Address: $353B - strs-neql
        defw no_l_eql_etc_      ; $14 Address: $353B - str-grtr
        defw no_l_eql_etc_      ; $15 Address: $353B - str-less
        defw no_l_eql_etc_      ; $16 Address: $353B - strs-eql
        defw strs_add           ; $17 Address: $359C - strs-add

;   Unary follow.

        defw val_               ; $18 Address: $35DE - val$
        defw usr__              ; $19 Address: $34BC - usr-$
        defw read_in            ; $1A Address: $3645 - read-in
        defw negate             ; $1B Address: $346E - negate

        defw code               ; $1C Address: $3669 - code
        defw val_               ; $1D Address: $35DE - val
        defw len                ; $1E Address: $3674 - len
        defw sin                ; $1F Address: $37B5 - sin
        defw cos                ; $20 Address: $37AA - cos
        defw tan                ; $21 Address: $37DA - tan
        defw asn                ; $22 Address: $3833 - asn
        defw acs                ; $23 Address: $3843 - acs
        defw atn                ; $24 Address: $37E2 - atn
        defw ln                 ; $25 Address: $3713 - ln
        defw exp                ; $26 Address: $36C4 - exp
        defw int                ; $27 Address: $36AF - int
        defw sqr                ; $28 Address: $384A - sqr
        defw sgn                ; $29 Address: $3492 - sgn
        defw abs                ; $2A Address: $346A - abs
        defw peek               ; $2B Address: $34AC - peek
        defw in_func            ; $2C Address: $34A5 - in
        defw usr_no             ; $2D Address: $34B3 - usr-no
        defw str_               ; $2E Address: $361F - str$
        defw chrs               ; $2F Address: $35C9 - chrs
        defw not                ; $30 Address: $3501 - not

;   End of true unary.

        defw MOVE_FP            ; $31 Address: $33C0 - duplicate
        defw n_mod_m            ; $32 Address: $36A0 - n-mod-m
        defw JUMP               ; $33 Address: $3686 - jump
        defw stk_data           ; $34 Address: $33C6 - stk-data
        defw dec_jr_nz          ; $35 Address: $367A - dec-jr-nz
        defw less_0             ; $36 Address: $3506 - less-0
        defw greater_0          ; $37 Address: $34F9 - greater-0
        defw end_calc           ; $38 Address: $369B - end-calc
        defw get_argt           ; $39 Address: $3783 - get-argt
        defw truncate           ; $3A Address: $3214 - truncate
        defw fp_calc_2          ; $3B Address: $33A2 - fp-calc-2
        defw E_TO_FP            ; $3C Address: $2D4F - e-to-fp
        defw re_stack           ; $3D Address: $3297 - re-stack

;   The following are just the next available slots for the 128 compound 
;   literals which are in range $80 - $FF.

        defw series_xx          ;     Address: $3449 - series-xx    $80 - $9F.
        defw stk_const_xx       ;     Address: $341B - stk-const-xx $A0 - $BF.
        defw st_mem_xx          ;     Address: $342D - st-mem-xx    $C0 - $DF.
        defw get_mem_xx         ;     Address: $340F - get-mem-xx   $E0 - $FF.

;   Aside: 3E - 3F are therefore unused calculator literals.
;   If the literal has to be also usable as a function then bits 6 and 7 are 
;   used to show type of arguments and result.

; --------------
; The Calculator
; --------------
;  "A good calculator does not need artificial aids"
;  Lao Tze 604 - 531 B.C.

;; CALCULATE

CALCULATE:
        call STK_PNTRS          ; routine STK-PNTRS is called to set up the
                                ; calculator stack pointers for a default
                                ; unary operation. HL = last value on stack.
                                ; DE = STKEND first location after stack.

; the calculate routine is called at this point by the series generator...

;; GEN-ENT-1

GEN_ENT_1:
        ld a, b                 ; fetch the Z80 B register to A
        ld (BREG), a            ; and store value in system variable BREG.
                                ; this will be the counter for dec-jr-nz
                                ; or if used from fp-calc2 the calculator
                                ; instruction.

; ... and again later at this point

;; GEN-ENT-2

GEN_ENT_2:
        exx                     ; switch sets
        ex (sp), hl             ; and store the address of next instruction,
                                ; the return address, in H'L'.
                                ; If this is a recursive call the H'L'
                                ; of the previous invocation goes on stack.
                                ; c.f. end-calc.
        exx                     ; switch back to main set

; this is the re-entry looping point when handling a string of literals.

;; RE-ENTRY

RE_ENTRY:
        ld (STKEND), de         ; save end of stack in system variable STKEND
        exx                     ; switch to alt
        ldi a, (hl)             ; get next literal
                                ; increase pointer'

; single operation jumps back to here

;; SCAN-ENT

SCAN_ENT:
        push hl                 ; save pointer on stack
        and a                   ; now test the literal
        jp p, FIRST_3D          ; forward to FIRST-3D if in range $00 - $3D
                                ; anything with bit 7 set will be one of
                                ; 128 compound literals.

; compound literals have the following format.
; bit 7 set indicates compound.
; bits 6-5 the subgroup 0-3.
; bits 4-0 the embedded parameter $00 - $1F.
; The subgroup 0-3 needs to be manipulated to form the next available four
; address places after the simple literals in the address table.

        ld d, a                 ; save literal in D
        and $60                 ; and with 01100000 to isolate subgroup
        rrca                    ; rotate bits
        rrca                    ; 4 places to right
        rrca                    ; not five as we need offset * 2
        rrca                    ; 00000xx0
        add a, $7C              ; add ($3E * 2) to give correct offset.
                                ; alter above if you add more literals.
        ld l, a                 ; store in L for later indexing.
        ld a, d                 ; bring back compound literal
        and $1F                 ; use mask to isolate parameter bits
        jr ENT_TABLE            ; forward to ENT-TABLE


; ---

; the branch was here with simple literals.

;; FIRST-3D

FIRST_3D:
        cp $18                  ; compare with first unary operations.
        jr nc, DOUBLE_A         ; to DOUBLE-A with unary operations

; it is binary so adjust pointers.

        exx
        ld bc, $FFFB            ; the value -5
        ld de, hl               ; transfer HL, the last value, to DE.
        add hl, bc              ; subtract 5 making HL point to second
                                ; value.
        exx

;; DOUBLE-A

DOUBLE_A:
        rlca                    ; double the literal
        ld l, a                 ; and store in L for indexing

;; ENT-TABLE

ENT_TABLE:
        ld de, tbl_addrs        ; Address: tbl-addrs
        ld h, $00               ; prepare to index
        add hl, de              ; add to get address of routine
        ldi e, (hl)             ; low byte to E
        ld d, (hl)              ; high byte to D
        ld hl, RE_ENTRY         ; Address: RE-ENTRY
        ex (sp), hl             ; goes to stack
        push de                 ; now address of routine
        exx                     ; main set
                                ; avoid using IY register.
        ld bc, ($5C66)          ; STKEND_hi
                                ; nothing much goes to C but BREG to B
                                ; and continue into next ret instruction
                                ; which has a dual identity


; ------------------
; Handle delete (02)
; ------------------
; A simple return but when used as a calculator literal this
; deletes the last value from the calculator stack.
; On entry, as always with binary operations,
; HL=first number, DE=second number
; On exit, HL=result, DE=stkend.
; So nothing to do

;; delete

delete:
        ret                     ; return - indirect jump if from above.


; ---------------------
; Single operation (3B)
; ---------------------
;   This single operation is used, in the first instance, to evaluate most
;   of the mathematical and string functions found in BASIC expressions.

;; fp-calc-2

fp_calc_2:
        pop af                  ; drop return address.
        ld a, (BREG)            ; load accumulator from system variable BREG
                                ; value will be literal e.g. 'tan'
        exx                     ; switch to alt
        jr SCAN_ENT             ; back to SCAN-ENT
                                ; next literal will be end-calc at L2758


; ---------------------------------
; THE 'TEST FIVE SPACES' SUBROUTINE
; ---------------------------------
;   This routine is called from MOVE-FP, STK-CONST and STK-STORE to test that 
;   there is enough space between the calculator stack and the machine stack 
;   for another five-byte value.  It returns with BC holding the value 5 ready 
;   for any subsequent LDIR.

;; TEST-5-SP

TEST_5_SP:
        push de                 ; save
        push hl                 ; registers
        ld bc, $0005            ; an overhead of five bytes
        call TEST_ROOM          ; routine TEST-ROOM tests free RAM raising
                                ; an error if not.
        pop hl                  ; else restore
        pop de                  ; registers.
        ret                     ; return with BC set at 5.


; -----------------------------
; THE 'STACK NUMBER' SUBROUTINE
; -----------------------------
;   This routine is called to stack a hidden floating point number found in
;   a BASIC line.  It is also called to stack a numeric variable value, and
;   from BEEP, to stack an entry in the semi-tone table.  It is not part of the
;   calculator suite of routines.  On entry, HL points to the number to be 
;   stacked.

;; STACK-NUM

STACK_NUM:
        ld de, (STKEND)         ; Load destination from STKEND system variable.

        call MOVE_FP            ; Routine MOVE-FP puts on calculator stack
                                ; with a memory check.
        ld (STKEND), de         ; Set STKEND to next free location.

        ret                     ; Return.


; ---------------------------------
; Move a floating point number (31)
; ---------------------------------

; This simple routine is a 5-byte LDIR instruction
; that incorporates a memory check.
; When used as a calculator literal it duplicates the last value on the
; calculator stack.
; Unary so on entry HL points to last value, DE to stkend

;; duplicate
;; MOVE-FP

MOVE_FP:
        call TEST_5_SP          ; routine TEST-5-SP test free memory
                                ; and sets BC to 5.
        ldir                    ; copy the five bytes.
        ret                     ; return with DE addressing new STKEND
                                ; and HL addressing new last value.


; -------------------
; Stack literals ($34)
; -------------------
; When a calculator subroutine needs to put a value on the calculator
; stack that is not a regular constant this routine is called with a
; variable number of following data bytes that convey to the routine
; the integer or floating point form as succinctly as is possible.

;; stk-data

stk_data:
        ld hl, de               ; transfer STKEND
                                ; to HL for result.

;; STK-CONST

STK_CONST:
        call TEST_5_SP          ; routine TEST-5-SP tests that room exists
                                ; and sets BC to $05.

        exx                     ; switch to alternate set
        push hl                 ; save the pointer to next literal on stack
        exx                     ; switch back to main set

        ex (sp), hl             ; pointer to HL, destination to stack.

        push bc                 ; save BC - value 5 from test room ??.

        ld a, (hl)              ; fetch the byte following 'stk-data'
        and $C0                 ; isolate bits 7 and 6
        rlca                    ; rotate
        rlca                    ; to bits 1 and 0  range $00 - $03.
        ld c, a                 ; transfer to C
        inc c                   ; and increment to give number of bytes
                                ; to read. $01 - $04
        ld a, (hl)              ; reload the first byte
        and $3F                 ; mask off to give possible exponent.
        jr nz, FORM_EXP         ; forward to FORM-EXP if it was possible to
                                ; include the exponent.

; else byte is just a byte count and exponent comes next.

        inc hl                  ; address next byte and
        ld a, (hl)              ; pick up the exponent ( - $50).

;; FORM-EXP

FORM_EXP:
        add a, $50              ; now add $50 to form actual exponent
        ld (de), a              ; and load into first destination byte.
        ld a, $05               ; load accumulator with $05 and
        sub c                   ; subtract C to give count of trailing
                                ; zeros plus one.
        inc hl                  ; increment source
        inc de                  ; increment destination
        ld b, $00               ; prepare to copy
        ldir                    ; copy C bytes

        pop bc                  ; restore 5 counter to BC ??.

        ex (sp), hl             ; put HL on stack as next literal pointer
                                ; and the stack value - result pointer -
                                ; to HL.

        exx                     ; switch to alternate set.
        pop hl                  ; restore next literal pointer from stack
                                ; to H'L'.
        exx                     ; switch back to main set.

        ld b, a                 ; zero count to B
        xor a                   ; clear accumulator

;; STK-ZEROS

STK_ZEROS:
        dec b                   ; decrement B counter
        ret z                   ; return if zero.          >>
                                ; DE points to new STKEND
                                ; HL to new number.

        ldi (de), a             ; else load zero to destination
                                ; increase destination
        jr STK_ZEROS            ; loop back to STK-ZEROS until done.


; -------------------------------
; THE 'SKIP CONSTANTS' SUBROUTINE
; -------------------------------
;   This routine traverses variable-length entries in the table of constants,
;   stacking intermediate, unwanted constants onto a dummy calculator stack,
;   in the first five bytes of ROM.  The destination DE normally points to the
;   end of the calculator stack which might be in the normal place or in the
;   system variables area during E-LINE-NO; INT-TO-FP; stk-ten.  In any case,
;   it would be simpler all round if the routine just shoved unwanted values 
;   where it is going to stick the wanted value.  The instruction LD DE, $0000 
;   can be removed.

;; SKIP-CONS

SKIP_CONS:
        and a                   ; test if initially zero.

;; SKIP-NEXT

SKIP_NEXT:
        ret z                   ; return if zero.          >>

        push af                 ; save count.
        push de                 ; and normal STKEND

        ld de, $0000            ; dummy value for STKEND at start of ROM
                                ; Note. not a fault but this has to be
                                ; moved elsewhere when running in RAM.
                                ; e.g. with Expandor Systems 'Soft ROM'.
                                ; Better still, write to the normal place.
        call STK_CONST          ; routine STK-CONST works through variable
                                ; length records.

        pop de                  ; restore real STKEND
        pop af                  ; restore count
        dec a                   ; decrease
        jr SKIP_NEXT            ; loop back to SKIP-NEXT


; ------------------------------
; THE 'LOCATE MEMORY' SUBROUTINE
; ------------------------------
;   This routine, when supplied with a base address in HL and an index in A,
;   will calculate the address of the A'th entry, where each entry occupies
;   five bytes.  It is used for reading the semi-tone table and addressing
;   floating-point numbers in the calculator's memory area.
;   It is not possible to use this routine for the table of constants as these
;   six values are held in compressed format.

;; LOC-MEM

LOC_MEM:
        ld c, a                 ; store the original number $00-$1F.
        rlca                    ; X2 - double.
        rlca                    ; X4 - quadruple.
        add a, c                ; X5 - now add original to multiply by five.

        ld c, a                 ; place the result in the low byte.
        ld b, $00               ; set high byte to zero.
        add hl, bc              ; add to form address of start of number in HL.

        ret                     ; return.


; ------------------------------
; Get from memory area ($E0 etc.)
; ------------------------------
; Literals $E0 to $FF
; A holds $00-$1F offset.
; The calculator stack increases by 5 bytes.

;; get-mem-xx

get_mem_xx:
        push de                 ; save STKEND
        ld hl, (MEM)            ; MEM is base address of the memory cells.
        call LOC_MEM            ; routine LOC-MEM so that HL = first byte
        call MOVE_FP            ; routine MOVE-FP moves 5 bytes with memory
                                ; check.
                                ; DE now points to new STKEND.
        pop hl                  ; original STKEND is now RESULT pointer.
        ret                     ; return.


; --------------------------
; Stack a constant (A0 etc.)
; --------------------------
; This routine allows a one-byte instruction to stack up to 32 constants
; held in short form in a table of constants. In fact only 5 constants are
; required. On entry the A register holds the literal ANDed with 1F.
; It isn't very efficient and it would have been better to hold the
; numbers in full, five byte form and stack them in a similar manner
; to that used for semi-tone table values.

;; stk-const-xx

stk_const_xx:
        ld hl, de               ; save STKEND - required for result
        exx                     ; swap
        push hl                 ; save pointer to next literal
        ld hl, stk_zero         ; Address: stk-zero - start of table of
                                ; constants
        exx
        call SKIP_CONS          ; routine SKIP-CONS
        call STK_CONST          ; routine STK-CONST
        exx
        pop hl                  ; restore pointer to next literal.
        exx
        ret                     ; return.


; --------------------------------
; Store in a memory area ($C0 etc.)
; --------------------------------
; Offsets $C0 to $DF
; Although 32 memory storage locations can be addressed, only six
; $C0 to $C5 are required by the ROM and only the thirty bytes (6*5)
; required for these are allocated. Spectrum programmers who wish to
; use the floating point routines from assembly language may wish to
; alter the system variable MEM to point to 160 bytes of RAM to have 
; use the full range available.
; A holds the derived offset $00-$1F.
; This is a unary operation, so on entry HL points to the last value and DE 
; points to STKEND.

;; st-mem-xx

st_mem_xx:
        push hl                 ; save the result pointer.
        ex de, hl               ; transfer to DE.
        ld hl, (MEM)            ; fetch MEM the base of memory area.
        call LOC_MEM            ; routine LOC-MEM sets HL to the destination.
        ex de, hl               ; swap - HL is start, DE is destination.
        call MOVE_FP            ; routine MOVE-FP.
                                ; note. a short ld bc,5; ldir
                                ; the embedded memory check is not required
                                ; so these instructions would be faster.
        ex de, hl               ; DE = STKEND
        pop hl                  ; restore original result pointer
        ret                     ; return.


; -------------------------
; THE 'EXCHANGE' SUBROUTINE
; -------------------------
; (offset: $01 'exchange')
;   This routine swaps the last two values on the calculator stack.
;   On entry, as always with binary operations,
;   HL=first number, DE=second number
;   On exit, HL=result, DE=stkend.

;; exchange

exchange:
        ld b, $05               ; there are five bytes to be swapped

; start of loop.

;; SWAP-BYTE

SWAP_BYTE:
        ld a, (de)              ; each byte of second
        ld c, (hl)              ; each byte of first
        ex de, hl               ; swap pointers
        ld (de), a              ; store each byte of first
        ldi (hl), c             ; store each byte of second
                                ; advance both
        inc de                  ; pointers.
        djnz SWAP_BYTE          ; loop back to SWAP-BYTE until all 5 done.

        ex de, hl               ; even up the exchanges so that DE addresses
                                ; STKEND.

        ret                     ; return.


; ------------------------------
; THE 'SERIES GENERATOR' ROUTINE
; ------------------------------
; (offset: $86 'series-06')
; (offset: $88 'series-08')
; (offset: $8C 'series-0C')
;   The Spectrum uses Chebyshev polynomials to generate approximations for
;   SIN, ATN, LN and EXP.  These are named after the Russian mathematician
;   Pafnuty Chebyshev, born in 1821, who did much pioneering work on numerical
;   series.  As far as calculators are concerned, Chebyshev polynomials have an
;   advantage over other series, for example the Taylor series, as they can
;   reach an approximation in just six iterations for SIN, eight for EXP and
;   twelve for LN and ATN.  The mechanics of the routine are interesting but
;   for full treatment of how these are generated with demonstrations in
;   Sinclair BASIC see "The Complete Spectrum ROM Disassembly" by Dr Ian Logan
;   and Dr Frank O'Hara, published 1983 by Melbourne House.

;; series-xx

series_xx:
        ld b, a                 ; parameter $00 - $1F to B counter
        call GEN_ENT_1          ; routine GEN-ENT-1 is called.
                                ; A recursive call to a special entry point
                                ; in the calculator that puts the B register
                                ; in the system variable BREG. The return
                                ; address is the next location and where
                                ; the calculator will expect its first
                                ; instruction - now pointed to by HL'.
                                ; The previous pointer to the series of
                                ; five-byte numbers goes on the machine stack.

; The initialization phase.

        defb $31                ; ;duplicate       x,x
        defb $0F                ; ;addition        x+x
        defb $C0                ; ;st-mem-0        x+x
        defb $02                ; ;delete          .
        defb $A0                ; ;stk-zero        0
        defb $C2                ; ;st-mem-2        0

; a loop is now entered to perform the algebraic calculation for each of
; the numbers in the series

;; G-LOOP
        defb $31                ; ;duplicate       v,v.
        defb $E0                ; ;get-mem-0       v,v,x+2
        defb $04                ; ;multiply        v,v*x+2
        defb $E2                ; ;get-mem-2       v,v*x+2,v
        defb $C1                ; ;st-mem-1
        defb $03                ; ;subtract
        defb $38                ; ;end-calc

; the previous pointer is fetched from the machine stack to H'L' where it
; addresses one of the numbers of the series following the series literal.

        call stk_data           ; routine STK-DATA is called directly to
                                ; push a value and advance H'L'.
        call GEN_ENT_2          ; routine GEN-ENT-2 recursively re-enters
                                ; the calculator without disturbing
                                ; system variable BREG
                                ; H'L' value goes on the machine stack and is
                                ; then loaded as usual with the next address.

        defb $0F                ; ;addition
        defb $01                ; ;exchange
        defb $C2                ; ;st-mem-2
        defb $02                ; ;delete

        defb $35                ; ;dec-jr-nz
        defb $EE                ; ;back to L3453, G-LOOP

; when the counted loop is complete the final subtraction yields the result
; for example SIN X.

        defb $E1                ; ;get-mem-1
        defb $03                ; ;subtract
        defb $38                ; ;end-calc

        ret                     ; return with H'L' pointing to location
                                ; after last number in series.


; ---------------------------------
; THE 'ABSOLUTE MAGNITUDE' FUNCTION
; ---------------------------------
; (offset: $2A 'abs')
;   This calculator literal finds the absolute value of the last value,
;   integer or floating point, on calculator stack.

;; abs

abs:
        ld b, $FF               ; signal abs
        jr NEG_TEST             ; forward to NEG-TEST


; ---------------------------
; THE 'UNARY MINUS' OPERATION
; ---------------------------
; (offset: $1B 'negate')
;   Unary so on entry HL points to last value, DE to STKEND.

;; NEGATE
;; negate

negate:
        call TEST_ZERO          ; call routine TEST-ZERO and
        ret c                   ; return if so leaving zero unchanged.

        ld b, $00               ; signal negate required before joining
                                ; common code.

;; NEG-TEST

NEG_TEST:
        ld a, (hl)              ; load first byte and
        and a                   ; test for zero
        jr z, INT_CASE          ; forward to INT-CASE if a small integer

; for floating point numbers a single bit denotes the sign.

        inc hl                  ; address the first byte of mantissa.
        ld a, b                 ; action flag $FF=abs, $00=neg.
        and $80                 ; now         $80      $00
        or (hl)                 ; sets bit 7 for abs
        rla                     ; sets carry for abs and if number negative
        ccf                     ; complement carry flag
        rra                     ; and rotate back in altering sign
        ldd (hl), a             ; put the altered adjusted number back
                                ; HL points to result
        ret                     ; return with DE unchanged


; ---

; for integer numbers an entire byte denotes the sign.

;; INT-CASE

INT_CASE:
        push de                 ; save STKEND.

        push hl                 ; save pointer to the last value/result.

        call INT_FETCH          ; routine INT-FETCH puts integer in DE
                                ; and the sign in C.

        pop hl                  ; restore the result pointer.

        ld a, b                 ; $FF=abs, $00=neg
        or c                    ; $FF for abs, no change neg
        cpl                     ; $00 for abs, switched for neg
        ld c, a                 ; transfer result to sign byte.

        call INT_STORE          ; routine INT-STORE to re-write the integer.

        pop de                  ; restore STKEND.
        ret                     ; return.


; ---------------------
; THE 'SIGNUM' FUNCTION
; ---------------------
; (offset: $29 'sgn')
;   This routine replaces the last value on the calculator stack,
;   which may be in floating point or integer form, with the integer values
;   zero if zero, with one if positive and  with -minus one if negative.

;; sgn

sgn:
        call TEST_ZERO          ; call routine TEST-ZERO and
        ret c                   ; exit if so as no change is required.

        push de                 ; save pointer to STKEND.

        ld de, $0001            ; the result will be 1.
        inc hl                  ; skip over the exponent.
        rl (hl)                 ; rotate the sign bit into the carry flag.
        dec hl                  ; step back to point to the result.
        sbc a, a                ; byte will be $FF if negative, $00 if positive.
        ld c, a                 ; store the sign byte in the C register.
        call INT_STORE          ; routine INT-STORE to overwrite the last
                                ; value with 0001 and sign.

        pop de                  ; restore STKEND.
        ret                     ; return.


; -----------------
; THE 'IN' FUNCTION
; -----------------
; (offset: $2C 'in')
;   This function reads a byte from an input port.

;; in

in_func:
        call FIND_INT2          ; Routine FIND-INT2 puts port address in BC.
                                ; All 16 bits are put on the address line.

        in a, (c)               ; Read the port.

        jr IN_PK_STK            ; exit to STACK-A (via IN-PK-STK to save a byte
                                ; of instruction code).


; -------------------
; THE 'PEEK' FUNCTION
; -------------------
; (offset: $2B 'peek')
;   This function returns the contents of a memory address.
;   The entire address space can be peeked including the ROM.

;; peek

peek:
        call FIND_INT2          ; routine FIND-INT2 puts address in BC.
        ld a, (bc)              ; load contents into A register.

;; IN-PK-STK

IN_PK_STK:
        jp STACK_A              ; exit via STACK-A to put the value on the
                                ; calculator stack.


; ------------------
; THE 'USR' FUNCTION
; ------------------
; (offset: $2d 'usr-no')
;   The USR function followed by a number 0-65535 is the method by which
;   the Spectrum invokes machine code programs. This function returns the
;   contents of the BC register pair.
;   Note. that STACK-BC re-initializes the IY register if a user-written
;   program has altered it.

;; usr-no

usr_no:
        call FIND_INT2          ; routine FIND-INT2 to fetch the
                                ; supplied address into BC.

        ld hl, STACK_BC         ; address: STACK-BC is
        push hl                 ; pushed onto the machine stack.
        push bc                 ; then the address of the machine code
                                ; routine.

        ret                     ; make an indirect jump to the routine
                                ; and, hopefully, to STACK-BC also.


; -------------------------
; THE 'USR STRING' FUNCTION
; -------------------------
; (offset: $19 'usr-$')
;   The user function with a one-character string argument, calculates the
;   address of the User Defined Graphic character that is in the string.
;   As an alternative, the ASCII equivalent, upper or lower case,
;   may be supplied. This provides a user-friendly method of redefining
;   the 21 User Definable Graphics e.g.
;   POKE USR "a", BIN 10000000 will put a dot in the top left corner of the
;   character 144.
;   Note. the curious double check on the range. With 26 UDGs the first check
;   only is necessary. With anything less the second check only is required.
;   It is highly likely that the first check was written by Steven Vickers.

;; usr-$

usr__:
        call STK_FETCH          ; routine STK-FETCH fetches the string
                                ; parameters.
        dec bc                  ; decrease BC by
        ld a, b                 ; one to test
        or c                    ; the length.
        jr nz, REPORT_A         ; to REPORT-A if not a single character.

        ld a, (de)              ; fetch the character
        call ALPHA              ; routine ALPHA sets carry if 'A-Z' or 'a-z'.
        jr c, USR_RANGE         ; forward to USR-RANGE if ASCII.

        sub $90                 ; make UDGs range 0-20d
        jr c, REPORT_A          ; to REPORT-A if too low. e.g. usr " ".

        cp $15                  ; Note. this test is not necessary.
        jr nc, REPORT_A         ; to REPORT-A if higher than 20.

        inc a                   ; make range 1-21d to match LSBs of ASCII

;; USR-RANGE

USR_RANGE:
        dec a                   ; make range of bits 0-4 start at zero
        add a, a                ; multiply by eight
        add a, a                ; and lose any set bits
        add a, a                ; range now 0 - 25*8
        cp $A8                  ; compare to 21*8
        jr nc, REPORT_A         ; to REPORT-A if originally higher
                                ; than 'U','u' or graphics U.

        ld bc, (UDG)            ; fetch the UDG system variable value.
        add a, c                ; add the offset to character
        ld c, a                 ; and store back in register C.
        jr nc, USR_STACK        ; forward to USR-STACK if no overflow.

        inc b                   ; increment high byte.

;; USR-STACK

USR_STACK:
        jp STACK_BC             ; jump back and exit via STACK-BC to store


; ---

;; REPORT-A

REPORT_A:
        rst $08                 ; ERROR-1
        defb $09                ; Error Report: Invalid argument

; ------------------------------
; THE 'TEST FOR ZERO' SUBROUTINE
; ------------------------------
;   Test if top value on calculator stack is zero.  The carry flag is set if 
;   the last value is zero but no registers are altered.
;   All five bytes will be zero but first four only need be tested.
;   On entry, HL points to the exponent the first byte of the value.

;; TEST-ZERO

TEST_ZERO:
        push hl                 ; preserve HL which is used to address.
        push bc                 ; preserve BC which is used as a store.
        ld b, a                 ; preserve A in B.

        ldi a, (hl)             ; load first byte to accumulator
                                ; advance.
        or (hl)                 ; OR with second byte and clear carry.
        inc hl                  ; advance.
        or (hl)                 ; OR with third byte.
        inc hl                  ; advance.
        or (hl)                 ; OR with fourth byte.

        ld a, b                 ; restore A without affecting flags.
        pop bc                  ; restore the saved
        pop hl                  ; registers.

        ret nz                  ; return if not zero and with carry reset.

        scf                     ; set the carry flag.
        ret                     ; return with carry set if zero.


; --------------------------------
; THE 'GREATER THAN ZERO' OPERATOR
; --------------------------------
; (offset: $37 'greater-0' )
;   Test if the last value on the calculator stack is greater than zero.
;   This routine is also called directly from the end-tests of the comparison 
;   routine.

;; GREATER-0
;; greater-0

greater_0:
        call TEST_ZERO          ; routine TEST-ZERO
        ret c                   ; return if was zero as this
                                ; is also the Boolean 'false' value.

        ld a, $FF               ; prepare XOR mask for sign bit
        jr SIGN_TO_C            ; forward to SIGN-TO-C
                                ; to put sign in carry
                                ; (carry will become set if sign is positive)
                                ; and then overwrite location with 1 or 0
                                ; as appropriate.


; ------------------
; THE 'NOT' FUNCTION
; ------------------
; (offset: $30 'not')
;   This overwrites the last value with 1 if it was zero else with zero
;   if it was any other value.
;
;   e.g. NOT 0 returns 1, NOT 1 returns 0, NOT -3 returns 0.
;
;   The subroutine is also called directly from the end-tests of the comparison
;   operator.

;; NOT
;; not

not:
        call TEST_ZERO          ; routine TEST-ZERO sets carry if zero

        jr FP_0_1               ; to FP-0/1 to overwrite operand with
                                ; 1 if carry is set else to overwrite with zero.


; ------------------------------
; THE 'LESS THAN ZERO' OPERATION
; ------------------------------
; (offset: $36 'less-0' )
;   Destructively test if last value on calculator stack is less than zero.
;   Bit 7 of second byte will be set if so.

;; less-0

less_0:
        xor a                   ; set XOR mask to zero
                                ; (carry will become set if sign is negative).

;   transfer sign of mantissa to Carry Flag.

;; SIGN-TO-C

SIGN_TO_C:
        inc hl                  ; address 2nd byte.
        xor (hl)                ; bit 7 of HL will be set if number is negative.
        dec hl                  ; address 1st byte again.
        rlca                    ; rotate bit 7 of A to carry.

; ----------------------------
; THE 'ZERO OR ONE' SUBROUTINE
; ----------------------------
;   This routine places an integer value of zero or one at the addressed 
;   location of the calculator stack or MEM area.  The value one is written if 
;   carry is set on entry else zero.

;; FP-0/1

FP_0_1:
        push hl                 ; save pointer to the first byte
        ld a, $00               ; load accumulator with zero - without
                                ; disturbing flags.
        ldi (hl), a             ; zero to first byte
                                ; address next
        ldi (hl), a             ; zero to 2nd byte
                                ; address low byte of integer
        rla                     ; carry to bit 0 of A
        ld (hl), a              ; load one or zero to low byte.
        rra                     ; restore zero to accumulator.
        inc hl                  ; address high byte of integer.
        ldi (hl), a             ; put a zero there.
                                ; address fifth byte.
        ld (hl), a              ; put a zero there.
        pop hl                  ; restore pointer to the first byte.
        ret                     ; return.


; -----------------
; THE 'OR' OPERATOR
; -----------------
; (offset: $07 'or' )
; The Boolean OR operator. e.g. X OR Y
; The result is zero if both values are zero else a non-zero value.
;
; e.g.    0 OR 0  returns 0.
;        -3 OR 0  returns -3.
;         0 OR -3 returns 1.
;        -3 OR 2  returns 1.
;
; A binary operation.
; On entry HL points to first operand (X) and DE to second operand (Y).

;; or

or_func:
        ex de, hl               ; make HL point to second number
        call TEST_ZERO          ; routine TEST-ZERO
        ex de, hl               ; restore pointers
        ret c                   ; return if result was zero - first operand,
                                ; now the last value, is the result.

        scf                     ; set carry flag
        jr FP_0_1               ; back to FP-0/1 to overwrite the first operand
                                ; with the value 1.



; ---------------------------------
; THE 'NUMBER AND NUMBER' OPERATION
; ---------------------------------
; (offset: $08 'no-&-no')
;   The Boolean AND operator.
;
;   e.g.    -3 AND 2  returns -3.
;           -3 AND 0  returns 0.
;            0 and -2 returns 0.
;            0 and 0  returns 0.
;
;   Compare with OR routine above.

;; no-&-no

no___no:
        ex de, hl               ; make HL address second operand.

        call TEST_ZERO          ; routine TEST-ZERO sets carry if zero.

        ex de, hl               ; restore pointers.
        ret nc                  ; return if second non-zero, first is result.

;

        and a                   ; else clear carry.
        jr FP_0_1               ; back to FP-0/1 to overwrite first operand
                                ; with zero for return value.


; ---------------------------------
; THE 'STRING AND NUMBER' OPERATION
; ---------------------------------
; (offset: $10 'str-&-no')
;   e.g. "You Win" AND score>99 will return the string if condition is true
;   or the null string if false.

;; str-&-no

str___no:
        ex de, hl               ; make HL point to the number.
        call TEST_ZERO          ; routine TEST-ZERO.
        ex de, hl               ; restore pointers.
        ret nc                  ; return if number was not zero - the string
                                ; is the result.

;   if the number was zero (false) then the null string must be returned by
;   altering the length of the string on the calculator stack to zero.

        push de                 ; save pointer to the now obsolete number
                                ; (which will become the new STKEND)

        dec de                  ; point to the 5th byte of string descriptor.
        xor a                   ; clear the accumulator.
        ldd (de), a             ; place zero in high byte of length.
                                ; address low byte of length.
        ld (de), a              ; place zero there - now the null string.

        pop de                  ; restore pointer - new STKEND.
        ret                     ; return.


; ---------------------------
; THE 'COMPARISON' OPERATIONS
; ---------------------------
; (offset: $0A 'no-gr-eql')
; (offset: $0B 'nos-neql')
; (offset: $0C 'no-grtr')
; (offset: $0D 'no-less')
; (offset: $0E 'nos-eql')
; (offset: $11 'str-l-eql')
; (offset: $12 'str-gr-eql')
; (offset: $13 'strs-neql')
; (offset: $14 'str-grtr')
; (offset: $15 'str-less')
; (offset: $16 'strs-eql')

;   True binary operations.
;   A single entry point is used to evaluate six numeric and six string
;   comparisons. On entry, the calculator literal is in the B register and
;   the two numeric values, or the two string parameters, are on the 
;   calculator stack.
;   The individual bits of the literal are manipulated to group similar
;   operations although the SUB 8 instruction does nothing useful and merely
;   alters the string test bit.
;   Numbers are compared by subtracting one from the other, strings are 
;   compared by comparing every character until a mismatch, or the end of one
;   or both, is reached.
;
;   Numeric Comparisons.
;   --------------------
;   The 'x>y' example is the easiest as it employs straight-thru logic.
;   Number y is subtracted from x and the result tested for greater-0 yielding
;   a final value 1 (true) or 0 (false). 
;   For 'x<y' the same logic is used but the two values are first swapped on the
;   calculator stack. 
;   For 'x=y' NOT is applied to the subtraction result yielding true if the
;   difference was zero and false with anything else. 
;   The first three numeric comparisons are just the opposite of the last three
;   so the same processing steps are used and then a final NOT is applied.
;
; literal    Test   No  sub 8       ExOrNot  1st RRCA  exch sub  ?   End-Tests
; =========  ====   == ======== === ======== ========  ==== ===  =  === === ===
; no-l-eql   x<=y   09 00000001 dec 00000000 00000000  ---- x-y  ?  --- >0? NOT
; no-gr-eql  x>=y   0A 00000010 dec 00000001 10000000c swap y-x  ?  --- >0? NOT
; nos-neql   x<>y   0B 00000011 dec 00000010 00000001  ---- x-y  ?  NOT --- NOT
; no-grtr    x>y    0C 00000100  -  00000100 00000010  ---- x-y  ?  --- >0? ---
; no-less    x<y    0D 00000101  -  00000101 10000010c swap y-x  ?  --- >0? ---
; nos-eql    x=y    0E 00000110  -  00000110 00000011  ---- x-y  ?  NOT --- ---
;
;                                                           comp -> C/F
;                                                           ====    ===
; str-l-eql  x$<=y$ 11 00001001 dec 00001000 00000100  ---- x$y$ 0  !or >0? NOT
; str-gr-eql x$>=y$ 12 00001010 dec 00001001 10000100c swap y$x$ 0  !or >0? NOT
; strs-neql  x$<>y$ 13 00001011 dec 00001010 00000101  ---- x$y$ 0  !or >0? NOT
; str-grtr   x$>y$  14 00001100  -  00001100 00000110  ---- x$y$ 0  !or >0? ---
; str-less   x$<y$  15 00001101  -  00001101 10000110c swap y$x$ 0  !or >0? ---
; strs-eql   x$=y$  16 00001110  -  00001110 00000111  ---- x$y$ 0  !or >0? ---
;
;   String comparisons are a little different in that the eql/neql carry flag
;   from the 2nd RRCA is, as before, fed into the first of the end tests but
;   along the way it gets modified by the comparison process. The result on the
;   stack always starts off as zero and the carry fed in determines if NOT is 
;   applied to it. So the only time the greater-0 test is applied is if the
;   stack holds zero which is not very efficient as the test will always yield
;   zero. The most likely explanation is that there were once separate end tests
;   for numbers and strings.

;; no-l-eql,etc.

no_l_eql_etc_:
        ld a, b                 ; transfer literal to accumulator.
        sub $08                 ; subtract eight - which is not useful.

        bit 2, a                ; isolate '>', '<', '='.

        jr nz, EX_OR_NOT        ; skip to EX-OR-NOT with these.

        dec a                   ; else make $00-$02, $08-$0A to match bits 0-2.

;; EX-OR-NOT

EX_OR_NOT:
        rrca                    ; the first RRCA sets carry for a swap.
        jr nc, NU_OR_STR        ; forward to NU-OR-STR with other 8 cases

; for the other 4 cases the two values on the calculator stack are exchanged.

        push af                 ; save A and carry.
        push hl                 ; save HL - pointer to first operand.
                                ; (DE points to second operand).

        call exchange           ; routine exchange swaps the two values.
                                ; (HL = second operand, DE = STKEND)

        pop de                  ; DE = first operand
        ex de, hl               ; as we were.
        pop af                  ; restore A and carry.

; Note. it would be better if the 2nd RRCA preceded the string test.
; It would save two duplicate bytes and if we also got rid of that sub 8 
; at the beginning we wouldn't have to alter which bit we test.

;; NU-OR-STR

NU_OR_STR:
        bit 2, a                ; test if a string comparison.
        jr nz, STRINGS          ; forward to STRINGS if so.

; continue with numeric comparisons.

        rrca                    ; 2nd RRCA causes eql/neql to set carry.
        push af                 ; save A and carry

        call subtract           ; routine subtract leaves result on stack.
        jr END_TESTS            ; forward to END-TESTS


; ---

;; STRINGS

STRINGS:
        rrca                    ; 2nd RRCA causes eql/neql to set carry.
        push af                 ; save A and carry.

        call STK_FETCH          ; routine STK-FETCH gets 2nd string params
        push de                 ; save start2 *.
        push bc                 ; and the length.

        call STK_FETCH          ; routine STK-FETCH gets 1st string
                                ; parameters - start in DE, length in BC.
        pop hl                  ; restore length of second to HL.

; A loop is now entered to compare, by subtraction, each corresponding character
; of the strings. For each successful match, the pointers are incremented and 
; the lengths decreased and the branch taken back to here. If both string 
; remainders become null at the same time, then an exact match exists.

;; BYTE-COMP

BYTE_COMP:
        ld a, h                 ; test if the second string
        or l                    ; is the null string and hold flags.

        ex (sp), hl             ; put length2 on stack, bring start2 to HL *.
        ld a, b                 ; hi byte of length1 to A

        jr nz, SEC_PLUS         ; forward to SEC-PLUS if second not null.

        or c                    ; test length of first string.

;; SECND-LOW

SECND_LOW:
        pop bc                  ; pop the second length off stack.
        jr z, BOTH_NULL         ; forward to BOTH-NULL if first string is also
                                ; of zero length.

; the true condition - first is longer than second (SECND-LESS)

        pop af                  ; restore carry (set if eql/neql)
        ccf                     ; complement carry flag.
                                ; Note. equality becomes false.
                                ; Inequality is true. By swapping or applying
                                ; a terminal 'not', all comparisons have been
                                ; manipulated so that this is success path.
        jr STR_TEST             ; forward to leave via STR-TEST


; ---
; the branch was here with a match

;; BOTH-NULL

BOTH_NULL:
        pop af                  ; restore carry - set for eql/neql
        jr STR_TEST             ; forward to STR-TEST


; ---  
; the branch was here when 2nd string not null and low byte of first is yet
; to be tested.


;; SEC-PLUS

SEC_PLUS:
        or c                    ; test the length of first string.
        jr z, FRST_LESS         ; forward to FRST-LESS if length is zero.

; both strings have at least one character left.

        ld a, (de)              ; fetch character of first string.
        sub (hl)                ; subtract with that of 2nd string.
        jr c, FRST_LESS         ; forward to FRST-LESS if carry set

        jr nz, SECND_LOW        ; back to SECND-LOW and then STR-TEST
                                ; if not exact match.

        dec bc                  ; decrease length of 1st string.
        inc de                  ; increment 1st string pointer.

        inc hl                  ; increment 2nd string pointer.
        ex (sp), hl             ; swap with length on stack
        dec hl                  ; decrement 2nd string length
        jr BYTE_COMP            ; back to BYTE-COMP


; ---
; the false condition.

;; FRST-LESS

FRST_LESS:
        pop bc                  ; discard length
        pop af                  ; pop A
        and a                   ; clear the carry for false result.

; ---
; exact match and x$>y$ rejoin here

;; STR-TEST

STR_TEST:
        push af                 ; save A and carry

        rst $28                 ; ; FP-CALC
        defb $A0                ; ;stk-zero      an initial false value.
        defb $38                ; ;end-calc

; both numeric and string paths converge here.

;; END-TESTS

END_TESTS:
        pop af                  ; pop carry  - will be set if eql/neql
        push af                 ; save it again.

        call c, not             ; routine NOT sets true(1) if equal(0)
                                ; or, for strings, applies true result.

        pop af                  ; pop carry and
        push af                 ; save A

        call nc, greater_0      ; routine GREATER-0 tests numeric subtraction
                                ; result but also needlessly tests the string
                                ; value for zero - it must be.

        pop af                  ; pop A
        rrca                    ; the third RRCA - test for '<=', '>=' or '<>'.
        call nc, not            ; apply a terminal NOT if so.
        ret                     ; return.


; ------------------------------------
; THE 'STRING CONCATENATION' OPERATION
; ------------------------------------
; (offset: $17 'strs-add')
;   This literal combines two strings into one e.g. LET a$ = b$ + c$
;   The two parameters of the two strings to be combined are on the stack.

;; strs-add

strs_add:
        call STK_FETCH          ; routine STK-FETCH fetches string parameters
                                ; and deletes calculator stack entry.
        push de                 ; save start address.
        push bc                 ; and length.

        call STK_FETCH          ; routine STK-FETCH for first string
        pop hl                  ; re-fetch first length
        push hl                 ; and save again
        push de                 ; save start of second string
        push bc                 ; and its length.

        add hl, bc              ; add the two lengths.
        ld bc, hl               ; transfer to BC
                                ; and create
        rst $30                 ; BC-SPACES in workspace.
                                ; DE points to start of space.

        call STK_STO__          ; routine STK-STO-$ stores parameters
                                ; of new string updating STKEND.

        pop bc                  ; length of first
        pop hl                  ; address of start
        ld a, b                 ; test for
        or c                    ; zero length.
        jr z, OTHER_STR         ; to OTHER-STR if null string

        ldir                    ; copy string to workspace.

;; OTHER-STR

OTHER_STR:
        pop bc                  ; now second length
        pop hl                  ; and start of string
        ld a, b                 ; test this one
        or c                    ; for zero length
        jr z, STK_PNTRS         ; skip forward to STK-PNTRS if so as complete.

        ldir                    ; else copy the bytes.
                                ; and continue into next routine which
                                ; sets the calculator stack pointers.

; -----------------------------------
; THE 'SET STACK POINTERS' SUBROUTINE
; -----------------------------------
;   Register DE is set to STKEND and HL, the result pointer, is set to five 
;   locations below this.
;   This routine is used when it is inconvenient to save these values at the
;   time the calculator stack is manipulated due to other activity on the 
;   machine stack.
;   This routine is also used to terminate the VAL and READ-IN  routines for
;   the same reason and to initialize the calculator stack at the start of
;   the CALCULATE routine.

;; STK-PNTRS

STK_PNTRS:
        ld hl, (STKEND)         ; fetch STKEND value from system variable.
        ld de, $FFFB            ; the value -5
        push hl                 ; push STKEND value.

        add hl, de              ; subtract 5 from HL.

        pop de                  ; pop STKEND to DE.
        ret                     ; return.


; -------------------
; THE 'CHR$' FUNCTION
; -------------------
; (offset: $2f 'chr$')
;   This function returns a single character string that is a result of 
;   converting a number in the range 0-255 to a string e.g. CHR$ 65 = "A".

;; chrs

chrs:
        call FP_TO_A            ; routine FP-TO-A puts the number in A.

        jr c, REPORT_Bd         ; forward to REPORT-Bd if overflow
        jr nz, REPORT_Bd        ; forward to REPORT-Bd if negative

        push af                 ; save the argument.

        ld bc, $0001            ; one space required.
        rst $30                 ; BC-SPACES makes DE point to start

        pop af                  ; restore the number.

        ld (de), a              ; and store in workspace

        call STK_STO__          ; routine STK-STO-$ stacks descriptor.

        ex de, hl               ; make HL point to result and DE to STKEND.
        ret                     ; return.


; ---

;; REPORT-Bd

REPORT_Bd:
        rst $08                 ; ERROR-1
        defb $0A                ; Error Report: Integer out of range

; ----------------------------
; THE 'VAL and VAL$' FUNCTIONS
; ----------------------------
; (offset: $1d 'val')
; (offset: $18 'val$')
;   VAL treats the characters in a string as a numeric expression.
;   e.g. VAL "2.3" = 2.3, VAL "2+4" = 6, VAL ("2" + "4") = 24.
;   VAL$ treats the characters in a string as a string expression.
;   e.g. VAL$ (z$+"(2)") = a$(2) if z$ happens to be "a$".

;; val
;; val$

val_:
        ld hl, (CH_ADD)         ; fetch value of system variable CH_ADD
        push hl                 ; and save on the machine stack.
        ld a, b                 ; fetch the literal (either $1D or $18).
        add a, $E3              ; add $E3 to form $00 (setting carry) or $FB.
        sbc a, a                ; now form $FF bit 6 = numeric result
                                ; or $00 bit 6 = string result.
        push af                 ; save this mask on the stack

        call STK_FETCH          ; routine STK-FETCH fetches the string operand
                                ; from calculator stack.

        push de                 ; save the address of the start of the string.
        inc bc                  ; increment the length for a carriage return.

        rst $30                 ; BC-SPACES creates the space in workspace.
        pop hl                  ; restore start of string to HL.
        ld (CH_ADD), de         ; load CH_ADD with start DE in workspace.

        push de                 ; save the start in workspace
        ldir                    ; copy string from program or variables or
                                ; workspace to the workspace area.
        ex de, hl               ; end of string + 1 to HL
        dec hl                  ; decrement HL to point to end of new area.
        ld (hl), $0D            ; insert a carriage return at end.
        res 7, (iy+FLAGS-IY0)   ; update FLAGS  - signal checking syntax.
        call SCANNING           ; routine SCANNING evaluates string
                                ; expression and result.

        rst $18                 ; GET-CHAR fetches next character.
        cp $0D                  ; is it the expected carriage return ?
        jr nz, V_RPORT_C        ; forward to V-RPORT-C if not
                                ; 'Nonsense in BASIC'.

        pop hl                  ; restore start of string in workspace.
        pop af                  ; restore expected result flag (bit 6).
        xor (iy+FLAGS-IY0)      ; xor with FLAGS now updated by SCANNING.
        and $40                 ; test bit 6 - should be zero if result types
                                ; match.

;; V-RPORT-C

V_RPORT_C:
        jp nz, REPORT_C         ; jump back to REPORT-C with a result mismatch.

        ld (CH_ADD), hl         ; set CH_ADD to the start of the string again.
        set 7, (iy+FLAGS-IY0)   ; update FLAGS  - signal running program.
        call SCANNING           ; routine SCANNING evaluates the string
                                ; in full leaving result on calculator stack.

        pop hl                  ; restore saved character address in program.
        ld (CH_ADD), hl         ; and reset the system variable CH_ADD.

        jr STK_PNTRS            ; back to exit via STK-PNTRS.
                                ; resetting the calculator stack pointers
                                ; HL and DE from STKEND as it wasn't possible
                                ; to preserve them during this routine.


; -------------------
; THE 'STR$' FUNCTION
; -------------------
; (offset: $2e 'str$')
;   This function produces a string comprising the characters that would appear
;   if the numeric argument were printed.
;   e.g. STR$ (1/10) produces "0.1".

;; str$

str_:
        ld bc, $0001            ; create an initial byte in workspace
        rst $30                 ; using BC-SPACES restart.

        ld (K_CUR), hl          ; set system variable K_CUR to new location.
        push hl                 ; and save start on machine stack also.

        ld hl, (CURCHL)         ; fetch value of system variable CURCHL
        push hl                 ; and save that too.

        ld a, $FF               ; select system channel 'R'.
        call CHAN_OPEN          ; routine CHAN-OPEN opens it.
        call PRINT_FP           ; routine PRINT-FP outputs the number to
                                ; workspace updating K-CUR.

        pop hl                  ; restore current channel.
        call CHAN_FLAG          ; routine CHAN-FLAG resets flags.

        pop de                  ; fetch saved start of string to DE.
        ld hl, (K_CUR)          ; load HL with end of string from K_CUR.

        and a                   ; prepare for true subtraction.
        sbc hl, de              ; subtract start from end to give length.
        ld bc, hl               ; transfer the length to
                                ; the BC register pair.

        call STK_STO__          ; routine STK-STO-$ stores string parameters
                                ; on the calculator stack.

        ex de, hl               ; HL = last value, DE = STKEND.
        ret                     ; return.


; ------------------------
; THE 'READ-IN' SUBROUTINE
; ------------------------
; (offset: $1a 'read-in')
;   This is the calculator literal used by the INKEY$ function when a '#'
;   is encountered after the keyword.
;   INKEY$ # does not interact correctly with the keyboard, #0 or #1, and
;   its uses are for other channels.

;; read-in

read_in:
        call FIND_INT1          ; routine FIND-INT1 fetches stream to A
        cp $10                  ; compare with 16 decimal.
        jp nc, REPORT_Bb        ; JUMP to REPORT-Bb if not in range 0 - 15.
                                ; 'Integer out of range'
                                ; (REPORT-Bd is within range)

        ld hl, (CURCHL)         ; fetch current channel CURCHL
        push hl                 ; save it

        call CHAN_OPEN          ; routine CHAN-OPEN opens channel

        call INPUT_AD           ; routine INPUT-AD - the channel must have an
                                ; input stream or else error here from stream
                                ; stub.
        ld bc, $0000            ; initialize length of string to zero
        jr nc, R_I_STORE        ; forward to R-I-STORE if no key detected.

        inc c                   ; increase length to one.

        rst $30                 ; BC-SPACES creates space for one character
                                ; in workspace.
        ld (de), a              ; the character is inserted.

;; R-I-STORE

R_I_STORE:
        call STK_STO__          ; routine STK-STO-$ stacks the string
                                ; parameters.
        pop hl                  ; restore current channel address

        call CHAN_FLAG          ; routine CHAN-FLAG resets current channel
                                ; system variable and flags.

        jp STK_PNTRS            ; jump back to STK-PNTRS


; -------------------
; THE 'CODE' FUNCTION
; -------------------
; (offset: $1c 'code')
;   Returns the ASCII code of a character or first character of a string
;   e.g. CODE "Aardvark" = 65, CODE "" = 0.

;; code

code:
        call STK_FETCH          ; routine STK-FETCH to fetch and delete the
                                ; string parameters.
                                ; DE points to the start, BC holds the length.

        ld a, b                 ; test length
        or c                    ; of the string.
        jr z, STK_CODE          ; skip to STK-CODE with zero if the null string.

        ld a, (de)              ; else fetch the first character.

;; STK-CODE

STK_CODE:
        jp STACK_A              ; jump back to STACK-A (with memory check)


; ------------------
; THE 'LEN' FUNCTION
; ------------------
; (offset: $1e 'len')
;   Returns the length of a string.
;   In Sinclair BASIC strings can be more than twenty thousand characters long
;   so a sixteen-bit register is required to store the length

;; len

len:
        call STK_FETCH          ; Routine STK-FETCH to fetch and delete the
                                ; string parameters from the calculator stack.
                                ; Register BC now holds the length of string.

        jp STACK_BC             ; Jump back to STACK-BC to save result on the
                                ; calculator stack (with memory check).


; -------------------------------------
; THE 'DECREASE THE COUNTER' SUBROUTINE
; -------------------------------------
; (offset: $35 'dec-jr-nz')
;   The calculator has an instruction that decrements a single-byte
;   pseudo-register and makes consequential relative jumps just like
;   the Z80's DJNZ instruction.

;; dec-jr-nz

dec_jr_nz:
        exx                     ; switch in set that addresses code

        push hl                 ; save pointer to offset byte
        ld hl, BREG             ; address BREG in system variables
        dec (hl)                ; decrement it
        pop hl                  ; restore pointer

        jr nz, JUMP_2           ; to JUMP-2 if not zero

        inc hl                  ; step past the jump length.
        exx                     ; switch in the main set.
        ret                     ; return.


; Note. as a general rule the calculator avoids using the IY register
; otherwise the cumbersome 4 instructions in the middle could be replaced by
; dec (iy+$2d) - three bytes instead of six.


; ---------------------
; THE 'JUMP' SUBROUTINE
; ---------------------
; (offset: $33 'jump')
;   This enables the calculator to perform relative jumps just like the Z80 
;   chip's JR instruction.

;; jump
;; JUMP

JUMP:
        exx                     ; switch in pointer set

;; JUMP-2

JUMP_2:
        ld e, (hl)              ; the jump byte 0-127 forward, 128-255 back.
        ld a, e                 ; transfer to accumulator.
        rla                     ; if backward jump, carry is set.
        sbc a, a                ; will be $FF if backward or $00 if forward.
        ld d, a                 ; transfer to high byte.
        add hl, de              ; advance calculator pointer forward or back.

        exx                     ; switch back.
        ret                     ; return.


; --------------------------
; THE 'JUMP-TRUE' SUBROUTINE
; --------------------------
; (offset: $00 'jump-true')
;   This enables the calculator to perform conditional relative jumps dependent
;   on whether the last test gave a true result.

;; jump-true

jump_true:
        inc de                  ; Collect the
        inc de                  ; third byte
        ldd a, (de)             ; of the test
                                ; result and
        dec de                  ; backtrack.

        and a                   ; Is result 0 or 1 ?
        jr nz, JUMP             ; Back to JUMP if true (1).

        exx                     ; Else switch in the pointer set.
        inc hl                  ; Step past the jump length.
        exx                     ; Switch in the main set.
        ret                     ; Return.


; -------------------------
; THE 'END-CALC' SUBROUTINE
; -------------------------
; (offset: $38 'end-calc')
;   The end-calc literal terminates a mini-program written in the Spectrum's
;   internal language.

;; end-calc

end_calc:
        pop af                  ; Drop the calculator return address RE-ENTRY
        exx                     ; Switch to the other set.

        ex (sp), hl             ; Transfer H'L' to machine stack for the
                                ; return address.
                                ; When exiting recursion, then the previous
                                ; pointer is transferred to H'L'.

        exx                     ; Switch back to main set.
        ret                     ; Return.



; ------------------------
; THE 'MODULUS' SUBROUTINE 
; ------------------------
; (offset: $32 'n-mod-m')
; (n1,n2 -- r,q)  
;   Similar to FORTH's 'divide mod' /MOD
;   On the Spectrum, this is only used internally by the RND function and could
;   have been implemented inline.  On the ZX81, this calculator routine was also
;   used by PRINT-FP.

;; n-mod-m

n_mod_m:
        rst $28                 ; ; FP-CALC          17, 3.
        defb $C0                ; ;st-mem-0          17, 3.
        defb $02                ; ;delete            17.
        defb $31                ; ;duplicate         17, 17.
        defb $E0                ; ;get-mem-0         17, 17, 3.
        defb $05                ; ;division          17, 17/3.
        defb $27                ; ;int               17, 5.
        defb $E0                ; ;get-mem-0         17, 5, 3.
        defb $01                ; ;exchange          17, 3, 5.
        defb $C0                ; ;st-mem-0          17, 3, 5.
        defb $04                ; ;multiply          17, 15.
        defb $03                ; ;subtract          2.
        defb $E0                ; ;get-mem-0         2, 5.
        defb $38                ; ;end-calc          2, 5.

        ret                     ; return.



; ------------------
; THE 'INT' FUNCTION
; ------------------
; (offset $27: 'int' )
; This function returns the integer of x, which is just the same as truncate
; for positive numbers. The truncate literal truncates negative numbers
; upwards so that -3.4 gives -3 whereas the BASIC INT function has to
; truncate negative numbers down so that INT -3.4 is -4.
; It is best to work through using, say, +-3.4 as examples.

;; int

int:
        rst $28                 ; ; FP-CALC              x.    (= 3.4 or -3.4).
        defb $31                ; ;duplicate             x, x.
        defb $36                ; ;less-0                x, (1/0)
        defb $00                ; ;jump-true             x, (1/0)
        defb $04                ; ;to L36B7, X-NEG

        defb $3A                ; ;truncate              trunc 3.4 = 3.
        defb $38                ; ;end-calc              3.

        ret                     ; return with + int x on stack.


; ---


;; X-NEG

X_NEG:
        defb $31                ; ;duplicate             -3.4, -3.4.
        defb $3A                ; ;truncate              -3.4, -3.
        defb $C0                ; ;st-mem-0              -3.4, -3.
        defb $03                ; ;subtract              -.4
        defb $E0                ; ;get-mem-0             -.4, -3.
        defb $01                ; ;exchange              -3, -.4.
        defb $30                ; ;not                   -3, (0).
        defb $00                ; ;jump-true             -3.
        defb $03                ; ;to L36C2, EXIT        -3.

        defb $A1                ; ;stk-one               -3, 1.
        defb $03                ; ;subtract              -4.

;; EXIT

EXIT:
        defb $38                ; ;end-calc              -4.

        ret                     ; return.



; ------------------
; THE 'EXP' FUNCTION
; ------------------
; (offset $26: 'exp')
;   The exponential function EXP x is equal to e^x, where e is the mathematical
;   name for a number approximated to 2.718281828.
;   ERROR 6 if argument is more than about 88.

;; EXP
;; exp

exp:
        rst $28                 ; ; FP-CALC
        defb $3D                ; ;re-stack      (not required - mult will do)
        defb $34                ; ;stk-data
        defb $F1                ; ;Exponent: $81, Bytes: 4
        defb $38, $AA, $3B, $29 ; ;
        defb $04                ; ;multiply
        defb $31                ; ;duplicate
        defb $27                ; ;int
        defb $C3                ; ;st-mem-3
        defb $03                ; ;subtract
        defb $31                ; ;duplicate
        defb $0F                ; ;addition
        defb $A1                ; ;stk-one
        defb $03                ; ;subtract
        defb $88                ; ;series-08
        defb $13                ; ;Exponent: $63, Bytes: 1
        defb $36                ; ;(+00,+00,+00)
        defb $58                ; ;Exponent: $68, Bytes: 2
        defb $65, $66           ; ;(+00,+00)
        defb $9D                ; ;Exponent: $6D, Bytes: 3
        defb $78, $65, $40      ; ;(+00)
        defb $A2                ; ;Exponent: $72, Bytes: 3
        defb $60, $32, $C9      ; ;(+00)
        defb $E7                ; ;Exponent: $77, Bytes: 4
        defb $21, $F7, $AF, $24 ; ;
        defb $EB                ; ;Exponent: $7B, Bytes: 4
        defb $2F, $B0, $B0, $14 ; ;
        defb $EE                ; ;Exponent: $7E, Bytes: 4
        defb $7E, $BB, $94, $58 ; ;
        defb $F1                ; ;Exponent: $81, Bytes: 4
        defb $3A, $7E, $F8, $CF ; ;
        defb $E3                ; ;get-mem-3
        defb $38                ; ;end-calc

        call FP_TO_A            ; routine FP-TO-A
        jr nz, N_NEGTV          ; to N-NEGTV

        jr c, REPORT_6b         ; to REPORT-6b
                                ; 'Number too big'

        add a, (hl)
        jr nc, RESULT_OK        ; to RESULT-OK


;; REPORT-6b

REPORT_6b:
        rst $08                 ; ERROR-1
        defb $05                ; Error Report: Number too big

; ---

;; N-NEGTV

N_NEGTV:
        jr c, RSLT_ZERO         ; to RSLT-ZERO

        sub (hl)
        jr nc, RSLT_ZERO        ; to RSLT-ZERO

        neg                     ; Negate

;; RESULT-OK

RESULT_OK:
        ld (hl), a
        ret                     ; return.


; ---


;; RSLT-ZERO

RSLT_ZERO:
        rst $28                 ; ; FP-CALC
        defb $02                ; ;delete
        defb $A0                ; ;stk-zero
        defb $38                ; ;end-calc

        ret                     ; return.



; --------------------------------
; THE 'NATURAL LOGARITHM' FUNCTION 
; --------------------------------
; (offset $25: 'ln')
;   Function to calculate the natural logarithm (to the base e ). 
;   Natural logarithms were devised in 1614 by well-traveled Scotsman John 
;   Napier who noted
;   "Nothing doth more molest and hinder calculators than the multiplications,
;    divisions, square and cubical extractions of great numbers".
;
;   Napier's logarithms enabled the above operations to be accomplished by 
;   simple addition and subtraction simplifying the navigational and 
;   astronomical calculations which beset his age.
;   Napier's logarithms were quickly overtaken by logarithms to the base 10
;   devised, in conjunction with Napier, by Henry Briggs a Cambridge-educated 
;   professor of Geometry at Oxford University. These simplified the layout
;   of the tables enabling humans to easily scale calculations.
;
;   It is only recently with the introduction of pocket calculators and machines
;   like the ZX Spectrum that natural logarithms are once more at the fore,
;   although some computers retain logarithms to the base ten.
;
;   'Natural' logarithms are powers to the base 'e', which like 'pi' is a 
;   naturally occurring number in branches of mathematics.
;   Like 'pi' also, 'e' is an irrational number and starts 2.718281828...
;
;   The tabular use of logarithms was that to multiply two numbers one looked
;   up their two logarithms in the tables, added them together and then looked 
;   for the result in a table of antilogarithms to give the desired product.
;
;   The EXP function is the BASIC equivalent of a calculator's 'antiln' function 
;   and by picking any two numbers, 1.72 and 6.89 say,
;     10 PRINT EXP ( LN 1.72 + LN 6.89 ) 
;   will give just the same result as
;     20 PRINT 1.72 * 6.89.
;   Division is accomplished by subtracting the two logs.
;
;   Napier also mentioned "square and cubicle extractions". 
;   To raise a number to the power 3, find its 'ln', multiply by 3 and find the 
;   'antiln'.  e.g. PRINT EXP( LN 4 * 3 )  gives 64.
;   Similarly to find the n'th root divide the logarithm by 'n'.
;   The ZX81 ROM used PRINT EXP ( LN 9 / 2 ) to find the square root of the 
;   number 9. The Napieran square root function is just a special case of 
;   the 'to_power' function. A cube root or indeed any root/power would be just
;   as simple.

;   First test that the argument to LN is a positive, non-zero number.
;   Error A if the argument is 0 or negative.

;; ln

ln:
        rst $28                 ; ; FP-CALC
        defb $3D                ; ;re-stack
        defb $31                ; ;duplicate
        defb $37                ; ;greater-0
        defb $00                ; ;jump-true
        defb $04                ; ;to L371C, VALID

        defb $38                ; ;end-calc


;; REPORT-Ab

REPORT_Ab:
        rst $08                 ; ERROR-1
        defb $09                ; Error Report: Invalid argument

;; VALID

VALID:
        defb $A0                ; ;stk-zero              Note. not
        defb $02                ; ;delete                necessary.
        defb $38                ; ;end-calc
        ld a, (hl)

        ld (hl), $80
        call STACK_A            ; routine STACK-A

        rst $28                 ; ; FP-CALC
        defb $34                ; ;stk-data
        defb $38                ; ;Exponent: $88, Bytes: 1
        defb $00                ; ;(+00,+00,+00)
        defb $03                ; ;subtract
        defb $01                ; ;exchange
        defb $31                ; ;duplicate
        defb $34                ; ;stk-data
        defb $F0                ; ;Exponent: $80, Bytes: 4
        defb $4C, $CC, $CC, $CD ; ;
        defb $03                ; ;subtract
        defb $37                ; ;greater-0
        defb $00                ; ;jump-true
        defb $08                ; ;to L373D, GRE.8

        defb $01                ; ;exchange
        defb $A1                ; ;stk-one
        defb $03                ; ;subtract
        defb $01                ; ;exchange
        defb $38                ; ;end-calc

        inc (hl)

        rst $28                 ; ; FP-CALC

;; GRE.8

GRE_8:
        defb $01                ; ;exchange
        defb $34                ; ;stk-data
        defb $F0                ; ;Exponent: $80, Bytes: 4
        defb $31, $72, $17, $F8 ; ;
        defb $04                ; ;multiply
        defb $01                ; ;exchange
        defb $A2                ; ;stk-half
        defb $03                ; ;subtract
        defb $A2                ; ;stk-half
        defb $03                ; ;subtract
        defb $31                ; ;duplicate
        defb $34                ; ;stk-data
        defb $32                ; ;Exponent: $82, Bytes: 1
        defb $20                ; ;(+00,+00,+00)
        defb $04                ; ;multiply
        defb $A2                ; ;stk-half
        defb $03                ; ;subtract
        defb $8C                ; ;series-0C
        defb $11                ; ;Exponent: $61, Bytes: 1
        defb $AC                ; ;(+00,+00,+00)
        defb $14                ; ;Exponent: $64, Bytes: 1
        defb $09                ; ;(+00,+00,+00)
        defb $56                ; ;Exponent: $66, Bytes: 2
        defb $DA, $A5           ; ;(+00,+00)
        defb $59                ; ;Exponent: $69, Bytes: 2
        defb $30, $C5           ; ;(+00,+00)
        defb $5C                ; ;Exponent: $6C, Bytes: 2
        defb $90, $AA           ; ;(+00,+00)
        defb $9E                ; ;Exponent: $6E, Bytes: 3
        defb $70, $6F, $61      ; ;(+00)
        defb $A1                ; ;Exponent: $71, Bytes: 3
        defb $CB, $DA, $96      ; ;(+00)
        defb $A4                ; ;Exponent: $74, Bytes: 3
        defb $31, $9F, $B4      ; ;(+00)
        defb $E7                ; ;Exponent: $77, Bytes: 4
        defb $A0, $FE, $5C, $FC ; ;
        defb $EA                ; ;Exponent: $7A, Bytes: 4
        defb $1B, $43, $CA, $36 ; ;
        defb $ED                ; ;Exponent: $7D, Bytes: 4
        defb $A7, $9C, $7E, $5E ; ;
        defb $F0                ; ;Exponent: $80, Bytes: 4
        defb $6E, $23, $80, $93 ; ;
        defb $04                ; ;multiply
        defb $0F                ; ;addition
        defb $38                ; ;end-calc

        ret                     ; return.



; -----------------------------
; THE 'TRIGONOMETRIC' FUNCTIONS
; -----------------------------
; Trigonometry is rocket science. It is also used by carpenters and pyramid
; builders. 
; Some uses can be quite abstract but the principles can be seen in simple
; right-angled triangles. Triangles have some special properties -
;
; 1) The sum of the three angles is always PI radians (180 degrees).
;    Very helpful if you know two angles and wish to find the third.
; 2) In any right-angled triangle the sum of the squares of the two shorter
;    sides is equal to the square of the longest side opposite the right-angle.
;    Very useful if you know the length of two sides and wish to know the
;    length of the third side.
; 3) Functions sine, cosine and tangent enable one to calculate the length 
;    of an unknown side when the length of one other side and an angle is 
;    known.
; 4) Functions arcsin, arccosine and arctan enable one to calculate an unknown
;    angle when the length of two of the sides is known.

; --------------------------------
; THE 'REDUCE ARGUMENT' SUBROUTINE
; --------------------------------
; (offset $39: 'get-argt')
;
; This routine performs two functions on the angle, in radians, that forms
; the argument to the sine and cosine functions.
; First it ensures that the angle 'wraps round'. That if a ship turns through 
; an angle of, say, 3*PI radians (540 degrees) then the net effect is to turn 
; through an angle of PI radians (180 degrees).
; Secondly it converts the angle in radians to a fraction of a right angle,
; depending within which quadrant the angle lies, with the periodicity 
; resembling that of the desired sine value.
; The result lies in the range -1 to +1.              
;
;                     90 deg.
; 
;                     (pi/2)
;              II       +1        I
;                       |
;        sin+      |\   |   /|    sin+
;        cos-      | \  |  / |    cos+
;        tan-      |  \ | /  |    tan+
;                  |   \|/)  |           
; 180 deg. (pi) 0 -|----+----|-- 0  (0)   0 degrees
;                  |   /|\   |
;        sin-      |  / | \  |    sin-
;        cos-      | /  |  \ |    cos+
;        tan+      |/   |   \|    tan-
;                       |
;              III      -1       IV
;                     (3pi/2)
;
;                     270 deg.
;

;; get-argt

get_argt:
        rst $28                 ; ; FP-CALC      X.
        defb $3D                ; ;re-stack      (not rquired done by mult)
        defb $34                ; ;stk-data
        defb $EE                ; ;Exponent: $7E,
                                ; ;Bytes: 4
        defb $22, $F9, $83, $6E ; ;              X, 1/(2*PI)
        defb $04                ; ;multiply      X/(2*PI) = fraction
        defb $31                ; ;duplicate
        defb $A2                ; ;stk-half
        defb $0F                ; ;addition
        defb $27                ; ;int

        defb $03                ; ;subtract      now range -.5 to .5

        defb $31                ; ;duplicate
        defb $0F                ; ;addition      now range -1 to 1.
        defb $31                ; ;duplicate
        defb $0F                ; ;addition      now range -2 to +2.

; quadrant I (0 to +1) and quadrant IV (-1 to 0) are now correct.
; quadrant II ranges +1 to +2.
; quadrant III ranges -2 to -1.

        defb $31                ; ;duplicate     Y, Y.
        defb $2A                ; ;abs           Y, abs(Y).    range 1 to 2
        defb $A1                ; ;stk-one       Y, abs(Y), 1.
        defb $03                ; ;subtract      Y, abs(Y)-1.  range 0 to 1
        defb $31                ; ;duplicate     Y, Z, Z.
        defb $37                ; ;greater-0     Y, Z, (1/0).

        defb $C0                ; ;st-mem-0         store as possible sign
                                ; ;                 for cosine function.

        defb $00                ; ;jump-true
        defb $04                ; ;to L37A1, ZPLUS  with quadrants II and III.

; else the angle lies in quadrant I or IV and value Y is already correct.

        defb $02                ; ;delete        Y.   delete the test value.
        defb $38                ; ;end-calc      Y.

        ret                     ; return.       with Q1 and Q4           >>>


; ---

; the branch was here with quadrants II (0 to 1) and III (1 to 0).
; Y will hold -2 to -1 if this is quadrant III.

;; ZPLUS

ZPLUS:
        defb $A1                ; ;stk-one         Y, Z, 1.
        defb $03                ; ;subtract        Y, Z-1.       Q3 = 0 to -1
        defb $01                ; ;exchange        Z-1, Y.
        defb $36                ; ;less-0          Z-1, (1/0).
        defb $00                ; ;jump-true       Z-1.
        defb $02                ; ;to L37A8, YNEG
                                ; ;if angle in quadrant III

; else angle is within quadrant II (-1 to 0)

        defb $1B                ; ;negate          range +1 to 0.

;; YNEG

YNEG:
        defb $38                ; ;end-calc        quadrants II and III correct.

        ret                     ; return.



; ---------------------
; THE 'COSINE' FUNCTION
; ---------------------
; (offset $20: 'cos')
; Cosines are calculated as the sine of the opposite angle rectifying the 
; sign depending on the quadrant rules. 
;
;
;           /|
;        h /y|
;         /  |o
;        /x  |
;       /----|    
;         a
;
; The cosine of angle x is the adjacent side (a) divided by the hypotenuse 1.
; However if we examine angle y then a/h is the sine of that angle.
; Since angle x plus angle y equals a right-angle, we can find angle y by 
; subtracting angle x from pi/2.
; However it's just as easy to reduce the argument first and subtract the
; reduced argument from the value 1 (a reduced right-angle).
; It's even easier to subtract 1 from the angle and rectify the sign.
; In fact, after reducing the argument, the absolute value of the argument
; is used and rectified using the test result stored in mem-0 by 'get-argt'
; for that purpose.
;

;; cos

cos:
        rst $28                 ; ; FP-CALC              angle in radians.
        defb $39                ; ;get-argt              X     reduce -1 to +1

        defb $2A                ; ;abs                   ABS X.   0 to 1
        defb $A1                ; ;stk-one               ABS X, 1.
        defb $03                ; ;subtract              now opposite angle
                                ; ;                      although sign is -ve.

        defb $E0                ; ;get-mem-0             fetch the sign indicator
        defb $00                ; ;jump-true
        defb $06                ; ;fwd to L37B7, C-ENT
                                ; ;forward to common code if in QII or QIII.

        defb $1B                ; ;negate                else make sign +ve.
        defb $33                ; ;jump
        defb $03                ; ;fwd to L37B7, C-ENT
                                ; ; with quadrants I and IV.

; -------------------
; THE 'SINE' FUNCTION
; -------------------
; (offset $1F: 'sin')
; This is a fundamental transcendental function from which others such as cos
; and tan are directly, or indirectly, derived.
; It uses the series generator to produce Chebyshev polynomials.
;
;
;           /|
;        1 / |
;         /  |x
;        /a  |
;       /----|    
;         y
;
; The 'get-argt' function is designed to modify the angle and its sign 
; in line with the desired sine value and afterwards it can launch straight
; into common code.

;; sin

sin:
        rst $28                 ; ; FP-CALC      angle in radians
        defb $39                ; ;get-argt      reduce - sign now correct.

;; C-ENT

C_ENT:
        defb $31                ; ;duplicate
        defb $31                ; ;duplicate
        defb $04                ; ;multiply
        defb $31                ; ;duplicate
        defb $0F                ; ;addition
        defb $A1                ; ;stk-one
        defb $03                ; ;subtract

        defb $86                ; ;series-06
        defb $14                ; ;Exponent: $64, Bytes: 1
        defb $E6                ; ;(+00,+00,+00)
        defb $5C                ; ;Exponent: $6C, Bytes: 2
        defb $1F, $0B           ; ;(+00,+00)
        defb $A3                ; ;Exponent: $73, Bytes: 3
        defb $8F, $38, $EE      ; ;(+00)
        defb $E9                ; ;Exponent: $79, Bytes: 4
        defb $15, $63, $BB, $23 ; ;
        defb $EE                ; ;Exponent: $7E, Bytes: 4
        defb $92, $0D, $CD, $ED ; ;
        defb $F1                ; ;Exponent: $81, Bytes: 4
        defb $23, $5D, $1B, $EA ; ;
        defb $04                ; ;multiply
        defb $38                ; ;end-calc

        ret                     ; return.


; ----------------------
; THE 'TANGENT' FUNCTION
; ----------------------
; (offset $21: 'tan')
;
; Evaluates tangent x as    sin(x) / cos(x).
;
;
;           /|
;        h / |
;         /  |o
;        /x  |
;       /----|    
;         a
;
; the tangent of angle x is the ratio of the length of the opposite side 
; divided by the length of the adjacent side. As the opposite length can 
; be calculates using sin(x) and the adjacent length using cos(x) then 
; the tangent can be defined in terms of the previous two functions.

; Error 6 if the argument, in radians, is too close to one like pi/2
; which has an infinite tangent. e.g. PRINT TAN (PI/2)  evaluates as 1/0.
; Similarly PRINT TAN (3*PI/2), TAN (5*PI/2) etc.

;; tan

tan:
        rst $28                 ; ; FP-CALC          x.
        defb $31                ; ;duplicate         x, x.
        defb $1F                ; ;sin               x, sin x.
        defb $01                ; ;exchange          sin x, x.
        defb $20                ; ;cos               sin x, cos x.
        defb $05                ; ;division          sin x/cos x (= tan x).
        defb $38                ; ;end-calc          tan x.

        ret                     ; return.


; ---------------------
; THE 'ARCTAN' FUNCTION
; ---------------------
; (Offset $24: 'atn')
; the inverse tangent function with the result in radians.
; This is a fundamental transcendental function from which others such as asn
; and acs are directly, or indirectly, derived.
; It uses the series generator to produce Chebyshev polynomials.

;; atn

atn:
        call re_stack           ; routine re-stack
        ld a, (hl)              ; fetch exponent byte.
        cp $81                  ; compare to that for 'one'
        jr c, SMALL             ; forward, if less, to SMALL

        rst $28                 ; ; FP-CALC
        defb $A1                ; ;stk-one
        defb $1B                ; ;negate
        defb $01                ; ;exchange
        defb $05                ; ;division
        defb $31                ; ;duplicate
        defb $36                ; ;less-0
        defb $A3                ; ;stk-pi/2
        defb $01                ; ;exchange
        defb $00                ; ;jump-true
        defb $06                ; ;to L37FA, CASES

        defb $1B                ; ;negate
        defb $33                ; ;jump
        defb $03                ; ;to L37FA, CASES

;; SMALL

SMALL:
        rst $28                 ; ; FP-CALC
        defb $A0                ; ;stk-zero

;; CASES

CASES:
        defb $01                ; ;exchange
        defb $31                ; ;duplicate
        defb $31                ; ;duplicate
        defb $04                ; ;multiply
        defb $31                ; ;duplicate
        defb $0F                ; ;addition
        defb $A1                ; ;stk-one
        defb $03                ; ;subtract
        defb $8C                ; ;series-0C
        defb $10                ; ;Exponent: $60, Bytes: 1
        defb $B2                ; ;(+00,+00,+00)
        defb $13                ; ;Exponent: $63, Bytes: 1
        defb $0E                ; ;(+00,+00,+00)
        defb $55                ; ;Exponent: $65, Bytes: 2
        defb $E4, $8D           ; ;(+00,+00)
        defb $58                ; ;Exponent: $68, Bytes: 2
        defb $39, $BC           ; ;(+00,+00)
        defb $5B                ; ;Exponent: $6B, Bytes: 2
        defb $98, $FD           ; ;(+00,+00)
        defb $9E                ; ;Exponent: $6E, Bytes: 3
        defb $00, $36, $75      ; ;(+00)
        defb $A0                ; ;Exponent: $70, Bytes: 3
        defb $DB, $E8, $B4      ; ;(+00)
        defb $63                ; ;Exponent: $73, Bytes: 2
        defb $42, $C4           ; ;(+00,+00)
        defb $E6                ; ;Exponent: $76, Bytes: 4
        defb $B5, $09, $36, $BE ; ;
        defb $E9                ; ;Exponent: $79, Bytes: 4
        defb $36, $73, $1B, $5D ; ;
        defb $EC                ; ;Exponent: $7C, Bytes: 4
        defb $D8, $DE, $63, $BE ; ;
        defb $F0                ; ;Exponent: $80, Bytes: 4
        defb $61, $A1, $B3, $0C ; ;
        defb $04                ; ;multiply
        defb $0F                ; ;addition
        defb $38                ; ;end-calc

        ret                     ; return.



; ---------------------
; THE 'ARCSIN' FUNCTION
; ---------------------
; (Offset $22: 'asn')
;   The inverse sine function with result in radians.
;   Derived from arctan function above.
;   Error A unless the argument is between -1 and +1 inclusive.
;   Uses an adaptation of the formula asn(x) = atn(x/sqr(1-x*x))
;
;
;                 /|
;                / |
;              1/  |x
;              /a  |
;             /----|    
;               y
;
;   e.g. We know the opposite side (x) and hypotenuse (1) 
;   and we wish to find angle a in radians.
;   We can derive length y by Pythagoras and then use ATN instead. 
;   Since y*y + x*x = 1*1 (Pythagoras Theorem) then
;   y=sqr(1-x*x)                         - no need to multiply 1 by itself.
;   So, asn(a) = atn(x/y)
;   or more fully,
;   asn(a) = atn(x/sqr(1-x*x))

;   Close but no cigar.

;   While PRINT ATN (x/SQR (1-x*x)) gives the same results as PRINT ASN x,
;   it leads to division by zero when x is 1 or -1.
;   To overcome this, 1 is added to y giving half the required angle and the 
;   result is then doubled. 
;   That is, PRINT ATN (x/(SQR (1-x*x) +1)) *2
;
;   GEOMETRIC PROOF.
;
;
;               . /|
;            .  c/ |
;         .     /1 |x
;      . c   b /a  |
;    ---------/----|    
;      1      y
;
;   By creating an isosceles triangle with two equal sides of 1, angles c and 
;   c are also equal. If b+c+c = 180 degrees and b+a = 180 degrees then c=a/2.
;
;   A value higher than 1 gives the required error as attempting to find  the
;   square root of a negative number generates an error in Sinclair BASIC.

;; asn

asn:
        rst $28                 ; ; FP-CALC      x.
        defb $31                ; ;duplicate     x, x.
        defb $31                ; ;duplicate     x, x, x.
        defb $04                ; ;multiply      x, x*x.
        defb $A1                ; ;stk-one       x, x*x, 1.
        defb $03                ; ;subtract      x, x*x-1.
        defb $1B                ; ;negate        x, 1-x*x.
        defb $28                ; ;sqr           x, sqr(1-x*x) = y
        defb $A1                ; ;stk-one       x, y, 1.
        defb $0F                ; ;addition      x, y+1.
        defb $05                ; ;division      x/y+1.
        defb $24                ; ;atn           a/2       (half the angle)
        defb $31                ; ;duplicate     a/2, a/2.
        defb $0F                ; ;addition      a.
        defb $38                ; ;end-calc      a.

        ret                     ; return.



; ---------------------
; THE 'ARCCOS' FUNCTION
; ---------------------
; (Offset $23: 'acs')
; the inverse cosine function with the result in radians.
; Error A unless the argument is between -1 and +1.
; Result in range 0 to pi.
; Derived from asn above which is in turn derived from the preceding atn.
; It could have been derived directly from atn using acs(x) = atn(sqr(1-x*x)/x).
; However, as sine and cosine are horizontal translations of each other,
; uses acs(x) = pi/2 - asn(x)

; e.g. the arccosine of a known x value will give the required angle b in 
; radians.
; We know, from above, how to calculate the angle a using asn(x). 
; Since the three angles of any triangle add up to 180 degrees, or pi radians,
; and the largest angle in this case is a right-angle (pi/2 radians), then
; we can calculate angle b as pi/2 (both angles) minus asn(x) (angle a).
; 
;
;           /|
;        1 /b|
;         /  |x
;        /a  |
;       /----|    
;         y
;

;; acs

acs:
        rst $28                 ; ; FP-CALC      x.
        defb $22                ; ;asn           asn(x).
        defb $A3                ; ;stk-pi/2      asn(x), pi/2.
        defb $03                ; ;subtract      asn(x) - pi/2.
        defb $1B                ; ;negate        pi/2 -asn(x)  =  acs(x).
        defb $38                ; ;end-calc      acs(x).

        ret                     ; return.



; --------------------------
; THE 'SQUARE ROOT' FUNCTION
; --------------------------
; (Offset $28: 'sqr')
; This routine is remarkable for its brevity - 7 bytes.
; It wasn't written here but in the ZX81 where the programmers had to squeeze
; a bulky operating system into an 8K ROM. It simply calculates 
; the square root by stacking the value .5 and continuing into the 'to-power'
; routine. With more space available the much faster Newton-Raphson method
; could have been used as on the Jupiter Ace.

;; sqr

sqr:
        rst $28                 ; ; FP-CALC
        defb $31                ; ;duplicate
        defb $30                ; ;not
        defb $00                ; ;jump-true
        defb $1E                ; ;to L386C, LAST

        defb $A2                ; ;stk-half
        defb $38                ; ;end-calc


; ------------------------------
; THE 'EXPONENTIATION' OPERATION
; ------------------------------
; (Offset $06: 'to-power')
; This raises the first number X to the power of the second number Y.
; As with the ZX80,
; 0 ^ 0 = 1.
; 0 ^ +n = 0.
; 0 ^ -n = arithmetic overflow.
;

;; to-power

to_power:
        rst $28                 ; ; FP-CALC              X, Y.
        defb $01                ; ;exchange              Y, X.
        defb $31                ; ;duplicate             Y, X, X.
        defb $30                ; ;not                   Y, X, (1/0).
        defb $00                ; ;jump-true
        defb $07                ; ;to L385D, XIS0   if X is zero.

;   else X is non-zero. Function 'ln' will catch a negative value of X.

        defb $25                ; ;ln                    Y, LN X.
        defb $04                ; ;multiply              Y * LN X.
        defb $38                ; ;end-calc

        jp exp                  ; jump back to EXP routine   ->


; ---

;   these routines form the three simple results when the number is zero.
;   begin by deleting the known zero to leave Y the power factor.

;; XIS0

XIS0:
        defb $02                ; ;delete                Y.
        defb $31                ; ;duplicate             Y, Y.
        defb $30                ; ;not                   Y, (1/0).
        defb $00                ; ;jump-true
        defb $09                ; ;to L386A, ONE         if Y is zero.

        defb $A0                ; ;stk-zero              Y, 0.
        defb $01                ; ;exchange              0, Y.
        defb $37                ; ;greater-0             0, (1/0).
        defb $00                ; ;jump-true             0.
        defb $06                ; ;to L386C, LAST        if Y was any positive
                                ; ;                      number.

;   else force division by zero thereby raising an Arithmetic overflow error.
;   There are some one and two-byte alternatives but perhaps the most formal
;   might have been to use end-calc; rst 08; defb 05.

        defb $A1                ; ;stk-one               0, 1.
        defb $01                ; ;exchange              1, 0.
        defb $05                ; ;division              1/0        ouch!

; ---

;; ONE

ONE:
        defb $02                ; ;delete                .
        defb $A1                ; ;stk-one               1.

;; LAST

LAST:
        defb $38                ; ;end-calc              last value is 1 or 0.

        ret                     ; return.


;   "Everything should be made as simple as possible, but not simpler"
;   - Albert Einstein, 1879-1955.

; ---------------------
; THE 'SPARE' LOCATIONS
; ---------------------

;; spare

spare:
        defb $FF, $FF


        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF


; -------------------------------
; THE 'ZX SPECTRUM CHARACTER SET'
; -------------------------------

;; char-set

; $20 - Character: ' '          CHR$(32)


char_set:
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

; $21 - Character: '!'          CHR$(33)

        defb %00000000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00000000
        defb %00010000
        defb %00000000

; $22 - Character: '"'          CHR$(34)

        defb %00000000
        defb %00100100
        defb %00100100
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

; $23 - Character: '#'          CHR$(35)

        defb %00000000
        defb %00100100
        defb %01111110
        defb %00100100
        defb %00100100
        defb %01111110
        defb %00100100
        defb %00000000

; $24 - Character: '$'          CHR$(36)

        defb %00000000
        defb %00001000
        defb %00111110
        defb %00101000
        defb %00111110
        defb %00001010
        defb %00111110
        defb %00001000

; $25 - Character: '%'          CHR$(37)

        defb %00000000
        defb %01100010
        defb %01100100
        defb %00001000
        defb %00010000
        defb %00100110
        defb %01000110
        defb %00000000

; $26 - Character: '&'          CHR$(38)

        defb %00000000
        defb %00010000
        defb %00101000
        defb %00010000
        defb %00101010
        defb %01000100
        defb %00111010
        defb %00000000

; $27 - Character: '''          CHR$(39)

        defb %00000000
        defb %00001000
        defb %00010000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

; $28 - Character: '('          CHR$(40)

        defb %00000000
        defb %00000100
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00000100
        defb %00000000

; $29 - Character: ')'          CHR$(41)

        defb %00000000
        defb %00100000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00100000
        defb %00000000

; $2A - Character: '*'          CHR$(42)

        defb %00000000
        defb %00000000
        defb %00010100
        defb %00001000
        defb %00111110
        defb %00001000
        defb %00010100
        defb %00000000

; $2B - Character: '+'          CHR$(43)

        defb %00000000
        defb %00000000
        defb %00001000
        defb %00001000
        defb %00111110
        defb %00001000
        defb %00001000
        defb %00000000

; $2C - Character: ','          CHR$(44)

        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00001000
        defb %00001000
        defb %00010000

; $2D - Character: '-'          CHR$(45)

        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00111110
        defb %00000000
        defb %00000000
        defb %00000000

; $2E - Character: '.'          CHR$(46)

        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00000000

; $2F - Character: '/'          CHR$(47)

        defb %00000000
        defb %00000000
        defb %00000010
        defb %00000100
        defb %00001000
        defb %00010000
        defb %00100000
        defb %00000000

; $30 - Character: '0'          CHR$(48)

        defb %00000000
        defb %00111100
        defb %01000110
        defb %01001010
        defb %01010010
        defb %01100010
        defb %00111100
        defb %00000000

; $31 - Character: '1'          CHR$(49)

        defb %00000000
        defb %00011000
        defb %00101000
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00111110
        defb %00000000

; $32 - Character: '2'          CHR$(50)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %00000010
        defb %00111100
        defb %01000000
        defb %01111110
        defb %00000000

; $33 - Character: '3'          CHR$(51)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %00001100
        defb %00000010
        defb %01000010
        defb %00111100
        defb %00000000

; $34 - Character: '4'          CHR$(52)

        defb %00000000
        defb %00001000
        defb %00011000
        defb %00101000
        defb %01001000
        defb %01111110
        defb %00001000
        defb %00000000

; $35 - Character: '5'          CHR$(53)

        defb %00000000
        defb %01111110
        defb %01000000
        defb %01111100
        defb %00000010
        defb %01000010
        defb %00111100
        defb %00000000

; $36 - Character: '6'          CHR$(54)

        defb %00000000
        defb %00111100
        defb %01000000
        defb %01111100
        defb %01000010
        defb %01000010
        defb %00111100
        defb %00000000

; $37 - Character: '7'          CHR$(55)

        defb %00000000
        defb %01111110
        defb %00000010
        defb %00000100
        defb %00001000
        defb %00010000
        defb %00010000
        defb %00000000

; $38 - Character: '8'          CHR$(56)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %00111100
        defb %01000010
        defb %01000010
        defb %00111100
        defb %00000000

; $39 - Character: '9'          CHR$(57)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %01000010
        defb %00111110
        defb %00000010
        defb %00111100
        defb %00000000

; $3A - Character: ':'          CHR$(58)

        defb %00000000
        defb %00000000
        defb %00000000
        defb %00010000
        defb %00000000
        defb %00000000
        defb %00010000
        defb %00000000

; $3B - Character: ';'          CHR$(59)

        defb %00000000
        defb %00000000
        defb %00010000
        defb %00000000
        defb %00000000
        defb %00010000
        defb %00010000
        defb %00100000

; $3C - Character: '<'          CHR$(60)

        defb %00000000
        defb %00000000
        defb %00000100
        defb %00001000
        defb %00010000
        defb %00001000
        defb %00000100
        defb %00000000

; $3D - Character: '='          CHR$(61)

        defb %00000000
        defb %00000000
        defb %00000000
        defb %00111110
        defb %00000000
        defb %00111110
        defb %00000000
        defb %00000000

; $3E - Character: '>'          CHR$(62)

        defb %00000000
        defb %00000000
        defb %00010000
        defb %00001000
        defb %00000100
        defb %00001000
        defb %00010000
        defb %00000000

; $3F - Character: '?'          CHR$(63)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %00000100
        defb %00001000
        defb %00000000
        defb %00001000
        defb %00000000

; $40 - Character: '@'          CHR$(64)

        defb %00000000
        defb %00111100
        defb %01001010
        defb %01010110
        defb %01011110
        defb %01000000
        defb %00111100
        defb %00000000

; $41 - Character: 'A'          CHR$(65)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %01000010
        defb %01111110
        defb %01000010
        defb %01000010
        defb %00000000

; $42 - Character: 'B'          CHR$(66)

        defb %00000000
        defb %01111100
        defb %01000010
        defb %01111100
        defb %01000010
        defb %01000010
        defb %01111100
        defb %00000000

; $43 - Character: 'C'          CHR$(67)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %01000000
        defb %01000000
        defb %01000010
        defb %00111100
        defb %00000000

; $44 - Character: 'D'          CHR$(68)

        defb %00000000
        defb %01111000
        defb %01000100
        defb %01000010
        defb %01000010
        defb %01000100
        defb %01111000
        defb %00000000

; $45 - Character: 'E'          CHR$(69)

        defb %00000000
        defb %01111110
        defb %01000000
        defb %01111100
        defb %01000000
        defb %01000000
        defb %01111110
        defb %00000000

; $46 - Character: 'F'          CHR$(70)

        defb %00000000
        defb %01111110
        defb %01000000
        defb %01111100
        defb %01000000
        defb %01000000
        defb %01000000
        defb %00000000

; $47 - Character: 'G'          CHR$(71)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %01000000
        defb %01001110
        defb %01000010
        defb %00111100
        defb %00000000

; $48 - Character: 'H'          CHR$(72)

        defb %00000000
        defb %01000010
        defb %01000010
        defb %01111110
        defb %01000010
        defb %01000010
        defb %01000010
        defb %00000000

; $49 - Character: 'I'          CHR$(73)

        defb %00000000
        defb %00111110
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00111110
        defb %00000000

; $4A - Character: 'J'          CHR$(74)

        defb %00000000
        defb %00000010
        defb %00000010
        defb %00000010
        defb %01000010
        defb %01000010
        defb %00111100
        defb %00000000

; $4B - Character: 'K'          CHR$(75)

        defb %00000000
        defb %01000100
        defb %01001000
        defb %01110000
        defb %01001000
        defb %01000100
        defb %01000010
        defb %00000000

; $4C - Character: 'L'          CHR$(76)

        defb %00000000
        defb %01000000
        defb %01000000
        defb %01000000
        defb %01000000
        defb %01000000
        defb %01111110
        defb %00000000

; $4D - Character: 'M'          CHR$(77)

        defb %00000000
        defb %01000010
        defb %01100110
        defb %01011010
        defb %01000010
        defb %01000010
        defb %01000010
        defb %00000000

; $4E - Character: 'N'          CHR$(78)

        defb %00000000
        defb %01000010
        defb %01100010
        defb %01010010
        defb %01001010
        defb %01000110
        defb %01000010
        defb %00000000

; $4F - Character: 'O'          CHR$(79)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %01000010
        defb %01000010
        defb %01000010
        defb %00111100
        defb %00000000

; $50 - Character: 'P'          CHR$(80)

        defb %00000000
        defb %01111100
        defb %01000010
        defb %01000010
        defb %01111100
        defb %01000000
        defb %01000000
        defb %00000000

; $51 - Character: 'Q'          CHR$(81)

        defb %00000000
        defb %00111100
        defb %01000010
        defb %01000010
        defb %01010010
        defb %01001010
        defb %00111100
        defb %00000000

; $52 - Character: 'R'          CHR$(82)

        defb %00000000
        defb %01111100
        defb %01000010
        defb %01000010
        defb %01111100
        defb %01000100
        defb %01000010
        defb %00000000

; $53 - Character: 'S'          CHR$(83)

        defb %00000000
        defb %00111100
        defb %01000000
        defb %00111100
        defb %00000010
        defb %01000010
        defb %00111100
        defb %00000000

; $54 - Character: 'T'          CHR$(84)

        defb %00000000
        defb %11111110
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00000000

; $55 - Character: 'U'          CHR$(85)

        defb %00000000
        defb %01000010
        defb %01000010
        defb %01000010
        defb %01000010
        defb %01000010
        defb %00111100
        defb %00000000

; $56 - Character: 'V'          CHR$(86)

        defb %00000000
        defb %01000010
        defb %01000010
        defb %01000010
        defb %01000010
        defb %00100100
        defb %00011000
        defb %00000000

; $57 - Character: 'W'          CHR$(87)

        defb %00000000
        defb %01000010
        defb %01000010
        defb %01000010
        defb %01000010
        defb %01011010
        defb %00100100
        defb %00000000

; $58 - Character: 'X'          CHR$(88)

        defb %00000000
        defb %01000010
        defb %00100100
        defb %00011000
        defb %00011000
        defb %00100100
        defb %01000010
        defb %00000000

; $59 - Character: 'Y'          CHR$(89)

        defb %00000000
        defb %10000010
        defb %01000100
        defb %00101000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00000000

; $5A - Character: 'Z'          CHR$(90)

        defb %00000000
        defb %01111110
        defb %00000100
        defb %00001000
        defb %00010000
        defb %00100000
        defb %01111110
        defb %00000000

; $5B - Character: '['          CHR$(91)

        defb %00000000
        defb %00001110
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00001110
        defb %00000000

; $5C - Character: '\'          CHR$(92)

        defb %00000000
        defb %00000000
        defb %01000000
        defb %00100000
        defb %00010000
        defb %00001000
        defb %00000100
        defb %00000000

; $5D - Character: ']'          CHR$(93)

        defb %00000000
        defb %01110000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %01110000
        defb %00000000

; $5E - Character: '^'          CHR$(94)

        defb %00000000
        defb %00010000
        defb %00111000
        defb %01010100
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00000000

; $5F - Character: '_'          CHR$(95)

        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11111111

; $60 - Character: ' £ '        CHR$(96)

        defb %00000000
        defb %00011100
        defb %00100010
        defb %01111000
        defb %00100000
        defb %00100000
        defb %01111110
        defb %00000000

; $61 - Character: 'a'          CHR$(97)

        defb %00000000
        defb %00000000
        defb %00111000
        defb %00000100
        defb %00111100
        defb %01000100
        defb %00111100
        defb %00000000

; $62 - Character: 'b'          CHR$(98)

        defb %00000000
        defb %00100000
        defb %00100000
        defb %00111100
        defb %00100010
        defb %00100010
        defb %00111100
        defb %00000000

; $63 - Character: 'c'          CHR$(99)

        defb %00000000
        defb %00000000
        defb %00011100
        defb %00100000
        defb %00100000
        defb %00100000
        defb %00011100
        defb %00000000

; $64 - Character: 'd'          CHR$(100)

        defb %00000000
        defb %00000100
        defb %00000100
        defb %00111100
        defb %01000100
        defb %01000100
        defb %00111100
        defb %00000000

; $65 - Character: 'e'          CHR$(101)

        defb %00000000
        defb %00000000
        defb %00111000
        defb %01000100
        defb %01111000
        defb %01000000
        defb %00111100
        defb %00000000

; $66 - Character: 'f'          CHR$(102)

        defb %00000000
        defb %00001100
        defb %00010000
        defb %00011000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00000000

; $67 - Character: 'g'          CHR$(103)

        defb %00000000
        defb %00000000
        defb %00111100
        defb %01000100
        defb %01000100
        defb %00111100
        defb %00000100
        defb %00111000

; $68 - Character: 'h'          CHR$(104)

        defb %00000000
        defb %01000000
        defb %01000000
        defb %01111000
        defb %01000100
        defb %01000100
        defb %01000100
        defb %00000000

; $69 - Character: 'i'          CHR$(105)

        defb %00000000
        defb %00010000
        defb %00000000
        defb %00110000
        defb %00010000
        defb %00010000
        defb %00111000
        defb %00000000

; $6A - Character: 'j'          CHR$(106)

        defb %00000000
        defb %00000100
        defb %00000000
        defb %00000100
        defb %00000100
        defb %00000100
        defb %00100100
        defb %00011000

; $6B - Character: 'k'          CHR$(107)

        defb %00000000
        defb %00100000
        defb %00101000
        defb %00110000
        defb %00110000
        defb %00101000
        defb %00100100
        defb %00000000

; $6C - Character: 'l'          CHR$(108)

        defb %00000000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00001100
        defb %00000000

; $6D - Character: 'm'          CHR$(109)

        defb %00000000
        defb %00000000
        defb %01101000
        defb %01010100
        defb %01010100
        defb %01010100
        defb %01010100
        defb %00000000

; $6E - Character: 'n'          CHR$(110)

        defb %00000000
        defb %00000000
        defb %01111000
        defb %01000100
        defb %01000100
        defb %01000100
        defb %01000100
        defb %00000000

; $6F - Character: 'o'          CHR$(111)

        defb %00000000
        defb %00000000
        defb %00111000
        defb %01000100
        defb %01000100
        defb %01000100
        defb %00111000
        defb %00000000

; $70 - Character: 'p'          CHR$(112)

        defb %00000000
        defb %00000000
        defb %01111000
        defb %01000100
        defb %01000100
        defb %01111000
        defb %01000000
        defb %01000000

; $71 - Character: 'q'          CHR$(113)

        defb %00000000
        defb %00000000
        defb %00111100
        defb %01000100
        defb %01000100
        defb %00111100
        defb %00000100
        defb %00000110

; $72 - Character: 'r'          CHR$(114)

        defb %00000000
        defb %00000000
        defb %00011100
        defb %00100000
        defb %00100000
        defb %00100000
        defb %00100000
        defb %00000000

; $73 - Character: 's'          CHR$(115)

        defb %00000000
        defb %00000000
        defb %00111000
        defb %01000000
        defb %00111000
        defb %00000100
        defb %01111000
        defb %00000000

; $74 - Character: 't'          CHR$(116)

        defb %00000000
        defb %00010000
        defb %00111000
        defb %00010000
        defb %00010000
        defb %00010000
        defb %00001100
        defb %00000000

; $75 - Character: 'u'          CHR$(117)

        defb %00000000
        defb %00000000
        defb %01000100
        defb %01000100
        defb %01000100
        defb %01000100
        defb %00111000
        defb %00000000

; $76 - Character: 'v'          CHR$(118)

        defb %00000000
        defb %00000000
        defb %01000100
        defb %01000100
        defb %00101000
        defb %00101000
        defb %00010000
        defb %00000000

; $77 - Character: 'w'          CHR$(119)

        defb %00000000
        defb %00000000
        defb %01000100
        defb %01010100
        defb %01010100
        defb %01010100
        defb %00101000
        defb %00000000

; $78 - Character: 'x'          CHR$(120)

        defb %00000000
        defb %00000000
        defb %01000100
        defb %00101000
        defb %00010000
        defb %00101000
        defb %01000100
        defb %00000000

; $79 - Character: 'y'          CHR$(121)

        defb %00000000
        defb %00000000
        defb %01000100
        defb %01000100
        defb %01000100
        defb %00111100
        defb %00000100
        defb %00111000

; $7A - Character: 'z'          CHR$(122)

        defb %00000000
        defb %00000000
        defb %01111100
        defb %00001000
        defb %00010000
        defb %00100000
        defb %01111100
        defb %00000000

; $7B - Character: '{'          CHR$(123)

        defb %00000000
        defb %00001110
        defb %00001000
        defb %00110000
        defb %00001000
        defb %00001000
        defb %00001110
        defb %00000000

; $7C - Character: '|'          CHR$(124)

        defb %00000000
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00001000
        defb %00000000

; $7D - Character: '}'          CHR$(125)

        defb %00000000
        defb %01110000
        defb %00010000
        defb %00001100
        defb %00010000
        defb %00010000
        defb %01110000
        defb %00000000

; $7E - Character: '~'          CHR$(126)

        defb %00000000
        defb %00010100
        defb %00101000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

; $7F - Character: ' © '        CHR$(127)

        defb %00111100
        defb %01000010
        defb %10011001
        defb %10100001
        defb %10100001
        defb %10011001
        defb %01000010
        defb %00111100



;#end                            ; generic cross-assembler directive 

; Acknowledgements
; -----------------
; Sean Irvine               for default list of section headings
; Dr. Ian Logan             for labels and functional disassembly.
; Dr. Frank O'Hara          for labels and functional disassembly.
;
; Credits
; -------
; Alex Pallero Gonzales     for corrections.
; Mike Dailly               for comments.
; Alvin Albrecht            for comments.
; Andy Styles               for full relocatability implementation and testing.                    testing.
; Andrew Owen               for ZASM compatibility and format improvements.

;   For other assemblers you may have to add directives like these near the 
;   beginning - see accompanying documentation.
;   ZASM (MacOs) cross-assembler directives. (uncomment by removing ';' )
;   #target rom           ; declare target file format as binary.
;   #code   0,$4000       ; declare code segment.
;   Also see notes at Address Labels 0609 and 1CA5 if your assembler has 
;   trouble with expressions.
;
;   Note. The Sinclair Interface 1 ROM written by Dr. Ian Logan and Martin 
;   Brennan calls numerous routines in this ROM.  
;   Non-standard entry points have a label beginning with X. 



; $0000 CCCCCCCCCCCCCCCCCCCBBBBBCCCCCCCCCCCCCBBBCCCBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0050 CCCCCCCCCCCCCCCBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBB
; $00A0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $00F0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0140 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0190 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $01E0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0230 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0280 BBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $02D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0320 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0370 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $03C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBCCCCCCCCC
; $0410 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBCCCCBBBBCCCCCCCCBBBBBBBBBBBBBBBBCCCCC
; $0460 CCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCC
; $04B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0500 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0550 CCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $05A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $05F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0640 CCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0690 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $06E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0730 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0780 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $07D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCC
; $0820 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0870 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $08C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0910 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0960 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBB
; $09B0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCC
; $0A00 CCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0A50 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0AA0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0AF0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0B40 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0B90 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0BE0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0C30 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0C80 CCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0CD0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0D20 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0D70 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0DC0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0E10 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0E60 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0EB0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0F00 CCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0F50 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0FA0 BBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0FF0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1040 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1090 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $10E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1130 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1180 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $11D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1220 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1270 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $12C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1310 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1360 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $13B0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1400 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1450 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $14A0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $14F0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1540 BBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1590 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCWWWWBWWWWBWWWWBWWWWBBCBBBBBBBBBBBBBBBCCCCCCCCCCCC
; $15E0 CCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBB
; $1630 BBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1680 CCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $16D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBCCCC
; $1720 CCCCCCBCCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCC
; $1770 CCCCCCCCCCBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $17C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1810 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1860 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $18B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1900 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1950 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $19A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $19F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1A40 CCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBWWBBBWWBBWWBWWBWW
; $1A90 BBBBBBWWBBWWBWWBWWBWWBWWBWWBWWBWWBBWWBWWBWWBWWBWWBBWWBBWWBWWBWWBWWBBWWBWWBWWBWWB
; $1AE0 BBBBBWWBBWWBBBBBBBBWWBBWWBWWBBBBWWBBWWBBWWBBBBWWBBWWBWWCCCCCCCCCCCCCCCCCCCCCCCCC
; $1B30 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCC
; $1B80 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1BD0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCC
; $1C20 CCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1C70 CCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1CC0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBCCBCCCCCCCBBCCCCCCCCCCCCCCCCCCCCCCC
; $1D10 CCCCBBCBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1D60 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1DB0 CCCCCCCCCCCCCCBBBBBBCCCCCCCCCCCCCCCCCCCCCBCBBBBBBBBBBBBCCBCCCCCCCCCCCCCCCCCCCCCC
; $1E00 CCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1E50 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1EA0 BCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCC
; $1EF0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCC
; $1F40 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1F90 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1FE0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2030 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2080 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $20D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2120 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2170 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $21C0 CCCCCCCCCCCCCCCBCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2210 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2260 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $22B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2300 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBCCCCCCBBCCCBBCCCBBBCCCCCBBBBCCC
; $2350 CCCBBBCCCCCBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBB
; $23A0 CCCBBBBBBBBBBBBBBBBBBCCCCCCBBBCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $23F0 BBBBBBBBBBBBBCCCCCCCCCBBCCCCCCCBBBBCCCCCCCBBBBBCCCCCCCBBBBBBBBBBBBBBBBBBBCCBBBBB
; $2440 BCCCCCCCBBBBBBBBCCCCCCCBBCCCCCCCBBBBCCCCCCCBBBCCCCCCCBBCCCCCCCBBBBBBBBBBBBCCCCCC
; $2490 CCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $24E0 CCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2530 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2580 CCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $25D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBCCCCCCCCC
; $2620 CCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2670 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $26C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2710 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBCCCCCCC
; $2760 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $27B0 BBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2800 CCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2850 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCC
; $28A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $28F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2940 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2990 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $29E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCC
; $2A30 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2A80 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2AD0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2B20 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCC
; $2B70 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2BC0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2C10 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2C60 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2CB0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBCBBBBCCCCCCCBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCC
; $2D00 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCBBCCCCCCBBBBBCCCCCC
; $2D50 CCCCCCCCCCCCCBBCCCCCCCBBBBBBBBBBCCCCCBBBCCCCBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2DA0 CCCBCCCCCBBBBCBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBCCCCCCCCCCCCCCCBBBBBBBBBBCC
; $2DF0 CCBBCCCCBBBBBBCCCCBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCCBBBBBB
; $2E40 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2E90 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBCCCCCCCCCCCCCCCCC
; $2EE0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2F30 CBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2F80 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $2FD0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3020 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3070 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $30C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3110 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3160 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBC
; $31B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3200 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3250 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $32A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBWWWWWWWWWWWWWWWWWWWWWWWWW
; $32F0 WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
; $3340 WWWWWWWWWWWWWWWWWWWWWWWWWWWCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3390 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $33E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3430 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBCCCCCCBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCC
; $3480 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $34D0 CCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3520 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3570 CCCCCCCCCCCCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $35C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3610 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $3660 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBCC
; $36B0 BBBBBBCBBBBBBBBBBBBCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCC
; $3700 CCCCBCCCCCCCCCCBBBCCBBBBBBCBBBBCCCCCCCBBBBBBBBBBBBBBBBBBBBBCCBBBBBBBBBBBBBBBBBBB
; $3750 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $37A0 CBBBBBBBBCCBBBBBBBBBBCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCBBBBBBCCCCCCCCCCBBBBB
; $37F0 BBBBBBBBCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCBBBBBBBBBBBB
; $3840 BBCCBBBBBCCBBBBBBCBBBBBBBBCCCBBBBBBBBBBBBBBBBCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3890 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $38E0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3930 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3980 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $39D0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3A20 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3A70 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3AC0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3B10 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3B60 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3BB0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3C00 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3C50 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3CA0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3CF0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3D40 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3D90 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3DE0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3E30 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3E80 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3ED0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3F20 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3F70 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $3FC0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB

; Labels
;
; $0000 => START                abs           => $346A
; $0008 => ERROR_1              acs           => $3843
; $0010 => PRINT_A              ADD_BACK      => $3004
; $0018 => GET_CHAR             ADD_CH_1      => $0F8B
; $001C => TEST_CHAR            ADD_CHAR      => $0F81
; $0020 => NEXT_CHAR            ADD_REP_6     => $309F
; $0028 => FP_CALC              ADDEND_0      => $2FF9
; $0030 => BC_SPACES            addition      => $3014
; $0038 => MASK_INT             ADDN_OFLW     => $303C
; $0048 => KEY_INT              ALL_ADDED     => $300D
; $0053 => ERROR_2              ALPHA         => $2C8D
; $0055 => ERROR_3              ALPHANUM      => $2C88
; $0066 => RESET                ARC_END       => $245F
; $0070 => NO_RESET             ARC_LOOP      => $2425
; $0074 => CH_ADD_1             ARC_START     => $2439
; $0077 => TEMP_PTR1            asn           => $3833
; $0078 => TEMP_PTR2            atn           => $37E2
; $007B => X007B                ATTR_P        => $5C8D
; $007D => SKIP_OVER            ATTR_T        => $5C8F
; $0090 => SKIPS                AUTO_L_1      => $17CE
; $0095 => TKN_TABLE            AUTO_L_2      => $17E1
; $0205 => MAIN_KEYS            AUTO_L_3      => $17E4
; $022C => E_UNSHIFT            AUTO_L_4      => $17ED
; $0246 => EXT_SHIFT            AUTO_LIST     => $1795
; $0260 => CTL_CODES            BC_SPACES     => $0030
; $026A => SYM_CODES            BE_AGAIN      => $03F2
; $0284 => E_DIGITS             BE_END        => $03F6
; $028E => KEY_SCAN             BE_H_L_LP     => $03D6
; $0296 => KEY_LINE             BE_I_OK       => $0425
; $029F => KEY_3KEYS            BE_IX_0       => $03D4
; $02A1 => KEY_BITS             BE_IX_1       => $03D3
; $02AB => KEY_DONE             BE_IX_2       => $03D2
; $02BF => KEYBOARD             BE_IX_3       => $03D1
; $02C6 => K_ST_LOOP            BE_OCTAVE     => $0427
; $02D1 => K_CH_SET             beep          => $03F8
; $02F1 => K_NEW                BEEPER        => $03B5
; $0308 => K_END                BIN_DIGIT     => $2CA2
; $0310 => K_REPEAT             BIN_END       => $2CB3
; $031E => K_TEST               BITS_ZERO     => $3283
; $032C => K_MAIN               BORDCR        => $5C48
; $0333 => K_DECODE             BORDER        => $2294
; $0341 => K_E_LET              BORDER_1      => $22A6
; $034A => K_LOOK_UP            BOTH_NULL     => $3572
; $034F => K_KLC_LET            BREAK_KEY     => $1F54
; $0364 => K_TOKENS             BREG          => $5C67
; $0367 => K_DIGIT              BYTE_COMP     => $3564
; $0382 => K_8___9              BYTE_ZERO     => $327E
; $0389 => K_GRA_DGT            C_ARC_GE1     => $235A
; $039D => K_KLC_DGT            C_ENT         => $37B7
; $03B2 => K___CHAR             C_R_GRE_1     => $233B
; $03B5 => BEEPER               CA_10_A_C     => $2F8B
; $03D1 => BE_IX_3              CALCULATE     => $335B
; $03D2 => BE_IX_2              CALL_JUMP     => $162C
; $03D3 => BE_IX_1              CALL_SUB      => $15F7
; $03D4 => BE_IX_0              CASES         => $37FA
; $03D6 => BE_H_L_LP            CAT_ETC       => $1793
; $03F2 => BE_AGAIN             CD_PRMS1      => $247D
; $03F6 => BE_END               CH_ADD        => $5C5D
; $03F8 => beep                 CH_ADD_1      => $0074
; $0425 => BE_I_OK              CHAN_FLAG     => $1615
; $0427 => BE_OCTAVE            CHAN_K        => $1634
; $046C => REPORT_B             CHAN_OP_1     => $1610
; $046E => semi_tone            CHAN_OPEN     => $1601
; $04AA => zx81_name            CHAN_P        => $164D
; $04C2 => SA_BYTES             CHAN_S        => $1642
; $04D0 => SA_FLAG              CHAN_S_1      => $1646
; $04D8 => SA_LEADER            CHANS         => $5C4F
; $04EA => SA_SYNC_1            char_set      => $3D00
; $04F2 => SA_SYNC_2            CHARS         => $5C36
; $04FE => SA_LOOP              CHECK_END     => $1BEE
; $0505 => SA_LOOP_P            chn_cd_lu     => $162D
; $0507 => SA_START             chrs          => $35C9
; $050E => SA_PARITY            CIRCLE        => $2320
; $0511 => SA_BIT_2             CL_09_1       => $1CD6
; $0514 => SA_BIT_1             CL_ADDR       => $0E9B
; $051A => SA_SET               CL_ALL        => $0DAF
; $051C => SA_OUT               CL_ATTR       => $0E88
; $0525 => SA_8_BITS            CL_CHAN       => $0D94
; $053C => SA_DELAY             CL_CHAN_A     => $0DA0
; $053F => SA_LD_RET            CL_LINE       => $0E44
; $0552 => REPORT_Da            CL_LINE_1     => $0E4A
; $0554 => SA_LD_END            CL_LINE_2     => $0E4D
; $0556 => LD_BYTES             CL_LINE_3     => $0E80
; $056B => LD_BREAK             CL_SC_ALL     => $0DFE
; $056C => LD_START             CL_SCR_1      => $0E05
; $0574 => LD_WAIT              CL_SCR_2      => $0E0D
; $0580 => LD_LEADER            CL_SCR_3      => $0E19
; $058F => LD_SYNC              CL_SCROLL     => $0E00
; $05A9 => LD_LOOP              CL_SET        => $0DD9
; $05B3 => LD_FLAG              CL_SET_1      => $0DEE
; $05BD => LD_VERIFY            CL_SET_2      => $0DF4
; $05C2 => LD_NEXT              cl_str_lu     => $1716
; $05C4 => LD_DEC               CLASS_00      => $1C10
; $05C8 => LD_MARKER            CLASS_01      => $1C1F
; $05CA => LD_8_BITS            CLASS_02      => $1C4E
; $05E3 => LD_EDGE_2            CLASS_03      => $1C0D
; $05E7 => LD_EDGE_1            CLASS_04      => $1C6C
; $05E9 => LD_DELAY             CLASS_05      => $1C11
; $05ED => LD_SAMPLE            CLASS_07      => $1C96
; $0605 => SAVE_ETC             CLASS_09      => $1CBE
; $0609 => L0609                CLASS_0B      => $1CDB
; $0621 => SA_SPACE             class_tbl     => $1C01
; $0629 => SA_BLANK             CLEAR         => $1EAC
; $0642 => REPORT_Fa            CLEAR_1       => $1EB7
; $0644 => SA_NULL              CLEAR_2       => $1EDC
; $064B => SA_NAME              CLEAR_PRB     => $0EDF
; $0652 => SA_DATA              CLEAR_RUN     => $1EAF
; $0670 => REPORT_2a            CLEAR_SP      => $1097
; $0672 => SA_V_OLD             CLOSE         => $16E5
; $0685 => SA_V_NEW             CLOSE_1       => $16FC
; $068F => SA_V_TYPE            CLOSE_2       => $1701
; $0692 => SA_DATA_1            CLOSE_STR     => $171C
; $06A0 => SA_SCR_              CLS           => $0D6B
; $06C3 => SA_CODE              CLS_1         => $0D87
; $06E1 => SA_CODE_1            CLS_2         => $0D89
; $06F0 => SA_CODE_2            CLS_3         => $0D8E
; $06F5 => SA_CODE_3            CLS_LOWER     => $0D6E
; $06F9 => SA_CODE_4            CO_CHANGE     => $226C
; $0710 => SA_TYPE_3            CO_TEMP_1     => $21E1
; $0716 => SA_LINE              CO_TEMP_2     => $21E2
; $0723 => SA_LINE_1            CO_TEMP_3     => $21F2
; $073A => SA_TYPE_0            CO_TEMP_4     => $21FC
; $075A => SA_ALL               CO_TEMP_5     => $2211
; $0767 => LD_LOOK_H            CO_TEMP_6     => $2228
; $078A => LD_TYPE              CO_TEMP_7     => $2234
; $07A6 => LD_NAME              CO_TEMP_8     => $223E
; $07AD => LD_CH_PR             CO_TEMP_9     => $2246
; $07CB => VR_CONTRL            CO_TEMP_A     => $2257
; $07E9 => VR_CONT_1            CO_TEMP_B     => $2258
; $07F4 => VR_CONT_2            CO_TEMP_C     => $2273
; $0800 => VR_CONT_3            CO_TEMP_D     => $227D
; $0802 => LD_BLOCK             CO_TEMP_E     => $2287
; $0806 => REPORT_R             code          => $3669
; $0808 => LD_CONTRL            comma_sp      => $1537
; $0819 => LD_CONT_1            CONTINUE      => $1E5F
; $0825 => LD_CONT_2            COORDS        => $5C7D
; $082E => LD_DATA              COORDS_hi     => $5C7E
; $084C => LD_DATA_1            COPY          => $0EAC
; $0873 => LD_PROG              COPY_1        => $0EB2
; $08AD => LD_PROG_1            COPY_2        => $0EC9
; $08B6 => ME_CONTRL            COPY_3        => $0ED3
; $08CE => X08CE                COPY_BUFF     => $0ECD
; $08D2 => ME_NEW_LP            COPY_END      => $0EDA
; $08D7 => ME_OLD_LP            COPY_L_1      => $0EFD
; $08DF => ME_OLD_L1            COPY_L_2      => $0F0C
; $08EB => ME_NEW_L2            COPY_L_3      => $0F14
; $08F0 => ME_VAR_LP            COPY_L_4      => $0F18
; $08F9 => ME_OLD_VP            COPY_L_5      => $0F1E
; $0901 => ME_OLD_V1            COPY_LINE     => $0EF4
; $0909 => ME_OLD_V2            copyright     => $1539
; $0912 => ME_OLD_V3            cos           => $37AA
; $091E => ME_OLD_V4            COUNT_ONE     => $31FA
; $0921 => ME_VAR_L1            CP_LINES      => $1980
; $0923 => ME_VAR_L2            CTL_CODES     => $0260
; $092C => ME_ENTER             ctlchrtab     => $0A11
; $093E => ME_ENT_1             CURCHL        => $5C51
; $0955 => ME_ENT_2             D_L_DIAG      => $24D4
; $0958 => ME_ENT_3             D_L_HR_VT     => $24DB
; $0970 => SA_CONTRL            D_L_LOOP      => $24CE
; $0991 => SA_1_SEC             D_L_PLOT      => $24EC
; $09A1 => tape_msgs            D_L_RANGE     => $24F7
; $09C1 => tape_msgs_2          D_L_STEP      => $24DF
; $09F4 => PRINT_OUT            D_LETTER      => $2C1F
; $0A11 => ctlchrtab            D_NO_LOOP     => $2C2E
; $0A23 => PO_BACK_1            D_RPORT_C     => $2C05
; $0A38 => PO_BACK_2            D_RUN         => $2C15
; $0A3A => PO_BACK_3            D_SIZE        => $2C2D
; $0A3D => PO_RIGHT             DATA          => $1E27
; $0A4F => PO_ENTER             DATA_1        => $1E2C
; $0A5F => PO_COMMA             DATA_2        => $1E37
; $0A69 => PO_QUEST             DATADD        => $5C57
; $0A6D => PO_TV_2              DE__DE_1_     => $2AEE
; $0A75 => PO_2_OPER            dec_jr_nz     => $367A
; $0A7A => PO_1_OPER            DEC_RPT_C     => $2CCF
; $0A7D => PO_TV_1              DEC_STO_1     => $2CD5
; $0A80 => PO_CHANGE            DEC_TO_FP     => $2C9B
; $0A87 => PO_CONT              DECIMAL       => $2CCB
; $0AAC => PO_AT_ERR            DEF_FN        => $1F60
; $0ABF => PO_AT_SET            DEF_FN_1      => $1F6A
; $0AC2 => PO_TAB               DEF_FN_2      => $1F7D
; $0AC3 => PO_FILL              DEF_FN_3      => $1F86
; $0AD0 => PO_SPACE             DEF_FN_4      => $1F89
; $0AD9 => PO_ABLE              DEF_FN_5      => $1F94
; $0ADC => PO_STORE             DEF_FN_6      => $1FA6
; $0AF0 => PO_ST_E              DEF_FN_7      => $1FBD
; $0AFC => PO_ST_PR             DEFADD        => $5C0B
; $0B03 => PO_FETCH             delete        => $33A1
; $0B1D => PO_F_PR              DEST          => $5C4D
; $0B24 => PO_ANY               DF_CC         => $5C84
; $0B38 => PO_GR_1              DF_SZ         => $5C6B
; $0B3E => PO_GR_2              DFCCL         => $5C86
; $0B4C => PO_GR_3              DIFFER        => $19DD
; $0B52 => PO_T_UDG             DIM           => $2C02
; $0B5F => PO_T                 DIM_CLEAR     => $2C7C
; $0B65 => PO_CHAR              DIM_SIZES     => $2C7F
; $0B6A => PO_CHAR_2            div_34th      => $31DB
; $0B76 => PO_CHAR_3            DIV_LOOP      => $31D2
; $0B7F => PR_ALL               DIV_START     => $31E2
; $0B93 => PR_ALL_1             division      => $31AF
; $0BA4 => PR_ALL_2             DIVN_EXPT     => $313D
; $0BB6 => PR_ALL_3             DL_LARGER     => $24CB
; $0BB7 => PR_ALL_4             DL_X_GE_Y     => $24C4
; $0BC1 => PR_ALL_5             DOUBLE_A      => $338C
; $0BD3 => PR_ALL_6             DR_3_PRMS     => $238D
; $0BDB => PO_ATTR              DR_PRMS       => $23C1
; $0BFA => PO_ATTR_1            DR_SIN_NZ     => $23A3
; $0C08 => PO_ATTR_2            DRAW          => $2382
; $0C0A => PO_MSG               DRAW_LINE     => $24B7
; $0C10 => PO_TOKENS            DRAW_SAVE     => $2497
; $0C14 => PO_TABLE             DRW_STEPS     => $2420
; $0C22 => PO_EACH              E_DIGITS      => $0284
; $0C35 => PO_TR_SP             E_DIVSN       => $2D6D
; $0C3B => PO_SAVE              E_END         => $2D7B
; $0C41 => PO_SEARCH            E_FETCH       => $2D6E
; $0C44 => PO_STEP              E_FORMAT      => $2CEB
; $0C55 => PO_SCR               E_FP_JUMP     => $2D18
; $0C86 => REPORT_5             E_L_1         => $1A15
; $0C88 => PO_SCR_2             E_LINE        => $5C59
; $0CD2 => PO_SCR_3             E_LINE_NO     => $19FB
; $0CF0 => PO_SCR_3A            E_LOOP        => $2D60
; $0CF8 => scrl_mssg            E_PPC         => $5C49
; $0D00 => REPORT_D             E_SAVE        => $2D55
; $0D02 => PO_SCR_4             E_TO_FP       => $2D4F
; $0D1C => PO_SCR_4A            E_TST_END     => $2D71
; $0D2D => PO_SCR_4B            E_UNSHIFT     => $022C
; $0D4D => TEMPS                EACH_S_1      => $1990
; $0D5B => TEMPS_1              EACH_S_2      => $1998
; $0D65 => TEMPS_2              EACH_S_3      => $199A
; $0D6B => CLS                  EACH_S_4      => $19A5
; $0D6E => CLS_LOWER            EACH_S_5      => $19AD
; $0D87 => CLS_1                EACH_S_6      => $19B1
; $0D89 => CLS_2                EACH_STMT     => $198B
; $0D8E => CLS_3                ECHO_E        => $5C82
; $0D94 => CL_CHAN              ED_AGAIN      => $0F30
; $0DA0 => CL_CHAN_A            ED_BLANK      => $1150
; $0DAF => CL_ALL               ED_C_DONE     => $117C
; $0DD9 => CL_SET               ED_C_END      => $117E
; $0DEE => CL_SET_1             ED_CONTR      => $0F6C
; $0DF4 => CL_SET_2             ED_COPY       => $111D
; $0DFE => CL_SC_ALL            ED_CUR        => $1011
; $0E00 => CL_SCROLL            ED_DELETE     => $1015
; $0E05 => CL_SCR_1             ED_DOWN       => $0FF3
; $0E0D => CL_SCR_2             ED_EDGE       => $1031
; $0E19 => CL_SCR_3             ED_EDGE_1     => $103E
; $0E44 => CL_LINE              ED_EDGE_2     => $1051
; $0E4A => CL_LINE_1            ED_EDIT       => $0FA9
; $0E4D => CL_LINE_2            ED_END        => $1026
; $0E80 => CL_LINE_3            ED_ENTER      => $1024
; $0E88 => CL_ATTR              ED_ERROR      => $107F
; $0E9B => CL_ADDR              ED_FULL       => $1167
; $0EAC => COPY                 ED_GRAPH      => $107C
; $0EAF => L0EAF                ED_IGNORE     => $101E
; $0EB2 => COPY_1               ED_KEYS       => $0F92
; $0EC9 => COPY_2               ed_keys_t     => $0FA0
; $0ECD => COPY_BUFF            ED_LEFT       => $1007
; $0ED3 => COPY_3               ED_LIST       => $106E
; $0EDA => COPY_END             ED_LOOP       => $0F38
; $0EDF => CLEAR_PRB            ED_RIGHT      => $100C
; $0EE7 => PRB_BYTES            ED_SPACES     => $115E
; $0EF4 => COPY_LINE            ED_STOP       => $1001
; $0EFD => COPY_L_1             ED_SYMBOL     => $1076
; $0F0A => REPORT_Dc            ED_UP         => $1059
; $0F0C => COPY_L_2             EDITOR        => $0F2C
; $0F14 => COPY_L_3             end_calc      => $369B
; $0F18 => COPY_L_4             END_COMPL     => $30A3
; $0F1E => COPY_L_5             END_TESTS     => $358C
; $0F2C => EDITOR               ENT_TABLE     => $338E
; $0F30 => ED_AGAIN             ERR_NR        => $5C3A
; $0F38 => ED_LOOP              ERR_SP        => $5C3D
; $0F6C => ED_CONTR             ERROR_1       => $0008
; $0F81 => ADD_CHAR             ERROR_2       => $0053
; $0F85 => X0F85                ERROR_3       => $0055
; $0F8B => ADD_CH_1             EX_OR_NOT     => $3543
; $0F92 => ED_KEYS              exchange      => $343C
; $0FA0 => ed_keys_t            EXIT          => $36C2
; $0FA9 => ED_EDIT              exp           => $36C4
; $0FF3 => ED_DOWN              EXPT_1NUM     => $1C82
; $1001 => ED_STOP              EXPT_2NUM     => $1C7A
; $1007 => ED_LEFT              EXPT_EXP      => $1C8C
; $100C => ED_RIGHT             EXT_SHIFT     => $0246
; $1011 => ED_CUR               F_FOUND       => $1D7C
; $1015 => ED_DELETE            F_L_S         => $1D34
; $101E => ED_IGNORE            F_LOOP        => $1D64
; $1024 => ED_ENTER             F_REORDER     => $1D16
; $1026 => ED_END               F_USE_1       => $1D10
; $1031 => ED_EDGE              FETCH_NUM     => $1CDE
; $103E => ED_EDGE_1            FETCH_TWO     => $2FBA
; $1051 => ED_EDGE_2            FIND_I_1      => $1E9C
; $1059 => ED_UP                FIND_INT1     => $1E94
; $106E => ED_LIST              FIND_INT2     => $1E99
; $1076 => ED_SYMBOL            FIRST_3D      => $3380
; $107C => ED_GRAPH             FLAGS         => $5C3B
; $107F => ED_ERROR             FLAGS2        => $5C6A
; $1097 => CLEAR_SP             FLAGX         => $5C71
; $10A8 => KEY_INPUT            FN_SKPOVR     => $28AB
; $10DB => KEY_M_CL             FOR           => $1D03
; $10E6 => KEY_MODE             FORM_EXP      => $33DE
; $10F4 => KEY_FLAG             FP_0_1        => $350B
; $10FA => KEY_CONTR            FP_A_END      => $2DE1
; $1105 => KEY_DATA             FP_CALC       => $0028
; $110D => KEY_NEXT             fp_calc_2     => $33A2
; $1113 => KEY_CHAN             FP_DELETE     => $2DAD
; $111B => KEY_DONE2            FP_TO_A       => $2DD5
; $111D => ED_COPY              FP_TO_BC      => $2DA2
; $1150 => ED_BLANK             FRAMES        => $5C78
; $115E => ED_SPACES            FRAMES3       => $5C7A
; $1167 => ED_FULL              free_mem      => $1F1A
; $117C => ED_C_DONE            FRST_LESS     => $3585
; $117E => ED_C_END             FULL_ADDN     => $303E
; $1190 => SET_HL               GEN_ENT_1     => $335E
; $1195 => SET_DE               GEN_ENT_2     => $3362
; $11A7 => REMOVE_FP            get_argt      => $3783
; $11B7 => NEW                  GET_CHAR      => $0018
; $11CB => START_NEW            GET_HL_DE     => $2AF4
; $11DA => ram_check            get_mem_xx    => $340F
; $11DC => RAM_FILL             GET_PARAM     => $1B55
; $11E2 => RAM_READ             GO_NC_MLT     => $30A5
; $11EF => RAM_DONE             GO_SUB        => $1EED
; $1219 => RAM_SET              GO_TO         => $1E67
; $121C => NMI_VECT             GO_TO_2       => $1E73
; $12A2 => MAIN_EXEC            GRE_8         => $373D
; $12A9 => MAIN_1               greater_0     => $34F9
; $12AC => MAIN_2               HL_AGAIN      => $30BC
; $12CF => MAIN_3               HL_END        => $30BE
; $1303 => MAIN_4               HL_HL_DE      => $30A9
; $1313 => MAIN_G               HL_LOOP       => $30B1
; $133C => MAIN_5               I_CARRY       => $2AE8
; $1349 => X1349                I_RESTORE     => $2AEB
; $1373 => MAIN_6               IF            => $1CF0
; $1376 => MAIN_7               IF_1          => $1D00
; $1384 => MAIN_8               IN_ASSIGN     => $21B9
; $1386 => MAIN_9               IN_CHAN_K     => $21D6
; $1391 => rpt_mesgs            in_func       => $34A5
; $1537 => comma_sp             IN_ITEM_1     => $20C1
; $1539 => copyright            IN_ITEM_2     => $20D8
; $1555 => REPORT_G             IN_ITEM_3     => $20ED
; $155D => MAIN_ADD             IN_NEXT_1     => $21AF
; $157D => MAIN_ADD1            IN_NEXT_2     => $21B2
; $15AB => MAIN_ADD2            IN_PK_STK     => $34B0
; $15AF => init_chan            IN_PR_1       => $211A
; $15C4 => REPORT_J             IN_PR_2       => $211C
; $15C6 => init_strm            IN_PR_3       => $2129
; $15D4 => WAIT_KEY             IN_PROMPT     => $20FA
; $15DE => WAIT_KEY1            IN_STOP       => $21D0
; $15E4 => REPORT_8             IN_VAR_1      => $213A
; $15E6 => INPUT_AD             IN_VAR_2      => $2148
; $15EF => OUT_CODE             IN_VAR_3      => $215E
; $15F2 => PRINT_A_2            IN_VAR_4      => $2161
; $15F7 => CALL_SUB             IN_VAR_5      => $2174
; $1601 => CHAN_OPEN            IN_VAR_6      => $219B
; $160E => REPORT_Oa            INDEXER       => $16DC
; $1610 => CHAN_OP_1            INDEXER_1     => $16DB
; $1615 => CHAN_FLAG            init_chan     => $15AF
; $162C => CALL_JUMP            init_strm     => $15C6
; $162D => chn_cd_lu            INPUT         => $2089
; $1634 => CHAN_K               INPUT_1       => $2096
; $1642 => CHAN_S               INPUT_2       => $20AD
; $1646 => CHAN_S_1             INPUT_AD      => $15E6
; $164D => CHAN_P               int           => $36AF
; $1652 => ONE_SPACE            INT_CASE      => $3483
; $1655 => MAKE_ROOM            INT_EXP1      => $2ACC
; $1664 => POINTERS             INT_EXP2      => $2ACD
; $166B => PTR_NEXT             INT_FETCH     => $2D7F
; $167F => PTR_DONE             INT_STORE     => $2D8E
; $168F => LINE_ZERO            INT_TO_FP     => $2D3B
; $1691 => LINE_NO_A            IX_END        => $3290
; $1695 => LINE_NO              JUMP          => $3686
; $169E => RESERVE              JUMP_2        => $3687
; $16B0 => SET_MIN              jump_true     => $368F
; $16BF => SET_WORK             K_8___9       => $0382
; $16C5 => SET_STK              K___CHAR      => $03B2
; $16D4 => REC_EDIT             K_CH_SET      => $02D1
; $16DB => INDEXER_1            K_CUR         => $5C5B
; $16DC => INDEXER              K_DATA        => $5C0D
; $16E5 => CLOSE                K_DECODE      => $0333
; $16FC => CLOSE_1              K_DIGIT       => $0367
; $1701 => CLOSE_2              K_E_LET       => $0341
; $1708 => ROM_TRAP             K_END         => $0308
; $1716 => cl_str_lu            K_GRA_DGT     => $0389
; $171C => CLOSE_STR            K_KLC_DGT     => $039D
; $171E => STR_DATA             K_KLC_LET     => $034F
; $1725 => REPORT_Ob            K_LOOK_UP     => $034A
; $1727 => STR_DATA1            K_MAIN        => $032C
; $1736 => OPEN                 K_NEW         => $02F1
; $1756 => OPEN_1               K_REPEAT      => $0310
; $175D => OPEN_2               K_ST_LOOP     => $02C6
; $1765 => REPORT_Fb            K_TEST        => $031E
; $1767 => OPEN_3               K_TOKENS      => $0364
; $177A => op_str_lu            KEY_3KEYS     => $029F
; $1781 => OPEN_K               KEY_BITS      => $02A1
; $1785 => OPEN_S               KEY_CHAN      => $1113
; $1789 => OPEN_P               KEY_CONTR     => $10FA
; $178B => OPEN_END             KEY_DATA      => $1105
; $1793 => CAT_ETC              KEY_DONE      => $02AB
; $1795 => AUTO_LIST            KEY_DONE2     => $111B
; $17CE => AUTO_L_1             KEY_FLAG      => $10F4
; $17E1 => AUTO_L_2             KEY_INPUT     => $10A8
; $17E4 => AUTO_L_3             KEY_INT       => $0048
; $17ED => AUTO_L_4             KEY_LINE      => $0296
; $17F5 => LLIST                KEY_M_CL      => $10DB
; $17F9 => LIST                 KEY_MODE      => $10E6
; $17FB => LIST_1               KEY_NEXT      => $110D
; $1814 => LIST_2               KEY_SCAN      => $028E
; $181A => LIST_3               KEYBOARD      => $02BF
; $181F => LIST_4               KSTATE        => $5C00
; $1822 => LIST_5               KSTATE1       => $5C01
; $1833 => LIST_ALL             KSTATE2       => $5C02
; $1835 => LIST_ALL_2           KSTATE3       => $5C03
; $1855 => OUT_LINE             KSTATE4       => $5C04
; $1865 => OUT_LINE1            KSTATE5       => $5C05
; $187D => OUT_LINE2            KSTATE6       => $5C06
; $1881 => OUT_LINE3            KSTATE7       => $5C07
; $1894 => OUT_LINE4            L0609         => $0609
; $18A1 => OUT_LINE5            L0EAF         => $0EAF
; $18B4 => OUT_LINE6            L1CA5         => $1CA5
; $18B6 => NUMBER               L2758         => $2758
; $18C1 => OUT_FLASH            L2E25         => $2E25
; $18E1 => OUT_CURS             L_ADD_        => $2BAF
; $18F3 => OUT_C_1              L_CHAR        => $2B3E
; $1909 => OUT_C_2              L_DELETE_     => $2B72
; $190F => LN_FETCH             L_EACH_CH     => $2B0B
; $191C => LN_STORE             L_ENTER       => $2BA6
; $1925 => OUT_SP_2             L_EXISTS      => $2B66
; $192A => OUT_SP_NO            L_FIRST       => $2BEA
; $192B => OUT_SP_1             L_IN_W_S      => $2BA3
; $1937 => OUT_CHAR             L_LENGTH      => $2B9B
; $195A => OUT_CH_1             L_NEW_        => $2BC0
; $1968 => OUT_CH_2             L_NO_SP       => $2B0C
; $196C => OUT_CH_3             L_NUMERIC     => $2B59
; $196E => LINE_ADDR            L_SINGLE      => $2B4F
; $1974 => LINE_AD_1            L_SPACES      => $2B29
; $1980 => CP_LINES             L_STRING      => $2BC6
; $1988 => not_used             L_TEST_CH     => $2B1F
; $198B => EACH_STMT            LAST          => $386C
; $1990 => EACH_S_1             LAST_K        => $5C08
; $1998 => EACH_S_2             LD_8_BITS     => $05CA
; $199A => EACH_S_3             LD_BLOCK      => $0802
; $19A5 => EACH_S_4             LD_BREAK      => $056B
; $19AD => EACH_S_5             LD_BYTES      => $0556
; $19B1 => EACH_S_6             LD_CH_PR      => $07AD
; $19B8 => NEXT_ONE             LD_CONT_1     => $0819
; $19C7 => NEXT_O_1             LD_CONT_2     => $0825
; $19CE => NEXT_O_2             LD_CONTRL     => $0808
; $19D5 => NEXT_O_3             LD_DATA       => $082E
; $19D6 => NEXT_O_4             LD_DATA_1     => $084C
; $19DB => NEXT_O_5             LD_DEC        => $05C4
; $19DD => DIFFER               LD_DELAY      => $05E9
; $19E5 => RECLAIM_1            LD_EDGE_1     => $05E7
; $19E8 => RECLAIM_2            LD_EDGE_2     => $05E3
; $19FB => E_LINE_NO            LD_FLAG       => $05B3
; $1A15 => E_L_1                LD_LEADER     => $0580
; $1A1B => OUT_NUM_1            LD_LOOK_H     => $0767
; $1A28 => OUT_NUM_2            LD_LOOP       => $05A9
; $1A30 => OUT_NUM_3            LD_MARKER     => $05C8
; $1A42 => OUT_NUM_4            LD_NAME       => $07A6
; $1A48 => offst_tbl            LD_NEXT       => $05C2
; $1A7A => P_LET                LD_PROG       => $0873
; $1A7D => P_GO_TO              LD_PROG_1     => $08AD
; $1A81 => P_IF                 LD_SAMPLE     => $05ED
; $1A86 => P_GO_SUB             LD_START      => $056C
; $1A8A => P_STOP               LD_SYNC       => $058F
; $1A8D => P_RETURN             LD_TYPE       => $078A
; $1A90 => P_FOR                LD_VERIFY     => $05BD
; $1A98 => P_NEXT               LD_WAIT       => $0574
; $1A9C => P_PRINT              len           => $3674
; $1A9F => P_INPUT              less_0        => $3506
; $1AA2 => P_DIM                LESS_MASK     => $328A
; $1AA5 => P_REM                LET           => $2AFF
; $1AA8 => P_NEW                LINE_AD_1     => $1974
; $1AAB => P_RUN                LINE_ADDR     => $196E
; $1AAE => P_LIST               LINE_DRAW     => $2477
; $1AB1 => P_POKE               LINE_END      => $1BB3
; $1AB5 => P_RANDOM             LINE_NEW      => $1B9E
; $1AB8 => P_CONT               LINE_NO       => $1695
; $1ABB => P_CLEAR              LINE_NO_A     => $1691
; $1ABE => P_CLS                LINE_RUN      => $1B8A
; $1AC1 => P_PLOT               LINE_SCAN     => $1B17
; $1AC5 => P_PAUSE              LINE_USE      => $1BBF
; $1AC9 => P_READ               LINE_ZERO     => $168F
; $1ACC => P_DATA               LIST          => $17F9
; $1ACF => P_RESTORE            LIST_1        => $17FB
; $1AD2 => P_DRAW               LIST_2        => $1814
; $1AD6 => P_COPY               LIST_3        => $181A
; $1AD9 => P_LPRINT             LIST_4        => $181F
; $1ADC => P_LLIST              LIST_5        => $1822
; $1ADF => P_SAVE               LIST_ALL      => $1833
; $1AE0 => P_LOAD               LIST_ALL_2    => $1835
; $1AE1 => P_VERIFY             LIST_SP       => $5C3F
; $1AE2 => P_MERGE              LLIST         => $17F5
; $1AE3 => P_BEEP               ln            => $3713
; $1AE7 => P_CIRCLE             LN_FETCH      => $190F
; $1AEB => P_INK                LN_STORE      => $191C
; $1AEC => P_PAPER              LOC_MEM       => $3406
; $1AED => P_FLASH              LOG_2_A_      => $2DC1
; $1AEE => P_BRIGHT             LOOK_P_1      => $1D8B
; $1AEF => P_INVERSE            LOOK_P_2      => $1DA3
; $1AF0 => P_OVER               LOOK_PROG     => $1D86
; $1AF1 => P_OUT                LOOK_VARS     => $28B2
; $1AF5 => P_BORDER             LPRINT        => $1FC9
; $1AF9 => P_DEF_FN             MAIN_1        => $12A9
; $1AFC => P_OPEN               MAIN_2        => $12AC
; $1B02 => P_CLOSE              MAIN_3        => $12CF
; $1B06 => P_FORMAT             MAIN_4        => $1303
; $1B0A => P_MOVE               MAIN_5        => $133C
; $1B10 => P_ERASE              MAIN_6        => $1373
; $1B14 => P_CAT                MAIN_7        => $1376
; $1B17 => LINE_SCAN            MAIN_8        => $1384
; $1B28 => STMT_LOOP            MAIN_9        => $1386
; $1B29 => STMT_L_1             MAIN_ADD      => $155D
; $1B52 => SCAN_LOOP            MAIN_ADD1     => $157D
; $1B55 => GET_PARAM            MAIN_ADD2     => $15AB
; $1B6F => SEPARATOR            MAIN_EXEC     => $12A2
; $1B76 => STMT_RET             MAIN_G        => $1313
; $1B7B => REPORT_L             MAIN_KEYS     => $0205
; $1B7D => STMT_R_1             MAKE_EXPT     => $313B
; $1B8A => LINE_RUN             MAKE_ROOM     => $1655
; $1B9E => LINE_NEW             MASK_INT      => $0038
; $1BB0 => REPORT_0             MASK_P        => $5C8E
; $1BB2 => REM                  MASK_T        => $5C90
; $1BB3 => LINE_END             ME_CONTRL     => $08B6
; $1BBF => LINE_USE             ME_ENT_1      => $093E
; $1BD1 => NEXT_LINE            ME_ENT_2      => $0955
; $1BEC => REPORT_N             ME_ENT_3      => $0958
; $1BEE => CHECK_END            ME_ENTER      => $092C
; $1BF4 => STMT_NEXT            ME_NEW_L2     => $08EB
; $1C01 => class_tbl            ME_NEW_LP     => $08D2
; $1C0D => CLASS_03             ME_OLD_L1     => $08DF
; $1C10 => CLASS_00             ME_OLD_LP     => $08D7
; $1C11 => CLASS_05             ME_OLD_V1     => $0901
; $1C1F => CLASS_01             ME_OLD_V2     => $0909
; $1C22 => VAR_A_1              ME_OLD_V3     => $0912
; $1C2E => REPORT_2             ME_OLD_V4     => $091E
; $1C30 => VAR_A_2              ME_OLD_VP     => $08F9
; $1C46 => VAR_A_3              ME_VAR_L1     => $0921
; $1C4E => CLASS_02             ME_VAR_L2     => $0923
; $1C56 => VAL_FET_1            ME_VAR_LP     => $08F0
; $1C59 => VAL_FET_2            MEM           => $5C68
; $1C6C => CLASS_04             MEMBOT        => $5C92
; $1C79 => NEXT_2NUM            MLT_LOOP      => $3114
; $1C7A => EXPT_2NUM            MODE          => $5C41
; $1C82 => EXPT_1NUM            MOVE_FP       => $33C0
; $1C8A => REPORT_C             MULT_LONG     => $30F0
; $1C8C => EXPT_EXP             MULT_OFLW     => $30EF
; $1C96 => CLASS_07             MULT_RSLT     => $30EA
; $1CA5 => L1CA5                multiply      => $30CA
; $1CBE => CLASS_09             n_mod_m       => $36A0
; $1CD6 => CL_09_1              N_NEGTV       => $3705
; $1CDB => CLASS_0B             NEAR_ZERO     => $3159
; $1CDE => FETCH_NUM            NEG_BYTE      => $2FAF
; $1CE6 => USE_ZERO             NEG_TEST      => $3474
; $1CEE => STOP_BAS             negate        => $346E
; $1CF0 => IF                   NEW           => $11B7
; $1D00 => IF_1                 NEWPPC        => $5C42
; $1D03 => FOR                  NEXT          => $1DAB
; $1D10 => F_USE_1              NEXT_1        => $1DE2
; $1D16 => F_REORDER            NEXT_2        => $1DE9
; $1D34 => F_L_S                NEXT_2NUM     => $1C79
; $1D64 => F_LOOP               NEXT_CHAR     => $0020
; $1D7C => F_FOUND              NEXT_LINE     => $1BD1
; $1D84 => REPORT_I             NEXT_LOOP     => $1DDA
; $1D86 => LOOK_PROG            NEXT_O_1      => $19C7
; $1D8B => LOOK_P_1             NEXT_O_2      => $19CE
; $1DA3 => LOOK_P_2             NEXT_O_3      => $19D5
; $1DAB => NEXT                 NEXT_O_4      => $19D6
; $1DD8 => REPORT_1             NEXT_O_5      => $19DB
; $1DDA => NEXT_LOOP            NEXT_ONE      => $19B8
; $1DE2 => NEXT_1               NIL_BYTES     => $3272
; $1DE9 => NEXT_2               NMI_VECT      => $121C
; $1DEC => READ_3               NMIADD        => $5CB0
; $1DED => READ                 no___no       => $3524
; $1E08 => REPORT_E             NO_ADD        => $311B
; $1E0A => READ_1               no_l_eql_etc_ => $353B
; $1E1E => READ_2               NO_RESET      => $0070
; $1E27 => DATA                 NO_RSTORE     => $31F9
; $1E2C => DATA_1               NORMALISE     => $316C
; $1E37 => DATA_2               NORML_NOW     => $3186
; $1E39 => PASS_BY              not           => $3501
; $1E42 => RESTORE              NOT_BIN       => $2CB8
; $1E45 => REST_RUN             not_used      => $1988
; $1E4F => RANDOMIZE            NSPPC         => $5C44
; $1E5A => RAND_1               NU_OR_STR     => $354E
; $1E5F => CONTINUE             NUMBER        => $18B6
; $1E67 => GO_TO                NUMERIC       => $2D1B
; $1E73 => GO_TO_2              NXT_DGT_1     => $2CDA
; $1E7A => OUT_BAS              NXT_DGT_2     => $2D40
; $1E80 => POKE                 NXTLIN        => $5C55
; $1E85 => TWO_PARAM            offst_tbl     => $1A48
; $1E8E => TWO_P_1              OFLOW_CLR     => $3195
; $1E94 => FIND_INT1            OFLW1_CLR     => $3146
; $1E99 => FIND_INT2            OFLW2_CLR     => $3151
; $1E9C => FIND_I_1             OLDPPC        => $5C6E
; $1E9F => REPORT_Bb            ONE           => $386A
; $1EA1 => RUN                  ONE_SHIFT     => $2FE5
; $1EAC => CLEAR                ONE_SPACE     => $1652
; $1EAF => CLEAR_RUN            op_str_lu     => $177A
; $1EB7 => CLEAR_1              OPEN          => $1736
; $1EDA => REPORT_M             OPEN_1        => $1756
; $1EDC => CLEAR_2              OPEN_2        => $175D
; $1EED => GO_SUB               OPEN_3        => $1767
; $1F05 => TEST_ROOM            OPEN_END      => $178B
; $1F15 => REPORT_4             OPEN_K        => $1781
; $1F1A => free_mem             OPEN_P        => $1789
; $1F23 => RETURN               OPEN_S        => $1785
; $1F36 => REPORT_7             or_func       => $351B
; $1F3A => PAUSE                OSPCC         => $5C70
; $1F3D => PAUSE_1              OTHER_STR     => $35B7
; $1F49 => PAUSE_2              OUT_BAS       => $1E7A
; $1F4F => PAUSE_END            OUT_C_1       => $18F3
; $1F54 => BREAK_KEY            OUT_C_2       => $1909
; $1F60 => DEF_FN               OUT_CH_1      => $195A
; $1F6A => DEF_FN_1             OUT_CH_2      => $1968
; $1F7D => DEF_FN_2             OUT_CH_3      => $196C
; $1F86 => DEF_FN_3             OUT_CHAR      => $1937
; $1F89 => DEF_FN_4             OUT_CODE      => $15EF
; $1F94 => DEF_FN_5             OUT_CURS      => $18E1
; $1FA6 => DEF_FN_6             OUT_FLASH     => $18C1
; $1FBD => DEF_FN_7             OUT_LINE      => $1855
; $1FC3 => UNSTACK_Z            OUT_LINE1     => $1865
; $1FC9 => LPRINT               OUT_LINE2     => $187D
; $1FCD => PRINT                OUT_LINE3     => $1881
; $1FCF => PRINT_1              OUT_LINE4     => $1894
; $1FDF => PRINT_2              OUT_LINE5     => $18A1
; $1FE5 => PRINT_3              OUT_LINE6     => $18B4
; $1FF2 => PRINT_4              OUT_NUM_1     => $1A1B
; $1FF5 => PRINT_CR             OUT_NUM_2     => $1A28
; $1FFC => PR_ITEM_1            OUT_NUM_3     => $1A30
; $200E => PR_ITEM_2            OUT_NUM_4     => $1A42
; $201E => PR_AT_TAB            OUT_SP_1      => $192B
; $2024 => PR_ITEM_3            OUT_SP_2      => $1925
; $203C => PR_STRING            OUT_SP_NO     => $192A
; $2045 => PR_END_Z             P_BEEP        => $1AE3
; $2048 => PR_ST_END            P_BORDER      => $1AF5
; $204E => PR_POSN_1            P_BRIGHT      => $1AEE
; $2061 => PR_POSN_2            P_CAT         => $1B14
; $2067 => PR_POSN_3            P_CIRCLE      => $1AE7
; $206E => PR_POSN_4            P_CLEAR       => $1ABB
; $2070 => STR_ALTER            P_CLOSE       => $1B02
; $2089 => INPUT                P_CLS         => $1ABE
; $2096 => INPUT_1              P_CONT        => $1AB8
; $20AD => INPUT_2              P_COPY        => $1AD6
; $20C1 => IN_ITEM_1            P_DATA        => $1ACC
; $20D8 => IN_ITEM_2            P_DEF_FN      => $1AF9
; $20ED => IN_ITEM_3            P_DIM         => $1AA2
; $20FA => IN_PROMPT            P_DRAW        => $1AD2
; $211A => IN_PR_1              P_ERASE       => $1B10
; $211C => IN_PR_2              P_FLAG        => $5C91
; $2129 => IN_PR_3              P_FLASH       => $1AED
; $213A => IN_VAR_1             P_FOR         => $1A90
; $2148 => IN_VAR_2             P_FORMAT      => $1B06
; $215E => IN_VAR_3             P_GO_SUB      => $1A86
; $2161 => IN_VAR_4             P_GO_TO       => $1A7D
; $2174 => IN_VAR_5             P_IF          => $1A81
; $219B => IN_VAR_6             P_INK         => $1AEB
; $21AF => IN_NEXT_1            P_INPUT       => $1A9F
; $21B2 => IN_NEXT_2            p_int_sto     => $2D8C
; $21B9 => IN_ASSIGN            P_INVERSE     => $1AEF
; $21CE => REPORT_Cb            P_LET         => $1A7A
; $21D0 => IN_STOP              P_LIST        => $1AAE
; $21D4 => REPORT_H             P_LLIST       => $1ADC
; $21D6 => IN_CHAN_K            P_LOAD        => $1AE0
; $21E1 => CO_TEMP_1            P_LPRINT      => $1AD9
; $21E2 => CO_TEMP_2            P_MERGE       => $1AE2
; $21F2 => CO_TEMP_3            P_MOVE        => $1B0A
; $21FC => CO_TEMP_4            P_NEW         => $1AA8
; $2211 => CO_TEMP_5            P_NEXT        => $1A98
; $2228 => CO_TEMP_6            P_OPEN        => $1AFC
; $2234 => CO_TEMP_7            P_OUT         => $1AF1
; $223E => CO_TEMP_8            P_OVER        => $1AF0
; $2244 => REPORT_K             P_PAPER       => $1AEC
; $2246 => CO_TEMP_9            P_PAUSE       => $1AC5
; $2257 => CO_TEMP_A            P_PLOT        => $1AC1
; $2258 => CO_TEMP_B            P_POKE        => $1AB1
; $226C => CO_CHANGE            P_POSN        => $5C7F
; $2273 => CO_TEMP_C            P_PRINT       => $1A9C
; $227D => CO_TEMP_D            P_RAMT        => $5CB4
; $2287 => CO_TEMP_E            P_RANDOM      => $1AB5
; $2294 => BORDER               P_READ        => $1AC9
; $22A6 => BORDER_1             P_REM         => $1AA5
; $22AA => PIXEL_ADD            P_RESTORE     => $1ACF
; $22CB => POINT_SUB            P_RETURN      => $1A8D
; $22D4 => POINT_LP             P_RUN         => $1AAB
; $22DC => PLOT                 P_SAVE        => $1ADF
; $22E5 => PLOT_SUB             P_STOP        => $1A8A
; $22F0 => PLOT_LOOP            P_VERIFY      => $1AE1
; $22FD => PL_TST_IN            PASS_BY       => $1E39
; $2303 => PLOT_END             PAUSE         => $1F3A
; $2307 => STK_TO_BC            PAUSE_1       => $1F3D
; $2314 => STK_TO_A             PAUSE_2       => $1F49
; $2320 => CIRCLE               PAUSE_END     => $1F4F
; $233B => C_R_GRE_1            peek          => $34AC
; $235A => C_ARC_GE1            PF_ALL_9      => $2EB8
; $2382 => DRAW                 PF_BITS       => $2E7B
; $238D => DR_3_PRMS            PF_BYTES      => $2E8A
; $23A3 => DR_SIN_NZ            PF_COUNT      => $2F2D
; $23C1 => DR_PRMS              PF_DC_OUT     => $2F5E
; $2420 => DRW_STEPS            PF_DEC_0S     => $2F64
; $2425 => ARC_LOOP             PF_DIGITS     => $2EA1
; $2439 => ARC_START            PF_E_FRMT     => $2F6C
; $245F => ARC_END              PF_E_POS      => $2F83
; $2477 => LINE_DRAW            PF_E_SBRN     => $2F4A
; $247D => CD_PRMS1             PF_E_SIGN     => $2F85
; $2495 => USE_252              PF_FR_DGT     => $2EEC
; $2497 => DRAW_SAVE            PF_FR_EXX     => $2EEF
; $24B7 => DRAW_LINE            PF_FRACTN     => $2ECF
; $24C4 => DL_X_GE_Y            PF_FRN_LP     => $2EDF
; $24CB => DL_LARGER            PF_INSERT     => $2EA9
; $24CE => D_L_LOOP             PF_LARGE      => $2E56
; $24D4 => D_L_DIAG             PF_LOOP       => $2E01
; $24DB => D_L_HR_VT            PF_MEDIUM     => $2E6F
; $24DF => D_L_STEP             PF_MORE       => $2ECB
; $24EC => D_L_PLOT             PF_NEGTVE     => $2DF2
; $24F7 => D_L_RANGE            PF_NOT_E      => $2F46
; $24F9 => REPORT_Bc            PF_OUT_DT     => $2F59
; $24FB => SCANNING             PF_OUT_LP     => $2F52
; $24FF => S_LOOP_1             PF_POSTVE     => $2DF8
; $250F => S_QUOTE_S            PF_R_BACK     => $2F25
; $2522 => S_2_COORD            PF_RND_LP     => $2F18
; $252D => S_RPORT_C            PF_ROUND      => $2F0C
; $2530 => SYNTAX_Z             PF_SAVE       => $2E1E
; $2535 => S_SCRN__S            PF_SMALL      => $2E24
; $254F => S_SCRN_LP            PF_TEST_2     => $2EB3
; $255A => S_SC_MTCH            PIP           => $5C39
; $255D => S_SC_ROWS            PIXEL_ADD     => $22AA
; $2573 => S_SCR_NXT            PL_TST_IN     => $22FD
; $257D => S_SCR_STO            PLOT          => $22DC
; $2580 => S_ATTR_S             PLOT_END      => $2303
; $2596 => scan_func            PLOT_LOOP     => $22F0
; $25AF => S_U_PLUS             PLOT_SUB      => $22E5
; $25B3 => S_QUOTE              PO_1_OPER     => $0A7A
; $25BE => S_Q_AGAIN            PO_2_OPER     => $0A75
; $25CB => S_Q_COPY             PO_ABLE       => $0AD9
; $25D9 => S_Q_PRMS             PO_ANY        => $0B24
; $25DB => S_STRING             PO_AT_ERR     => $0AAC
; $25E8 => S_BRACKET            PO_AT_SET     => $0ABF
; $25F5 => S_FN                 PO_ATTR       => $0BDB
; $25F8 => S_RND                PO_ATTR_1     => $0BFA
; $2625 => S_RND_END            PO_ATTR_2     => $0C08
; $2627 => S_PI                 PO_BACK_1     => $0A23
; $2630 => S_PI_END             PO_BACK_2     => $0A38
; $2634 => S_INKEY_             PO_BACK_3     => $0A3A
; $2660 => S_IK__STK            PO_CHANGE     => $0A80
; $2665 => S_INK__EN            PO_CHAR       => $0B65
; $2668 => S_SCREEN_            PO_CHAR_2     => $0B6A
; $2672 => S_ATTR               PO_CHAR_3     => $0B76
; $267B => S_POINT              PO_COMMA      => $0A5F
; $2684 => S_ALPHNUM            PO_CONT       => $0A87
; $268D => S_DECIMAL            PO_EACH       => $0C22
; $26B5 => S_STK_DEC            PO_ENTER      => $0A4F
; $26B6 => S_SD_SKIP            PO_F_PR       => $0B1D
; $26C3 => S_NUMERIC            PO_FETCH      => $0B03
; $26C9 => S_LETTER             PO_FILL       => $0AC3
; $26DD => S_CONT_1             PO_GR_1       => $0B38
; $26DF => S_NEGATE             PO_GR_2       => $0B3E
; $2707 => S_NO_TO__            PO_GR_3       => $0B4C
; $270D => S_PUSH_PO            PO_MSG        => $0C0A
; $2712 => S_CONT_2             PO_QUEST      => $0A69
; $2713 => S_CONT_3             PO_RIGHT      => $0A3D
; $2723 => S_OPERTR             PO_SAVE       => $0C3B
; $2734 => S_LOOP               PO_SCR        => $0C55
; $274C => S_STK_LST            PO_SCR_2      => $0C88
; $2758 => L2758                PO_SCR_3      => $0CD2
; $275B => S_SYNTEST            PO_SCR_3A     => $0CF0
; $2761 => S_RPORT_C2           PO_SCR_4      => $0D02
; $2764 => S_RUNTEST            PO_SCR_4A     => $0D1C
; $2770 => S_LOOPEND            PO_SCR_4B     => $0D2D
; $2773 => S_TIGHTER            PO_SEARCH     => $0C41
; $2788 => S_NOT_AND            PO_SPACE      => $0AD0
; $2790 => S_NEXT               PO_ST_E       => $0AF0
; $2795 => tbl_of_ops           PO_ST_PR      => $0AFC
; $27B0 => tbl_priors           PO_STEP       => $0C44
; $27BD => S_FN_SBRN            PO_STORE      => $0ADC
; $27D0 => SF_BRKT_1            PO_T          => $0B5F
; $27D9 => SF_ARGMTS            PO_T_UDG      => $0B52
; $27E4 => SF_BRKT_2            PO_TAB        => $0AC2
; $27E6 => SF_RPRT_C            PO_TABLE      => $0C14
; $27E9 => SF_FLAG_6            PO_TOKENS     => $0C10
; $27F4 => SF_SYN_EN            PO_TR_SP      => $0C35
; $27F7 => SF_RUN               PO_TV_1       => $0A7D
; $2802 => SF_ARGMT1            PO_TV_2       => $0A6D
; $2808 => SF_FND_DF            POINT_LP      => $22D4
; $2812 => REPORT_P             POINT_SUB     => $22CB
; $2814 => SF_CP_DEF            POINTERS      => $1664
; $2825 => SF_NOT_FD            POKE          => $1E80
; $2831 => SF_VALUES            PPC           => $5C45
; $2843 => SF_ARG_LP            PR_ALL        => $0B7F
; $2852 => SF_ARG_VL            PR_ALL_1      => $0B93
; $2885 => SF_R_BR_2            PR_ALL_2      => $0BA4
; $288B => REPORT_Q             PR_ALL_3      => $0BB6
; $288D => SF_VALUE             PR_ALL_4      => $0BB7
; $28AB => FN_SKPOVR            PR_ALL_5      => $0BC1
; $28B2 => LOOK_VARS            PR_ALL_6      => $0BD3
; $28D4 => V_CHAR               PR_AT_TAB     => $201E
; $28DE => V_STR_VAR            PR_CC         => $5C80
; $28E3 => V_TEST_FN            PR_END_Z      => $2045
; $28EF => V_RUN_SYN            PR_ITEM_1     => $1FFC
; $28FD => V_RUN                PR_ITEM_2     => $200E
; $2900 => V_EACH               PR_ITEM_3     => $2024
; $2912 => V_MATCHES            PR_POSN_1     => $204E
; $2913 => V_SPACES             PR_POSN_2     => $2061
; $2929 => V_GET_PTR            PR_POSN_3     => $2067
; $292A => V_NEXT               PR_POSN_4     => $206E
; $2932 => V_80_BYTE            PR_ST_END     => $2048
; $2934 => V_SYNTAX             PR_STRING     => $203C
; $293E => V_FOUND_1            PRB_BYTES     => $0EE7
; $293F => V_FOUND_2            PREP_ADD      => $2F9B
; $2943 => V_PASS               PREP_M_D      => $30C0
; $294B => V_END                PRINT         => $1FCD
; $2951 => STK_F_ARG            PRINT_1       => $1FCF
; $295A => SFA_LOOP             PRINT_2       => $1FDF
; $296B => SFA_CP_VR            PRINT_3       => $1FE5
; $2981 => SFA_MATCH            PRINT_4       => $1FF2
; $2991 => SFA_END              PRINT_A       => $0010
; $2996 => STK_VAR              PRINT_A_2     => $15F2
; $29A1 => SV_SIMPLE_           PRINT_CR      => $1FF5
; $29AE => SV_ARRAYS            PRINT_FP      => $2DE3
; $29C0 => SV_PTR               PRINT_OUT     => $09F4
; $29C3 => SV_COMMA             PROG          => $5C53
; $29D8 => SV_CLOSE             PTR_DONE      => $167F
; $29E0 => SV_CH_ADD            PTR_NEXT      => $166B
; $29E7 => SV_COUNT             R_I_STORE     => $365F
; $29EA => SV_LOOP              ram_check     => $11DA
; $29FB => SV_MULT              RAM_DONE      => $11EF
; $2A12 => SV_RPT_C             RAM_FILL      => $11DC
; $2A20 => REPORT_3             RAM_READ      => $11E2
; $2A22 => SV_NUMBER            RAM_SET       => $1219
; $2A2C => SV_ELEM_             RAMTOP        => $5CB2
; $2A45 => SV_SLICE             RAND_1        => $1E5A
; $2A48 => SV_DIM               RANDOMIZE     => $1E4F
; $2A49 => SV_SLICE_            RASP          => $5C38
; $2A52 => SLICING              RE_ENTRY      => $3365
; $2A7A => SL_RPT_C             RE_ST_TWO     => $3293
; $2A81 => SL_SECOND            re_stack      => $3297
; $2A94 => SL_DEFINE            READ          => $1DED
; $2AA8 => SL_OVER              READ_1        => $1E0A
; $2AAD => SL_STORE             READ_2        => $1E1E
; $2AB1 => STK_ST_0             READ_3        => $1DEC
; $2AB2 => STK_STO__            read_in       => $3645
; $2AB6 => STK_STORE            REC_EDIT      => $16D4
; $2ACC => INT_EXP1             RECLAIM_1     => $19E5
; $2ACD => INT_EXP2             RECLAIM_2     => $19E8
; $2AE8 => I_CARRY              REM           => $1BB2
; $2AEB => I_RESTORE            REMOVE_FP     => $11A7
; $2AEE => DE__DE_1_            REPDEL        => $5C09
; $2AF4 => GET_HL_DE            REPORT_0      => $1BB0
; $2AFF => LET                  REPORT_1      => $1DD8
; $2B0B => L_EACH_CH            REPORT_2      => $1C2E
; $2B0C => L_NO_SP              REPORT_2a     => $0670
; $2B1F => L_TEST_CH            REPORT_3      => $2A20
; $2B29 => L_SPACES             REPORT_4      => $1F15
; $2B3E => L_CHAR               REPORT_5      => $0C86
; $2B4F => L_SINGLE             REPORT_6      => $31AD
; $2B59 => L_NUMERIC            REPORT_6b     => $3703
; $2B66 => L_EXISTS             REPORT_7      => $1F36
; $2B72 => L_DELETE_            REPORT_8      => $15E4
; $2B9B => L_LENGTH             REPORT_A      => $34E7
; $2BA3 => L_IN_W_S             REPORT_Ab     => $371A
; $2BA6 => L_ENTER              REPORT_B      => $046C
; $2BAF => L_ADD_               REPORT_Bb     => $1E9F
; $2BC0 => L_NEW_               REPORT_Bc     => $24F9
; $2BC6 => L_STRING             REPORT_Bd     => $35DC
; $2BEA => L_FIRST              REPORT_C      => $1C8A
; $2BF1 => STK_FETCH            REPORT_Cb     => $21CE
; $2C02 => DIM                  REPORT_D      => $0D00
; $2C05 => D_RPORT_C            REPORT_Da     => $0552
; $2C15 => D_RUN                REPORT_Dc     => $0F0A
; $2C1F => D_LETTER             REPORT_E      => $1E08
; $2C2D => D_SIZE               REPORT_Fa     => $0642
; $2C2E => D_NO_LOOP            REPORT_Fb     => $1765
; $2C7C => DIM_CLEAR            REPORT_G      => $1555
; $2C7F => DIM_SIZES            REPORT_H      => $21D4
; $2C88 => ALPHANUM             REPORT_I      => $1D84
; $2C8D => ALPHA                REPORT_J      => $15C4
; $2C9B => DEC_TO_FP            REPORT_K      => $2244
; $2CA2 => BIN_DIGIT            REPORT_L      => $1B7B
; $2CB3 => BIN_END              REPORT_M      => $1EDA
; $2CB8 => NOT_BIN              REPORT_N      => $1BEC
; $2CCB => DECIMAL              REPORT_Oa     => $160E
; $2CCF => DEC_RPT_C            REPORT_Ob     => $1725
; $2CD5 => DEC_STO_1            REPORT_P      => $2812
; $2CDA => NXT_DGT_1            REPORT_Q      => $288B
; $2CEB => E_FORMAT             REPORT_R      => $0806
; $2CF2 => SIGN_FLAG            REPPER        => $5C0A
; $2CFE => SIGN_DONE            RESERVE       => $169E
; $2CFF => ST_E_PART            RESET         => $0066
; $2D18 => E_FP_JUMP            REST_RUN      => $1E45
; $2D1B => NUMERIC              RESTK_SUB     => $3296
; $2D22 => STK_DIGIT            RESTORE       => $1E42
; $2D28 => STACK_A              RESULT_OK     => $370C
; $2D2B => STACK_BC             RETURN        => $1F23
; $2D3B => INT_TO_FP            ROM_TRAP      => $1708
; $2D40 => NXT_DGT_2            rpt_mesgs     => $1391
; $2D4F => E_TO_FP              RS_NRMLSE     => $32B1
; $2D55 => E_SAVE               RS_STORE      => $32BD
; $2D60 => E_LOOP               RSLT_ZERO     => $370E
; $2D6D => E_DIVSN              RSTK_LOOP     => $32B2
; $2D6E => E_FETCH              RUN           => $1EA1
; $2D71 => E_TST_END            S_2_COORD     => $2522
; $2D7B => E_END                S_ALPHNUM     => $2684
; $2D7F => INT_FETCH            S_ATTR        => $2672
; $2D8C => p_int_sto            S_ATTR_S      => $2580
; $2D8E => INT_STORE            S_BRACKET     => $25E8
; $2DA2 => FP_TO_BC             S_CONT_1      => $26DD
; $2DAD => FP_DELETE            S_CONT_2      => $2712
; $2DC1 => LOG_2_A_             S_CONT_3      => $2713
; $2DD5 => FP_TO_A              S_DECIMAL     => $268D
; $2DE1 => FP_A_END             S_FN          => $25F5
; $2DE3 => PRINT_FP             S_FN_SBRN     => $27BD
; $2DF2 => PF_NEGTVE            S_IK__STK     => $2660
; $2DF8 => PF_POSTVE            S_INK__EN     => $2665
; $2E01 => PF_LOOP              S_INKEY_      => $2634
; $2E1E => PF_SAVE              S_LETTER      => $26C9
; $2E24 => PF_SMALL             S_LOOP        => $2734
; $2E25 => L2E25                S_LOOP_1      => $24FF
; $2E56 => PF_LARGE             S_LOOPEND     => $2770
; $2E6F => PF_MEDIUM            S_NEGATE      => $26DF
; $2E7B => PF_BITS              S_NEXT        => $2790
; $2E8A => PF_BYTES             S_NO_TO__     => $2707
; $2EA1 => PF_DIGITS            S_NOT_AND     => $2788
; $2EA9 => PF_INSERT            S_NUMERIC     => $26C3
; $2EB3 => PF_TEST_2            S_OPERTR      => $2723
; $2EB8 => PF_ALL_9             S_PI          => $2627
; $2ECB => PF_MORE              S_PI_END      => $2630
; $2ECF => PF_FRACTN            S_POINT       => $267B
; $2EDF => PF_FRN_LP            S_POSN        => $5C88
; $2EEC => PF_FR_DGT            S_POSN_hi     => $5C89
; $2EEF => PF_FR_EXX            S_PUSH_PO     => $270D
; $2F0C => PF_ROUND             S_Q_AGAIN     => $25BE
; $2F18 => PF_RND_LP            S_Q_COPY      => $25CB
; $2F25 => PF_R_BACK            S_Q_PRMS      => $25D9
; $2F2D => PF_COUNT             S_QUOTE       => $25B3
; $2F46 => PF_NOT_E             S_QUOTE_S     => $250F
; $2F4A => PF_E_SBRN            S_RND         => $25F8
; $2F52 => PF_OUT_LP            S_RND_END     => $2625
; $2F59 => PF_OUT_DT            S_RPORT_C     => $252D
; $2F5E => PF_DC_OUT            S_RPORT_C2    => $2761
; $2F64 => PF_DEC_0S            S_RUNTEST     => $2764
; $2F6C => PF_E_FRMT            S_SC_MTCH     => $255A
; $2F83 => PF_E_POS             S_SC_ROWS     => $255D
; $2F85 => PF_E_SIGN            S_SCR_NXT     => $2573
; $2F8B => CA_10_A_C            S_SCR_STO     => $257D
; $2F9B => PREP_ADD             S_SCREEN_     => $2668
; $2FAF => NEG_BYTE             S_SCRN__S     => $2535
; $2FBA => FETCH_TWO            S_SCRN_LP     => $254F
; $2FDD => SHIFT_FP             S_SD_SKIP     => $26B6
; $2FE5 => ONE_SHIFT            S_STK_DEC     => $26B5
; $2FF9 => ADDEND_0             S_STK_LST     => $274C
; $2FFB => ZEROS_4_5            S_STRING      => $25DB
; $3004 => ADD_BACK             S_SYNTEST     => $275B
; $300D => ALL_ADDED            S_TIGHTER     => $2773
; $300F => subtract             S_TOP         => $5C6C
; $3014 => addition             S_U_PLUS      => $25AF
; $303C => ADDN_OFLW            SA_1_SEC      => $0991
; $303E => FULL_ADDN            SA_8_BITS     => $0525
; $3055 => SHIFT_LEN            SA_ALL        => $075A
; $307C => TEST_NEG             SA_BIT_1      => $0514
; $309F => ADD_REP_6            SA_BIT_2      => $0511
; $30A3 => END_COMPL            SA_BLANK      => $0629
; $30A5 => GO_NC_MLT            SA_BYTES      => $04C2
; $30A9 => HL_HL_DE             SA_CODE       => $06C3
; $30B1 => HL_LOOP              SA_CODE_1     => $06E1
; $30BC => HL_AGAIN             SA_CODE_2     => $06F0
; $30BE => HL_END               SA_CODE_3     => $06F5
; $30C0 => PREP_M_D             SA_CODE_4     => $06F9
; $30CA => multiply             SA_CONTRL     => $0970
; $30EA => MULT_RSLT            SA_DATA       => $0652
; $30EF => MULT_OFLW            SA_DATA_1     => $0692
; $30F0 => MULT_LONG            SA_DELAY      => $053C
; $3114 => MLT_LOOP             SA_FLAG       => $04D0
; $311B => NO_ADD               SA_LD_END     => $0554
; $3125 => STRT_MLT             SA_LD_RET     => $053F
; $313B => MAKE_EXPT            SA_LEADER     => $04D8
; $313D => DIVN_EXPT            SA_LINE       => $0716
; $3146 => OFLW1_CLR            SA_LINE_1     => $0723
; $3151 => OFLW2_CLR            SA_LOOP       => $04FE
; $3155 => TEST_NORM            SA_LOOP_P     => $0505
; $3159 => NEAR_ZERO            SA_NAME       => $064B
; $315D => ZERO_RSLT            SA_NULL       => $0644
; $315E => SKIP_ZERO            SA_OUT        => $051C
; $316C => NORMALISE            SA_PARITY     => $050E
; $316E => SHIFT_ONE            SA_SCR_       => $06A0
; $3186 => NORML_NOW            SA_SET        => $051A
; $3195 => OFLOW_CLR            SA_SPACE      => $0621
; $31AD => REPORT_6             SA_START      => $0507
; $31AF => division             SA_SYNC_1     => $04EA
; $31D2 => DIV_LOOP             SA_SYNC_2     => $04F2
; $31DB => div_34th             SA_TYPE_0     => $073A
; $31E2 => DIV_START            SA_TYPE_3     => $0710
; $31F2 => SUBN_ONLY            SA_V_NEW      => $0685
; $31F9 => NO_RSTORE            SA_V_OLD      => $0672
; $31FA => COUNT_ONE            SA_V_TYPE     => $068F
; $3214 => truncate             SAVE_ETC      => $0605
; $3221 => T_GR_ZERO            SCAN_ENT      => $336C
; $3233 => T_FIRST              scan_func     => $2596
; $323F => T_SMALL              SCAN_LOOP     => $1B52
; $3252 => T_NUMERIC            SCANNING      => $24FB
; $325E => T_TEST               SCR_CT        => $5C8C
; $3261 => T_SHIFT              scrl_mssg     => $0CF8
; $3267 => T_STORE              SEC_PLUS      => $3575
; $326C => T_EXPNENT            SECND_LOW     => $356B
; $326D => X_LARGE              SEED          => $5C76
; $3272 => NIL_BYTES            semi_tone     => $046E
; $327E => BYTE_ZERO            SEPARATOR     => $1B6F
; $3283 => BITS_ZERO            series_xx     => $3449
; $328A => LESS_MASK            SET_DE        => $1195
; $3290 => IX_END               SET_HL        => $1190
; $3293 => RE_ST_TWO            SET_MIN       => $16B0
; $3296 => RESTK_SUB            SET_STK       => $16C5
; $3297 => re_stack             SET_WORK      => $16BF
; $32B1 => RS_NRMLSE            SF_ARG_LP     => $2843
; $32B2 => RSTK_LOOP            SF_ARG_VL     => $2852
; $32BD => RS_STORE             SF_ARGMT1     => $2802
; $32C5 => stk_zero             SF_ARGMTS     => $27D9
; $32C8 => stk_one              SF_BRKT_1     => $27D0
; $32CC => stk_half             SF_BRKT_2     => $27E4
; $32CE => stk_pi_2             SF_CP_DEF     => $2814
; $32D3 => stk_ten              SF_FLAG_6     => $27E9
; $32D7 => tbl_addrs            SF_FND_DF     => $2808
; $335B => CALCULATE            SF_NOT_FD     => $2825
; $335E => GEN_ENT_1            SF_R_BR_2     => $2885
; $3362 => GEN_ENT_2            SF_RPRT_C     => $27E6
; $3365 => RE_ENTRY             SF_RUN        => $27F7
; $336C => SCAN_ENT             SF_SYN_EN     => $27F4
; $3380 => FIRST_3D             SF_VALUE      => $288D
; $338C => DOUBLE_A             SF_VALUES     => $2831
; $338E => ENT_TABLE            SFA_CP_VR     => $296B
; $33A1 => delete               SFA_END       => $2991
; $33A2 => fp_calc_2            SFA_LOOP      => $295A
; $33A9 => TEST_5_SP            SFA_MATCH     => $2981
; $33B4 => STACK_NUM            sgn           => $3492
; $33C0 => MOVE_FP              SHIFT_FP      => $2FDD
; $33C6 => stk_data             SHIFT_LEN     => $3055
; $33C8 => STK_CONST            SHIFT_ONE     => $316E
; $33DE => FORM_EXP             SIGN_DONE     => $2CFE
; $33F1 => STK_ZEROS            SIGN_FLAG     => $2CF2
; $33F7 => SKIP_CONS            SIGN_TO_C     => $3507
; $33F8 => SKIP_NEXT            sin           => $37B5
; $3406 => LOC_MEM              SKIP_CONS     => $33F7
; $340F => get_mem_xx           SKIP_NEXT     => $33F8
; $341B => stk_const_xx         SKIP_OVER     => $007D
; $342D => st_mem_xx            SKIP_ZERO     => $315E
; $343C => exchange             SKIPS         => $0090
; $343E => SWAP_BYTE            SL_DEFINE     => $2A94
; $3449 => series_xx            SL_OVER       => $2AA8
; $346A => abs                  SL_RPT_C      => $2A7A
; $346E => negate               SL_SECOND     => $2A81
; $3474 => NEG_TEST             SL_STORE      => $2AAD
; $3483 => INT_CASE             SLICING       => $2A52
; $3492 => sgn                  SMALL         => $37F8
; $34A5 => in_func              spare         => $386E
; $34AC => peek                 SPOSNL        => $5C8A
; $34B0 => IN_PK_STK            sqr           => $384A
; $34B3 => usr_no               ST_E_PART     => $2CFF
; $34BC => usr__                st_mem_xx     => $342D
; $34D3 => USR_RANGE            STACK_A       => $2D28
; $34E4 => USR_STACK            STACK_BC      => $2D2B
; $34E7 => REPORT_A             STACK_NUM     => $33B4
; $34E9 => TEST_ZERO            START         => $0000
; $34F9 => greater_0            START_NEW     => $11CB
; $3501 => not                  STK_CODE      => $3671
; $3506 => less_0               STK_CONST     => $33C8
; $3507 => SIGN_TO_C            stk_const_xx  => $341B
; $350B => FP_0_1               stk_data      => $33C6
; $351B => or_func              STK_DIGIT     => $2D22
; $3524 => no___no              STK_F_ARG     => $2951
; $352D => str___no             STK_FETCH     => $2BF1
; $353B => no_l_eql_etc_        stk_half      => $32CC
; $3543 => EX_OR_NOT            stk_one       => $32C8
; $354E => NU_OR_STR            stk_pi_2      => $32CE
; $3559 => STRINGS              STK_PNTRS     => $35BF
; $3564 => BYTE_COMP            STK_ST_0      => $2AB1
; $356B => SECND_LOW            STK_STO__     => $2AB2
; $3572 => BOTH_NULL            STK_STORE     => $2AB6
; $3575 => SEC_PLUS             stk_ten       => $32D3
; $3585 => FRST_LESS            STK_TO_A      => $2314
; $3588 => STR_TEST             STK_TO_BC     => $2307
; $358C => END_TESTS            STK_VAR       => $2996
; $359C => strs_add             stk_zero      => $32C5
; $35B7 => OTHER_STR            STK_ZEROS     => $33F1
; $35BF => STK_PNTRS            STKBOT        => $5C63
; $35C9 => chrs                 STKEND        => $5C65
; $35DC => REPORT_Bd            STMT_L_1      => $1B29
; $35DE => val_                 STMT_LOOP     => $1B28
; $360C => V_RPORT_C            STMT_NEXT     => $1BF4
; $361F => str_                 STMT_R_1      => $1B7D
; $3645 => read_in              STMT_RET      => $1B76
; $365F => R_I_STORE            STOP_BAS      => $1CEE
; $3669 => code                 str_          => $361F
; $3671 => STK_CODE             str___no      => $352D
; $3674 => len                  STR_ALTER     => $2070
; $367A => dec_jr_nz            STR_DATA      => $171E
; $3686 => JUMP                 STR_DATA1     => $1727
; $3687 => JUMP_2               STR_TEST      => $3588
; $368F => jump_true            STRINGS       => $3559
; $369B => end_calc             STRLEN        => $5C72
; $36A0 => n_mod_m              STRMS         => $5C10
; $36AF => int                  strs_add      => $359C
; $36B7 => X_NEG                STRT_MLT      => $3125
; $36C2 => EXIT                 SUBN_ONLY     => $31F2
; $36C4 => exp                  SUBPPC        => $5C47
; $3703 => REPORT_6b            subtract      => $300F
; $3705 => N_NEGTV              SV_ARRAYS     => $29AE
; $370C => RESULT_OK            SV_CH_ADD     => $29E0
; $370E => RSLT_ZERO            SV_CLOSE      => $29D8
; $3713 => ln                   SV_COMMA      => $29C3
; $371A => REPORT_Ab            SV_COUNT      => $29E7
; $371C => VALID                SV_DIM        => $2A48
; $373D => GRE_8                SV_ELEM_      => $2A2C
; $3783 => get_argt             SV_LOOP       => $29EA
; $37A1 => ZPLUS                SV_MULT       => $29FB
; $37A8 => YNEG                 SV_NUMBER     => $2A22
; $37AA => cos                  SV_PTR        => $29C0
; $37B5 => sin                  SV_RPT_C      => $2A12
; $37B7 => C_ENT                SV_SIMPLE_    => $29A1
; $37DA => tan                  SV_SLICE      => $2A45
; $37E2 => atn                  SV_SLICE_     => $2A49
; $37F8 => SMALL                SWAP_BYTE     => $343E
; $37FA => CASES                SYM_CODES     => $026A
; $3833 => asn                  SYNTAX_Z      => $2530
; $3843 => acs                  T_ADDR        => $5C74
; $384A => sqr                  T_EXPNENT     => $326C
; $3851 => to_power             T_FIRST       => $3233
; $385D => XIS0                 T_GR_ZERO     => $3221
; $386A => ONE                  T_NUMERIC     => $3252
; $386C => LAST                 T_SHIFT       => $3261
; $386E => spare                T_SMALL       => $323F
; $3D00 => char_set             T_STORE       => $3267
; $5C00 => KSTATE               T_TEST        => $325E
; $5C01 => KSTATE1              tan           => $37DA
; $5C02 => KSTATE2              tape_msgs     => $09A1
; $5C03 => KSTATE3              tape_msgs_2   => $09C1
; $5C04 => KSTATE4              tbl_addrs     => $32D7
; $5C05 => KSTATE5              tbl_of_ops    => $2795
; $5C06 => KSTATE6              tbl_priors    => $27B0
; $5C07 => KSTATE7              TEMP_PTR1     => $0077
; $5C08 => LAST_K               TEMP_PTR2     => $0078
; $5C09 => REPDEL               TEMPS         => $0D4D
; $5C0A => REPPER               TEMPS_1       => $0D5B
; $5C0B => DEFADD               TEMPS_2       => $0D65
; $5C0D => K_DATA               TEST_5_SP     => $33A9
; $5C0E => TVDATA               TEST_CHAR     => $001C
; $5C10 => STRMS                TEST_NEG      => $307C
; $5C36 => CHARS                TEST_NORM     => $3155
; $5C38 => RASP                 TEST_ROOM     => $1F05
; $5C39 => PIP                  TEST_ZERO     => $34E9
; $5C3A => ERR_NR               TKN_TABLE     => $0095
; $5C3B => FLAGS                to_power      => $3851
; $5C3C => TV_FLAG              truncate      => $3214
; $5C3D => ERR_SP               TV_FLAG       => $5C3C
; $5C3F => LIST_SP              TVDATA        => $5C0E
; $5C41 => MODE                 TWO_P_1       => $1E8E
; $5C42 => NEWPPC               TWO_PARAM     => $1E85
; $5C44 => NSPPC                UDG           => $5C7B
; $5C45 => PPC                  UNSTACK_Z     => $1FC3
; $5C47 => SUBPPC               USE_252       => $2495
; $5C48 => BORDCR               USE_ZERO      => $1CE6
; $5C49 => E_PPC                usr__         => $34BC
; $5C4B => VARS                 usr_no        => $34B3
; $5C4D => DEST                 USR_RANGE     => $34D3
; $5C4F => CHANS                USR_STACK     => $34E4
; $5C51 => CURCHL               V_80_BYTE     => $2932
; $5C53 => PROG                 V_CHAR        => $28D4
; $5C55 => NXTLIN               V_EACH        => $2900
; $5C57 => DATADD               V_END         => $294B
; $5C59 => E_LINE               V_FOUND_1     => $293E
; $5C5B => K_CUR                V_FOUND_2     => $293F
; $5C5D => CH_ADD               V_GET_PTR     => $2929
; $5C5F => X_PTR                V_MATCHES     => $2912
; $5C61 => WORKSP               V_NEXT        => $292A
; $5C63 => STKBOT               V_PASS        => $2943
; $5C65 => STKEND               V_RPORT_C     => $360C
; $5C67 => BREG                 V_RUN         => $28FD
; $5C68 => MEM                  V_RUN_SYN     => $28EF
; $5C6A => FLAGS2               V_SPACES      => $2913
; $5C6B => DF_SZ                V_STR_VAR     => $28DE
; $5C6C => S_TOP                V_SYNTAX      => $2934
; $5C6E => OLDPPC               V_TEST_FN     => $28E3
; $5C70 => OSPCC                val_          => $35DE
; $5C71 => FLAGX                VAL_FET_1     => $1C56
; $5C72 => STRLEN               VAL_FET_2     => $1C59
; $5C74 => T_ADDR               VALID         => $371C
; $5C76 => SEED                 VAR_A_1       => $1C22
; $5C78 => FRAMES               VAR_A_2       => $1C30
; $5C7A => FRAMES3              VAR_A_3       => $1C46
; $5C7B => UDG                  VARS          => $5C4B
; $5C7D => COORDS               VR_CONT_1     => $07E9
; $5C7E => COORDS_hi            VR_CONT_2     => $07F4
; $5C7F => P_POSN               VR_CONT_3     => $0800
; $5C80 => PR_CC                VR_CONTRL     => $07CB
; $5C82 => ECHO_E               WAIT_KEY      => $15D4
; $5C84 => DF_CC                WAIT_KEY1     => $15DE
; $5C86 => DFCCL                WORKSP        => $5C61
; $5C88 => S_POSN               X007B         => $007B
; $5C89 => S_POSN_hi            X08CE         => $08CE
; $5C8A => SPOSNL               X0F85         => $0F85
; $5C8C => SCR_CT               X1349         => $1349
; $5C8D => ATTR_P               X_LARGE       => $326D
; $5C8E => MASK_P               X_NEG         => $36B7
; $5C8F => ATTR_T               X_PTR         => $5C5F
; $5C90 => MASK_T               XIS0          => $385D
; $5C91 => P_FLAG               YNEG          => $37A8
; $5C92 => MEMBOT               ZERO_RSLT     => $315D
; $5CB0 => NMIADD               ZEROS_4_5     => $2FFB
; $5CB2 => RAMTOP               ZPLUS         => $37A1
; $5CB4 => P_RAMT               zx81_name     => $04AA
