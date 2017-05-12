// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 19  Network Programming
//
// Section:     Section 19.3  Establishing Socket Connections With Existing Servers In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ClientSocket.cc

#include "ClientSocket.h"

#include <qapplication.h>
#include <qsocket.h>
#include <string>
#include <iostream>
using namespace std;


ClientSocket::ClientSocket( string siteName ) : QSocket( 0 , 0 )
{
    wwwName = siteName;

    socket = new QSocket( );

    connect( socket, SIGNAL( connected() ),
             this,   SLOT( reportConnected() ) );

    connect( socket, SIGNAL( hostFound() ),
             this,   SLOT( reportHostFound() ) );

    connect( socket, SIGNAL( readyRead() ),
             this,   SLOT( getWebPage() ) );

    connect( socket, SIGNAL( connectionClosed() ),
             this,   SLOT( socketConnectionClosed() ) );

    connect( socket, SIGNAL( error( int ) ),
             this,   SLOT( reportError( int ) ) );

    QString qstr( wwwName.c_str() );

    socket->connectToHost( qstr, 80 );   // asynchronous call
}

ClientSocket::~ClientSocket() {}

string ClientSocket::constructHttpRequest( ) {
    string hostHeader = "Host: " + wwwName;
    string urlString( hostHeader );
    string httpRequestString = "GET / HTTP/1.0\r\n" + 
                               urlString + "\r\n" + "\r\n";
    return httpRequestString;
}

void ClientSocket::reportHostFound() {
    cout << "host found" << endl; 
}

void ClientSocket::reportConnected() {
    cout << "connection established" << endl; 
    string httpRequest = constructHttpRequest();
    int len = httpRequest.size();
    socket->writeBlock( httpRequest.c_str(), len );
}

void ClientSocket::getWebPage() {
    // cout << "socket ready to read" << endl; 
    int howManyBytes = socket->bytesAvailable();
    // cout << "bytes available: " << howManyBytes << endl;
    char data[howManyBytes];
    socket->readBlock( data, howManyBytes );
    cout << data;
    cout.flush();
}

void ClientSocket::socketConnectionClosed() {
    socket->close();
    if ( socket->state() == QSocket::Closing ) {   // delayed close
        connect( socket, SIGNAL( delayedCloseFinished() ),
                 this,   SLOT( socketClosed() ) );
    } else {
        // The socket is really closed
        socketClosed();
    }
}

void ClientSocket::reportError( int e ) {
    cout << "error report from connectToHost" << endl; 
    cout << "error id: " << e << endl;
}

void ClientSocket::socketClosed() {
    cout << "Connection closed" << endl;
    exit( 0 );
}

int main( int argc, char* argv[] )
{
    QApplication app( argc, argv );
    ClientSocket* sock = new ClientSocket( argv[1] );
    return app.exec();
}
