// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 16  Multiple Inheritance In C++
//
// Section:     Section 16.5  Virtual Bases And Assignment Operators
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//VirtualBaseAssign.cc

#include <iostream>
using namespace std;

class X {
    int x;
public:
    X( int xx ) : x(xx) {}
    X( const X& other ) : x( other.x ) {}
    //assignment op:
    X& operator=( const X& other ) {  
        if ( this == &other ) return *this;
        x = other.x;
        return *this;
    }
    virtual void print() { 
        cout << "printing value of x of X subobject: " << x << endl;
    }
};

class Y : virtual public X {
    int y;
public:
    Y( int xx, int yy ) : X( xx ), y( yy ) {}
    Y( const Y& other ) : X( other ), y( other.y ) {}
    //assignment op:  
    Y& operator=( const Y& other ) {         
        if ( this == &other ) return *this;
        X::operator=( other );
        y = other.y;
        return *this;
    }
    void print() { 
        X::print();  
        cout << "printing value of y of Y subobject: " << y << endl; 
    }  
};

class T : virtual public X {
    int t;
public:
    T( int xx, int tt ) : X( xx ), t( tt ) {}
    T( const T& other ) : X( other ), t( other.t ) {}  
    // assignment op:
    T& operator=( const T& other ) {  
        if ( this == &other ) return *this;
        X::operator=( other );
        t = other.t;
        return *this;
    }
    void print() { 
        X::print();  
        cout << "printing value of t of T subobject: " << t << endl; 
    }  
};

class Z : public Y {
    int z;
public:
    Z( int xx, int yy, int zz ) : Y( xx, yy ), X(xx), z( zz ) {}
    Z( const Z& other ) : Y( other ), X( other ), z( other.z ) {}  
    // assignment op:
    Z& operator=( const Z& other ) {        
        if ( this == &other ) return *this;
        Y::operator=( other );
        z = other.z;
        return *this;
    }
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
    U( const U& other ) 
      : Z( other ), T( other ), X( other ), u( other.u ) {}
    // assignment op:
    U& operator=( const U& other ) {    
        if ( this == &other ) return *this;
        Z::operator=( other );                                    //(A)
        T::operator=( other );                                    //(B)
        u = other.u;
        return *this;
    }
    void print() { 
        Z::print(); 
        T::print(); 
        cout << "printing value of u of U subobject: " << u << endl; 
    }
};

int main()
{
    cout << "U object coming up: " << endl;
    U u_obj_1(9100, 9200, 9300, 9400, 9500 );
    u_obj_1.print();                                              //(C)
    cout << endl;

    U u_obj_2(7100, 7200, 7300, 7400, 7500 );

    u_obj_2 = u_obj_1;                                            //(D)

    cout << "U object after assignment: " << endl;
    u_obj_2.print();                                              //(E)
    return 0;
}