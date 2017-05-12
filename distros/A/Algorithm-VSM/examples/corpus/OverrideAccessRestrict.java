// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.15  Restrictions On Overriding Methods In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//OverrideAccessRestrict.java

class Base {
    private int m;
    private void foo(){                                      //(A) 
        System.out.println("Base's foo invoked" );           
    }
    public Base( int mm ) { m = mm; }
    public void bar() { foo(); }                             //(B)
}

class Derived extends Base {
    private int n;
    private void foo() {                                     //(C)
        System.out.println( "Derived's foo invoked" );  
    }
    public Derived( int mm, int nn ) {                       //(D)
        super( mm );  n = nn;
    }
}

class Test {
    public static void main( String[] args ) {
        Base p = new Derived( 10, 20 );                      //(G)
        p.bar();           //output: Base's foo invoked      //(H)
    }
}