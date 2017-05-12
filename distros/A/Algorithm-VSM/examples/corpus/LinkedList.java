// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 13  Generics And Templates
//
// Section:     Section 13.3.1  Creating Your Own Parameterized Types in Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//LinkedList.java
// code by Bracha, Odersky, Stoutamire, and Wadler

interface Collection {                                            //(A)
    public void add( Object x );
    public Iterator iterator();
}

interface Iterator {                                              //(B)
    public Object next();
    public boolean hasNext();
}

class NoSuchElementException extends RuntimeException {}          //(C)

class LinkedList implements Collection {                          //(D)

    protected class Node {                                        //(E)
        Object item;                   
        Node next = null;
        Node( Object item ) { this.item = item; }
    }

    protected Node head = null, tail = null;

    public LinkedList() {}

    public void add( Object item ) {
        if ( head == null ) { 
            head = new Node( item ); 
            tail = head; 
        }
        else { 
            tail.next = new Node( item ); 
            tail = tail.next; 
        }
    }

    public Iterator iterator() {                                  //(F)
        return new Iterator() {                                   //(G)
                protected Node ptr = head;
                public boolean hasNext() { return ptr != null; }
                public Object next() {
                    if ( ptr != null ) {
                        Object item = ptr.item; 
                        ptr = ptr.next; 
                        return item;
                    } else throw new NoSuchElementException();
                }
           };
    }
}  // end of class LinkedList




class Test {
    public static void main( String[] args ) {

        String str = "";

        //int list
        LinkedList intList = new LinkedList();
        intList.add( new Integer( 0 ) ); 
        intList.add( new Integer( 1 ) );
        intList.add( new Integer( 2 ) );
        Iterator int_it = intList.iterator();
        while ( int_it.hasNext() )
            str += ( (Integer) int_it.next() ).intValue() + "  "; //(H)
        System.out.println( str );               // 0  1  2

        //string list 
        LinkedList stringList = new LinkedList();      
        stringList.add( "zero" ); 
        stringList.add( "one" );
        stringList.add( "two" );
        str = "";
        Iterator string_it = stringList.iterator();
        while ( string_it.hasNext() )
            str += (String) string_it.next() + "  ";              //(I)
        System.out.println( str );               // zero one two

        // string list treated as int list
        // gives rise to run-time exception
        // Integer w = ( Integer ) stringList.iterator().next();  //(J)
    }
}