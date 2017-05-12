// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 13  Generics And Templates
//
// Section:     Section 13.3.3  Constraining the Parameters
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//IntegerGeneric.java
// code by Bracha, Odersky, Stoutamire, and Wadler
// with inconsequential changes by the author

interface Comparable<T> {                        
    public int compareTo( T that );                               //(A)
}

class Integer implements Comparable<Integer> {
    private int value;

    public Integer( int value ) { this.value = value; }

    public int intValue() { return value; }

    public int compareTo( Integer that ) {                        //(B)
        return this.value - that.value;
    }

    public String toString() { return "" + value; }
}

class Collections {
    public static <T implements Comparable<T>> T 
                                   max( Collection<T> coll ) {    //(C)
        Iterator<T> it = coll.iterator();
        T max = it.next();
        while ( it.hasNext() ) {
            T next =  it.next();
            if ( max.compareTo( next ) < 0 ) max = next;
        }
        return max;
    }
}

class Test {
    public static void main( String[] args ) {
        // Integer collection
        LinkedList<Integer> list = new LinkedList<Integer>();
        list.add( new Integer( 0 ) ); 
        list.add( new Integer( 1 ) );
        Integer x = Collections.max( list );
     
        // boolean collection
        LinkedList<Boolean> listBool = new LinkedList<Boolean>();
        listBool.add( new Boolean( false ) );  
        listBool.add( new Boolean( true ) );
        // Boolean b = Collections.max( listBook );  
                                      // run-time exception
    }
}