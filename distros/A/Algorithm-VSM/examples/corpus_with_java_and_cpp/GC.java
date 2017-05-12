// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.9  Object Destruction In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//GC.java

class X {
    int id;
    static int nextId = 1;

    //constructor:
    public X() { id = nextId++; }

    protected void finalize() throws Throwable {                  //(A)
        if ( id%1000 == 0 )
            System.out.println("Finalization of X object, id = " + id);     
        super.finalize();                                         //(B)
    }
}

class Test {
    public static void main( String[] args ) {
        X[] xarray = new X[ 10000 ];                              //(C)
        for (int i = 0; i < 10000; i++ )                          //(D)
            xarray[i] = new X();                                  //(E)
        xarray = null;                                            //(F)
        System.gc();                                              //(G)
    }
}