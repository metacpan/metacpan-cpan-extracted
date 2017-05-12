// SvDouble.java                                                  -*- Java -*-
//   Double Scalar variable, similar to SvNV in the perlguts
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.


package org.perl.internals;

/**
 * SvDouble - A scalar that only contains a double value
 * 
 * This is a simple, straightforward, non-optimized implementation of a
 * scalar variable containing only a double.
 *
 * @author Bradley M. Kuhn
 * @version 0.02
 */

class SvDouble extends SvBase {
    double doubleValue;

    /** Creates a new instance of SvDouble, which is undefined.
     *  @see SvBase#SvBase()
     */
    SvDouble() {
        super();
        doubleValue = 0.0;
    }

    /** Creates a new instance of SvDouble, which is defined and set to the
     * given value.
     * @param value The value to set the new double scalar
     */
    SvDouble(double value) {
        defined     = true;
        doubleValue = value;
    }

    /** Creates a new instance of SvDouble, making a copy of some other
     * SvDouble.
     * @param old another SvDouble from which to copy
     */
    SvDouble(SvDouble old) {
        defined     = old.isDefined();
        doubleValue = old.getDoubleValue();
    }

    /** Gets the double value of the current Perl variable.  
     * @return the double value of the variable
     */
    double getDoubleValue()  {
        return (defined) ? doubleValue : 0;
    }

    /** Sets the double value of the current Perl variable.  
     * @param newDouble the double to use as the new value
     */
    void setIntegerValue(double newDouble) {
        defined     = true;
        doubleValue = newDouble;
    }

    /** Morph this SvDouble so that it can hold a string value. This is done
      * by creating a new SvStringIntegerDouble object and returing it.
      * @return a new SvStringIntegerDouble
      * @see org.perl.internals.SvStringIntegerDouble#SvStringIntegerDouble(SvDouble)
      */
    SvBase morphToHoldString() {
        return new SvStringIntegerDouble(this);
    }

    /** Morph this SvDouble so that it can hold an integer value.  This is done
     * by creating a new SvStringIntegerDouble object and returing it.
     * @return a new SvStringIntegerDouble object
     * @see org.perl.internals.SvStringIntegerDouble#SvStringIntegerDouble(SvDouble)
     */
    SvBase morphToHoldInteger() {
        return new SvStringIntegerDouble(this);
    }
    /** Morph this SvDouble so that it can hold an double value.   Since an
     * SvDouble can already hold a double, 'this' is returned.
     * @return this same SvDouble
     *
     */
    SvBase morphToHoldDouble() {
        return this;
    }
}
