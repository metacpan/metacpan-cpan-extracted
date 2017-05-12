// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 18  Multithreaded Object-Oriented Programming
//
// Section:     Section 18.2  The Runnable Interface In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ThreadBasicWithRunnable.java

class HelloThread implements Runnable { 
    String message;
    HelloThread( String message ) { this.message = message; }

    public void run() {                                           //(A)
        //int sleeptime = (int) ( Math.random() * 3000 );         //(B)
        //try {                                                   //(C)
        //    Thread.sleep( sleeptime );                          //(D)
        //} catch( InterruptedException e ){}                     //(E)
        System.out.print( message );
    }

    public static void main( String[] args )
    {
        HelloThread ht1 = new HelloThread( "Good" );              //(F)
        Thread t1 = new Thread( ht1 );                            //(G)

        HelloThread ht2 = new HelloThread( " morning" ); 
        Thread t2 = new Thread( ht2 );

        HelloThread ht3 = new HelloThread( " to" );
        Thread t3 = new Thread( ht3 );

        t1.start();                                               //(H)
        t2.start();
        t3.start();

        try {
            Thread.sleep( 1000 );                                 //(I)
        } catch( InterruptedException e ){}   

        System.out.println( " you!" );
    }
}