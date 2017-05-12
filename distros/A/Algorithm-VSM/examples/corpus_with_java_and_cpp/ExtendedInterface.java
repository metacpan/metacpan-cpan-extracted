// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.18.1  Implementing Multiple Interfaces in Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ExtendedInterface.java

abstract class Shape {
    abstract protected double area();
    abstract protected double circumference();
}

class Circle extends Shape {
    protected double r;
    protected static double PI = 3.14159;
    public Circle( double r ) { this.r = r; }
    public double area() { return PI*r*r; }
    public double circumference() { return 2 * PI * r; }
}

class Rectangle extends Shape {
    double w, h;
    public Rectangle( double w, double h ) { 
        this.w = w; 
        this.h = h; 
    }
    public double area() { return w * h; }
    public double circumference() { return 2 * (w + h); }
}

interface Drawable {
    public void setColor( Color c );
    public void setPosition( double x, double y );
    public void draw( DrawWindow dw );
}

interface DrawScalable extends Drawable {
    public void drawScaledShape( int scaleFactor, DrawWindow dw );
}

class DrawScalableRectangle extends Rectangle implements DrawScalable {
    private Color c;
    private double x, y;
    public DrawScalableRectangle(double w, double h) { super( w, h ); }
    //Implementations of the methods inherited from the interface:
    public void setColor( Color c ) { this.c = c; }
    public void setPosition( double x, double y ) { 
        this.x = x; this.y = y; 
    }
    public void draw( DrawWindow dw ) { 
        dw.drawRect( x, y, w, h, c ); 
    }
    public void drawScaledShape( int scaleFactor, 
                        DrawWindow dw ) {
        dw.drawScaledRect( x, y, w, h, c, scaleFactor );
    }
}

class DrawScalableCircle extends Circle implements DrawScalable {
    private Color c;
    private double x, y;
    public DrawScalableCircle( double rad ) { super( rad ); } 
    public void setColor( Color c ) { this.c = c; }
    public void setPosition( double x, double y ) { 
        this.x = x; this.y = y; 
    }
    public void draw( DrawWindow dw ) { dw.drawCircle( x, y, r, c ); }
    public void drawScaledShape( int scaleFactor, 
            DrawWindow dw ) {
        dw.drawScaledCircle( x, y, r, c, scaleFactor );
    }
}

class Color { int R, G, B; }

class DrawWindow {
    public DrawWindow() {};
    public void drawRect( double x, double y, 
                double width, double height, Color col ) {
        System.out.println(                                       //(A)
         "Code for drawing a rect needs to be invoked" );
    }
    public void drawScaledRect( double x, double y, double width, 
              double height, Color col, int scale ){            
        System.out.println(                                       //(B)
         "Code for drawing a scaled rect needs to be invoked" );
    }
    public void drawCircle( double x, double y, 
                                 double radius, Color col ) {
        System.out.println(                                       //(C)
         "Code for drawing a circle needs to be invoked" );
    }
    public void drawScaledCircle( double x, double y, double radius, 
                              Color col, int scale ){
        System.out.println(                                       //(D)
         "Code for drawing a scaled circle needs to be invoked" );
    }
}



class Test {
    public static void main( String[] args )
    {
        Shape[] shapes = new Shape[3];
        DrawScalable[] drawScalables = new DrawScalable[3];

        DrawScalableCircle dc = new DrawScalableCircle( 1.1 );
        DrawScalableRectangle dr1 = 
                new DrawScalableRectangle( 2.5, 3.5 );
        DrawScalableRectangle dr2 = 
                new DrawScalableRectangle( 2.3, 4.5 );

        shapes[0] = dc;
        shapes[1] = dr1;
        shapes[2] = dr2;

        drawScalables[0] = dc;
        drawScalables[1] = dr1;
        drawScalables[2] = dr2;

        int total_area = 0;
        DrawWindow dw = new DrawWindow();
        for (int i = 0; i < shapes.length; i++ ) {
            total_area += shapes[i].area();
            drawScalables[i].setPosition( i*10.0, i*10.0 );  
            drawScalables[i].drawScaledShape( 2, dw );       
        }
        System.out.println("Total area = " + total_area);         //(E)
    }
}