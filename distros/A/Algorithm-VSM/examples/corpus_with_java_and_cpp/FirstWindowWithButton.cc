// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.6  Minimialist GUI Programs In QT
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//FirstWindowWithButton.cc

#include <qapplication.h>
#include <qmainwindow.h>
#include <qpushbutton.h>
#include <qfont.h>
 
int main( int argc, char **argv )
{
    QApplication myApp( argc, argv );                             //(A) 
    QMainWindow* myWin = new QMainWindow( 0, 0, 0 );              //(B)
    myWin->resize( 500, 300 );                                    //(C)
    myWin->move( 200, 100 );                                      //(D)

    QPushButton* quitButton = new QPushButton( "Quit", myWin );   //(E)
    quitButton->resize( 60, 30 );                                 //(F)
    quitButton->move( 220, 135 );                                 //(G)
    quitButton->setFont( QFont( "Times", 18, QFont::Bold ) );     //(H)
 
    QObject::connect( quitButton, 
                      SIGNAL(clicked()), 
                      &myApp, 
                      SLOT(quit()) );                             //(I)
    myApp.setMainWidget( myWin );                                 //(J)
    myWin->show();                                                //(L)
    return myApp.exec();                                          //(M)
}                          
