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



//ExceptionUsage4.java

class MyException extends Exception {}
class Err extends Exception {}

class Test {
    static void f() throws MyException {                          //(A)
        throw new MyException();
    }
    static void g() throws Err {                                  //(B)
        throw new Err();
    }
    static void h() throws MyException, Err {                     //(C)
        f();
        g();
    }

    public static void main( String[] args ) {
        try {
            h();                                                  //(D)
        } catch( MyException e ) { 
            System.out.println( "caught MyException" );
        } catch( Err e ) { 
            System.out.println( "caught Err" );
        }
    }
}