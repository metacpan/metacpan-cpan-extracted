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



//EventThreadDemo2.java

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.text.*;
import javax.swing.event.*;

//////////////////////  class EventThreadDemo  ////////////////////////
class EventThreadDemo {
    public static void main( String[] args ) {
        LaunchAFrame laf1 = new LaunchAFrame();                   //(A)
        LaunchAFrame laf2 = new LaunchAFrame();                   //(B)
        laf1.start();                                             //(C)
        laf2.start();                                             //(D)
    }
}

////////////////////////  class LaunchFrame  /////////////////////////
class LaunchAFrame extends Thread {                               //(E)
    public LaunchAFrame() {}

    public void run() {                                           //(F)
        MyTools.printThreadInfo(                                  //(G)
                 "Just before creating Frame object:" );
        JFrame frame = new JFrame( "EventThreadsDemo 2" );        //(H)
        MyTools.printThreadInfo( 
                 "Just after creating Frame object:" );
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
        MyTools.printThreadInfo(                                  //(I)
                     "Just after registering document listener:" );
        JScrollPane areaScrollPane = new JScrollPane(textArea);

        MyTools.printThreadInfo(                                  //(J)
                     "Just after creating the scroll pane:" );

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
        MyTools.printThreadInfo( "Just before calling pack:" );
        frame.pack();
        frame.setLocation( 300, 300 );
        frame.setVisible( true );
        MyTools.printThreadInfo("Just after calling setVisible:");//(K)     
    }
}

///////////////////////////  class MyTools  ///////////////////////////
class MyTools {                                                   //(L)
    public static void printThreadInfo( String s ) {              //(M)
        System.out.println( s );
//        Thread.currentThread().getThreadGroup().list();
//        System.out.println( 
//          "Number of threads in the current thread group: "
//          + Thread.currentThread().getThreadGroup().activeCount() );
        System.out.println( "The current thread is: " 
                          + Thread.currentThread() );
    }

    public static void keepBusy( int howLong ) {                  //(N)
        long curr = System.currentTimeMillis();
        while ( System.currentTimeMillis() < curr + howLong )
            ;
    }
}

//////////////////////  class MyDocumentListener  /////////////////////
class MyDocumentListener implements DocumentListener {
        public void insertUpdate( final DocumentEvent e ) {
            String str = null;
            Document doc = e.getDocument();
            int lengthText = doc.getLength();
            try {
                str = doc.getText( lengthText - 1, 1 );
            } catch( BadLocationException badloc ) { 
                        badloc.printStackTrace(); 
            }
            MyTools.printThreadInfo("From iniside the listener:");//(O)    
            MyTools.keepBusy( 500 );
            System.out.print( str );
        }
        public void removeUpdate(DocumentEvent e) { }
        public void changedUpdate(DocumentEvent e) { }
}