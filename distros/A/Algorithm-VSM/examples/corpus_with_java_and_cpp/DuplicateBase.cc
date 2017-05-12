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



//DuplicateBase.cc

#include <iostream>
using namespace std;

class X {
    int x;
public:
    X( int xx ) : x(xx) {}
    X( const X& other ) : x( other.x ) {}
    X& operator=( const X& other ) {
        if ( this == &other ) return *this;
        x = other.x;
        return *this;
    }
    virtual void print() { 
        cout << "printing value of x of X subobject: " << x << endl; 
    }
};

//class Y : virtual public X {
class Y : public X {                // base is now nonvirtual     //(F)  
    int y;
public:
    Y( int xx, int yy ) : X( xx ), y( yy ) {}
    Y( const Y& other ) : X( other ), y( other.y ) {}
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

//class T : virtual public X {
class T : public X {               // base is now nonvirtual      //(G)
    int t;
public:
    T( int xx, int tt ) : X( xx ), t( tt ) {}
    T( const T& other ) : X( other ), t( other.t ) {}  
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
    // Z( int xx, int yy, int zz ) : Y(xx, yy), X(xx), z(zz) {}
    Z( int xx, int yy, int zz ) : Y( xx, yy ), z( zz ) {}         //(H)   
    //  Z( const Z& other ) : Y(other), X(other), z( other.z ) {}  
    Z( const Z& other ) : Y( other ), z( other.z ) {}             //(I)
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
      //      : Z( xx, yy, zz ), T( xx, tt ), X(xx), u(uu) {}
              : Z( xx, yy, zz ), T( xx, tt ), u( uu ) {}          //(J)
    U( const U& other ) 
      //      : Z( other ), T( other ), X( other ), u(other.u) {}
              : Z( other ), T( other ), u( other.u ) {}           //(K)
    U& operator=( const U& other ) {
        if ( this == &other ) return *this;
        Z::operator=( other );                                    //(L)
        T::operator=( other );                                    //(M)
        u = other.u;
        return *this;
    }
    void print() { 
        Z::print();  T::print(); 
        cout << "printing value of u of U subobject: " << u << endl; 
    }
};

int main()
{
    cout << "U object coming up: " << endl;
    U u_obj_1(9100, 9200, 9300, 9400, 9500 );
    u_obj_1.print();                                              //(N)
    cout << endl;

    U u_obj_2(7100, 7200, 7300, 7400, 7500 );

    u_obj_2 = u_obj_1;

    cout << "The U object after assignment from another U object: " 
         << endl;
    u_obj_2.print();                                              //(O)
    cout << endl;
    return 0; 
}
