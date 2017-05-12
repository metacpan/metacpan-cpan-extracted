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




//TestFinal.java
import packageX.*;                                           //(F)

public class TestFinal {
    packageX.TestOne testone_X = new packageX.TestOne();     //(G)
    packageY.TestOne testone_Y = new packageY.TestOne();     //(H)
    TestTwo testtwo = new TestTwo();                         //(I)

    void print() { 
        System.out.println( "print of TestFinal invoked" ); 
    }

    public static void main( String[] args ) {
        TestFinal tf = new TestFinal();
        tf.print();
        tf.testone_X.print();
        tf.testone_Y.print();
        tf.testtwo.print();
    }
}