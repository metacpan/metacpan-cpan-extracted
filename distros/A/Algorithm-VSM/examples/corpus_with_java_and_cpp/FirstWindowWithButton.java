// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.5  Minimalist GUI Programs In AWT/Swing
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//FirstWindowWithButton.java

import javax.swing.*;
import java.awt.*;                   // for FlowLayout
import java.awt.event.*;             // for ActionListener

class FirstWindowWithButton {
    public static void main(String[] args) {
        JFrame f = new JFrame( "FirstWindowWithButton" );   

        f.addWindowListener(new WindowAdapter() {                 //(A)
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });

        JButton b = new JButton("Click Here for a Message");      //(B)
        b.setVerticalTextPosition( AbstractButton.CENTER );       //(C)
        b.setHorizontalTextPosition( AbstractButton.CENTER );     //(D)

        b.addActionListener( new ActionListener() {               //(E)
            public void actionPerformed( ActionEvent evt ) {
                System.out.println( "Have a Good Day!" );
            }
        });

        f.getContentPane().setLayout( new FlowLayout() );         //(F)
        f.getContentPane().add( b );                              //(G)
        f.setLocation( 100, 50);                                  //(H)
        f.pack();                                                 //(I)
        f.setVisible( true );                                     //(J)
    }
}
