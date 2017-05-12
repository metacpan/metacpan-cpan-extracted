// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.16  Windows With Menus In AWT/Swing
//


//WindowWithMenu.java

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;

class WindowWithMenu extends JFrame implements ActionListener {         
    TextArea ta = new TextArea( 45, 40 );                         //(A)
    String filename;
    FileDialog loadDialog = new FileDialog( this,                 //(B)
                                          "Load File Dialog:", 
                                          FileDialog.LOAD );
    FileDialog saveDialog = new FileDialog( this,                 //(C)
                                          "Save File Dialog:", 
                                          FileDialog.SAVE );  
    public WindowWithMenu() {
        super( "Window with Menu" );
        addWindowListener( new WindowAdapter() {            
            public void windowClosing( WindowEvent e ){
                System.exit( 0 ) ;           
            } 
        });

        MenuBar menuBar = new MenuBar();    
  
        ta.setEditable( false );              
        getContentPane().add( ta, "North" );                   

        Menu menu = new Menu( "File" );

        MenuItem menuItem = new MenuItem( "New" );
        menuItem.addActionListener( this );                       //(D)
        menu.add( menuItem );

        menuItem = new MenuItem( "Open" );
        menuItem.addActionListener( this );                       //(E)
        menu.add( menuItem );

        menuItem = new MenuItem( "Save" );
        menuItem.addActionListener( this );                       //(F)
        menu.add( menuItem );

        menuBar.add (menu );
        setMenuBar( menuBar );
    }

    public void actionPerformed( ActionEvent evt ) {              //(G)
        String arg = evt.getActionCommand(); 
        if ( arg.equals( "New" ) ) ta.setEditable( true );            
        if ( arg.equals( "Open" ) ) {          
            loadDialog.setDirectory(".");
            loadDialog.show();
            filename = loadDialog.getFile();                      //(H)
            String superString = "";
            if (filename != null) {
                try {
                    FileInputStream fin = 
                             new FileInputStream( filename );
                    while (true) {
                        int ch = fin.read();                      //(I)
                        if ( ch == -1 ) break;
                        superString += (char) ch;                 //(J)
                    }
                    fin.close();
                } catch( IOException e ) { 
                    System.out.println( "IO error" ); 
                }
            }
            ta.append( superString );                             //(K)
            ta.setEditable( true );
        }
        if ( arg.equals( "Save" ) ) {         
            saveDialog.setDirectory(".");
            saveDialog.show();
            filename = saveDialog.getFile();
            String superString = ta.getText();                    //(L)
            if (filename != null) {
                try {
                    FileOutputStream fout = 
                            new FileOutputStream( filename );
                    for (int i=0; i<superString.length(); i++)
                        fout.write( superString.charAt(i) );      //(M)
                    fout.close();
                } catch( IOException e ) { 
                    System.out.println( "IO error" ); 
                }
            }
        }
    }

    public static void main(String[] args){
        Toolkit tk = Toolkit.getDefaultToolkit();
        Dimension d = tk.getScreenSize();
        int screenHeight = d.height;
        int screenWidth = d.width;
        Frame wb = new WindowWithMenu();   
        wb.setSize( 2*screenWidth/3, 3*screenHeight/4 );
        wb.setLocation(screenWidth / 5, screenHeight / 5);
        wb.show();
    }
}
