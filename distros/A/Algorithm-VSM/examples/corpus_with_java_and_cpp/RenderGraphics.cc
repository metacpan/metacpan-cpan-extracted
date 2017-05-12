// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.20  Drawing Shapes,Text,And Images In Qt
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//RenderGraphics.cc

#include <qwidget.h>
#include <qpainter.h>
#include <qapplication.h>
#include <qpixmap.h>

class RenderGraphicsWidget : public QWidget {                     //(I)
public:
    RenderGraphicsWidget();                                       //(J)
protected:
    void   paintEvent( QPaintEvent * );                           //(K)
};

RenderGraphicsWidget::RenderGraphicsWidget() {                    //(L)
    setCaption( "Render Graphics with Qt" );
    setBackgroundColor( white );
}

void RenderGraphicsWidget::paintEvent( QPaintEvent* ) {           //(M)
    QWMatrix matrix;                                              //(N)
    QPainter painter( this );                                     //(O)

    QBrush b1( Qt::NoBrush );                                    //(P1)
    QBrush b2( Qt::magenta );                                    //(P2)
    QBrush b3( Qt::red, Qt::Dense2Pattern );                     //(P3)
    QBrush b4( Qt::blue, Qt::Dense7Pattern );                    //(P4)
    QBrush b5( Qt::CrossPattern );                               //(P5)

    painter.setPen( Qt::red );                                    //(Q)
    painter.setBrush( b1 );                                       //(R)
    painter.drawRect( 10, 10, 100, 50 );                          //(S)

    matrix.translate( 150, 0 );
    matrix.rotate( (float)3*10 );       
    painter.setWorldMatrix( matrix );
    painter.setBrush( b2 );
    painter.drawRoundRect( 10, 10, 100, 50, 30, 30 );

    matrix.rotate( - (float)3*10 );     
    matrix.translate( - 150, -30 );
    matrix.shear( 0.8, 0.2 );           
    painter.setWorldMatrix( matrix );
    painter.setBrush( b3 );
    painter.drawRect( 250, 0, 100, 50 );

    matrix.reset();                                               //(T)
    //  matrix.setMatrix( 1.0, 0.0, 0.0, 1.0, 0.0, 0.0 );
    painter.setWorldMatrix( matrix );
    painter.setBrush( b4 );
    painter.drawRect( 10, 200, 100, 50 );

    painter.setBrush( b5 );
    painter.drawEllipse( 130, 200, 100, 50 );

    painter.setPen( Qt::NoPen );
    QPixmap pix( "allthatjazz.xpm" );
    pix.resize( 100, 50 );
    painter.drawPixmap( 260, 200, pix );

    int y = 300;
    painter.setWorldMatrix( matrix );
    QFont font( "Times", 18 );
    painter.setFont( font );
    QFontMetrics fm = painter.fontMetrics();
    y += fm.ascent();
    painter.drawText( 70, y, 
                      "Graphics rendered using QPainter methods" );
}

int main( int argc, char **argv )
{
    QApplication app( argc, argv );
    RenderGraphicsWidget drawdemo;
    drawdemo.setGeometry( 200, 200, 450, 400 );
    app.setMainWidget( &drawdemo );
    drawdemo.show();
    return app.exec();
}