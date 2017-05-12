#include "Python.h"

PyObject *
find_class(PyObject *module, const char *classname)
{
	PyObject * mod;
	PyObject * obj;
	char * start;
	char * name;
	char * ap;

	if (NULL == module) {
		(void)PyErr_Format(PyExc_RuntimeError, "null module for finding '%s'", classname);
		return NULL;
	}
#if 0
	start = strdup(classname);
	if (NULL == start) {
		PyErr_SetString(PyExc_MemoryError, "(in find_class)");
		return NULL;
	}
#else
	start = malloc(1 + strlen(classname));
	if (NULL == start) {
		PyErr_SetString(PyExc_MemoryError, "(in find_class)");
		return NULL;
	}
	strcpy(start, classname);
#endif
	mod = module;
	Py_INCREF(mod);
	name = start;
	while ((ap = strchr(name, '.')) != NULL) {
		*ap = '\0';
		obj = PyObject_GetAttrString(mod, name); // New reference
		Py_DECREF(mod);
		mod = obj;
		if (NULL == obj) {
			(void)PyErr_Format(PyExc_RuntimeError, "no attr '%s' for finding '%s'", name, classname);
			goto err;
		}
		name = ++ap;
	}
	obj = PyObject_GetAttrString(mod, name); // New reference
	Py_DECREF(mod);
	if (NULL == obj) {
		(void)PyErr_Format(PyExc_RuntimeError, "no attr '%s' for finding '%s'", name, classname);
	}
err:
	free(start);
	return obj;
}

PyObject *
lookup_itf(const char *repos_id)
{
	PyObject * class;
	PyObject * mod;
	PyObject * dict;
	static PyObject * func = NULL;

	if (NULL == func) {
		mod = PyImport_ImportModule("PyIDL"); // New reference
		if (NULL == mod) {
			return NULL;
		}
		dict = PyModule_GetDict(mod); // Borrowed reference
		if (NULL == dict) {
			return NULL;
		}
		func = PyDict_GetItemString(dict, "Lookup"); // Borrowed reference
		if (NULL == func) {
			return NULL;
		}
		if (!PyCallable_Check(func)) {
			func = NULL;
			return NULL;
		}
	}

	class = PyObject_CallFunction(func, "s", repos_id);	// cls = PyIDL.Lookup(repos_id)
	if (Py_None == class) {
		return NULL;
	}
	return class;
}

int
parse_object(PyObject *obj, const char *format, void *addr)
{
	PyObject * args;
	int result;

	if (NULL == obj)
		return -1;
	args = PyTuple_New(1); // New reference
	PyTuple_SetItem(args, 0, obj); // stolen reference
	result = PyArg_ParseTuple(args, format, addr);
	Py_INCREF(obj); // Increase reference to keep obj on args delete
	Py_DECREF(args);
	return result;
}

