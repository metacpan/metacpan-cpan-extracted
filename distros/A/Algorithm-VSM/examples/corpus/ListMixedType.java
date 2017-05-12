// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 13  Generics And Templates
//
// Section:     Section 13.3  Parameterized Classes In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//ListMixedType.java

import java.util.*;

class ListMixedType {
    public static void main( String[] args ) {
        List list = new ArrayList();
        list.add( "one" );
        list.add( "two" );    
        list.add( "three" );
        //   list.add( new Integer( 4 ) );                         //(A)

        ListIterator iter = list.listIterator();
        while ( iter.hasNext() )
            System.out.println( (String) iter.next() );            //(B)
    }
}