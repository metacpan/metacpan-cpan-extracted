// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.2  Can Multiple Constructors Help Each Other?
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//MultiConstructors.java

class X {
    private int x;
    private int y;
  
    public X() { x = 5; }                                         //(A)

    public X( int m ) {                                           //(B)
        this();                                                   //(C)
        y = m;
    }

    public static void main( String[] args )
    {
        X xobj = new X( 100 );
        System.out.println ( xobj.x + " " + xobj.y );    // 5 100
    }  
}  