// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 19  Network Programming
//
// Section:     Section 19.2  Server Sockets In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ChatServer.java

import java.io.*;
import java.net.*;
import java.util.*;

public class ChatServer {
    public static List clientList = new ArrayList();

    public static void main( String[] args ) {
        try {
            ServerSocket server = new ServerSocket( 5000 );
            for (;;) {
                Socket socket = server.accept();
                System.out.print( "A new client checked in:   " );
                ClientHandler clh = new ClientHandler( socket );
                clientList.add( clh );
                clh.start();
            }
        } catch( Exception e ) { System.out.println( e ); }
    }
}

/////////////////  class ClientHandler extends Thread  ////////////////
class ClientHandler extends Thread {
    private String userName;
    private Socket sock;
    private static List chatStore = new ArrayList();
    private BufferedReader buff_reader = null;
    private PrintWriter out = null;

    public ClientHandler( Socket s ) {
        try {
            sock = s;
            out = new PrintWriter( sock.getOutputStream() );
            InputStream in_stream = sock.getInputStream();
            InputStreamReader in_reader = 
                new InputStreamReader( in_stream );
            buff_reader = new BufferedReader( in_reader );

            // ask for user name
            out.println( "\n\nWelcome to Avi Kak's chatroom");
            out.println();
            out.println( 
               "Type \"bye\" in a new line to terminate session.\n" );
            out.print( "Please enter your first name: " );
            out.flush();
            userName = buff_reader.readLine();
            out.print("\n\n");
            out.flush();
            System.out.print( userName + "\n\n" );
  
            // show to new client all the chat 
            // that has taken place so far
            if ( chatStore.size() != 0 ) {
                out.println( "Chat history:\n\n" );

                ListIterator iter = chatStore.listIterator();
                while ( iter.hasNext() ) {                
                    out.println( (String) iter.next() );
                }
                out.print("\n\n");
                out.flush();
            }
        } catch( Exception e ) {}
    }

    public void run() {    
        try {
            boolean done = false;
            while ( !done ) {
                out.print( userName + ": " );
                out.flush();
                String str = buff_reader.readLine();

                if ( str.equals( "bye" ) ) {
                    str = userName + " signed off";
                    done = true;
                }
                String strWithName = userName + ": " + str;
                chatStore.add( strWithName );
                ListIterator iter = 
                              ChatServer.clientList.listIterator();
                while ( iter.hasNext() ) {
                    ClientHandler cl = (ClientHandler) iter.next();
                    if ( this != cl ) {
                        cl.out.println();
                        cl.out.println( strWithName );
                        cl.out.print( cl.userName + ": " );
                        cl.out.flush();
                    }
                }
            }
            System.out.println( userName + " signed off" + "\n\n" );
            buff_reader.close();
            out.close();
            sock.close();
        } catch ( Exception e ) {}
    }
}