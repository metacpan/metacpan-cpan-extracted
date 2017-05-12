// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.9.5  Card Layout
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//CardLayoutTest.java

import java.awt.*;            // for Container, BorderLayout
import java.awt.event.*;      // for WindowAdapter
import javax.swing.*;
import javax.swing.border.*;  // for Border, BorderFactory

public class CardLayoutTest extends JFrame implements ItemListener {
    JPanel cards;
    final static String[] comboBoxItems 
                    = {"frigid","balmy","stormy","sunny" };

    public CardLayoutTest() {
        Container contentPane = getContentPane();

        JPanel comboPanel = new JPanel();
        JComboBox c = new JComboBox( comboBoxItems );             //(A)
        c.setEditable( false );
        c.addItemListener( this );                                //(B)
        c.setBorder( 
             BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) ); //(C)
        comboPanel.add( c );                                      //(D)

        contentPane.add( comboPanel, BorderLayout.NORTH );

        cards = new JPanel() {
                public Dimension getPreferredSize() {             //(E)
                    Dimension size = super.getPreferredSize();
                    size.width = 200;
                    size.height = 200;
                    return size;
                }
        };

        cards.setLayout( new CardLayout() );

        //Card 1:
        ImageIcon firstIcon = new ImageIcon( "snowflake.gif" );
        JLabel firstLabel = new JLabel( "Frigid in the North", 
                                         firstIcon, 
                                         JLabel.CENTER ); 
        firstLabel.setVerticalTextPosition( JLabel.BOTTOM );
        firstLabel.setHorizontalTextPosition( JLabel.CENTER );
        firstLabel.setBorder( 
                    BorderFactory.createLineBorder( Color.blue ) );
        cards.add( firstLabel, "frigid" );

        //Card 2:
        ImageIcon secondIcon = new ImageIcon( "zwthr14.gif" );
        JLabel secondLabel = new JLabel( "Balmy in the South", 
                                         secondIcon, 
                                         JLabel.CENTER ); 
        secondLabel.setVerticalTextPosition( JLabel.BOTTOM );
        secondLabel.setHorizontalTextPosition( JLabel.CENTER );
        secondLabel.setBorder( 
               BorderFactory.createLineBorder( Color.green ) );
        cards.add( secondLabel, "balmy" );

        //Card 3:
        ImageIcon thirdIcon = new ImageIcon( "thunderstormanim.gif" );
        JLabel thirdLabel = new JLabel( "Stormy In the East", 
                                        thirdIcon, 
                                        JLabel.CENTER ); 
        thirdLabel.setVerticalTextPosition( JLabel.BOTTOM );
        thirdLabel.setHorizontalTextPosition( JLabel.CENTER );
        thirdLabel.setBorder( 
                        BorderFactory.createLineBorder( Color.red ) );
        cards.add( thirdLabel, "stormy" );

        //Card 4:
        ImageIcon fourthIcon = new ImageIcon( "sunanim.gif" );
        JLabel fourthLabel = new JLabel( "Sunny in the West", 
                                         fourthIcon, 
                                         JLabel.CENTER ); 
        fourthLabel.setVerticalTextPosition( JLabel.BOTTOM );
        fourthLabel.setHorizontalTextPosition( JLabel.CENTER );
        fourthLabel.setBorder( 
                      BorderFactory.createLineBorder( Color.white ) );
        cards.add( fourthLabel, "sunny" );

        contentPane.add( cards, BorderLayout.CENTER );

        addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });
    }
      
    public void itemStateChanged( ItemEvent evt ) {               //(F)
        CardLayout cl = (CardLayout) ( cards.getLayout() );
        cl.show( cards, (String) evt.getItem() );
    }

    public static void main( String[] args ) {
        CardLayoutTest window = new CardLayoutTest();
        window.setTitle( "CardLayoutTest" );
        window.setLocation( 200, 300 );
        window.pack();
        window.setVisible( true );
    }
}
