// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 3 ---- The Notion Of A Class And Some Other Ideas
//
// Section:     Section 3.16 - Nested Types
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//NestedClassAsType.java

class X {                                                           

    public static class Y{                                        //(A)
        private int m;
        public Y( int mm ) { m = mm; }                              
        public void printY(){                                       
            System.out.println( "m of nested class obj: " + m );
        }
    }

    private Y yref;                                                 

    public X() { yref = new Y( 100 ); }                             

    Y get_yref(){ return yref; }                                    
}


class Test {
    public static void main( String[] args ) {                     
        X x = new X();                                             
        x.get_yref().printY();  // m of nested class obj: 100

        X.Y y = new X.Y( 200 );                                   //(B)
        y.printY();             // m of nested class obj: 200
    }
}