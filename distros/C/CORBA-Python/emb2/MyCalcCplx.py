
import Cplx

class MyCalcCplx(Cplx.CalcCplx):

    def Add(self, val1, val2):
        return Cplx.Complex(val1.re + val2.re, val1.im + val2.im)

    def Sub(self, val1, val2):
        return Cplx.Complex(val1.re - val2.re, val1.im - val2.im)

