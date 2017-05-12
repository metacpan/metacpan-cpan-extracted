#ifndef _PERSON_h
#define _PERSON_H

class Person {
public:
	int getAge();
	int getId();
	Person(int, int);

private:
	int age;
	int id;
};

#endif
