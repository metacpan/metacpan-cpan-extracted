// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 6 The Primitive Types and Their Input/Output
//
// Section:     Section 6.9.2  Writing Strings
//


//WriteStringToFile.java

import java.io.*;

class WriteStringToFile {
    public static void main( String[] args ) throws Exception {

        String aString = "hello";                                 //(A)

        FileWriter fw = new FileWriter( "out.fw" );               //(B)
        fw.write( aString );                                      //(C)
        fw.close();

        DataOutputStream dos = new DataOutputStream(            
                         new FileOutputStream( "out.dos" ) );     //(D)
        dos.writeBytes( aString );                                //(E)
        dos.close();

        DataOutputStream dos2 = new DataOutputStream( 
            new FileOutputStream( "out.dos2" ) );                 //(F)
        dos2.writeChars( aString );                               //(G)
        dos2.close();

        DataOutputStream dos3 = new DataOutputStream( 
            new FileOutputStream( "out.dos3" ) );                 //(H)
        dos3.writeUTF( aString );                                 //(I)
        dos3.close();

        PrintStream ps = 
            new PrintStream( new FileOutputStream( "out.ps" ) );  //(J)
        ps.print( aString );                                      //(K)
        ps.close();

        PrintWriter pw = 
            new PrintWriter( new FileOutputStream( "out.pw" ) );  //(L)
        pw.print( aString );                                      //(M)
        pw.close();

        PrintWriter pw2 = 
            new PrintWriter( new FileWriter( "out.pw2" ) );       //(N)
        pw2.print( aString );                                     //(O)
        pw2.close();

        RandomAccessFile ra = 
            new RandomAccessFile( "out.ra", "rw" );               //(P)
        ra.writeBytes( aString );                                 //(Q)
        ra.close();

        RandomAccessFile ra2 = 
            new RandomAccessFile( "out.ra2", "rw" );              //(R)
        ra2.writeChars( aString );                                //(S)
        ra2.close();

        RandomAccessFile ra3 = 
            new RandomAccessFile( "out.ra3", "rw" );              //(T)
        ra3.writeUTF( aString );                                  //(U)
        ra3.close();
    }
}
