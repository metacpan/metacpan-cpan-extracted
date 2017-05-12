// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.12  Abstract Classes In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//AbstractShape.cc

#include <iostream>
using namespace std;

class Shape {
public:
    virtual double area() = 0;
    virtual double circumference() = 0;
};

class Circle : public Shape {
protected:
    double r;
    static double PI;
public:  
    Circle() { r = 1.0; }
    Circle( double r ) { this->r = r; }
    double area() { return PI*r*r; }
    double circumference() { return 2 * PI * r; }
    double getRadius() {return r;}
};

double Circle::PI = 3.14159265358979323846;

class Rectangle : public Shape {
    double w, h;
public:
    Rectangle() { w=0.0; h = 0.0; }
    Rectangle( double w, double h ) { this->w = w; this->h = h; }
    double area() { return w * h; }
    double circumference() { return 2 * (w + h); }
    double getWidth() { return w; }
    double getHeight() { return h; }
};

int main()
{
    Shape* shapes[ 3 ];
    shapes[0] = new Circle( 2.0 );
    shapes[1] = new Rectangle( 1.0, 3.0 );
    shapes[2] = new Rectangle( 4.0, 2.0 );
    double total_area = 0;
    for (int i=0; i < 3; i++ )
        total_area += shapes[i]->area();
    cout << "Total area = " << total_area << endl;
    return 0;
}