// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 7  Declarations, Definitions, And Initializations
//
// Section:     Section 7.10.2  java.lang.Arrays Class for Sorting, Searching, and so on
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//







//ArraysShuffle.java

import java.util.*;

class Test {
    public static void main( String[] args ) {

        Integer[] intArr2 = new Integer[10];                      //(A)

        for ( int i=0; i<intArr2.length; i++ )                    //(B)
            intArr2[i] = new Integer(i);

        List list = Arrays.asList( intArr2 );                     //(C)

        Collections.shuffle( list );                              //(D)

        Integer[] intArr3 = (Integer[]) list.toArray();           //(E)

        for ( int i=0; i<intArr2.length; i++ )                    //(F)
            System.out.print( intArr3[ i ].intValue() + " " );
                    // 9 8 5 1 3 4 7 2 6 0  (different with each run)
        System.out.println();      
    }
}