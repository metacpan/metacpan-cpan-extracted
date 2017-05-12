// HV.java                                                        -*- Java -*-
//   Perl Hash value class
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

/**
 * Hash - A class for Perl Hash variables
 * 
 * This is really just a wrapper for Java's hashtables at this point.  In
 * the future, though, we might want to change the implementation of
 * underlying hash tables.  Plus, when magic is added, this might be helpful.
 *
 * @author Bradley M. Kuhn
 * @version 0.02
**/

public class Hash {
    HV table;

    /** Default Constructor: creates a new, empty Hash
     * @param old the old HV to copy
     */
    Hash() {
        table = null;
    }

    /** Constructor: creates a new Hash by copying another Hash
     * @param old the old Hash to copy
     */
    Hash(Hash old) {
        if (old.table != null) {
            table = (HV) old.table.clone();
        } else {
            table = null;
        }
    }

    /** tests if this HV is defined
     * @return true iff. this HV is defined
     */
    boolean isDefined() {
        return (table != null);
    }

    /** get a value from an HV.
     * @param key the key to look up.
     * @return an undefined scalar value if the key is not found, otherwise
     *         the value associated with the key.
     */
    Scalar get(Scalar key) {
        if (table == null) {
            return Scalar.UNDEFINED;
        }
        Scalar value = (Scalar) table.get(key);

        if (value == null) {
            return Scalar.UNDEFINED;
        } else {
            return value;
        }
    }
    /** set a (key, value) in an HV.
     * @param key the key to set.
     * @param value the key to set the key to.
     */
    void put(Scalar key, Scalar value) {
        if (table == null) {
            table = new HV();
        }
        table.put(key, value);
    }
    /** check to see if a hash element  is defined
     * @param key the key to check for definedness.
     */
    boolean elementDefined(Scalar key) {
        return (table != null && table.containsKey(key));
    }
    /** removes an element completely from a hash
     * @param key element to remove
     */
    void delete(Scalar key) {
        if (table != null) {
            table.remove(key);
        }
    }
}
