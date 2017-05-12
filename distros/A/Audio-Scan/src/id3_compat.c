/* C code produced by gperf version 3.0.4 */
/* Command-line: gperf -tCcTonDE -K id -N _id3_compat_lookup -s -3 -k '*' id3_compat.gperf  */

#if !((' ' == 32) && ('!' == 33) && ('"' == 34) && ('#' == 35) \
      && ('%' == 37) && ('&' == 38) && ('\'' == 39) && ('(' == 40) \
      && (')' == 41) && ('*' == 42) && ('+' == 43) && (',' == 44) \
      && ('-' == 45) && ('.' == 46) && ('/' == 47) && ('0' == 48) \
      && ('1' == 49) && ('2' == 50) && ('3' == 51) && ('4' == 52) \
      && ('5' == 53) && ('6' == 54) && ('7' == 55) && ('8' == 56) \
      && ('9' == 57) && (':' == 58) && (';' == 59) && ('<' == 60) \
      && ('=' == 61) && ('>' == 62) && ('?' == 63) && ('A' == 65) \
      && ('B' == 66) && ('C' == 67) && ('D' == 68) && ('E' == 69) \
      && ('F' == 70) && ('G' == 71) && ('H' == 72) && ('I' == 73) \
      && ('J' == 74) && ('K' == 75) && ('L' == 76) && ('M' == 77) \
      && ('N' == 78) && ('O' == 79) && ('P' == 80) && ('Q' == 81) \
      && ('R' == 82) && ('S' == 83) && ('T' == 84) && ('U' == 85) \
      && ('V' == 86) && ('W' == 87) && ('X' == 88) && ('Y' == 89) \
      && ('Z' == 90) && ('[' == 91) && ('\\' == 92) && (']' == 93) \
      && ('^' == 94) && ('_' == 95) && ('a' == 97) && ('b' == 98) \
      && ('c' == 99) && ('d' == 100) && ('e' == 101) && ('f' == 102) \
      && ('g' == 103) && ('h' == 104) && ('i' == 105) && ('j' == 106) \
      && ('k' == 107) && ('l' == 108) && ('m' == 109) && ('n' == 110) \
      && ('o' == 111) && ('p' == 112) && ('q' == 113) && ('r' == 114) \
      && ('s' == 115) && ('t' == 116) && ('u' == 117) && ('v' == 118) \
      && ('w' == 119) && ('x' == 120) && ('y' == 121) && ('z' == 122) \
      && ('{' == 123) && ('|' == 124) && ('}' == 125) && ('~' == 126))
/* The character set is not based on ISO-646.  */
error "gperf generated tables don't work with this execution character set. Please report a bug to <bug-gnu-gperf@gnu.org>."
#endif

#line 1 "id3_compat.gperf"

/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Id$
 */

#define EQ(id)    #id
#define OBSOLETE    0
#define TX(id)    #id

/* maximum key range = 130, duplicates = 0 */

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
static unsigned int
compat_hash (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char asso_values[] =
    {
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131,  89,
       54,  64,  94, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131,   3,  58,   9,  18,  18,
       57,   1,   4,  21,  59,  52,  11,   0,  47,  26,
       10,  10,  25,  20,   5,  12,  32,   0,  25,  15,
       25, 131,  37,  37, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131,
      131, 131, 131, 131, 131, 131, 131, 131, 131, 131
    };
  register int hval = 0;

  switch (len)
    {
      default:
        hval += asso_values[(unsigned char)str[3]];
      /*FALLTHROUGH*/
      case 3:
        hval += asso_values[(unsigned char)str[2]];
      /*FALLTHROUGH*/
      case 2:
        hval += asso_values[(unsigned char)str[1]+4];
      /*FALLTHROUGH*/
      case 1:
        hval += asso_values[(unsigned char)str[0]];
        break;
    }
  return hval;
}

#ifdef __GNUC__
__inline
#if defined __GNUC_STDC_INLINE__ || defined __GNUC_GNU_INLINE__
__attribute__ ((__gnu_inline__))
#endif
#endif
const id3_compat *
_id3_compat_lookup (str, len)
     register const char *str;
     register unsigned int len;
{
  enum
    {
      TOTAL_KEYWORDS = 79,
      MIN_WORD_LENGTH = 3,
      MAX_WORD_LENGTH = 4,
      MIN_HASH_VALUE = 1,
      MAX_HASH_VALUE = 130
    };

  static const id3_compat wordlist[] =
    {
#line 107 "id3_compat.gperf"
      {"WCM",  EQ(WCOM)  /* Commercial information */},
#line 70 "id3_compat.gperf"
      {"TIM",  EQ(TIME)  /* Time [obsolete] */},
#line 61 "id3_compat.gperf"
      {"TCM",  EQ(TCOM)  /* Composer */},
#line 113 "id3_compat.gperf"
      {"TSA",  EQ(TSOA)  /* non-standard iTunes album sort */},
#line 112 "id3_compat.gperf"
      {"TST",  EQ(TSOT)  /* non-standard iTunes track sort */},
#line 108 "id3_compat.gperf"
      {"WCP",  EQ(WCOP)  /* Copyright/legal information */},
#line 65 "id3_compat.gperf"
      {"TDA",  EQ(TDAT)  /* Date [obsolete] */},
#line 86 "id3_compat.gperf"
      {"TPA",  EQ(TPOS)  /* Part of a set */},
#line 116 "id3_compat.gperf"
      {"TSC",  EQ(TSOC), /* non-standard iTunes composer sort */},
#line 114 "id3_compat.gperf"
      {"TSP",  EQ(TSOP)  /* non-standard iTunes artist sort */},
#line 111 "id3_compat.gperf"
      {"TCP",  EQ(TCMP)  /* non-standard iTunes compilation flag */},
#line 66 "id3_compat.gperf"
      {"TDAT", OBSOLETE  /* Date [obsolete] */},
#line 73 "id3_compat.gperf"
      {"TLA",  EQ(TLAN)  /* Language(s) */},
#line 52 "id3_compat.gperf"
      {"PIC",  TX(APIC)  /* Attached picture */},
#line 75 "id3_compat.gperf"
      {"TMT",  EQ(TMED)  /* Media type */},
#line 51 "id3_compat.gperf"
      {"MLL",  EQ(MLLT)  /* MPEG location lookup table */},
#line 50 "id3_compat.gperf"
      {"MCI",  EQ(MCDI)  /* Music CD identifier */},
#line 71 "id3_compat.gperf"
      {"TIME", OBSOLETE  /* Time [obsolete] */},
#line 67 "id3_compat.gperf"
      {"TDY",  EQ(TDLY)  /* Playlist delay */},
#line 94 "id3_compat.gperf"
      {"TSS",  EQ(TSSE)  /* Software/hardware and settings used for encoding */},
#line 92 "id3_compat.gperf"
      {"TSI",  OBSOLETE  /* Size [obsolete] */},
#line 103 "id3_compat.gperf"
      {"ULT",  EQ(USLT)  /* Unsynchronised lyric/text transcription */},
#line 76 "id3_compat.gperf"
      {"TOA",  EQ(TOPE)  /* Original artist(s)/performer(s) */},
#line 40 "id3_compat.gperf"
      {"COM",  EQ(COMM)  /* Comments */},
#line 81 "id3_compat.gperf"
      {"TOT",  EQ(TOAL)  /* Original album/movie/show title */},
#line 64 "id3_compat.gperf"
      {"TCR",  EQ(TCOP)  /* Copyright message */},
#line 62 "id3_compat.gperf"
      {"TCO",  TX(TCON)  /* Content type */},
#line 74 "id3_compat.gperf"
      {"TLE",  EQ(TLEN)  /* Length */},
#line 59 "id3_compat.gperf"
      {"TAL",  EQ(TALB)  /* Album/movie/show title */},
#line 57 "id3_compat.gperf"
      {"SLT",  EQ(SYLT)  /* Synchronised lyric/text */},
#line 78 "id3_compat.gperf"
      {"TOL",  EQ(TOLY)  /* Original lyricist(s)/text writer(s) */},
#line 47 "id3_compat.gperf"
      {"IPL",  EQ(TIPL)  /* Involved people list */},
#line 106 "id3_compat.gperf"
      {"WAS",  EQ(WOAS)  /* Official audio source webpage */},
#line 39 "id3_compat.gperf"
      {"CNT",  EQ(PCNT)  /* Play counter */},
#line 53 "id3_compat.gperf"
      {"POP",  EQ(POPM)  /* Popularimeter */},
#line 42 "id3_compat.gperf"
      {"CRM",  OBSOLETE  /* Encrypted meta frame [obsolete] */},
#line 43 "id3_compat.gperf"
      {"EQU",  OBSOLETE  /* Equalization [obsolete] */},
#line 105 "id3_compat.gperf"
      {"WAR",  EQ(WOAR)  /* Official artist/performer webpage */},
#line 41 "id3_compat.gperf"
      {"CRA",  EQ(AENC)  /* Audio encryption */},
#line 44 "id3_compat.gperf"
      {"EQUA", OBSOLETE  /* Equalization [obsolete] */},
#line 88 "id3_compat.gperf"
      {"TRC",  EQ(TSRC)  /* ISRC (international standard recording code) */},
#line 98 "id3_compat.gperf"
      {"TXT",  EQ(TEXT)  /* Lyricist/text writer */},
#line 46 "id3_compat.gperf"
      {"GEO",  EQ(GEOB)  /* General encapsulated object */},
#line 72 "id3_compat.gperf"
      {"TKE",  EQ(TKEY)  /* Initial key */},
#line 79 "id3_compat.gperf"
      {"TOR",  EQ(TDOR)  /* Original release year [obsolete] */},
#line 93 "id3_compat.gperf"
      {"TSIZ", OBSOLETE  /* Size [obsolete] */},
#line 45 "id3_compat.gperf"
      {"ETC",  EQ(ETCO)  /* Event timing codes */},
#line 55 "id3_compat.gperf"
      {"RVA",  EQ(RVAD)  /* Relative volume adjustment [obsolete] */},
#line 58 "id3_compat.gperf"
      {"STC",  EQ(SYTC)  /* Synchronised tempo codes */},
#line 89 "id3_compat.gperf"
      {"TRD",  OBSOLETE  /* Recording dates [obsolete] */},
#line 48 "id3_compat.gperf"
      {"IPLS", EQ(TIPL)  /* Involved people list */},
#line 90 "id3_compat.gperf"
      {"TRDA", OBSOLETE  /* Recording dates [obsolete] */},
#line 115 "id3_compat.gperf"
      {"TS2",  EQ(TSO2), /* non-standard iTunes album artist sort */},
#line 100 "id3_compat.gperf"
      {"TYE",  EQ(TYER)  /* Year [obsolete] */},
#line 110 "id3_compat.gperf"
      {"WXX",  EQ(WXXX)  /* User defined URL link frame */},
#line 109 "id3_compat.gperf"
      {"WPB",  EQ(WPUB)  /* Publishers official webpage */},
#line 83 "id3_compat.gperf"
      {"TP2",  EQ(TPE2)  /* Band/orchestra/accompaniment */},
#line 80 "id3_compat.gperf"
      {"TORY", EQ(TDOR)  /* Original release year [obsolete] */},
#line 99 "id3_compat.gperf"
      {"TXX",  EQ(TXXX)  /* User defined text information frame */},
#line 87 "id3_compat.gperf"
      {"TPB",  EQ(TPUB)  /* Publisher */},
#line 69 "id3_compat.gperf"
      {"TFT",  EQ(TFLT)  /* File type */},
#line 56 "id3_compat.gperf"
      {"RVAD", OBSOLETE  /* Relative volume adjustment [obsolete] */},
#line 60 "id3_compat.gperf"
      {"TBP",  EQ(TBPM)  /* BPM (beats per minute) */},
#line 68 "id3_compat.gperf"
      {"TEN",  EQ(TENC)  /* Encoded by */},
#line 84 "id3_compat.gperf"
      {"TP3",  EQ(TPE3)  /* Conductor/performer refinement */},
#line 104 "id3_compat.gperf"
      {"WAF",  EQ(WOAF)  /* Official audio file webpage */},
#line 54 "id3_compat.gperf"
      {"REV",  EQ(RVRB)  /* Reverb */},
#line 63 "id3_compat.gperf"
      {"TCON", TX(TCON)  /* Content type */},
#line 77 "id3_compat.gperf"
      {"TOF",  EQ(TOFN)  /* Original filename */},
#line 96 "id3_compat.gperf"
      {"TT2",  EQ(TIT2)  /* Title/songname/content description */},
#line 101 "id3_compat.gperf"
      {"TYER", OBSOLETE  /* Year [obsolete] */},
#line 49 "id3_compat.gperf"
      {"LNK",  EQ(LINK)  /* Linked information */},
#line 91 "id3_compat.gperf"
      {"TRK",  EQ(TRCK)  /* Track number/position in set */},
#line 102 "id3_compat.gperf"
      {"UFI",  EQ(UFID)  /* Unique file identifier */},
#line 97 "id3_compat.gperf"
      {"TT3",  EQ(TIT3)  /* Subtitle/description refinement */},
#line 82 "id3_compat.gperf"
      {"TP1",  EQ(TPE1)  /* Lead performer(s)/soloist(s) */},
#line 85 "id3_compat.gperf"
      {"TP4",  EQ(TPE4)  /* Interpreted, remixed, or otherwise modified by */},
#line 95 "id3_compat.gperf"
      {"TT1",  EQ(TIT1)  /* Content group description */},
#line 38 "id3_compat.gperf"
      {"BUF",  EQ(RBUF)  /* Recommended buffer size */}
    };

  static const short lookup[] =
    {
      -1,  0, -1, -1, -1,  1,  2, -1,  3, -1,  4,  5,  6,  7,
       8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
      22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
      36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
      -1, 50, 51, 52, 53, -1, 54, 55, 56, 57, -1, 58, 59, 60,
      -1, 61, 62, 63, 64, 65, -1, -1, 66, 67, -1, -1, 68, -1,
      69, 70, -1, -1, 71, 72, -1, -1, 73, -1, 74, -1, -1, -1,
      -1, 75, -1, -1, -1, -1, 76, -1, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1, -1, -1, 77, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, 78
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = compat_hash (str, len);

      if (key <= MAX_HASH_VALUE && key >= 0)
        {
          register int index = lookup[key];

          if (index >= 0)
            {
              register const char *s = wordlist[index].id;

              if (*str == *s && !strncmp (str + 1, s + 1, len - 1) && s[len] == '\0')
                return &wordlist[index];
            }
        }
    }
  return 0;
}
#line 117 "id3_compat.gperf"

