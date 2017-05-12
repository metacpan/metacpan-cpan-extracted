// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.16  Constructor Order Dependencies In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ConstructorOrderFoo.java

class Base {
    public void foo(){ System.out.println( "Base's foo invoked" ); }
    public Base() { foo(); }
}

class Derived extends Base { 
    public void foo(){ System.out.println( "Derived's foo invoked" ); }
    public Derived() {}
}

class Test {
    public static void main( String[] args )
    {
        Derived d = new Derived();          //Derived's foo() invoked
    }
}