// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.17  Windows with Menus in Qt
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




///////////  file: WindowWithMenu.cc  /////////////


#include "WindowWithMenu.h"
#include <qfiledialog.h>
#include <iostream> 
using namespace std;


WindowWithMenu::WindowWithMenu( QWidget* parent, const char* name )
    : QWidget( parent, name )
{
    setPalette( QPalette( QColor( 250, 250, 200 ) ) );

    filemenu = new QPopupMenu( this ); //arg is parent, useful for auo destruct
    filemenu->insertItem( "New", this, SLOT( allowTextEntry() ) );
    filemenu->insertItem( "Open", this, SLOT( getTextFromFile() ) );
    filemenu->insertItem( "Save", this, SLOT( saveTextToFile() ) );


    colormenu = new QPopupMenu( this );
    colormenu->insertItem( "blue", BLUE );
    colormenu->insertItem( "yellow", YELLOW );
    colormenu->insertItem( "magenta", MAGENTA );

    QObject::connect( colormenu,
                      SIGNAL( activated( int ) ),
                      this,
                      SLOT( selectColor( int ) ) );


    menubar = new QMenuBar( this );
    menubar->insertItem( "&File", filemenu );
    menubar->insertItem( "Color", colormenu );

    QRect rect = menubar->frameGeometry();
    int h = rect.height();

    textarea = new QMultiLineEdit( this );
    textarea->setGeometry( 0, h, 300, 350 );
    textarea->setReadOnly( TRUE );
}


WindowWithMenu::~WindowWithMenu() { }



void WindowWithMenu::allowTextEntry() 
{
    cout << "New selected" << endl;
    textarea->setReadOnly( FALSE );
}


void WindowWithMenu::getTextFromFile() 
{
    cout << "Open selected" << endl;
    QFileDialog* fd = new QFileDialog();
    QString fileName = 
        fd->getOpenFileName( QString::null, QString::null, this );
    cout << "file selected: " + fileName << endl;    
    if ( !fileName.isEmpty() && !fileName.isNull() )
        load( fileName );
    else
        cout << "File is either empty or does not exist" << endl;
}
                                                                         


void WindowWithMenu::saveTextToFile() {
    cout << "Save selected" << endl;
    QString fileName = 
       QFileDialog::getSaveFileName( QString::null, QString::null, this );
    save( fileName );
}



void WindowWithMenu::selectColor( int item ) {

    switch( item ) {
        case BLUE:
            borderColor = &blue;  // predefined QColor object
            textarea->setPalette( QPalette( *borderColor ) );
            textarea->repaint();
            break;
        case YELLOW:
            borderColor = &yellow;
            textarea->setPalette( QPalette( *borderColor ) );
            textarea->repaint();
            break;
        case MAGENTA:
            borderColor = &magenta;
            textarea->setPalette( QPalette( *borderColor ) );
            textarea->repaint();
            break;
        default:
            borderColor = &white;
            textarea->setPalette( QPalette( *borderColor ) );
            textarea->repaint();
    }
}
  

void WindowWithMenu::load( const char* fileName ) {

    QFile f( fileName );
    if ( !f.open( IO_ReadOnly ) )
        return;
 
    textarea->setAutoUpdate( FALSE );
    //    textarea->clear();
 
    QTextStream t(&f);
    while ( !t.eof() ) {
        QString s = t.readLine();
        textarea->append( s );
    }
    f.close();
 
    textarea->setAutoUpdate( TRUE );
    textarea->repaint();
    textarea->setEdited( FALSE );
    textarea->setReadOnly( FALSE );
}                   



void WindowWithMenu::save( const char* filename )
{
    QString text = textarea->text();
    QFile f( filename );
    if ( !f.open( IO_WriteOnly ) ) {
        cout << "Could not write to the file" << endl;
        return;
    }
 
    QTextStream t( &f );
    t << text;
    f.close();
 
    textarea->setEdited( FALSE );
}
 
