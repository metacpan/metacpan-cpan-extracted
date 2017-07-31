#pragma once
#include <memory>
#include <string>
#include "sqlite_queue.h"

class sqlite3;

class sqlite_sth;
class sqlite_request;

class sqlite_dbh {
public:
	sqlite_dbh(const std::string &filename);
virtual ~sqlite_dbh(); 

	/** Returns the filename corresponding to this sqlite database */
	const std::string &filename() const { return filename_; }

	/** Prepares a statement handle from the given SQL */
	sqlite_sth *prepare(const std::string &sql);

	/** Returns the event FD corresponding to this database */
	int eventfd() const { return fd_; }

	void push(sqlite_queue::item_type &&req);

	sqlite3 *db() { return db_; }

private:
	const std::string filename_;
	sqlite3 *db_;
	int fd_;
	std::unique_ptr<sqlite_queue> queue_;
};

