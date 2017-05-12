// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.19  Drawing Shapes, Text, And Images In AWT/Swing
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//RenderGraphics.java

import java.awt.*;            // for Color, GridLayout, Graphics, etc.
import java.awt.event.*;      // for WindowAdapter
import javax.swing.*;

public class RenderGraphics {
    static final int maxCharHeight = 15;
    static final Color bg = Color.lightGray;
    static final Color fg = Color.black;
    static int width;          // for width of a shape panel
    static int height;         // for height of a shape panel
    static int rectWidth;      // width of shape's bounding rect
    static int rectHeight;     // height of shape's bounding rect

    public static void main( String[] args ) {
        JFrame f = new JFrame( "Draw Shape Samples" );
        f.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });

        f.setBackground(bg);                                      //(D) 
        f.setForeground(fg);                                      //(E)

        Container contentPane = f.getContentPane();
        contentPane.setLayout( new GridLayout( 0, 3 ) );

        //polyline:
        contentPane.add( new JPanel() {
            public void paintComponent(Graphics g) {
                super.paintComponent(g);      //clears the background
                width = getWidth();
                height = getHeight();
                int stringY = height - 10;
                rectWidth = width - 20;
                rectHeight = stringY - maxCharHeight - 10;
                int x2Points[] = 
                      {10, 10+rectWidth, 10, 10+rectWidth};
                int y2Points[] = 
                      {10, 10+rectHeight, 10+rectHeight, 10};
                g.drawPolyline(x2Points, 
                      y2Points, x2Points.length);                 //(F)
                g.drawString("drawPolyline", 10, stringY);        //(G)
            }
            });

        //rounded rectangle:
        contentPane.add( new JPanel() {
            public void paintComponent(Graphics g) {
                super.paintComponent(g);  
                width = getWidth();
                height = getHeight();
                int stringY = height - 10;
                rectWidth = width - 20;
                rectHeight = stringY - maxCharHeight - 10;
                g.drawRoundRect(10, 
                      10, rectWidth, rectHeight, 10, 10);         //(H)
                g.drawString("drawRect", 10, stringY);        
            }
            });

        //filled oval:
        contentPane.add( new JPanel() {
            public void paintComponent(Graphics g) {
                super.paintComponent(g);  
                width = getWidth();
                height = getHeight();
                int stringY = height - 10;
                rectWidth = width - 80;
                rectHeight = stringY - maxCharHeight - 10;
                g.fillOval(40, 10, rectWidth, rectHeight);        //(I)
                g.drawString("drawOval", 10, stringY);
              }
            });

        f.setSize(new Dimension(550, 200));
        f.setVisible(true);
    }
}