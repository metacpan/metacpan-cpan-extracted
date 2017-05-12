// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 18  Multithreaded Object-Oriented Programming
//
// Section:     Section 18.4  Thread Interference In Java 
//

//UnsynchedSwaps.java

/////////////////////////  class DataObject  //////////////////////////
class DataObject {                                         
    int dataItem1;
    int dataItem2;

    DataObject() {                                               //(A1)
        dataItem1 = 50;                                          //(A2)
        dataItem2 = 50;                                          //(A3)
    }
    void itemSwap() {                                            //(B1)
        int x = (int) ( -4.999999 + Math.random() * 10 );        //(B2)
        dataItem1 -= x;                                          //(B3)
        keepBusy(10);                                            //(B4)
        dataItem2 += x;                                          //(B5)
    }
    void test() {                                                //(C1)
        int sum = dataItem1 + dataItem2;                         //(C2)
        System.out.println( sum );                               //(C3)
    }
    public void keepBusy( int howLong ) {                         //(D)
        long curr = System.currentTimeMillis();            
        while ( System.currentTimeMillis() < curr + howLong )
            ;
    }
}

////////////////////////  class RepeatedSwaps  ////////////////////////
class RepeatedSwaps extends Thread  {                             //(E)
    DataObject dobj;

    RepeatedSwaps( DataObject d ) {                               //(F)
        dobj = d;
        start();
    }
    public void run( ) {                                         //(G1)
        int i = 0;
        while ( i < 20000 ) {                                    //(G2)
            dobj.itemSwap();                                     //(G3)
            if ( i % 4000 == 0 ) dobj.test();                    //(G4)
            try { sleep( (int) (Math.random() * 2 ) ); }         //(G5)
            catch( InterruptedException e ) {}
            i++;
        }
    }
    public void keepBusy() {
        long curr = System.currentTimeMillis();
        while ( System.currentTimeMillis() < 
                       curr + (int) (Math.random()*10) )
            ;
    }
}

///////////////////////  class UnsynchedSwaps  ////////////////////////
public class UnsynchedSwaps {                                     //(H)
    public static void main( String[] args ) {           
        DataObject d = new DataObject();                          //(I)
        new RepeatedSwaps( d );                                  //(J1)
        new RepeatedSwaps( d );                                  //(J2)
        new RepeatedSwaps( d );                                  //(J3)
        new RepeatedSwaps( d );                                  //(J4)
    }
}    
