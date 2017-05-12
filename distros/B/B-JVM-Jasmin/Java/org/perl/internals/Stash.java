// Stash.java                                                    -*- Java -*-
//   Perl Symbol table representation
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

// "No - I think that I dropped my stash."  -- Mimi, "Light My Candle", _RENT_

package org.perl.internals;

/**
 * Stash - A symbol table for Perl's global symbols
 * 
 * This is an implementation of what is perl calls a "stash", a "symbol
 * table hash".  It is based on what I read about stashes at:
 * Perl Guts Illustrated, http://home.sol.no/~aas/perl/guts/
 *
 * Note that entries in the Stash that end in :: are of type Stash, but
 *  those that do not are GV's.  This can be a bit confusing, but this saves
 *  wasting space for a GV for every Stash entry, since it would only use the 
 *  HV field anyway.  
 *
 * @author Bradley M. Kuhn
 * @version 0.02
**/

class Stash extends HV {
    static Stash DEF_STASH = new Stash("main");

    String name;

    /** Constructor to build a new Stash with a given name
     * @param newName name of the new scope
     */
    Stash(String newName) {
        super();
        name = newName;
    }

    /** finds a namespace given its name
     * @param nameSought the namespace we want the stash for
     * @return the stash called nameSought, null if it is not found
     */
    Stash findNamespace(String nameSought) {
        int colonAt = nameSought.indexOf("::", 0);
        if (colonAt == -1) {
            return (Stash) this.get(nameSought);
        } else {
            Stash newLookup = (Stash) this.get(
                                       nameSought.substring(0, colonAt+3));
            if (newLookup == null) {
                newLookup = this.createSubNamespace(this, nameSought);
            }
            return newLookup.findNamespace(nameSought.substring(colonAt+2,
                                                      nameSought.length()));
        }
    }
    /** creates a subnamespace
     * @param parent the namespace that the new namespace will be under
     * @param subSpaceName the subnamespace to create
     * @return the stash 
     */
    Stash createSubNamespace(Stash parent, String subSpaceName) {
        System.err.println("FIXME: createSubNamespace\n");
        // FIXME
        return null;
    }
    /** finds a GV in the current namespace
     * @param nameSought the name of the GV sought
     * @return the GV called nameSought, null if it is not found
     */
    GV findGV(String nameSought) {
        // FIXME: NAME SPACE SHOULD BE HANDLED HERE!  IT IS NOT AT ALL!
        GV gv = (GV) this.get(nameSought);

        if (gv == null) {
            gv = new GV(nameSought);
            this.put(nameSought, gv);
        }
        return gv;
    }
}
