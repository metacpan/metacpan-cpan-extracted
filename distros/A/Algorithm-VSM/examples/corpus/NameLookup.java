// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.14  Extending Classes In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//NameLookup.java

class Base {
    public void foo() {                                           //(A)
        System.out.println( "Base's foo() invoked" ); 
    }
    public void foo( int i ) {                                    //(B)
        System.out.println( "Base's foo( int ) invoked" ); 
    }
    public void foo( int i, int j ) {                             //(C)
        System.out.println( "Base's foo( int, int ) invoked" ); 
    }
}

class Derived extends Base {
    public void foo() {                                           //(D)
        System.out.println( "Derived's foo() invoked" ); 
    }
}

public class Test {
    public static void main( String[] args )  
    {
        Derived d = new Derived();
        d.foo();             // Derived's foo() invoked           //(E)
        d.foo( 3 );          // Base's foo( int ) invoked         //(F)
        d.foo( 3, 4 );       // Base's foo( int, int ) invoked    //(G)
    }
}