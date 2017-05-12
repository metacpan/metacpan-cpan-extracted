// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 18  Multithreaded Object-Oriented Programming
//
// Section:     Section 18.11  Object-Oriented Multithreading In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//SynchedSwaps.cc

#include <qthread.h>
#include <cstdlib>
#include <iostream>
#include <ctime>
using namespace std;

void keepBusy( double howLongInMillisec );

class DataObject : public QThread {
    QMutex mutex;
    int dataItem1;
    int dataItem2;
public:
    DataObject() {
        dataItem1 = 50;
        dataItem2 = 50;
    }
    void itemSwap() {
        mutex.lock();                                             //(A)
        int x = (int) ( -4.999999 + rand() % 10 );
        dataItem1 -= x;
        keepBusy( 1 );
        dataItem2 += x;
        mutex.unlock();                                           //(B)
    }
    void test() {
        mutex.lock();
        int sum = dataItem1 + dataItem2;
        cout << sum << endl;
        mutex.unlock();
    }
    void run() {}
};

DataObject dobj;

class RepeatedSwaps : public QThread  {
public:
    RepeatedSwaps() {
        start();
    }
    void run() {
        int i = 0;
        while ( i++ < 5000 ) {
            dobj.itemSwap();
            if ( i % 1000 == 0 ) dobj.test();
        }
    }
};

int main( )
{
    RepeatedSwaps t0;
    RepeatedSwaps t1;
    RepeatedSwaps t2;    
    RepeatedSwaps t3;        

    t0.wait();
    t1.wait();
    t2.wait();
    t3.wait();
}
    
void keepBusy( double howLongInMillisec ) {
    int ticksPerSec = CLOCKS_PER_SEC;
    int ticksPerMillisec = ticksPerSec / 1000;
    clock_t ct = clock();
    while ( clock() < ct + howLongInMillisec * ticksPerMillisec )
        ;
}