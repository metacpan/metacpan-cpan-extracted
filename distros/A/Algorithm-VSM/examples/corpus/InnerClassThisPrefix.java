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




//InnerClassThisPrefix.java

class X {                           
    private int m;                                                //(A)
    private static int n = 300;                                   //(B)

    public class Y{                        
        private int m;                                            //(C)
        private int n;                                            //(D)
        public Y() { 
            this.m = X.this.m;                                    //(E)
            this.n = X.this.n;                                    //(F)
        }
        public String toString() { 
            return "inner's state: " + this.m + "  " +  this.n; 
        } 
    }

    public X( int mm ) { m = mm; }                                //(G) 
}

class Test {
    public static void main( String[] args ) {
        X x = new X( 100 );                    
        X.Y y = x.new Y();               
        System.out.println( y );                // 100 300
    }
}