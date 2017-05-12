// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 10  Handling Exceptions
//
// Section:     Section 10.6  Some Usage Patterns For Exception Handling In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ExceptionUsage2.java

class MyException extends Exception {}

class Test {
    static void f( ) throws MyException {}

    public static void main( String[] args ) {
        try {
            f();
        } catch( MyException e ) {}
    }
}