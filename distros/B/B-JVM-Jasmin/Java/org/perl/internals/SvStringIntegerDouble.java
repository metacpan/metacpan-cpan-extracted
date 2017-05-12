// SvStringIntegerDouble.java                                      -*- Java -*-
//   String, Integer and Double Scalar variable,
//      similar to an SvPVNV in the perlguts
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

import java.lang.Double;
import java.lang.Integer;

/**
 * SvStringIntegerDouble - A scalar that only contains string, number and
 * integer values.
 * 
 * This is a simple, straightforward, non-optimized implementation of a
 * scalar variable.
 *
 * @author Bradley M. Kuhn
 * @version 0.02
 */

class SvStringIntegerDouble extends SvString {
    int    integerValue;
    double doubleValue;
    boolean integerOk, doubleOk, stringOk;

    /** Utility function that turns a string into an integer, following the
     * same method that Perl uses.
     * @param s a string to change to an int.
     & @return an integer value in Perl-ish fashion from the string given.
     */
    static int stringToInteger(String s) {
        // FIXME:  This is not the right way to do this.  It is inefficient
        //         and it probably doesn't even work right.

        Integer value = null;
        boolean found = false;

        while (! found) {
            try {
               value = Integer.decode(s);
               found = true;
            } catch (NumberFormatException ne) {
                int len = s.length();

                if (len == 0) {
                    s = "0";
                } else {
                    s = s.substring(0, len-1);
                }
            }
        }
        return value.intValue();
    }

    /** Utility function that turns a string into a double, following the
     * same method that Perl uses.
     * @param s a string to change to an double.
     & @return an double value in Perl-ish fashion from the string given.
     */
    static double stringToDouble(String s) {
        // FIXME:  This is not the right way to do this.  It is inefficient
        //         and it probably doesn't even work right.

        Double value = null;
        boolean found = false;

        while (! found) {
            try {
               value = Double.valueOf(s);
               found = true;
            } catch (NumberFormatException ne) {
                int len = s.length();

                if (len == 0) {
                    s = "0";
                } else {
                    s = s.substring(0, len-1);
                }
            }
        }
        return value.doubleValue();
    }
    /** Creates a new instance of SvString, which is undefined.
     *  @see SvString#SvString()
     */
    SvStringIntegerDouble() {
        super();
        integerValue = 0;
        doubleValue  = 0.0;
        integerOk = doubleOk = stringOk = defined;
    }

    /** Creates a new instance of SvStringIntegerDouble, making a copy of
     * some other SvString.
     * @param old another SvString from which to copy
     */
    SvStringIntegerDouble(SvString old) {
        stringOk = defined  = old.isDefined();
        stringValue = old.stringValue;
        integerOk = doubleOk = false;
    }

    /** Creates a new instance of SvStringIntegerDouble, making a copy of
     * some other SvInteger.
     * @param old another SvInteger from which to copy
     */
    SvStringIntegerDouble(SvInteger old) {
        integerOk = defined = old.isDefined();
        integerValue = old.getIntegerValue();
        stringOk = doubleOk = false;
    }

    /** Creates a new instance of SvStringIntegerDouble, making a copy of
     * some other SvDouble.
     * @param old another SvInteger from which to copy
     */
    SvStringIntegerDouble(SvDouble old) {
        doubleOk = defined = old.isDefined();
        doubleValue = old.getDoubleValue();
        stringOk = integerOk = false;
    }

    /** Creates a new instance of SvStringIntegerDouble, making a copy of
     * some other SvStringIntegerDouble.
     * @param old another SvStringIntegerDouble from which to copy
     */
    SvStringIntegerDouble(SvStringIntegerDouble old) {
        defined   = old.isDefined();
        stringOk  = old.stringOk;
        integerOk = old.integerOk;
        doubleOk  = old.doubleOk;

        doubleValue  = old.doubleValue;
        integerValue = old.integerValue;
        stringValue  = old.stringValue;
    }

    /** Gets the string value of the current Perl variable.  
     * @return the string value of the variable
     */
    String getStringValue() throws InvalidSvFieldException {
        if (! defined) {
            return "";
        } else if (stringOk) {
            return stringValue;
        } else if (doubleOk) {
            stringValue = Double.toString(doubleValue);
            stringOk = true;
            return stringValue;
        } else if (integerOk) {
            stringValue = Integer.toString(integerValue);
            stringOk = true;
            return stringValue;
        } else {
            throw new InvalidSvFieldException("Inconsistent state of values");
        }
    }

    /** Gets the integer value of the current Perl variable.  
     * @return the integer value of the variable
     */
    int getIntegerValue() throws InvalidSvFieldException {
        if (! defined) {
            return 0;
        } else if (integerOk) {
            return integerValue;
        } else if (doubleOk) {
            integerValue = (int) doubleValue;
            integerOk = true;
            return integerValue;
        } else if (stringOk) {
            integerValue = SvStringIntegerDouble.stringToInteger(stringValue);
            integerOk = true;
            return integerValue;
        } else {
            throw new InvalidSvFieldException("Inconsistent state of values");
        }
    }

    /** Gets the double value of the current Perl variable.  
     * @return the double value of the variable
     */
    double getDoubleValue()  throws  InvalidSvFieldException {
        if (! defined) {
            return 0;
        } else if (doubleOk) {
            return doubleValue;
        } else if (integerOk) {
            doubleValue = (double) integerValue;
            doubleOk = true;
            return doubleValue;
        } else if (stringOk) {
            doubleValue = SvStringIntegerDouble.stringToDouble(stringValue);
            doubleOk = true;
            return doubleValue;
        } else {
            throw new InvalidSvFieldException("Inconsistent state of values");
        }
    }

    /** Sets the string value of the current Perl variable.  
     * @param newString the string to use as the new value
     */
    void setStringValue(String newString) {
        stringValue = newString;
        defined = true;
        integerOk = doubleOk = false;
    }

    /** Sets the integer value of the current Perl variable.  
     * @param newInteger the integer to use as the new value
     */
    void setIntegerValue(int newInteger) {
        integerValue = newInteger;
        defined = true;
        stringOk = doubleOk = false;
    }

    /** Sets the double value of the current Perl variable.  
     * @param newDouble the integer to use as the new value
     */
    void setDoubleValue(double newDouble) {
        doubleValue = newDouble;
        defined = true;
        stringOk = integerOk = false;
    }

    /** Morph this SvString so that it can hold a string value.  Since an
     * SvStringIntegerDouble can already hold a string, 'this' is returned.
     * @return the same SvStringIntegerDouble as this.
     * @see org.perl.internals.SvBase#SvString()
     *
     */
    SvBase morphToHoldString() {
        return this;
    }
    /** Morph this SvStringIntegerDouble so that it can hold an integer
     * value.  Since an SvStringIntegerDouble can already hold a string,
     * 'this' is returned.
     * @return the same SvStringIntegerDouble as this.
     * @see org.perl.internals.SvBase#SvInteger()
     * @see org.perl.internals.SvStringInteger#SvStringInteger(SvString)
     * */
    SvBase morphToHoldInteger() {
        return this;
    }
    /** Morph this SvStringIntegerDouble so that it can hold an double
     * value.  Since an SvStringIntegerDouble can already hold a string,
     * 'this' is returned.
     * @return the same SvStringIntegerDouble as this.
     * @see org.perl.internals.SvBase#SvDouble()
     * @see org.perl.internals.SvStringIntegerDouble#SvStringIntegerDouble(SvString)
     * */
    SvBase morphToHoldDouble() {
        return this;
    }
}
