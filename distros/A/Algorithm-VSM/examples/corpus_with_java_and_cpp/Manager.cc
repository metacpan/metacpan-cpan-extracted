// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.19  A C++ Study Of A Small Class Hierarchy With Moderately 
//                               Complex Behavior
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Manager.cc

#include "Employee.h"
using namespace std;

//////////////////////////// class Poodle  ////////////////////////////
class Poodle : public Dog {
     Employee owner;
     double weight;                                               //(K)
     double height;
public:
    Poodle() : owner( Employee() ), weight( 0.0 ), height( 0.0 ) {}; 
    Poodle( Employee owner, string name, 
               int age, double weight, double height ) 
        : Dog( name, age )  {
       this->owner = owner;
       this->weight = weight;
       this->height = height;
    }
    friend ostream& operator<<( ostream& os, const Poodle& poodle ) {
        cout << (Dog) poodle;
        cout << "\nPedigree: Poodle" 
             << "  Weight: " << poodle.weight 
             << "  Height: " << poodle.height << endl;
        return os;
    }
    void print() { cout << *this; }
    double getDogCompareParameter() { return weight; }            //(L)
};

//////////////////////////  class Chihuahua  //////////////////////////
class Chihuahua : public Dog {
     Employee owner;
     double weight;                                               //(M)
     double height;
public:
    Chihuahua() : owner( Employee() ), weight( 0.0 ), height( 0.0 ) {};
    Chihuahua( Employee owner, string name, 
                     int age, double weight, double height ) 
        : Dog( name, age )  {
       this->owner = owner;
       this->weight = weight;
       this->height = height;
    }
    friend ostream& operator<<(ostream& os, const Chihuahua& huahua) {      
        cout << (Dog) huahua;
        cout << "\nPedigree: Chihuahua" 
             << "  Weight: " << huahua.weight 
             << "  Height: " << huahua.height << endl;
        return os;
    }
    void print() { cout << *this; }
    double getDogCompareParameter() { return weight; }            //(N)       
};

///////////////////////////  class Manager  ///////////////////////////
class Manager : public Employee {
     Employee* workersSupervised;       
     int numWorkersSupervised;
public:
    Manager() : workersSupervised(0), numWorkersSupervised( 0 ) {}   
    Manager( Employee e, vector<Dog*> dogs ) : Employee( e ) {    //(O)
        vector<Dog*>::iterator iter = dogs.begin();
        while ( iter < dogs.end() ) {
            Poodle* p = dynamic_cast<Poodle*>( *iter );
            if ( p != 0 ) 
                addDogToDogs( new Poodle( *p ) );
            Chihuahua* c = dynamic_cast<Chihuahua*>( *iter );
            if ( c != 0 ) 
                addDogToDogs( new Chihuahua( *c ) );
            iter++;
        }
    }
    friend ostream& operator<<( ostream& os, const Manager& m );    
};

ostream& operator<<( ostream& os, const Manager& m ) {
    os << (Employee) m;
    return os;
}

///////////////////////////////  main  ////////////////////////////////
int main() 
{
    Employee e1( "Zoe", "Zaphod" );

//                name         age
    Dog dog1(    "fido",        3 );
    Dog dog2(    "spot",        4 );
    Dog dog3(    "bruno",       2 );
    Dog dog4(    "darth",       1 );

//                 Employee     name      age    weight     height 
    Poodle dog5(     e1,      "pooch",    4,    15.8,       2.1 );
    Poodle dog6(     e1,      "doggy",    3,    12.9,       3.4 );
    Poodle dog7(     e1,      "lola",     3,    12.9,       3.4 );
    Chihuahua dog8(  e1,      "bitsy",    5,    3.2,        0.3 );
    Chihuahua dog9(  e1,      "bookam",   5,    7.2,        0.9 );
    Chihuahua dog10( e1,      "pie",      5,    4.8,        0.7 );

    vector<Dog*> dawgs;
    dawgs.push_back( &dog1 );
    dawgs.push_back( &dog2 );
    dawgs.push_back( &dog5 );
    dawgs.push_back( &dog6 );
    dawgs.push_back( &dog3 );
    dawgs.push_back( &dog4 );
    dawgs.push_back( &dog10 );
    dawgs.push_back( &dog7 );
    dawgs.push_back( &dog8 );
    dawgs.push_back( &dog9 );

    Manager m1( e1, dawgs );
    cout << m1;          
    return 0;
}
