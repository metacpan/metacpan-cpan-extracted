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






//ExplicitCast2.java

class Test {
    public static void main( String[] args )
    {
        int i1 = 312;
        int i2 = -255;
        int i3 = 32768;

        System.out.println( i1 + ": " + "cast to short is " +
                     (short) i1 + ",  cast to byte is " + (byte) i1 );

        System.out.println( i2 + ": " + "cast to short is " +
                     (short) i2 + ",  cast to byte is " + (byte) i2 );

        System.out.println( i3 + ": " + "cast to short is " +
                     (short) i3 + ",  cast to byte is " + (byte) i3 );
    }    
}