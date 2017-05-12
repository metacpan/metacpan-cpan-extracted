// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 18  Multithreaded Object-Oriented Programming
//
// Section:     Section 18.6  Java's wait-notify Mechanism For Dealing With Deadlock
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//MultiCustomerAccount.java

///////////////////////////  class Account  ///////////////////////////
class Account {                                                   //(A)
    int balance;                                                  //(B)

    Account() { balance = 0; }                                    //(C)

    synchronized void deposit( int dep ){                         //(D)
        balance += dep;                                           //(E)
        notifyAll();                                              //(F)
    }
    synchronized void withdraw( int draw ) {                      //(G)
        while ( balance < draw ) {                                //(H)
            try { 
                wait();                                           //(I)
            } catch( InterruptedException e ) {}
        }
        balance -= draw;                                          //(J)
    }
}

//////////////////////////  class Depositor  //////////////////////////
class Depositor extends Thread {                                  //(K)
    private Account acct;                                         //(L)

    Depositor( Account act ){ acct = act; }                       //(M)

    public void run() {                                           //(N)
        int i = 0;
        while ( true ) {                                          //(O)
            int x = (int) ( 10 * Math.random() );                 //(P)
            acct.deposit( x );                                    //(Q)
            if ( i++ % 1000 == 0 )                                //(R)
                System.out.println( 
                    "balance after deposits:  " 
                    + acct.balance );                             //(S)
            try { sleep( 5 ); } catch( InterruptedException e ) {}
        }
    }
}

//////////////////////////  class Withdrawer  /////////////////////////
class Withdrawer extends Thread {                                 //(T)
    private Account acct;

    Withdrawer( Account act ) { acct = act; }

    public void run() {
        int i = 0;
        while ( true ) {
            int x = (int) ( 10 * Math.random() );
            acct.withdraw( x );
            if ( i++ % 1000 == 0 ) 
                System.out.println( "balance after withdrawals:  " 
                                 + acct.balance );       
            try { sleep( 5 ); } catch( InterruptedException e ) {}      
        }
    }
}

////////////////////  class MultiCustomerAccount  /////////////////////
class MultiCustomerAccount {                                      //(U)
    public static void main( String[] args ) {
        Account account = new Account();
        Depositor[] depositors = new Depositor[ 5 ];
        Withdrawer[] withdrawers = new Withdrawer[ 5 ];    
        for ( int i=0; i < 5; i++ ) {
            depositors[ i ] = new Depositor( account );      
            withdrawers[ i ] = new Withdrawer( account );
            depositors[ i ].start();
            withdrawers[ i ].start();
        }
    }
}