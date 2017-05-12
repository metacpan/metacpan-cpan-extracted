#!/usr/bin/env python -w

from MyCalc import *
import PyIDL.rpc_giop as RPC_GIOP
import SocketServer

class Giopd(SocketServer.BaseRequestHandler):
	def handle(self):
		global servant
		while True :
			request = self.request.recv(1024)
			if len(request) != 0 :
				print "data (%d) received" % len(request)
				(reply, reminder) = servant.Servant(request)
				if reply != None :	# !oneway
					self.request.sendall(reply)
		self.request.close()


servant = RPC_GIOP.Servant()
myCalc = MyCalc()
servant.Register(myCalc.corba_id(), myCalc)

SocketServer.TCPServer.allow_reuse_address = True 
srv = SocketServer.TCPServer(('', 12345), Giopd)
print "Waiting ..."
srv.serve_forever()
