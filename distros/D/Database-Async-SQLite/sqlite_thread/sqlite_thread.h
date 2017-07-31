#pragma once
#include <thread>
#include <sqlite_dbh.h>

class sqlite_thread {
public:
	sqlite_thread();
	virtual ~sqlite_thread();
private:
	std::thread thread_;
};

