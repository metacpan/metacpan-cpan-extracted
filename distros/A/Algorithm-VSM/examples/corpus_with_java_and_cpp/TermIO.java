// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:    Chapter 2 -- Baby Steps 
//
// Section:    Section 2.2 --- Simple Programs: Terminal I/O
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//





//TermIO.java

import java.io.*;

class TermIO {

    static boolean newline;                                       //(A)      

    public static void main( String[] args ) {  
        int sum = 0;
        System.out.println( "Enter a sequence of integers: " );
        while ( newline == false ) {
            String str = readString();                            //(B)
            if ( str != null ) {
                int i = Integer.parseInt( str );                  //(C)
                sum += i; 
            }
        }
        System.out.println( "Sum of the numbers is: " + sum );
    }

    static String readString() {                                  //(D)
        String word = "";                       
        try {
            int ch;
            while ( ( ch = System.in.read() ) == ' ' )            //(E)
                ;
            if ( ch == '\n' ) {                                   //(F)
                newline = true;                                   //(G)
                return null;                                      //(H)
            }
            word += (char) ch;                                    //(I)
            while ( ( ch = System.in.read() ) != ' ' 
                      && ch != '\n' )                             //(J)
                word += (char) ch;                                //(K)
            if ( ch == '\n' ) newline = true;                     //(L)
        } catch( IOException e ) {}
        return word;                                              //(M)
    }
}