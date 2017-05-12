// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 6  The Primitive Types and Their Input/Output
//
// Section:     Section 6.9.3  Reading the Primitive Types
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//







//ReadIntFromFile.java

import java.io.*;

class ReadIntFromFile {
    public static void main( String[] args ) throws Exception {

        int anInt = 123456;

        int x;

        DataOutputStream dos = new DataOutputStream( 
            new FileOutputStream( "out.num" ) );                  //(A)
        dos.writeInt( anInt ); //writes hex 00 01 e2 40 to file   //(B)
        dos.close();  

        // read int with DataInputStream
        DataInputStream dis = new DataInputStream( 
            new FileInputStream( "out.num" ) );                   //(C)
        x = dis.readInt();                                        //(D)
        System.out.println( x );    // 123456
        dis.close();


        // read int with buffered DataInputStream
        DataInputStream dbis = new DataInputStream( 
            new BufferedInputStream(
                new FileInputStream("out.num")));                 //(E)
        x = dbis.readInt();                                       //(F)
        System.out.println( x );    // 123456
        dbis.close();

        // read int with RandomAccessFile
        RandomAccessFile rai = new 
            RandomAccessFile( "out.num", "r" );                   //(G)
        x = rai.readInt();                                        //(H)
        System.out.println( x );    // 123456
        rai.close();
    }
}