/*
	g++ -I/usr/include/boost-1_33_1 -o hello hello.cpp
*/
#include <iostream>
#include <boost/format.hpp>

int main(){

	using namespace boost;
	std::cout << format("[%1%, %2%!]") % "Hello" % "world" << std::endl;

	return 0;
}
