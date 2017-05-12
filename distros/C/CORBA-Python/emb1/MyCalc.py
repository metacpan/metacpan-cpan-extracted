
from _Calc import *

class MyCalc(Calc):

    def Add(self, val1, val2):
        res = val1 + val2
        print "Add %d + %d => %d" % (val1, val2, res)
        return res
    
    def Div(self, val1, val2):
        if val2 == 0 :
            print "Div %d / %d => DivisionByZero" % (val1, val2)
            raise Calc.DivisionByZero()
        else:
            res = val1 / val2
            print "Div %d / %d => %d" % (val1, val2, res)
            return res

    def Mul(self, val1, val2):
        res = val1 * val2
        print "Mul %d * %d => %d" % (val1, val2, res)
        return res

    def Sub(self, val1, val2):
        res = val1 - val2
        print "Sub %d - %d => %d" % (val1, val2, res)
        return res
