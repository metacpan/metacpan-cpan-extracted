// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 3 ---- The Notion Of A Class And Some Other Key Ideas
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




//TestTwo.java
package packageX;                                            //(B)

import packageX.*;                                           //(C)

public class TestTwo {
    TestOne testone = new TestOne();                         //(D)

    public void print() { 
        System.out.println( "print of packageX.TestTwo invoked" ); 
    }
    public static void main( String[] args ) {
        TestTwo testtwo = new TestTwo();
        testtwo.print();
        testtwo.testone.print();
    }
}