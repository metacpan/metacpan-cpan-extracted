// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 5  ----  Using the Container Classes
//
// Section:     Section 5.2.4 ----  Vector
//


//VectorOps.java

import java.io.*;
import java.util.*;

class VectorOps {
    public static void main( String[] args )
    {
        Vector charVec = new Vector();                            //(A)

        charVec.addElement( new Character( 'c' ) );               //(B)
        charVec.addElement( new Character( 'a' ) );               //(C)
        charVec.addElement( new Character( 't' ) );               //(D)

        int n = charVec.size();                   // 3            //(E)

        char[] charArray = new char[charVec.size()];              //(F)
        for ( int i=0; i<charVec.size(); i++ ) {                  //(G)
            Character charac = (Character) charVec.elementAt(i);  //(H)
            charArray[i] = charac.charValue();                    //(I)
        }
        String str =  new String( charArray );                    //(J)
        System.out.println( str );                // cat          //(K)
    }
}
