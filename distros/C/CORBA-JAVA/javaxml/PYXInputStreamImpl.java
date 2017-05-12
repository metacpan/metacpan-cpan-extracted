/*
 * @(#)PYXInputStreamImpl.java
 *
 * Copyright 2004, Francois PERRAD
 */

import java.io.*;
import java.net.URL;

import org.xml.sax.*;
import org.xml.sax.helpers.*;

import org.omg.CORBA.Any;
import org.omg.CORBA.TypeCode;

public class PYXInputStreamImpl extends org.omg.CORBA.portable.XMLInputStream
{

	//Fields
	private java.io.BufferedReader	br;
	private int		line;		// current line number
	private int		column;		// current column number
	private java.lang.String	curr;
	private org.xml.sax.ErrorHandler	errorHandler;

	//Constructors
	public PYXInputStreamImpl (InputStream _is, org.xml.sax.ErrorHandler _errorHandler)
	{
		Reader r = new InputStreamReader (_is);
		br = new BufferedReader (r);
		errorHandler = _errorHandler;
		_init();
	}

	public PYXInputStreamImpl (InputStream _is)
	{
		this (_is, new org.xml.sax.helpers.DefaultHandler ());
	}

	public PYXInputStreamImpl (org.xml.sax.InputSource source, org.xml.sax.ErrorHandler _errorHandler)
	{
		br = _getBufferedReaderFromSource (source);
		errorHandler = _errorHandler;
		_init ();
	}

	public PYXInputStreamImpl (org.xml.sax.InputSource source)
	{
		this (source, new org.xml.sax.helpers.DefaultHandler ());
	}

	private BufferedReader _getBufferedReaderFromSource (org.xml.sax.InputSource source)
	{
		Reader r = source.getCharacterStream ();
		if (r == null)
		{
			InputStream is = source.getByteStream ();
			if (is == null)
			{
				String uri = source.getSystemId ();
				if (uri == null)
				{
					return null;
				}
				try {
					URL url = new URL (uri);
					is = url.openStream ();
				} catch (IOException ex) {
					return null;
				}
			}
			r = new InputStreamReader (is);
		}
		return new BufferedReader (r);
	}

	private void _init ()
	{
		line = 0;
		column = 0;
		curr = _get_line();
	}

	//Methods
	public void setErrorHandler(org.xml.sax.ErrorHandler handler)
	{
		errorHandler = handler;
	}

	public org.xml.sax.ErrorHandler getErrorHandler()
	{
		return errorHandler;
	}

	private void warning (String msg)
	{
		SAXParseException se = new SAXParseException (msg, null, null, line, column);
		try {
			errorHandler.warning (se);
		} catch (org.xml.sax.SAXException e) {
		}
	}

	private void error (String msg)
	{
		SAXParseException se = new SAXParseException (msg, null, null, line, column);
		try {
			errorHandler.error (se);
		} catch (org.xml.sax.SAXException e) {
		}
	}

	private void fatalError (String msg)
	{
		SAXParseException se = new SAXParseException (msg, null, null, line, column);
		try {
			errorHandler.fatalError (se);
		} catch (org.xml.sax.SAXException e) {
		}
	}

	public void close () throws IOException
	{
		br.close ();
		super.close ();
	}

	public void read_open_tag (java.lang.String tag)
	{
		if (curr == null)
		{
			error ("EOF");
			throw new org.omg.CORBA.MARSHAL ("EOF");
		}
		if (curr.charAt (0) != '(')
		{
			throw new org.omg.CORBA.MARSHAL ("Open Tag expected");
		}
		while (!curr.substring (1).equals (tag))	// Extensibility
		{
			_eat_balanced_tag ();
			if (curr == null)
			{
				error ("EOF");
				throw new org.omg.CORBA.MARSHAL ("EOF");
			}
			if (curr.charAt (0) != '(')
			{
				throw new org.omg.CORBA.MARSHAL ("Open Tag expected");
			}
		}
		curr = _get_line();
		while (curr != null && curr.charAt (0) == 'A')	// Attributs : tolerance
		{
			curr = _get_line();
		}
	}

	public void read_close_tag (java.lang.String tag)
	{
		if (curr == null)
		{
			error ("EOF");
			throw new org.omg.CORBA.MARSHAL ("EOF");
		}
		while (curr.charAt (0) == '(')	// Extensibility
		{
			_eat_balanced_tag ();
		}
		if (curr.charAt (0) != ')')
		{
			throw new org.omg.CORBA.MARSHAL ("Close Tag expected");
		}
		if (!curr.substring (1).equals (tag))
		{
			error ("Bad Close Tag");
			throw new org.omg.CORBA.MARSHAL ("Bad Close Tag");
		}
		curr = _get_line();
	}

	public java.lang.String read_pcdata ()
	{
		if (curr == null)
		{
			error ("EOF");
			return "";
		}
		while (curr.charAt (0) == '(')	// Extensibility
		{
			_eat_balanced_tag ();
		}
		if (curr.charAt (0) != '-')
		{
			return "";
		}
		String str = curr.substring (1);
		curr = _get_line();
		return str;
	}

	private void _eat_balanced_tag ()
	{
		if (curr == null || curr.charAt (0) != '(')
		{
			return;
		}
		String tag = curr.substring (1);
		curr = _get_line();
		while (curr != null)
		{
			switch (curr.charAt (0))
			{
			case 'A':
			case '-':
				curr = _get_line();
				break;
			case '(':
				_eat_balanced_tag ();
				break;
			case ')':
				if (!curr.substring (1).equals (tag))
				{
					error ("Bad Close Tag");
					throw new org.omg.CORBA.MARSHAL ("Bad Close Tag");
				}
				curr = _get_line();
				return;
			default:
				return;
			}
		}
	}

	public boolean read_boolean (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		if (str.equals ("true"))
		{
			return true;
		}
		if (!str.equals ("false"))
		{
			throw new org.omg.CORBA.MARSHAL ("Bad value for 'boolean'");
		}
		return false;
	}

	public char read_char (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		if (str.length () != 1)
		{
			throw new org.omg.CORBA.MARSHAL ("Bad length for 'char'");
		}
		return str.charAt (0);
	}

	public char read_wchar (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		if (str.length () != 1)
		{
			throw new org.omg.CORBA.MARSHAL ("Bad length for 'char'");
		}
		return str.charAt (0);
	}

	public byte read_octet (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		try {
			int val = Integer.parseInt (str.trim ());
			if (val < Byte.MIN_VALUE && val > Byte.MAX_VALUE)
			{
				throw new org.omg.CORBA.MARSHAL ("Out of range for 'octet'");
			}
			return (byte)val;
		} catch (NumberFormatException ex) {
			throw new org.omg.CORBA.MARSHAL (ex.getMessage ());
		}
	}

	public short read_short (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		try {
			int val = Integer.parseInt (str.trim ());
			if (val < Short.MIN_VALUE && val > Short.MAX_VALUE)
			{
				throw new org.omg.CORBA.MARSHAL ("Out of range for 'short'");
			}
			return (short)val;
		} catch (NumberFormatException ex) {
			throw new org.omg.CORBA.MARSHAL (ex.getMessage ());
		}
	}

	public short read_ushort (java.lang.String tag)
	{
		return read_short (tag);
	}

	public int read_long (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		try {
			int val = Integer.parseInt (str.trim ());
			return val;
		} catch (NumberFormatException ex) {
			throw new org.omg.CORBA.MARSHAL (ex.getMessage ());
		}
	}

	public int read_ulong (java.lang.String tag)
	{
		return read_long (tag);
	}

	public long read_longlong (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		try {
			long val = Long.parseLong (str.trim ());
			return val;
		} catch (NumberFormatException ex) {
			throw new org.omg.CORBA.MARSHAL (ex.getMessage ());
		}
	}

	public long read_ulonglong (java.lang.String tag)
	{
		return read_longlong (tag);
	}

	public float read_float (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		try {
			float val = Float.parseFloat (str.trim ());
			return val;
		} catch (NumberFormatException ex) {
			throw new org.omg.CORBA.MARSHAL (ex.getMessage ());
		}
	}

	public double read_double (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		try {
			double val = Double.parseDouble (str.trim ());
			return val;
		} catch (NumberFormatException ex) {
			throw new org.omg.CORBA.MARSHAL (ex.getMessage ());
		}
	}

	public java.lang.String read_string (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		return str;
	}

	public java.lang.String read_wstring (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		return str;
	}

	public java.math.BigDecimal read_fixed (java.lang.String tag)
	{
		read_open_tag (tag);
		String str = read_pcdata();
		read_close_tag (tag);
		try {
			return new java.math.BigDecimal (str.trim ());
		} catch (NumberFormatException ex) {
			throw new org.omg.CORBA.MARSHAL (ex.getMessage ());
		}
	}

	public org.omg.CORBA.Object read_Object (java.lang.String tag)
	{
		throw new org.omg.CORBA.NO_IMPLEMENT ();
	}

	public org.omg.CORBA.TypeCode read_TypeCode (java.lang.String tag)
	{
		throw new org.omg.CORBA.NO_IMPLEMENT ();
	}

	public org.omg.CORBA.Any read_any (java.lang.String tag)
	{
		throw new org.omg.CORBA.NO_IMPLEMENT ();
	}

	String _get_line()
	{
		if (br == null)
		{
			return null;
		}
		String esc;
		try {
			esc = br.readLine ();
			if (esc == null)
			{	// the end of the stream has been reached
				return null;
			}
			line ++;
		} catch (IOException e) {
			fatalError ("I/O error");
			return null;
		}

		StringBuffer str = new StringBuffer ();
		StringBuffer dec = null;
		int state = 1;
		for (int i = 0; i < esc.length (); i++)
		{
			column = i;
			char c = esc.charAt (i);
			switch (state)
			{
			case 1:
				if (c == '\\')
				{
					state = 2;
				}
				else
				{
					str.append (c);
				}
				break;
			case 2:
				if (c == '#')
				{
					state = 3;
					dec = new StringBuffer ();
				}
				else
				{	// '\\' and 'n' and otherwise
					str.append (c);
					state = 1;
					if (c != '\\' && c != 'n')
					{
						warning ("Invalid escape");
					}
				}
				break;
			case 3:
				if (c >= '0' && c <= '9')
				{
					dec.append (c);
				}
				else
				{	// ';' and otherwise
					int val = Integer.parseInt (dec.toString ());
					str.append ((char)val);
					state = 1;
					if (c != ';')
					{
						warning ("';' expected");
					}
				}
				break;
			}
		}
		return str.toString ();
	}

}
