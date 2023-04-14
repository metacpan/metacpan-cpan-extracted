#include "std.h"

class MyClass
{
  public:
    int myNum;
    const char *myString;
    void speed(int maxSpeed);
    int speed();
};

DLLEXPORT
int MyClass::speed() {
    return myNum;
}
DLLEXPORT
void MyClass::speed(int maxSpeed) {
    myNum = maxSpeed;
}

DLLEXPORT MyClass setup() {
    MyClass myObj = {.myNum = 15, .myString = "Some text"};
    return myObj;
}

DLLEXPORT MyClass setup(int i) {
    MyClass myObj = {.myNum = i, .myString = "Some different text"};
    return myObj;
}
