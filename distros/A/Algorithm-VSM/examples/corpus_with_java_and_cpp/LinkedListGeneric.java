// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 13  Generics And Templates
//
// Section:     Section 13.3.1  Creating Your Own Parameterized Types In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//LinkedListGeneric.java
// code by Bracha, Odersky, Stoutamire, and Wadler

interface Collection<T> {                                         //(A)
    public void add( T x );
    public Iterator<T> iterator();
}

interface Iterator<T> {                                           //(B)
    public T next();
    public boolean hasNext();
}

class NoSuchElementException extends RuntimeException {}          //(C)

class LinkedList<T> implements Collection<T> {                    //(D)
    protected class Node {                                        //(E)
        T item;
        Node next = null;
        Node( T item ) { this.item = item; }
    }
    protected Node head = null, tail = null;
    public LinkedList() {}
    public void add( T item ) {
        if ( head == null ) { 
            head = new Node( item ); 
            tail = head; 
        }
        else { 
            tail.next = new Node( item ); 
            tail = tail.next; 
        }
    }
    public Iterator<T> iterator() {                               //(F)
        return new Iterator<T>() {                                //(G)
                protected Node ptr = head;

                public boolean hasNext() { return ptr != null; }

                public T next() {
                    if ( ptr != null ) {
                        T item = ptr.item; 
                        ptr = ptr.next; 
                        return item;
                    } else throw new NoSuchElementException();
                }
            };
    }
}

class Test {
    public static void main( String[] args ) {

        String str = "";

        //int list
        LinkedList<Integer> intList = new LinkedList<Integer>();
        intList.add( new Integer( 0 ) ); 
        intList.add( new Integer( 1 ) );
        intList.add( new Integer( 2 ) );
        Iterator<Integer> int_it = intList.iterator();
        while ( int_it.hasNext() )
            str += int_it.next().intValue() + "  ";               //(H)
        System.out.println( str );             //  0  1  2

        //string list 
        LinkedList<String> stringList = new LinkedList<String>();      
        stringList.add( "zero" ); 
        stringList.add( "one" );
        stringList.add( "two" );
        str = "";
        Iterator<String> string_it = stringList.iterator();
        while ( string_it.hasNext() )
            str += string_it.next() + "  ";                       //(I)
        System.out.println( str );             // zero  one  two

        // string list treated as int list
        // gives rise to compile-time error
        // Integer w = stringList.iterator().next();              //(J)
    }
}