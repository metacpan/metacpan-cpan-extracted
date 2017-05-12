// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 13  Generics And Templates
//
// Section:     Section 13.3.2  Parameterization of Methods
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//CollectionMax.java
// code by Bracha, Odersky, Stoutamire, and Wadler
// with inconsequential changes by the author

interface Comparator {
    public int compare( Object x, Object y );
}

class IntComparator implements Comparator {
    public int compare( Object x, Object y ) {
        return ( (Integer) x ).intValue() - ( (Integer) y ).intValue();
    }
}

class Collections {
    public static Object max( Collection xs, Comparator comp ) {  //(A)
        Iterator it = xs.iterator();
        Object max = it.next();
        while ( it.hasNext() ) {
            Object next = it.next();
            if ( comp.compare( max, next ) < 0 )  max = next;
        }
        return max;
    }
}

class Test {
    public static void main( String[] args ) {
        // int list with int comparator:
        LinkedList intList = new LinkedList();                    //(B)
        intList.add( new Integer( 0 ) ); 
        intList.add( new Integer( 10 ) );
        Integer max = 
          (Integer) Collections.max( intList, new IntComparator() );
        System.out.println( "Max value: " + max.intValue() );

        // string list with int comparator:
        LinkedList stringList = new LinkedList();
        stringList.add( "zero" ); 
        stringList.add( "one" );
        // the following will give runtime exception
        // String str = 
        // (String) Collections.max( stringList, new IntComparator() );
    }
}