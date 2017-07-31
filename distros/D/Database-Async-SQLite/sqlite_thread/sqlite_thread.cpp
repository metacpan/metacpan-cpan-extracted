#include <iostream>
#include <thread>
#include <sqlite_thread.h>

sqlite_thread::sqlite_thread()
	:thread_{ [] {
		std::cout << "this is the thread\n";
		return 0;
	} }
{

}

