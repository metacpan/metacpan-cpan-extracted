// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 19  Network Programming
//
// Section:     Section 19.4  Server Sockets In C++ (Qt) 
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ChatServer.cc

#include "ChatServer.h"

#include <qapplication.h>
#include <iostream>
using namespace std;

ChatServer::ChatServer( int port ) : QServerSocket( port )
{
    cout << "Server monitoring port " << port << endl;
    if ( !ok() ) {
        qWarning( "Failed to register the server port" );
        exit( 1 );
    }
}

// You must provide an override implementation for
// this method.  When a client requests a connection,
// this method will be called automatically with the
// socket argument set to the filedescriptor associated
// with the socket.
void ChatServer::newConnection( int socketFD ) {
    QSocket* socket = new QSocket();
    socket->setSocket( socketFD );
    ClientHandler* clh = new ClientHandler( socket, this );
    cout << "A new client checked in on socket FD " 
         << socketFD << endl;
}

ChatServer::~ChatServer(){}

ClientHandler::ClientHandler() {}

// Copy constructor is needed since it is the copies of
// the ClientHandler objects that will be stored in the
// vector clientVector
ClientHandler::ClientHandler( const ClientHandler& other )
    : handlerSocket( other.handlerSocket ),
      chatName( other.chatName ),
      chatServer( other.chatServer ),
      os( other.os )
{}

ClientHandler& ClientHandler::operator=( const ClientHandler& other ) {
    if ( this == &other ) return *this;

    cout << "ClientHandler assignment op invoked" << endl;

    if ( handlerSocket != 0 ) delete handlerSocket;
    handlerSocket = other.handlerSocket;
    if ( chatName != 0 ) delete chatName;
    chatName = other.chatName;
    if ( os != 0 ) delete os;
    os = other.os;
    chatServer = other.chatServer;
}

ClientHandler::ClientHandler( QSocket* socket, ChatServer* chatserver )
    : chatName(0), 
      chatServer( chatserver ),
      handlerSocket( socket )
{
    os = new QTextStream( handlerSocket );

    (*os) << "Welcome to a chat room powered by C++\n";      
    (*os) << ">>>>    Enter 'bye' to exit   <<<\n";      
    (*os) << "Enter chat name: ";      

    connect( handlerSocket, SIGNAL( readyRead() ),
             this, SLOT( readFromClient() ) );
    connect( handlerSocket, SIGNAL( error( int ) ),
             this,   SLOT( reportError( int ) ) );
}

// The destructor definition intentionally does not invoke 
// the delete operator on any of the objects pointed to 
// by the data members of a ClientHandler.  In this program, 
// the most frequent invocation of the destructor is caused 
// by the push_back statement in the readFromClient() 
// function.  The push_back invocation causes the vector 
// to be moved to a different location in the memory.  The 
// memory occupied by the ClientHandler objects in the 
// vector is freed by invoking the destructor.  Deleting 
// the memory occupied by the socket and other objects 
// pointed to by the data members of the ClientHandler 
// objects would lead to disastrous results.
ClientHandler::~ClientHandler(){}

void ClientHandler::reportError( int e ) {
    cout << "error report from connectToHost" << endl; 
    cout << "error id: " << e << endl;
}

void ClientHandler::readFromClient() {
    QSocket* sock = (QSocket*) sender();
    while ( sock->canReadLine() ) {
        QString qstr = sock->readLine();

        // This block is for the case when a new chatter 
        // has just signed in and supplied his/her chat name. 
        // The block sets the chatname of the ClientHandler 
        // object assigned to this new user.  Next it pushes 
        // the ClientHandler object for this new user in the 
        // vector clientVector.  Subsequently, The block informs 
        // all other current chatters that this new user has
        // signed in.
        if ( chatName == 0 ) {
            chatName = new QString( qstr.stripWhiteSpace() );
            chatServer->clientVector.push_back( *this );
            for ( int i=0; i<chatServer->clientVector.size(); i++ ) {
                if ( *chatServer->clientVector[i].chatName 
                                          != *chatName &&
                     chatServer->clientVector[i].handlerSocket != 0 ) {
                    QString outgoing = "\nMessage from chat server: " 
                                    + *chatName + " signed in ";
                    *chatServer->clientVector[i].os << outgoing;
                }
            }
        }

        // This block treats the case when a chatter wants 
        // to sign out by typing "bye".  It broadcasts a message 
        // to all the other chatters that this chatter is signing 
        // off.  This block than closes the socket.  Note that 
        // socket pointer is set to null in both the ClientHandler 
        // object assigned to the exiting chatter and its copy the 
        // vector clientVector.
        else if ( qstr.stripWhiteSpace() == "bye" ) {
            for ( int i=0; i<chatServer->clientVector.size(); i++ ) {
                QString outgoing( "\nMessage from the chat server: " +
                          *chatName + " signed off" );
                if ( *chatServer->clientVector[i].chatName 
                                                 != *chatName  &&
                     chatServer->clientVector[i].handlerSocket != 0 ) {
                    *chatServer->clientVector[i].os << outgoing;
                }
            }
            handlerSocket->close();
            handlerSocket = 0;
            for ( int i=0; i<chatServer->clientVector.size(); i++ ) {
                if (*chatServer->clientVector[i].chatName == *chatName)
                    chatServer->clientVector[i].handlerSocket = 0;
            }
        }

        // This is the normal case encountered during the 
        // course of a chat.  The string typed in by a 
        // chatter is broadcast to all the other chatters.  
        // The string is pre-pended by the name of the 
        // chatter who typed in the string.
        else {
            cout << *chatName << ": " << qstr << endl;
            qstr.truncate( qstr.length() - 2 );
            for ( int i=0; i<chatServer->clientVector.size(); i++ ) {
                if ( *chatServer->clientVector[i].chatName 
                                                 != *chatName &&
                     chatServer->clientVector[i].handlerSocket != 0 ) {
                    QString outgoing = "\n" + *chatName + ": " + qstr;
                    *chatServer->clientVector[i].os << outgoing;
                }
            }
        }

        // A chatter's terminal always shows his/her own 
        // name at beginning of a new line.  This way, 
        // when a chatter types in his/her own message, it 
        // is always on a line that starts with his/her 
        //own name.
        for ( int i=0; i<chatServer->clientVector.size(); i++ ) {
            if ( chatServer->clientVector[i].handlerSocket != 0 ) {
                QString outgoing = "\n" + 
                   *chatServer->clientVector[i].chatName + ": ";
                *chatServer->clientVector[i].os << outgoing;
            }
        }
    }
}

int main( int argc, char* argv[] )
{
    QApplication app( argc, argv );
    ChatServer* server = new ChatServer( 5000 );
    return app.exec();
}