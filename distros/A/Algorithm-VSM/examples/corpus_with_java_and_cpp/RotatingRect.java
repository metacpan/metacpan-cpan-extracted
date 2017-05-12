// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.19  Drawing Shapes, Text, And Images In AWT/SwingR4
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//RotatingRect.java

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class RotatingRect {
    public static void main(String[] args) {
        JFrame f = new JFrame("Rotating Rectangle");
        f.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });
        Container container = f.getContentPane();
        container.add( new RotatingRectPanel() );
        f.setLocation( 300, 300 );
        f.pack();
        f.setVisible(true);
    }
}

class RotatingRectPanel extends JPanel {
    Graphics2D g2d;
    Point point = null;          // point in window clicked on
    Dimension preferredSize = new Dimension(300, 300);

    //width and height of the rotating yellow square:
    int rectWidth = 60;          
    int rectHeight = 60;         
    
    //the following two data members needed for computing
    //rotation angles around the center of the square:
    int halfWindowWidth = preferredSize.width / 2;
    int halfWindowHeight = preferredSize.height / 2;

    //theta is desired orientation of the square
    //thetaPrevious is current orientation of the square
    double theta  = 0.0;                                          //(J)
    double thetaPrevious = 0.0;                                   //(K)

    //constructor:
    public RotatingRectPanel( ) {
        addMouseListener(new MouseAdapter() {                     //(L)
            public void mousePressed(MouseEvent e) {              //(M)
                //coordinates of the pointed clicked on:
                int x = e.getX();                                 //(N)
                int y = e.getY();                                 //(O)
                if (point == null) {
                    point = new Point(x, y);
                } else {
                    point.x = x;
                    point.y = y;
                }
                repaint();
            }
        });
    }

    //important for panel sizing:
    public Dimension getPreferredSize() {     
        return preferredSize;
    }

    public void paintComponent(Graphics g) {
        super.paintComponent(g);                //paint background
        int xFromCenter = 0;
        int yFromCenter = 0;
        int rectOriginX = halfWindowWidth - rectWidth / 2;
        int rectOriginY = halfWindowHeight - rectHeight / 2;

        g2d = (Graphics2D) g;
        if ( point != null ) {
            xFromCenter = point.x - halfWindowWidth;
            yFromCenter = point.y - halfWindowHeight;
            theta = Math.atan2( (double) yFromCenter, 
                                (double) xFromCenter ) + Math.PI/4.0;
        }

        g2d.translate( halfWindowWidth, halfWindowHeight );       //(P)
        g2d.rotate( theta - thetaPrevious );                      //(Q)
        g2d.translate( - halfWindowWidth, - halfWindowHeight );   //(R)
        g2d.setColor(Color.yellow);
        g2d.fillRect(rectOriginX, rectOriginY, rectWidth, rectHeight);

        thetaPrevious = theta;
    }
}
