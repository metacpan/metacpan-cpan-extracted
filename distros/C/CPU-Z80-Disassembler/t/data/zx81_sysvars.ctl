0000	:<
		:<; ================
		:<; ZX-81 MEMORY MAP
		:<; ================
		:<
		:<
		:<; +------------------+-- Top of memory
		:<; | Reserved area    |
		:<; +------------------+-- (RAMTOP)
		:<; | GOSUB stack      |
		:<; +------------------+-- (ERR_SP)
		:<; | Machine stack    |
		:<; +------------------+-- SP
		:<; | Spare memory     |
		:<; +------------------+-- (STKEND)
		:<; | Calculator stack |
		:<; +------------------+-- (STKBOT)
		:<; | Edit line        |
		:<; +------------------+-- (E_LINE)
		:<; | User variables   |
		:<; +------------------+-- (VARS)
		:<; | Screen           |
		:<; +------------------+-- (D_FILE)
		:<; | User program     |
		:<; +------------------+-- 407Dh (16509d)
		:<; | System variables |
		:<; +------------------+-- 4000h (16384d)
		:<
		:<
		:<; ======================
		:<; ZX-81 SYSTEM VARIABLES
		:<; ======================
		:<
		:<

4000	:IY

4000	:=	ERR_NR 			; N1   Current report code minus one
4001	:=	FLAGS  			; N1   Various flags
4002	:=	ERR_SP 			; N2   Address of top of GOSUB stack
4004	:=	RAMTOP 			; N2   Address of reserved area (not wiped out by NEW)
4006	:=	MODE   			; N1   Current cursor mode
4007	:=	PPC    			; N2   Line number of line being executed
4009	:=	VERSN  			; N1   First system variable to be SAVEd
400A	:=	E_PPC  			; N2   Line number of line with cursor
400C	:=	D_FILE 			; N2   Address of start of display file
400E	:=	DF_CC  			; N2   Address of print position within display file
4010	:=	VARS   			; N2   Address of start of variables area
4012	:=	DEST   			; N2   Address of variable being assigned
4014	:=	E_LINE 			; N2   Address of start of edit line
4016	:=	CH_ADD 			; N2   Address of the next character to interpret
4018	:=	X_PTR  			; N2   Address of char. preceding syntax error marker
401A	:=	STKBOT 			; N2   Address of calculator stack
401C	:=	STKEND 			; N2   Address of end of calculator stack
401E	:=	BERG   			; N1   Used by floating point calculator
401F	:=	MEM    			; N2   Address of start of calculator's memory area
4021	:=	SPARE1 			; N1   One spare byte
4022	:=	DF_SZ  			; N2   Number of lines in lower part of screen
4023	:=	S_TOP  			; N2   Line number of line at top of screen
4025	:=	LAST_K 			; N2   Keyboard scan taken after the last TV frame
4027	:=	DB_ST  			; N1   Debounce status of keyboard
4028	:=	MARGIN 			; N1   Number of blank lines above or below picture
4029	:=	NXTLIN 			; N2   Address of next program line to be executed
402B	:=	OLDPPC 			; N2   Line number to which CONT/CONTINUE jumps
402D	:=	FLAGX  			; N1   Various flags
402E	:=	STRLEN 			; N2   Information concerning assigning of strings
4030	:=	T_ADDR 			; N2   Address of next item in syntax table
4032	:=	SEED   			; N2   Seed for random number generator
4034	:=	FRAMES 			; N2   Updated once for every TV frame displayed
4036	:=	COORDS 			; N2   Coordinates of last point PLOTed
4038	:=	PR_CC  			; N1   Address of LPRINT position (high part assumed $40)
4039	:=	S_POSN 			; N2   Coordinates of print position
403B	:=	CDFLAG 			; N1   Flags relating to FAST/SLOW mode
403C	:=	PRBUFF 			; N21h Buffer to store LPRINT output
405D	:=	MEMBOT 			; N1E  Area which may be used for calculator memory
407B	:=	SPARE2 			; N2   Two spare bytes
407D	:=	PROG			;      Start of BASIC program
