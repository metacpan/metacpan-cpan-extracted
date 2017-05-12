// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User INterfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.9  Layout Management In AWT/Swing
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//BorderLayoutTest.java
//additional files needed: snlowflake.gif, zwthr14.gif, 
//thunderstormanim.gif, sunanim.gif

import java.awt.*;            // for Container, BorderLayout
import java.awt.event.*;      // for WindowAdapter
import javax.swing.*;
import javax.swing.border.*;  // Border, BorderFactory

public class BorderLayoutTest {
    public static void main( String[] args ) {
        JFrame f = new JFrame( "BorderLayoutTest" );

        f.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });

        Container contentPane = f.getContentPane();

        //the following is unnecessary since BorderLayout is default:
        // contentPane.setLayout( new BorderLayout() ); 

        //NORTH:
        ImageIcon northIcon = new ImageIcon( "image/snowflake.gif" );
        JLabel northLabel = new JLabel( "Frigid in the North", 
                                         northIcon, 
                                         JLabel.CENTER ); 
        northLabel.setVerticalTextPosition( JLabel.BOTTOM );
        northLabel.setHorizontalTextPosition( JLabel.CENTER );
        contentPane.add( northLabel , BorderLayout.NORTH );

        //SOUTH:
        ImageIcon southIcon = new ImageIcon( "image/zwthr14.gif" );
        JLabel southLabel = new JLabel( "Balmy in the South", 
                                         southIcon, 
                                         JLabel.CENTER ); 
        southLabel.setVerticalTextPosition( JLabel.BOTTOM );
        southLabel.setHorizontalTextPosition( JLabel.CENTER );
        contentPane.add( southLabel, BorderLayout.SOUTH );

        //EAST:
        ImageIcon eastIcon = 
                     new ImageIcon( "image/thunderstormanim.gif" );
        JLabel eastLabel = new JLabel( "Stormy In the East", 
                                       eastIcon, 
                                       JLabel.CENTER ); 
        eastLabel.setVerticalTextPosition( JLabel.BOTTOM );
        eastLabel.setHorizontalTextPosition( JLabel.CENTER );
        Border borderEastLabel = 
                      BorderFactory.createLineBorder( Color.blue );
        eastLabel.setBorder( borderEastLabel );
        contentPane.add( eastLabel, BorderLayout.EAST );

        //WEST:
        ImageIcon iconWest = new ImageIcon( "image/sunanim.gif" );
        JLabel westLabel = new JLabel( "Sunny in the West", 
                                       iconWest, 
                                       JLabel.CENTER ); 
        westLabel.setVerticalTextPosition( JLabel.BOTTOM );
        westLabel.setHorizontalTextPosition( JLabel.CENTER );
        Border borderWestLabel = 
                    BorderFactory.createLineBorder( Color.black );
        westLabel.setBorder( borderWestLabel );
        contentPane.add( westLabel, BorderLayout.WEST );

        //CENTER:
        JLabel centerLabel = 
               new JLabel( "The Weather Compass", JLabel.CENTER );
        Border borderCenterLabel = 
               BorderFactory.createLineBorder( Color.red );
        centerLabel.setBorder( borderCenterLabel );
        contentPane.add( centerLabel , BorderLayout.CENTER );

        f.pack();
        f.setLocation( 200, 300 );
        f.setVisible( true );
    }
}
