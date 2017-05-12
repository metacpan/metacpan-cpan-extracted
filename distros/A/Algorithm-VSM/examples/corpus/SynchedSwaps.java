// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 18  Multithreaded Object-Oriented Programming
//
// Section:     Section 18.5  Thread Synchronization In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//SynchedSwaps.java

//////////////////////////  class DataObject  /////////////////////////
class DataObject {
    int dataItem1;
    int dataItem2;

    DataObject() {
        dataItem1 = 50;
        dataItem2 = 50;
    }
    synchronized void itemSwap() {
        int x = (int) ( -4.999999 + Math.random() * 10 );
        dataItem1 -= x;
        keepBusy(10);                                     
        dataItem2 += x;
    }
    synchronized void test() {
        int sum = dataItem1 + dataItem2;
        System.out.println( sum );    
    }
    public void keepBusy( int howLong ) {
        long curr = System.currentTimeMillis();            
        while ( System.currentTimeMillis() < curr + howLong )
            ;
    }
}

////////////////////////  class RepeatedSwaps  ////////////////////////
class RepeatedSwaps extends Thread  {
    DataObject dobj;

    RepeatedSwaps( DataObject d ) {
        dobj = d;
        start();
    }
    public void run( ) {
        int i = 0;
        while ( i++ < 20000 ) {
            dobj.itemSwap();
            if ( i % 4000 == 0 ) dobj.test();
            try { sleep( 1 ); } catch( InterruptedException e ) {}
        }
    }
}

/////////////////////////  class SynchedSwaps  ////////////////////////
public class SynchedSwaps {
    public static void main( String[] args ) {
        DataObject d = new DataObject();
        new RepeatedSwaps(  d );
        new RepeatedSwaps(  d );
        new RepeatedSwaps(  d );    
        new RepeatedSwaps(  d );        
    }
}    