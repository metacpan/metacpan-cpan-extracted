// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 3 ---- The Notion Of A Class And Some Other Key Ideas
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




//NestedClass.java

class X {                                                         //(A)
    static class Y{                                               //(B)
        private int m;
        public Y( int mm ) { m = mm; }      
        public void printY(){               
            System.out.println( "m of nested class object: " + m );
        }
    }

    private Y yref;                         

    public X() { yref = new Y( 100 ); }     

    Y get_yref(){ return yref; }            
}

class Test {
    public static void main( String[] args ) {
        X x = new X();
        x.get_yref().printY();   // m of nested class object: 100 
    }
}