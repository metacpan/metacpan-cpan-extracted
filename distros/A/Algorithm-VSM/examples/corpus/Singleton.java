// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.1.1  Limiting the Number of Objects
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Singleton.java

class X {
    private int n;
    private static X unique;                                      //(A)
    private X( int m ){ n = m; }                                  //(B)
    public static X makeInstanceOfX() {                           //(C)
        if ( unique == null ) unique  = new X( 10 );              //(D)
        return unique;
    }
}

class Test {
    public static void main( String[] args )
    {
        X xobj_1 = X.makeInstanceOfX();
        X xobj_2 = X.makeInstanceOfX();
        System.out.println( xobj_1 == xobj_2 );     // true
    }
}