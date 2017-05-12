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




//CollectionMaxGeneric.java
// code by Bracha, Odersky, Stoutamire, and Wadler
// with inconsequential changes by the author

interface Comparator<T> {
    public int compare( Object x, Object y );                     //(A)
}
class IntComparator implements Comparator<Integer> {              //(B)
    public int compare( Object x, Object y ) {
        return ( (Integer) x ).intValue() - ( (Integer) y ).intValue();
    }
}

class Collections {
    public static <T> T 
             max( Collection<T> coll, Comparator<T> comp ) {      //(C)
        Iterator<T> it = coll.iterator();
        T max = it.next();

        while ( it.hasNext() ) {
            T next = it.next();
            if ( comp.compare( max, next ) < 0 )  max = next;
        }
        return max;
    }
}

class Test {
    public static void main( String[] args ) {

        // int list with int comparator
        LinkedList<Integer> intList = new LinkedList<Integer>();
        intList.add( new Integer( 0 ) ); 
        intList.add( new Integer( 1 ) );
        Integer m = 
          Collections.max( intList, new IntComparator() );
        System.out.println( "Max value: " + m );            // 1

        // string list with int comparator
        LinkedList<String> stringList = new LinkedList<String>();
        stringList.add( "zero" ); 
        stringList.add( "one" );
        // the following will give compile time error
        // String str = 
        // Collections.max( stringList, new IntComparator() );
    }
}