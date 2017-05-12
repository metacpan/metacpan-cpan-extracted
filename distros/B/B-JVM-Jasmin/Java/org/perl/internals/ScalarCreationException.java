// ScalarCreationException.java                                    -*- Java -*-
//   Exception that is thrown if not able to create a Scalar
//
//   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
//
// You may distribute under the terms of either the GNU General Public License
// or the Artistic License, as specified in the LICENSE file that was shipped
// with this distribution.

package org.perl.internals;

class ScalarCreationException extends Exception {
    ScalarCreationException(String newMessage) {
        super(newMessage);
    }
}
