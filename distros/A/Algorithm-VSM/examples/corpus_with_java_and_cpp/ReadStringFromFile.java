// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 6 The Primitive Types and Their Input/Output
//
// Section:     Section 6.9.4  Reading Strings
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//ReadStringFromFile.java

import java.io.*;

class ReadStringFromFile {

    public static void main( String[] args ) throws Exception {

        String aString = "hello";
        String bString = "there";
        String str;

        DataOutputStream dos = new DataOutputStream( 
                    new FileOutputStream( "out.dos" ) );
        dos.writeUTF( aString ); //hex output:  00 05 68 65 6c 6c 6f
        dos.writeUTF( bString ); //hex output:  00 05 74 68 65 72 65
        dos.close();

        DataInputStream dis = new DataInputStream( 
                    new FileInputStream( "out.dos3" ) );
        str = dis.readUTF();
        System.out.println( "read by readUTF of DataInputStream: " + str );
        str = dis.readUTF();
        System.out.println( "read by readUTF of DataInputStream: " + str );
        dis.close();


        RandomAccessFile ra = new RandomAccessFile( "out.dos", "r" );
        str = ra.readUTF();
        System.out.println( "read by readUTF of RandomAccessFile: " + str );
        str = ra.readUTF();
        System.out.println( "read by readUTF of RandomAccessFile: " + str );
        ra.close();
    }
}

