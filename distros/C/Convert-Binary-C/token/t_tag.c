/**********************************************************************
 *
 *  Prototypes
 *
 **********************************************************************/

static enum CbcTagId get_tag_id(const char *tag);
static TAG_SET(ByteOrder);
static TAG_GET(ByteOrder);
static TAG_VERIFY(ByteOrder);
static enum CbcTagByteOrder GetTagByteOrder(const char *t);
static TAG_INIT(Dimension);
static TAG_CLONE(Dimension);
static TAG_FREE(Dimension);
static TAG_SET(Dimension);
static TAG_GET(Dimension);
static TAG_VERIFY(Dimension);
static TAG_SET(Format);
static TAG_GET(Format);
static TAG_VERIFY(Format);
static enum CbcTagFormat GetTagFormat(const char *t);
static TAG_INIT(Hooks);
static TAG_CLONE(Hooks);
static TAG_FREE(Hooks);
static TAG_SET(Hooks);
static TAG_GET(Hooks);

/**********************************************************************
 *
 *  Tag IDs
 *
 **********************************************************************/

static const char *gs_TagIdStr[] = {
  "ByteOrder",
  "Dimension",
  "Format",
  "Hooks",
  "<<INVALID>>"
};

/**********************************************************************
 *
 *  Dimension Vtable
 *
 **********************************************************************/

static CtTagVtable gs_Dimension_vtable = {
  Dimension_Init,
  Dimension_Clone,
  Dimension_Free
};

/**********************************************************************
 *
 *  Hooks Vtable
 *
 **********************************************************************/

static CtTagVtable gs_Hooks_vtable = {
  Hooks_Init,
  Hooks_Clone,
  Hooks_Free
};

/**********************************************************************
 *
 *  Tag Method Table
 *
 **********************************************************************/

static const struct tag_tbl_ent {
  TagSetMethod set;
  TagGetMethod get;
  TagVerifyMethod verify;
  CtTagVtable *vtbl;
} gs_TagTbl[] = {
  { ByteOrder_Set, ByteOrder_Get, ByteOrder_Verify, NULL },
  { Dimension_Set, Dimension_Get, Dimension_Verify, &gs_Dimension_vtable },
  { Format_Set, Format_Get, Format_Verify, NULL },
  { Hooks_Set, Hooks_Get, NULL, &gs_Hooks_vtable },
  {NULL, NULL, NULL, NULL}
};

/**********************************************************************
 *
 *  Main Tag Tokenizer
 *
 **********************************************************************/

static enum CbcTagId get_tag_id(const char *tag)
{
  switch (tag[0])
  {
    case 'B':
      if (tag[1] == 'y' &&
          tag[2] == 't' &&
          tag[3] == 'e' &&
          tag[4] == 'O' &&
          tag[5] == 'r' &&
          tag[6] == 'd' &&
          tag[7] == 'e' &&
          tag[8] == 'r' &&
          tag[9] == '\0')
      {                                             /* ByteOrder */
        return CBC_TAG_BYTE_ORDER;
      }
  
      goto unknown;
  
    case 'D':
      if (tag[1] == 'i' &&
          tag[2] == 'm' &&
          tag[3] == 'e' &&
          tag[4] == 'n' &&
          tag[5] == 's' &&
          tag[6] == 'i' &&
          tag[7] == 'o' &&
          tag[8] == 'n' &&
          tag[9] == '\0')
      {                                             /* Dimension */
        return CBC_TAG_DIMENSION;
      }
  
      goto unknown;
  
    case 'F':
      if (tag[1] == 'o' &&
          tag[2] == 'r' &&
          tag[3] == 'm' &&
          tag[4] == 'a' &&
          tag[5] == 't' &&
          tag[6] == '\0')
      {                                             /* Format    */
        return CBC_TAG_FORMAT;
      }
  
      goto unknown;
  
    case 'H':
      if (tag[1] == 'o' &&
          tag[2] == 'o' &&
          tag[3] == 'k' &&
          tag[4] == 's' &&
          tag[5] == '\0')
      {                                             /* Hooks     */
        return CBC_TAG_HOOKS;
      }
  
      goto unknown;
  
    default:
      goto unknown;
  }

unknown:
  return CBC_INVALID_TAG;
}

/**********************************************************************
 *
 *  ByteOrder Tokenizer
 *
 **********************************************************************/

static enum CbcTagByteOrder GetTagByteOrder(const char *t)
{
  switch (t[0])
  {
    case 'B':
      if (t[1] == 'i' &&
          t[2] == 'g' &&
          t[3] == 'E' &&
          t[4] == 'n' &&
          t[5] == 'd' &&
          t[6] == 'i' &&
          t[7] == 'a' &&
          t[8] == 'n' &&
          t[9] == '\0')
      {                                             /* BigEndian    */
        return CBC_TAG_BYTE_ORDER_BIG_ENDIAN;
      }
  
      goto unknown;
  
    case 'L':
      if (t[1] == 'i' &&
          t[2] == 't' &&
          t[3] == 't' &&
          t[4] == 'l' &&
          t[5] == 'e' &&
          t[6] == 'E' &&
          t[7] == 'n' &&
          t[8] == 'd' &&
          t[9] == 'i' &&
          t[10] == 'a' &&
          t[11] == 'n' &&
          t[12] == '\0')
      {                                             /* LittleEndian */
        return CBC_TAG_BYTE_ORDER_LITTLE_ENDIAN;
      }
  
      goto unknown;
  
    default:
      goto unknown;
  }

unknown:
  return CBC_INVALID_BYTE_ORDER;
}

/**********************************************************************
 *
 *  Format Tokenizer
 *
 **********************************************************************/

static enum CbcTagFormat GetTagFormat(const char *t)
{
  switch (t[0])
  {
    case 'B':
      if (t[1] == 'i' &&
          t[2] == 'n' &&
          t[3] == 'a' &&
          t[4] == 'r' &&
          t[5] == 'y' &&
          t[6] == '\0')
      {                                             /* Binary */
        return CBC_TAG_FORMAT_BINARY;
      }
  
      goto unknown;
  
    case 'S':
      if (t[1] == 't' &&
          t[2] == 'r' &&
          t[3] == 'i' &&
          t[4] == 'n' &&
          t[5] == 'g' &&
          t[6] == '\0')
      {                                             /* String */
        return CBC_TAG_FORMAT_STRING;
      }
  
      goto unknown;
  
    default:
      goto unknown;
  }

unknown:
  return CBC_INVALID_FORMAT;
}

/**********************************************************************
 *
 *  ByteOrder Set/Get Methods
 *
 **********************************************************************/

static TAG_SET(ByteOrder)
{
  if (SvOK(val))
  {
    if (SvROK(val))
      Perl_croak(aTHX_ "Value for ByteOrder tag must not be a reference");
    else
    {
      const char *valstr = SvPV_nolen(val);
      enum CbcTagByteOrder ByteOrder = GetTagByteOrder(valstr);

      if (ByteOrder == CBC_INVALID_BYTE_ORDER)
        Perl_croak(aTHX_ "Invalid value '%s' for ByteOrder tag", valstr);

      tag->flags = ByteOrder;

      return TSRV_UPDATE;
    }
  }

  return TSRV_DELETE;
}

static TAG_GET(ByteOrder)
{
  static const char *val[] = {
    "BigEndian",
    "LittleEndian"
  };

  if (tag->flags >= sizeof(val) / sizeof(val[0]))
    fatal("Invalid value (%d) for ByteOrder tag", tag->flags);

  return newSVpv(val[tag->flags], 0);
}

/**********************************************************************
 *
 *  Format Set/Get Methods
 *
 **********************************************************************/

static TAG_SET(Format)
{
  if (SvOK(val))
  {
    if (SvROK(val))
      Perl_croak(aTHX_ "Value for Format tag must not be a reference");
    else
    {
      const char *valstr = SvPV_nolen(val);
      enum CbcTagFormat Format = GetTagFormat(valstr);

      if (Format == CBC_INVALID_FORMAT)
        Perl_croak(aTHX_ "Invalid value '%s' for Format tag", valstr);

      tag->flags = Format;

      return TSRV_UPDATE;
    }
  }

  return TSRV_DELETE;
}

static TAG_GET(Format)
{
  static const char *val[] = {
    "String",
    "Binary"
  };

  if (tag->flags >= sizeof(val) / sizeof(val[0]))
    fatal("Invalid value (%d) for Format tag", tag->flags);

  return newSVpv(val[tag->flags], 0);
}

