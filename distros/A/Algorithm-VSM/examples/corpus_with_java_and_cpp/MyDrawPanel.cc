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


////////////////  file:  MyDrawPanel.cc  ///////////////

#include "MyDrawPanel.h"
#include <string.h>
#include <qpainter.h>
#include <qwidget.h>
#include <stdlib.h>       // for rand()
#include <time.h>         // for time(NULL) to seed rand()


MyDrawPanel::MyDrawPanel( QWidget* parent, const char* name )
    : QWidget( parent, name )
{
    setPalette( QPalette( QColor( 250, 250, 200 ) ) );
    srand( (unsigned) time(NULL) );
}



void MyDrawPanel::paintEvent( QPaintEvent* )
{
    QPainter p( this );
}



void MyDrawPanel::drawColoredSquare( char* key )
{
    QPainter p( this );
    p.setBrush( QString( key ) );
    p.setPen( NoPen );
    int x = rand() % 250 + 1;
    int y = rand() % 300 + 1;
    p.drawRect( QRect( x, y, 30, 30 ) );
}


QSizePolicy MyDrawPanel::sizePolicy() const                 // (K)
{
    return QSizePolicy( QSizePolicy::Expanding, 
                             QSizePolicy::Expanding );
}
