// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 9  Functions And Methods
//
// Section:     Section 9.3.1  Passing a Primitive Type Argument by Value
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//







//PassPrimByValue.java

class Test {
    public static void main( String[] args )
    {
        int x = 100;                                              //(A)
        g(x);                                                     //(B)
        System.out.println( x );           // outputs 100
    }

    static void g( int y ) { y++; }                               //(C)
}