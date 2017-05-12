// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.13  Event Processing In AWT/Swing
//


//WindowWithButtons.java

import javax.swing.*;
import java.awt.*;    
import java.awt.event.*;

class WindowWithButtons {
    static JButton startButton;                                   //(A)
    static JButton greetingButton;                                //(B)
    static JButton closeButton;                                   //(C)

    private static class MyActionListener 
                    implements ActionListener {                   //(D)
        public void actionPerformed( ActionEvent e )  {
            if ( e.getActionCommand().equals( "start" ) ) {
                greetingButton.setEnabled( true );
                closeButton.setEnabled( true );
            }
            else if ( e.getActionCommand().equals("print greeting") ) {
                startButton.setEnabled( false );
                System.out.println( "Good Morning to you!" );
            }
            else if ( e.getActionCommand().equals( "close window" ) ) {
                System.out.println( "Good Bye!" );
                System.exit( 0 );
            }
        }
    }

    private static class MyWindowListener extends WindowAdapter { //(E)
        public void windowClosing( WindowEvent e ) {
            System.exit( 0 );
        }
    }

    public static void main(String[] args)
    {
        JPanel buttonPanel = new JPanel();
        buttonPanel.setLayout( new GridLayout( 1, 3, 10, 0 ) );   //(F)
        ImageIcon icon1 = new ImageIcon( "images/smiley.gif" );
        ImageIcon icon2 = new ImageIcon( "images/happyface.gif" );

        startButton = new JButton("Start here" );      
        startButton.setActionCommand( "start" );
        startButton.setToolTipText( 
                   "Click to enable the other buttons." );        //(G)
        startButton.setMnemonic( KeyEvent.VK_S );                 //(H)
        startButton.addActionListener( new MyActionListener() );  //(I)
        buttonPanel.add( startButton );                 

        greetingButton = new JButton( "Click for Greeting", icon1 );      
        greetingButton.setVerticalTextPosition(AbstractButton.BOTTOM);
        greetingButton.setHorizontalTextPosition( 
                                     AbstractButton.CENTER );
        greetingButton.setToolTipText( "First \"Start\"," 
                       + " then click this to see greetings." );
        greetingButton.setMnemonic( KeyEvent.VK_C );
        greetingButton.setActionCommand( "print greeting" );
        greetingButton.addActionListener(new MyActionListener()); //(J)
        buttonPanel.add( greetingButton );                 

        closeButton = new JButton( "Time to quit", icon2 );      
        closeButton.setToolTipText( "First \"Start\"," 
                         + " then click here to close window." );
        closeButton.setActionCommand( "close window" );
        closeButton.setMnemonic(KeyEvent.VK_T);
        closeButton.addActionListener( new MyActionListener() );  //(K)
        buttonPanel.add( closeButton );                 

        greetingButton.setEnabled( false );
        closeButton.setEnabled( false );

        buttonPanel.setBorder( 
               BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );
        
        JFrame f = new JFrame();
        f.addWindowListener( new MyWindowListener() );            //(L)
        f.getContentPane().add( buttonPanel );
        f.setLocation( 100, 50);                            
        f.pack();
        f.setVisible( true );                                           
    }
}
