// Scalar.java                                                     -*- Java -*-
//   Scalar Variable  class
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

/**
 * Scalar - A class for Scalar variables
 * 
 * This class is the one that should be used by clients that want to work
 * with scalar variables.  Internally, it uses the Sv* classes to actually
 * hold the representation.  However, external users (i.e., those outside of
 * org.perl.internals) should not access scalars except through the Scalar
 * class.
 *
 * @author Bradley M. Kuhn
 * @version 0.02
**/

public class Scalar {
    public static Scalar UNDEFINED = new Scalar(true);

    SvBase representation;
    boolean isConstant;    // true iff. this scalar is constant and cannot be
                           // changed

    /** Default Constructor: creates an empty, undefined scalar variable.
     */
    public Scalar() {
        representation = new SvBase();
        isConstant = false;
    }

    /** Constructor: creates an empty, undefined scalar variable.
     * @param constant true iff. this scalar is to be constant value
     */
    public Scalar(boolean constant) {
        representation = new SvBase();
        isConstant = constant;
    }

    /** Constructor: creates a new Scalar by copying another scalar
     * @param oldScalar the old Scalar to copy
     */
    Scalar(Scalar oldScalar) throws ScalarCreationException {
        assignFromScalar(oldScalar);
    }
    /** Constructor: creates a new Scalar given a java/lang/String
     * @param stVal a java/lang/String that will be used to initialize
     *              this scalar
     */
    Scalar(String strVal) {
        representation =  new SvString(strVal);
        isConstant = false;
    }

    /** Constructor: creates a new Scalar given a java/lang/String
     * @param stVal a java/lang/String that will be used to initialize
     *              this scalar
     * @param constant true iff. this scalar is to be constant value
     */
    Scalar(String strVal, boolean constant) {
        representation =  new SvString(strVal);
        isConstant = constant;
    }

    /** Constructor: creates a new Scalar given a native int
     * @param intVal an integer value that will be used to initialize
     *                    this scalar
     */
    Scalar(int intVal) {
        representation =  new SvInteger(intVal);
        isConstant = false;
    }

    /** Gets the string value of this Scalar.  The internal representation 
     * will morph into something that can hold a string, if needed.
     * @return string value of this Scalar
     */
    String getStringValue() throws ScalarException {
        String value;
        try {
            value = representation.getStringValue();
        } catch (InvalidSvFieldException e) {
            representation = representation.morphToHoldString();
            try {
                value = representation.getStringValue();
            } catch (InvalidSvFieldException e2) {
                throw new ScalarException(e2.getMessage());
            }
        }
        return value;
    }

    /** Gets the integer value of this Scalar.  The internal representation 
     * will morph into something that can hold a integer, if needed.
     * @return integer value of this Scalar
     */
    int getIntegerValue() throws ScalarException {
        int value;
        try {
            value = representation.getIntegerValue();
        } catch (InvalidSvFieldException e) {
            representation = representation.morphToHoldInteger();
            try {
                value = representation.getIntegerValue();
            } catch (InvalidSvFieldException e2) {
                throw new ScalarException(e2.getMessage());
            }
        }
        return value;
    }

    /** Gets the double value of this Scalar.  The internal representation 
     * will morph into something that can hold a double, if needed.
     * @return double value of this Scalar
     */
    double getDoubleValue() throws ScalarException {
        double value;
        try {
            value = representation.getDoubleValue();
        } catch (InvalidSvFieldException e) {
            representation = representation.morphToHoldDouble();
            try {
                value = representation.getDoubleValue();
            } catch (InvalidSvFieldException e2) {
                throw new ScalarException(e2.getMessage());
            }
        }
        return value;
    }
    /** Test to see if this Perl variable is defined.  
     * @return a boolean value that indicates if the variable is defined.
     *
     */
    boolean isDefined() {
        return representation.isDefined();
    }
    /** Test to see if this Perl variable's value is true.  
     * @return a boolean value that indicates if the variable's value is true.
     * @exception ScalarException thrown if unuable to get values from Scalar
     */
    boolean isTrue() throws ScalarException {
        if (! this.isDefined()) {
            return false;
        } else {
            String stringValue = this.getStringValue();
            if ( (! stringValue.equals("")) &&
                 (! stringValue.equals("0")) ) {
                return true;
            } else if (this.getDoubleValue() != 0.0) {
                return true;
            } else if (this.getIntegerValue() != 0) {
                return true;
            } else {
                return false;
            }
        }
    }
    /** assign a scalar value from another scalar value.
     * @param oldScalar the old Scalar to assign from
     */
    void assignFromScalar(Scalar oldScalar) throws ScalarCreationException {
        if (isConstant) {
            throw new ScalarCreationException(
                           "assignment to constant Scalar attempted");
        }
        try {
            // Weird stuff going on here.  Since Java doesn't have 
            // true metaclasses, we have to do this stuff.  The basic
            // idea is as follows: Instantiate a copy of the oldScalar's 
            // representation using the constructor for its class that takes
            // itself as an argument.  Note that since all Sv* classes must
            // have a constructor that takes itself as an argument, we can
            // be sure that one is there.  Still, in case something goes wrong,
            // we thrown an exception.  

            representation = (SvBase) oldScalar.representation.performClone();
            
        } catch (Exception e) {
            throw new ScalarCreationException(e.toString());
        }

    }
    /** concatenate another Scalar onto the end of this one.
     * @param other the scalar to concatenate onto the end of this one.
     */
    void concat(Scalar other) throws ScalarException {
        String mine   = this.getStringValue();
        String newValue = mine + other.getStringValue();

        try {
            this.representation.setStringValue(newValue);
        } catch (InvalidSvFieldException isfe) {
            throw new ScalarException(isfe.toString());
        }
    }
    /** do a string equality comparison between this Scalar and another
     * @param other the scalar to compare onto the end of this one.
     * @return a Scalar that is 1 if the two strings are equal, "" if not
     */

    Scalar seq(Scalar other) throws ScalarException {
        if (this.getStringValue().equals(other.getStringValue())) {
            return new Scalar(1);
        } else {
            return new Scalar("");
        }
    }

    /** do a string non-equality comparison between this Scalar and another
     * @param other the scalar to compare onto the end of this one.
     * @return a Scalar that is "" if the two strings are equal, 1 if not
     */

    Scalar sne(Scalar other) throws ScalarException {
        if (this.getStringValue().equals(other.getStringValue())) {
            return new Scalar("");
        } else {
            return new Scalar(1);
        }
    }
}
