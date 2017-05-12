// SvBase.java                                                     -*- Java -*-
//   Scalar variable representation base class
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

/**
 * SvBase - Scalar variable representation base class
 * 
 * This class is most like SvNULL in the perlguts.  It is always undefined.
 * It is primarily used as a base class for other Perl variable
 * representations, hence the name.
 *
 * @author Bradley M. Kuhn
 * @version 0.02
 */

class SvBase implements Cloneable {
    boolean defined;

    /** Creates a new instance of SvBase, which is undefined.
     */
    SvBase() {
        defined = false;
    }

    /** Creates a new instance of an SvBase, given another SvBase.
     * @param old The old SvBase (not actually used)
     */
    SvBase(SvBase old) {
        defined = false;
    }

    SvBase performClone() throws CloneNotSupportedException {
        return (SvBase) this.clone();
    }

    /** Gets the string value of the current Perl variable.  Since there
     * is no string field here, this simply throws the exception.
     * @return the string value of the variable
     * @exception InvalidSvFieldException if it turns out this field simply
     *            doesn't exist in this type of variable
     */
    String getStringValue() throws InvalidSvFieldException {
        throw new InvalidSvFieldException("Class does not have string value.");
    }
    /** Gets the integer value of the current Perl variable.  Since there
     * is no integer field here, this simply throws the exception.
     * @return the integer value of the variable
     * @exception InvalidSvFieldException if it turns out this field simply
     *            doesn't exist in this type of variable
     */
    int getIntegerValue() throws InvalidSvFieldException {
        throw new 
            InvalidSvFieldException("Class does not have integer value.");
    }

    /** Gets the integer value of the current Perl variable.  Since there
     * is no integer field here, this simply throws the exception.
     * @return the double value of the variable
     * @exception InvalidSvFieldException if it turns out this field simply
     *            doesn't exist in this type of variable
     */
    double getDoubleValue() throws InvalidSvFieldException {
        throw new InvalidSvFieldException("Class does not have double value.");
    }

    /** Sets the string value of the current Perl variable.  Since SvBase has
     * no string value, this simply throws the exception.
     * @param newString the string to use as the new value
     * @exception InvalidSvFieldException if it turns out this field simply
     *            doesn't exist in this type of variable
     */
    void setStringValue(String newString)
        throws InvalidSvFieldException {
        throw new InvalidSvFieldException("Class does not have string value.");
    }

    /** Sets the integer value of the current Perl variable.  Since SvBase has
     * no integer value, this simply throws the exception.
     * @param newInt the integer to use as the new value
     * @exception InvalidSvFieldException if it turns out this field simply
     *            doesn't exist in this type of variable
     */
    void setIntegerValue(int newInt) throws InvalidSvFieldException  {
        throw new 
            InvalidSvFieldException("Class does not have integer value.");
    }

    /** Sets the double value of the current Perl variable.  Since SvBase has
     * no integer value, this simply throws the exception.
     * @param newDouble the double to use as the new value
     * @exception InvalidSvFieldException if it turns out this field simply
     *            doesn't exist in this type of variable
     */
    void setDoubleValue(double newDouble)
        throws InvalidSvFieldException   {
        throw new InvalidSvFieldException("Class does not have double value.");
    }


    /** Test to see if this Perl variable is defined.
     * @return a boolean value that indicates if the variable is defined.
     *
     */
    boolean isDefined() {
        return defined;
    }

    /** Undefine this Perl variable
     */
    void undef() {
        defined = false;
    }

    /** Morph this SvBase so that it can hold a string value.  This is done
     * by creating a new SvString object and returing it.
     * @return a new undefined SvString object 
     * @see org.perl.internals.SvString#SvString()
     *
     */
    SvBase morphToHoldString() {
        return new SvString();
    }
    /** Morph this SvBase so that it can hold an integer value.  This is done
     * by creating a new SvInteger object and returing it.
     * @return a new undefined SvInteger object
     * @see org.perl.internals.SvInteger#SvInteger()
     *
     */
    SvBase morphToHoldInteger() {
        return new SvInteger();
    }
    /** Morph this SvBase so that it can hold an double value.  This is done
     * by creating a new SvDouble object and returing it.
     * @return a new undefined SvDouble object
     * @see org.perl.internals.SvDouble#SvDouble()
     *
     */
    SvBase morphToHoldDouble() {
        return new SvDouble();
    }
}
