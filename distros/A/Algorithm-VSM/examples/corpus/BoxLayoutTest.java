// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.9.3  Box Layout
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//BoxLayoutTest.java

import java.awt.*;            // for Container, BorderLayout
import java.awt.event.*;      // for WindowAdapter
import javax.swing.*;

public class BoxLayoutTest {
    public static void main( String[] args ) {
        JFrame f = new JFrame( "BoxLayoutTest" );

        f.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });

        Container contentPane = f.getContentPane();               //(A)

        String[] data = {"sunny", "hot", "stormy", "balmy",       //(B)
                         "cold",  "frigid", "rainy", "windy", 
                         "snowy", "blistery", "blizzardy"};

        JList list = new JList( data );                           //(C)

        //this makes list the viewport of listscroller:
        JScrollPane listScroller = new JScrollPane( list );       //(D)

        listScroller.setPreferredSize( new Dimension( 300, 100 ) );
        listScroller.setMinimumSize( new Dimension( 300, 100 ) );
        listScroller.setAlignmentX( Component.LEFT_ALIGNMENT );

        JPanel listPanel = new JPanel();                          //(E)
        listPanel.setLayout( 
                    new BoxLayout( listPanel, BoxLayout.Y_AXIS ) );
        JLabel label = new JLabel( "Select today's weather:" );
        listPanel.add( label );
        listPanel.add( 
                Box.createRigidArea( new Dimension( 0, 10 ) ) );  //(F)
        listPanel.add( listScroller );
        listPanel.setBorder( 
            BorderFactory.createEmptyBorder( 10, 10, 10, 10 ) );  //(G)

        contentPane.add( listPanel, BorderLayout.CENTER );        //(H)

        JButton cancelButton = new JButton( "Cancel" );
        JButton selectButton = new JButton( "Select" );

        JPanel buttonPanel = new JPanel();                        //(I)
        buttonPanel.setLayout( 
                 new BoxLayout( buttonPanel, BoxLayout.X_AXIS ) );
        buttonPanel.setBorder( 
                 BorderFactory.createEmptyBorder(0,10,10,10 ) );
        buttonPanel.add( Box.createHorizontalGlue() );
        buttonPanel.add( cancelButton );
        buttonPanel.add( 
                Box.createRigidArea( new Dimension( 10, 0 ) ) );
        buttonPanel.add( selectButton );

        contentPane.add( buttonPanel, BorderLayout.SOUTH );       //(J)

        f.pack();
        f.setLocation( 200, 300 );
        f.setVisible( true );
    }
}
