import unittest

import Cplx

class Test(unittest.TestCase):
	def setUp(self):
		self.c1 = Cplx.Complex(1.0, 3.0)
		self.c2 = Cplx.Complex(2.0, -1.0)
		self.calc = Cplx.CalcCplx()

	def tearDown(self):
		del self.c1
		del self.c2
		del self.calc

	def test0(self):
		self.assertEqual(self.c1.re, 1.0)
		self.assertEqual(self.c1.im, 3.0)
		self.assertNotEqual(self.c1, self.c2)

	def test1(self):
		result = self.calc.Add(self.c1, self.c2)
		self.assertEqual(result.re, 3.0)
		self.assertEqual(result.im, 2.0)

	def test2(self):
		result = self.calc.Sub(self.c1, self.c2)
		self.assertEqual(result.re, -1.0)
		self.assertEqual(result.im, 4.0)

if __name__ == '__main__' :
	unittest.main()
