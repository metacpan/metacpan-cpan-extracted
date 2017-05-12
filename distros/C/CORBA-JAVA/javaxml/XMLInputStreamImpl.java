/*
 * @(#)XMLInputStreamImpl.java
 *
 * Copyright 2004, Francois PERRAD
 * See below for extracts from AElfred XML Parser
 */

import java.io.*;
import java.net.URL;
import java.util.Hashtable;
import java.util.Stack;

import org.xml.sax.*;
import org.xml.sax.helpers.*;

import org.omg.CORBA.Any;
import org.omg.CORBA.TypeCode;

public class XMLInputStreamImpl extends org.omg.CORBA.portable.XMLInputStream
{
	//Fields
	private org.xml.sax.ErrorHandler	errorHandler;
	private BufferedReader	reader; 	// current reader
	private boolean emptyElement;

	//Constructors
	public XMLInputStreamImpl (InputStream _is, org.xml.sax.ErrorHandler _errorHandler)
	{
		errorHandler = _errorHandler;
		try {
			Reader r = new InputStreamReader (_is, "UTF-8");
			reader = new BufferedReader (r);
		} catch (java.io.UnsupportedEncodingException e) {
		}
		_init();
	}

	public XMLInputStreamImpl (InputStream _is)
	{
		this (_is, new org.xml.sax.helpers.DefaultHandler ());
	}

	public XMLInputStreamImpl (org.xml.sax.InputSource source, org.xml.sax.ErrorHandler _errorHandler)
	{
		errorHandler = _errorHandler;
		reader = _getReaderFromSource (source);
		_init ();
	}

	public XMLInputStreamImpl (org.xml.sax.InputSource source)
	{
		this (source, new org.xml.sax.helpers.DefaultHandler ());
	}

	private BufferedReader _getReaderFromSource (org.xml.sax.InputSource source)
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
			try {
				r = new InputStreamReader (is, "UTF-8");
			} catch (java.io.UnsupportedEncodingException e) {
			}
		}
		return new BufferedReader (r);
	}

	private void _init ()
	{
		initializeVariables ();

		// predeclare the built-in entities here (replacement texts)
		// we don't need to intern(), since we're guaranteed literals
		// are always (globally) interned.
		setInternalEntity ("amp", "&#38;");
		setInternalEntity ("lt", "&#60;");
		setInternalEntity ("gt", "&#62;");
		setInternalEntity ("apos", "&#39;");
		setInternalEntity ("quot", "&#34;");

		try {
			pushURL ();
			parseMisc ();
		} catch (IOException ee) {
			throw new org.omg.CORBA.MARSHAL (ee.toString ());
		} catch (org.xml.sax.SAXException se) {
			throw new org.omg.CORBA.MARSHAL (se.toString ());
		}
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
		reader.close ();
		cleanupVariables ();
		super.close ();
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


    /**
     * Parse an element, with its tags.
     * <pre>
     * [39] element ::= EmptyElementTag | STag content ETag
     * [40] STag ::= '&lt;' Name (S Attribute)* S? '&gt;'
     * [44] EmptyElementTag ::= '&lt;' Name (S Attribute)* S? '/&gt;'
     * </pre>
     * <p> (The '&lt;' has already been read.)
     * <p>NOTE: this method actually chains onto parseContent (), if necessary,
     * and parseContent () will take care of calling parseETag ().
     */
    public void read_open_tag (java.lang.String tag)
    {
        String  gi;
        char    c;

        emptyElement = false;

        try {
            while (true) {
                require ('<', "open_tag");
                // Read the element type name.
                gi = readNmtoken (true);

                // Read the attributes, if any.
                // After this loop, "c" is the closing delimiter.
                boolean white = tryWhitespace ();
                c = readCh ();
                while (c != '/' && c != '>') {
                    unread (c);
                    if (!white)
                        error ("need whitespace between attributes");
                    parseAttribute (gi);
                    white = tryWhitespace ();
                    c = readCh ();
                }

                // Figure out if this is a start tag
                // or an empty element, and dispatch an
                // event accordingly.
                switch (c) {
                case '>':
                    if (! gi.equals(tag)) {
                        currentElement = gi;
                        parseContent ();
                    }
                    break;
                case '/':
                    require ('>', "empty element tag");
                    if (gi.equals(tag))
                        emptyElement = true;
                    break;
                }
                if (gi.equals(tag))
                    break;
            }
        } catch (org.xml.sax.SAXException se) {
            throw new org.omg.CORBA.MARSHAL (se.toString ());
        } catch (IOException e) {
            throw new org.omg.CORBA.MARSHAL (e.toString ());
        }
        return;
    }

    /**
     * Parse an end tag.
     * <pre>
     * [42] ETag ::= '</' Name S? '>'
     * </pre>
     */
    public void read_close_tag (java.lang.String tag)
    {
        if (emptyElement) {
            return;
        }

        try {
            require (tag, "element end tag");
            skipWhitespace ();
            require ('>', "name in end tag");
        } catch (org.xml.sax.SAXException se) {
            throw new org.omg.CORBA.MARSHAL (se.toString ());
        } catch (IOException e) {
            throw new org.omg.CORBA.MARSHAL (e.toString ());
        }
        return;
    }

    /**
     * Parse the content of an element.
     * <pre>
     * [43] content ::= (element | CharData | Reference
     *		| CDSect | PI | Comment)*
     * [67] Reference ::= EntityRef | CharRef
     * </pre>
     */
    public java.lang.String read_pcdata ()
    {
        if (emptyElement) {
            return "";
        }

        StringBuffer data = new StringBuffer();
        boolean ETag = false;
        char c;

        try {
            while (!ETag) {

                parseCharData();

                // Handle delimiters
                c = readCh ();
                switch (c) {
                case '&': 			// Found "&"

                    c = readCh ();
                    if (c == '#') {
                        parseCharRef ();
                    } else {
                        unread (c);
                        parseEntityRef (true);
                    }
                    break;

                case '<': 			// Found "<"
                    data.append (dataBuffer, 0, dataBufferPos);
                    dataBufferPos = 0;
                    c = readCh ();
                    switch (c) {
                    case '!': 			// Found "<!"
                        c = readCh ();
                        switch (c) {
                        case '-': 		// Found "<!-"
                            require ('-', "start of comment");
                            parseComment ();
                            break;
                        case '[': 		// Found "<!["
                            require ("CDATA[", "CDATA section");
                            parseCDSect ();
                            data.append (dataBuffer, 0, dataBufferPos);
                            dataBufferPos = 0;
                            break;
                        default:
                            error ("expected comment or CDATA section", c, null);
                            break;
                        }
                        break;

                    case '?': 		// Found "<?"
                        parsePI ();
                        break;

                    case '/': 		// Found "</"
                        ETag = true;
                        break;

                    default: 		// Found "<" followed by something else
                        unread (c);
                        parseElement ();
                        break;
                    }
                }
            }
        } catch (org.xml.sax.SAXException se) {
            throw new org.omg.CORBA.MARSHAL (se.toString ());
        } catch (IOException e) {
            throw new org.omg.CORBA.MARSHAL (e.toString ());
        }

        data.append (dataBuffer, 0, dataBufferPos);
        dataBufferPos = 0;
        return data.toString ();
    }


/*****************************************************************************/
/*
 * Code derived from AElfred XML Parser (file xmlparser.java)
 */

// AElfred XML Parser. This version of the AElfred parser is
// derived from the original Microstar distribution, with additional
// bug fixes by Michael Kay, and selected enhancements and further
// bug fixes from the version produced by David Brownell.
//

/*
 * Copyright (C) 1999-2001 David Brownell
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

//
// Copyright (c) 1997, 1998 by Microstar Software Ltd.
// From Microstar's README (the entire original license):
//
// AElfred is free for both commercial and non-commercial use and
// redistribution, provided that Microstar's copyright and disclaimer are
// retained intact.  You are free to modify AElfred for your own use and
// to redistribute AElfred with your modifications, provided that the
// modifications are clearly documented.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// merchantability or fitness for a particular purpose.  Please use it AT
// YOUR OWN RISK.
//

    // parse from buffer, avoiding slow per-character readCh()
    private final static boolean USE_CHEATS = true;

    ////////////////////////////////////////////////////////////////////////
    // Constants.
    ////////////////////////////////////////////////////////////////////////

    //
    //
    // Constants for the entity type.
    //

    /**
     * Constant: the entity has not been declared.
     * @see #getEntityType
     */
    public final static int ENTITY_UNDECLARED = 0;

    /**
     * Constant: the entity is internal.
     * @see #getEntityType
     */
    public final static int ENTITY_INTERNAL = 1;

    //
    // Constants for input.
    //
    private final static int INPUT_NONE = 0;
    private final static int INPUT_INTERNAL = 1;
    private final static int INPUT_READER = 5;


    //
    // Flags for reading literals.
    //
	// expand general entity refs (attribute values in dtd and content)
    private final static int LIT_ENTITY_REF = 2;
	// normalize this value (space chars) (attributes, public ids)
    private final static int LIT_NORMALIZE = 4;
	// literal is an attribute value
    private final static int LIT_ATTRIBUTE = 8;
	// don't expand parameter entities
    private final static int LIT_DISABLE_PE = 16;
	// don't expand [or parse] character refs
    private final static int LIT_DISABLE_CREF = 32;
	// don't parse general entity refs
    private final static int LIT_DISABLE_EREF = 64;
	// don't expand general entities, but make sure we _could_
    private final static int LIT_ENTITY_CHECK = 128;
	// literal is a public ID value
    private final static int LIT_PUBID = 256;

    //////////////////////////////////////////////////////////////////////
    // Error reporting.
    //////////////////////////////////////////////////////////////////////


    /**
     * Report an error.
     * @param message The error message.
     * @param textFound The text that caused the error (or null).
     * @see SAXDriver#error
     * @see #line
     */
    private void error (String message, String textFound, String textExpected)
    throws SAXException
    {
	if (textFound != null) {
	    message = message + " (found \"" + textFound + "\")";
	}
	if (textExpected != null) {
	    message = message + " (expected \"" + textExpected + "\")";
	}
	error (message);
    }


    /**
     * Report a serious error.
     * @param message The error message.
     * @param textFound The text that caused the error (or null).
     */
    private void error (String message, char textFound, String textExpected)
    throws SAXException
    {
	error (message, new Character (textFound).toString (), textExpected);
    }


    //////////////////////////////////////////////////////////////////////
    // Major syntactic productions.
    //////////////////////////////////////////////////////////////////////


    /**
     * Skip a comment.
     * <pre>
     * [15] Comment ::= '&lt;!--' ((Char - '-') | ('-' (Char - '-')))* "-->"
     * </pre>
     * <p> (The <code>&lt;!--</code> has already been read.)
     */
    private void parseComment ()
    throws SAXException, IOException
    {
	char c;

	parseUntil ("--");
	require ('>', "-- in comment");
	dataBufferPos = 0;
    }


    /**
     * Parse a processing instruction and do a call-back.
     * <pre>
     * [16] PI ::= '&lt;?' PITarget
     *		(S (Char* - (Char* '?&gt;' Char*)))?
     *		'?&gt;'
     * [17] PITarget ::= Name - ( ('X'|'x') ('M'|m') ('L'|l') )
     * </pre>
     * <p> (The <code>&lt;?</code> has already been read.)
     */
    private void parsePI ()
    throws SAXException, IOException
    {
	String name;

	name = readNmtoken (true);
	if ("xml".equalsIgnoreCase (name))
	    error ("Illegal processing instruction target", name, null);
	if (!tryRead ("?>")) {
	    requireWhitespace ();
	    parseUntil ("?>");
	}
	dataBufferPos = 0;
    }


    /**
     * Parse a CDATA section.
     * <pre>
     * [18] CDSect ::= CDStart CData CDEnd
     * [19] CDStart ::= '&lt;![CDATA['
     * [20] CData ::= (Char* - (Char* ']]&gt;' Char*))
     * [21] CDEnd ::= ']]&gt;'
     * </pre>
     * <p> (The '&lt;![CDATA[' has already been read.)
     */
    private void parseCDSect ()
    throws SAXException, IOException
    {
	parseUntil ("]]>");
    }


    /**
     * Parse the XML declaration.
     * <pre>
     * [23] XMLDecl ::= '&lt;?xml' VersionInfo EncodingDecl? SDDecl? S? '?&gt;'
     * [24] VersionInfo ::= S 'version' Eq
     *		("'" VersionNum "'" | '"' VersionNum '"' )
     * [26] VersionNum ::= ([a-zA-Z0-9_.:] | '-')*
     * [32] SDDecl ::= S 'standalone' Eq
     *		( "'"" ('yes' | 'no') "'"" | '"' ("yes" | "no") '"' )
     * [80] EncodingDecl ::= S 'encoding' Eq
     *		( "'" EncName "'" | "'" EncName "'" )
     * [81] EncName ::= [A-Za-z] ([A-Za-z0-9._] | '-')*
     * </pre>
     * <p> (The <code>&lt;?xml</code> and whitespace have already been read.)
     * @return the encoding in the declaration, uppercased; or null
     * @see #parseTextDecl
     * @see #setupDecoding
     */
    private String parseXMLDecl (boolean ignoreEncoding)
    throws SAXException, IOException
    {
	String	version;
	String	encodingName = null;
	String	standalone = null;
	int	flags = LIT_DISABLE_CREF | LIT_DISABLE_PE | LIT_DISABLE_EREF;

	// Read the version.
	require ("version", "XML declaration");
	parseEq ();
	version = readLiteral (flags);
	if (!version.equals ("1.0")) {
	    error ("unsupported XML version", version, "1.0");
	}

	// Try reading an encoding declaration.
	boolean white = tryWhitespace ();
	if (tryRead ("encoding")) {
	    if (!white)
		error ("whitespace required before 'encoding='");
	    parseEq ();
	    encodingName = readLiteral (flags);
	}

	// Try reading a standalone declaration
	if (encodingName != null)
	    white = tryWhitespace ();
	if (tryRead ("standalone")) {
	    if (!white)
		error ("whitespace required before 'standalone='");
	    parseEq ();
	    standalone = readLiteral (flags);
	    if (! ("yes".equals (standalone) || "no".equals (standalone)))
		error ("standalone flag must be 'yes' or 'no'");
	}

	skipWhitespace ();
	require ("?>", "XML declaration");

	return encodingName;
    }


    /**
     * Parse miscellaneous markup outside the document element and DOCTYPE
     * declaration.
     * <pre>
     * [27] Misc ::= Comment | PI | S
     * </pre>
     */
    private void parseMisc ()
    throws SAXException, IOException
    {
	while (true) {
	    skipWhitespace ();
	    if (tryRead ("<?")) {
		parsePI ();
	    } else if (tryRead ("<!--")) {
		parseComment ();
	    } else {
		return;
	    }
	}
    }


    /**
     * Parse an element, with its tags.
     * <pre>
     * [39] element ::= EmptyElementTag | STag content ETag
     * [40] STag ::= '&lt;' Name (S Attribute)* S? '&gt;'
     * [44] EmptyElementTag ::= '&lt;' Name (S Attribute)* S? '/&gt;'
     * </pre>
     * <p> (The '&lt;' has already been read.)
     * <p>NOTE: this method actually chains onto parseContent (), if necessary,
     * and parseContent () will take care of calling parseETag ().
     */
    private void parseElement ()
    throws SAXException, IOException
    {
	String	gi;
	char	c;
	String	oldElement = currentElement;

	// Read the element type name.
	gi = readNmtoken (true);

	// Read the attributes, if any.
	// After this loop, "c" is the closing delimiter.
	boolean white = tryWhitespace ();
	c = readCh ();
	while (c != '/' && c != '>') {
	    unread (c);
	    if (!white)
		error ("need whitespace between attributes");
	    parseAttribute (gi);
	    white = tryWhitespace ();
	    c = readCh ();
	}

	// Figure out if this is a start tag
	// or an empty element, and dispatch an
	// event accordingly.
	switch (c) {
	case '>':
	    parseContent ();
	    break;
	case '/':
	    require ('>', "empty element tag");
	    break;
	}

	// Restore the previous state.
	currentElement = oldElement;
    }


    /**
     * Parse an attribute assignment.
     * <pre>
     * [41] Attribute ::= Name Eq AttValue
     * </pre>
     * @param name The name of the attribute's element.
     * @see SAXDriver#attribute
     */
    private void parseAttribute (String name)
    throws SAXException, IOException
    {
	String aname;
	String value;
	int flags = LIT_ATTRIBUTE |  LIT_ENTITY_REF;

	// Read the attribute name.
	aname = readNmtoken (true);

	// Parse '='
	parseEq ();

	    value = readLiteral (flags);

	dataBufferPos = 0;
    }


    /**
     * Parse an equals sign surrounded by optional whitespace.
     * <pre>
     * [25] Eq ::= S? '=' S?
     * </pre>
     */
    private void parseEq ()
    throws SAXException, IOException
    {
	skipWhitespace ();
	require ('=', "attribute name");
	skipWhitespace ();
    }


    /**
     * Parse an end tag.
     * <pre>
     * [42] ETag ::= '</' Name S? '>'
     * </pre>
     * <p>NOTE: parseContent () chains to here, we already read the
     * "&lt;/".
     */
    private void parseETag ()
    throws SAXException, IOException
    {
	require (currentElement, "element end tag");
	skipWhitespace ();
	require ('>', "name in end tag");
    }


    /**
     * Parse the content of an element.
     * <pre>
     * [43] content ::= (element | CharData | Reference
     *		| CDSect | PI | Comment)*
     * [67] Reference ::= EntityRef | CharRef
     * </pre>
     * <p> NOTE: consumes ETtag.
     */
    private void parseContent ()
    throws SAXException, IOException
    {
	char c;
	while (true) {

	    parseCharData();

	    // Handle delimiters
	    c = readCh ();
	    switch (c) {
	    case '&': 			// Found "&"

    		c = readCh ();
    		if (c == '#') {
    		    parseCharRef ();
    		} else {
    		    unread (c);
    		    parseEntityRef (true);
    		}
    		break;

	    case '<': 			// Found "<"
    		dataBufferFlush ();
    		c = readCh ();
    		switch (c) {
    		  case '!': 			// Found "<!"
    		    c = readCh ();
    		    switch (c) {
    		      case '-': 		// Found "<!-"
        			require ('-', "start of comment");
        			parseComment ();
        			break;
    		      case '[': 		// Found "<!["
        			require ("CDATA[", "CDATA section");
        			parseCDSect ();
        			break;
    		      default:
        			error ("expected comment or CDATA section", c, null);
        			break;
    		    }
    		    break;

    		  case '?': 		// Found "<?"
    		    parsePI ();
    		    break;

    		  case '/': 		// Found "</"
    		    parseETag ();
    		    dataBufferPos = 0;				// FP : flush
    		    return;

    		  default: 		// Found "<" followed by something else
    		    unread (c);
    		    parseElement ();
    		    break;
    		}
	        }
	    }
    }


    /**
     * Read and interpret a character reference.
     * <pre>
     * [66] CharRef ::= '&#' [0-9]+ ';' | '&#x' [0-9a-fA-F]+ ';'
     * </pre>
     * <p>NOTE: the '&#' has already been read.
     */
    private void parseCharRef ()
    throws SAXException, IOException
    {
	int value = 0;
	char c;

	if (tryRead ('x')) {
loop1:
	    while (true) {
		c = readCh ();
		switch (c) {
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
		case 'a':
		case 'A':
		case 'b':
		case 'B':
		case 'c':
		case 'C':
		case 'd':
		case 'D':
		case 'e':
		case 'E':
		case 'f':
		case 'F':
		    value *= 16;
		    value += Integer.parseInt (new Character (c).toString (),
				    16);
		    break;
		case ';':
		    break loop1;
		default:
		    error ("illegal character in character reference", c, null);
		    break loop1;
		}
	    }
	} else {
loop2:
	    while (true) {
		c = readCh ();
		switch (c) {
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
		    value *= 10;
		    value += Integer.parseInt (new Character (c).toString (),
				    10);
		    break;
		case ';':
		    break loop2;
		default:
		    error ("illegal character in character reference", c, null);
		    break loop2;
		}
	    }
	}

	// check for character refs being legal XML
	if ((value < 0x0020
		&& ! (value == '\n' || value == '\t' || value == '\r'))
		|| (value >= 0xD800 && value <= 0xDFFF)
		|| value == 0xFFFE || value == 0xFFFF
		|| value > 0x0010ffff)
	    error ("illegal XML character reference U+"
		    + Integer.toHexString (value));

	// Check for surrogates: 00000000 0000xxxx yyyyyyyy zzzzzzzz
	//  (1101|10xx|xxyy|yyyy + 1101|11yy|zzzz|zzzz:
	if (value <= 0x0000ffff) {
	    // no surrogates needed
	    dataBufferAppend ((char) value);
	} else if (value <= 0x0010ffff) {
	    value -= 0x10000;
	    // > 16 bits, surrogate needed
	    dataBufferAppend ((char) (0xd800 | (value >> 10)));
	    dataBufferAppend ((char) (0xdc00 | (value & 0x0003ff)));
	} else {
	    // too big for surrogate
	    error ("character reference " + value + " is too large for UTF-16",
		   new Integer (value).toString (), null);
	}
    }


    /**
     * Parse and expand an entity reference.
     * <pre>
     * [68] EntityRef ::= '&' Name ';'
     * </pre>
     * <p>NOTE: the '&amp;' has already been read.
     * @param externalAllowed External entities are allowed here.
     */
    private void parseEntityRef (boolean externalAllowed)
    throws SAXException, IOException
    {
	String name;

	name = readNmtoken (true);
	require (';', "entity reference");
	switch (getEntityType (name)) {
	case ENTITY_UNDECLARED:
	    error ("reference to undeclared entity", name, null);
	    break;
	case ENTITY_INTERNAL:
	    pushString (name, getEntityValue (name));
	    break;
	}
    }


    /**
     * Parse character data.
     * <pre>
     * [14] CharData ::= [^&lt;&amp;]* - ([^&lt;&amp;]* ']]&gt;' [^&lt;&amp;]*)
     * </pre>
     */
    private void parseCharData ()
    throws SAXException, IOException
    {
	char c;

	// Start with a little cheat -- in most
	// cases, the entire sequence of
	// character data will already be in
	// the readBuffer; if not, fall through to
	// the normal approach.
	if (USE_CHEATS) {
	    int lineAugment = 0;
	    int columnAugment = 0;

loop:
	    for (int i = readBufferPos; i < readBufferLength; i++) {

		switch (c = readBuffer [i]) {
		case '\n':
		    lineAugment++;
		    columnAugment = 0;
		    break;
		case '&':
		case '<':
		    int start = readBufferPos;
		    columnAugment++;
		    readBufferPos = i;
		    if (lineAugment > 0) {
			    line += lineAugment;
			    column = columnAugment;
		    } else {
			    column += columnAugment;
		    }
		    dataBufferAppend (readBuffer, start, i - start);
		    return;
		case ']':
		    // XXX missing two end-of-buffer cases
		    if ((i + 2) < readBufferLength) {
    			if (readBuffer [i + 1] == ']'
    				&& readBuffer [i + 2] == '>') {
    			    error ("character data may not contain ']]>'");
    			}
		    }
		    columnAugment++;
		    break;
		case '\r':
		case '\t':
		    columnAugment++;
		    break;
		default:
		    if (c < 0x0020 || c > 0xFFFD)
			error ("illegal XML character U+"
				+ Integer.toHexString (c));
		    columnAugment++;
		}
	    }
	}

	// OK, the cheat didn't work; start over
	// and do it by the book.

	int closeSquareBracketCount = 0;
	while (true) {
	    c = readCh ();
	    switch (c) {
	    case '<':
	    case '&':
		    unread (c);
		    return;
	    case ']':
	        closeSquareBracketCount++;
	        dataBufferAppend(c);
	        break;
        case '>':
            if (closeSquareBracketCount>=2) {
                // we've hit ']]>'
                error ("']]>' is not allowed here");
                break;
            }
	        closeSquareBracketCount=0;
	        dataBufferAppend (c);
	        break;
	    default:
	        closeSquareBracketCount=0;
		    dataBufferAppend (c);
		    break;
	    }
	}
    }


    //////////////////////////////////////////////////////////////////////
    // High-level reading and scanning methods.
    //////////////////////////////////////////////////////////////////////

    /**
     * Require whitespace characters.
     */
    private void requireWhitespace ()
    throws SAXException, IOException
    {
	char c = readCh ();
	if (isWhitespace (c)) {
	    skipWhitespace ();
	} else {
	    error ("whitespace required", c, null);
	}
    }


    /**
     * Skip whitespace characters.
     * <pre>
     * [3] S ::= (#x20 | #x9 | #xd | #xa)+
     * </pre>
     */
    private void skipWhitespace ()
    throws SAXException, IOException
    {
	// Start with a little cheat.  Most of
	// the time, the white space will fall
	// within the current read buffer; if
	// not, then fall through.
	if (USE_CHEATS) {
	    int lineAugment = 0;
	    int columnAugment = 0;

loop:
	    for (int i = readBufferPos; i < readBufferLength; i++) {
		switch (readBuffer [i]) {
		case ' ':
		case '\t':
		case '\r':
		    columnAugment++;
		    break;
		case '\n':
		    lineAugment++;
		    columnAugment = 0;
		    break;
		default:
		    readBufferPos = i;
		    if (lineAugment > 0) {
			line += lineAugment;
			column = columnAugment;
		    } else {
			column += columnAugment;
		    }
		    return;
		}
	    }
	}

	// OK, do it by the book.
	char c = readCh ();
	while (isWhitespace (c)) {
	    c = readCh ();
	}
	unread (c);
    }


    /**
     * Read a name or (when parsing an enumeration) name token.
     * <pre>
     * [5] Name ::= (Letter | '_' | ':') (NameChar)*
     * [7] Nmtoken ::= (NameChar)+
     * </pre>
     */
    private String readNmtoken (boolean isName)
    throws SAXException, IOException
    {
	char c;

	if (USE_CHEATS) {
loop:
	    for (int i = readBufferPos; i < readBufferLength; i++) {
		c = readBuffer [i];
		switch (c) {
		    // What may legitimately come AFTER a name/nmtoken?
		  case '<': case '>': case '&':
		  case ',': case '|': case '*': case '+': case '?':
		  case ')':
		  case '=':
		  case '\'': case '"':
		  case '[':
		  case ' ': case '\t': case '\r': case '\n':
		  case ';':
		  case '/':
		    int start = readBufferPos;
		    if (i == start)
			error ("name expected", readBuffer [i], null);
		    readBufferPos = i;
		    return intern (readBuffer, start, i - start);

		  default:
		    // punt on exact tests from Appendix A; approximate
		    // them using the Unicode ID start/part rules
		    if (i == readBufferPos && isName) {
			if (!Character.isUnicodeIdentifierStart (c)
				&& c != ':' && c != '_')
			    error ("Not a name start character, U+"
				  + Integer.toHexString (c));
		    } else if (!Character.isUnicodeIdentifierPart (c)
			    && c != '-' && c != ':' && c != '_' && c != '.'
			    && !isExtender (c))
			error ("Not a name character, U+"
				+ Integer.toHexString (c));
		}
	    }
	}

	nameBufferPos = 0;

	// Read the first character.
loop:
	while (true) {
	    c = readCh ();
	    switch (c) {
	    case '%':
	    case '<': case '>': case '&':
	    case ',': case '|': case '*': case '+': case '?':
	    case ')':
	    case '=':
	    case '\'': case '"':
	    case '[':
	    case ' ': case '\t': case '\n': case '\r':
	    case ';':
	    case '/':
		unread (c);
		if (nameBufferPos == 0) {
		    error ("name expected");
		}
		// punt on exact tests from Appendix A, but approximate them
		if (isName
			&& !Character.isUnicodeIdentifierStart (
				nameBuffer [0])
			&& ":_".indexOf (nameBuffer [0]) == -1)
		    error ("Not a name start character, U+"
			      + Integer.toHexString (nameBuffer [0]));
		String s = intern (nameBuffer, 0, nameBufferPos);
		nameBufferPos = 0;
		return s;
	    default:
		// punt on exact tests from Appendix A, but approximate them

		if ((nameBufferPos != 0 || !isName)
			&& !Character.isUnicodeIdentifierPart (c)
			&& ":-_.".indexOf (c) == -1
			&& !isExtender (c))
		    error ("Not a name character, U+"
			    + Integer.toHexString (c));
		if (nameBufferPos >= nameBuffer.length)
		    nameBuffer =
			(char[]) extendArray (nameBuffer,
				    nameBuffer.length, nameBufferPos);
		nameBuffer [nameBufferPos++] = c;
	    }
	}
    }

    private static boolean isExtender (char c)
    {
	// [88] Extender ::= ...
	return c == 0x00b7 || c == 0x02d0 || c == 0x02d1 || c == 0x0387
	       || c == 0x0640 || c == 0x0e46 || c == 0x0ec6 || c == 0x3005
	       || (c >= 0x3031 && c <= 0x3035)
	       || (c >= 0x309d && c <= 0x309e)
	       || (c >= 0x30fc && c <= 0x30fe);
    }


    /**
     * Read a literal.  With matching single or double quotes as
     * delimiters (and not embedded!) this is used to parse:
     * <pre>
     *	[9] EntityValue ::= ... ([^%&amp;] | PEReference | Reference)* ...
     *	[10] AttValue ::= ... ([^<&] | Reference)* ...
     *	[11] SystemLiteral ::= ... (URLchar - "'")* ...
     *	[12] PubidLiteral ::= ... (PubidChar - "'")* ...
     * </pre>
     * as well as the quoted strings in XML and text declarations
     * (for version, encoding, and standalone) which have their
     * own constraints.
     */
    private String readLiteral (int flags)
    throws SAXException, IOException
    {
	char	delim, c;
	int	startLine = line;

	// Find the first delimiter.
	delim = readCh ();
	if (delim != '"' && delim != '\'' && delim != (char) 0) {
	    error ("expected '\"' or \"'\"", delim, null);
	    return null;
	}

	// Each level of input source has its own buffer; remember
	// ours, so we won't read the ending delimiter from any
	// other input source, regardless of entity processing.
	char ourBuf [] = readBuffer;

	// Read the literal.
	try {
	    c = readCh ();
loop:
	    while (! (c == delim && readBuffer == ourBuf)) {
		switch (c) {
		    // attributes and public ids are normalized
		    // in almost the same ways
		case '\n':
		case '\r':
		    if ((flags & (LIT_ATTRIBUTE | LIT_PUBID)) != 0)
			c = ' ';
		    break;
		case '\t':
		    if ((flags & LIT_ATTRIBUTE) != 0)
			c = ' ';
		    break;
		case '&':
		    c = readCh ();
		    // Char refs are expanded immediately, except for
		    // all the cases where it's deferred.
		    if (c == '#') {
			if ((flags & LIT_DISABLE_CREF) != 0) {
			    dataBufferAppend ('&');
			    continue;
			}
			parseCharRef ();

		    // It looks like an entity ref ...
		    } else {
			unread (c);
			// Expand it?
			if ((flags & LIT_ENTITY_REF) > 0) {
			    parseEntityRef (false);

			// Is it just data?
			} else if ((flags & LIT_DISABLE_EREF) != 0) {
			    dataBufferAppend ('&');
			}
		    }
		    c = readCh ();
		    continue loop;

		case '<':
		    // and why?  Perhaps so "&foo;" expands the same
		    // inside and outside an attribute?
		    if ((flags & LIT_ATTRIBUTE) != 0)
			error ("attribute values may not contain '<'");
		    break;

		// We don't worry about case '%' and PE refs, readCh does.

		default:
		    break;
		}
		dataBufferAppend (c);
		c = readCh ();
	    }
	} catch (EOFException e) {
	    error ("end of input while looking for delimiter (started on line "
		   + startLine + ')', null, new Character (delim).toString ());
	}

	// Return the value.
	return dataBufferToString ();
    }


    /**
     * Test if a character is whitespace.
     * <pre>
     * [3] S ::= (#x20 | #x9 | #xd | #xa)+
     * </pre>
     * @param c The character to test.
     * @return true if the character is whitespace.
     */
    private final boolean isWhitespace (char c)
    {
	if (c > 0x20)
	    return false;
	if (c == 0x20 || c == 0x0a || c == 0x09 || c == 0x0d)
	    return true;
	return false;	// illegal ...
    }


    //////////////////////////////////////////////////////////////////////
    // Utility routines.
    //////////////////////////////////////////////////////////////////////


    /**
     * Add a character to the data buffer.
     */
    private void dataBufferAppend (char c)
    {
	// Expand buffer if necessary.
	if (dataBufferPos >= dataBuffer.length)
	    dataBuffer =
		(char[]) extendArray (dataBuffer,
			dataBuffer.length, dataBufferPos);
	dataBuffer [dataBufferPos++] = c;
    }


    /**
     * Add a string to the data buffer.
     */
    private void dataBufferAppend (String s)
    {
	dataBufferAppend (s.toCharArray (), 0, s.length ());
    }


    /**
     * Append (part of) a character array to the data buffer.
     */
    private void dataBufferAppend (char ch[], int start, int length)
    {
	dataBuffer = (char[])
		extendArray (dataBuffer, dataBuffer.length,
				    dataBufferPos + length);

	System.arraycopy (ch, start, dataBuffer, dataBufferPos, length);
	dataBufferPos += length;
    }


    /**
     * Convert the data buffer to a string.
     */
    private String dataBufferToString ()
    {
	String s = new String (dataBuffer, 0, dataBufferPos);
	dataBufferPos = 0;
	return s;
    }


    /**
     * Flush the contents of the data buffer to the handler, as
     * appropriate, and reset the buffer for new input.
     */
    private void dataBufferFlush ()
    {
	    dataBufferPos = 0;
    }


    /**
     * Require a string to appear, or throw an exception.
     * <p><em>Precondition:</em> Entity expansion is not required.
     * <p><em>Precondition:</em> data buffer has no characters that
     * will get sent to the application.
     */
    private void require (String delim, String context)
    throws SAXException, IOException
    {
	int	length = delim.length ();
	char	ch [];

	if (length < dataBuffer.length) {
	    ch = dataBuffer;
	    delim.getChars (0, length, ch, 0);
	} else
	    ch = delim.toCharArray ();

	if (USE_CHEATS
		&& length <= (readBufferLength - readBufferPos)) {
	    int offset = readBufferPos;

	    for (int i = 0; i < length; i++, offset++)
		if (ch [i] != readBuffer [offset])
		    error ("unexpected characters in " + context, null, delim);
	    readBufferPos = offset;

	} else {
	    for (int i = 0; i < length; i++)
		require (ch [i], delim);
	}
    }


    /**
     * Require a character to appear, or throw an exception.
     */
    private void require (char delim, String after)
    throws SAXException, IOException
    {
	char c = readCh ();

	if (c != delim) {
	    error ("unexpected character after " + after, c, delim+"");
	}
    }


    /**
     * Create an interned string from a character array.
     * &AElig;lfred uses this method to create an interned version
     * of all names and name tokens, so that it can test equality
     * with <code>==</code> instead of <code>String.equals ()</code>.
     *
     * <p>This is much more efficient than constructing a non-interned
     * string first, and then interning it.
     *
     * @param ch an array of characters for building the string.
     * @param start the starting position in the array.
     * @param length the number of characters to place in the string.
     * @return an interned string.
     * @see #intern (String)
     * @see java.lang.String#intern
     */
    public String intern (char ch[], int start, int length)
    {
	int	index = 0;
	int	hash = 0;
	Object	bucket [];

	// Generate a hash code.
	for (int i = start; i < start + length; i++)
	    hash = 31 * hash + ch [i];
	hash = (hash & 0x7fffffff) % SYMBOL_TABLE_LENGTH;

	// Get the bucket -- consists of {array,String} pairs
	if ((bucket = symbolTable [hash]) == null) {
	    // first string in this bucket
	    bucket = new Object [8];

	// Search for a matching tuple, and
	// return the string if we find one.
	} else {
	    while (index < bucket.length) {
		char chFound [] = (char []) bucket [index];

		// Stop when we hit a null index.
		if (chFound == null)
		    break;

		// If they're the same length, check for a match.
		if (chFound.length == length) {
		    for (int i = 0; i < chFound.length; i++) {
			// continue search on failure
			if (ch [start + i] != chFound [i]) {
			    break;
			} else if (i == length - 1) {
			    // That's it, we have a match!
			    return (String) bucket [index + 1];
			}
		    }
		}
		index += 2;
	    }
	    // Not found -- we'll have to add it.

	    // Do we have to grow the bucket?
	    bucket = (Object []) extendArray (bucket, bucket.length, index);
	}
	symbolTable [hash] = bucket;

	// OK, add it to the end of the bucket -- "local" interning.
	// Intern "globally" to let applications share interning benefits.
	String s = new String (ch, start, length).intern ();
	bucket [index] = s.toCharArray ();
	bucket [index + 1] = s;
	return s;
    }


    /**
     * Ensure the capacity of an array, allocating a new one if
     * necessary.  Usually called only a handful of times.
     */
    private Object extendArray (Object array, int currentSize, int requiredSize)
    {
	if (requiredSize < currentSize) {
	    return array;
	} else {
	    Object newArray = null;
	    int newSize = currentSize * 2;

	    if (newSize <= requiredSize)
		newSize = requiredSize + 1;

	    if (array instanceof char[])
		newArray = new char [newSize];
	    else if (array instanceof Object[])
		newArray = new Object [newSize];
	    else
		throw new RuntimeException ();

	    System.arraycopy (array, 0, newArray, 0, currentSize);
	    return newArray;
	}
    }


    //////////////////////////////////////////////////////////////////////
    // XML query routines.
    //////////////////////////////////////////////////////////////////////


    //
    // Entities
    //

    /**
     * Find the type of an entity.
     * @returns An integer constant representing the entity type.
     * @see #ENTITY_UNDECLARED
     * @see #ENTITY_INTERNAL
     * @see #ENTITY_NDATA
     * @see #ENTITY_TEXT
     */
    public int getEntityType (String ename)
    {
	Object entity[] = entityInfo.get (ename);
	if (entity == null) {
	    return ENTITY_UNDECLARED;
	} else {
	    return ((Integer) entity [0]).intValue ();
	}
    }


    /**
     * Return the value of an internal entity.
     * @param ename The name of the internal entity.
     * @return The entity's value, or null if the entity was
     *	 not declared, or if it is not an internal entity.
     * @see #getEntityType
     */
    public String getEntityValue (String ename)
    {
	Object entity[] = entityInfo.get (ename);
	if (entity == null) {
	    return null;
	} else {
	    return (String) entity [3];
	}
    }


    /**
     * Register an entity declaration for later retrieval.
     */
    private void setInternalEntity (String eName, String value)
    {
	setEntity (eName, ENTITY_INTERNAL, null, null, value, null);
    }


    /**
     * Register an entity declaration for later retrieval.
     */
    private void setEntity (String eName, int eClass,
		     String pubid, String sysid,
		     String value, String nName)
    {
	Object entity[];

	if (entityInfo.get (eName) == null) {
	    entity = new Object [6];
	    entity [0] = new Integer (eClass);
	    entity [1] = pubid;
	    entity [2] = sysid;
	    entity [3] = value;
	    entity [4] = nName;

	    entityInfo.put (eName, entity);
	}
    }


    //////////////////////////////////////////////////////////////////////
    // High-level I/O.
    //////////////////////////////////////////////////////////////////////


    /**
     * Read a single character from the readBuffer.
     * <p>The readDataChunk () method maintains the buffer.
     * <p>If we hit the end of an entity, try to pop the stack and
     * keep going.
     * <p> (This approach doesn't really enforce XML's rules about
     * entity boundaries, but this is not currently a validating
     * parser).
     * <p>This routine also attempts to keep track of the current
     * position in external entities, but it's not entirely accurate.
     * @return The next available input character.
     * @see #unread (char)
     * @see #unread (String)
     * @see #readDataChunk
     * @see #readBuffer
     * @see #line
     * @return The next character from the current input source.
     */
    private char readCh ()
    throws SAXException, IOException
    {
	// As long as there's nothing in the
	// read buffer, try reading more data
	// (for an external entity) or popping
	// the entity stack (for either).
	while (readBufferPos >= readBufferLength) {
	    switch (sourceType) {
	    case INPUT_READER:
		readDataChunk ();
		while (readBufferLength < 1) {
		    popInput ();
		    if (readBufferLength < 1) {
			readDataChunk ();
		    }
		}
		break;

	    default:

		popInput ();
		break;
	    }
	}

	char c = readBuffer [readBufferPos++];

	if (c == '\n') {
	    line++;
	    column = 0;
	} else {
	    if (c == '<') {
		/* the most common  return to parseContent () .. NOP */ ;
	    } else if ((c < 0x0020 && (c != '\t') && (c != '\r')) || c > 0xFFFD)
		error ("illegal XML character U+"
			+ Integer.toHexString (c));

	    column++;
	}

	return c;
    }


    /**
     * Push a single character back onto the current input stream.
     * <p>This method usually pushes the character back onto
     * the readBuffer, while the unread (String) method treats the
     * string as a new internal entity.
     * <p>I don't think that this would ever be called with
     * readBufferPos = 0, because the methods always reads a character
     * before unreading it, but just in case, I've added a boundary
     * condition.
     * @param c The character to push back.
     * @see #readCh
     * @see #unread (String)
     * @see #unread (char[])
     * @see #readBuffer
     */
    private void unread (char c)
    throws SAXException
    {
	// Normal condition.
	if (c == '\n') {
	    line--;
	    column = -1;
	}
	if (readBufferPos > 0) {
	    readBuffer [--readBufferPos] = c;
	} else {
	    pushString (null, new Character (c).toString ());
	}
    }


    /**
     * Push a char array back onto the current input stream.
     * <p>NOTE: you must <em>never</em> push back characters that you
     * haven't actually read: use pushString () instead.
     * @see #readCh
     * @see #unread (char)
     * @see #unread (String)
     * @see #readBuffer
     * @see #pushString
     */
    private void unread (char ch[], int length)
    throws SAXException
    {
	for (int i = 0; i < length; i++) {
	    if (ch [i] == '\n') {
		line--;
		column = -1;
	    }
	}
	if (length < readBufferPos) {
	    readBufferPos -= length;
	} else {
	    pushCharArray (null, ch, 0, length);
	}
    }


    /**
     * Push a new external input source.
     * The source will be some kind of parsed entity, such as a PE
     * (including the external DTD subset) or content for the body.
     * <p>TODO: Right now, this method always attempts to autodetect
     * the encoding; in the future, it should allow the caller to
     * request an encoding explicitly, and it should also look at the
     * headers with an HTTP connection.
     * @param url The java.net.URL object for the entity.
     * @see SAXDriver#resolveEntity
     * @see #pushString
     * @see #sourceType
     * @see #pushInput
     * @see #detectEncoding
     * @see #sourceType
     * @see #readBuffer
     */
    private void pushURL (
    ) throws SAXException, IOException
    {
	// Push the existing status.
	pushInput ("[document]");

	// Create a new read buffer.
	// (Note the four-character margin)
	readBuffer = new char [READ_BUFFER_MAX + 4];
	readBufferPos = 0;
	readBufferLength = 0;
	readBufferOverflow = -1;
	line = 1;
	column = 0;
	currentByteCount = 0;

	    sourceType = INPUT_READER;
	    tryEncodingDecl (true);
    }


    /**
     * Check for an encoding declaration.  This is the second part of the
     * XML encoding autodetection algorithm, relying on detectEncoding to
     * get to the point that this part can read any encoding declaration
     * in the document (using only US-ASCII characters).
     *
     * <p> Because this part starts to fill parser buffers with this data,
     * it's tricky to to a reader so that Java's built-in decoders can be
     * used for the character encodings that aren't built in to this parser
     * (such as EUC-JP, KOI8-R, Big5, etc).
     *
     * @return any encoding in the declaration, uppercased; or null
     * @see detectEncoding
     */
    private String tryEncodingDecl (boolean ignoreEncoding)
    throws SAXException, IOException
    {
	// Read the XML/text declaration.
	if (tryRead ("<?xml")) {
	    dataBufferFlush ();
	    if (tryWhitespace ()) {
		    return parseXMLDecl (ignoreEncoding);
	    } else {
		unread ("xml".toCharArray (), 3);
		parsePI ();
	    }
	}
	return null;
    }


    /**
     * This method pushes a string back onto input.
     * <p>It is useful either as the expansion of an internal entity,
     * or for backtracking during the parse.
     * <p>Call pushCharArray () to do the actual work.
     * @param s The string to push back onto input.
     * @see #pushCharArray
     */
    private void pushString (String ename, String s)
    throws SAXException
    {
	char ch[] = s.toCharArray ();
	pushCharArray (ename, ch, 0, ch.length);
    }


    /**
     * Push a new internal input source.
     * <p>This method is useful for expanding an internal entity,
     * or for unreading a string of characters.  It creates a new
     * readBuffer containing the characters in the array, instead
     * of characters converted from an input byte stream.
     * @param ch The char array to push.
     * @see #pushString
     * @see #pushURL
     * @see #readBuffer
     * @see #sourceType
     * @see #pushInput
     */
    private void pushCharArray (String ename, char ch[], int start, int length)
    throws SAXException
    {
	// Push the existing status
	pushInput (ename);
	sourceType = INPUT_INTERNAL;
	readBuffer = ch;
	readBufferPos = start;
	readBufferLength = length;
	readBufferOverflow = -1;
    }


    /**
     * Save the current input source onto the stack.
     * <p>This method saves all of the global variables associated with
     * the current input source, so that they can be restored when a new
     * input source has finished.  It also tests for entity recursion.
     * <p>The method saves the following global variables onto a stack
     * using a fixed-length array:
     * <ol>
     * <li>sourceType
     * <li>externalEntity
     * <li>readBuffer
     * <li>readBufferPos
     * <li>readBufferLength
     * <li>line
     * <li>encoding
     * </ol>
     * @param ename The name of the entity (if any) causing the new input.
     * @see #popInput
     * @see #sourceType
     * @see #externalEntity
     * @see #readBuffer
     * @see #readBufferPos
     * @see #readBufferLength
     * @see #line
     * @see #encoding
     */
    private void pushInput (String ename)
    throws SAXException
    {
	Object input[] = new Object [12];

	// Don't bother if there is no current input.
	if (sourceType == INPUT_NONE) {
	    return;
	}

	// Set up a snapshot of the current
	// input source.
	input [0] = new Integer (sourceType);
	input [2] = readBuffer;
	input [3] = new Integer (readBufferPos);
	input [4] = new Integer (readBufferLength);
	input [5] = new Integer (line);
	input [7] = new Integer (readBufferOverflow);
	input [9] = new Integer (currentByteCount);
	input [10] = new Integer (column);
	input [11] = reader;

	// Push it onto the stack.
	inputStack.push (input);
    }


    /**
     * Restore a previous input source.
     * <p>This method restores all of the global variables associated with
     * the current input source.
     * @exception java.io.EOFException
     *    If there are no more entries on the input stack.
     * @see #pushInput
     * @see #sourceType
     * @see #externalEntity
     * @see #readBuffer
     * @see #readBufferPos
     * @see #readBufferLength
     * @see #line
     * @see #encoding
     */
    private void popInput ()
    throws SAXException, IOException
    {
	// Throw an EOFException if there
	// is nothing else to pop.
	if (inputStack.isEmpty ()) {
	    throw new EOFException ("no more input");
	}

	Object[] input = inputStack.pop ();

	sourceType = ((Integer) input [0]).intValue ();
	readBuffer = (char[]) input [2];
	readBufferPos = ((Integer) input [3]).intValue ();
	readBufferLength = ((Integer) input [4]).intValue ();
	line = ((Integer) input [5]).intValue ();
	readBufferOverflow = ((Integer) input [7]).intValue ();
	currentByteCount = ((Integer) input [9]).intValue ();
	column = ((Integer) input [10]).intValue ();
	reader = (BufferedReader) input [11];
    }


    /**
     * Return true if we can read the expected character.
     * <p>Note that the character will be removed from the input stream
     * on success, but will be put back on failure.  Do not attempt to
     * read the character again if the method succeeds.
     * @param delim The character that should appear next.  For a
     *	      insensitive match, you must supply this in upper-case.
     * @return true if the character was successfully read, or false if
     *	 it was not.
     * @see #tryRead (String)
     */
    private boolean tryRead (char delim)
    throws SAXException, IOException
    {
	char c;

	// Read the character
	c = readCh ();

	// Test for a match, and push the character
	// back if the match fails.
	if (c == delim) {
	    return true;
	} else {
	    unread (c);
	    return false;
	}
    }


    /**
     * Return true if we can read the expected string.
     * <p>This is simply a convenience method.
     * <p>Note that the string will be removed from the input stream
     * on success, but will be put back on failure.  Do not attempt to
     * read the string again if the method succeeds.
     * <p>This method will push back a character rather than an
     * array whenever possible (probably the majority of cases).
     * <p><b>NOTE:</b> This method currently has a hard-coded limit
     * of 100 characters for the delimiter.
     * @param delim The string that should appear next.
     * @return true if the string was successfully read, or false if
     *	 it was not.
     * @see #tryRead (char)
     */
    private boolean tryRead (String delim)
    throws SAXException, IOException
    {
	char ch[] = delim.toCharArray ();
	char c;

	// Compare the input, character-
	// by character.

	for (int i = 0; i < ch.length; i++) {
	    c = readCh ();
	    if (c != ch [i]) {
		unread (c);
		if (i != 0) {
		    unread (ch, i);
		}
		return false;
	    }
	}
	return true;
    }


    /**
     * Return true if we can read some whitespace.
     * <p>This is simply a convenience method.
     * <p>This method will push back a character rather than an
     * array whenever possible (probably the majority of cases).
     * @return true if whitespace was found.
     */
    private boolean tryWhitespace ()
    throws SAXException, IOException
    {
	char c;
	c = readCh ();
	if (isWhitespace (c)) {
	    skipWhitespace ();
	    return true;
	} else {
	    unread (c);
	    return false;
	}
    }


    /**
     * Read all data until we find the specified string.
     * This is useful for scanning CDATA sections and PIs.
     * <p>This is inefficient right now, since it calls tryRead ()
     * for every character.
     * @param delim The string delimiter
     * @see #tryRead (String, boolean)
     * @see #readCh
     */
    private void parseUntil (String delim)
    throws SAXException, IOException
    {
	char c;
	int startLine = line;

	try {
	    while (!tryRead (delim)) {
		c = readCh ();
		dataBufferAppend (c);
	    }
	} catch (EOFException e) {
	    error ("end of input while looking for delimiter "
		+ "(started on line " + startLine
		+ ')', null, delim);
	}
    }


    //////////////////////////////////////////////////////////////////////
    // Low-level I/O.
    //////////////////////////////////////////////////////////////////////


    /**
     * Read a chunk of data from an external input source.
     * <p>This is simply a front-end that fills the rawReadBuffer
     * with bytes, then calls the appropriate encoding handler.
     * @see #encoding
     * @see #rawReadBuffer
     * @see #readBuffer
     * @see #filterCR
     * @see #copyUtf8ReadBuffer
     */
    private void readDataChunk ()
    throws SAXException, IOException
    {
	int count;

	// See if we have any overflow (filterCR sets for CR at end)
	if (readBufferOverflow > -1) {
	    readBuffer [0] = (char) readBufferOverflow;
	    readBufferOverflow = -1;
	    readBufferPos = 1;
	    sawCR = true;
	} else {
	    readBufferPos = 0;
	    sawCR = false;
	}

	// input from a character stream.
	    count = reader.read (readBuffer,
			    readBufferPos, READ_BUFFER_MAX - readBufferPos);
	    if (count < 0)
		readBufferLength = readBufferPos;
	    else
		readBufferLength = readBufferPos + count;
	    if (readBufferLength > 0)
		filterCR (count >= 0);
	    sawCR = false;

    }


    /**
     * Filter carriage returns in the read buffer.
     * CRLF becomes LF; CR becomes LF.
     * @param moreData true iff more data might come from the same source
     * @see #readDataChunk
     * @see #readBuffer
     * @see #readBufferOverflow
     */
    private void filterCR (boolean moreData)
    {
	int i, j;

	readBufferOverflow = -1;

loop:
	for (i = j = readBufferPos; j < readBufferLength; i++, j++) {
	    switch (readBuffer [j]) {
	    case '\r':
		if (j == readBufferLength - 1) {
		    if (moreData) {
			readBufferOverflow = '\r';
			readBufferLength--;
		    } else 	// CR at end of buffer
			readBuffer [i++] = '\n';
		    break loop;
		} else if (readBuffer [j + 1] == '\n') {
		    j++;
		}
		readBuffer [i] = '\n';
		break;

	    case '\n':
	    default:
		readBuffer [i] = readBuffer [j];
		break;
	    }
	}
	readBufferLength = i;
    }


    //////////////////////////////////////////////////////////////////////
    // Local Variables.
    //////////////////////////////////////////////////////////////////////

    /**
     * Re-initialize the variables for each parse.
     */
    private void initializeVariables ()
    {
	// First line
	line = 1;
	column = 0;

	// Set up the buffers for data and names
	dataBufferPos = 0;
	dataBuffer = new char [DATA_BUFFER_INITIAL];
	nameBufferPos = 0;
	nameBuffer = new char [NAME_BUFFER_INITIAL];

	// Set up the DTD hash tables
	entityInfo = new Hashtable<String, Object[]> ();

	// Set up the variables for the current
	// element context.
	currentElement = null;

	// Set up the input variables
	sourceType = INPUT_NONE;
	inputStack = new Stack<Object[]> ();
	readBufferOverflow = -1;

	symbolTable = new Object [SYMBOL_TABLE_LENGTH][];
    }


    /**
     * Clean up after the parse to allow some garbage collection.
     */
    private void cleanupVariables ()
    {
	dataBuffer = null;
	nameBuffer = null;

	entityInfo = null;

	currentElement = null;

	inputStack = null;

	symbolTable = null;
    }

    //
    // I/O information.
    //
    private Stack<Object[]>	inputStack; 	// stack of input soruces
    private int		line; 		// current line number
    private int		column; 	// current column number
    private int		sourceType; 	// type of input source
    private int		currentByteCount; // bytes read from current source

    //
    // Buffers for decoded but unparsed character input.
    //
    private char	readBuffer [];
    private int		readBufferPos;
    private int		readBufferLength;
    private int		readBufferOverflow;  // overflow from last data chunk.


    //
    // Buffer for undecoded raw byte input.
    //
    private final static int READ_BUFFER_MAX = 16384;


    //
    // Buffer for parsed character data.
    //
    private static int DATA_BUFFER_INITIAL = 4096;
    private char	dataBuffer [];
    private int		dataBufferPos;

    //
    // Buffer for parsed names.
    //
    private static int NAME_BUFFER_INITIAL = 1024;
    private char	nameBuffer [];
    private int		nameBufferPos;


    //
    // Hashtables for DTD information on elements, entities, and notations.
    //
    private Hashtable<String, Object[]>	entityInfo;


    //
    // Element type currently in force.
    //
    private String	currentElement;

    //
    // Symbol table, for caching interned names.
    //
    private final static int SYMBOL_TABLE_LENGTH = 1087;
    private Object	symbolTable [][];

    //
    // Utility flag: have we noticed a CR while reading the last
    // data chunk?  If so, we will have to go back and normalise
    // CR or CR/LF line ends.
    //
    private boolean	sawCR;

}
