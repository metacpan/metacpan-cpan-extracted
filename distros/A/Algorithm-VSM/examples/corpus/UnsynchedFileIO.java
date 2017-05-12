// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 18  Multithreaded Object-Oriented Programming
//
// Section:     Section 18.4  Thread Interference In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//UnsynchedFileIO.java

///////////////////////////  class DataFile  //////////////////////////
class DataFile {                                                  //(A)

    public DataFile() {                                          //(B1)
        try {
            FileIO.writeOneString( "Hello", "hello.dat" );       //(B2)
        } catch( FileIOException e ) {}
    }

    void fileIO() {                                              //(C1)
        try {
            String str = FileIO.readOneString( "hello.dat" );    //(C2)
            FileIO.writeOneString( str  , "hello.dat" );         //(C3)
        } catch( FileIOException e ) {}
    }
}


///////////////////////  class ThreadedFileIO  ////////////////////////
class ThreadedFileIO extends Thread  {                            //(D)
    DataFile df;                                                  //(E)

    ThreadedFileIO( String threadName, DataFile d ) {             //(F)
        df = d;
        setName( threadName );
        start();
    }
    public void run( ) {                                          //(G)
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

///////////////////////  class UnsynchedFileIO  ///////////////////////
public class UnsynchedFileIO {                                    //(H)
    public static void main( String[] args ) {
        DataFile dd = new DataFile();                             //(I)
        new ThreadedFileIO( "t0", dd );                          //(J1)
        new ThreadedFileIO( "t1", dd );                          //(J2)
        new ThreadedFileIO( "t2", dd );                          //(J3)
        new ThreadedFileIO( "t3", dd );                          //(J4)
        new ThreadedFileIO( "t4", dd );                          //(J5)
    }
}    