// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 2-- Baby Steps
//
// Section:     Section 2.3 --- Simple Programs: File I/O
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//FileCopy.java

import java.io.*;                                                 //(A)

class FileCopy {                                                  //(B)

    public static void main( String[] args )                      //(C)
    {
        int ch = 0;                              
        FileInputStream in = null;                                //(D)
        FileOutputStream out = null;                              //(E)
  
        if ( args.length != 2 ) {                                 //(F)
            System.err.println( "usage: java FileCopy source dest" );
            System.exit( 0 );
        }
        try {                                    
            in = new FileInputStream( args[0] );                  //(G)
            out = new FileOutputStream( args[1] );                //(H)
     
            while ( true ) {                       
                ch = in.read();                                   //(I)
                if (ch == -1) break;                   
                out.write(ch);                                    //(J)
            }
            out.close();                                          //(K)
            in.close();                                           //(L)
        } catch (IOException e) {                
          System.out.println( "IO error" );    
        }  
    }
}