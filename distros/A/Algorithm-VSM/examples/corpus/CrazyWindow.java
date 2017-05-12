// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.13.1  An Exammple In Inter-Component Communication in AWT/Swing
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//CrazyWindow.java

import javax.swing.*;                 // for JTextArea, JPanel, etc.
import javax.swing.event.*;           // for DocumentListener
import javax.swing.text.*;            // for Document interface
import java.awt.*;                    // for Graphics, GridLayout, etc.
import java.awt.event.*;              // for WindowAdapter

class CrazyWindow extends JFrame {
    MyTextPanel panel1;                                           //(A)
    MyDrawPanel panel2;                                           //(B)
    
    public CrazyWindow() {
        super( "Crazy Window" );
        addWindowListener( new WindowAdapter() {            
                 public void windowClosing( WindowEvent e ) { 
                     System.exit( 0 ) ;           
                 } 
        });
        JPanel contentPane = new JPanel();
        contentPane.setLayout(new GridLayout(1, 2));
        panel1 = new MyTextPanel();                               //(C)
        panel2 = new MyDrawPanel();                               //(D)
        contentPane.add( panel1 );  
        contentPane.add( panel2 );
        setContentPane( contentPane );
    }

    class MyTextPanel extends JPanel  {
        class MyDocumentListener implements DocumentListener {    //(E)
            int lengthText;
            StringBuffer word = new StringBuffer("");             //(F)
            public void insertUpdate( DocumentEvent e ) {         //(G)
                Document doc = (Document) e.getDocument();
                try {
                    lengthText = doc.getLength();
                    String currentChar = 
                                 doc.getText( lengthText - 1, 1 );
                    char ch = 
                       currentChar.charAt( currentChar.length() - 1 );
                    if ( currentChar.equals( " " ) || ch == '\n' ) {
                        if ( word.toString().equals( "red" ) ) {  //(H)
                            panel2.drawColoredSquare( "red" );    //(I)
                        }
                        if ( word.toString().equals( "green" ) ) {
                            panel2.drawColoredSquare( "green" );
                        }
                        if ( word.toString().equals( "blue" ) ) {
                            panel2.drawColoredSquare( "blue" );
                        }
                        if ( word.toString().equals( "magenta" ) ) {
                            panel2.drawColoredSquare( "magenta" );
                        }
                        if ( word.toString().equals( "orange" ) ) {
                            panel2.drawColoredSquare( "orange" );
                        }
                        word = new StringBuffer();
                    }
                    else                                          //(J)
                        word = word.append( currentChar );
                } catch( BadLocationException bad ) { 
                    bad.printStackTrace(); 
                }
            }
            public void removeUpdate( DocumentEvent e )  {        //(K)
                try {
                  Document doc = (Document) e.getDocument();
                  lengthText = doc.getLength();
  
                  String currentChar = 
                                  doc.getText( lengthText - 1, 1 );
                  char ch = 
                    currentChar.charAt( currentChar.length() - 1 );
                  if ( currentChar.equals( " " ) || ch == '\n'  ) {
                      word = new StringBuffer();                  //(L)
                  }
                  else if ( word.length() >= 1 )
                      word = 
                        word.deleteCharAt( word.length() - 1 );   //(M)
                } catch( BadLocationException bad ) { 
                    bad.printStackTrace(); 
                }
            }
            public void changedUpdate( DocumentEvent e ) {}       //(N) 
        }

        public MyTextPanel() {
             JTextArea ta = new JTextArea( 100, 60);
             ta.getDocument().addDocumentListener( 
                                new MyDocumentListener() );
             ta.setEditable(true);
             JScrollPane jsp = new JScrollPane( ta );
             jsp.setPreferredSize(new Dimension( 150, 150));
             add(jsp, "Center");
             setBorder( BorderFactory.createCompoundBorder(
                 BorderFactory.createTitledBorder("My Text Window"), 
                 BorderFactory.createEmptyBorder( 5, 5, 5, 5 ) ) );
        }
    }   

    // panel2
    class MyDrawPanel extends JPanel {
        protected void paintComponent( Graphics g ) { }
        public void drawColoredSquare( String color ) {           //(O)
            Graphics g = getGraphics();
            g.translate( getInsets().left, getInsets().top );
            int width = getBounds().width;
            int height = getBounds().height;    
            if ( color.equals( "red" ) ) g.setColor( Color.red );
            if ( color.equals( "green" ) ) g.setColor( Color.green );
            if ( color.equals( "blue" ) ) g.setColor( Color.blue );    
            if ( color.equals( "orange" ) ) g.setColor( Color.orange );
            if ( color.equals("magenta") ) g.setColor( Color.magenta );
            int x = (int) ( Math.random() * width );
            int y = (int) ( Math.random() * height );
            if ( x > width - 30 ) x = x - 30;
            if ( y > height - 30 ) y = y - 30;
            g.fillRect( x, y, 30, 30 );
            paintComponent( g );                                  //(P)
        }
    }

    public static void main(String[] args)
    {
        JFrame wg = new CrazyWindow();            
        wg.setSize( 500, 400 );
        wg.show();
    }
}