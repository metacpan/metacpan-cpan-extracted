// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 17  OO For Graphical User Interfaces, A Tour Of Three Toolkits
//
// Section:     Section 17.20 Drawing Shapes,Text,and Images In Qt
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Sketch.cc

#include <qapplication.h>
#include <qpainter.h>
#include <qwidget.h>

const int MAXPOINTS = 200;

class SketchWidget : public QWidget {
public:
    SketchWidget( QWidget *parent=0, const char *name=0 );
   ~SketchWidget();
protected:
    void        paintEvent( QPaintEvent * );
    void        mousePressEvent( QMouseEvent *);
    void        mouseDoubleClickEvent( QMouseEvent* );
private:
    QPoint     *points;
    int         count; 
};

SketchWidget::SketchWidget( QWidget *parent, const char *name )
    : QWidget( parent, name ) {
    setBackgroundColor( white );     
    count = 0;
    points = new QPoint[MAXPOINTS];
}

SketchWidget::~SketchWidget() {
    delete[] points; 
}


void SketchWidget::paintEvent( QPaintEvent* ) {                   //(U)
    QPainter paint( this );
    for ( int i=0; i<count - 2; i++ ) {
        paint.drawLine( points[i], points[ i + 1 ] ); 
    }
}

void SketchWidget::mousePressEvent( QMouseEvent* mouse ) {        //(V)
    points[count++] = mouse->pos();
}

void SketchWidget::mouseDoubleClickEvent( QMouseEvent* mouse ) {
    points[count++] = mouse->pos();
    repaint();                                                    //(W)
}

int main( int argc, char* argv[] )
{
    QApplication app( argc, argv );

    SketchWidget* sketchWidget = new SketchWidget();
    sketchWidget->setGeometry( 200, 200, 200, 200 );
    sketchWidget->show();
    app.setMainWidget( sketchWidget );
    return app.exec();
}