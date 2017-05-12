
from _Calc_skel import *

class MyCalc(Calc_skel):
	""" Implementation of Interface: IDL:Calc:1.0 """

	def Add(self, a, b):
		res = a + b
		print "Add %d + %d => %d" % (a, b, res)
		return res

	def Sub(self, a, b):
		res = a - b
		print "Sub %d - %d => %d" % (a, b, res)
		return res

	def Mul(self, a, b):
		res = a * b
		print "Mul %d x %d => %d" % (a, b, res)
		return res

	def Div(self, a, b):
		if b == 0 :
			print "Div %d / %d => DivisionByZero" % (a, b)
			raise Calc_skel.DivisionByZero()
		else :
			res = a / b
			print "Div %d / %d => %d" % (a, b, res)
			return res
