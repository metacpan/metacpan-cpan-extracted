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



//ExceptionUsage7.java

class MyException extends Exception {
    String message;                                               //(A)
    public MyException( String mess ) { message = mess; }         //(B)
}

class Test {
    static void f() throws MyException {
        throw new MyException( "Hello from f()" );                //(C)
    }

    public static void main( String[] args )
    {
        try {
            f();
        } catch( MyException e ) { 
            System.out.println( e.message );
        }
    }
}