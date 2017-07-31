#pragma once
#include <string>
#include <vector>

class sqlite_dbh;
struct sqlite3_stmt;

class sqlite_sth {
public:
	sqlite_sth(sqlite_dbh &dbh, const std::string &sql);
	virtual ~sqlite_sth();

	const std::string &sql() const { return sql_; }
	
	void step();

private:
	sqlite_dbh &dbh_;
	sqlite3_stmt *stmt_;
	std::string sql_;
	std::vector<std::string> pending_;
	int count_;
	std::vector<std::string> column_names_;
};

