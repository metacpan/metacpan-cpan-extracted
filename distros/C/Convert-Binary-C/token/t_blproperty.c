static enum BLError Generic_get(aSELF, BLProperty prop, BLPropValue *value)
{
  BL_SELF(Generic);

  switch (prop)
  {
    case BLP_ALIGN:
      value->type = BLPVT_INT;
      value->v.v_int = self->align;
      break;

    case BLP_BYTE_ORDER:
      value->type = BLPVT_STR;
      value->v.v_str = self->byte_order;
      break;

    case BLP_MAX_ALIGN:
      value->type = BLPVT_INT;
      value->v.v_int = self->max_align;
      break;

    case BLP_OFFSET:
      value->type = BLPVT_INT;
      value->v.v_int = self->offset;
      break;

    default:
      return BLE_INVALID_PROPERTY;
  }

  return BLE_NO_ERROR;
}

static enum BLError Generic_set(aSELF, BLProperty prop, const BLPropValue *value)
{
  BL_SELF(Generic);

  switch (prop)
  {
    case BLP_ALIGN:
      assert(value->type == BLPVT_INT);
      self->align = value->v.v_int;
      break;

    case BLP_BYTE_ORDER:
      assert(value->type == BLPVT_STR);
      self->byte_order = value->v.v_str;
      break;

    case BLP_MAX_ALIGN:
      assert(value->type == BLPVT_INT);
      self->max_align = value->v.v_int;
      break;

    case BLP_OFFSET:
      assert(value->type == BLPVT_INT);
      self->offset = value->v.v_int;
      break;

    default:
      return BLE_INVALID_PROPERTY;
  }

  return BLE_NO_ERROR;
}

static const BLOption *Generic_options(aSELF, int *count)
{
  assert(count != NULL);
  *count = 0;
  return NULL;
}

static enum BLError Microsoft_get(aSELF, BLProperty prop, BLPropValue *value)
{
  BL_SELF(Microsoft);

  switch (prop)
  {
    case BLP_ALIGN:
      value->type = BLPVT_INT;
      value->v.v_int = self->align;
      break;

    case BLP_BYTE_ORDER:
      value->type = BLPVT_STR;
      value->v.v_str = self->byte_order;
      break;

    case BLP_MAX_ALIGN:
      value->type = BLPVT_INT;
      value->v.v_int = self->max_align;
      break;

    case BLP_OFFSET:
      value->type = BLPVT_INT;
      value->v.v_int = self->offset;
      break;

    default:
      return BLE_INVALID_PROPERTY;
  }

  return BLE_NO_ERROR;
}

static enum BLError Microsoft_set(aSELF, BLProperty prop, const BLPropValue *value)
{
  BL_SELF(Microsoft);

  switch (prop)
  {
    case BLP_ALIGN:
      assert(value->type == BLPVT_INT);
      self->align = value->v.v_int;
      break;

    case BLP_BYTE_ORDER:
      assert(value->type == BLPVT_STR);
      self->byte_order = value->v.v_str;
      break;

    case BLP_MAX_ALIGN:
      assert(value->type == BLPVT_INT);
      self->max_align = value->v.v_int;
      break;

    case BLP_OFFSET:
      assert(value->type == BLPVT_INT);
      self->offset = value->v.v_int;
      break;

    default:
      return BLE_INVALID_PROPERTY;
  }

  return BLE_NO_ERROR;
}

static const BLOption *Microsoft_options(aSELF, int *count)
{
  assert(count != NULL);
  *count = 0;
  return NULL;
}

static enum BLError Simple_get(aSELF, BLProperty prop, BLPropValue *value)
{
  BL_SELF(Simple);

  switch (prop)
  {
    case BLP_ALIGN:
      value->type = BLPVT_INT;
      value->v.v_int = self->align;
      break;

    case BLP_BLOCK_SIZE:
      value->type = BLPVT_INT;
      value->v.v_int = self->block_size;
      break;

    case BLP_BYTE_ORDER:
      value->type = BLPVT_STR;
      value->v.v_str = self->byte_order;
      break;

    case BLP_MAX_ALIGN:
      value->type = BLPVT_INT;
      value->v.v_int = self->max_align;
      break;

    case BLP_OFFSET:
      value->type = BLPVT_INT;
      value->v.v_int = self->offset;
      break;

    default:
      return BLE_INVALID_PROPERTY;
  }

  return BLE_NO_ERROR;
}

static enum BLError Simple_set(aSELF, BLProperty prop, const BLPropValue *value)
{
  BL_SELF(Simple);

  switch (prop)
  {
    case BLP_ALIGN:
      assert(value->type == BLPVT_INT);
      self->align = value->v.v_int;
      break;

    case BLP_BLOCK_SIZE:
      assert(value->type == BLPVT_INT);
      self->block_size = value->v.v_int;
      break;

    case BLP_BYTE_ORDER:
      assert(value->type == BLPVT_STR);
      self->byte_order = value->v.v_str;
      break;

    case BLP_MAX_ALIGN:
      assert(value->type == BLPVT_INT);
      self->max_align = value->v.v_int;
      break;

    case BLP_OFFSET:
      assert(value->type == BLPVT_INT);
      self->offset = value->v.v_int;
      break;

    default:
      return BLE_INVALID_PROPERTY;
  }

  return BLE_NO_ERROR;
}

static const BLOption *Simple_options(aSELF, int *count)
{
  static const BLOption options[] = {
    { BLP_BLOCK_SIZE, BLPVT_INT, 0, 0 }
  };

  assert(count != NULL);
  *count = sizeof options / sizeof options[0];
  return &options[0];
}

BLProperty bl_property(const char *property)
{
  switch (property[0])
  {
    case 'A':
      if (property[1] == 'l' &&
          property[2] == 'i' &&
          property[3] == 'g' &&
          property[4] == 'n' &&
          property[5] == '\0')
      {                                           /* Align     */
        return BLP_ALIGN;
      }

      goto unknown;

    case 'B':
      switch (property[1])
      {
        case 'l':
          if (property[2] == 'o' &&
              property[3] == 'c' &&
              property[4] == 'k' &&
              property[5] == 'S' &&
              property[6] == 'i' &&
              property[7] == 'z' &&
              property[8] == 'e' &&
              property[9] == '\0')
          {                                       /* BlockSize */
            return BLP_BLOCK_SIZE;
          }

          goto unknown;

        case 'y':
          if (property[2] == 't' &&
              property[3] == 'e' &&
              property[4] == 'O' &&
              property[5] == 'r' &&
              property[6] == 'd' &&
              property[7] == 'e' &&
              property[8] == 'r' &&
              property[9] == '\0')
          {                                       /* ByteOrder */
            return BLP_BYTE_ORDER;
          }

          goto unknown;

        default:
          goto unknown;
      }

    case 'M':
      if (property[1] == 'a' &&
          property[2] == 'x' &&
          property[3] == 'A' &&
          property[4] == 'l' &&
          property[5] == 'i' &&
          property[6] == 'g' &&
          property[7] == 'n' &&
          property[8] == '\0')
      {                                           /* MaxAlign  */
        return BLP_MAX_ALIGN;
      }

      goto unknown;

    case 'O':
      if (property[1] == 'f' &&
          property[2] == 'f' &&
          property[3] == 's' &&
          property[4] == 'e' &&
          property[5] == 't' &&
          property[6] == '\0')
      {                                           /* Offset    */
        return BLP_OFFSET;
      }

      goto unknown;

    default:
      goto unknown;
  }

unknown:
  return INVALID_BLPROPERTY;
}

BLPropValStr bl_propval(const char *propval)
{
  switch (propval[0])
  {
    case 'B':
      if (propval[1] == 'i' &&
          propval[2] == 'g' &&
          propval[3] == 'E' &&
          propval[4] == 'n' &&
          propval[5] == 'd' &&
          propval[6] == 'i' &&
          propval[7] == 'a' &&
          propval[8] == 'n' &&
          propval[9] == '\0')
      {                                           /* BigEndian    */
        return BLPV_BIG_ENDIAN;
      }

      goto unknown;

    case 'L':
      if (propval[1] == 'i' &&
          propval[2] == 't' &&
          propval[3] == 't' &&
          propval[4] == 'l' &&
          propval[5] == 'e' &&
          propval[6] == 'E' &&
          propval[7] == 'n' &&
          propval[8] == 'd' &&
          propval[9] == 'i' &&
          propval[10] == 'a' &&
          propval[11] == 'n' &&
          propval[12] == '\0')
      {                                           /* LittleEndian */
        return BLPV_LITTLE_ENDIAN;
      }

      goto unknown;

    default:
      goto unknown;
  }

unknown:
  return INVALID_BLPROPVAL;
}

const char *bl_property_string(BLProperty property)
{
  static const char *properties[] = {
    "Align",
    "BlockSize",
    "ByteOrder",
    "MaxAlign",
    "Offset"
  };

  if (property < sizeof properties / sizeof properties[0])
    return properties[property];

  return NULL;
}

const char *bl_propval_string(BLPropValStr propval)
{
  static const char *propvalues[] = {
    "BigEndian",
    "LittleEndian"
  };

  if (propval < sizeof propvalues / sizeof propvalues[0])
    return propvalues[propval];

  return NULL;
}
