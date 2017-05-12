
#include "Python.h"
#include "CalcCplx3.h"

static void tst_add(void)
{
	Cplx_Complex a = { 1.0, 3.0 };
	Cplx_Complex b = { 2.0, -1.0 };
	Cplx_Complex r;
	CORBA_Environment ev = { CORBA_NO_EXCEPTION, NULL, NULL, NULL };

	r = Cplx_CalcCplx_Add(NULL, &a, &b, &ev);
	if (CORBA_NO_EXCEPTION == ev._major) {
		if ((a.re + b.re == r.re)
		 && (a.im + b.im == r.im) ){
			printf(".");
		} else {
			printf("F");
		}
	} else {
		printf("%s\n", ev._repo_id);
		printf("E");
	}
}

int main(void)
{
	Py_Initialize();
	PyRun_SimpleString(
		"import PyIDL\n"
		"import MyCalcCplx\n"
		"PyIDL.Register('IDL:Cplx/CalcCplx:1.0', MyCalcCplx.MyCalcCplx)\n"
	);

	tst_add();

	Py_Finalize();
	return 0;
}
