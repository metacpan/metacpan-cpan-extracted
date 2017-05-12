// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 16  Multiple Inheritance In C++
//
// Section:     Section 16.3  Virtual Bases For Multiple Inheritance
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//VirtualBase.cc

#include <iostream>
using namespace std;

class X {
    int x;
public:
    X( int xx ) : x(xx) {}
    virtual void print() { 
        cout << "printing value of x of X subobject: " << x << endl; 
    }
};

class Y : virtual public X {                                      //(A)
    int y;
public:
    Y( int xx, int yy ) : X( xx ), y( yy ) {}
    void print() { 
        X::print();  
        cout << "printing value of y of Y subobject: " << y << endl; 
    }  
};

class T : virtual public X {                                      //(B)
    int t;
public:
    T( int xx, int tt ) : X( xx ), t( tt ) {}
    void print(){ 
        X::print();  
        cout << "printing value of t of T subobject: " << t << endl; 
    }  
};

class Z : public Y {
    int z;
public:
    Z( int xx, int yy, int zz ) : Y( xx, yy ), X(xx), z( zz ) {}  //(C)
    void print() { 
        Y::print(); 
        cout << "printing value of z of Z subobject: " << z << endl; 
    }
};

class U : public Z, public T {
    int u;
public:
    U( int xx, int yy, int zz, int tt, int uu )            
        : Z( xx, yy, zz ), T( xx, tt ), X( xx ), u( uu ) {}       //(D)
    void print() { 
        Z::print(); 
        T::print(); 
        cout << "printing value of u of U subobject: " << u << endl; 
    }
};

int main()
{
    cout << "X object coming up: " << endl;
    X xobj( 1 );
    xobj.print();                                                 //(E)
    cout << endl;

    cout << "Y object coming up: " << endl;
    Y yobj( 11, 12 );
    yobj.print();                                                 //(F)
    cout << endl;
  
    cout << "Z object coming up: " << endl;
    Z zobj( 110, 120, 130 );
    zobj.print();                                                 //(G)
    cout << endl;
  
    cout << "T object coming up: " << endl;
    T tobj( 21, 22 );
    tobj.print();                                                 //(H)
    cout << endl;

    cout << "U object coming up: " << endl;
    U uobj(9100, 9200, 9300, 9400, 9500 );                        //(I)
    uobj.print();
    cout << endl;

    return 0;
}