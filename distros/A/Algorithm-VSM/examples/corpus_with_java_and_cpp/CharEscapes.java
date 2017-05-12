// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 6  ----  The Primitive Types and Their Input/Output
//
// Section:     Section 6.4 ----  Character Types
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//CharEscapes.java

class Test {
    public static void main( String[] args ) {

        String y1 = "a\u0062";           
        print( "y1:\t" + y1 );         // Printed output:  ab
                                       
        String y2 = "a\n";           
        print( "y2:\t" + y2 );         // Printed output:  a

        String y3 = "a\nbcdef";        
        print( "y3:\t"+ y3 );          // Printed output:  a
                                       //                  bcdef
        String y4 = "a\nwxyz";       
        print( "y4:\t" + y4 );         // Printed output:  a
                                       //                  wxyz
        String y5 = "a\u0abcdef";      
        print( "y5:\t" + y5 );         // Printed output:  a?def

        String y6 = "a\u00ef";           
        print( "y6:\t" + y6 );         // Correct, but the character
                                       // following 'a' may not have
                                       // a print representation

        String w1 = "a\142";           
        print( "w1:\t" + w1 );         // Printed output:  ab
                                       
        String w2 = "a\142c";          
        print( "w2:\t" + w2 );         // Printed output:  abc
                                       
        String w3 = "a\142142";        
        print( "w3:\t" + w3 );         // Printed output:  ab142
    
        String w4 = "a\79";           
        print( "w4:\t" + w4 );         // Printed output:  a9
    }

    static void print( String str ) { System.out.println( str ); }
}    