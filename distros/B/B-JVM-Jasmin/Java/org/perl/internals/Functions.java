// Functions.java                                               -*- Java -*-
//   Perl functions class
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

/**
 * Functions - A class to hold methods corresponding to Perl functions
 * 
 * This class contains all the static functions that correspond to functions
 * in 'perlfunc'
 *
 * @author Bradley M. Kuhn
 * @version 0.02
**/

public class Functions {

    static public int print(Scalar arg) {
        int retVal = 1;
        try {
            System.out.print(arg.getStringValue());
        } catch (ScalarException se) {
            retVal = 0;
        }
        return retVal;
    }
}
