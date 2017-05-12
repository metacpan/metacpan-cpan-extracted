#!/usr/bin/env python -w

from Tkinter import *
from ScrolledText import *
import socket

from _Calc import *

class Top:

	def __init__(self, root, calc):
		self._root = root
		self._calc = calc
		# Default settings.
		self._var1_add = IntVar(0)
		self._var2_add = IntVar(0)
		self._var1_sub = IntVar(0)
		self._var2_sub = IntVar(0)
		self._var1_mul = IntVar(0)
		self._var2_mul = IntVar(0)
		self._var1_div = IntVar(0)
		self._var2_div = IntVar(0)

		root.title("GIOP - Tk/Client")

		fr_res = Frame(root,
		)
		fr_res.pack(
		)
		#~ self._text = Scrolled(fr_res,
			#~ "ROText",
			#~ scrollbars='osoe',
		self._text = ScrolledText(fr_res,
			height=12,
			width=32,
		)
		self._text.pack(
		)

		fr_add = Frame(root,
		)
		fr_add.pack(
		)
		b_add = Button(fr_add,
				text="Add",
				padx=10,
				command=self.OnAdd,
		)
		b_add.pack(
				side=LEFT,
		)
		e1_add = Entry(fr_add,
				width=10,
				textvariable=self._var1_add,
		)
		e1_add.pack(
				side=LEFT,
		)
		e2_add = Entry(fr_add,
				width=10,
				textvariable=self._var2_add,
		)
		e2_add.pack(
				side=LEFT,
		)
		
		fr_sub = Frame(root,
		)
		fr_sub.pack(
		)
		b_sub = Button(fr_sub,
				text="Sub",
				padx=10,
				command=self.OnSub,
		)
		b_sub.pack(
				side=LEFT,
		)
		e1_sub = Entry(fr_sub,
				width=10,
				textvariable=self._var1_sub,
		)
		e1_sub.pack(
				side=LEFT,
		)
		e2_sub = Entry(fr_sub,
				width=10,
				textvariable=self._var2_sub,
		)
		e2_sub.pack(
				side=LEFT,
		)
		
		fr_mul = Frame(root,
		)
		fr_mul.pack(
		)
		b_mul = Button(fr_mul,
				text="Mul",
				padx=10,
				command=self.OnMul,
		)
		b_mul.pack(
				side=LEFT,
		)
		e1_mul = Entry(fr_mul,
				width=10,
				textvariable=self._var1_mul,
		)
		e1_mul.pack(
				side=LEFT,
		)
		e2_mul = Entry(fr_mul,
				width=10,
				textvariable=self._var2_mul,
		)
		e2_mul.pack(
				side=LEFT,
		)
		
		fr_div = Frame(root,
		)
		fr_div.pack(
		)
		b_div = Button(fr_div,
				text="Div",
				padx=10,
				command=self.OnDiv,
		)
		b_div.pack(
				side=LEFT,
		)
		e1_div = Entry(fr_div,
				width=10,
				textvariable=self._var1_div,
		)
		e1_div.pack(
				side=LEFT,
		)
		e2_div = Entry(fr_div,
				width=10,
				textvariable=self._var2_div,
		)
		e2_div.pack(
				side=LEFT,
		)		

		# Cntl-C stops the demo.
		root.bind('<Control-c>', lambda x: sys.exit(0))

	def OnAdd(self):
		try:
			ret = self._calc.Add(self._var1_add.get(), self._var2_add.get())
			msg = "%d\n" % ret
			self._text.insert('end', msg)
		except Exception, e:
			self._text.insert('end', e.__str__())

	def OnSub(self):
		try:
			ret = self._calc.Sub(self._var1_sub.get(), self._var2_sub.get())
			msg = "%d\n" % ret
			self._text.insert('end', msg)
		except Exception, e:
			self._text.insert('end', e.__str__())

	def OnMul(self):
		try:
			ret = self._calc.Mul(self._var1_mul.get(), self._var2_mul.get())
			msg = "%d\n" % ret
			self._text.insert('end', msg)
		except Exception, e:
			self._text.insert('end', e.__str__())

	def OnDiv(self):
		try:
			ret = self._calc.Div(self._var1_div.get(), self._var2_div.get())
			msg = "%d\n" % ret
			self._text.insert('end', msg)
		except Calc.DivisionByZero, e:
			msg = "%s\n" % e.__str__()
			self._text.insert('end', msg)
#		except Exception, e:
#			self._text.insert('end', e.__str__())


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(('localhost', 12345))
calc = Calc(sock)
root = Tk()
top = Top(root, calc)
root.mainloop()
