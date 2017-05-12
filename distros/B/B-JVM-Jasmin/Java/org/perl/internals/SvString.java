// SvString.java                                                   -*- Java -*-
//   String Scalar variable, similar to an SvPV in the perlguts
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

/**
 * SvString - A scalar that only contains a string value
 * 
 * This is a simple, straightforward, non-optimized implementation of a
 * scalar variable containing only a string.
 *
 * @author Bradley M. Kuhn
 * @version 0.02
 */
class SvString extends SvBase {
    String  stringValue;

    /** Creates a new instance of SvString, which is undefined.
     *  @see SvBase#SvBase()
     */
    SvString() {
        super();
        stringValue = "";
    }

    /** Creates a new instance of SvString, which is defined and set to the
     * given value.
     * @param value The value to set the new string variable to
     */
    SvString(String value) {
        super();
        defined     = true;
        stringValue = value;
    }

    /** Creates a new instance of SvString, making a copy of some other
     * SvString.
     * @param old another SvString from which to copy
     */
    SvString(SvString old) {
        super();
        defined     = old.isDefined();
        stringValue = old.stringValue;
    }

    /** Gets the string value of the current Perl variable.  
     * @return the string value of the variable
     */
    String getStringValue() throws InvalidSvFieldException {
        return (defined) ? stringValue : "";
    }

    /** Sets the string value of the current Perl variable.  
     * @param newString the string to use as the new value
     * @exception InvalidSVFieldException if it turns out this field simply
     *            doesn't exist in this type of variable
     */
    void setStringValue(String newString) {
        stringValue = newString;
        defined = true;
    }

    /** Morph this SvString so that it can hold a string value.  Since an
     * SvString can already hold a string, 'this' is returned.
     * @return the same SvString as this.
     * @see org.perl.internals.SvBase#SvString()
     *
     */
    SvBase morphToHoldString() {
        return this;
    }
    /** Morph this SvString so that it can hold an integer value.  This is done
     * by creating a new SvStringInteger object and returing it.
     * @return a new SvStringInteger object
     * @see org.perl.internals.SvBase#SvInteger()
     * @see org.perl.internals.SvStringInteger#SvStringInteger(SvString)
     *
     */
    SvBase morphToHoldInteger() {
        return new SvStringIntegerDouble(this);
    }
    /** Morph this SvString so that it can hold an double value.  This is done
     * by creating a new SvStringIntegerDouble object and returing it.
     * @return a new SvStringDouble object
     * @see org.perl.internals.SvBase#SvDouble()
     * @see org.perl.internals.SvStringIntegerDouble#SvStringIntegerDouble(SvString)
     *
     */
    SvBase morphToHoldDouble() {
        return new SvStringIntegerDouble(this);
    }
}
