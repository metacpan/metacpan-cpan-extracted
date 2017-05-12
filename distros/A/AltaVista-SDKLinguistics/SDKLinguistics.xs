#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <avsl.h>

MODULE = AltaVista::SDKLinguistics		PACKAGE = AltaVista::SDKLinguistics		


void *
avsl_thesaurus_init(config)
	char *config
	CODE:
	{
	void *hdl = 0;
	if (avsl_thesaurus_init(config, &hdl) != 0)
		{
		printf("avsl_thesaurus_init(config = %s) FAILED with error = \"%s\"\n",
			config, avsl_thesaurus_getlasterr());
		fflush(stdout);
		RETVAL = 0;
		}
	else
		{
		RETVAL = hdl;
		}
	}
	OUTPUT:
	RETVAL

char *
avsl_thesaurus_get(hdl, word, language, separator = ' ')
	void *hdl
	char *word
	char *language
	char separator
	
	CODE:
	{
	char results[5000];
	int found;
	int returned;
	int totalbytes = 0;
	int i;
	char *p, *returnbuf;
	int len;
	int err;
	
	err = avsl_thesaurus_get(hdl, word, language, results, sizeof(results), &found, &returned);
	if (err != AVSL_OK)
		{
		printf("avsl_thesaurus_get(word=%s, language = %s) FAILED, error = %s\n", word, language, avs_errmsg(err));
		fflush(stdout);
		RETVAL = 0;
		}
	else
		{
		if (returned != 0)
			{
			for (i = 0, p = results ; i < returned ; i++)
				{
				len = strlen(p) + 1;
				p += len;
				totalbytes += len;
				}
	
			returnbuf = calloc(totalbytes, 1);
			memcpy(returnbuf, results, totalbytes);
			for (i = 0 ; i < totalbytes - 1 ; i++)
				if (returnbuf[i] == '\0') returnbuf[i] = separator;

			RETVAL = returnbuf;
			}
		else
			{
			RETVAL = 0;
			}
		}
	}
	
	OUTPUT:
	RETVAL


int
avsl_thesaurus_close(hdl)
	void *hdl
	CODE:
	{
	int err;

	err = avsl_thesaurus_close(hdl);
	if (err != AVSL_OK)
		{
		printf("avsl_thesaurus_close() FAILED, error = %s\n", avs_errmsg(err));
		fflush(stdout);
		}

	RETVAL = err;
	}
	
	OUTPUT:
	RETVAL







void *
avsl_phrase_init(config)
	char *config
	CODE:
	{
	void *hdl = 0;
	if (avsl_phrase_init(config, &hdl) != 0)
		{
		printf("avsl_phrase_init(config = %s) FAILED with error = \"%s\"\n",
			config, avsl_phrase_getlasterr());
		fflush(stdout);
		RETVAL = 0;
		}
	else
		{
		RETVAL = hdl;
		}
	}
	OUTPUT:
	RETVAL

char *
avsl_phrase_get(hdl, word, language, separator = ':')
	void *hdl
	char *word
	char *language
	char separator

	CODE:
	{
	char results[5000];
	int found;
	int returned;
	int totalbytes = 0;
	int i;
	char *p, *returnbuf;
	int len;
	int err;
	
	err = avsl_phrase_get(hdl, word, language, results, sizeof(results), &found, &returned);
	if (err != AVSL_OK)
		{
		printf("avsl_phrase_get(word=%s, language = %s) FAILED, error = %s\n",
			word, language, avs_errmsg(err));
		fflush(stdout);
		RETVAL = 0;
		}
	else
		{
		if (returned != 0)
			{
			for (i = 0, p = results ; i < returned ; i++)
				{
				len = strlen(p) + 1;
				p += len;
				totalbytes += len;
				}
	
			returnbuf = calloc(totalbytes, 1);
			memcpy(returnbuf, results, totalbytes);
			for (i = 0 ; i < totalbytes - 1 ; i++)
				if (returnbuf[i] == '\0') returnbuf[i] = separator;

			RETVAL = returnbuf;
			}
		else
			{
			RETVAL = 0;
			}
		}
	}
	
	OUTPUT:
	RETVAL


int
avsl_phrase_close(hdl)
	void *hdl
	CODE:
	{
	int err;

	err = avsl_phrase_close(hdl);
	if (err != AVSL_OK)
		{
		printf("avsl_phrase_close() FAILED, error = %s\n", avs_errmsg(err));
		fflush(stdout);
		}

	RETVAL = err;
	}
	
	OUTPUT:
	RETVAL



void *
avsl_stem_init(package, tags)
	char *package
	char *tags
	CODE:
	{
	void *hdl = 0;
	if (avsl_stem_init(package, tags, &hdl) != 0)
		{
		printf("avsl_stem_init(package = %s, tags = %s) FAILED with error = \"%s\"\n",
			package, tags, avsl_stem_getlasterr());
		fflush(stdout);
		RETVAL = 0;
		}
	else
		{
		RETVAL = hdl;
		}
	}
	OUTPUT:
	RETVAL

char *
avsl_stem_get(hdl, word, language, separator = ' ')
	void *hdl
	char *word
	char *language
	char separator

	CODE:
	{
	char results[5000];
	int found;
	int returned;
	int totalbytes = 0;
	int i;
	char *p, *returnbuf;
	int len;
	int err;
	
	err = avsl_stem_get(hdl, word, language, results, sizeof(results), &found, &returned);
	if (err != AVSL_OK)
		{
		printf("avsl_stem_get(word=%s, language = %s) FAILED, err = %s\n",
			word, language, avs_errmsg(err));
		fflush(stdout);
		RETVAL = 0;
		}
	else
		{
		if (returned != 0)
			{
			for (i = 0, p = results ; i < returned ; i++)
				{
				len = strlen(p) + 1;
				p += len;
				totalbytes += len;
				}
	
			returnbuf = calloc(totalbytes, 1);
			memcpy(returnbuf, results, totalbytes);
			for (i = 0 ; i < totalbytes - 1 ; i++)
				if (returnbuf[i] == '\0') returnbuf[i] = separator;

			RETVAL = returnbuf;
			}
		else
			{
			RETVAL = 0;
			}
		}
	}
	
	OUTPUT:
	RETVAL


int
avsl_stem_close(hdl)
	void *hdl
	CODE:
	{
	int err;

	err = avsl_stem_close(hdl);
	if (err != AVSL_OK)
		{
		printf("avsl_stem_close() FAILED, error = %s\n", avs_errmsg(err));
		fflush(stdout);
		}

	RETVAL = err;
	}
	
	OUTPUT:
	RETVAL


void *
avsl_spell_init(config)
	char *config
	CODE:
	{
	void *hdl = 0;
	if (avsl_spell_init(config, &hdl) != 0)
		{
		printf("avsl_spell_init(config = %s) FAILED with error = \"%s\"\n",
			config, avsl_spell_getlasterr());
		fflush(stdout);
		RETVAL = 0;
		}
	else
		{
		RETVAL = hdl;
		}
	}
	OUTPUT:
	RETVAL


char *
avsl_spellcheck_get(hdl, word, language, separator = ' ')
	void *hdl
	char *word
	char *language
	char separator

	CODE:
	{
	char results[5000];
	int found;
	int returned;
	int totalbytes = 0;
	int i;
	char *p, *returnbuf;
	int len;
	int err;
	
	err = avsl_spellcheck_get(hdl, word, language, results, sizeof(results), &found, &returned);
	if (err != AVSL_OK)
		{
		printf("avsl_spellcheck_get(word=%s, language = %s) FAILED, error = %s\n",
			word, language, avs_errmsg(err));
		fflush(stdout);
		RETVAL = 0;
		}
	else
		{
		if (returned != 0)
			{
			for (i = 0, p = results ; i < returned ; i++)
				{
				len = strlen(p) + 1;
				p += len;
				totalbytes += len;
				}
	
			returnbuf = calloc(totalbytes, 1);
			memcpy(returnbuf, results, totalbytes);
			for (i = 0 ; i < totalbytes - 1 ; i++)
				if (returnbuf[i] == '\0') returnbuf[i] = separator;

			RETVAL = returnbuf;
			}
		else
			{
			RETVAL = 0;
			}
		}
	}
	
	OUTPUT:
	RETVAL

char *
avsl_spellcorrection_get(hdl, word, language, separator = ' ')
	void *hdl
	char *word
	char *language
	char separator

	CODE:
	{
	char results[5000];
	int found;
	int returned;
	int totalbytes = 0;
	int i;
	char *p, *returnbuf;
	int len;
	int err;
	
	err = avsl_spellcorrection_get(hdl, word, language, results, sizeof(results), &found, &returned);
	if (err != AVSL_OK)
		{
		printf("avsl_spellcorrection_get(word=%s, language = %s) FAILED, error = %s\n",
			word, language, avs_errmsg(err));
		fflush(stdout);
		RETVAL = 0;
		}
	else
		{
		if (returned != 0)
			{
			for (i = 0, p = results ; i < returned ; i++)
				{
				len = strlen(p) + 1;
				p += len;
				totalbytes += len;
				}
	
			returnbuf = calloc(totalbytes, 1);
			memcpy(returnbuf, results, totalbytes);
			for (i = 0 ; i < totalbytes - 1 ; i++)
				if (returnbuf[i] == '\0') returnbuf[i] = separator;

			RETVAL = returnbuf;
			}
		else
			{
			RETVAL = 0;
			}
		}
	}
	
	OUTPUT:
	RETVAL


int
avsl_spell_close(hdl)
	void *hdl
	CODE:
	{
	int err;

	err = avsl_spell_close(hdl);
	if (err != AVSL_OK)
		{
		printf("avsl_spell_close() FAILED, error = %s\n", avs_errmsg(err));
		fflush(stdout);
		}

	RETVAL = err;
	}
	
	OUTPUT:
	RETVAL








