// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User INterfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.9.6  Grid-Bag Layout
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//GridBagLayoutTest.java

import java.awt.*;            // for Container, BorderLayout
import java.awt.event.*;      // for WindowAdapter
import javax.swing.*;

public class GridBagLayoutTest {
    public static void main( String[] args ) {

        JButton button;

        JFrame f = new JFrame( "GridBagLayoutTest" );
        f.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });

        Container contentPane = f.getContentPane();
        GridBagLayout gridbag = new GridBagLayout();
        contentPane.setLayout( gridbag );
        GridBagConstraints cons = new GridBagConstraints();
        cons.fill = GridBagConstraints.BOTH;
        cons.weightx = 1.0;
        cons.weighty = 1.0;

        // ROW 1:
        button = new JButton( "Button 1" );
        cons.gridx = 0;
        cons.gridy = 0;
        cons.ipadx = 100;
        gridbag.setConstraints( button, cons );
        contentPane.add( button );

        button = new JButton( "Button 2" );
        cons.gridx = 1;
        cons.gridy = 0;
        cons.ipadx = 0;
        gridbag.setConstraints( button, cons );
        contentPane.add( button );

        button = new JButton( "Button 3" );
        cons.gridx = 2;
        cons.gridy = 0;
        gridbag.setConstraints( button, cons );
        contentPane.add( button );

        // ROW 2:       
        button = new JButton( "Button 4" );
        cons.gridwidth = 2;
        cons.gridx = 0;
        cons.gridy = 1;
        cons.ipady = 50;
        gridbag.setConstraints( button, cons );
        contentPane.add( button );

        button = new JButton( "Button 5" );
        cons.gridwidth = 1;
        cons.gridx = 2;
        cons.gridy = 1;
        gridbag.setConstraints( button, cons );
        contentPane.add( button );

        // ROW 3:
        button = new JButton( "Button 6" );
        cons.gridwidth = 3;
        cons.gridx = 0;
        cons.gridy = 2;
        cons.ipady = 0;
        gridbag.setConstraints( button, cons );
        contentPane.add( button );

        f.pack();
        f.setLocation( 200, 300 );
        f.setVisible( true );
    }
}
