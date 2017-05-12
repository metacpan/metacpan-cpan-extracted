// GV.java                                                        -*- Java -*-
//   Perl Glob Value representation
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

/**
 * GV - A glob value for Perl
 * 
 * This is an implementation of what is perl calls a GV.
 * It is based on what I read about GVs at:
 * Perl Guts Illustrated, http://home.sol.no/~aas/perl/guts/
 *
 * @author Bradley M. Kuhn
 * @version 0.02
**/

class GV {
    String name;
    Hash hash;
    Scalar scalar;

    /** Constructor to build a new Stash with a given name
     * @param newName name of the new scope
     */
    GV(String newName) {
        super();
        name = newName;
        hash = new Hash();
        scalar = new Scalar();
    }

    /** gets the Scalar from this GV.
     * @return the scalar from this GV.
     */
    Scalar getScalar() {
        if (scalar == null) {
            System.out.println("WHY IS SCALAR NULL");
        } 
        return scalar;
    }

    /** gets the Hash from this GV.
     * @return the hash from this GV.
     */
    Hash getHash() {
        return hash;
    }
}
