/*
 * @(#)XMLInputStream.java
 *
 * Copyright 2004, Francois PERRAD
 */

package org.omg.CORBA.portable;

import org.omg.CORBA.TypeCode;
import org.omg.CORBA.Any;

/**
 * XMLInputStream is the Java API for reading IDL types
 * from XML/WS-I marshal streams. These methods are used by the ORB to
 * unmarshal IDL types as well as to extract IDL types out of Anys.
 */

public abstract class XMLInputStream extends java.io.InputStream
{

    public abstract void read_open_tag (java.lang.String tag);

    public abstract void read_close_tag (java.lang.String tag);

    public abstract java.lang.String read_pcdata ();

    /**
     * Reads a boolean value from this input stream.
     *
     * @return the <code>boolean</code> value read from this input stream
     */
    public abstract boolean read_boolean (java.lang.String tag);
    /**
     * Reads a char value from this input stream.
     *
     * @return the <code>char</code> value read from this input stream
     */
    public abstract char read_char (java.lang.String tag);
    /**
     * Reads a wide char value from this input stream.
     *
     * @return the <code>char</code> value read from this input stream
     */
    public abstract char read_wchar (java.lang.String tag);
    /**
     * Reads an octet (that is, a byte) value from this input stream.
     *
     * @return the <code>byte</code> value read from this input stream
     */
    public abstract byte read_octet (java.lang.String tag);
    /**
     * Reads a short value from this input stream.
     *
     * @return the <code>short</code> value read from this input stream
     */
    public abstract short read_short (java.lang.String tag);
    /**
     * Reads a unsigned short value from this input stream.
     *
     * @return the <code>short</code> value read from this input stream
     */
    public abstract short read_ushort (java.lang.String tag);
    /**
     * Reads a CORBA long (that is, Java int) value from this input stream.
     *
     * @return the <code>int</code> value read from this input stream
     */
    public abstract int read_long (java.lang.String tag);
    /**
     * Reads an unsigned CORBA long (that is, Java int) value from this input stream.
     *
     * @return the <code>int</code> value read from this input stream
     */
    public abstract int read_ulong (java.lang.String tag);
    /**
     * Reads a CORBA longlong (that is, Java long) value from this input stream.
     *
     * @return the <code>long</code> value read from this input stream
     */
    public abstract long read_longlong (java.lang.String tag);
    /**
     * Reads a CORBA unsigned longlong (that is, Java long) value from this input stream.
     *
     * @return the <code>long</code> value read from this input stream
     */
    public abstract long read_ulonglong (java.lang.String tag);
    /**
     * Reads a float value from this input stream.
     *
     * @return the <code>float</code> value read from this input stream
     */
    public abstract float read_float (java.lang.String tag);
    /**
     * Reads a double value from this input stream.
     *
     * @return the <code>double</code> value read from this input stream
     */
    public abstract double read_double (java.lang.String tag);
    /**
     * Reads a string value from this input stream.
     *
     * @return the <code>String</code> value read from this input stream
     */
    public abstract java.lang.String read_string (java.lang.String tag);
    /**
     * Reads a wide string value from this input stream.
     *
     * @return the <code>String</code> value read from this input stream
     */
    public abstract java.lang.String read_wstring (java.lang.String tag);
    /**
     * Reads a BigDecimal number.
     * @return a java.math.BigDecimal number
     */
    public abstract java.math.BigDecimal read_fixed (java.lang.String tag);

    /**
     * Reads a CORBA object from this input stream.
     *
     * @return the <code>Object</code> instance read from this input stream
     */
    public abstract org.omg.CORBA.Object read_Object (java.lang.String tag);
    /**
     * Reads a TypeCode from this input stream.
     *
     * @return the <code>TypeCode</code> instance read from this input stream
     */
    public abstract org.omg.CORBA.TypeCode read_TypeCode (java.lang.String tag);
    /**
     * Reads an Any from this input stream.
     *
     * @return the <code>Any</code> instance read from this input stream
     */
    public abstract org.omg.CORBA.Any read_any (java.lang.String tag);

    /**
     * @see <a href="package-summary.html#unimpl"><code>portable</code>
     * package comments for unimplemented features</a>
     */
    public int read() throws java.io.IOException
    {
        throw new org.omg.CORBA.NO_IMPLEMENT ();
    }

    /**
     * Reads a CORBA context from the stream.
     * @return a CORBA context
     * @see <a href="package-summary.html#unimpl"><code>portable</code>
     * package comments for unimplemented features</a>
     */
//    public org.omg.CORBA.Context read_Context ()
//    {
//        throw new org.omg.CORBA.NO_IMPLEMENT ();
//    }
    /*
     * The following methods were added by orbos/98-04-03: Java to IDL
     * Mapping. These are used by RMI over IIOP.
     */

    /**
     * Returns the ORB that created this InputStream.
     *
     * @return the <code>ORB</code> object that created this stream
     *
     * @see <a href="package-summary.html#unimpl"><code>portable</code>
     * package comments for unimplemented features</a>
     */
//    public org.omg.CORBA.ORB orb() {
//	throw new org.omg.CORBA.NO_IMPLEMENT();
//    }

}
