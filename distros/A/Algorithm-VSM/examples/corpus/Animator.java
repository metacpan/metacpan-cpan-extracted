// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 18  Multithreaded Object-Oriented Programming
//
// Section:     Section 18.8  Java Threads For Applets
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Animator.java

import java.applet.*;
import java.awt.*;

public class Animator extends Applet implements Runnable {
    private String imageNameBase;                                 //(A)
    private int imageCount;                                       //(B)
    private Thread runner;                                        //(C)
    private Image image = null;                                   //(D)
    private Image[] imageArr;                                     //(E)
  
    public void init() {                                          //(F)
        imageNameBase = getParameter( "imagename" );              //(G)
        imageCount = Integer.parseInt( 
                         getParameter( "imagecount" ) );          //(H)
        imageArr = new Image[ imageCount ];                      
        int i = 0;
        while ( i < imageCount  ) {                              
            String imageName = imageNameBase + i + ".gif";
            imageArr[i] = 
                  getImage( getDocumentBase(), imageName );       //(I)
            MediaTracker tracker = new MediaTracker( this );     
            tracker.addImage( imageArr[i], 0 );                  
            try {
                tracker.waitForID( 0 );                          
            } catch( InterruptedException e ) {}
            i++;
        }
    }

    public void start() {                                         //(J)
        runner = new Thread( this );                              //(K)
        runner.start();                                           //(L)
    }

    public void stop() {                                          //(M)
        runner = null;                                            //(N)
    }

    public void paint( Graphics g ) {                             //(O)
        if ( image == null ) return;
        g.drawImage( image, 100, 100, this );                    
    }

    public void run() {                                           //(P)
        int i = 0;
        while ( true ) {
            image = imageArr[i];
            i = ++i % imageCount;
            try {
                Thread.sleep( 200 );
            } catch( InterruptedException e ){}
            repaint();                                            //(Q)
        }
    }
}