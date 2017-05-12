// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 6   The Primitive Types and Their Input/Output
//
// Section:     Section 6.7.2    The Conversion For the Primitive Types
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//





//Narrowing.java

class Test {

    static void g1( short x ) {}
    static void g2( int x ) {}  
    static void g3( float x ) {}

    public static void main( String[] args )
    {
        int i = 98;
        // char c = i;    // not allowed for initialization
        char c = 98;      // ok for initialization from literal
        System.out.println( c );    // output:  b                 //(A)

        byte b = 97;      // ok for initialization from literal
        System.out.println( b );    // output:  97                //(B)

        // float y = 1e100;    // double to float not allowed

        double z = 1e100;
        // float y = z;        // double to float not allowed
        float y = (float) z;       // but ok with cast
        System.out.println( y );   // output: Infinity            //(C)

/*
        g1( y );    // ERROR: 
                    //   cannot automatically convert float to short
        g2( y );    // ERROR: 
                    //   cannot automatically convert float to int
        g3( z );    // ERROR: 
                    //   cannot automatically convert double to float
*/
    } 
}   