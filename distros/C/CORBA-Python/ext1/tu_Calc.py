import unittest

from _Calc import *

class Test(unittest.TestCase):
	def setUp(self):
		self.c = Calc()

	def test1(self):
		ret = self.c.Add(5, 2)
		self.assertEqual(7, ret)

	def test2(self):
		ret = self.c.Mul(5, 2)
		self.assertEqual(10, ret)

	def test3(self):
		ret = self.c.Mul(5, 0)
		self.assertEqual(0, ret)

	def test4(self):
		ret = self.c.Sub(5, 2)
		self.assertEqual(3, ret)

	def test5(self):
		ret = self.c.Div(5, 2)
		self.assertEqual(2, ret)

	def test6(self):
		ret = self.c.Div(0, 2)
		self.assertEqual(0, ret)

	def test7(self):
		try:
			ret = self.c.Div(5, 0)
			self.fail()
		except Calc.DivisionByZero:
			self.failUnless(1)

if __name__ == '__main__' :
	unittest.main()
