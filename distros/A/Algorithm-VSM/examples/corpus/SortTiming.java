// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 3 ---- The NOtion Of A Class And Some Other Key Ideas
//
// Section:     Section 3.9 -- Packages In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//SortTiming.java

import java.util.*;                                               //(A)

class Test {
    public static void main( String[] args ) {
        int[] arr = new int[1000000];                             //(B)
        for ( int i=0; i<1000000; i++ )
            arr[i] = (int) ( 1000000 * Math.random() );           //(C)
        long startTime = System.currentTimeMillis();              //(D)
        Arrays.sort( arr );                                       //(E)
        long diffTime = System.currentTimeMillis() - startTime;   //(F)
        System.out.println("Sort time in millisecs: " + diffTime);//(G)
    }
}
