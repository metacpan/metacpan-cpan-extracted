/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: gperf -tCcTonDE -K id -N _id3_frametype_lookup -s -3 -k '*' id3_frametype.gperf  */

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
#error "gperf generated tables don't work with this execution character set. Please report a bug to <bug-gperf@gnu.org>."
#endif

#line 1 "id3_frametype.gperf"

/*
 * libid3tag - ID3 tag manipulation library
 * Copyright (C) 2000-2004 Underbit Technologies, Inc.
 *
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

#define FIELDS(id)  static enum id3_field_type const fields_##id[]

/* frame field descriptions */

FIELDS(UFID) = {
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(TXXX) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_STRING
};

FIELDS(WXXX) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_LATIN1
};

FIELDS(MCDI) = {
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(ETCO) = {
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(MLLT) = {
  ID3_FIELD_TYPE_INT16,
  ID3_FIELD_TYPE_INT24,
  ID3_FIELD_TYPE_INT24,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(SYTC) = {
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(USLT) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_LANGUAGE,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_STRINGFULL
};

FIELDS(SYLT) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_LANGUAGE,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(COMM) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_LANGUAGE,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_STRINGFULL
};

FIELDS(RVA2) = {
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(EQU2) = {
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(RVRB) = {
  ID3_FIELD_TYPE_INT16,
  ID3_FIELD_TYPE_INT16,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT8
};

FIELDS(APIC) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(GEOB) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(PCNT) = {
  ID3_FIELD_TYPE_INT32PLUS
};

FIELDS(POPM) = {
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT32PLUS
};

FIELDS(RBUF) = {
  ID3_FIELD_TYPE_INT24,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT32
};

FIELDS(AENC) = {
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_INT16,
  ID3_FIELD_TYPE_INT16,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(LINK) = {
  ID3_FIELD_TYPE_FRAMEID,
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_LATIN1LIST
};

FIELDS(POSS) = {
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(USER) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_LANGUAGE,
  ID3_FIELD_TYPE_STRING
};

FIELDS(OWNE) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_DATE,
  ID3_FIELD_TYPE_STRING
};

FIELDS(COMR) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_DATE,
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(ENCR) = {
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(GRID) = {
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(PRIV) = {
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(SIGN) = {
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(SEEK) = {
  ID3_FIELD_TYPE_INT32
};

FIELDS(ASPI) = {
  ID3_FIELD_TYPE_INT32,
  ID3_FIELD_TYPE_INT32,
  ID3_FIELD_TYPE_INT16,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(text) = {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_STRINGLIST
};

FIELDS(url) = {
  ID3_FIELD_TYPE_LATIN1
};

FIELDS(unknown) = {
  ID3_FIELD_TYPE_BINARYDATA
};

FIELDS(ZOBS) = {
  ID3_FIELD_TYPE_FRAMEID,
  ID3_FIELD_TYPE_BINARYDATA
};

#define FRAME(id)  \
  sizeof(fields_##id) / sizeof(fields_##id[0]), fields_##id

#define FRAMETYPE(type, id, desc)  \
  id3_frametype const id3_frametype_##type = {  \
    0, FRAME(id), desc  \
  }

/* static frame types */

FRAMETYPE(text,         text,     "Unknown text information frame");
FRAMETYPE(url,          url,      "Unknown URL link frame");
FRAMETYPE(experimental, unknown,  "Experimental frame");
FRAMETYPE(unknown,      unknown,  "Unknown frame");
FRAMETYPE(obsolete,     unknown,  "Obsolete frame");
/* maximum key range = 171, duplicates = 0 */

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
static unsigned int
frametype_hash (register const char *str, register size_t len)
{
  static const unsigned char asso_values[] =
    {
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
       69,   4,  13,  47, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178,  31,  63,   3,  15,   3,
       24,  25,  10,  52,  74,   5,  23,  30,   1,   5,
       10,  62,  20,   0,  28,  28,  22,  19,  25,  62,
       10, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178, 178, 178, 178,
      178, 178, 178, 178, 178, 178, 178
    };
  return asso_values[(unsigned char)str[3]+1] + asso_values[(unsigned char)str[2]] + asso_values[(unsigned char)str[1]] + asso_values[(unsigned char)str[0]];
}

const struct id3_frametype *
_id3_frametype_lookup (register const char *str, register size_t len)
{
  enum
    {
      TOTAL_KEYWORDS = 86,
      MIN_WORD_LENGTH = 4,
      MAX_WORD_LENGTH = 4,
      MIN_HASH_VALUE = 7,
      MAX_HASH_VALUE = 177
    };

  static const struct id3_frametype wordlist[] =
    {
#line 268 "id3_frametype.gperf"
      {"ENCR", FRAME(ENCR), "Encryption method registration"},
#line 278 "id3_frametype.gperf"
      {"POPM", FRAME(POPM), "Popularimeter"},
#line 337 "id3_frametype.gperf"
      {"WCOM", FRAME(url),  "Commercial information"},
#line 284 "id3_frametype.gperf"
      {"SEEK", FRAME(SEEK), "Seek frame"},
#line 335 "id3_frametype.gperf"
      {"USER", FRAME(USER), "Terms of use"},
#line 271 "id3_frametype.gperf"
      {"GEOB", FRAME(GEOB), "General encapsulated object"},
#line 290 "id3_frametype.gperf"
      {"TCOM", FRAME(text), "Composer"},
#line 267 "id3_frametype.gperf"
      {"COMR", FRAME(COMR), "Commercial frame"},
#line 266 "id3_frametype.gperf"
      {"COMM", FRAME(COMM), "Comments"},
#line 291 "id3_frametype.gperf"
      {"TCON", FRAME(text), "Content type"},
#line 277 "id3_frametype.gperf"
      {"PCNT", FRAME(PCNT), "Play counter"},
#line 279 "id3_frametype.gperf"
      {"POSS", FRAME(POSS), "Position synchronisation frame"},
#line 270 "id3_frametype.gperf"
      {"ETCO", FRAME(ETCO), "Event timing codes"},
#line 318 "id3_frametype.gperf"
      {"TPE2", FRAME(text), "Band/orchestra/accompaniment"},
#line 306 "id3_frametype.gperf"
      {"TKEY", FRAME(text), "Initial key"},
#line 299 "id3_frametype.gperf"
      {"TENC", FRAME(text), "Encoded by"},
#line 295 "id3_frametype.gperf"
      {"TDOR", FRAME(text), "Original release time"},
#line 276 "id3_frametype.gperf"
      {"OWNE", FRAME(OWNE), "Ownership frame"},
#line 263 "id3_frametype.gperf"
      {"AENC", FRAME(AENC), "Audio encryption"},
#line 293 "id3_frametype.gperf"
      {"TDEN", FRAME(text), "Encoding time"},
#line 331 "id3_frametype.gperf"
      {"TSSE", FRAME(text), "Software/hardware and settings used for encoding"},
#line 325 "id3_frametype.gperf"
      {"TRSN", FRAME(text), "Internet radio station name"},
#line 319 "id3_frametype.gperf"
      {"TPE3", FRAME(text), "Conductor/performer refinement"},
#line 340 "id3_frametype.gperf"
      {"WOAR", FRAME(url),  "Official artist/performer webpage"},
#line 332 "id3_frametype.gperf"
      {"TSST", FRAME(text), "Set subtitle"},
#line 316 "id3_frametype.gperf"
      {"TOWN", FRAME(text), "File owner/licensee"},
#line 326 "id3_frametype.gperf"
      {"TRSO", FRAME(text), "Internet radio station owner"},
#line 308 "id3_frametype.gperf"
      {"TLEN", FRAME(text), "Length"},
#line 344 "id3_frametype.gperf"
      {"WPUB", FRAME(url),  "Publishers official webpage"},
#line 329 "id3_frametype.gperf"
      {"TSOT", FRAME(text), "Title sort order"},
#line 313 "id3_frametype.gperf"
      {"TOFN", FRAME(text), "Original filename"},
#line 330 "id3_frametype.gperf"
      {"TSRC", FRAME(text), "ISRC (international standard recording code)"},
#line 310 "id3_frametype.gperf"
      {"TMED", FRAME(text), "Media type"},
#line 283 "id3_frametype.gperf"
      {"RVRB", FRAME(RVRB), "Reverb"},
#line 314 "id3_frametype.gperf"
      {"TOLY", FRAME(text), "Original lyricist(s)/text writer(s)"},
#line 315 "id3_frametype.gperf"
      {"TOPE", FRAME(text), "Original artist(s)/performer(s)"},
#line 322 "id3_frametype.gperf"
      {"TPRO", FRAME(text), "Produced notice"},
#line 323 "id3_frametype.gperf"
      {"TPUB", FRAME(text), "Publisher"},
#line 343 "id3_frametype.gperf"
      {"WPAY", FRAME(url),  "Payment"},
#line 321 "id3_frametype.gperf"
      {"TPOS", FRAME(text), "Part of a set"},
#line 342 "id3_frametype.gperf"
      {"WORS", FRAME(url),  "Official Internet radio station homepage"},
#line 311 "id3_frametype.gperf"
      {"TMOO", FRAME(text), "Mood"},
#line 324 "id3_frametype.gperf"
      {"TRCK", FRAME(text), "Track number/position in set"},
#line 294 "id3_frametype.gperf"
      {"TDLY", FRAME(text), "Playlist delay"},
#line 282 "id3_frametype.gperf"
      {"RVA2", FRAME(RVA2), "Relative volume adjustment (2)"},
#line 296 "id3_frametype.gperf"
      {"TDRC", FRAME(text), "Recording time"},
#line 336 "id3_frametype.gperf"
      {"USLT", FRAME(USLT), "Unsynchronised lyric/text transcription"},
#line 339 "id3_frametype.gperf"
      {"WOAF", FRAME(url),  "Official audio file webpage"},
#line 298 "id3_frametype.gperf"
      {"TDTG", FRAME(text), "Tagging time"},
#line 285 "id3_frametype.gperf"
      {"SIGN", FRAME(SIGN), "Signature frame"},
#line 341 "id3_frametype.gperf"
      {"WOAS", FRAME(url),  "Official audio source webpage"},
#line 300 "id3_frametype.gperf"
      {"TEXT", FRAME(text), "Lyricist/text writer"},
#line 288 "id3_frametype.gperf"
      {"TALB", FRAME(text), "Album/movie/show title"},
#line 307 "id3_frametype.gperf"
      {"TLAN", FRAME(text), "Language(s)"},
#line 320 "id3_frametype.gperf"
      {"TPE4", FRAME(text), "Interpreted, remixed, or otherwise modified by"},
#line 338 "id3_frametype.gperf"
      {"WCOP", FRAME(url),  "Copyright/legal information"},
#line 309 "id3_frametype.gperf"
      {"TMCL", FRAME(text), "Musician credits list"},
#line 346 "id3_frametype.gperf"
      {"XSOP", FRAME(text), "Performer sort order (v2.3)"},
#line 297 "id3_frametype.gperf"
      {"TDRL", FRAME(text), "Release time"},
#line 312 "id3_frametype.gperf"
      {"TOAL", FRAME(text), "Original album/movie/show title"},
#line 328 "id3_frametype.gperf"
      {"TSOP", FRAME(text), "Performer sort order"},
#line 327 "id3_frametype.gperf"
      {"TSOA", FRAME(text), "Album sort order"},
#line 269 "id3_frametype.gperf"
      {"EQU2", FRAME(EQU2), "Equalisation (2)"},
#line 292 "id3_frametype.gperf"
      {"TCOP", FRAME(text), "Copyright message"},
#line 273 "id3_frametype.gperf"
      {"LINK", FRAME(LINK), "Linked information"},
#line 272 "id3_frametype.gperf"
      {"GRID", FRAME(GRID), "Group identification registration"},
#line 280 "id3_frametype.gperf"
      {"PRIV", FRAME(PRIV), "Private frame"},
#line 289 "id3_frametype.gperf"
      {"TBPM", FRAME(text), "BPM (beats per minute)"},
#line 301 "id3_frametype.gperf"
      {"TFLT", FRAME(text), "File type"},
#line 275 "id3_frametype.gperf"
      {"MLLT", FRAME(MLLT), "MPEG location lookup table"},
#line 287 "id3_frametype.gperf"
      {"SYTC", FRAME(SYTC), "Synchronised tempo codes"},
#line 351 "id3_frametype.gperf"
      {"ZOBS", FRAME(ZOBS), "Obsolete frame"},
#line 334 "id3_frametype.gperf"
      {"UFID", FRAME(UFID), "Unique file identifier"},
#line 264 "id3_frametype.gperf"
      {"APIC", FRAME(APIC), "Attached picture"},
#line 317 "id3_frametype.gperf"
      {"TPE1", FRAME(text), "Lead performer(s)/soloist(s)"},
#line 304 "id3_frametype.gperf"
      {"TIT2", FRAME(text), "Title/songname/content description"},
#line 286 "id3_frametype.gperf"
      {"SYLT", FRAME(SYLT), "Synchronised lyric/text"},
#line 265 "id3_frametype.gperf"
      {"ASPI", FRAME(ASPI), "Audio seek point index"},
#line 302 "id3_frametype.gperf"
      {"TIPL", FRAME(text), "Involved people list"},
#line 305 "id3_frametype.gperf"
      {"TIT3", FRAME(text), "Subtitle/description refinement"},
#line 274 "id3_frametype.gperf"
      {"MCDI", FRAME(MCDI), "Music CD identifier"},
#line 347 "id3_frametype.gperf"
      {"GRP1", FRAME(text), "Content group description"},
#line 345 "id3_frametype.gperf"
      {"WXXX", FRAME(WXXX), "User defined URL link frame"},
#line 281 "id3_frametype.gperf"
      {"RBUF", FRAME(RBUF), "Recommended buffer size"},
#line 333 "id3_frametype.gperf"
      {"TXXX", FRAME(TXXX), "User defined text information frame"},
#line 303 "id3_frametype.gperf"
      {"TIT1", FRAME(text), "Content group description"}
    };

  static const signed char lookup[] =
    {
      -1, -1, -1, -1, -1, -1, -1,  0, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
       2,  3, -1,  4, -1, -1, -1, -1,  5,  6,  7,  8, -1,  9,
      10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
      24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37,
      38, 39, 40, 41, 42, -1, 43, 44, 45, 46, 47, 48, 49, 50,
      51, 52, -1, 53, 54, 55, -1, 56, 57, 58, 59, 60, 61, 62,
      63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, -1, 74, -1,
      75, 76, -1, 77, -1, -1, -1, -1, 78, 79, 80, -1, 81, -1,
      -1, -1, -1, -1, -1, 82, -1, -1, -1, -1, 83, -1, -1, -1,
      84, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1, -1, -1, -1, -1, 85
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = frametype_hash (str, len);

      if (key <= MAX_HASH_VALUE)
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
