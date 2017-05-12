// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 5 ---- Using the Container Classes
//
// Section:     Section 5.2.4 ----  vector
//


//VectorListOps.java

import java.io.*;
import java.util.*;

class VectorListOps {
    public static void main( String[] args )
    {
        Vector charVec = new Vector();                            //(A)

        charVec.addElement( new Character( 'c' ) );               //(B)
        charVec.addElement( new Character( 'a' ) );               //(C)
        charVec.addElement( new Character( 't' ) );               //(D)

        charVec.insertElementAt(new Character('h'), 1); // chat   //(E)
        charVec.removeElementAt( 0 );                   // hat    //(F)
        charVec.addElement( new Character( 's' ) );     // hats   //(G)
        charVec.removeElement( new Character( 't' ) );  // has    //(H)
     
        System.out.println( charVec.size() );           // 3

        char[] charArray = new char[charVec.size()];
        for ( int i=0; i<charVec.size(); i++ ) {
            Character Ch = (Character) charVec.elementAt(i); 
            charArray[i] = Ch.charValue();
        }
        String str =  new String( charArray );
        System.out.println( str );                      // has
   
    }
}
