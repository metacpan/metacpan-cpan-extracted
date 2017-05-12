/*
 * @(#)XMLOutputStreamImpl.java
 *
 * Copyright 2004, Francois PERRAD
 */

import java.io.*;

import org.omg.CORBA.Any;
import org.omg.CORBA.TypeCode;

import org.omg.CORBA.portable.XMLInputStream;

public class XMLOutputStreamImpl extends org.omg.CORBA.portable.XMLOutputStream
{

	//Fields
	private BufferedWriter bw;


	//Constructors
	public XMLOutputStreamImpl (OutputStream _os)
	{
		try {
			Writer w = new OutputStreamWriter (_os, "UTF-8");
			bw = new BufferedWriter (w);
		} catch (java.io.UnsupportedEncodingException e) {
		}
	}


	//Methods
	public void close () throws IOException
	{
		bw.close ();
		super.close ();
	}


	public XMLInputStream create_input_stream ()
	{
		throw new org.omg.CORBA.NO_IMPLEMENT ();
	}



	private void escaped_write (java.lang.String str) throws IOException
	{
		for (int i = 0; i < str.length (); i++)
		{
			char c = str.charAt (i);
			if      (c == '"')
				bw.write ("&#34;");
			else if (c == '&')
				bw.write ("&#38;");
			else if (c == '\'')
				bw.write ("&#39;");
			else if (c == '<')
				bw.write ("&#60;");
			else if (c == '>')
				bw.write ("&#62;");
			else
				bw.write (c);
		}
	}

	public void write_open_tag (java.lang.String tag)
	{
		try {
			bw.write ('<');
			bw.write (tag);
			bw.write ('>');
		}
		catch (IOException e) {
			throw new org.omg.CORBA.INTERNAL (e.getMessage ());
		}
	}

	public void write_close_tag (java.lang.String tag)
	{
		try {
			bw.write ("</");
			bw.write (tag);
			bw.write (">");
		}
		catch (IOException e) {
			throw new org.omg.CORBA.INTERNAL (e.getMessage ());
		}
	}

	public void write_pcdata (java.lang.String data)
	{
		try {
			escaped_write (data);
		}
		catch (IOException e) {
			throw new org.omg.CORBA.INTERNAL (e.getMessage ());
		}
	}


	private void _write_pcdata (java.lang.String data)
	{
		try {
			bw.write (data);
		}
		catch (IOException e) {
			throw new org.omg.CORBA.INTERNAL (e.getMessage ());
		}
	}


//	public void write_Abstract (Object value)
//	{
//		throw new org.omg.CORBA.NO_IMPLEMENT ();
//	}


	public void write_any (org.omg.CORBA.Any value, java.lang.String tag)
	{
		throw new org.omg.CORBA.NO_IMPLEMENT ();
	}


	public void write_boolean (boolean value, java.lang.String tag)
	{
		write_open_tag (tag);
		_write_pcdata (value ? "true" : "false");
		write_close_tag (tag);
	}


	public void write_char (char value, java.lang.String tag)
	{
		Character obj = new Character (value);
		write_open_tag (tag);
		write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_double (double value, java.lang.String tag)
	{
		Double obj = new Double (value);
		write_open_tag (tag);
		_write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_float (float value, java.lang.String tag)
	{
		Float obj = new Float (value);
		write_open_tag (tag);
		_write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_long (int value, java.lang.String tag)
	{
		Long obj = new Long (value);
		write_open_tag (tag);
		_write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_longlong (long value, java.lang.String tag)
	{
		Long obj = new Long (value);
		write_open_tag (tag);
		_write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_Object (org.omg.CORBA.Object value, java.lang.String tag)
	{
		throw new org.omg.CORBA.NO_IMPLEMENT ();
	}


	public void write_octet (byte value, java.lang.String tag)
	{
		Byte obj = new Byte (value);
		write_open_tag (tag);
		_write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_short (short value, java.lang.String tag)
	{
		Short obj = new Short (value);
		write_open_tag (tag);
		_write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_string (String value, java.lang.String tag)
	{
		write_open_tag (tag);
		write_pcdata (value);
		write_close_tag (tag);
	}


	public void write_TypeCode (org.omg.CORBA.TypeCode value, java.lang.String tag)
	{
		throw new org.omg.CORBA.NO_IMPLEMENT ();
	}


	public void write_ulong (int value, java.lang.String tag)
	{
		Long obj = new Long (value);
		write_open_tag (tag);
		_write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_ulonglong (long value, java.lang.String tag)
	{
		Long obj = new Long (value);
		write_open_tag (tag);
		_write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_ushort (short value, java.lang.String tag)
	{
		Short obj = new Short (value);
		write_open_tag (tag);
		_write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


//	public void write_Value (Serializable value)
//	{
//		throw new org.omg.CORBA.NO_IMPLEMENT ();
//	}


	public void write_wchar (char value, java.lang.String tag)
	{
		Character obj = new Character (value);
		write_open_tag (tag);
		write_pcdata (obj.toString ());
		write_close_tag (tag);
	}


	public void write_wstring (String value, java.lang.String tag)
	{
		write_open_tag (tag);
		write_pcdata (value);
		write_close_tag (tag);
	}

	public void write_fixed (java.math.BigDecimal value, java.lang.String tag)
	{
		write_open_tag (tag);
		_write_pcdata (value.toString ());
		write_close_tag (tag);
	}

}
