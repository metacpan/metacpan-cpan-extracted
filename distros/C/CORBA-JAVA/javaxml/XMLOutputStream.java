/*
 * @(#)XMLOutputStream.java
 *
 * Copyright 2004, Francois PERRAD
 */

package org.omg.CORBA.portable;

import java.io.*;
import org.omg.CORBA.TypeCode;
import org.omg.CORBA.Any;

import org.omg.CORBA.portable.XMLInputStream;

/**
 * XMLOuputStream is the Java API for writing IDL types
 * to XML/WS-I marshal streams. These methods are used by the ORB to
 * marshal IDL types as well as to insert IDL types into Anys.
 */


public abstract class XMLOutputStream extends java.io.OutputStream
{
    public abstract void write_open_tag (java.lang.String tag);

    public abstract void write_close_tag (java.lang.String tag);

    public abstract void write_pcdata (java.lang.String data);

    /**
     * Returns an input stream with the same buffer.
     *@return an input stream with the same buffer.
     */
    public abstract XMLInputStream create_input_stream();

    /**
     * Writes a boolean value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_boolean (boolean value, java.lang.String tag);
    /**
     * Writes a char value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_char (char value, java.lang.String tag);
    /**
     * Writes a wide char value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_wchar (char value, java.lang.String tag);
    /**
     * Writes a CORBA octet (i.e. byte) value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_octet (byte value, java.lang.String tag);
    /**
     * Writes a short value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_short (short value, java.lang.String tag);
    /**
     * Writes an unsigned short value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_ushort (short value, java.lang.String tag);
    /**
     * Writes a CORBA long (i.e. Java int) value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_long (int value, java.lang.String tag);
    /**
     * Writes an unsigned CORBA long (i.e. Java int) value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_ulong (int value, java.lang.String tag);
    /**
     * Writes a CORBA longlong (i.e. Java long) value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_longlong (long value, java.lang.String tag);
    /**
     * Writes an unsigned CORBA longlong (i.e. Java long) value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_ulonglong (long value, java.lang.String tag);
    /**
     * Writes a float value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_float (float value, java.lang.String tag);
    /**
     * Writes a double value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_double (double value, java.lang.String tag);
    /**
     * Writes a string value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_string (String value, java.lang.String tag);
    /**
     * Writes a wide string value to this stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_wstring (String value, java.lang.String tag);
    /**
     * Writes a BigDecimal number.
     * @param value a BigDecimal--value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_fixed (java.math.BigDecimal value, java.lang.String tag);
    /**
     * Writes a CORBA Object on this output stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_Object (org.omg.CORBA.Object value, java.lang.String tag);
    /**
     * Writes a TypeCode on this output stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_TypeCode (org.omg.CORBA.TypeCode value, java.lang.String tag);
    /**
     * Writes an Any on this output stream.
     * @param value the value to be written.
     * @param tag the tag to be written.
     */
    public abstract void write_any (org.omg.CORBA.Any value, java.lang.String tag);

    /**
     */
    public void write (int b) throws java.io.IOException
    {
        throw new org.omg.CORBA.NO_IMPLEMENT ();
    }

//    /**
//     * Writes a CORBA context on this stream. The
//     * Context is marshaled as a sequence of strings.
//     * Only those Context values specified in the contexts
//     * parameter are actually written.
//     * @param ctx a CORBA context
//     * @param contexts a <code>ContextList</code> object containing the list of contexts
//     *        to be written
//     * @see <a href="package-summary.html#unimpl"><code>portable</code>
//     * package comments for unimplemented features</a>
//     */
//    public void write_Context(org.omg.CORBA.Context ctx,
//			      org.omg.CORBA.ContextList contexts)
//    {
//        throw new org.omg.CORBA.NO_IMPLEMENT ();
//    }

//    /**
//     * Returns the ORB that created this OutputStream.
//     * @return the ORB that created this OutputStream
//     * @see <a href="package-summary.html#unimpl"><code>portable</code>
//     * package comments for unimplemented features</a>
//     */
//    public org.omg.CORBA.ORB orb ()
//    {
//	throw new org.omg.CORBA.NO_IMPLEMENT ();
//    }
}
