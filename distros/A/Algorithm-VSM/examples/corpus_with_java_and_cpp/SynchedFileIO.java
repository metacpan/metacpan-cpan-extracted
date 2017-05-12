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



//SynchedFileIO.java

///////////////////////////  class DataFile  //////////////////////////
class DataFile {
    public DataFile() {
        try {
            FileIO.writeOneString( "Hello", "hello.dat" );      
        } catch( FileIOException e ) {}
    }
    synchronized void fileIO() {
        try {
            String str = FileIO.readOneString( "hello.dat" );
            FileIO.writeOneString( str  , "hello.dat" );
        } catch( FileIOException e ) {}
    }
}


////////////////////////  class ThreadedFileIO  ///////////////////////
class ThreadedFileIO extends Thread  {
    DataFile df;

    ThreadedFileIO( String threadName, DataFile d ) {
        df = d;
        setName( threadName );
        start();
    }
    public void run( ) {
        int i = 0;
        while ( i++ < 4 ) {
            try {
                df.fileIO();
                String str = FileIO.readOneString( "hello.dat" );        
                System.out.println( getName() + ":     "  
                           +  "hello.dat contains: " + str ); 
                sleep( 5 ); 
            } catch( InterruptedException e ) {}
              catch( FileIOException e ) {}
        }
    }
}

////////////////////////  class SynchedFileIO  ////////////////////////
public class SynchedFileIO {
    public static void main( String[] args ) {
        DataFile dd = new DataFile();
        new ThreadedFileIO( "t0", dd );
        new ThreadedFileIO( "t1", dd );
        new ThreadedFileIO( "t2", dd );
        new ThreadedFileIO( "t3", dd );    
        new ThreadedFileIO( "t4", dd );        
    }
}    