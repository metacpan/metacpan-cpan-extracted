// SvInteger.java                                                 -*- Java -*-
//   Integer Scalar variable, similar to an SvIV in the perlguts
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

/**
 * SvInteger - A scalar that only contains an integer value
 * 
 * This is a simple, straightforward, non-optimized implementation of a
 * scalar variable containing only an integer.
 *
 * @author Bradley M. Kuhn
 * @version 0.02
 * @see SvString
 * @see SvBase
 * @see SV
 */
class SvInteger extends SvBase {
    int  integerValue;

    /** Creates a new instance of SvInteger, which is undefined.
     *  @see SvBase#SvBase()
     */
    SvInteger() {
        super();
        integerValue = 0;
    }

    /** Creates a new instance of SvInteger, which is defined and set to the
     * given value.
     * @param value The value to set the new integer scalar
     */
    SvInteger(int value) {
        defined     = true;
        integerValue = value;
    }

    /** Creates a new instance of SvInteger, making a copy of some other
     * SvInteger.
     * @param old another SvInteger from which to copy
     */
    SvInteger(SvInteger old) {
        defined      = old.isDefined();
        integerValue = old.getIntegerValue();
    }

    /** Gets the integer value of the current Perl variable.  
     * @return the integer value of the variable
     */
    public int getIntegerValue()  {
        return (defined) ? integerValue : 0;
    }

    /** Sets the integer value of the current Perl variable.  
     * @param newInt the integer to use as the new value
     */
    public void setIntegerValue(int newInt) {
        defined = true;
        integerValue = newInt;
    }

    /** Morph this SvInteger so that it can hold a string value. This is done
      * by creating a new SvStringInteger object and returing it.
      * @return a new SvStringInteger
      * @see org.perl.internals.SvStringInteger#SvStringInteger(SvInteger)
      */
    SvBase morphToHoldString() {
        return new SvStringIntegerDouble(this);
    }
    /** Morph this SvInteger so that it can hold an integer value.   Since an
     * SvInteger can already hold an integer, 'this' is returned.
     * @return a new SvStringInteger object
     */
    SvBase morphToHoldInteger() {
        return this;
    }
    /** Morph this SvInteger so that it can hold an double value.  This is done
     * by creating a new SvIntegerDouble object and returing it.
     * @return a new SvIntegerDouble object
     * @see org.perl.internals.SvStringInteger#SvIntegerDouble(SvInteger)
     *
     */
    SvBase morphToHoldDouble() {
        return new SvStringIntegerDouble(this);
    }
}
