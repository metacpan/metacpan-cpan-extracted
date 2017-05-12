// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 18  Multithreaded Object-Oriented Programming
//
// Section:     Section 18.7  Data I/O Between Threads In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//InterThreadIO.java

import java.io.*;

/////////////////////////////  top level  /////////////////////////////
class InterThreadIO {
    public static void main( String[] args ) {                   
        try {
            PipedOutputStream pout = new PipedOutputStream();     //(A)
            PipedInputStream pin = new PipedInputStream( pout );  //(B)

            Module_1 mod1 = new Module_1( pout );                 //(C)
            Module_2 mod2 = new Module_2( pin );                  //(D)

            mod1.start();
            mod2.start();
        } catch( IOException e ){}          
    }
}


//////////////////////////  class Module_1  ///////////////////////////
class Module_1 extends Thread {                                  
    private DataOutputStream out;                                
  
    public Module_1( OutputStream outsm ) {                      
        out = new DataOutputStream( outsm );                      //(E)
    }
    public void run() {                                          
        for (;;) {
            try {
                double num = Math.random();                      
                out.writeDouble( num );
                System.out.println( 
                   "Number written into the pipe: " + num );
                out.flush();                                     
                sleep( 500 );
            } catch( Exception e ) { 
                System.out.println( "Error: " + e ); 
            }
        }
    }
}

////////////////////////// class Module_2  ////////////////////////////
class Module_2 extends Thread {                                  
    private DataInputStream in;                                  
  
    public Module_2( InputStream istr ) {                        
        in = new DataInputStream( istr );                         //(F)
    }
    public void run() {
        for (;;) {
            try {
                double x = in.readDouble();
                System.out.println( 
                    "  Number received from the pipe: " + x );
            } catch( IOException e ) {
            System.out.println( "Error: " + e );
            }
        }
    }
}