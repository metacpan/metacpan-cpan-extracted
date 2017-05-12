// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.19  Drawing Shapes, Text, And Images In AWT/Swing
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//FontFamilies.java

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

class FontFamilies extends JPanel {

    public void paintComponent( Graphics g ) {
        super.paintComponent( g );
        g.translate( getInsets().left, getInsets().top );
        GraphicsEnvironment ge = 
            GraphicsEnvironment.getLocalGraphicsEnvironment();
        String[] fontList = ge.getAvailableFontFamilyNames();   
        Font defaultFont = g.getFont();
        for (int i = 0; i < fontList.length; i++ ) {
            g.setFont( defaultFont );
            g.drawString( fontList[ i ], 10, i * 14 );
            Font f = new Font( fontList[ i ], Font.PLAIN, 12 );
            g.setFont( f );
            g.drawString( "Purdue", 200 , i * 14 );
        }
    }

    public static void main( String[] args ) {
        JFrame f = new JFrame();
        f.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });
        FontFamilies fd = new FontFamilies();
        f.getContentPane().add( fd, BorderLayout.CENTER );
        f.setSize( 300, 300 );
        f.setLocation( 200, 300 );
        f.setVisible( true );
    }
}