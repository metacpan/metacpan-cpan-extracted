// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 10  Handling Exceptions
//
// Section:     Section 10.7  Checked And Unchecked Exceptions In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//RuntimeExcep.java

class MyException extends RuntimeException {                      //(A)
    public MyException() {
        super();
    }
    public MyException( String s ) {
        super( s );
    }
}

class Test {
    static void f( ) throws MyException {
        throw new MyException( "Exception thrown by function f()" );
    }
    public static void main( String[] args ) {
            f();                                                  //(B)
    }
}