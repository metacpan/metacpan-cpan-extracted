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


////////////////  file:  MyTextPanel.cc  ///////////////

#include "MyTextPanel.h"
#include <qtextstream.h>
#include <stdlib.h>                   // for malloc()


MyTextPanel::MyTextPanel( QWidget* parent, const char* name )
    : QMultiLineEdit( parent, name )
{
    word = QString( "" );
    setPalette( QPalette( QColor( 250, 250, 200 ) ) );

    //MyTextPanel inherits the signal textChanged() 
    //from its superclass QMultiLineEdit
    QObject::connect( this,                                // (I)
                      SIGNAL( textChanged() ),
                      this,
                      SLOT( doSomethingTextChanged( ) ) );
}


void MyTextPanel::doSomethingTextChanged()                 // (J)
{
    QString qstr = text();    
    QChar c = qstr[ (int) qstr.length() - 1 ];
    if ( c == ' ' ) {
        if ( word == "red"   || 
             word == "blue"  ||
             word == "orange"||
             word == "green"  ) {
           char* keyword = (char*) malloc( word.length() + 1 );
           strcpy( keyword, word );        
           emit( userTypedKeyword( keyword ) );
        }
       word = QString( "" );
    }
    else
        word += c ;
}
