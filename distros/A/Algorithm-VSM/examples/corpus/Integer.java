// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 13  Generics And Templates
//
// Section:     Section 13.3.3  Constraining the Parameters
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//Integer.java
// code by Bracha, Odersky, Stoutamire, and Wadler
// with inconsequential changes by the author

import java.util.*;

interface Comparable {
    public int compareTo( Object that );                          //(A)
}

class Integer implements Comparable {
    private int value;

    public Integer( int value ) { this.value = value; }

    public int intValue() { return value; }

    public int compareTo( Integer that ) {                        //(B) 
        return this.value - that.value;
    }

    public int compareTo( Object that ) {                         //(C)
        return this.compareTo( ( Integer ) that );
    }

    public String toString() { return "" + value; }
}

class Collections {
    public static Comparable max( Collection coll ) {
        Iterator it = coll.iterator();
        Comparable max = ( Comparable ) it.next();
        while ( it.hasNext() ) {
            Comparable next = ( Comparable ) it.next();
            if ( max.compareTo( next ) < 0 ) max = next;
        }
        return max;
    }
}

class Test {
    public static void main( String[] args ) {

        // int collection
        LinkedList intList = new LinkedList();
        intList.add( new Integer( 0 ) ); 
        intList.add( new Integer( 1 ) );
        Integer maxVal = ( Integer ) Collections.max( intList );
        System.out.println( "Max value: " + maxVal );     // 1
    }
}