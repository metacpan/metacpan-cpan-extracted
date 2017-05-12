// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 18  Multithreaded Object-Oriented Programming
//
// Section:     Section 18.9  The Event Dispatch Thread In AWT/Swing
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//EventThreadDemo.java

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.text.*;
import javax.swing.event.*;

class EventThreadDemo {

    public static void main( String[] args ) {

        JFrame frame = new JFrame( "Event Thread Demo" );

        frame.addWindowListener( new WindowAdapter() {
                public void windowClosing( WindowEvent e ) {
                    System.exit( 0 );
                }
        });

        JTextArea textArea = new JTextArea();
        textArea.setLineWrap(true);
        textArea.setWrapStyleWord(true);
        textArea.getDocument().addDocumentListener(
                                 new MyDocumentListener());
        JScrollPane areaScrollPane = new JScrollPane(textArea);
        areaScrollPane.setVerticalScrollBarPolicy(
                        JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        areaScrollPane.setPreferredSize(new Dimension(250, 250));
        areaScrollPane.setBorder(
            BorderFactory.createCompoundBorder(
                BorderFactory.createCompoundBorder(
                    BorderFactory.createTitledBorder("Plain Text"),
                    BorderFactory.createEmptyBorder(5,5,5,5)),
                areaScrollPane.getBorder()));
        
        frame.getContentPane().add( 
                       areaScrollPane, BorderLayout.CENTER );
        frame.pack();
        frame.setVisible( true );
        keepBusy( 500, "main" );                                  //(A)
    }

    static class MyDocumentListener implements DocumentListener {
        public void insertUpdate( final DocumentEvent e ) {
            String str = null;
            Document doc = e.getDocument();
            int lengthText = doc.getLength();
            try {
                str = doc.getText( lengthText - 1, 1 );
            } catch( BadLocationException badloc ) { 
                        badloc.printStackTrace(); 
            }
            keepBusy( 500, "MyDocumentListener" );                //(B)
            System.out.print( str );
        }
        public void removeUpdate(DocumentEvent e) { }
        public void changedUpdate(DocumentEvent e) { }
    }

    public static void keepBusy( int howLong, String source  ) {  
        if (SwingUtilities.isEventDispatchThread() == true )      //(C)
            System.out.println(                                   //(D)
             " using Event Dispatch Thread for keepBusy in " + source); 
        else 
            System.out.println(                                   //(E)
              "   using the main thread for keepBusy in " + source );
        long curr = System.currentTimeMillis();
        while ( System.currentTimeMillis() < curr + howLong )
            ;
    }
}