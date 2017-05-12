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



//MultiCustomerAccount.cc

#include <qthread.h>
#include <cstdlib>
#include <iostream>
#include <ctime>
using namespace std;

void keepBusy( double howLongInMillisec );

QMutex mutex;
QWaitCondition cond;

class Account : public QThread {
public:
    int balance;

    Account() { balance = 0; }
    void deposit( int dep ) {
        mutex.lock();
        balance += dep;
        keepBusy( 1 );
        cond.wakeAll();
        mutex.unlock();
    }
    void withdraw( int draw ) {
        mutex.lock();
        while ( balance < draw ) {
            cond.wait( &mutex );
        }
        keepBusy( 1 );
        balance -= draw;
        mutex.unlock();
    }
    void run(){}
};

Account acct;

class Depositor : public QThread {
public:
    void run() {
        int i = 0;
        while ( true ) {
            int x = (int) ( rand() % 10 );
            acct.deposit( x );
            if ( i++ % 100 == 0 ) 
                cerr << "balance after deposits: " 
                     <<  acct.balance << endl;          
            keepBusy( 1 );
        }
    }
};

class Withdrawer : public QThread {
public:

    void run() {
        int i = 0;
        while ( true ) {
            int x = (int) ( rand() % 10 );
            acct.withdraw( x );
            if ( i++ % 100 == 0 ) 
                cerr << "balance after withdrawals:  " 
                     << acct.balance << endl;  
            keepBusy( 1 );
        }
    }
};

int main()
{
    Depositor* depositors[5];
    Withdrawer* withdrawers[5];    

    for ( int i=0; i < 5; i++ ) {
        depositors[ i ] = new Depositor();      
        withdrawers[ i ] = new Withdrawer();
        depositors[ i ]->start();
        withdrawers[ i ]->start();
    }
    for ( int i=0; i < 5; i++ ) {
        depositors[ i ]->wait();
        withdrawers[ i ]->wait();
    }
}

void keepBusy( double howLongInMillisec ) {
    int ticksPerSec = CLOCKS_PER_SEC;
    int ticksPerMillisec = ticksPerSec / 1000;
    clock_t ct = clock();
    while ( clock() < ct + howLongInMillisec * ticksPerMillisec )
        ;
}