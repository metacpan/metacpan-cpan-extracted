#if !defined(__INCLUDE_PPMD_EXCEPTION_HPP__)
#define __INCLUDE_PPMD_EXCEPTION_HPP__


class PPMD_Exception {
public:
    PPMD_Exception(char *text) : myText(text) {}
    char *Text() { return myText; }
private:
    char *myText;
};


#endif
