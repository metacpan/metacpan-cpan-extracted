// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.4 Static Members In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Date.java

class Date {
    private int d, m, y;
    private static Date today = new Date( 31, 10, 2001 );         //(A)

    public Date( int dd, int mm, int yy ) {                       //(B) 
        d = dd; 
        m = mm;  
        y = yy; 
    } 

    public Date( int dd, int mm ) {                               //(C)
        d = dd; 
        m = mm;  
        y = today.y; 
    }  

    public Date( int dd ) {                                       //(D)
        d = dd; 
        m = today.m;  
        y = today.y; 
    }  

    public Date() {                                               //(E)
        d = today.d;
        m = today.m;  
        y = today.y; 
    }  

    public static void setToday( int dd, int mm, int yy ) {       //(F)
        today = new Date(dd, mm, yy);                      
    }

    public void print() { 
        System.out.println( "day: " + d + " month: " + m 
                                         + " year: " + y ); 
    }

    public static void main( String[] args ) {
        Date d1 = new Date( 1, 1, 1970 );
        d1.print();               // day: 1  month: 1  year: 1970
        Date d2 = new Date( 2 );
        d2.print();               // day: 2  month: 10  year: 2001
        setToday(3, 4, 2000);                                     //(G)
        today.print();            // day: 3  month: 4  year: 2000
        Date d3 = new Date( 7 );
        d3.print();               // day: 7  month: 4  year: 2000
        Date d4 = new Date();
        d4.print();               // day: 3  month: 4  year: 2000
    }
}