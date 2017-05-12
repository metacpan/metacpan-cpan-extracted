// StackElement.java                                               -*- Java -*-
//   Perl stack element class
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

/**
 * StackElement - A class for elements on the stack
 * 
 * This is just a wrapper that allows for the "pushmark" operator to work 
 * properly.
 *
 * @author Bradley M. Kuhn
 * @version 0.02
**/

class StackElement {
    // LIST_MARK is the "mark" that the Perl stack uses as "pushmark"
    public static StackElement LIST_MARK = new StackElement(true, false);

    // STATE_MARK should always be pushed onto the JVM operand
    // stack when a new state occurs on the Perl operand tree.  It is needed
    // when the "nextstate" comes around, so that it can clean up the stack.
    public static StackElement STATE_MARK = new StackElement(false, true);

    Scalar element;
    boolean listMark;
    boolean stateMark;

    /** Default Constructor for a new stack element.  Note that it is the
     * mark by default
     */
    StackElement() {
        super();
        element = null;
        listMark = false;
        stateMark = false;
    }
    /** Constructor to build a new stack element.
     * @param item name of element to place on the stack
     */
    StackElement(Scalar item) {
        super();
        element = item;
        listMark = false;
        stateMark = false;
    }
    /** Constructor to create a list mark or a state mark
     * @param list true iff. this is to be a list mark
     * @param state true iff. this is to be a state mark
     */
    StackElement(boolean list, boolean state) {
        super();
        if (list && state) {
            state = false;
        }
        element = null;
        listMark = list;
        stateMark = state;
    }

    /** Test to see if this stack element is a list mark 
     ** @return true iff. the element in question is a list mark
     */
    boolean isListMark() {
        return listMark;
    }
    /** Test to see if this stack element is the state mark 
     ** @return true iff. the element in question is the state mark
     */
    boolean isStateMark() {
        return stateMark;
    }
    /** gets the Scalar value of the element
     */
    Scalar getElement() {
        return element;
    }
}
