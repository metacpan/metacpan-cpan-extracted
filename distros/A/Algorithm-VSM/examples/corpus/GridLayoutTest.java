// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.9.4  Grid Layout
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//GridLayoutTest.java

import java.awt.*;            // for Container, BorderLayout
import java.awt.event.*;      // for WindowAdapter
import javax.swing.*;
import javax.swing.border.*;  // for Border, BorderFactory

public class GridLayoutTest {
    public static void main( String[] args ) {
        JFrame f = new JFrame( "GridLayoutTest" );
        f.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });
        Container contentPane = f.getContentPane();
        contentPane.setLayout( new GridLayout( 0, 2 ) );

        //ITEM 1:
        ImageIcon firstIcon = new ImageIcon( "snowflake.gif" );
        JLabel firstLabel = new JLabel( "Frigid in the North", 
                                         firstIcon, 
                                         JLabel.CENTER ); 
        firstLabel.setVerticalTextPosition( JLabel.BOTTOM );
        firstLabel.setHorizontalTextPosition( JLabel.CENTER );
        contentPane.add( firstLabel );

        //ITEM 2:
        ImageIcon secondIcon = new ImageIcon( "zwthr14.gif" );
        JLabel secondLabel = new JLabel( "Balmy in the South", 
                                         secondIcon, 
                                         JLabel.CENTER ); 
        secondLabel.setVerticalTextPosition( JLabel.BOTTOM );
        secondLabel.setHorizontalTextPosition( JLabel.CENTER );
        contentPane.add( secondLabel );

        //ITEM 3:
        ImageIcon thirdIcon = new ImageIcon( "thunderstormanim.gif" );
        JLabel thirdLabel = new JLabel( "Stormy In the East", 
                                        thirdIcon, 
                                        JLabel.CENTER ); 
        thirdLabel.setVerticalTextPosition( JLabel.BOTTOM );
        thirdLabel.setHorizontalTextPosition( JLabel.CENTER );
        Border borderThirdLabel = 
                         BorderFactory.createLineBorder( Color.blue );
        thirdLabel.setBorder( borderThirdLabel );
        contentPane.add( thirdLabel );

        //ITEM 4:
        ImageIcon fourthIcon = new ImageIcon( "sunanim.gif" );
        JLabel fourthLabel = new JLabel( "Sunny in the West", 
                                         fourthIcon, 
                                         JLabel.CENTER ); 
        fourthLabel.setVerticalTextPosition( JLabel.BOTTOM );
        fourthLabel.setHorizontalTextPosition( JLabel.CENTER );
        Border borderFourthLabel = 
                 BorderFactory.createLineBorder( Color.black );
        fourthLabel.setBorder( borderFourthLabel );
        contentPane.add( fourthLabel );

        //ITEM 5:
        JLabel fifthLabel = 
              new JLabel( "The Weather Compass", JLabel.CENTER );
        Border borderFifthLabel = 
                     BorderFactory.createLineBorder( Color.red );
        fifthLabel.setBorder( borderFifthLabel );
        contentPane.add( fifthLabel );

        f.pack();
        f.setLocation( 200, 300 );
        f.setVisible( true );
    }
}
