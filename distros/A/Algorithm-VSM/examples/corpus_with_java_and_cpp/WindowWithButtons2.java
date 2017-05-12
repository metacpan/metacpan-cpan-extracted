// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.13  Event Processing In AWT/Swing
//

//WindowWithButtons2.java

import javax.swing.*;
import java.awt.*;    
import java.awt.event.*;

class WindowWithButtons {
    static JButton startButton;
    static JButton greetingButton;
    static JButton closeButton;

    public static void main(String[] args)
    {
        JPanel buttonPanel = new JPanel();
        buttonPanel.setLayout( new GridLayout( 1, 3, 10, 0 ) );   
        ImageIcon icon1 = new ImageIcon( "images/smiley.gif" );
        ImageIcon icon2 = new ImageIcon( "images/happyface.gif" );

        startButton = new JButton("Start here" );      
        startButton.setToolTipText( 
                          "Click to enable the other buttons." );
        startButton.setMnemonic( KeyEvent.VK_S );
        startButton.addActionListener( new ActionListener() {     //(M)
            public void actionPerformed( ActionEvent e ) {
                    greetingButton.setEnabled( true );
                    closeButton.setEnabled( true );
            }
        } );
        buttonPanel.add( startButton );                 

        greetingButton = new JButton( "Click for Greeting", icon1 );      
        greetingButton.setVerticalTextPosition(AbstractButton.BOTTOM );
        greetingButton.setHorizontalTextPosition(
                                             AbstractButton.CENTER);
        greetingButton.setToolTipText( "First \"Start\"," 
                           + " then click this to see greetings." );
        greetingButton.setMnemonic( KeyEvent.VK_C );
        greetingButton.addActionListener( new ActionListener() {  //(N)  
            public void actionPerformed( ActionEvent e ) {
                    startButton.setEnabled( false );
                    System.out.println( "Good Morning to you!" );
            }
        } );
        buttonPanel.add( greetingButton );                 

        closeButton = new JButton( "Time to quit", icon2 );      
        closeButton.setToolTipText( "First \"Start\"," 
                         + " then click here to close window." );
        closeButton.setMnemonic(KeyEvent.VK_T);
        closeButton.addActionListener( new ActionListener() {     //(O)
            public void actionPerformed( ActionEvent e ) {
                    System.out.println( "Good Bye!" );
                    System.exit( 0 );
            }
        } );
        buttonPanel.add( closeButton );                 

        greetingButton.setEnabled( false );
        closeButton.setEnabled( false );

        buttonPanel.setBorder( 
                 BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );
        
        JFrame f = new JFrame();
        f.addWindowListener( new WindowAdapter() {                //(P) 
                public void windowClosing( WindowEvent e ) {      //(Q)
                    System.exit( 0 );
                }
        } );
        f.getContentPane().add( buttonPanel );
        f.setLocation( 100, 50);                            
        f.pack();
        f.setVisible( true );                                           
    }
}
