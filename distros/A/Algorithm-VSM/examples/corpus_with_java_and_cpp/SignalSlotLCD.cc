// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.14  Event Processing In Qt
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//SignalSlotLCD.cc
//Based on a program by Dalheimer with
//inconsequential changes made by the author

#include <qapplication.h>
#include <qslider.h>
#include <qlcdnumber.h>
 
int main( int argc, char **argv )
{
    QApplication myApp( argc, argv );                     
    QWidget* myWidget= new QWidget();                     
    myWidget->setGeometry( 400, 300, 170, 110 );          

    QSlider* myslider = 
               new QSlider( 0,      // minimum value              //(A)
               9,                   // maximum value      
               1,                   // step               
               1,                   // initial value      
               QSlider::Horizontal, // orient.            
               myWidget );          // parent             

    myslider->setGeometry( 10, 10, 150, 30 );             

    //first arg below is the number of digits to display:
    QLCDNumber* mylcdnum = new QLCDNumber( 1, myWidget );         //(B)
    mylcdnum->setGeometry( 60, 50, 50, 50 ); 
    //manual invocation of slot:
    mylcdnum->display( 1 );                                       //(C)

    // connect slider and number display
    QObject::connect( myslider,                                   //(D)
                      SIGNAL( valueChanged( int ) ),
                      mylcdnum,
                      SLOT( display( int ) ) );

    myApp.setMainWidget( myWidget );                     
    myWidget->show();                                    

    // starts event loop    
    return myApp.exec();                                 
}                          
