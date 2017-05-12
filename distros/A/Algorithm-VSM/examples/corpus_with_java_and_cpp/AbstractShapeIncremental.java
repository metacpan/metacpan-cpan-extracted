// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.17  Abstract Classes In Java
//



//AbstractShapeIncremental.java

abstract class Shape {
    abstract protected double area();
    abstract protected double circumference();
}

abstract class Polygon extends Shape {
    protected int numVertices;
    protected boolean starShaped;
}

abstract class curvedShape extends Shape {
    abstract public void polygonalApprox();
}

class Circle extends curvedShape {
    protected double r;
    protected static double PI = 3.14159;

    public Circle() { r = 1.0; }
    public Circle( double r ) { this.r = r; }
    public double area() { return PI*r*r; }
    public double circumference() { return 2 * PI * r; }
    public double getRadius() {return r;}
    public void polygonalApprox() {
        System.out.println(
             "polygonal approximation code goes here");
    }
}

class Rectangle extends Polygon {
    double w, h;
    public Rectangle() { 
        w=0.0; h = 0.0; numVertices = 0; starShaped = true; 
    }
    public Rectangle( double w, double h ) { 
        this.w = w; 
        this.h = h; 
        numVertices = 4;
        starShaped = true;
    }
    public double area() { return w * h; }
    public double circumference() { return 2 * (w + h); }
    public double getWidth() { return w; }
    public double getHeight() { return h; }
}

class Test {
    public static void main( String[] args )
    {
        Shape[] shapes = new Shape[ 3 ];
        shapes[0] = new Circle( 2.0 );
        shapes[1] = new Rectangle( 1.0, 3.0 );
        shapes[2] = new Rectangle( 4.0, 2.0 );

        double total_area = 0;
        for (int i=0; i < shapes.length; i++ )
          total_area += shapes[i].area();
        System.out.println("Total area = " + total_area);
    }
}
