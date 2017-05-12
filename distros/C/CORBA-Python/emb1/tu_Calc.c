
#include "Python.h"
#include "Calc.h"

static void tst_add(void)
{
	CORBA_long a, b, r;
	CORBA_Environment ev = { CORBA_NO_EXCEPTION, NULL, NULL, NULL };

	a = 5;
	b = 2;                                                       
	r = Calc_Add(NULL, a, b, &ev);
	if (CORBA_NO_EXCEPTION == ev._major) {
		if (a + b == r) {
			printf(".");
		} else {
			printf("F");
		}
	} else {
		printf("%s\n", ev._repo_id);
		printf("E");
	}
}

static void tst_div(void)
{
	CORBA_long a, b, r;
	CORBA_Environment ev = { CORBA_NO_EXCEPTION, NULL, NULL, NULL };

	a = 5;
	b = 0;                                                       
	r = Calc_Div(NULL, a, b, &ev);
	if (CORBA_NO_EXCEPTION == ev._major) {
		printf("F");
	} else if (CORBA_USER_EXCEPTION == ev._major) {
		printf(".");
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
		"import MyCalc\n"
		"PyIDL.Register('IDL:Calc:1.0', MyCalc.MyCalc)\n"
	); 

	tst_div();
	tst_add();

	Py_Finalize();
	return 0;
}
