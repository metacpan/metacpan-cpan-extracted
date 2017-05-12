// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 6  The Primitive Types and Their Input/Output
//
// Section:     Section 6.7.4  Explicit Type Conversion in Java  
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//







//ExplicitCast1.java

import java.io.*;

class Test {
    public static void main( String[] args )
    {
        try {
            PrintWriter out = new PrintWriter( 
                                new FileOutputStream( "out_file" ) );      
            char ch_value;
            for (int i=0; i< 10000; i++) {
                ch_value = (char) i;                              //(A)      
                out.println( "for i= " + i + " char is " + ch_value );
            }
            out.close();
        } catch( IOException e) { }
    }
}
