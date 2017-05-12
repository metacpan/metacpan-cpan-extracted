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



//ImageLoadAndDisplay.java

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

class ImageLoadAndDisplay extends JPanel {

    public void paintComponent( Graphics g ) {
        super.paintComponent( g );
        g.translate( getInsets().left, getInsets().top );
        Dimension d = getSize();      
        Insets in = getInsets();      
        Image image = Toolkit.getDefaultToolkit().getImage(
                                    "images/slideshow/flower16.jpg");
        MediaTracker tracker = new MediaTracker( this );
        tracker.addImage( image, 0 );      
        try {                                               
            tracker.waitForID( 0 );        
        } catch( InterruptedException e ) {}
        
        int imageWidth = image.getWidth( this );
        int imageHeight = image.getHeight( this );
        int clientWidth = d.width - in.right - in.left;
        int clientHeight = d.height - in.bottom - in.top;      
        g.drawImage( image, 
                     in.left, in.top, 
                     clientWidth, clientHeight, 
                     this );
    }


    public static void main( String[] args ) {
        JFrame f = new JFrame( "ImageLoadAndDisplay" );
        f.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });
        ImageLoadAndDisplay im = new ImageLoadAndDisplay();
        f.getContentPane().add( im, BorderLayout.CENTER );
        f.setSize( 1000, 600 );
        f.setLocation( 200, 300 );
        f.setVisible( true );
    }
}