// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.14.1  A Qt Exammple that Requires Meta Object Compilation
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



///////////////     file:  CrazyWindow.cc   ///////////////

#include "CrazyWindow.h"
#include <qpainter.h>
#include <qlayout.h>

#include "MyTextPanel.h"
#include "MyDrawPanel.h"


CrazyWindow::CrazyWindow( QWidget* parent, const char* name )    // (B)
    : QWidget( parent, name )
{
    QGridLayout* grid = new QGridLayout( this, 0, 1 );           // (C)

    MyTextPanel* textPanel = 
               new MyTextPanel( this, "for text only" );         // (D)

    MyDrawPanel* drawPanel = 
               new MyDrawPanel( this, "for graphics only" );     // (E)

    grid->addWidget( textPanel, 0, 0 );
    grid->addWidget( drawPanel, 0, 1 );

    QObject::connect( textPanel,                                 // (F)
                      SIGNAL( userTypedKeyword( char* ) ),
                      drawPanel,
                      SLOT( drawColoredSquare( char* ) ) );
}
