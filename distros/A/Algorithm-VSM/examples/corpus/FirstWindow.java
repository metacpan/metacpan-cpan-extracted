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



//FirstWindow.java

import javax.swing.*;
 
class FirstWindow {
    public static void main(String[] args)  {
        JFrame f = new JFrame( "FirstWindow" );             
        f.setSize( 300, 200 );               
        f.setLocation( 200, 300 );             
        f.setVisible( true );                            
    }
}
