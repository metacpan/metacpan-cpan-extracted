// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 10 Handling Exceptions
//
// Section:     Section 10.4  Differences Between C++ And Java For Exception Handling
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//TryCatch.java

import java.io.*;

class Err extends Exception { }

class Test {
    public static void main( String[] args )
    {
        try {
            f(0);
        } catch( Err e ) {
            System.out.println( "Exception caught in main" );     
        }
    }
  
    static void f(int j) throws Err {                             
        System.out.println( "function f invoked with j = " + j );
        if (j == 3) throw new Err();                              
        f( ++j );
    }
}