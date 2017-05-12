// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.22.5  The AppleContent Interface
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Left.java

import java.awt.*;
import java.awt.event.*;
import java.applet.*;
import java.net.*;
import java.io.*;

public class Left extends Applet implements ActionListener {
    private List links = new List( 3, false );

    public void init() {
        setLayout( new BorderLayout() );      
        setBackground( Color.red );
        Font f = new Font( "SansSerif", Font.BOLD, 14 );
        setFont( f );    
    
        Panel p = new Panel();    
        p.setLayout( new BorderLayout() );
        p.add( links, "Center" );
        links.addActionListener( this );
        int i = 1;
        String s;
        while ( ( s = getParameter( "item_" + i ) ) != null ) {
            links.add( s );
            i++;
        }
        add( p, "Center" );

    }

    public void actionPerformed( ActionEvent evt ) {
        try {
            String str = evt.getActionCommand();
            AppletContext context = getAppletContext();
            int i = 1;
            String s;
            while ( ( s = getParameter( "item_" + i ) ) != null ) {
                if ( str.equals( s ) ) {
                    URL u = new URL( getParameter( "url_" + i ) );
                    context.showDocument( u, "right" ); 
                }
            i++;
            }
        } catch( Exception e ) { showStatus( "Error " + e ); }
    }
}