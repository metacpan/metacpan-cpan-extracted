        org 0
        adc  a,(hl)             ; 0000 8E
        ADC  A,(HL)             ; 0001 8E
        adc  a,(ix)             ; 0002 DD 8E 00
        ADC  A,(IX)             ; 0005 DD 8E 00
        adc  a,(ix+-128)        ; 0008 DD 8E 80
        adc  a,(ix-128)         ; 000B DD 8E 80
        adc  a,(ix+-127)        ; 000E DD 8E 81
        adc  a,(ix-127)         ; 0011 DD 8E 81
        adc  a,(ix+-1)          ; 0014 DD 8E FF
        adc  a,(ix-1)           ; 0017 DD 8E FF
        adc  a,(ix+-0)          ; 001A DD 8E 00
        adc  a,(ix-0)           ; 001D DD 8E 00
        adc  a,(ix+0)           ; 0020 DD 8E 00
        adc  a,(ix)             ; 0023 DD 8E 00
        adc  a,(ix+1)           ; 0026 DD 8E 01
        adc  a,(ix+126)         ; 0029 DD 8E 7E
        adc  a,(ix+127)         ; 002C DD 8E 7F
        adc  a,(ix+127)         ; 002F DD 8E 7F
        adc  a,(iy)             ; 0032 FD 8E 00
        ADC  A,(IY)             ; 0035 FD 8E 00
        adc  a,(iy+127)         ; 0038 FD 8E 7F
        adc  a,(iy+127)         ; 003B FD 8E 7F
        adc  a,-128             ; 003E CE 80
        adc  a,-127             ; 0040 CE 81
        adc  a,-2               ; 0042 CE FE
        adc  a,-1               ; 0044 CE FF
        adc  a,0                ; 0046 CE 00
        adc  a,1                ; 0048 CE 01
        adc  a,126              ; 004A CE 7E
        adc  a,127              ; 004C CE 7F
        adc  a,128              ; 004E CE 80
        adc  a,129              ; 0050 CE 81
        adc  a,254              ; 0052 CE FE
        adc  a,255              ; 0054 CE FF
        adc  a,a                ; 0056 8F
        adc  a,b                ; 0057 88
        ADC  A,B                ; 0058 88
        adc  a,c                ; 0059 89
        ADC  A,C                ; 005A 89
        adc  a,d                ; 005B 8A
        ADC  A,D                ; 005C 8A
        adc  a,e                ; 005D 8B
        ADC  A,E                ; 005E 8B
        adc  a,h                ; 005F 8C
        ADC  A,H                ; 0060 8C
        adc  a,ixh              ; 0061 DD 8C
        ADC  A,IXH              ; 0063 DD 8C
        adc  a,ixl              ; 0065 DD 8D
        ADC  A,IXL              ; 0067 DD 8D
        adc  a,iyh              ; 0069 FD 8C
        ADC  A,IYH              ; 006B FD 8C
        adc  a,iyl              ; 006D FD 8D
        ADC  A,IYL              ; 006F FD 8D
        adc  a,l                ; 0071 8D
        ADC  A,L                ; 0072 8D
        adc  hl,bc              ; 0073 ED 4A
        ADC  HL,BC              ; 0075 ED 4A
        adc  hl,de              ; 0077 ED 5A
        ADC  HL,DE              ; 0079 ED 5A
        adc  hl,hl              ; 007B ED 6A
        adc  hl,sp              ; 007D ED 7A
        ADC  HL,SP              ; 007F ED 7A
        add  a,(hl)             ; 0081 86
        ADD  A,(HL)             ; 0082 86
        add  a,(ix)             ; 0083 DD 86 00
        add  a,(ix+127)         ; 0086 DD 86 7F
        add  a,(ix+127)         ; 0089 DD 86 7F
        add  a,(iy)             ; 008C FD 86 00
        add  a,(iy+127)         ; 008F FD 86 7F
        add  a,(iy+127)         ; 0092 FD 86 7F
        add  a,255              ; 0095 C6 FF
        add  a,a                ; 0097 87
        add  a,b                ; 0098 80
        add  a,c                ; 0099 81
        add  a,d                ; 009A 82
        add  a,e                ; 009B 83
        add  a,h                ; 009C 84
        add  a,ixh              ; 009D DD 84
        add  a,ixl              ; 009F DD 85
        add  a,iyh              ; 00A1 FD 84
        add  a,iyl              ; 00A3 FD 85
        add  a,l                ; 00A5 85
        add  hl,bc              ; 00A6 09
        add  hl,de              ; 00A7 19
        add  hl,hl              ; 00A8 29
        add  hl,sp              ; 00A9 39
        add  ix,bc              ; 00AA DD 09
        add  ix,de              ; 00AC DD 19
        add  ix,ix              ; 00AE DD 29
        add  ix,sp              ; 00B0 DD 39
        add  iy,bc              ; 00B2 FD 09
        add  iy,de              ; 00B4 FD 19
        add  iy,iy              ; 00B6 FD 29
        add  iy,sp              ; 00B8 FD 39
        and  (hl)               ; 00BA A6
        AND  (HL)               ; 00BB A6
        and  (ix)               ; 00BC DD A6 00
        and  (ix+127)           ; 00BF DD A6 7F
        and  (ix+127)           ; 00C2 DD A6 7F
        and  (iy)               ; 00C5 FD A6 00
        and  (iy+127)           ; 00C8 FD A6 7F
        and  (iy+127)           ; 00CB FD A6 7F
        and  255                ; 00CE E6 FF
        and  a                  ; 00D0 A7
        and  b                  ; 00D1 A0
        and  c                  ; 00D2 A1
        and  d                  ; 00D3 A2
        and  e                  ; 00D4 A3
        and  h                  ; 00D5 A4
        and  ixh                ; 00D6 DD A4
        and  ixl                ; 00D8 DD A5
        and  iyh                ; 00DA FD A4
        and  iyl                ; 00DC FD A5
        and  l                  ; 00DE A5
        bit  0,(hl)             ; 00DF CB 46
        BIT  0,(HL)             ; 00E1 CB 46
        bit  0,(ix)             ; 00E3 DD CB 00 46
        bit  0,(ix+127)         ; 00E7 DD CB 7F 46
        bit  0,(ix+127)         ; 00EB DD CB 7F 46
        bit  0,(iy)             ; 00EF FD CB 00 46
        bit  0,(iy+127)         ; 00F3 FD CB 7F 46
        bit  0,(iy+127)         ; 00F7 FD CB 7F 46
        bit  0,a                ; 00FB CB 47
        bit  0,b                ; 00FD CB 40
        bit  0,c                ; 00FF CB 41
        bit  0,d                ; 0101 CB 42
        bit  0,e                ; 0103 CB 43
        bit  0,h                ; 0105 CB 44
        bit  0,l                ; 0107 CB 45
        bit  1,(hl)             ; 0109 CB 4E
        bit  1,(ix)             ; 010B DD CB 00 4E
        bit  1,(ix+127)         ; 010F DD CB 7F 4E
        bit  1,(ix+127)         ; 0113 DD CB 7F 4E
        bit  1,(iy)             ; 0117 FD CB 00 4E
        bit  1,(iy+127)         ; 011B FD CB 7F 4E
        bit  1,(iy+127)         ; 011F FD CB 7F 4E
        bit  1,a                ; 0123 CB 4F
        bit  1,b                ; 0125 CB 48
        bit  1,c                ; 0127 CB 49
        bit  1,d                ; 0129 CB 4A
        bit  1,e                ; 012B CB 4B
        bit  1,h                ; 012D CB 4C
        bit  1,l                ; 012F CB 4D
        bit  2,(hl)             ; 0131 CB 56
        bit  2,(ix)             ; 0133 DD CB 00 56
        bit  2,(ix+127)         ; 0137 DD CB 7F 56
        bit  2,(ix+127)         ; 013B DD CB 7F 56
        bit  2,(iy)             ; 013F FD CB 00 56
        bit  2,(iy+127)         ; 0143 FD CB 7F 56
        bit  2,(iy+127)         ; 0147 FD CB 7F 56
        bit  2,a                ; 014B CB 57
        bit  2,b                ; 014D CB 50
        bit  2,c                ; 014F CB 51
        bit  2,d                ; 0151 CB 52
        bit  2,e                ; 0153 CB 53
        bit  2,h                ; 0155 CB 54
        bit  2,l                ; 0157 CB 55
        bit  3,(hl)             ; 0159 CB 5E
        bit  3,(ix)             ; 015B DD CB 00 5E
        bit  3,(ix+127)         ; 015F DD CB 7F 5E
        bit  3,(ix+127)         ; 0163 DD CB 7F 5E
        bit  3,(iy)             ; 0167 FD CB 00 5E
        bit  3,(iy+127)         ; 016B FD CB 7F 5E
        bit  3,(iy+127)         ; 016F FD CB 7F 5E
        bit  3,a                ; 0173 CB 5F
        bit  3,b                ; 0175 CB 58
        bit  3,c                ; 0177 CB 59
        bit  3,d                ; 0179 CB 5A
        bit  3,e                ; 017B CB 5B
        bit  3,h                ; 017D CB 5C
        bit  3,l                ; 017F CB 5D
        bit  4,(hl)             ; 0181 CB 66
        bit  4,(ix)             ; 0183 DD CB 00 66
        bit  4,(ix+127)         ; 0187 DD CB 7F 66
        bit  4,(ix+127)         ; 018B DD CB 7F 66
        bit  4,(iy)             ; 018F FD CB 00 66
        bit  4,(iy+127)         ; 0193 FD CB 7F 66
        bit  4,(iy+127)         ; 0197 FD CB 7F 66
        bit  4,a                ; 019B CB 67
        bit  4,b                ; 019D CB 60
        bit  4,c                ; 019F CB 61
        bit  4,d                ; 01A1 CB 62
        bit  4,e                ; 01A3 CB 63
        bit  4,h                ; 01A5 CB 64
        bit  4,l                ; 01A7 CB 65
        bit  5,(hl)             ; 01A9 CB 6E
        bit  5,(ix)             ; 01AB DD CB 00 6E
        bit  5,(ix+127)         ; 01AF DD CB 7F 6E
        bit  5,(ix+127)         ; 01B3 DD CB 7F 6E
        bit  5,(iy)             ; 01B7 FD CB 00 6E
        bit  5,(iy+127)         ; 01BB FD CB 7F 6E
        bit  5,(iy+127)         ; 01BF FD CB 7F 6E
        bit  5,a                ; 01C3 CB 6F
        bit  5,b                ; 01C5 CB 68
        bit  5,c                ; 01C7 CB 69
        bit  5,d                ; 01C9 CB 6A
        bit  5,e                ; 01CB CB 6B
        bit  5,h                ; 01CD CB 6C
        bit  5,l                ; 01CF CB 6D
        bit  6,(hl)             ; 01D1 CB 76
        bit  6,(ix)             ; 01D3 DD CB 00 76
        bit  6,(ix+127)         ; 01D7 DD CB 7F 76
        bit  6,(ix+127)         ; 01DB DD CB 7F 76
        bit  6,(iy)             ; 01DF FD CB 00 76
        bit  6,(iy+127)         ; 01E3 FD CB 7F 76
        bit  6,(iy+127)         ; 01E7 FD CB 7F 76
        bit  6,a                ; 01EB CB 77
        bit  6,b                ; 01ED CB 70
        bit  6,c                ; 01EF CB 71
        bit  6,d                ; 01F1 CB 72
        bit  6,e                ; 01F3 CB 73
        bit  6,h                ; 01F5 CB 74
        bit  6,l                ; 01F7 CB 75
        bit  7,(hl)             ; 01F9 CB 7E
        bit  7,(ix)             ; 01FB DD CB 00 7E
        bit  7,(ix+127)         ; 01FF DD CB 7F 7E
        bit  7,(ix+127)         ; 0203 DD CB 7F 7E
        bit  7,(iy)             ; 0207 FD CB 00 7E
        bit  7,(iy+127)         ; 020B FD CB 7F 7E
        bit  7,(iy+127)         ; 020F FD CB 7F 7E
        bit  7,a                ; 0213 CB 7F
        bit  7,b                ; 0215 CB 78
        bit  7,c                ; 0217 CB 79
        bit  7,d                ; 0219 CB 7A
        bit  7,e                ; 021B CB 7B
        bit  7,h                ; 021D CB 7C
        bit  7,l                ; 021F CB 7D
        call -32768             ; 0221 CD 00 80
        CALL -32768             ; 0224 CD 00 80
        call -32767             ; 0227 CD 01 80
        call -128               ; 022A CD 80 FF
        call -1                 ; 022D CD FF FF
        call 0                  ; 0230 CD 00 00
        call 1                  ; 0233 CD 01 00
        call 127                ; 0236 CD 7F 00
        call 128                ; 0239 CD 80 00
        call 255                ; 023C CD FF 00
        call 256                ; 023F CD 00 01
        call 32767              ; 0242 CD FF 7F
        call 32768              ; 0245 CD 00 80
        call 65534              ; 0248 CD FE FF
        call 65535              ; 024B CD FF FF
        call c,65535            ; 024E DC FF FF
        call m,65535            ; 0251 FC FF FF
        CALL M,65535            ; 0254 FC FF FF
        call nc,65535           ; 0257 D4 FF FF
        CALL NC,65535           ; 025A D4 FF FF
        call nz,65535           ; 025D C4 FF FF
        CALL NZ,65535           ; 0260 C4 FF FF
        call p,65535            ; 0263 F4 FF FF
        CALL P,65535            ; 0266 F4 FF FF
        call pe,65535           ; 0269 EC FF FF
        CALL PE,65535           ; 026C EC FF FF
        call po,65535           ; 026F E4 FF FF
        CALL PO,65535           ; 0272 E4 FF FF
        call z,65535            ; 0275 CC FF FF
        CALL Z,65535            ; 0278 CC FF FF
        ccf                     ; 027B 3F
        CCF                     ; 027C 3F
        cp   (hl)               ; 027D BE
        CP   (HL)               ; 027E BE
        cp   (ix)               ; 027F DD BE 00
        cp   (ix+127)           ; 0282 DD BE 7F
        cp   (ix+127)           ; 0285 DD BE 7F
        cp   (iy)               ; 0288 FD BE 00
        cp   (iy+127)           ; 028B FD BE 7F
        cp   (iy+127)           ; 028E FD BE 7F
        cp   255                ; 0291 FE FF
        cp   a                  ; 0293 BF
        cp   b                  ; 0294 B8
        cp   c                  ; 0295 B9
        cp   d                  ; 0296 BA
        cp   e                  ; 0297 BB
        cp   h                  ; 0298 BC
        cp   ixh                ; 0299 DD BC
        cp   ixl                ; 029B DD BD
        cp   iyh                ; 029D FD BC
        cp   iyl                ; 029F FD BD
        cp   l                  ; 02A1 BD
        cpd                     ; 02A2 ED A9
        CPD                     ; 02A4 ED A9
        cpdr                    ; 02A6 ED B9
        CPDR                    ; 02A8 ED B9
        cpi                     ; 02AA ED A1
        CPI                     ; 02AC ED A1
        cpir                    ; 02AE ED B1
        CPIR                    ; 02B0 ED B1
        cpl                     ; 02B2 2F
        CPL                     ; 02B3 2F
        daa                     ; 02B4 27
        DAA                     ; 02B5 27
        dec  (hl)               ; 02B6 35
        DEC  (HL)               ; 02B7 35
        dec  (ix)               ; 02B8 DD 35 00
        dec  (ix+127)           ; 02BB DD 35 7F
        dec  (ix+127)           ; 02BE DD 35 7F
        dec  (iy)               ; 02C1 FD 35 00
        dec  (iy+127)           ; 02C4 FD 35 7F
        dec  (iy+127)           ; 02C7 FD 35 7F
        dec  a                  ; 02CA 3D
        dec  b                  ; 02CB 05
        dec  bc                 ; 02CC 0B
        dec  c                  ; 02CD 0D
        dec  d                  ; 02CE 15
        dec  de                 ; 02CF 1B
        dec  e                  ; 02D0 1D
        dec  h                  ; 02D1 25
        dec  hl                 ; 02D2 2B
        dec  ix                 ; 02D3 DD 2B
        dec  ixh                ; 02D5 DD 25
        dec  ixl                ; 02D7 DD 2D
        dec  iy                 ; 02D9 FD 2B
        dec  iyh                ; 02DB FD 25
        dec  iyl                ; 02DD FD 2D
        dec  l                  ; 02DF 2D
        dec  sp                 ; 02E0 3B
        di                      ; 02E1 F3
        DI                      ; 02E2 F3
        djnz 613                ; 02E3 10 80
        DJNZ 615                ; 02E5 10 80
        djnz 618                ; 02E7 10 81
        djnz 745                ; 02E9 10 FE
        djnz 749                ; 02EB 10 00
        djnz 752                ; 02ED 10 01
        djnz 879                ; 02EF 10 7E
        djnz 882                ; 02F1 10 7F
        ei                      ; 02F3 FB
        EI                      ; 02F4 FB
        ex   (sp),hl            ; 02F5 E3
        EX   (SP),HL            ; 02F6 E3
        ex   (sp),ix            ; 02F7 DD E3
        ex   (sp),iy            ; 02F9 FD E3
        ex   af,af'             ; 02FB 08
        EX   AF,AF'             ; 02FC 08
        ex   de,hl              ; 02FD EB
        exx                     ; 02FE D9
        EXX                     ; 02FF D9
        halt                    ; 0300 76
        HALT                    ; 0301 76
        im   0                  ; 0302 ED 46
        IM   0                  ; 0304 ED 46
        im   1                  ; 0306 ED 56
        im   2                  ; 0308 ED 5E
        in   a,(255)            ; 030A DB FF
        IN   A,(255)            ; 030C DB FF
        in   a,(c)              ; 030E ED 78
        in   b,(c)              ; 0310 ED 40
        in   c,(c)              ; 0312 ED 48
        in   d,(c)              ; 0314 ED 50
        in   e,(c)              ; 0316 ED 58
        in   f,(c)              ; 0318 ED 70
        IN   F,(C)              ; 031A ED 70
        in   h,(c)              ; 031C ED 60
        in   l,(c)              ; 031E ED 68
        inc  (hl)               ; 0320 34
        INC  (HL)               ; 0321 34
        inc  (ix)               ; 0322 DD 34 00
        inc  (ix+127)           ; 0325 DD 34 7F
        inc  (ix+127)           ; 0328 DD 34 7F
        inc  (iy)               ; 032B FD 34 00
        inc  (iy+127)           ; 032E FD 34 7F
        inc  (iy+127)           ; 0331 FD 34 7F
        inc  a                  ; 0334 3C
        inc  b                  ; 0335 04
        inc  bc                 ; 0336 03
        inc  c                  ; 0337 0C
        inc  d                  ; 0338 14
        inc  de                 ; 0339 13
        inc  e                  ; 033A 1C
        inc  h                  ; 033B 24
        inc  hl                 ; 033C 23
        inc  ix                 ; 033D DD 23
        inc  ixh                ; 033F DD 24
        inc  ixl                ; 0341 DD 2C
        inc  iy                 ; 0343 FD 23
        inc  iyh                ; 0345 FD 24
        inc  iyl                ; 0347 FD 2C
        inc  l                  ; 0349 2C
        inc  sp                 ; 034A 33
        ind                     ; 034B ED AA
        IND                     ; 034D ED AA
        indr                    ; 034F ED BA
        INDR                    ; 0351 ED BA
        ini                     ; 0353 ED A2
        INI                     ; 0355 ED A2
        inir                    ; 0357 ED B2
        INIR                    ; 0359 ED B2
        jp   (hl)               ; 035B E9
        JP   (HL)               ; 035C E9
        jp   (ix)               ; 035D DD E9
        jp   (iy)               ; 035F FD E9
        jp   65535              ; 0361 C3 FF FF
        jp   c,65535            ; 0364 DA FF FF
        jp   m,65535            ; 0367 FA FF FF
        jp   nc,65535           ; 036A D2 FF FF
        jp   nz,65535           ; 036D C2 FF FF
        jp   p,65535            ; 0370 F2 FF FF
        jp   pe,65535           ; 0373 EA FF FF
        jp   po,65535           ; 0376 E2 FF FF
        jp   z,65535            ; 0379 CA FF FF
        jr   1021               ; 037C 18 7F
        JR   1023               ; 037E 18 7F
        jr   c,1025             ; 0380 38 7F
        jr   m,1027             ; 0382 FA 03 04
        jr   nc,1030            ; 0385 30 7F
        jr   nz,1032            ; 0387 20 7F
        jr   p,1034             ; 0389 F2 0A 04
        jr   pe,1037            ; 038C EA 0D 04
        jr   po,1040            ; 038F E2 10 04
        jr   z,1043             ; 0392 28 7F
        ld   (65535),a          ; 0394 32 FF FF
        LD   (65535),A          ; 0397 32 FF FF
        ld   (65535),bc         ; 039A ED 43 FF FF
        ld   (65535),de         ; 039E ED 53 FF FF
        ld   (65535),hl         ; 03A2 22 FF FF
        ld   (65535),ix         ; 03A5 DD 22 FF FF
        ld   (65535),iy         ; 03A9 FD 22 FF FF
        ld   (65535),sp         ; 03AD ED 73 FF FF
        ld   (bc),a             ; 03B1 02
        ld   (de),a             ; 03B2 12
        ld   (hl),255           ; 03B3 36 FF
        ld   (hl),a             ; 03B5 77
        ld   (hl),b             ; 03B6 70
        ld   (hl),bc            ; 03B7 71 23 70 2B
        ld   (hl),c             ; 03BB 71
        ld   (hl),d             ; 03BC 72
        ld   (hl),de            ; 03BD 73 23 72 2B
        ld   (hl),e             ; 03C1 73
        ld   (hl),h             ; 03C2 74
        ld   (hl),l             ; 03C3 75
        ld   (ix),255           ; 03C4 DD 36 00 FF
        ld   (ix),a             ; 03C8 DD 77 00
        ld   (ix),b             ; 03CB DD 70 00
        ld   (ix),bc            ; 03CE DD 71 00 DD 70 01
        ld   (ix),c             ; 03D4 DD 71 00
        ld   (ix),d             ; 03D7 DD 72 00
        ld   (ix),de            ; 03DA DD 73 00 DD 72 01
        ld   (ix),e             ; 03E0 DD 73 00
        ld   (ix),h             ; 03E3 DD 74 00
        ld   (ix),hl            ; 03E6 DD 75 00 DD 74 01
        ld   (ix),l             ; 03EC DD 75 00
        ld   (ix+127),255       ; 03EF DD 36 7F FF
        ld   (ix+127),a         ; 03F3 DD 77 7F
        ld   (ix+127),b         ; 03F6 DD 70 7F
        ld   (ix+126),bc        ; 03F9 DD 71 7E DD 70 7F
        ld   (ix+127),c         ; 03FF DD 71 7F
        ld   (ix+127),d         ; 0402 DD 72 7F
        ld   (ix+126),de        ; 0405 DD 73 7E DD 72 7F
        ld   (ix+127),e         ; 040B DD 73 7F
        ld   (ix+127),h         ; 040E DD 74 7F
        ld   (ix+126),hl        ; 0411 DD 75 7E DD 74 7F
        ld   (ix+127),l         ; 0417 DD 75 7F
        ld   (ix+127),255       ; 041A DD 36 7F FF
        ld   (ix+127),a         ; 041E DD 77 7F
        ld   (ix+127),b         ; 0421 DD 70 7F
        ld   (ix+126),bc        ; 0424 DD 71 7E DD 70 7F
        ld   (ix+127),c         ; 042A DD 71 7F
        ld   (ix+127),d         ; 042D DD 72 7F
        ld   (ix+126),de        ; 0430 DD 73 7E DD 72 7F
        ld   (ix+127),e         ; 0436 DD 73 7F
        ld   (ix+127),h         ; 0439 DD 74 7F
        ld   (ix+126),hl        ; 043C DD 75 7E DD 74 7F
        ld   (ix+127),l         ; 0442 DD 75 7F
        ld   (iy),255           ; 0445 FD 36 00 FF
        ld   (iy),a             ; 0449 FD 77 00
        ld   (iy),b             ; 044C FD 70 00
        ld   (iy),bc            ; 044F FD 71 00 FD 70 01
        ld   (iy),c             ; 0455 FD 71 00
        ld   (iy),d             ; 0458 FD 72 00
        ld   (iy),de            ; 045B FD 73 00 FD 72 01
        ld   (iy),e             ; 0461 FD 73 00
        ld   (iy),h             ; 0464 FD 74 00
        ld   (iy),hl            ; 0467 FD 75 00 FD 74 01
        ld   (iy),l             ; 046D FD 75 00
        ld   (iy+127),255       ; 0470 FD 36 7F FF
        ld   (iy+127),a         ; 0474 FD 77 7F
        ld   (iy+127),b         ; 0477 FD 70 7F
        ld   (iy+126),bc        ; 047A FD 71 7E FD 70 7F
        ld   (iy+127),c         ; 0480 FD 71 7F
        ld   (iy+127),d         ; 0483 FD 72 7F
        ld   (iy+126),de        ; 0486 FD 73 7E FD 72 7F
        ld   (iy+127),e         ; 048C FD 73 7F
        ld   (iy+127),h         ; 048F FD 74 7F
        ld   (iy+126),hl        ; 0492 FD 75 7E FD 74 7F
        ld   (iy+127),l         ; 0498 FD 75 7F
        ld   (iy+127),255       ; 049B FD 36 7F FF
        ld   (iy+127),a         ; 049F FD 77 7F
        ld   (iy+127),b         ; 04A2 FD 70 7F
        ld   (iy+126),bc        ; 04A5 FD 71 7E FD 70 7F
        ld   (iy+127),c         ; 04AB FD 71 7F
        ld   (iy+127),d         ; 04AE FD 72 7F
        ld   (iy+126),de        ; 04B1 FD 73 7E FD 72 7F
        ld   (iy+127),e         ; 04B7 FD 73 7F
        ld   (iy+127),h         ; 04BA FD 74 7F
        ld   (iy+126),hl        ; 04BD FD 75 7E FD 74 7F
        ld   (iy+127),l         ; 04C3 FD 75 7F
        ld   a,(65535)          ; 04C6 3A FF FF
        ld   a,(bc)             ; 04C9 0A
        ld   a,(de)             ; 04CA 1A
        ld   a,(hl)             ; 04CB 7E
        ld   a,(ix)             ; 04CC DD 7E 00
        ld   a,(ix+127)         ; 04CF DD 7E 7F
        ld   a,(ix+127)         ; 04D2 DD 7E 7F
        ld   a,(iy)             ; 04D5 FD 7E 00
        ld   a,(iy+127)         ; 04D8 FD 7E 7F
        ld   a,(iy+127)         ; 04DB FD 7E 7F
        ld   a,255              ; 04DE 3E FF
        ld   a,a                ; 04E0 7F
        ld   a,b                ; 04E1 78
        ld   a,c                ; 04E2 79
        ld   a,d                ; 04E3 7A
        ld   a,e                ; 04E4 7B
        ld   a,h                ; 04E5 7C
        ld   a,i                ; 04E6 ED 57
        LD   A,I                ; 04E8 ED 57
        ld   a,ixh              ; 04EA DD 7C
        ld   a,ixl              ; 04EC DD 7D
        ld   a,iyh              ; 04EE FD 7C
        ld   a,iyl              ; 04F0 FD 7D
        ld   a,l                ; 04F2 7D
        ld   a,r                ; 04F3 ED 5F
        LD   A,R                ; 04F5 ED 5F
        ld   b,(hl)             ; 04F7 46
        ld   b,(ix)             ; 04F8 DD 46 00
        ld   b,(ix+127)         ; 04FB DD 46 7F
        ld   b,(ix+127)         ; 04FE DD 46 7F
        ld   b,(iy)             ; 0501 FD 46 00
        ld   b,(iy+127)         ; 0504 FD 46 7F
        ld   b,(iy+127)         ; 0507 FD 46 7F
        ld   b,255              ; 050A 06 FF
        ld   b,a                ; 050C 47
        ld   b,b                ; 050D 40
        ld   b,c                ; 050E 41
        ld   b,d                ; 050F 42
        ld   b,e                ; 0510 43
        ld   b,h                ; 0511 44
        ld   b,ixh              ; 0512 DD 44
        ld   b,ixl              ; 0514 DD 45
        ld   b,iyh              ; 0516 FD 44
        ld   b,iyl              ; 0518 FD 45
        ld   b,l                ; 051A 45
        ld   bc,(65535)         ; 051B ED 4B FF FF
        ld   bc,(hl)            ; 051F 4E 23 46 2B
        ld   bc,(ix)            ; 0523 DD 4E 00 DD 46 01
        ld   bc,(ix+126)        ; 0529 DD 4E 7E DD 46 7F
        ld   bc,(ix+126)        ; 052F DD 4E 7E DD 46 7F
        ld   bc,(iy)            ; 0535 FD 4E 00 FD 46 01
        ld   bc,(iy+126)        ; 053B FD 4E 7E FD 46 7F
        ld   bc,(iy+126)        ; 0541 FD 4E 7E FD 46 7F
        ld   bc,65535           ; 0547 01 FF FF
        ld   bc,bc              ; 054A 40 49
        ld   bc,de              ; 054C 42 4B
        ld   bc,hl              ; 054E 44 4D
        ld   bc,ix              ; 0550 DD 44 DD 4D
        ld   bc,iy              ; 0554 FD 44 FD 4D
        ld   c,(hl)             ; 0558 4E
        ld   c,(ix)             ; 0559 DD 4E 00
        ld   c,(ix+127)         ; 055C DD 4E 7F
        ld   c,(ix+127)         ; 055F DD 4E 7F
        ld   c,(iy)             ; 0562 FD 4E 00
        ld   c,(iy+127)         ; 0565 FD 4E 7F
        ld   c,(iy+127)         ; 0568 FD 4E 7F
        ld   c,255              ; 056B 0E FF
        ld   c,a                ; 056D 4F
        ld   c,b                ; 056E 48
        ld   c,c                ; 056F 49
        ld   c,d                ; 0570 4A
        ld   c,e                ; 0571 4B
        ld   c,h                ; 0572 4C
        ld   c,ixh              ; 0573 DD 4C
        ld   c,ixl              ; 0575 DD 4D
        ld   c,iyh              ; 0577 FD 4C
        ld   c,iyl              ; 0579 FD 4D
        ld   c,l                ; 057B 4D
        ld   d,(hl)             ; 057C 56
        ld   d,(ix)             ; 057D DD 56 00
        ld   d,(ix+127)         ; 0580 DD 56 7F
        ld   d,(ix+127)         ; 0583 DD 56 7F
        ld   d,(iy)             ; 0586 FD 56 00
        ld   d,(iy+127)         ; 0589 FD 56 7F
        ld   d,(iy+127)         ; 058C FD 56 7F
        ld   d,255              ; 058F 16 FF
        ld   d,a                ; 0591 57
        ld   d,b                ; 0592 50
        ld   d,c                ; 0593 51
        ld   d,d                ; 0594 52
        ld   d,e                ; 0595 53
        ld   d,h                ; 0596 54
        ld   d,ixh              ; 0597 DD 54
        ld   d,ixl              ; 0599 DD 55
        ld   d,iyh              ; 059B FD 54
        ld   d,iyl              ; 059D FD 55
        ld   d,l                ; 059F 55
        ld   de,(65535)         ; 05A0 ED 5B FF FF
        ld   de,(hl)            ; 05A4 5E 23 56 2B
        ld   de,(ix)            ; 05A8 DD 5E 00 DD 56 01
        ld   de,(ix+126)        ; 05AE DD 5E 7E DD 56 7F
        ld   de,(ix+126)        ; 05B4 DD 5E 7E DD 56 7F
        ld   de,(iy)            ; 05BA FD 5E 00 FD 56 01
        ld   de,(iy+126)        ; 05C0 FD 5E 7E FD 56 7F
        ld   de,(iy+126)        ; 05C6 FD 5E 7E FD 56 7F
        ld   de,65535           ; 05CC 11 FF FF
        ld   de,bc              ; 05CF 50 59
        ld   de,de              ; 05D1 52 5B
        ld   de,hl              ; 05D3 54 5D
        ld   de,ix              ; 05D5 DD 54 DD 5D
        ld   de,iy              ; 05D9 FD 54 FD 5D
        ld   e,(hl)             ; 05DD 5E
        ld   e,(ix)             ; 05DE DD 5E 00
        ld   e,(ix+127)         ; 05E1 DD 5E 7F
        ld   e,(ix+127)         ; 05E4 DD 5E 7F
        ld   e,(iy)             ; 05E7 FD 5E 00
        ld   e,(iy+127)         ; 05EA FD 5E 7F
        ld   e,(iy+127)         ; 05ED FD 5E 7F
        ld   e,255              ; 05F0 1E FF
        ld   e,a                ; 05F2 5F
        ld   e,b                ; 05F3 58
        ld   e,c                ; 05F4 59
        ld   e,d                ; 05F5 5A
        ld   e,e                ; 05F6 5B
        ld   e,h                ; 05F7 5C
        ld   e,ixh              ; 05F8 DD 5C
        ld   e,ixl              ; 05FA DD 5D
        ld   e,iyh              ; 05FC FD 5C
        ld   e,iyl              ; 05FE FD 5D
        ld   e,l                ; 0600 5D
        ld   h,(hl)             ; 0601 66
        ld   h,(ix)             ; 0602 DD 66 00
        ld   h,(ix+127)         ; 0605 DD 66 7F
        ld   h,(ix+127)         ; 0608 DD 66 7F
        ld   h,(iy)             ; 060B FD 66 00
        ld   h,(iy+127)         ; 060E FD 66 7F
        ld   h,(iy+127)         ; 0611 FD 66 7F
        ld   h,255              ; 0614 26 FF
        ld   h,a                ; 0616 67
        ld   h,b                ; 0617 60
        ld   h,c                ; 0618 61
        ld   h,d                ; 0619 62
        ld   h,e                ; 061A 63
        ld   h,h                ; 061B 64
        ld   h,l                ; 061C 65
        ld   hl,(65535)         ; 061D 2A FF FF
        ld   hl,(ix)            ; 0620 DD 6E 00 DD 66 01
        ld   hl,(ix+126)        ; 0626 DD 6E 7E DD 66 7F
        ld   hl,(ix+126)        ; 062C DD 6E 7E DD 66 7F
        ld   hl,(iy)            ; 0632 FD 6E 00 FD 66 01
        ld   hl,(iy+126)        ; 0638 FD 6E 7E FD 66 7F
        ld   hl,(iy+126)        ; 063E FD 6E 7E FD 66 7F
        ld   hl,65535           ; 0644 21 FF FF
        ld   hl,bc              ; 0647 60 69
        ld   hl,de              ; 0649 62 6B
        ld   hl,hl              ; 064B 64 6D
        ld   hl,ix              ; 064D DD E5 E1
        ld   hl,iy              ; 0650 FD E5 E1
        ld   i,a                ; 0653 ED 47
        ld   ix,(65535)         ; 0655 DD 2A FF FF
        ld   ix,65535           ; 0659 DD 21 FF FF
        ld   ix,bc              ; 065D DD 69 DD 60
        ld   ix,de              ; 0661 DD 6B DD 62
        ld   ix,hl              ; 0665 E5 DD E1
        ld   ix,ix              ; 0668 DD 6D DD 64
        ld   ix,iy              ; 066C FD E5 DD E1
        ld   ixh,255            ; 0670 DD 26 FF
        ld   ixh,a              ; 0673 DD 67
        ld   ixh,b              ; 0675 DD 60
        ld   ixh,c              ; 0677 DD 61
        ld   ixh,d              ; 0679 DD 62
        ld   ixh,e              ; 067B DD 63
        ld   ixh,ixh            ; 067D DD 64
        ld   ixh,ixl            ; 067F DD 65
        ld   ixl,255            ; 0681 DD 2E FF
        ld   ixl,a              ; 0684 DD 6F
        ld   ixl,b              ; 0686 DD 68
        ld   ixl,c              ; 0688 DD 69
        ld   ixl,d              ; 068A DD 6A
        ld   ixl,e              ; 068C DD 6B
        ld   ixl,ixh            ; 068E DD 6C
        ld   ixl,ixl            ; 0690 DD 6D
        ld   iy,(65535)         ; 0692 FD 2A FF FF
        ld   iy,65535           ; 0696 FD 21 FF FF
        ld   iy,bc              ; 069A FD 69 FD 60
        ld   iy,de              ; 069E FD 6B FD 62
        ld   iy,hl              ; 06A2 E5 FD E1
        ld   iy,ix              ; 06A5 DD E5 FD E1
        ld   iy,iy              ; 06A9 FD 6D FD 64
        ld   iyh,255            ; 06AD FD 26 FF
        ld   iyh,a              ; 06B0 FD 67
        ld   iyh,b              ; 06B2 FD 60
        ld   iyh,c              ; 06B4 FD 61
        ld   iyh,d              ; 06B6 FD 62
        ld   iyh,e              ; 06B8 FD 63
        ld   iyh,iyh            ; 06BA FD 64
        ld   iyh,iyl            ; 06BC FD 65
        ld   iyl,255            ; 06BE FD 2E FF
        ld   iyl,a              ; 06C1 FD 6F
        ld   iyl,b              ; 06C3 FD 68
        ld   iyl,c              ; 06C5 FD 69
        ld   iyl,d              ; 06C7 FD 6A
        ld   iyl,e              ; 06C9 FD 6B
        ld   iyl,iyh            ; 06CB FD 6C
        ld   iyl,iyl            ; 06CD FD 6D
        ld   l,(hl)             ; 06CF 6E
        ld   l,(ix)             ; 06D0 DD 6E 00
        ld   l,(ix+127)         ; 06D3 DD 6E 7F
        ld   l,(ix+127)         ; 06D6 DD 6E 7F
        ld   l,(iy)             ; 06D9 FD 6E 00
        ld   l,(iy+127)         ; 06DC FD 6E 7F
        ld   l,(iy+127)         ; 06DF FD 6E 7F
        ld   l,255              ; 06E2 2E FF
        ld   l,a                ; 06E4 6F
        ld   l,b                ; 06E5 68
        ld   l,c                ; 06E6 69
        ld   l,d                ; 06E7 6A
        ld   l,e                ; 06E8 6B
        ld   l,h                ; 06E9 6C
        ld   l,l                ; 06EA 6D
        ld   r,a                ; 06EB ED 4F
        ld   sp,(65535)         ; 06ED ED 7B FF FF
        ld   sp,65535           ; 06F1 31 FF FF
        ld   sp,hl              ; 06F4 F9
        ld   sp,ix              ; 06F5 DD F9
        ld   sp,iy              ; 06F7 FD F9
        ldd                     ; 06F9 ED A8
        LDD                     ; 06FB ED A8
        ldd  (bc),a             ; 06FD 02 0B
        ldd  (de),a             ; 06FF 12 1B
        ldd  (hl),255           ; 0701 36 FF 2B
        ldd  (hl),a             ; 0704 77 2B
        ldd  (hl),b             ; 0706 70 2B
        ldd  (hl),c             ; 0708 71 2B
        ldd  (hl),d             ; 070A 72 2B
        ldd  (hl),e             ; 070C 73 2B
        ldd  (hl),h             ; 070E 74 2B
        ldd  (hl),l             ; 0710 75 2B
        ldd  (ix),255           ; 0712 DD 36 00 FF DD 2B
        ldd  (ix),a             ; 0718 DD 77 00 DD 2B
        ldd  (ix),b             ; 071D DD 70 00 DD 2B
        ldd  (ix),c             ; 0722 DD 71 00 DD 2B
        ldd  (ix),d             ; 0727 DD 72 00 DD 2B
        ldd  (ix),e             ; 072C DD 73 00 DD 2B
        ldd  (ix),h             ; 0731 DD 74 00 DD 2B
        ldd  (ix),l             ; 0736 DD 75 00 DD 2B
        ldd  (ix+127),255       ; 073B DD 36 7F FF DD 2B
        ldd  (ix+127),a         ; 0741 DD 77 7F DD 2B
        ldd  (ix+127),b         ; 0746 DD 70 7F DD 2B
        ldd  (ix+127),c         ; 074B DD 71 7F DD 2B
        ldd  (ix+127),d         ; 0750 DD 72 7F DD 2B
        ldd  (ix+127),e         ; 0755 DD 73 7F DD 2B
        ldd  (ix+127),h         ; 075A DD 74 7F DD 2B
        ldd  (ix+127),l         ; 075F DD 75 7F DD 2B
        ldd  (ix+127),255       ; 0764 DD 36 7F FF DD 2B
        ldd  (ix+127),a         ; 076A DD 77 7F DD 2B
        ldd  (ix+127),b         ; 076F DD 70 7F DD 2B
        ldd  (ix+127),c         ; 0774 DD 71 7F DD 2B
        ldd  (ix+127),d         ; 0779 DD 72 7F DD 2B
        ldd  (ix+127),e         ; 077E DD 73 7F DD 2B
        ldd  (ix+127),h         ; 0783 DD 74 7F DD 2B
        ldd  (ix+127),l         ; 0788 DD 75 7F DD 2B
        ldd  (iy),255           ; 078D FD 36 00 FF FD 2B
        ldd  (iy),a             ; 0793 FD 77 00 FD 2B
        ldd  (iy),b             ; 0798 FD 70 00 FD 2B
        ldd  (iy),c             ; 079D FD 71 00 FD 2B
        ldd  (iy),d             ; 07A2 FD 72 00 FD 2B
        ldd  (iy),e             ; 07A7 FD 73 00 FD 2B
        ldd  (iy),h             ; 07AC FD 74 00 FD 2B
        ldd  (iy),l             ; 07B1 FD 75 00 FD 2B
        ldd  (iy+127),255       ; 07B6 FD 36 7F FF FD 2B
        ldd  (iy+127),a         ; 07BC FD 77 7F FD 2B
        ldd  (iy+127),b         ; 07C1 FD 70 7F FD 2B
        ldd  (iy+127),c         ; 07C6 FD 71 7F FD 2B
        ldd  (iy+127),d         ; 07CB FD 72 7F FD 2B
        ldd  (iy+127),e         ; 07D0 FD 73 7F FD 2B
        ldd  (iy+127),h         ; 07D5 FD 74 7F FD 2B
        ldd  (iy+127),l         ; 07DA FD 75 7F FD 2B
        ldd  (iy+127),255       ; 07DF FD 36 7F FF FD 2B
        ldd  (iy+127),a         ; 07E5 FD 77 7F FD 2B
        ldd  (iy+127),b         ; 07EA FD 70 7F FD 2B
        ldd  (iy+127),c         ; 07EF FD 71 7F FD 2B
        ldd  (iy+127),d         ; 07F4 FD 72 7F FD 2B
        ldd  (iy+127),e         ; 07F9 FD 73 7F FD 2B
        ldd  (iy+127),h         ; 07FE FD 74 7F FD 2B
        ldd  (iy+127),l         ; 0803 FD 75 7F FD 2B
        ldd  a,(bc)             ; 0808 0A 0B
        ldd  a,(de)             ; 080A 1A 1B
        ldd  a,(hl)             ; 080C 7E 2B
        ldd  a,(ix)             ; 080E DD 7E 00 DD 2B
        ldd  a,(ix+127)         ; 0813 DD 7E 7F DD 2B
        ldd  a,(ix+127)         ; 0818 DD 7E 7F DD 2B
        ldd  a,(iy)             ; 081D FD 7E 00 FD 2B
        ldd  a,(iy+127)         ; 0822 FD 7E 7F FD 2B
        ldd  a,(iy+127)         ; 0827 FD 7E 7F FD 2B
        ldd  b,(hl)             ; 082C 46 2B
        ldd  b,(ix)             ; 082E DD 46 00 DD 2B
        ldd  b,(ix+127)         ; 0833 DD 46 7F DD 2B
        ldd  b,(ix+127)         ; 0838 DD 46 7F DD 2B
        ldd  b,(iy)             ; 083D FD 46 00 FD 2B
        ldd  b,(iy+127)         ; 0842 FD 46 7F FD 2B
        ldd  b,(iy+127)         ; 0847 FD 46 7F FD 2B
        ldd  c,(hl)             ; 084C 4E 2B
        ldd  c,(ix)             ; 084E DD 4E 00 DD 2B
        ldd  c,(ix+127)         ; 0853 DD 4E 7F DD 2B
        ldd  c,(ix+127)         ; 0858 DD 4E 7F DD 2B
        ldd  c,(iy)             ; 085D FD 4E 00 FD 2B
        ldd  c,(iy+127)         ; 0862 FD 4E 7F FD 2B
        ldd  c,(iy+127)         ; 0867 FD 4E 7F FD 2B
        ldd  d,(hl)             ; 086C 56 2B
        ldd  d,(ix)             ; 086E DD 56 00 DD 2B
        ldd  d,(ix+127)         ; 0873 DD 56 7F DD 2B
        ldd  d,(ix+127)         ; 0878 DD 56 7F DD 2B
        ldd  d,(iy)             ; 087D FD 56 00 FD 2B
        ldd  d,(iy+127)         ; 0882 FD 56 7F FD 2B
        ldd  d,(iy+127)         ; 0887 FD 56 7F FD 2B
        ldd  e,(hl)             ; 088C 5E 2B
        ldd  e,(ix)             ; 088E DD 5E 00 DD 2B
        ldd  e,(ix+127)         ; 0893 DD 5E 7F DD 2B
        ldd  e,(ix+127)         ; 0898 DD 5E 7F DD 2B
        ldd  e,(iy)             ; 089D FD 5E 00 FD 2B
        ldd  e,(iy+127)         ; 08A2 FD 5E 7F FD 2B
        ldd  e,(iy+127)         ; 08A7 FD 5E 7F FD 2B
        ldd  h,(hl)             ; 08AC 66 2B
        ldd  h,(ix)             ; 08AE DD 66 00 DD 2B
        ldd  h,(ix+127)         ; 08B3 DD 66 7F DD 2B
        ldd  h,(ix+127)         ; 08B8 DD 66 7F DD 2B
        ldd  h,(iy)             ; 08BD FD 66 00 FD 2B
        ldd  h,(iy+127)         ; 08C2 FD 66 7F FD 2B
        ldd  h,(iy+127)         ; 08C7 FD 66 7F FD 2B
        ldd  l,(hl)             ; 08CC 6E 2B
        ldd  l,(ix)             ; 08CE DD 6E 00 DD 2B
        ldd  l,(ix+127)         ; 08D3 DD 6E 7F DD 2B
        ldd  l,(ix+127)         ; 08D8 DD 6E 7F DD 2B
        ldd  l,(iy)             ; 08DD FD 6E 00 FD 2B
        ldd  l,(iy+127)         ; 08E2 FD 6E 7F FD 2B
        ldd  l,(iy+127)         ; 08E7 FD 6E 7F FD 2B
        lddr                    ; 08EC ED B8
        LDDR                    ; 08EE ED B8
        ldi                     ; 08F0 ED A0
        LDI                     ; 08F2 ED A0
        ldi  (bc),a             ; 08F4 02 03
        ldi  (de),a             ; 08F6 12 13
        ldi  (hl),255           ; 08F8 36 FF 23
        ldi  (hl),a             ; 08FB 77 23
        ldi  (hl),b             ; 08FD 70 23
        ldi  (hl),bc            ; 08FF 71 23 70 23
        ldi  (hl),c             ; 0903 71 23
        ldi  (hl),d             ; 0905 72 23
        ldi  (hl),de            ; 0907 73 23 72 23
        ldi  (hl),e             ; 090B 73 23
        ldi  (hl),h             ; 090D 74 23
        ldi  (hl),l             ; 090F 75 23
        ldi  (ix),255           ; 0911 DD 36 00 FF DD 23
        ldi  (ix),a             ; 0917 DD 77 00 DD 23
        ldi  (ix),b             ; 091C DD 70 00 DD 23
        ldi  (ix),bc            ; 0921 DD 71 00 DD 23 DD 70 00 DD 23
        ldi  (ix),c             ; 092B DD 71 00 DD 23
        ldi  (ix),d             ; 0930 DD 72 00 DD 23
        ldi  (ix),de            ; 0935 DD 73 00 DD 23 DD 72 00 DD 23
        ldi  (ix),e             ; 093F DD 73 00 DD 23
        ldi  (ix),h             ; 0944 DD 74 00 DD 23
        ldi  (ix),hl            ; 0949 DD 75 00 DD 23 DD 74 00 DD 23
        ldi  (ix),l             ; 0953 DD 75 00 DD 23
        ldi  (ix+127),255       ; 0958 DD 36 7F FF DD 23
        ldi  (ix+127),a         ; 095E DD 77 7F DD 23
        ldi  (ix+127),b         ; 0963 DD 70 7F DD 23
        ldi  (ix+126),bc        ; 0968 DD 71 7E DD 23 DD 70 7E DD 23
        ldi  (ix+127),c         ; 0972 DD 71 7F DD 23
        ldi  (ix+127),d         ; 0977 DD 72 7F DD 23
        ldi  (ix+126),de        ; 097C DD 73 7E DD 23 DD 72 7E DD 23
        ldi  (ix+127),e         ; 0986 DD 73 7F DD 23
        ldi  (ix+127),h         ; 098B DD 74 7F DD 23
        ldi  (ix+126),hl        ; 0990 DD 75 7E DD 23 DD 74 7E DD 23
        ldi  (ix+127),l         ; 099A DD 75 7F DD 23
        ldi  (ix+127),255       ; 099F DD 36 7F FF DD 23
        ldi  (ix+127),a         ; 09A5 DD 77 7F DD 23
        ldi  (ix+127),b         ; 09AA DD 70 7F DD 23
        ldi  (ix+126),bc        ; 09AF DD 71 7E DD 23 DD 70 7E DD 23
        ldi  (ix+127),c         ; 09B9 DD 71 7F DD 23
        ldi  (ix+127),d         ; 09BE DD 72 7F DD 23
        ldi  (ix+126),de        ; 09C3 DD 73 7E DD 23 DD 72 7E DD 23
        ldi  (ix+127),e         ; 09CD DD 73 7F DD 23
        ldi  (ix+127),h         ; 09D2 DD 74 7F DD 23
        ldi  (ix+126),hl        ; 09D7 DD 75 7E DD 23 DD 74 7E DD 23
        ldi  (ix+127),l         ; 09E1 DD 75 7F DD 23
        ldi  (iy),255           ; 09E6 FD 36 00 FF FD 23
        ldi  (iy),a             ; 09EC FD 77 00 FD 23
        ldi  (iy),b             ; 09F1 FD 70 00 FD 23
        ldi  (iy),bc            ; 09F6 FD 71 00 FD 23 FD 70 00 FD 23
        ldi  (iy),c             ; 0A00 FD 71 00 FD 23
        ldi  (iy),d             ; 0A05 FD 72 00 FD 23
        ldi  (iy),de            ; 0A0A FD 73 00 FD 23 FD 72 00 FD 23
        ldi  (iy),e             ; 0A14 FD 73 00 FD 23
        ldi  (iy),h             ; 0A19 FD 74 00 FD 23
        ldi  (iy),hl            ; 0A1E FD 75 00 FD 23 FD 74 00 FD 23
        ldi  (iy),l             ; 0A28 FD 75 00 FD 23
        ldi  (iy+127),255       ; 0A2D FD 36 7F FF FD 23
        ldi  (iy+127),a         ; 0A33 FD 77 7F FD 23
        ldi  (iy+127),b         ; 0A38 FD 70 7F FD 23
        ldi  (iy+126),bc        ; 0A3D FD 71 7E FD 23 FD 70 7E FD 23
        ldi  (iy+127),c         ; 0A47 FD 71 7F FD 23
        ldi  (iy+127),d         ; 0A4C FD 72 7F FD 23
        ldi  (iy+126),de        ; 0A51 FD 73 7E FD 23 FD 72 7E FD 23
        ldi  (iy+127),e         ; 0A5B FD 73 7F FD 23
        ldi  (iy+127),h         ; 0A60 FD 74 7F FD 23
        ldi  (iy+126),hl        ; 0A65 FD 75 7E FD 23 FD 74 7E FD 23
        ldi  (iy+127),l         ; 0A6F FD 75 7F FD 23
        ldi  (iy+127),255       ; 0A74 FD 36 7F FF FD 23
        ldi  (iy+127),a         ; 0A7A FD 77 7F FD 23
        ldi  (iy+127),b         ; 0A7F FD 70 7F FD 23
        ldi  (iy+126),bc        ; 0A84 FD 71 7E FD 23 FD 70 7E FD 23
        ldi  (iy+127),c         ; 0A8E FD 71 7F FD 23
        ldi  (iy+127),d         ; 0A93 FD 72 7F FD 23
        ldi  (iy+126),de        ; 0A98 FD 73 7E FD 23 FD 72 7E FD 23
        ldi  (iy+127),e         ; 0AA2 FD 73 7F FD 23
        ldi  (iy+127),h         ; 0AA7 FD 74 7F FD 23
        ldi  (iy+126),hl        ; 0AAC FD 75 7E FD 23 FD 74 7E FD 23
        ldi  (iy+127),l         ; 0AB6 FD 75 7F FD 23
        ldi  a,(bc)             ; 0ABB 0A 03
        ldi  a,(de)             ; 0ABD 1A 13
        ldi  a,(hl)             ; 0ABF 7E 23
        ldi  a,(ix)             ; 0AC1 DD 7E 00 DD 23
        ldi  a,(ix+127)         ; 0AC6 DD 7E 7F DD 23
        ldi  a,(ix+127)         ; 0ACB DD 7E 7F DD 23
        ldi  a,(iy)             ; 0AD0 FD 7E 00 FD 23
        ldi  a,(iy+127)         ; 0AD5 FD 7E 7F FD 23
        ldi  a,(iy+127)         ; 0ADA FD 7E 7F FD 23
        ldi  b,(hl)             ; 0ADF 46 23
        ldi  b,(ix)             ; 0AE1 DD 46 00 DD 23
        ldi  b,(ix+127)         ; 0AE6 DD 46 7F DD 23
        ldi  b,(ix+127)         ; 0AEB DD 46 7F DD 23
        ldi  b,(iy)             ; 0AF0 FD 46 00 FD 23
        ldi  b,(iy+127)         ; 0AF5 FD 46 7F FD 23
        ldi  b,(iy+127)         ; 0AFA FD 46 7F FD 23
        ldi  bc,(hl)            ; 0AFF 4E 23 46 23
        ldi  bc,(ix)            ; 0B03 DD 4E 00 DD 23 DD 46 00 DD 23
        ldi  bc,(ix+126)        ; 0B0D DD 4E 7E DD 23 DD 46 7E DD 23
        ldi  bc,(ix+126)        ; 0B17 DD 4E 7E DD 23 DD 46 7E DD 23
        ldi  bc,(iy)            ; 0B21 FD 4E 00 FD 23 FD 46 00 FD 23
        ldi  bc,(iy+126)        ; 0B2B FD 4E 7E FD 23 FD 46 7E FD 23
        ldi  bc,(iy+126)        ; 0B35 FD 4E 7E FD 23 FD 46 7E FD 23
        ldi  c,(hl)             ; 0B3F 4E 23
        ldi  c,(ix)             ; 0B41 DD 4E 00 DD 23
        ldi  c,(ix+127)         ; 0B46 DD 4E 7F DD 23
        ldi  c,(ix+127)         ; 0B4B DD 4E 7F DD 23
        ldi  c,(iy)             ; 0B50 FD 4E 00 FD 23
        ldi  c,(iy+127)         ; 0B55 FD 4E 7F FD 23
        ldi  c,(iy+127)         ; 0B5A FD 4E 7F FD 23
        ldi  d,(hl)             ; 0B5F 56 23
        ldi  d,(ix)             ; 0B61 DD 56 00 DD 23
        ldi  d,(ix+127)         ; 0B66 DD 56 7F DD 23
        ldi  d,(ix+127)         ; 0B6B DD 56 7F DD 23
        ldi  d,(iy)             ; 0B70 FD 56 00 FD 23
        ldi  d,(iy+127)         ; 0B75 FD 56 7F FD 23
        ldi  d,(iy+127)         ; 0B7A FD 56 7F FD 23
        ldi  de,(hl)            ; 0B7F 5E 23 56 23
        ldi  de,(ix)            ; 0B83 DD 5E 00 DD 23 DD 56 00 DD 23
        ldi  de,(ix+126)        ; 0B8D DD 5E 7E DD 23 DD 56 7E DD 23
        ldi  de,(ix+126)        ; 0B97 DD 5E 7E DD 23 DD 56 7E DD 23
        ldi  de,(iy)            ; 0BA1 FD 5E 00 FD 23 FD 56 00 FD 23
        ldi  de,(iy+126)        ; 0BAB FD 5E 7E FD 23 FD 56 7E FD 23
        ldi  de,(iy+126)        ; 0BB5 FD 5E 7E FD 23 FD 56 7E FD 23
        ldi  e,(hl)             ; 0BBF 5E 23
        ldi  e,(ix)             ; 0BC1 DD 5E 00 DD 23
        ldi  e,(ix+127)         ; 0BC6 DD 5E 7F DD 23
        ldi  e,(ix+127)         ; 0BCB DD 5E 7F DD 23
        ldi  e,(iy)             ; 0BD0 FD 5E 00 FD 23
        ldi  e,(iy+127)         ; 0BD5 FD 5E 7F FD 23
        ldi  e,(iy+127)         ; 0BDA FD 5E 7F FD 23
        ldi  h,(hl)             ; 0BDF 66 23
        ldi  h,(ix)             ; 0BE1 DD 66 00 DD 23
        ldi  h,(ix+127)         ; 0BE6 DD 66 7F DD 23
        ldi  h,(ix+127)         ; 0BEB DD 66 7F DD 23
        ldi  h,(iy)             ; 0BF0 FD 66 00 FD 23
        ldi  h,(iy+127)         ; 0BF5 FD 66 7F FD 23
        ldi  h,(iy+127)         ; 0BFA FD 66 7F FD 23
        ldi  hl,(ix)            ; 0BFF DD 6E 00 DD 23 DD 66 00 DD 23
        ldi  hl,(ix+126)        ; 0C09 DD 6E 7E DD 23 DD 66 7E DD 23
        ldi  hl,(ix+126)        ; 0C13 DD 6E 7E DD 23 DD 66 7E DD 23
        ldi  hl,(iy)            ; 0C1D FD 6E 00 FD 23 FD 66 00 FD 23
        ldi  hl,(iy+126)        ; 0C27 FD 6E 7E FD 23 FD 66 7E FD 23
        ldi  hl,(iy+126)        ; 0C31 FD 6E 7E FD 23 FD 66 7E FD 23
        ldi  l,(hl)             ; 0C3B 6E 23
        ldi  l,(ix)             ; 0C3D DD 6E 00 DD 23
        ldi  l,(ix+127)         ; 0C42 DD 6E 7F DD 23
        ldi  l,(ix+127)         ; 0C47 DD 6E 7F DD 23
        ldi  l,(iy)             ; 0C4C FD 6E 00 FD 23
        ldi  l,(iy+127)         ; 0C51 FD 6E 7F FD 23
        ldi  l,(iy+127)         ; 0C56 FD 6E 7F FD 23
        ldir                    ; 0C5B ED B0
        LDIR                    ; 0C5D ED B0
        neg                     ; 0C5F ED 44
        NEG                     ; 0C61 ED 44
        nop                     ; 0C63 00
        NOP                     ; 0C64 00
        or   (hl)               ; 0C65 B6
        OR   (HL)               ; 0C66 B6
        or   (ix)               ; 0C67 DD B6 00
        or   (ix+127)           ; 0C6A DD B6 7F
        or   (ix+127)           ; 0C6D DD B6 7F
        or   (iy)               ; 0C70 FD B6 00
        or   (iy+127)           ; 0C73 FD B6 7F
        or   (iy+127)           ; 0C76 FD B6 7F
        or   255                ; 0C79 F6 FF
        or   a                  ; 0C7B B7
        or   b                  ; 0C7C B0
        or   c                  ; 0C7D B1
        or   d                  ; 0C7E B2
        or   e                  ; 0C7F B3
        or   h                  ; 0C80 B4
        or   ixh                ; 0C81 DD B4
        or   ixl                ; 0C83 DD B5
        or   iyh                ; 0C85 FD B4
        or   iyl                ; 0C87 FD B5
        or   l                  ; 0C89 B5
        otdr                    ; 0C8A ED BB
        OTDR                    ; 0C8C ED BB
        otir                    ; 0C8E ED B3
        OTIR                    ; 0C90 ED B3
        out  (255),a            ; 0C92 D3 FF
        OUT  (255),A            ; 0C94 D3 FF
        out  (c),0              ; 0C96 ED 71
        out  (c),a              ; 0C98 ED 79
        out  (c),b              ; 0C9A ED 41
        out  (c),c              ; 0C9C ED 49
        out  (c),d              ; 0C9E ED 51
        out  (c),e              ; 0CA0 ED 59
        out  (c),h              ; 0CA2 ED 61
        out  (c),l              ; 0CA4 ED 69
        outd                    ; 0CA6 ED AB
        OUTD                    ; 0CA8 ED AB
        outi                    ; 0CAA ED A3
        OUTI                    ; 0CAC ED A3
        pop  af                 ; 0CAE F1
        POP  AF                 ; 0CAF F1
        pop  bc                 ; 0CB0 C1
        pop  de                 ; 0CB1 D1
        pop  hl                 ; 0CB2 E1
        pop  ix                 ; 0CB3 DD E1
        pop  iy                 ; 0CB5 FD E1
        push af                 ; 0CB7 F5
        PUSH AF                 ; 0CB8 F5
        push bc                 ; 0CB9 C5
        push de                 ; 0CBA D5
        push hl                 ; 0CBB E5
        push ix                 ; 0CBC DD E5
        push iy                 ; 0CBE FD E5
        res  0,(hl)             ; 0CC0 CB 86
        RES  0,(HL)             ; 0CC2 CB 86
        res  0,(ix)             ; 0CC4 DD CB 00 86
        res  0,(ix),a           ; 0CC8 DD CB 00 87
        res  0,(ix),b           ; 0CCC DD CB 00 80
        res  0,(ix),c           ; 0CD0 DD CB 00 81
        res  0,(ix),d           ; 0CD4 DD CB 00 82
        res  0,(ix),e           ; 0CD8 DD CB 00 83
        res  0,(ix),h           ; 0CDC DD CB 00 84
        res  0,(ix),l           ; 0CE0 DD CB 00 85
        res  0,(ix+127)         ; 0CE4 DD CB 7F 86
        res  0,(ix+127),a       ; 0CE8 DD CB 7F 87
        res  0,(ix+127),b       ; 0CEC DD CB 7F 80
        res  0,(ix+127),c       ; 0CF0 DD CB 7F 81
        res  0,(ix+127),d       ; 0CF4 DD CB 7F 82
        res  0,(ix+127),e       ; 0CF8 DD CB 7F 83
        res  0,(ix+127),h       ; 0CFC DD CB 7F 84
        res  0,(ix+127),l       ; 0D00 DD CB 7F 85
        res  0,(ix+127)         ; 0D04 DD CB 7F 86
        res  0,(ix+127),a       ; 0D08 DD CB 7F 87
        res  0,(ix+127),b       ; 0D0C DD CB 7F 80
        res  0,(ix+127),c       ; 0D10 DD CB 7F 81
        res  0,(ix+127),d       ; 0D14 DD CB 7F 82
        res  0,(ix+127),e       ; 0D18 DD CB 7F 83
        res  0,(ix+127),h       ; 0D1C DD CB 7F 84
        res  0,(ix+127),l       ; 0D20 DD CB 7F 85
        res  0,(iy)             ; 0D24 FD CB 00 86
        res  0,(iy),a           ; 0D28 FD CB 00 87
        res  0,(iy),b           ; 0D2C FD CB 00 80
        res  0,(iy),c           ; 0D30 FD CB 00 81
        res  0,(iy),d           ; 0D34 FD CB 00 82
        res  0,(iy),e           ; 0D38 FD CB 00 83
        res  0,(iy),h           ; 0D3C FD CB 00 84
        res  0,(iy),l           ; 0D40 FD CB 00 85
        res  0,(iy+127)         ; 0D44 FD CB 7F 86
        res  0,(iy+127),a       ; 0D48 FD CB 7F 87
        res  0,(iy+127),b       ; 0D4C FD CB 7F 80
        res  0,(iy+127),c       ; 0D50 FD CB 7F 81
        res  0,(iy+127),d       ; 0D54 FD CB 7F 82
        res  0,(iy+127),e       ; 0D58 FD CB 7F 83
        res  0,(iy+127),h       ; 0D5C FD CB 7F 84
        res  0,(iy+127),l       ; 0D60 FD CB 7F 85
        res  0,(iy+127)         ; 0D64 FD CB 7F 86
        res  0,(iy+127),a       ; 0D68 FD CB 7F 87
        res  0,(iy+127),b       ; 0D6C FD CB 7F 80
        res  0,(iy+127),c       ; 0D70 FD CB 7F 81
        res  0,(iy+127),d       ; 0D74 FD CB 7F 82
        res  0,(iy+127),e       ; 0D78 FD CB 7F 83
        res  0,(iy+127),h       ; 0D7C FD CB 7F 84
        res  0,(iy+127),l       ; 0D80 FD CB 7F 85
        res  0,a                ; 0D84 CB 87
        res  0,b                ; 0D86 CB 80
        res  0,c                ; 0D88 CB 81
        res  0,d                ; 0D8A CB 82
        res  0,e                ; 0D8C CB 83
        res  0,h                ; 0D8E CB 84
        res  0,l                ; 0D90 CB 85
        res  1,(hl)             ; 0D92 CB 8E
        res  1,(ix)             ; 0D94 DD CB 00 8E
        res  1,(ix),a           ; 0D98 DD CB 00 8F
        res  1,(ix),b           ; 0D9C DD CB 00 88
        res  1,(ix),c           ; 0DA0 DD CB 00 89
        res  1,(ix),d           ; 0DA4 DD CB 00 8A
        res  1,(ix),e           ; 0DA8 DD CB 00 8B
        res  1,(ix),h           ; 0DAC DD CB 00 8C
        res  1,(ix),l           ; 0DB0 DD CB 00 8D
        res  1,(ix+127)         ; 0DB4 DD CB 7F 8E
        res  1,(ix+127),a       ; 0DB8 DD CB 7F 8F
        res  1,(ix+127),b       ; 0DBC DD CB 7F 88
        res  1,(ix+127),c       ; 0DC0 DD CB 7F 89
        res  1,(ix+127),d       ; 0DC4 DD CB 7F 8A
        res  1,(ix+127),e       ; 0DC8 DD CB 7F 8B
        res  1,(ix+127),h       ; 0DCC DD CB 7F 8C
        res  1,(ix+127),l       ; 0DD0 DD CB 7F 8D
        res  1,(ix+127)         ; 0DD4 DD CB 7F 8E
        res  1,(ix+127),a       ; 0DD8 DD CB 7F 8F
        res  1,(ix+127),b       ; 0DDC DD CB 7F 88
        res  1,(ix+127),c       ; 0DE0 DD CB 7F 89
        res  1,(ix+127),d       ; 0DE4 DD CB 7F 8A
        res  1,(ix+127),e       ; 0DE8 DD CB 7F 8B
        res  1,(ix+127),h       ; 0DEC DD CB 7F 8C
        res  1,(ix+127),l       ; 0DF0 DD CB 7F 8D
        res  1,(iy)             ; 0DF4 FD CB 00 8E
        res  1,(iy),a           ; 0DF8 FD CB 00 8F
        res  1,(iy),b           ; 0DFC FD CB 00 88
        res  1,(iy),c           ; 0E00 FD CB 00 89
        res  1,(iy),d           ; 0E04 FD CB 00 8A
        res  1,(iy),e           ; 0E08 FD CB 00 8B
        res  1,(iy),h           ; 0E0C FD CB 00 8C
        res  1,(iy),l           ; 0E10 FD CB 00 8D
        res  1,(iy+127)         ; 0E14 FD CB 7F 8E
        res  1,(iy+127),a       ; 0E18 FD CB 7F 8F
        res  1,(iy+127),b       ; 0E1C FD CB 7F 88
        res  1,(iy+127),c       ; 0E20 FD CB 7F 89
        res  1,(iy+127),d       ; 0E24 FD CB 7F 8A
        res  1,(iy+127),e       ; 0E28 FD CB 7F 8B
        res  1,(iy+127),h       ; 0E2C FD CB 7F 8C
        res  1,(iy+127),l       ; 0E30 FD CB 7F 8D
        res  1,(iy+127)         ; 0E34 FD CB 7F 8E
        res  1,(iy+127),a       ; 0E38 FD CB 7F 8F
        res  1,(iy+127),b       ; 0E3C FD CB 7F 88
        res  1,(iy+127),c       ; 0E40 FD CB 7F 89
        res  1,(iy+127),d       ; 0E44 FD CB 7F 8A
        res  1,(iy+127),e       ; 0E48 FD CB 7F 8B
        res  1,(iy+127),h       ; 0E4C FD CB 7F 8C
        res  1,(iy+127),l       ; 0E50 FD CB 7F 8D
        res  1,a                ; 0E54 CB 8F
        res  1,b                ; 0E56 CB 88
        res  1,c                ; 0E58 CB 89
        res  1,d                ; 0E5A CB 8A
        res  1,e                ; 0E5C CB 8B
        res  1,h                ; 0E5E CB 8C
        res  1,l                ; 0E60 CB 8D
        res  2,(hl)             ; 0E62 CB 96
        res  2,(ix)             ; 0E64 DD CB 00 96
        res  2,(ix),a           ; 0E68 DD CB 00 97
        res  2,(ix),b           ; 0E6C DD CB 00 90
        res  2,(ix),c           ; 0E70 DD CB 00 91
        res  2,(ix),d           ; 0E74 DD CB 00 92
        res  2,(ix),e           ; 0E78 DD CB 00 93
        res  2,(ix),h           ; 0E7C DD CB 00 94
        res  2,(ix),l           ; 0E80 DD CB 00 95
        res  2,(ix+127)         ; 0E84 DD CB 7F 96
        res  2,(ix+127),a       ; 0E88 DD CB 7F 97
        res  2,(ix+127),b       ; 0E8C DD CB 7F 90
        res  2,(ix+127),c       ; 0E90 DD CB 7F 91
        res  2,(ix+127),d       ; 0E94 DD CB 7F 92
        res  2,(ix+127),e       ; 0E98 DD CB 7F 93
        res  2,(ix+127),h       ; 0E9C DD CB 7F 94
        res  2,(ix+127),l       ; 0EA0 DD CB 7F 95
        res  2,(ix+127)         ; 0EA4 DD CB 7F 96
        res  2,(ix+127),a       ; 0EA8 DD CB 7F 97
        res  2,(ix+127),b       ; 0EAC DD CB 7F 90
        res  2,(ix+127),c       ; 0EB0 DD CB 7F 91
        res  2,(ix+127),d       ; 0EB4 DD CB 7F 92
        res  2,(ix+127),e       ; 0EB8 DD CB 7F 93
        res  2,(ix+127),h       ; 0EBC DD CB 7F 94
        res  2,(ix+127),l       ; 0EC0 DD CB 7F 95
        res  2,(iy)             ; 0EC4 FD CB 00 96
        res  2,(iy),a           ; 0EC8 FD CB 00 97
        res  2,(iy),b           ; 0ECC FD CB 00 90
        res  2,(iy),c           ; 0ED0 FD CB 00 91
        res  2,(iy),d           ; 0ED4 FD CB 00 92
        res  2,(iy),e           ; 0ED8 FD CB 00 93
        res  2,(iy),h           ; 0EDC FD CB 00 94
        res  2,(iy),l           ; 0EE0 FD CB 00 95
        res  2,(iy+127)         ; 0EE4 FD CB 7F 96
        res  2,(iy+127),a       ; 0EE8 FD CB 7F 97
        res  2,(iy+127),b       ; 0EEC FD CB 7F 90
        res  2,(iy+127),c       ; 0EF0 FD CB 7F 91
        res  2,(iy+127),d       ; 0EF4 FD CB 7F 92
        res  2,(iy+127),e       ; 0EF8 FD CB 7F 93
        res  2,(iy+127),h       ; 0EFC FD CB 7F 94
        res  2,(iy+127),l       ; 0F00 FD CB 7F 95
        res  2,(iy+127)         ; 0F04 FD CB 7F 96
        res  2,(iy+127),a       ; 0F08 FD CB 7F 97
        res  2,(iy+127),b       ; 0F0C FD CB 7F 90
        res  2,(iy+127),c       ; 0F10 FD CB 7F 91
        res  2,(iy+127),d       ; 0F14 FD CB 7F 92
        res  2,(iy+127),e       ; 0F18 FD CB 7F 93
        res  2,(iy+127),h       ; 0F1C FD CB 7F 94
        res  2,(iy+127),l       ; 0F20 FD CB 7F 95
        res  2,a                ; 0F24 CB 97
        res  2,b                ; 0F26 CB 90
        res  2,c                ; 0F28 CB 91
        res  2,d                ; 0F2A CB 92
        res  2,e                ; 0F2C CB 93
        res  2,h                ; 0F2E CB 94
        res  2,l                ; 0F30 CB 95
        res  3,(hl)             ; 0F32 CB 9E
        res  3,(ix)             ; 0F34 DD CB 00 9E
        res  3,(ix),a           ; 0F38 DD CB 00 9F
        res  3,(ix),b           ; 0F3C DD CB 00 98
        res  3,(ix),c           ; 0F40 DD CB 00 99
        res  3,(ix),d           ; 0F44 DD CB 00 9A
        res  3,(ix),e           ; 0F48 DD CB 00 9B
        res  3,(ix),h           ; 0F4C DD CB 00 9C
        res  3,(ix),l           ; 0F50 DD CB 00 9D
        res  3,(ix+127)         ; 0F54 DD CB 7F 9E
        res  3,(ix+127),a       ; 0F58 DD CB 7F 9F
        res  3,(ix+127),b       ; 0F5C DD CB 7F 98
        res  3,(ix+127),c       ; 0F60 DD CB 7F 99
        res  3,(ix+127),d       ; 0F64 DD CB 7F 9A
        res  3,(ix+127),e       ; 0F68 DD CB 7F 9B
        res  3,(ix+127),h       ; 0F6C DD CB 7F 9C
        res  3,(ix+127),l       ; 0F70 DD CB 7F 9D
        res  3,(ix+127)         ; 0F74 DD CB 7F 9E
        res  3,(ix+127),a       ; 0F78 DD CB 7F 9F
        res  3,(ix+127),b       ; 0F7C DD CB 7F 98
        res  3,(ix+127),c       ; 0F80 DD CB 7F 99
        res  3,(ix+127),d       ; 0F84 DD CB 7F 9A
        res  3,(ix+127),e       ; 0F88 DD CB 7F 9B
        res  3,(ix+127),h       ; 0F8C DD CB 7F 9C
        res  3,(ix+127),l       ; 0F90 DD CB 7F 9D
        res  3,(iy)             ; 0F94 FD CB 00 9E
        res  3,(iy),a           ; 0F98 FD CB 00 9F
        res  3,(iy),b           ; 0F9C FD CB 00 98
        res  3,(iy),c           ; 0FA0 FD CB 00 99
        res  3,(iy),d           ; 0FA4 FD CB 00 9A
        res  3,(iy),e           ; 0FA8 FD CB 00 9B
        res  3,(iy),h           ; 0FAC FD CB 00 9C
        res  3,(iy),l           ; 0FB0 FD CB 00 9D
        res  3,(iy+127)         ; 0FB4 FD CB 7F 9E
        res  3,(iy+127),a       ; 0FB8 FD CB 7F 9F
        res  3,(iy+127),b       ; 0FBC FD CB 7F 98
        res  3,(iy+127),c       ; 0FC0 FD CB 7F 99
        res  3,(iy+127),d       ; 0FC4 FD CB 7F 9A
        res  3,(iy+127),e       ; 0FC8 FD CB 7F 9B
        res  3,(iy+127),h       ; 0FCC FD CB 7F 9C
        res  3,(iy+127),l       ; 0FD0 FD CB 7F 9D
        res  3,(iy+127)         ; 0FD4 FD CB 7F 9E
        res  3,(iy+127),a       ; 0FD8 FD CB 7F 9F
        res  3,(iy+127),b       ; 0FDC FD CB 7F 98
        res  3,(iy+127),c       ; 0FE0 FD CB 7F 99
        res  3,(iy+127),d       ; 0FE4 FD CB 7F 9A
        res  3,(iy+127),e       ; 0FE8 FD CB 7F 9B
        res  3,(iy+127),h       ; 0FEC FD CB 7F 9C
        res  3,(iy+127),l       ; 0FF0 FD CB 7F 9D
        res  3,a                ; 0FF4 CB 9F
        res  3,b                ; 0FF6 CB 98
        res  3,c                ; 0FF8 CB 99
        res  3,d                ; 0FFA CB 9A
        res  3,e                ; 0FFC CB 9B
        res  3,h                ; 0FFE CB 9C
        res  3,l                ; 1000 CB 9D
        res  4,(hl)             ; 1002 CB A6
        res  4,(ix)             ; 1004 DD CB 00 A6
        res  4,(ix),a           ; 1008 DD CB 00 A7
        res  4,(ix),b           ; 100C DD CB 00 A0
        res  4,(ix),c           ; 1010 DD CB 00 A1
        res  4,(ix),d           ; 1014 DD CB 00 A2
        res  4,(ix),e           ; 1018 DD CB 00 A3
        res  4,(ix),h           ; 101C DD CB 00 A4
        res  4,(ix),l           ; 1020 DD CB 00 A5
        res  4,(ix+127)         ; 1024 DD CB 7F A6
        res  4,(ix+127),a       ; 1028 DD CB 7F A7
        res  4,(ix+127),b       ; 102C DD CB 7F A0
        res  4,(ix+127),c       ; 1030 DD CB 7F A1
        res  4,(ix+127),d       ; 1034 DD CB 7F A2
        res  4,(ix+127),e       ; 1038 DD CB 7F A3
        res  4,(ix+127),h       ; 103C DD CB 7F A4
        res  4,(ix+127),l       ; 1040 DD CB 7F A5
        res  4,(ix+127)         ; 1044 DD CB 7F A6
        res  4,(ix+127),a       ; 1048 DD CB 7F A7
        res  4,(ix+127),b       ; 104C DD CB 7F A0
        res  4,(ix+127),c       ; 1050 DD CB 7F A1
        res  4,(ix+127),d       ; 1054 DD CB 7F A2
        res  4,(ix+127),e       ; 1058 DD CB 7F A3
        res  4,(ix+127),h       ; 105C DD CB 7F A4
        res  4,(ix+127),l       ; 1060 DD CB 7F A5
        res  4,(iy)             ; 1064 FD CB 00 A6
        res  4,(iy),a           ; 1068 FD CB 00 A7
        res  4,(iy),b           ; 106C FD CB 00 A0
        res  4,(iy),c           ; 1070 FD CB 00 A1
        res  4,(iy),d           ; 1074 FD CB 00 A2
        res  4,(iy),e           ; 1078 FD CB 00 A3
        res  4,(iy),h           ; 107C FD CB 00 A4
        res  4,(iy),l           ; 1080 FD CB 00 A5
        res  4,(iy+127)         ; 1084 FD CB 7F A6
        res  4,(iy+127),a       ; 1088 FD CB 7F A7
        res  4,(iy+127),b       ; 108C FD CB 7F A0
        res  4,(iy+127),c       ; 1090 FD CB 7F A1
        res  4,(iy+127),d       ; 1094 FD CB 7F A2
        res  4,(iy+127),e       ; 1098 FD CB 7F A3
        res  4,(iy+127),h       ; 109C FD CB 7F A4
        res  4,(iy+127),l       ; 10A0 FD CB 7F A5
        res  4,(iy+127)         ; 10A4 FD CB 7F A6
        res  4,(iy+127),a       ; 10A8 FD CB 7F A7
        res  4,(iy+127),b       ; 10AC FD CB 7F A0
        res  4,(iy+127),c       ; 10B0 FD CB 7F A1
        res  4,(iy+127),d       ; 10B4 FD CB 7F A2
        res  4,(iy+127),e       ; 10B8 FD CB 7F A3
        res  4,(iy+127),h       ; 10BC FD CB 7F A4
        res  4,(iy+127),l       ; 10C0 FD CB 7F A5
        res  4,a                ; 10C4 CB A7
        res  4,b                ; 10C6 CB A0
        res  4,c                ; 10C8 CB A1
        res  4,d                ; 10CA CB A2
        res  4,e                ; 10CC CB A3
        res  4,h                ; 10CE CB A4
        res  4,l                ; 10D0 CB A5
        res  5,(hl)             ; 10D2 CB AE
        res  5,(ix)             ; 10D4 DD CB 00 AE
        res  5,(ix),a           ; 10D8 DD CB 00 AF
        res  5,(ix),b           ; 10DC DD CB 00 A8
        res  5,(ix),c           ; 10E0 DD CB 00 A9
        res  5,(ix),d           ; 10E4 DD CB 00 AA
        res  5,(ix),e           ; 10E8 DD CB 00 AB
        res  5,(ix),h           ; 10EC DD CB 00 AC
        res  5,(ix),l           ; 10F0 DD CB 00 AD
        res  5,(ix+127)         ; 10F4 DD CB 7F AE
        res  5,(ix+127),a       ; 10F8 DD CB 7F AF
        res  5,(ix+127),b       ; 10FC DD CB 7F A8
        res  5,(ix+127),c       ; 1100 DD CB 7F A9
        res  5,(ix+127),d       ; 1104 DD CB 7F AA
        res  5,(ix+127),e       ; 1108 DD CB 7F AB
        res  5,(ix+127),h       ; 110C DD CB 7F AC
        res  5,(ix+127),l       ; 1110 DD CB 7F AD
        res  5,(ix+127)         ; 1114 DD CB 7F AE
        res  5,(ix+127),a       ; 1118 DD CB 7F AF
        res  5,(ix+127),b       ; 111C DD CB 7F A8
        res  5,(ix+127),c       ; 1120 DD CB 7F A9
        res  5,(ix+127),d       ; 1124 DD CB 7F AA
        res  5,(ix+127),e       ; 1128 DD CB 7F AB
        res  5,(ix+127),h       ; 112C DD CB 7F AC
        res  5,(ix+127),l       ; 1130 DD CB 7F AD
        res  5,(iy)             ; 1134 FD CB 00 AE
        res  5,(iy),a           ; 1138 FD CB 00 AF
        res  5,(iy),b           ; 113C FD CB 00 A8
        res  5,(iy),c           ; 1140 FD CB 00 A9
        res  5,(iy),d           ; 1144 FD CB 00 AA
        res  5,(iy),e           ; 1148 FD CB 00 AB
        res  5,(iy),h           ; 114C FD CB 00 AC
        res  5,(iy),l           ; 1150 FD CB 00 AD
        res  5,(iy+127)         ; 1154 FD CB 7F AE
        res  5,(iy+127),a       ; 1158 FD CB 7F AF
        res  5,(iy+127),b       ; 115C FD CB 7F A8
        res  5,(iy+127),c       ; 1160 FD CB 7F A9
        res  5,(iy+127),d       ; 1164 FD CB 7F AA
        res  5,(iy+127),e       ; 1168 FD CB 7F AB
        res  5,(iy+127),h       ; 116C FD CB 7F AC
        res  5,(iy+127),l       ; 1170 FD CB 7F AD
        res  5,(iy+127)         ; 1174 FD CB 7F AE
        res  5,(iy+127),a       ; 1178 FD CB 7F AF
        res  5,(iy+127),b       ; 117C FD CB 7F A8
        res  5,(iy+127),c       ; 1180 FD CB 7F A9
        res  5,(iy+127),d       ; 1184 FD CB 7F AA
        res  5,(iy+127),e       ; 1188 FD CB 7F AB
        res  5,(iy+127),h       ; 118C FD CB 7F AC
        res  5,(iy+127),l       ; 1190 FD CB 7F AD
        res  5,a                ; 1194 CB AF
        res  5,b                ; 1196 CB A8
        res  5,c                ; 1198 CB A9
        res  5,d                ; 119A CB AA
        res  5,e                ; 119C CB AB
        res  5,h                ; 119E CB AC
        res  5,l                ; 11A0 CB AD
        res  6,(hl)             ; 11A2 CB B6
        res  6,(ix)             ; 11A4 DD CB 00 B6
        res  6,(ix),a           ; 11A8 DD CB 00 B7
        res  6,(ix),b           ; 11AC DD CB 00 B0
        res  6,(ix),c           ; 11B0 DD CB 00 B1
        res  6,(ix),d           ; 11B4 DD CB 00 B2
        res  6,(ix),e           ; 11B8 DD CB 00 B3
        res  6,(ix),h           ; 11BC DD CB 00 B4
        res  6,(ix),l           ; 11C0 DD CB 00 B5
        res  6,(ix+127)         ; 11C4 DD CB 7F B6
        res  6,(ix+127),a       ; 11C8 DD CB 7F B7
        res  6,(ix+127),b       ; 11CC DD CB 7F B0
        res  6,(ix+127),c       ; 11D0 DD CB 7F B1
        res  6,(ix+127),d       ; 11D4 DD CB 7F B2
        res  6,(ix+127),e       ; 11D8 DD CB 7F B3
        res  6,(ix+127),h       ; 11DC DD CB 7F B4
        res  6,(ix+127),l       ; 11E0 DD CB 7F B5
        res  6,(ix+127)         ; 11E4 DD CB 7F B6
        res  6,(ix+127),a       ; 11E8 DD CB 7F B7
        res  6,(ix+127),b       ; 11EC DD CB 7F B0
        res  6,(ix+127),c       ; 11F0 DD CB 7F B1
        res  6,(ix+127),d       ; 11F4 DD CB 7F B2
        res  6,(ix+127),e       ; 11F8 DD CB 7F B3
        res  6,(ix+127),h       ; 11FC DD CB 7F B4
        res  6,(ix+127),l       ; 1200 DD CB 7F B5
        res  6,(iy)             ; 1204 FD CB 00 B6
        res  6,(iy),a           ; 1208 FD CB 00 B7
        res  6,(iy),b           ; 120C FD CB 00 B0
        res  6,(iy),c           ; 1210 FD CB 00 B1
        res  6,(iy),d           ; 1214 FD CB 00 B2
        res  6,(iy),e           ; 1218 FD CB 00 B3
        res  6,(iy),h           ; 121C FD CB 00 B4
        res  6,(iy),l           ; 1220 FD CB 00 B5
        res  6,(iy+127)         ; 1224 FD CB 7F B6
        res  6,(iy+127),a       ; 1228 FD CB 7F B7
        res  6,(iy+127),b       ; 122C FD CB 7F B0
        res  6,(iy+127),c       ; 1230 FD CB 7F B1
        res  6,(iy+127),d       ; 1234 FD CB 7F B2
        res  6,(iy+127),e       ; 1238 FD CB 7F B3
        res  6,(iy+127),h       ; 123C FD CB 7F B4
        res  6,(iy+127),l       ; 1240 FD CB 7F B5
        res  6,(iy+127)         ; 1244 FD CB 7F B6
        res  6,(iy+127),a       ; 1248 FD CB 7F B7
        res  6,(iy+127),b       ; 124C FD CB 7F B0
        res  6,(iy+127),c       ; 1250 FD CB 7F B1
        res  6,(iy+127),d       ; 1254 FD CB 7F B2
        res  6,(iy+127),e       ; 1258 FD CB 7F B3
        res  6,(iy+127),h       ; 125C FD CB 7F B4
        res  6,(iy+127),l       ; 1260 FD CB 7F B5
        res  6,a                ; 1264 CB B7
        res  6,b                ; 1266 CB B0
        res  6,c                ; 1268 CB B1
        res  6,d                ; 126A CB B2
        res  6,e                ; 126C CB B3
        res  6,h                ; 126E CB B4
        res  6,l                ; 1270 CB B5
        res  7,(hl)             ; 1272 CB BE
        res  7,(ix)             ; 1274 DD CB 00 BE
        res  7,(ix),a           ; 1278 DD CB 00 BF
        res  7,(ix),b           ; 127C DD CB 00 B8
        res  7,(ix),c           ; 1280 DD CB 00 B9
        res  7,(ix),d           ; 1284 DD CB 00 BA
        res  7,(ix),e           ; 1288 DD CB 00 BB
        res  7,(ix),h           ; 128C DD CB 00 BC
        res  7,(ix),l           ; 1290 DD CB 00 BD
        res  7,(ix+127)         ; 1294 DD CB 7F BE
        res  7,(ix+127),a       ; 1298 DD CB 7F BF
        res  7,(ix+127),b       ; 129C DD CB 7F B8
        res  7,(ix+127),c       ; 12A0 DD CB 7F B9
        res  7,(ix+127),d       ; 12A4 DD CB 7F BA
        res  7,(ix+127),e       ; 12A8 DD CB 7F BB
        res  7,(ix+127),h       ; 12AC DD CB 7F BC
        res  7,(ix+127),l       ; 12B0 DD CB 7F BD
        res  7,(ix+127)         ; 12B4 DD CB 7F BE
        res  7,(ix+127),a       ; 12B8 DD CB 7F BF
        res  7,(ix+127),b       ; 12BC DD CB 7F B8
        res  7,(ix+127),c       ; 12C0 DD CB 7F B9
        res  7,(ix+127),d       ; 12C4 DD CB 7F BA
        res  7,(ix+127),e       ; 12C8 DD CB 7F BB
        res  7,(ix+127),h       ; 12CC DD CB 7F BC
        res  7,(ix+127),l       ; 12D0 DD CB 7F BD
        res  7,(iy)             ; 12D4 FD CB 00 BE
        res  7,(iy),a           ; 12D8 FD CB 00 BF
        res  7,(iy),b           ; 12DC FD CB 00 B8
        res  7,(iy),c           ; 12E0 FD CB 00 B9
        res  7,(iy),d           ; 12E4 FD CB 00 BA
        res  7,(iy),e           ; 12E8 FD CB 00 BB
        res  7,(iy),h           ; 12EC FD CB 00 BC
        res  7,(iy),l           ; 12F0 FD CB 00 BD
        res  7,(iy+127)         ; 12F4 FD CB 7F BE
        res  7,(iy+127),a       ; 12F8 FD CB 7F BF
        res  7,(iy+127),b       ; 12FC FD CB 7F B8
        res  7,(iy+127),c       ; 1300 FD CB 7F B9
        res  7,(iy+127),d       ; 1304 FD CB 7F BA
        res  7,(iy+127),e       ; 1308 FD CB 7F BB
        res  7,(iy+127),h       ; 130C FD CB 7F BC
        res  7,(iy+127),l       ; 1310 FD CB 7F BD
        res  7,(iy+127)         ; 1314 FD CB 7F BE
        res  7,(iy+127),a       ; 1318 FD CB 7F BF
        res  7,(iy+127),b       ; 131C FD CB 7F B8
        res  7,(iy+127),c       ; 1320 FD CB 7F B9
        res  7,(iy+127),d       ; 1324 FD CB 7F BA
        res  7,(iy+127),e       ; 1328 FD CB 7F BB
        res  7,(iy+127),h       ; 132C FD CB 7F BC
        res  7,(iy+127),l       ; 1330 FD CB 7F BD
        res  7,a                ; 1334 CB BF
        res  7,b                ; 1336 CB B8
        res  7,c                ; 1338 CB B9
        res  7,d                ; 133A CB BA
        res  7,e                ; 133C CB BB
        res  7,h                ; 133E CB BC
        res  7,l                ; 1340 CB BD
        ret                     ; 1342 C9
        RET                     ; 1343 C9
        ret  c                  ; 1344 D8
        ret  m                  ; 1345 F8
        ret  nc                 ; 1346 D0
        ret  nz                 ; 1347 C0
        ret  p                  ; 1348 F0
        ret  pe                 ; 1349 E8
        ret  po                 ; 134A E0
        ret  z                  ; 134B C8
        reti                    ; 134C ED 4D
        RETI                    ; 134E ED 4D
        retn                    ; 1350 ED 45
        RETN                    ; 1352 ED 45
        rl   (hl)               ; 1354 CB 16
        RL   (HL)               ; 1356 CB 16
        rl   (ix)               ; 1358 DD CB 00 16
        rl   (ix),a             ; 135C DD CB 00 17
        rl   (ix),b             ; 1360 DD CB 00 10
        rl   (ix),c             ; 1364 DD CB 00 11
        rl   (ix),d             ; 1368 DD CB 00 12
        rl   (ix),e             ; 136C DD CB 00 13
        rl   (ix),h             ; 1370 DD CB 00 14
        rl   (ix),l             ; 1374 DD CB 00 15
        rl   (ix+127)           ; 1378 DD CB 7F 16
        rl   (ix+127),a         ; 137C DD CB 7F 17
        rl   (ix+127),b         ; 1380 DD CB 7F 10
        rl   (ix+127),c         ; 1384 DD CB 7F 11
        rl   (ix+127),d         ; 1388 DD CB 7F 12
        rl   (ix+127),e         ; 138C DD CB 7F 13
        rl   (ix+127),h         ; 1390 DD CB 7F 14
        rl   (ix+127),l         ; 1394 DD CB 7F 15
        rl   (ix+127)           ; 1398 DD CB 7F 16
        rl   (ix+127),a         ; 139C DD CB 7F 17
        rl   (ix+127),b         ; 13A0 DD CB 7F 10
        rl   (ix+127),c         ; 13A4 DD CB 7F 11
        rl   (ix+127),d         ; 13A8 DD CB 7F 12
        rl   (ix+127),e         ; 13AC DD CB 7F 13
        rl   (ix+127),h         ; 13B0 DD CB 7F 14
        rl   (ix+127),l         ; 13B4 DD CB 7F 15
        rl   (iy)               ; 13B8 FD CB 00 16
        rl   (iy),a             ; 13BC FD CB 00 17
        rl   (iy),b             ; 13C0 FD CB 00 10
        rl   (iy),c             ; 13C4 FD CB 00 11
        rl   (iy),d             ; 13C8 FD CB 00 12
        rl   (iy),e             ; 13CC FD CB 00 13
        rl   (iy),h             ; 13D0 FD CB 00 14
        rl   (iy),l             ; 13D4 FD CB 00 15
        rl   (iy+127)           ; 13D8 FD CB 7F 16
        rl   (iy+127),a         ; 13DC FD CB 7F 17
        rl   (iy+127),b         ; 13E0 FD CB 7F 10
        rl   (iy+127),c         ; 13E4 FD CB 7F 11
        rl   (iy+127),d         ; 13E8 FD CB 7F 12
        rl   (iy+127),e         ; 13EC FD CB 7F 13
        rl   (iy+127),h         ; 13F0 FD CB 7F 14
        rl   (iy+127),l         ; 13F4 FD CB 7F 15
        rl   (iy+127)           ; 13F8 FD CB 7F 16
        rl   (iy+127),a         ; 13FC FD CB 7F 17
        rl   (iy+127),b         ; 1400 FD CB 7F 10
        rl   (iy+127),c         ; 1404 FD CB 7F 11
        rl   (iy+127),d         ; 1408 FD CB 7F 12
        rl   (iy+127),e         ; 140C FD CB 7F 13
        rl   (iy+127),h         ; 1410 FD CB 7F 14
        rl   (iy+127),l         ; 1414 FD CB 7F 15
        rl   a                  ; 1418 CB 17
        rl   b                  ; 141A CB 10
        rl   bc                 ; 141C CB 11 CB 10
        rl   c                  ; 1420 CB 11
        rl   d                  ; 1422 CB 12
        rl   de                 ; 1424 CB 13 CB 12
        rl   e                  ; 1428 CB 13
        rl   h                  ; 142A CB 14
        rl   hl                 ; 142C CB 15 CB 14
        rl   l                  ; 1430 CB 15
        rla                     ; 1432 17
        RLA                     ; 1433 17
        rlc  (hl)               ; 1434 CB 06
        RLC  (HL)               ; 1436 CB 06
        rlc  (ix)               ; 1438 DD CB 00 06
        rlc  (ix),a             ; 143C DD CB 00 07
        rlc  (ix),b             ; 1440 DD CB 00 00
        rlc  (ix),c             ; 1444 DD CB 00 01
        rlc  (ix),d             ; 1448 DD CB 00 02
        rlc  (ix),e             ; 144C DD CB 00 03
        rlc  (ix),h             ; 1450 DD CB 00 04
        rlc  (ix),l             ; 1454 DD CB 00 05
        rlc  (ix+127)           ; 1458 DD CB 7F 06
        rlc  (ix+127),a         ; 145C DD CB 7F 07
        rlc  (ix+127),b         ; 1460 DD CB 7F 00
        rlc  (ix+127),c         ; 1464 DD CB 7F 01
        rlc  (ix+127),d         ; 1468 DD CB 7F 02
        rlc  (ix+127),e         ; 146C DD CB 7F 03
        rlc  (ix+127),h         ; 1470 DD CB 7F 04
        rlc  (ix+127),l         ; 1474 DD CB 7F 05
        rlc  (ix+127)           ; 1478 DD CB 7F 06
        rlc  (ix+127),a         ; 147C DD CB 7F 07
        rlc  (ix+127),b         ; 1480 DD CB 7F 00
        rlc  (ix+127),c         ; 1484 DD CB 7F 01
        rlc  (ix+127),d         ; 1488 DD CB 7F 02
        rlc  (ix+127),e         ; 148C DD CB 7F 03
        rlc  (ix+127),h         ; 1490 DD CB 7F 04
        rlc  (ix+127),l         ; 1494 DD CB 7F 05
        rlc  (iy)               ; 1498 FD CB 00 06
        rlc  (iy),a             ; 149C FD CB 00 07
        rlc  (iy),b             ; 14A0 FD CB 00 00
        rlc  (iy),c             ; 14A4 FD CB 00 01
        rlc  (iy),d             ; 14A8 FD CB 00 02
        rlc  (iy),e             ; 14AC FD CB 00 03
        rlc  (iy),h             ; 14B0 FD CB 00 04
        rlc  (iy),l             ; 14B4 FD CB 00 05
        rlc  (iy+127)           ; 14B8 FD CB 7F 06
        rlc  (iy+127),a         ; 14BC FD CB 7F 07
        rlc  (iy+127),b         ; 14C0 FD CB 7F 00
        rlc  (iy+127),c         ; 14C4 FD CB 7F 01
        rlc  (iy+127),d         ; 14C8 FD CB 7F 02
        rlc  (iy+127),e         ; 14CC FD CB 7F 03
        rlc  (iy+127),h         ; 14D0 FD CB 7F 04
        rlc  (iy+127),l         ; 14D4 FD CB 7F 05
        rlc  (iy+127)           ; 14D8 FD CB 7F 06
        rlc  (iy+127),a         ; 14DC FD CB 7F 07
        rlc  (iy+127),b         ; 14E0 FD CB 7F 00
        rlc  (iy+127),c         ; 14E4 FD CB 7F 01
        rlc  (iy+127),d         ; 14E8 FD CB 7F 02
        rlc  (iy+127),e         ; 14EC FD CB 7F 03
        rlc  (iy+127),h         ; 14F0 FD CB 7F 04
        rlc  (iy+127),l         ; 14F4 FD CB 7F 05
        rlc  a                  ; 14F8 CB 07
        rlc  b                  ; 14FA CB 00
        rlc  c                  ; 14FC CB 01
        rlc  d                  ; 14FE CB 02
        rlc  e                  ; 1500 CB 03
        rlc  h                  ; 1502 CB 04
        rlc  l                  ; 1504 CB 05
        rlca                    ; 1506 07
        RLCA                    ; 1507 07
        rld                     ; 1508 ED 6F
        RLD                     ; 150A ED 6F
        rr   (hl)               ; 150C CB 1E
        RR   (HL)               ; 150E CB 1E
        rr   (ix)               ; 1510 DD CB 00 1E
        rr   (ix),a             ; 1514 DD CB 00 1F
        rr   (ix),b             ; 1518 DD CB 00 18
        rr   (ix),c             ; 151C DD CB 00 19
        rr   (ix),d             ; 1520 DD CB 00 1A
        rr   (ix),e             ; 1524 DD CB 00 1B
        rr   (ix),h             ; 1528 DD CB 00 1C
        rr   (ix),l             ; 152C DD CB 00 1D
        rr   (ix+127)           ; 1530 DD CB 7F 1E
        rr   (ix+127),a         ; 1534 DD CB 7F 1F
        rr   (ix+127),b         ; 1538 DD CB 7F 18
        rr   (ix+127),c         ; 153C DD CB 7F 19
        rr   (ix+127),d         ; 1540 DD CB 7F 1A
        rr   (ix+127),e         ; 1544 DD CB 7F 1B
        rr   (ix+127),h         ; 1548 DD CB 7F 1C
        rr   (ix+127),l         ; 154C DD CB 7F 1D
        rr   (ix+127)           ; 1550 DD CB 7F 1E
        rr   (ix+127),a         ; 1554 DD CB 7F 1F
        rr   (ix+127),b         ; 1558 DD CB 7F 18
        rr   (ix+127),c         ; 155C DD CB 7F 19
        rr   (ix+127),d         ; 1560 DD CB 7F 1A
        rr   (ix+127),e         ; 1564 DD CB 7F 1B
        rr   (ix+127),h         ; 1568 DD CB 7F 1C
        rr   (ix+127),l         ; 156C DD CB 7F 1D
        rr   (iy)               ; 1570 FD CB 00 1E
        rr   (iy),a             ; 1574 FD CB 00 1F
        rr   (iy),b             ; 1578 FD CB 00 18
        rr   (iy),c             ; 157C FD CB 00 19
        rr   (iy),d             ; 1580 FD CB 00 1A
        rr   (iy),e             ; 1584 FD CB 00 1B
        rr   (iy),h             ; 1588 FD CB 00 1C
        rr   (iy),l             ; 158C FD CB 00 1D
        rr   (iy+127)           ; 1590 FD CB 7F 1E
        rr   (iy+127),a         ; 1594 FD CB 7F 1F
        rr   (iy+127),b         ; 1598 FD CB 7F 18
        rr   (iy+127),c         ; 159C FD CB 7F 19
        rr   (iy+127),d         ; 15A0 FD CB 7F 1A
        rr   (iy+127),e         ; 15A4 FD CB 7F 1B
        rr   (iy+127),h         ; 15A8 FD CB 7F 1C
        rr   (iy+127),l         ; 15AC FD CB 7F 1D
        rr   (iy+127)           ; 15B0 FD CB 7F 1E
        rr   (iy+127),a         ; 15B4 FD CB 7F 1F
        rr   (iy+127),b         ; 15B8 FD CB 7F 18
        rr   (iy+127),c         ; 15BC FD CB 7F 19
        rr   (iy+127),d         ; 15C0 FD CB 7F 1A
        rr   (iy+127),e         ; 15C4 FD CB 7F 1B
        rr   (iy+127),h         ; 15C8 FD CB 7F 1C
        rr   (iy+127),l         ; 15CC FD CB 7F 1D
        rr   a                  ; 15D0 CB 1F
        rr   b                  ; 15D2 CB 18
        rr   bc                 ; 15D4 CB 18 CB 19
        rr   c                  ; 15D8 CB 19
        rr   d                  ; 15DA CB 1A
        rr   de                 ; 15DC CB 1A CB 1B
        rr   e                  ; 15E0 CB 1B
        rr   h                  ; 15E2 CB 1C
        rr   hl                 ; 15E4 CB 1C CB 1D
        rr   l                  ; 15E8 CB 1D
        rra                     ; 15EA 1F
        RRA                     ; 15EB 1F
        rrc  (hl)               ; 15EC CB 0E
        RRC  (HL)               ; 15EE CB 0E
        rrc  (ix)               ; 15F0 DD CB 00 0E
        rrc  (ix),a             ; 15F4 DD CB 00 0F
        rrc  (ix),b             ; 15F8 DD CB 00 08
        rrc  (ix),c             ; 15FC DD CB 00 09
        rrc  (ix),d             ; 1600 DD CB 00 0A
        rrc  (ix),e             ; 1604 DD CB 00 0B
        rrc  (ix),h             ; 1608 DD CB 00 0C
        rrc  (ix),l             ; 160C DD CB 00 0D
        rrc  (ix+127)           ; 1610 DD CB 7F 0E
        rrc  (ix+127),a         ; 1614 DD CB 7F 0F
        rrc  (ix+127),b         ; 1618 DD CB 7F 08
        rrc  (ix+127),c         ; 161C DD CB 7F 09
        rrc  (ix+127),d         ; 1620 DD CB 7F 0A
        rrc  (ix+127),e         ; 1624 DD CB 7F 0B
        rrc  (ix+127),h         ; 1628 DD CB 7F 0C
        rrc  (ix+127),l         ; 162C DD CB 7F 0D
        rrc  (ix+127)           ; 1630 DD CB 7F 0E
        rrc  (ix+127),a         ; 1634 DD CB 7F 0F
        rrc  (ix+127),b         ; 1638 DD CB 7F 08
        rrc  (ix+127),c         ; 163C DD CB 7F 09
        rrc  (ix+127),d         ; 1640 DD CB 7F 0A
        rrc  (ix+127),e         ; 1644 DD CB 7F 0B
        rrc  (ix+127),h         ; 1648 DD CB 7F 0C
        rrc  (ix+127),l         ; 164C DD CB 7F 0D
        rrc  (iy)               ; 1650 FD CB 00 0E
        rrc  (iy),a             ; 1654 FD CB 00 0F
        rrc  (iy),b             ; 1658 FD CB 00 08
        rrc  (iy),c             ; 165C FD CB 00 09
        rrc  (iy),d             ; 1660 FD CB 00 0A
        rrc  (iy),e             ; 1664 FD CB 00 0B
        rrc  (iy),h             ; 1668 FD CB 00 0C
        rrc  (iy),l             ; 166C FD CB 00 0D
        rrc  (iy+127)           ; 1670 FD CB 7F 0E
        rrc  (iy+127),a         ; 1674 FD CB 7F 0F
        rrc  (iy+127),b         ; 1678 FD CB 7F 08
        rrc  (iy+127),c         ; 167C FD CB 7F 09
        rrc  (iy+127),d         ; 1680 FD CB 7F 0A
        rrc  (iy+127),e         ; 1684 FD CB 7F 0B
        rrc  (iy+127),h         ; 1688 FD CB 7F 0C
        rrc  (iy+127),l         ; 168C FD CB 7F 0D
        rrc  (iy+127)           ; 1690 FD CB 7F 0E
        rrc  (iy+127),a         ; 1694 FD CB 7F 0F
        rrc  (iy+127),b         ; 1698 FD CB 7F 08
        rrc  (iy+127),c         ; 169C FD CB 7F 09
        rrc  (iy+127),d         ; 16A0 FD CB 7F 0A
        rrc  (iy+127),e         ; 16A4 FD CB 7F 0B
        rrc  (iy+127),h         ; 16A8 FD CB 7F 0C
        rrc  (iy+127),l         ; 16AC FD CB 7F 0D
        rrc  a                  ; 16B0 CB 0F
        rrc  b                  ; 16B2 CB 08
        rrc  c                  ; 16B4 CB 09
        rrc  d                  ; 16B6 CB 0A
        rrc  e                  ; 16B8 CB 0B
        rrc  h                  ; 16BA CB 0C
        rrc  l                  ; 16BC CB 0D
        rrca                    ; 16BE 0F
        RRCA                    ; 16BF 0F
        rrd                     ; 16C0 ED 67
        RRD                     ; 16C2 ED 67
        rst  0                  ; 16C4 C7
        RST  0                  ; 16C5 C7
        rst  1                  ; 16C6 CF
        rst  16                 ; 16C7 D7
        rst  2                  ; 16C8 D7
        rst  24                 ; 16C9 DF
        rst  3                  ; 16CA DF
        rst  32                 ; 16CB E7
        rst  4                  ; 16CC E7
        rst  40                 ; 16CD EF
        rst  48                 ; 16CE F7
        rst  5                  ; 16CF EF
        rst  56                 ; 16D0 FF
        rst  6                  ; 16D1 F7
        rst  7                  ; 16D2 FF
        rst  8                  ; 16D3 CF
        sbc  a,(hl)             ; 16D4 9E
        SBC  A,(HL)             ; 16D5 9E
        sbc  a,(ix)             ; 16D6 DD 9E 00
        sbc  a,(ix+127)         ; 16D9 DD 9E 7F
        sbc  a,(ix+127)         ; 16DC DD 9E 7F
        sbc  a,(iy)             ; 16DF FD 9E 00
        sbc  a,(iy+127)         ; 16E2 FD 9E 7F
        sbc  a,(iy+127)         ; 16E5 FD 9E 7F
        sbc  a,255              ; 16E8 DE FF
        sbc  a,a                ; 16EA 9F
        sbc  a,b                ; 16EB 98
        sbc  a,c                ; 16EC 99
        sbc  a,d                ; 16ED 9A
        sbc  a,e                ; 16EE 9B
        sbc  a,h                ; 16EF 9C
        sbc  a,ixh              ; 16F0 DD 9C
        sbc  a,ixl              ; 16F2 DD 9D
        sbc  a,iyh              ; 16F4 FD 9C
        sbc  a,iyl              ; 16F6 FD 9D
        sbc  a,l                ; 16F8 9D
        sbc  hl,bc              ; 16F9 ED 42
        sbc  hl,de              ; 16FB ED 52
        sbc  hl,hl              ; 16FD ED 62
        sbc  hl,sp              ; 16FF ED 72
        scf                     ; 1701 37
        SCF                     ; 1702 37
        set  0,(hl)             ; 1703 CB C6
        SET  0,(HL)             ; 1705 CB C6
        set  0,(ix)             ; 1707 DD CB 00 C6
        set  0,(ix),a           ; 170B DD CB 00 C7
        set  0,(ix),b           ; 170F DD CB 00 C0
        set  0,(ix),c           ; 1713 DD CB 00 C1
        set  0,(ix),d           ; 1717 DD CB 00 C2
        set  0,(ix),e           ; 171B DD CB 00 C3
        set  0,(ix),h           ; 171F DD CB 00 C4
        set  0,(ix),l           ; 1723 DD CB 00 C5
        set  0,(ix+127)         ; 1727 DD CB 7F C6
        set  0,(ix+127),a       ; 172B DD CB 7F C7
        set  0,(ix+127),b       ; 172F DD CB 7F C0
        set  0,(ix+127),c       ; 1733 DD CB 7F C1
        set  0,(ix+127),d       ; 1737 DD CB 7F C2
        set  0,(ix+127),e       ; 173B DD CB 7F C3
        set  0,(ix+127),h       ; 173F DD CB 7F C4
        set  0,(ix+127),l       ; 1743 DD CB 7F C5
        set  0,(ix+127)         ; 1747 DD CB 7F C6
        set  0,(ix+127),a       ; 174B DD CB 7F C7
        set  0,(ix+127),b       ; 174F DD CB 7F C0
        set  0,(ix+127),c       ; 1753 DD CB 7F C1
        set  0,(ix+127),d       ; 1757 DD CB 7F C2
        set  0,(ix+127),e       ; 175B DD CB 7F C3
        set  0,(ix+127),h       ; 175F DD CB 7F C4
        set  0,(ix+127),l       ; 1763 DD CB 7F C5
        set  0,(iy)             ; 1767 FD CB 00 C6
        set  0,(iy),a           ; 176B FD CB 00 C7
        set  0,(iy),b           ; 176F FD CB 00 C0
        set  0,(iy),c           ; 1773 FD CB 00 C1
        set  0,(iy),d           ; 1777 FD CB 00 C2
        set  0,(iy),e           ; 177B FD CB 00 C3
        set  0,(iy),h           ; 177F FD CB 00 C4
        set  0,(iy),l           ; 1783 FD CB 00 C5
        set  0,(iy+127)         ; 1787 FD CB 7F C6
        set  0,(iy+127),a       ; 178B FD CB 7F C7
        set  0,(iy+127),b       ; 178F FD CB 7F C0
        set  0,(iy+127),c       ; 1793 FD CB 7F C1
        set  0,(iy+127),d       ; 1797 FD CB 7F C2
        set  0,(iy+127),e       ; 179B FD CB 7F C3
        set  0,(iy+127),h       ; 179F FD CB 7F C4
        set  0,(iy+127),l       ; 17A3 FD CB 7F C5
        set  0,(iy+127)         ; 17A7 FD CB 7F C6
        set  0,(iy+127),a       ; 17AB FD CB 7F C7
        set  0,(iy+127),b       ; 17AF FD CB 7F C0
        set  0,(iy+127),c       ; 17B3 FD CB 7F C1
        set  0,(iy+127),d       ; 17B7 FD CB 7F C2
        set  0,(iy+127),e       ; 17BB FD CB 7F C3
        set  0,(iy+127),h       ; 17BF FD CB 7F C4
        set  0,(iy+127),l       ; 17C3 FD CB 7F C5
        set  0,a                ; 17C7 CB C7
        set  0,b                ; 17C9 CB C0
        set  0,c                ; 17CB CB C1
        set  0,d                ; 17CD CB C2
        set  0,e                ; 17CF CB C3
        set  0,h                ; 17D1 CB C4
        set  0,l                ; 17D3 CB C5
        set  1,(hl)             ; 17D5 CB CE
        set  1,(ix)             ; 17D7 DD CB 00 CE
        set  1,(ix),a           ; 17DB DD CB 00 CF
        set  1,(ix),b           ; 17DF DD CB 00 C8
        set  1,(ix),c           ; 17E3 DD CB 00 C9
        set  1,(ix),d           ; 17E7 DD CB 00 CA
        set  1,(ix),e           ; 17EB DD CB 00 CB
        set  1,(ix),h           ; 17EF DD CB 00 CC
        set  1,(ix),l           ; 17F3 DD CB 00 CD
        set  1,(ix+127)         ; 17F7 DD CB 7F CE
        set  1,(ix+127),a       ; 17FB DD CB 7F CF
        set  1,(ix+127),b       ; 17FF DD CB 7F C8
        set  1,(ix+127),c       ; 1803 DD CB 7F C9
        set  1,(ix+127),d       ; 1807 DD CB 7F CA
        set  1,(ix+127),e       ; 180B DD CB 7F CB
        set  1,(ix+127),h       ; 180F DD CB 7F CC
        set  1,(ix+127),l       ; 1813 DD CB 7F CD
        set  1,(ix+127)         ; 1817 DD CB 7F CE
        set  1,(ix+127),a       ; 181B DD CB 7F CF
        set  1,(ix+127),b       ; 181F DD CB 7F C8
        set  1,(ix+127),c       ; 1823 DD CB 7F C9
        set  1,(ix+127),d       ; 1827 DD CB 7F CA
        set  1,(ix+127),e       ; 182B DD CB 7F CB
        set  1,(ix+127),h       ; 182F DD CB 7F CC
        set  1,(ix+127),l       ; 1833 DD CB 7F CD
        set  1,(iy)             ; 1837 FD CB 00 CE
        set  1,(iy),a           ; 183B FD CB 00 CF
        set  1,(iy),b           ; 183F FD CB 00 C8
        set  1,(iy),c           ; 1843 FD CB 00 C9
        set  1,(iy),d           ; 1847 FD CB 00 CA
        set  1,(iy),e           ; 184B FD CB 00 CB
        set  1,(iy),h           ; 184F FD CB 00 CC
        set  1,(iy),l           ; 1853 FD CB 00 CD
        set  1,(iy+127)         ; 1857 FD CB 7F CE
        set  1,(iy+127),a       ; 185B FD CB 7F CF
        set  1,(iy+127),b       ; 185F FD CB 7F C8
        set  1,(iy+127),c       ; 1863 FD CB 7F C9
        set  1,(iy+127),d       ; 1867 FD CB 7F CA
        set  1,(iy+127),e       ; 186B FD CB 7F CB
        set  1,(iy+127),h       ; 186F FD CB 7F CC
        set  1,(iy+127),l       ; 1873 FD CB 7F CD
        set  1,(iy+127)         ; 1877 FD CB 7F CE
        set  1,(iy+127),a       ; 187B FD CB 7F CF
        set  1,(iy+127),b       ; 187F FD CB 7F C8
        set  1,(iy+127),c       ; 1883 FD CB 7F C9
        set  1,(iy+127),d       ; 1887 FD CB 7F CA
        set  1,(iy+127),e       ; 188B FD CB 7F CB
        set  1,(iy+127),h       ; 188F FD CB 7F CC
        set  1,(iy+127),l       ; 1893 FD CB 7F CD
        set  1,a                ; 1897 CB CF
        set  1,b                ; 1899 CB C8
        set  1,c                ; 189B CB C9
        set  1,d                ; 189D CB CA
        set  1,e                ; 189F CB CB
        set  1,h                ; 18A1 CB CC
        set  1,l                ; 18A3 CB CD
        set  2,(hl)             ; 18A5 CB D6
        set  2,(ix)             ; 18A7 DD CB 00 D6
        set  2,(ix),a           ; 18AB DD CB 00 D7
        set  2,(ix),b           ; 18AF DD CB 00 D0
        set  2,(ix),c           ; 18B3 DD CB 00 D1
        set  2,(ix),d           ; 18B7 DD CB 00 D2
        set  2,(ix),e           ; 18BB DD CB 00 D3
        set  2,(ix),h           ; 18BF DD CB 00 D4
        set  2,(ix),l           ; 18C3 DD CB 00 D5
        set  2,(ix+127)         ; 18C7 DD CB 7F D6
        set  2,(ix+127),a       ; 18CB DD CB 7F D7
        set  2,(ix+127),b       ; 18CF DD CB 7F D0
        set  2,(ix+127),c       ; 18D3 DD CB 7F D1
        set  2,(ix+127),d       ; 18D7 DD CB 7F D2
        set  2,(ix+127),e       ; 18DB DD CB 7F D3
        set  2,(ix+127),h       ; 18DF DD CB 7F D4
        set  2,(ix+127),l       ; 18E3 DD CB 7F D5
        set  2,(ix+127)         ; 18E7 DD CB 7F D6
        set  2,(ix+127),a       ; 18EB DD CB 7F D7
        set  2,(ix+127),b       ; 18EF DD CB 7F D0
        set  2,(ix+127),c       ; 18F3 DD CB 7F D1
        set  2,(ix+127),d       ; 18F7 DD CB 7F D2
        set  2,(ix+127),e       ; 18FB DD CB 7F D3
        set  2,(ix+127),h       ; 18FF DD CB 7F D4
        set  2,(ix+127),l       ; 1903 DD CB 7F D5
        set  2,(iy)             ; 1907 FD CB 00 D6
        set  2,(iy),a           ; 190B FD CB 00 D7
        set  2,(iy),b           ; 190F FD CB 00 D0
        set  2,(iy),c           ; 1913 FD CB 00 D1
        set  2,(iy),d           ; 1917 FD CB 00 D2
        set  2,(iy),e           ; 191B FD CB 00 D3
        set  2,(iy),h           ; 191F FD CB 00 D4
        set  2,(iy),l           ; 1923 FD CB 00 D5
        set  2,(iy+127)         ; 1927 FD CB 7F D6
        set  2,(iy+127),a       ; 192B FD CB 7F D7
        set  2,(iy+127),b       ; 192F FD CB 7F D0
        set  2,(iy+127),c       ; 1933 FD CB 7F D1
        set  2,(iy+127),d       ; 1937 FD CB 7F D2
        set  2,(iy+127),e       ; 193B FD CB 7F D3
        set  2,(iy+127),h       ; 193F FD CB 7F D4
        set  2,(iy+127),l       ; 1943 FD CB 7F D5
        set  2,(iy+127)         ; 1947 FD CB 7F D6
        set  2,(iy+127),a       ; 194B FD CB 7F D7
        set  2,(iy+127),b       ; 194F FD CB 7F D0
        set  2,(iy+127),c       ; 1953 FD CB 7F D1
        set  2,(iy+127),d       ; 1957 FD CB 7F D2
        set  2,(iy+127),e       ; 195B FD CB 7F D3
        set  2,(iy+127),h       ; 195F FD CB 7F D4
        set  2,(iy+127),l       ; 1963 FD CB 7F D5
        set  2,a                ; 1967 CB D7
        set  2,b                ; 1969 CB D0
        set  2,c                ; 196B CB D1
        set  2,d                ; 196D CB D2
        set  2,e                ; 196F CB D3
        set  2,h                ; 1971 CB D4
        set  2,l                ; 1973 CB D5
        set  3,(hl)             ; 1975 CB DE
        set  3,(ix)             ; 1977 DD CB 00 DE
        set  3,(ix),a           ; 197B DD CB 00 DF
        set  3,(ix),b           ; 197F DD CB 00 D8
        set  3,(ix),c           ; 1983 DD CB 00 D9
        set  3,(ix),d           ; 1987 DD CB 00 DA
        set  3,(ix),e           ; 198B DD CB 00 DB
        set  3,(ix),h           ; 198F DD CB 00 DC
        set  3,(ix),l           ; 1993 DD CB 00 DD
        set  3,(ix+127)         ; 1997 DD CB 7F DE
        set  3,(ix+127),a       ; 199B DD CB 7F DF
        set  3,(ix+127),b       ; 199F DD CB 7F D8
        set  3,(ix+127),c       ; 19A3 DD CB 7F D9
        set  3,(ix+127),d       ; 19A7 DD CB 7F DA
        set  3,(ix+127),e       ; 19AB DD CB 7F DB
        set  3,(ix+127),h       ; 19AF DD CB 7F DC
        set  3,(ix+127),l       ; 19B3 DD CB 7F DD
        set  3,(ix+127)         ; 19B7 DD CB 7F DE
        set  3,(ix+127),a       ; 19BB DD CB 7F DF
        set  3,(ix+127),b       ; 19BF DD CB 7F D8
        set  3,(ix+127),c       ; 19C3 DD CB 7F D9
        set  3,(ix+127),d       ; 19C7 DD CB 7F DA
        set  3,(ix+127),e       ; 19CB DD CB 7F DB
        set  3,(ix+127),h       ; 19CF DD CB 7F DC
        set  3,(ix+127),l       ; 19D3 DD CB 7F DD
        set  3,(iy)             ; 19D7 FD CB 00 DE
        set  3,(iy),a           ; 19DB FD CB 00 DF
        set  3,(iy),b           ; 19DF FD CB 00 D8
        set  3,(iy),c           ; 19E3 FD CB 00 D9
        set  3,(iy),d           ; 19E7 FD CB 00 DA
        set  3,(iy),e           ; 19EB FD CB 00 DB
        set  3,(iy),h           ; 19EF FD CB 00 DC
        set  3,(iy),l           ; 19F3 FD CB 00 DD
        set  3,(iy+127)         ; 19F7 FD CB 7F DE
        set  3,(iy+127),a       ; 19FB FD CB 7F DF
        set  3,(iy+127),b       ; 19FF FD CB 7F D8
        set  3,(iy+127),c       ; 1A03 FD CB 7F D9
        set  3,(iy+127),d       ; 1A07 FD CB 7F DA
        set  3,(iy+127),e       ; 1A0B FD CB 7F DB
        set  3,(iy+127),h       ; 1A0F FD CB 7F DC
        set  3,(iy+127),l       ; 1A13 FD CB 7F DD
        set  3,(iy+127)         ; 1A17 FD CB 7F DE
        set  3,(iy+127),a       ; 1A1B FD CB 7F DF
        set  3,(iy+127),b       ; 1A1F FD CB 7F D8
        set  3,(iy+127),c       ; 1A23 FD CB 7F D9
        set  3,(iy+127),d       ; 1A27 FD CB 7F DA
        set  3,(iy+127),e       ; 1A2B FD CB 7F DB
        set  3,(iy+127),h       ; 1A2F FD CB 7F DC
        set  3,(iy+127),l       ; 1A33 FD CB 7F DD
        set  3,a                ; 1A37 CB DF
        set  3,b                ; 1A39 CB D8
        set  3,c                ; 1A3B CB D9
        set  3,d                ; 1A3D CB DA
        set  3,e                ; 1A3F CB DB
        set  3,h                ; 1A41 CB DC
        set  3,l                ; 1A43 CB DD
        set  4,(hl)             ; 1A45 CB E6
        set  4,(ix)             ; 1A47 DD CB 00 E6
        set  4,(ix),a           ; 1A4B DD CB 00 E7
        set  4,(ix),b           ; 1A4F DD CB 00 E0
        set  4,(ix),c           ; 1A53 DD CB 00 E1
        set  4,(ix),d           ; 1A57 DD CB 00 E2
        set  4,(ix),e           ; 1A5B DD CB 00 E3
        set  4,(ix),h           ; 1A5F DD CB 00 E4
        set  4,(ix),l           ; 1A63 DD CB 00 E5
        set  4,(ix+127)         ; 1A67 DD CB 7F E6
        set  4,(ix+127),a       ; 1A6B DD CB 7F E7
        set  4,(ix+127),b       ; 1A6F DD CB 7F E0
        set  4,(ix+127),c       ; 1A73 DD CB 7F E1
        set  4,(ix+127),d       ; 1A77 DD CB 7F E2
        set  4,(ix+127),e       ; 1A7B DD CB 7F E3
        set  4,(ix+127),h       ; 1A7F DD CB 7F E4
        set  4,(ix+127),l       ; 1A83 DD CB 7F E5
        set  4,(ix+127)         ; 1A87 DD CB 7F E6
        set  4,(ix+127),a       ; 1A8B DD CB 7F E7
        set  4,(ix+127),b       ; 1A8F DD CB 7F E0
        set  4,(ix+127),c       ; 1A93 DD CB 7F E1
        set  4,(ix+127),d       ; 1A97 DD CB 7F E2
        set  4,(ix+127),e       ; 1A9B DD CB 7F E3
        set  4,(ix+127),h       ; 1A9F DD CB 7F E4
        set  4,(ix+127),l       ; 1AA3 DD CB 7F E5
        set  4,(iy)             ; 1AA7 FD CB 00 E6
        set  4,(iy),a           ; 1AAB FD CB 00 E7
        set  4,(iy),b           ; 1AAF FD CB 00 E0
        set  4,(iy),c           ; 1AB3 FD CB 00 E1
        set  4,(iy),d           ; 1AB7 FD CB 00 E2
        set  4,(iy),e           ; 1ABB FD CB 00 E3
        set  4,(iy),h           ; 1ABF FD CB 00 E4
        set  4,(iy),l           ; 1AC3 FD CB 00 E5
        set  4,(iy+127)         ; 1AC7 FD CB 7F E6
        set  4,(iy+127),a       ; 1ACB FD CB 7F E7
        set  4,(iy+127),b       ; 1ACF FD CB 7F E0
        set  4,(iy+127),c       ; 1AD3 FD CB 7F E1
        set  4,(iy+127),d       ; 1AD7 FD CB 7F E2
        set  4,(iy+127),e       ; 1ADB FD CB 7F E3
        set  4,(iy+127),h       ; 1ADF FD CB 7F E4
        set  4,(iy+127),l       ; 1AE3 FD CB 7F E5
        set  4,(iy+127)         ; 1AE7 FD CB 7F E6
        set  4,(iy+127),a       ; 1AEB FD CB 7F E7
        set  4,(iy+127),b       ; 1AEF FD CB 7F E0
        set  4,(iy+127),c       ; 1AF3 FD CB 7F E1
        set  4,(iy+127),d       ; 1AF7 FD CB 7F E2
        set  4,(iy+127),e       ; 1AFB FD CB 7F E3
        set  4,(iy+127),h       ; 1AFF FD CB 7F E4
        set  4,(iy+127),l       ; 1B03 FD CB 7F E5
        set  4,a                ; 1B07 CB E7
        set  4,b                ; 1B09 CB E0
        set  4,c                ; 1B0B CB E1
        set  4,d                ; 1B0D CB E2
        set  4,e                ; 1B0F CB E3
        set  4,h                ; 1B11 CB E4
        set  4,l                ; 1B13 CB E5
        set  5,(hl)             ; 1B15 CB EE
        set  5,(ix)             ; 1B17 DD CB 00 EE
        set  5,(ix),a           ; 1B1B DD CB 00 EF
        set  5,(ix),b           ; 1B1F DD CB 00 E8
        set  5,(ix),c           ; 1B23 DD CB 00 E9
        set  5,(ix),d           ; 1B27 DD CB 00 EA
        set  5,(ix),e           ; 1B2B DD CB 00 EB
        set  5,(ix),h           ; 1B2F DD CB 00 EC
        set  5,(ix),l           ; 1B33 DD CB 00 ED
        set  5,(ix+127)         ; 1B37 DD CB 7F EE
        set  5,(ix+127),a       ; 1B3B DD CB 7F EF
        set  5,(ix+127),b       ; 1B3F DD CB 7F E8
        set  5,(ix+127),c       ; 1B43 DD CB 7F E9
        set  5,(ix+127),d       ; 1B47 DD CB 7F EA
        set  5,(ix+127),e       ; 1B4B DD CB 7F EB
        set  5,(ix+127),h       ; 1B4F DD CB 7F EC
        set  5,(ix+127),l       ; 1B53 DD CB 7F ED
        set  5,(ix+127)         ; 1B57 DD CB 7F EE
        set  5,(ix+127),a       ; 1B5B DD CB 7F EF
        set  5,(ix+127),b       ; 1B5F DD CB 7F E8
        set  5,(ix+127),c       ; 1B63 DD CB 7F E9
        set  5,(ix+127),d       ; 1B67 DD CB 7F EA
        set  5,(ix+127),e       ; 1B6B DD CB 7F EB
        set  5,(ix+127),h       ; 1B6F DD CB 7F EC
        set  5,(ix+127),l       ; 1B73 DD CB 7F ED
        set  5,(iy)             ; 1B77 FD CB 00 EE
        set  5,(iy),a           ; 1B7B FD CB 00 EF
        set  5,(iy),b           ; 1B7F FD CB 00 E8
        set  5,(iy),c           ; 1B83 FD CB 00 E9
        set  5,(iy),d           ; 1B87 FD CB 00 EA
        set  5,(iy),e           ; 1B8B FD CB 00 EB
        set  5,(iy),h           ; 1B8F FD CB 00 EC
        set  5,(iy),l           ; 1B93 FD CB 00 ED
        set  5,(iy+127)         ; 1B97 FD CB 7F EE
        set  5,(iy+127),a       ; 1B9B FD CB 7F EF
        set  5,(iy+127),b       ; 1B9F FD CB 7F E8
        set  5,(iy+127),c       ; 1BA3 FD CB 7F E9
        set  5,(iy+127),d       ; 1BA7 FD CB 7F EA
        set  5,(iy+127),e       ; 1BAB FD CB 7F EB
        set  5,(iy+127),h       ; 1BAF FD CB 7F EC
        set  5,(iy+127),l       ; 1BB3 FD CB 7F ED
        set  5,(iy+127)         ; 1BB7 FD CB 7F EE
        set  5,(iy+127),a       ; 1BBB FD CB 7F EF
        set  5,(iy+127),b       ; 1BBF FD CB 7F E8
        set  5,(iy+127),c       ; 1BC3 FD CB 7F E9
        set  5,(iy+127),d       ; 1BC7 FD CB 7F EA
        set  5,(iy+127),e       ; 1BCB FD CB 7F EB
        set  5,(iy+127),h       ; 1BCF FD CB 7F EC
        set  5,(iy+127),l       ; 1BD3 FD CB 7F ED
        set  5,a                ; 1BD7 CB EF
        set  5,b                ; 1BD9 CB E8
        set  5,c                ; 1BDB CB E9
        set  5,d                ; 1BDD CB EA
        set  5,e                ; 1BDF CB EB
        set  5,h                ; 1BE1 CB EC
        set  5,l                ; 1BE3 CB ED
        set  6,(hl)             ; 1BE5 CB F6
        set  6,(ix)             ; 1BE7 DD CB 00 F6
        set  6,(ix),a           ; 1BEB DD CB 00 F7
        set  6,(ix),b           ; 1BEF DD CB 00 F0
        set  6,(ix),c           ; 1BF3 DD CB 00 F1
        set  6,(ix),d           ; 1BF7 DD CB 00 F2
        set  6,(ix),e           ; 1BFB DD CB 00 F3
        set  6,(ix),h           ; 1BFF DD CB 00 F4
        set  6,(ix),l           ; 1C03 DD CB 00 F5
        set  6,(ix+127)         ; 1C07 DD CB 7F F6
        set  6,(ix+127),a       ; 1C0B DD CB 7F F7
        set  6,(ix+127),b       ; 1C0F DD CB 7F F0
        set  6,(ix+127),c       ; 1C13 DD CB 7F F1
        set  6,(ix+127),d       ; 1C17 DD CB 7F F2
        set  6,(ix+127),e       ; 1C1B DD CB 7F F3
        set  6,(ix+127),h       ; 1C1F DD CB 7F F4
        set  6,(ix+127),l       ; 1C23 DD CB 7F F5
        set  6,(ix+127)         ; 1C27 DD CB 7F F6
        set  6,(ix+127),a       ; 1C2B DD CB 7F F7
        set  6,(ix+127),b       ; 1C2F DD CB 7F F0
        set  6,(ix+127),c       ; 1C33 DD CB 7F F1
        set  6,(ix+127),d       ; 1C37 DD CB 7F F2
        set  6,(ix+127),e       ; 1C3B DD CB 7F F3
        set  6,(ix+127),h       ; 1C3F DD CB 7F F4
        set  6,(ix+127),l       ; 1C43 DD CB 7F F5
        set  6,(iy)             ; 1C47 FD CB 00 F6
        set  6,(iy),a           ; 1C4B FD CB 00 F7
        set  6,(iy),b           ; 1C4F FD CB 00 F0
        set  6,(iy),c           ; 1C53 FD CB 00 F1
        set  6,(iy),d           ; 1C57 FD CB 00 F2
        set  6,(iy),e           ; 1C5B FD CB 00 F3
        set  6,(iy),h           ; 1C5F FD CB 00 F4
        set  6,(iy),l           ; 1C63 FD CB 00 F5
        set  6,(iy+127)         ; 1C67 FD CB 7F F6
        set  6,(iy+127),a       ; 1C6B FD CB 7F F7
        set  6,(iy+127),b       ; 1C6F FD CB 7F F0
        set  6,(iy+127),c       ; 1C73 FD CB 7F F1
        set  6,(iy+127),d       ; 1C77 FD CB 7F F2
        set  6,(iy+127),e       ; 1C7B FD CB 7F F3
        set  6,(iy+127),h       ; 1C7F FD CB 7F F4
        set  6,(iy+127),l       ; 1C83 FD CB 7F F5
        set  6,(iy+127)         ; 1C87 FD CB 7F F6
        set  6,(iy+127),a       ; 1C8B FD CB 7F F7
        set  6,(iy+127),b       ; 1C8F FD CB 7F F0
        set  6,(iy+127),c       ; 1C93 FD CB 7F F1
        set  6,(iy+127),d       ; 1C97 FD CB 7F F2
        set  6,(iy+127),e       ; 1C9B FD CB 7F F3
        set  6,(iy+127),h       ; 1C9F FD CB 7F F4
        set  6,(iy+127),l       ; 1CA3 FD CB 7F F5
        set  6,a                ; 1CA7 CB F7
        set  6,b                ; 1CA9 CB F0
        set  6,c                ; 1CAB CB F1
        set  6,d                ; 1CAD CB F2
        set  6,e                ; 1CAF CB F3
        set  6,h                ; 1CB1 CB F4
        set  6,l                ; 1CB3 CB F5
        set  7,(hl)             ; 1CB5 CB FE
        set  7,(ix)             ; 1CB7 DD CB 00 FE
        set  7,(ix),a           ; 1CBB DD CB 00 FF
        set  7,(ix),b           ; 1CBF DD CB 00 F8
        set  7,(ix),c           ; 1CC3 DD CB 00 F9
        set  7,(ix),d           ; 1CC7 DD CB 00 FA
        set  7,(ix),e           ; 1CCB DD CB 00 FB
        set  7,(ix),h           ; 1CCF DD CB 00 FC
        set  7,(ix),l           ; 1CD3 DD CB 00 FD
        set  7,(ix+127)         ; 1CD7 DD CB 7F FE
        set  7,(ix+127),a       ; 1CDB DD CB 7F FF
        set  7,(ix+127),b       ; 1CDF DD CB 7F F8
        set  7,(ix+127),c       ; 1CE3 DD CB 7F F9
        set  7,(ix+127),d       ; 1CE7 DD CB 7F FA
        set  7,(ix+127),e       ; 1CEB DD CB 7F FB
        set  7,(ix+127),h       ; 1CEF DD CB 7F FC
        set  7,(ix+127),l       ; 1CF3 DD CB 7F FD
        set  7,(ix+127)         ; 1CF7 DD CB 7F FE
        set  7,(ix+127),a       ; 1CFB DD CB 7F FF
        set  7,(ix+127),b       ; 1CFF DD CB 7F F8
        set  7,(ix+127),c       ; 1D03 DD CB 7F F9
        set  7,(ix+127),d       ; 1D07 DD CB 7F FA
        set  7,(ix+127),e       ; 1D0B DD CB 7F FB
        set  7,(ix+127),h       ; 1D0F DD CB 7F FC
        set  7,(ix+127),l       ; 1D13 DD CB 7F FD
        set  7,(iy)             ; 1D17 FD CB 00 FE
        set  7,(iy),a           ; 1D1B FD CB 00 FF
        set  7,(iy),b           ; 1D1F FD CB 00 F8
        set  7,(iy),c           ; 1D23 FD CB 00 F9
        set  7,(iy),d           ; 1D27 FD CB 00 FA
        set  7,(iy),e           ; 1D2B FD CB 00 FB
        set  7,(iy),h           ; 1D2F FD CB 00 FC
        set  7,(iy),l           ; 1D33 FD CB 00 FD
        set  7,(iy+127)         ; 1D37 FD CB 7F FE
        set  7,(iy+127),a       ; 1D3B FD CB 7F FF
        set  7,(iy+127),b       ; 1D3F FD CB 7F F8
        set  7,(iy+127),c       ; 1D43 FD CB 7F F9
        set  7,(iy+127),d       ; 1D47 FD CB 7F FA
        set  7,(iy+127),e       ; 1D4B FD CB 7F FB
        set  7,(iy+127),h       ; 1D4F FD CB 7F FC
        set  7,(iy+127),l       ; 1D53 FD CB 7F FD
        set  7,(iy+127)         ; 1D57 FD CB 7F FE
        set  7,(iy+127),a       ; 1D5B FD CB 7F FF
        set  7,(iy+127),b       ; 1D5F FD CB 7F F8
        set  7,(iy+127),c       ; 1D63 FD CB 7F F9
        set  7,(iy+127),d       ; 1D67 FD CB 7F FA
        set  7,(iy+127),e       ; 1D6B FD CB 7F FB
        set  7,(iy+127),h       ; 1D6F FD CB 7F FC
        set  7,(iy+127),l       ; 1D73 FD CB 7F FD
        set  7,a                ; 1D77 CB FF
        set  7,b                ; 1D79 CB F8
        set  7,c                ; 1D7B CB F9
        set  7,d                ; 1D7D CB FA
        set  7,e                ; 1D7F CB FB
        set  7,h                ; 1D81 CB FC
        set  7,l                ; 1D83 CB FD
        sla  (hl)               ; 1D85 CB 26
        SLA  (HL)               ; 1D87 CB 26
        sla  (ix)               ; 1D89 DD CB 00 26
        sla  (ix),a             ; 1D8D DD CB 00 27
        sla  (ix),b             ; 1D91 DD CB 00 20
        sla  (ix),c             ; 1D95 DD CB 00 21
        sla  (ix),d             ; 1D99 DD CB 00 22
        sla  (ix),e             ; 1D9D DD CB 00 23
        sla  (ix),h             ; 1DA1 DD CB 00 24
        sla  (ix),l             ; 1DA5 DD CB 00 25
        sla  (ix+127)           ; 1DA9 DD CB 7F 26
        sla  (ix+127),a         ; 1DAD DD CB 7F 27
        sla  (ix+127),b         ; 1DB1 DD CB 7F 20
        sla  (ix+127),c         ; 1DB5 DD CB 7F 21
        sla  (ix+127),d         ; 1DB9 DD CB 7F 22
        sla  (ix+127),e         ; 1DBD DD CB 7F 23
        sla  (ix+127),h         ; 1DC1 DD CB 7F 24
        sla  (ix+127),l         ; 1DC5 DD CB 7F 25
        sla  (ix+127)           ; 1DC9 DD CB 7F 26
        sla  (ix+127),a         ; 1DCD DD CB 7F 27
        sla  (ix+127),b         ; 1DD1 DD CB 7F 20
        sla  (ix+127),c         ; 1DD5 DD CB 7F 21
        sla  (ix+127),d         ; 1DD9 DD CB 7F 22
        sla  (ix+127),e         ; 1DDD DD CB 7F 23
        sla  (ix+127),h         ; 1DE1 DD CB 7F 24
        sla  (ix+127),l         ; 1DE5 DD CB 7F 25
        sla  (iy)               ; 1DE9 FD CB 00 26
        sla  (iy),a             ; 1DED FD CB 00 27
        sla  (iy),b             ; 1DF1 FD CB 00 20
        sla  (iy),c             ; 1DF5 FD CB 00 21
        sla  (iy),d             ; 1DF9 FD CB 00 22
        sla  (iy),e             ; 1DFD FD CB 00 23
        sla  (iy),h             ; 1E01 FD CB 00 24
        sla  (iy),l             ; 1E05 FD CB 00 25
        sla  (iy+127)           ; 1E09 FD CB 7F 26
        sla  (iy+127),a         ; 1E0D FD CB 7F 27
        sla  (iy+127),b         ; 1E11 FD CB 7F 20
        sla  (iy+127),c         ; 1E15 FD CB 7F 21
        sla  (iy+127),d         ; 1E19 FD CB 7F 22
        sla  (iy+127),e         ; 1E1D FD CB 7F 23
        sla  (iy+127),h         ; 1E21 FD CB 7F 24
        sla  (iy+127),l         ; 1E25 FD CB 7F 25
        sla  (iy+127)           ; 1E29 FD CB 7F 26
        sla  (iy+127),a         ; 1E2D FD CB 7F 27
        sla  (iy+127),b         ; 1E31 FD CB 7F 20
        sla  (iy+127),c         ; 1E35 FD CB 7F 21
        sla  (iy+127),d         ; 1E39 FD CB 7F 22
        sla  (iy+127),e         ; 1E3D FD CB 7F 23
        sla  (iy+127),h         ; 1E41 FD CB 7F 24
        sla  (iy+127),l         ; 1E45 FD CB 7F 25
        sla  a                  ; 1E49 CB 27
        sla  b                  ; 1E4B CB 20
        sla  bc                 ; 1E4D CB 21 CB 10
        sla  c                  ; 1E51 CB 21
        sla  d                  ; 1E53 CB 22
        sla  de                 ; 1E55 CB 23 CB 12
        sla  e                  ; 1E59 CB 23
        sla  h                  ; 1E5B CB 24
        sla  hl                 ; 1E5D 29
        sla  l                  ; 1E5E CB 25
        sli  (hl)               ; 1E60 CB 36
        SLI  (HL)               ; 1E62 CB 36
        sli  (ix)               ; 1E64 DD CB 00 36
        sli  (ix),a             ; 1E68 DD CB 00 37
        sli  (ix),b             ; 1E6C DD CB 00 30
        sli  (ix),c             ; 1E70 DD CB 00 31
        sli  (ix),d             ; 1E74 DD CB 00 32
        sli  (ix),e             ; 1E78 DD CB 00 33
        sli  (ix),h             ; 1E7C DD CB 00 34
        sli  (ix),l             ; 1E80 DD CB 00 35
        sli  (ix+127)           ; 1E84 DD CB 7F 36
        sli  (ix+127),a         ; 1E88 DD CB 7F 37
        sli  (ix+127),b         ; 1E8C DD CB 7F 30
        sli  (ix+127),c         ; 1E90 DD CB 7F 31
        sli  (ix+127),d         ; 1E94 DD CB 7F 32
        sli  (ix+127),e         ; 1E98 DD CB 7F 33
        sli  (ix+127),h         ; 1E9C DD CB 7F 34
        sli  (ix+127),l         ; 1EA0 DD CB 7F 35
        sli  (ix+127)           ; 1EA4 DD CB 7F 36
        sli  (ix+127),a         ; 1EA8 DD CB 7F 37
        sli  (ix+127),b         ; 1EAC DD CB 7F 30
        sli  (ix+127),c         ; 1EB0 DD CB 7F 31
        sli  (ix+127),d         ; 1EB4 DD CB 7F 32
        sli  (ix+127),e         ; 1EB8 DD CB 7F 33
        sli  (ix+127),h         ; 1EBC DD CB 7F 34
        sli  (ix+127),l         ; 1EC0 DD CB 7F 35
        sli  (iy)               ; 1EC4 FD CB 00 36
        sli  (iy),a             ; 1EC8 FD CB 00 37
        sli  (iy),b             ; 1ECC FD CB 00 30
        sli  (iy),c             ; 1ED0 FD CB 00 31
        sli  (iy),d             ; 1ED4 FD CB 00 32
        sli  (iy),e             ; 1ED8 FD CB 00 33
        sli  (iy),h             ; 1EDC FD CB 00 34
        sli  (iy),l             ; 1EE0 FD CB 00 35
        sli  (iy+127)           ; 1EE4 FD CB 7F 36
        sli  (iy+127),a         ; 1EE8 FD CB 7F 37
        sli  (iy+127),b         ; 1EEC FD CB 7F 30
        sli  (iy+127),c         ; 1EF0 FD CB 7F 31
        sli  (iy+127),d         ; 1EF4 FD CB 7F 32
        sli  (iy+127),e         ; 1EF8 FD CB 7F 33
        sli  (iy+127),h         ; 1EFC FD CB 7F 34
        sli  (iy+127),l         ; 1F00 FD CB 7F 35
        sli  (iy+127)           ; 1F04 FD CB 7F 36
        sli  (iy+127),a         ; 1F08 FD CB 7F 37
        sli  (iy+127),b         ; 1F0C FD CB 7F 30
        sli  (iy+127),c         ; 1F10 FD CB 7F 31
        sli  (iy+127),d         ; 1F14 FD CB 7F 32
        sli  (iy+127),e         ; 1F18 FD CB 7F 33
        sli  (iy+127),h         ; 1F1C FD CB 7F 34
        sli  (iy+127),l         ; 1F20 FD CB 7F 35
        sli  a                  ; 1F24 CB 37
        sli  b                  ; 1F26 CB 30
        sli  bc                 ; 1F28 CB 31 CB 10
        sli  c                  ; 1F2C CB 31
        sli  d                  ; 1F2E CB 32
        sli  de                 ; 1F30 CB 33 CB 12
        sli  e                  ; 1F34 CB 33
        sli  h                  ; 1F36 CB 34
        sli  hl                 ; 1F38 CB 35 CB 14
        sli  l                  ; 1F3C CB 35
        sll  (hl)               ; 1F3E CB 36
        SLL  (HL)               ; 1F40 CB 36
        sll  (ix)               ; 1F42 DD CB 00 36
        sll  (ix),a             ; 1F46 DD CB 00 37
        sll  (ix),b             ; 1F4A DD CB 00 30
        sll  (ix),c             ; 1F4E DD CB 00 31
        sll  (ix),d             ; 1F52 DD CB 00 32
        sll  (ix),e             ; 1F56 DD CB 00 33
        sll  (ix),h             ; 1F5A DD CB 00 34
        sll  (ix),l             ; 1F5E DD CB 00 35
        sll  (ix+127)           ; 1F62 DD CB 7F 36
        sll  (ix+127),a         ; 1F66 DD CB 7F 37
        sll  (ix+127),b         ; 1F6A DD CB 7F 30
        sll  (ix+127),c         ; 1F6E DD CB 7F 31
        sll  (ix+127),d         ; 1F72 DD CB 7F 32
        sll  (ix+127),e         ; 1F76 DD CB 7F 33
        sll  (ix+127),h         ; 1F7A DD CB 7F 34
        sll  (ix+127),l         ; 1F7E DD CB 7F 35
        sll  (ix+127)           ; 1F82 DD CB 7F 36
        sll  (ix+127),a         ; 1F86 DD CB 7F 37
        sll  (ix+127),b         ; 1F8A DD CB 7F 30
        sll  (ix+127),c         ; 1F8E DD CB 7F 31
        sll  (ix+127),d         ; 1F92 DD CB 7F 32
        sll  (ix+127),e         ; 1F96 DD CB 7F 33
        sll  (ix+127),h         ; 1F9A DD CB 7F 34
        sll  (ix+127),l         ; 1F9E DD CB 7F 35
        sll  (iy)               ; 1FA2 FD CB 00 36
        sll  (iy),a             ; 1FA6 FD CB 00 37
        sll  (iy),b             ; 1FAA FD CB 00 30
        sll  (iy),c             ; 1FAE FD CB 00 31
        sll  (iy),d             ; 1FB2 FD CB 00 32
        sll  (iy),e             ; 1FB6 FD CB 00 33
        sll  (iy),h             ; 1FBA FD CB 00 34
        sll  (iy),l             ; 1FBE FD CB 00 35
        sll  (iy+127)           ; 1FC2 FD CB 7F 36
        sll  (iy+127),a         ; 1FC6 FD CB 7F 37
        sll  (iy+127),b         ; 1FCA FD CB 7F 30
        sll  (iy+127),c         ; 1FCE FD CB 7F 31
        sll  (iy+127),d         ; 1FD2 FD CB 7F 32
        sll  (iy+127),e         ; 1FD6 FD CB 7F 33
        sll  (iy+127),h         ; 1FDA FD CB 7F 34
        sll  (iy+127),l         ; 1FDE FD CB 7F 35
        sll  (iy+127)           ; 1FE2 FD CB 7F 36
        sll  (iy+127),a         ; 1FE6 FD CB 7F 37
        sll  (iy+127),b         ; 1FEA FD CB 7F 30
        sll  (iy+127),c         ; 1FEE FD CB 7F 31
        sll  (iy+127),d         ; 1FF2 FD CB 7F 32
        sll  (iy+127),e         ; 1FF6 FD CB 7F 33
        sll  (iy+127),h         ; 1FFA FD CB 7F 34
        sll  (iy+127),l         ; 1FFE FD CB 7F 35
        sll  a                  ; 2002 CB 37
        sll  b                  ; 2004 CB 30
        sll  bc                 ; 2006 CB 31 CB 10
        sll  c                  ; 200A CB 31
        sll  d                  ; 200C CB 32
        sll  de                 ; 200E CB 33 CB 12
        sll  e                  ; 2012 CB 33
        sll  h                  ; 2014 CB 34
        sll  hl                 ; 2016 CB 35 CB 14
        sll  l                  ; 201A CB 35
        sra  (hl)               ; 201C CB 2E
        SRA  (HL)               ; 201E CB 2E
        sra  (ix)               ; 2020 DD CB 00 2E
        sra  (ix),a             ; 2024 DD CB 00 2F
        sra  (ix),b             ; 2028 DD CB 00 28
        sra  (ix),c             ; 202C DD CB 00 29
        sra  (ix),d             ; 2030 DD CB 00 2A
        sra  (ix),e             ; 2034 DD CB 00 2B
        sra  (ix),h             ; 2038 DD CB 00 2C
        sra  (ix),l             ; 203C DD CB 00 2D
        sra  (ix+127)           ; 2040 DD CB 7F 2E
        sra  (ix+127),a         ; 2044 DD CB 7F 2F
        sra  (ix+127),b         ; 2048 DD CB 7F 28
        sra  (ix+127),c         ; 204C DD CB 7F 29
        sra  (ix+127),d         ; 2050 DD CB 7F 2A
        sra  (ix+127),e         ; 2054 DD CB 7F 2B
        sra  (ix+127),h         ; 2058 DD CB 7F 2C
        sra  (ix+127),l         ; 205C DD CB 7F 2D
        sra  (ix+127)           ; 2060 DD CB 7F 2E
        sra  (ix+127),a         ; 2064 DD CB 7F 2F
        sra  (ix+127),b         ; 2068 DD CB 7F 28
        sra  (ix+127),c         ; 206C DD CB 7F 29
        sra  (ix+127),d         ; 2070 DD CB 7F 2A
        sra  (ix+127),e         ; 2074 DD CB 7F 2B
        sra  (ix+127),h         ; 2078 DD CB 7F 2C
        sra  (ix+127),l         ; 207C DD CB 7F 2D
        sra  (iy)               ; 2080 FD CB 00 2E
        sra  (iy),a             ; 2084 FD CB 00 2F
        sra  (iy),b             ; 2088 FD CB 00 28
        sra  (iy),c             ; 208C FD CB 00 29
        sra  (iy),d             ; 2090 FD CB 00 2A
        sra  (iy),e             ; 2094 FD CB 00 2B
        sra  (iy),h             ; 2098 FD CB 00 2C
        sra  (iy),l             ; 209C FD CB 00 2D
        sra  (iy+127)           ; 20A0 FD CB 7F 2E
        sra  (iy+127),a         ; 20A4 FD CB 7F 2F
        sra  (iy+127),b         ; 20A8 FD CB 7F 28
        sra  (iy+127),c         ; 20AC FD CB 7F 29
        sra  (iy+127),d         ; 20B0 FD CB 7F 2A
        sra  (iy+127),e         ; 20B4 FD CB 7F 2B
        sra  (iy+127),h         ; 20B8 FD CB 7F 2C
        sra  (iy+127),l         ; 20BC FD CB 7F 2D
        sra  (iy+127)           ; 20C0 FD CB 7F 2E
        sra  (iy+127),a         ; 20C4 FD CB 7F 2F
        sra  (iy+127),b         ; 20C8 FD CB 7F 28
        sra  (iy+127),c         ; 20CC FD CB 7F 29
        sra  (iy+127),d         ; 20D0 FD CB 7F 2A
        sra  (iy+127),e         ; 20D4 FD CB 7F 2B
        sra  (iy+127),h         ; 20D8 FD CB 7F 2C
        sra  (iy+127),l         ; 20DC FD CB 7F 2D
        sra  a                  ; 20E0 CB 2F
        sra  b                  ; 20E2 CB 28
        sra  bc                 ; 20E4 CB 28 CB 19
        sra  c                  ; 20E8 CB 29
        sra  d                  ; 20EA CB 2A
        sra  de                 ; 20EC CB 2A CB 1B
        sra  e                  ; 20F0 CB 2B
        sra  h                  ; 20F2 CB 2C
        sra  hl                 ; 20F4 CB 2C CB 1D
        sra  l                  ; 20F8 CB 2D
        srl  (hl)               ; 20FA CB 3E
        SRL  (HL)               ; 20FC CB 3E
        srl  (ix)               ; 20FE DD CB 00 3E
        srl  (ix),a             ; 2102 DD CB 00 3F
        srl  (ix),b             ; 2106 DD CB 00 38
        srl  (ix),c             ; 210A DD CB 00 39
        srl  (ix),d             ; 210E DD CB 00 3A
        srl  (ix),e             ; 2112 DD CB 00 3B
        srl  (ix),h             ; 2116 DD CB 00 3C
        srl  (ix),l             ; 211A DD CB 00 3D
        srl  (ix+127)           ; 211E DD CB 7F 3E
        srl  (ix+127),a         ; 2122 DD CB 7F 3F
        srl  (ix+127),b         ; 2126 DD CB 7F 38
        srl  (ix+127),c         ; 212A DD CB 7F 39
        srl  (ix+127),d         ; 212E DD CB 7F 3A
        srl  (ix+127),e         ; 2132 DD CB 7F 3B
        srl  (ix+127),h         ; 2136 DD CB 7F 3C
        srl  (ix+127),l         ; 213A DD CB 7F 3D
        srl  (ix+127)           ; 213E DD CB 7F 3E
        srl  (ix+127),a         ; 2142 DD CB 7F 3F
        srl  (ix+127),b         ; 2146 DD CB 7F 38
        srl  (ix+127),c         ; 214A DD CB 7F 39
        srl  (ix+127),d         ; 214E DD CB 7F 3A
        srl  (ix+127),e         ; 2152 DD CB 7F 3B
        srl  (ix+127),h         ; 2156 DD CB 7F 3C
        srl  (ix+127),l         ; 215A DD CB 7F 3D
        srl  (iy)               ; 215E FD CB 00 3E
        srl  (iy),a             ; 2162 FD CB 00 3F
        srl  (iy),b             ; 2166 FD CB 00 38
        srl  (iy),c             ; 216A FD CB 00 39
        srl  (iy),d             ; 216E FD CB 00 3A
        srl  (iy),e             ; 2172 FD CB 00 3B
        srl  (iy),h             ; 2176 FD CB 00 3C
        srl  (iy),l             ; 217A FD CB 00 3D
        srl  (iy+127)           ; 217E FD CB 7F 3E
        srl  (iy+127),a         ; 2182 FD CB 7F 3F
        srl  (iy+127),b         ; 2186 FD CB 7F 38
        srl  (iy+127),c         ; 218A FD CB 7F 39
        srl  (iy+127),d         ; 218E FD CB 7F 3A
        srl  (iy+127),e         ; 2192 FD CB 7F 3B
        srl  (iy+127),h         ; 2196 FD CB 7F 3C
        srl  (iy+127),l         ; 219A FD CB 7F 3D
        srl  (iy+127)           ; 219E FD CB 7F 3E
        srl  (iy+127),a         ; 21A2 FD CB 7F 3F
        srl  (iy+127),b         ; 21A6 FD CB 7F 38
        srl  (iy+127),c         ; 21AA FD CB 7F 39
        srl  (iy+127),d         ; 21AE FD CB 7F 3A
        srl  (iy+127),e         ; 21B2 FD CB 7F 3B
        srl  (iy+127),h         ; 21B6 FD CB 7F 3C
        srl  (iy+127),l         ; 21BA FD CB 7F 3D
        srl  a                  ; 21BE CB 3F
        srl  b                  ; 21C0 CB 38
        srl  bc                 ; 21C2 CB 38 CB 19
        srl  c                  ; 21C6 CB 39
        srl  d                  ; 21C8 CB 3A
        srl  de                 ; 21CA CB 3A CB 1B
        srl  e                  ; 21CE CB 3B
        srl  h                  ; 21D0 CB 3C
        srl  hl                 ; 21D2 CB 3C CB 1D
        srl  l                  ; 21D6 CB 3D
        stop                    ; 21D8 DD DD 00
        STOP                    ; 21DB DD DD 00
        sub  (hl)               ; 21DE 96
        SUB  (HL)               ; 21DF 96
        sub  (ix)               ; 21E0 DD 96 00
        sub  (ix+127)           ; 21E3 DD 96 7F
        sub  (ix+127)           ; 21E6 DD 96 7F
        sub  (iy)               ; 21E9 FD 96 00
        sub  (iy+127)           ; 21EC FD 96 7F
        sub  (iy+127)           ; 21EF FD 96 7F
        sub  255                ; 21F2 D6 FF
        sub  a                  ; 21F4 97
        sub  b                  ; 21F5 90
        sub  c                  ; 21F6 91
        sub  d                  ; 21F7 92
        sub  e                  ; 21F8 93
        sub  h                  ; 21F9 94
        sub  hl,bc              ; 21FA B7 ED 42
        sub  hl,de              ; 21FD B7 ED 52
        sub  hl,hl              ; 2200 B7 ED 62
        sub  hl,sp              ; 2203 B7 ED 72
        sub  ixh                ; 2206 DD 94
        sub  ixl                ; 2208 DD 95
        sub  iyh                ; 220A FD 94
        sub  iyl                ; 220C FD 95
        sub  l                  ; 220E 95
        xor  (hl)               ; 220F AE
        XOR  (HL)               ; 2210 AE
        xor  (ix)               ; 2211 DD AE 00
        xor  (ix+127)           ; 2214 DD AE 7F
        xor  (ix+127)           ; 2217 DD AE 7F
        xor  (iy)               ; 221A FD AE 00
        xor  (iy+127)           ; 221D FD AE 7F
        xor  (iy+127)           ; 2220 FD AE 7F
        xor  255                ; 2223 EE FF
        xor  a                  ; 2225 AF
        xor  b                  ; 2226 A8
        xor  c                  ; 2227 A9
        xor  d                  ; 2228 AA
        xor  e                  ; 2229 AB
        xor  h                  ; 222A AC
        xor  ixh                ; 222B DD AC
        xor  ixl                ; 222D DD AD
        xor  iyh                ; 222F FD AC
        xor  iyl                ; 2231 FD AD
        xor  l                  ; 2233 AD
