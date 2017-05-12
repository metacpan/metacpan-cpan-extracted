
/* $Id: CzFast.xs,v 1.2 2001/03/19 19:54:24 trip Exp $ */

/*   Copyright (C) 2000 Tomas Styblo (tripiecz@yahoo.com)

  This program uses character tables created by Jaromir Dolecek for
  the Csacek project (http://www.csacek.cz).

  This code is free software; you can redistribute it and/or modify it
  under the terms of either:

  a) the GNU General Public License as published by the Free Software
  Foundation; either version 1, or (at your option) any later version,
  or

  b) the "Artistic License" which comes with this module.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
  the GNU General Public License or the Artistic License for more details.

  You should have received a copy of the Artistic License with this
  module, in the file ARTISTIC.  If not, I'll be glad to provide one.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA

*/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>

#define CHARSETS_COUNT 9	/* Total count of charsets */

static const unsigned char *charsets[CHARSETS_COUNT] = 
{
	/* ASCII */
	(const unsigned char *) "AAAAACCCDDEEEEIILLLNNOOOORRSSSTTUUUUYZZZaaaaacccddeeeeiilllnnoooorrsssttuuuuyzzz/.\"\"-'' x'''\"",
	/* ISO-8859-1 */
	(const unsigned char *) "ÁÂAÄACÇCDĞÉEËEÍÎLLLNNÓÔOÖRRSSSTTUÚUÜİZZZáâaäacçcdğéeëeíîlllnnóôoörrsssttuúuüızzz÷.\"\"-«» ×´''\"",
	/* ISO-8859-2 */
	(const unsigned char *) "ÁÂÃÄ¡ÆÇÈÏĞÉÊËÌÍÎÅ£¥ÑÒÓÔÕÖØÀ©ª¦«ŞÙÚÛÜİ®¬¯áâãä±æçèïğéêëìíîå³µñòóôõöøà¹º¶»şùúûüı¾¼¿÷.\"\"-'' ×´''\"",
	/* Windows-1250 */
	(const unsigned char *) "ÁÂÃÄ¥ÆÇÈÏĞÉÊËÌÍÎÅ£¼ÑÒÓÔÕÖØÀŠªŒŞÙÚÛÜİ¯áâãä¹æçèïğéêëìíîå³¾ñòóôõöøàšºœşùúûüıŸ¿÷…„“–«» ×´‘’”",
	/* Kam */
	(const unsigned char *) "AAACC€…DEE‰‹IŠLœN¥•§O™«›SS†T¦—Uš’ZZ aa„acc‡ƒd‚eeˆ¡ilŒn¤¢“o”©ª¨ssŸt–£u˜‘zzö.\"\"-'' x'''\"",
	/* PC Latin2 */
	(const unsigned char *) "µ¶Æ¤€¬ÒÑ¨Ó·Ö×‘•ãÕàâŠ™üèæ¸—›İŞéëší¦½ ƒÇ„¥†‡ŸÔĞ‚©‰Ø¡Œ’ˆ–äå¢“‹”ıêç­˜œî…£ûì§«¾ö.\"\"-®¯ÿ×ïÔÕ”",
	/* KOI-8 CS */
	(const unsigned char *) "áAøñACCãäD÷EEåéëILìNîïğOíòæóSSôTêõUèùúZZÁaaÑaccÃÄd×eeÅÉiËlÌnÎÏĞoÍÒÆÓssÔtÊÕuÈÙÚzz/.\"\"-'' x'''\"",
	/* MAC */
	(const unsigned char *) "çA€„ŒC‰‘Dƒ¢EIê½ü»ÁÅîïÌ…ÛÙáSåèTñòô†øëû‡a‚Šˆc‹“d«e’i¾¸¼ÄË—™ÎšŞÚäsæétóœõŸùìıÖÉãÒĞÇÈÊx'ÔÕ”",
	/* CP 850 */
	(const unsigned char *) "µ¶AAC€CDDEÓEÖ×LLLNNàâO™RRSSSTTUéUšíZZZ ƒa„ac‡cdd‚e‰e¡Œlllnn¢“o”rrsssttu£uìzzzö.\"\"-®¯ÿ×ï''\"" 
};


/*	Compiles and caches character transition maps in a private static array.
	Takes two arguments that corespond to the input and output charset
	of the transition map. Either generates the map, caches it and returns
	a pointer to it, or returns a pointer to already cached instance of the
	map.
	Dynamically allocates mem for the map to save memory - we do not need
	most of the possible charset combinations in most cases.
	The static caching is implemented in a completely thread-safe manner -
	there is no way how one thread could get a pointer to a map that is not
	yet fully compiled by another thread.
*/

unsigned char *_czgetmap (const int charset_from, const int charset_to)
{
	int i, e;
	unsigned char *map_to, *map_from;
	static unsigned char *maps[CHARSETS_COUNT][CHARSETS_COUNT];
	static int maps_init[CHARSETS_COUNT][CHARSETS_COUNT];
	
	map_from = (unsigned char *) charsets[charset_from];
	map_to = (unsigned char *) charsets[charset_to];
	
	if (maps_init[charset_from][charset_to] == 0)	{
		maps[charset_from][charset_to] = malloc(256);
		for(i = 0; i < 256; i++) {
			maps[charset_from][charset_to][i] = (i & 0x80) ? '_' : i;
		}

		for(i = 0; map_from[i]; i++) {
			if (map_from[i] > 127) {
				maps[charset_from][charset_to][map_from[i]] = map_to[i];
			}
		}
		maps_init[charset_from][charset_to] = 1;
	}
	
	return maps[charset_from][charset_to];
}


MODULE = CzFast		PACKAGE = CzFast
		
unsigned char *
_czrecode (charset_from, charset_to, str_from)
	int charset_from;
	int charset_to;
	unsigned char *str_from;

	PROTOTYPE: $;$;$
	CODE:

	const int str_len = strlen(str_from);			
	unsigned char str_to[str_len + 1];
	unsigned char *p_str_to = str_to;
	unsigned char *map_actual;	
	const unsigned char *end = str_from + str_len;

	if (charset_from == charset_to) {
		RETVAL = str_from;
	}
	else if (charset_from >= CHARSETS_COUNT 
			|| charset_to >= CHARSETS_COUNT
			|| charset_from < 0
			|| charset_to < 0) {
		croak ("CGI::CzFast - XS: Invalid character set identificator.");
	}
	else {
		map_actual = _czgetmap (charset_from, charset_to);
		
		for( ; str_from < end; str_from++, p_str_to++) {
			*p_str_to = map_actual[*str_from] & 0xFF;
		}

		*p_str_to = '\0';
		p_str_to = str_to;

		RETVAL = p_str_to;
	}
		
	OUTPUT:
		RETVAL
		
