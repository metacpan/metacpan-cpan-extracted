#!/usr/bin/env python

from MyCalc import *
import PyIDL.rpc_giop as RPC_GIOP
import twisted.internet.protocol
import twisted.internet.reactor

class ProtocolRpcGiop(twisted.internet.protocol.Protocol):
    def connectionMade(self):
        self.peer = self.transport.getPeer()
        print "connexion of (%s:%s)" % (self.peer.host, self.peer.port)

    def dataReceived(self, request):
        global servant
        print "data (%d) received" % len(request)
        (reply, reminder) = servant.Servant(request)
        if reply != None :  # !oneway
            self.transport.write(reply)

    def connectionLost(self, reason):
        print "deconnexion of", self.peer, reason.value


servant = RPC_GIOP.Servant()
myCalc = MyCalc()
servant.Register(myCalc.corba_id(), myCalc)

factory = twisted.internet.protocol.Factory()
factory.protocol = ProtocolRpcGiop
twisted.internet.reactor.listenTCP(12345, factory)      
twisted.internet.reactor.run()

