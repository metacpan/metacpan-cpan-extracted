// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 6 The Primitive Types and Their Input/Output
//
// Section:     Section 6.9  I/O Streams For Java
//



//WriteIntToFile.java

import java.io.*;

class WriteIntToFile {
    public static void main( String[] args ) throws Exception {

        int anInt = 98;                                           //(A)

        FileOutputStream fos = new FileOutputStream( "out.fos" ); //(B)
        fos.write( anInt );                                       //(C)
        fos.close();

        FileWriter fw = new FileWriter( "out.fw" );               //(D)
        fw.write( anInt );                                        //(E)
        fw.close();

        DataOutputStream dos = new DataOutputStream( 
            new FileOutputStream( "out.dos" ) );                  //(F)
        dos.writeInt( anInt );                                    //(G)
        dos.close();

        DataOutputStream dbos = new DataOutputStream( 
              new BufferedOutputStream(
                  new FileOutputStream( "out.dbos" ) ) );         //(H)
        dbos.writeInt( anInt );                                   //(I)
        dbos.close();


        PrintStream ps = new PrintStream( 
            new FileOutputStream( "out.ps" ) );                   //(J)
        ps.print( anInt );                                        //(K)
        ps.close();

        PrintStream pbs = new PrintStream( 
              new BufferedOutputStream( 
                  new FileOutputStream( "out.pbs" ) ) );          //(L)
        pbs.print( anInt );                                       //(M)
        pbs.close();

        PrintWriter pw = new PrintWriter( 
            new FileOutputStream( "out.pw" ) );                   //(N)
        pw.print( anInt );                                        //(O)
        pw.close();

        PrintWriter pbw = new PrintWriter( 
            new BufferedOutputStream( 
                new FileOutputStream( "out.pbw" ) ) );            //(P)
        pbw.print( anInt );                                       //(Q)
        pbw.close();

        PrintWriter pw2 = new PrintWriter( 
            new FileWriter( "out.pw2" ) );                        //(R)
        pw2.print( anInt );                                       //(S)
        pw2.close();

        RandomAccessFile ra = 
            new RandomAccessFile( "out.ra", "rw" );               //(T)
        ra.writeInt( anInt );                                     //(U)
        ra.close();
    }
}
