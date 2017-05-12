// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.10.2  Grid Layout
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//QGridLayoutTest.cc

#include <qdialog.h>
#include <qpushbutton.h>
#include <qlayout.h>
#include <qapplication.h>

class MyDialog : public QDialog {
public:
    MyDialog();
};

MyDialog::MyDialog() {
    QPushButton* b1 = new QPushButton( "button1", this );
    b1->setMinimumSize( b1->sizeHint() );
    QPushButton* b2 = new QPushButton( "button2", this );
    b2->setMinimumSize( b2->sizeHint() );
    QPushButton* b3 = new QPushButton( "button3", this );
    b3->setMinimumSize( b3->sizeHint() );
    QPushButton* b4 = new QPushButton( "button4", this );
    b4->setMinimumSize( b4->sizeHint() );

    QGridLayout* layout = new QGridLayout( this, 2, 3 );          //(A)
    layout->addWidget( b1, 0, 0 );                                //(B)
    layout->addWidget( b2, 0, 1 );
    layout->addWidget( b3, 0, 2 );
    layout->addWidget( b4, 1, 1 );
    layout->activate();
}


int main( int argc, char* argv[] )
{
    QApplication a( argc, argv );

    MyDialog* dlg = new MyDialog();
    dlg->show();
    a.setMainWidget( dlg );
    
    return a.exec();
}
