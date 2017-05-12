// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 16  Multiple Inheritance In C++
//
// Section:     Section 16.4  Virtual Bases And Copy Constructors
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//VirtualBaseCopyConstruct.cc

#include <iostream>
using namespace std;

class X {
    int x;
public:
    X( int xx ) : x(xx) {}
    //copy constructor:
    X( const X& other ) : x( other.x ) {}                         //(A)
    virtual void print() { 
        cout << "printing value of x of X subobject: " << x << endl; 
    }
};

class Y : virtual public X {
    int y;
public:
    Y( int xx, int yy ) : X( xx ), y( yy ) {}    
    //copy constructor:
    Y( const Y& other ) : X( other ), y( other.y ) {}             //(B)
    void print() { 
        X::print();  
        cout << "printing value of y of Y subobject: " << y << endl; 
    }  
};

class T : virtual public X {
    int t;
public:
    T( int xx, int tt ) : X( xx ), t( tt ) {}
    //copy constructor:
    T( const T& other ) : X( other ), t( other.t ) {}             //(C)
    void print() { 
        X::print();  
        cout << "printing value of t of T subobject: " << t << endl; 
    }  
};

class Z : public Y {
    int z;
public:
    Z( int xx, int yy, int zz ) : Y( xx, yy ), X(xx), z( zz ) {}
    //copy constructor:
    Z( const Z& other ): Y( other ), X( other ), z( other.z ) {}  //(D)
    void print() { 
        Y::print(); 
        cout << "printing value of z of Z subobject: " << z << endl; 
    }
};

class U : public Z, public T {
    int u;
public:
    U ( int xx, int yy, int zz, int tt, int uu ) 
        : Z( xx, yy, zz ), T( xx, tt ), X( xx ), u( uu ) {}
    U( const U& other )        // copy constructor
      : Z( other ), T( other ), X( other ), u( other.u ) {}       //(E)
    void print() { 
        Z::print();  T::print(); 
        cout << "printing value of u of U subobject: " << u << endl; 
    }
};

int main()
{
    cout << "Z object coming up: " << endl;
    Z z_obj_1( 1110, 1120, 1130 );
    z_obj_1.print();                                              //(F)
    cout << endl;
 
    cout << "Z's duplicate object coming up: " << endl;
    Z z_obj_2 = z_obj_1;
    z_obj_2.print();                                              //(G)
    cout << endl;
 
    cout << "U object coming up: " << endl;
    U u_obj_1(9100, 9200, 9300, 9400, 9500 );
    u_obj_1.print();                                              //(H)
    cout << endl;
 
    //call U's copy constructor:
    cout << "U's duplicate object coming up: " << endl;
    U u_obj_2 = u_obj_1; 
    u_obj_2.print();                                              //(I)
    cout << endl;

    return 0;
}