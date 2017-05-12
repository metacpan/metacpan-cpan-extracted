// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.22.3  An Applet Example
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//SlideShowApplet.java

import javax.swing.*;
import java.awt.*;             //for Graphics, Color, Dimension, etc.
import java.awt.event.*;
import java.net.*;             //for URL needed for image loading

public class SlideShowApplet extends JApplet {                    //(B)
    int frameIndex = 0;        //current frame number
    String dir;                //directory relative to the codebase 
    Timer timer;               //timer for sequencing through images      
    int pause;                 //time interval between images
    int numImages;             //number of images to display
    int width;                 //width of the applet
    int height;                //height of the applet
    int displayWidth;
    int displayHeight;
    JComponent contentPane;    //the applet's content pane
    ImageIcon images[];        //the images
    boolean finishedLoading = false;
    JLabel statusLabel;
    JScrollPane scrollableImage;
    boolean newFrameAvailable = false;

    public void init() {                                          //(C)
        //Get the applet parameters.
        String at = getParameter("dir");
        dir = (at != null) ? at : "images/slideshow";
        at = getParameter("pause");
        pause = (at != null) ? Integer.valueOf(at).intValue() : 2000;
        at = getParameter("numImages");
        numImages = (at != null) ? Integer.valueOf(at).intValue() : 10;

        width = getWidth();
        height = getHeight();
        displayWidth = width - getInsets().left - getInsets().right;
        displayHeight = height - getInsets().top - getInsets().bottom;

        contentPane = new JPanel() {
            public void paintComponent( Graphics g ) {            //(D)
                super.paintComponent( g );
                if ( finishedLoading && newFrameAvailable ) {
                    scrollableImage = 
                         new JScrollPane( 
                             new JLabel( 
                                 images[ frameIndex - 1 ],        //(E)
                                         JLabel.CENTER ) );
                    scrollableImage.setPreferredSize( 
                      new Dimension( 
                             displayWidth, displayHeight - 8 ) );
                }
                if ( scrollableImage != null ) {
                    contentPane.removeAll();
                    contentPane.add( scrollableImage );
                }
                contentPane.revalidate();
                contentPane.setVisible( true );
                newFrameAvailable = false;
            }
        };
        contentPane.setBackground(Color.white);                   //(F)
        setContentPane(contentPane);

        statusLabel = new JLabel("Loading Images...", JLabel.CENTER);
        statusLabel.setForeground( Color.red );
        contentPane.add(statusLabel);

        timer = new Timer( pause, new ActionListener() {          //(G)
                public void actionPerformed( ActionEvent evt ) {
                    frameIndex++;                                 //(H)
                    if ( frameIndex == numImages )
                        frameIndex = 1;
                    newFrameAvailable = true;
                    contentPane.repaint();
                }
        });
        timer.setInitialDelay( 0 );
        timer.setCoalesce(false);        

        images = new ImageIcon[numImages];                        //(I)
        new Thread() {                                            //(J)
                public void run() {
                    loadImages();
                }
        }.start();
    }

    public void start() {                                         //(K)
        if ( finishedLoading )
            timer.restart();
    }

    public void loadImages() {                                    //(L)
        String prefix = dir + "/flower";
        for ( int i = 0; i < numImages; i++ ) {
            statusLabel.setText( "loading image " + ( i + 1 ) );
            try {
              images[i] =                                         //(M)
                   new ImageIcon( new URL( getCodeBase() + 
                                  prefix + (i+1) + ".jpg" ) );
            } catch( MalformedURLException m ) {
                System.out.println(
                     "Couldn't create image: badly formed URL" );
            }
        }
        finishedLoading = true;
        statusLabel.setText( null );
        timer.start();
    }

    public void stop() {                                          //(N)
        timer.stop();
    }

    public String getAppletInfo() {                               //(O)
        return "Title: A SlideShow Applet\n";
    }
  
    public String[][] getParameterInfo() {                        //(P)
        String[][] info = {
          {"dir", 
           "String", 
           "the directory containing the images to loop"},
          {"pause", 
           "int", 
           "the time interval between successive frames"},
          {"numImages", 
           "int", 
           "the number of images to display; default is 10 " },
        };
        return info;
    }
}