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
 * HV - A class for internal hash values
 * 
 * This is really just a wrapper for Java's hashtables at this point.  In
 * the future, though, we might want to change the implementation of
 * underlying hash tables.  Plus, when magic is added, this might be helpful.
 *
 * @author Bradley M. Kuhn
 * @version 0.02
**/

import java.util.Hashtable;

class HV extends Hashtable { }
