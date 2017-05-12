// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.18  Interfaces In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//MultiPolymorphism.java

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

class DrawableRectangle extends Rectangle implements Drawable {
    private Color c;
    private double x, y;
    public DrawableRectangle( double w, double h ) { super( w, h ); }
    // Implementations of the methods inherited from the interface:
    public void setColor( Color c ) { this.c = c; }
    public void setPosition( double x, double y ) { 
        this.x = x; this.y = y; 
    }
    public void draw( DrawWindow dw ) { dw.drawRect( x, y, w, h, c ); }
}

class DrawableCircle extends Circle implements Drawable {
    private Color c;
    private double x, y;
    public DrawableCircle( double rad ) { super( rad ); } 
    public void setColor( Color c ) { this.c = c; }
    public void setPosition( double x, double y ) { 
        this.x = x; this.y = y; 
    }
    public void draw( DrawWindow dw ) { dw.drawCircle( x, y, r, c ); }
}

class Color { int R, G, B; }

class DrawWindow {
    public DrawWindow() {};
    public void drawRect( double x, double y, 
               double width, double height, Color col ) {
        System.out.println( 
            "Code for drawing a rect needs to be invoked" );      //(A)
    }
    public void drawCircle( double x, double y, 
                               double radius, Color col ) {
        System.out.println( 
            "Code for drawing a circle needs to be invoked" );    //(B)
    }
}

class Test {
    public static void main( String[] args )
    {
        Shape[] shapes = new Shape[3];
        Drawable[] drawables = new Drawable[3];

        DrawableCircle dc = new DrawableCircle( 1.1 );
        DrawableRectangle dr1 = new DrawableRectangle( 2.5, 3.5 );
        DrawableRectangle dr2 = new DrawableRectangle( 2.3, 4.5 );

        shapes[0] = dc;
        shapes[1] = dr1;
        shapes[2] = dr2;

        drawables[0] = dc;
        drawables[1] = dr1;
        drawables[2] = dr2;

        int total_area = 0;
        DrawWindow dw = new DrawWindow();
        for (int i = 0; i < shapes.length; i++ ) {
            total_area += shapes[i].area();
            drawables[i].setPosition( i*10.0, i*10.0 );           //(C)
            drawables[i].draw( dw );                              //(D)
        }
        System.out.println("Total area = " + total_area);         //(E)
    }
}