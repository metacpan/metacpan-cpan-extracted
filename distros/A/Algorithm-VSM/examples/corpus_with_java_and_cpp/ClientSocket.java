// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 19  Network Programming
//
// Section:     Section 19.1  Establishing Socket Connections With Existing Servers In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ClientSocket.java

import java.io.*;
import java.net.*;


class ClientSocket {

    public static void main( String[] args ) 
    {
 
        try {
            String webAddress = args[0];
            String hostHeader = "Host: " + webAddress;

            Socket socket = new Socket( webAddress, 80 );
  
            OutputStream os = socket.getOutputStream();      
            PrintStream ps = new PrintStream( os, true );

            InputStream in = socket.getInputStream();
            InputStreamReader in_reader = new InputStreamReader( in );
            BufferedReader b_reader = new BufferedReader( in_reader );

            ps.print( "GET / HTTP/1.0\r\n" + hostHeader +"\r\n" + "\r\n" );

            boolean more = true;
            while (more) {
                String str = b_reader.readLine();
                if (str == null) more = false;
                System.out.println(str);
            }
        } catch( IOException e ) {System.out.println( "Error:   " + e ); }
    }
}
