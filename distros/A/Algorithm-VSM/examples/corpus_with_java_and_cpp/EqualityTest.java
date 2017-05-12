// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 3 ---- The Notion Of A Class And Some Other Key Ideas
//
// Section:     Section 3.13 - Comparing Objects
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//EqualityTest.java

class  X {
    int p;
    int q;
    X( int m, int n ) { p = m; q = n; }
    boolean equals( X other ) { return p == other.p; }            //(A)
}

class Test {
    public static void main( String[] args ) {
        X x1 = new X( 10, 100 );        // x1 and x2              //(B)
        X x2 = new X( 10, 10000 );      // look very different    //(C)
        System.out.println( x1.equals( x2 ) );   // true          //(D)
    }
}