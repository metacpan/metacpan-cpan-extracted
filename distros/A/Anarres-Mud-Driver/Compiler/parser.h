typedef union {
	int			 number;
	const char	*str;
	SV			*sv;
	SV			*obj;
	AV			*av;
	struct _assoc_t {
		SV	*key;
		SV	*value;
	} 			 assoc;
} AMD_YYSTYPE;
#define	L_BREAK	257
#define	L_CASE	258
#define	L_CATCH	259
#define	L_CLASS	260
#define	L_CONTINUE	261
#define	L_DEFAULT	262
#define	L_DO	263
#define	L_EFUN	264
#define	L_ELSE	265
#define	L_FOR	266
#define	L_FOREACH	267
#define	L_IF	268
#define	L_IN	269
#define	L_INHERIT	270
#define	L_NEW	271
#define	L_NIL	272
#define	L_RETURN	273
#define	L_RLIMITS	274
#define	L_SWITCH	275
#define	L_SSCANF	276
#define	L_TRY	277
#define	L_WHILE	278
#define	L_MAP_START	279
#define	L_MAP_END	280
#define	L_ARRAY_START	281
#define	L_ARRAY_END	282
#define	L_FUNCTION_START	283
#define	L_FUNCTION_END	284
#define	L_PARAMETER	285
#define	L_IDENTIFIER	286
#define	L_STRING	287
#define	L_CHARACTER	288
#define	L_INTEGER	289
#define	L_HEXINTEGER	290
#define	L_BASIC_TYPE	291
#define	L_TYPE_MODIFIER	292
#define	L_STATIC	293
#define	L_COLONCOLON	294
#define	L_VOID	295
#define	L_ELLIPSIS	296
#define	L_ARROW	297
#define	L_RANGE	298
#define	LOWER_THAN_ELSE	299
#define	L_PLUS_EQ	300
#define	L_MINUS_EQ	301
#define	L_DIV_EQ	302
#define	L_TIMES_EQ	303
#define	L_MOD_EQ	304
#define	L_AND_EQ	305
#define	L_OR_EQ	306
#define	L_XOR_EQ	307
#define	L_DOT_EQ	308
#define	L_LOR_EQ	309
#define	L_LAND_EQ	310
#define	L_LOR	311
#define	L_LAND	312
#define	L_EQ	313
#define	L_NE	314
#define	L_GE	315
#define	L_LE	316
#define	L_LSH	317
#define	L_RSH	318
#define	L_INC	319
#define	L_DEC	320

