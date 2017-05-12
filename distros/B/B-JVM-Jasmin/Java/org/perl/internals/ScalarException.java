// ScalarExecption.java                                        -*- Java -*-
//   General Exception that is thrown out of the Scalar class when something
//      unfixable goes wrong.
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

class ScalarException extends Exception {
    ScalarException(String newMessage) {
        super(newMessage);
    }
}
