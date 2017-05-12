// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.7  Self-Reference In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//SpecialInt.java

class SpecialInt {
    int i;
    int accumulator;

    SpecialInt( int m ) throws Exception { 
        if ( m > 100 || m < -100 ) throw new Exception();
        i = m; 
        accumulator = m; 
    }

    int getI() { return i; }

    SpecialInt plus( SpecialInt sm ) throws Exception {
        accumulator += sm.getI();
        if ( accumulator > 100 || accumulator < -100 ) 
            throw new Exception();
        return this;
    }

    public static void main( String[] args ) throws Exception {
        SpecialInt s1 = new SpecialInt( 4 );
        SpecialInt s2 = new SpecialInt( 5 );
        SpecialInt s3 = new SpecialInt( 6 );
        SpecialInt s4 = new SpecialInt( 7 );
        s1.plus( s2 ).plus( s3 ).plus( s4 );     
        System.out.println( s1.accumulator );      // 22
        //SpecialInt s5 = new SpecialInt( 101 );   // range violation
    }
}