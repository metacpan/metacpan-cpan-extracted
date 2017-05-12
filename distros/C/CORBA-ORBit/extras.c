#include "extras.h"

static CORBA_Principal porbit_cookie = { 0, 0, NULL, CORBA_FALSE };

static gboolean
porbit_handle_connection(GIOChannel *source, GIOCondition cond,
			 GIOPConnection *cnx)
{

  /* The best way to know about an fd exception is if select()/poll()
   * tells you about it, so we just relay that information on to ORBit
   * if possible
   */
	
  if(cond & (G_IO_HUP|G_IO_NVAL|G_IO_ERR))
    giop_main_handle_connection_exception(cnx);
  else
    giop_main_handle_connection(cnx);
	
  return TRUE;
}

static void
porbit_add_connection(GIOPConnection *cnx)
{
  int tag;
  GIOChannel *channel;
	
  channel = g_io_channel_unix_new(GIOP_CONNECTION_GET_FD(cnx));
  tag = g_io_add_watch_full (channel, G_PRIORITY_DEFAULT,
			     G_IO_IN|G_IO_ERR|G_IO_HUP|G_IO_NVAL, 
			     (GIOFunc)porbit_handle_connection,
			     cnx, NULL);
  g_io_channel_unref (channel);
	
  cnx->user_data = GUINT_TO_POINTER (tag);
}

static void
porbit_remove_connection(GIOPConnection *cnx)
{
  g_source_remove(GPOINTER_TO_UINT (cnx->user_data));
  cnx->user_data = GINT_TO_POINTER (-1);
}

void
porbit_set_use_gmain (gboolean set)
{
  if (set)
    {
      IIOPAddConnectionHandler = porbit_add_connection;
      IIOPRemoveConnectionHandler = porbit_remove_connection;
    }
  else
    {
      IIOPAddConnectionHandler = NULL;
      IIOPRemoveConnectionHandler = NULL;
    }
}

void
porbit_set_cookie (const char *cookie)
{
  if (porbit_cookie._buffer)
    g_free (porbit_cookie._buffer);
  porbit_cookie._buffer = g_strdup (cookie);
  porbit_cookie._length = strlen(cookie) + 1;
  ORBit_set_default_principal(&porbit_cookie);
}

static ORBit_MessageValidationResult 
porbit_request_validate(CORBA_unsigned_long request_id,
			CORBA_Principal *principal,
			CORBA_char *operation)
{
  if (principal->_length == porbit_cookie._length &&
      principal->_buffer[principal->_length - 1] ==  '\0' &&
      strcmp(principal->_buffer, porbit_cookie._buffer) == 0)
    return ORBIT_MESSAGE_ALLOW_ALL;
  else
    return ORBIT_MESSAGE_BAD;
}

void
porbit_set_check_cookies (gboolean set)
{
  if (set)
    ORBit_set_request_validation_handler (porbit_request_validate);
  else
    ORBit_set_request_validation_handler (NULL);
}

